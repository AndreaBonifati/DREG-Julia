function compute_spectral_gap_trajectory_plaw_raes(n::Int, d::Int, c::Real, k::Real, p_std::Real, num_runs::Int, num_rounds::Int)
    
    gaps_matrix = Matrix{Float64}(undef, num_runs, num_rounds)
    avg_gaps_vector = Vector{Float64}(undef, num_rounds)
    for R in 1:num_runs
        local seed = R +123
        state = plaw_raes_graph(n, seed, k,d, p_std)
        for r in 1:num_rounds
            plaw_raes_step_one!(state)
            plaw_raes_step_two!(state, c)
            gaps_matrix[R,r] = spectral_gap(state.g)
        end
    end

    avg_gaps_vector = vec(mean(gaps_matrix, dims=1))
    return avg_gaps_vector
end


struct NetStatsPlawRaes
    avg_deg::Float64
    max_deg::Int
    min_deg::Int
    perc_nodes_below_avg::Float64
    perc_nodes_above_avg::Float64 
    
    num_nodes_with_min_deg::Float64 
    num_nodes_with_max_deg::Float64 
    
    perc_edges_in_top_1::Float64
end

function compute_structure_metrics_plaw_raes(n::Int, d::Int, c::Real, k::Real, p::Real, runs::Int, rounds::Int)
    
    run_results = map(1:runs) do i
        seed = n + 123 + i 
        state = plaw_raes_graph(n, seed, k, d, p)
        
        for r in 1:rounds
            plaw_raes_step_one!(state)
            plaw_raes_step_two!(state, c)
        end
        
        degs = degree(state.g)
        avg = mean(degs)
        d_max = maximum(degs)
        d_min = minimum(degs)
        
        n_below = count(x -> x < avg, degs)
        n_above = count(x -> x > avg, degs)
        
        perc_below = (n_below / n) * 100
        perc_above = (n_above / n) * 100
        
        n_min_deg = count(x -> x == d_min, degs)
        n_max_deg = count(x -> x == d_max, degs)
        
        sorted_degs = sort(degs, rev=true)
        top_1_percent_idx = max(1, round(Int, n * 0.01))
        edges_top_1 = sum(sorted_degs[1:top_1_percent_idx])
        total_edges_volume = sum(degs)
        dominance = (edges_top_1 / total_edges_volume) * 100
        
        return (avg, d_max, d_min, perc_below, perc_above, n_min_deg, n_max_deg, dominance)
    end
    
    return NetStatsPlawRaes(
        mean(s[1] for s in run_results),
        round(Int, mean(s[2] for s in run_results)),
        round(Int, mean(s[3] for s in run_results)),
        mean(s[4] for s in run_results),
        mean(s[5] for s in run_results),
        mean(s[6] for s in run_results),
        mean(s[7] for s in run_results),
        mean(s[8] for s in run_results)
    )
end

function compute_assortativity_stats_single_plaw_raes(p_val::Float64, n::Int, d::Int, c::Float64, k::Float64, runs::Int, rounds::Int)
    
    r_values = Float64[]
    
    for i in 1:runs
        seed = 12345 + i + Int(round(p_val * 1000)) + n
        

        state = plaw_raes_graph(n, seed, k, d, p_val)
        

        for r in 1:rounds
            plaw_raes_step_one!(state)
            plaw_raes_step_two!(state, c)
        end
        
 
        r_coeff = assortativity(state.g)
        
        if !isnan(r_coeff)
            push!(r_values, r_coeff)
        end
    end
    
    if isempty(r_values)
        return (p_val, NaN, NaN)
    end

    return (p_val, mean(r_values), std(r_values))
end