using Graphs, GraphPlot, Colors
using Printf

function draw_graph_skabelon()
    
    # Definer noder
    noder = ["A", "B", "C", "D", "E"];
    
    # Definer edges(kanter) og vægte. 
    # Defineres som (edge1, edge2, vægt, "D"/"U" = directed/undirected)
    kanter = [
                ("A", "B", 5, "D"),
                ("A", "D", 3, "D"),
                ("B", "C", 4, "D"),
                ("B", "E", 7, "D"),
                ("D", "E", 2, "D"),
            ];
    
    # OUTPUT KONFIGURATION 
    output_terminal = true;  # Vis graf i terminal/VSCode
    output_fil = false;     # Gem ikke som fil
    
    return (
        noder = noder,
        kanter = kanter,
        output_terminal = output_terminal,
        output_fil = output_fil
    )
end

# Funktion til at tegne grafen
function plot_graph(noder, kanter, dec=2)
        # Opret graf
        # Tjek om der er directed edges
        has_directed = any(kant[4] == "D" for kant in kanter)
        
        if has_directed
            G = SimpleDiGraph(length(noder))
        else
            G = SimpleGraph(length(noder))
        end
        
        # Mapping fra nodenavn til index
        node_index = Dict(noder[i] => i for i in 1:length(noder))
        
        # Tilføj edges til grafen
        edge_weights = Dict{Tuple{Int, Int}, Float64}()
        edge_labels = String[]
        
        for kant in kanter
            from_node, to_node, weight, direction = kant[1], kant[2], kant[3], kant[4]
            from_idx = node_index[from_node]
            to_idx = node_index[to_node]
            
            if direction == "D"
                # Directed edge
                if !has_edge(G, from_idx, to_idx)
                    add_edge!(G, from_idx, to_idx)
                end
                edge_weights[(from_idx, to_idx)] = weight
            else
                # Undirected edge - tilføj begge retninger for SimpleDiGraph
                if has_directed
                    if !has_edge(G, from_idx, to_idx)
                        add_edge!(G, from_idx, to_idx)
                    end
                    if !has_edge(G, to_idx, from_idx)
                        add_edge!(G, to_idx, from_idx)
                    end
                    edge_weights[(from_idx, to_idx)] = weight
                    edge_weights[(to_idx, from_idx)] = weight
                else
                    if !has_edge(G, from_idx, to_idx)
                        add_edge!(G, from_idx, to_idx)
                    end
                    edge_weights[(from_idx, to_idx)] = weight
                end
            end
        end
        
        # Opret edge labels
        for e in edges(G)
            src_idx = src(e)
            dst_idx = dst(e)
            if haskey(edge_weights, (src_idx, dst_idx))
                weight = edge_weights[(src_idx, dst_idx)]
                push!(edge_labels, @sprintf("%.*f", dec, weight))
            else
                push!(edge_labels, "")
            end
        end
        
        # Node labels
        node_labels = noder
        
        # Node farver (standard blå)
        node_colors = fill(colorant"lightsteelblue", length(noder))
        
        # Edge farver (grå)
        edge_colors = fill(colorant"grey50", ne(G))
        
        # Plot grafen
        p = gplot(G,
            nodelabel = node_labels,
            edgelabel = edge_labels,
            nodefillc = node_colors,
            edgestrokec = edge_colors,
            nodesize = 0.3,
            nodestrokelw = 1.0,
            edgelinewidth = 0.5
        )
            display("image/svg+xml", p)
    end


# Eksempel brug:
# P = draw_graph_skabelon()
# plot_graph(P.noder, P.kanter)
