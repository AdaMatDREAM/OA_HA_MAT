# Inkludere pakken (som skal downloades i tools)
library(lpSolveAPI)

# Navn på uskrvningsfil
fil <- "RCtest3.txt"

# Formål max eller min
obj <- "max"

# Obejktivcoefficienter
c  <-  c(120, 200, (160+119))
x_navne  <-  c("BC", "RR", "CS") # Navne på coefficienter

# Begrænsningesmatrix
A    <-    rbind(
  c(1, 1, 1),
  c(30, 15, 45),
  c(40, 80, 120)
)
# Retninger
dir  <-  c( "<=", "<=","<=")

# B-vektor
b  <-  c(11, 300,820)
B_navne  <-  c("DOCKS", "AA","K") # Navne på begrænsninger

# Begrænsninger på x_i. Eks alle >=0 eller lign. Vi har nedre og øvre grænse.
# Du kan enten skrive denne her, eller du kan skrive dem som relle begrænsinger i A (tror jeg)
lower_bounds <- c(0, 0, 0)
upper_bounds <- c(Inf ,Inf, Inf)

dec <- 2 # Ønsket antal decimaler
tol <- 1e-9 # Ønsket tolerence
##################################### Alt herfra kræver ikke opmærksomhed ####################
#Definition af funktioner
# Til pæn tekst med parameter restriktioner
bnd_str <- function(name, lo, up, d = dec) {
  if (is.infinite(lo) && is.infinite(up)) {
    paste0(name, " Fri")                      # fri variabel
  } else if (is.infinite(lo)) {
    paste0(name, " <= ", format_tal(up, d))       # kun øvre grænse
  } else if (is.infinite(up)) {
    paste0(name, " >= ", format_tal(lo, d))       # kun nedre grænse
  } else if (abs(lo - up) <= tol) {
    paste0(name, " = ", format_tal(lo, d))        # fastlåst variabel
  } else {
    paste0(format_tal(lo, d), " <= ", name, " <= ", format_tal(up, d))  # interval
  }
}

# Formatering af tal så uendeligheder står som inf mm.
format_tal <- function(x, d = dec, inf_cut = 1e29) {
  z <- x
  z[!is.infinite(z) & z >=  inf_cut] <-  Inf
  z[!is.infinite(z) & z <= -inf_cut] <- -Inf
  out <- ifelse(is.infinite(z),
                ifelse(z > 0, "Inf", "-Inf"),
                formatC(round(z, d), digits = d, format = "f"))
  nz <- grepl("^-0\\.0+$", out)
  out[nz] <- sub("-", "", out[nz])
  out
}

# Hjælpefunktion til pæn tekst
fortegn <- function(c_n , tal) {
  if(abs(c_n - 1) < tol) tal
  else if (abs(c_n + 1) < tol) paste0("-",tal)
  else paste0(c_n, " * ", tal)
}

# Dimensioner
m <- nrow(A);n <- length(c)

# Byg model
LP_P <- make.lp(0, n) # 0 begræsningsiner (tilføjes) og n variable 
set.bounds(LP_P, lower = lower_bounds, upper = upper_bounds) # Sætter parametre grænser
set.objfn(LP_P, c)    # Obejktivfunktion
for (i in 1:m) add.constraint(LP_P, A[i,], dir[i], b[i]) # Begrænsninger
lp.control(LP_P, sense = obj) # Maksimeringsproblem

colnames(LP_P) <- x_navne # Giver navne
rownames(LP_P) <- B_navne # Giver navne

status <- solve(LP_P) # Løs model. 

z_s  <- get.objective(LP_P)    # Objektivfunktionens værdi
x_s  <- get.variables(LP_P)    # Løsningsvariablenes værdi
lhs  <- get.constraints(LP_P)  # Benyttet i løsning for begrænsninger
rhs  <- get.rhs(LP_P)          # Samme som b-vektor
dirs <- get.constr.type(LP_P)  # Samme som dir

slack <- numeric(m)  # Vektor med længde m
# Beregner slack
slack <- ifelse(dirs == "<=", rhs - lhs,
                ifelse(dirs == ">=", lhs - rhs, 0))

# Henter grænserne for objektivkoefficienterne
c_range <- get.sensitivity.obj(LP_P)
lower <- c_range$objfrom[1:n]
upper <- c_range$objtill[1:n]

b_range <- get.sensitivity.rhs(LP_P) # Ranges for b-værdier

# Henter skyggepriser og reduced costs
sp_og_rc <- get.dual.solution(LP_P)
sp  <- b_range$duals[1:m] 
rc <- tail(sp_og_rc, n)

