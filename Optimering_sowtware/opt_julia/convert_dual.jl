# Pragram til at konvertere primalt program til dualt program
function convert_dual(obj, A, b, b_dir, c, fortegn, x_type)
if obj == MOI.MAX_SENSE
    obj = MOI.MIN_SENSE
elseif obj == MOI.MIN_SENSE
    obj = MOI.MAX_SENSE
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

