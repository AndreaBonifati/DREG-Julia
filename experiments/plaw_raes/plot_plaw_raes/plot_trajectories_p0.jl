using Pkg
Pkg.activate(".")

using Plots
using DelimitedFiles
using Printf


results_folder = "results/plaw_raes"
file_high_k = joinpath(results_folder, "spectral_gap_trajectory_by_k.csv")       
file_low_k  = joinpath(results_folder, "spectral_gap_trajectory_k2.0_only.csv")   


trajectories = Dict{Float64, Vector{Float64}}()
num_rounds = 0


if isfile(file_high_k)
    data, header = readdlm(file_high_k, ',', header=true)
    for i in axes(data, 1)
        k_val = Float64(data[i, 1])
        traj = Float64.(data[i, 2:end])
        trajectories[k_val] = traj
        global num_rounds = length(traj)
    end
    println("  - Caricati dati High K")
end


if isfile(file_low_k)
    data, header = readdlm(file_low_k, ',', header=true)
    traj = Float64.(data[:, 2])
    trajectories[2.0] = traj
    global num_rounds = max(num_rounds, length(traj))
    println("  - Caricati dati K=2.0")
end


println("Generazione grafico...")


sorted_k = sort(collect(keys(trajectories)))

p1 = plot(
    title = "Evoluzione Spectral Gap (Power Law, p=0.0)",
    xlabel = "Round",
    ylabel = "Spectral Gap",
    legend = :bottomright,
    grid = :on,
    size = (900, 600),
    margin = 5Plots.mm
)

for k in sorted_k
    traj = trajectories[k]
    plot!(p1, 1:length(traj), traj, 
          label="k=$(k)", 
          linewidth=2)
end

output_file = joinpath(results_folder, "plot_trajectories_p0_time.png")
savefig(p1, output_file)
println("Grafico salvato in: $output_file")