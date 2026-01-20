function simplex_skabelon()

    # Objektivcoefficienter og variabelnavne
    c = [4, 2, 5];
    x_navne = ["x_1", "x_2", "x_3"];
    
    # Begr??nsningskoefficienter og kapaciteter
    A = [5 4 3;
         -2 -1 -3;
         2 1 3];
    
    b = [11, -8, 8];
    
    # Danner slackvariable
    # S_navne = ["S_1", "S_2", "S_3"];
    S_navne = ["S_$(i)" for i in 1:length(b)];
    
    # LaTeX output konfiguration
    output_latex = true;
    output_terminal = true;
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
    output_latex_navn = joinpath(output_mappe, "simplex_u1_o4_b.tex")
    return (
        c = c, 
        x_navne = x_navne, 
        A = A, 
        b = b, 
        S_navne = S_navne,
        output_latex = output_latex,
        output_terminal = output_terminal,
        output_base_sti = output_base_sti,
        output_mappe_navn = output_mappe_navn,
        output_mappe = output_mappe,
        output_latex_navn = output_latex_navn
        )
    end
    
    ##########################################################
    