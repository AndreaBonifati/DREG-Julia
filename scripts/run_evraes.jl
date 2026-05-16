using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Printf
using Graphs
using Random
using KrylovKit

println("Esecuzione di debug (Singola run) - Classical EVRAES")

const PARAMS = (
    n = 2^15,
    d = 4,
    c = 1.5,
    q = 0.1,
    p = 0.1,
    rounds = 30
)

function count_active_edges(g::SimpleGraph, active::BitVector)
    s = 0
    for u in vertices(g)
        if active[u]
            for v in neighbors(g, u)
                if active[v] && u < v  
                    s += 1
                end
            end
        end
    end
    return s
end

function run_debug_experiment(params)
    state = evraes_graph(params.n, 123)
    λ = Float64(params.q * params.n)


    

    println("Round | Nodi Attivi | Nodi Post step 0 | Archi Attivi | Nodi < d (Pre 1) | Nodi < d (Post 1) | Archi Post-S1 | Nodi > c*d (Pre 2) | Archi Post-S2 | Nodi < d (Post 2) | Nodi > c*d (Post 2) | Archi Post 3  | Nodi Post 4 | Archi Post 4")
    println("------|-------------|------------------|--------------|------------------|-------------------|---------------|--------------------|---------------|-------------------|---------------------|---------------|-------------|-------------")

    for r in 1:params.rounds
 
        nodi_attivi = count(state.active_nodes)
        archi_attivi = count_active_edges(state.g, state.active_nodes)

        n_old = ev_raes_step_zero!(state, λ)
        nodi_post_step0 = count(state.active_nodes)

        nodi_sotto_d_pre_s1 = count(<(params.d), [degree(state.g, u) for u in vertices(state.g) if state.active_nodes[u]])
        ev_raes_step_one!(state, params.d, n_old)
        nodi_sotto_d_post_s1 = count(<(params.d), [degree(state.g, u) for u in vertices(state.g) if state.active_nodes[u]])
        nodi_sopra_cd_post_s1 = count(>(params.c*params.d), [degree(state.g, u) for u in vertices(state.g) if state.active_nodes[u]])
        archi_post_s1 = count_active_edges(state.g, state.active_nodes)

        ev_raes_step_two!(state, params.d, params.c)
        archi_post_s2 = count_active_edges(state.g, state.active_nodes)
        nodi_sopra_cd_post_s2 = count(>(params.c*params.d), [degree(state.g, u) for u in vertices(state.g) if state.active_nodes[u]])
        nodi_sotto_d_post_s2 = count(<(params.d), [degree(state.g, u) for u in vertices(state.g) if state.active_nodes[u]])

        ev_raes_step_three!(state, params.p)
        archi_post_s3 = count_active_edges(state.g, state.active_nodes)

        ev_raes_step_four!(state, params.q)
        nodi_post_s4 = count(state.active_nodes)
        archi_post_s4 = count_active_edges(state.g, state.active_nodes)

        @printf("%5d | %11d | %16d | %12d | %16d | %17d | %13d | %18d | %13d | %17d | %19d | %13d | %11d | %12d \n",
                r, nodi_attivi, nodi_post_step0, archi_attivi,
                nodi_sotto_d_pre_s1, nodi_sotto_d_post_s1, archi_post_s1,
                nodi_sopra_cd_post_s1, archi_post_s2, nodi_sotto_d_post_s2,
                nodi_sopra_cd_post_s2, archi_post_s3, nodi_post_s4, archi_post_s4)
    end
end

run_debug_experiment(PARAMS)