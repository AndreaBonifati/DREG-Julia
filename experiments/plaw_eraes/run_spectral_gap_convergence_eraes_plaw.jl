using Pkg            
Pkg.activate(".")    

using DynamicRandomExpanderGenerator
using Graphs
using Random
using Statistics
using Base.Threads
using Printf
using DelimitedFiles


println("Esperimento: Convergenza dello Spectral Gap (E-RAES Power Law) ")

const PARAMS = (
    n = 2^15, 
    d_default = 4,
    c = 3.0,
    p = 0.1,    
    rounds = 30,
    k = 2.0,
    prob_default = 0.5,
    prob_downscale = 0.4,
    prob_upscale = 0.1,
    min_d = 2
)
const NUM_SIMULATIONS = 100 

#println("Parametri: n=$(PARAMS.n), d=$(PARAMS.d_default), c=$(PARAMS.c), p=$(PARAMS.p), rounds=$(PARAMS.rounds)")
println("Numero di simulazioni: $NUM_SIMULATIONS")


all_gaps = Matrix{Float64}(undef, PARAMS.rounds, NUM_SIMULATIONS)


Threads.@threads for i in 1:NUM_SIMULATIONS
    local seed = 123+i+PARAMS.n
    local state = plaw_eraes_graph(PARAMS.n, seed,  PARAMS.k, PARAMS.d_default, PARAMS.prob_default, PARAMS.prob_downscale, PARAMS.prob_upscale, PARAMS.min_d )
    println("Thread $(threadid()) avvia la simulazione $i...")

    all_gaps[:, i] = run_serial_spectral_gap_experiment_eraes_plaw( state, PARAMS.c, PARAMS.p , PARAMS.rounds )
        
    println("Thread $(threadid()) ha completato la simulazione $i.")

end


results_folder = "results/eraes_plaw"

mkpath(results_folder)


output_filename = joinpath(results_folder, "spectral_gaps_convergence_eraes_plaw_main.csv")

println("Salvataggio dei risultati formattati in '$output_filename'")


data_transposed = transpose(all_gaps)

run_indices = collect(1:NUM_SIMULATIONS)


data_to_save = hcat(run_indices, data_transposed)


header = ["Run"; ["Round_$(r)" for r in 1:PARAMS.rounds]]


open(output_filename, "w") do io
    writedlm(io, [header], ',')
    writedlm(io, data_to_save, ',')
end

println("Salvataggio completato.")


println("Tutte le simulazioni sono completate.")

