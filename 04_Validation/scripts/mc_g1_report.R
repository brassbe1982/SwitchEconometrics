## mc_g1_report.R -- evaluate the G1 Monte Carlo study against the
## pre-registered thresholds (04_Validation/MONTE_CARLO_DESIGN.md s.5) and
## write the generated tables.
##
## Usage (from the workspace root):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/mc_g1_report.R \
##       <run folder> <output .md> [package version]
## The run folder holds the cell_*.rds files written by mc_g1.R (mode full).
## Outputs: the markdown file and, next to it, gate_checks_G1.csv and
## mc_g1_summary.csv. Thresholds are NOT parameters of this script.

args <- commandArgs(trailingOnly = TRUE)
run <- args[1]
out_md <- args[2]
version <- if (length(args) >= 3) args[3] else "unknown"
`%||%` <- function(a, b) if (is.null(a)) b else a
out_dir <- dirname(out_md)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

files <- sort(list.files(run, "^cell_[0-9]+\\.rds$", full.names = TRUE))
stopifnot(length(files) > 0)
cells <- lapply(files, readRDS)

## per-cell summaries (same definitions as mc_g1.R)
source_sum <- function(cr) {
  cl <- cr$cell; tr <- cr$truth
  rows <- list()
  for (m in c("fiml", "two_step")) {
    rr <- lapply(cr$res, `[[`, m)
    ok <- vapply(rr, function(x) isTRUE(x$ok) && identical(x$code, 0L), logical(1))
    conv <- mean(ok)
    if (!any(ok)) next
    E <- do.call(rbind, lapply(rr[ok], `[[`, "est"))
    SE <- do.call(rbind, lapply(rr[ok], `[[`, "se"))
    nm <- colnames(E)
    for (k in seq_along(nm)) {
      e <- E[, k]; s <- SE[, k]; t <- tr[k]
      cover <- if (m == "fiml" && grepl(":rho$", nm[k])) {
        ew <- vapply(rr[ok], function(x) x$est_w[[k]], numeric(1))
        sw <- vapply(rr[ok], function(x) x$se_w[[k]], numeric(1))
        mean(abs(ew - atanh(t)) <= 1.96 * sw)
      } else mean(abs(e - t) <= 1.96 * s)
      rows[[length(rows) + 1]] <- data.frame(
        group = cl$group, N = cl$N, rho1 = cl$rho1, rho0 = cl$rho0,
        method = m, kind = "parameter", parameter = nm[k], truth = t,
        R = length(rr), conv = conv, bias = mean(e) - t,
        rel_bias = if (abs(t) >= 0.2) (mean(e) - t) / abs(t) else NA,
        rmse = sqrt(mean((e - t)^2)), emp_sd = sd(e), mean_se = mean(s),
        se_ratio = mean(s) / sd(e), coverage = cover,
        boundary = mean(vapply(rr[ok], function(x) isTRUE(x$boundary), logical(1))),
        stringsAsFactors = FALSE)
    }
    if (m == "two_step") {
      okL <- ok & vapply(rr, function(x) !is.null(x$lambda), logical(1))
      if (any(okL)) {
        LE <- do.call(rbind, lapply(rr[okL], function(x) x$lambda$est))
        LS <- do.call(rbind, lapply(rr[okL], function(x) x$lambda$se))
        lt <- rr[okL][[1]]$lambda$truth
        for (k in 1:2) {
          e <- LE[, k]; s <- LS[, k]; t <- lt[k]
          rows[[length(rows) + 1]] <- data.frame(
            group = cl$group, N = cl$N, rho1 = cl$rho1, rho0 = cl$rho0,
            method = m, kind = "lambda",
            parameter = c("regime_0:lambda", "regime_1:lambda")[k], truth = t,
            R = length(rr), conv = conv, bias = mean(e) - t,
            rel_bias = if (abs(t) >= 0.2) (mean(e) - t) / abs(t) else NA,
            rmse = sqrt(mean((e - t)^2)), emp_sd = sd(e), mean_se = mean(s),
            se_ratio = mean(s) / sd(e),
            coverage = mean(abs(e - t) <= 1.96 * s), boundary = NA,
            stringsAsFactors = FALSE)
        }
      }
    }
    ## sandwich standard errors (design s.3; reported, not gated): FIML robust
    ## sandwich and the two-step stacked M-estimation sandwich, same estimates
    okS <- ok & vapply(rr, function(x) !is.null(x$sand), logical(1))
    if (any(okS)) {
      lab <- if (m == "fiml") "fiml_sandwich" else "two_step_robust"
      mk <- function(kind, par, t, e, s, cover) data.frame(
        group = cl$group, N = cl$N, rho1 = cl$rho1, rho0 = cl$rho0,
        method = lab, kind = kind, parameter = par, truth = t,
        R = length(rr), conv = mean(okS), bias = mean(e) - t,
        rel_bias = if (abs(t) >= 0.2) (mean(e) - t) / abs(t) else NA,
        rmse = sqrt(mean((e - t)^2)), emp_sd = sd(e), mean_se = mean(s),
        se_ratio = mean(s) / sd(e), coverage = cover, boundary = NA,
        stringsAsFactors = FALSE)
      E2 <- do.call(rbind, lapply(rr[okS], `[[`, "est"))
      S2 <- do.call(rbind, lapply(rr[okS], function(x) x$sand$se))
      for (k in seq_along(nm)) {
        e <- E2[, k]; s <- S2[, k]; t <- tr[k]
        cover <- if (m == "fiml" && grepl(":rho$", nm[k])) {
          ew <- vapply(rr[okS], function(x) x$est_w[[k]], numeric(1))
          sw <- vapply(rr[okS], function(x) x$sand$se_w[[k]], numeric(1))
          mean(abs(ew - atanh(t)) <= 1.96 * sw)
        } else mean(abs(e - t) <= 1.96 * s)
        rows[[length(rows) + 1]] <- mk("parameter", nm[k], t, e, s, cover)
      }
      if (m == "two_step") {
        okL2 <- okS & vapply(rr, function(x) !is.null(x$lambda), logical(1))
        LE <- do.call(rbind, lapply(rr[okL2], function(x) x$lambda$est))
        LS <- do.call(rbind, lapply(rr[okL2], function(x) x$sand$lambda_se))
        lt <- rr[okL2][[1]]$lambda$truth
        for (k in 1:2) {
          e <- LE[, k]; s <- LS[, k]; t <- lt[k]
          rows[[length(rows) + 1]] <- mk("lambda",
            c("regime_0:lambda", "regime_1:lambda")[k], t, e, s,
            mean(abs(e - t) <= 1.96 * s))
        }
        same <- vapply(rr[okS], function(x) isTRUE(x$sand$same_est), logical(1))
        if (!all(same)) warning(sprintf("cell %s N = %d: robust refit changed %d estimates",
                                        cl$group, cl$N, sum(!same)))
      }
    }
    okE <- ok & vapply(rr, function(x) !is.null(x$eff_est), logical(1))
    if (any(okE)) {
      EE <- do.call(rbind, lapply(rr[okE], `[[`, "eff_est"))
      ES <- do.call(rbind, lapply(rr[okE], `[[`, "eff_se"))
      ET <- do.call(rbind, lapply(rr[okE], `[[`, "eff_true"))
      for (k in colnames(EE)) {
        dev <- EE[, k] - ET[, k]; t <- mean(ET[, k])
        rows[[length(rows) + 1]] <- data.frame(
          group = cl$group, N = cl$N, rho1 = cl$rho1, rho0 = cl$rho0,
          method = m, kind = "effect", parameter = k, truth = t,
          R = length(rr), conv = conv, bias = mean(dev),
          rel_bias = if (abs(t) >= 0.2) mean(dev) / abs(t) else NA,
          rmse = sqrt(mean(dev^2)), emp_sd = sd(dev), mean_se = mean(ES[, k]),
          se_ratio = mean(ES[, k]) / sd(dev),
          coverage = mean(abs(dev) <= 1.96 * ES[, k]), boundary = NA,
          stringsAsFactors = FALSE)
      }
    }
  }
  do.call(rbind, rows)
}
S <- do.call(rbind, lapply(cells, source_sum))
S$rho <- sprintf("(%g, %g)", S$rho1, S$rho0)
## dry runs on smoke output only: treat smoke cells as core cells
if ("--dry-run" %in% args) S$group[S$group == "smoke"] <- "core"
write.csv(S, file.path(out_dir, "mc_g1_summary.csv"), row.names = FALSE)

