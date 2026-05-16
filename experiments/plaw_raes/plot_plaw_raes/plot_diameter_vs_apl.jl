using Plots
using CSV
using DataFrames


file_path = "results/plaw_raes/optimized_dynamic_stats.csv"
df = CSV.read(file_path, DataFrame)
output_plot = "results/plaw_raes/diameter_vs_apl.png"


p1 = plot(df.p_value, df.mean_diameter, yerror=df.std_diameter,
    label="Diametro Medio",
    marker=:circle,
    linewidth=2,
    color=:navy,
    legend=:topleft
)

plot!(p1, df.p_value, df.mean_apl, yerror=df.std_apl,
    label="Cammino Medio (APL)",
    marker=:square,
    linewidth=2,
    color=:dodgerblue,
    linestyle=:dash
)

title!("Efficienza della Rete: Compattezza")
xlabel!("Parametro P (Probabilità Grado Fisso)")
ylabel!("Distanza (nodi)")


savefig("diameter_vs_apl.png")
println("Grafico salvato: 1_efficienza_rete.png")