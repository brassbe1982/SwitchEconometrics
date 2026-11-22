## mc_g1.R -- Monte Carlo study of Generation 1
## (pre-registered design: 04_Validation/MONTE_CARLO_DESIGN.md).
##
## Usage (from the workspace root):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/mc_g1.R \
##       <mode> <library> <outdir> [cores]
##   mode    smoke (R = 50, four cells) | core | ofat | multistart | full
##   library folder with the installed SwitchEconometrics version to test
##   outdir  output folder (raw results and summaries; outside the repository)
##   cores   number of worker processes (default 1)
##
## Random numbers: L'Ecuyer-CMRG, master seed 20261122, one stream per cell,
## replication r uses substream r of its cell (results do not depend on the
## number of cores). Effects (ATT, ATU, ATE, TH, BH1, BH0; from version
## 0.6.0): the estimand of each replication is the same effect evaluated at
## the true parameters on that replication's sample (MONTE_CARLO_DESIGN.md
## s.3); delta-method standard errors.

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args) >= 1) args[1] else "smoke"
lib <- if (length(args) >= 2) args[2] else NULL
outdir <- if (length(args) >= 3) args[3] else file.path(tempdir(), "mc_g1")
cores <- if (length(args) >= 4) as.integer(args[4]) else 1L
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

## ---------------------------------------------------------------- design
base <- list(N = 1000, rho1 = 0.6, rho0 = 0.4, gamma0 = 0.5, gz = -0.4,
             sigma1 = 1, sigma0 = 1, hetero = TRUE, excl = "moderate")
cell <- function(...) { b <- base; a <- list(...); b[names(a)] <- a; b }
core_cells <- unlist(lapply(c(250, 500, 1000, 2000, 5000), function(N)
  lapply(list(c(0, 0), c(0.6, 0.4), c(0.7, -0.5), c(0.85, 0.85)), function(r)
    cell(N = N, rho1 = r[1], rho0 = r[2], R = 1000, group = "core"))),
  recursive = FALSE)
ofat_cells <- unlist(lapply(c(500, 2000), function(N) c(
  lapply(c(0.2, 0.5, 0.8), function(p)
    cell(N = N, gamma0 = qnorm(p) * sqrt(1.25), R = 500,
         group = sprintf("selection_rate_%.1f", p))),
  list(cell(N = N, gz = -1.0, excl = "strong", R = 500, group = "excl_strong"),
       cell(N = N, gz = -0.1, excl = "weak", R = 500, group = "excl_weak"),
       cell(N = N, gz = 0, excl = "none", R = 500, group = "excl_none"),
       cell(N = N, sigma1 = 2, R = 500, group = "variance_ratio_2"),
       cell(N = N, hetero = FALSE, R = 500, group = "homogeneous_slopes")))),
  recursive = FALSE)
ms_cells <- list(cell(N = 500, gz = -0.1, excl = "weak", R = 200,
                      starts = 10, group = "multistart_weak"),
                 cell(N = 500, gz = 0, excl = "none", R = 200, starts = 10,
                      group = "multistart_none"))
smoke_cells <- list(
  cell(N = 1000, rho1 = 0, rho0 = 0, R = 50, group = "smoke"),
  cell(N = 1000, R = 50, group = "smoke"),
  cell(N = 1000, rho1 = 0.7, rho0 = -0.5, R = 50, group = "smoke"),
  cell(N = 500, R = 50, group = "smoke"))
cells <- switch(mode, smoke = smoke_cells, core = core_cells,
                ofat = ofat_cells, multistart = ms_cells,
                full = c(core_cells, ofat_cells, ms_cells),
                stop("unknown mode ", mode))

## true parameters (map order: selection; regime_0 beta, sigma, rho;
## regime_1 beta, sigma, rho)
truth_of <- function(cl) {
  b1 <- if (cl$hetero) c(1.5, 0.8, 0.4) else c(1.5, 0.5, 0.2)
  g <- if (cl$excl == "none") c(cl$gamma0, 0.3) else c(cl$gamma0, 0.3, cl$gz)
  c(g, c(1.0, 0.5, 0.2), cl$sigma0, cl$rho0, b1, cl$sigma1, cl$rho1)
}

