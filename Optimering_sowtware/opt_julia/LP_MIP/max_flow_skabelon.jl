function max_flow_skabelon()

    # Modeltype er LP (pga. totally unimodular matrix giver LP-relaxation heltallig løsning)
    model_type = "LP";
    dual_defined = false;
    # Maximum flow er altid et maksimeringsproblem
    obj = :MAX;

    # Definer noder
    noder = [
    "København", 
    "Rostock", 
    "Putgarden", 
    "Padborg", 
    "Hamburg", 
    "Berlin", 
    "Strasbourg", 
    "Bruxelles", 
    "Liege", 
    "Paris"];

    # Definer edges(kanter) med kapacitet
    # Format: (from_node, to_node, kapacitet)
    # NOTE: Alle kanter er directed (orienterede) i maximum flow problemer
    kanter = [
            ("København", "Rostock", 8),
            ("København", "Putgarden", 11),
            ("København", "Padborg", 2),
            ("Rostock", "Hamburg", 3),
            ("Rostock", "Berlin", 5),
            ("Putgarden", "Hamburg", 14),
            ("Putgarden", "Berlin", 11),
            ("Padborg", "Hamburg", 10),
            ("Hamburg", "Berlin", 12),
            ("Hamburg", "Strasbourg", 12),
            ("Berlin", "Strasbourg", 4),
            ("Berlin", "Bruxelles", 10),
            ("Berlin", "Liege", 10),
            ("Strasbourg", "Bruxelles", 4),
            ("Strasbourg", "Liege", 12),
            ("Strasbourg", "Paris", 11),
            ("Bruxelles", "Liege", 23),
            ("Bruxelles", "Paris", 16),
            ("Liege", "Paris", 10)
        ];

    # Definer source (fra node) og sink (til node)
    source_node = "København";
    sink_node = "Paris";

    # Vi opretter c-vektoren (objektivkoefficienter) og x_navne-vektoren
    # For max flow: objektiv er at maksimere flow fra source
    # c[i] = 1 hvis edge går fra source, ellers 0
    c = Float64[];
    x_navne = String[];
    kapaciteter = Float64[]; # Gem kapaciteter for hver kant (til brug i print-funktioner)

    for (idx, kant) in enumerate(kanter)
        from_node, to_node, kapacitet = kant[1], kant[2], kant[3];

        # Oprette variabelnavn
        var_navn = string("x_", from_node, "_", to_node);
        push!(x_navne, var_navn);
        
        # Objektivkoefficient: 1 hvis edge går fra source, ellers 0
        if from_node == source_node
            push!(c, 1.0);
        else
            push!(c, 0.0);
        end
        
        push!(kapaciteter, Float64(kapacitet));
    end

    num_kanter = length(kanter);
    num_noder = length(noder);

    # ===================================================================
    # MATEMATISK BEGRUNDELSE FOR FLOW BALANCE CONSTRAINTS:
    # ===================================================================
    # I maximum flow problemet har vi:
    # 1. Flow balance for transshipment nodes (alle noder undtagen source og sink):
    #    inflow - outflow = 0
    #    Dette sikrer flow-konservation: alt flow der kommer ind, skal også gå ud
    #
    # 2. Source node: Ingen constraint
    #    Flow kan gå ud frit. Objektivfunktionen maksimerer flow fra source:
    #    Maximize: Σ f[source, j]
    #
    # 3. Sink node: Ingen constraint
    #    Flow kan komme ind frit. Pga. flow balance på alle andre noder,
    #    vil flow til sink automatisk være lig med flow fra source
    #

    # ===================================================================

    # Vi opretter constraints
    # 1. Flow balance constraints for transshipment nodes (ikke source/sink)
    A_flow_rows = Vector{Vector{Float64}}();
    b_flow = Float64[];
    b_dir_flow = Symbol[];
    b_navne_flow = String[];

    for node in noder
        # Spring source og sink over (de har ingen flow balance constraint)
        if node == source_node || node == sink_node
            continue;
        end

        A_row = zeros(num_kanter);

        # Flow balance: inflow - outflow = 0
        # inflow = edges der går til denne node (positiv koefficient)
        # outflow = edges der går fra denne node (negativ koefficient)
        
        for (idx, kant) in enumerate(kanter)
            from_node, to_node = kant[1], kant[2];
            
            if to_node == node
                A_row[idx] += 1.0; # Inflow
            elseif from_node == node
                A_row[idx] -= 1.0; # Outflow
            end
        end

        push!(A_flow_rows, A_row);
        push!(b_flow, 0.0);
        push!(b_dir_flow, :(==));
        push!(b_navne_flow, string("Flow_balance_", node));
    end

    # 2. Capacity constraints: x_ij <= u_ij (kapacitet)
    A_capacity_rows = Vector{Vector{Float64}}();
    b_capacity = Float64[];
    b_dir_capacity = Symbol[];
    b_navne_capacity = String[];
    
    for i in 1:num_kanter
        A_row = zeros(num_kanter);
        A_row[i] = 1.0;
        push!(A_capacity_rows, A_row);
        push!(b_capacity, kapaciteter[i]);
        push!(b_dir_capacity, :<=);
        push!(b_navne_capacity, string("Capacity_", x_navne[i]));
    end

    # Vi sammensætter alle constraints
    num_flow_constraints = length(A_flow_rows);
    A_flow = zeros(num_flow_constraints, num_kanter);
    for i in 1:num_flow_constraints
        A_flow[i, :] = A_flow_rows[i];
    end
    
    num_capacity_constraints = length(A_capacity_rows);
    A_capacity = zeros(num_capacity_constraints, num_kanter);
    for i in 1:num_capacity_constraints
        A_capacity[i, :] = A_capacity_rows[i];
    end
    
    # Kombiner flow balance og capacity constraints
    A = vcat(A_flow, A_capacity);
    b = vcat(b_flow, b_capacity);
    b_dir = vcat(b_dir_flow, b_dir_capacity);
    b_navne = vcat(b_navne_flow, b_navne_capacity);

    # Variabeltyper og GRÆNSER
    fortegn = fill(:>=, num_kanter);
    nedre_grænse = zeros(num_kanter);
    øvre_grænse = kapaciteter; # Upper bound er kapaciteten for hver kant
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
        output_mappe = joinpath(@__DIR__, output_mappe_navn);
    else
        output_mappe = joinpath(output_base_sti, output_mappe_navn);
    end

    if !isdir(output_mappe)
        mkpath(output_mappe);
    end

    output_fil_navn = joinpath(output_mappe, "max_flow_problem.txt");
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
        kapaciteter = kapaciteter,
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