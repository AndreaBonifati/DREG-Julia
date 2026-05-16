using Pkg
Pkg.activate(".")

using DynamicRandomExpanderGenerator
using Base.Threads
using Printf      
using DelimitedFiles 
using ThreadsX
using Statistics 
using Random     
using Graphs

println("Esperimento: Pre-calcolo Stabilità (Epsilon e t0) ")


const N_VALUES = [2^9, 2^10, 2^11, 2^12, 2^13, 2^14, 2^15]
const P_VALUES = 0.0:0.1:1.0
const d_default = 4
const c = 1.5
const k = 2.0
const prob_default = 0.5
const prob_downscale = 0.4
const prob_upscale = 0.1
const min_d = 2
const NUM_ROUNDS_PER_RUN = 100 
const PRINT_EVERY = 1

println("Parametri fissi: d=$d_default, c=$c")
println("Valori di n: $N_VALUES")
println("Valori di p: $P_VALUES")


epsilon_matrix = Matrix{Float64}(undef, length(P_VALUES), length(N_VALUES))
t0_matrix = Matrix{Int}(undef, length(P_VALUES), length(N_VALUES))


tasks = [(n, p, i, j) for (j, n) in enumerate(N_VALUES) for (i, p) in enumerate(P_VALUES)]
num_tasks = length(tasks)
println("Numero di task da eseguire: $num_tasks")
println("Threads attivi: ", Threads.nthreads())

"""
Task parallelo: esegue una simulazione pilota per (n,p)
e calcola i parametri di stabilità.
"""
function calculate_stability_params(task, idx)
    (n, p, i, j) = task
    
    local seed = 123+i+ n
    local state = plaw_eraes_graph(n, seed,  k, d_default, prob_default, prob_downscale, prob_upscale, min_d )

    pilot_gaps = run_serial_spectral_gap_experiment_eraes_plaw( state, c, p , NUM_ROUNDS_PER_RUN )

    epsilon = compute_epsilon(pilot_gaps)
    t0 = compute_t0(pilot_gaps, n, epsilon)
    
    if idx % PRINT_EVERY == 0
        @info "Completato $idx/$num_tasks: (n=$n, p=$p) -> ε=$(round(epsilon, digits=4)), t0=$t0"
    end


    return (i, j, epsilon, t0)
end

task_results = ThreadsX.map(calculate_stability_params, tasks, 1:num_tasks)


for (i, j, epsilon, t0) in task_results
    epsilon_matrix[i, j] = epsilon
    t0_matrix[i, j] = t0
end

println("\nTutti i calcoli di stabilità sono completati.")



results_folder = "results/eraes_plaw"
mkpath(results_folder)


function save_matrix_to_csv(filename, p_values, n_values, data_matrix)
    header = ["p_value"; ["n=$(n)" for n in n_values]]
    p_colonna = collect(p_values)
    data_to_save = hcat(p_colonna, data_matrix)
    
    open(filename, "w") do io
        writedlm(io, [header], ',')
        writedlm(io, data_to_save, ',')
    end
    println("Salvataggio completato in '$filename'")
end


save_matrix_to_csv(joinpath(results_folder, "stabilization_epsilon_plaw_eraes_c15.csv"), P_VALUES, N_VALUES, epsilon_matrix)
save_matrix_to_csv(joinpath(results_folder, "stabilization_t0_plaw_eraes_c15.csv"), P_VALUES, N_VALUES, t0_matrix)