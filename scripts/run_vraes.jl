using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Printf
using Graphs
using Random
using KrylovKit

println("Esecuzione di debug (Singola run) - Classical VRAES ")

const PARAMS = (
    n = 2^15,
    d = 4,
    c = 1.5,
    q = 0.5,
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
    state = vraes_graph(params.n, 123)
    λ = Float64(params.q * params.n)

    

    println("Round | Nodi Attivi | Nodi Post step 0 | Archi Attivi | Nodi < d (Pre 1) | Nodi < d (Post 1) | Archi Post-S1 | Nodi > c*d (Pre 2) | Archi Post-S2 | Nodi < d (Post 2) | Nodi > c*d (Post 2) | Nodi Post 3 | Archi Post 3")
    println("------|-------------|------------------|--------------|------------------|-------------------|---------------|--------------------|---------------|-------------------|---------------------|-------------|-------------")

    for r in 1:params.rounds
        nodi_attivi = count(state.active_nodes)
        archi_attivi = count_active_edges(state.g, state.active_nodes)


        n_old = v_raes_step_zero!(state, λ)
        nodi_post_step0 = count(state.active_nodes)

        nodi_sotto_d_pre_s1 = count(<(params.d), [degree(state.g, u) for u in vertices(state.g) if state.active_nodes[u]])
        v_raes_step_one!(state, params.d, n_old)
        nodi_sotto_d_post_s1 = count(<(params.d), [degree(state.g, u) for u in vertices(state.g) if state.active_nodes[u]])
        nodi_sopra_cd_post_s1 = count(>(params.c*params.d), [degree(state.g, u) for u in vertices(state.g) if state.active_nodes[u]])
        archi_post_s1 = count_active_edges(state.g, state.active_nodes)

        v_raes_step_two!(state, params.d, params.c)
        archi_post_s2 = count_active_edges(state.g, state.active_nodes)
        nodi_sopra_cd_post_s2 = count(>(params.c*params.d), [degree(state.g, u) for u in vertices(state.g) if state.active_nodes[u]])
        nodi_sotto_d_post_s2 = count(<(params.d), [degree(state.g, u) for u in vertices(state.g) if state.active_nodes[u]])

        v_raes_step_three!(state, params.q)
        nodi_post_s3 = count(state.active_nodes)
        archi_post_s3 = count_active_edges(state.g, state.active_nodes)

        @printf("%5d | %11d | %16d | %12d | %16d | %17d | %13d | %18d | %13d | %17d | %19d | %11d | %12d \n",
                r, nodi_attivi, nodi_post_step0, archi_attivi,
                nodi_sotto_d_pre_s1, nodi_sotto_d_post_s1, archi_post_s1,
                nodi_sopra_cd_post_s1, archi_post_s2, nodi_sotto_d_post_s2,
                nodi_sopra_cd_post_s2, nodi_post_s3, archi_post_s3)
    end
end

run_debug_experiment(PARAMS)