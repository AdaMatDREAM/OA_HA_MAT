using HiGHS, JuMP;
using Printf

include("Skabelon_simplex.jl")
include("Primal_Dual_simplex_alg.jl")
include("Print_tableau.jl")

println("Ny kørsel")

P = simplex_skabelon()
P_tableau = simplex_tableau_BFS(P.c, P.x_navne, P.A, P.b, P.S_navne)

# Antal decimaler i output
dec = 2

if P.output_terminal
    P_tableau = simplex_solve(P_tableau; print_tableaux_iterationer=P.print_tableaux_iterationer)
    # Beregn sensitivitet
    result = optimal_tableau(P_tableau)
    # Print fuld rapport
    println("\nOPTIMAL LØSNING OG SENSITIVITETSANALYSE\n")
    full_report_simplex_sensitivity(result, P_tableau.x_S_navne, P.x_navne, P.c, P.b, P.b_navne, dec)
end

if P.output_fil
    # Skriv til fil
    open(P.output_fil_navn, "w") do file
        redirect_stdout(file) do
            # Genberegn tableau for fil output
            P_tableau_fil = simplex_tableau_BFS(P.c, P.x_navne, P.A, P.b, P.S_navne)
            P_tableau_fil = simplex_solve(P_tableau_fil; print_tableaux_iterationer=P.print_tableaux_iterationer)
            result = optimal_tableau(P_tableau_fil)
            println("\nOPTIMAL LØSNING OG SENSITIVITETSANALYSE\n")
            full_report_simplex_sensitivity(result, P_tableau_fil.x_S_navne, P.x_navne, P.c, P.b, P.b_navne, dec)
        end
    end
    println("Output er gemt i .txt filen: ", P.output_fil_navn)
end