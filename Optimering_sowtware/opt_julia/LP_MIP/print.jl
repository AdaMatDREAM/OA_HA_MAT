# Funktion til at tjekke om løsningen er heltallig (for at verificere unimodularitet)
# Bruges til at verificere at LP-relaxation giver heltallig løsning for totally unimodular problemer
function check_integer_solution(x, x_navne, tol=1e-6)
    all_integer = true
    non_integer_vars = []
    
    for i in eachindex(x)
        val = value(x[i])
        # Tjek om værdien er tæt på et heltal (0 eller 1 for binære problemer)
        nearest_int = round(val)
        if abs(val - nearest_int) > tol
            all_integer = false
            push!(non_integer_vars, (x_navne[i], val))
        end
    end
    
    return all_integer, non_integer_vars
end

function print_optimal_solution(M, x, x_navne, x_type, dec=2)
    println("-"^100)
    @printf("Værdi af objektivfunktionen:\n -> %.*f\n", dec, objective_value(M))
    println("\n")
    @printf("%-30s |%-30s |%-30s\n", "Variabelnavn", "Variabeltype", "Værdi")
    println("-"^85)
    for i in eachindex(x)
        @printf("%-30s |%-30s |%-30.*f\n", x_navne[i], x_type[i], dec, value(x[i]))
    end
    println("\n")
end

##########################################################
function print_slack_shadow_price(M, constraints, b_navne, b, b_dir, dec=2, tol=1e-9)
    println("Slack og skyggepris: \n")
    
    # Find maksimal længde af begrænsningsnavne, men begræns til maksimum 30 tegn
    max_name_length = min(30, maximum([length(s) for s in b_navne]))
    name_width = max(15, max_name_length + 2)
    
    @printf("%-*s |%-15s |%-15s |%-15s |%-15s |%-15s\n", 
            name_width, "Begrænsningnavn", "LHS", "RHS", "Slack", "Skyggepris", "Bindende status")
    println("-"^(name_width + 15*5 + 5))
    
    # Hent objektivets retning
    obj_sense = objective_sense(M)
    obj_sense_str = string(obj_sense)
    
    for i in eachindex(constraints)
        lhs = value(constraints[i])
        if b_dir[i] == :<=
            slack = b[i] - lhs
        elseif b_dir[i] == :>=
            slack = lhs - b[i]
        else
            slack = b[i] - lhs
        end
        if abs(slack) <= tol
            bindende = "Bindende"
        else
            bindende = "Ikke-bindende"
        end
        
        # Beregn skyggepris korrekt baseret på objektivets retning
        # I JuMP: for MIN problemer returnerer dual() positiv værdi for ≤ begrænsninger
        #         for MAX problemer returnerer dual() negativ værdi for ≤ begrænsninger
        # Skyggeprisen skal altid være den marginale værdi af at øge RHS
        dual_val = dual(constraints[i])
        # objective_sense returnerer MOI enum, konverter til string for sammenligning
        if obj_sense_str == "MIN_SENSE"
            # For MIN: dual() returnerer allerede korrekt fortegn
            shadow_price = dual_val
        else  # MAX_SENSE
            # For MAX: dual() returnerer negativ værdi, så vi skal tage minus
            shadow_price = -dual_val
        end
        
        # Afkort navn hvis det er for langt
        navn = length(b_navne[i]) > max_name_length ? b_navne[i][1:max_name_length] : b_navne[i]
        @printf("%-*s |%-15.*f |%-15.*f |%-15.*f |%-15.*f |%-15s\n", 
                name_width, navn, dec, lhs, dec, b[i], dec, slack, dec, shadow_price, bindende)
    end
    println("\n")
end

##########################################################
function print_sensitivity_objective_coefficients(M, report, x, x_navne, c, dec=2)
    println("\nSensitivitetsrapport for objektivkoefficienter: \n")
    
    @printf("%-18s |%-18s |%-18s |%-18s |%-18s\n", "Variabelnavn", "Koefficientværdi",
            "Maksimalt fald", "Maksimal stigning", "Reduced costs")
    println("-"^(18*5+9))
    for i in eachindex(x)
        limits = report[x[i]]
        @printf("%-18s |%-18.*f |%-18.*f |%-18.*f |%-18.*f\n", 
                x_navne[i], dec, c[i], dec, limits[1], dec, limits[2], dec, reduced_cost(x[i]))
    end
    println("-"^(18*5+9))
    println("\n")
