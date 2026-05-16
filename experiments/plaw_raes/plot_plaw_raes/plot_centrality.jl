using Plots
using CSV
using DataFrames


file_path = "results/plaw_raes/optimized_dynamic_stats.csv"
df = CSV.read(file_path, DataFrame)


p3 = plot(df.p_value, df.mean_max_betweenness, yerror=df.std_max_betweenness,
    label="Max Betweenness Centrality",
    marker=:circle,
    linewidth=2,
    color=:firebrick,
    legend=:topright
)


title!("Centralizzazione: Carico sul nodo più importante")
xlabel!("Parametro P (Probabilità Grado Fisso)")
ylabel!("Betweenness Score")



savefig("centrality_plot.png")
println("Grafico salvato: centrality_plot.png")