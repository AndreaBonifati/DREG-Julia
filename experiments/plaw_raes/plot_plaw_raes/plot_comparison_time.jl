using Pkg
Pkg.activate(".")

using Plots
using DelimitedFiles
using Printf

results_folder = "results/plaw_raes"
file_high_k = joinpath(results_folder, "spectral_gap_trajectory_by_k.csv")
file_low_k  = joinpath(results_folder, "spectral_gap_trajectory_k2_only.csv")
file_base   = joinpath(results_folder, "spectral_gap_baseline_p1.csv")


trajectories = Dict{Float64, Vector{Float64}}()
baseline_traj = Float64[]


if isfile(file_high_k)
    data, _ = readdlm(file_high_k, ',', header=true)
    for i in axes(data, 1)
        k_val = Float64(data[i, 1])
        trajectories[k_val] = Float64.(data[i, 2:end])
    end
end

if isfile(file_low_k)
    data, _ = readdlm(file_low_k, ',', header=true)
    trajectories[2.0] = Float64.(data[:, 2])
end


if isfile(file_base)
    data, _ = readdlm(file_base, ',', header=true)

    global baseline_traj = Float64.(data[:, 2])
    println("  - Caricata Baseline P=1.0")
else
    @warn "File Baseline non trovato: $file_base"
end


println("Generazione grafico di confronto...")

sorted_k = sort(collect(keys(trajectories)))

p2 = plot(
    title = "Confronto RAES: Power Law vs Classico",
    xlabel = "Tempo (Round)",
    ylabel = "Spectral Gap Medio",
    legend = :bottomright,
    grid = :on,
    size = (900, 600),
    margin = 5Plots.mm
)


if !isempty(baseline_traj)
    plot!(p2, 1:length(baseline_traj), baseline_traj,
        label = "Classico (p=1.0)",
        color = :black,
        linewidth = 3,
        linestyle = :dash,
        alpha = 0.8
    )
end

colors = palette(:viridis, length(sorted_k))

for (i, k) in enumerate(sorted_k)
    traj = trajectories[k]
    plot!(p2, 1:length(traj), traj,
        label = "PLaw (p=0.0) k=$(k)",
        linewidth = 2,
        color = colors[i]
    )
end

output_file = joinpath(results_folder, "plot_comparison_time_p0_vs_p1.png")
savefig(p2, output_file)
println("Grafico salvato in: $output_file")