end

##########################################################
function print_sensitivity_RHS(report, constraints, b, b_navne, dec=2)
    println("\nSensitivitetsrapport for RHS (kapacitet): \n")
    
    # Find maksimal længde af begrænsningsnavne, men begræns til maksimum 30 tegn
    max_name_length = min(30, maximum([length(s) for s in b_navne]))
    name_width = max(20, max_name_length + 2)
    
    @printf("%-*s |%-20s |%-20s |%-20s\n", name_width, "Begrænsningnavn", "RHS (nu)",
            "Maksimalt fald", "Maksimal stigning")
    println("-"^(name_width + 20*3 + 3))
    for i in eachindex(constraints)
        limits = report[constraints[i]]
        # Afkort navn hvis det er for langt
        navn = length(b_navne[i]) > max_name_length ? b_navne[i][1:max_name_length] : b_navne[i]
        @printf("%-*s |%-20.*f |%-20.*f |%-20.*f\n", 
                name_width, navn, dec, b[i], dec, limits[1], dec, limits[2])
    end
    println("-"^(name_width + 20*3 + 3))
    println("\n")
end

##########################################################
function full_report_LP(M, report, x, x_navne, c, constraints, b, b_dir, b_navne, x_type, dec=2, tol=1e-9)
    print_optimal_solution(M, x, x_navne, x_type, dec)
    print_slack_shadow_price(M, constraints, b_navne, b, b_dir, dec, tol)
    print_sensitivity_objective_coefficients(M, report, x, x_navne, c, dec)
    print_sensitivity_RHS(report, constraints, b, b_navne, dec)
end

##########################################################
function standard_LP_output(M, x, x_navne, c, A, obj, constraints, b, b_dir, b_navne, dec=2, tol=1e-9, output_terminal=true,
     output_fil=false, output_fil_navn="output.txt", model_type="LP", x_type=nothing, fortegn=nothing)

if model_type != "LP"
    println("Fejl: Modeltype er ikke LP. Benyt anden output funktion.")
    return
end

println("Output i LP format begynder nu\n")
    # Optimer modellen, hent sensitivitetsrapport og status
optimize!(M)
status = termination_status(M)
status_str = string(status)
report = lp_sensitivity_report(M)


    # Resultat ved standard LP-solver (HiGHS)
# Statusser der har en løsning at udskrive
if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
    # Bestem status-tekst baseret på hvilken status
    if status_str == "OPTIMAL"
        status_tekst = "OPTIMAL - Optimal løsning fundet"
    else
        status_tekst = "ALMOST_OPTIMAL - Næsten optimal løsning fundet (inden for tolerance)"
    end
    # Udskriv resultaterne baseret på output_type
if output_terminal
    println("\n", status_tekst)
    full_report_LP(M, report, x, x_navne, c, constraints, b, b_dir, b_navne, x_type, dec, tol)
end

if output_fil
    open(output_fil_navn, "w") do file
        redirect_stdout(file) do
            println("\n", status_tekst)
            full_report_LP(M, report, x, x_navne, c, constraints, b, b_dir, b_navne, x_type, dec, tol)
        end
    end
    println("Output er gemt i .txt filen: ", output_fil_navn)
end

# Statusser uden løsning (kun statusbesked)
elseif status_str == "INFEASIBLE"
    println("\nINFEASIBLE - Ingen løsning: begrænsningerne er modstridende")
elseif status_str == "DUAL_INFEASIBLE"
    println("\nDUAL_INFEASIBLE (UNBOUNDED) - Problemet er ubegrænset, objektivfunktionen kan vokse uendeligt")
elseif status_str == "INFEASIBLE_OR_UNBOUNDED"
    println("\nINFEASIBLE_OR_UNBOUNDED - Enten infeasible eller unbounded (solver kan ikke skelne)")
elseif status_str == "LOCALLY_SOLVED"
    println("\nLOCALLY_SOLVED - Lokal optimal løsning fundet (for ikke-lineære problemer)")
elseif status_str == "ITERATION_LIMIT"
    println("\nITERATION_LIMIT - Maksimalt antal iterationer nået før optimal løsning")
elseif status_str == "TIME_LIMIT"
    println("\nTIME_LIMIT - Tidsgrænse nået før optimal løsning")
elseif status_str == "NUMERICAL_ERROR"
    println("\nNUMERICAL_ERROR - Numerisk fejl opstod under løsning")
