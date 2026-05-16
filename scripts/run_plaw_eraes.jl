using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Printf
using Graphs
using Random
using KrylovKit
using Statistics
using Distributions

println("Esecuzione di debug (Singola run) - Power Law ERAES ")

const PARAMS = (
    n = 2^15, 
    d_default = 4,
    c = 3.0,
    p = 0.1,
    rounds = 50,

    k = 2.0,
    prob_default = 0.5,
    prob_downscale = 0.4,
    prob_upscale = 0.1,
    min_d = 2
)


function count_plaw_metrics(state::plaw_eraes_graph, c::Real)
    g = state.g
    targets = state.target_degrees
    n = nv(g)
    
    sotto_d_u = 0
    sopra_cd_u = 0
    
    current_degrees = degree(g) 
    
    for u in 1:n
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


function run_debug_experiment_plaw(params)
    

    local state = plaw_eraes_graph(
        params.n, 123, params.k, params.d_default, 
        params.prob_default, params.prob_downscale, 
        params.prob_upscale, params.min_d
    )

    local g = state.g
    local c = params.c
    local p = params.p


    println("Distribuzione gradi target generata (primi 20 nodi):")
    println(state.target_degrees[1:20])

    all_target_degrees = values(state.target_degrees)
    d_def = params.d_default
    

    count_down = count(d -> d < d_def, all_target_degrees)
    count_default = count(d -> d == d_def, all_target_degrees)
    count_up = count(d -> d > d_def, all_target_degrees)
    
    @printf("   - Nodi Downscale (< %d): %d (%.1f%%)\n", d_def, count_down, 100 * count_down / params.n)
    @printf("   - Nodi Default   (== %d): %d (%.1f%%)\n", d_def, count_default, 100 * count_default / params.n)
    @printf("   - Nodi Upscale   (> %d): %d (%.1f%%)\n", d_def, count_up, 100 * count_up / params.n)

    println("-"^143)

    println("\nRound | Archi Iniziali | Nodi < d_u | Nodi < d_u | Nodi > c*d_u| Archi Post-S1/2 | Nodi < d_u | Nodi > c*d_u| Connected |Spectral gap |Archi Finali")
    println("      |                | (Pre S1)   | (Post S1)  | (Post S1)   |                 | (Post S2)  | (Post S2)   |           |             |            ")
    println("------|----------------|------------|------------|-------------|-----------------|------------|-------------|-----------|-------------|------------")
    
    for r in 1:params.rounds

        archi_iniziali = ne(g)
        (nodi_sotto_d_pre_s1, _) = count_plaw_metrics(state, c)


        plaw_e_raes_step_one!(state)
        (nodi_sotto_d_post_s1, nodi_sopra_cd_post_s1) = count_plaw_metrics(state, c)
        
        plaw_e_raes_step_two!(state, c)
        

        archi_post_s12 = ne(g)
        (nodi_sotto_d_post_s2, nodi_sopra_cd_post_s2) = count_plaw_metrics(state, c)
        
        connected = is_connected(g)
        gap = spectral_gap(g) 
        

        plaw_e_raes_step_three!(state, p)
        

        archi_finali = ne(g)

        @printf("%5d | %14d | %10d | %10d | %11d | %15d | %10d | %11d | %9s | %11.5f | %11d\n", 
                r, archi_iniziali, nodi_sotto_d_pre_s1, 
                nodi_sotto_d_post_s1, nodi_sopra_cd_post_s1, 
                archi_post_s12, 
                nodi_sotto_d_post_s2, nodi_sopra_cd_post_s2, 
                string(connected), gap, archi_finali)
    end
end

run_debug_experiment_plaw(PARAMS)