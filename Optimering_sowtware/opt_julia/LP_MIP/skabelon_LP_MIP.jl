function LP_MIP_model_skabelon()
# Type af model: LP eller MIP
model_type = "LP";
# True hvis du også vil have dualt program
dual_defined = false;

# Objektiv MAX eller MIN
obj = MOI.MAX_SENSE;

# Objektivcoefficienter og variabelnavne
# Simpelt MIP testproblem med binære og heltalsvariable
c = [5, 3, 2];
x_navne = ["x_1", "x_2", "x_3"];
# Fortegnskrav 
# :R -> ]-inf, inf[
# :>= -> x_i >= 0
# :<= -> x_i <= 0
fortegn = [:>=, :>=, :>=]
nedre_grænse = zeros(length(fortegn))
øvre_grænse = zeros(length(fortegn))
for i in eachindex(fortegn)
    if fortegn[i] == :R
        nedre_grænse[i] = -Inf
        øvre_grænse[i] = Inf
    elseif fortegn[i] == :>=
        nedre_grænse[i] = 0
        øvre_grænse[i] = Inf
    elseif fortegn[i] == :<=
        nedre_grænse[i] = -Inf
        øvre_grænse[i] = 0
    end
end

# Begrænsninger og kapaciteter
A = [1 1 1;
     2 1 0;
     1 2 1];

b = [10, 8, 12];
# Retningen af begrænsningerne kan skiftes mellem :<=, :>= og :(==)
b_dir = [:<=, :<=, :<=];
b_navne = ["B1", "B2", "B3"];

if model_type == "MIP"
    # vælg variabeltyper hved MIP problemer. Du kan vælge mellem :Integer, :Binary og :Continuous.
    x_type = [:Binary, :Integer, :Binary];
elseif model_type == "LP"
    x_type = fill(:Continuous, length(c));
end

# Antal decimaler i output og tolerance for 0-værdier
dec = 2;
tol = 1e-9;

# Output af resultater i terminal eller fil
output_terminal = true;
output_fil = false;
output_latex = false;

# Output mappe konfiguration
# Du kan enten bruge en absolut sti eller en relativ sti
# Hvis output_base_sti er tom (""), bruges samme mappe som koden
output_base_sti = ""  # F.eks. "" for samme mappe, eller "C:\\Users\\Adam\\Documents" for absolut sti
output_mappe_navn = "Output"  # Navn på output-mappen

# Byg output mappe sti
if output_base_sti == ""
    # Brug samme mappe som koden
    output_mappe = joinpath(@__DIR__, output_mappe_navn)
else
    # Brug brugerdefineret sti
    output_mappe = joinpath(output_base_sti, output_mappe_navn)
end

# Opret output mappe hvis den ikke eksisterer
if !isdir(output_mappe)
    mkpath(output_mappe)
end

# Filnavn til output (defineres altid)
output_fil_navn = joinpath(output_mappe, "test_primal_2.txt")
output_latex_navn = joinpath(output_mappe, "test_primal_4.tex")

output_fil_navn_D = joinpath(output_mappe, "test_dual_2.txt")
output_latex_navn_D = joinpath(output_mappe, "test_dual_3.tex")

# Returner som NamedTuple for bedre læsbarhed
return (
    model_type = model_type,
    dual_defined = dual_defined,
    obj = obj,
    c = c,
    x_navne = x_navne,
    fortegn = fortegn,
    nedre_grænse = nedre_grænse,
    øvre_grænse = øvre_grænse,
    A = A,
    b = b,
    b_dir = b_dir,
    b_navne = b_navne,
    x_type = x_type,
    dec = dec,
    tol = tol,
    output_terminal = output_terminal,
    output_fil = output_fil,
    output_latex = output_latex,
    output_base_sti = output_base_sti,
    output_mappe_navn = output_mappe_navn,
    output_mappe = output_mappe,
    output_fil_navn = output_fil_navn,
    output_latex_navn = output_latex_navn,
    output_fil_navn_D = output_fil_navn_D,
    output_latex_navn_D = output_latex_navn_D
)
end