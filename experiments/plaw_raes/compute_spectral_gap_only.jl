using Pkg
Pkg.activate(".")
Pkg.instantiate()
using DynamicRandomExpanderGenerator
using Graphs
using Random
using KrylovKit
using Statistics
using DelimitedFiles
using ThreadsX
using Printf
using LinearAlgebra
using Base.Threads: Atomic, atomic_add!

BLAS.set_num_threads(1)



const N = 2^15
const D_FIXED = 4      
const C_STD = 3        
const K_POWER = 2.0    

const NUM_RUNS = 100
const NUM_ROUNDS = 100


const P_VALUES_GAP = 0.0:0.1:1.0

println("--- AVVIO EXPERIMENTI PLAW RAES (Solo Spectral Gap) ---")
println("N=$N, d=$D_FIXED, c_std=$C_STD, k=$K_POWER")
println("Runs: $NUM_RUNS, Rounds: $NUM_ROUNDS")



struct SimTask
    p_val :: Float64
    run_idx :: Int
end


all_tasks = [SimTask(p, r) for p in P_VALUES_GAP for r in 1:NUM_RUNS]

total_tasks = length(all_tasks)
progress_cnt = Atomic{Int}(0)


results_gap = Dict{Float64, Vector{Float64}}()


locks = Dict(p => ReentrantLock() for p in P_VALUES_GAP)
for p in P_VALUES_GAP
    results_gap[p] = Float64[]
end



function run_simulation(task::SimTask)
    p = task.p_val
    seed = 12345 + task.run_idx + Int(round(p * 1000))

    state = plaw_raes_graph(N, seed, K_POWER, D_FIXED, p)
    
    for _ in 1:NUM_ROUNDS
        plaw_raes_step_one!(state)
        plaw_raes_step_two!(state, C_STD) 
    end
    
    gap = spectral_gap(state.g)
    
    lock(locks[p]) do
        push!(results_gap[p], gap)
    end
    
    c = atomic_add!(progress_cnt, 1)
    if c % 100 == 0
        @info "Completati $c / $total_tasks tasks"
    end
end

println("Esecuzione parallela su $(Threads.nthreads()) threads...")
ThreadsX.foreach(run_simulation, all_tasks)

mkpath("results/plaw_raes")

gap_file = "results/plaw_raes/spectral_gap_vs_p_standard_params_plaw_raes.csv"
open(gap_file, "w") do io

    writedlm(io, ["p_value" "mean_gap" "std_gap"], ',')
    
    sorted_ps = sort(collect(keys(results_gap)))
    
    for p in sorted_ps
        vals = results_gap[p]
        writedlm(io, [p mean(vals) std(vals)], ',')
    end
end

println("Salvati risultati Spectral Gap in: $gap_file")
println("Processo Completato con Successo.")