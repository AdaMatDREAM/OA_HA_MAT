# =============================================================================
# RUN MINIMUM COST FLOW
# =============================================================================
# Løser minimum cost flow problemet defineret i min_cost_flow_skabelon.jl.
# Understøtter både LP (kontinuerlige x) og MIP (heltallige x).
# Genbruger problemformulering (print_problem_terminal / write_problem_file)
# og standard LP/MIP output fra print.jl og build.jl.
# =============================================================================

using HiGHS, JuMP
using Printf
using Graphs, GraphPlot, Colors

include("build.jl")
include("print.jl")
include("convert_dual.jl")
include("min_cost_flow_skabelon.jl")

P = min_cost_flow_skabelon()

if P.output_terminal
    print_problem_terminal(P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
end

M, x, constraints = build_matrix_notation(P.obj, P.c, P.A, P.b, P.b_dir,
    P.nedre_grænse, P.øvre_grænse, P.x_type)

if P.model_type == "LP"
    if P.output_terminal
        standard_LP_output(M, x, P.x_navne, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
            P.dec, P.tol, P.output_terminal, P.output_fil,
            P.output_fil_navn, P.model_type, P.x_type, P.fortegn)
        status = termination_status(M)
        status_str = string(status)
        if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
            print_min_cost_flow(M, x, P.x_navne, P.kanter, P.supply_dict, P.demand_dict, P.kapaciteter, P.dec)
            println("\n" * "─"^100)
            println("GRAF VISUALISERING (GraphPlot):")
            println("─"^100)
            plot_min_cost_flow(M, x, P.x_navne, P.kanter, P.noder, P.supply_dict, P.demand_dict, P.kapaciteter, P.dec)
        end
    end

    if P.output_fil
        open(P.output_fil_navn, "w") do file
            write_problem_file(file, P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
            redirect_stdout(file) do
                standard_LP_output(M, x, P.x_navne, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
                    P.dec, P.tol, true, false,
                    P.output_fil_navn, P.model_type, P.x_type, P.fortegn)
                status = termination_status(M)
                status_str = string(status)
                if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
                    print_min_cost_flow(M, x, P.x_navne, P.kanter, P.supply_dict, P.demand_dict, P.kapaciteter, P.dec)
                end
            end
            status = termination_status(M)
            status_str = string(status)
            if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
                println("\n" * "─"^100)
                println("GRAF VISUALISERING (GraphPlot):")
                println("─"^100)
                plot_min_cost_flow(M, x, P.x_navne, P.kanter, P.noder, P.supply_dict, P.demand_dict, P.kapaciteter, P.dec)
            end
        end
        println("Output er gemt i .txt filen: ", P.output_fil_navn)
    end

elseif P.model_type == "MIP"
    if P.output_terminal
        standard_MIP_output(M, x, P.x_navne, P.x_type, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
            P.dec, P.tol, P.output_terminal, P.output_fil,
            P.output_fil_navn, P.model_type, P.fortegn)
        status = termination_status(M)
        status_str = string(status)
        if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
            print_min_cost_flow(M, x, P.x_navne, P.kanter, P.supply_dict, P.demand_dict, P.kapaciteter, P.dec)
            println("\n" * "─"^100)
            println("GRAF VISUALISERING (GraphPlot):")
            println("─"^100)
            plot_min_cost_flow(M, x, P.x_navne, P.kanter, P.noder, P.supply_dict, P.demand_dict, P.kapaciteter, P.dec)
        end
    end

    if P.output_fil
        open(P.output_fil_navn, "w") do file
            write_problem_file(file, P.obj, P.c, P.A, P.b, P.b_dir, P.x_navne, P.fortegn, P.x_type)
            redirect_stdout(file) do
                standard_MIP_output(M, x, P.x_navne, P.x_type, P.c, P.A, P.obj, constraints, P.b, P.b_dir, P.b_navne,
                    P.dec, P.tol, true, false,
                    P.output_fil_navn, P.model_type, P.fortegn)
                status = termination_status(M)
                status_str = string(status)
                if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
                    print_min_cost_flow(M, x, P.x_navne, P.kanter, P.supply_dict, P.demand_dict, P.kapaciteter, P.dec)
                end
            end
            status = termination_status(M)
            status_str = string(status)
            if status_str == "OPTIMAL" || status_str == "ALMOST_OPTIMAL"
                println("\n" * "─"^100)
                println("GRAF VISUALISERING (GraphPlot):")
                println("─"^100)
                plot_min_cost_flow(M, x, P.x_navne, P.kanter, P.noder, P.supply_dict, P.demand_dict, P.kapaciteter, P.dec)
            end
        end
        println("Output er gemt i .txt filen: ", P.output_fil_navn)
    end
else
    error("model_type skal være \"LP\" eller \"MIP\".")
end
