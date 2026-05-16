using Pkg           
Pkg.activate(".")   

using DelimitedFiles
using Statistics
using Plots
using DynamicRandomExpanderGenerator 




results_folder = "results/eraes_plaw" 
input_filename = joinpath(results_folder, "spectral_gaps_convergence_eraes_plaw_main.csv")

println("Caricamento dei dati da '$input_filename'...")

try
    data_matrix, header = readdlm(input_filename, ',', header=true)
    
    all_gaps_transposed = data_matrix[:, 2:end]
    all_gaps = transpose(all_gaps_transposed)
    num_rounds = size(all_gaps, 1)
    println("Dati caricati: $(size(all_gaps, 2)) simulazioni, $num_rounds round per simulazione.")
    average_gaps = mean(all_gaps, dims=2)
    cartesian_index = findfirst(g -> g > 0, average_gaps)
    first_nonzero_round = isnothing(cartesian_index) ? 1 : cartesian_index[1]
    trimmed_all_runs = all_gaps[first_nonzero_round:end, :]
    trimmed_average_run = average_gaps[first_nonzero_round:end]
    time_axis = first_nonzero_round:num_rounds


    output_plot_filename = joinpath(results_folder, "spectral_gaps_convergence_eraes_plaw_main.png")

    println("Generazione del grafico in '$output_plot_filename'...")


    plot_object = plot_spectral_gap_multiple_runs(
        time_axis, trimmed_all_runs, trimmed_average_run 
    )


    savefig(plot_object, output_plot_filename)

    println("Grafico salvato.")
    println("\n Analisi completata ")

catch e
    println("\n Errore: Impossibile leggere o processare il file '$input_filename'.")
    println("Assicurarsi che lo script di esperimento sia stato eseguito e abbia creato il file.")
    println("Dettagli errore: ", e)
end