using HiGHS, JuMP;
using Printf
using Colors  # Nødvendig for colorant i print.jl funktioner
using Combinatorics  # For combinations() i TSP subtour constraints
using Graphs, GraphPlot  # For TSP tour visualisering

# Includefiler til funktioner
include("build.jl")
include("print.jl")
include("convert_dual.jl")
include("TSP_problem_skabelon.jl")

# Indlæs modellen og indstillinger
# Syntax P.[variabelnavn]
P = TSP_problem_skabelon()

# Print problemformulering først
if P.output_terminal
    print_problem_terminal(P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
end

# Bygger modellen
M, x, constraints = build_matrix_notation(P.obj, P.c, P.A, P.b, P.b_dir, 
    P.nedre_grænse, P.øvre_grænse, P.x_type)

# TSP problemet er et MIP problem (binary variabler)
if P.model_type == "MIP"
    if P.output_terminal
        standard_MIP_output(M, x, P.x_navne, P.x_type, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
        P.dec, P.tol, P.output_terminal, P.output_fil, 
        P.output_fil_navn, P.model_type, P.fortegn)
        
        # Print TSP matrix og tour hvis optimal løsning (modellen er allerede optimeret i standard_MIP_output)
        status = termination_status(M)
        status_str = string(status)
        if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
            print_TSP_matrix(M, x, P.x_navne, P.node_navne, P.dec)
            print_TSP_tour(M, x, P.x_navne, P.node_navne, P.c, P.dec)
            
            # Visualiser TSP tour med GraphPlot
            println("\n" * "─"^100)
            println("GRAF VISUALISERING (GraphPlot):")
            println("─"^100)
            plot_TSP(M, x, P.x_navne, P.node_navne, P.c, P.dec)
        end
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
                
                # Print TSP matrix og tour hvis optimal løsning (modellen er allerede optimeret i standard_MIP_output)
                status = termination_status(M)
                status_str = string(status)
                if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
                    print_TSP_matrix(M, x, P.x_navne, P.node_navne, P.dec)
                    print_TSP_tour(M, x, P.x_navne, P.node_navne, P.c, P.dec)

                     # Visualiser TSP tour med GraphPlot
                    println("\n" * "─"^100)
                    println("GRAF VISUALISERING (GraphPlot):")
                    println("─"^100)
                    plot_TSP(M, x, P.x_navne, P.node_navne, P.c, P.dec)
                end
            end
        end
        println("Output er gemt i .txt filen: ", P.output_fil_navn)
    end
else
    error("TSP problemet skal være et MIP problem (model_type = \"MIP\")")
end
