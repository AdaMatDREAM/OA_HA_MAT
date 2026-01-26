using HiGHS, JuMP;
using Printf


include("skabelon_LP_MIP.jl")
include("Convert_dual.jl")

P = LP_MIP_model_skabelon()

# Vælg filnavn til samlet output (primal + dual i samme fil)
output_fil_navn = joinpath(P.output_mappe, "primal_dual.txt")

# Print primal og dual til terminal (altid print dual i convert_dual sammenhæng)
if P.output_terminal
    println("\nPRIMAL PROBLEM:")
    print_problem_terminal(P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
    
    # Konverter til dual og print
    D = convert_dual(P.obj, P.A, P.b, P.b_dir, P.c, P.fortegn, P.x_type)
    println("\nDUAL PROBLEM:")
    print_problem_terminal(D.obj, D.c_D, D.A_D, D.b_D, D.b_dir_D, D.y_navne, D.fortegn_D, D.y_type)
end

# Skriv primal og dual til samme fil (hvis output_fil er true)
if P.output_fil
    D = convert_dual(P.obj, P.A, P.b, P.b_dir, P.c, P.fortegn, P.x_type)
    open(output_fil_navn, "w") do file
        println(file, "PRIMAL PROBLEM:")
        write_problem_file(file, P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
        println(file, "\nDUAL PROBLEM:")
        write_problem_file(file, D.obj, D.c_D, D.A_D, D.b_D, D.b_dir_D, D.y_navne, D.fortegn_D, D.y_type)
    end
    println("\nPrimal og dual problem skrevet til: ", output_fil_navn)
end

