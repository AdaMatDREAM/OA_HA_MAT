using HiGHS, JuMP;
using MathOptInterface
const MOI = MathOptInterface
using Printf

# Includefiler til funktioner
include("build.jl")
include("print.jl")
include("Convert_dual.jl")
include("skabelon_LP_MIP.jl")

# Indlæs modellen og indstillinger
# Syntax P.[variabelnavn]
P = LP_MIP_model_skabelon()

# Bygger modellen
M, x, constraints = build_matrix_notation(P.obj, P.c, P.A, P.b, P.b_dir, 
    P.nedre_grænse, P.øvre_grænse, P.x_type)

if P.model_type == "LP"
    standard_LP_output(M, x, P.x_navne, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
    P.dec, P.tol, P.output_terminal, P.output_fil, P.output_latex, 
    P.output_fil_navn, P.output_latex_navn, P.model_type, P.x_type, P.fortegn)
    
    # Hvis dual skal løses
    if P.dual_defined == true
        D = convert_dual(P.obj, P.A, P.b, P.b_dir, P.c, P.fortegn, P.x_type)
        M_D, y, constraints_D = build_matrix_notation(D.obj, D.c_D, D.A_D, D.b_D, D.b_dir_D, 
            D.nedre_grænse_D, D.øvre_grænse_D, D.y_type)
        standard_LP_output(M_D, y, D.y_navne, D.c_D, D.A_D, D.obj, constraints_D, D.b_D, D.b_dir_D, D.b_D_navne,
        P.dec, P.tol, P.output_terminal, P.output_fil, P.output_latex, 
        P.output_fil_navn_D, P.output_latex_navn_D, P.model_type, D.y_type, D.fortegn_D)
    end
elseif P.model_type == "MIP"
    standard_MIP_output(M, x, P.x_navne, P.x_type, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
    P.dec, P.tol, P.output_terminal, P.output_fil, P.output_latex, 
    P.output_fil_navn, P.output_latex_navn, P.model_type, P.fortegn)
end 