elseif status_str == "OTHER_ERROR"
    println("\nOTHER_ERROR - Anden fejl opstod")
else
    println("\nUKENDT STATUS: ", status_str)
end

end

########################################################## Her starter MIP funktionerne
##########################################################
function print_slack(constraints, b_navne, b, b_dir, dec=2, tol=1e-9)
    println("Slack: \n")
    
    # Find maksimal længde af begrænsningsnavne, men begræns til maksimum 30 tegn
    max_name_length = min(30, maximum([length(s) for s in b_navne]))
    name_width = max(15, max_name_length + 2)
    
    @printf("%-*s |%-15s |%-15s |%-15s |%-15s\n", 
            name_width, "Begrænsningnavn", "LHS", "RHS", "Slack", "Bindende status")
    println("-"^(name_width + 15*4 + 4))
    for i in eachindex(constraints)
        lhs = value(constraints[i])
        if b_dir[i] == :<=
            slack = b[i] - lhs
        elseif b_dir[i] == :>=
            slack = lhs - b[i]
        else
            slack = b[i] - lhs
        end
        if abs(slack) <= tol
            bindende = "Bindende"
        else
            bindende = "Ikke-bindende"
        end
        # Afkort navn hvis det er for langt
        navn = length(b_navne[i]) > max_name_length ? b_navne[i][1:max_name_length] : b_navne[i]
        @printf("%-*s |%-15.*f |%-15.*f |%-15.*f |%-15s\n", 
                name_width, navn, dec, lhs, dec, b[i], dec, slack, bindende)
    end
    println("\n")
end

##########################################################
function full_report_MIP(M, x, x_navne, x_type, constraints, b, b_dir, b_navne, dec=2, tol=1e-9)
    print_optimal_solution(M, x, x_navne, x_type, dec)
    print_slack(constraints, b_navne, b, b_dir, dec, tol)
end
##########################################################

# Funktion til at printe assignment/transportation problem løsning som matrix
function print_assignment_transportation_matrix(M, x, x_navne, supply_navne, demand_navne, dec=2)
    println("\n" * "="^100)
    println("TRANSPORTATION/ASSIGNMENT MATRIX")
    println("="^100)
    
    n = length(supply_navne)
    m = length(demand_navne)
    
    # Opret matrix til at gemme værdier
    assignment_matrix = zeros(n, m)
    
    # Parse x_navne og find værdier
    for k in eachindex(x_navne)
        var_name = x_navne[k]
        # Variabelnavne er i form "x_supply_demand"
        parts = split(var_name, "_")
        if length(parts) >= 3
            supply_name = parts[2]
            demand_name = parts[3]
            
            # Find indeks i supply_navne og demand_navne
            i = findfirst(==(supply_name), supply_navne)
            j = findfirst(==(demand_name), demand_navne)
            
            if i !== nothing && j !== nothing
                assignment_matrix[i, j] = value(x[k])
            end
        end
    end
    
    # Beregn række- og kolonnesummer
    row_sums = [sum(assignment_matrix[i, :]) for i in 1:n]
    col_sums = [sum(assignment_matrix[:, j]) for j in 1:m]
    total_sum = sum(assignment_matrix)
    
    # Bestem kolonnebredde
    col_width = max(8, maximum([length(s) for s in vcat(supply_navne, demand_navne, ["Sum"])]) + 2)
    num_width = max(col_width, dec + 4)
    
    # Print header række
    @printf("%-*s", col_width, "")
    for j in 1:m
        @printf("|%-*s", num_width, demand_navne[j])
    end
    @printf("|%-*s", num_width, "Sum")
    println()
    
    # Print separator linje
    print("-"^col_width)
    for j in 1:(m+1)
        print("-" * "-"^num_width)
    end
    println()
    
    # Print data rækker
    for i in 1:n
        @printf("%-*s", col_width, supply_navne[i])
        for j in 1:m
            @printf("|%*.*f", num_width, dec, assignment_matrix[i, j])
        end
        @printf("|%*.*f", num_width, dec, row_sums[i])
        println()
    end
    
    # Print separator linje
    print("-"^col_width)
    for j in 1:(m+1)
        print("-" * "-"^num_width)
    end
    println()
    
    # Print sum række
    @printf("%-*s", col_width, "Sum")
    for j in 1:m
        @printf("|%*.*f", num_width, dec, col_sums[j])
    end
    @printf("|%*.*f", num_width, dec, total_sum)
    println()
    
    println("="^100)
    println()
