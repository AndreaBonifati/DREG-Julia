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
using LinearAlgebra
using Base.Threads: Atomic, atomic_add!

BLAS.set_num_threads(1)

# FUNZIONE ANALISI LCC (Adattata per Active Nodes) 
function analyze_lcc_churn(state)
    g_input = state.g
    active_mask = state.active_nodes
    

    active_indices = findall(active_mask)
    n_active = length(active_indices)
    
    if n_active < 2 return (0.0, 0.0) end


    subgraph, _ = induced_subgraph(g_input, active_indices)
    
    if !is_connected(subgraph)
        comps = connected_components(subgraph)
        if isempty(comps) return (0.0, 0.0) end
        
        largest_comp = comps[argmax(length.(comps))]
        lcc_size = length(largest_comp)
        
        lcc_fraction = lcc_size / n_active
        
        if lcc_size < 3
            return (0.0, lcc_fraction)
        end
        
        g_lcc, _ = induced_subgraph(subgraph, largest_comp)
    else
        g_lcc = subgraph
        lcc_fraction = 1.0
    end
    
    gap = 0.0
    try
        n = nv(g_lcc)
        degs = degree(g_lcc)
        if n >= 3 && !any(iszero, degs)
            A = adjacency_matrix(g_lcc, Float64)
            D_inv_sqrt = 1.0 ./ sqrt.(degs)
            op = x -> x .- (D_inv_sqrt .* (A * (D_inv_sqrt .* x)))
            vals, _, _ = eigsolve(op, n, 2, :SR; tol=1e-5, maxiter=500)
            gap = real(vals[2])
        end
    catch
        gap = 0.0
    end
    
    return (gap, lcc_fraction)
end


const N_START = 2^15
const D_DEFAULT = 4
const C_PARAM = 3.0
const K_FIXED = 2.0
const P_STD_FIXED = 0.0
const NUM_RUNS = 50       
const NUM_ROUNDS = 100


const Q_NODE_VALUES = [0.0, 0.005, 0.01, 0.05, 0.1, 0.2, 0.3]

println("--- ESECUZIONE: LCC Gap + Size Analysis per Node Churn (k=$K_FIXED) ---")

struct SimTask
    q_val :: Float64
    run_idx :: Int
end

all_tasks = [SimTask(q, r) for q in Q_NODE_VALUES for r in 1:NUM_RUNS]
total_tasks = length(all_tasks)
progress = Atomic{Int}(0)

function run_lcc_churn(task)
    seed = 9999 + task.run_idx + Int(round(task.q_val * 100000))
    state = plaw_evraes_graph(N_START, seed, K_FIXED, D_DEFAULT, P_STD_FIXED)
    
    lambda_val = N_START * task.q_val
    
    traj_gap = zeros(NUM_ROUNDS)
    traj_size = zeros(NUM_ROUNDS)
    
    for r in 1:NUM_ROUNDS
        n_old = plaw_ev_raes_step_zero!(state, lambda_val)
        plaw_ev_raes_step_one!(state, n_old)
        plaw_ev_raes_step_two!(state, C_PARAM)
        plaw_ev_raes_step_three!(state, 0.0) 
        plaw_ev_raes_step_four!(state, task.q_val)
        

        (gap, size_frac) = analyze_lcc_churn(state)
        traj_gap[r] = gap
        traj_size[r] = size_frac
    end
    
    curr = atomic_add!(progress, 1)
    if curr % 50 == 0 @info "Done $curr / $total_tasks" end
    
    return (task.q_val, traj_gap, traj_size)
end

results = ThreadsX.map(run_lcc_churn, all_tasks)


avg_gaps = Dict{Float64, Vector{Float64}}()
avg_sizes = Dict{Float64, Vector{Float64}}()
counts = Dict{Float64, Int}()

for q in Q_NODE_VALUES
    avg_gaps[q] = zeros(NUM_ROUNDS)
    avg_sizes[q] = zeros(NUM_ROUNDS)
    counts[q] = 0
end

for (q, g_traj, s_traj) in results
    avg_gaps[q] .+= g_traj
    avg_sizes[q] .+= s_traj
    counts[q] += 1
end

for q in Q_NODE_VALUES
    avg_gaps[q] ./= counts[q]
    avg_sizes[q] ./= counts[q]
end


results_folder = "results/plaw_evraes_LCC"
mkpath(results_folder)

open(joinpath(results_folder, "spectral_gap_LCC_churn.csv"), "w") do io
    header = vcat("q_node", ["round_$r" for r in 1:NUM_ROUNDS])
    writedlm(io, reshape(header, 1, :), ',')
    for q in Q_NODE_VALUES
        row = vcat(q, avg_gaps[q])
        writedlm(io, reshape(row, 1, :), ',')
    end
end

open(joinpath(results_folder, "network_size_LCC_churn.csv"), "w") do io
    header = vcat("q_node", ["round_$r" for r in 1:NUM_ROUNDS])
    writedlm(io, reshape(header, 1, :), ',')
    for q in Q_NODE_VALUES
        row = vcat(q, avg_sizes[q])
        writedlm(io, reshape(row, 1, :), ',')
    end
end

println("Finito. Risultati in $results_folder")