using HiGHS, JuMP;
using MathOptInterface
const MOI = MathOptInterface

# Funktion til at bygge en LP/MIP-model
function build_matrix_notation(obj, c, A, b, b_dir, nedre_grænse, øvre_grænse, x_type=fill(:Continuous, length(c)))
    # Deklarerer modellen og variablene
    M = Model(HiGHS.Optimizer);
    @variable(M, x[i=eachindex(c)]);
    
    # Sæt variabeltyper (kun hvis der er ikke-kontinuerlige variable)
    if any(x_type .!= :Continuous)
        for i in eachindex(x)
            if x_type[i] == :Integer
                set_integer(x[i])
            elseif x_type[i] == :Binary
                set_binary(x[i])
            end
            # :Continuous er standard, så ingen handling nødvendig
        end
    end
    
    # Sætter grænserne for variablene
    for i in eachindex(x)
        if nedre_grænse[i] != -Inf
            set_lower_bound(x[i], nedre_grænse[i]);
        end
        if øvre_grænse[i] != Inf
            set_upper_bound(x[i], øvre_grænse[i]);
        end
    end

# Tilføjer begrænsningerne og gemmer dem i en container
constraints = []
for i in eachindex(b)
    if b_dir[i] == :<=
        push!(constraints, @constraint(M, sum(A[i,j] * x[j] for j in eachindex(c)) <= b[i]))
    elseif b_dir[i] == :>=
        push!(constraints, @constraint(M, sum(A[i,j] * x[j] for j in eachindex(c)) >= b[i]))
    elseif b_dir[i] == :(==)
        push!(constraints, @constraint(M, sum(A[i,j] * x[j] for j in eachindex(c)) == b[i]))
    end
end

# Tilføjer objektivet
@objective(M, obj, sum(c[i] * x[i] for i in eachindex(c)));

return M, x, constraints
end


##########################################################
# Funktion til at nulstille alle model-relaterede variable
# Dette gør det muligt at køre flere forskellige modeller i samme session
function reset_model_variables()
    # Liste over alle variable der skal nulstilles
    vars_to_reset = [
        :model_type, :obj, :c, :x_navne, :nedre_grænse, :øvre_grænse,
        :A, :b, :b_dir, :b_navne, :x_type,
        :dec, :tol,
        :output_terminal, :output_fil, :output_latex,
        :output_base_sti, :output_mappe_navn, :output_mappe,
        :output_fil_navn, :output_latex_navn,
        :M, :x, :constraints
    ]
    # Slet alle variable hvis de er defineret
    for var in vars_to_reset
            eval(Main, :(global $var = nothing))
    end
end

