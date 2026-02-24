function Assignment_problem_skabelon()
    # Type af model: LP eller MIP
    model_type = "MIP";
    # True hvis du også vil have dualt program
    dual_defined = false;
    
    # Da vi kigger på assignment problemet, er opbjektivet et minimiere omkostninger (minimeringsproblem).
    obj = :MIN; 
    
    # Omkostningsmatrix (n×n)
    c_matrix = [12  14  9   13  10;
                11  13  15  17  13;
                9   15  9   14  12;
                10  12  11  13  14;
                13  10  15  10  16];
    m, n = size(c_matrix);
    m != n ? error("c_matrix skal være en kvadratisk matrix") : nothing;

    # Flatten omkostningsmatrixen til vektor (row-major order)
    # c skal matche rækkefølgen i x_navne: x_A_A, x_A_B, x_A_C, x_A_D, x_B_A, ...
    # x_navne er konstrueret som: x_worker_i_task_j for i=1..m, j=1..n
    # c_matrix[i, j] skal svare til omkostningen for worker i → task j
    # c_matrix er givet med workers som rækker og tasks som kolonner
    c = vec(c_matrix');  # Flatten matrixen (row-major: række 1, række 2, ...)
    
    # Navne på workers og tasks
    supply_navne = ["J", "K", "H", "MA", "MI"]; # Søjle
    demand_navne = ["1", "2", "3", "4", "5"]; # Række

    # Opret variabelnavne som vektor (samme rækkefølge som c)
    x_navne = [string("x_", supply_navne[i], "_", demand_navne[j]) for i in 1:m for j in 1:n];
    
    # Konstruer A-matrixen for assignment problemet
    # Første m rækker: hver worker får præcis én opgave (Σ_j x_ij = 1)
    # Næste n rækker: hver opgave får præcis én worker (Σ_i x_ij = 1)
    A = zeros(2*n, n*n);
    
    # Første n rækker: hver worker (i) får præcis én opgave
    for i in 1:n
        for j in 1:n
            # Variabel x_ij er på position (i-1)*n + j i vektoren
            A[i, (i-1)*n + j] = 1.0;
        end
    end
    
    # Næste n rækker: hver opgave (j) får præcis én worker
    for j in 1:n
        for i in 1:n
            # Variabel x_ij er på position (i-1)*n + j i vektoren
            A[n + j, (i-1)*n + j] = 1.0;
        end
    end
    
    # Højreside: alle begrænsninger er lig 1
    b = ones(2*n);

    # Retningen af begrænsningerne: alle er ligheder (==)
    b_dir = fill(:(==), 2*n);
    
    # Navne på begrænsninger
    b_navne = vcat(
        [string("Worker_", supply_navne[i]) for i in 1:n],
        [string("Task_", demand_navne[j]) for j in 1:n]
    );
    
    # Variabeltyper: alle er binary (0 eller 1)
    x_type = fill(:Binary, n*n);
    
    # Fortegnskrav: alle variable er >= 0 (binary variabler er automatisk >= 0)
    fortegn = fill(:>=, n*n);
    nedre_grænse = zeros(n*n);
    øvre_grænse = fill(Inf, n*n);
    
    # Antal decimaler i output og tolerance for 0-værdier
    dec = 2;
    tol = 1e-9;
    
    # Output af resultater i terminal eller fil
    output_terminal = false;
    output_fil = true;
    
    # Output mappe konfiguration
    # Du kan enten bruge en absolut sti eller en relativ sti
    # Hvis output_base_sti er tom (""), bruges samme mappe som koden
    output_base_sti = ""  # F.eks. "" for samme mappe, eller "C:\\Users\\Adam\\Documents" for absolut sti
    output_mappe_navn = "Output"  # Navn på output-mappen
    
    # Byg output mappe sti
    if output_base_sti == ""
        # Brug samme mappe som koden
        output_mappe = joinpath(@__DIR__, output_mappe_navn)
    else
        # Brug brugerdefineret sti
        output_mappe = joinpath(output_base_sti, output_mappe_navn)
    end
    
    # Opret output mappe hvis den ikke eksisterer
    if !isdir(output_mappe)
        mkpath(output_mappe)
    end
    
    # Filnavn til output (defineres altid)
    output_fil_navn = joinpath(output_mappe, "Assignment_problem.txt")
    output_fil_navn_D = joinpath(output_mappe, "Output_LP_MIP_Dual.txt") # benyttes ikke i virkeligheden, da dual problemet ikke er defineret
    
    # Returner som NamedTuple for bedre læsbarhed
    return (
        model_type = model_type,
        dual_defined = dual_defined,
        obj = obj,
        c = c,
        x_navne = x_navne,
        supply_navne = supply_navne,
        demand_navne = demand_navne,
        fortegn = fortegn,
        nedre_grænse = nedre_grænse,
        øvre_grænse = øvre_grænse,
        A = A,
        b = b,
        b_dir = b_dir,
        b_navne = b_navne,
        x_type = x_type,
        dec = dec,
        tol = tol,
        output_terminal = output_terminal,
        output_fil = output_fil,
        output_base_sti = output_base_sti,
        output_mappe_navn = output_mappe_navn,
        output_mappe = output_mappe,
        output_fil_navn = output_fil_navn,
        output_fil_navn_D = output_fil_navn_D
    )
    end