end
##########################################################

# Funktion til at printe TSP løsning som matrix
function print_TSP_matrix(M, x, x_navne, node_navne, dec=2)
    println("\n" * "="^100)
    println("TSP MATRIX")
    println("="^100)
    
    n = length(node_navne)
    
    # Opret matrix til at gemme værdier
    tsp_matrix = zeros(n, n)
    
    # Parse x_navne og find værdier
    for k in eachindex(x_navne)
        var_name = x_navne[k]
        # Variabelnavne er i form "x_i_j" hvor i og j er tal eller navne
        parts = split(var_name, "_")
        if length(parts) >= 3
            i_str = parts[2]
            j_str = parts[3]
            
            # Prøv at parse som integers først
            try
                i = parse(Int, i_str)
                j = parse(Int, j_str)
                if 1 <= i <= n && 1 <= j <= n
                    tsp_matrix[i, j] = value(x[k])
                end
            catch
                # Hvis parsing fejler, prøv at finde i node_navne
                i = findfirst(==(i_str), node_navne)
                j = findfirst(==(j_str), node_navne)
                if i !== nothing && j !== nothing
                    tsp_matrix[i, j] = value(x[k])
                end
            end
        end
    end
    
    # Beregn række- og kolonnesummer
    row_sums = [sum(tsp_matrix[i, :]) for i in 1:n]
    col_sums = [sum(tsp_matrix[:, j]) for j in 1:n]
    total_sum = sum(tsp_matrix)
    
    # Bestem kolonnebredde
    col_width = max(8, maximum([length(s) for s in vcat(node_navne, ["Sum"])]) + 2)
    num_width = max(col_width, dec + 4)
    
    # Print header række
    @printf("%-*s", col_width, "")
    for j in 1:n
        @printf("|%-*s", num_width, node_navne[j])
    end
    @printf("|%-*s", num_width, "Sum")
    println()
    
    # Print separator linje
    print("-"^col_width)
    for j in 1:(n+1)
        print("-" * "-"^num_width)
    end
    println()
    
    # Print data rækker
    for i in 1:n
        @printf("%-*s", col_width, node_navne[i])
        for j in 1:n
            @printf("|%*.*f", num_width, dec, tsp_matrix[i, j])
        end
        @printf("|%*.*f", num_width, dec, row_sums[i])
        println()
    end
    
    # Print separator linje
    print("-"^col_width)
    for j in 1:(n+1)
        print("-" * "-"^num_width)
    end
    println()
    
    # Print sum række
    @printf("%-*s", col_width, "Sum")
    for j in 1:n
        @printf("|%*.*f", num_width, dec, col_sums[j])
    end
    @printf("|%*.*f", num_width, dec, total_sum)
    println()
    
    println("="^100)
    println()
end

