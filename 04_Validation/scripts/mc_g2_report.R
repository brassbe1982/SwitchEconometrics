## mc_g2_report.R -- gate evaluation of the Generation 2 Monte Carlo study
## against the pre-registered thresholds of MONTE_CARLO_DESIGN.md s.8.4 and
## the gated cells of s.8.3 and s.8.6 (approved by the owner on 23 November
## 2026; the thresholds below are copied from those sections and must not
## be edited after results are seen).
##
## Usage (from the workspace root):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/mc_g2_report.R <run folder> [<run folder> ...]
## Each run folder holds mc_g2_summary.csv, mc_g2_cells.csv and
## run_info.txt; several folders (one per group of designs) are stacked. A
## cell present in more than one folder is taken from the last one named.
## Writes into SwitchEconometrics/04_Validation/results/: mc_g2_summary.csv,
## mc_g2_cells.csv, gate_checks_G2.csv and MC_G2_generated.md.

runs <- commandArgs(trailingOnly = TRUE)
stopifnot(length(runs) >= 1L)
res <- file.path("SwitchEconometrics", "04_Validation", "results")

## cells file of the WP2.1 driver (one row per cell) -> one row per method
norm_cells <- function(C) {
  if ("method" %in% names(C)) return(C)
  mk <- function(m, time, errors, boundary, rho_out, i6) data.frame(
    cell = C$cell, design = C$design, N = C$N, rho = C$rho, R = C$R,
    method = m, share = formatC(C$share, format = "f", digits = 3),
    time = time, elapsed = C$elapsed, errors = errors, not_converged = NA,
    boundary = boundary, rho_out = rho_out, I6_warning = i6,
    stringsAsFactors = FALSE)
  o <- rbind(mk("fiml", C$time_fiml, C$errors_fiml, C$boundary_fiml, 0L,
                C$I6_warning_fiml),
             mk("two_step", C$time_two_step, 0L, 0L, C$rho_out_two_step, 0L))
  o[order(match(o$cell, C$cell)), ]
}
S <- NULL; C <- NULL; info <- character()
for (run in runs) {
  s <- utils::read.csv(file.path(run, "mc_g2_summary.csv"), stringsAsFactors = FALSE)
  cc <- norm_cells(utils::read.csv(file.path(run, "mc_g2_cells.csv"),
                                   stringsAsFactors = FALSE))
  cc$share <- as.character(cc$share)
  S <- rbind(S[!S$cell %in% s$cell, ], s)
  C <- rbind(C[!C$cell %in% cc$cell, ], cc)
  ri <- readLines(file.path(run, "run_info.txt"))
  info <- c(info, sprintf("`%s`: %s", basename(run), paste(ri, collapse = "; ")))
}

## ------------------------------------------------- pre-registered rules
thr <- list(rel_bias = 0.05, abs_bias_small = 0.01, dep_bias = 0.03,
            dep_bias_2d = 0.05, rootn = c(0.8, 1.2), se_ratio = c(0.90, 1.10),
            coverage = c(0.93, 0.97), conv_main = 0.99, conv_2d = 0.97,
            eff_rel = 0.05, eff_abs = 0.02, d_a_bias = 0.03)
## Gated cells (sections 8.3 and 8.6). "full": bias, standard-error ratio,
## coverage (R = 1000), convergence and root-N; "bias": bias and
## convergence only.
gate_fiml <- function(d, m, N) {
  if (d %in% c("H", "T") && m == "fiml" && N >= 1000) return("full")
  if (d == "L" && m == "fiml_lee" && N >= 2000) return("full")
  if (d == "G" && m == "fiml_ns" && N == 5000) return("bias")
  if (d == "L8" && m == "fiml_lee" && N == 8000) return("bias")
  "none"
}
gate_ts_cov <- function(d, m, N) {
  (d %in% c("H", "T") && m == "two_step" && N >= 2000) ||
    (d == "L" && m == "ts_lee" && N == 5000)
}
gate_d <- function(d, m, N) d == "D" && m %in% c("ts_dmf", "ts_bfg1") && N == 5000
dep_limit <- function(d) if (d == "G") thr$dep_bias_2d else thr$dep_bias
conv_limit <- function(d) if (d == "G") thr$conv_2d else thr$conv_main

