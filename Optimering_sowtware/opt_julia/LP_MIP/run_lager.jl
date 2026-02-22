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
            
            # Tilføj ekstra information om lagerproblemet
            println(file, "\n" * "="^100)
            println(file, "LAGERPROBLEM - EKSTRA INFORMATION")
            println(file, "="^100)
            
            # Beregn total omsætning (d^T·p)
            total_omsætning = sum(P.d .* P.p)
            println(file, "\nTotal omsætning (d^T·p): $(round(total_omsætning, digits=P.dec))")
            
            # Beregn faktiske omkostninger fra løsningen
            # (optimize! er allerede kaldt i standard_MIP_output)
            status = termination_status(M)
            status_str = string(status)
            if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
                # Hent løsningsværdier
                x_vals = [value(x[i]) for i in 1:P.k]
                i_vals = [value(x[P.k + 1 + t]) for t in 0:P.k]
                delta_vals = [value(x[2*P.k + 1 + i]) for i in 1:P.k]
                
                # Beregn omkostninger
                variable_omkostninger = sum(x_vals .* P.c_V)
                lager_omkostninger = sum(i_vals .* P.c_I)
                faste_omkostninger = sum(delta_vals .* P.c_F)
                total_omkostninger = variable_omkostninger + lager_omkostninger + faste_omkostninger
                
                # Beregn profit (omsætning - omkostninger)
                total_profit = total_omsætning - total_omkostninger
                
                println(file, "\nDetaljerede omkostninger:")
                println(file, "  Variable produktionsomkostninger: $(round(variable_omkostninger, digits=P.dec))")
                println(file, "  Lageromkostninger: $(round(lager_omkostninger, digits=P.dec))")
                println(file, "  Faste omkostninger: $(round(faste_omkostninger, digits=P.dec))")
                println(file, "  Total omkostninger: $(round(total_omkostninger, digits=P.dec))")
                println(file, "\nTotal profit (omsætning - omkostninger): $(round(total_profit, digits=P.dec))")
                
                println(file, "\nProduktionsplan:")
                println(file, "Periode | Produktion (x_i) | Efterspørgsel (d_i) | Slutlager (i_i) | Produktion aktiv (δ_i)")
                println(file, "-"^100)
                println(file, @sprintf("  %2d    |        -         |         -          |      %8.2f      |         -", 
                    0, i_vals[1]))  # i_0 (startlager)
                for i in 1:P.k
                    println(file, @sprintf("  %2d    |      %8.2f      |        %8.2f       |      %8.2f      |         %d", 
                        i, x_vals[i], P.d[i], i_vals[i+1], round(Int, delta_vals[i])))
                end
            end
            
            println(file, "\n" * "="^100)
        end
        println("Output er gemt i .txt filen: ", P.output_fil_navn)
    end
else
    println("Fejl: Lagerproblemet skal være MIP (pga. binære δ variabler)")
end
