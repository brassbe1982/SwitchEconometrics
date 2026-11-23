## mc_g2.R -- Monte Carlo study of Generation 2
## (pre-registered design: 04_Validation/MONTE_CARLO_DESIGN.md section 8;
## approved by the owner on 23 November 2026).
##
## Usage (from the workspace root):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/mc_g2.R \
##       <mode> <library> <outdir> [cores] [designs]
##   mode     smoke (R = 20, one cell per design at its smallest N) | full
##   library  folder with the installed SwitchEconometrics version to test
##   outdir   output folder (outside the repository), e.g.
##            runs/mc_g2_<version>_<mode>
##   cores    worker processes (default 1; at most 3, handoff section 4)
##   designs  comma-separated design ids (default: all delivered designs)
##
## Delivered designs: H, T, Th (WP2.1). Later work packages add theirs.
##
## Random numbers: L'Ecuyer-CMRG, master seed 20261123, one stream per cell
## (in the fixed order of the full cell list), replication r uses substream
## r of its cell: results do not depend on the number of cores or on the
## mode. Effects: the estimand of a replication is the same formula at the
## true parameters on that replication's sample (section 8.1).
##
## Output: raw_<cell>.rds (one list per replication), mc_g2_summary.csv
## (one row per cell, estimator and quantity) and mc_g2_cells.csv.

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args) >= 1) args[1] else "smoke"
lib <- if (length(args) >= 2) args[2] else NULL
outdir <- if (length(args) >= 3) args[3] else file.path(tempdir(), "mc_g2")
cores <- if (length(args) >= 4) as.integer(args[4]) else 1L
want <- if (length(args) >= 5) strsplit(args[5], ",")[[1]] else NULL
stopifnot(mode %in% c("smoke", "full"), cores >= 1L, cores <= 3L)
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
if (!is.null(lib)) lib <- normalizePath(lib, winslash = "/")

## ---------------------------------------------------------------- cells
## The full list fixes the order of the random-number streams. Never
## reorder or delete entries; append new designs at the end.
mk <- function(design, N, rho, R) list(design = design, N = N, rho = rho,
  R = R, id = sprintf("%s_N%d_rho%s", design, N, format(rho)))
cells_all <- c(
  unlist(lapply(c(500, 1000, 2000, 5000), function(N)
    lapply(c(0, 0.6), function(r) mk("H", N, r, 1000L))), recursive = FALSE),
  unlist(lapply(c(500, 1000, 2000, 5000), function(N)
    lapply(c(0, 0.6), function(r) mk("T", N, r, 1000L))), recursive = FALSE),
  lapply(c(1000, 5000), function(N) mk("Th", N, 0.6, 500L)))
for (k in seq_along(cells_all)) cells_all[[k]]$stream <- k
delivered <- c("H", "T", "Th")
`%||%` <- function(a, b) if (is.null(a)) b else a
want <- want %||% delivered
cells <- Filter(function(cl) cl$design %in% want, cells_all)
if (mode == "smoke") {
  cells <- lapply(split(cells, vapply(cells, `[[`, "", "design")), function(g) {
    cl <- g[[which.min(vapply(g, `[[`, 0, "N"))]]
    cl$R <- 20L
    cl
  })
}

## true parameters in the order of coef()
gam <- c(0.5, 0.3, -0.4)
truth_of <- function(cl) switch(cl$design,
  H = c(gam, 1.5, 0.8, 0.4, 1, cl$rho),
  T = c(gam, 1.0, 0.5, 0.2, 0.5, 1, cl$rho),
  Th = c(gam, 1.0, 0.5, 0.2, 0.5, 0.3, 1, cl$rho))

