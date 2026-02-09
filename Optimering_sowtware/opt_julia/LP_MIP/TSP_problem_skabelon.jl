using Combinatorics  # For combinations() funktionen til at generere delmængder

function TSP_problem_skabelon()
    # Type af model: TSP er altid MIP med binary variabler
    model_type = "MIP";
    # True hvis du også vil have dualt program (det vil du ikke)
    dual_defined = false;
    
    # TSP er altid et minimeringsproblem (minimer total omkostning/afstand)
    obj = :MIN; 
    
    # Omkostningsmatrix (n×n) - diagonalen skal indeholde L (meget høj værdi)
    # L er en parameter som brugeren kan sætte (standard: 1e6)
    L = 1e16;  # Meget høj værdi for at forhindre self-loops
    
    # Eksempel problem: 5 byer (Odense, Nyborg, København, Holbæk, Næstved)
    # Omkostningsmatrix baseret på regneark eksempel
    # Byer: 1=Odense, 2=Nyborg, 3=København, 4=Holbæk, 5=Næstved
    c_matrix = [L   16   10   12 11.5;
                12  L    10   12 10.5;
                12  10   L    8   7.5;
                16  12   10   L   8.5;
                13.5 10.5 5.5 9.5  L];
    n, m = size(c_matrix);
    n != m ? error("c_matrix skal være en kvadratisk matrix") : nothing;
    
    # Tjek om diagonalen indeholder L eller meget høje værdier
    for i in 1:n
        if c_matrix[i, i] < 1e10
            println("ADVARSEL: Diagonal element c_matrix[$i, $i] = $(c_matrix[i, i]) er ikke meget høj. Overvej at bruge L = $L for at forhindre self-loops.")
        end
    end
    
    c = vec(c_matrix');  # Flatten matrixen (transponeret)
    
    # Navne på noder/byer (bruges kun til output, ikke i variabelnavne)
    node_navne = ["ca", "wh", "ta", "kr", "cr"];  
    
    # Tjek om antal node navne matcher matrix dimension
    if length(node_navne) != n
        error("Antal node_navne ($(length(node_navne))) matcher ikke antal rækker/kolonner i c_matrix ($n)")
    end

    # Opret variabelnavne som vektor (row-major orden: x_1_1, x_1_2, ..., x_1_n, x_2_1, ...)
    # Dette matcher Assignment problem strukturen
    x_navne = [string("x_", i, "_", j) for i in 1:n for j in 1:n];
    
    # Konstruer A-matrixen for TSP problemet
    # Første n rækker: hver node har præcis én udgående kant (Σ_j x_ij = 1)
    # Næste n rækker: hver node har præcis én indgående kant (Σ_i x_ij = 1)
    # Derefter: subtour elimination constraints
    
    # Start med assignment constraints (2n constraints)
    A_assignment = zeros(2*n, n*n);
    

    for i in 1:n
        for j in 1:n
            # Variabel x_ij er på position (i-1)*n + j (row-major)
            A_assignment[i, (i-1)*n + j] = 1.0;
        end
    end
    
    # Næste n rækker: hver node (j) har præcis én indgående kant
    for j in 1:n
        for i in 1:n
            # Variabel x_ij er på position (i-1)*n + j (row-major)
            A_assignment[n + j, (i-1)*n + j] = 1.0;
        end
    end
    
    # Højreside for assignment constraints: alle er lig 1
    b_assignment = ones(2*n);
    
    # Retning for assignment constraints: alle er ligheder (==)
    b_dir_assignment = fill(:(==), 2*n);
    
    # Navne på assignment begrænsninger
    b_navne_assignment = vcat(
        [string("Outgoing_", node_navne[i]) for i in 1:n],
        [string("Incoming_", node_navne[j]) for j in 1:n]
    );
    
    # Generer subtour elimination constraints
    # For alle delmængder S ⊆ {1,...,n} hvor 2 ≤ |S| ≤ n-1
    # Constraint: Σ_{i ∈ S} Σ_{j ∈ S, j ≠ i} x_ij ≤ |S| - 1
    # Self-loops forhindres via høje omkostninger (L) i diagonalen af c_matrix
    # Størrelse n (alle noder) er redundant med assignment constraints
    A_subtour, b_subtour, b_dir_subtour, b_navne_subtour = generate_subtour_constraints(n, node_navne);
    
    # Kombiner alle constraints
    A = vcat(A_assignment, A_subtour);
    b = vcat(b_assignment, b_subtour);
    b_dir = vcat(b_dir_assignment, b_dir_subtour);
    b_navne = vcat(b_navne_assignment, b_navne_subtour);
    
    # Variabeltyper: alle er binary (0 eller 1)
    x_type = fill(:Binary, n*n);
    
    # Fortegnskrav: alle variable er >= 0 (binary variabler er automatisk >= 0)
    fortegn = fill(:>=, n*n);
    nedre_grænse = zeros(n*n);
    øvre_grænse = fill(Inf, n*n);
    
    # Antal decimaler i output og tolerance for 0-værdier
    dec = 2;
    tol = 1e-9;
    
    # Output af resultater i terminal eller fil
    output_terminal = false;
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
    output_fil_navn = joinpath(output_mappe, "TSP_problem.txt")
    output_fil_navn_D = joinpath(output_mappe, "Output_LP_MIP_Dual.txt") # benyttes ikke i virkeligheden, da dual problemet ikke er defineret
    
    # Returner som NamedTuple for bedre læsbarhed
    return (
        model_type = model_type,
        dual_defined = dual_defined,
        obj = obj,
        c = c,
        x_navne = x_navne,
        node_navne = node_navne,
        L = L,
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

# Funktion til at generere subtour elimination constraints
# For alle delmængder S ⊆ {1,...,n} hvor 2 ≤ |S| ≤ n-1
# Constraint: Σ_{i ∈ S} Σ_{j ∈ S, j ≠ i} x_ij ≤ |S| - 1
# BEMÆRK: Vi udelader størrelse 1 (self-loops forhindres via høje omkostninger L i diagonalen)
# BEMÆRK: Vi udelader også størrelse n (alle noder) da det er redundant med assignment constraints
# Brug Combinatorics.combinations() for at simplificere genereringen
function generate_subtour_constraints(n, node_navne)
    # Saml alle constraints
    A_rows = Vector{Vector{Float64}}()
    b_values = Float64[]
    b_dir_values = Symbol[]
    b_navne_values = String[]
    
    constraint_idx = 1
    
    # Generer constraints for alle delmængder med størrelse 2 til n-1
    # Brug Combinatorics.combinations() for at generere alle kombinationer
    for size_S in 2:(n-1)
        # Generer alle kombinationer af 'size_S' noder fra {1,...,n}
        for S in combinations(1:n, size_S)
            # Opret en række for denne constraint
            A_row = zeros(n*n)
            
            # Constraint: Σ_{i ∈ S} Σ_{j ∈ S, j ≠ i} x_ij ≤ |S| - 1
            # x_navne er i row-major orden, så x_ij er på position (i-1)*n + j
            # Vi udelader self-loops (x_ii) - kun kanter mellem forskellige noder i S
            for i in S
                for j in S
                    if i != j  # Udelad self-loops
                        # Variabel x_ij er på position (i-1)*n + j (row-major)
                        A_row[(i-1)*n + j] = 1.0
                    end
                end
            end
            
            push!(A_rows, A_row)
            push!(b_values, length(S) - 1)
            push!(b_dir_values, :<=)
            push!(b_navne_values, string("Subtour_", constraint_idx))
            constraint_idx += 1
        end
    end
    
    # Konverter til arrays med korrekt størrelse
    num_constraints = length(A_rows)
    A_subtour = zeros(num_constraints, n*n)
    for i in 1:num_constraints
        A_subtour[i, :] = A_rows[i]
    end
    
    b_subtour = b_values
    b_dir_subtour = b_dir_values
    b_navne_subtour = b_navne_values
    
    return A_subtour, b_subtour, b_dir_subtour, b_navne_subtour
end
