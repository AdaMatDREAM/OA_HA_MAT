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
        if obj_sense == MOI.MIN_SENSE
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
function full_report_LP_latex(output_latex_navn, M, report, x, x_navne, c, constraints, b, b_dir, b_navne, dec=2, tol=1e-9, x_type=nothing)
open(output_latex_navn, "w") do file
    # Skriv LaTeX header
    println(file, "\\documentclass{article}")
    println(file, "\\usepackage[utf8]{inputenc}")
    println(file, "\\usepackage{booktabs}")
    println(file, "\\begin{document}")
    println(file, "\\begin{flushleft}")
    println(file, "")
    println(file, "\\section*{Resultater fra optimering}")
    println(file, "")
    
    # Objektiv værdi
    println(file, "\\textbf{Type:} Standard LP")
    println(file, "")
    println(file, "\\textbf{Objektivfunktionens værdi:} ", 
    round(objective_value(M), digits=dec))
    println(file, "")
    
    # Variabel værdier som tabel (med type)
    println(file, "\\subsection*{Optimale variabelværdier}")
    println(file, "\\begin{tabular}{ccc}")
    println(file, "\\toprule")
    println(file, "Variabelnavn & Variabeltype & Værdi \\\\")
    println(file, "\\midrule")
    for i in eachindex(x)
        # Håndter x_type: hvis ikke givet, brug "Continuous" som standard
        if x_type === nothing
            type_str = "Continuous"
        else
            # Konverter symbol til string hvis nødvendigt
            type_str = string(x_type[i])
        end
        println(file, x_navne[i], " & ", type_str, " & ", round(value(x[i]), digits=dec), " \\\\")
    end
    println(file, "\\bottomrule")
    println(file, "\\end{tabular}")
    println(file, "")
    
    # Slack og skyggepris tabel
    println(file, "\\subsection*{Slack og Skyggepriser}")
    println(file, "\\begin{tabular}{cccccc}")
    println(file, "\\toprule")
    println(file, "Begrænsning & LHS & RHS & Slack & Skyggepris & Status \\\\")
    println(file, "\\midrule")
    
    # Hent objektivets retning
    obj_sense = objective_sense(M)
    
    for i in eachindex(constraints)
        lhs = value(constraints[i])
        if b_dir[i] == :<=
            slack = b[i] - lhs
        elseif b_dir[i] == :>=
            slack = lhs - b[i]
        else
            slack = b[i] - lhs
        end
        bindende = abs(slack) <= tol ? "Bindende" : "Ikke-bindende"
        
        # Beregn skyggepris korrekt baseret på objektivets retning
        dual_val = dual(constraints[i])
        if obj_sense == MOI.MIN_SENSE
            shadow_price = dual_val
        else  # MAX_SENSE
            shadow_price = -dual_val
        end
        
        println(file, b_navne[i], " & ", 
                round(lhs, digits=dec), " & ",
                round(b[i], digits=dec), " & ",
                round(slack, digits=dec), " & ",
                round(shadow_price, digits=dec), " & ",
                bindende, " \\\\")
    end
    println(file, "\\bottomrule")
    println(file, "\\end{tabular}")
    println(file, "")
    
    # Sensitivitetsrapport for objektivkoefficienter
    println(file, "\\subsection*{Sensitivitetsrapport for Objektivkoefficienter}")
    println(file, "\\begin{tabular}{ccccc}")
    println(file, "\\toprule")
    println(file, "Variabelnavn & Koefficientværdi & Maksimalt fald & Maksimal stigning & Reduced costs \\\\")
    println(file, "\\midrule")
    for i in eachindex(x)
        limits = report[x[i]]
        # Håndter Inf værdier
        nedre_gr = isinf(limits[1]) ? raw"$-\infty$" : string(round(limits[1], digits=dec))
        øvre_gr = isinf(limits[2]) ? raw"$\infty$" : string(round(limits[2], digits=dec))
        println(file, x_navne[i], " & ", 
                round(c[i], digits=dec), " & ",
                nedre_gr, " & ",
                øvre_gr, " & ",
                round(reduced_cost(x[i]), digits=dec), " \\\\")
    end
    println(file, "\\bottomrule")
    println(file, "\\end{tabular}")
    println(file, "")
    
    # Sensitivitetsrapport for RHS (kapacitet)
    println(file, "\\subsection*{Sensitivitetsrapport for RHS (Kapacitet)}")
    println(file, "\\begin{tabular}{cccc}")
    println(file, "\\toprule")
    println(file, "Begrænsning & RHS (nu) & Maksimalt fald & Maksimal stigning \\\\")
    println(file, "\\midrule")
    for i in eachindex(constraints)
        limits = report[constraints[i]]
        # Håndter Inf værdier
        nedre_gr = isinf(limits[1]) ? raw"$-\infty$" : string(round(limits[1], digits=dec))
        øvre_gr = isinf(limits[2]) ? raw"$\infty$" : string(round(limits[2], digits=dec))
        println(file, b_navne[i], " & ", 
                round(b[i], digits=dec), " & ",
                nedre_gr, " & ",
                øvre_gr, " \\\\")
    end
    println(file, "\\bottomrule")
    println(file, "\\end{tabular}")
    println(file, "")
    
    # LaTeX footer
    println(file, "\\end{flushleft}")
    println(file, "\\end{document}")
