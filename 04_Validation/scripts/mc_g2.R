## mc_g2.R -- Monte Carlo study of Generation 2
## (pre-registered design: 04_Validation/MONTE_CARLO_DESIGN.md section 8;
## approved by the owner on 23 and 24 November 2026).
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
## Delivered designs: H, T, Th (WP2.1); L, D, Lw, G, LN, L8 (WP2.2).
## LN is the cell "normal-score FIML on Lee data" of section 8.6.
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
`%||%` <- function(a, b) if (is.null(a)) b else a
stopifnot(mode %in% c("smoke", "full"), cores >= 1L, cores <= 3L)
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
if (!is.null(lib)) lib <- normalizePath(lib, winslash = "/")

## ---------------------------------------------------------------- cells
## The full list fixes the order of the random-number streams. Never
## reorder or delete entries; append new designs at the end.
mk <- function(design, N, rho, R, tag = format(rho)) list(
  design = design, N = N, rho = rho, R = R,
  id = sprintf("%s_N%d_rho%s", design, N, tag))
cells_all <- c(
  unlist(lapply(c(500, 1000, 2000, 5000), function(N)
    lapply(c(0, 0.6), function(r) mk("H", N, r, 1000L))), recursive = FALSE),
  unlist(lapply(c(500, 1000, 2000, 5000), function(N)
    lapply(c(0, 0.6), function(r) mk("T", N, r, 1000L))), recursive = FALSE),
  lapply(c(1000, 5000), function(N) mk("Th", N, 0.6, 500L)),
  ## WP2.2 (rho = 1: the dependent parameter set; rho = 0: independence)
  unlist(lapply(c(1000, 2000, 5000), function(N)
    lapply(c(1, 0), function(r) mk("L", N, r, 1000L,
                                   if (r == 1) "dep" else "0"))),
    recursive = FALSE),
  lapply(c(2000, 5000), function(N) mk("D", N, 1, 500L, "dep")),
  list(mk("Lw", 2000, 1, 500L, "dep")),
  lapply(c(2000, 5000), function(N) mk("G", N, 1, 500L, "dep")),
  list(mk("LN", 5000, 1, 300L, "dep")),
  lapply(c(4000, 8000), function(N) mk("L8", N, 1, 500L, "dep")))
for (k in seq_along(cells_all)) cells_all[[k]]$stream <- k
delivered <- c("H", "T", "Th", "L", "D", "Lw", "G", "LN", "L8")
want <- if (length(args) >= 5) strsplit(args[5], ",")[[1]] else delivered
cells <- Filter(function(cl) cl$design %in% want, cells_all)
if (mode == "smoke") {
  cells <- lapply(split(cells, vapply(cells, `[[`, "", "design")), function(g) {
    cl <- g[[which.min(vapply(g, `[[`, 0, "N"))]]
    cl$R <- 20L
    cl
  })
}

## ------------------------------------------------------- one replication
one_rep <- function(seed, cell, lib) {
  suppressPackageStartupMessages(library(SwitchEconometrics, lib.loc = lib))
  assign(".Random.seed", seed, envir = globalenv())
  ns <- asNamespace("SwitchEconometrics")
  if (cell$design %in% c("H", "T", "Th")) rep_binary(cell)
  else rep_multi(cell, ns)
}

