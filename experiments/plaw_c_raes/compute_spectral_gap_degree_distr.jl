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



const N = 2^15
const D_FIXED = 8       
const C_STD = 16       
const K_POWER = 2.0     

const NUM_RUNS = 100
const NUM_ROUNDS = 100


const P_VALUES_GAP = 0.0:0.1:1.0

const P_VALUES_DEG = [round(p, digits=1) for p in 0.0:0.1:1.0]

println("--- AVVIO ESPERIMENTI PLAW C-RAES ---")
println("N=$N, d=$D_FIXED, c_std=$C_STD, k=$K_POWER")
println("Runs: $NUM_RUNS, Rounds: $NUM_ROUNDS")



struct SimTask
    p_val :: Float64
    run_idx :: Int
end


all_p_needed = sort(unique(vcat(collect(P_VALUES_GAP), P_VALUES_DEG)))
all_tasks = [SimTask(p, r) for p in all_p_needed for r in 1:NUM_RUNS]

total_tasks = length(all_tasks)
progress_cnt = Atomic{Int}(0)

results_gap = Dict{Float64, Vector{Float64}}()

results_degrees = Dict{Float64, Vector{Int}}()


locks = Dict(p => ReentrantLock() for p in all_p_needed)
for p in all_p_needed
    results_gap[p] = Float64[]
    results_degrees[p] = Int[] 
end

function run_simulation(task::SimTask)
    p = task.p_val
    seed = 12345 + task.run_idx + Int(round(p * 1000))
    

    state = plaw_c_raes_graph(N, seed, K_POWER, D_FIXED, C_STD, p)
    

    for _ in 1:NUM_ROUNDS
        plaw_c_raes_step_one!(state)
        plaw_c_raes_step_two!(state) 
    end
    

    gap = spectral_gap(state.g)
    degs = degree(state.g)
    
 
    lock(locks[p]) do
        push!(results_gap[p], gap)
        append!(results_degrees[p], degs)
    end
    
    
    c = atomic_add!(progress_cnt, 1)
    if c % 100 == 0
        @info "Completati $c / $total_tasks tasks"
    end
end

println("Esecuzione parallela su $(Threads.nthreads()) threads...")
ThreadsX.foreach(run_simulation, all_tasks)



mkpath("results/plaw_c_raes")


gap_file = "results/plaw_c_raes/spectral_gap_vs_p.csv"
open(gap_file, "w") do io
    writedlm(io, ["p_value" "mean_gap" "std_gap"], ',')

    sorted_ps = sort(collect(keys(results_gap)))
    for p in sorted_ps

        vals = results_gap[p]
        writedlm(io, [p mean(vals) std(vals)], ',')
    end
end
println("Salvati risultati Spectral Gap in $gap_file")

avg_deg_file = "results/plaw_c_raes/average_degrees.csv"
open(avg_deg_file, "w") do io
    writedlm(io, ["p_value" "average_degree" "std_degree"], ',')
    sorted_ps = sort(collect(keys(results_degrees)))
    for p in sorted_ps
        all_degs = results_degrees[p]
        if !isempty(all_degs)
            avg = mean(all_degs)
            dev = std(all_degs)
            writedlm(io, [p avg dev], ',')
        end
    end
end
println("Salvati risultati Grado Medio: $avg_deg_file")


max_deg_global = 0
for p in P_VALUES_DEG
    if !isempty(results_degrees[p])

        global max_deg_global = max(max_deg_global, maximum(results_degrees[p]))
    end
end

deg_file = "results/plaw_c_raes/degree_distributions.csv"
open(deg_file, "w") do io

    header = ["degree"]
    sorted_p_deg = sort(P_VALUES_DEG)
    for p in sorted_p_deg
        push!(header, "p_$p")
    end
    writedlm(io, reshape(header, 1, :), ',')
    

    for k in 0:max_deg_global
        row = Any[k]
        for p in sorted_p_deg
            all_degs = results_degrees[p]
            if isempty(all_degs)
                push!(row, 0.0)
            else

                deg_count = count(x -> x == k, all_degs)
                freq = deg_count / length(all_degs)
                push!(row, freq)
            end
        end
        writedlm(io, reshape(row, 1, :), ',')
    end
end
println("Salvati risultati Distribuzioni Gradi in $deg_file")
println("Finito.")