# Funktion til at printe TSP tour
function print_TSP_tour(M, x, x_navne, node_navne, c, dec=2)
    println("\n" * "="^100)
    println("TSP TOUR")
    println("="^100)
    
    n = length(node_navne)
    
    # Find alle aktive kanter (x_ij = 1)
    active_edges = Tuple{Int, Int}[]
    for k in eachindex(x_navne)
        if abs(value(x[k]) - 1.0) < 1e-6  # Tjek om x[k] ≈ 1
            var_name = x_navne[k]
            # Parse variabelnavn: x_i_j (hvor i og j er tal)
            parts = split(var_name, "_")
            if length(parts) >= 3
                i_str = parts[2]
                j_str = parts[3]
                
                # Konverter til integers (variabler hedder x_1_1, x_1_2, osv.)
                try
                    i = parse(Int, i_str)
                    j = parse(Int, j_str)
                    push!(active_edges, (i, j))
                catch
                    # Hvis parsing fejler, prøv at finde i node_navne (for bagudkompatibilitet)
                    i = findfirst(==(i_str), node_navne)
                    j = findfirst(==(j_str), node_navne)
                    if i !== nothing && j !== nothing
                        push!(active_edges, (i, j))
                    end
                end
            end
        end
    end
    
    # Rekonstruer tour'en
    if length(active_edges) != n
        println("FEJL: Antal aktive kanter ($(length(active_edges))) matcher ikke antal noder ($n)")
        return
    end
    
    # Opret en dictionary for at finde næste node fra hver node
    next_node = Dict{Int, Int}()
    for (i, j) in active_edges
        next_node[i] = j
    end
    
    # Find start node (vælg første node)
    start_node = 1
    current_node = start_node
    tour = Int[]
    
    # Følg tour'en
    for _ in 1:n
        push!(tour, current_node)
        current_node = next_node[current_node]
    end
    
    # Print tour
    println("\nTour sekvens:")
    tour_str = ""
    total_cost = 0.0
    for i in 1:length(tour)
        node_idx = tour[i]
        tour_str *= node_navne[node_idx]
        if i < length(tour)
            tour_str *= " → "
            # Beregn omkostning for denne kant
            from_idx = tour[i]
            to_idx = tour[i+1]
            # Find position i c vektoren: (from_idx-1)*n + to_idx
            cost_idx = (from_idx-1)*n + to_idx
            if cost_idx <= length(c)
                cost = c[cost_idx]
                total_cost += cost
            end
        end
    end
    # Tilføj tilbage til start
    tour_str *= " → " * node_navne[tour[1]]
    # Beregn omkostning for sidste kant (tilbage til start)
    from_idx = tour[end]
    to_idx = tour[1]
    cost_idx = (from_idx-1)*n + to_idx
    if cost_idx <= length(c)
        cost = c[cost_idx]
        total_cost += cost
    end
    
    println(tour_str)
    @printf("\nTotal omkostning: %.*f\n", dec, total_cost)
    
    println("="^100)
    println()
end
##########################################################

##########################################################
function standard_MIP_output(M, x, x_navne, x_type, c, A, obj, constraints, b, b_dir, b_navne, dec=2, tol=1e-9, output_terminal=true,
     output_fil=false, output_fil_navn="output.txt", model_type="MIP", fortegn=nothing)

if model_type != "MIP"
    println("Fejl: Modeltype er ikke MIP. Benyt anden output funktion.")
    return
end

println("Output i MIP format begynder nu\n")

    # Optimer modellen og hent status
optimize!(M)
status = termination_status(M)
status_str = string(status)

    # Resultat ved MIP-solver (HiGHS)
# Statusser der har en løsning at udskrive
if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
    # Bestem status-tekst baseret på hvilken status
    if status_str == "OPTIMAL"
        status_tekst = "OPTIMAL - Optimal løsning fundet"
    else
        status_tekst = "ALMOST_OPTIMAL - Næsten optimal løsning fundet (inden for tolerance)"
    end
    # Udskriv resultaterne baseret på output_type
if output_terminal
    println("\n", status_tekst)
    full_report_MIP(M, x, x_navne, x_type, constraints, b, b_dir, b_navne, dec, tol)
end

if output_fil
    open(output_fil_navn, "w") do file
        redirect_stdout(file) do
            println("\n", status_tekst)
            full_report_MIP(M, x, x_navne, x_type, constraints, b, b_dir, b_navne, dec, tol)
        end
    end
    println("Output er gemt i .txt filen: ", output_fil_navn)
end

# Statusser uden løsning (kun statusbesked)
elseif status_str == "INFEASIBLE"
    println("\nINFEASIBLE - Ingen løsning: begrænsningerne er modstridende")
elseif status_str == "DUAL_INFEASIBLE"
    println("\nDUAL_INFEASIBLE (UNBOUNDED) - Problemet er ubegrænset, objektivfunktionen kan vokse uendeligt")
elseif status_str == "INFEASIBLE_OR_UNBOUNDED"
    println("\nINFEASIBLE_OR_UNBOUNDED - Enten infeasible eller unbounded (solver kan ikke skelne)")
elseif status_str == "LOCALLY_SOLVED"
    println("\nLOCALLY_SOLVED - Lokal optimal løsning fundet (for ikke-lineære problemer)")
elseif status_str == "ITERATION_LIMIT"
    println("\nITERATION_LIMIT - Maksimalt antal iterationer nået før optimal løsning")
elseif status_str == "TIME_LIMIT"
    println("\nTIME_LIMIT - Tidsgrænse nået før optimal løsning")
elseif status_str == "NUMERICAL_ERROR"
    println("\nNUMERICAL_ERROR - Numerisk fejl opstod under løsning")
elseif status_str == "OTHER_ERROR"
    println("\nOTHER_ERROR - Anden fejl opstod")
