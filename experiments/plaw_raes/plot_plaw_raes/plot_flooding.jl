using Pkg
Pkg.activate(".")

using Plots
using DelimitedFiles




csv_path = "results/plaw_raes/flooding/flooding_vs_p_k2_dynamic.csv"
output_plot = "results/plaw_raes/plot_flooding_vs_p_final.png"

if !isfile(csv_path)
    error("File dati non trovato!")
end

data, header = readdlm(csv_path, ',', header=true)
p_vals = data[:, 1]
flooding_times = data[:, 3]


p = plot(
    p_vals, flooding_times,
    label = "Flooding Time",
    marker = :circle,
    markersize = 6,
    linewidth = 2.5,
    color = :blue,   
    

    xlabel = "Probabilità P",
    ylabel = "Tempo Medio di Flooding (Round)",
    title = "Flooding Time vs P (K=2.0)",
    

    grid = :on,
    legend = :topleft,
    

    xticks = 0.0:0.2:1.0,               
    ylims = (minimum(flooding_times) - 0.3 , maximum(flooding_times) +1),
    

    size = (800, 500),
    dpi = 300
)



mkpath(dirname(output_plot))
savefig(p, output_plot)
println("Grafico pulito salvato in: $output_plot")
display(p)