end
end

##########################################################
function standard_LP_output(M, x, x_navne, c, constraints, b, b_dir, b_navne, dec=2, tol=1e-9, output_terminal=true,
     output_fil=false, output_latex=false, output_fil_navn="output.txt", output_latex_navn="output.tex", model_type="LP", x_type=nothing)

if model_type != "LP"
    println("Fejl: Modeltype er ikke LP. Benyt anden output funktion.")
    return
end

println("Output i LP format begynder nu\n")
    # Optimer modellen, hent sensitivitetsrapport og status
optimize!(M)
status = termination_status(M)
report = lp_sensitivity_report(M)


    # Resultat ved standard LP-solver (HiGHS)
# Statusser der har en løsning at udskrive
if status == MOI.OPTIMAL || status == MOI.ALMOST_OPTIMAL
    # Bestem status-tekst baseret på hvilken status
    if status == MOI.OPTIMAL
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

if output_latex
    full_report_LP_latex(output_latex_navn, M, report, x, x_navne, c, constraints, b, b_dir, b_navne, dec, tol, x_type)
    println("Output er gemt i .tex filen: ", output_latex_navn)
end

# Statusser uden løsning (kun statusbesked)
elseif status == MOI.INFEASIBLE
    println("\nINFEASIBLE - Ingen løsning: begrænsningerne er modstridende")
elseif status == MOI.DUAL_INFEASIBLE
    println("\nDUAL_INFEASIBLE (UNBOUNDED) - Problemet er ubegrænset, objektivfunktionen kan vokse uendeligt")
elseif status == MOI.INFEASIBLE_OR_UNBOUNDED
    println("\nINFEASIBLE_OR_UNBOUNDED - Enten infeasible eller unbounded (solver kan ikke skelne)")
elseif status == MOI.LOCALLY_SOLVED
    println("\nLOCALLY_SOLVED - Lokal optimal løsning fundet (for ikke-lineære problemer)")
elseif status == MOI.ITERATION_LIMIT
    println("\nITERATION_LIMIT - Maksimalt antal iterationer nået før optimal løsning")
elseif status == MOI.TIME_LIMIT
    println("\nTIME_LIMIT - Tidsgrænse nået før optimal løsning")
elseif status == MOI.NUMERICAL_ERROR
    println("\nNUMERICAL_ERROR - Numerisk fejl opstod under løsning")
elseif status == MOI.OTHER_ERROR
    println("\nOTHER_ERROR - Anden fejl opstod")