## ---- designs H, T, Th (WP2.1; random-number use unchanged)
rep_binary <- function(cl) {
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
  out <- list(share = mean(S), est = list())
  for (m in c("fiml", "two_step")) {
    t0 <- proc.time()[["elapsed"]]
    f <- tryCatch(suppressWarnings(suppressMessages(fitter(m, "hessian"))),
                  error = function(e) e)
    tm <- proc.time()[["elapsed"]] - t0
    if (inherits(f, "error")) {
      out$est[[m]] <- list(ok = FALSE, error = conditionMessage(f), time = tm)
      next
    }
    est <- coef(f)
    se <- sqrt(pmax(diag(vcov(f)), 0))
    ci <- confint(f)
    names(th0) <- names(est)
    kind <- ifelse(grepl(":rho$", names(est)), "dependence",
                   ifelse(grepl(":sigma$", names(est)), "scale", "coefficient"))
    res <- list(ok = TRUE, time = tm, est = est, se = se, truth = th0,
                kind = kind, cover = ci[, 1] <= th0 & th0 <= ci[, 2],
                code = f$convergence$code,
                boundary = length(f$diagnostics$flags$rho_boundary) > 0)
    fs <- tryCatch(suppressWarnings(suppressMessages(fitter(m, "sandwich"))),
                   error = function(e) NULL)
    res$se_sandwich <- if (!is.null(fs)) sqrt(pmax(diag(vcov(fs)), 0)) else
      rep(NA_real_, length(est))
    names(res$se_sandwich) <- names(est)
    add <- function(nm, e1, s1, t1, kd, cov = abs(e1 - t1) <= qnorm(0.975) * s1) {
      res$est[[nm]] <<- e1; res$se[[nm]] <<- s1; res$truth[[nm]] <<- t1
      res$kind <<- c(res$kind, kd)
      res$cover[[nm]] <<- cov
      res$se_sandwich[[nm]] <<- NA_real_
    }
    if (m == "two_step") {
      ts <- f$two_step
      k <- ts$index_psi$outcome[length(ts$index_psi$outcome)]
      add("outcome:theta", ts$psi[[k]], sqrt(ts$vcov_psi[k, k]),
          th0[["outcome:sigma"]] * th0[["outcome:rho"]], "correction")
      res$rho_out <- any(ts$rho_out_of_range)
    }
    idn <- f$identification$table
    res$I6 <- any(idn$status[idn$code == "I6"] == "warning")
    if (cl$design != "H") {
      ef <- tryCatch(switch_effects(f, effects = c("ATT", "ATE"))$table,
                     error = function(e) NULL)
      if (!is.null(ef)) {
        tr <- c(ATT = mean(te[S == 1]), ATE = mean(te))
        for (i in seq_len(nrow(ef))) {
          t1 <- tr[[ef$effect[i]]]
          add(ef$effect[i], ef$estimate[i], ef$std_error[i], t1, "effect",
              ef$lower[i] <= t1 && t1 <= ef$upper[i])
        }
      }
    }
    out$est[[m]] <- res
  }
  out
}

