function compare_methods()
    g = SimpleGraph(PARAMS.n)
    rng = MersenneTwister(123)

    println("Inizio simulazione su $PARAMS.rounds round...")
    println("-------------------------------------------")

    for r in 1:PARAMS.rounds
        e_raes_step_one!(g, PARAMS.d; rng=rng)
        check_and_print(g, r, "Step 1")

        e_raes_step_two!(g, PARAMS.d, PARAMS.c; rng=rng)
        check_and_print(g, r, "Step 2")

        e_raes_step_three!(g, PARAMS.p; rng=rng)
        check_and_print(g, r, "Step 3")
        
        println("Round $r completato.")
    end
end

function check_and_print(g, round, step)
    if !is_connected(g)
        @warn "Grafo NON CONNESSO al Round $round - dopo $step"
    else
        println("Round $round ($step): Connesso")
    end
end