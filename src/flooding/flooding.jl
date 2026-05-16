using Base.Threads, Random

"""
Singolo passo di flooding. Prende un vettore di nodi informati, un grafo semplice e un 
vettore contenente i nodi attivi nella rete. Informa tutti i vicini dei nodi informati.
"""
function flooding_step!(all_informed::BitVector, g::SimpleGraph, active_nodes::BitVector)

    all_informed .&= active_nodes

    newly_informed = Set{Int}()

    for u in findall(all_informed)
        for v in neighbors(g, u)
            if v <= length(active_nodes) && active_nodes[v] && !all_informed[v]
                push!(newly_informed, v)
            end
        end
    end

    for v in newly_informed
        if v <= length(all_informed)
            all_informed[v] = true
        end
    end

    return nothing
end


"""
********************************************************************************
Le successive funzioni sono di prova e NON vengono utilizzate dagli esperimenti.
********************************************************************************
"""
function threaded_flooding_step_dynamic(g::SimpleGraph, all_informed::Set{Int}, notified_neighbors::Dict{Int, Set{Int}})
    nthreads = Threads.nthreads()
    thread_new = [Vector{Int}() for _ in 1:nthreads]  

    nodes_to_check =  collect(all_informed)

    Threads.@threads for i in eachindex(nodes_to_check)
        tid = threadid()
        u = nodes_to_check[i]

        for v in neighbors(g, u)
            if v ∉ already_notified && v ∉ all_informed
                push!(thread_new[tid], v)
            end
        end

        notified_neighbors[u] = Set(neighbors(g, u))
    end


    new_frontier = Set{Int}()
    for buf in thread_new
        union!(new_frontier, buf)
    end


    union!(all_informed, new_frontier)

    return collect(new_frontier), all_informed, notified_neighbors
end


function flooding_dynamic(snapshots::Vector{SimpleGraph}; rng = Random.GLOBAL_RNG)
    g0 = snapshots[1]
    s = rand(rng, vertices(g0))  
    all_informed = Set([s])
    frontier = [s]
    notified_neighbors = Dict{Int, Set{Int}}()
    results = Vector{Set{Int}}(undef, length(snapshots))

    for (i, g) in enumerate(snapshots)
        new_frontier, all_informed, notified_neighbors = threaded_flooding_step_dynamic(g, all_informed, notified_neighbors)
        frontier = new_frontier
        results[i] = copy(all_informed)
        println("Round $i: $(length(all_informed)) nodes informed")
    end

    return results

end

function flooding_dynamic_verbose(snapshots::Vector{SimpleGraph}; rng=Random.GLOBAL_RNG)
    g0 = snapshots[1]
    s = rand(rng, vertices(g0))
    all_informed = Set([s])
    frontier = [s]
    notified_neighbors = Dict{Int, Set{Int}}()
    results = Vector{Set{Int}}(undef, length(snapshots))

    println("Initial source node: $s")

    for (i, g) in enumerate(snapshots)
        new_frontier, all_informed, notified_neighbors = threaded_flooding_step_dynamic(
            g, frontier, all_informed, notified_neighbors
        )
        frontier = new_frontier
        results[i] = copy(all_informed)


        sorted_nodes = sort(collect(all_informed))
        println("Round $i: $(length(all_informed)) nodes informed -> $sorted_nodes")
    end

    return results
end

function flooding_colors(snapshots::Vector{SimpleGraph}; rng=Random.GLOBAL_RNG)
    g0 = snapshots[1]
    s = rand(rng, vertices(g0))
    all_informed = Set([s])
    frontier = [s]
    notified_neighbors = Dict{Int, Set{Int}}()
    color_snapshots = Vector{Vector{Int}}(undef, length(snapshots))  

    for (i, g) in enumerate(snapshots)
        new_frontier, all_informed, notified_neighbors = threaded_flooding_step_dynamic(
            g, frontier, all_informed, notified_neighbors
        )
        frontier = new_frontier
        colors = [in(node, all_informed) ? 1 : 0 for node in vertices(g)]
        color_snapshots[i] = colors
    end

    return color_snapshots
end


function flooding_step_dynamic( g::SimpleGraph, frontier::Set{Int}, all_informed::Set{Int}, notified_neighbors::Dict{Int, Set{Int}})

    new_frontier = Set{Int}()


    for u in all_informed
        already_notified = get(notified_neighbors, u, Set{Int}())
        for v in neighbors(g, u)
            if v ∉ all_informed && v ∉ already_notified
                push!(all_informed, v)
                push!(new_frontier, v)
            end
        end

        notified_neighbors[u] = union(already_notified, Set(neighbors(g, u)))
    end

    return new_frontier, all_informed, notified_neighbors
end


function basic_flood(g::Graph, source::Int)
    visited = falses(nv(g))   
    queue = [source]          
    visited[source] = true
    
    while !isempty(queue)
        node = popfirst!(queue)   
        @show node                

        for nbr in neighbors(g, node)
            if !visited[nbr]
                visited[nbr] = true
                push!(queue, nbr)
            end
        end
    end
    
    return visited
end


function parallel_flood(g::Graph, source::Int)
    visited = falses(nv(g))
    visited[source] = true
    frontier = [source]

    while !isempty(frontier)
        next_frontier = Channel{Int}(Inf)

        @threads for node in frontier
            for nbr in neighbors(g, node)
                if !visited[nbr]
                    lock(() -> begin
                        if !visited[nbr]
                            visited[nbr] = true
                            put!(next_frontier, nbr)
                        end
                    end)
                end
            end
        end

        frontier = collect(next_frontier)
    end

    return visited
end
