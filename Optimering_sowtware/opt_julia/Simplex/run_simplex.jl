using HiGHS, JuMP;
using MathOptInterface
const MOI = MathOptInterface
using Printf

include("Skabelon_simplex.jl")
include("Primal_Dual_simplex_alg.jl")
include("Print_tableau.jl")


P = simplex_skabelon()
P_tableau = simplex_tableau_BFS(P.c, P.x_navne, P.A, P.b, P.S_navne)


println("Ny kørsel")


if P.output_latex
    simplex_solve_latex(P_tableau, P.output_latex_navn)
end

if P.output_terminal
    simplex_solve(P_tableau)
end