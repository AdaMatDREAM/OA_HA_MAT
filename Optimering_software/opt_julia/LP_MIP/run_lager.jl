using HiGHS, JuMP;
using Printf
using Colors  # Nødvendig for colorant i print.jl funktioner

# Includefiler til funktioner
include("build.jl")
include("print.jl")
include("convert_dual.jl")  # Indeholder write_problem_file og print_problem_terminal
include("lager_problem_skabelon.jl")

# Indlæs modellen og indstillinger
# Syntax P.[variabelnavn]
P = lager_problem_skabelon()

# Print problemformulering først
if P.output_terminal
    print_problem_terminal(P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
end

# Bygger modellen
M, x, constraints = build_matrix_notation(P.obj, P.c, P.A, P.b, P.b_dir, 
    P.nedre_grænse, P.øvre_grænse, P.x_type)

if P.model_type == "MIP"
    # Optimer modellen
    optimize!(M)
    
    if P.output_terminal
        # Print problemformulering
        print_problem_terminal(P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
        # Print lagerproblem løsning
        print_lager_problem(M, x, P, P.dec, P.tol)
    end
    
    if P.output_fil
        # Skriv problemformulering og løsning til fil
        open(P.output_fil_navn, "w") do file
            # Skriv problemformulering først
            write_problem_file(file, P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
            
            # Skriv løsning til fil (brug redirect_stdout så output går til filen)
            redirect_stdout(file) do
                print_lager_problem(M, x, P, P.dec, P.tol)
            end
        end
        println("Output er gemt i .txt filen: ", P.output_fil_navn)
    end
else
    println("Fejl: Lagerproblemet skal være MIP (pga. binære δ variabler)")
end
