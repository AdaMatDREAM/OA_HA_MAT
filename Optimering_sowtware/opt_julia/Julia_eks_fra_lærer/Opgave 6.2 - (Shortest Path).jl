using JuMP
using HiGHS

function find_shortest_path()

    costs = [
        0  6  4  9  0  0  0  0;  # r
        0  0  2  0  3  0  0  0;  # p
        0  1  0  0  2  0  6  0;  # q
        0  0  0  0  0  8  1  0;  # a
        0  0  0  1  0  0  0  8;  # b
        0  0  1  0  2  0  0  4;  # c
        0  0  0  0  0  1  0  6;  # d
        0  0  0  0  0  0  0  0;  # s
    ]

    n = size(costs, 1)
    source_node = 1
    sink_node = 8

    shortest_path_model = Model(HiGHS.Optimizer)
    # Smart trick til at gøre solveren silent, så den ikke udskriver status under kørsel. Det kan gøre outputtet lidt mere overskueligt.
    set_silent(shortest_path_model)

    # Opret en binær variabel for hver mulig kant.
    @variable(shortest_path_model, x[i=1:n, j=1:n; costs[i, j] > 0], Bin)

    # Minimer den samlede omkostning af den valgte sti.
    @objective(shortest_path_model, Min, sum(costs[i, j] * x[i, j] for i=1:n, j=1:n if costs[i, j] > 0))

    # Sørg for at inflow = outflow for hver node på nær source og sink.
    for i in 1:n
        flow_balance = @expression(shortest_path_model,
            sum(x[j, i] for j=1:n if costs[j, i] > 0) - sum(x[i, j] for j=1:n if costs[i, j] > 0)
        )
        if i == source_node
            @constraint(shortest_path_model, flow_balance == -1)
        elseif i == sink_node
            @constraint(shortest_path_model, flow_balance == 1)
        else
            @constraint(shortest_path_model, flow_balance == 0)
        end
    end

    # Løs problemet
    optimize!(shortest_path_model)

    if termination_status(shortest_path_model) == MOI.OPTIMAL
        min_cost = objective_value(shortest_path_model)
        println("==========================================")
        println("Beregning af korteste vej fra 'r' (1) til 's' (8):")
        println("Mindste samlede omkostning: ", round(Int, min_cost))
        println("\nSti:")

        current_node = source_node
        path = [current_node]
        while current_node != sink_node
            next_node_found = false
            for j in 1:n
                if costs[current_node, j] > 0 && value(x[current_node, j]) > 0.9
                    push!(path, j)
                    current_node = j
                    next_node_found = true
                    break 
                end
            end
            if !next_node_found
                println("Fejl: Kunne ikke rekonstruere hele stien.")
                break
            end
        end
        println(join(path, " -> "))
        println("==========================================")
    else
        println("Kunne ikke finde en optimal løsning.")
    end
end

find_shortest_path()