# Til at undersøge mulighed for uendeligt mange løsninger.
# UB_tjeck <- format_tal(upper, dec)
# LB_tjeck <- format_tal(lower, dec)
infinite_interval <- any(upper > 1e29 | lower < -1e29)

if(status == 0) {
  # check for multiple optima: reduced costs = 0 og ubundet objektivinterval
  if(any(abs(rc) < tol) & infinite_interval) {
    msg <- "Optimal løsning fundet.\n-> Uendeligt mange optimale løsninger er muligt."
  } else {
    msg <- "Optimal løsning fundet."
  }
} else {
  msg <- switch(as.character(status),
                "1"  = "Suboptimal løsning (typisk fra MIP: integer løsning fundet, men optimalitet ej garanteret).",
                "2"  = "Infeasible (ingen punkter opfylder alle begrænsninger).",
                "3"  = "Unbounded (objektivfunktionen kan forbedres uden grænse).",
                "4"  = "Degeneracy (numerisk/pivot-degeneracy i modellen).",
                "5"  = "Numerical failure (numerisk instabilitet/afrundingsfejl).",
                "6"  = "Afbrudt af bruger/abort-funktion.",
                "7"  = "Timeout (tidsgrænse nået).",
                "9"  = "Løst i presolve.",
                paste("Ukendt/anden statuskode:", status)
  )
}

sink(fil)   # Starter udskrivning til .txt

######################## Problemformulering ############################
cat(">>>>>>>>>>>>>>> PROBLEMFORMULERING <<<<<<<<<<<<<<<\n")
formaal <- if(obj == "max") "Maksimer" else "Minimer"

# Laver en string med objektivfunktionen hvor fortegn bliver sat på
obj_string <- paste(mapply(fortegn, c, x_navne), collapse = " + ")
obj_string <- gsub("\\+ -", "- ", obj_string) # Erstatter + - med -

cat(formaal, " Z = ", obj_string, "\n\n") #Udskriver formål

# Udskriver begrænsninger
for (i in 1:m) {
  lhs_string <- paste(mapply(fortegn, A[i, ], x_navne), collapse = " + ")
  lhs_string <- gsub("\\+ -", "- ", lhs_string)
  cat("(", B_navne[i], ")", lhs_string, dir[i], b[i], "\n")
}

# Hent bounds fra modellen
bnds <- get.bounds(LP_P)
lb <- bnds$lower[1:n]
ub <- bnds$upper[1:n]

pr_linje <- paste(mapply(bnd_str, x_navne, lb, ub, MoreArgs = list(d = 0)),
                  collapse = ", ")

# Udskriv “naturlige begrænsninger” baseret på set.bounds
cat("( Parameter restriktioner ) ", pr_linje, "\n", sep = "")

######################## Udskriver resultater ############################
cat("________________________________________________________________________________\n")
cat(">>>>>>>>>>>>>>> STATUS <<<<<<<<<<<<<<<\n\n")
cat("->", msg, "\n")
cat("________________________________________________________________________________\n")
cat(">>>>>>>>>>>>>>> OPTIMUM <<<<<<<<<<<<<<<\n\n")
cat("Objektivfunktionens værdi:\n-> ", round(z_s,dec), "\n")
cat("Løsningsvariablenes værdier:\n-> ", paste(x_navne,"=", round(x_s,dec), collapse=", "),"\n")
cat("________________________________________________________________________________\n")
cat(">>>>>>>>>>>>>>> BEGRÆNSNINGER <<<<<<<<<<<<<<<\n\n")

lhss   <- format_tal(lhs, dec)
rhss   <- format_tal(rhs, dec)
slacks <- format_tal(slack, dec)
sps    <- format_tal(sp, dec)

# Bindende/ikke-bindende ud fra numerisk slack og retning
bindende_status <- ifelse(dirs == "=", "Bindende",
                          ifelse(abs(slack) <= tol, "Bindende", "Ikke-bindende"))

# Overskrifter (tilføj sidste kolonne)
headers <- c("Begrænsning","LHS","Retning","RHS","Slack","Skyggepris","Bindende")

# Kolonnebredder (maks af header og data)
w1 <- max(nchar(headers[1]), nchar(B_navne))
w2 <- max(nchar(headers[2]), nchar(lhss))
w3 <- max(nchar(headers[3]), nchar(dirs))
w4 <- max(nchar(headers[4]), nchar(rhss))
w5 <- max(nchar(headers[5]), nchar(slacks))
w6 <- max(nchar(headers[6]), nchar(sps))
w7 <- max(nchar(headers[7]), nchar(bindende_status))

# Formatstreng: navne/status venstrejusteres, tal højrejusteres
raekke_format_1 <- paste0(
  "%-",w1,"s  %",w2,"s  %-",w3,"s  %",w4,"s  %",w5,"s  %",w6,"s  %-",w7,"s\n"
)

