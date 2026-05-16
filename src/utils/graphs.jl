"""
Funzione di debugging utilizzata per vedere se, dopo uno step di una dinamica
esistono dei nodi aventi grado che non hanno raggiunto il treshold 
"""

function check_degree(g::SimpleGraph, d::Int)
    n = nv(g)
    deg = degree(g)
    for i in 1:n
        if deg[i] < d
            println("Node $i didn't reach the treshold, her degree is $(deg[i])")
        end
    end
end