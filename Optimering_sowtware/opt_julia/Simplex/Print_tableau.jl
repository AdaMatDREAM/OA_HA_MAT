function print_tableau(P_tableau)
    println("\nSimplex-tableau:")
    @printf("%-8s", "")
    for name in P_tableau.x_S_navne
        @printf("%-12s", name)
    end
    println()

    for i in 1:size(P_tableau.T, 1)
        @printf("%-8s", P_tableau.basis_navne[i])
        for j in 1:size(P_tableau.T, 2)
            @printf("%-12.2f", P_tableau.T[i, j])
        end
        println()
    end
end

##########################################################

# Formatterer tal til LaTeX-venlig tekst
function format_num(x; dec=2)
    r = round(x, digits=dec)
    if r == -0.0
        r = 0.0
    end
    return string(r)
end

##########################################################

# Skriver tableau som LaTeX-tabular
# ratio_position = :right (ratio-kolonne) eller :bottom (ratio-række)
function tableau_to_latex(P_tableau; ratios=nothing, highlight_col=nothing, highlight_row=nothing, ratio_position=:right, dec=2, fit_width=true)
    T = P_tableau.T
    vars = P_tableau.x_S_navne
    basis = P_tableau.basis_navne
    vars_no_b = vars[1:end-1]

    io = IOBuffer()
    if fit_width
        println(io, "\\fitTableau{")
    end
    println(io, "\\begin{tabular}{", latex_colspec(vars_no_b, highlight_col, ratio_position, ratios), "}")
    println(io, "\\textbf{Basis} & ", join(["\$" * v * "\$" for v in vars_no_b], " & "),
            " & \$b_i\$",
            (ratio_position == :right && ratios !== nothing ? " & \\textbf{Ratio}" : ""),
            " \\\\ \\hline")

    for i in 1:size(T, 1)
        if highlight_row !== nothing && i == highlight_row
            print(io, "\\rowcolor{green!15} ")
        end
        row_vals = [format_num(T[i, j], dec=dec) for j in 1:length(vars_no_b)]
        rhs_val = format_num(T[i, end], dec=dec)

        if ratio_position == :right && ratios !== nothing && i <= length(ratios)
            if isinf(ratios[i])
                ratio_val = ""
            else
                ratio_val = format_num(ratios[i], dec=dec)
            end
        else
            ratio_val = ""
        end

        println(io, "\$" * string(basis[i]) * "\$", " & ", join(row_vals, " & "), " & ", rhs_val,
                (ratio_position == :right && ratios !== nothing ? " & " * ratio_val : ""),
                " \\\\")
    end

    if ratio_position == :bottom && ratios !== nothing
        ratio_vals = [isinf(r) ? "" : format_num(r, dec=dec) for r in ratios]
        println(io, "\\hline")
        println(io, "\\textbf{Ratio} & ", join(ratio_vals, " & "), " &  \\\\")
    end

    println(io, "\\end{tabular}")
    if fit_width
        println(io, "}")
    end
    return String(take!(io))
end


##########################################################


function latex_colspec(vars_no_b, highlight_col, ratio_position, ratios)
    cols = String[]
    push!(cols, "c|")
    for j in 1:length(vars_no_b)
        if highlight_col !== nothing && j == highlight_col
            push!(cols, ">{\\columncolor{green!15}}c")
        else
            push!(cols, "c")
        end
    end
    push!(cols, "|c")
    if ratio_position == :right && ratios !== nothing
        push!(cols, "|c")
    end
    return join(cols, "")
end


##########################################################


# Skriver LaTeX-tableau direkte til fil
function write_tableau_latex(file, P_tableau; ratios=nothing, highlight_col=nothing, highlight_row=nothing, ratio_position=:right, dec=2, fit_width=true)
    latex = tableau_to_latex(P_tableau;
        ratios=ratios,
        highlight_col=highlight_col,
        highlight_row=highlight_row,
        ratio_position=ratio_position,
        dec=dec,
        fit_width=fit_width
    )
    println(file, latex)
end

##########################################################

