# OA_HA_MAT – Operationsanalyse (Julia)

Dette repository indeholder Julia-kode til køteori og lineær/heltallig optimering (simplex, LP/MIP, netværksproblemer m.m.). Materialet er til brug ved undervisning og eksamen i operationsanalyse. Nedenfor beskrives den overordnede struktur og hvordan man bruger Julia-programmet.

**Kom i gang:** (1) Installer Julia og de nødvendige pakker (se afsnit 7). (2) Åbn den skabelon der passer til din opgave (køteori, simplex, LP/MIP eller et netværksproblem). (3) Indtast dine data og kør den tilhørende run-fil fra den mappe hvor filen ligger. Se dine resultater i en af de tilhørende output mapper eller i terminalen.

**Indholdsfortegnelse:** [1. Overordnet struktur](#1-overordnet-struktur) · [2. Køteori](#2-køteori) · [3. Simplex](#3-simplex) · [4. LP og MIP](#4-lp-og-mip-generel-optimering) · [5. Netværks- og flow-problemer](#5-netværks--og-flow-problemer) · [6. Øvrige filer](#6-øvrige-filer) · [7. Krav og kørsel](#7-krav-og-kørsel) · [8. Hurtig oversigt](#8-hurtig-oversigt) · [9. Forklaring af filer](#9-forklaring-af-filer)

---

## 1. Overordnet struktur

```
OA_HA_MAT/
├── Køteori/
│   ├── Run_kø.jl
│   ├── Skabelon_Kø.jl
│   ├── Funktioner.jl
│   ├── Print.jl
│   └── Output/
│
└── Optimering_sowtware/
    └── opt_julia/
        ├── Simplex/
        │   ├── run_simplex.jl
        │   ├── run_tableau.jl
        │   ├── Skabelon_simplex.jl
        │   ├── Primal_Dual_simplex_alg.jl
        │   ├── Print_tableau.jl
        │   └── Output/
        │
        ├── LP_MIP/
        │   ├── run_LP_MIP.jl
        │   ├── run_convert_dual.jl
        │   ├── skabelon_LP_MIP.jl
        │   ├── build.jl
        │   ├── print.jl
        │   ├── convert_dual.jl
        │   ├── max_flow_skabelon.jl / run_max_flow.jl
        │   ├── min_cost_flow_skabelon.jl / run_min_cost_flow.jl
        │   ├── shortest_path_skabelon.jl / run_shortest_path.jl, run_shortest_path_Dijkstra.jl, run_shortest_path_BellmanFord.jl
        │   ├── MST_skabelon.jl / run_MST.jl, run_MST_Kruskal.jl
        │   ├── Transportation_problem_skabelon.jl / run_transportation.jl
        │   ├── Assignment_problem_skabelon.jl / run_assignment.jl
        │   ├── TSP_problem_skabelon.jl / run_TSP.jl
        │   ├── lager_problem_skabelon.jl / run_lager.jl
        │   ├── draw_graph_skabelon.jl / run_draw_graph.jl
        │   └── Output/
        │
        ├── Andet/
        └── Julia_eks_fra_lærer/
```

---

## 2. Køteori

Køteori-delen beregner typiske mål for et køsystem: udnyttelsesgrad, koefficienter af variation for ankomst og service, gennemsnitlig køtid, gennemsnitlig lead time samt gennemsnitligt antal i kø og i systemet. Den understøtter D/D/N, M/M/N og G/G/N-systemer.

Du bruger det ved at åbne Skabelon_Kø.jl og sætte dine tal: ankomst- og service-rate (lambda og mu) eller gennemsnitlige tider (T_a og T_p), standardafvigelser sigma_a og sigma_p, antal servere N, og om du vil have resultaterne i terminalen eller gemt i en fil. Når skabelonen er tilpasset, kører du Run_kø.jl fra mappen Køteori (fx ved at skrive "julia Run_kø.jl" i en terminal). Resultaterne kommer enten på skærmen eller i en fil i Output-mappen; filnavnet vælges i skabelonen. Run_kø.jl henter selv funktionerne fra Funktioner.jl og Print.jl, så du behøver ikke køre andre filer.

---

## 3. Simplex

Simplex-delen kan bruges på to måder.

Den første er at starte fra et fuldt lineært program: du redigerer Skabelon_simplex.jl med objektivkoefficienter (c), begrænsningsmatrix (A), højreside (b) og navne på variable og slack-variable. Når du kører run_simplex.jl, bygges start-tableauet automatisk, simplex-algoritmen kører, og du får den optimale løsning samt sensitivitetsanalyse. Du kan vælge at se output i terminalen eller i en fil; filnavnet sættes i skabelonen. Al tableau- og pivot-logikken ligger i Primal_Dual_simplex_alg.jl, og Print_tableau.jl står for udskrivning af tableau og rapport.

Den anden måde er at du allerede har et simplex-tableau (fx fra en opgave). Så åbner du run_tableau.jl og indsætter din matrix T samt navnene på kolonner og basisvariabler i den afmærkede sektion. Når du kører run_tableau.jl, løses tableauet videre til optimalitet, og løsningen udskrives. Det er praktisk når du kun vil arbejde med et givet tableau uden at definere hele LP’en i skabelonen.

---

## 4. LP og MIP (generel optimering)

Under LP_MIP findes den generelle løsning af lineære programmer (LP) og blandet-heltallige programmer (MIP). Du definerer dit problem i skabelon_LP_MIP.jl: om det er LP eller MIP, om du vil maksimere eller minimere, objektivkoefficienter, begrænsninger, retninger (mindre end, større end, lig med) og evt. heltallige eller binære variable. Når du kører run_LP_MIP.jl, bygges modellen med JuMP og HiGHS, den løses, og resultatet (inkl. slack og skyggepriser) skrives til terminalen eller til en fil. Filnavnene (både for primal og evt. dual) vælges i skabelonen. Hvis du i skabelonen sætter at dual også skal løses, genereres og løses det duale program, og det duale resultat gemmes i en separat fil.

Hvis du kun vil se den primale og duale problemformulering uden at løse, bruger du run_convert_dual.jl. Den læser samme skabelon_LP_MIP.jl og udskriver primal og dual formulering til terminal eller fil (filnavnet angives i run_convert_dual.jl).

Bygning af modellen sker i build.jl, og al udskrivning (problemformulering, løsning, slack, skyggepriser) håndteres i print.jl. convert_dual.jl bruges til at lave det duale problem ud fra det primale.

---

## 5. Netværks- og flow-problemer

I LP_MIP-mappen findes også særskilte skabeloner og run-filer til netværksproblemer: maximum flow (max_flow_skabelon.jl og run_max_flow.jl), minimum cost flow (min_cost_flow_skabelon.jl og run_min_cost_flow.jl), shortest path (shortest_path_skabelon.jl med run_shortest_path.jl samt Dijkstra- og Bellman-Ford-varianter), minimum spanning tree (MST_skabelon.jl med run_MST.jl og run_MST_Kruskal.jl), transportproblemet, assignmentsproblemet, TSP og lagerproblemer. For hver type åbner du den tilhørende skabelon, indtaster noder, kanter, kapaciteter og omkostninger (eller supply/demand, source/sink, alt efter problemet), og kører derefter den tilhørende run-fil fra LP_MIP-mappen. Resultaterne skrives som ved den generelle LP/MIP, og for max flow og min cost flow kan der evt. tegnes en graf hvis det er slået til i run-filen.

Til kun at tegne en graf uden at løse et optimeringsproblem bruges draw_graph_skabelon.jl og run_draw_graph.jl.

---

## 6. Øvrige filer

Mapperne Andet og Julia_eks_fra_lærer indeholder eksempel- og opgavefiler fra undervisningen (fx minimum cost flow, MST, shortest path, max flow). De er ikke en del af hovedprogrammet og skal ikke bruges for at køre køteori, simplex eller LP/MIP-skabelonerne; de kan køres for sig selv hvis man vil gennemgå eksemplerne.

---

## 7. Krav og kørsel

Du skal have Julia installeret. Installer de nødvendige pakker ved i Julia REPL at køre:

```
using Pkg
Pkg.add("JuMP")
Pkg.add("HiGHS")
```

Til graf-tegning og nogle run-filer under LP_MIP bruges også Graphs, GraphPlot og Colors. Installer dem evt. med:

```
Pkg.add("Graphs")
Pkg.add("GraphPlot")
Pkg.add("Colors")
```

Kør alt fra den mappe hvor run-filen ligger (fx Køteori for Run_kø.jl, eller LP_MIP for run_LP_MIP.jl), så inkluderede filer og output-stier findes korrekt. Output gemmes som standard i en Output-mappe under den aktuelle kode-mappe; skabelonerne opretter Output-mappen automatisk hvis den ikke findes. Du kan i skabelonen sætte en anden output_base_sti hvis du vil gemme resultater et andet sted.


---

## 8. Hurtig oversigt

- Køteori: rediger Skabelon_Kø.jl, kør Run_kø.jl (fra mappen Køteori).
- Simplex fra LP: rediger Skabelon_simplex.jl, kør run_simplex.jl (fra mappen Simplex).
- Simplex fra tableau: rediger run_tableau.jl (tableau-sektionen), kør run_tableau.jl (fra mappen Simplex).
- Generel LP eller MIP: rediger skabelon_LP_MIP.jl, kør run_LP_MIP.jl (fra mappen LP_MIP).
- Kun primal og dual formulering: rediger skabelon_LP_MIP.jl, kør run_convert_dual.jl (fra mappen LP_MIP).
- Maximum flow: rediger max_flow_skabelon.jl, kør run_max_flow.jl.
- Minimum cost flow: rediger min_cost_flow_skabelon.jl, kør run_min_cost_flow.jl.
- Shortest path: rediger shortest_path_skabelon.jl, kør run_shortest_path.jl (eller Dijkstra/Bellman-Ford-varianten).
- MST: rediger MST_skabelon.jl, kør run_MST.jl eller run_MST_Kruskal.jl.
- Transport, assignment, TSP, lager: rediger den tilsvarende skabelon, kør den tilsvarende run-fil (fra mappen LP_MIP).

---

## 9. Forklaring af filer

Her beskrives hver fil. Run-filer og skabeloner er de filer du selv redigerer eller kører; de øvrige filer er hjælpefiler som run-filerne kalder, og som du som regel ikke behøver at åbne.

#### Køteori

Run_kø.jl  
Den fil du kører for køteori. Den indlæser skabelon, funktioner og print, henter parametrene fra skabelonen og kalder den rigtige udskrivningsfunktion afhængigt af om du bruger lambda/mu eller T_a/T_p.

Skabelon_Kø.jl  
Her sætter du dine tal og indstillinger: rate_parameter, lambda, mu (eller T_a, T_p), sigma_a, sigma_p, N, antal decimaler, og om output skal til terminal eller fil. Du ændrer kun denne fil når du vil lave nye køteori-beregninger.

Funktioner.jl  
Indeholder de rene beregningsfunktioner: ankomst- og service-rate, udnyttelsesgrad, koefficienter af variation for ankomst og service, gennemsnitlig køtid, lead time, antal i betjening, gennemsnitlig kølængde og totalt antal i systemet. Run_kø.jl bruger dem via Print.jl; du behøver ikke køre eller redigere Funktioner.jl.

Print.jl  
Står for al udskrivning i køteori: den samler beregninger ved hjælp af Funktioner.jl, formaterer tabellen med input og resultater, skriver til terminal eller fil, og tilføjer den forklarende tekst om hvad de enkelte mål betyder og hvordan man kan bruge dem i praksis. Kaldes automatisk fra Run_kø.jl.

#### Simplex

run_simplex.jl  
Kør denne når du vil løse et LP defineret i Skabelon_simplex.jl. Den bygger tableau, kører simplex til optimalitet og skriver problemformulering, tableau (evt. hver iteration), optimal løsning og sensitivitetsrapport.

run_tableau.jl  
Til når du allerede har et tableau (fx fra en opgave). Du indsætter matrix T og navne i filen, kører run_tableau.jl, og får tableauet løst videre og løsningen udskrevet.

Skabelon_simplex.jl  
Her definerer du LP’en: objektivkoefficienter (c), begrænsningsmatrix (A), højreside (b), navne på variable og slack-variable, samt om du vil have output i terminal eller fil og om hver tableau-iteration skal printes.

Primal_Dual_simplex_alg.jl  
Indeholder selve simplex-algoritmen: opbygning af start-tableau fra c, A, b, pivot-regel, tableau-opdatering og funktioner der udtrækker den optimale basis og sensitivitetsinformation fra det endelige tableau. Bruges af både run_simplex.jl og run_tableau.jl; du behøver ikke ændre denne fil.

Print_tableau.jl  
Indeholder funktioner til at printe LP-formulering, simplex-tableau (med navne) og den fulde sensitivitetsrapport (slack-værdier, reducerede omkostninger, skyggepriser osv.) til terminal eller fil. Kaldes fra run_simplex.jl og run_tableau.jl.

#### LP_MIP (fælles og generel LP/MIP)

run_LP_MIP.jl  
Kør denne for at løse det problem du har defineret i skabelon_LP_MIP.jl (LP eller MIP). Modellen bygges, løses med HiGHS, og resultatet (inkl. dual hvis du har bedt om det) skrives ud.

run_convert_dual.jl  
Læser samme skabelon som run_LP_MIP.jl og udskriver kun den primale og duale problemformulering uden at løse. Filnavn til output sættes i run_convert_dual.jl.

skabelon_LP_MIP.jl  
Her definerer du det generelle LP- eller MIP-problem: model_type, objektiv retning, c, A, b, begrænsningsretninger, variabeltyper (kontinuert, heltallig, binær) og output-indstillinger (herunder evt. filnavne til resultat). Bruges af run_LP_MIP.jl og run_convert_dual.jl.

build.jl  
Bygger JuMP-modellen: opretter variabler med grænser og typer, tilføjer begrænsninger og objektiv, og returnerer modellen samt variabel- og begrænsningsreferencer. Indeholder også hjælpefunktioner til at bygge grafer til shortest path og MST (noder, kanter, afstandsmatrix). Alle LP_MIP run-filer der løser optimering kalder build.jl; du behøver ikke redigere den.

print.jl  
Indeholder al udskrivning til LP/MIP: problemformulering til terminal eller fil, løsning med variabelværdier, slack og skyggepriser, og særlige udskrifter til max flow, min cost flow osv. samt evt. graf-tegning. Bruges af run_LP_MIP.jl og de andre run-filer i LP_MIP; du behøver som regel ikke ændre print.jl.

convert_dual.jl  
En funktion der tager det primale problem (objektiv, A, b, begrænsningsretninger, c, fortegn på variable) og returnerer det duale problem (ny matrix, højreside, retninger og variabelnavne). Bruges af run_LP_MIP.jl når dual også skal løses, og af run_convert_dual.jl når du kun vil se primal og dual formulering.

#### LP_MIP (netværks- og flow-problemer)

For hver problemtype findes en skabelon og en run-fil. Skabelonen er hvor du indtaster data (noder, kanter, kapaciteter, omkostninger, supply/demand, source/sink osv.); run-filen indlæser skabelonen og build/print/convert_dual, bygger modellen, løser og skriver resultat (og evt. graf).

max_flow_skabelon.jl og run_max_flow.jl  
Maximum flow: du definerer netværket og source/sink i skabelonen, kører run_max_flow.jl og får optimal flow og evt. graf.

min_cost_flow_skabelon.jl og run_min_cost_flow.jl  
Minimum cost flow: du definerer netværk, omkostninger, kapaciteter og supply/demand i skabelonen, kører run_min_cost_flow.jl og får optimal flow og evt. graf.

shortest_path_skabelon.jl  
Fælles skabelon til shortest path. run_shortest_path.jl, run_shortest_path_Dijkstra.jl og run_shortest_path_BellmanFord.jl bruger den med hver deres løsningsmetode.

MST_skabelon.jl, run_MST.jl og run_MST_Kruskal.jl  
Minimum spanning tree: skabelon med noder og kanter; de to run-filer bruger hver deres algoritme.

Transportation_problem_skabelon.jl og run_transportation.jl  
Transportproblemet: du angiver tilbud, efterspørgsel og omkostninger i skabelonen og kører run_transportation.jl.

Assignment_problem_skabelon.jl og run_assignment.jl  
Assignmentsproblemet: data i skabelonen, løsning via run_assignment.jl.

TSP_problem_skabelon.jl og run_TSP.jl  
TSP (rejsende sælger): skabelon med afstande/noder, run_TSP.jl løser.

lager_problem_skabelon.jl og run_lager.jl  
Lagerproblem: skabelon med data, run_lager.jl kører optimeringen.

draw_graph_skabelon.jl og run_draw_graph.jl  
Kun til at tegne en graf uden at løse et optimeringsproblem: du definerer grafen i skabelonen og kører run_draw_graph.jl for at vise den.