## ---------------------------------------------------------------- gates
gated_rho <- c("(0, 0)", "(0.6, 0.4)", "(0.7, -0.5)")
G <- S[S$group == "core" & S$N >= 1000 & S$rho %in% gated_rho, ]
checks <- list()
chk <- function(criterion, d, value, lo, hi, detail) {
  if (is.null(d) || !nrow(d)) return(invisible(NULL))
  checks[[length(checks) + 1]] <<- data.frame(
    criterion = criterion, N = d$N, rho = d$rho, method = d$method,
    parameter = d$parameter, value = value, lower = lo, upper = hi,
    pass = !is.na(value) & value >= lo & value <= hi, detail = detail,
    stringsAsFactors = FALSE)
  invisible(NULL)
}
Fp <- G[G$method == "fiml" & G$kind == "parameter", ]
nr <- Fp[!grepl(":rho$", Fp$parameter), ]
big <- abs(nr$truth) >= 0.2
chk("C1 relative bias gamma/beta/sigma", nr[big, ], abs(nr$rel_bias[big]), 0, 0.05,
    "|relative bias| <= 5%")
chk("C1 relative bias gamma/beta/sigma", nr[!big, ], abs(nr$bias[!big]), 0, 0.01,
    "|bias| <= 0.01 (|truth| < 0.2)")
