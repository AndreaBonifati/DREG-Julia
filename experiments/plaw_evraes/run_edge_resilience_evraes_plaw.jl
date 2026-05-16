using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Graphs
using Random
using Distributions
using StatsBase
using KrylovKit
using Statistics
using DelimitedFiles
using ThreadsX
using Printf
using LinearAlgebra
using Base.Threads: Atomic, atomic_add!

BLAS.set_num_threads(1)

const N_START = 2^15        # 32768
const D_DEFAULT = 4
const C_PARAM = 3.0


const K_FIXED = 2.0         
const P_STD_FIXED = 0.0     
const Q_NODE_FAIL = 0.0     
const LAMBDA_GROWTH = 0.0   

const NUM_RUNS_PER_POINT = 100 
const NUM_ROUNDS_PER_RUN = 100


const P_EDGE_VALUES = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

println("--- ESECUZIONE STRESS TEST (EDGE FAILURE) PER K=$K_FIXED ---")
println("Valori di p_edge da testare: $P_EDGE_VALUES")


struct SimulationTask
    p_val   :: Float64 
    run_idx :: Int
end

all_tasks = SimulationTask[]
for p in P_EDGE_VALUES
    for r in 1:NUM_RUNS_PER_POINT
        push!(all_tasks, SimulationTask(p, r))
    end
end

total_tasks = length(all_tasks)
progress_counter = Atomic{Int}(0)

function execute_single_run_stress(task::SimulationTask)
    local p_fail = task.p_val
    local run_id = task.run_idx
    

    local seed = 12345 + run_id + Int(round(p_fail * 10000)) + N_START
    

    state = plaw_evraes_graph(N_START, seed, K_FIXED, D_DEFAULT, P_STD_FIXED)
    
    trajectory = Vector{Float64}(undef, NUM_ROUNDS_PER_RUN)
    
    for r in 1:NUM_ROUNDS_PER_RUN
        n_old = plaw_ev_raes_step_zero!(state, LAMBDA_GROWTH)
        plaw_ev_raes_step_one!(state, n_old)
        plaw_ev_raes_step_two!(state, C_PARAM)
        

        plaw_ev_raes_step_three!(state, p_fail) 
        

        plaw_ev_raes_step_four!(state, Q_NODE_FAIL)

        trajectory[r] = spectral_gap(state.g)
    end
    
    c = atomic_add!(progress_counter, 1)
    if c % 50 == 0 || c == total_tasks
        @info "Progresso: $c / $total_tasks."
    end
    
    return (p_fail, trajectory)
end



println("\nAvvio simulazioni...")
results_flat = ThreadsX.map(execute_single_run_stress, all_tasks)


grouped_data = Dict{Float64, Matrix{Float64}}()
for p in P_EDGE_VALUES
    grouped_data[p] = Matrix{Float64}(undef, NUM_RUNS_PER_POINT, NUM_ROUNDS_PER_RUN)
end

fill_indices = Dict{Float64, Int}()
for p in P_EDGE_VALUES
    fill_indices[p] = 1
end

for (p, traj) in results_flat
    idx = fill_indices[p]
    grouped_data[p][idx, :] = traj
    fill_indices[p] += 1
end

final_results_matrix = Matrix{Float64}(undef, length(P_EDGE_VALUES), NUM_ROUNDS_PER_RUN)

for (i, p) in enumerate(P_EDGE_VALUES)
    mat = grouped_data[p]
    final_results_matrix[i, :] = vec(mean(mat, dims=1))
end


results_folder = "results/plaw_evraes"
mkpath(results_folder)

filename = "spectral_gap_k$(K_FIXED)_edge_failure.csv"
output_path = joinpath(results_folder, filename)

println("Salvataggio in '$output_path'")

header_rounds = ["round_$r" for r in 1:NUM_ROUNDS_PER_RUN]
header = vcat("p_edge_value", header_rounds)

p_col = collect(P_EDGE_VALUES)
data_to_save = hcat(p_col, final_results_matrix)

open(output_path, "w") do io
    writedlm(io, reshape(header, 1, :), ',')
    writedlm(io, data_to_save, ',')
end

println("Finito.")