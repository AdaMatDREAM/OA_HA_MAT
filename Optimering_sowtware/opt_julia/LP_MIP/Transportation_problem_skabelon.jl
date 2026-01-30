function Transportation_problem_skabelon()
    # Type af model: LP eller MIP
    model_type = "LP";  # eller "MIP" for heltalsproblemer
    # True hvis du også vil have dualt program
    dual_defined = false;
    
    # Transportation problemer er altid minimeringsproblemer
    obj = :MIN; 
    
    # Omkostningsmatrix (m×n) hvor m er antal sources og n er antal destinations
    c_matrix = [3  7  6  4;
                2  4  3  2;
                4  3  8  5];
    m, n = size(c_matrix);

    # Flatten omkostningsmatrixen til vektor (row-major order)
    # c skal matche rækkefølgen i x_navne: x_S1_D1, x_S1_D2, ..., x_S1_Dn, x_S2_D1, ...
    # x_navne er konstrueret som: x_supply_i_demand_j for i=1..m, j=1..n
    # c_matrix[i, j] skal svare til omkostningen for source i → destination j
    c = vec(c_matrix');  # Flatten matrixen (row-major: række 1, række 2, ...)
    
    # Navne på sources (supply points)
    supply_navne = ["A", "B", "C"];
    # Supply værdier (s_i) - RHS for supply constraints
    supply_værdier = [5, 2, 3];
    
    # Navne på destinations (demand points)
    demand_navne = ["D1", "D2", "D3", "D4"];
    # Demand værdier (d_j) - RHS for demand constraints
    demand_værdier = [3, 3, 2, 2];
    
    # Tjek om problemet er balanceret: Σ supply = Σ demand
    total_supply = sum(supply_værdier);
    total_demand = sum(demand_værdier);
    if abs(total_supply - total_demand) > 1e-9
        error("Problemet er ikke balanceret: Total supply = $total_supply, Total demand = $total_demand")
    end
    
    # Tjek om antal supply navne matcher matrix dimension
    if length(supply_navne) != m
        error("Antal supply_navne ($(length(supply_navne))) matcher ikke antal rækker i c_matrix ($m)")
    end
    if length(supply_værdier) != m
        error("Antal supply_værdier ($(length(supply_værdier))) matcher ikke antal rækker i c_matrix ($m)")
    end
    
    # Tjek om antal demand navne matcher matrix dimension
    if length(demand_navne) != n
        error("Antal demand_navne ($(length(demand_navne))) matcher ikke antal kolonner i c_matrix ($n)")
    end
    if length(demand_værdier) != n
        error("Antal demand_værdier ($(length(demand_værdier))) matcher ikke antal kolonner i c_matrix ($n)")
    end

    # Opret variabelnavne som vektor (samme rækkefølge som c)
    x_navne = [string("x_", supply_navne[i], "_", demand_navne[j]) for i in 1:m for j in 1:n];
    
    # Konstruer A-matrixen for transportation problemet
    # Første m rækker: hver source sender præcis supply_værdier[i] enheder (Σ_j x_ij = s_i)
    # Næste n rækker: hver destination modtager præcis demand_værdier[j] enheder (Σ_i x_ij = d_j)
    A = zeros(m + n, m * n);
    
    # Første m rækker: hver source (i) sender præcis supply_værdier[i] enheder
    for i in 1:m
        for j in 1:n
            # Variabel x_ij er på position (i-1)*n + j i vektoren
            A[i, (i-1)*n + j] = 1.0;
        end
    end
    
    # Næste n rækker: hver destination (j) modtager præcis demand_værdier[j] enheder
    for j in 1:n
        for i in 1:m
            # Variabel x_ij er på position (i-1)*n + j i vektoren
            A[m + j, (i-1)*n + j] = 1.0;
        end
    end
    
    # Højreside: supply værdier først, derefter demand værdier
    b = vcat(supply_værdier, demand_værdier);

    # Retningen af begrænsningerne: alle er ligheder (==)
    b_dir = fill(:(==), m + n);
    
    # Navne på begrænsninger (bruger supply_navne og demand_navne direkte)
    b_navne = vcat(
        supply_navne,
        demand_navne
    );
    
    # Variabeltyper baseret på model_type
    if model_type == "MIP"
        # Standard: alle variabler er Integer
        # Du kan override dette ved at eksplicit definere x_type efter denne linje
        x_type = fill(:Integer, m * n);
    elseif model_type == "LP"
        # Alle variabler er kontinuerte for LP problemer
        x_type = fill(:Continuous, m * n);
    else
        error("model_type skal være enten \"LP\" eller \"MIP\"")
    end
    
    # Fortegnskrav: alle variable er >= 0
    fortegn = fill(:>=, m * n);
    nedre_grænse = zeros(m * n);
    øvre_grænse = fill(Inf, m * n);
    
    # Antal decimaler i output og tolerance for 0-værdier
    dec = 2;
    tol = 1e-9;
    
    # Output af resultater i terminal eller fil
    output_terminal = true;
    output_fil = true;
    
    # Output mappe konfiguration
    # Du kan enten bruge en absolut sti eller en relativ sti
    # Hvis output_base_sti er tom (""), bruges samme mappe som koden
    output_base_sti = ""  # F.eks. "" for samme mappe, eller "C:\\Users\\Adam\\Documents" for absolut sti
    output_mappe_navn = "Output"  # Navn på output-mappen
    
    # Byg output mappe sti
    if output_base_sti == ""
        # Brug samme mappe som koden
        output_mappe = joinpath(@__DIR__, output_mappe_navn)
    else
        # Brug brugerdefineret sti
        output_mappe = joinpath(output_base_sti, output_mappe_navn)
    end
    
    # Opret output mappe hvis den ikke eksisterer
    if !isdir(output_mappe)
        mkpath(output_mappe)
    end
    
    # Filnavn til output (defineres altid)
    output_fil_navn = joinpath(output_mappe, "Transportation_problem.txt")
    output_fil_navn_D = joinpath(output_mappe, "Output_LP_MIP_Dual.txt") # benyttes ikke i virkeligheden, da dual problemet ikke er defineret
    
    # Returner som NamedTuple for bedre læsbarhed
    return (
        model_type = model_type,
        dual_defined = dual_defined,
        obj = obj,
        c = c,
        x_navne = x_navne,
        supply_navne = supply_navne,
        supply_værdier = supply_værdier,
        demand_navne = demand_navne,
        demand_værdier = demand_værdier,
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
