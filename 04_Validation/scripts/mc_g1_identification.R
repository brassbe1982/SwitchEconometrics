## mc_g1_identification.R -- supplementary to the G1 Monte Carlo study (not
## pre-registered): how the identification diagnostics I5 (strength of the
## exclusion, heuristic chi2/df < 10) and I6 (collinearity of the correction
## term, heuristic R2 > 0.95) behave in the exclusion-strength cells, and how
## their flags relate to the FIML performance on the same replications.
## Econometric gate question 5 (GENERATION_1.md s.3) asked for these heuristic
## thresholds to be revisited after the Monte Carlo study.
##
## It regenerates each replication's data from the seed scheme of mc_g1.R
## (identical data), runs switch_validate() on a two-step fit, and links the
## result to the stored FIML estimates of that replication.
##
## Usage (from the workspace root):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/mc_g1_identification.R \
##       <library> <run folder of mc_g1.R full> <output .csv> [max replications per cell]
args <- commandArgs(trailingOnly = TRUE)
lib <- args[1]; rundir <- args[2]; out <- args[3]
maxr <- if (length(args) >= 4) as.integer(args[4]) else Inf   # testing only
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
suppressPackageStartupMessages(library(SwitchEconometrics, lib.loc = lib))
RNGkind("L'Ecuyer-CMRG"); set.seed(20261122); s_cell <- .Random.seed

## cells: core N = 500 and 2000 at (0.6, 0.4) (moderate exclusion, -0.4) and
## the OFAT exclusion cells (strong -1.0, weak -0.1, none) at N = 500 and 2000
files <- sort(list.files(rundir, "^cell_[0-9]+\\.rds$", full.names = TRUE))
info <- lapply(files, function(f) readRDS(f)$cell)
want <- which(vapply(info, function(cl)
  (cl$group == "core" && cl$rho1 == 0.6 && cl$N %in% c(500, 2000)) ||
    (cl$group %in% c("excl_strong", "excl_weak", "excl_none")), logical(1)))
num <- function(s, pat) as.numeric(sub(pat, "\\1", s))
rows <- list()
for (k in want) {
  cr <- readRDS(files[k]); cl <- cr$cell
  pn <- names(Filter(function(x) isTRUE(x$ok), lapply(cr$res, `[[`, "fiml"))[[1]]$est)
  tr <- stats::setNames(cr$truth, pn)
  ir <- grep(":rho$", pn)                       # regime_0:rho, regime_1:rho
  s <- s_cell; for (j in seq_len(k)) s <- parallel::nextRNGStream(s)
  sr <- s
  for (r in seq_len(min(cl$R, maxr))) {
    sr <- parallel::nextRNGSubStream(sr)
    assign(".Random.seed", sr, envir = globalenv())
    N <- cl$N
    x1 <- rnorm(N); x2 <- rnorm(N); z1 <- rnorm(N); u <- rnorm(N)
    e1 <- cl$sigma1 * (cl$rho1 * u + sqrt(1 - cl$rho1^2) * rnorm(N))
    e0 <- cl$sigma0 * (cl$rho0 * u + sqrt(1 - cl$rho0^2) * rnorm(N))
    b1 <- if (cl$hetero) c(1.5, 0.8, 0.4) else c(1.5, 0.5, 0.2)
    S <- as.integer(cl$gamma0 + 0.3 * x1 + cl$gz * z1 + u > 0)
    y <- ifelse(S == 1, b1[1] + b1[2] * x1 + b1[3] * x2 + e1,
                1.0 + 0.5 * x1 + 0.2 * x2 + e0)
    d <- data.frame(S, y, x1, x2, z1)
    sel <- if (cl$excl == "none") S ~ x1 else S ~ x1 + z1
    f <- suppressWarnings(suppressMessages(switch_fit(
      sel, list(regime_0 = y ~ x1 + x2, regime_1 = y ~ x1 + x2), data = d,
      method = "two_step")))
    tab <- switch_validate(f)$table
    i5 <- tab[tab$code == "I5", ]
    i6 <- tab[tab$code == "I6", ]
    fm <- cr$res[[r]]$fiml
    okf <- isTRUE(fm$ok) && identical(fm$code, 0L)
    cov_rho <- if (okf) abs(fm$est_w[ir] - atanh(tr[ir])) <= 1.96 * fm$se_w[ir] else c(NA, NA)
    rows[[length(rows) + 1]] <- data.frame(
      cell = cl$group, N = N, rep = r,
      i5_status = if (nrow(i5)) i5$status[1] else "none",
      i5_ratio = if (nrow(i5) && grepl("chi2/df", i5$value[1]))
        num(i5$value[1], ".*chi2/df = ([0-9.eE+-]+).*") else NA,
      i6_status_max = if (any(i6$status == "warning")) "warning" else "ok",
      i6_r2_max = max(num(i6$value, "R2 = ([0-9.]+),.*")),
      fiml_ok = okf,
      rho0_err = if (okf) fm$est[ir[1]] - tr[ir[1]] else NA,
      rho1_err = if (okf) fm$est[ir[2]] - tr[ir[2]] else NA,
      rho0_cover = cov_rho[1], rho1_cover = cov_rho[2],
      stringsAsFactors = FALSE)
  }
  cat(sprintf("cell %d (%s, N = %d) done\n", k, cl$group, cl$N))
}
res <- do.call(rbind, rows)
res$cell[res$cell == "core"] <- "excl_moderate (base)"
write.csv(res, out, row.names = FALSE)

## summary by cell
sm <- do.call(rbind, lapply(split(res, list(res$cell, res$N), drop = TRUE), function(x) {
  fl5 <- x$i5_status %in% c("warning", "note")
  data.frame(cell = x$cell[1], N = x$N[1], R = nrow(x),
             i5_median_ratio = stats::median(x$i5_ratio, na.rm = TRUE),
             i5_flag_share = mean(fl5), i5_warning_share = mean(x$i5_status == "warning"),
             i6_median_r2 = stats::median(x$i6_r2_max), i6_flag_share = mean(x$i6_status_max == "warning"),
             rho_bias = mean(c(x$rho0_err, x$rho1_err), na.rm = TRUE),
             rho_cover_all = mean(c(x$rho0_cover, x$rho1_cover), na.rm = TRUE),
             rho_cover_i5_flagged = if (any(fl5)) mean(c(x$rho0_cover[fl5], x$rho1_cover[fl5]), na.rm = TRUE) else NA,
             rho_cover_i5_clear = if (any(!fl5)) mean(c(x$rho0_cover[!fl5], x$rho1_cover[!fl5]), na.rm = TRUE) else NA)
}))
sm <- sm[order(sm$N, sm$cell), ]
print(sm, digits = 3, row.names = FALSE)
write.csv(sm, sub("\\.csv$", "_summary.csv", out), row.names = FALSE)
