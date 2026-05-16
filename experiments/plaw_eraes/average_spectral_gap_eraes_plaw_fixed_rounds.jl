using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Base.Threads
using Printf      
using DelimitedFiles 
using ThreadsX
using ProgressMeter



const N_VALUES = [2^9, 2^10, 2^11, 2^12, 2^13, 2^14, 2^15] # 512 to 32768 [2^9, 2^10, 2^11, 2^12, 2^13, 2^14, 2^15]
const P_VALUES = 0.0:0.1:1.0 # p from 0.0 to 1.0 in steps of 0.1
const d_default = 4
const c = 1.5
const k = 2.0
const prob_default = 0.5
const prob_downscale = 0.4
const prob_upscale = 0.1
const min_d = 2
const NUM_RUNS_PER_POINT = 100 
const NUM_ROUNDS_PER_RUN = 100 
const SKIP_ROUNDS = 0 

const PRINT_EVERY = 10
println("Parametri fissi: grado target default=$d_default, c=$c, k=$k, grado target minimo = $min_d")
println("Probabilità di nodo default = $prob_default, probabilità di nodo downscale = $prob_downscale, probabilità di nodo upscale = $prob_upscale")
println("Valori di n: $N_VALUES")
println("Valori di p: $P_VALUES")
println("Numero di run per punto: $NUM_RUNS_PER_POINT")


results = Matrix{Float64}(undef, length(P_VALUES), length(N_VALUES))

println("\nAvvio delle simulazioni")

tasks = [(n, p, i, j) for (j, n) in enumerate(N_VALUES) for (i, p) in enumerate(P_VALUES)]
num_tasks = length(tasks)
println("Numero di task da eseguire: $num_tasks")
println("Threads attivi: ", Threads.nthreads())


function run_single_task(task, idx)
    (n, p, i, j) = task
    local_result = calculate_average_gap_before_failure_eraes_plaw(
        n, d_default, c, p, k, prob_default, prob_upscale, prob_downscale, min_d, NUM_RUNS_PER_POINT, NUM_ROUNDS_PER_RUN, SKIP_ROUNDS
    )
    if idx % PRINT_EVERY == 0
        @info "Completati $idx / $num_tasks task"
    end

    return (i, j, local_result)
end
task_results = ThreadsX.map(run_single_task, tasks, 1:num_tasks)

for (i, j, value) in task_results
    results[i, j] = value
end

println("\nTutte le simulazioni sono completate.")

results_folder = "results/eraes_plaw"

mkpath(results_folder)


output_filename = joinpath(results_folder, "average_spectral_gap_eraes_fixed_c15.csv") 

println("Salvataggio dei risultati con intestazioni in '$output_filename'")


header = ["p_value"; ["n=$(n)" for n in N_VALUES]]


p_colonna = collect(P_VALUES)
data_to_save = hcat(p_colonna, results)


open(output_filename, "w") do io
    writedlm(io, [header], ',')
    writedlm(io, data_to_save, ',')
end