else
    println("\nUKENDT STATUS: ", status)
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
function full_report_MIP_latex(output_latex_navn, M, x, x_navne, x_type, constraints, b, b_dir, b_navne, dec=2, tol=1e-9)
open(output_latex_navn, "w") do file
    # Skriv LaTeX header
    println(file, "\\documentclass{article}")
    println(file, "\\usepackage[utf8]{inputenc}")
    println(file, "\\usepackage{booktabs}")
    println(file, "\\begin{document}")
    println(file, "\\begin{flushleft}")
    println(file, "")
    println(file, "\\section*{Resultater fra optimering}")
    println(file, "\\textbf{Type:} MIP")
    println(file, "")
    
    # Objektiv værdi
    println(file, "\\textbf{Objektivfunktionens værdi:} ", 
    round(objective_value(M), digits=dec))
    println(file, "")
    
    # Variabel værdier som tabel (med type)
    println(file, "\\subsection*{Optimale variabelværdier}")
    println(file, "\\begin{tabular}{ccc}")
    println(file, "\\toprule")
    println(file, "Variabelnavn & Variabeltype & Værdi \\\\")
    println(file, "\\midrule")
    for i in eachindex(x)
        # Konverter symbol til string hvis nødvendigt
        type_str = string(x_type[i])
        println(file, x_navne[i], " & ", type_str, " & ", round(value(x[i]), digits=dec), " \\\\")
    end
    println(file, "\\bottomrule")
    println(file, "\\end{tabular}")
    println(file, "")
    
    # Slack tabel (uden skyggepris for MIP)
    println(file, "\\subsection*{Slack}")
    println(file, "\\begin{tabular}{ccccc}")
    println(file, "\\toprule")
    println(file, "Begrænsning & LHS & RHS & Slack & Status \\\\")
    println(file, "\\midrule")
    for i in eachindex(constraints)
        lhs = value(constraints[i])
        if b_dir[i] == :<=
            slack = b[i] - lhs
        elseif b_dir[i] == :>=
            slack = lhs - b[i]
        else
            slack = b[i] - lhs
        end
        bindende = abs(slack) <= tol ? "Bindende" : "Ikke-bindende"
        println(file, b_navne[i], " & ", 
                round(lhs, digits=dec), " & ",
                round(b[i], digits=dec), " & ",
                round(slack, digits=dec), " & ",
                bindende, " \\\\")
    end
    println(file, "\\bottomrule")
    println(file, "\\end{tabular}")
    println(file, "")
    
    # LaTeX footer
    println(file, "\\end{flushleft}")
    println(file, "\\end{document}")
end
end

##########################################################
function standard_MIP_output(M, x, x_navne, x_type, c, constraints, b, b_dir, b_navne, dec=2, tol=1e-9, output_terminal=true,
     output_fil=false, output_latex=false, output_fil_navn="output.txt", output_latex_navn="output.tex", model_type="MIP")

if model_type != "MIP"
    println("Fejl: Modeltype er ikke MIP. Benyt anden output funktion.")
    return
end

println("Output i MIP format begynder nu\n")

    # Optimer modellen og hent status
optimize!(M)
status = termination_status(M)

    # Resultat ved MIP-solver (HiGHS)
# Statusser der har en løsning at udskrive
if status == MOI.OPTIMAL || status == MOI.ALMOST_OPTIMAL
    # Bestem status-tekst baseret på hvilken status
    if status == MOI.OPTIMAL
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

if output_latex
    full_report_MIP_latex(output_latex_navn, M, x, x_navne, x_type, constraints, b, b_dir, b_navne, dec, tol)
    println("Output er gemt i .tex filen: ", output_latex_navn)
end

# Statusser uden løsning (kun statusbesked)
elseif status == MOI.INFEASIBLE
    println("\nINFEASIBLE - Ingen løsning: begrænsningerne er modstridende")
elseif status == MOI.DUAL_INFEASIBLE
    println("\nDUAL_INFEASIBLE (UNBOUNDED) - Problemet er ubegrænset, objektivfunktionen kan vokse uendeligt")
elseif status == MOI.INFEASIBLE_OR_UNBOUNDED
    println("\nINFEASIBLE_OR_UNBOUNDED - Enten infeasible eller unbounded (solver kan ikke skelne)")
elseif status == MOI.LOCALLY_SOLVED
    println("\nLOCALLY_SOLVED - Lokal optimal løsning fundet (for ikke-lineære problemer)")
elseif status == MOI.ITERATION_LIMIT
    println("\nITERATION_LIMIT - Maksimalt antal iterationer nået før optimal løsning")
elseif status == MOI.TIME_LIMIT
    println("\nTIME_LIMIT - Tidsgrænse nået før optimal løsning")
elseif status == MOI.NUMERICAL_ERROR
    println("\nNUMERICAL_ERROR - Numerisk fejl opstod under løsning")
elseif status == MOI.OTHER_ERROR
    println("\nOTHER_ERROR - Anden fejl opstod")
else
    println("\nUKENDT STATUS: ", status)
end

end