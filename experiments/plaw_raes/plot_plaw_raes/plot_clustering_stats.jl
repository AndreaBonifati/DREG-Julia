using Plots
using CSV
using DataFrames


file_path = "results/plaw_raes/optimized_dynamic_stats.csv"
df = CSV.read(file_path, DataFrame)

p2 = plot(df.p_value, df.mean_global_clust, yerror=df.std_global_clust,
    label="Clustering Globale",
    marker=:diamond,
    linewidth=2,
    color=:forestgreen
)

plot!(p2, df.p_value, df.mean_local_clust, yerror=df.std_local_clust,
    label="Clustering Locale Medio",
    marker=:utriangle,
    linewidth=2,
    color=:limegreen,
    linestyle=:dash
)


title!("Struttura Comunitaria: Clustering")
xlabel!("Parametro P (Probabilità Grado Fisso)")
ylabel!("Coefficiente (0-1)")


savefig("2_clustering.png")
println("Grafico salvato: 2_clustering.png")