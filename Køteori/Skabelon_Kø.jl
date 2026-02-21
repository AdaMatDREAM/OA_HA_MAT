

function skabelon_kø()
    # ============================================================================
    # KØTEORI SYSTEM TYPE KONFIGURATION
    # ============================================================================
    # Systemet kan konfigureres til tre forskellige typer:
    #
    # 1. D/D/N (Deterministisk/Deterministisk/N servere):
    #    - sigma_a = 0 (ingen variabilitet i ankomsttider)
    #    - sigma_p = 0 (ingen variabilitet i service-tider)
    #    - Faste ankomst- og service-tider
    #    - Eksempel: sigma_a = 0.0, sigma_p = 0.0
    #
    # 2. M/M/N (Markovian/Markovian/N servere):
    #    - sigma_a = T_a (standardafvigelse = gennemsnit for inter-arrival tider)
    #    - sigma_p = T_p (standardafvigelse = gennemsnit for service-tider)
    #    - Eksponentielt fordelte ankomst- og service-tider
    #    - Eksempel: Hvis T_a = 0.0056 og T_p = 0.0133, så:
    #                sigma_a = 0.0056, sigma_p = 0.0133
    #    - Dette giver c_a = 1 og c_p = 1 (Poisson ankomst, eksponentiel service)
    #
    # 3. G/G/N (Generel/Generel/N servere):
    #    - Alt andet (hvilken som helst kombination af sigma_a og sigma_p)
    #    - Generelle fordelinger for ankomst- og service-tider
    #    - Eksempel: sigma_a = 0.01, sigma_p = 0.05 (nuværende konfiguration)
    #
    # BEMÆRK: Coefficient of variation beregnes som:
    #   - c_a = sigma_a * lambda
    #   - c_p = sigma_p * mu
    # ============================================================================
    
    # Hvis rate-parameter er TRUE, så har vi lambda og mu som input
    # Hvis rate-parameter er FALSE, så har vi T_a og T_p som input
    rate_parameter = true;
    lambda = 4; # Lambda er ankomst rate; antall som kommer per time(elrno)
    #mu = 75; # Mu er service rate; antall som kan serveres per time(elrno)
    T_a = 1/lambda;
    T_p = (12/60);
    mu = 1/T_p;
    
    # ============================================================================
    # SYSTEM TYPE KONFIGURATION - VÆLG EN AF FØLGENDE:
    # ============================================================================
    
    # D/D/N (Deterministisk):
    # sigma_a = 0.0;
    # sigma_p = 0.0;
    
    # M/M/N (Markovian):
    # sigma_a = T_a;  # For markovian: sigma_a skal være lig T_a
    # sigma_p = T_p;  # For markovian: sigma_p skal være lig T_p
    
    # G/G/N (Generel) - NUVÆRENDE KONFIGURATION:
    sigma_a = T_a; # Sigma_a er standardafvigelse/spredning for ankomst rate
    sigma_p = T_p; # Sigma_p er standardafvigelse/spredning for service rate
    
    N = 1; # N er antal servere
    
    # Antal decimaler i output
    dec = 4;
    
    # OUTPUT KONFIGURATION
    # Output af resultater i terminal eller fil
    output_terminal = true;
    output_fil = false;
    
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
    output_fil_navn = joinpath(output_mappe, "Køteori_beregninger.txt")
    
    # Returner som NamedTuple for bedre læsbarhed
    return (
        rate_parameter = rate_parameter,
        T_a = T_a,
        T_p = T_p,
        lambda = lambda,
        mu = mu,
        sigma_a = sigma_a,
        sigma_p = sigma_p,
        N = N,
        dec = dec,
        output_terminal = output_terminal,
        output_fil = output_fil,
        output_base_sti = output_base_sti,
        output_mappe_navn = output_mappe_navn,
        output_mappe = output_mappe,
        output_fil_navn = output_fil_navn
    )
end