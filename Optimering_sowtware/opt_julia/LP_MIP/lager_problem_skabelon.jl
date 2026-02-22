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
    k = 4;  # Eksempel: 4 perioder
    
    # Efterspørgsel pr. periode (enheder)
    d = [500, 600, 300, 400];
    
    # Pris pr. enhed pr. periode
    p = [750, 750, 750, 750];
    
    # Variable omkostninger pr. enhed pr. periode
    c_V = [350, 350, 350, 350];
    
    # Lager omkostninger pr. enhed pr. periode (inkl. i_0)
    # Bemærk: k+1 elementer (i_0 til i_k)
    c_I = [200, 200, 200, 200, 200];
    
    # Faste omkostninger pr. periode (kun hvis produktion sker)
    c_F = [150000, 150000, 150000, 150000];
    
    # Lager parametre
    k_1 = 0;      # Startlager (i_0) - typisk 0
    k_2 = 0;      # Slutlager (i_k) - typisk 0
    k_3 = 800;    # Maksimal lagerkapacitet
    
    # Big-M konstant (skal være større end maksimal mulig produktion)
    # Beregnes automatisk som sum af efterspørgsel + maksimal kapacitet
    M = sum(d) + k_2 + k_3;  # Eller sæt manuelt: M = 1000;
    
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
    
    # ============================================
    # OPRET VARIABLER OG OBJEKTIVFUNKTION
    # ============================================
    # Variabelrækkefølge: [x_1, x_2, ..., x_k, i_0, i_1, ..., i_k, δ_1, δ_2, ..., δ_k]
    # Total: k + (k+1) + k = 3k + 1 variabler
    
    # Objektivkoefficienter
    # Objektiv: max -x^T·c_V - i^T·c_I - δ^T·c_F
    # (d^T·p er konstant og udelades, men kan tilføjes til output)
    c = vcat(
        -c_V,                    # -x^T·c_V (negativ fordi vi maksimerer)
        -c_I,                    # -i^T·c_I
        -c_F                     # -δ^T·c_F
    );
    
    # Variabelnavne
    x_navne = vcat(
        ["x_$i" for i in 1:k],                    # Produktionsvariabler
        ["i_$i" for i in 0:k],                    # Lagervariabler
        ["delta_$i" for i in 1:k]                 # Binære variabler
    );
    
    # Fortegnskrav
    # x_i >= 0, i_t >= 0, δ_i >= 0 (binære håndteres i x_type)
    fortegn = vcat(
        fill(:>=, k),              # x variabler >= 0
        fill(:>=, k+1),             # i variabler >= 0
        fill(:>=, k)                # δ variabler >= 0
    );
    
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
    
    # Variabeltyper (MIP med binære δ)
    if x_integer
        x_type = vcat(
            fill(:Integer, k),      # x variabler er heltallige
            fill(:Continuous, k+1),  # i variabler er kontinuerte
            fill(:Binary, k)         # δ variabler er binære
        );
    else
        x_type = vcat(
            fill(:Continuous, k),    # x variabler er kontinuerte
            fill(:Continuous, k+1),  # i variabler er kontinuerte
            fill(:Binary, k)         # δ variabler er binære
        );
    end
    
    # ============================================
    # OPRET BEGRÆNSNINGER
    # ============================================
    # Total antal begrænsninger:
    #   k lagerligninger + 1 startlager + 1 slutlager + (k+1) kapacitet + k Big-M = 3k + 3
    
    num_constraints = 3*k + 3;
    num_vars = 3*k + 1;  # k x'er + (k+1) i'er + k δ'er
    
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
    
    # 4. Kapacitet: i_t <= k_3  (for t = 0, 1, ..., k)
    for t in 0:k
        A[constraint_idx, k + 1 + t] = 1.0;
        b[constraint_idx] = k_3;
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
        M = M
    );
end
