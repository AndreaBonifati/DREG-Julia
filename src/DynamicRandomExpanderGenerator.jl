module DynamicRandomExpanderGenerator
using Graphs, Random, Base.Threads, GraphPlot, Colors, BenchmarkTools
using LinearAlgebra 
using SparseArrays  
using KrylovKit
using Plots
using Arpack
using DelimitedFiles
using IterativeSolvers
using Statistics, StatsBase, Distributions
using ThreadsX

include("models/eraes.jl")
include("flooding/flooding.jl")
include("utils/plotting.jl")
include("utils/graphs.jl")
include("utils/math.jl")
include("models/vraes.jl")
include("analysis/spectral.jl")
include("analysis/general.jl")
include("analysis/eraes_specific.jl")
include("models/evraes.jl")
include("models/plaw_eraes.jl")
include("models/plaw_vraes.jl")
include("models/plaw_evraes.jl")
include("analysis/eraes_plaw_specific.jl")
include("models/plaw_raes.jl")
include("models/plaw_raes_c.jl")
include("analysis/raes_plaw_specific.jl")

export e_raes_round!, e_raes!, e_raes_snapshots!, e_raes_threaded_round!, e_raes_threaded_snapshots!, e_raes_threaded!, e_raes_step_one!, e_raes_step_two!, e_raes_step_three!
export eraes_degree_stats, eraes_plot_degree_heatmap, run_spectral_gap_experiment, run_serial_spectral_gap_experiment_eraes
export threaded_flooding_step_dynamic, flooding_dynamic, flooding_dynamic_verbose, flooding_colors, flooding_step!
export spectral_gap, spectral_gap_lcc, plot_spectral_gap_convergence, plot_spectral_gap_multiple_runs, spectral_gap2, spectral_gap_classical, spectral_gap_paper_style
export compute_epsilon, compute_t0, calculate_average_gap_before_failure_eraes, plot_spectral_gap_edge_failure_rate
export check_degree
export vraes_graph, v_raes_step_zero!, v_raes_step_one!, v_raes_step_two!, v_raes_step_three!
export plaw_c_raes_graph, plaw_c_raes_step_one!, plaw_c_raes_step_two!
export evraes_graph, ev_raes_step_zero!, ev_raes_step_one!, ev_raes_step_two!, ev_raes_step_three!, ev_raes_step_four!
export plaw_eraes_graph, plaw_e_raes_step_one!, plaw_e_raes_step_two!, plaw_e_raes_step_three!
export plaw_vraes_graph, plaw_v_raes_step_zero!, plaw_v_raes_step_one!, plaw_v_raes_step_two!, plaw_v_raes_step_three!
export measure_flooding_time_eraes, calculate_average_flooding_time_eraes
export plaw_evraes_graph, plaw_ev_raes_step_zero!, plaw_ev_raes_step_one!, plaw_ev_raes_step_two!, plaw_ev_raes_step_three!, plaw_ev_raes_step_four!
export run_serial_spectral_gap_experiment_eraes_plaw, calculate_average_gap_before_failure_eraes_plaw, calculate_average_flooding_time_eraes_plaw
export plaw_raes_graph, plaw_raes_step_one!, plaw_raes_step_two!, compute_spectral_gap_trajectory_plaw_raes
export compute_structure_metrics_plaw_raes, NetStatsPlawRaes, compute_assortativity_stats_single_plaw_raes

end # module DynamicRandomExpanderGenerator
