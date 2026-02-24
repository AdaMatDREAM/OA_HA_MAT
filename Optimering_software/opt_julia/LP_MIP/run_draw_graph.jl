using HiGHS, JuMP
using Printf
using Graphs, GraphPlot, Colors

include("draw_graph_skabelon.jl")

# Indlæs grafen og indstillinger
# Syntax P.[variabelnavn]
P = draw_graph_skabelon()

# Tegn grafen
if P.output_terminal
    println("\n" * "─"^100)
    println("GRAF VISUALISERING (GraphPlot):")
    println("─"^100)
    plot_graph(P.noder, P.kanter)
end