else
    println("\nUKENDT STATUS: ", status_str)
end

end

##########################################################
# Funktion til at printe MST kanter (edges)
function print_MST_edges(M, x, x_navne, kanter, c, dec=2)
    println("\n" * "="^100)
    println("MINIMUM SPANNING TREE - VALGTE KANTER")
    println("="^100)
    
    # Find alle aktive kanter (x ≈ 1 for binary, eller x > tol for continuous)
    active_edges = []
    total_weight = 0.0
    
    for k in eachindex(x_navne)
        val = value(x[k])
        # For binary: tjek om ≈ 1, for continuous: tjek om > tol
        if abs(val - 1.0) < 1e-6 || val > 1e-6
            # Find hvilken kant dette svarer til
            var_name = x_navne[k]
            # Parse variabelnavn: x_node1_node2
            parts = split(var_name, "_")
            if length(parts) >= 3
                node1 = parts[2]
                node2 = parts[3]
                
                # Find vægten for denne kant
                weight = c[k]
                total_weight += weight * val
                
                push!(active_edges, (node1, node2, weight, val))
            end
        end
    end
    
    # Sorter kanterne alfabetisk (først efter node1, derefter node2)
    sort!(active_edges, by = edge -> (edge[1], edge[2]))
    
    # Print kanterne med forbedret formatering
    println("\n" * "─"^100)
    println("VALGTE KANTER I MINIMUM SPANNING TREE:")
    println("─"^100)
    @printf("%-4s | %-15s | %-15s | %-12s | %-12s\n", "Nr.", "Fra node", "Til node", "Vægt", "Værdi")
    println("─"^100)
    
    for (idx, (node1, node2, weight, val)) in enumerate(active_edges)
        @printf("%-4d | %-15s | %-15s | %-12.*f | %-12.*f\n", 
                idx, node1, node2, dec, weight, dec, val)
    end
    
    println("─"^100)
    
    # Beregn antal unikke noder
    all_nodes_in_tree = Set{String}()
    for (node1, node2, weight, val) in active_edges
        push!(all_nodes_in_tree, node1)
        push!(all_nodes_in_tree, node2)
    end
    num_nodes = length(all_nodes_in_tree)
    
    # Print opsummering
    println("\n" * "─"^100)
    println("OPSUMMERING:")
    println("─"^100)
    @printf("  %-25s %.*f\n", "Total vægt af MST:", dec, total_weight)
    @printf("  %-25s %d\n", "Antal kanter i MST:", length(active_edges))
    @printf("  %-25s %d\n", "Antal noder:", num_nodes)
    @printf("  %-25s %.*f\n", "Gennemsnitlig kantvægt:", dec, total_weight / length(active_edges))
    println("─"^100)
    
    # Print træ-struktur (visuel repræsentation)
    println("\n" * "─"^100)
    println("TRÆ-STRUKTUR (visuel repræsentation):")
    println("─"^100)
    
    # Opret en mapping fra node til dens naboer
    node_neighbors = Dict{String, Vector{String}}()
    for (node1, node2, weight, val) in active_edges
        if !haskey(node_neighbors, node1)
            node_neighbors[node1] = []
        end
        if !haskey(node_neighbors, node2)
            node_neighbors[node2] = []
        end
        push!(node_neighbors[node1], node2)
        push!(node_neighbors[node2], node1)
    end
    
    # Find root (node med færrest naboer, eller første node)
    all_nodes = collect(keys(node_neighbors))
    root = all_nodes[1]
    for node in all_nodes
        if length(node_neighbors[node]) == 1
            root = node
            break
        end
    end
    
    # Print træet med indentation
    visited = Set{String}()
    function print_tree(node, prefix="", is_last=true)
        if node in visited
            return
        end
        push!(visited, node)
        
        connector = is_last ? "└── " : "├── "
        println(prefix * connector * node)
        
        neighbors = [n for n in node_neighbors[node] if n ∉ visited]
        for (idx, neighbor) in enumerate(neighbors)
            is_last_neighbor = idx == length(neighbors)
            extension = is_last ? "    " : "│   "
            print_tree(neighbor, prefix * extension, is_last_neighbor)
        end
    end
    
    print_tree(root)
    
    println("\n" * "="^100)
end

