using Printf

# Hjælpefunktion til at runde værdier tæt på nul til 0.0 (for at undgå -0.00 i output)
function round_near_zero(val, tol=1e-9)
    return abs(val) < tol ? 0.0 : val
end

# Simpel funktion til at beregne kolonnebredde baseret på værdier
function calculate_num_width(values, dec=2, min_width=10)
    max_len = min_width
    for val in values
        if !isnan(val) && !isinf(val)
            len = length(@sprintf("%.*f", dec, val))
            max_len = max(max_len, len)
        end
    end
    return max_len + 2  # Lidt padding
end

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
    
    # Hent objektivets retning
    obj_sense = objective_sense(M)
    obj_sense_str = string(obj_sense)
    
    # Beregn alle værdier først for at finde maksimale bredder
    lhs_vals = Float64[]
    slack_vals = Float64[]
    shadow_vals = Float64[]
    for i in eachindex(constraints)
        push!(lhs_vals, value(constraints[i]))
        lhs = value(constraints[i])
        if b_dir[i] == :<=
            slack = b[i] - lhs
        elseif b_dir[i] == :>=
            slack = lhs - b[i]
        else
            slack = b[i] - lhs
        end
        push!(slack_vals, slack)
        dual_val = dual(constraints[i])
        shadow_price = obj_sense_str == "MIN_SENSE" ? dual_val : -dual_val
        push!(shadow_vals, round_near_zero(shadow_price))
    end
    
    # Beregn dynamiske bredder
    lhs_width = calculate_num_width(vcat(lhs_vals, b), dec, 10)
    rhs_width = calculate_num_width(b, dec, 10)
    slack_width = calculate_num_width(slack_vals, dec, 10)
    shadow_width = calculate_num_width(shadow_vals, dec, 10)
    bindende_width = max(15, length("Ikke-bindende"))
    
    total_width = name_width + lhs_width + rhs_width + slack_width + shadow_width + bindende_width + 10
    @printf("%-*s |%-*s |%-*s |%-*s |%-*s |%-*s\n", 
            name_width, "Begrænsningnavn", lhs_width, "LHS", rhs_width, "RHS", 
            slack_width, "Slack", shadow_width, "Skyggepris", bindende_width, "Bindende status")
    println("-"^total_width)
    
    for i in eachindex(constraints)
        lhs = lhs_vals[i]
        slack = slack_vals[i]
        shadow_price = shadow_vals[i]
        bindende = abs(slack) <= tol ? "Bindende" : "Ikke-bindende"
        navn = length(b_navne[i]) > max_name_length ? b_navne[i][1:max_name_length] : b_navne[i]
        @printf("%-*s |%-*.*f |%-*.*f |%-*.*f |%-*.*f |%-*s\n", 
                name_width, navn, lhs_width, dec, lhs, rhs_width, dec, b[i], 
                slack_width, dec, slack, shadow_width, dec, shadow_price, bindende_width, bindende)
    end
    println("\n")
end

##########################################################
function print_sensitivity_objective_coefficients(M, report, x, x_navne, c, dec=2)
    println("\nSensitivitetsrapport for objektivkoefficienter: \n")
    
    # Find maksimal længde af variabelnavne, men begræns til maksimum 40 tegn
    max_name_length = min(40, maximum([length(s) for s in x_navne]))
    name_width = max(18, max_name_length + 2)
    
    # Beregn alle værdier først for at finde maksimale bredder
    coeff_vals = Float64[]
    limit1_vals = Float64[]
    limit2_vals = Float64[]
    red_cost_vals = Float64[]
    for i in eachindex(x)
        push!(coeff_vals, c[i])
        limits = report[x[i]]
        push!(limit1_vals, round_near_zero(limits[1]))
        push!(limit2_vals, round_near_zero(limits[2]))
        push!(red_cost_vals, round_near_zero(reduced_cost(x[i])))
    end
    
    # Beregn dynamiske bredder
    coeff_width = calculate_num_width(coeff_vals, dec, 10)
    limit1_width = calculate_num_width(limit1_vals, dec, 10)
    limit2_width = calculate_num_width(limit2_vals, dec, 10)
    red_cost_width = calculate_num_width(red_cost_vals, dec, 10)
    
    total_width = name_width + coeff_width + limit1_width + limit2_width + red_cost_width + 9
    @printf("%-*s |%-*s |%-*s |%-*s |%-*s\n", 
            name_width, "Variabelnavn", 
            coeff_width, "Koefficientværdi",
            limit1_width, "Maksimalt fald", 
            limit2_width, "Maksimal stigning", 
            red_cost_width, "Reduced costs")
    println("-"^total_width)
    
    for i in eachindex(x)
        limits = report[x[i]]
        navn = length(x_navne[i]) > max_name_length ? x_navne[i][1:max_name_length] : x_navne[i]
        @printf("%-*s |%-*.*f |%-*.*f |%-*.*f |%-*.*f\n", 
                name_width, navn, 
                coeff_width, dec, c[i], 
                limit1_width, dec, round_near_zero(limits[1]), 
                limit2_width, dec, round_near_zero(limits[2]), 
                red_cost_width, dec, round_near_zero(reduced_cost(x[i])))
    end
    println("-"^total_width)
    println("\n")
end

