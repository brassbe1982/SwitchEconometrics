## ac4b_bootstrap_check.R -- acceptance criterion AC4(b)
## (04_Validation/ACCEPTANCE_TESTS.md): bootstrap and Hessian standard errors
## agree within 10% at N = 2000.
##
## Two datasets of N = 2000: (1) the base design of MONTE_CARLO_DESIGN.md
## (rho1 = 0.6, rho0 = 0.4), seed 20261122; (2) the package data set `firms`.
## Nonparametric bootstrap, R = 999, seed 20261122. The bootstrap standard
## error has a Monte Carlo error of about 1/sqrt(2R) = 2.2% of its value.
## Criterion: every FIML parameter has bootstrap SE / Hessian SE in [0.90, 1.10]
## (rho: on the atanh scale, where the intervals are built). Effects are
## reported for information (not part of AC4(b)).
##
## Usage (from the workspace root):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/ac4b_bootstrap_check.R \
##       <library> <output .csv> [cores]
args <- commandArgs(trailingOnly = TRUE)
lib <- args[1]; out <- args[2]
cores <- if (length(args) >= 3) as.integer(args[3]) else 1L
suppressPackageStartupMessages(library(SwitchEconometrics, lib.loc = lib))
cat("SwitchEconometrics", as.character(packageVersion("SwitchEconometrics", lib.loc = lib)), "\n")

## dataset 1: base design
RNGkind("L'Ecuyer-CMRG"); set.seed(20261122)
N <- 2000
x1 <- rnorm(N); x2 <- rnorm(N); z1 <- rnorm(N); u <- rnorm(N)
e1 <- 0.6 * u + sqrt(1 - 0.36) * rnorm(N)
e0 <- 0.4 * u + sqrt(1 - 0.16) * rnorm(N)
S <- as.integer(0.5 + 0.3 * x1 - 0.4 * z1 + u > 0)
y <- ifelse(S == 1, 1.5 + 0.8 * x1 + 0.4 * x2 + e1, 1.0 + 0.5 * x1 + 0.2 * x2 + e0)
base <- data.frame(S, y, x1, x2, z1)
RNGkind("default")

fits <- list(
  base = switch_fit(S ~ x1 + z1, list(regime_0 = y ~ x1 + x2, regime_1 = y ~ x1 + x2),
                    data = base),
  firms = switch_fit(digital_adoption ~ internet_access + management_quality +
                       firm_size + owner_education,
                     list(regime_0 = productivity ~ firm_size + capital + labour,
                          regime_1 = productivity ~ firm_size + capital + labour),
                     data = firms))
rows <- list()
for (nm in names(fits)) {
  f <- fits[[nm]]
  stopifnot(identical(f$convergence$code, 0L))
  t0 <- proc.time()[["elapsed"]]
  b <- switch_bootstrap(f, R = 999, seed = 20261122, cores = cores)
  be <- switch_bootstrap(f, R = 999, seed = 20261122, cores = cores,
                         statistics = "effects")
  tm <- proc.time()[["elapsed"]] - t0
  ## rho on the atanh scale: bootstrap SD of atanh(rho*) vs working-scale Hessian SE
  pn <- names(coef(f))
  isr <- grepl(":rho$", pn)
  bse <- b$se
  bse[isr] <- apply(atanh(b$replicates[, isr, drop = FALSE]), 2, sd, na.rm = TRUE)
  hse <- sqrt(diag(vcov(f)))
  hse[isr] <- sqrt(diag(vcov(f, "working")))[isr]
  rows[[length(rows) + 1]] <- data.frame(
    dataset = nm, kind = "parameter", name = pn,
    scale = ifelse(isr, "atanh", "natural"), hessian_se = unname(hse),
    bootstrap_se = unname(bse), ratio = unname(bse / hse),
    pass = unname(bse / hse >= 0.9 & bse / hse <= 1.1),
    successful = b$successful, stringsAsFactors = FALSE)
  ef <- switch_effects(f)$table
  bes <- be$se[names(be$se) %in% ef$effect]
  ef <- ef[match(names(bes), ef$effect), ]
  rows[[length(rows) + 1]] <- data.frame(
    dataset = nm, kind = "effect (information)", name = ef$effect, scale = "natural",
    hessian_se = ef$std_error, bootstrap_se = unname(bes),
    ratio = unname(bes) / ef$std_error, pass = NA,
    successful = be$successful, stringsAsFactors = FALSE)
  cat(sprintf("%s: bootstrap %d + %d successful replicates, %.0f s\n", nm,
              b$successful, be$successful, tm))
}
res <- do.call(rbind, rows)
write.csv(res, out, row.names = FALSE)
print(res[, c("dataset", "kind", "name", "scale", "ratio", "pass")], digits = 3, row.names = FALSE)
p <- res[res$kind == "parameter", ]
cat(sprintf("\nAC4(b): %d of %d parameter ratios in [0.90, 1.10]; range %.3f-%.3f\n",
            sum(p$pass), nrow(p), min(p$ratio), max(p$ratio)))
