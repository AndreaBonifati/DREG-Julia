using Base.Threads

function e_raes_step_one!(g::SimpleGraph{Int}, d::Int; rng=Random.GLOBAL_RNG) 
    n = nv(g)
    new_edges = Tuple{Int, Int}[]
    deg_snapshot = degree(g)

    for u in 1:n
        need = max(0, d - deg_snapshot[u])
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


function e_raes_step_two!(g::SimpleGraph{Int}, d::Int, c::Real; rng=Random.GLOBAL_RNG) 
    deg_snapshot = degree(g)
    max_deg = ceil(Int, d * c)
    
    edges_to_remove = Set{Edge{Int}}()
    
    for u in vertices(g)
        excess = max(0, deg_snapshot[u] - max_deg)
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

function e_raes_step_three!(g::SimpleGraph{Int}, p::Real; rng = Random.GLOBAL_RNG)
    p == 0 && return g
        for e in collect(edges(g))
            if rand(rng) < p
                rem_edge!(g, src(e), dst(e))
            end
        end

    return g
end

function e_raes_round!(g::SimpleGraph{Int}, d::Int, c::Real, p::Real; rng = Random.GLOBAL_RNG)
    @assert 0 ≤ p ≤ 1
    @assert d ≥ 0 && c ≥ 1

    e_raes_step_one!(g,d; rng = rng)
    e_raes_step_two!(g,d,c; rng = rng)
    e_raes_step_three!(g,p; rng = rng)

    return g
end

function e_raes!(g::SimpleGraph{Int}, d::Int, c::Real, p::Real, rounds::Int ; rng = Random.GLOBAL_RNG)
    for r in 1:rounds
        e_raes_round!(g,d,c,p; rng = rng)
    end
    return g
end

function e_raes_snapshots!(g::SimpleGraph{Int}, d::Int, c::Real, p::Real, rounds::Int ; rng = Random.GLOBAL_RNG)
    snapshots = Vector{SimpleGraph}(undef, rounds)
    for r in 1:rounds
        #println("Round: $r")
        e_raes_round!(g, d, c, p; rng)
        snapshots[r] = deepcopy(g)
    end
    return snapshots
end


function e_raes_threaded_step_one!(g::SimpleGraph{Int}, d::Int; rng=Random.GLOBAL_RNG)
    n = nv(g)
    deg_snapshot = degree(g)

    rngs = [MersenneTwister(rand(rng, UInt)) for _ in 1:Threads.nthreads()]

    thread_edges = [Vector{Tuple{Int,Int}}() for _ in 1:Threads.nthreads()]

    Threads.@threads for u in 1:n
        tid = threadid()
        local_rng = rngs[tid]

        need = max(0, d - deg_snapshot[u])
        need == 0 && continue

        taken = Set(neighbors(g,u))
        push!(taken, u) 

  
        count = 0
        while count < need
            v = rand(local_rng, 1:n)
            if v ∉ taken
                push!(thread_edges[tid], (u,v))
                # push!(taken, v) if included, the sampling is without replacement
                count += 1
            end
        end
    end


    for edge_list in thread_edges
        for (u,v) in edge_list
            if !has_edge(g, u, v)
                add_edge!(g, u, v)
            end
        end
    end

    return g
end


function e_raes_threaded_step_two!(g::SimpleGraph{Int}, d::Int, c::Real; rng=Random.GLOBAL_RNG)
    n = nv(g)
    deg_snapshot = degree(g)

    rngs = [MersenneTwister(rand(rng, UInt)) for _ in 1:Threads.nthreads()]

    thread_drops = [Vector{Tuple{Int,Int}}() for _ in 1:Threads.nthreads()]

    Threads.@threads for u in 1:n
        tid = threadid()
        local_rng = rngs[tid]

        excess = max(0, deg_snapshot[u] - ceil(Int, d*c))
        excess == 0 && continue

        neighs = collect(neighbors(g,u))
        if !isempty(neighs)
            chosen = [rand(local_rng, neighs) for _ in 1:excess]
            for v in chosen
                push!(thread_drops[tid], (u,v))
            end
        end
    end

    for drop_list in thread_drops
        for (u,v) in drop_list
            has_edge(g,u,v) && rem_edge!(g,u,v)
        end
    end

    return g
end

function e_raes_threaded_round!(g::SimpleGraph{Int}, d::Int, c::Real, p::Real; rng = Random.GLOBAL_RNG)
    @assert 0 ≤ p ≤ 1
    @assert d ≥ 0 && c ≥ 1

    e_raes_threaded_step_one!(g,d; rng = rng)
    e_raes_threaded_step_two!(g,d,c; rng = rng)
    e_raes_step_three!(g,p; rng = rng)

    return g
end

function e_raes_threaded!(g::SimpleGraph{Int}, d::Int, c::Real, p::Real, rounds::Int ; rng = Random.GLOBAL_RNG)
    for r in 1:rounds
        e_raes_threaded_round!(g,d,c,p; rng = rng)
    end
    return g
end

function e_raes_threaded_snapshots!(g::SimpleGraph{Int}, d::Int, c::Real, p::Real, rounds::Int ; rng = Random.GLOBAL_RNG)
    snapshots = Vector{SimpleGraph}(undef, rounds)
    for r in 1:rounds
        #println("Round: $r")
        e_raes_threaded_round!(g, d, c, p; rng)
        snapshots[r] = deepcopy(g)
    end
    return snapshots
end