using Pkg; Pkg.activate(".")
using DynamicRandomExpanderGenerator
using Graphs, Random, Printf

const PARAMS = (n = 2^15, d = 4, c = 3, p = 0.1, rounds = 100)

g = SimpleGraph(PARAMS.n)
spectral_gaps = Vector{Float64}(undef, PARAMS.rounds)
#snapshots = Vector{SimpleGraph}(undef, PARAMS.rounds)
rng = MersenneTwister(7)
for r in 1:PARAMS.rounds
    e_raes_step_one!(g, PARAMS.d; rng = rng)
    e_raes_step_two!(g, PARAMS.d, PARAMS.c; rng=rng)
    gap = spectral_gap(g)
    spectral_gaps[r] = gap
    e_raes_step_three!(g, PARAMS.p; rng= rng)
end


println("Spectral gaps: $spectral_gaps")

eps = compute_epsilon(spectral_gaps)
println("epsilon: $eps")
t_0 = compute_t0(spectral_gaps, PARAMS.n, eps)
println("Starting round: $t_0")