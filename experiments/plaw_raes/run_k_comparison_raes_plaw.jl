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

BLAS.set_num_threads(1)

"""
Si fissa n, d e p=0.0, si fanno variare i diversi valori di k.
Si restituisce un csv dove ogni riga corrisponde ad un valore di k ed ogni colonna ad un round.
Una riga contiene la media, ottenuta da 100 run, dello spectral gap ad ogni round.
"""

const N = 2^15        
const D_DEFAULT = 4
const C_PARAM = 3.0
const P_STD = 0.0    
const NUM_RUNS_PER_POINT = 100 
const NUM_ROUNDS_PER_RUN = 100



const K_VALUES = [ 2.5, 3.0, 3.5, 4.0, 4.5, 5.0] 

println("Parametri fissi: N=$N, d=$D_DEFAULT, c=$C_PARAM, p_std=$P_STD")
println("Valori di k: $K_VALUES")
println("Numero di run per punto: $NUM_RUNS_PER_POINT")


results = Matrix{Float64}(undef, length(K_VALUES), NUM_ROUNDS_PER_RUN)

println("\nAvvio delle simulazioni")


tasks = [(k, i) for (i, k) in enumerate(K_VALUES)]
num_tasks = length(tasks)

println("Numero di task da eseguire: $num_tasks")
println("Threads attivi: ", Threads.nthreads())

function run_single_task(task, idx)
    (k_val, i) = task

    trajectory_vector = compute_spectral_gap_trajectory_plaw_raes(
        N, D_DEFAULT, C_PARAM, k_val, P_STD, NUM_RUNS_PER_POINT, NUM_ROUNDS_PER_RUN
    )
    
    @info "Completato task per k=$k_val ($idx/$num_tasks)"

    return (i, trajectory_vector)
end


task_results = ThreadsX.map(run_single_task, tasks, 1:num_tasks)


for (i, trajectory) in task_results
    results[i, :] = trajectory
end

println("\nTutte le simulazioni sono completate.")



results_folder = "results/plaw_raes"
mkpath(results_folder)

output_filename = joinpath(results_folder, "spectral_gap_trajectory_by_k.csv") 
println("Salvataggio dei risultati in '$output_filename'")

header_rounds = ["round_$r" for r in 1:NUM_ROUNDS_PER_RUN]
header = vcat("k_value", header_rounds)

k_colonna = collect(K_VALUES)
data_to_save = hcat(k_colonna, results)

open(output_filename, "w") do io
    writedlm(io, reshape(header, 1, :), ',') 
    writedlm(io, data_to_save, ',')
end

println("Salvataggio completato.")