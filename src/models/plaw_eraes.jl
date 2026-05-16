using Graphs, Random, Distributions, StatsBase

mutable struct plaw_eraes_graph
    g::SimpleGraph{Int}
    target_degrees::Vector{Int}
    informed_nodes::BitVector  
    rng::AbstractRNG
    
    function plaw_eraes_graph(n::Int, seed::Int, k::Float64, d::Int, prob_default::Float64, prob_downscale::Float64, prob_upscale::Float64, min_d::Int)
        @assert (prob_default + prob_downscale + prob_upscale) == 1
        local_rng = MersenneTwister(seed)
        degs = Vector{Int}(undef, n)
        
        upscale_distr = Pareto(k, 1.0)
        for i in 1:n
            r = rand(local_rng)

            if r < prob_default
                degs[i] = d
            elseif  r < prob_default + prob_downscale 
                degs[i] = rand(local_rng, min_d:(d - 1))
            else
                upscale_val = rand(local_rng, upscale_distr)
                degs[i] = d + round(Int, upscale_val)
            end
        end

        new(
            SimpleGraph(n),       
            degs,          
            falses(n),          
            MersenneTwister(seed) 
        )
    end
end

function plaw_e_raes_step_one!(state::plaw_eraes_graph) 
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

function plaw_e_raes_step_two!(state::plaw_eraes_graph, c::Real) 
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

function plaw_e_raes_step_three!(state::plaw_eraes_graph, p::Real)
    local g = state.g
    local rng = state.rng
    p == 0 && return g
        for e in collect(edges(g))
            if rand(rng) < p
                rem_edge!(g, src(e), dst(e))
            end
        end

    return g
end