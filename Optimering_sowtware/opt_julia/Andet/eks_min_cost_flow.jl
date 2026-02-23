using JuMP,HiGHS

WeighKap = Dict(
    ("JM", "N") => (5, 10), ("JM", "E") => (5, 10),
    ("N", "24.L") => (15, 20), ("JM", "24.L") => (10, 15),
    ("JM", "25.L") => (5, 15), 
    ("JM", "26.L") => (10, 15) , ("E", "26.L") => (15, 20),
    ("24.L", "24.2") => (8, 20), ## ("24.L", "24.2") => (8, 25)
    ("25.L", "25.1") => (12,20), ("26.L", "26.2") => (3,20),
    ("24.2", "24.1") => (7,15),                              ("26.2", "26.1") => (6,15),
    ("24.1", "24.S") => (6,10), ("25.1", "25.S") => (5,10),  ("26.1", "26.S") => (7,10),
    ("24.2", "25.1") => (6,15), ("25.1", "24.S") => (9,10),  ("26.1", "25.S") => (9,10),
    ("24.S", "26.S") => (2,5), ("26.S", "24.S") => (2,5) ,
    ("25.L", "26.L") => (0,10), ("26.L", "25.L") => (0,10)   
)


Edges = collect(keys(WeighKap))

node_set = Set{String}()
for edge in Edges
    push!(node_set, edge[1])
    push!(node_set, edge[2])
end
Nodes = collect(node_set)

flow = Dict( 
    "JM" => 30,
    "N"  => 15,
    "E"  => 10,
    "24.2" => -2,
    "26.2" => -2,
    "24.1" => -7,
    "25.1" => -7,
    "26.1" => -7,
    "24.S" => -10,
    "25.S" => -10,
    "26.S" => -10
)

flow_nodes = collect(keys(flow))
flow_tjeck = sum(flow[node] for node in flow_nodes)
tol = 1e-9
if abs(flow_tjeck) > tol
    error("Sum af flow er ikke 0 (sum = $flow_tjeck, tol = $tol)")
end

flow_const = Dict{String, Float64}()
for node in Nodes
    if node in flow_nodes
        flow_const[node] = flow[node]
    else
        flow_const[node] = 0
    end
end


MCF = Model(HiGHS.Optimizer)

@variable(MCF, x[Edges])

@objective(MCF, Min, sum(WeighKap[edge][1]*x[edge] for edge in Edges))

@constraint(MCF, [edge in Edges], 0 <= x[edge] <= WeighKap[edge][2])

# Flowbalance: udstrøm - indstrøm = flow_const (positiv = kilde, negativ = senke), som i opgaven
@constraint(MCF, [node in Nodes],
    sum(x[edge] for edge in Edges if edge[1] == node) - sum(x[edge] for edge in Edges if edge[2] == node) == flow_const[node]
)

optimize!(MCF)

println("Termination status $(termination_status(MCF)) \n")
if termination_status(MCF) == MOI.OPTIMAL
    println("Optimal værdi (objektfunktion): $(objective_value(MCF))")
    println("\nKanter med flow > 0:")
    for edge in Edges
        if value(x[edge]) > 1e-6
            println("  $(edge[1]) -> $(edge[2]): $(round(value(x[edge]); digits=2)) gaver")
        end
    end
end


