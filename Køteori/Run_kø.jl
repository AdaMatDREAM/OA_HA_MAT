using Printf

# Includefiler til funktioner
include("Funktioner.jl")
include("Print.jl")
include("Skabelon_Kø.jl")

# Indlæs konfigurationen og indstillinger
# Syntax P.[variabelnavn]
P = skabelon_kø()

# Beregn og print køteori beregninger baseret på rate_parameter
if P.rate_parameter
    # Brug lambda og mu direkte
    print_queue_table(P.lambda, P.mu, P.sigma_a, P.sigma_p, P.N, P.dec,
                      P.output_terminal, P.output_fil, P.output_fil_navn)
else
    print_queue_table_T(P.T_a, P.T_p, P.sigma_a, P.sigma_p, P.N, P.dec,
                        P.output_terminal, P.output_fil, P.output_fil_navn)
end
