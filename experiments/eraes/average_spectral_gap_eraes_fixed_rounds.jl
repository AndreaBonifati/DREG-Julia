using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Base.Threads
using Printf      
using DelimitedFiles 
using ThreadsX
using ProgressMeter

println("Spectral Gap vs. p")


const N_VALUES = [2^9, 2^10, 2^11, 2^12, 2^13, 2^14, 2^15] # 512 to 32768 [2^9, 2^10, 2^11, 2^12, 2^13, 2^14, 2^15]
const P_VALUES = 0.0:0.1:1.0 # p from 0.0 to 1.0 in steps of 0.1
const D_PARAM = 4
const C_PARAM = 1.5 # 3.0
const NUM_RUNS_PER_POINT = 100 # Number of simulations to average for each (n, p) point 100
const NUM_ROUNDS_PER_RUN = 100 # Rounds per simulation run 100
const SKIP_ROUNDS = 15 # Initial rounds to discard

const PRINT_EVERY = 10
println("Parametri fissi: d=$D_PARAM, c=$C_PARAM")
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
    local_result = calculate_average_gap_before_failure_eraes(
        n, D_PARAM, C_PARAM, p;
        num_runs=NUM_RUNS_PER_POINT,
        num_rounds=NUM_ROUNDS_PER_RUN,
        skip_initial_rounds=SKIP_ROUNDS
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

results_folder = "results"

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