## ------------------------------------------------------- one replication
one_rep <- function(cl, seed) {
  suppressPackageStartupMessages(
    library(SwitchEconometrics, lib.loc = lib))
  assign(".Random.seed", seed, envir = globalenv())
  N <- cl$N
  x1 <- rnorm(N); x2 <- rnorm(N); z1 <- rnorm(N)
  u <- rnorm(N)
  e1 <- cl$sigma1 * (cl$rho1 * u + sqrt(1 - cl$rho1^2) * rnorm(N))
  e0 <- cl$sigma0 * (cl$rho0 * u + sqrt(1 - cl$rho0^2) * rnorm(N))
  b1 <- if (cl$hetero) c(1.5, 0.8, 0.4) else c(1.5, 0.5, 0.2)
  S <- as.integer(cl$gamma0 + 0.3 * x1 + cl$gz * z1 + u > 0)
  y <- ifelse(S == 1, b1[1] + b1[2] * x1 + b1[3] * x2 + e1,
              1.0 + 0.5 * x1 + 0.2 * x2 + e0)
  d <- data.frame(S, y, x1, x2, z1)
  sel <- if (cl$excl == "none") S ~ x1 else S ~ x1 + z1
  out <- list()
  for (m in c("fiml", "two_step")) {
    t0 <- proc.time()[["elapsed"]]
    ctl <- switch_control(starts = cl$starts %||% 1L)
    f <- tryCatch(suppressWarnings(suppressMessages(
      switch_fit(sel, list(regime_0 = y ~ x1 + x2, regime_1 = y ~ x1 + x2),
                 data = d, method = m, control = ctl))),
      error = function(e) e)
    tm <- proc.time()[["elapsed"]] - t0
    if (inherits(f, "error")) {
      out[[m]] <- list(ok = FALSE, error = conditionMessage(f), time = tm)
      next
    }
    est <- coef(f)
    se <- sqrt(pmax(diag(vcov(f)), 0))
    se_w <- if (m == "fiml") sqrt(pmax(diag(vcov(f, "working")), 0)) else NA
    eff <- if ("switch_effects" %in% getNamespaceExports("SwitchEconometrics"))
      tryCatch(switch_effects(f), error = function(e) NULL)
    eff_true <- if (!is.null(eff)) SwitchEconometrics:::se_eff_values(
      stats::setNames(truth_of(cl), names(est)), f$data, f$map)
    out[[m]] <- list(
      eff_est = if (!is.null(eff)) stats::setNames(eff$table$estimate, eff$table$effect),
      eff_se = if (!is.null(eff)) stats::setNames(eff$table$std_error, eff$table$effect),
      eff_true = eff_true,
      ok = TRUE, est = est, se = se, se_w = se_w,
      est_w = if (m == "fiml") coef(f, "working") else NA,
      code = f$convergence$code, loglik = f$loglik,
      grad = f$convergence$gradient_max,
      boundary = length(f$diagnostics$flags$rho_boundary) > 0,
      n_local = if (m == "fiml") f$diagnostics$local_maxima else NA,
      two_step_best = if (m == "fiml") f$starts$origin[f$starts$best] == "two_step" else NA,
      time = tm)
  }
  out
}
`%||%` <- function(a, b) if (is.null(a)) b else a

## ---------------------------------------------------------------- run
RNGkind("L'Ecuyer-CMRG")
set.seed(20261122)
s_cell <- .Random.seed
run_cell <- function(k) {
  cl <- cells[[k]]
  s <- s_cell
  for (j in seq_len(k)) s <- parallel::nextRNGStream(s)
  seeds <- vector("list", cl$R)
  sr <- s
  for (r in seq_len(cl$R)) { sr <- parallel::nextRNGSubStream(sr); seeds[[r]] <- sr }
  t0 <- Sys.time()
  res <- if (cores > 1) {
    cluster <- parallel::makeCluster(cores, rscript_args = "--no-init-file")
    on.exit(parallel::stopCluster(cluster))
    parallel::clusterExport(cluster, c("lib", "%||%", "one_rep"),
                            envir = globalenv())
    parallel::parLapply(cluster, seeds, function(s, cl) one_rep(cl, s), cl = cl)
  } else lapply(seeds, function(s) one_rep(cl, s))
  list(cell = cl, truth = truth_of(cl), res = res,
       time = as.numeric(difftime(Sys.time(), t0, units = "secs")))
}

