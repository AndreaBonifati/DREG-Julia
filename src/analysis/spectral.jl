"""
Calcola lo spectral gap del grafo g.

Lo spectral gap è il secondo più piccolo autovalore del Laplaciano Normalizzato
del grafo. Corrisponde a 1 - λ₂, dove λ₂ è il secondo più grande autovalore
della matrice di transizione di un random walk sul grafo.

Restituisce 0.0 se il grafo non è connesso o ha meno di 2 nodi.
"""

function spectral_gap(g::SimpleGraph{Int})
    if !is_connected(g) || nv(g) < 3
        return 0.0
    end

    degs = degree(g)
    if any(iszero, degs)
        return 0.0
    end

    n = nv(g)
    A = adjacency_matrix(g, Float64)
    D_inv_sqrt = 1.0 ./ sqrt.(degs)

    function L_mul(x)
        tmp = D_inv_sqrt .* x
        Ax = A * tmp
        return x .- D_inv_sqrt .* Ax
    end

    op = (x -> L_mul(x))
    vals, _, _ = eigsolve(op, n, 2, :SR; tol=1e-6, maxiter=500)

    return real(vals[2])
end

function spectral_gap2(g::SimpleGraph{Int})
    if !is_connected(g) || nv(g) < 3
        return 0.0
    end
    degs = degree(g)
    if any(iszero, degs)
        return 0.0
    end

    A = adjacency_matrix(g, Float64)
    D_inv_sqrt = spdiagm(0 => 1.0 ./ sqrt.(degs))
    Id = spdiagm(0 => ones(Float64, nv(g)))
    L_norm = Id - D_inv_sqrt * A * D_inv_sqrt


    vals, _, _ = eigs(L_norm, nev=2, which=:SR)
    
    return real(vals[2])
end

function spectral_gap_classical(g::SimpleGraph{Int})
    if !is_connected(g) || nv(g) < 3; return 0.0; end
    degs = degree(g); if any(iszero, degs); return 0.0; end


    A = adjacency_matrix(g, Float64)
    D_inv = spdiagm(0 => 1.0 ./ degs)
    P = D_inv * A


    all_eigenvalues = eigvals(Matrix(P))
    
    sorted_vals = sort(real.(all_eigenvalues), rev=true)
    
    return sorted_vals[1] - sorted_vals[2]
end

function spectral_gap_paper_style(g::SimpleGraph{Int})
    if nv(g) <= 2 || !is_connected(g)
        return 0.0
    end

    degs = degree(g)
    if any(iszero, degs)
        return 0.0
    end

    A = adjacency_matrix(g, Float64)
    D_inv = spdiagm(0 => 1.0 ./ degs)
    P = D_inv * A

    vals, _, _ = eigsolve(P, 2, :LR)  
    vals = sort(real(vals); rev=true)
    λ1, λ2 = vals[1], vals[2]
    sg = λ1 - λ2  
    return sg
end

using Graphs, LinearAlgebra, KrylovKit, SparseArrays

function spectral_gap_lcc(g_input::SimpleGraph{Int})

    if !is_connected(g_input)
        comps = connected_components(g_input)
        if isempty(comps) return 0.0 end
        

        largest_comp_nodes = comps[argmax(length.(comps))]
        

        if length(largest_comp_nodes) < 3
            return 0.0
        end


        g, _ = induced_subgraph(g_input, largest_comp_nodes)
    else
        g = g_input
    end


    n = nv(g)
    if n < 3
        return 0.0
    end

    degs = degree(g)

    if any(iszero, degs)
        return 0.0
    end


    A = adjacency_matrix(g, Float64)
    D_inv_sqrt = 1.0 ./ sqrt.(degs)

    # Operatore lineare implicito L = I - D^-1/2 * A * D^-1/2
    function L_mul(x)
        tmp = D_inv_sqrt .* x
        Ax = A * tmp
        return x .- (D_inv_sqrt .* Ax)
    end

    op = (x -> L_mul(x))

    try
        # :SR = Smallest Real part. Cerca i primi 2 autovalori.
        vals, _, _ = eigsolve(op, n, 2, :SR; tol=1e-5, maxiter=500)
        
        # Il gap spettrale del Laplaciano Normalizzato è esattamente lambda_2
        # (perché lambda_1 = 0)
        return real(vals[2])
    catch e
        # Fallback nel caso in cui eigsolve non converga
        return 0.0
    end
end