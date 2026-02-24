function simplex_skabelon()

    # Objektivcoefficienter og variabelnavne
    c = [30, 20];
    x_navne = ["x_1", "x_2"];
    
    # Begr??nsningskoefficienter og kapaciteter
    A = [2     1;
         1     2;
         1     1];
    
    # Husk at alle b_dir er <=
    b = [8,   8,  5];
    b_navne = ["Arbejdstimer", "Maskintimer", "Gomory"];
    
    # Danner slackvariable
    # S_navne = ["S_1", "S_2", "S_3"];
    S_navne = ["S_$(i)" for i in 1:length(b)];
    
    # Output konfiguration
    output_terminal = false;
    output_fil = true;
    print_tableaux_iterationer = true;
    output_base_sti = ""  # tom streng -> samme mappe som koden
    output_mappe_navn = "Output"
    if output_base_sti == ""
        output_mappe = joinpath(@__DIR__, output_mappe_navn)
    else
        output_mappe = joinpath(output_base_sti, output_mappe_navn)
    end
    if !isdir(output_mappe)
        mkpath(output_mappe)
    end
    output_fil_navn = joinpath(output_mappe, "simplex.txt")
    return (
        c = c, 
        x_navne = x_navne, 
        A = A, 
        b = b, 
        b_navne = b_navne,
        S_navne = S_navne,
        output_fil = output_fil,
        output_terminal = output_terminal,
        print_tableaux_iterationer = print_tableaux_iterationer,
        output_base_sti = output_base_sti,
        output_mappe_navn = output_mappe_navn,
        output_mappe = output_mappe,
        output_fil_navn = output_fil_navn
        )
    end
    
    ##########################################################
    