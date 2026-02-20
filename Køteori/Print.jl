using Printf

# Hjælpefunktion til at printe forklarende tekst
function _print_explanation(io)
    println(io, "FORKLARING AF BEREGNEDE VÆRDIER:")
    println(io, "-"^80)
    println(io)
    println(io, "• Arrival_rate (lambda):")
    println(io, "  Gennemsnitlig antal kunder/opgaver der ankommer per tidsenhed.")
    println(io, "  Højere lambda betyder mere trafik til systemet.")
    println(io)
    println(io, "• Processing_rate (mu):")
    println(io, "  Gennemsnitlig antal kunder/opgaver der kan betjenes per tidsenhed per server.")
    println(io, "  Højere mu betyder hurtigere service.")
    println(io)
    println(io, "• Utilization (rho):")
    println(io, "  Systemets udnyttelsesgrad: rho = lambda / (N * mu).")
    println(io, "  - rho < 1: Systemet kan håndtere ankomsten (stabil tilstand)")
    println(io, "  - rho = 1: Systemet er præcis i balance (meget følsomt)")
    println(io, "  - rho > 1: Systemet kan ikke følge med (ustabil, kø vokser)")
    println(io, "  Når rho nærmer sig 1, vokser ventetiderne eksponentielt.")
    println(io)
    println(io, "• Coefficient_of_variation_arrival (c_a):")
    println(io, "  Måler variabiliteten i ankomsttiderne.")
    println(io, "  - c_a = 0: Perfekt regelmæssige ankomster")
    println(io, "  - c_a = 1: Poisson-ankomster (tilfældige)")
    println(io, "  - c_a > 1: Høj variabilitet (bursty trafik)")
    println(io, "  Højere variabilitet øger ventetiderne.")
    println(io)
    println(io, "• Coefficient_of_variation_processing (c_p):")
    println(io, "  Måler variabiliteten i service-tiderne.")
    println(io, "  - c_p = 0: Faste service-tider")
    println(io, "  - c_p = 1: Eksponentielt fordelte service-tider")
    println(io, "  - c_p > 1: Høj variabilitet i service")
    println(io, "  Højere variabilitet øger ventetiderne.")
    println(io)
    println(io, "• Average_queing_time (A_Q_time):")
    println(io, "  Forventet tid en kunde/opgave venter i køen før betjening starter.")
    println(io, "  Beregnet ved hjælp af Kingman's formel (eller udvidet formel for multi-server).")
    println(io, "  Denne værdi vokser kraftigt når utilization (rho) nærmer sig 1.")
    println(io)
    println(io, "• Average_lead_time (A_L_time):")
    println(io, "  Forventet total tid en kunde/opgave er i systemet (ventetid + service tid).")
    println(io, "  A_L_time = A_Q_time + 1/mu")
    println(io, "  Dette er den samlede 'lead time' fra ankomst til afgang.")
    println(io)
    println(io, "• Inventory_processing (I_processing):")
    println(io, "  Forventet antal kunder/opgaver der er i betjening (ikke i kø).")
    println(io, "  I_processing = rho * N")
    println(io, "  Dette er antallet af aktive servere i gennemsnit.")
    println(io)
    println(io, "• Average_length_of_queue (A_L_queue):")
    println(io, "  Forventet antal kunder/opgaver i køen (venter på betjening).")
    println(io, "  A_L_queue = lambda * A_Q_time (Little's Law)")
    println(io, "  Højere værdi betyder længere køer.")
    println(io)
    println(io, "• Total_inventory (T_inventory):")
    println(io, "  Forventet totalt antal kunder/opgaver i systemet (kø + betjening).")
    println(io, "  T_inventory = lambda * A_L_time (Little's Law)")
    println(io, "  Dette er det samlede 'work-in-progress' i systemet.")
    println(io)
    println(io, "PRAKTISKE IMPLIKATIONER:")
    println(io, "-"^80)
    println(io)
    println(io, "• Hvis utilization (rho) er tæt på 1, er systemet meget følsomt for")
    println(io, "  små ændringer i ankomst eller service rate. Små stigninger i")
    println(io, "  ankomst kan føre til dramatiske stigninger i ventetider.")
    println(io)
    println(io, "• For at reducere ventetider kan man:")
    println(io, "  - Øge antal servere (N)")
    println(io, "  - Øge service rate (mu) - hurtigere betjening")
    println(io, "  - Reducere variabilitet (c_a og c_p) - mere forudsigelige processer")
    println(io)
    println(io, "• Økonomiske overvejelser:")
    println(io, "  - Højere kapacitet (flere servere) reducerer ventetider men øger omkostninger")
    println(io, "  - Længere ventetider kan føre til:")
    println(io, "    * Tabt goodwill (utilfredse kunder)")
    println(io, "    * Abandoned calls/opgaver (kunder der opgiver)")
    println(io, "    * Tabt omsætning")
    println(io, "  - Optimal løsning findes ved at balancere kapacitetsomkostninger mod")
    println(io, "    omkostningerne ved ventetid.")
    println(io)
    println(io, "="^80)
    println(io)
