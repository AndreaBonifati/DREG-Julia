using Pkg
Pkg.activate(".")

using Plots
using DelimitedFiles
using Printf


file_traj_p = "results/plaw_raes/spectral_gap_trajectory_by_p.csv"
file_baseline = "results/plaw_raes/spectral_gap_baseline_p1.csv"
output_plot = "results/plaw_raes/plot_spectral_gap_by_p.png"


if !isfile(file_traj_p)
    error("File traiettorie non trovato: $file_traj_p")
end
data_p, header_p = readdlm(file_traj_p, ',', header=true)


if !isfile(file_baseline)
    println("ATTENZIONE: File baseline non trovato ($file_baseline). Il grafico non avrà la linea di riferimento.")
    has_baseline = false
else
    data_base, header_base = readdlm(file_baseline, ',', header=true)
    has_baseline = true
end


p = plot(
    title = "Evoluzione Spectral Gap al variare di P (K=2.0)",
    xlabel = "Round",
    ylabel = "Spectral Gap Medio",
    legend = :bottomright,
    grid = :on,
    size = (900, 600),
    dpi = 300,
    ylims = (0.2, 0.65) 
)


rounds_x = 1:(size(data_p, 2) - 1)


colors = [:firebrick, :orange, :green, :cyan, :blue] 


for i in axes(data_p, 1)
    p_val = data_p[i, 1]
    gaps = data_p[i, 2:end] 
    
    col = get(colors, i, :black)
    
    plot!(p, rounds_x, gaps, 
          label = "p = $(p_val)", 
          linewidth = 2, 
          alpha = 0.8,
          color = col)
end


if has_baseline
    base_rounds = data_base[:, 1]
    base_gaps = data_base[:, 2]
    
    plot!(p, base_rounds, base_gaps, 
          label = "Baseline (p=1.0)", 
          linestyle = :dash, 
          color = :black, 
          linewidth = 2.5)
end


mkpath(dirname(output_plot))
savefig(p, output_plot)
println("Grafico salvato con successo in: $output_plot")


display(p)