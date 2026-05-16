using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Graphs
using Statistics
using DelimitedFiles
using Printf
using Random
using Dates 


const N = 2^15        
const D = 4
const C = 3.0
const K = 2.0         
const RUNS = 50       
const ROUNDS = 50     
const SAMPLE_SIZE = 2000 

const P_VALUES = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

println("--- ADVANCED TOPOLOGY ANALYSIS  ---")
println("Numero Thread Attivi: $(Threads.nthreads())") 
println("Config: N=$N, Runs=$RUNS, SampleSize=$SAMPLE_SIZE")
println("Inizio: $(now())")

function compute_single_run(p_val::Float64, run_idx::Int, n::Int, d::Int, c::Float64, k::Float64, rounds::Int, sample_sz::Int)
    
    seed = run_idx + Int(round(p_val * 10000)) 
    

    state = plaw_raes_graph(n, seed, k, d, p_val)
    for r in 1:rounds
        plaw_raes_step_one!(state)
        plaw_raes_step_two!(state, c)
    end
    
    g = state.g

    if !is_connected(g)
        components = connected_components(g)
        largest_comp = sort(components, by=length, rev=true)[1]
        g_sub, _ = induced_subgraph(g, largest_comp)
        g_main = g_sub
    else
        g_main = g
    end
    

    real_sample_sz = min(sample_sz, nv(g_main))
    

    sources = rand(1:nv(g_main), real_sample_sz)
    local_maxs = Int[]
    local_means = Float64[]
    
    for s in sources
        dists = gdistances(g_main, s)
        push!(local_maxs, maximum(dists))
        push!(local_means, mean(dists))
    end
    
    diam = isempty(local_maxs) ? 0.0 : Float64(maximum(local_maxs))
    apl  = isempty(local_means) ? 0.0 : mean(local_means)

    g_clust = global_clustering_coefficient(g_main)
    l_clust = mean(local_clustering_coefficient(g_main))


    bc_scores = betweenness_centrality(g_main, real_sample_sz) 
    max_bc = maximum(bc_scores)


    return (p_val, diam, apl, g_clust, l_clust, max_bc)
end


println("--- OPTIMIZED DYNAMIC TOPOLOGY ANALYSIS  ---")
println("Numero Thread Attivi: $(Threads.nthreads())")
println("Jobs totali: $(length(P_VALUES) * RUNS)")
println("Inizio: $(now())")


jobs = [(p, r) for p in P_VALUES for r in 1:RUNS]
total_jobs = length(jobs)


raw_results = Vector{Any}(undef, total_jobs)


progress_counter = Threads.Atomic{Int}(0)
print_lock = ReentrantLock()


Threads.@threads :dynamic for i in 1:total_jobs
    (p_val, run_idx) = jobs[i]
    

    res = compute_single_run(p_val, run_idx, N, D, C, K, ROUNDS, SAMPLE_SIZE)
    
    raw_results[i] = res
    

    Threads.atomic_add!(progress_counter, 1)
    current_count = progress_counter.value

    if current_count % 10 == 0 || current_count == total_jobs
        lock(print_lock) do
            perc = round(current_count / total_jobs * 100, digits=1)
            @printf("[%s] Progresso: %d/%d (%.1f%%)\n", Dates.format(now(), "HH:MM:SS"), current_count, total_jobs, perc)
        end
    end
end

println("\nCalcoli completati. Aggregazione dati...")


final_results_matrix = Matrix{Float64}(undef, length(P_VALUES), 11)

for (i, p) in enumerate(P_VALUES)
    subset = [r for r in raw_results if r[1] == p]
    
    diams    = [x[2] for x in subset]
    apls     = [x[3] for x in subset]
    g_clusts = [x[4] for x in subset]
    l_clusts = [x[5] for x in subset]
    max_bcs  = [x[6] for x in subset]

    final_results_matrix[i, :] = [
        p,
        mean(diams), std(diams),
        mean(apls), std(apls),
        mean(g_clusts), std(g_clusts),
        mean(l_clusts), std(l_clusts),
        mean(max_bcs), std(max_bcs)
    ]
end


mkpath("results/plaw_raes")
output_file = "results/plaw_raes/optimized_dynamic_stats.csv"
header = [
    "p_value", 
    "mean_diameter", "std_diameter", 
    "mean_apl", "std_apl", 
    "mean_global_clust", "std_global_clust",
    "mean_local_clust", "std_local_clust",
    "mean_max_betweenness", "std_max_betweenness"
]

open(output_file, "w") do io
    writedlm(io, reshape(header, 1, :), ',')
    writedlm(io, final_results_matrix, ',')
end

println("Dati salvati in: $output_file")
println("Fine esperimento: $(now())")