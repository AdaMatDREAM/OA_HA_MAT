using Graphs
using Printf
using GraphPlot, Colors

# Includefiler til funktioner
include("build.jl")
include("print.jl")
include("shortest_path_skabelon.jl")

# Indlæs modellen og indstillinger
# Syntax P.[variabelnavn]
P = shortest_path_skabelon()

# ========== KONSTRUKTION AF GRAF OG DISTANCE MATRIX ==========
G, DistanceMatrix, node_to_int, int_to_node = build_shortest_path_graph(P.noder, P.kanter)

# ========== TJEK FOR NEGATIVE WEIGHTS ==========
# Dijkstra kræver non-negative weights
has_negative_weights = false
for (from_node, to_node, weight, direction) in P.kanter
    if weight < 0
        has_negative_weights = true
        break
    end
end

if has_negative_weights
    error("Dijkstra's algoritme kræver non-negative edge weights. Brug Bellman-Ford algoritmen i stedet.")
end

# ========== DIJKSTRA'S ALGORITME ==========
if P.output_terminal
    println("="^100)
    println("LØSNING MED DIJKSTRA'S ALGORITME")
    println("="^100)
end

source_idx = node_to_int[P.source_node]
sink_idx = node_to_int[P.sink_node]

# Kør Dijkstra's algoritme
result = dijkstra_shortest_paths(G, source_idx, DistanceMatrix)

# ========== REKONSTRUER STI FRA SOURCE TIL SINK ==========
# Rekonstruer stien ved at følge parents baglæns fra sink til source
# Tjek om der er en sti til sink
if result.dists[sink_idx] == Inf
    error("Ingen sti fundet fra $(P.source_node) til $(P.sink_node)")
end

# Følg parents baglæns - brug en funktion for at undgå scope problemer
function reconstruct_path(parents, sink_idx)
    path_indices = Int[]
    current = sink_idx
    while current != 0  # 0 betyder ingen parent (source node)
        pushfirst!(path_indices, current)
        current = parents[current]
    end
    return path_indices
end

path_indices = reconstruct_path(result.parents, sink_idx)

# Konverter til nodenavne
path = [int_to_node[idx] for idx in path_indices]

# ========== BEREGN TOTAL VÆGT OG EDGE WEIGHTS ==========
total_weight = result.dists[sink_idx]
edge_weights = Dict{Tuple{String, String}, Float64}()

# Opret mapping af edge weights
for (from_node, to_node, weight, direction) in P.kanter
    edge_weights[(from_node, to_node)] = weight
    if direction == "U"
        # Undirected: tilføj også omvendt retning
        edge_weights[(to_node, from_node)] = weight
    end
end

# ========== PRINT RESULTATER ==========
# Brug output funktionen (respekterer output_terminal)
if P.output_terminal
    print_shortest_path_algorithm(path, edge_weights, P.source_node, P.sink_node, total_weight, P.dec, true)
    
    # Visualiser shortest path med GraphPlot
    println("\n" * "─"^100)
    println("GRAF VISUALISERING (GraphPlot):")
    println("─"^100)
    plot_shortest_path_from_algorithm(path, P.kanter, P.noder, P.source_node, P.sink_node, P.dec)
end

# ========== OUTPUT TIL FIL (hvis ønsket) ==========
if P.output_fil
    output_fil_navn_dijkstra = replace(P.output_fil_navn, ".txt" => "_Dijkstra.txt")
    open(output_fil_navn_dijkstra, "w") do file
        redirect_stdout(file) do
            println("="^100)
            println("LØSNING MED DIJKSTRA'S ALGORITME")
            println("="^100)
            
            # Brug samme output funktion (med output_terminal = true så den printer)
            print_shortest_path_algorithm(path, edge_weights, P.source_node, P.sink_node, total_weight, P.dec, true)
        end
        
        # Visualiser shortest path med GraphPlot (udenfor redirect_stdout så plot stadig vises)
        println("\n" * "─"^100)
        println("GRAF VISUALISERING (GraphPlot):")
        println("─"^100)
        plot_shortest_path_from_algorithm(path, P.kanter, P.noder, P.source_node, P.sink_node, P.dec)
    end
    println("Output er gemt i .txt filen: ", output_fil_navn_dijkstra)
end
