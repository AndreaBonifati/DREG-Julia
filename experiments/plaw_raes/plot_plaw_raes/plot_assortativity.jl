using Pkg
Pkg.activate(".")

using Plots
using DelimitedFiles


input_file = "results/plaw_raes/assortativity_stats_k2.csv"
output_file = "results/plaw_raes/assortativity_plot.png"


println("Caricamento dati da: $input_file")
data, header = readdlm(input_file, ',', header=true)


p_values = Float64.(data[:, 1])
r_means  = Float64.(data[:, 2])
r_stds   = Float64.(data[:, 3])


println("Generazione grafico...")


default(fontfamily="Computer Modern", framestyle=:box, grid=true) 


plt = plot(p_values, r_means,
    yerror = r_stds,               
    label = "Mean Assortativity (r)",
    

    color = :blue,
    marker = :circle,
    markersize = 5,
    linewidth = 2,
    linealpha = 0.8,
    

    title = "Network Assortativity vs Default target degree probability p",
    xlabel = "Probability (p)",
    ylabel = "Pearson Correlation Coeff. (r)",
    

    ylims = (-0.35, 0.05),          
    legend = :bottomright,
    

    guidefontsize = 12,
    tickfontsize = 10,
    titlefontsize = 14,
    size = (800, 600)               
)


hline!([0], 
    label = "Neutrality (Random Mixing)", 
    color = :red, 
    linestyle = :dash, 
    linewidth = 2
)



mkpath(dirname(output_file)) 
savefig(plt, output_file)
println("Grafico salvato con successo in: $output_file")