rr <- Fp[grepl(":rho$", Fp$parameter), ]
chk("C2 bias rho", rr, abs(rr$bias), 0, 0.03, "|bias| <= 0.03")
## root-N: sqrt(5000) RMSE_5000 / sqrt(1000) RMSE_1000
a <- Fp[Fp$N == 1000, c("rho", "parameter", "rmse")]
b <- Fp[Fp$N == 5000, c("rho", "parameter", "rmse")]
rn <- merge(a, b, by = c("rho", "parameter"), suffixes = c("_1000", "_5000"))
if (nrow(rn)) {
  rn$N <- 5000L; rn$method <- "fiml"
  chk("C3 root-N", rn, sqrt(5000) * rn$rmse_5000 / (sqrt(1000) * rn$rmse_1000),
      0.8, 1.2, "sqrt(N) RMSE ratio 5000 vs 1000 in [0.8, 1.2]")
}
chk("C4 SE ratio (Hessian)", Fp, Fp$se_ratio, 0.90, 1.10, "mean SE / empirical SD")
chk("C5 coverage 95%", Fp, Fp$coverage, 0.93, 0.97, "rho on the atanh scale")
cv <- unique(Fp[, c("N", "rho", "method", "conv")])
if (nrow(cv)) {
  cv$parameter <- "(all)"
  chk("C6 convergence", cv, cv$conv, 0.99, 1, "share of converged FIML fits")
}
Fe <- G[G$method == "fiml" & G$kind == "effect" &
          G$parameter %in% c("ATT", "ATU", "ATE"), ]
bige <- abs(Fe$truth) >= 0.2
chk("C7 effects relative bias", Fe[bige, ], abs(Fe$rel_bias[bige]), 0, 0.05,
    "|relative bias| <= 5%")
chk("C7 effects relative bias", Fe[!bige, ], abs(Fe$bias[!bige]), 0, 0.01,
    "|bias| <= 0.01 (|truth| < 0.2)")
chk("C7 effects coverage", Fe, Fe$coverage, 0.93, 0.97, "delta method")
Tw <- G[G$method == "two_step" & G$N >= 2000 &
          (G$kind == "lambda" | (G$kind == "parameter" &
             !grepl(":(sigma|rho)$|^selection:", G$parameter))), ]
chk("C8 two-step coverage", Tw, Tw$coverage, 0.93, 0.97,
    "model-based intervals, beta and theta_j, N >= 2000")
C <- do.call(rbind, checks)
if (is.null(C)) stop("no gated cells in this run")
write.csv(C, file.path(out_dir, "gate_checks_G1.csv"), row.names = FALSE)

## --------------------------------------------------------------- report
f3 <- function(x) formatC(x, digits = 3, format = "fg", flag = "#")
md <- c(sprintf("# Monte Carlo study G1: generated tables (SwitchEconometrics %s)", version),
        "", sprintf("Generated %s from `%s` (%d cells) by `mc_g1_report.R`.",
                    format(Sys.time(), "%Y-%m-%d %H:%M"), run, length(cells)),
        "Thresholds: MONTE_CARLO_DESIGN.md section 5 (pre-registered).", "",
        "## Gate summary (gated cells: FIML, core grid, N >= 1000, rho in (0,0), (0.6,0.4), (0.7,-0.5))",
        "", "| Criterion | Checks | Passed | Failed |", "| --- | --- | --- | --- |")
