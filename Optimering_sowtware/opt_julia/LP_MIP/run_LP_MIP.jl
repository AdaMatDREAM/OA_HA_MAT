using HiGHS, JuMP;
using Printf
using Colors  # Nødvendig for colorant i print.jl funktioner

# Includefiler til funktioner
include("build.jl")
include("print.jl")
include("Convert_dual.jl")
include("skabelon_LP_MIP.jl")

# Indlæs modellen og indstillinger
# Syntax P.[variabelnavn]
P = LP_MIP_model_skabelon()

# Print problemformulering først
if P.output_terminal
    print_problem_terminal(P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
end

# Bygger modellen
M, x, constraints = build_matrix_notation(P.obj, P.c, P.A, P.b, P.b_dir, 
    P.nedre_grænse, P.øvre_grænse, P.x_type)

if P.model_type == "LP"
    if P.output_terminal
        standard_LP_output(M, x, P.x_navne, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
        P.dec, P.tol, P.output_terminal, false, 
        P.output_fil_navn, P.model_type, P.x_type, P.fortegn)
    end
    
    if P.output_fil
        # Skriv problemformulering og løsning til fil
        open(P.output_fil_navn, "w") do file
            # Skriv problemformulering først
            write_problem_file(file, P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
            
            # Skriv løsning til fil (brug redirect_stdout så output går til filen)
            redirect_stdout(file) do
                # Sæt output_terminal = true så standard_LP_output printer, men output går til filen
                standard_LP_output(M, x, P.x_navne, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
                P.dec, P.tol, true, false, 
                P.output_fil_navn, P.model_type, P.x_type, P.fortegn)
            end
        end
        println("Output er gemt i .txt filen: ", P.output_fil_navn)
    end
    
    # Hvis dual skal løses
    if P.dual_defined == true
        D = convert_dual(P.obj, P.A, P.b, P.b_dir, P.c, P.fortegn, P.x_type)
        
        if P.output_terminal
            println("\nDUAL PROBLEM:")
            print_problem_terminal(D.obj, D.c_D, D.A_D, D.b_D, D.b_dir_D, D.y_navne, D.fortegn_D, D.y_type)
        end
        
        M_D, y, constraints_D = build_matrix_notation(D.obj, D.c_D, D.A_D, D.b_D, D.b_dir_D, 
            D.nedre_grænse_D, D.øvre_grænse_D, D.y_type)
        
        if P.output_terminal
            standard_LP_output(M_D, y, D.y_navne, D.c_D, D.A_D, D.obj, constraints_D, D.b_D, D.b_dir_D, D.b_D_navne,
            P.dec, P.tol, P.output_terminal, false, 
            P.output_fil_navn_D, P.model_type, D.y_type, D.fortegn_D)
        end
        
        if P.output_fil
            # Skriv dual problemformulering og løsning til fil
            open(P.output_fil_navn_D, "w") do file
                # Skriv problemformulering først
                println(file, "DUAL PROBLEM:")
                write_problem_file(file, D.obj, D.c_D, D.A_D, D.b_D, D.b_dir_D, D.y_navne, D.fortegn_D, D.y_type)
                
                # Skriv løsning til fil (brug redirect_stdout så output går til filen)
                redirect_stdout(file) do
                    # Sæt output_terminal = true så standard_LP_output printer, men output går til filen
                    standard_LP_output(M_D, y, D.y_navne, D.c_D, D.A_D, D.obj, constraints_D, D.b_D, D.b_dir_D, D.b_D_navne,
                    P.dec, P.tol, true, false, 
                    P.output_fil_navn_D, P.model_type, D.y_type, D.fortegn_D)
                end
            end
            println("Output er gemt i .txt filen: ", P.output_fil_navn_D)
        end
    end
elseif P.model_type == "MIP"
    if P.output_terminal
        standard_MIP_output(M, x, P.x_navne, P.x_type, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
        P.dec, P.tol, P.output_terminal, false, 
        P.output_fil_navn, P.model_type, P.fortegn)
    end
    
    if P.output_fil
        # Skriv problemformulering og løsning til fil
        open(P.output_fil_navn, "w") do file
            # Skriv problemformulering først
            write_problem_file(file, P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
            
            # Skriv løsning til fil (brug redirect_stdout så output går til filen)
            redirect_stdout(file) do
                # Sæt output_terminal = true så standard_MIP_output printer, men output går til filen
                standard_MIP_output(M, x, P.x_navne, P.x_type, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
                P.dec, P.tol, true, false, 
                P.output_fil_navn, P.model_type, P.fortegn)
            end
        end
        println("Output er gemt i .txt filen: ", P.output_fil_navn)
    end
end 