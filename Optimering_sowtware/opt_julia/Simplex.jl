using HiGHS, JuMP;
using MathOptInterface
const MOI = MathOptInterface
using Printf

function simplex_skabelon()

# Objektivcoefficienter og variabelnavne
c = [2, 1];
x_navne = ["x_1", "x_2"];

# Begr??nsningskoefficienter og kapaciteter
A = [0 1;
     2 5;
     1 1;
     3 1];

b = [10, 60, 18, 44];

# Danner slackvariable
# S_navne = ["S_1", "S_2", "S_3"];
S_navne = ["S_$(i)" for i in 1:length(b)];
return (
    c = c, 
    x_navne = x_navne, 
    A = A, 
    b = b, 
    S_navne = S_navne
    )
end


function identity_matrix(m)
    I = zeros(m, m)
    for i in 1:m
        I[i, i] = 1.0
    end
    return I
end


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
        return P_tableau, true
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
            return nyt_tableau, false
        else 
            println("Unbounded problem")
            return P_tableau, true
        end
    end

end

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
        return P_tableau, true
    else
        # pivot-række: mest negative b blandt negative
        neg_idx = findall(<(-tol), b);
        pivot_række = neg_idx[argmin(b[neg_idx])]
        # Dan pivot_række
        row = T[pivot_række, 1:end-1]
           if any(row .< -tol)
            # Find z-rækken
            z = T[end, 1:end-1]
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
                return P_tableau
            end
            # Find pivot-søjle
            pivot_søjle = argmax(ratios)

        else
            println("Ingen løsning (alle a_ij >= 0)") 
            return P_tableau, true
        end
    end
    println("Pivot-søjle: ", x_S_navne[pivot_søjle],
            "  |  Pivot-række: ", basis_navne[pivot_række])
    P_tableau = pivot_tableau(P_tableau, pivot_søjle, pivot_række)
    return P_tableau, false
end

function simplex_solve(P_tableau; max_iter_dual=50, max_iter_primal=50)
    # Dual simplex loop (kør indtil BFS)
    for k in 1:max_iter_dual
        P_tableau, stop = dual_simplex_iteration(P_tableau)
        if stop
            println("Dual simplex stoppet grundet funden BFS")
            break
        end
        print_tableau(P_tableau)
    end

    # Primal simplex loop (kør indtil optimal)
    for k in 1:max_iter_primal
        P_tableau, stop = simplex_iteration(P_tableau)
        if stop
            println("Primal simplex stoppet grundet funden optimal løsning")
            break
        end
        print_tableau(P_tableau)
    end

    return P_tableau
end



println("Ny kørsel")
P = simplex_skabelon()

P_tableau = simplex_tableau_BFS(P.c, P.x_navne, P.A, P.b, P.S_navne)

print_tableau(P_tableau)

P_tableau_solved = simplex_solve(P_tableau)
