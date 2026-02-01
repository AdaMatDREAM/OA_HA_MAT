using HiGHS, JuMP;
using Printf

# Includefiler til funktioner
include("build.jl")
include("print.jl")
include("convert_dual.jl")
include("shortest_path_skabelon.jl")

# Indlæs modellen og indstillinger
# Syntax P.[variabelnavn]
P = shortest_path_skabelon()

# Print problemformulering først
if P.output_terminal
    print_problem_terminal(P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
end

# Bygger modellen
M, x, constraints = build_matrix_notation(P.obj, P.c, P.A, P.b, P.b_dir, 
    P.nedre_grænse, P.øvre_grænse, P.x_type)

# Shortest path problemet er LP (pga. totally unimodular matrix)
if P.model_type == "LP"
    if P.output_terminal
        standard_LP_output(M, x, P.x_navne, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
        P.dec, P.tol, P.output_terminal, P.output_fil, 
        P.output_fil_navn, P.model_type, P.x_type, P.fortegn)
        
        # Tjek om løsningen er heltallig (for at verificere totally unimodular matrix)
        status = termination_status(M)
        status_str = string(status)
        if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
            all_integer, non_integer_vars = check_integer_solution(x, P.x_navne, P.tol)
            
            println("\n" * "─"^100)
            println("TJEK FOR HELTALLIG LØSNING (UNIMODULARITET):")
            println("─"^100)
            if all_integer
                println("   Success: Alle løsningsværdier er heltallige (0 eller 1)")
                println("   Dette bekræfter at constraint-matricen er totally unimodular.")
                println("   LP-relaxation giver samme resultat som MIP!")
            else
                println("  ADVARSEL: Nogle løsningsværdier er IKKE heltallige:")
                for (var_name, val) in non_integer_vars
                    @printf("   %s = %.*f\n", var_name, P.dec, val)
                end
                println("   Dette tyder på at constraint-matricen IKKE er totally unimodular.")
            end
            println("─"^100)
            
            print_shortest_path(M, x, P.x_navne, P.kanter, P.source_node, P.sink_node, P.c, P.dec)
        end
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
                
                # Tjek om løsningen er heltallig (for at verificere totally unimodular matrix)
                status = termination_status(M)
                status_str = string(status)
                if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
                    all_integer, non_integer_vars = check_integer_solution(x, P.x_navne, P.tol)
                    
                    println("\n" * "─"^100)
                    println("TJEK FOR HELTALLIG LØSNING (UNIMODULARITET):")
                    println("─"^100)
                    if all_integer
                        println("   Success: Alle løsningsværdier er heltallige (0 eller 1)")
                        println("   Dette bekræfter at constraint-matricen er totally unimodular.")
                        println("   LP-relaxation giver samme resultat som MIP!")
                    else
                        println("  ADVARSEL: Nogle løsningsværdier er IKKE heltallige:")
                        for (var_name, val) in non_integer_vars
                            @printf("   %s = %.*f\n", var_name, P.dec, val)
                        end
                        println("   Dette tyder på at constraint-matricen IKKE er totally unimodular.")
                    end
                    println("─"^100)
                    
                    print_shortest_path(M, x, P.x_navne, P.kanter, P.source_node, P.sink_node, P.c, P.dec)
                end
            end
        end
        println("Output er gemt i .txt filen: ", P.output_fil_navn)
    end
else
    error("Shortest path problemet skal være LP (model_type = \"LP\")")
end
