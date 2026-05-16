"""
Funzione che prende un vettore di grafi, un intero d e un reale c e verifica,
per ogni grafo, quanti nodi si trovano sotto la soglia d e quanti nodi superano
la soglia c*d.
"""
function analyze_degree_snapshots(snapshots::Vector{SimpleGraph}, d::Int, c::Real)
    println("Analisi Gradi per Round")
    for r in 1:length(snapshots)
        g_r = snapshots[r]
        degs = degree(g_r)
        nodes_under_threshold = count(<(d), degs)
        nodes_over_threshold  = count(>=(c*d), degs)
        println("Round $r: $nodes_under_threshold nodi < $d, $nodes_over_threshold nodi > $(c*d)")
    end
end


function calculate_degree_stats(graphs::Vector{SimpleGraph}, d::Int, c::Real)
    rounds = length(graphs)
    low_degree = zeros(Int, rounds)
    high_degree = zeros(Int, rounds)

    for r in 1:rounds
        degs = degree(graphs[r])
        low_degree[r] = count(<(d), degs)
        high_degree[r] = count(>(c*d), degs)
    end

    return low_degree, high_degree
end

"""
Calcola la matrice di conteggio dei gradi per generare una heatmap.
"""
function calculate_degree_heatmap_data(graphs::Vector{SimpleGraph})
    rounds = length(graphs)
    max_deg = isempty(graphs) ? 0 : maximum(g -> maximum(degree(g), init=0), graphs)
    deg_counts = zeros(Int, max_deg + 1, rounds)

    for r in 1:rounds
        degs = degree(graphs[r])
        for k in 0:max_deg
            deg_counts[k+1, r] = count(==(k), degs)
        end
    end
    return deg_counts
end

"""
Dato un vettore di gap spettrali, ne calcola la mean absolute deviation,
prendendo in considerazione solamente i valori maggiori di zero.
"""

function compute_epsilon(spectral_gaps::Vector{Float64})
    non_zero_gaps = filter( x -> x > 0.0, spectral_gaps)

    if isempty(non_zero_gaps)
        return 0.0
    end

    mu = mean(non_zero_gaps)
    epsilon = mean(abs.(non_zero_gaps .- mu))
    return epsilon
end

"""
Trova il primo round dove il grafo raggiunge stabilità.
Criterio: Tutti i gap in una finestra di log_{2}(n) round 
devono differire dall'ultimo gap (gap_t) al massimo di eps.
"""

function compute_t0(spectral_gaps::Vector{Float64}, n::Int, epsilon::Float64)

    window_size = ceil(Int, log2(n))
    
    if length(spectral_gaps) < window_size
        return -1
    end
    
    for i in window_size:length(spectral_gaps)
        start_index = i - window_size + 1
        window = @view spectral_gaps[start_index:i]
        
        gap_t = window[end] 
        

        is_stable = true
        for gap_i in window
            if abs(gap_i - gap_t) > epsilon
                is_stable = false
                break 
            end
        end

        if is_stable
            return i # Primo round stabile.
        end
    end
    
    return -1 # Round stabile non trovato.
end