summarise_cell <- function(cr) {
  cl <- cr$cell; tr <- cr$truth
  rows <- list()
  for (m in c("fiml", "two_step")) {
    rr <- lapply(cr$res, `[[`, m)
    ok <- vapply(rr, function(x) isTRUE(x$ok) && identical(x$code, 0L), logical(1))
    if (!any(ok)) next
    E <- do.call(rbind, lapply(rr[ok], `[[`, "est"))
    SE <- do.call(rbind, lapply(rr[ok], `[[`, "se"))
    nm <- colnames(E)
    isrho <- grepl(":rho$", nm)
    for (k in seq_along(nm)) {
      e <- E[, k]; s <- SE[, k]; t <- tr[k]
      if (m == "fiml" && isrho[k]) {
        ew <- vapply(rr[ok], function(x) x$est_w[[k]], numeric(1))
        sw <- vapply(rr[ok], function(x) x$se_w[[k]], numeric(1))
        cover <- mean(abs(ew - atanh(t)) <= 1.96 * sw)
      } else cover <- mean(abs(e - t) <= 1.96 * s)
      rows[[length(rows) + 1]] <- data.frame(
        group = cl$group, N = cl$N, rho1 = cl$rho1, rho0 = cl$rho0,
        method = m, parameter = nm[k], truth = t, R = length(rr),
        converged = sum(ok), bias = mean(e) - t,
        rel_bias = if (abs(t) >= 0.2) (mean(e) - t) / abs(t) else NA,
        rmse = sqrt(mean((e - t)^2)), emp_sd = sd(e),
        mean_se = mean(s), se_ratio = mean(s) / sd(e), coverage = cover,
        boundary = mean(vapply(rr[ok], function(x) isTRUE(x$boundary), logical(1))),
        median_time = median(vapply(rr, function(x) x$time, numeric(1))),
        stringsAsFactors = FALSE)
    }
    ## effects: estimand varies by replication (sample-conditional effect)
    okE <- ok & vapply(rr, function(x) !is.null(x$eff_est), logical(1))
    if (any(okE)) {
      EE <- do.call(rbind, lapply(rr[okE], `[[`, "eff_est"))
      ES <- do.call(rbind, lapply(rr[okE], `[[`, "eff_se"))
      ET <- do.call(rbind, lapply(rr[okE], `[[`, "eff_true"))
      for (k in colnames(EE)) {
        dev <- EE[, k] - ET[, k]
        t <- mean(ET[, k])
        rows[[length(rows) + 1]] <- data.frame(
          group = cl$group, N = cl$N, rho1 = cl$rho1, rho0 = cl$rho0,
          method = m, parameter = paste0("effect:", k), truth = t,
          R = length(rr), converged = sum(okE), bias = mean(dev),
          rel_bias = if (abs(t) >= 0.2) mean(dev) / abs(t) else NA,
          rmse = sqrt(mean(dev^2)), emp_sd = sd(dev), mean_se = mean(ES[, k]),
          se_ratio = mean(ES[, k]) / sd(dev),
          coverage = mean(abs(dev) <= 1.96 * ES[, k]), boundary = NA,
          median_time = NA, stringsAsFactors = FALSE)
      }
    }
  }
  do.call(rbind, rows)
}

all_sum <- list()
for (k in seq_along(cells)) {
  cr <- run_cell(k)
  saveRDS(cr, file.path(outdir, sprintf("cell_%03d.rds", k)))
  s <- summarise_cell(cr)
  all_sum[[k]] <- s
  cat(sprintf("cell %d/%d (%s, N = %d, rho = %g/%g): %.0f s, FIML converged %d/%d\n",
              k, length(cells), cr$cell$group, cr$cell$N, cr$cell$rho1,
              cr$cell$rho0, cr$time,
              s$converged[s$method == "fiml"][1], s$R[1]))
}
summary_tab <- do.call(rbind, all_sum)
write.csv(summary_tab, file.path(outdir, sprintf("summary_%s.csv", mode)),
          row.names = FALSE)
cat("summary written to", file.path(outdir, sprintf("summary_%s.csv", mode)), "\n")
