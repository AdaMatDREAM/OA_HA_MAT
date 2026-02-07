using Graphs
using Printf
using GraphPlot, Colors

# Includefiler til funktioner
include("build.jl")
include("print.jl")
include("MST_skabelon.jl")

# Indlæs modellen og indstillinger
# Syntax P.[variabelnavn]
P = MST_skabelon()

# ========== KONSTRUKTION AF GRAF OG DISTANCE MATRIX ==========
G, DistanceMatrix, node_to_int, int_to_node = build_MST_graph(P.noder, P.kanter)

# ========== KRUSKAL'S ALGORITME ==========
if P.output_terminal
    println("="^100)
    println("LØSNING MED KRUSKAL'S ALGORITME")
    println("="^100)
end

MST_edges = kruskal_mst(G, DistanceMatrix)

# ========== BEREGN RESULTATER ==========
# Beregn total vægt
total_weight = sum(DistanceMatrix[src(edge), dst(edge)] for edge in MST_edges)

# Konverter edges til (node1, node2, weight) format
active_edges = []
for edge in MST_edges
    node1_idx = src(edge)
    node2_idx = dst(edge)
    node1 = int_to_node[node1_idx]
    node2 = int_to_node[node2_idx]
    weight = DistanceMatrix[node1_idx, node2_idx]
    push!(active_edges, (node1, node2, weight, 1.0))  # Værdi er 1.0 for Kruskal
end

# ========== PRINT RESULTATER ==========
# Brug output funktionen (respekterer output_terminal)
print_MST_Kruskal_output(active_edges, total_weight, P.dec, P.output_terminal)

# ========== VISUALISER MST ==========
if P.output_terminal
    println("\n" * "─"^100)
    println("GRAF VISUALISERING (GraphPlot):")
    println("─"^100)
    plot_MST_from_edges(active_edges, P.kanter, P.noder, P.dec)
end

# ========== OUTPUT TIL FIL (hvis ønsket) ==========
if P.output_fil
    output_fil_navn_kruskal = replace(P.output_fil_navn, ".txt" => "_Kruskal.txt")
    open(output_fil_navn_kruskal, "w") do file
        redirect_stdout(file) do
            println("="^100)
            println("LØSNING MED KRUSKAL'S ALGORITME")
            println("="^100)
            
            # Brug samme output funktion (med output_terminal = true så den printer)
            print_MST_Kruskal_output(active_edges, total_weight, P.dec, true)
        end
        
        # Visualiser MST med GraphPlot (udenfor redirect_stdout så plot stadig vises)
        println("\n" * "─"^100)
        println("GRAF VISUALISERING (GraphPlot):")
        println("─"^100)
        plot_MST_from_edges(active_edges, P.kanter, P.noder, P.dec)
    end
    println("Output er gemt i .txt filen: ", output_fil_navn_kruskal)
end