for (cr in unique(C$criterion)) {
  d <- C[C$criterion == cr, ]
  md <- c(md, sprintf("| %s | %d | %d | %d |", cr, nrow(d), sum(d$pass), sum(!d$pass)))
}
md <- c(md, sprintf("| **All** | %d | %d | %d |", nrow(C), sum(C$pass), sum(!C$pass)), "")
fl <- C[!C$pass, ]
if (nrow(fl)) {
  md <- c(md, "### Failed checks", "",
          "| Criterion | N | rho | Method | Parameter | Value | Range |",
          "| --- | --- | --- | --- | --- | --- | --- |",
          sprintf("| %s | %d | %s | %s | %s | %s | [%g, %g] |", fl$criterion,
                  fl$N, fl$rho, fl$method, fl$parameter, f3(fl$value), fl$lower,
                  fl$upper), "")
}
core_tab <- function(meth, kind, title) {
  d <- S[S$group == "core" & S$method == meth & S$kind == kind, ]
  if (!nrow(d)) return(character())
  agg <- do.call(rbind, lapply(split(d, list(d$N, d$rho), drop = TRUE), function(x) {
    data.frame(N = x$N[1], rho = x$rho[1], conv = x$conv[1],
               max_abs_rel_bias = suppressWarnings(max(abs(x$rel_bias), na.rm = TRUE)),
               max_abs_bias_small = suppressWarnings(max(abs(x$bias[is.na(x$rel_bias)]))),
               se_ratio = paste(f3(range(x$se_ratio, na.rm = TRUE)), collapse = "-"),
               coverage = paste(f3(range(x$coverage, na.rm = TRUE)), collapse = "-"))
  }))
  agg <- agg[order(agg$rho, agg$N), ]
  c(sprintf("## %s", title), "",
    "| N | (rho1, rho0) | converged | max \\|rel. bias\\| | max \\|bias\\| (\\|truth\\| < 0.2) | SE ratio range | coverage range |",
    "| --- | --- | --- | --- | --- | --- | --- |",
    sprintf("| %d | %s | %s | %s | %s | %s | %s |", agg$N, agg$rho, f3(agg$conv),
            ifelse(is.finite(agg$max_abs_rel_bias), f3(agg$max_abs_rel_bias), "-"),
            ifelse(is.finite(agg$max_abs_bias_small),
                                             f3(agg$max_abs_bias_small), "-"),
            agg$se_ratio, agg$coverage), "")
}
md <- c(md, core_tab("fiml", "parameter", "Core grid, FIML parameters (R = 1000 per cell)"),
        core_tab("fiml", "effect", "Core grid, FIML effects (ATT, ATU, ATE, TH, BH1, BH0)"),
        core_tab("two_step", "parameter",
                 "Core grid, two-step parameters (SE ratio and coverage: gamma and beta; sigma and rho have no SEs)"),
        core_tab("two_step", "lambda", "Core grid, two-step selection-correction coefficients"),
        core_tab("fiml_sandwich", "parameter",
                 "Core grid, FIML with sandwich standard errors (not gated)"),
        core_tab("two_step_robust", "parameter",
                 "Core grid, two-step with stacked-sandwich standard errors (gamma and beta; not gated)"),
        core_tab("two_step_robust", "lambda",
                 "Core grid, two-step selection-correction coefficients, stacked sandwich (not gated)"))
## rho detail
rd <- S[S$group == "core" & S$method == "fiml" & grepl(":rho$", S$parameter), ]
md <- c(md, "## FIML correlation estimates by cell", "",
        "| N | (rho1, rho0) | parameter | bias | RMSE | SE ratio | coverage | boundary share |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
        sprintf("| %d | %s | %s | %s | %s | %s | %s | %s |", rd$N, rd$rho, rd$parameter,
                f3(rd$bias), f3(rd$rmse), f3(rd$se_ratio), f3(rd$coverage),
                f3(rd$boundary)), "")
## effects detail
ed <- S[S$group == "core" & S$method == "fiml" & S$kind == "effect" &
          S$parameter %in% c("ATT", "ATU", "ATE"), ]
