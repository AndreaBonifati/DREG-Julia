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




const N_START = 2^15        
const D_DEFAULT = 4
const C_PARAM = 3.0


const K_FIXED = 2.0         
const P_STD_FIXED = 0.0     
const P_EDGE_FAIL = 0.0    
const LAMBDA_GROWTH = 0.0   

const NUM_RUNS_PER_POINT = 100 
const NUM_ROUNDS_PER_RUN = 100


const Q_NODE_VALUES = [0.001, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.3]

println("--- ESECUZIONE STRESS TEST (NODE FAILURE) PER K=$K_FIXED ---")
println("Valori di q_node da testare: $Q_NODE_VALUES")
println("Runs per valore: $NUM_RUNS_PER_POINT, Threads: $(Threads.nthreads())")



struct SimulationTask
    q_val   :: Float64 
    run_idx :: Int
end

all_tasks = SimulationTask[]
for q in Q_NODE_VALUES
    for r in 1:NUM_RUNS_PER_POINT
        push!(all_tasks, SimulationTask(q, r))
    end
end

total_tasks = length(all_tasks)
progress_counter = Atomic{Int}(0)

function execute_single_run_churn(task::SimulationTask)
    local q_fail = task.q_val
    local run_id = task.run_idx

    local lambda_val = N_START * q_fail
    local seed = 12345 + run_id + Int(round(q_fail * 100000)) + N_START
    
    state = plaw_evraes_graph(N_START, seed, K_FIXED, D_DEFAULT, P_STD_FIXED)
    
    trajectory = Vector{Float64}(undef, NUM_ROUNDS_PER_RUN)
    
    for r in 1:NUM_ROUNDS_PER_RUN
        n_old = plaw_ev_raes_step_zero!(state, lambda_val)
        plaw_ev_raes_step_one!(state, n_old)
        plaw_ev_raes_step_two!(state, C_PARAM)
        

        plaw_ev_raes_step_three!(state, P_EDGE_FAIL) 

        plaw_ev_raes_step_four!(state, q_fail)


        trajectory[r] = spectral_gap(state.g)
    end
    
    c = atomic_add!(progress_counter, 1)
    if c % 50 == 0 || c == total_tasks
        @info "Progresso: $c / $total_tasks."
    end
    
    return (q_fail, trajectory)
end

println("\nAvvio simulazioni...")
results_flat = ThreadsX.map(execute_single_run_churn, all_tasks)


grouped_data = Dict{Float64, Matrix{Float64}}()
for q in Q_NODE_VALUES
    grouped_data[q] = Matrix{Float64}(undef, NUM_RUNS_PER_POINT, NUM_ROUNDS_PER_RUN)
end

fill_indices = Dict{Float64, Int}()
for q in Q_NODE_VALUES
    fill_indices[q] = 1
end

for (q, traj) in results_flat
    idx = fill_indices[q]
    grouped_data[q][idx, :] = traj
    fill_indices[q] += 1
end

final_results_matrix = Matrix{Float64}(undef, length(Q_NODE_VALUES), NUM_ROUNDS_PER_RUN)

for (i, q) in enumerate(Q_NODE_VALUES)
    mat = grouped_data[q]
    final_results_matrix[i, :] = vec(mean(mat, dims=1))
end


results_folder = "results/plaw_evraes"
mkpath(results_folder)

filename = "spectral_gap_k$(K_FIXED)_vary_node_failure.csv"
output_path = joinpath(results_folder, filename)

println("Salvataggio in '$output_path'")

header_rounds = ["round_$r" for r in 1:NUM_ROUNDS_PER_RUN]
header = vcat("q_node_value", header_rounds)

q_col = collect(Q_NODE_VALUES)
data_to_save = hcat(q_col, final_results_matrix)

open(output_path, "w") do io
    writedlm(io, reshape(header, 1, :), ',')
    writedlm(io, data_to_save, ',')
end

println("Finito.")