# Overskrift
cat(sprintf(raekke_format_1, headers[1], headers[2], headers[3],
            headers[4], headers[5], headers[6], headers[7]))

# Separatorlinje
tot_width <- w1+2 + w2+2 + w3+2 + w4+2 + w5+2 + w6+2 + w7
cat(paste0(rep("-", tot_width), collapse = ""), "\n")

# Rækker
for (i in 1:m) {
  cat(sprintf(raekke_format_1,
              B_navne[i],
              lhss[i],
              dirs[i],
              rhss[i],
              slacks[i],
              sps[i],
              bindende_status[i]))
}


cat("________________________________________________________________________________\n")
cat(">>>>>>>>>>>>>>> SENSITIVTET OBJEKTIV COEFFICIENTER <<<<<<<<<<<<<<<\n\n")

CS  <- format_tal(c,  dec)
LB  <- format_tal(lower,dec)
UB  <- format_tal(upper,dec)
RCs <- ifelse(is.na(rc), format_tal(0, dec), format_tal(rc, dec))

headers <- c("Variabelnavn","Coefficient","Nedre grænse","Øvre grænse","Reduced costs")

# Kolonnebredder
w1 <- max(nchar(headers[1]), nchar(x_navne))
w2 <- max(nchar(headers[2]), nchar(CS))
w3 <- max(nchar(headers[3]), nchar(LB))
w4 <- max(nchar(headers[4]), nchar(UB))
w5 <- max(nchar(headers[5]), nchar(RCs))

# Formatstreng (navn venstrejusteres, tal højrejusteres)
raekke_format_2 <- paste0("%-",w1,"s  %",w2,"s  %",w3,"s  %",w4,"s  %",w5,"s\n")

# Header
cat(sprintf(raekke_format_2, headers[1], headers[2], headers[3], headers[4], headers[5]))

# Separator
tot_width <- w1 + 2 + w2 + 2 + w3 + 2 + w4 + 2 + w5
cat(paste0(rep("-", tot_width), collapse = ""), "\n")

# Rækker
for (j in 1:n) {
  cat(sprintf(raekke_format_2,
              x_navne[j],
              CS[j],
              LB[j],
              UB[j],
              RCs[j]))
}
cat("________________________________________________________________________________\n")


cat(">>>>>>>>>>>>>>> SENSITIVITET B-VEKTOR (KAPACITET) <<<<<<<<<<<<<<<\n\n")

# Udtræk kun de første m elementer (de hører til de m egentlige begrænsninger)
rhs_now <- rhs[1:m]                       # nuværende RHS (din b-vektor)
rhs_min <- b_range$dualsfrom[1:m]         # tilladt nedre RHS
rhs_max <- b_range$dualstill[1:m]         # tilladt øvre RHS

# Identificér ikke-bindende rækker (skyggepris ~ 0)
nb_le <- dirs == "<=" & abs(sp) < tol
nb_ge <- dirs == ">=" & abs(sp) < tol
nb_eq <- dirs == "="  & abs(sp) < tol  # sjældent relevant her

# For en ikke-bindende ≤-række: min RHS kan ikke være under LHS
rhs_min[nb_le] <- pmax(rhs_min[nb_le], lhs[nb_le])

# For en ikke-bindende ≥-række: max RHS kan ikke være over LHS
rhs_max[nb_ge] <- pmin(rhs_max[nb_ge], lhs[nb_ge])


RHS_NOW <- format_tal(rhs_now, dec)
RHS_MIN <- format_tal(rhs_min, dec)
RHS_MAX <- format_tal(rhs_max, dec)

headers <- c("Begrænsning","RHS (nu)","RHS min","RHS max")

# Kolonnebredder
w1 <- max(nchar(headers[1]), nchar(B_navne))
w2 <- max(nchar(headers[2]), nchar(RHS_NOW))
w3 <- max(nchar(headers[3]), nchar(RHS_MIN))
w4 <- max(nchar(headers[4]), nchar(RHS_MAX))

row_fmt <- paste0("%-",w1,"s  %",w2,"s  %",w3,"s  %",w4,"s\n")
cat(sprintf(row_fmt, headers[1], headers[2], headers[3], headers[4]))
tot_w <- w1+2+w2+2+w3+2+w4
cat(paste0(rep("-", tot_w), collapse=""), "\n")

for(i in 1:m){
  cat(sprintf(row_fmt, B_navne[i], RHS_NOW[i], RHS_MIN[i], RHS_MAX[i]))
}

sink() # Stopper udskrivning til .txt
on.exit(sink(), add = TRUE) # Sørger for at filen altid lukker