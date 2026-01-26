using HiGHS, JuMP;
using MathOptInterface
const MOI = MathOptInterface
using Printf

include("Skabelon_simplex.jl")
include("Primal_Dual_simplex_alg.jl")
include("Print_tableau.jl")

println("Test kørsel")

P = simplex_skabelon()
P_tableau = simplex_tableau_BFS(P.c, P.x_navne, P.A, P.b, P.S_navne)

if P.output_terminal
    P_tableau = simplex_solve(P_tableau; print_tableaux_iterationer=P.print_tableaux_iterationer)
end

# Beregn sensitivitet
result = optimal_tableau(P_tableau)

# Print resultater
println("\n" * "="^60)
println("SENSITIVITETSANALYSE - TEST")
println("="^60)

# Antal decimaler i output
dec = 2

# Print fuld rapport
println("\nOPTIMAL LØSNING OG SENSITIVITETSANALYSE\n")
full_report_simplex_sensitivity(result, P_tableau.x_S_navne, P.x_navne, P.c, P.b, P.b_navne, dec)
