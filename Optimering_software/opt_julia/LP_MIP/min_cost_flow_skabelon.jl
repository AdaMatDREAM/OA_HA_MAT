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
        "F1", "F2",
        "L1", "L2",
        "G1", "G2", "G3", "G4"
            ];

    # --- Kanter: (fra_node, til_node, omkostning, kapacitet) ---
    # Alle kanter er directed. Kapacitet = øvre grænse for flow på kanten.
    L = 1e9; #Stor kapacitet, hvis der ingen kapacitet er
    kanter = [
        ("F1", "L1", 400, 250),
        ("F1", "L2", 350, L),
        ("F2", "L2", 250, L),
        ("L1", "G1", 600, L),
        ("L1", "G2", 350, L),
        ("L2", "G2", 550, L),
        ("L2", "G3", 500, L),
        ("L2", "G4", 650, L)
    ];

    # --- Supply-noder: node => mængde (positiv = hvor meget der forlader noden) ---
    supply_dict = Dict(
        "F1" => 400,
        "F2" => 250
    );

    # --- Demand-noder: node => mængde (positiv = hvor meget der skal modtages) ---
    # I flowbalance bruges b_i = -demand for disse noder.
    demand_dict = Dict(
        "G1" => 200,
        "G2" => 100,
        "G3" => 150,
        "G4" => 200
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
