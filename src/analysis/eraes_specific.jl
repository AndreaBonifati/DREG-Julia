function run_spectral_gap_experiment(g::SimpleGraph, d::Int, c::Real, p::Real, rounds::Int; rng=Random.GLOBAL_RNG)
    spectral_gaps = Float64[]

    println("Starting simulation")
    for r in 1:rounds
        print("Round $r/$rounds\r")

        e_raes_threaded_step_one!(g, d; rng=rng)
        
        e_raes_threaded_step_two!(g, d, c; rng=rng)

        gap = spectral_gap(g)
        println("Spectral gap: $gap")
        push!(spectral_gaps, gap)

        e_raes_step_three!(g, p; rng=rng)
    end
    
    println("\nSimulation finished.")
    return spectral_gaps
end

"""
Funzione utilizzata per emulare esperimento 1 del paper (Sezione 3.1 convergence criterion)
"""

function run_serial_spectral_gap_experiment_eraes(g::SimpleGraph, d::Int, c::Real, p::Real, rounds::Int; rng=Random.GLOBAL_RNG)
    spectral_gaps = Float64[]
    local skip_rounds = 0 # Impostare a numero di round iniziali che si vogliono saltare

    for r in 1:rounds
        e_raes_step_one!(g, d; rng=rng)
        e_raes_step_two!(g, d, c; rng=rng)

        local gap::Float64
        if r < skip_rounds
            gap = 0.0
        else
            gap = spectral_gap(g)
        end
        
        push!(spectral_gaps, gap)
        e_raes_step_three!(g, p; rng=rng)
    end
    return spectral_gaps
end

"""
Funzione usata per emulare esperimento 2 del paper (Sezione 3.2 Average spectral gap in the long run)
"""
function calculate_average_gap_before_failure_eraes(n::Int, d::Int, c::Real, p::Real; num_runs::Int=10, num_rounds::Int=100, skip_initial_rounds::Int=30 )
    
    total_gaps_for_p = Float64[]
    for run in 1:num_runs
        g = SimpleGraph(n)
        rng = MersenneTwister(1234 + run + Int(p*1000) + n) 
        run_gaps = Float64[]

        for r in 1:num_rounds

            e_raes_step_one!(g, d; rng=rng)
            e_raes_step_two!(g, d, c; rng=rng)

            if r > skip_initial_rounds

                gap = spectral_gap(g)
                push!(run_gaps, gap)
            end
            
            e_raes_step_three!(g, p; rng=rng)
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

"""
Funzione usata per emulare esperimento 3 del paper (Sezione 3.3 flooding time analysis)
"""

function measure_flooding_time_eraes(n::Int, d::Int, c::Real, p::Real, t0_skip::Int, simulation_rounds::Int ; base_rng::AbstractRNG)
    
    local g = SimpleGraph(n)
    local active_nodes = trues(n)
    local all_informed = falses(n)
    local rng = deepcopy(base_rng) 

    for r in 1:t0_skip
        e_raes_step_one!(g, d; rng=rng)
        e_raes_step_two!(g, d, c; rng=rng)
        e_raes_step_three!(g, p; rng=rng)
    end


    local starter_node = rand(rng, 1:n)
    all_informed[starter_node] = true
    
    local flooding_rounds = 0
    

    if count(all_informed) == n
        return 0
    end



    max_simulation_rounds = t0_skip + simulation_rounds
    
    for r in (t0_skip + 1):max_simulation_rounds
        flooding_rounds += 1
        
        e_raes_step_one!(g, d; rng=rng)
        e_raes_step_two!(g, d, c; rng=rng)
        e_raes_step_three!(g, p; rng=rng)
        
        flooding_step!(all_informed, g, active_nodes)
        

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
function calculate_average_flooding_time_eraes(n, d, c, p, t0_skip, num_runs, simulation_rounds; base_seed=123)
    times = Float64[]
    
    for i in 1:num_runs
        run_rng = MersenneTwister(base_seed + i + n + Int(p*100))
        time_taken = measure_flooding_time_eraes(n, d, c, p, t0_skip, simulation_rounds; base_rng=run_rng)
        push!(times, time_taken)
    end
    
    return mean(times)
end