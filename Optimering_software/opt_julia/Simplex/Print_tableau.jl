function print_tableau(P_tableau; ratios=nothing, ratio_position=:right, dec=2)
    T = P_tableau.T
    x_S_navne = P_tableau.x_S_navne
    basis_navne = P_tableau.basis_navne
    
    # Find antal strukturelle variable (p)
    # x_S_navne indeholder: strukturelle, slack, "b"
    # basis_navne indeholder: slack variabler, "Z"
    p = length(x_S_navne[1:end-1]) - length(basis_navne[1:end-1])
    num_cols = size(T, 2)
    num_rows = size(T, 1)
    
    # Kolonnebredder
    col_width = 12
    basis_width = 8
    ratio_width = 12
    
    # Funktion til at printe vandret linje med alle separators
    function print_horizontal_line()
        # Basis kolonne
        print("-"^basis_width)
        # Lodret linje efter basis
        print("-")
        # Strukturelle variable
        for j in 1:p
            print("-"^col_width)
        end
        # Slack variable
        num_slack = num_cols - p - 1  # -1 fordi b kolonne er sidst
        for j in 1:num_slack
            print("-"^col_width)
        end
        # b kolonne
        print("-"^col_width)
        # Ratio kolonne (hvis ratio_position == :right)
        if ratios !== nothing && ratio_position == :right
            print("-"^ratio_width)
        end
        println()
    end
    
    println("\nSimplex-tableau:")
    
    # Top linje
    print_horizontal_line()
    
    # Header række
    @printf("|%-*s", basis_width-1, "Basis")
    print("|")  # Lodret linje efter basis
    for j in 1:p
        var_name = x_S_navne[j]
        @printf("%-*s|", col_width-1, var_name)
    end
    # Ingen ekstra linje - sidste strukturelle har allerede | i slutningen
    for j in (p+1):(num_cols-1)
        var_name = x_S_navne[j]
        @printf("%-*s|", col_width-1, var_name)
    end
    # Ingen ekstra linje - sidste slack har allerede | i slutningen
    var_name = x_S_navne[num_cols]
    @printf("%-*s", col_width-1, var_name)
    # Ratio kolonne header (hvis ratio_position == :right)
    if ratios !== nothing && ratio_position == :right
        @printf("|%-*s", ratio_width-1, "Ratio")
    end
    println("|")
    
    # Vandret linje efter header
    print_horizontal_line()
    
    # Data rækker (alle undtagen Z)
    for i in 1:(num_rows-1)
        @printf("|%-*s", basis_width-1, basis_navne[i])
        print("|")  # Lodret linje efter basis
        for j in 1:p
            @printf("%*.*f|", col_width-1, dec, T[i, j])
        end
        # Ingen ekstra linje - sidste strukturelle har allerede | i slutningen
        for j in (p+1):(num_cols-1)
            @printf("%*.*f|", col_width-1, dec, T[i, j])
        end
        # Ingen ekstra linje - sidste slack har allerede | i slutningen
        @printf("%*.*f", col_width-1, dec, T[i, num_cols])
        # Ratio værdi (hvis ratio_position == :right og ratio findes for denne række)
        if ratios !== nothing && ratio_position == :right && i <= length(ratios)
            if isinf(ratios[i])
                @printf("|%-*s", ratio_width-1, "")
            else
                @printf("|%*.*f", ratio_width-1, dec, ratios[i])
            end
        end
        println("|")
    end
    
    # Vandret linje før Z-rækken
    print_horizontal_line()
    
    # Z-rækken (sidste række)
    @printf("|%-*s", basis_width-1, basis_navne[num_rows])
    print("|")  # Lodret linje efter basis
    for j in 1:p
        @printf("%*.*f|", col_width-1, dec, T[num_rows, j])
    end
    # Ingen ekstra linje - sidste strukturelle har allerede | i slutningen
    for j in (p+1):(num_cols-1)
        @printf("%*.*f|", col_width-1, dec, T[num_rows, j])
    end
    # Ingen ekstra linje - sidste slack har allerede | i slutningen
    @printf("%*.*f", col_width-1, dec, T[num_rows, num_cols])
    # Ratio kolonne (tom for Z-rækken)
    if ratios !== nothing && ratio_position == :right
        @printf("|%-*s", ratio_width-1, "")
    end
    println("|")
    
    # Ratio række (hvis ratio_position == :bottom)
    if ratios !== nothing && ratio_position == :bottom
        print_horizontal_line()
        @printf("|%-*s", basis_width-1, "Ratio")
        print("|")  # Lodret linje efter basis
        for j in 1:p
            if j <= length(ratios)
                if isinf(ratios[j])
                    @printf("%-*s|", col_width-1, "")
                else
                    @printf("%*.*f|", col_width-1, dec, ratios[j])
                end
            else
                @printf("%-*s|", col_width-1, "")
            end
        end
        for j in (p+1):(num_cols-1)
            if j <= length(ratios)
                if isinf(ratios[j])
                    @printf("%-*s|", col_width-1, "")
                else
                    @printf("%*.*f|", col_width-1, dec, ratios[j])
                end
            else
                @printf("%-*s|", col_width-1, "")
            end
        end
        # Tom for b kolonne
        @printf("%-*s", col_width-1, "")
        println("|")
    end
    
    # Bottom linje
    print_horizontal_line()
    println()
