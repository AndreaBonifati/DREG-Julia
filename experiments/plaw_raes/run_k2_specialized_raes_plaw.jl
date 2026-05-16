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

println("--- ESECUZIONE SPECIALIZZATA PER K=2.0 (Parallelismo sulle Run) ---")

const N = 2^15
const D_DEFAULT = 4
const C_PARAM = 3.0
const P_STD = 0.0
const K_TARGET = 2.0  
const NUM_RUNS = 100 
const NUM_ROUNDS = 100

println("Configurazione: N=$N, k=$K_TARGET (Run=$NUM_RUNS su $(Threads.nthreads()) thread)")



function execute_single_run_plaw(run_idx, n, d, c, k, p_std, num_rounds)
    local seed = 12345 + run_idx + Int(round(k*100)) + n
    
    state = plaw_raes_graph(n, seed, k, d, p_std)
    
    gaps_history = Vector{Float64}(undef, num_rounds)
    
    for r in 1:num_rounds
        plaw_raes_step_one!(state)
        plaw_raes_step_two!(state, c)

        gaps_history[r] = spectral_gap(state.g)
    end
    

    @info "Run $run_idx completata."
    
    return gaps_history
end



println("\nAvvio delle $NUM_RUNS run in parallelo...")


all_runs_trajectories = ThreadsX.map(1:NUM_RUNS) do i
    execute_single_run_plaw(i, N, D_DEFAULT, C_PARAM, K_TARGET, P_STD, NUM_ROUNDS)
end

println("Tutte le run completate. Elaborazione statistiche...")


data_matrix = hcat(all_runs_trajectories...) 

avg_trajectory = vec(mean(data_matrix, dims=2))


results_folder = "results/plaw_raes"
mkpath(results_folder)
output_filename = joinpath(results_folder, "spectral_gap_trajectory_k2.0_only.csv")

println("Salvataggio risultati in '$output_filename'")

header = ["round", "avg_gap_k2.0"]
data_to_save = hcat(1:NUM_ROUNDS, avg_trajectory)

open(output_filename, "w") do io
    writedlm(io, reshape(header, 1, :), ',')
    writedlm(io, data_to_save, ',')
end

println("Completato.")