checks <- list()
add <- function(row, criterion, value, limit, pass) {
  checks[[length(checks) + 1L]] <<- data.frame(
    cell = row$cell, design = row$design, N = row$N, rho = row$rho,
    method = row$method, quantity = row$quantity, criterion = criterion,
    value = value, limit = limit, pass = isTRUE(pass), stringsAsFactors = FALSE)
}
inr <- function(x, r) is.finite(x) && x >= r[1] && x <= r[2]
S$gate <- vapply(seq_len(nrow(S)), function(i)
  gate_fiml(S$design[i], S$method[i], S$N[i]), character(1))
for (i in seq_len(nrow(S))) {
  r <- S[i, ]
  if (r$gate != "none") {
    if (r$kind %in% c("coefficient", "scale")) {
      if (abs(r$truth) >= 0.2) {
        add(r, "relative bias", abs(r$rel_bias), "<= 0.05",
            abs(r$rel_bias) <= thr$rel_bias)
      } else {
        add(r, "absolute bias", abs(r$bias), "<= 0.01",
            abs(r$bias) <= thr$abs_bias_small)
      }
    } else if (r$kind == "dependence") {
      dl <- dep_limit(r$design)
      add(r, "absolute bias (rho)", abs(r$bias), sprintf("<= %.2f", dl),
          abs(r$bias) <= dl)
    } else if (r$kind == "effect") {
      if (abs(r$truth) >= 0.2) {
        add(r, "relative bias (effect)", abs(r$rel_bias), "<= 0.05",
            abs(r$rel_bias) <= thr$eff_rel)
      } else {
        add(r, "absolute bias (effect)", abs(r$bias), "<= 0.02",
            abs(r$bias) <= thr$eff_abs)
      }
    }
    if (r$gate == "full") {
      add(r, "standard-error ratio", r$se_ratio, "[0.90, 1.10]",
          inr(r$se_ratio, thr$se_ratio))
      if (r$R == 1000) {
        add(r, "95% coverage", r$coverage, "[0.93, 0.97]",
            inr(r$coverage, thr$coverage))
      }
    }
  }
  if (gate_ts_cov(r$design, r$method, r$N) && r$R == 1000 &&
      (r$kind == "correction" ||
       (r$kind == "coefficient" && !startsWith(r$quantity, "selection")))) {
    add(r, "95% coverage (two-step)", r$coverage, "[0.93, 0.97]",
        inr(r$coverage, thr$coverage))
  }
  if (gate_d(r$design, r$method, r$N)) {
    if (r$kind == "coefficient" && !startsWith(r$quantity, "selection")) {
      add(r, "relative bias of beta (design D)", abs(r$rel_bias), "<= 0.05",
          abs(r$rel_bias) <= thr$rel_bias)
    } else if (r$kind == "correction") {
      add(r, "absolute bias of a_jk (design D)", abs(r$bias), "<= 0.03",
          abs(r$bias) <= thr$d_a_bias)
    }
  }
}
## convergence, once per gated cell
cv <- unique(S[S$gate != "none",
               c("cell", "design", "N", "rho", "method", "convergence_rate")])
for (i in seq_len(nrow(cv))) {
  r <- cv[i, ]; r$quantity <- "(all)"
  cl <- conv_limit(r$design)
  add(r, "convergence rate", r$convergence_rate, sprintf(">= %.2f", cl),
      r$convergence_rate >= cl)
}
## root-N behaviour between the smallest and largest gated N
G <- S[S$gate == "full", ]
for (key in unique(paste(G$design, G$rho, G$method, G$quantity))) {
  g <- G[paste(G$design, G$rho, G$method, G$quantity) == key, ]
  if (nrow(g) < 2L) next
  a <- g[which.min(g$N), ]; b <- g[which.max(g$N), ]
  ratio <- sqrt(b$N) * b$rmse / (sqrt(a$N) * a$rmse)
  r <- b; r$cell <- sprintf("%s rho %s: N %d vs %d", b$design, format(b$rho),
                           a$N, b$N)
  add(r, "root-N ratio of RMSE", ratio, "[0.8, 1.2]", inr(ratio, thr$rootn))
}
K <- do.call(rbind, checks)
S$gate <- NULL

