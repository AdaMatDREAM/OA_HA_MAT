function identity_matrix(m)
    I = zeros(m, m)
    for i in 1:m
        I[i, i] = 1.0
    end
    return I
end

##########################################################

function simplex_tableau_BFS(c, x_navne, A, b, S_navne)

    m,n = size(A);
    
    I = identity_matrix(m);
    c_s = -[c; zeros(m)];
    T = [A I b; c_s' 0.0];
    
    x_S_navne = vcat(x_navne, S_navne, ["b"])
    basis_navne = vcat(S_navne, ["Z"])
    return (
    T = T, 
    x_S_navne = x_S_navne, 
    basis_navne = basis_navne
    )
    end
    
    ##########################################################


    function simplex_iteration(P_tableau)
        T = P_tableau.T;
        tol = 1e-11
        # Undersøger om vi har fundet en optimal løsning
        if any(T[end, 1:end-1] .< -tol)
            stop = false
        else
            stop = true
        end
    
        if stop
            println("Optimal løsning fundet")
            return P_tableau, true, nothing, nothing, nothing
        else
            # Finder pivot-søjle
            pivot_søjle = argmin(T[end, 1:end-1])
    
            # Tjek at der findes positive elementer i pivot-søjlen (ellers unbounded)
            if any(T[1:end-1, pivot_søjle] .> tol)
                rhs = T[1:end-1, end]
                col = T[1:end-1, pivot_søjle]
                ratios = fill(Inf, length(rhs))
    
                # Minimal kvotient-regel: b_i / a_ij, men kun hvis a_ij > 0
                for i in eachindex(rhs)
                    if col[i] > tol
                        ratios[i] = rhs[i] / col[i]
                    end
                end
    
                pivot_række = argmin(ratios)
                println("Pivot-søjle: ", P_tableau.x_S_navne[pivot_søjle],
                        "  |  Pivot-række: ", P_tableau.basis_navne[pivot_række])
    
                # Pivotér tableau og opdater basis
                nyt_tableau = pivot_tableau(P_tableau, pivot_søjle, pivot_række)
                return nyt_tableau, false, pivot_søjle, pivot_række, ratios
            else 
                println("Unbounded problem")
                return P_tableau, true, nothing, nothing, nothing
            end
        end
    
    end
    
    ##########################################################
# Pivotfunktion: opdaterer tableau og basis efter pivot
# Input er direkte pivot-søjle og pivot-række (kendt på forhånd)
function pivot_tableau(P_tableau, pivot_søjle::Int, pivot_række::Int)
    T = copy(P_tableau.T)
    x_S_navne = P_tableau.x_S_navne
    basis_navne = copy(P_tableau.basis_navne)

    if pivot_række == size(T, 1)
        error("Z-rækken kan ikke forlade basis.")
    end

    pivot_val = T[pivot_række, pivot_søjle]
    if abs(pivot_val) < 1e-12
        error("Pivot-elementet er nul (eller tæt på nul).")
    end

    # Normaliser pivot-rækken: divider hele rækken med pivot-elementet
    for j in 1:size(T, 2)
        T[pivot_række, j] = T[pivot_række, j] / pivot_val
    end

    # Nulstil pivot-kolonnen i alle andre rækker
    for i in 1:size(T, 1)
        # Skipper pivot-række
        if i == pivot_række
            continue
        end
        faktor = T[i, pivot_søjle]
        if abs(faktor) > 0
            # Rækkeoperation: række i = række i - faktor * pivot-rækken
            for j in 1:size(T, 2)
                T[i, j] = T[i, j] - faktor * T[pivot_række, j]
            end
        end
    end

    # Opdater basisvariabel (navn fra kolonnen)
    basis_navne[pivot_række] = x_S_navne[pivot_søjle]

return (
        T = T,
        x_S_navne = x_S_navne,
        basis_navne = basis_navne
       )
end


##########################################################
function dual_simplex_iteration(P_tableau)
    T = P_tableau.T;
    x_S_navne = P_tableau.x_S_navne;
    basis_navne = P_tableau.basis_navne;
    tol = 1e-11;
    b = T[1:end-1, end];
    if any(b .< -tol)
        stop = false
    else
        stop = true
    end
    if stop
        println("Basic feasible solution (BFS) fundet")
        return P_tableau, true, nothing, nothing, nothing
    else
        # pivot-række: mest negative b blandt negative
        neg_idx = findall(<(-tol), b);
        pivot_række = neg_idx[argmin(b[neg_idx])]
        # Dan pivot_række
        row = T[pivot_række, 1:end-1]
           if any(row .< -tol)
            # Find z-rækken
            z = -T[end, 1:end-1]
            # Find ratios z_j/a_ij
            ratios = fill(-Inf, length(z))
            for j in eachindex(z)
                if row[j] < -tol
                    ratios[j] = z[j] / row[j]
                end
            end
            # Tjek om der findes en gyldig pivot-søjle
            if all(ratios .== -Inf)
                println("Ingen gyldig pivot-søjle")
                return P_tableau, true, nothing, nothing, nothing
            end
            # Find pivot-søjle
            pivot_søjle = argmax(ratios)

        else
            println("Ingen løsning (alle a_ij >= 0)") 
            return P_tableau, true, nothing, nothing, nothing
        end
    end
    println("Pivot-søjle: ", x_S_navne[pivot_søjle],
            "  |  Pivot-række: ", basis_navne[pivot_række])
    P_tableau = pivot_tableau(P_tableau, pivot_søjle, pivot_række)
    return P_tableau, false, pivot_søjle, pivot_række, ratios
end


##########################################################




##########################################################
function simplex_solve(P_tableau; max_iter_dual=50, max_iter_primal=50, print_tableaux_iterationer=true)
    # Dual simplex loop (kør indtil BFS)
    # Holder styr på om slut-tableau allerede er printet
    dual_printed = false
    for k in 1:max_iter_dual
        P_tableau, stop, _, _, _ = dual_simplex_iteration(P_tableau)
        if stop
            println("Dual simplex stoppet grundet funden BFS")
            print_tableau(P_tableau)
            dual_printed = true
            break
        end
        if print_tableaux_iterationer
            print_tableau(P_tableau)
        end
    end
    if !dual_printed
        print_tableau(P_tableau)
    end


    # Primal simplex loop (kør indtil optimal)
    # Holder styr på om slut-tableau allerede er printet
    primal_printed = false
    for k in 1:max_iter_primal
        P_tableau, stop, _, _, _ = simplex_iteration(P_tableau)
        if stop
            println("Primal simplex stoppet grundet funden optimal løsning")
            print_tableau(P_tableau)
            primal_printed = true
            break
        end
        if print_tableaux_iterationer
            print_tableau(P_tableau)
        end
    end
    if !primal_printed
        print_tableau(P_tableau)
    end


    return P_tableau
end

function optimal_tableau(P_tableau)
    # Vi definerer lokale variable
    T = P_tableau.T;
    x_S_navne = P_tableau.x_S_navne;
    basis_navne = P_tableau.basis_navne;
    # Objektivfunktionens værdi
    z_opt = T[end, end];
    # Variabelværdier i løsningen
    x_S_opt = zeros(length(x_S_navne));
    b_opt = T[1:end-1, end];
    for i in eachindex(x_S_navne)
        if x_S_navne[i] in basis_navne
            idx = findfirst(==(x_S_navne[i]), basis_navne[1:end-1])
            if idx !== nothing
                x_S_opt[i] = b_opt[idx]
            end
        end
    end
# skyggepriser
# I tableauet er z-rækken -c^*, så skyggepriserne er direkte fra tableauet
skyggepriser = T[end, 1:end-1]
# slackværdier kendes allerede fra tableau

# Sensitivitetsanalyse for objektivkoefficienter
c_sens_lower = zeros(length(x_S_navne[1:end-1]));
c_sens_upper = zeros(length(x_S_navne[1:end-1]));
for k in eachindex(x_S_navne[1:end-1])
    # Definer variablenavn
    var_k = x_S_navne[k]
    # Tjek om variablenavnet er i basisnavnene
    if var_k in basis_navne[1:end-1]
        # Finder rækken ved brug af index for variablenavnet i basisnavnene
        idx = findfirst(==(var_k), basis_navne[1:end-1])
        # Finder rækken i tableauet ved brug af index
        row = T[idx, 1:end-1];
        # Definer c i optimal løsning
        c_opt = T[end, 1:end-1];
        # Finder først C_k^-
        # Hjælpevariabel til at finde C_k^-
        c_minus = Inf;
        # Tjek om alle elementer i rækken er <= 0
        if all(row[j] <= 0 for j in eachindex(row) if j != k)
            c_sens_lower[k] = Inf;
        else
            # Hvis ikke så finder vi mindste ratio for at finde C_k^-
            for j in eachindex(row)
                if j != k && row[j] > 0
                    ratio = c_opt[j] / row[j]
                    if ratio <= c_minus
                        c_minus = ratio;
                    end
                end
            end
            c_sens_lower[k] = c_minus;
        end
        # Finder C_k^+
        # Hjælpevariabel til at finde C_k^+
        c_plus = Inf;
        # Tjek om alle elementer i rækken er >= 0
        if all(row[j] >= 0 for j in eachindex(row) if j != k)
            c_sens_upper[k] = Inf;
        else
            # Hvis ikke så finder vi mindste ratio for at finde C_k^+
            for j in eachindex(row)
                if j != k && row[j] < 0
                    ratio = - c_opt[j] / row[j]
                    if ratio <= c_plus
                        c_plus = ratio;
                    end
                end
            end
            c_sens_upper[k] = c_plus;
        end
    else
        c_sens_lower[k] = Inf;
        c_sens_upper[k] = T[end, k];
    end
end

# Sensitivitetsanalyse for begrænsninger
# Vi har b_opt fra tidligere
b_sens_lower = zeros(length(b_opt));
b_sens_upper = zeros(length(b_opt));
# Antal strukturelle variable
p = length(x_S_navne[1:end-1]) - length(basis_navne[1:end-1])
for k in eachindex(b_opt)
    # Find den tilhørende slack-variabel
    S_q = x_S_navne[p + k]
    if S_q in basis_navne[1:end-1]
        b_sens_lower[k] = x_S_opt[p + k]
        b_sens_upper[k] = Inf;
    else
        # Søjlen i tableauet for den tilhørende slack-variabel
        col = T[1:end-1, p + k];
        if all(col[j] <= 0 for j in eachindex(col))
            b_sens_lower[k] = Inf;
        else
            b_minus = Inf;
            for j in eachindex(col)
                if col[j] > 0
                    ratio = b_opt[j] / col[j]
                    if ratio <= b_minus
                        b_minus = ratio;
                    end
                end
            end
            b_sens_lower[k] = b_minus;
        end
        # Finder b_k^+
        b_plus = Inf;
        if all(col[j] >= 0 for j in eachindex(col))
            b_sens_upper[k] = Inf;
        else
            for j in eachindex(col)
                if col[j] < 0
                    ratio = - b_opt[j] / col[j]
                    if ratio <= b_plus
                        b_plus = ratio;
                    end
                end
            end
            b_sens_upper[k] = b_plus;
        end
    end
end
return (
    z_opt = z_opt,
    x_S_opt = x_S_opt,
    skyggepriser = skyggepriser,
    c_sens_lower = c_sens_lower,
    c_sens_upper = c_sens_upper,
    b_sens_lower = b_sens_lower,
    b_sens_upper = b_sens_upper
)

end

