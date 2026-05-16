using Graphs, Random, Distributions, StatsBase

mutable struct plaw_raes_graph
    g::SimpleGraph{Int}
    target_degrees::Vector{Int}
    informed_nodes::BitVector  
    rng::AbstractRNG
    
    function plaw_raes_graph(n::Int, seed::Int, k::Real, d::Int, p_std::Real)
        @assert p_std <= 1
        @assert p_std >= 0 
        local_rng = MersenneTwister(seed)
        target_degs = Vector{Int}(undef, n)
        
        pareto_distr = Pareto(k-1, 1.0)
        for i in 1:n
            r = rand(local_rng)

            if r <= p_std
                target_degs[i] = d
            else 
                target_degs[i] = round(Int, rand(local_rng, pareto_distr))
            end
        end

        new(
            SimpleGraph(n),       
            target_degs,          
            falses(n),          
            MersenneTwister(seed) 
        )
    end
end

function plaw_raes_step_one!(state::plaw_raes_graph) 
    local g = state.g
    local rng = state.rng
    n = nv(g)
    new_edges = Tuple{Int, Int}[]
    deg_snapshot = degree(g)

    for u in 1:n
        d_u = state.target_degrees[u]
        need = max(0, d_u - deg_snapshot[u])
        need == 0 && continue

        forbidden = Set(neighbors(g, u))
        push!(forbidden, u)

        if length(forbidden) >= n 
            continue 
        end

        count = 0

        while count < need
            target = rand(rng, 1:n) 

            if target ∉ forbidden
                push!(new_edges, (u, target))
                #push!(forbidden, target)  #(without replacement)
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

function plaw_raes_step_two!(state::plaw_raes_graph, c::Real) 
    local g = state.g
    local rng = state.rng
    deg_snapshot = degree(g)

    edges_to_remove = Set{Edge{Int}}()
    
    for u in vertices(g)
        d_u = state.target_degrees[u]
        max_deg_u = ceil(Int, d_u * c)
        deg_u = deg_snapshot[u]
        excess = max(0, deg_u - max_deg_u)
        excess == 0 && continue
        
        current_neighbors = neighbors(g, u)
        to_drop = sample(rng, current_neighbors, excess, replace=true)
        
        for v in to_drop
            push!(edges_to_remove, Edge(min(u,v), max(u,v)))
        end
    end
    

    for e in edges_to_remove
        rem_edge!(g, e)
    end
    
    return g
end