##########################################################
function print_sensitivity_RHS(report, constraints, b, b_navne, dec=2)
    println("\nSensitivitetsrapport for RHS (kapacitet): \n")
    
    # Find maksimal længde af begrænsningsnavne, men begræns til maksimum 30 tegn
    max_name_length = min(30, maximum([length(s) for s in b_navne]))
    name_width = max(20, max_name_length + 2)
    
    # Beregn alle værdier først for at finde maksimale bredder
    rhs_vals = Float64[]
    limit1_vals = Float64[]
    limit2_vals = Float64[]
    for i in eachindex(constraints)
        push!(rhs_vals, b[i])
        limits = report[constraints[i]]
        push!(limit1_vals, round_near_zero(limits[1]))
        push!(limit2_vals, round_near_zero(limits[2]))
    end
    
    # Beregn dynamiske bredder
    rhs_width = calculate_num_width(rhs_vals, dec, 10)
    limit1_width = calculate_num_width(limit1_vals, dec, 10)
    limit2_width = calculate_num_width(limit2_vals, dec, 10)
    
    total_width = name_width + rhs_width + limit1_width + limit2_width + 6
    @printf("%-*s |%-*s |%-*s |%-*s\n", name_width, "Begrænsningnavn", rhs_width, "RHS (nu)",
            limit1_width, "Maksimalt fald", limit2_width, "Maksimal stigning")
    println("-"^total_width)
    for i in eachindex(constraints)
        limits = report[constraints[i]]
        navn = length(b_navne[i]) > max_name_length ? b_navne[i][1:max_name_length] : b_navne[i]
        @printf("%-*s |%-*.*f |%-*.*f |%-*.*f\n", 
                name_width, navn, rhs_width, dec, b[i], 
                limit1_width, dec, round_near_zero(limits[1]), 
                limit2_width, dec, round_near_zero(limits[2]))
    end
    println("-"^total_width)
    println("\n")
end

# Funktion til at tjekke for advarsel om uendeligt mange løsninger
function check_multiple_solutions(x, x_navne, tol=1e-9)
    warning_vars = []
    for i in eachindex(x)
        val = value(x[i])
        red_cost = reduced_cost(x[i])
        # Tjek om variabel er ikke-basis (værdi tæt på 0) og har reduced cost = 0
        if abs(val) < tol && abs(red_cost) < tol
            push!(warning_vars, x_navne[i])
        end
    end
    return warning_vars
end

##########################################################
function full_report_LP(M, report, x, x_navne, c, constraints, b, b_dir, b_navne, x_type, dec=2, tol=1e-9)
    print_optimal_solution(M, x, x_navne, x_type, dec)
    print_slack_shadow_price(M, constraints, b_navne, b, b_dir, dec, tol)
    print_sensitivity_objective_coefficients(M, report, x, x_navne, c, dec)
    print_sensitivity_RHS(report, constraints, b, b_navne, dec)
    
    # Tjek for advarsel om uendeligt mange løsninger
    warning_vars = check_multiple_solutions(x, x_navne, tol)
    if !isempty(warning_vars)
        println("="^100)
        println(" ADVARSEL: Uendeligt mange løsninger muligt")
        println("="^100)
        println("Følgende ikke-basisvariabler har reduced cost = 0:")
        for var in warning_vars
            println("  - $var")
        end
        println("Dette kan indikere, at der findes uendeligt mange optimale løsninger.")
        println("="^100)
        println()
    end
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
    
    # Beregn alle værdier først for at finde maksimale bredder
    lhs_vals = Float64[]
    slack_vals = Float64[]
    for i in eachindex(constraints)
        lhs = value(constraints[i])
        push!(lhs_vals, lhs)
        if b_dir[i] == :<=
            slack = b[i] - lhs
        elseif b_dir[i] == :>=
            slack = lhs - b[i]
        else
            slack = b[i] - lhs
        end
        push!(slack_vals, slack)
    end
    
    # Beregn dynamiske bredder
    lhs_width = calculate_num_width(vcat(lhs_vals, b), dec, 10)
    rhs_width = calculate_num_width(b, dec, 10)
    slack_width = calculate_num_width(slack_vals, dec, 10)
    bindende_width = max(15, length("Ikke-bindende"))
    
    total_width = name_width + lhs_width + rhs_width + slack_width + bindende_width + 8
    @printf("%-*s |%-*s |%-*s |%-*s |%-*s\n", 
            name_width, "Begrænsningnavn", lhs_width, "LHS", rhs_width, "RHS", 
            slack_width, "Slack", bindende_width, "Bindende status")
    println("-"^total_width)
    for i in eachindex(constraints)
        lhs = lhs_vals[i]
        slack = slack_vals[i]
        bindende = abs(slack) <= tol ? "Bindende" : "Ikke-bindende"
        navn = length(b_navne[i]) > max_name_length ? b_navne[i][1:max_name_length] : b_navne[i]
        @printf("%-*s |%-*.*f |%-*.*f |%-*.*f |%-*s\n", 
                name_width, navn, lhs_width, dec, lhs, rhs_width, dec, b[i], 
                slack_width, dec, slack, bindende_width, bindende)
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
            println(" ADVARSEL: Kunne ikke rekonstruere hele stien fra ", source_node, " til ", sink_node)
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

