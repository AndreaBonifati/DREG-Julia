using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Graphs
using Random
using Distributions
using Statistics
using DelimitedFiles
using ThreadsX


const N = 2^15
const D = 4
const C = 3.0
const K = 2.0
const P_STD = 0.0


const Q_NODE_VALUES = [0.0, 0.005, 0.01, 0.05, 0.1, 0.2, 0.3]
const NUM_RUNS = 20
const NUM_ROUNDS = 50 

println("--- DIAGNOSTICA CHURN: Analisi Isolamento Nodi Vivi ---")

struct DiagnosticTask
    q_val :: Float64
    run_idx :: Int
end

all_tasks = [DiagnosticTask(q, r) for q in Q_NODE_VALUES for r in 1:NUM_RUNS]

function run_diagnostic_churn(task)
    seed = 12345 + task.run_idx + Int(round(task.q_val * 10000))
    state = plaw_evraes_graph(N, seed, K, D, P_STD)
    

    lambda_val = N * task.q_val
    
    isolated_fraction = Vector{Float64}(undef, NUM_ROUNDS)
    
    for r in 1:NUM_ROUNDS
        n_old = plaw_ev_raes_step_zero!(state, lambda_val)
        plaw_ev_raes_step_one!(state, n_old)
        plaw_ev_raes_step_two!(state, C)
        plaw_ev_raes_step_three!(state, 0.0) 
        plaw_ev_raes_step_four!(state, task.q_val)
        

        degs = degree(state.g)
        num_isolated_active = 0
        num_active = 0
        
        for u in 1:length(state.active_nodes)
            if state.active_nodes[u]
                num_active += 1
                if u > length(degs) || degs[u] == 0
                    num_isolated_active += 1
                end
            end
        end
        
        if num_active > 0
            isolated_fraction[r] = num_isolated_active / num_active
        else
            isolated_fraction[r] = 0.0
        end
    end
    return (task.q_val, isolated_fraction)
end

results = ThreadsX.map(run_diagnostic_churn, all_tasks)


avg_isolation = Dict{Float64, Vector{Float64}}()
for q in Q_NODE_VALUES
    avg_isolation[q] = zeros(NUM_ROUNDS)
end
counts = Dict{Float64, Int}()
for q in Q_NODE_VALUES counts[q] = 0 end

for (q, traj) in results
    avg_isolation[q] .+= traj
    counts[q] += 1
end

for q in Q_NODE_VALUES
    avg_isolation[q] ./= counts[q]
end


mkpath("results/diagnostics")
open("results/diagnostics/isolated_nodes_churn.csv", "w") do io
    header = vcat("q_node", ["round_$r" for r in 1:NUM_ROUNDS])
    writedlm(io, reshape(header, 1, :), ',')
    for q in Q_NODE_VALUES
        row = vcat(q, avg_isolation[q])
        writedlm(io, reshape(row, 1, :), ',')
    end
end
println("Diagnostica salvata in results/diagnostics/isolated_nodes_churn.csv")