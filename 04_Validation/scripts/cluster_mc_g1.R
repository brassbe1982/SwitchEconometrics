## cluster_mc_g1.R -- supplementary Monte Carlo (WP1.8): cluster-robust
## standard errors under clustered data, for FIML and two-step. No other R
## package computes cluster-robust standard errors for the two-step ESR, so
## this simulation is their external check (BENCHMARK_G1.md section 4.5).
## Not pre-registered and not gated; the C4/C5 ranges of
## MONTE_CARLO_DESIGN.md are shown for reference only.
##
## Usage (from the workspace root):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/cluster_mc_g1.R \
##       <library> <output .csv> [R] [cores]
##
## Design (fixed before the run): N = 2000 in G = 100 clusters of 20;
## (rho1, rho0) = (0.6, 0.4); the base coefficients of the Monte Carlo study.
## Clustering: x1 and z1 have a cluster component with half their variance;
## u and the outcome noise each have a cluster component with 30% of their
## variance (variances stay 1, so the marginal model and the true parameters
## are those of the base design). Per replication: FIML with Hessian and
## cluster standard errors; two-step with model-based and cluster standard
## errors. RNG: L'Ecuyer-CMRG, seed 20261123, substream r for replication r.

args <- commandArgs(trailingOnly = TRUE)
lib <- normalizePath(args[1]); out <- args[2]
R <- if (length(args) >= 3) as.integer(args[3]) else 500L
cores <- if (length(args) >= 4) as.integer(args[4]) else 1L
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)

truth <- c(0.5, 0.3, -0.4,  1.0, 0.5, 0.2, 1, 0.4,  1.5, 0.8, 0.4, 1, 0.6)

one_rep <- function(seed, lib) {
  suppressPackageStartupMessages(library(SwitchEconometrics, lib.loc = lib))
  assign(".Random.seed", seed, envir = globalenv())
  G <- 100L; m <- 20L; N <- G * m
  cl <- rep(seq_len(G), each = m)
  cg <- function(share) sqrt(share) * rnorm(G)[cl] + sqrt(1 - share) * rnorm(N)
  x1 <- cg(0.5); x2 <- rnorm(N); z1 <- cg(0.5)
  u <- cg(0.3)
  e1 <- 0.6 * u + sqrt(1 - 0.36) * cg(0.3)
  e0 <- 0.4 * u + sqrt(1 - 0.16) * cg(0.3)
  S <- as.integer(0.5 + 0.3 * x1 - 0.4 * z1 + u > 0)
  y <- ifelse(S == 1, 1.5 + 0.8 * x1 + 0.4 * x2 + e1, 1.0 + 0.5 * x1 + 0.2 * x2 + e0)
  d <- data.frame(S, y, x1, x2, z1, cl)
  fml <- list(regime_0 = y ~ x1 + x2, regime_1 = y ~ x1 + x2)
  fit <- function(...) tryCatch(suppressWarnings(suppressMessages(
    switch_fit(S ~ x1 + z1, fml, data = d, ...))), error = function(e) NULL)
  res <- list()
  fh <- fit(); fc <- fit(cluster = ~cl)
  if (!is.null(fh) && !is.null(fc) && fh$convergence$code == 0L) {
    res$fiml_hessian <- list(est = coef(fh), se = sqrt(diag(vcov(fh))))
    res$fiml_cluster <- list(est = coef(fc), se = sqrt(diag(vcov(fc))))
  }
  th <- fit(method = "two_step"); tc <- fit(method = "two_step", cluster = ~cl)
  if (!is.null(th) && !is.null(tc)) {
    pick <- function(f) {
      ts <- f$two_step
      ith <- vapply(ts$index_psi[-1], function(i) i[length(i)], numeric(1))
      list(est = c(coef(f), theta = ts$psi[ith]),
           se = c(sqrt(diag(vcov(f))), theta = sqrt(diag(ts$vcov_psi)[ith])))
    }
    res$two_step_model <- pick(th)
    res$two_step_cluster <- pick(tc)
  }
  res
}

RNGkind("L'Ecuyer-CMRG")
set.seed(20261123)
s <- .Random.seed
seeds <- vector("list", R)
for (r in seq_len(R)) { s <- parallel::nextRNGSubStream(s); seeds[[r]] <- s }
t0 <- proc.time()[["elapsed"]]
if (cores > 1L) {
  cl <- parallel::makeCluster(cores)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  reps <- parallel::parLapply(cl, seeds, one_rep, lib = lib)
} else {
  reps <- lapply(seeds, one_rep, lib = lib)
}
elapsed <- proc.time()[["elapsed"]] - t0

theta_true <- c(0.4, 0.6)            # sigma0 rho0, sigma1 rho1 (sigma = 1)
rows <- list()
for (m in c("fiml_hessian", "fiml_cluster", "two_step_model", "two_step_cluster")) {
  ok <- Filter(Negate(is.null), lapply(reps, `[[`, m))
  E <- do.call(rbind, lapply(ok, `[[`, "est")); S <- do.call(rbind, lapply(ok, `[[`, "se"))
  tr <- c(truth, if (grepl("two_step", m)) theta_true)
  for (j in seq_len(ncol(E))) {
    if (all(!is.finite(S[, j]))) next
    lo <- E[, j] - qnorm(0.975) * S[, j]; hi <- E[, j] + qnorm(0.975) * S[, j]
    rows[[length(rows) + 1L]] <- data.frame(
      method = m, parameter = colnames(E)[j], truth = tr[j], R = nrow(E),
      bias = mean(E[, j]) - tr[j], emp_sd = sd(E[, j]), mean_se = mean(S[, j], na.rm = TRUE),
      se_ratio = mean(S[, j], na.rm = TRUE) / sd(E[, j]),
      coverage = mean(lo <= tr[j] & tr[j] <= hi, na.rm = TRUE), stringsAsFactors = FALSE)
  }
}
res <- do.call(rbind, rows)
write.csv(res, out, row.names = FALSE)
cat(sprintf("%d replications, %.0f s; written %s\n", R, elapsed, out))
print(aggregate(cbind(se_ratio, coverage) ~ method, res, function(v) round(range(v), 3)))
