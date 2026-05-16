using Pkg
Pkg.activate(".")

using Plots
using DelimitedFiles
using Printf


input_file = "results/plaw_evraes/spectral_gap_k2.0_vary_node_failure.csv"
output_plot = "results/plaw_evraes/plot_node_resilience.png"


if !isfile(input_file)
    error("File non trovato: $input_file")
end

data, header = readdlm(input_file, ',', header=true)


p = plot(
    title = "Node Resilience: Spectral Gap vs Churn (k=2.0)",
    xlabel = "Round",
    ylabel = "Spectral Gap Medio",
    legend = :outertopright, 
    grid = :on,
    size = (1000, 600),
    dpi = 300,
    ylims = (0.0, 0.6)
)

num_curves = size(data, 1)
rounds_x = 1:(size(data, 2) - 1)


mypalette = cgrad(:plasma, num_curves, categorical=true)
sorted_indices = sortperm(data[:, 1])

for (color_idx, row_idx) in enumerate(sorted_indices)
    q_val = data[row_idx, 1]
    gaps = data[row_idx, 2:end]
    
    plot!(p, rounds_x, gaps, 
          label = "q_node = $(q_val)", 
          linewidth = 2, 
          alpha = 0.8,
          color = mypalette[color_idx])
end


mkpath(dirname(output_plot))
savefig(p, output_plot)
println("Grafico salvato con successo in: $output_plot")
display(p)