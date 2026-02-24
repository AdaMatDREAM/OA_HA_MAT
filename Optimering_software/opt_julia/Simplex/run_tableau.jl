using HiGHS, JuMP;
using Printf

include("Primal_Dual_simplex_alg.jl")
include("Print_tableau.jl")

println("="^100)
println("SIMPLEX FRA TABLEAU")
println("="^100)

# ============================================================================
# OPSÆT DIT TABLEAU HER
# ============================================================================
#
# TABLEAU STRUKTUR:
# T skal være en matrix med følgende struktur:
#   [A  I  b]
#   [-c' 0 0]
#
# Hvor:
#   - A: Begrænsningskoefficienter (m x n matrix)
#   - I: Identitetsmatrix for slack variable (m x m)
#   - b: Højreside værdier (m x 1 kolonne)
#   - -c': Objektivkoefficienter med MINUS fortegn (1 x n række)
#   - Sidste række skal have 0 i b-kolonnen
#
# EKSEMPEL:
# Hvis du har problemet:
#   Max Z = 7x_1 - x_2
#   s.t.  10x_1 - 2x_2 <= 20
#          0x_1 + 2x_2 <= 13
#          2x_1 + 2x_2 <= 15
#
# Så bliver tableauet:
#   Basis | x_1  x_2  S_1  S_2  S_3  |  b
#   ------|--------------------------|----
#   S_1   | 10   -2    1    0    0  | 20
#   S_2   |  0    2    0    1    0  | 13
#   S_3   |  2    2    0    0    1  | 15
#   Z     | -7    1    0    0    0  |  0
#
# ============================================================================

# T: Matrix med tableau værdier
# Format: [række1; række2; række3; ...; z-række]
T = [1  0  0.08  0  0.08  0  2.92;
     0  0  0.17  1 -0.83  0  3.83;
     0  1 -0.08  0  0.42  0  4.58;
     0  0  -0.08 0 -0.08  1 -0.92;
     0  0   0.67 0  0.17  0 15.83];

# x_S_navne: Navne på alle kolonner (strukturelle variable, slack variable, "b")
# Format: [strukturelle variable, slack variable, "b"]
# Antal kolonner skal matche antal kolonner i T (inkl. b-kolonne)
x_S_navne = ["x_1", "x_2", "S_1", "S_2", "S_3", "S_4", "b"]

# basis_navne: Navne på basis variabler (en for hver række + "Z" til sidst)
# Format: [basis variabel for række 1, række 2, ..., "Z"]
# Antal elementer skal matche antal rækker i T
basis_navne = ["x_1", "S_2", "x_2", "S_4", "Z"]

# ============================================================================
# OUTPUT KONFIGURATION
# ============================================================================

# Skal tableauer printes under iterationer?
print_tableaux_iterationer = true

# Antal decimaler i output
dec = 2

# Output af resultater i terminal eller fil
output_terminal = true
output_fil = true

# Output mappe konfiguration
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
output_fil_navn = joinpath(output_mappe, "tableau_resultat.txt")

# ============================================================================
# KØR SIMPLEX ALGORITMEN
# ============================================================================

# Opret tableau struktur
P_tableau = (
    T = T,
    x_S_navne = x_S_navne,
    basis_navne = basis_navne
)

# Kør simplex algoritmen
if output_terminal
    println("\nStarter simplex algoritme...\n")
    P_tableau = simplex_solve(P_tableau; print_tableaux_iterationer=print_tableaux_iterationer)
    
    # Vis optimal løsning
    println("\n" * "="^100)
    println("OPTIMAL LØSNING")
    println("="^100)
    
    result = optimal_tableau(P_tableau)
    
    # Brug samme output-funktion som run_simplex.jl
    print_optimal_solution_simplex(result, P_tableau.x_S_navne, dec)
    
    println("="^100)
end

if output_fil
    # Skriv til fil
    open(output_fil_navn, "w") do file
        redirect_stdout(file) do
            println("="^100)
            println("SIMPLEX FRA TABLEAU")
            println("="^100)
            
            # Genberegn tableau for fil output (deep copy)
            P_tableau_fil = (
                T = copy(T),
                x_S_navne = x_S_navne,
                basis_navne = copy(basis_navne)
            )
            
            println("\nStarter simplex algoritme...\n")
            P_tableau_fil = simplex_solve(P_tableau_fil; print_tableaux_iterationer=print_tableaux_iterationer)
            
            # Vis optimal løsning
            println("\n" * "="^100)
            println("OPTIMAL LØSNING")
            println("="^100)
            
            result = optimal_tableau(P_tableau_fil)
            
            # Brug samme output-funktion som run_simplex.jl
            print_optimal_solution_simplex(result, P_tableau_fil.x_S_navne, dec)
            
            println("="^100)
        end
    end
    println("Output er gemt i .txt filen: ", output_fil_navn)
end
