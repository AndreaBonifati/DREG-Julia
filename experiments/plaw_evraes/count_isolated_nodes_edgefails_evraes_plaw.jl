using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Graphs
using Random
using Distributions
using Statistics
using DelimitedFiles
using ThreadsX
# ESPERIMENTO FATTO PER MOSTRARE CHE CI SONO NODI DISTACCATI E PER TALE MOTIVO SI ANALIZZA LA LCC

const N = 2^15
const D = 4
const C = 3.0
const K = 2.0
const P_STD = 0.0


const P_EDGE_VALUES = [0.0, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.5]
const NUM_RUNS = 20  
const NUM_ROUNDS = 50 

println("--- DIAGNOSTICA: Analisi Frammentazione (Nodi Isolati) ---")

struct DiagnosticTask
    p_val :: Float64
    run_idx :: Int
end

all_tasks = [DiagnosticTask(p, r) for p in P_EDGE_VALUES for r in 1:NUM_RUNS]

function run_diagnostic(task)
    seed = 12345 + task.run_idx + Int(round(task.p_val * 1000))

    state = plaw_evraes_graph(N, seed, K, D, P_STD)
    

    isolated_fraction = Vector{Float64}(undef, NUM_ROUNDS)
    
    for r in 1:NUM_ROUNDS

        n_old = plaw_ev_raes_step_zero!(state, 0.0) 
        plaw_ev_raes_step_one!(state, n_old)
        plaw_ev_raes_step_two!(state, C)
        plaw_ev_raes_step_three!(state, task.p_val) 
        plaw_ev_raes_step_four!(state, 0.0)
        

        degs = degree(state.g)
        num_isolated = count(==(0), degs)
        isolated_fraction[r] = num_isolated / nv(state.g)
    end
    return (task.p_val, isolated_fraction)
end

results = ThreadsX.map(run_diagnostic, all_tasks)


avg_isolation = Dict{Float64, Vector{Float64}}()
for p in P_EDGE_VALUES
    avg_isolation[p] = zeros(NUM_ROUNDS)
end
counts = Dict{Float64, Int}()
for p in P_EDGE_VALUES counts[p] = 0 end

for (p, traj) in results
    avg_isolation[p] .+= traj
    counts[p] += 1
end

for p in P_EDGE_VALUES
    avg_isolation[p] ./= counts[p]
end


mkpath("results/diagnostics")
open("results/diagnostics/isolated_nodes_percentage.csv", "w") do io
    header = vcat("p_edge", ["round_$r" for r in 1:NUM_ROUNDS])
    writedlm(io, reshape(header, 1, :), ',')
    for p in P_EDGE_VALUES
        row = vcat(p, avg_isolation[p])
        writedlm(io, reshape(row, 1, :), ',')
    end
end
println("Diagnostica salvata in results/diagnostics/isolated_nodes_percentage.csv")