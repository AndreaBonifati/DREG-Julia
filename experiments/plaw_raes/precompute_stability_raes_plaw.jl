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
const D = 4
const C = 3.0
const K = 2.0        
const PILOT_RUNS = 1  
const ROUNDS = 100    


const P_VALUES = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

println("Config: N=$N, K=$K, Pilot Runs=$PILOT_RUNS")

print_lock = ReentrantLock()

function run_pilot_analysis_serial(p_val)
    t0_values = Int[]
    
    for i in 1:PILOT_RUNS
        seed = N + 123 + i 
        state = plaw_raes_graph(N, seed, K, D, p_val)
        
        gaps = Float64[]
        for r in 1:ROUNDS
            plaw_raes_step_one!(state)
            plaw_raes_step_two!(state, C)
            push!(gaps, spectral_gap(state.g))
        end
        
        eps = compute_epsilon(gaps)
        t0 = compute_t0(gaps, N, eps)
        push!(t0_values, t0)
    end
    
    valid_t0 = filter(x -> x != -1, t0_values)
    if isempty(valid_t0); return -1; end
    return maximum(valid_t0) 
end

results_list = ThreadsX.map(P_VALUES) do p
    
    t0_final = run_pilot_analysis_serial(p)
    
    lock(print_lock) do
        @printf("Completato p=%.1f -> t0 stabile: %d\n", p, t0_final)
    end
    
    return (p, t0_final)
end



results_matrix = Matrix{Any}(undef, length(P_VALUES), 2)
for (i, (p, t0)) in enumerate(results_list)
    results_matrix[i, :] = [p, t0]
end

mkpath("results/plaw_raes")
output_file = "results/plaw_raes/stabilization_t0_plaw.csv"
header = ["p_value", "t0"]

open(output_file, "w") do io
    writedlm(io, reshape(header, 1, :), ',')
    writedlm(io, results_matrix, ',')
end

println("\nTabella t0 salvata in: $output_file")