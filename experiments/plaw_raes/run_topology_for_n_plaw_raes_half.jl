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


function compute_dominance_metric(g::SimpleGraph)
    n = nv(g)
    if n == 0 return 0.0 end
    
    degs = degree(g)
    sorted_degs = sort(degs, rev=true)
    
    top_1_percent_idx = max(1, round(Int, n * 0.01))
    edges_top_1 = sum(sorted_degs[1:top_1_percent_idx])
    total_edges_volume = sum(degs)
    
    if total_edges_volume == 0 return 0.0 end
    
    return (edges_top_1 / total_edges_volume) * 100.0
end


function compute_assortativity_metric(g::SimpleGraph)
    val = assortativity(g)
    return isnan(val) ? 0.0 : val
end


function estimated_diameter_percent(g::SimpleGraph, sample_percent::Float64)
    if !is_connected(g)
        comps = connected_components(g)
        largest = comps[argmax(length.(comps))]
        g_calc, _ = induced_subgraph(g, largest)
    else
        g_calc = g
    end
    
    n = nv(g_calc)
    if n < 2 return 0.0 end
    
    num_samples = max(1, round(Int, n * sample_percent))
    num_samples = min(num_samples, 500) # Safety cap 
    
    sources = sample(1:n, num_samples, replace=false)
    max_d = 0
    
    for s in sources
        dists = gdistances(g_calc, s)

        valid = filter(x -> x < n, dists)
        if !isempty(valid)
            max_d = max(max_d, maximum(valid))
        end
    end
    return Float64(max_d)
end



const D_FIXED = 4
const C_FIXED = 3.0
const P_FIXED = 0.5      
const K_FIXED = 2.0      
const NUM_ROUNDS = 100    
const NUM_RUNS = 50      


const DIAM_SAMPLE_PCT = 0.1 


const N_VALUES = [2^i for i in 7:16]

println("--- SCALING ANALYSIS PLAW RAES (Static) ---")
println("N Range: $(minimum(N_VALUES)) -> $(maximum(N_VALUES))")
println("Threads: $(Threads.nthreads())")

struct ScalingTask
    n_val   :: Int
    run_idx :: Int
end

all_tasks = ScalingTask[]
for n in N_VALUES
    for r in 1:NUM_RUNS
        push!(all_tasks, ScalingTask(n, r))
    end
end
total_tasks = length(all_tasks)
progress_cnt = Atomic{Int}(0)

function execute_task(task::ScalingTask)
    n = task.n_val
    seed = 99999 + task.run_idx + n 
    
    state = plaw_raes_graph(n, seed, K_FIXED, D_FIXED, P_FIXED)
    
    for _ in 1:NUM_ROUNDS
        plaw_raes_step_one!(state)
        plaw_raes_step_two!(state, C_FIXED)
    end
    

    gap = spectral_gap(state.g)
    dom = compute_dominance_metric(state.g)
    assort = compute_assortativity_metric(state.g)
    diam = estimated_diameter_percent(state.g, DIAM_SAMPLE_PCT)
    
    c = atomic_add!(progress_cnt, 1)
    if c % 20 == 0 || c == total_tasks
        @info "Completed $c / $total_tasks tasks."
    end
    
    return (n, [gap, dom, assort, diam])
end

println("Avvio microtask...")
results_raw = ThreadsX.map(execute_task, all_tasks)



agg_data = Dict{Int, Vector{Vector{Float64}}}()
for n in N_VALUES
    agg_data[n] = Vector{Float64}[]
end

for (n, metrics) in results_raw
    push!(agg_data[n], metrics)
end

output_matrix = Matrix{Float64}(undef, length(N_VALUES), 5)

for (i, n) in enumerate(N_VALUES)
    metrics_coll = agg_data[n]

    mat = reduce(hcat, metrics_coll)

    means = vec(mean(mat, dims=2))
    
    output_matrix[i, 1] = Float64(n)
    output_matrix[i, 2:5] = means
end


res_dir = "results/plaw_raes"
mkpath(res_dir)
fname = joinpath(res_dir, "scaling_metrics_k$(K_FIXED)_metrics_half_nodes.csv")

open(fname, "w") do io

    header = ["N", "SpectralGap", "HubDominance", "Assortativity", "Diameter"]
    writedlm(io, reshape(header, 1, :), ',')
    writedlm(io, output_matrix, ',')
end
