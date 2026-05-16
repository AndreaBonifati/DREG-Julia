using Pkg
Pkg.activate(".")
Pkg.instantiate()

using DynamicRandomExpanderGenerator
using Graphs
using Random
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


const P_VALUES = [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0]

println("--- AVVIO EXPERIMENTI PLAW C-RAES (Solo Grado Massimo) ---")
println("N=$N, d=$D_FIXED, c_std=$C_STD, k=$K_POWER")
println("Runs: $NUM_RUNS, Rounds: $NUM_ROUNDS")



struct SimTask
    p_val :: Float64
    run_idx :: Int
end

all_tasks = [SimTask(p, r) for p in P_VALUES for r in 1:NUM_RUNS]
total_tasks = length(all_tasks)
progress_cnt = Atomic{Int}(0)


results_max_deg = Dict{Float64, Vector{Int}}()


locks = Dict(p => ReentrantLock() for p in P_VALUES)
for p in P_VALUES
    results_max_deg[p] = Int[]
end



function run_simulation(task::SimTask)
    p = task.p_val
    seed = 12345 + task.run_idx + Int(round(p * 1000))
    
    state = plaw_c_raes_graph(N, seed, K_POWER, D_FIXED, C_STD, p)
    
    for _ in 1:NUM_ROUNDS
        plaw_c_raes_step_one!(state)
        plaw_c_raes_step_two!(state) 
    end
    
    max_d = maximum(degree(state.g))
    
    lock(locks[p]) do
        push!(results_max_deg[p], max_d)
    end
    
    c = atomic_add!(progress_cnt, 1)
    if c % 100 == 0
        @info "Completati $c / $total_tasks tasks"
    end
end

println("Esecuzione parallela su $(Threads.nthreads()) threads...")
ThreadsX.foreach(run_simulation, all_tasks)


mkpath("results/plaw_c_raes")

max_deg_file = "results/plaw_c_raes/max_degree_vs_p_standard_params.csv"
open(max_deg_file, "w") do io
    writedlm(io, ["p_value" "mean_max_degree" "std_max_degree" "absolute_max"], ',')
    
    sorted_ps = sort(collect(keys(results_max_deg)))
    
    for p in sorted_ps
        vals = results_max_deg[p]
        writedlm(io, [p mean(vals) std(vals) maximum(vals)], ',')
    end
end

println("Salvati risultati Grado Massimo in: $max_deg_file")
println("Processo Completato con Successo.")