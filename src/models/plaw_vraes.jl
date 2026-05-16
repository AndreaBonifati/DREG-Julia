using Graphs, Random, Distributions, StatsBase

mutable struct plaw_vraes_graph
    g::SimpleGraph{Int}
    active_nodes::BitVector
    informed_nodes::BitVector
    target_degrees::Dict{Int, Int} 
    rng::AbstractRNG
    
    k::Float64
    d_default::Int
    prob_default::Float64
    prob_downscale::Float64
    prob_upscale::Float64
    min_d::Int
    

    function plaw_vraes_graph(
        n::Int, 
        seed::Int, 
        k::Float64, 
        d::Int, 
        prob_default::Float64, 
        prob_downscale::Float64, 
        prob_upscale::Float64, 
        min_d::Int
    )
        
        @assert (prob_default + prob_downscale + prob_upscale) == 1
        local_rng = MersenneTwister(seed)
        
        target_d_dict = Dict{Int, Int}()
        upscale_distr = Pareto(k, 1.0)

        for i in 1:n
            r = rand(local_rng)
            if r < prob_default
                target_d_dict[i] = d
            elseif r < prob_default + prob_downscale 
                target_d_dict[i] = rand(local_rng, min_d:(d - 1))
            else
                upscale_val = rand(local_rng, upscale_distr)
                target_d_dict[i] = d + round(Int, upscale_val)
            end
        end

        new(
            SimpleGraph(n),       
            trues(n),          
            falses(n),          
            target_d_dict, 
            local_rng,     
            k, d, prob_default, prob_downscale, prob_upscale, min_d
        )
    end
end

function plaw_v_raes_step_zero!(state::plaw_vraes_graph, lambda::Float64)
    n_old = nv(state.g)
    num_nuovi_nodi = rand(state.rng, Poisson(lambda))
    if num_nuovi_nodi == 0
        return n_old
    end
    
    add_vertices!(state.g, num_nuovi_nodi)
    

    upscale_distr = Pareto(state.k, 1.0)
    
    for i in 1:num_nuovi_nodi
        new_node_id = n_old + i
        

        push!(state.active_nodes, true)
        push!(state.informed_nodes, false)
        
        r = rand(state.rng)
        d_default = state.d_default
        
        local new_d_u::Int
        if r < state.prob_default
            new_d_u = d_default
        elseif r < state.prob_default + state.prob_downscale
            new_d_u = rand(state.rng, state.min_d:(d_default - 1))
        else
            upscale_val = rand(state.rng, upscale_distr)
            new_d_u = d_default + round(Int, upscale_val)
        end
        
        state.target_degrees[new_node_id] = new_d_u
    end
    
    return n_old
end

function plaw_v_raes_step_one!(state::plaw_vraes_graph, n_old::Int)
    g = state.g
    n_total = nv(g) 
    new_edges = Tuple{Int, Int}[]
    deg_snapshot = degree(g)

    for u in 1:n_total
        if !state.active_nodes[u]
            continue
        end
        
        d_u = state.target_degrees[u] 
        
        need = max(0, d_u - deg_snapshot[u])
        need == 0 && continue

        forbidden = Set(neighbors(g, u))
        push!(forbidden, u)

        count = 0
        attempts = 0
        max_attempts = need * 50 

        while count < need && attempts < max_attempts
            attempts += 1
            target = rand(state.rng, 1:n_old) 

            if target <= length(state.active_nodes) && state.active_nodes[target] && target ∉ forbidden
                push!(new_edges, (u, target))
                count += 1
            end
        end
    end
    
    for (u, v) in new_edges
        !has_edge(g, u, v) && add_edge!(g, u, v)
    end
end

function plaw_v_raes_step_two!(state::plaw_vraes_graph, c::Real)
    g = state.g
    rng = state.rng
    deg_snapshot = degree(g)
    edges_to_remove = Set{Edge{Int}}() 

    for u in findall(state.active_nodes)
        
        d_u = state.target_degrees[u]
        max_deg_u = ceil(Int, d_u * c)
        
        deg_u = deg_snapshot[u] 
        excess = max(0, deg_u - max_deg_u)
        excess == 0 && continue
        
        current_neighbors = filter(v -> state.active_nodes[v], neighbors(g, u))
        if isempty(current_neighbors) continue end

        neighbors_to_drop = sample(rng, current_neighbors, excess, replace=true)
        
        for v in neighbors_to_drop
            push!(edges_to_remove, Edge(min(u,v), max(u,v))) 
        end
    end
    
    for e in edges_to_remove
        rem_edge!(g, e)
    end
end

function plaw_v_raes_step_three!(state::plaw_vraes_graph, q::Float64)
    g = state.g
    nodes_to_remove = Int[]
    
    for u in findall(state.active_nodes)
        if rand(state.rng) < q
            push!(nodes_to_remove, u)
        end
    end

    if isempty(nodes_to_remove)
        return
    end

    for u in nodes_to_remove
        state.active_nodes[u] = false
        state.informed_nodes[u] = false

        delete!(state.target_degrees, u)

        neighbors_copy = collect(neighbors(g, u))
        for v in neighbors_copy
            rem_edge!(g, u, v)
        end
    end
end