##########################################################
# Funktion til at printe max flow løsning
function print_max_flow(M, x, x_navne, kanter, source_node, sink_node, kapaciteter, dec=2)
    println("\n" * "="^100)
    println("MAXIMUM FLOW - LØSNING")
    println("="^100)
    
    # Beregn total flow (sum af flow fra source)
    total_flow = 0.0
    active_flows = Dict{Tuple{String, String}, Float64}()  # Mapping fra (from, to) til flow værdi
    
    # Opret mapping fra variabelnavn til (from, to) par og find flow værdier
    for (idx, var_name) in enumerate(x_navne)
        val = value(x[idx])
        if val > 1e-6  # Hvis der er flow gennem denne kant
            # Parse variabelnavn: x_from_to
            parts = split(var_name, "_")
            if length(parts) >= 3
                from_node = parts[2]
                to_node = parts[3]
                
                active_flows[(from_node, to_node)] = val
                
                # Hvis det er en kant fra source, tilføj til total flow
                if from_node == source_node
                    total_flow += val
                end
            end
        end
    end
    
    # Print resultater
    println("\n" * "─"^100)
    println("FLOW RESULTATER:")
    println("─"^100)
    @printf("Source node: %s\n", source_node)
    @printf("Sink node: %s\n", sink_node)
    @printf("Maksimal flow: %.*f\n\n", dec, total_flow)
    
    # Print flow gennem hver kant
    println("Flow gennem kanter:")
    println("─"^100)
    @printf("%-20s | %-20s | %-15s | %-15s | %-15s\n", "Fra node", "Til node", "Flow", "Kapacitet", "Utilisering")
    println("─"^100)
    
    # Sorter kanter for bedre læsbarhed
    sorted_edges = sort(collect(keys(active_flows)), by = x -> (x[1], x[2]))
    
    for (from_node, to_node) in sorted_edges
        flow_val = active_flows[(from_node, to_node)]
        # Find kapacitet for denne kant
        capacity = 0.0
        for (idx, kant) in enumerate(kanter)
            if length(kant) >= 3
                if kant[1] == from_node && kant[2] == to_node
                    capacity = Float64(kant[3])
                    break
                end
            end
        end
        utilization = capacity > 0 ? (flow_val / capacity) * 100 : 0.0
        @printf("%-20s | %-20s | %-15.*f | %-15.*f | %-15.*f%%\n", 
                from_node, to_node, dec, flow_val, dec, capacity, dec, utilization)
    end
    
    println("─"^100)
    println("\n" * "─"^100)
    println("OPSUMMERING:")
    println("─"^100)
    @printf("  %-30s %.*f\n", "Maksimal flow værdi:", dec, total_flow)
    @printf("  %-30s %d\n", "Antal aktive kanter:", length(active_flows))
    println("─"^100)
    
    # Print flow netværk-struktur (visuel repræsentation)
    println("\n" * "─"^100)
    println("FLOW NETVÆRK (visuel repræsentation):")
    println("─"^100)
    
    # Opret en mapping fra node til dens udgående kanter (med flow værdier)
    node_outgoing = Dict{String, Vector{Tuple{String, Float64}}}()  # Mapping fra node til [(to_node, flow), ...]
    
    for ((from_node, to_node), flow_val) in active_flows
        if flow_val > 1e-6  # Kun kanter med flow
            if !haskey(node_outgoing, from_node)
                node_outgoing[from_node] = []
            end
            push!(node_outgoing[from_node], (to_node, flow_val))
        end
    end
    
    # Vis flow-netværket grupperet efter hver node's udgående flow
    # Start med source node og vis alle noder i en logisk rækkefølge
    visited = Set{String}()
    nodes_to_process = [source_node]
    
    println()
    while !isempty(nodes_to_process)
        current_node = popfirst!(nodes_to_process)
        if current_node in visited
            continue
        end
        push!(visited, current_node)
        
        if haskey(node_outgoing, current_node)
            # Vis node header
            if current_node == source_node
                println("  $(current_node) (SOURCE)")
            elseif current_node == sink_node
                println("  $(current_node) (SINK)")
            else
                println("  $(current_node)")
            end
            
            # Vis alle udgående kanter fra denne node
            for (to_node, flow_val) in node_outgoing[current_node]
                # Find kapacitet for denne kant
                capacity = 0.0
                for (idx, kant) in enumerate(kanter)
                    # Kant er en tuple: (from_node, to_node, kapacitet)
                    if length(kant) >= 2 && kant[1] == current_node && kant[2] == to_node
                        if length(kant) >= 3
                            # Kapacitet er i tredje element af tuple
                            capacity = Float64(kant[3])
                        elseif idx <= length(kapaciteter)
                            # Eller brug kapaciteter array
                            capacity = kapaciteter[idx]
                        end
                        break
                    end
                end
                
                utilization = capacity > 0 ? (flow_val / capacity) * 100 : 0.0
                
                # Vis kant med flow og kapacitet
                if capacity > 0
                    arrow = " ──[flow: $(round(flow_val, digits=dec)) / cap: $(round(capacity, digits=dec))]──> "
                else
                    arrow = " ──[flow: $(round(flow_val, digits=dec))]──> "
                end
                @printf("    %s%s", arrow, to_node)
                
                if to_node == sink_node
                    println(" (SINK)")
                else
                    println()
                end
                
                # Tilføj destination node til køen hvis den ikke er besøgt
                if !(to_node in visited) && haskey(node_outgoing, to_node)
                    push!(nodes_to_process, to_node)
                end
            end
            println()
        end
    end
    
    println("─"^100)
    println("\n" * "="^100)
end

