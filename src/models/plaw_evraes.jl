using Graphs, Random, Distributions, StatsBase

mutable struct plaw_evraes_graph
    g::SimpleGraph{Int}
    active_nodes::BitVector
    informed_nodes::BitVector
    target_degrees::Dict{Int, Int} 
    rng::AbstractRNG

    p_std::Real
    k::Real
    d::Int
    

    function plaw_evraes_graph(n::Int, seed::Int, k::Real, d::Int, p_std::Real)
        @assert p_std <= 1
        @assert p_std >= 0 
        local_rng = MersenneTwister(seed)
        target_d_dict = Dict{Int, Int}()
        
        pareto_distr = Pareto(k-1, 1.0)
        for i in 1:n
            r = rand(local_rng)

            if r <= p_std
                target_d_dict[i] = d
            else 
                target_d_dict[i] = round(Int, rand(local_rng, pareto_distr))
            end
        end

        new(
            SimpleGraph(n),       
            trues(n),          
            falses(n),          
            target_d_dict, 
            local_rng,
            p_std,
            k,
            d
        )
    end
end


function plaw_ev_raes_step_zero!(state::plaw_evraes_graph, lambda::Float64)
    n_old = nv(state.g)
    
    num_nuovi_nodi = rand(state.rng, Poisson(lambda))
    
    if num_nuovi_nodi == 0
        return n_old
    end

    add_vertices!(state.g, num_nuovi_nodi)
    

    pareto_distr = Pareto(state.k - 1, 1.0)
    
    for i in 1:num_nuovi_nodi
        new_node_id = n_old + i

        push!(state.active_nodes, true)
        push!(state.informed_nodes, false)
        

        r = rand(state.rng)
        
        if r <= state.p_std

            state.target_degrees[new_node_id] = state.d
        else

            val = rand(state.rng, pareto_distr)
            state.target_degrees[new_node_id] = round(Int, val)
        end
    end
    
    return n_old
end


function plaw_ev_raes_step_one!(state::plaw_evraes_graph, n_old::Int)
    g = state.g
    n_total = length(state.active_nodes)
    
    new_edges = Tuple{Int, Int}[]
    deg_snapshot = degree(g) 

    for u in 1:n_total
        if !state.active_nodes[u] continue end
        
        if !haskey(state.target_degrees, u) continue end 
        
        d_u = state.target_degrees[u] 
        current_deg = (u <= length(deg_snapshot)) ? deg_snapshot[u] : 0
        
        need = max(0, d_u - current_deg)
        need == 0 && continue

        forbidden = Set(neighbors(g, u))
        push!(forbidden, u)

        count = 0
        attempts = 0
        max_attempts = need * 50 

        while count < need && attempts < max_attempts
            attempts += 1
            

            if n_old == 0 break end 
            
            target = rand(state.rng, 1:n_old) 

            if state.active_nodes[target] && target ∉ forbidden
                push!(new_edges, (u, target))
                push!(forbidden, target) 
                count += 1
            end
        end
    end
    
    for (u, v) in new_edges
        add_edge!(g, u, v)
    end
end


function plaw_ev_raes_step_two!(state::plaw_evraes_graph, c::Real)
    g = state.g
    rng = state.rng
    deg_snapshot = degree(g)
    edges_to_remove = Set{Edge{Int}}() 

    for u in 1:length(state.active_nodes)
        if !state.active_nodes[u] continue end
        
        if !haskey(state.target_degrees, u) continue end 
        
        d_u = state.target_degrees[u]
        max_deg_u = ceil(Int, d_u * c)
        
        deg_u = (u <= length(deg_snapshot)) ? deg_snapshot[u] : 0
        excess = max(0, deg_u - max_deg_u)
        excess == 0 && continue
        
        current_neighbors = [v for v in neighbors(g, u) if state.active_nodes[v]]
        
        if isempty(current_neighbors) continue end

        k_drop = min(excess, length(current_neighbors))
        neighbors_to_drop = sample(rng, current_neighbors, k_drop, replace=false)
        
        for v in neighbors_to_drop
            push!(edges_to_remove, Edge(min(u,v), max(u,v))) 
        end
    end
    
    for e in edges_to_remove
        rem_edge!(g, e)
    end
end


function plaw_ev_raes_step_three!(state::plaw_evraes_graph, p_edge::Float64)
    if p_edge <= 0 return end
    
    g = state.g
    rng = state.rng 
    

    edges_to_fail = Edge{Int}[]

    for e in edges(g)
        if rand(rng) < p_edge
            push!(edges_to_fail, e)
        end
    end

    for e in edges_to_fail
        rem_edge!(g, e)
    end
end


function plaw_ev_raes_step_four!(state::plaw_evraes_graph, q_node::Float64)
    if q_node <= 0 return end
    
    g = state.g
    nodes_to_remove = Int[]
    

    for u in 1:length(state.active_nodes)
        if state.active_nodes[u] && rand(state.rng) < q_node
            push!(nodes_to_remove, u)
        end
    end

    if isempty(nodes_to_remove) return end

    for u in nodes_to_remove
 
        state.active_nodes[u] = false
        state.informed_nodes[u] = false
        
        delete!(state.target_degrees, u)

        nbrs = collect(neighbors(g, u))
        for v in nbrs
            rem_edge!(g, u, v)
        end
    end
end