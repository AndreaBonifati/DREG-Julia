using Pkg            
Pkg.activate(".")    

using DynamicRandomExpanderGenerator
using Graphs
using Random
using Statistics
using Base.Threads
using Printf
using DelimitedFiles


println("Esperimento: Convergenza dello Spectral Gap (E-RAES) ")

const PARAMS = (
    n = 2^15,   
    d = 4,      
    c = 1.5,    
    p = 0.1,    
    rounds = 30 
)
const NUM_SIMULATIONS = 100 

println("Parametri: n=$(PARAMS.n), d=$(PARAMS.d), c=$(PARAMS.c), p=$(PARAMS.p), rounds=$(PARAMS.rounds)")
println("Numero di simulazioni: $NUM_SIMULATIONS")


all_gaps = Matrix{Float64}(undef, PARAMS.rounds, NUM_SIMULATIONS)



Threads.@threads for i in 1:NUM_SIMULATIONS
    local g = SimpleGraph(PARAMS.n)
    local local_rng = MersenneTwister()
    println("Thread $(threadid()) avvia la simulazione $i...")

    all_gaps[:, i] = run_serial_spectral_gap_experiment_eraes(
            g, PARAMS.d, PARAMS.c, PARAMS.p, PARAMS.rounds;
            rng=local_rng   )
        
    println("Thread $(threadid()) ha completato la simulazione $i.")

end


results_folder = "results"

mkpath(results_folder)


output_filename = joinpath(results_folder, "spectral_gaps_convergence_eraes_2.csv")

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