##########################################################
# Funktion til at visualisere maximum flow
# Kræver: using Graphs, GraphPlot, Colors (skal være inkluderet i filen der kalder funktionen)
function plot_max_flow(M, x, x_navne, kanter, noder, source_node, sink_node, kapaciteter, dec=2)
    # Vi starter med at bygge grafen med alle noder
    num_noder = length(noder)
    G = SimpleDiGraph(num_noder)  # Directed graph for max flow

    # Mapping fra nodenavn til integer index
    node_to_int = Dict(noder[i] => i for i in 1:num_noder)

    # Opretter mapping fra edge til kapacitet og flow
    edge_capacities = Dict()
    edge_flows = Dict()
    
    # Find flow værdier fra løsningen
    for (idx, var_name) in enumerate(x_navne)
        val = value(x[idx])
        # Parse variabelnavn: x_from_to
        parts = split(var_name, "_")
        if length(parts) >= 3
            from_node = parts[2]
            to_node = parts[3]
            if haskey(node_to_int, from_node) && haskey(node_to_int, to_node)
                i = node_to_int[from_node]
                j = node_to_int[to_node]
                edge_flows[(i, j)] = val
            end
        end
    end

    # Tilføjer alle kanter til grafen og gem kapaciteter
    for (idx, kant) in enumerate(kanter)
        from_node, to_node, capacity = kant[1], kant[2], kant[3]
        i = node_to_int[from_node]
        j = node_to_int[to_node]
        add_edge!(G, i, j)
        edge_capacities[(i, j)] = Float64(capacity)
        # Hvis der ikke er flow for denne edge, sæt til 0
        if !haskey(edge_flows, (i, j))
            edge_flows[(i, j)] = 0.0
        end
    end

    # Beregn flow/capacity ratio for hver edge og find maksimum for normalisering
    max_ratio = 0.0
    edge_ratios = Dict()
    for e in edges(G)
        i, j = src(e), dst(e)
        flow = edge_flows[(i, j)]
        capacity = edge_capacities[(i, j)]
        ratio = capacity > 0 ? flow / capacity : 0.0
        edge_ratios[(i, j)] = ratio
        max_ratio = max(max_ratio, ratio)
    end

    # Opretter farver for edges baseret på flow/capacity ratio
    # Gradient: mørk blå (høj flow) -> lys blå (lav flow) -> grå (ingen flow)
    edge_colors = []
    edge_widths = []
    for e in edges(G)
        i, j = src(e), dst(e)
        ratio = edge_ratios[(i, j)]
        flow = edge_flows[(i, j)]
        
        if flow < 1e-6
            # Ingen flow - grå og tynd
            push!(edge_colors, colorant"grey70")
            push!(edge_widths, 0.5)
        else
            # Normaliser ratio (0 til 1)
            normalized_ratio = max_ratio > 0 ? ratio / max_ratio : 0.0
            
            # Gradient fra lys blå (lav flow) til mørk blå (høj flow)
            # Interpoler mellem lightblue (0,0,1) og darkblue (0,0,0.5) baseret på normalized_ratio
            # Brug RGB værdier: r=0, g går fra 0.7 til 0, b går fra 1.0 til 0.5
            r = 0.0
            g = 0.7 * (1.0 - normalized_ratio)  # Går fra 0.7 til 0
            b = 1.0 - 0.5 * normalized_ratio    # Går fra 1.0 til 0.5
            
            # Konverter til RGB colorant
            push!(edge_colors, RGB(r, g, b))
            # Edge width baseret på flow: minimum 0.5, maksimum 2.0 (tyndere)
            width = 0.5 + 1.5 * normalized_ratio
            push!(edge_widths, width)
        end
    end
    
    # Opretter farver for noder - marker source og sink
    node_colors = fill(colorant"lightsteelblue", num_noder)
    source_idx = node_to_int[source_node]
    sink_idx = node_to_int[sink_node]
    node_colors[source_idx] = colorant"red"  # Rød for source (start)
    node_colors[sink_idx] = colorant"green"  # Grøn for sink (mål)

    # Opret edge labels (flow/capacity format)
    edge_labels = String[]
    for e in edges(G)
        i, j = src(e), dst(e)
        flow = edge_flows[(i, j)]
        capacity = edge_capacities[(i, j)]
        
        # Vis label kun hvis der er flow (eller vis alle - kan justeres)
        if flow > 1e-6
            push!(edge_labels, string(round(flow, digits=dec), "/", round(capacity, digits=dec)))
        else
            push!(edge_labels, "")  # Tom label for kanter uden flow
        end
    end
    
    # Opret node labels
    node_labels = [string(node) for node in noder]
    
    # Plotter grafen
    p = gplot(G, 
              nodelabel=node_labels,
              edgelabel=edge_labels,
              edgestrokec=edge_colors,
              edgelinewidth=edge_widths,
              nodesize=0.8,  # Større nodes for større plot
              nodefillc=node_colors,
              nodestrokec=colorant"black",
              nodestrokelw=1.0)  # Tyndere node borders
    
    # Prøv at vise plottet - virker i VSCode, men kan fejle i terminalen uden Cairo/Fontconfig
    try
        display("image/svg+xml",p)
    catch e
        if occursin("Cairo", string(e)) || occursin("Fontconfig", string(e)) || occursin("image/png", string(e))
            println("   (Plottet kan ikke vises i denne terminal. Installer Cairo og Fontconfig for at se plottet.)")
            println("   Koden kører stadig korrekt - se output filen for resultater.")
        else
            rethrow(e)  # Hvis det er en anden fejl, rethrow den
        end
    end
    return p
end

##########################################################
# Funktion til at visualiserer MST
# Kræver: using Graphs, GraphPlot, Colors (skal være inkluderet i filen der kalder funktionen)
function plot_MST(M, x, x_navne, kanter, noder, c, dec=2)
    # Vi starter med at bygge grafen med alle noder
    num_noder = length(noder)
    G = SimpleGraph(num_noder)

    # Mapping fra nodenavn til integer index
    node_to_int = Dict(noder[i] => i for i in 1:num_noder)

    # Opretter mapping fra edge til vægt
    edge_weights = Dict()

    # Tilføjer alle kanter til grafen
    for (idx, (node1, node2, weight)) in enumerate(kanter)
        i = node_to_int[node1]
        j = node_to_int[node2]
        add_edge!(G, i, j)
        edge_weights[(i, j)] = weight
        edge_weights[(j, i)] = weight
    end

    # Find aktive kanter i MST
    mst_edges = Set()
    for k in eachindex(x_navne)
        val = value(x[k])
        if abs(val - 1.0) < 1e-6 || val > 1e-6
            var_name = x_navne[k]
            parts = split(var_name, "_")
            if length(parts) >= 3
                node1 = parts[2]
                node2 = parts[3]
                i = node_to_int[node1]
                j = node_to_int[node2]
                push!(mst_edges, (i, j))
                push!(mst_edges, (j, i))
            end
        end
    end

    # Opretter farver for edges i MST
    # Grøn for MST grå for andre - bruger colorant i stedet for Symbols
    edge_colors = [(src(e), dst(e)) in mst_edges ? colorant"seagreen" : colorant"grey50" for e in edges(G)]
    edge_widths = [(src(e), dst(e)) in mst_edges ? 3.0 : 0.5 for e in edges(G)]
    
    # Opretter farver for noder i MST
    node_colors = fill(colorant"lightsteelblue", num_noder)

    # ===== INDSTILLING: Edge labels =====
    # Sæt til true for at vise labels på alle kanter, false for kun MST-kanter
    show_all_edge_labels = true  # Ændr denne værdi for at vælge
    # =====================================
    
    # Opret edge labels (vægte) som Vector - GraphPlot forventer Vector, ikke Dict
    # En label for hver edge i edges(G)
    edge_labels = String[]
    for e in edges(G)
        i, j = src(e), dst(e)
        # Vis label hvis: alle labels er aktiveret, ELLER kanten er i MST
        if show_all_edge_labels || (i, j) in mst_edges || (j, i) in mst_edges
            weight = edge_weights[(i, j)]
            push!(edge_labels, string(round(weight, digits=dec)))
        else
            push!(edge_labels, "")  # Tom label for kanter uden label
        end
    end
    
    # Opret node labels
    node_labels = [string(node) for node in noder]
    
    # Plotter grafen
    # GraphPlot bruger automatisk en passende layout (spring layout som default)
    p = gplot(G, 
              nodelabel=node_labels,
              edgelabel=edge_labels,
              edgestrokec=edge_colors,
              edgelinewidth=edge_widths,
              nodesize=0.3,
              nodefillc=node_colors,
              nodestrokec=colorant"black",
              nodestrokelw=2.0)  # Rettet: nodestrokewidth -> nodestrokelw
    
    # Prøv at vise plottet - virker i VSCode, men kan fejle i terminalen uden Cairo/Fontconfig
    try
        display("image/svg+xml",p)
    catch e
        if occursin("Cairo", string(e)) || occursin("Fontconfig", string(e)) || occursin("image/png", string(e))
            println("   (Plottet kan ikke vises i denne terminal. Installer Cairo og Fontconfig for at se plottet.)")
            println("   Koden kører stadig korrekt - se output filen for resultater.")
        else
            rethrow(e)  # Hvis det er en anden fejl, rethrow den
        end
    end
    return p