## ------------------------------------------------------- one replication
one_rep <- function(seed, cell, lib) {
  cl <- cell
  suppressPackageStartupMessages(library(SwitchEconometrics, lib.loc = lib))
  assign(".Random.seed", seed, envir = globalenv())
  N <- cl$N
  x1 <- rnorm(N); x2 <- rnorm(N); z1 <- rnorm(N)
  u <- rnorm(N)
  e <- cl$rho * u + sqrt(1 - cl$rho^2) * rnorm(N)
  S <- as.integer(0.5 + 0.3 * x1 - 0.4 * z1 + u > 0)
  th0 <- switch(cl$design,
    H = c(0.5, 0.3, -0.4, 1.5, 0.8, 0.4, 1, cl$rho),
    T = c(0.5, 0.3, -0.4, 1.0, 0.5, 0.2, 0.5, 1, cl$rho),
    Th = c(0.5, 0.3, -0.4, 1.0, 0.5, 0.2, 0.5, 0.3, 1, cl$rho))
  if (cl$design == "H") {
    y <- ifelse(S == 1, 1.5 + 0.8 * x1 + 0.4 * x2 + e, NA_real_)
  } else {
    te <- if (cl$design == "T") rep(0.5, N) else 0.5 + 0.3 * x1
    y <- 1 + 0.5 * x1 + 0.2 * x2 + S * te + e
  }
  d <- data.frame(S, y, x1, x2, z1)
  fitter <- function(m, v) {
    if (cl$design == "H") {
      heckman(S ~ x1 + z1, y ~ x1 + x2, data = d, method = m, vcov = v,
              control = switch_control(starts = 1L))
    } else {
      treatment(S ~ x1 + z1, y ~ x1 + x2, data = d, method = m, vcov = v,
                shift = if (cl$design == "T") ~ 1 else ~ x1,
                control = switch_control(starts = 1L))
    }
  }
  out <- list(share = mean(S))
  for (m in c("fiml", "two_step")) {
    t0 <- proc.time()[["elapsed"]]
    f <- tryCatch(suppressWarnings(suppressMessages(fitter(m, "hessian"))),
                  error = function(e) e)
    tm <- proc.time()[["elapsed"]] - t0
    if (inherits(f, "error")) {
      out[[m]] <- list(ok = FALSE, error = conditionMessage(f), time = tm)
      next
    }
    est <- coef(f)
    se <- sqrt(pmax(diag(vcov(f)), 0))
    ci <- confint(f)
    names(th0) <- names(est)
    res <- list(ok = TRUE, time = tm, est = est, se = se,
                cover = ci[, 1] <= th0 & th0 <= ci[, 2],
                code = f$convergence$code,
                iterations = f$convergence$iterations,
                gradient_max = f$convergence$gradient_max,
                boundary = length(f$diagnostics$flags$rho_boundary) > 0)
    fs <- tryCatch(suppressWarnings(suppressMessages(fitter(m, "sandwich"))),
                   error = function(e) NULL)
    if (!is.null(fs)) res$se_sandwich <- sqrt(pmax(diag(vcov(fs)), 0))
    if (m == "two_step") {
      ts <- f$two_step
      k <- ts$index_psi$outcome[length(ts$index_psi$outcome)]
      tt <- ts$psi[[k]]; st <- sqrt(ts$vcov_psi[k, k])
      t0v <- th0[["outcome:sigma"]] * th0[["outcome:rho"]]
      res$theta <- c(est = tt, se = st,
                     cover = abs(tt - t0v) <= qnorm(0.975) * st)
      res$rho_out <- any(ts$rho_out_of_range)
    }
    idn <- f$identification$table
    if (!is.null(idn)) {
      res$ident <- stats::setNames(idn$status[idn$code %in% c("I5", "I6")],
                                   idn$code[idn$code %in% c("I5", "I6")])
    }
    if (cl$design != "H") {
      ef <- tryCatch(switch_effects(f, effects = c("ATT", "ATE"))$table,
                     error = function(e) NULL)
      if (!is.null(ef)) {
        tr <- c(ATT = mean(te[S == 1]), ATE = mean(te))
        res$eff <- cbind(est = ef$estimate, se = ef$std_error,
                         truth = tr[ef$effect],
                         cover = ef$lower <= tr[ef$effect] &
                           tr[ef$effect] <= ef$upper)
        rownames(res$eff) <- ef$effect
      }
    }
    out[[m]] <- res
  }
  out
}

## --------------------------------------------------------------- summary
summarise_cell <- function(cl, reps) {
  th0 <- truth_of(cl)
  rows <- list()
  for (m in c("fiml", "two_step")) {
    rr <- lapply(reps, `[[`, m)
    okf <- vapply(rr, function(r) isTRUE(r$ok), logical(1))
    conv <- okf & vapply(rr, function(r) isTRUE(r$code == 0L), logical(1))
    use <- rr[conv]
    if (!length(use)) next
    E <- do.call(rbind, lapply(use, `[[`, "est"))
    SE <- do.call(rbind, lapply(use, `[[`, "se"))
    CV <- do.call(rbind, lapply(use, `[[`, "cover"))
    SS <- do.call(rbind, lapply(use, function(r)
      r$se_sandwich %||% rep(NA_real_, ncol(E))))
    add <- function(q, est, se, cover, truth, se_s = NA_real_, kind) {
      bias <- mean(est) - mean(truth)
      rows[[length(rows) + 1L]] <<- data.frame(
        cell = cl$id, design = cl$design, N = cl$N, rho = cl$rho, R = cl$R,
        method = m, quantity = q, kind = kind, truth = mean(truth),
        mean = mean(est), bias = bias,
        rel_bias = if (abs(mean(truth)) > 0) bias / abs(mean(truth)) else NA,
        sd = stats::sd(est), rmse = sqrt(mean((est - truth)^2)),
        mean_se = mean(se, na.rm = TRUE),
        se_ratio = mean(se, na.rm = TRUE) / stats::sd(est),
        coverage = mean(cover, na.rm = TRUE),
        se_ratio_sandwich = mean(se_s, na.rm = TRUE) / stats::sd(est),
        n_used = length(est), n_fit = sum(okf),
        convergence_rate = mean(conv), stringsAsFactors = FALSE)
    }
    for (j in seq_len(ncol(E))) {
      nm <- colnames(E)[j]
      kind <- if (grepl(":rho$", nm)) "dependence" else if (grepl(":sigma$", nm))
        "scale" else "coefficient"
      add(nm, E[, j], SE[, j], CV[, j], th0[j], SS[, j], kind)
    }
    if (m == "two_step") {
      TH <- do.call(rbind, lapply(use, `[[`, "theta"))
      add("outcome:theta", TH[, "est"], TH[, "se"], TH[, "cover"],
          th0[length(th0) - 1L] * th0[length(th0)], kind = "correction")
    }
    if (!is.null(use[[1L]]$eff)) {
      for (e in rownames(use[[1L]]$eff)) {
        M <- do.call(rbind, lapply(use, function(r) r$eff[e, ]))
        add(e, M[, "est"], M[, "se"], M[, "cover"], M[, "truth"],
            kind = "effect")
      }
    }
  }
  do.call(rbind, rows)
}

