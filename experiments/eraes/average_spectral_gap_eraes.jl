using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Base.Threads
using Printf      
using DelimitedFiles 
using ThreadsX
using ProgressMeter
using Statistics
using Random

println(" Spectral Gap vs. p ")


const N_VALUES = [2^9, 2^10, 2^11, 2^12, 2^13, 2^14, 2^15]
const P_VALUES = 0.0:0.1:1.0
const D_PARAM = 4
const C_PARAM = 1.5 # 3.0
const NUM_RUNS_PER_POINT = 100
const NUM_ROUNDS_PER_RUN = 100
const FALLBACK_SKIP_ROUNDS = 15 # Fallback se t0=-1 

println("Parametri fissi: d=$D_PARAM, c=$C_PARAM")
println("Valori di n: $N_VALUES")
println("Valori di p: $P_VALUES")
println("Numero di run per punto: $NUM_RUNS_PER_POINT")


results = Matrix{Float64}(undef, length(P_VALUES), length(N_VALUES))

println("Caricamento parametri di stabilità pre-calcolati")
results_folder = "results"
try
    global t0_matrix = readdlm(joinpath(results_folder, "stabilization_t0.csv"), ',', header=true)[1][:, 2:end]
    println("Matrice t0 caricata.")
catch e
    println("Errore: Impossibile caricare 'stabilization_t0.csv'. Esegui prima 'precompute_stability_eraes.jl'.")
    rethrow(e)
end

println("\nAvvio delle simulazioni")

tasks = [(n, p, i, j) for (j, n) in enumerate(N_VALUES) for (i, p) in enumerate(P_VALUES)]
num_tasks = length(tasks)
println("Numero di task da eseguire: $num_tasks")
println("Threads attivi: ", Threads.nthreads())


function run_single_task(task, idx)
    (n, p, i, j) = task
    
    local_t0 = t0_matrix[i, j]
    min_skip = ceil(Int, log2(n)) 
    
    local skip_rounds_dynamic::Int
    
    if p >= 0.8
        skip_rounds_dynamic = min_skip
    elseif local_t0 == -1 
        skip_rounds_dynamic = FALLBACK_SKIP_ROUNDS
    else 
        skip_rounds_dynamic = local_t0
    end


    local_result = DynamicRandomExpanderGenerator.calculate_average_gap_before_failure_eraes(
        n, D_PARAM, C_PARAM, p;
        num_runs=NUM_RUNS_PER_POINT,
        num_rounds=NUM_ROUNDS_PER_RUN,
        skip_initial_rounds=skip_rounds_dynamic 
    )
    
    if idx % 1 == 0 
        @info "Completato $idx/$num_tasks: (n=$n, p=$p) -> (t0 usato: $skip_rounds_dynamic) -> Risultato: $(round(local_result, digits=4))"
    end

    return (i, j, local_result)
end

task_results = ThreadsX.map(run_single_task, tasks, 1:num_tasks)


for (i, j, value) in task_results
    results[i, j] = value
end

println("\nTutte le simulazioni sono completate.")


output_filename = joinpath(results_folder, "average_spectral_gap_eraes_main_small_c.csv")
println("Salvataggio dei risultati con intestazioni in '$output_filename'")
header = ["p_value"; ["n=$(n)" for n in N_VALUES]]
p_colonna = collect(P_VALUES)
data_to_save = hcat(p_colonna, results)
open(output_filename, "w") do io
    writedlm(io, [header], ',')
    writedlm(io, data_to_save, ',')
end
println("Salvataggio completato.")