## ---- multinomial designs (WP2.2)
rep_multi <- function(cl, ns) {
  N <- cl$N
  dep <- cl$rho == 1
  J <- if (cl$design == "L8") 8L else 3L
  x1 <- rnorm(N); x2 <- rnorm(N); z1 <- rnorm(N); z2 <- rnorm(N)
  if (J == 3L) {
    G <- rbind(c(0.2, 0.3, 0.8, -0.2), c(-0.2, -0.3, 0.2, 0.8))
    if (cl$design == "Lw") G[, 3:4] <- G[, 3:4] * 0.25
    B <- rbind(c(1.0, 0.5, 0.2), c(1.5, 0.8, 0.4), c(2.0, 0.3, -0.3))
    sig <- c(1, 1, 1.2)
    rho <- if (dep) c(0.5, 0.4, -0.4) else c(0, 0, 0)
    Rm <- rbind(c(0.4, -0.2, -0.2), c(-0.3, 0.5, -0.2), c(0.1, -0.4, 0.3))
  } else {
    G <- rbind(c(0.2, 0.3, 0.8, -0.2), c(-0.2, -0.3, 0.2, 0.8),
               c(0.1, 0.2, -0.6, 0.4), c(0, -0.2, 0.5, 0.5),
               c(-0.1, 0.4, -0.4, -0.6), c(0.1, -0.1, 0.9, 0.3),
               c(-0.1, 0.1, -0.3, 0.9))
    B <- cbind(1 + 0.25 * (0:7), 0.5, 0.2)
    sig <- rep(1, 8)
    rho <- c(0.5, 0.4, -0.4, 0.3, -0.3, 0.5, 0.2, -0.5)
  }
  labs <- paste0("r", seq_len(J))
  Z <- cbind(1, x1, z1, z2)
  X <- cbind(1, x1, x2)
  V <- cbind(0, Z %*% t(G))
  Uu <- matrix(runif(N * J), N, J)
  gum <- -log(-log(Uu))
  Ut <- V + gum
  S <- integer(N); best <- rep(-Inf, N)
  for (k in seq_len(J)) { b <- Ut[, k] > best; S[b] <- k; best[b] <- Ut[b, k] }
  xb <- X %*% t(B)
  truth_design <- cl$design
  if (cl$design %in% c("L", "Lw", "LN", "L8")) {        # Lee's model
    Y <- matrix(0, N, J)
    for (j in seq_len(J)) {
      es <- apply(Ut[, -j, drop = FALSE], 1L, max) - gum[, j]
      lF <- es - log(exp(es) + rowSums(exp(V[, -j, drop = FALSE])))
      us <- -qnorm(lF, log.p = TRUE)
      Y[, j] <- xb[, j] + sig[j] * (rho[j] * us + sqrt(1 - rho[j]^2) * rnorm(N))
    }
    truth_design <- "lee"
  } else if (cl$design == "D") {                        # linear in the Gumbels
    gE <- -digamma(1)
    Y <- vapply(seq_len(J), function(j) xb[, j] + sig[j] * (
      sqrt(6) / pi * drop((gum - gE) %*% Rm[j, ]) +
        sqrt(1 - sum(Rm[j, ]^2)) * rnorm(N)), numeric(N))
  } else {                                              # G: normal scores
    eta <- qnorm(Uu)
    Y <- vapply(seq_len(J), function(j) xb[, j] + sig[j] * (
      drop(eta %*% Rm[j, ]) + sqrt(1 - sum(Rm[j, ]^2)) * rnorm(N)),
      numeric(N))
  }
  d <- data.frame(regime = factor(labs[S], levels = labs),
                  y = Y[cbind(seq_len(N), S)], x1, x2, z1, z2)
  fo <- stats::setNames(rep(list(y ~ x1 + x2), J), labs)
  fsel <- regime ~ x1 + z1 + z2

  ## truths by parameter name
  tg <- stats::setNames(as.vector(t(G)), unlist(lapply(labs[-1], function(a)
    sprintf("selection[%s]:%s", a, c("(Intercept)", "x1", "z1", "z2")))))
  tb <- stats::setNames(as.vector(t(B)), unlist(lapply(labs, function(l)
    paste0(l, ":", c("(Intercept)", "x1", "x2")))))
  truth <- c(tg, tb, stats::setNames(sig, paste0(labs, ":sigma")))
  if (truth_design == "lee") {
    truth <- c(truth, stats::setNames(rho, paste0(labs, ":rho")),
               stats::setNames(sig * rho, paste0(labs, ":theta")))
  } else {
    sc <- if (cl$design == "D") sqrt(6) / pi else 1
    for (j in seq_len(J)) {
      truth <- c(truth,
        stats::setNames(Rm[j, ], sprintf("%s:rho[%s]", labs[j], labs)),
        stats::setNames(sig[j] * sc * Rm[j, ],
                        sprintf("%s:theta[%s]", labs[j], labs)))
    }
  }
  kind_of <- function(nm) ifelse(grepl(":rho", nm), "dependence",
    ifelse(grepl(":sigma$", nm), "scale",
           ifelse(grepl(":theta", nm), "correction", "coefficient")))

  ## true effects: the formulas of the true model at the true parameters
  true_effects <- function(f_true) {
    lay <- ns$se_multi_layout(f_true)
    psi <- numeric(lay$P)
    psi[seq_len(lay$ng)] <- as.vector(t(G))
    for (j in seq_len(J)) {
      psi[lay$beta[[j]]] <- B[j, ]
      psi[lay$dep[[j]]] <- if (truth_design == "lee") sig[j] * rho[j] else {
        a <- sig[j] * (if (cl$design == "D") sqrt(6) / pi else 1) * Rm[j, ]
        if (lay$type == "dmf") a[-j] else a
      }
    }
    sdd <- f_true$data
    prs <- ns$se_multi_pairs("all", labs)
    ns$se_multi_effect_values(psi, lay, sdd$Z, sdd$X, sdd$S, rep(1, sdd$n),
                              rep(TRUE, sdd$n), prs, c("ATE", "ATT"))
  }

  mkres <- function(f, tm) {
    est <- coef(f)
    se <- sqrt(pmax(diag(vcov(f)), 0))
    se[is.na(diag(vcov(f)))] <- NA_real_
    ci <- confint(f)
    tr <- truth[names(est)]
    names(tr) <- names(est)
    res <- list(ok = TRUE, time = tm, est = est, se = se, truth = tr,
                kind = kind_of(names(est)),
                cover = ci[, 1] <= tr & tr <= ci[, 2],
                code = f$convergence$code,
                boundary = length(f$diagnostics$flags$rho_boundary) > 0)
    res$se_sandwich <- if (f$method == "two_step" &&
                           identical(f$map$kind, "moments"))
      sqrt(pmax(diag(f$two_step$vcov_sandwich), 0)) else rep(NA_real_, length(est))
    names(res$se_sandwich) <- names(est)
    if (f$method == "two_step" && identical(f$map$kind, "lee")) {
      ts <- f$two_step
      for (l in labs) {
        k <- ts$index_psi[[l]][length(ts$index_psi[[l]])]
        nm <- paste0(l, ":theta")
        t1 <- if (nm %in% names(truth)) truth[[nm]] else NA_real_
        res$est[[nm]] <- ts$psi[[k]]; res$se[[nm]] <- sqrt(ts$vcov_psi[k, k])
        res$truth[[nm]] <- t1
        res$kind <- c(res$kind, "correction")
        res$cover[[nm]] <- abs(ts$psi[[k]] - t1) <= qnorm(0.975) * res$se[[nm]]
        res$se_sandwich[[nm]] <- NA_real_
      }
      res$rho_out <- any(ts$rho_out_of_range)
    }
    res
  }
  add_effects <- function(res, f, te) {
    ef <- tryCatch(switch_effects(f, effects = c("ATE", "ATT"))$table,
                   error = function(e) NULL)
    if (is.null(ef) || is.null(te)) return(res)
    for (i in seq_len(nrow(ef))) {
      nm <- sprintf("%s[%s-%s]", ef$effect[i], ef$regime[i], ef$against[i])
      t1 <- te[[i]]
      res$est[[nm]] <- ef$estimate[i]; res$se[[nm]] <- ef$std_error[i]
      res$truth[[nm]] <- t1
      res$kind <- c(res$kind, "effect")
      res$cover[[nm]] <- ef$lower[i] <= t1 && t1 <= ef$upper[i]
      res$se_sandwich[[nm]] <- NA_real_
    }
    res
  }
  run <- function(expr) {
    t0 <- proc.time()[["elapsed"]]
    f <- tryCatch(suppressWarnings(suppressMessages(expr)), error = function(e) e)
    list(f = f, tm = proc.time()[["elapsed"]] - t0)
  }
  ctl1 <- switch_control(starts = 1L)
  fits <- list()
  des <- cl$design
  if (des %in% c("L", "Lw", "L8", "G")) {
    fits$fiml_lee <- run(multinomial_switch(fsel, fo, data = d, control = ctl1))
  }
  if (des %in% c("L", "L8", "D")) {
    fits$ts_lee <- run(multinomial_switch(fsel, fo, data = d,
                                          method = "two_step"))
  }
  if (des %in% c("L", "D")) {
    boot <- des == "D" && cl$N == 2000
    for (cr in c("dmf", "bfg1", "bfg2")) {
      fits[[paste0("ts_", cr)]] <- run(multinomial_switch(
        fsel, fo, data = d, method = "two_step", correction = cr,
        vcov = if (boot) "hessian" else "sandwich",
        control = switch_control(bootstrap_R = 199L)))
    }
  }
  if (des == "G") {
    fits$ts_bfg2 <- run(multinomial_switch(fsel, fo, data = d,
                                           method = "two_step",
                                           correction = "bfg2",
                                           vcov = "sandwich"))
  }
  if (des %in% c("G", "LN")) {
    fits$fiml_ns <- run(switch_fit(fsel, fo, data = d,
                                   model = "multinomial_esr",
                                   dependence_structure = "normal_scores",
                                   control = ctl1))
  }
  ## the fit whose effect formulas are those of the true model
  true_name <- switch(des, D = "ts_bfg1", G = "fiml_ns", LN = "none",
                      "fiml_lee")
  te <- NULL
  if (true_name != "none" && !inherits(fits[[true_name]]$f, "error")) {
    te <- tryCatch(true_effects(fits[[true_name]]$f), error = function(e) NULL)
  }
  out <- list(share = tabulate(S, J) / N, est = list())
  for (nm in names(fits)) {
    f <- fits[[nm]]$f
    if (inherits(f, "error")) {
      out$est[[nm]] <- list(ok = FALSE, error = conditionMessage(f),
                            time = fits[[nm]]$tm)
      next
    }
    res <- mkres(f, fits[[nm]]$tm)
    if (J == 3L) res <- add_effects(res, f, te)
    idn <- f$identification$table
    res$I6 <- any(idn$status[idn$code == "I6"] == "warning")
    res$iterations <- f$convergence$iterations
    out$est[[nm]] <- res
  }
  out
}

