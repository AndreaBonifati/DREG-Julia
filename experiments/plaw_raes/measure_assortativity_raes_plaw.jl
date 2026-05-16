using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using ThreadsX
using DelimitedFiles
using Printf


const N = 2^15        
const D = 4
const C = 3.0
const K = 2.0         
const RUNS = 50       
const ROUNDS = 50     

const P_VALUES = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

println("--- ANALISI ASSORTATIVITÀ (K=$K) ---")
println("Config: N=$N, Runs=$RUNS, Threads=$(Threads.nthreads())")

print_lock = ReentrantLock()


results_list = ThreadsX.map(P_VALUES) do p
    
    (p_val, avg, dev) = compute_assortativity_stats_single_plaw_raes(p, N, D, C, K, RUNS, ROUNDS)
    
    lock(print_lock) do
        @printf("P=%.1f -> Assortatività: %+.4f (std: %.4f)\n", p_val, avg, dev)
    end
    
    return [p_val, avg, dev]
end


results_matrix = Matrix{Float64}(undef, length(results_list), 3)
for (i, row) in enumerate(results_list)
    results_matrix[i, :] = row
end

mkpath("results/plaw_raes")
output_file = "results/plaw_raes/assortativity_stats_k2.csv"
header = ["p_value", "mean_assortativity", "std_assortativity"]

open(output_file, "w") do io
    writedlm(io, reshape(header, 1, :), ',')
    writedlm(io, results_matrix, ',')
end

println("\nDati salvati in: $output_file")