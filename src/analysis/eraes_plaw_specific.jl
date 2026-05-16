function run_serial_spectral_gap_experiment_eraes_plaw(state::plaw_eraes_graph, c::Real, p::Real, rounds::Int)
    spectral_gaps = Float64[]
    local skip_rounds = 0 # Impostare a numero di round iniziali che si vogliono saltare

    for r in 1:rounds
        plaw_e_raes_step_one!(state)
        plaw_e_raes_step_two!(state, c)

        local gap::Float64
        if r < skip_rounds
            gap = 0.0
        else
            gap = spectral_gap(state.g)
        end
        
        push!(spectral_gaps, gap)
        plaw_e_raes_step_three!(state , p)
    end
    return spectral_gaps
end


function calculate_average_gap_before_failure_eraes_plaw(n::Int, d_default::Int, c::Real, p::Real, k::Real, prob_default::Real, prob_upscale::Real, prob_downscale::Real, min_d::Real, num_runs::Int, num_rounds::Int, skip_initial_rounds::Int)
    
    total_gaps_for_p = Float64[]
    for run in 1:num_runs
        local seed = 1234 + run + Int(p*1000) + n
        local state = plaw_eraes_graph(n, seed, k, d_default, prob_default, prob_downscale, prob_upscale, min_d )
        
        run_gaps = Float64[]

        for r in 1:num_rounds

            plaw_e_raes_step_one!(state)
            plaw_e_raes_step_two!(state, c)

            if r > skip_initial_rounds

                gap = spectral_gap(state.g)
                push!(run_gaps, gap)
            end
            
            plaw_e_raes_step_three!(state , p)
        end
        

        if !isempty(run_gaps)
            push!(total_gaps_for_p, mean(run_gaps)) 
        end
    end

    if isempty(total_gaps_for_p)
        @warn "No stable gaps collected for n=$n, p=$p"
        return 0.0
    end
    
    return mean(total_gaps_for_p)
end




function measure_flooding_time_eraes_plaw(n::Int, d_default::Int, c::Real, p::Real, k::Real, prob_default::Real, prob_upscale::Real, prob_downscale::Real, min_d::Real,t0_skip::Int, simulation_rounds::Int)
    
    local seed = 1234 + Int(p*1000) + n
    local state = plaw_eraes_graph(n, seed, k, d_default, prob_default, prob_downscale, prob_upscale, min_d )
    local active_nodes = trues(n)
    local all_informed = deepcopy(state.informed_nodes)

    for r in 1:t0_skip
        plaw_e_raes_step_one!(state)
        plaw_e_raes_step_two!(state, c)
        plaw_e_raes_step_three!(state , p)
    end


    local starter_node = rand(state.rng, 1:n)
    all_informed[starter_node] = true
    
    local flooding_rounds = 0
    

    if count(all_informed) == n
        return 0
    end



    max_simulation_rounds = t0_skip + simulation_rounds
    
    for r in (t0_skip + 1):max_simulation_rounds
        flooding_rounds += 1
        
        plaw_e_raes_step_one!(state)
        plaw_e_raes_step_two!(state, c)
        plaw_e_raes_step_three!(state , p)
        
        flooding_step!(all_informed, state.g, active_nodes)
        

        if count(all_informed) == n
            return flooding_rounds 
        end
    end
    
    @warn "Flooding non completato per (n=$n, p=$p) dopo $flooding_rounds round extra."
    return flooding_rounds
end

"""
Funzione che esegue N simulazioni di flooding e ne calcola la media.
"""
function calculate_average_flooding_time_eraes_plaw(n::Int, d_default::Int, c::Real, p::Real, k::Real, prob_default::Real, prob_upscale::Real, prob_downscale::Real, min_d::Real,t0_skip::Int, simulation_rounds::Int, num_runs::Int)
    times = Float64[]
    
    for i in 1:num_runs
        time_taken = measure_flooding_time_eraes_plaw(n, d_default, c, p, k, prob_default, prob_upscale, prob_downscale, min_d, t0_skip, simulation_rounds) 
        push!(times, time_taken)
    end
    
    return mean(times)
end