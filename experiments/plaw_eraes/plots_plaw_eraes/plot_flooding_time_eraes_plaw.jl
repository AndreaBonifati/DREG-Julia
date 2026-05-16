using Pkg
Pkg.activate(".")

using DelimitedFiles
using Plots
using Printf



results_folder = "results/eraes_plaw"
input_filename = joinpath(results_folder, "average_flooding_time_eraes_plaw_c3.csv")
output_filename = joinpath(results_folder, "average_flooding_time_eraes_plaw_c3.png")

println("Caricamento CSV: $input_filename")


res, header = readdlm(input_filename, ',', header=true)

println("CSV caricato con successo.")


header_row = header[1, :]          


n_values_str = [split(h, "=")[2] for h in header_row[2:end]]
n_values_loaded = parse.(Int, n_values_str)


p_values_loaded = res[:, 1]
flooding_times_matrix = res[:, 2:end]

println("Assi estratti:")
println("N = $n_values_loaded")
println("P = $p_values_loaded")


println("Generazione grafico in corso")

plt = plot(
    xlabel = "Number of nodes",
    ylabel = "Flooding time (rounds)",
    title = "Flooding Time vs. Network Size (E-RAES)",
    xaxis = :log,
    legend = :topleft,
    minorticks = true,
    grid = :on,
    fontfamily = "Computer Modern"
)

p_to_plot = Set([0.0, 0.1, 0.5, 0.7, 0.9])

for i in axes(flooding_times_matrix, 1)
    current_p = p_values_loaded[i]
    if current_p ∉ p_to_plot
        continue   
    end

    plot!(
        plt,
        n_values_loaded,
        flooding_times_matrix[i, :],
        label = "p = $current_p",
        linewidth = 2,
        marker = :circle,
        markersize = 3
    )
end


savefig(plt, output_filename)


println("Grafico salvato con successo in: $output_filename")