utils::write.csv(S, file.path(res, "mc_g2_summary.csv"), row.names = FALSE)
utils::write.csv(C, file.path(res, "mc_g2_cells.csv"), row.names = FALSE)
utils::write.csv(K, file.path(res, "gate_checks_G2.csv"), row.names = FALSE)

## ---------------------------------------------------------------- report
f3 <- function(x) ifelse(is.na(x), "", formatC(x, format = "f", digits = 3))
i0 <- function(x) ifelse(is.na(x), "", formatC(x, format = "d"))
md <- c("# Monte Carlo results, Generation 2 (generated)", "",
        "Generated by `04_Validation/scripts/mc_g2_report.R`; do not edit.",
        "Design and thresholds: MONTE_CARLO_DESIGN.md section 8.", "",
        "Runs:", "", paste0("- ", info), "",
        sprintf("Gated checks: **%d, passed %d, failed %d.**", nrow(K),
                sum(K$pass), sum(!K$pass)), "")
tab <- stats::aggregate(pass ~ design + method + criterion, K, function(p)
  sprintf("%d / %d", sum(p), length(p)))
tab <- tab[order(match(tab$design, unique(K$design)), tab$method), ]
md <- c(md, "## Gated checks by design, estimator and criterion", "",
        "| Design | Estimator | Criterion | Passed |", "| --- | --- | --- | --- |",
        sprintf("| %s | %s | %s | %s |", tab$design, tab$method, tab$criterion,
                tab$pass), "")
Fz <- K[!K$pass, ]
md <- c(md, "## Failed gated checks", "")
md <- c(md, if (!nrow(Fz)) "None." else c(
  "| Cell | Estimator | Quantity | Criterion | Value | Limit |",
  "| --- | --- | --- | --- | --- | --- |",
  sprintf("| %s | %s | %s | %s | %s | %s |", Fz$cell, Fz$method, Fz$quantity,
          Fz$criterion, f3(Fz$value), Fz$limit)), "")
md <- c(md, "## Cells and estimators", "",
        "Errors: fits that stopped with an error. Not converged: fits that returned without meeting the convergence criteria (not recorded by the WP2.1 driver). Seconds: mean time of one fit.",
        "",
        "| Cell | R | Estimator | Regime shares | Errors | Not converged | rho at boundary | two-step rho outside (-1, 1) | I6 warnings | Seconds |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
        sprintf("| %s | %d | %s | %s | %s | %s | %s | %s | %s | %s |", C$cell, C$R,
                C$method, C$share, i0(C$errors), i0(C$not_converged),
                i0(C$boundary), i0(C$rho_out), i0(C$I6_warning), f3(C$time)), "")
for (m in unique(S$method)) {
  md <- c(md, sprintf("## All cells: estimator `%s`", m), "",
          "| Cell | Quantity | Truth | Bias | RMSE | SE ratio | Sandwich SE ratio | Coverage | Converged |",
          "| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
  s <- S[S$method == m, ]
  md <- c(md, sprintf("| %s | %s | %s | %s | %s | %s | %s | %s | %s |", s$cell,
                      s$quantity, f3(s$truth), formatC(s$bias, format = "f",
                                                       digits = 4),
                      formatC(s$rmse, format = "f", digits = 4),
                      f3(s$se_ratio), f3(s$se_ratio_sandwich), f3(s$coverage),
                      f3(s$convergence_rate)), "")
}
writeLines(md, file.path(res, "MC_G2_generated.md"), useBytes = TRUE)
cat(sprintf("gated checks: %d, passed %d, failed %d\n", nrow(K), sum(K$pass),
            sum(!K$pass)))
if (nrow(Fz)) print(Fz[, c("cell", "method", "quantity", "criterion", "value")],
                    row.names = FALSE)
