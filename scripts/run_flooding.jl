using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Random
using Graphs, GraphPlot, Colors, Plots, BenchmarkTools
using Printf

PARAMS = (n = 2^15, d = 4, c = 1.5, p = 0.9, rounds = 50, q = 0.9)

function test_eraes_flooding(n::Int, d::Int, c::Real, p::Real, rounds::Int; seed = 1)
    println("\n Avvio Test Flooding E-RAES")
    println("Parametri: n=$n, d=$d, c=$c, p=$p, rounds=$rounds")
    
    local g = SimpleGraph(n)
    local rng = MersenneTwister(seed)


    local active_nodes = trues(n) 
    local all_informed = falses(n)

    local starter_node = rand(rng, 1:n)
    all_informed[starter_node] = true
    @printf("Round 0: Nodo iniziale %d. Informati: 1 / %d\n", starter_node, n)

    for r in 1:rounds
        

        e_raes_step_one!(g, d; rng=rng)
        e_raes_step_two!(g, d, c; rng=rng)
        e_raes_step_three!(g, p; rng=rng)

        flooding_step!(all_informed, g, active_nodes)

  
        current_informed_count = count(all_informed)
        @printf("Round %d: Informati %d / %d nodi\n", r, current_informed_count, n)
        if r < 6
            println("\n   [Debug Dettagliato Round $r]")
            
            informed_list = findall(all_informed)
            sort!(informed_list) 
            
            println("   Lista Nodi Informati: ", informed_list)
            println("   Dettaglio Vicinato (sul grafo attuale):")
            
            for u in informed_list
                current_neighbors = sort(collect(neighbors(g, u)))
                @printf("     - Nodo %d -> Vicini: %s\n", u, current_neighbors)
            end
            println("   [Fine Debug Dettagliato Round $r]")
        end

   
        if current_informed_count == n
            println("Flooding E-RAES Completo")
            break
        end
    end
end

function test_vraes_flooding(n::Int, d::Int, c::Real, q::Real, rounds::Int; seed = 12)
    println("\n Avvio Test Flooding V-RAES ")
    println("Parametri: n=$n, d=$d, c=$c, q=$q, rounds=$rounds")


    local state = vraes_graph(n, seed)
    local rng = state.rng
    local lambda = n * q 
    #local lambda = (n * q) / (1 - q)


    local starter_node = rand(rng, 1:n)
    state.informed_nodes[starter_node] = true
    
    n_attivi_iniziali = count(state.active_nodes)
    @printf("Round 0: Nodo iniziale %d. Informati: 1 / %d\n", starter_node, n_attivi_iniziali)
    

    println("-------------------------------------------------------------------------------------------------")
    @printf("%-6s | %-12s | %-12s | %-16s | %-10s\n", "Round", "Nodi Inizio", "Nodi Post-S0", "Nodi Attivi (Fine)", "Informati")
    println("-------------------------------------------------------------------------------------------------")



    for r in 1:rounds
        
        local nodi_inizio_round = count(state.active_nodes)


        n_old = v_raes_step_zero!(state, lambda)
        
        local nodi_post_step0 = count(state.active_nodes)


        v_raes_step_one!(state, d, n_old)
        v_raes_step_two!(state, d, c)
        
        v_raes_step_three!(state, q) 

        flooding_step!(state.informed_nodes, state.g, state.active_nodes)


        local current_informed_count = count(state.informed_nodes)

        local current_active_count = count(state.active_nodes) 
        
        @printf("%-6d | %-12d | %-12d | %-16d | %-10d\n", 
                r, nodi_inizio_round, nodi_post_step0, current_active_count, current_informed_count)


        if current_active_count > 0 && current_informed_count == current_active_count
            println("Flooding V-RAES Completo")
            break
        elseif current_active_count == 0
            println("Flooding Fallito: Rete vuota")
            break
        elseif current_informed_count == 0
             println("Flooding Fallito: Tutti i nodi informati sono morti")
             break
        end
    end
end



#test_eraes_flooding(PARAMS.n, PARAMS.d, PARAMS.c, PARAMS.p, PARAMS.rounds)

test_vraes_flooding(PARAMS.n, PARAMS.d, PARAMS.c, PARAMS.q, PARAMS.rounds)