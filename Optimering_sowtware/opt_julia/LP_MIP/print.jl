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
    @printf("%-15s |%-15s |%-15s |%-15s |%-15s |%-15s\n", 
            "Begrænsningnavn", "LHS", "RHS", "Slack", "Skyggepris", "Bindende status")
    println("-"^100)
    
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
        
        @printf("%-15s |%-15.*f |%-15.*f |%-15.*f |%-15.*f |%-15s\n", 
                b_navne[i], dec, lhs, dec, b[i], dec, slack, dec, shadow_price, bindende)
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
    
    @printf("%-20s |%-20s |%-20s |%-20s\n", "Begrænsningnavn", "RHS (nu)",
            "Maksimalt fald", "Maksimal stigning")
    println("-"^(20*4+6))
    for i in eachindex(constraints)
        limits = report[constraints[i]]
        @printf("%-20s |%-20.*f |%-20.*f |%-20.*f\n", 
                b_navne[i], dec, b[i], dec, limits[1], dec, limits[2])
    end
    println("-"^(20*4+6))
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
    @printf("%-15s |%-15s |%-15s |%-15s |%-15s\n", 
            "Begrænsningnavn", "LHS", "RHS", "Slack", "Bindende status")
    println("-"^85)
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
        @printf("%-15s |%-15.*f |%-15.*f |%-15.*f |%-15s\n", 
                b_navne[i], dec, lhs, dec, b[i], dec, slack, bindende)
    end
    println("\n")
end

##########################################################
function full_report_MIP(M, x, x_navne, x_type, constraints, b, b_dir, b_navne, dec=2, tol=1e-9)
    print_optimal_solution(M, x, x_navne, x_type, dec)
    print_slack(constraints, b_navne, b, b_dir, dec, tol)
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