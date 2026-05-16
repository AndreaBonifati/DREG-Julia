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

#  FUNZIONE SPECTRAL GAP LCC, Ritorna (Gap, Fraction_Nodes_in_LCC)
function analyze_lcc_properties(g_input::SimpleGraph{Int}) 
    n_total = nv(g_input)
    if n_total == 0 return (0.0, 0.0) end

    if !is_connected(g_input)
        comps = connected_components(g_input)
        if isempty(comps) return (0.0, 0.0) end
        

        largest_comp_nodes = comps[argmax(length.(comps))]
        lcc_size = length(largest_comp_nodes)
        lcc_fraction = lcc_size / n_total
        

        if lcc_size < 3
            return (0.0, lcc_fraction)
        end
        
        g, _ = induced_subgraph(g_input, largest_comp_nodes)
    else
        g = g_input
        lcc_fraction = 1.0
    end
    

    gap = 0.0
    try
        degs = degree(g)
        n = nv(g)
        if n >= 3 && !any(iszero, degs)
            A = adjacency_matrix(g, Float64)
            D_inv_sqrt = 1.0 ./ sqrt.(degs)
            function L_mul(x)
                tmp = D_inv_sqrt .* x
                Ax = A * tmp
                return x .- (D_inv_sqrt .* Ax)
            end
            op = (x -> L_mul(x))
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


const P_EDGE_VALUES = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5]

println("--- ESECUZIONE: LCC Gap + Size Analysis (k=$K_FIXED) ---")

struct SimTask
    p_val :: Float64
    run_idx :: Int
end

all_tasks = [SimTask(p, r) for p in P_EDGE_VALUES for r in 1:NUM_RUNS]
total_tasks = length(all_tasks)
progress = Atomic{Int}(0)

function run_lcc_sim(task)
    seed = 9999 + task.run_idx + Int(round(task.p_val * 1000))
    state = plaw_evraes_graph(N_START, seed, K_FIXED, D_DEFAULT, P_STD_FIXED)
    
    traj_gap = zeros(NUM_ROUNDS)
    traj_size = zeros(NUM_ROUNDS)
    
    for r in 1:NUM_ROUNDS
        n_old = plaw_ev_raes_step_zero!(state, 0.0)
        plaw_ev_raes_step_one!(state, n_old)
        plaw_ev_raes_step_two!(state, C_PARAM)
        plaw_ev_raes_step_three!(state, task.p_val)
        plaw_ev_raes_step_four!(state, 0.0)
        

        (gap, size_frac) = analyze_lcc_properties(state.g)
        traj_gap[r] = gap
        traj_size[r] = size_frac
    end
    
    curr = atomic_add!(progress, 1)
    if curr % 50 == 0 @info "Done $curr / $total_tasks" end
    
    return (task.p_val, traj_gap, traj_size)
end

results = ThreadsX.map(run_lcc_sim, all_tasks)


avg_gaps = Dict{Float64, Vector{Float64}}()
avg_sizes = Dict{Float64, Vector{Float64}}()
counts = Dict{Float64, Int}()

for p in P_EDGE_VALUES
    avg_gaps[p] = zeros(NUM_ROUNDS)
    avg_sizes[p] = zeros(NUM_ROUNDS)
    counts[p] = 0
end

for (p, g_traj, s_traj) in results
    avg_gaps[p] .+= g_traj
    avg_sizes[p] .+= s_traj
    counts[p] += 1
end

for p in P_EDGE_VALUES
    avg_gaps[p] ./= counts[p]
    avg_sizes[p] ./= counts[p]
end


results_folder = "results/plaw_evraes_LCC"
mkpath(results_folder)


open(joinpath(results_folder, "spectral_gap_LCC_edge_failure.csv"), "w") do io
    header = vcat("p_edge", ["round_$r" for r in 1:NUM_ROUNDS])
    writedlm(io, reshape(header, 1, :), ',')
    for p in P_EDGE_VALUES
        row = vcat(p, avg_gaps[p])
        writedlm(io, reshape(row, 1, :), ',')
    end
end


open(joinpath(results_folder, "network_size_LCC_edge_failure.csv"), "w") do io
    header = vcat("p_edge", ["round_$r" for r in 1:NUM_ROUNDS])
    writedlm(io, reshape(header, 1, :), ',')
    for p in P_EDGE_VALUES
        row = vcat(p, avg_sizes[p])
        writedlm(io, reshape(row, 1, :), ',')
    end
end

println("Finito. Risultati in $results_folder")