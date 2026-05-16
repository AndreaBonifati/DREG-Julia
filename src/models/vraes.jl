using Graphs, Random, Distributions, StatsBase

mutable struct vraes_graph
    g::SimpleGraph{Int}
    active_nodes::BitVector  # active_nodes[i]=true se nodo available, false altrimenti
    informed_nodes::BitVector  # Per flooding, informed_nodes[i] = true se nodo i è informato
    rng::AbstractRNG
    
    function vraes_graph(n::Int, seed::Int)
        new(
            SimpleGraph(n),       # g
            trues(n),          # active_nodes 
            falses(n),          # informed_nodes 
            MersenneTwister(seed) # rng
        )
    end
end

function v_raes_step_zero!(state::vraes_graph, lambda::Float64)
    n_old = nv(state.g)
    num_nuovi_nodi = rand(state.rng, Poisson(lambda))
    if num_nuovi_nodi == 0
        return n_old
    end
    
    add_vertices!(state.g, num_nuovi_nodi)

    append!(state.active_nodes, trues(num_nuovi_nodi))
    append!(state.informed_nodes, falses(num_nuovi_nodi)) 
    
    return n_old
end

function v_raes_step_one!(state::vraes_graph, d::Int, n_old::Int)
    g = state.g
    n_total = nv(g) 
    new_edges = Tuple{Int, Int}[]
    deg_snapshot = degree(g)

    for u in 1:n_total
        if !state.active_nodes[u]
            continue
        end
        
        need = max(0, d - deg_snapshot[u])
        need == 0 && continue

        forbidden = Set(neighbors(g, u))
        push!(forbidden, u)

        count = 0

        attempts = 0
        max_attempts = need * 50 

        while count < need && attempts < max_attempts
            attempts += 1
            
            target = rand(state.rng, 1:n_old)

            if state.active_nodes[target] && target ∉ forbidden
                push!(new_edges, (u, target))

                count += 1
            end
        end
    end
    
    for (u, v) in new_edges
        !has_edge(g, u, v) && add_edge!(g, u, v)
    end
end

function v_raes_step_two!(state::vraes_graph, d::Int, c::Real)
    g = state.g
    rng = state.rng
    max_deg = ceil(Int, d * c)


    edges_to_remove = Set{Edge{Int}}() 
    

    deg_snapshot = degree(g)


    for u in findall(state.active_nodes)
        
        deg_u = deg_snapshot[u] 
        excess = max(0, deg_u - max_deg)
        
        excess == 0 && continue
        
        current_neighbors = neighbors(g, u)
        
        neighbors_to_drop = sample(rng, current_neighbors, excess, replace=true)
        
        for v in neighbors_to_drop
            push!(edges_to_remove, Edge(u, v)) 
        end
    end
    
    for e in edges_to_remove
        rem_edge!(g, e)
    end
end

function v_raes_step_three!(state::vraes_graph, q::Float64)
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

        neighbors_copy = collect(neighbors(g, u))
        for v in neighbors_copy
            rem_edge!(g, u, v)
        end
    end
end