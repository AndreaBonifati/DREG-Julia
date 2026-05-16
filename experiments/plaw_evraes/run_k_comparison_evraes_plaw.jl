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
const P_STD = 0.0           
const P_EDGE_FAIL = 0.0
const Q_NODE_FAIL = 0.0
const LAMBDA_NODE_ARRIVAL = 0.0 

const NUM_RUNS_PER_POINT = 100 
const NUM_ROUNDS_PER_RUN = 100


const K_VALUES = [2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0]

println("--- ESECUZIONE PARALLELA PER EV_RAES (PLAW) ---")
println("Parametri: N=$N_START, d=$D_DEFAULT, c=$C_PARAM, p_std=$P_STD")
println("Failures: p_edge=$P_EDGE_FAIL, q_node=$Q_NODE_FAIL")
println("Growth: lambda=$LAMBDA_NODE_ARRIVAL")
println("Valori di k: $K_VALUES")
println("Threads attivi: ", Threads.nthreads())



struct SimulationTask
    k_val   :: Float64
    run_idx :: Int
end

all_tasks = SimulationTask[]
for k in K_VALUES
    for r in 1:NUM_RUNS_PER_POINT
        push!(all_tasks, SimulationTask(k, r))
    end
end

total_tasks = length(all_tasks)
println("Totale microtask da eseguire: $total_tasks")

progress_counter = Atomic{Int}(0)

function execute_single_run_ev(task::SimulationTask)
    local k = task.k_val
    local run_id = task.run_idx
    local seed = 12345 + run_id + Int(round(k * 1000)) + N_START
    

    state = plaw_evraes_graph(N_START, seed, k, D_DEFAULT, P_STD)
    
    trajectory = Vector{Float64}(undef, NUM_ROUNDS_PER_RUN)
    
    for r in 1:NUM_ROUNDS_PER_RUN

        n_old = plaw_ev_raes_step_zero!(state, LAMBDA_NODE_ARRIVAL)
        
        plaw_ev_raes_step_one!(state, n_old)
        
        plaw_ev_raes_step_two!(state, C_PARAM)
        
        plaw_ev_raes_step_three!(state, P_EDGE_FAIL)
        plaw_ev_raes_step_four!(state, Q_NODE_FAIL)

        trajectory[r] = spectral_gap(state.g)
    end
    
    c = atomic_add!(progress_counter, 1)
    if c % 10 == 0 || c == total_tasks
        @info "Progresso: $c / $total_tasks completati."
    end
    
    return (k, trajectory)
end

println("\nAvvio elaborazione parallela...")


results_flat = ThreadsX.map(execute_single_run_ev, all_tasks)

println("\nElaborazione completata. Aggregazione dati...")

grouped_data = Dict{Float64, Matrix{Float64}}()

for k in K_VALUES
    grouped_data[k] = Matrix{Float64}(undef, NUM_RUNS_PER_POINT, NUM_ROUNDS_PER_RUN)
end

fill_indices = Dict{Float64, Int}()
for k in K_VALUES
    fill_indices[k] = 1
end

for (k, traj) in results_flat
    idx = fill_indices[k]
    grouped_data[k][idx, :] = traj
    fill_indices[k] += 1
end

final_results_matrix = Matrix{Float64}(undef, length(K_VALUES), NUM_ROUNDS_PER_RUN)

for (i, k) in enumerate(K_VALUES)
    mat = grouped_data[k]
    mean_trajectory = vec(mean(mat, dims=1)) 
    final_results_matrix[i, :] = mean_trajectory
end

results_folder = "results/plaw_evraes"
mkpath(results_folder)

file_suffix = (P_EDGE_FAIL > 0 || Q_NODE_FAIL > 0) ? "_FAILURES_p$(P_EDGE_FAIL)_q$(Q_NODE_FAIL)" : ""
if LAMBDA_NODE_ARRIVAL > 0
    file_suffix *= "_GROWTH_lambda$(LAMBDA_NODE_ARRIVAL)"
end

output_filename = joinpath(results_folder, "spectral_gap_trajectory_by_k$(file_suffix).csv")

println("Salvataggio risultati in '$output_filename'")

header_rounds = ["round_$r" for r in 1:NUM_ROUNDS_PER_RUN]
header = vcat("k_value", header_rounds)

k_col = collect(K_VALUES)
data_to_save = hcat(k_col, final_results_matrix)

open(output_filename, "w") do io
    writedlm(io, reshape(header, 1, :), ',')
    writedlm(io, data_to_save, ',')
end

println("Salvataggio completato.")