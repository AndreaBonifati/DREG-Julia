using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Printf
using Graphs
using Random
using KrylovKit
using Statistics

println("Esecuzione di debug (Singola run) - Classical ERAES ")

const PARAMS = (
    n = 2^15,
    d = 4,
    c = 3,
    p = 0.5,
    rounds = 100
)



function run_debug_experiment(params)
    local g = SimpleGraph(params.n)
    local rng = MersenneTwister(123) 

    println("Round | Archi Iniziali | Nodi < d (Pre 1) | Nodi < d (Post 1)| Nodi > c*d (Pre 2)| Archi Post-S1/2 | Nodi < d (Post 2) | Nodi > c*d (Post 2)| Connected |Spectral gap |Archi Finali")
    println("------|----------------|------------------|------------------|-------------------|-----------------|-------------------|--------------------|-----------|--------------|-------------")
    #println("Round | Archi Iniziali | Nodi < d (Pre 1) | Nodi < d (Post 1)| Nodi > c*d (Pre 2)| Archi Post-S1/2 | Nodi < d (Post 2) | Nodi > c*d (Post 2)| Connected | Archi Finali")
    #println("------|----------------|------------------|------------------|-------------------|-----------------|-------------------|--------------------|-----------|-------------")
    for r in 1:params.rounds

        archi_iniziali = ne(g)
        nodi_sotto_d_pre_s1 = count(<(params.d), degree(g))


        DynamicRandomExpanderGenerator.e_raes_step_one!(g, params.d; rng=rng)
        #DynamicRandomExpanderGenerator.check_degree(g, params.d)
        nodi_sotto_d_post_s1 = count(<(params.d), degree(g))
        nodi_sopra_cd_post_s1 = count(>(params.c * params.d), degree(g))
        DynamicRandomExpanderGenerator.e_raes_step_two!(g, params.d, params.c; rng=rng)
        deg = degree(g)
        avg_deg = mean(deg)
        #println("Round $r: Min Deg: $(minimum(deg)), Avg Deg: $avg_deg, Connected: $(is_connected(g))")

        archi_post_s12 = ne(g)
        nodi_sopra_cd_post_s2 = count(>(params.c * params.d), degree(g))
        nodi_sotto_d_post_s2 = count(<(params.d), degree(g))
        #println("Connected? ", is_connected(g))
        #println("Min degree: ", minimum(degree(g)))
        connected = is_connected(g)

        gap = DynamicRandomExpanderGenerator.spectral_gap(g)
        


        DynamicRandomExpanderGenerator.e_raes_step_three!(g, params.p; rng=rng)
        

        archi_finali = ne(g)
        
  
        @printf("%5d | %14d | %16d | %16d | %17d | %15d | %17d | %18d | %9s | %12f | %12d\n", r, archi_iniziali, nodi_sotto_d_pre_s1, nodi_sotto_d_post_s1, nodi_sopra_cd_post_s1, archi_post_s12, nodi_sotto_d_post_s2, nodi_sopra_cd_post_s2, string(connected), gap, archi_finali)
        #@printf("%5d | %14d | %16d | %16d | %17d | %15d | %17d | %18d | %9s | %12d\n", r, archi_iniziali, nodi_sotto_d_pre_s1, nodi_sotto_d_post_s1, nodi_sopra_cd_post_s1, archi_post_s12, nodi_sotto_d_post_s2, nodi_sopra_cd_post_s2, string(connected), archi_finali)
    end
end

run_debug_experiment(PARAMS)