end

##########################################################
# Funktion til at visualisere MST fra direkte edges (f.eks. fra Kruskal)
# Kræver: using Graphs, GraphPlot, Colors (skal være inkluderet i filen der kalder funktionen)
# active_edges: Liste af tuples (node1, node2, weight, value) eller (node1, node2, weight)
function plot_MST_from_edges(active_edges, kanter, noder, dec=2)
    # Vi starter med at bygge grafen med alle noder
    num_noder = length(noder)
    G = SimpleGraph(num_noder)

    # Mapping fra nodenavn til integer index
    node_to_int = Dict(noder[i] => i for i in 1:num_noder)

    # Opretter mapping fra edge til vægt
    edge_weights = Dict()

    # Tilføjer alle kanter til grafen
    for (idx, (node1, node2, weight)) in enumerate(kanter)
        i = node_to_int[node1]
        j = node_to_int[node2]
        add_edge!(G, i, j)
        edge_weights[(i, j)] = weight
        edge_weights[(j, i)] = weight
    end

    # Find aktive kanter i MST fra active_edges
    mst_edges = Set()
    for edge_tuple in active_edges
        # Håndter både (node1, node2, weight, value) og (node1, node2, weight) format
        if length(edge_tuple) >= 3
            node1 = edge_tuple[1]
            node2 = edge_tuple[2]
            if haskey(node_to_int, node1) && haskey(node_to_int, node2)
                i = node_to_int[node1]
                j = node_to_int[node2]
                push!(mst_edges, (i, j))
                push!(mst_edges, (j, i))
            end
        end
    end

    # Opretter farver for edges i MST
    # Grøn for MST grå for andre - bruger colorant i stedet for Symbols
    edge_colors = [(src(e), dst(e)) in mst_edges ? colorant"seagreen" : colorant"grey50" for e in edges(G)]
    edge_widths = [(src(e), dst(e)) in mst_edges ? 3.0 : 0.5 for e in edges(G)]
    
    # Opretter farver for noder i MST
    node_colors = fill(colorant"lightsteelblue", num_noder)

    # ===== INDSTILLING: Edge labels =====
    # Sæt til true for at vise labels på alle kanter, false for kun MST-kanter
    show_all_edge_labels = true  # Ændr denne værdi for at vælge
    # =====================================
    
    # Opret edge labels (vægte) som Vector - GraphPlot forventer Vector, ikke Dict
    # En label for hver edge i edges(G)
    edge_labels = String[]
    for e in edges(G)
        i, j = src(e), dst(e)
        # Vis label hvis: alle labels er aktiveret, ELLER kanten er i MST
        if show_all_edge_labels || (i, j) in mst_edges || (j, i) in mst_edges
            weight = edge_weights[(i, j)]
            push!(edge_labels, string(round(weight, digits=dec)))
        else
            push!(edge_labels, "")  # Tom label for kanter uden label
        end
    end
    
    # Opret node labels
    node_labels = [string(node) for node in noder]
    
    # Plotter grafen
    # GraphPlot bruger automatisk en passende layout (spring layout som default)
    p = gplot(G, 
              nodelabel=node_labels,
              edgelabel=edge_labels,
              edgestrokec=edge_colors,
              edgelinewidth=edge_widths,
              nodesize=0.3,
              nodefillc=node_colors,
              nodestrokec=colorant"black",
              nodestrokelw=2.0)
    
    # Prøv at vise plottet - virker i VSCode, men kan fejle i terminalen uden Cairo/Fontconfig
    try
        display("image/svg+xml",p)
    catch e
        if occursin("Cairo", string(e)) || occursin("Fontconfig", string(e)) || occursin("image/png", string(e))
            println("   (Plottet kan ikke vises i denne terminal. Installer Cairo og Fontconfig for at se plottet.)")
            println("   Koden kører stadig korrekt - se output filen for resultater.")
        else
            rethrow(e)  # Hvis det er en anden fejl, rethrow den
        end
    end
    return p
end

