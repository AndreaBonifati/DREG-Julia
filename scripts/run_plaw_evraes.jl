using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Printf
using Graphs
using Random
using Distributions
using StatsBase
using Statistics

function count_active_edges(g::SimpleGraph, active::BitVector)
    s = 0
    for u in findall(active)
        for v in neighbors(g, u)
            if v <= length(active) && active[v] && u < v 
                s += 1
            end
        end
    end
    return s
end

function count_plaw_metrics_active(state::plaw_evraes_graph, c::Real)
    g = state.g
    targets = state.target_degrees
    sotto_d_u = 0
    sopra_cd_u = 0
    current_degrees = degree(g)
    
    for u in findall(state.active_nodes)
        if !haskey(targets, u)
            @warn "Nodo attivo $u non ha un grado target!"
            continue
        end
        
        deg_u = current_degrees[u]
        d_u = targets[u]
        max_deg_u = ceil(Int, d_u * c)
        
        if deg_u < d_u
            sotto_d_u += 1
        end
        if deg_u > max_deg_u
            sopra_cd_u += 1
        end
    end
    return (sotto_d_u, sopra_cd_u)
end

const PARAMS = (
    n = 2^15,
    d_default = 4,
    c = 3.0,
    p = 0.1,    
    q = 0.1,    
    rounds = 30,
    k = 2.0,
    prob_default = 0.5,
    prob_downscale = 0.4,
    prob_upscale = 0.1,
    min_d = 2
)

function run_debug_experiment_plaw_evraes(params)
    
    local state = plaw_evraes_graph(
        params.n, 123, params.k, params.d_default, 
        params.prob_default, params.prob_downscale, 
        params.prob_upscale, params.min_d
    )
    
 
    local lambda = (params.n * params.q) / (1.0 - params.q)

    println("Stato iniziale: Nodi=$(count(state.active_nodes)), Lambda=$(round(lambda, digits=2))")
    

    all_target_degrees = values(state.target_degrees)
    d_def = params.d_default
    count_down = count(d -> d < d_def, all_target_degrees)
    count_default = count(d -> d == d_def, all_target_degrees)
    count_up = count(d -> d > d_def, all_target_degrees)
    @printf("Distribuzione Gradi: Down=%.1f%%, Default=%.1f%%, Up=%.1f%%\n",
            100*count_down/params.n, 100*count_default/params.n, 100*count_up/params.n)
    
    println("-"^160)
    @printf("%-5s | %-9s | %-10s | %-10s | %-10s | %-11s | %-11s | %-12s | %-10s | %-11s | %-9s | %-12s | %-9s | %-10s\n",
            "Round", "N_Start", "N_Post_S0", "Archi_Start", "Nodi < d_u", "Nodi < d_u", "Archi_Post_S1", "Nodi > c*d_u", "Archi_Post_S2", "Nodi < d_u", "Nodi > c*d_u", "Archi_Post_S3", "N_End", "Archi_End")
    @printf("%-5s | %-9s | %-10s | %-10s | %-10s | %-11s | %-11s | %-12s | %-10s | %-11s | %-9s | %-12s | %-9s | %-10s\n",
            "", "(S0)", "(S0)", "(S1)", "(Pre S1)", "(Post S1)", "(S1)", "(Pre S2)", "(S2)", "(Post S2)", "(Post S2)", "(S3)", "(S4)", "(S4)")
    println("-"^160)


    for r in 1:params.rounds

        nodi_attivi = count(state.active_nodes)
        archi_attivi = count_active_edges(state.g, state.active_nodes)
        (nodi_sotto_d_pre_s1, _) = count_plaw_metrics_active(state, params.c)

   
        n_old = plaw_ev_raes_step_zero!(state, lambda)
        nodi_post_step0 = count(state.active_nodes)


        plaw_ev_raes_step_one!(state, n_old)
        (nodi_sotto_d_post_s1, nodi_sopra_cd_pre_s2) = count_plaw_metrics_active(state, params.c)
        archi_post_s1 = count_active_edges(state.g, state.active_nodes)


        plaw_ev_raes_step_two!(state, params.c)
        archi_post_s2 = count_active_edges(state.g, state.active_nodes)
        (nodi_sotto_d_post_s2, nodi_sopra_cd_post_s2) = count_plaw_metrics_active(state, params.c)


        plaw_ev_raes_step_three!(state, params.p)
        archi_post_s3 = count_active_edges(state.g, state.active_nodes)

        plaw_ev_raes_step_four!(state, params.q)
        nodi_post_s4 = count(state.active_nodes)
        archi_post_s4 = count_active_edges(state.g, state.active_nodes)


        @printf("%-5d | %-9d | %-10d | %-10d | %-10d | %-11d | %-11d | %-12d | %-10d | %-11d | %-9d | %-12d | %-9d | %-10d\n",
                r, nodi_attivi, nodi_post_step0, archi_attivi,
                nodi_sotto_d_pre_s1, nodi_sotto_d_post_s1, archi_post_s1,
                nodi_sopra_cd_pre_s2, archi_post_s2, nodi_sotto_d_post_s2,
                nodi_sopra_cd_post_s2, archi_post_s3, nodi_post_s4, archi_post_s4)
                
        if nodi_post_s4 == 0
            println("Rete vuota, simulazione interrotta.")
            break
        end
    end
end


run_debug_experiment_plaw_evraes(PARAMS)