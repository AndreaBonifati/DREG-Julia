using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Graphs, Random, Statistics

function debug_cycle()
    N = 2^15 #
    D = 4
    C = 1.5
    rng = MersenneTwister(123)
    
    println(" Ciclo di debugging ERAES ")
    g = SimpleGraph(N)
    println("1. Grafo Iniziale: $(ne(g)) archi.")


    DynamicRandomExpanderGenerator.e_raes_step_one!(g, D; rng=rng)
    println("2. Dopo Step 1 (Round 1): $(ne(g)) archi. Min Deg: $(minimum(degree(g)))")
    
    if minimum(degree(g)) < D
        println(" Step 1 non ha raggiunto il grado target!")
        return
    end


    DynamicRandomExpanderGenerator.e_raes_step_three!(g, 1.0; rng=rng)
    println("3. Dopo Step 3 (p=1.0): $(ne(g)) archi.")

    deg_before = degree(g)
    println("4. Inizio Step 1 (Round 2). Gradi attuali: Min=$(minimum(deg_before)), Max=$(maximum(deg_before))")
    
    DynamicRandomExpanderGenerator.e_raes_step_one!(g, D; rng=rng)
    
    deg_after = degree(g)
    println("5. Dopo Step 1 (Round 2): $(ne(g)) archi.")
    println("   Min Deg: $(minimum(deg_after))")
    println("   Avg Deg: $(mean(deg_after))")
    println("   Connesso: $(is_connected(g))")

    if minimum(deg_after) == 0
        println("\n Il grado minimo è 0 dopo la ricostruzione ")
    else
        println("\n Il grafo si è ricostruito correttamente.")
    end
end


function debug_step2_crash()
    N = 4096 
    D = 4
    C = 1.5
    rng = MersenneTwister(123)
    
    println(" Debug step 2 (Pruning degli archi) ")
    g = SimpleGraph(N)
    

    DynamicRandomExpanderGenerator.e_raes_step_one!(g, D; rng=rng)
    println("1. Dopo Step 1: $(ne(g)) archi. Avg Deg: $(mean(degree(g))). Connesso: $(is_connected(g))")
    

    DynamicRandomExpanderGenerator.e_raes_step_two!(g, D, C; rng=rng)
    println("2. Dopo Step 2: $(ne(g)) archi. Avg Deg: $(mean(degree(g))). Connesso: $(is_connected(g))")
    
    if !is_connected(g)
        println("\n Lo Step 2 disconnette il grafo appena nato")
    else
        println("\nIl grafo ha resistito.")
    end
end

debug_step2_crash()

#debug_cycle()