##########################################################
# Funktion til at printe MST resultater fra Kruskal's algoritme
function print_MST_Kruskal_output(active_edges, total_weight, dec=2, output_terminal=true)
    # Sorter kanterne alfabetisk (først efter node1, derefter node2)
    sort!(active_edges, by = edge -> (edge[1], edge[2]))
    
    # Beregn antal unikke noder
    all_nodes_in_tree = Set{String}()
    for (node1, node2, weight, val) in active_edges
        push!(all_nodes_in_tree, node1)
        push!(all_nodes_in_tree, node2)
    end
    num_nodes = length(all_nodes_in_tree)
    
    # Opret en mapping fra node til dens naboer
    node_neighbors = Dict{String, Vector{String}}()
    for (node1, node2, weight, val) in active_edges
        if !haskey(node_neighbors, node1)
            node_neighbors[node1] = []
        end
        if !haskey(node_neighbors, node2)
            node_neighbors[node2] = []
        end
        push!(node_neighbors[node1], node2)
        push!(node_neighbors[node2], node1)
    end
    
    # Find root (node med færrest naboer, eller første node)
    all_nodes = collect(keys(node_neighbors))
    local root = all_nodes[1]
    for node in all_nodes
        if length(node_neighbors[node]) == 1
            root = node
            break
        end
    end
    
    # Print funktion (kun hvis output_terminal er true)
    if output_terminal
        println("\n" * "="^100)
        println("MINIMUM SPANNING TREE - VALGTE KANTER (KRUSKAL'S ALGORITME)")
        println("="^100)
        
        # Print kanterne med forbedret formatering
        println("\n" * "─"^100)
        println("VALGTE KANTER I MINIMUM SPANNING TREE:")
        println("─"^100)
        @printf("%-4s | %-15s | %-15s | %-12s | %-12s\n", "Nr.", "Fra node", "Til node", "Vægt", "Værdi")
        println("─"^100)
        
        for (idx, (node1, node2, weight, val)) in enumerate(active_edges)
            @printf("%-4d | %-15s | %-15s | %-12.*f | %-12.*f\n", 
                    idx, node1, node2, dec, weight, dec, val)
        end
        
        println("─"^100)
        
        # Print opsummering
        println("\n" * "─"^100)
        println("OPSUMMERING:")
        println("─"^100)
        @printf("  %-25s %.*f\n", "Total vægt af MST:", dec, total_weight)
        @printf("  %-25s %d\n", "Antal kanter i MST:", length(active_edges))
        @printf("  %-25s %d\n", "Antal noder:", num_nodes)
        @printf("  %-25s %.*f\n", "Gennemsnitlig kantvægt:", dec, total_weight / length(active_edges))
        println("─"^100)
        
        # Print træ-struktur (visuel repræsentation)
        println("\n" * "─"^100)
        println("TRÆ-STRUKTUR (visuel repræsentation):")
        println("─"^100)
        
        # Print træet med indentation
        visited = Set{String}()
        function print_tree(node, prefix="", is_last=true)
            if node in visited
                return
            end
            push!(visited, node)
            
            connector = is_last ? "└── " : "├── "
            println(prefix * connector * node)
            
            neighbors = [n for n in node_neighbors[node] if n ∉ visited]
            for (idx, neighbor) in enumerate(neighbors)
                is_last_neighbor = idx == length(neighbors)
                extension = is_last ? "    " : "│   "
                print_tree(neighbor, prefix * extension, is_last_neighbor)
            end
        end
        
        print_tree(root)
        
        println("\n" * "="^100)
    end
end

