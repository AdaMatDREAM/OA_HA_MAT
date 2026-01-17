# Inkludér pakken
library(lpSolveAPI)

# ---------- Basisinput ----------
fil <- "OutputMIP.txt"
obj <- "max"    # "min" eller "max"

# Objektivkoefficienter og navne
c       <- c(40, 35)
x_navne <- c("x1", "x2")

# Blandede variabletyper: "C" (kontinuer), "I" (heltal), "B" (binær)
var_type <- c("I", "I")

# Begrænsningsmatrix, retninger og RHS
A <- rbind(
  c(15,  10),
  c(8, 12)
)
dir <- c("<=", "<=")
b   <- c(300, 230)
B_navne <- c("B1", "B2")

# (Valgfrie) bounds på variable
lower_bounds <- c(0,  0)
upper_bounds <- c(Inf, Inf)

# ---------- Indstillinger ----------
dec <- 2
tol <- 1e-9

# ---------- Hjælpefunktioner ----------
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
fortegn <- function(c_n , tal) {
  if (abs(c_n - 1) < tol) tal
  else if (abs(c_n + 1) < tol) paste0("-", tal)
  else paste0(c_n, " * ", tal)
}
bnd_str <- function(name, lo, up, d = dec) {
  if (is.infinite(lo) && is.infinite(up)) paste0(name, " Fri")
  else if (is.infinite(lo))               paste0(name, " <= ", format_tal(up, d))
  else if (is.infinite(up))               paste0(name, " >= ", format_tal(lo, d))
  else if (abs(lo - up) <= tol)           paste0(name, " = ",  format_tal(lo, d))
  else                                    paste0(format_tal(lo, d), " <= ", name, " <= ", format_tal(up, d))
}

# ---------- Byg og løs model ----------
m <- nrow(A); n <- length(c)
LP_P <- make.lp(0, n)

# Bounds
set.bounds(LP_P, lower = lower_bounds, upper = upper_bounds)

# Objektiv + begrænsninger
set.objfn(LP_P, c)
for (i in 1:m) add.constraint(LP_P, A[i,], dir[i], b[i])
lp.control(LP_P, sense = obj)

# Navne
colnames(LP_P) <- x_navne
rownames(LP_P) <- B_navne

# Sæt variabletyper
for (j in 1:n) {
  if (var_type[j] == "I") set.type(LP_P, j, "integer")
  if (var_type[j] == "B") set.type(LP_P, j, "binary")
  # "C" = kontinuert (standard) -> ingen set.type nødvendig
}

# Løs
status <- solve(LP_P)

# Hent løsninger og information
z_s  <- get.objective(LP_P)
x_s  <- get.variables(LP_P)
lhs  <- get.constraints(LP_P)
rhs  <- get.rhs(LP_P)
dirs <- get.constr.type(LP_P)

# Slack: definér per retning
slack <- ifelse(dirs == "<=", rhs - lhs,
                ifelse(dirs == ">=", lhs - rhs, 0))

bindende_status <- ifelse(dirs == "=", "Bindende",
                          ifelse(abs(slack) <= tol, "Bindende", "Ikke-bindende"))

# MIP-venlig statusmeddelelse (uden LP-sensitivitet)
msg <- switch(as.character(status),
              "0" = "Optimal løsning fundet.",
              "1" = "Suboptimal (typisk MIP: integer løsning fundet, men optimalitet ej garanteret).",
              "2" = "Infeasible (ingen løsning opfylder alle begrænsninger).",
              "3" = "Unbounded (objektivfunktion kan forbedres uden grænse).",
              "4" = "Degeneracy (pivot/numerisk degenerering).",
              "5" = "Numerical failure (numerisk instabilitet/afrundingsfejl).",
              "6" = "Afbrudt af bruger/abort.",
              "7" = "Timeout (tidsgrænse nået).",
              "9" = "Løst i presolve.",
              paste("Ukendt/anden statuskode:", status)
)

# Hent bounds fra modellen (efter presolve)
bnds <- get.bounds(LP_P)
lb <- bnds$lower[1:n]
ub <- bnds$upper[1:n]

# ---------- Udskriv til fil ----------
sink(fil)
on.exit(sink(), add = TRUE)

cat(">>>>>>>>>>>>>>> PROBLEMFORMULERING (MIP) <<<<<<<<<<<<<<<\n")
formaal <- if (obj == "max") "Maksimer" else "Minimer"

obj_string <- paste(mapply(fortegn, c, x_navne), collapse = " + ")
obj_string <- gsub("\\+ -", "- ", obj_string)

