using Pkg
Pkg.activate(".")

using DelimitedFiles
using Plots
using DynamicRandomExpanderGenerator 



results_folder = "results/eraes"
input_filename = joinpath(results_folder, "average_spectral_gap_eraes_fixed_c15.csv")

println("Caricamento dei dati da '$input_filename'")

try

    data_matrix, header = readdlm(input_filename, ',', header=true)


    p_values_loaded = data_matrix[:, 1]

    results_loaded = data_matrix[:, 2:end]


    n_values_str = [split(h, "=")[2] for h in header[1, 2:end]]
    n_values_loaded = parse.(Int, n_values_str)

    println("Dati caricati: $(length(p_values_loaded)) valori di p, $(length(n_values_loaded)) valori di n.")


    output_plot_filename = "average_spectral_gap_eraes_fixed_c15.png" 
    println("Generazione del grafico in '$output_plot_filename'")


    plot_object = plot_spectral_gap_edge_failure_rate(
        p_values_loaded,
        n_values_loaded,
        results_loaded
    )


    savefig(plot_object, output_plot_filename)
    println("Grafico salvato.")
    println("\n Analisi completata")

catch e
    println("\n Errore: Impossibile leggere o processare il file '$input_filename'.")
    println("Assicurarsi che lo script di esperimento sia stato eseguito e abbia creato il file.")
    println("Dettagli errore: ", e)
    rethrow(e) 
end