##########################################################
# Funktion til at printe shortest path sti
function print_shortest_path(M, x, x_navne, kanter, source_node, sink_node, c, dec=2)
    println("\n" * "="^100)
    println("SHORTEST PATH - LØSNING")
    println("="^100)
    
    # Find alle aktive kanter (værdi ≈ 1.0)
    active_edges = Dict{String, String}();  # Mapping fra from_node til to_node
    edge_weights = Dict{Tuple{String, String}, Float64}();  # Mapping fra (from, to) til vægt
    total_weight = 0.0
    
    # Opret mapping fra variabelnavn til (from, to) par
    var_to_edge = Dict{String, Tuple{String, String}}();
    for (idx, var_name) in enumerate(x_navne)
        val = value(x[idx])
        if abs(val - 1.0) < 1e-6 || val > 1e-6
            # Parse variabelnavn: x_from_to
            parts = split(var_name, "_")
            if length(parts) >= 3
                from_node = parts[2]
                to_node = parts[3]
                var_to_edge[var_name] = (from_node, to_node)
                
                # Hvis værdien er tæt på 1, er det en aktiv kant
                if abs(val - 1.0) < 1e-6
                    active_edges[from_node] = to_node
                    weight = c[idx]
                    edge_weights[(from_node, to_node)] = weight
                    total_weight += weight * val
                end
            end
        end
    end
    
    # Rekonstruer stien fra source til sink
    path = [source_node]
    current_node = source_node
    path_found = false
    
    while current_node != sink_node
        if haskey(active_edges, current_node)
            next_node = active_edges[current_node]
            push!(path, next_node)
            current_node = next_node
            path_found = true
        else
            # Hvis vi ikke kan finde næste node, er stien ikke komplet
            println("⚠️  ADVARSEL: Kunne ikke rekonstruere hele stien fra ", source_node, " til ", sink_node)
            break
        end
    end
    
    # Print stien
    println("\n" * "─"^100)
    println("KORTESTE STI:")
    println("─"^100)
    @printf("Fra: %s\n", source_node)
    @printf("Til: %s\n", sink_node)
    @printf("Total vægt: %.*f\n\n", dec, total_weight)
    
    println("Sti:")
    if path_found && path[end] == sink_node
        # Vis stien med kanter og vægte
        for i in 1:(length(path)-1)
            from = path[i]
            to = path[i+1]
            weight = haskey(edge_weights, (from, to)) ? edge_weights[(from, to)] : 0.0
            if i == 1
                @printf("  %s --[%.*f]--> %s", from, dec, weight, to)
            else
                @printf(" --[%.*f]--> %s", dec, weight, to)
            end
        end
        println()
        println()
        # Vis også som simpel liste
        @printf("  %s\n", join(path, " → "))
    else
        println("  Kunne ikke finde komplet sti")
    end
    
    println("\n" * "─"^100)
    println("OPSUMMERING:")
    println("─"^100)
    @printf("  %-25s %.*f\n", "Total vægt af sti:", dec, total_weight)
    @printf("  %-25s %d\n", "Antal kanter i sti:", length(path) - 1)
    @printf("  %-25s %d\n", "Antal noder i sti:", length(path))
    if length(path) > 1
        @printf("  %-25s %.*f\n", "Gennemsnitlig kantvægt:", dec, total_weight / (length(path) - 1))
    end
    println("─"^100)
    
    println("\n" * "="^100)
end

##########################################################
# Funktion til at printe shortest path sti fra algoritme (Dijkstra/Bellman-Ford)
# Tager path (liste af noder) og edge_weights (dict fra (from, to) til vægt)
function print_shortest_path_algorithm(path, edge_weights, source_node, sink_node, total_weight, dec=2, output_terminal=true)
    if !output_terminal
        return
    end
    
    println("\n" * "="^100)
    println("SHORTEST PATH - LØSNING")
    println("="^100)
    
    # Print stien
    println("\n" * "─"^100)
    println("KORTESTE STI:")
    println("─"^100)
    @printf("Fra: %s\n", source_node)
    @printf("Til: %s\n", sink_node)
    @printf("Total vægt: %.*f\n\n", dec, total_weight)
    
    println("Sti:")
    if length(path) > 1
        # Vis stien med kanter og vægte
        for i in 1:(length(path)-1)
            from = path[i]
            to = path[i+1]
            weight = haskey(edge_weights, (from, to)) ? edge_weights[(from, to)] : 0.0
            if i == 1
                @printf("  %s --[%.*f]--> %s", from, dec, weight, to)
            else
                @printf(" --[%.*f]--> %s", dec, weight, to)
            end
        end
        println()
        println()
        # Vis også som simpel liste
        @printf("  %s\n", join(path, " → "))
    else
        println("  Ingen sti fundet")
    end
    
    println("\n" * "─"^100)
    println("OPSUMMERING:")
    println("─"^100)
    @printf("  %-25s %.*f\n", "Total vægt af sti:", dec, total_weight)
    if length(path) > 1
        @printf("  %-25s %d\n", "Antal kanter i sti:", length(path) - 1)
        @printf("  %-25s %d\n", "Antal noder i sti:", length(path))
        @printf("  %-25s %.*f\n", "Gennemsnitlig kantvægt:", dec, total_weight / (length(path) - 1))
    end
    println("─"^100)
    
    println("\n" * "="^100)
end