##########################################################
# Funktion til at visualisere shortest path
# Kræver: using Graphs, GraphPlot, Colors (skal være inkluderet i filen der kalder funktionen)
function plot_shortest_path(M, x, x_navne, kanter, noder, source_node, sink_node, c, dec=2)
    # Vi starter med at bygge grafen med alle noder
    num_noder = length(noder)
    G = SimpleDiGraph(num_noder)  # Directed graph for shortest path

    # Mapping fra nodenavn til integer index
    node_to_int = Dict(noder[i] => i for i in 1:num_noder)

    # Opretter mapping fra edge til vægt
    edge_weights = Dict()
    bidirectional_edges = Dict()  # Track edges der har modsatte retning: (min(i,j), max(i,j)) => (weight_ij, weight_ji)
    added_undirected = Set()  # Track undirected edges vi allerede har tilføjet

    # Først: saml alle edges for at finde bidirectional edges
    for (idx, kant) in enumerate(kanter)
        from_node, to_node, weight = kant[1], kant[2], kant[3]
        i = node_to_int[from_node]
        j = node_to_int[to_node]
        
        is_undirected = length(kant) == 4 && kant[4] == "U"
        
        if !is_undirected
            # For directed edges, track begge retninger
            key = (min(i, j), max(i, j))
            if !haskey(bidirectional_edges, key)
                bidirectional_edges[key] = (nothing, nothing)
            end
            if i < j
                bidirectional_edges[key] = (Float64(weight), bidirectional_edges[key][2])
            else
                bidirectional_edges[key] = (bidirectional_edges[key][1], Float64(weight))
            end
        end
    end

    # Tilføjer alle kanter til grafen
    for (idx, kant) in enumerate(kanter)
        from_node, to_node, weight = kant[1], kant[2], kant[3]
        i = node_to_int[from_node]
        j = node_to_int[to_node]
        
        # Håndter både (node1, node2, weight) og (node1, node2, weight, direction) format
        is_undirected = length(kant) == 4 && kant[4] == "U"
        
        if is_undirected
            # For undirected edges, tilføj begge retninger som separate edges (to pile)
            if i < j
                # Tilføj begge retninger
                if !has_edge(G, i, j)
                    add_edge!(G, i, j)
                end
                if !has_edge(G, j, i)
                    add_edge!(G, j, i)
                end
                edge_weights[(i, j)] = Float64(weight)
                edge_weights[(j, i)] = Float64(weight)
                push!(added_undirected, (i, j))
            elseif j < i && !((j, i) in added_undirected)
                # Tilføj begge retninger
                if !has_edge(G, j, i)
                    add_edge!(G, j, i)
                end
                if !has_edge(G, i, j)
                    add_edge!(G, i, j)
                end
                edge_weights[(j, i)] = Float64(weight)
                edge_weights[(i, j)] = Float64(weight)
                push!(added_undirected, (j, i))
            end
        else
            # Directed edge - tilføj begge retninger hvis der er to retninger (to pile)
            key = (min(i, j), max(i, j))
            has_both_directions = haskey(bidirectional_edges, key) && 
                                  bidirectional_edges[key][1] !== nothing && 
                                  bidirectional_edges[key][2] !== nothing
            
            if has_both_directions
                # For bidirectional edges, tilføj begge retninger som separate edges (to pile)
                w1, w2 = bidirectional_edges[key]
                if i < j
                    # Tilføj begge retninger
                    if !has_edge(G, i, j)
                        add_edge!(G, i, j)
                    end
                    if !has_edge(G, j, i)
                        add_edge!(G, j, i)
                    end
                    edge_weights[(i, j)] = w1  # Vægt for i -> j
                    edge_weights[(j, i)] = w2  # Vægt for j -> i
                end
            else
                # Kun én retning - tilføj normalt
                add_edge!(G, i, j)
                edge_weights[(i, j)] = Float64(weight)
            end
        end
    end

    # Find aktive kanter i shortest path (værdi ≈ 1.0)
    path_edges = Set()
    for k in eachindex(x_navne)
        val = value(x[k])
        if abs(val - 1.0) < 1e-6 || val > 1e-6
            var_name = x_navne[k]
            parts = split(var_name, "_")
            if length(parts) >= 3
                node1 = parts[2]
                node2 = parts[3]
                if haskey(node_to_int, node1) && haskey(node_to_int, node2)
                    i = node_to_int[node1]
                    j = node_to_int[node2]
                    if abs(val - 1.0) < 1e-6  # Kun edges med værdi 1.0 er i stien
                        push!(path_edges, (i, j))
                    end
                end
            end
        end
    end

    # Opretter farver for edges - grøn og tyk for path, grå og tynd for andre
    # For undirected edges, tjek også omvendt retning
    edge_colors = []
    edge_widths = []
    for e in edges(G)
        i, j = src(e), dst(e)
        # Tjek om edge er i path (inkl. omvendt retning for undirected)
        is_in_path = (i, j) in path_edges || (j, i) in path_edges
        push!(edge_colors, is_in_path ? colorant"seagreen" : colorant"grey50")
        push!(edge_widths, is_in_path ? 3.0 : 0.5)
    end
    
    # Opretter farver for noder - marker source og sink
    node_colors = fill(colorant"lightsteelblue", num_noder)
    source_idx = node_to_int[source_node]
    sink_idx = node_to_int[sink_node]
    node_colors[source_idx] = colorant"red"  # Rød for source (start)
    node_colors[sink_idx] = colorant"green"  # Grøn for sink (mål)

    # ===== INDSTILLING: Edge labels =====
    # Sæt til true for at vise labels på alle kanter, false for kun path-kanter
    show_all_edge_labels = false  # Ændr denne værdi for at vælge
    # =====================================
    
    # Opret edge labels (vægte) som Vector - GraphPlot forventer Vector, ikke Dict
    edge_labels = String[]
    for e in edges(G)
        i, j = src(e), dst(e)
        # Tjek om edge er i path (inkl. omvendt retning for undirected)
        is_in_path = (i, j) in path_edges || (j, i) in path_edges
        # Vis label hvis: alle labels er aktiveret, ELLER kanten er i path
        if show_all_edge_labels || is_in_path
            weight = edge_weights[(i, j)]
            push!(edge_labels, string(round(weight, digits=dec)))
        else
            push!(edge_labels, "")  # Tom label for kanter uden label
        end
    end
    
    # Opret node labels
    node_labels = [string(node) for node in noder]
    
    # Plotter grafen
    p = gplot(G, 
              nodelabel=node_labels,
              edgelabel=edge_labels,
              edgestrokec=edge_colors,
              edgelinewidth=edge_widths,
              nodesize=0.3,
              nodefillc=node_colors,
              nodestrokec=colorant"black",
              nodestrokelw=2.0)
    
    # Prøv at vise plottet - virker i VSCode, men kan fejle i terminalen uden Cairo/Fontconfig
    try
        display("image/svg+xml",p)
    catch e
        if occursin("Cairo", string(e)) || occursin("Fontconfig", string(e)) || occursin("image/png", string(e))
            println("   (Plottet kan ikke vises i denne terminal. Installer Cairo og Fontconfig for at se plottet.)")
            println("   Koden kører stadig korrekt - se output filen for resultater.")
        else
            rethrow(e)  # Hvis det er en anden fejl, rethrow den
        end
    end
    return p
