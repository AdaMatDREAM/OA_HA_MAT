# =============================================================================
# MINIMUM COST FLOW - SKABELON
# =============================================================================
# Formål: Definere et minimum cost flow (MCF) problem på netværksform.
# Alle kanter er directed (rettede); det behøves ikke angives.
#
# Problemstilling:
#   Minimér total omkostning af flow under flowbalance (udstrøm - indstrøm = b_i)
#   og kapacitetsbegrænsninger (0 <= x_ij <= u_ij).
#
# Konvention for flowbalance (udstrøm - indstrøm = b_i):
#   - Supply-noder (kilder): b_i > 0  (flow forlader noden)
#   - Demand-noder (senker): b_i < 0  (flow modtages i noden)
#   - Transshipment-noder:   b_i = 0  (flow gennem noden)
# =============================================================================

function min_cost_flow_skabelon()

    # --- Modeltype: "LP" eller "MIP" ---
    # LP: Kontinuerlige flowvariabler (ofte heltallig løsning pga. unimodularitet).
    # MIP: Heltallige flowvariabler (x_ij ∈ Z_+).
    model_type = "LP";
    dual_defined = false;
    obj = :MIN;

    # --- Noder ---
    # Kan angives eksplicit, eller udledes af kanter + supply/demand (se nedenfor).
    noder = [
        "JM", "N", "E",
        "24.L", "25.L", "26.L",
        "24.2", "25.1", "26.2",
        "24.1", "26.1",
        "24.S", "25.S", "26.S"
    ];

    # --- Kanter: (fra_node, til_node, omkostning, kapacitet) ---
    # Alle kanter er directed. Kapacitet = øvre grænse for flow på kanten.
    kanter = [
        ("JM", "N", 5, 10),
        ("JM", "E", 5, 10),
        ("N", "24.L", 15, 20),
        ("JM", "24.L", 10, 15),
        ("JM", "25.L", 5, 15),
        ("JM", "26.L", 10, 15),
        ("E", "26.L", 15, 20),
        ("24.L", "24.2", 8, 25),
        ("25.L", "25.1", 12, 20),
        ("26.L", "26.2", 3, 20),
        ("24.2", "24.1", 7, 15),
        ("26.2", "26.1", 6, 15),
        ("24.1", "24.S", 6, 10),
        ("25.1", "25.S", 5, 10),
        ("26.1", "26.S", 7, 10),
        ("24.2", "25.1", 6, 15),
        ("25.1", "24.S", 9, 10),
        ("26.1", "25.S", 9, 10),
        ("24.S", "26.S", 2, 5),
        ("26.S", "24.S", 2, 5)
    ];

    # --- Supply-noder: node => mængde (positiv = hvor meget der forlader noden) ---
    supply_dict = Dict(
        "JM" => 30,
        "N"  => 15,
        "E"  => 10
    );

    # --- Demand-noder: node => mængde (positiv = hvor meget der skal modtages) ---
    # I flowbalance bruges b_i = -demand for disse noder.
    demand_dict = Dict(
        "24.2" => 2,
        "26.2" => 2,
        "24.1" => 7,
        "25.1" => 7,
        "26.1" => 7,
        "24.S" => 10,
        "25.S" => 10,
        "26.S" => 10
    );

    # --- Udled noder fra kanter + supply + demand (hvis noder tom) ---
    if isempty(noder)
        node_set = Set{String}();
        for k in kanter
            push!(node_set, k[1]);
            push!(node_set, k[2]);
        end
        for node in keys(supply_dict); push!(node_set, node); end
        for node in keys(demand_dict); push!(node_set, node); end
        noder = collect(node_set);
    end

    # --- Objektivkoefficienter (c), variabelnavne (x_navne) og kapaciteter ---
    c = Float64[];
    x_navne = String[];
    kapaciteter = Float64[];
    for (idx, kant) in enumerate(kanter)
        fra, til, omkostning, kap = kant[1], kant[2], kant[3], kant[4];
        push!(x_navne, "x_$(fra)_$(til)");
        push!(c, Float64(omkostning));
        push!(kapaciteter, Float64(kap));
    end
    num_kanter = length(kanter);
    num_noder = length(noder);

    # --- Flowbalance: b_i for hver node (udstrøm - indstrøm = b_i) ---
    flow_const = Dict{String, Float64}();
    for node in noder
        if haskey(supply_dict, node)
            flow_const[node] = Float64(supply_dict[node]);
        elseif haskey(demand_dict, node)
            flow_const[node] = -Float64(demand_dict[node]);
        else
            flow_const[node] = 0.0;
        end
    end
    total_supply = sum(values(supply_dict));
    total_demand = sum(values(demand_dict));
    if abs(total_supply - total_demand) > 1e-9
        error("MCF: total supply ($total_supply) skal være lig total demand ($total_demand).")
    end

    # --- Flow balance constraints: indstrøm - udstrøm = -b_i (så udstrøm - indstrøm = b_i) ---
    A_flow_rows = Vector{Vector{Float64}}();
    b_flow = Float64[];
    b_dir_flow = Symbol[];
    b_navne_flow = String[];
    for node in noder
        A_row = zeros(num_kanter);
        for (idx, kant) in enumerate(kanter)
            fra, til = kant[1], kant[2];
            if fra == node
                A_row[idx] -= 1.0;
            elseif til == node
                A_row[idx] += 1.0;
            end
        end
        push!(A_flow_rows, A_row);
        push!(b_flow, -flow_const[node]);
        push!(b_dir_flow, :(==));
        push!(b_navne_flow, "Flow_balance_$(node)");
    end

    # --- Kapacitetsbegrænsninger: x_ij <= u_ij ---
    A_cap_rows = Vector{Vector{Float64}}();
    b_cap = Float64[];
    b_dir_cap = Symbol[];
    b_navne_cap = String[];
    for i in 1:num_kanter
        A_row = zeros(num_kanter);
        A_row[i] = 1.0;
        push!(A_cap_rows, A_row);
        push!(b_cap, kapaciteter[i]);
        push!(b_dir_cap, :<=);
        push!(b_navne_cap, "Capacity_$(x_navne[i])");
    end

    A_flow = zeros(length(A_flow_rows), num_kanter);
    for i in eachindex(A_flow_rows); A_flow[i, :] = A_flow_rows[i]; end
    A_cap = zeros(length(A_cap_rows), num_kanter);
    for i in eachindex(A_cap_rows); A_cap[i, :] = A_cap_rows[i]; end
    A = vcat(A_flow, A_cap);
    b = vcat(b_flow, b_cap);
    b_dir = vcat(b_dir_flow, b_dir_cap);
    b_navne = vcat(b_navne_flow, b_navne_cap);

    fortegn = fill(:>=, num_kanter);
    nedre_grænse = zeros(num_kanter);
    øvre_grænse = kapaciteter;
    x_type = model_type == "MIP" ? fill(:Integer, num_kanter) : fill(:Continuous, num_kanter);

    dec = 2;
    tol = 1e-9;
    output_terminal = false;
    output_fil = true;
    output_base_sti = "";
    output_mappe_navn = "Output";
    output_mappe = output_base_sti == "" ? joinpath(@__DIR__, output_mappe_navn) : joinpath(output_base_sti, output_mappe_navn);
    if !isdir(output_mappe); mkpath(output_mappe); end
    output_fil_navn = joinpath(output_mappe, "min_cost_flow_problem.txt");
    output_fil_navn_D = joinpath(output_mappe, "Output_LP_MIP_Dual.txt");

    return (
        model_type = model_type,
        dual_defined = dual_defined,
        obj = obj,
        c = c,
        x_navne = x_navne,
        noder = noder,
        kanter = kanter,
        supply_dict = supply_dict,
        demand_dict = demand_dict,
        flow_const = flow_const,
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
