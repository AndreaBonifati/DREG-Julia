using Graphs, Random, Distributions, StatsBase

mutable struct plaw_c_raes_graph
    g::SimpleGraph{Int}
    c_factors::Vector{Float64} 
    d::Int                    
    informed_nodes::BitVector  
    rng::AbstractRNG
    

    function plaw_c_raes_graph(n::Int, seed::Int, k::Real, d::Int, c_std::Real, p_std::Real)
        @assert p_std <= 1
        @assert p_std >= 0 
        local_rng = MersenneTwister(seed)
        

        c_factors = Vector{Float64}(undef, n)
        

        pareto_distr = Pareto(k-1, 1.0)
        
        for i in 1:n
            r = rand(local_rng)

            if r <= p_std

                c_factors[i] = c_std
            else 

                c_factors[i] = rand(local_rng, pareto_distr)
                

            end
        end

        new(
            SimpleGraph(n),       
            c_factors,
            d,          
            falses(n),          
            MersenneTwister(seed) 
        )
    end
end

function plaw_c_raes_step_one!(state::plaw_c_raes_graph) 
    local g = state.g
    local rng = state.rng
    n = nv(g)
    new_edges = Tuple{Int, Int}[]
    deg_snapshot = degree(g)
    

    d_target = state.d

    for u in 1:n

        need = max(0, d_target - deg_snapshot[u])
        need == 0 && continue

        forbidden = Set(neighbors(g, u))
        push!(forbidden, u)

        if length(forbidden) >= n 
            continue 
        end

        count = 0

        attempts = 0
        max_attempts = need * 50 

        while count < need && attempts < max_attempts
            attempts += 1
            
            target = rand(rng, 1:n) 

            if target ∉ forbidden
                push!(new_edges, (u, target))
                count += 1
            end
        end
    end

    for (u, v) in new_edges
        if !has_edge(g, u, v) 
            add_edge!(g, u, v)
        end
    end
    return g
end


function plaw_c_raes_step_two!(state::plaw_c_raes_graph) 
    local g = state.g
    local rng = state.rng
    deg_snapshot = degree(g)

    edges_to_remove = Set{Edge{Int}}()
    
    d_target = state.d 
    
    for u in vertices(g)

        c_u = state.c_factors[u]
        max_deg_u = ceil(Int, d_target * c_u)
        
        deg_u = deg_snapshot[u]
        excess = max(0, deg_u - max_deg_u)
        excess == 0 && continue
        
        current_neighbors = neighbors(g, u)
        

        to_drop = sample(rng, current_neighbors, excess, replace=false)
        
        for v in to_drop
            push!(edges_to_remove, Edge(min(u,v), max(u,v)))
        end
    end
    
    for e in edges_to_remove
        rem_edge!(g, e)
    end
    
    return g
end