end

##########################################################
# Funktion til at visualisere shortest path fra algoritme (Dijkstra/Bellman-Ford)
# Kræver: using Graphs, GraphPlot, Colors (skal være inkluderet i filen der kalder funktionen)
# path: Liste af nodenavne fra source til sink
function plot_shortest_path_from_algorithm(path, kanter, noder, source_node, sink_node, dec=2)
    # Vi starter med at bygge grafen med alle noder
    num_noder = length(noder)
    G = SimpleDiGraph(num_noder)  # Directed graph for shortest path

    # Mapping fra nodenavn til integer index
    node_to_int = Dict(noder[i] => i for i in 1:num_noder)

    # Opretter mapping fra edge til vægt
    edge_weights = Dict()
    bidirectional_edges = Dict()  # Track edges der har modsatte retning
    added_undirected = Set()  # Track undirected edges vi allerede har tilføjet

    # Først: saml alle edges for at finde bidirectional edges
    for (idx, kant) in enumerate(kanter)
        from_node, to_node, weight = kant[1], kant[2], kant[3]
        i = node_to_int[from_node]
        j = node_to_int[to_node]
        
        is_undirected = length(kant) == 4 && kant[4] == "U"
        
        if !is_undirected
            # For directed edges, track begge retninger
            key = (min(i, j), max(i, j))
            if !haskey(bidirectional_edges, key)
                bidirectional_edges[key] = (nothing, nothing)
            end
            if i < j
                bidirectional_edges[key] = (Float64(weight), bidirectional_edges[key][2])
            else
                bidirectional_edges[key] = (bidirectional_edges[key][1], Float64(weight))
            end
        end
    end

    # Tilføjer alle kanter til grafen
    for (idx, kant) in enumerate(kanter)
        from_node, to_node, weight = kant[1], kant[2], kant[3]
        i = node_to_int[from_node]
        j = node_to_int[to_node]
        
        # Håndter både (node1, node2, weight) og (node1, node2, weight, direction) format
        is_undirected = length(kant) == 4 && kant[4] == "U"
        
        if is_undirected
            # For undirected edges, tilføj begge retninger som separate edges (to pile)
            if i < j
                # Tilføj begge retninger
                if !has_edge(G, i, j)
                    add_edge!(G, i, j)
                end
                if !has_edge(G, j, i)
                    add_edge!(G, j, i)
                end
                edge_weights[(i, j)] = Float64(weight)
                edge_weights[(j, i)] = Float64(weight)
                push!(added_undirected, (i, j))
            elseif j < i && !((j, i) in added_undirected)
                # Tilføj begge retninger
                if !has_edge(G, j, i)
                    add_edge!(G, j, i)
                end
                if !has_edge(G, i, j)
                    add_edge!(G, i, j)
                end
                edge_weights[(j, i)] = Float64(weight)
                edge_weights[(i, j)] = Float64(weight)
                push!(added_undirected, (j, i))
            end
        else
            # Directed edge - tilføj begge retninger hvis der er to retninger (to pile)
            key = (min(i, j), max(i, j))
            has_both_directions = haskey(bidirectional_edges, key) && 
                                  bidirectional_edges[key][1] !== nothing && 
                                  bidirectional_edges[key][2] !== nothing
            
            if has_both_directions
                # For bidirectional edges, tilføj begge retninger som separate edges (to pile)
                w1, w2 = bidirectional_edges[key]
                if i < j
                    # Tilføj begge retninger
                    if !has_edge(G, i, j)
                        add_edge!(G, i, j)
                    end
                    if !has_edge(G, j, i)
                        add_edge!(G, j, i)
                    end
                    edge_weights[(i, j)] = w1  # Vægt for i -> j
                    edge_weights[(j, i)] = w2  # Vægt for j -> i
                end
            else
                # Kun én retning - tilføj normalt
                add_edge!(G, i, j)
                edge_weights[(i, j)] = Float64(weight)
            end
        end
    end

    # Find kanter i path
    path_edges = Set()
    for i in 1:(length(path)-1)
        from_node = path[i]
        to_node = path[i+1]
        if haskey(node_to_int, from_node) && haskey(node_to_int, to_node)
            from_idx = node_to_int[from_node]
            to_idx = node_to_int[to_node]
            push!(path_edges, (from_idx, to_idx))
        end
    end

    # Opretter farver for edges - grøn og tyk for path, grå og tynd for andre
    # For undirected edges, tjek også omvendt retning
    edge_colors = []
    edge_widths = []
    for e in edges(G)
        i, j = src(e), dst(e)
        # Tjek om edge er i path (inkl. omvendt retning for undirected)
        is_in_path = (i, j) in path_edges || (j, i) in path_edges
        push!(edge_colors, is_in_path ? colorant"seagreen" : colorant"grey50")
        push!(edge_widths, is_in_path ? 3.0 : 0.5)
    end
    
    # Opretter farver for noder - marker source og sink
    node_colors = fill(colorant"lightsteelblue", num_noder)
    source_idx = node_to_int[source_node]
    sink_idx = node_to_int[sink_node]
    node_colors[source_idx] = colorant"red"  # Rød for source (start)
    node_colors[sink_idx] = colorant"green"  # Grøn for sink (mål)

    # ===== INDSTILLING: Edge labels =====
    show_all_edge_labels = false  # Ændr denne værdi for at vælge
    # =====================================
    
    # Opret edge labels (vægte) som Vector
    edge_labels = String[]
    for e in edges(G)
        i, j = src(e), dst(e)
        # Tjek om edge er i path (inkl. omvendt retning for undirected)
        is_in_path = (i, j) in path_edges || (j, i) in path_edges
        if show_all_edge_labels || is_in_path
            weight = edge_weights[(i, j)]
            push!(edge_labels, string(round(weight, digits=dec)))
        else
            push!(edge_labels, "")
        end
    end
    
    # Opret node labels
    node_labels = [string(node) for node in noder]
    
    # Plotter grafen
    p = gplot(G, 
              nodelabel=node_labels,
              edgelabel=edge_labels,
              edgestrokec=edge_colors,
              edgelinewidth=edge_widths,
              nodesize=0.3,
              nodefillc=node_colors,
              nodestrokec=colorant"black",
              nodestrokelw=2.0)
    
    # Prøv at vise plottet - virker i VSCode, men kan fejle i terminalen uden Cairo/Fontconfig
    try
        display("image/svg+xml",p)
    catch e
        if occursin("Cairo", string(e)) || occursin("Fontconfig", string(e)) || occursin("image/png", string(e))
            println("   (Plottet kan ikke vises i denne terminal. Installer Cairo og Fontconfig for at se plottet.)")
            println("   Koden kører stadig korrekt - se output filen for resultater.")
        else
            rethrow(e)  # Hvis det er en anden fejl, rethrow den
        end
    end
    return p
