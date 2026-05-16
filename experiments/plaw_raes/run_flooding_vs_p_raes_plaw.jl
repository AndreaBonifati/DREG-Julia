using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Graphs
using Random
using Distributions
using StatsBase
using Statistics
using DelimitedFiles
using ThreadsX
using Printf
using LinearAlgebra


BLAS.set_num_threads(1)

function measure_flooding_time(n, d, c, k, p, t0_warmup, seed)
    state = plaw_raes_graph(n, seed, k, d, p)

    active_nodes = trues(n)
    all_informed = falses(n)
    
    for r in 1:t0_warmup
        plaw_raes_step_one!(state)
        plaw_raes_step_two!(state, c)
    end
    

    starter = rand(state.rng, 1:n)
    all_informed[starter] = true
    
    rounds = 0
    max_rounds = 100
    
    while count(all_informed) < n && rounds < max_rounds
        rounds += 1
        plaw_raes_step_one!(state)
        plaw_raes_step_two!(state, c)
        flooding_step!(all_informed, state.g, active_nodes)
    end
    
    return rounds
end

const N = 2^15        
const D = 4
const C = 3.0
const K = 2.0         
const RUNS = 100      
const DEFAULT_WARMUP = 15 

const P_VALUES = 0.0:0.1:1.0


t0_map = Dict{Float64, Int}()
t0_file = "results/plaw_raes/stabilization_t0_plaw.csv"

println("Caricamento t0 da $t0_file...")
if isfile(t0_file)
    data, header = readdlm(t0_file, ',', header=true)
    for i in axes(data, 1)
        p_val = Float64(data[i, 1])
        t0_val = Int(data[i, 2])
        t0_map[p_val] = t0_val
    end
    println("  -> Trovati $(length(t0_map)) valori di t0.")
else
    println("  -> ATTENZIONE: File t0 non trovato. Si usa il fallback ($DEFAULT_WARMUP).")
end

println("Config: N=$N, K=$K, Runs=$RUNS (Processi: $(Threads.nthreads()))")


println("\nAvvio simulazioni")


function run_p_task(p_val)
    t0_target = get(t0_map, p_val, -1)
    t0_used = (t0_target > 0) ? t0_target : DEFAULT_WARMUP
    
    times = Float64[]

    for i in 1:RUNS

        seed = N + 123 + i 
        t = measure_flooding_time(N, D, C, K, p_val, t0_used, seed)
        push!(times, t)
    end
    
    avg_t = mean(times)
    @printf("Completato P=%.1f (t0=%d) -> Avg Time: %.2f\n", p_val, t0_used, avg_t)
    
    return [p_val, Float64(t0_used), avg_t]
end


results_list = ThreadsX.map(run_p_task, collect(P_VALUES))


results_matrix = Matrix{Float64}(undef, length(P_VALUES), 3)
for (i, row) in enumerate(results_list)
    results_matrix[i, :] = row
end



mkpath("results/flooding")
csv_path = "results/flooding/flooding_vs_p_k2_dynamic.csv"
header = ["p_value", "t0_used", "avg_flooding_time"]

open(csv_path, "w") do io
    writedlm(io, reshape(header, 1, :), ',')
    writedlm(io, results_matrix, ',')
end
println("\nDati salvati in: $csv_path")