## --------------------------------------------------------------- summary
summarise_cell <- function(cl, reps) {
  rows <- list()
  ests <- unique(unlist(lapply(reps, function(r) names(r$est))))
  for (m in ests) {
    rr <- lapply(reps, function(r) r$est[[m]])
    okf <- vapply(rr, function(r) isTRUE(r$ok), logical(1))
    conv <- okf & vapply(rr, function(r) isTRUE(r$code == 0L), logical(1))
    use <- rr[conv]
    if (!length(use)) next
    nms <- names(use[[1L]]$est)
    pull <- function(what) do.call(rbind, lapply(use, function(r) {
      v <- unlist(r[[what]])[nms]
      names(v) <- nms
      v
    }))
    E <- pull("est"); SE <- pull("se"); CV <- pull("cover")
    TR <- pull("truth"); SS <- pull("se_sandwich")
    kd <- use[[1L]]$kind
    for (j in seq_along(nms)) {
      est <- E[, j]; truth <- TR[, j]
      if (all(is.na(est))) next
      bias <- mean(est - truth)
      rows[[length(rows) + 1L]] <- data.frame(
        cell = cl$id, design = cl$design, N = cl$N, rho = cl$rho, R = cl$R,
        method = m, quantity = nms[j], kind = kd[j], truth = mean(truth),
        mean = mean(est), bias = bias,
        rel_bias = if (isTRUE(abs(mean(truth)) > 0)) bias / abs(mean(truth))
                   else NA_real_,
        sd = stats::sd(est), rmse = sqrt(mean((est - truth)^2)),
        mean_se = mean(SE[, j], na.rm = TRUE),
        se_ratio = mean(SE[, j], na.rm = TRUE) / stats::sd(est),
        coverage = mean(CV[, j], na.rm = TRUE),
        se_ratio_sandwich = mean(SS[, j], na.rm = TRUE) / stats::sd(est),
        n_used = length(est), n_fit = sum(okf),
        convergence_rate = mean(conv), stringsAsFactors = FALSE)
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
  parallel::clusterExport(pcl, c("rep_binary", "rep_multi", "%||%"))
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
  summ[[cl$id]] <- summarise_cell(cl, reps)
  el <- proc.time()[["elapsed"]] - t0
  ests <- unique(unlist(lapply(reps, function(r) names(r$est))))
  shares <- do.call(rbind, lapply(reps, function(r) r$share))
  for (m in ests) {
    g <- function(what, default) vapply(reps, function(r) {
      v <- r$est[[m]][[what]]
      if (is.null(v)) default else as.numeric(v)
    }, numeric(1))
    cell_rows[[paste(cl$id, m)]] <- data.frame(
      cell = cl$id, design = cl$design, N = cl$N, rho = cl$rho, R = cl$R,
      method = m,
      share = paste(formatC(colMeans(shares), format = "f", digits = 3),
                    collapse = " "),
      time = mean(g("time", NA_real_), na.rm = TRUE), elapsed = el,
      errors = sum(g("ok", 0) == 0),
      not_converged = sum(g("ok", 0) == 1 & g("code", 9) != 0),
      boundary = sum(g("boundary", 0) == 1),
      rho_out = sum(g("rho_out", 0) == 1),
      I6_warning = sum(g("I6", 0) == 1),
      stringsAsFactors = FALSE)
  }
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
             sprintf("designs: %s", paste(want, collapse = ", ")),
             sprintf("elapsed: %.0f s", proc.time()[["elapsed"]] - t_all)),
           file.path(outdir, "run_info.txt"))
cat(sprintf("done: %d cells, %.0f s, version %s\n", length(cells),
            proc.time()[["elapsed"]] - t_all, ver))