end

##########################################################
# Funktion til at visualisere TSP tour
# Kræver: using Graphs, GraphPlot, Colors (skal være inkluderet i filen der kalder funktionen)
function plot_TSP(M, x, x_navne, node_navne, c, dec=2)
    # Vi starter med at bygge grafen med alle noder
    n = length(node_navne)
    G = SimpleDiGraph(n)  # Directed graph for TSP
    
    # Tilføj alle mulige kanter (alle par af noder)
    for i in 1:n
        for j in 1:n
            if i != j  # Udelad self-loops
                if !has_edge(G, i, j)
                    add_edge!(G, i, j)
                end
            end
        end
    end
    
    # Opretter mapping fra edge til omkostning
    # c er en vektor i row-major orden: c[(i-1)*n + j] er omkostningen for x_ij
    edge_costs = Dict()
    for i in 1:n
        for j in 1:n
            if i != j
                cost_idx = (i-1)*n + j
                if cost_idx <= length(c)
                    edge_costs[(i, j)] = c[cost_idx]
                end
            end
        end
    end
    
    # Find alle aktive kanter i tour'en (x_ij = 1)
    tour_edges = Set()
    for k in eachindex(x_navne)
        if abs(value(x[k]) - 1.0) < 1e-6  # Tjek om x[k] ≈ 1
            var_name = x_navne[k]
            # Parse variabelnavn: x_i_j (hvor i og j er tal)
            parts = split(var_name, "_")
            if length(parts) >= 3
                i_str = parts[2]
                j_str = parts[3]
                
                # Konverter til integers
                try
                    i = parse(Int, i_str)
                    j = parse(Int, j_str)
                    if i != j  # Udelad self-loops
                        push!(tour_edges, (i, j))
                    end
                catch
                    # Hvis parsing fejler, prøv at finde i node_navne (for bagudkompatibilitet)
                    i = findfirst(==(i_str), node_navne)
                    j = findfirst(==(j_str), node_navne)
                    if i !== nothing && j !== nothing && i != j
                        push!(tour_edges, (i, j))
                    end
                end
            end
        end
    end
    
    # Opretter farver for edges - grøn og tyk for tour, grå og tynd for andre
    edge_colors = []
    edge_widths = []
    for e in edges(G)
        i, j = src(e), dst(e)
        is_in_tour = (i, j) in tour_edges
        push!(edge_colors, is_in_tour ? colorant"seagreen" : colorant"grey50")
        push!(edge_widths, is_in_tour ? 3.0 : 0.5)
    end
    
    # Opretter farver for noder - alle samme farve (lightsteelblue)
    node_colors = fill(colorant"lightsteelblue", n)
    
    # ===== INDSTILLING: Edge labels =====
    # Sæt til true for at vise labels på alle kanter, false for kun tour-kanter
    show_all_edge_labels = false  # Ændr denne værdi for at vælge
    # =====================================
    
    # Opret edge labels (omkostninger) som Vector - GraphPlot forventer Vector, ikke Dict
    edge_labels = String[]
    for e in edges(G)
        i, j = src(e), dst(e)
        is_in_tour = (i, j) in tour_edges
        # Vis label hvis: alle labels er aktiveret, ELLER kanten er i tour
        if show_all_edge_labels || is_in_tour
            if haskey(edge_costs, (i, j))
                cost = edge_costs[(i, j)]
                push!(edge_labels, string(round(cost, digits=dec)))
            else
                push!(edge_labels, "")
            end
        else
            push!(edge_labels, "")  # Tom label for kanter uden label
        end
    end
    
    # Opret node labels
    node_labels = [string(node) for node in node_navne]
    
    # Plotter grafen
    p = gplot(G, 
              nodelabel=node_labels,
              edgelabel=edge_labels,
              edgestrokec=edge_colors,
              edgelinewidth=edge_widths,
              nodesize=0.8,
              nodefillc=node_colors,
              nodestrokec=colorant"black",
              nodestrokelw=1.0)
    
    # Prøv at vise plottet - virker i VSCode, men kan fejle i terminalen uden Cairo/Fontconfig
    try
        display("image/svg+xml",p)
    catch e
        if occursin("Cairo", string(e)) || occursin("Fontconfig", string(e)) || occursin("image/png", string(e))
            println("   (Plottet kan ikke vises i denne terminal. Installer Cairo og Fontconfig for at se plottet.)")
            println("   Koden kører stadig korrekt - se output filen for resultater.")
        else
            rethrow(e)  # Hvis det er en anden fejl, rethrow den
        end
    end
    return p
end
    