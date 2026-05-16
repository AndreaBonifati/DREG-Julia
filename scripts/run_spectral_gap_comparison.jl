using Pkg; Pkg.activate(".")
using DynamicRandomExpanderGenerator
using Graphs, Random, Printf


const PARAMS = (n = 2^10, d = 4, c = 1.5, p = 1, rounds = 100)

function compare_methods()
    g = SimpleGraph(PARAMS.n)
    rng = MersenneTwister(123)
    skip = 0

    total_gap1 = 0.0

    good_rounds = 0
    println("Round | Gap (KrylovKit)          |  Gap  (Arpack)             | Gap (Classical)            |Gap  (Paper style)        ")
    println("------|--------------------------|----------------------------|----------------------------|--------------------------")

    for r in 1:PARAMS.rounds
        e_raes_step_one!(g, PARAMS.d; rng=rng)
        e_raes_step_two!(g, PARAMS.d, PARAMS.c; rng=rng)

        gap1 = 0.0
        gap2 = 0.0
        gap3 = 0.0
        gap4 = 0.0
        
        
        if r >= skip
            gap1 = spectral_gap(g) # KrylovKit
            gap2 = spectral_gap2(g) # Arpack
            gap3 = spectral_gap_classical(g) # Classical
            gap4 = spectral_gap_paper_style(g) # Paper style
            
        end
        if gap1 > 0
            total_gap1 += gap1
            good_rounds = good_rounds +1
        end
        
        @printf("%5d | %24.6f | %26.6f | %26.6f  | %26.6f  \n", r, gap1, gap2, gap3, gap4)
        

        e_raes_step_three!(g, PARAMS.p; rng=rng)
    end
    avg_gap1 = total_gap1 / good_rounds
    println("-"^110)
    @printf("Media Gap 1 (KrylovKit) su %d round: %f\n", PARAMS.rounds, avg_gap1)
end

compare_methods()