end

##########################################################


##########################################################

# Print information om flere optimale løsninger
function print_multiple_solutions_info(result)
    info = result.multiple_solutions_info
    
    if info.has_multiple
        println("="^100)
        println("DER ER FLERE OPTIMALE LØSNINGER")
        println("="^100)
        
        # Begrundelse
        println("\nBegrundelse:")
        println("Løsningen er optimal, fordi:")
        println("  • Z-rækken har ikke-negative værdier for alle non-basic variabler")
        println("  • Alle b-værdier er ikke-negative (feasible løsning)")
        
        println("\nDer er flere optimale løsninger, fordi:")
        if length(info.non_basic_zero_rc) > 0
            println("  • Non-basic variabel(er) med reduced cost = 0:")
            for var in info.non_basic_zero_rc
                println("    - ", var, " kan indgå i basisen uden at ændre objektivværdien")
            end
            println("  • Dette betyder at der findes alternative optimale basisløsninger")
            println("  • Alle disse løsninger har samme objektivværdi")
        end
        
        if info.is_degenerate
            println("\nYderligere observation:")
            println("  • Degenerering er til stede (basisvariabel(er) med værdi 0):")
            for var in info.degenerate_vars
                println("    - ", var, " = 0")
            end
            println("  • Dette kan føre til flere optimale tableaux")
        end
        
        println("\n" * "="^100)
        println()
    end
end

# Print optimal løsning
function print_optimal_solution_simplex(result, x_S_navne, dec=2)
    println("-"^100)
    @printf("Værdi af objektivfunktionen:\n -> %.*f\n", dec, result.z_opt)
    println("\n")
    
    # Print information om flere løsninger hvis relevant
    print_multiple_solutions_info(result)
    
    @printf("%-30s |%-30s\n", "Variabelnavn", "Værdi")
    println("-"^65)
    for i in 1:length(x_S_navne[1:end-1])
        var = x_S_navne[i]
        val = result.x_S_opt[i]
            @printf("%-30s |%-30.*f\n", var, dec, val)
    end
    println("\n")
end

##########################################################

# Print slack og skyggepriser
function print_slack_shadow_price_simplex(result, x_S_navne, b, b_navne, dec=2, tol=1e-9)
    println("Slack og skyggepris: \n")
    @printf("%-15s |%-15s |%-15s |%-15s |%-15s |%-15s\n", 
            "Begrænsningnavn", "LHS", "RHS", "Slack", "Skyggepris", "Bindende status")
    println("-"^100)
    
    # Find slack-variabler og deres værdier
    for i in 1:length(x_S_navne[1:end-1])
        var = x_S_navne[i]
        if startswith(var, "S_")
            idx = parse(Int, var[3:end])
            if idx <= length(b)
                # Slack-værdi er i x_S_opt
                slack_val = result.x_S_opt[i]
                # LHS = RHS - Slack (for <= constraints)
                lhs = b[idx] - slack_val
                # Skyggepris er i skyggepriser array
                shadow_price = result.skyggepriser[i]
                # Bindende hvis slack er tæt på 0
                bindende = abs(slack_val) <= tol ? "Bindende" : "Ikke-bindende"
                
                @printf("%-15s |%-15.*f |%-15.*f |%-15.*f |%-15.*f |%-15s\n", 
                        b_navne[idx], dec, lhs, dec, b[idx], dec, slack_val, dec, shadow_price, bindende)
            end
        end
    end
    println("\n")
