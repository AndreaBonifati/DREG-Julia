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


const N = 2^15       
const D_DEFAULT = 4
const C_PARAM = 3.0
const K = 2.0    
const NUM_RUNS_PER_POINT = 100 
const NUM_ROUNDS_PER_RUN = 100



const P_VALUES =  [0.1, 0.3, 0.5, 0.7, 0.9]

println("Parametri fissi: N=$N, d=$D_DEFAULT, c=$C_PARAM, k=$K")
println("Valori di p: $P_VALUES")
println("Numero di run per punto: $NUM_RUNS_PER_POINT")


results = Matrix{Float64}(undef, length(P_VALUES), NUM_ROUNDS_PER_RUN)

println("--- ESPERIMENTO: Traiettorie Spectral Gap al variare di P (con K=2.0) ---")

println("\nAvvio delle simulazioni...")


tasks = [(p, i) for (i, p) in enumerate(P_VALUES)]
num_tasks = length(tasks)

println("Numero di task da eseguire: $num_tasks")
println("Threads attivi: ", Threads.nthreads())

function run_single_task(task, idx)
    (p, i) = task

    trajectory_vector = compute_spectral_gap_trajectory_plaw_raes(
        N, D_DEFAULT, C_PARAM, K, p, NUM_RUNS_PER_POINT, NUM_ROUNDS_PER_RUN
    )
    
    @info "Completato task per p=$p ($idx/$num_tasks)"

    return (i, trajectory_vector)
end


task_results = ThreadsX.map(run_single_task, tasks, 1:num_tasks)


for (i, trajectory) in task_results
    results[i, :] = trajectory
end

println("\nTutte le simulazioni sono completate.")



results_folder = "results/plaw_raes"
mkpath(results_folder)

output_filename = joinpath(results_folder, "spectral_gap_trajectory_by_p.csv") 
println("Salvataggio dei risultati in '$output_filename'")

header_rounds = ["round_$r" for r in 1:NUM_ROUNDS_PER_RUN]
header = vcat("p_value", header_rounds)

p_colonna = collect(P_VALUES)
data_to_save = hcat(p_colonna, results)

open(output_filename, "w") do io
    writedlm(io, reshape(header, 1, :), ',') 
    writedlm(io, data_to_save, ',')
end

println("Salvataggio completato.")