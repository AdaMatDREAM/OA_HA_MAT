using Graphs
using GraphsFlows

num_vertices = 8
source_node = 1  # r
sink_node = 2    # s

# Opret en orienteret graf (DiGraph)
g = SimpleDiGraph(num_vertices)

# Tilføj kanterne til grafen
edges_to_add = [
    (1, 7), # r -> p
    (7, 4), # p -> b
    (4, 2), # b -> s
    (6, 2), # d -> s
    (8, 6), # q -> d
    (1, 8), # r -> q
    (1, 3), # r -> a
    (3, 5), # a -> c
    (5, 2), # c -> s
    (5, 4), # c -> b
    (5, 8), # c -> q
    (8, 4), # q -> b
    (6, 5), # d -> c
    (3, 6), # a -> d
    (8, 7), # q -> p
    (7, 8), # p -> q
    (4, 3)  # b -> a
]

for edge in edges_to_add
    add_edge!(g, edge[1], edge[2])
end

# Opret en kapacitetsmatrix (adjacency matrix med kapaciteter)
capacities = [6, 3, 8, 6, 6, 4, 9, 8, 4, 2, 1, 2, 1, 1, 1, 2, 1]
capacity_matrix = zeros(Int, num_vertices, num_vertices)

for (i, edge) in enumerate(edges_to_add)
    u, v = edge
    capacity_matrix[u, v] = capacities[i]
end

# Beregn den maksimale flow
max_flow_value, flow_matrix = maximum_flow(g, source_node, sink_node, capacity_matrix)

println("Beregning af maksimal flow fra 'r' til 's':")
println("==========================================")
println("Maksimal flow: ", max_flow_value)
# println("\nFlow Matrix (viser flowet gennem hver kant):")
# println(flow_matrix)