end

# Hjælpefunktion til at printe tabel til en IO stream (terminal eller fil)
function _print_queue_table_content(io, lambda, mu, sigma_a, sigma_p, N, dec)
    # Beregn alle mellemværdier
    T_a = 1/lambda
    T_p = 1/mu
    
    # Beregn funktionerne i rækkefølge
    arrival_rate = Arrival_rate(T_a)
    processing_rate = Processing_rate(T_p)
    utilization = Utilization(lambda, mu, N)
    c_a = Coefficient_of_variation_arrival(lambda, sigma_a)
    c_p = Coefficient_of_variation_processing(mu, sigma_p)
    rho = utilization  # Samme som utilization
    avg_queuing_time = Average_queing_time(c_a, c_p, rho, N, mu)
    avg_lead_time = Average_lead_time(avg_queuing_time, mu)
    inventory_processing = Inventory_processing(rho, N)
    avg_length_of_queue = Average_length_of_queue(lambda, avg_queuing_time)
    total_inventory = Total_inventory(lambda, avg_queuing_time, mu)
    
    # Print tabel header
    println(io, "\n" * "="^80)
    println(io, "KØTEORI BEREGNINGER")
    println(io, "="^80)
    println(io, "\nInput parametre:")
    # Brug samme bredde (50 tegn) så lighedstegnene står på linje med beregnede værdier
    @printf(io, "  %-48s = %.*f\n", "lambda (ankomst rate)", dec, lambda)
    @printf(io, "  %-48s = %.*f\n", "mu (service rate)", dec, mu)
    @printf(io, "  %-48s = %.*f\n", "sigma_a (std. ankomst)", dec, sigma_a)
    @printf(io, "  %-48s = %.*f\n", "sigma_p (std. service)", dec, sigma_p)
    @printf(io, "  %-48s = %d\n", "N (antal servere)", N)
    println(io, "\n" * "-"^80)
    println(io, "Beregnede værdier (i rækkefølge):")
    println(io, "-"^80)
    
    # Print alle værdier i rækkefølge
    @printf(io, "%-50s = %.*f\n", "Arrival_rate (lambda)", dec, arrival_rate)
    @printf(io, "%-50s = %.*f\n", "Processing_rate (mu)", dec, processing_rate)
    @printf(io, "%-50s = %.*f\n", "Utilization (rho)", dec, utilization)
    @printf(io, "%-50s = %.*f\n", "Coefficient_of_variation_arrival (c_a)", dec, c_a)
    @printf(io, "%-50s = %.*f\n", "Coefficient_of_variation_processing (c_p)", dec, c_p)
    @printf(io, "%-50s = %.*f\n", "Average_queing_time (A_Q_time)", dec, avg_queuing_time)
    @printf(io, "%-50s = %.*f\n", "Average_lead_time (A_L_time)", dec, avg_lead_time)
    @printf(io, "%-50s = %.*f\n", "Inventory_processing (I_processing)", dec, inventory_processing)
    @printf(io, "%-50s = %.*f\n", "Average_length_of_queue (A_L_queue)", dec, avg_length_of_queue)
    @printf(io, "%-50s = %.*f\n", "Total_inventory (T_inventory)", dec, total_inventory)
    
    println(io, "="^80)
    println(io)
    
    # Print forklarende tekst
    _print_explanation(io)
end

# Funktion til at printe tabel med alle køteori beregninger
function print_queue_table(lambda, mu, sigma_a, sigma_p, N, dec=4, output_terminal=true, output_fil=false, output_fil_navn="")
    # Print til terminal hvis aktiveret
    if output_terminal
        _print_queue_table_content(stdout, lambda, mu, sigma_a, sigma_p, N, dec)
    end
    
    # Print til fil hvis aktiveret
    if output_fil
        if output_fil_navn == ""
            error("output_fil_navn skal være angivet når output_fil er true")
        end
        open(output_fil_navn, "w") do file
            _print_queue_table_content(file, lambda, mu, sigma_a, sigma_p, N, dec)
        end
        println("Output er gemt i .txt filen: ", output_fil_navn)
    end
