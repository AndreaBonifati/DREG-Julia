"""
Crea e salva un plot dell'evoluzione dello spectral gap nel tempo.
"""
function plot_spectral_gap_convergence(
    gaps::Vector{Float64};
    filename="spectral_gap_convergence.png"
)

    p = plot(
        gaps,
        xlabel="Time (Rounds)",
        ylabel="Spectral Gap",
        title="Evolution of the Spectral Gap",
        label="Single Run", 
        legend=:topright,
        linewidth=2,
        marker=:circle
    )

    savefig(p, filename)
    println("Plot saved to $filename")
end

"""
Crea un plot con tutte le esecuzioni di una simulazione come linee sottili
e la loro media come una linea spessa, simile alla Figura 1 del paper.
"""
function plot_spectral_gap_multiple_runs(
    time_axis,
    all_runs::Matrix{Float64},
    average_run;
    filename="spectral_gaps_convergence_eraes.png", 
    ylims=nothing
)
    num_simulations = size(all_runs, 2)

    p = plot(
        time_axis, all_runs,
        label=nothing, color=:gray, alpha=0.15, linewidth=0.5
    )

    plot!(
        p, time_axis, average_run,
        label="Average ($num_simulations runs)", color=:black, linewidth=3
    )

    xlabel!("Time")
    ylabel!("Spectral Gap")
    title!("Evolution of the Spectral Gap")

    if isnothing(ylims)
        ylims = (0.120, 0.280)
    end
    ylims!(p, ylims)

    savefig(p, filename)
    println("Grafico multi-run salvato in '$filename'")


    return p
end

"""
Crea un plot delle statistiche sul grado dei nodi nel tempo.
"""
function plot_degree_stats(low_degree::Vector{Int}, high_degree::Vector{Int})
    rounds = 1:length(low_degree)
    p = plot(rounds, low_degree, label="Degree < d", lw=2, marker=:circle)
    plot!(p, rounds, high_degree, label="Degree > c*d", lw=2, marker=:star)
    xlabel!("Round")
    ylabel!("Number of nodes")
    title!("Node Degree Extremes over Rounds")
    return p 
end

"""
Crea una heatmap della distribuzione dei gradi nel tempo.
"""
function plot_degree_heatmap(deg_counts::Matrix{Int})
    rounds = 1:size(deg_counts, 2)
    max_deg = size(deg_counts, 1) - 1

    heatmap(rounds, 0:max_deg, deg_counts,
            xlabel="Round", ylabel="Degree",
            colorbar_title="Nodes",
            title="Degree Distribution over Rounds")
end

"""
Crea un plot simile alla figura 2 del paper, che mostra un confronto tra 
gap spettrale medio e tasso di scomparsa degli archi p rispetto a diverse dimensioni
della rete.
"""

function plot_spectral_gap_edge_failure_rate(
    p_values::AbstractVector{Float64},
    n_values::AbstractVector{Int},
    results_matrix::Matrix{Float64}; 
    filename="average_spectral_gap_eraes.png",
    ylims_custom=nothing 
)
    

    theme(:seaborn_whitegrid) 

    plt = plot(
        xlabel="Edge disappearance rate (p)",
        ylabel="Average Spectral Gap (before failure)",
        title="Spectral Gap vs. Edge Failure Rate",
        legend=:bottomleft, 
        fontfamily="Computer Modern" 
    )

    colors = [:red, :blue, :green, :purple, :orange, :cyan, :magenta] 

    for (idx, n) in enumerate(n_values)
        plot!(plt,
              p_values,
              results_matrix[:, idx],
              label="n = $n",
              linewidth=1.5,      
              marker=:circle,     
              markersize=4,      
              markerstrokewidth=0, 
              color=colors[idx % length(colors) + 1] 
             )
    end

    if !isnothing(ylims_custom)
        ylims!(plt, ylims_custom)
    end

    savefig(plt, filename)
    println("Grafico Figura 2 salvato in '$filename'")
    return plt
end