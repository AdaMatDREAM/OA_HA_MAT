
# Pragram til at konvertere primalt program til dualt program
function convert_dual(obj, A, b, b_dir, c, fortegn, x_type)
if obj == :MAX
    obj = :MIN
elseif obj == :MIN
    obj = :MAX
end

m,n = size(A);
# A -> A^T
A_D = transpose(A);
# c -> b
b_D = c;
# x -> y
y_navne = ["y_$(i)" for i in 1:m];
# Y_navne =[y1, y2, y3, ...]

# b -> c
c_D = b

# Fortegnskrav for duale variable
# b_dir = <= -> >=
# b_dir = >= -> <=
# b_dir = (==) -> R
fortegn_D = Vector{Symbol}(undef, m)
for i in 1:m
    if b_dir[i] == :<=
        fortegn_D[i] = :>=
    elseif b_dir[i] == :>=
        fortegn_D[i] = :<=
    elseif b_dir[i] == :(==)
        fortegn_D[i] = :R
    end
end
nedre_grænse_D = zeros(m)
øvre_grænse_D = zeros(m)
for i in eachindex(fortegn_D)
    if fortegn_D[i] == :R
        nedre_grænse_D[i] = -Inf
        øvre_grænse_D[i] = Inf
    elseif fortegn_D[i] == :>=
        nedre_grænse_D[i] = 0
        øvre_grænse_D[i] = Inf
    elseif fortegn_D[i] == :<=
        nedre_grænse_D[i] = -Inf
        øvre_grænse_D[i] = 0
    end
end

b_dir_D = Vector{Symbol}(undef, n)
for i in 1:n
    if fortegn[i] == :>=
        b_dir_D[i] = :>=
    elseif fortegn[i] == :<=
        b_dir_D[i] = :<=
    elseif fortegn[i] == :R
        b_dir_D[i] = :(==)
    end
end
# Navne begrænsninger i dualt program
b_D_navne = ["BDual_$(i)" for i in 1:n]
# b_D_navne = ["BDual_1", "BDual_2", "BDual_3", ...]

y_type = fill(:Continuous, m)

# Returner som NamedTuple for bedre læsbarhed
return (
    obj = obj,
    A_D = A_D,
    b_D = b_D,
    b_dir_D = b_dir_D,
    fortegn_D = fortegn_D,
    c_D = c_D,
    y_navne = y_navne,
    y_type = y_type,
    b_D_navne = b_D_navne,
    nedre_grænse_D = nedre_grænse_D,
    øvre_grænse_D = øvre_grænse_D
)
end

#######################################################################################
# Funktion til at printe problemformulering til terminal
function print_problem_terminal(obj, c, A, b, b_dir, x_navne, fortegn, x_type)
    sense = obj == :MAX ? "Maksimer" : "Minimer"
    
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
    
    # Begrænsninger
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
        
        dir = b_dir[i] == :<= ? "<=" : (b_dir[i] == :>= ? ">=" : "=")
        println("  ", join(row_terms, ""), " ", dir, " ", b[i])
    end
    
    # Fortegnskrav
    dom_terms = String[]
    for i in eachindex(x_navne)
        if x_type[i] == :Binary
            push!(dom_terms, x_navne[i] * " ∈ {0,1}")
        elseif x_type[i] == :Integer
            if fortegn[i] == :>=
                push!(dom_terms, x_navne[i] * " ∈ ℤ, " * x_navne[i] * " ≥ 0")
            elseif fortegn[i] == :<=
                push!(dom_terms, x_navne[i] * " ∈ ℤ, " * x_navne[i] * " ≤ 0")
            else
                push!(dom_terms, x_navne[i] * " ∈ ℤ")
            end
        elseif x_type[i] == :Continuous
            if fortegn[i] == :R
                push!(dom_terms, x_navne[i] * " ∈ ℝ")
            elseif fortegn[i] == :<=
                push!(dom_terms, x_navne[i] * " ≤ 0")
            elseif fortegn[i] == :>=
                push!(dom_terms, x_navne[i] * " ≥ 0")
            end
        end
    end
    
    if !isempty(dom_terms)
        println("\nSamt fortegnskrav:")
        println("  ", join(dom_terms, ", "))
    end
    println("="^100)
    println()
end

# Funktion til at skrive problemformulering til fil
function write_problem_file(file, obj, c, A, b, b_dir, x_navne, fortegn, x_type)
    sense = obj == :MAX ? "Maksimer" : "Minimer"
    
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
    
    # Begrænsninger
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
        
        dir = b_dir[i] == :<= ? "<=" : (b_dir[i] == :>= ? ">=" : "=")
        println(file, "  ", join(row_terms, ""), " ", dir, " ", b[i])
    end
    
    # Fortegnskrav
    dom_terms = String[]
    for i in eachindex(x_navne)
        if x_type[i] == :Binary
            push!(dom_terms, x_navne[i] * " ∈ {0,1}")
        elseif x_type[i] == :Integer
            if fortegn[i] == :>=
                push!(dom_terms, x_navne[i] * " ∈ ℤ, " * x_navne[i] * " ≥ 0")
            elseif fortegn[i] == :<=
                push!(dom_terms, x_navne[i] * " ∈ ℤ, " * x_navne[i] * " ≤ 0")
            else
                push!(dom_terms, x_navne[i] * " ∈ ℤ")
            end
        elseif x_type[i] == :Continuous
            if fortegn[i] == :R
                push!(dom_terms, x_navne[i] * " ∈ ℝ")
            elseif fortegn[i] == :<=
                push!(dom_terms, x_navne[i] * " ≤ 0")
            elseif fortegn[i] == :>=
                push!(dom_terms, x_navne[i] * " ≥ 0")
            end
        end
    end
    
    if !isempty(dom_terms)
        println(file, "\nSamt fortegnskrav:")
        println(file, "  ", join(dom_terms, ", "))
    end
    println(file, "="^100)
    println(file)
end

# Funktion der kan kaldes direkte for at printe primal + dual til terminal
function print_primal_dual_terminal(P)
    # Print primal problemformulering
    println("\nPRIMAL PROBLEM:")
    print_problem_terminal(P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
    
    # Konverter til dual og print (altid i convert_dual sammenhæng)
    D = convert_dual(P.obj, P.A, P.b, P.b_dir, P.c, P.fortegn, P.x_type)
    println("\nDUAL PROBLEM:")
    print_problem_terminal(D.obj, D.c_D, D.A_D, D.b_D, D.b_dir_D, D.y_navne, D.fortegn_D, D.y_type)
end


