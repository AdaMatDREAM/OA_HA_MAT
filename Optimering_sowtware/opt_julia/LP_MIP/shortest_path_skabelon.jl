function shortest_path_skabelon()

    # Modeltype er LP (pga. totally unimodular matrix giver LP-relaxation heltallig og samme løsning som MIP)
    model_type = "LP";
    dual_defined = false;
    # Shortest path er altid et minimeringsproblem
    obj = :MIN;

    # Definer noder
    noder = ["r", "p", "q", "a", "b", "c", "d", "s"];

    # Definer edges(kanter) og vægte. 
    # Defineres som (egde1, edge2, vægt, "D"/"U" = directed/undirected)
kanter = [
            ("r", "p", 6, "D"),
            ("r", "q", 4, "D"),
            ("r", "a", 9, "D"),
            ("p", "q", 2, "D"),
            ("p", "b", 3, "D"),
            ("q", "p", 1, "D"),
            ("q", "b", 2, "D"),
            ("q", "d", 6, "D"),
            ("a", "c", 8, "D"),
            ("a", "d", 1, "D"),
            ("b", "a", 1, "D"),
            ("b", "s", 8, "D"),
            ("c", "q", 1, "D"),
            ("c", "b", 2, "D"),
            ("c", "s", 4, "D"),
            ("d", "c", 1, "D"),
            ("d", "s", 6, "D")
        ];
# Definer source (fra node) og sink (til node)
source_node = "r";
sink_node = "s";

# Vi opretter variable
# For undirected edges, opret kun én variabel (men den kan bruges i begge retninger i constraints (A-matricen))
# For directed edges, opret en variabel. 

# Vi opretter c-vektoren og x_navne-vektoren
c = Float64[];
x_navne = String[];

# Vi opretter en vektor til at håndtere index
kant_index = Dict{Tuple{String, String}, Int}(); # Mapping fra (node1, node2) til index

for (idx, kant) in enumerate(kanter)
    from_node, to_node, weight, direction = kant[1], kant[2], kant[3], kant[4];

    # Oprette variabelnavn og objektivkoefficienter
    var_navn = string("x_", from_node, "_", to_node);
    push!(x_navne, var_navn);
    push!(c, Float64(weight)); # Ikke nødvendigt med Float64() men stadig god praksis
    kant_index[(from_node, to_node)] = idx; # Mapping fra (node1, node2) til index (bruges senere)
end

num_kanter = length(kanter);
num_noder = length(noder);

# Vi oprette constraints
# 1. Flow balance constraints for alle noder 
# Source node: inflow - outflow = -1 (man går ud)
# Sink node: inflow - outflow = 1 (man kommer ind)
# Inflow - Outflow = 0 for alle noder undtagen source og sink (man går ind en gang og ud en gang)
A_flow_rows = Vector{Vector{Float64}}();
b_flow = Float64[];
b_dir_flow = Symbol[];
b_navne_flow = String[];

# Mappings fra nodenavn til index
node_index = Dict(noder[i] => i for i in 1:num_noder);

for node in noder
    A_row = zeros(num_kanter);

    # Flow balance: inflow - outflow 
    # inflow = edges der går til denne node (positiv koefficient)
    # outflow = edges der går fra denne node (negativ koefficient)
    
    for (idx, kant) in enumerate(kanter)
        from_node, to_node, weight, direction = kant[1], kant[2], kant[3], kant[4];
        if direction == "D"
            # Directed edges
            if to_node == node
                A_row[idx] += 1.0; # Inflow
            elseif from_node == node
                A_row[idx] -= 1.0; # Outflow
            end
        else
            # Undirected edges (kan bruges i begge retninger)
            # Hvis node er to er det inflow (positiv koefficient)
            # Hvis node er fra er det outflow (negativ koefficient)
            if to_node == node
                A_row[idx] += 1.0;
            elseif from_node == node
                A_row[idx] -= 1.0;
            end
        end
    end

    # Bestem RHS baseret på node type
    if node == source_node
        b_value = -1.0;
        constraint_name = string("Flow_balance_source_", node);
    elseif node == sink_node
        b_value = 1.0;
        constraint_name = string("Flow_balance_sink_", node);
    else
        b_value = 0.0;
        constraint_name = string("Flow_balance_node_", node);
    end
    push!(A_flow_rows, A_row);
    push!(b_flow, b_value);
    push!(b_dir_flow, :(==));
    push!(b_navne_flow, constraint_name);
end

    # 2. Upper bound constraints: x_ij <= 1 (håndteres via øvre_grænse, men vi kan også tilføje dem eksplicit hvis ønsket)
    # Vi håndterer dem via øvre_grænse (som i MST), men de vil blive vist i problemformuleringen (tror jeg)

    # Vi sammensætter alle constraints
    num_flow_constraints = length(A_flow_rows);
    A_flow = zeros(num_flow_constraints, num_kanter);
    for i in 1:num_flow_constraints
        A_flow[i, :] = A_flow_rows[i];
    end
    A = A_flow;
    b = b_flow;
    b_dir = b_dir_flow;
    b_navne = b_navne_flow;

    # Variabeltyper og GRÆNSER
    fortegn = fill(:>=, num_kanter);
    nedre_grænse = zeros(num_kanter);
    øvre_grænse = fill(1.0, num_kanter);
    x_type = fill(:Continuous, num_kanter);  # LP-relaxation

    # OUTPUT KONFIGURATION 
    dec = 2;
    tol = 1e-9;
    output_terminal = false;
    output_fil = true;
    output_base_sti = "";
    output_mappe_navn = "Output";

    # Byg output mappe sti
    if output_base_sti == ""
        # Brug samme mappe som koden
        output_mappe = joinpath(@__DIR__, output_mappe_navn);
    else
        # Brug brugerdefineret sti
        output_mappe = joinpath(output_base_sti, output_mappe_navn);
    end

    if !isdir(output_mappe)
        mkpath(output_mappe);
    end

    output_fil_navn = joinpath(output_mappe, "shortest_path_problem.txt");
    output_fil_navn_D = joinpath(output_mappe, "Output_LP_MIP_Dual.txt");

    return (
        model_type = model_type,
        dual_defined = dual_defined,
        obj = obj,
        c = c,
        x_navne = x_navne,
        noder = noder,
        kanter = kanter,
        source_node = source_node,
        sink_node = sink_node,
        fortegn = fortegn,
        nedre_grænse = nedre_grænse,
        øvre_grænse = øvre_grænse,
        A = A,
        b = b,
        b_dir = b_dir,
        b_navne = b_navne,
        x_type = x_type,
        dec = dec,
        tol = tol,
        output_terminal = output_terminal,
        output_fil = output_fil,
        output_base_sti = output_base_sti,
        output_mappe_navn = output_mappe_navn,
        output_mappe = output_mappe,
        output_fil_navn = output_fil_navn,
        output_fil_navn_D = output_fil_navn_D
    )
end