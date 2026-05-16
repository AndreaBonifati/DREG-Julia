using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Graphs
using Random
using Distributions
using Statistics
using DelimitedFiles
using ThreadsX
using Printf

const N = 2^15        
const D = 4
const C = 3.0
const K = 2.0         
const RUNS = 50       
const ROUNDS = 50

const P_VALUES = [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0]

println("--- ANALISI STRUTTURALE ESTESA (Parallelismo su Task P) ---")
println("Config: N=$N, K=$K, Threads=$(Threads.nthreads())")
println("\n  P   | AvgDeg | MaxDeg | MinDeg | % < Avg | % > Avg | # Min | # Max | HubPow")
println("------+--------+--------+--------+---------+---------+-------+-------+-------")


print_lock = ReentrantLock()


results_list = ThreadsX.map(P_VALUES) do p_val
    
    stats = compute_structure_metrics_plaw_raes(N, D, C, K, p_val, RUNS, ROUNDS)
    
    lock(print_lock) do
        @printf(" %.1f  |  %.2f  |  %5d |   %2d   |  %.1f%%  |  %.1f%%  | %5.1f | %5.1f | %.1f%%\n", 
                p_val, stats.avg_deg, stats.max_deg, stats.min_deg, 
                stats.perc_nodes_below_avg, stats.perc_nodes_above_avg,
                stats.num_nodes_with_min_deg, stats.num_nodes_with_max_deg,
                stats.perc_edges_in_top_1)
    end

    return (p_val, stats)
end



results_matrix = Matrix{Any}(undef, length(P_VALUES), 9)

for (i, (p_val, s)) in enumerate(results_list)
    results_matrix[i, :] = [
        p_val, s.avg_deg, s.max_deg, s.min_deg, 
        s.perc_nodes_below_avg, s.perc_nodes_above_avg,
        s.num_nodes_with_min_deg, s.num_nodes_with_max_deg,
        s.perc_edges_in_top_1
    ]
end

mkpath("results/structure")
output_file = "results/structure/topology_stats_k2_extended.csv"
header = ["p_value", "avg_deg", "max_deg", "min_deg", "perc_below_avg", "perc_above_avg", "count_nodes_min_deg", "count_nodes_max_deg", "hub_dominance"]

open(output_file, "w") do io
    writedlm(io, reshape(header, 1, :), ',')
    writedlm(io, results_matrix, ',')
end
println("\nDati salvati in: $output_file")