function lager_problem_skabelon()
    # Type af model: MIP (pga. binære δ variabler)
    model_type = "MIP";
    dual_defined = false;
    
    # Objektiv MAX (maksimer profit)
    obj = :MAX;
    
    # ============================================
    # PARAMETRE - JUSTER DISSE EFTER BEHOV
    # ============================================
    
    # Antal perioder
    k = 5;  # Eksempel: 4 perioder
    
    # Efterspørgsel pr. periode (enheder) 
    d = [20, 10, 50, 10, 20]; # (længde k)
    
    # Pris pr. enhed pr. periode 
    p = [0, 0, 0, 0, 0]; # (længde k)
    
    # Variable omkostninger pr. enhed pr. periode 
    c_V = [70, 70, 70, 70, 70]; # (længde k)
    
    # Lager omkostninger pr. enhed pr. periode (inkl. i_0) (Variable lageromkostninger)
    # Bemærk: k+1 elementer (i_0 til i_k) 
    c_I = [10, 10, 10, 10, 10, 10]; # (længde k+1)
    
    # Faste lageromkostninger pr. periode (kun hvis der er lager i perioden) 
    # Bemærk: k+1 elementer (i_0 til i_k) (længde k+1)
    c_I_fixed = [0, 0, 0, 0, 0, 0];  # F.eks. 0 for i_0, ellers faste omkostninger
    
    # Faste omkostninger pr. periode (kun hvis produktion sker)
    c_F = [400, 400, 400, 400, 400]; # (længde k)
    
    # Lager parametre
    k_1 = 0;      # Startlager (i_0) - typisk 0
    k_2 = 0;      # Slutlager (i_k) - typisk 0
    # Maksimal lagerkapacitet pr. periode (vektor med k+1 elementer for i_0 til i_k)
    k_3 = [20, 20, 20, 20, 20, 20];  # F.eks. [20, 20, 20, 20, 20] eller forskellige værdier pr. periode
    
    # Big-M konstant (skal være større end maksimal mulig produktion)
    # Beregnes automatisk som sum af efterspørgsel + maksimal kapacitet
    M = sum(d) + k_2 + maximum(k_3);  # Eller sæt manuelt: M = 1000;
    
    # Maksimal produktion pr. periode (vektor med k elementer)
    # Sæt til nothing hvis der ikke er nogen grænse, ellers en vektor med maksimal produktion for hver periode
    #  F.eks. x_max = [1000, 1200, 800, 1000]; eller x_max = nothing; (ingen grænse)
    # x_max = nothing;  
    x_max = [40, 40, 40, 40, 40]; # (længde k)
    
    # Batch-størrelse for produktion (sæt til nothing hvis produktion kan være kontinuerlig)
    # Hvis batch_size er sat (fx 5), kan man kun producere 0, 5, 10, 15, 20 osv.
    # F.eks. batch_size = 5; eller batch_size = nothing; (ingen batch-begrænsning)
    batch_size = 5;  # Eller f.eks. batch_size = 5;
    
    # Indstilling for heltallighed af x_i
    x_integer = true;  # Sæt til false hvis x_i skal være kontinuerlig
    
    # ============================================
    # VALIDERING AF INPUT
    # ============================================
    if length(d) != k || length(p) != k || length(c_V) != k || length(c_F) != k
        error("Alle vektorer skal have længde k = $k")
    end
    if length(c_I) != k + 1
        error("c_I skal have længde k+1 = $(k+1) (inkl. i_0)")
    end
    if length(c_I_fixed) != k + 1
        error("c_I_fixed skal have længde k+1 = $(k+1) (inkl. i_0)")
    end
    if length(k_3) != k + 1
        error("k_3 skal have længde k+1 = $(k+1) (inkl. i_0)")
    end
    if x_max !== nothing && length(x_max) != k
        error("x_max skal have længde k = $k eller være nothing")
    end
    if batch_size !== nothing && batch_size <= 0
        error("batch_size skal være positiv eller nothing")
    end
    
    # ============================================
    # OPRET VARIABLER OG OBJEKTIVFUNKTION
    # ============================================
    # Variabelrækkefølge: [x_1, x_2, ..., x_k, i_0, i_1, ..., i_k, δ_1, δ_2, ..., δ_k, γ_0, γ_1, ..., γ_k, y_1, ..., y_k (hvis batch)]
    # Total: k + (k+1) + k + (k+1) + k (hvis batch) = 4k + 2 + k (hvis batch) variabler
    
    # Objektivkoefficienter
    # Objektiv: max -x^T·c_V - i^T·c_I - δ^T·c_F - γ^T·c_I_fixed
    # (d^T·p er konstant og udelades, men kan tilføjes til output)
    # Hvis batch_size er sat, tilføjes y variabler med koefficient 0 (de påvirker ikke objektivet direkte)
    if batch_size !== nothing
        c = vcat(
            -c_V,                    # -x^T·c_V (negativ fordi vi maksimerer)
            -c_I,                    # -i^T·c_I
            -c_F,                    # -δ^T·c_F
            -c_I_fixed,              # -γ^T·c_I_fixed (faste lageromkostninger)
            zeros(k)                 # y variabler (antal batches) - koefficient 0
        );
    else
        c = vcat(
            -c_V,                    # -x^T·c_V (negativ fordi vi maksimerer)
            -c_I,                    # -i^T·c_I
            -c_F,                    # -δ^T·c_F
            -c_I_fixed               # -γ^T·c_I_fixed (faste lageromkostninger)
        );
    end
    
    # Variabelnavne
    if batch_size !== nothing
        x_navne = vcat(
            ["x_$i" for i in 1:k],                    # Produktionsvariabler
            ["i_$i" for i in 0:k],                    # Lagervariabler
            ["delta_$i" for i in 1:k],               # Binære variabler for produktion
            ["gamma_$i" for i in 0:k],               # Binære variabler for lager
            ["y_$i" for i in 1:k]                    # Batch-variabler (antal batches)
        );
    else
        x_navne = vcat(
            ["x_$i" for i in 1:k],                    # Produktionsvariabler
            ["i_$i" for i in 0:k],                    # Lagervariabler
            ["delta_$i" for i in 1:k],               # Binære variabler for produktion
            ["gamma_$i" for i in 0:k]                # Binære variabler for lager
        );
    end
    
    # Fortegnskrav
    # x_i >= 0, i_t >= 0, δ_i >= 0, γ_t >= 0, y_i >= 0 (hvis batch) (binære håndteres i x_type)
    if batch_size !== nothing
        fortegn = vcat(
            fill(:>=, k),              # x variabler >= 0
            fill(:>=, k+1),             # i variabler >= 0
            fill(:>=, k),               # δ variabler >= 0
            fill(:>=, k+1),             # γ variabler >= 0
            fill(:>=, k)                # y variabler >= 0
        );
    else
        fortegn = vcat(
            fill(:>=, k),              # x variabler >= 0
            fill(:>=, k+1),             # i variabler >= 0
            fill(:>=, k),               # δ variabler >= 0
            fill(:>=, k+1)              # γ variabler >= 0
        );
    end
    
    # Beregn nedre og øvre grænser
    nedre_grænse = zeros(length(fortegn));
    øvre_grænse = zeros(length(fortegn));
    for i in eachindex(fortegn)
        if fortegn[i] == :R
            nedre_grænse[i] = -Inf;
            øvre_grænse[i] = Inf;
        elseif fortegn[i] == :>=
            nedre_grænse[i] = 0;
            øvre_grænse[i] = Inf;
        elseif fortegn[i] == :<=
            nedre_grænse[i] = -Inf;
            øvre_grænse[i] = 0;
        end
    end
    
    # Variabeltyper (MIP med binære δ og γ)
    if batch_size !== nothing
        # Hvis batch_size er sat, er y variablerne altid heltallige
        if x_integer
            x_type = vcat(
                fill(:Integer, k),       # x variabler er heltallige
                fill(:Continuous, k+1),  # i variabler er kontinuerte
                fill(:Binary, k),         # δ variabler er binære
                fill(:Binary, k+1),       # γ variabler er binære
                fill(:Integer, k)         # y variabler er heltallige (antal batches)
            );
        else
            x_type = vcat(
                fill(:Continuous, k),    # x variabler er kontinuerte
                fill(:Continuous, k+1),  # i variabler er kontinuerte
                fill(:Binary, k),        # δ variabler er binære
                fill(:Binary, k+1),      # γ variabler er binære
                fill(:Integer, k)        # y variabler er heltallige (antal batches)
            );
        end
    else
        if x_integer
            x_type = vcat(
                fill(:Integer, k),       # x variabler er heltallige
                fill(:Continuous, k+1),  # i variabler er kontinuerte
                fill(:Binary, k),         # δ variabler er binære
                fill(:Binary, k+1)       # γ variabler er binære
            );
        else
            x_type = vcat(
                fill(:Continuous, k),    # x variabler er kontinuerte
                fill(:Continuous, k+1),  # i variabler er kontinuerte
                fill(:Binary, k),        # δ variabler er binære
                fill(:Binary, k+1)       # γ variabler er binære
            );
        end
    end
    
    # ============================================
    # OPRET BEGRÆNSNINGER
    # ============================================
    # Total antal begrænsninger:
    #   k lagerligninger + 1 startlager + 1 slutlager + (k+1) kapacitet + k Big-M (produktion) + k produktion (hvis x_max sat) + (k+1) Big-M (lager) = 3k + 3 + k (hvis x_max) + (k+1)
    
    num_production_constraints = x_max !== nothing ? k : 0
    num_batch_constraints = batch_size !== nothing ? k : 0
    num_constraints = 3*k + 3 + num_production_constraints + (k+1) + num_batch_constraints;
    num_vars = batch_size !== nothing ? 4*k + 2 + k : 4*k + 2;  # k x'er + (k+1) i'er + k δ'er + (k+1) γ'er + k y'er (hvis batch)
    
    A = zeros(num_constraints, num_vars);
    b = zeros(num_constraints);
    b_dir = fill(:(==), num_constraints);  # Start med ligheder, ændres nedenfor
    b_navne = String[];
    
    constraint_idx = 1;
    
    # 1. Lagerligninger: x_i + i_{i-1} - i_i = d_i  (for i = 1, 2, ..., k)
    for i in 1:k
        # x_i er på position i-1 (1-indexed, så x_1 er på position 0, dvs. i)
        A[constraint_idx, i] = 1.0;
        # i_{i-1} er på position k + 1 + (i-1) (fordi i_0 er på position k+1)
        A[constraint_idx, k + 1 + (i-1)] = 1.0;
        # i_i er på position k + 1 + i
        A[constraint_idx, k + 1 + i] = -1.0;
        b[constraint_idx] = d[i];
        push!(b_navne, "Lager_balance_$i");
        constraint_idx += 1;
    end
    
    # 2. Startlager: i_0 = k_1
    A[constraint_idx, k + 1] = 1.0;  # i_0 er på position k+1
    b[constraint_idx] = k_1;
    push!(b_navne, "Startlager");
    constraint_idx += 1;
    
    # 3. Slutlager: i_k = k_2
    A[constraint_idx, k + 1 + k] = 1.0;  # i_k er på position k+1+k = 2k+1
    b[constraint_idx] = k_2;
    push!(b_navne, "Slutlager");
    constraint_idx += 1;
    
    # 4. Kapacitet: i_t <= k_3[t+1]  (for t = 0, 1, ..., k)
    for t in 0:k
        A[constraint_idx, k + 1 + t] = 1.0;
        b[constraint_idx] = k_3[t+1];  # k_3 er nu en vektor, så brug k_3[t+1] for periode t
        b_dir[constraint_idx] = :<=;
        push!(b_navne, "Kapacitet_$t");
        constraint_idx += 1;
    end
    
    # 5. Big-M: x_i - M·δ_i <= 0  (for i = 1, 2, ..., k)
    for i in 1:k
        A[constraint_idx, i] = 1.0;  # x_i
        # δ_i er på position 2*k + 1 + i (fordi vi har k x'er + (k+1) i'er først)
        A[constraint_idx, 2*k + 1 + i] = -M;  # -M·δ_i
        b[constraint_idx] = 0.0;
        b_dir[constraint_idx] = :<=;
        push!(b_navne, "BigM_$i");
        constraint_idx += 1;
    end
    
    # 6. Maksimal produktion: x_i <= x_max[i]  (for i = 1, 2, ..., k) - kun hvis x_max er sat
    if x_max !== nothing
        for i in 1:k
            A[constraint_idx, i] = 1.0;  # x_i
            b[constraint_idx] = x_max[i];
            b_dir[constraint_idx] = :<=;
            push!(b_navne, "Max_produktion_$i");
            constraint_idx += 1;
        end
    end
    
    # 7. Big-M for lager: i_t - M_lager·γ_t <= 0  (for t = 0, 1, ..., k)
    # Hvor M_lager = maximum(k_3) (maksimal lagerkapacitet)
    M_lager = maximum(k_3);
    for t in 0:k
        # i_t er på position k + 1 + t
        A[constraint_idx, k + 1 + t] = 1.0;  # i_t
        # γ_t er på position 3*k + 1 + 1 + t (fordi vi har k x'er + (k+1) i'er + k δ'er først)
        A[constraint_idx, 3*k + 1 + 1 + t] = -M_lager;  # -M_lager·γ_t
        b[constraint_idx] = 0.0;
        b_dir[constraint_idx] = :<=;
        push!(b_navne, "BigM_lager_$t");
        constraint_idx += 1;
    end
    
    # 8. Batch-begrænsninger: x_i - batch_size·y_i = 0  (for i = 1, 2, ..., k) - kun hvis batch_size er sat
    if batch_size !== nothing
        for i in 1:k
            # x_i er på position i
            A[constraint_idx, i] = 1.0;  # x_i
            # y_i er på position 4*k + 2 + i (fordi vi har k x'er + (k+1) i'er + k δ'er + (k+1) γ'er først)
            A[constraint_idx, 4*k + 2 + i] = -batch_size;  # -batch_size·y_i
            b[constraint_idx] = 0.0;
            b_dir[constraint_idx] = :(==);
            push!(b_navne, "Batch_$i");
            constraint_idx += 1;
        end
    end
    
    # ============================================
    # OUTPUT KONFIGURATION
    # ============================================
    dec = 2;
    tol = 1e-9;
    output_terminal = false;
    output_fil = true;
    output_base_sti = "";
    output_mappe_navn = "Output";
    
    if output_base_sti == ""
        output_mappe = joinpath(@__DIR__, output_mappe_navn);
    else
        output_mappe = joinpath(output_base_sti, output_mappe_navn);
    end
    
    if !isdir(output_mappe)
        mkpath(output_mappe);
    end
    
    output_fil_navn = joinpath(output_mappe, "Lager_problem.txt");
    output_fil_navn_D = joinpath(output_mappe, "Lager_problem_Dual.txt");
    
    # Gem også parametre til brug i output (for at kunne beregne total omsætning)
    return (
        model_type = model_type,
        dual_defined = dual_defined,
        obj = obj,
        c = c,
        x_navne = x_navne,
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
        output_fil_navn_D = output_fil_navn_D,
        # Ekstra parametre for lagerproblemet
        k = k,
        d = d,
        p = p,
        c_V = c_V,
        c_I = c_I,
        c_F = c_F,
        k_1 = k_1,
        k_2 = k_2,
        k_3 = k_3,
        M = M,
        x_max = x_max,
        c_I_fixed = c_I_fixed,
        batch_size = batch_size
    );
end