## ------------------------------------------------------------------- run
RNGkind("L'Ecuyer-CMRG")
set.seed(20261123)
s <- .Random.seed
streams <- vector("list", length(cells_all))
for (k in seq_along(cells_all)) {
  s <- parallel::nextRNGStream(s)
  streams[[k]] <- s
}
pcl <- NULL
if (cores > 1L) {
  pcl <- parallel::makeCluster(cores, rscript_args = "--no-init-file")
}
t_all <- proc.time()[["elapsed"]]
summ <- list(); cell_rows <- list()
for (cl in cells) {
  t0 <- proc.time()[["elapsed"]]
  sub <- streams[[cl$stream]]
  seeds <- vector("list", cl$R)
  for (r in seq_len(cl$R)) {
    sub <- parallel::nextRNGSubStream(sub)
    seeds[[r]] <- sub
  }
  reps <- if (is.null(pcl)) lapply(seeds, one_rep, cell = cl, lib = lib)
          else parallel::parLapplyLB(pcl, seeds, one_rep, cell = cl, lib = lib)
  saveRDS(reps, file.path(outdir, sprintf("raw_%s.rds", cl$id)))
  sm <- summarise_cell(cl, reps)
  summ[[cl$id]] <- sm
  el <- proc.time()[["elapsed"]] - t0
  tm <- function(m) mean(vapply(reps, function(r) r[[m]]$time %||% NA_real_, 0),
                         na.rm = TRUE)
  cell_rows[[cl$id]] <- data.frame(
    cell = cl$id, design = cl$design, N = cl$N, rho = cl$rho, R = cl$R,
    share = mean(vapply(reps, `[[`, 0, "share")),
    time_fiml = tm("fiml"), time_two_step = tm("two_step"), elapsed = el,
    errors_fiml = sum(!vapply(reps, function(r) isTRUE(r$fiml$ok), TRUE)),
    boundary_fiml = sum(vapply(reps, function(r) isTRUE(r$fiml$boundary), TRUE)),
    rho_out_two_step = sum(vapply(reps, function(r)
      isTRUE(r$two_step$rho_out), TRUE)),
    I6_warning_fiml = sum(vapply(reps, function(r)
      identical(unname(r$fiml$ident["I6"]), "warning"), TRUE)),
    stringsAsFactors = FALSE)
  cat(sprintf("%-18s R = %4d  %.0f s\n", cl$id, cl$R, el))
  utils::write.csv(do.call(rbind, summ), file.path(outdir, "mc_g2_summary.csv"),
                   row.names = FALSE)
  utils::write.csv(do.call(rbind, cell_rows),
                   file.path(outdir, "mc_g2_cells.csv"), row.names = FALSE)
}
if (!is.null(pcl)) parallel::stopCluster(pcl)
ver <- as.character(utils::packageVersion("SwitchEconometrics", lib.loc = lib))
writeLines(c(sprintf("version: %s", ver), sprintf("mode: %s", mode),
             sprintf("cores: %d", cores), sprintf("R: %s", R.version.string),
             sprintf("date: %s", format(Sys.time())),
             sprintf("elapsed: %.0f s", proc.time()[["elapsed"]] - t_all)),
           file.path(outdir, "run_info.txt"))
cat(sprintf("done: %d cells, %.0f s, version %s\n", length(cells),
            proc.time()[["elapsed"]] - t_all, ver))