##########################################################
function simplex_solve_latex(P_tableau, output_latex_navn; max_iter_dual=50, max_iter_primal=50)
    open(output_latex_navn, "w") do file
        println(file, "\\documentclass{article}")
        println(file, "\\usepackage[table]{xcolor}")
        println(file, "\\usepackage{float}")
        println(file, "\\usepackage{graphicx}")
        println(file, "\\usepackage[margin=1.5cm]{geometry}")
        println(file, "\\newsavebox{\\tableauBox}")
        println(file, "\\newcommand{\\fitTableau}[1]{%")
        println(file, "\\sbox{\\tableauBox}{#1}%")
        println(file, "\\ifdim\\wd\\tableauBox>\\textwidth")
        println(file, "\\resizebox{\\textwidth}{!}{\\usebox{\\tableauBox}}%")
        println(file, "\\else")
        println(file, "\\usebox{\\tableauBox}%")
        println(file, "\\fi}")
        println(file, "\\begin{document}")
        println(file, "\\begin{table}[H]")
        println(file, "\\centering")
        println(file, "\\renewcommand{\\arraystretch}{1.2}")
        println(file, "\\setlength{\\tabcolsep}{6pt}")

        # Initialt tableau
        write_tableau_latex(file, P_tableau)
        println(file, "\\vspace{1em}")

        # Dual simplex loop (kør indtil BFS)
        for k in 1:max_iter_dual
            P_tableau, stop, pivot_søjle, pivot_række, ratios = dual_simplex_iteration(P_tableau)
            if stop
                println(file, "\\par\\medskip")
                println(file, "\\textit{Dual simplex stoppes, fordi alle }\$b_i \\ge 0\$ (basis er nu feasible).")
                println(file, "\\par\\medskip")
                break
            end
            write_tableau_latex(file, P_tableau;
                ratios=ratios,
                highlight_col=pivot_søjle,
                highlight_row=pivot_række,
                ratio_position=:bottom
            )
            println(file, "\\vspace{1em}")
        end

        # Primal simplex loop (kør indtil optimal)
        println(file, "\\par\\medskip")
        println(file, "\\textit{Skifter til primal simplex, fordi basis er feasible, og vi nu optimerer objektivet.}")
        println(file, "\\par\\medskip")
        for k in 1:max_iter_primal
            P_tableau, stop, pivot_søjle, pivot_række, ratios = simplex_iteration(P_tableau)
            if stop
                println(file, "\\par\\medskip")
                println(file, "\\textit{Primal simplex stoppes, fordi z-rækken ikke har negative værdier (optimal løsning).}")
                println(file, "\\par\\medskip")
                break
            end
            write_tableau_latex(file, P_tableau;
                ratios=ratios,
                highlight_col=pivot_søjle,
                highlight_row=pivot_række,
                ratio_position=:right
            )
            println(file, "\\vspace{1em}")
        end

        # Løsningstableau uden farver og ratios
        write_tableau_latex(file, P_tableau; ratios=nothing, highlight_col=nothing, highlight_row=nothing)

        println(file, "\\caption{Simplex-tableauer}")
        println(file, "\\end{table}")
        println(file, "\\end{document}")
    end

    return P_tableau
end


##########################################################

# Print optimal løsning
function print_optimal_solution_simplex(result, x_S_navne, dec=2)
    println("-"^100)
    @printf("Værdi af objektivfunktionen:\n -> %.*f\n", dec, result.z_opt)
    println("\n")
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

# Fuld rapport for simplex sensitivitetsanalyse
function full_report_simplex_sensitivity(result, x_S_navne, x_navne, c, b, b_navne, dec=2, tol=1e-9)
    print_optimal_solution_simplex(result, x_S_navne, dec)
    print_slack_shadow_price_simplex(result, x_S_navne, b, b_navne, dec, tol)
    print_sensitivity_objective_coefficients_simplex(result, x_S_navne, c, x_navne, dec)
    print_sensitivity_RHS_simplex(result, b, b_navne, dec)
end

##########################################################






