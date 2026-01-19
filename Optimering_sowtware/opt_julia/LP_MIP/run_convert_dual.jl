using HiGHS, JuMP;
using MathOptInterface
const MOI = MathOptInterface
using Printf


include("skabelon_LP_MIP.jl")
include("Convert_dual.jl")
include("print.jl")

P = LP_MIP_model_skabelon()

# Vælg filnavn til samlet output (primal + dual i samme .tex)
output_fælles_navn = joinpath(P.output_mappe, "primal_dual.tex")

open(output_fælles_navn, "w") do file
    println(file, "\\documentclass{article}")
    println(file, "\\usepackage[utf8]{inputenc}")
    println(file, "\\usepackage{amsmath,amssymb}")
    println(file, "\\begin{document}")
    println(file, "\\begin{flushleft}")
    println(file, "\\section*{Primal problem}")
    print_problem_latex_LP_MIP(file, P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
    if P.dual_defined
        D = convert_dual(P.obj, P.A, P.b, P.b_dir, P.c, P.fortegn, P.x_type)
        println(file, "\\section*{Dual problem}")
        print_problem_latex_LP_MIP(file, D.obj, D.c_D, D.A_D, D.b_D, D.b_dir_D, D.y_navne, D.fortegn_D, D.y_type)
    end
    println(file, "\\end{flushleft}")
    println(file, "\\end{document}")
end

println("Primal og dual skrevet til: ", output_fælles_navn)