end

##########################################################

# Print sensitivitet for objektivkoefficienter
function print_sensitivity_objective_coefficients_simplex(result, x_S_navne, c, x_navne, dec=2)
    println("\nSensitivitetsrapport for objektivkoefficienter: \n")
    
    @printf("%-18s |%-18s |%-18s |%-18s |%-18s\n", "Variabelnavn", "Koefficientværdi",
            "Maksimalt fald", "Maksimal stigning", "Reduced costs")
    println("-"^(18*5+9))
    
    # Hjælpefunktion til at finde original c-værdi
    function find_c_original(var, x_navne, c)
        idx = findfirst(==(var), x_navne)
        if idx !== nothing
            return c[idx]
        elseif startswith(var, "S_")
            return 0.0
        else
            return 0.0
        end
    end
    
    for i in 1:length(x_S_navne[1:end-1])
        var = x_S_navne[i]
        c_orig = find_c_original(var, x_navne, c)
        c_minus = result.c_sens_lower[i]
        c_plus = result.c_sens_upper[i]
        
        # Reduced cost: fra z-rækken (allerede i skyggepriser, men med modsat fortegn for non-basic)
        # For non-basic variabler: reduced cost = -skyggepris (fordi z-rækken er -c^*)
        # For basic variabler: reduced cost = 0
        reduced_cost_tableau = result.skyggepriser[i]  # Dette er -c^* i tableauet
        reduced_cost_actual = -reduced_cost_tableau  # Faktisk reduced cost
        
        # Formatér Inf værdier
        c_minus_str = isinf(c_minus) ? "-∞" : Printf.@sprintf("%.*f", dec, c_minus)
        c_plus_str = isinf(c_plus) ? "∞" : Printf.@sprintf("%.*f", dec, c_plus)
        
        @printf("%-18s |%-18.*f |%-18s |%-18s |%-18.*f\n", 
                var, dec, c_orig, c_minus_str, c_plus_str, dec, reduced_cost_actual)
    end
    println("-"^(18*5+9))
    println("\n")
end

##########################################################

# Print sensitivitet for RHS
function print_sensitivity_RHS_simplex(result, b, b_navne, dec=2)
    println("\nSensitivitetsrapport for RHS (kapacitet): \n")
    
    @printf("%-20s |%-20s |%-20s |%-20s\n", "Begrænsningnavn", "RHS (nu)",
            "Maksimalt fald", "Maksimal stigning")
    println("-"^(20*4+6))
    
    for i in 1:length(result.b_sens_lower)
        b_minus = result.b_sens_lower[i]
        b_plus = result.b_sens_upper[i]
        
        # Formatér Inf værdier
        b_minus_str = isinf(b_minus) ? "∞" : Printf.@sprintf("%.*f", dec, b_minus)
        b_plus_str = isinf(b_plus) ? "∞" : Printf.@sprintf("%.*f", dec, b_plus)
        
        @printf("%-20s |%-20.*f |%-20s |%-20s\n", 
                b_navne[i], dec, b[i], b_minus_str, b_plus_str)
    end
    println("-"^(20*4+6))
    println("\n")
end

##########################################################