cat(formaal, " Z = ", obj_string, "\n\n", sep = "")

for (i in 1:m) {
  lhs_string <- paste(mapply(fortegn, A[i, ], x_navne), collapse = " + ")
  lhs_string <- gsub("\\+ -", "- ", lhs_string)
  cat("(", B_navne[i], ") ", lhs_string, " ", dir[i], " ", b[i], "\n", sep = "")
}

# Naturlige/parameter-bounds
nb_linje <- paste(mapply(bnd_str, x_navne, lb, ub, MoreArgs = list(d = dec)),
                  collapse = ", ")
cat("( Parameter restriktioner ) ", nb_linje, "\n\n", sep = "")

# Angiv variabletyper i pæn tekst
type_txt <- function(t) if (t=="B") "Binær" else if (t=="I") "Heltal" else "Kontinuer"
cat("( Variabletyper ) ",
    paste(sprintf("%s: %s", x_navne, vapply(var_type, type_txt, "")),
          collapse = ", "),
    "\n\n", sep = "")

cat("________________________________________________________________________________\n")

# ---------- RESULTATTABELLER (ingen LP-sensitiviteter) ----------
cat(">>>>>>>>>>>>>>> STATUS <<<<<<<<<<<<<<<\n\n")
cat("-> ", msg, "\n\n", sep = "")
cat(">>>>>>>>>>>>>>> OPTIMUM <<<<<<<<<<<<<<<\n\n")
cat("Objektivfunktionens værdi:\n-> ", format_tal(z_s, dec), "\n\n", sep = "")

# --- Tabel: Variabler ---
cat(">>>>>>>>>>>>>>> VARIABLER <<<<<<<<<<<<<<<\n\n")

headers_v <- c("Variabel", "Type", "Værdi", "Nedre gr.", "Øvre gr.")
VAL <- format_tal(x_s, dec)
LB  <- format_tal(lb,  dec)
UB  <- format_tal(ub,  dec)
TYP <- vapply(var_type, type_txt, "")

w1 <- max(nchar(headers_v[1]), nchar(x_navne))
w2 <- max(nchar(headers_v[2]), nchar(TYP))
w3 <- max(nchar(headers_v[3]), nchar(VAL))
w4 <- max(nchar(headers_v[4]), nchar(LB))
w5 <- max(nchar(headers_v[5]), nchar(UB))

rowfmt_v <- paste0("%-",w1,"s  %-",w2,"s  %",w3,"s  %",w4,"s  %",w5,"s\n")
cat(sprintf(rowfmt_v, headers_v[1], headers_v[2], headers_v[3], headers_v[4], headers_v[5]))
cat(paste0(rep("-", w1+2+w2+2+w3+2+w4+2+w5), collapse=""), "\n")
for (j in 1:n) {
  cat(sprintf(rowfmt_v, x_navne[j], TYP[j], VAL[j], LB[j], UB[j]))
}
cat("\n")

# --- Tabel: Begrænsninger ---
cat(">>>>>>>>>>>>>>> BEGRÆNSNINGER <<<<<<<<<<<<<<<\n\n")

LHSS   <- format_tal(lhs,   dec)
RHSS   <- format_tal(rhs,   dec)
SLACKS <- format_tal(slack, dec)

headers_c <- c("Begrænsning","LHS","Retning","RHS","Slack","Bindende")

w1 <- max(nchar(headers_c[1]), nchar(B_navne))
w2 <- max(nchar(headers_c[2]), nchar(LHSS))
w3 <- max(nchar(headers_c[3]), nchar(dirs))
w4 <- max(nchar(headers_c[4]), nchar(RHSS))
w5 <- max(nchar(headers_c[5]), nchar(SLACKS))
w6 <- max(nchar(headers_c[6]), nchar(bindende_status))

rowfmt_c <- paste0("%-",w1,"s  %",w2,"s  %-",w3,"s  %",w4,"s  %",w5,"s  %-",w6,"s\n")
cat(sprintf(rowfmt_c, headers_c[1], headers_c[2], headers_c[3],
            headers_c[4], headers_c[5], headers_c[6]))
cat(paste0(rep("-", w1+2+w2+2+w3+2+w4+2+w5+2+w6), collapse=""), "\n")
for (i in 1:m) {
  cat(sprintf(rowfmt_c,
              B_navne[i], LHSS[i], dirs[i], RHSS[i], SLACKS[i], bindende_status[i]))
}

sink() # Stopper udskrivning til .txt
on.exit(sink(), add = TRUE) # Sørger for at filen altid lukker
# Slut på udskrift
