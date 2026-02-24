using Combinatorics
function MST_skabelon()
    # Modeltype er LP (pga. totally unimodular matrix giver LP-relaxation heltallig løsning)
model_type = "LP";
dual_defined = false;
# MST er altid et minimeringsproblem
obj = :MIN;

# Definer noder
noder = ["1", "2", "3", "4", "5", "6", "7", "8", "9"];

# Definer edges(kanter) og vægte. 
# Defineres som (egde1, edge2, vægt)
kanter = [
          ("1","2",4),
          ("1","3",9),
          ("1","4",11),
          ("1","6",7),
          ("2","3",2),
          ("2","5",3),
          ("3","6",1),
          ("3","7",6),
          ("4","7",12),
          ("4","8",8),
          ("5","6",3),
          ("5","8",6),
          ("5","9",4),
          ("6","9",4),
          ("7","9",7),
          ("8","9",8)
         ];

# Definer objektivkoefficienter og variabelnavne
c = [kant[3] for kant in kanter];
x_navne = [string("x_", kant[1], "_", kant[2]) for kant in kanter];

fortegn = fill(:>=, length(kanter));
nedre_grænse = zeros(length(fortegn));
# Dette er til for at sikre at variabel betingelsern er til stede <= 1
# Du vil ikke kunne se dette i output
øvre_grænse = fill(1, length(fortegn));

# Vi laver A matricen for begrænsningerne.
# Starter med at finde antallet af noder og kanter.
num_noder = length(noder);
num_kanter = length(kanter);

# Mapping fra nodenavn til index.
node_index = Dict(noder[i] => i for i in 1:num_noder);

# Mapping fra kant (node1, node2) til index.
kant_index = Dict( (kanter[i][1], kanter[i][2]) => i for i in 1:num_kanter);

# Vi opretter første bibetingelse, som er at antallet af aktive kanter er lig 1- antallet af noder.
# Constraint: Σ x_ij = n-1 (sum af alle kanter)
A_b1 = ones(1 , num_kanter);
b_b1 = [num_noder - 1];
b_dir_b1 = [:(==)];
b_navne_b1 = ["Antal_aktive_kanter"];

# Vi opretter de resterende bibetingelser (ingen subtours)
# For alle delmængder S ⊆ {1,...,n} hvor 2 ≤ |S| ≤ n-1
# Constraint: Σ_{i,j in S} x_ij ≤ |S| - 1
# (kun for kanter der faktisk eksisterer)

# Vi definerer antal an vektor af vektorer til A matricen
A_subtour_rows = Vector{Vector{Float64}}();
# Vi definerer en vektor til RHS værdierne
b_subtour = Float64[];
# Vi definerer en vektor til begrænsningsretningen
b_dir_subtour = Symbol[];
# Vi definerer en vektor til begrænsningsnavne
b_navne_subtour = String[];

# Opretter variable til indeksering af begrænsningerne
constraint_idx = 1;

# Set til at holde styr på unikke constraints (for at undgå duplikater)
# Vi gemmer constraints som tuples af (A_row_as_tuple, b_value) for sammenligning
unique_constraints = Set{Tuple{Tuple, Float64}}();

# Generer alle delmængder S ⊆ {1,...,n} hvor 2 ≤ |S| ≤ n-1
for size_S in 2:(num_noder-1)
    # Generer alle delmængder med denne størrelse
    for subset in combinations(1:num_noder, size_S)
        # Opret en række for denne constraint
        A_row = zeros(num_kanter);
        # Find alle kanter hvor begge endepunkter er i subset
        # Tjek både (i,j) og (j,i) da grafen er undirected
        for i in subset
            for j in subset
                if i != j #Udelad self-loops
                    node_i = noder[i];
                    node_j = noder[j];
                    
                    # Tjek om kanten (node_i, node_j) eksisterer
                    if haskey(kant_index, (node_i, node_j))
                        idx = kant_index[(node_i, node_j)];
                        A_row[idx] = 1.0;
                    # Tjek også omvendt retning (node_j, node_i) - undirected graph
                    elseif haskey(kant_index, (node_j, node_i))
                        idx = kant_index[(node_j, node_i)];
                        A_row[idx] = 1.0;
                    end
                end
            end
        end
    # Vi skal kun tilføje constrainten, hvis der er mindst én kant i subsettet
        if sum(A_row) > 0
            b_value = length(subset) - 1;
            # Tjek om denne constraint allerede eksisterer (undgå duplikater)
            # Konverter A_row til tuple for at kunne bruge i Set
            A_row_tuple = tuple(A_row...);
            constraint_key = (A_row_tuple, b_value);
            if !(constraint_key in unique_constraints)
                push!(unique_constraints, constraint_key);
                push!(A_subtour_rows, A_row);
                push!(b_subtour, b_value);
                push!(b_dir_subtour, :<=);
                push!(b_navne_subtour, string("Subtour_", constraint_idx));
                constraint_idx += 1;
            end
        end
    end
end

# Konverter subtour begrænsninger til en matrix
num_subtour = length(A_subtour_rows);
A_subtour = zeros(num_subtour, num_kanter);
for i in 1:num_subtour
    A_subtour[i, :] = A_subtour_rows[i];
end

# Note: Upper bound constraints (x_ij <= 1) er allerede inkluderet i subtour constraints for subsets af størrelse 2
# For eksempel: subtour constraint for subset {i,j} giver x_ij <= 1, hvilket er præcis samme som upper bound constraint
# Derfor tilføjer vi dem ikke eksplicit her, da de ville være duplikater

# Nu kombineres alle begrænsningerne til A matricen og b vektoren
A = vcat(A_b1, A_subtour);
b = vcat(b_b1, b_subtour);
b_dir = vcat(b_dir_b1, b_dir_subtour);
b_navne = vcat(b_navne_b1, b_navne_subtour);

# Vi definerer variabeltyperne til :Continuous (LP-relaxation giver heltallig løsning pga. totally unimodular matrix)
x_type = fill(:Continuous, num_kanter);
# ===================================================================================================================
# OUTPUT KONFIGURATION
# ===================================================================================================================
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
output_fil_navn = joinpath(output_mappe, "MST_problem.txt")
output_fil_navn_D = joinpath(output_mappe, "Output_LP_MIP_Dual.txt") # benyttes ikke i virkeligheden, da dual problemet ikke er defineret

# Returner som NamedTuple for bedre læsbarhed
return (
    model_type = model_type,
    dual_defined = dual_defined,
    obj = obj,
    c = c,
    x_navne = x_navne,
    noder = noder,
    kanter = kanter,
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

