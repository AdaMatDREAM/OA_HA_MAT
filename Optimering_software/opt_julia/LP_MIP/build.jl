using HiGHS, JuMP;

# Funktion til at bygge en LP/MIP-model
function build_matrix_notation(obj, c, A, b, b_dir, nedre_grænse, øvre_grænse, x_type=fill(:Continuous, length(c)))
    # Deklarerer modellen og variablene
    M = Model(HiGHS.Optimizer);
    @variable(M, x[i=eachindex(c)]);
    
    # Sæt variabeltyper (kun hvis der er ikke-kontinuerlige variable)
    if any(x_type .!= :Continuous)
        for i in eachindex(x)
            if x_type[i] == :Integer
                set_integer(x[i])
            elseif x_type[i] == :Binary
                set_binary(x[i])
            end
            # :Continuous er standard, så ingen handling nødvendig
        end
    end
    
    # Sætter grænserne for variablene
    for i in eachindex(x)
        if nedre_grænse[i] != -Inf
            set_lower_bound(x[i], nedre_grænse[i]);
        end
        if øvre_grænse[i] != Inf
            set_upper_bound(x[i], øvre_grænse[i]);
        end
    end

# Tilføjer begrænsningerne og gemmer dem i en container
constraints = []
for i in eachindex(b)
    if b_dir[i] == :<=
        push!(constraints, @constraint(M, sum(A[i,j] * x[j] for j in eachindex(c)) <= b[i]))
    elseif b_dir[i] == :>=
        push!(constraints, @constraint(M, sum(A[i,j] * x[j] for j in eachindex(c)) >= b[i]))
    elseif b_dir[i] == :(==)
        push!(constraints, @constraint(M, sum(A[i,j] * x[j] for j in eachindex(c)) == b[i]))
    end
end

# Tilføjer objektivet
# Konverter symbol til JuMP objektiv retning
if obj == :MAX
    @objective(M, Max, sum(c[i] * x[i] for i in eachindex(c)))
elseif obj == :MIN
    @objective(M, Min, sum(c[i] * x[i] for i in eachindex(c)))
else
    error("Ukendt objektiv retning: $obj. Brug :MAX eller :MIN")
end

return M, x, constraints
end


##########################################################
# Funktion til at nulstille alle model-relaterede variable
# Dette gør det muligt at køre flere forskellige modeller i samme session
function reset_model_variables()
    # Liste over alle variable der skal nulstilles
    vars_to_reset = [
        :model_type, :obj, :c, :x_navne, :nedre_grænse, :øvre_grænse,
        :A, :b, :b_dir, :b_navne, :x_type,
        :dec, :tol,
        :output_terminal, :output_fil,
        :output_base_sti, :output_mappe_navn, :output_mappe,
        :output_fil_navn,
        :M, :x, :constraints
    ]
    # Slet alle variable hvis de er defineret
    for var in vars_to_reset
            eval(Main, :(global $var = nothing))
    end
end


##########################################################
# Funktion til at konstruere directed graph og distance matrix fra shortest path skabelon
# Returnerer: G (SimpleDiGraph), DistanceMatrix, node_to_int, int_to_node
# Kræver: using Graphs (skal være inkluderet i filen der kalder funktionen)
function build_shortest_path_graph(noder, kanter)
    num_nodes = length(noder)
    G = SimpleDiGraph(num_nodes)  # Directed graph for shortest path
    
    # Mapping fra nodenavn til integer index (og omvendt)
    node_to_int = Dict(noder[i] => i for i in 1:num_nodes)
    int_to_node = Dict(i => noder[i] for i in 1:num_nodes)
    
    # Opret distance matrix (start med Inf)
    DistanceMatrix = fill(Inf, num_nodes, num_nodes)
    
    # Tilføj kanter til grafen og distance matrix
    for (from_node, to_node, weight, direction) in kanter
        i = node_to_int[from_node]
        j = node_to_int[to_node]
        
        if direction == "D"
            # Directed edge: kun én retning
            add_edge!(G, i, j)
            DistanceMatrix[i, j] = weight
        else
            # Undirected edge: begge retninger
            add_edge!(G, i, j)
            add_edge!(G, j, i)
            DistanceMatrix[i, j] = weight
            DistanceMatrix[j, i] = weight
        end
    end
    
    # Sæt diagonal til 0
    for i in 1:num_nodes
        DistanceMatrix[i, i] = 0
    end
    
    return G, DistanceMatrix, node_to_int, int_to_node
end


##########################################################
# Funktion til at konstruere undirected graph og distance matrix fra MST skabelon
# Returnerer: G (SimpleGraph), DistanceMatrix, node_to_int, int_to_node
# Kræver: using Graphs (skal være inkluderet i filen der kalder funktionen)
function build_MST_graph(noder, kanter)
    num_nodes = length(noder)
    G = SimpleGraph(num_nodes)  # Undirected graph for MST
    
    # Mapping fra nodenavn til integer index (og omvendt)
    node_to_int = Dict(noder[i] => i for i in 1:num_nodes)
    int_to_node = Dict(i => noder[i] for i in 1:num_nodes)
    
    # Opret distance matrix (start med Inf)
    DistanceMatrix = fill(Inf, num_nodes, num_nodes)
    
    # Tilføj kanter til grafen og distance matrix
    for (node1, node2, weight) in kanter
        i = node_to_int[node1]
        j = node_to_int[node2]
        
        # Undirected graph: tilføj edge og begge retninger i distance matrix
        add_edge!(G, i, j)
        DistanceMatrix[i, j] = weight
        DistanceMatrix[j, i] = weight  # Symmetric for undirected graph
    end
    
    # Sæt diagonal til 0
    for i in 1:num_nodes
        DistanceMatrix[i, i] = 0
    end
    
    return G, DistanceMatrix, node_to_int, int_to_node
end

