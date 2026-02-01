using JuMP,HiGHS

# parameters
Weights = Dict(("a", "b") => 2, ("a", "c") => 4, ("a", "d") => 5, 
               ("b", "c") => 1, ("b", "e") => 4, ("c", "e") => 3, 
               ("c", "f") => 5, ("c", "g") => 4, ("c", "d") => 3,
               ("d", "g") => 6, ("e", "h") => 2, ("e", "f") => 4,
               ("f", "g") => 5, ("f", "h") => 3, ("g", "h") => 4)
Edges = collect(keys(Weights))
Nodes = collect(Set(node for edge in Edges for node in edge))
N = length(Nodes);

MST = Model(HiGHS.Optimizer)

# one binary variable for each edge
@variable(MST, x[Edges], Bin)

# minimize cost
@objective(MST, Min, sum(Weights[edge]*x[edge] for edge in Edges))

# enforce N-1 edges
@constraint(MST, sum(x[edge] for edge in Edges) == N-1)

# ensure no cycles in any subset
using Combinatorics
for S in 2:N-1 
    for subset in combinations(Nodes, S)
        @constraint(MST, sum(x[edge] for edge in Edges if issubset(edge, subset)) <= S - 1)
    end
end

# solve
solution = optimize!(MST)
println("Termination status: $(termination_status(MST))")

if termination_status(MST) == MOI.OPTIMAL
    println("Optimal value of the objectivfunction: $(objective_value(MST))")
    for edge in Edges
        if value(x[edge])>0.999
            println("Connection between ", edge[1], " and ", edge[2], " is used.")
        end
    end
else
    println("No optimal solution available")
end


#####################
#Solving with Graphs#
#####################
using Graphs

# create an empty graph with N vertices
G = SimpleGraph(N)

# create a mapping from node names to integer labels (and vice-versa)
node_to_int = Dict(node => idx for (idx, node) in enumerate(Nodes))

int_to_node = Dict(idx => node for (idx, node) in enumerate(Nodes))

# add edges to the graph
for edge in Edges
    add_edge!(G, node_to_int[edge[1]], node_to_int[edge[2]])
end

# initialize distance matrix with infinity (Inf) values
DistanceMatrix = fill(Inf, N, N)

# update the distance matrix with the given weights
for edge in Edges
    i, j = node_to_int[edge[1]], node_to_int[edge[2]]
    DistanceMatrix[i, j] = Weights[edge]
    DistanceMatrix[j, i] = Weights[edge]  # since it's an undirected graph
end

DistanceMatrix

# apply Kruskal's algorithm
MST_eff = kruskal_mst(G, DistanceMatrix)

# report optimal value
println("Optimal value of the objective function: 
            $( sum( DistanceMatrix[src(edge),dst(edge)] for edge in MST_eff ) )")
for edge in MST_eff
    println("Connection between ", int_to_node[src(edge)], 
                " and ", int_to_node[dst(edge)], " is used.")
end

using Random, GraphPlot, Colors

edge_labels = [DistanceMatrix[src(edge),dst(edge)] for edge in edges(G)]

edge_colors = [e in MST_eff ? colorant"seagreen" : colorant"grey50" for e in edges(G)]

Random.seed!(1234) # try different numbers for different (random) graph layouts

gplot(G, nodelabel=Nodes, 
    edgelabel=edge_labels, 
    edgestrokec=edge_colors, 
    nodefillc=[colorant"lightsteelblue"])