# Funktion til at printe problemformulering til terminal
function print_problem_terminal_simplex(c, x_navne, A, b, b_navne, obj_sense=:MAX)
    sense = obj_sense == :MAX ? "Maksimer" : "Minimer"
    
    # Objektivfunktion
    obj_funktion = String[]
    for i in eachindex(c)
        coef = c[i]
        if coef == 0; continue; end
        
        fortegn_str = coef < 0 ? " - " : (isempty(obj_funktion) ? "" : " + ")
        abscoef = abs(coef)
        coef_tekst = abscoef == 1 ? "" : string(abscoef)
        
        push!(obj_funktion, fortegn_str * coef_tekst * x_navne[i])
    end
    
    println("\n" * "="^100)
    println("PROBLEMFORMULERING")
    println("="^100)
    println(sense, " Z = ", join(obj_funktion, ""))
    println("\nu.b.b.:")
    
    # Begrænsninger (alle er <= i standard simplex form)
    for i in 1:size(A, 1)
        row_terms = String[]
        for j in 1:size(A, 2)
            a = A[i, j]
            if a == 0; continue; end
            
            fortegn_str = a < 0 ? " - " : (isempty(row_terms) ? "" : " + ")
            abs_a = abs(a)
            coef_tekst = abs_a == 1 ? "" : string(abs_a)
            
            push!(row_terms, fortegn_str * coef_tekst * x_navne[j])
        end
        
        println("  ", b_navne[i], ": ", join(row_terms, ""), " <= ", b[i])
    end
    
    # Fortegnskrav (alle variable er >= 0 i standard simplex)
    dom_terms = String[]
    for i in eachindex(x_navne)
        push!(dom_terms, x_navne[i] * " >= 0")
    end
    
    if !isempty(dom_terms)
        println("\nSamt fortegnskrav:")
        println("  ", join(dom_terms, ", "))
    end
    println("="^100)
    println()
end

# Funktion til at skrive problemformulering til fil
function write_problem_file_simplex(file, c, x_navne, A, b, b_navne, obj_sense=:MAX)
    sense = obj_sense == :MAX ? "Maksimer" : "Minimer"
    
    # Objektivfunktion
    obj_funktion = String[]
    for i in eachindex(c)
        coef = c[i]
        if coef == 0; continue; end
        
        fortegn_str = coef < 0 ? " - " : (isempty(obj_funktion) ? "" : " + ")
        abscoef = abs(coef)
        coef_tekst = abscoef == 1 ? "" : string(abscoef)
        
        push!(obj_funktion, fortegn_str * coef_tekst * x_navne[i])
    end
    
    println(file, "\n" * "="^100)
    println(file, "PROBLEMFORMULERING")
    println(file, "="^100)
    println(file, sense, " Z = ", join(obj_funktion, ""))
    println(file, "\nu.b.b.:")
    
    # Begrænsninger (alle er <= i standard simplex form)
    for i in 1:size(A, 1)
        row_terms = String[]
        for j in 1:size(A, 2)
            a = A[i, j]
            if a == 0; continue; end
            
            fortegn_str = a < 0 ? " - " : (isempty(row_terms) ? "" : " + ")
            abs_a = abs(a)
            coef_tekst = abs_a == 1 ? "" : string(abs_a)
            
            push!(row_terms, fortegn_str * coef_tekst * x_navne[j])
        end
        
        println(file, "  ", b_navne[i], ": ", join(row_terms, ""), " <= ", b[i])
    end
    
    # Fortegnskrav (alle variable er >= 0 i standard simplex)
    dom_terms = String[]
    for i in eachindex(x_navne)
        push!(dom_terms, x_navne[i] * " >= 0")
    end
    
    if !isempty(dom_terms)
        println(file, "\nSamt fortegnskrav:")
        println(file, "  ", join(dom_terms, ", "))
    end
    println(file, "="^100)
    println(file)
end

##########################################################

# Fuld rapport for simplex sensitivitetsanalyse
function full_report_simplex_sensitivity(result, x_S_navne, x_navne, c, b, b_navne, dec=2, tol=1e-9)
    print_optimal_solution_simplex(result, x_S_navne, dec)
    print_slack_shadow_price_simplex(result, x_S_navne, b, b_navne, dec, tol)
    print_sensitivity_objective_coefficients_simplex(result, x_S_navne, c, x_navne, dec)
    print_sensitivity_RHS_simplex(result, b, b_navne, dec)
end

##########################################################