md <- c(md, "## FIML effects by cell", "",
        "| N | (rho1, rho0) | effect | mean truth | bias | SE ratio | coverage |",
        "| --- | --- | --- | --- | --- | --- | --- |",
        sprintf("| %d | %s | %s | %s | %s | %s | %s |", ed$N, ed$rho, ed$parameter,
                f3(ed$truth), f3(ed$bias), f3(ed$se_ratio), f3(ed$coverage)), "")
## OFAT and multistart
of <- S[S$group != "core" & S$method == "fiml", ]
if (nrow(of)) {
  agg <- do.call(rbind, lapply(split(of, list(of$group, of$N), drop = TRUE), function(x)
    data.frame(group = x$group[1], N = x$N[1], conv = x$conv[1],
               rho_bias = paste(f3(x$bias[grepl(":rho$", x$parameter)]), collapse = " / "),
               max_abs_rel_bias = max(abs(x$rel_bias[x$kind == "parameter"]), na.rm = TRUE),
               se_ratio = paste(f3(range(x$se_ratio[x$kind == "parameter"])), collapse = "-"),
               coverage = paste(f3(range(x$coverage[x$kind == "parameter"])), collapse = "-"),
               eff_coverage = paste(f3(range(x$coverage[x$kind == "effect"])), collapse = "-"),
               boundary = f3(max(x$boundary, na.rm = TRUE)))))
  md <- c(md, "## One-factor-at-a-time and multistart cells (FIML; not gated)", "",
          "| Cell | N | converged | rho bias (rho0 / rho1) | max \\|rel. bias\\| | SE ratio | coverage | effect coverage | boundary share |",
          "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
          sprintf("| %s | %d | %s | %s | %s | %s | %s | %s | %s |", agg$group, agg$N,
                  f3(agg$conv), agg$rho_bias, f3(agg$max_abs_rel_bias), agg$se_ratio,
                  agg$coverage, agg$eff_coverage, agg$boundary), "")
}
ms <- Filter(function(cr) grepl("^multistart", cr$cell$group), cells)
if (length(ms)) {
  md <- c(md, "## Multistart sub-study (starts = 10)", "",
          "| Cell | R | converged | share with lower local maxima | two-step start reached the best optimum |",
          "| --- | --- | --- | --- | --- |")
  for (cr in ms) {
    f <- lapply(cr$res, `[[`, "fiml")
    okm <- vapply(f, function(x) isTRUE(x$ok), logical(1))
    md <- c(md, sprintf("| %s | %d | %s | %s | %s |", cr$cell$group, length(f),
                        f3(mean(vapply(f[okm], function(x) identical(x$code, 0L), logical(1)))),
                        f3(mean(vapply(f[okm], function(x) isTRUE(x$n_local > 0), logical(1)))),
                        f3(mean(vapply(f[okm], function(x) isTRUE(x$two_step_best), logical(1))))))
  }
  md <- c(md, "")
}
## time per fit (design s.4), core cells, by method and N
tt <- do.call(rbind, lapply(Filter(function(cr) cr$cell$group == "core", cells), function(cr)
  do.call(rbind, lapply(c("fiml", "two_step"), function(m)
    data.frame(N = cr$cell$N, method = m,
               time = vapply(cr$res, function(x) x[[m]]$time %||% NA_real_, numeric(1)))))))
if (!is.null(tt) && nrow(tt)) {
  ag <- do.call(rbind, lapply(split(tt, list(tt$method, tt$N), drop = TRUE), function(x)
    data.frame(method = x$method[1], N = x$N[1],
               med = stats::median(x$time, na.rm = TRUE),
               p90 = stats::quantile(x$time, 0.9, na.rm = TRUE, names = FALSE))))
  ag <- ag[order(ag$method, ag$N), ]
  md <- c(md, "## Time per fit, core grid (seconds; one worker process, machine shared)", "",
          "| Method | N | median | 90th percentile |", "| --- | --- | --- | --- |",
          sprintf("| %s | %d | %s | %s |", ag$method, ag$N, f3(ag$med), f3(ag$p90)), "")
}
tm <- vapply(cells, function(cr) cr$time, numeric(1))
md <- c(md, sprintf("Total computing time over cells: %.1f hours (elapsed per cell, summed).",
                    sum(tm) / 3600))
writeLines(md, out_md)
cat(sprintf("%d gate checks: %d passed, %d failed\n", nrow(C), sum(C$pass), sum(!C$pass)))
cat("written:", out_md, "\n")
