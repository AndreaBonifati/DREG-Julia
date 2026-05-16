using Pkg
Pkg.activate(".")

using Plots
using DelimitedFiles
using Printf


csv_path = "results/plaw_raes/structure/topology_stats_k2_extended.csv"
output_dir = "results/plaw_raes/structure"
mkpath(output_dir)

if !isfile(csv_path)
    error("File dati non trovato: $csv_path")
end


data, header = readdlm(csv_path, ',', header=true)


p_vals = data[:, 1]
avg_deg = data[:, 2]
max_deg = data[:, 3]
perc_below = data[:, 5]
hub_dominance = data[:, 9]


common_style = (
    xlabel = "Probabilità P (Comportamento Uniforme)",
    grid = :on,
    linewidth = 3,
    marker = :circle,
    markersize = 6,
    legend = :none,   
    size = (800, 500),
    dpi = 300,
    margin = 5Plots.mm
)

println("Generazione grafici...")


p1 = plot(p_vals, max_deg,
    title = "Grado Massimo (Potere del Nodo più Ricco)",
    ylabel = "Grado Massimo",
    color = :purple,
    markerstrokecolor = :purple;
    common_style...
)
savefig(p1, joinpath(output_dir, "plot_max_degree.png"))
println(" -> Salvato: plot_max_degree.png")

p2 = plot(p_vals, hub_dominance,
    title = "Dominanza Hub (% Archi nell'Top 1% dei Nodi)",
    ylabel = "% Archi Totali",
    color = :firebrick,
    markerstrokecolor = :firebrick;
    common_style...
)
savefig(p2, joinpath(output_dir, "plot_hub_dominance.png"))
println(" -> Salvato: plot_hub_dominance.png")

p3 = plot(p_vals, perc_below,
    title = "Disuguaglianza (% Nodi sotto il Grado Medio)",
    ylabel = "% Nodi < Media",
    color = :orange,
    markerstrokecolor = :orange,
    ylims = (40, 100); 
    common_style...
)

hline!(p3, [50], linestyle=:dash, color=:gray, label="Equità (50%)")
savefig(p3, joinpath(output_dir, "plot_inequality.png"))
println(" -> Salvato: plot_inequality.png")


p4 = plot(p_vals, avg_deg,
    title = "Grado Medio della Rete",
    ylabel = "Grado Medio",
    color = :green,
    markerstrokecolor = :green,
    ylims = (0, maximum(avg_deg) + 2);
    common_style...
)
savefig(p4, joinpath(output_dir, "plot_avg_degree.png"))
println(" -> Salvato: plot_avg_degree.png")

println("\nTutti i grafici sono stati generati in: $output_dir")