end

# Hjælpefunktion til at printe tabel til en IO stream (terminal eller fil) - med T_a og T_p
function _print_queue_table_T_content(io, T_a, T_p, sigma_a, sigma_p, N, dec)
    # Beregn lambda og mu fra T_a og T_p
    lambda = 1/T_a
    mu = 1/T_p
    
    # Beregn funktionerne i rækkefølge
    arrival_rate = Arrival_rate(T_a)
    processing_rate = Processing_rate(T_p)
    utilization = Utilization(lambda, mu, N)
    c_a = Coefficient_of_variation_arrival(lambda, sigma_a)
    c_p = Coefficient_of_variation_processing(mu, sigma_p)
    rho = utilization  # Samme som utilization
    avg_queuing_time = Average_queing_time(c_a, c_p, rho, N, mu)
    avg_lead_time = Average_lead_time(avg_queuing_time, mu)
    inventory_processing = Inventory_processing(rho, N)
    avg_length_of_queue = Average_length_of_queue(lambda, avg_queuing_time)
    total_inventory = Total_inventory(lambda, avg_queuing_time, mu)
    
    # Print tabel header
    println(io, "\n" * "="^80)
    println(io, "KØTEORI BEREGNINGER")
    println(io, "="^80)
    println(io, "\nInput parametre:")
    # Brug samme bredde (50 tegn) så lighedstegnene står på linje med beregnede værdier
    @printf(io, "  %-48s = %.*f\n", "T_a (gennemsnitlig ankomst tid)", dec, T_a)
    @printf(io, "  %-48s = %.*f\n", "T_p (gennemsnitlig service tid)", dec, T_p)
    @printf(io, "  %-48s = %.*f\n", "sigma_a (std. ankomst)", dec, sigma_a)
    @printf(io, "  %-48s = %.*f\n", "sigma_p (std. service)", dec, sigma_p)
    @printf(io, "  %-48s = %d\n", "N (antal servere)", N)
    println(io, "\nBeregnet fra input:")
    @printf(io, "  %-48s = %.*f\n", "lambda (ankomst rate) = 1/T_a", dec, lambda)
    @printf(io, "  %-48s = %.*f\n", "mu (service rate) = 1/T_p", dec, mu)
    println(io, "\n" * "-"^80)
    println(io, "Beregnede værdier (i rækkefølge):")
    println(io, "-"^80)
    
    # Print alle værdier i rækkefølge
    @printf(io, "%-50s = %.*f\n", "Arrival_rate (lambda)", dec, arrival_rate)
    @printf(io, "%-50s = %.*f\n", "Processing_rate (mu)", dec, processing_rate)
    @printf(io, "%-50s = %.*f\n", "Utilization (rho)", dec, utilization)
    @printf(io, "%-50s = %.*f\n", "Coefficient_of_variation_arrival (c_a)", dec, c_a)
    @printf(io, "%-50s = %.*f\n", "Coefficient_of_variation_processing (c_p)", dec, c_p)
    @printf(io, "%-50s = %.*f\n", "Average_queing_time (A_Q_time)", dec, avg_queuing_time)
    @printf(io, "%-50s = %.*f\n", "Average_lead_time (A_L_time)", dec, avg_lead_time)
    @printf(io, "%-50s = %.*f\n", "Inventory_processing (I_processing)", dec, inventory_processing)
    @printf(io, "%-50s = %.*f\n", "Average_length_of_queue (A_L_queue)", dec, avg_length_of_queue)
    @printf(io, "%-50s = %.*f\n", "Total_inventory (T_inventory)", dec, total_inventory)
    
    println(io, "="^80)
    println(io)
    
    # Print forklarende tekst
    _print_explanation(io)
end

# Funktion til at printe tabel med alle køteori beregninger (med T_a og T_p som input)
function print_queue_table_T(T_a, T_p, sigma_a, sigma_p, N, dec=4, output_terminal=true, output_fil=false, output_fil_navn="")
    # Print til terminal hvis aktiveret
    if output_terminal
        _print_queue_table_T_content(stdout, T_a, T_p, sigma_a, sigma_p, N, dec)
    end
    
    # Print til fil hvis aktiveret
    if output_fil
        if output_fil_navn == ""
            error("output_fil_navn skal være angivet når output_fil er true")
        end
        open(output_fil_navn, "w") do file
            _print_queue_table_T_content(file, T_a, T_p, sigma_a, sigma_p, N, dec)
        end
        println("Output er gemt i .txt filen: ", output_fil_navn)
    end
end
