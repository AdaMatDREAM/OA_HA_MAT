using JuMP,HiGHS

# parameters
Weights = Dict(("1", "2") => 4, ("1", "3") => 9, ("1", "4") => 11, 
               ("2", "3") => 2, ("2", "5") => 3, ("3", "6") => 1, 
               ("3", "7") => 6, ("4", "7") => 12, ("4", "8") => 8,
               ("5", "6") => 3, ("5", "8") => 6, ("5", "9") => 4,
               ("6", "9") => 4, ("7", "9") => 7, ("8", "9") => 8)
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
for S in 2:N-1  # iterating over the size of the subsets
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
println("Optimal value of the objectivfunction: 
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


