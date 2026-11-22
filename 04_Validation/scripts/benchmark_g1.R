## benchmark_g1.R -- cross-software benchmarks of Generation 1
## (protocol: 04_Validation/BENCHMARK_PROTOCOL.md section 3; R only, plan
## decision D11 as amended by the owner on 22 November 2026).
##
## Usage (from the workspace root):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/benchmark_g1.R \
##       <library> <data dir> <output dir>
##   library     folder with SwitchEconometrics and endoSwitch 1.0.0 installed
##               (runs/lib_bench); sampleSelection, mvtnorm, data.table and
##               msm are taken from the default libraries
##   data dir    where the benchmark datasets are saved (runs/benchmarks_g1)
##   output dir  where BENCHMARK_G1_generated.md and benchmark_g1.csv are
##               written (04_Validation/results)
##
## Benchmarks (all decided before the run):
##   sampleSelection 1.2-16  ML and two-step, every dataset
##   endoSwitch 1.0.0        FIML (its default BFGS; and BFGS with
##                           reltol = 1e-14), its treatment effects and
##                           conditional expectations, and its two-stage
##                           estimator, wherever its interface can express the
##                           model (same outcome regressors in both regimes,
##                           selection regressors different from them)
## Tolerances: BENCHMARK_PROTOCOL.md section 3.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) stop("usage: benchmark_g1.R <library> <data dir> <output dir>")
lib <- normalizePath(args[1]); ddir <- args[2]; odir <- args[3]
dir.create(ddir, recursive = TRUE, showWarnings = FALSE)
dir.create(odir, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
suppressPackageStartupMessages({
  library(SwitchEconometrics)
  library(sampleSelection)
  library(endoSwitch)
  library(mvtnorm)
})
stopifnot(startsWith(normalizePath(find.package("SwitchEconometrics")), lib))
ns <- asNamespace("SwitchEconometrics")
seed0 <- 20261122

## ------------------------------------------------------------- datasets
gen_base <- function(N, seed, gz = -0.4, sigma1 = 1, sigma0 = 1) {
  set.seed(seed)
  x1 <- rnorm(N); x2 <- rnorm(N); z1 <- rnorm(N); u <- rnorm(N)
  e1 <- sigma1 * (0.6 * u + sqrt(1 - 0.6^2) * rnorm(N))
  e0 <- sigma0 * (0.4 * u + sqrt(1 - 0.4^2) * rnorm(N))
  S <- as.integer(0.5 + 0.3 * x1 + gz * z1 + u > 0)
  y <- ifelse(S == 1, 1.5 + 0.8 * x1 + 0.4 * x2 + e1,
              1.0 + 0.5 * x1 + 0.2 * x2 + e0)
  data.frame(S, y, x1, x2, z1)
}
## design of 01_Econometric_Architecture/verify_math.R (different regressors)
gen_d5 <- function(N, seed) {
  set.seed(seed)
  x1 <- rnorm(N); x2 <- rbinom(N, 1, 0.5); z1 <- rnorm(N)
  r10 <- 0.6 * 0.4
  R <- matrix(c(1, 0.6, 0.4, 0.6, 1, r10, 0.4, r10, 1), 3)
  E <- matrix(rnorm(3 * N), N) %*% chol(R)
  S <- as.integer(0.5 + 0.3 * x1 - 0.4 * z1 + E[, 1] > 0)
  y <- ifelse(S == 1, 1.5 + 0.8 * x1 + 0.4 * x2 + 1.2 * E[, 2],
              1.0 + 0.5 * x1 + 0.8 * E[, 3])
  data.frame(S, y, x1, x2, z1)
}
## sampleSelection's Tobit-5 examples, with their own code and seeds
## (vignette "selection", Toomet and Henningsen 2008, and ?selection)
gen_d6 <- function() {
  out <- list()
  set.seed(0)                                  # vignette, correct specification
  vc <- diag(3)
  vc[lower.tri(vc)] <- c(0.9, 0.5, 0.1)
  vc[upper.tri(vc)] <- vc[lower.tri(vc)]
  eps <- rmvnorm(500, c(0, 0, 0), vc)
  xs <- runif(500); ys <- xs + eps[, 1] > 0
  xo1 <- runif(500); yo1 <- xo1 + eps[, 2]
  xo2 <- runif(500); yo2 <- xo2 + eps[, 3]
  out$a <- data.frame(ys, xs, xo1, yo1, xo2, yo2)
  set.seed(5)                                  # vignette, non-normal errors
  eps <- rmvnorm(1000, rep(0, 3), vc)
  eps <- eps^2 - 1
  xs <- runif(1000, -1, 0); ys <- xs + eps[, 1] > 0
  xo1 <- runif(1000); yo1 <- xo1 + eps[, 2]
  xo2 <- runif(1000); yo2 <- xo2 + eps[, 3]
  out$b <- data.frame(ys, xs, xo1, yo1, xo2, yo2)
  set.seed(6)                                  # vignette, no exclusion restriction
  xs <- runif(1000, -1, 1)
  ys <- xs + eps[, 1] > 0
  yo1 <- xs + eps[, 2]; yo2 <- xs + eps[, 3]
  out$c <- data.frame(ys, xs, yo1, yo2)
  set.seed(0)                                  # ?selection; the page sets no seed
  N <- 500
  vc <- diag(3)
  vc[lower.tri(vc)] <- c(0.9, 0.5, 0.6)
  vc[upper.tri(vc)] <- vc[lower.tri(vc)]
  eps <- rmvnorm(N, rep(0, 3), vc)
  xs <- runif(N); ys <- xs + eps[, 1] > 0
  xo1 <- runif(N); yo1 <- xo1 + eps[, 2]
  xo2 <- runif(N); yo2 <- xo2 + eps[, 3]
  out$d <- data.frame(ys, xs, xo1, yo1, xo2, yo2)
  out
}
d6 <- gen_d6()
data("ImpactData", package = "endoSwitch", envir = environment())
impact <- as.data.frame(ImpactData)

fb <- function(z, x) list(sel = stats::reformulate(z, "S"),
                          out = list(regime_0 = stats::reformulate(x, "y"),
                                     regime_1 = stats::reformulate(x, "y")),
                          endo = list(y = "y", s = "S", x = x, z = z))
X <- c("x1", "x2"); Z <- c("x1", "z1")
ds <- list(
  D1 = c(list(desc = "base Monte Carlo design, (rho1, rho0) = (0.6, 0.4), N = 500",
              data = gen_base(500, seed0 + 1)), fb(Z, X)),
  D2 = c(list(desc = "base Monte Carlo design, N = 2000",
              data = gen_base(2000, seed0 + 2)), fb(Z, X)),
  D3 = c(list(desc = "base Monte Carlo design, N = 10 000",
              data = gen_base(10000, seed0 + 3)), fb(Z, X)),
  D4 = c(list(desc = "weak exclusion (gamma_z = -0.1), N = 2000",
              data = gen_base(2000, seed0 + 4, gz = -0.1)), fb(Z, X)),
  D5 = list(desc = "different regressors per regime (verify_math.R design), N = 3000",
            data = gen_d5(3000, seed0 + 5), sel = S ~ x1 + z1,
            out = list(regime_0 = y ~ x1, regime_1 = y ~ x1 + x2), endo = NULL),
  D6a = list(desc = "sampleSelection vignette, Tobit-5, correct specification (seed 0, N = 500)",
             data = d6$a, sel = ys ~ xs,
             out = list(regime_0 = yo1 ~ xo1, regime_1 = yo2 ~ xo2), endo = NULL),
  D6b = list(desc = "sampleSelection vignette, Tobit-5, non-normal errors (seed 5, N = 1000, iterlim = 20)",
             data = d6$b, sel = ys ~ xs,
             out = list(regime_0 = yo1 ~ xo1, regime_1 = yo2 ~ xo2), endo = NULL,
             ss_args = list(iterlim = 20)),
  D6c = list(desc = "sampleSelection vignette, Tobit-5, no exclusion restriction (seed 6, N = 1000, iterlim = 20)",
             data = d6$c, sel = ys ~ xs,
             out = list(regime_0 = yo1 ~ xs, regime_1 = yo2 ~ xs), endo = NULL,
             ss_args = list(iterlim = 20)),
  D6d = list(desc = "?selection Tobit-5 example (seed 0 added, N = 500)",
             data = d6$d, sel = ys ~ xs,
             out = list(regime_0 = yo1 ~ xo1, regime_1 = yo2 ~ xo2), endo = NULL),
  D7a = list(desc = "endoSwitch ImpactData, its documented example (CA ~ Age + Perception; Output ~ Age)",
             data = impact, sel = CA ~ Age + Perception,
             out = list(regime_0 = Output ~ Age, regime_1 = Output ~ Age),
             endo = list(y = "Output", s = "CA", x = "Age", z = c("Age", "Perception"))),
  D7b = list(desc = "endoSwitch ImpactData, larger specification chosen for this benchmark",
             data = impact,
             sel = CA ~ Age + Education + Land_holding + Access_to_credit + Perception +
               Number_of_extension_contacts,
             out = list(regime_0 = Output ~ Age + Education + Land_holding + Access_to_credit,
                        regime_1 = Output ~ Age + Education + Land_holding + Access_to_credit),
             endo = list(y = "Output", s = "CA",
                         x = c("Age", "Education", "Land_holding", "Access_to_credit"),
                         z = c("Age", "Education", "Land_holding", "Access_to_credit",
                               "Perception", "Number_of_extension_contacts")))
)
for (k in names(ds)) saveRDS(ds[[k]]$data, file.path(ddir, paste0(k, ".rds")))

## ------------------------------------------------------------ recording
rows <- list()
tol_rule <- c(ll = "|d| <= 1e-4 and ours >= theirs - 1e-6",
              est = "|d| <= 1e-3 max(1, |theirs|)",
              se = "|ours/theirs - 1| <= 0.01",
              eff = "|d| <= 1e-3 max(1, |theirs|)",
              ts = "|d| <= 1e-6")
add <- function(dsid, bench, quantity, ours, theirs, type, status = NULL, note = "") {
  ours <- unname(as.numeric(ours)); theirs <- unname(as.numeric(theirs))
  d <- ours - theirs
  crit <- switch(type,
    ll = abs(d), est = abs(d) / max(1, abs(theirs)), se = abs(ours / theirs - 1),
    eff = abs(d) / max(1, abs(theirs)), ts = abs(d), doc = NA_real_, info = NA_real_)
  if (is.null(status)) {
    ok <- switch(type,
      ll = abs(d) <= 1e-4 && ours >= theirs - 1e-6,
      est = crit <= 1e-3, se = crit <= 0.01, eff = crit <= 1e-3, ts = crit <= 1e-6)
    status <- if (isTRUE(ok)) "pass" else "FAIL"
  }
  rows[[length(rows) + 1L]] <<- data.frame(
    dataset = dsid, benchmark = bench, quantity = quantity, ours = ours,
    theirs = theirs, difference = d, criterion = crit,
    tolerance = if (type %in% names(tol_rule)) tol_rule[[type]] else type,
    status = status, note = note, stringsAsFactors = FALSE)
}
capture <- function(expr) {
  w <- character(0)
  val <- withCallingHandlers(expr, warning = function(e) {
    w <<- c(w, conditionMessage(e)); invokeRestart("muffleWarning") })
  list(value = val, warnings = unique(w))
}
timed <- function(expr) {
  t0 <- proc.time()[["elapsed"]]
  v <- capture(expr)
  v$time <- proc.time()[["elapsed"]] - t0
  v
}
runs <- list()   # fit information per dataset and package

## our effects and conditional expectations at any natural parameter vector
our_effects <- function(f, coef) ns$se_eff_values(unname(coef), f$data, f$map)
our_EY <- function(f, coef) {
  ix <- ns$se_psi_index(f$map, f$data$regimes)
  psi <- ns$se_psi_from_natural(unname(coef), f$map, f$data$regimes)
  ns$se_eff_components(psi, f$data$Z, f$data$X[[1L]], f$data$X[[2L]], ix,
                       grad = FALSE)$EY
}

## ------------------------------------------------------------------ run
for (k in names(ds)) {
  D <- ds[[k]]
  cat(sprintf("%s: %s\n", k, D$desc))
  fo <- timed(switch_fit(D$sel, D$out, data = D$data, method = "fiml"))
  ft <- timed(switch_fit(D$sel, D$out, data = D$data, method = "two_step"))
  f <- fo$value; tsf <- ft$value
  nm <- names(coef(f))
  kz <- length(f$map$index$gamma)
  k0 <- length(f$map$index$beta[[1L]]); k1 <- length(f$map$index$beta[[2L]])
  runs[[k]] <- list(desc = D$desc, n = f$data$n, n1 = sum(f$data$S == 1L),
                    ours = list(time = fo$time, code = f$convergence$code,
                                warnings = c(fo$warnings, ft$warnings),
                                time_ts = ft$time))
  eff_ours <- our_effects(f, coef(f))
  EY_ours <- predict(f, type = "conditional")

  ## ---- sampleSelection ML (their arguments) and, where they limit the
  ## ---- iterations, also with their default iteration limit
  ss_variants <- list(list(label = "sampleSelection ML", args = D$ss_args %||% list()))
  if (!is.null(D$ss_args)) {
    ss_variants[[2]] <- list(label = "sampleSelection ML (default iterations)", args = list())
  }
  for (v in ss_variants) {
    sm <- timed(do.call(selection, c(list(D$sel, unname(D$out), data = D$data,
                                          method = "ml"), v$args)))
    ss <- sm$value
    th <- as.numeric(coef(ss))
    stopifnot(length(th) == length(nm))
    runs[[k]][[v$label]] <- list(time = sm$time, code = ss$code,
                                 message = ss$message, iterations = ss$iterations,
                                 warnings = sm$warnings)
    add(k, v$label, "log-likelihood", f$loglik, as.numeric(logLik(ss)), "ll")
    for (i in seq_along(nm)) add(k, v$label, nm[i], coef(f)[i], th[i], "est")
    se_t <- sqrt(diag(vcov(ss)))
    se_o <- sqrt(diag(vcov(f)))
    for (i in seq_along(nm)) add(k, v$label, paste("SE", nm[i]), se_o[i], se_t[i], "se")
    e_t <- our_effects(f, th)
    for (q in names(eff_ours)) add(k, v$label, q, eff_ours[[q]], e_t[[q]], "eff",
                                   note = "ours at both estimates")
    EYt <- our_EY(f, th)
    for (q in colnames(EY_ours)) {
      r <- abs(EY_ours[, q] - EYt[, q]) / pmax(1, abs(EYt[, q]))
      j <- which.max(r)
      add(k, v$label, paste(q, "(largest unit difference)"), EY_ours[j, q], EYt[j, q], "eff",
          note = "ours at both estimates")
    }
  }

  ## ---- sampleSelection two-step
  s2 <- timed(selection(D$sel, unname(D$out), data = D$data, method = "2step"))
  cs <- as.numeric(coef(s2$value))
  psi <- tsf$two_step$psi
  # sampleSelection: gamma, beta0, IMR1, sigma1, rho1, beta1, IMR2, sigma2, rho2
  i_b0 <- kz + seq_len(k0); i_imr1 <- kz + k0 + 1L
  i_b1 <- kz + k0 + 3L + seq_len(k1); i_imr2 <- max(i_b1) + 1L
  runs[[k]][["sampleSelection two-step"]] <- list(time = s2$time, warnings = s2$warnings)
  lab <- "sampleSelection two-step"
  for (i in seq_len(kz)) add(k, lab, nm[i], psi[i], cs[i], "ts")
  for (i in seq_len(k0)) add(k, lab, nm[kz + i], psi[kz + i], cs[i_b0[i]], "ts")
  add(k, lab, "theta0 = sigma0 rho0 (their IMR1 with the sign mapped)",
      psi[kz + k0 + 1L], -cs[i_imr1], "ts")
  for (i in seq_len(k1)) add(k, lab, nm[kz + k0 + 2L + i], psi[kz + k0 + 1L + i],
                             cs[i_b1[i]], "ts")
  add(k, lab, "theta1 = sigma1 rho1 (their IMR2)", psi[kz + k0 + k1 + 2L], cs[i_imr2], "ts")
  ct <- coef(tsf)
  for (q in c("sigma", "rho")) for (r in 1:2) {
    io <- f$map$index[[q]][[r]]
    i_imr <- if (r == 1L) i_imr1 else i_imr2
    it <- i_imr + if (q == "sigma") 1L else 2L
    add(k, lab, nm[io], ct[[io]], cs[it], "doc", status = "documented",
        note = "D-SS-1: different variance formula")
  }

  ## ---- endoSwitch
  if (!is.null(D$endo)) {
    e <- D$endo
    dd <- D$data[, unique(c(e$y, e$s, e$x, e$z))]
    stopifnot(nrow(stats::na.omit(dd)) == f$data$n)
    pick_nat <- function(r) {
      b <- r$MLE.Results$estimate; dp <- r$distPar
      c(b[c("Select.Const", paste0("Select.", e$z))],
        b[c("Outcome.0.Const", paste0("Outcome.0.", e$x))],
        dp["Outcome.0.Sigma", 1], dp["Outcome.0.Rho", 1],
        b[c("Outcome.1.Const", paste0("Outcome.1.", e$x))],
        dp["Outcome.1.Sigma", 1], dp["Outcome.1.Rho", 1])
    }
    pick_se <- function(r) {
      s <- sqrt(diag(solve(-r$MLE.Results$hessian))); dp <- r$distPar
      c(s[c("Select.Const", paste0("Select.", e$z))],
        s[c("Outcome.0.Const", paste0("Outcome.0.", e$x))],
        dp["Outcome.0.Sigma", 2], dp["Outcome.0.Rho", 2],
        s[c("Outcome.1.Const", paste0("Outcome.1.", e$x))],
        dp["Outcome.1.Sigma", 2], dp["Outcome.1.Rho", 2])
    }
    variants <- list(list(label = "endoSwitch FIML", args = list()),
                     list(label = "endoSwitch FIML (reltol 1e-14)",
                          args = list(control = list(reltol = 1e-14))))
    for (v in variants) {
      em <- timed(do.call(endoSwitch, c(list(dd, e$y, e$s, e$x, e$z,
                                             treatEffect = TRUE), v$args)))
      r <- em$value
      runs[[k]][[v$label]] <- list(time = em$time, code = r$MLE.Results$code,
                                   message = r$MLE.Results$message,
                                   iterations = r$MLE.Results$iterations,
                                   warnings = em$warnings)
      th <- pick_nat(r); se_t <- pick_se(r)
      add(k, v$label, "log-likelihood", f$loglik, r$MLE.Results$maximum, "ll")
      for (i in seq_along(nm)) add(k, v$label, nm[i], coef(f)[i], th[i], "est")
      se_o <- sqrt(diag(vcov(f)))
      for (i in seq_along(nm)) add(k, v$label, paste("SE", nm[i]), se_o[i], se_t[i], "se")
      ## their reported effects (rounded to 4 decimals by endoSwitch)
      te <- r$treatEffect
      g <- function(i, j) as.numeric(te[i, j])
      rep_eff <- c(ATT = g("A1", 3), ATU = g("A0", 3), TH = g("Heterogeneity", 3),
                   BH1 = g("Heterogeneity", 1), BH0 = g("Heterogeneity", 2))
      for (q in names(rep_eff)) add(k, v$label, q, eff_ours[[q]], rep_eff[[q]], "eff",
                                    note = "end to end; theirs rounded to 4 decimals")
      ## their conditional expectations (unrounded) against ours, per unit
      ey <- endoSwitch:::treatmentEffect(r$MLE.Results, data.table::as.data.table(dd),
                                         e$y, e$s, e$x, e$z, FALSE)
      S1 <- f$data$S == 1L
      their <- list(EY1_S1 = ey$EYA1[[1]], EY0_S1 = ey$EYA1[[2]],
                    EY1_S0 = ey$EYA0[[1]], EY0_S0 = ey$EYA0[[2]])
      sets <- list(EY1_S1 = S1, EY0_S1 = S1, EY1_S0 = !S1, EY0_S0 = !S1)
      EYt <- our_EY(f, th)
      for (q in names(their)) {
        o <- EY_ours[sets[[q]], q]; t <- as.numeric(their[[q]])
        rr <- abs(o - t) / pmax(1, abs(t)); j <- which.max(rr)
        add(k, v$label, paste(q, "(largest unit difference)"), o[j], t[j], "eff",
            note = "end to end")
        o2 <- EYt[sets[[q]], q]
        add(k, v$label, paste(q, "formula at their estimates (largest unit difference)"),
            o2[which.max(abs(o2 - t))], t[which.max(abs(o2 - t))], "eff",
            note = "our formula at their estimates")
      }
    }
    ## two-stage estimator
    e2 <- timed(endoSwitch2Stage(dd, e$y, e$s, e$x, e$z))
    r2 <- e2$value
    runs[[k]][["endoSwitch two-stage"]] <- list(time = e2$time, warnings = e2$warnings)
    lab <- "endoSwitch two-stage"
    g1 <- coef(r2$FirstStageReg); c0 <- coef(r2$SecondStageReg.0)
    c1 <- coef(r2$SecondStageReg.1)
    for (i in seq_len(kz)) add(k, lab, nm[i], psi[i], g1[i], "ts")
    for (i in seq_len(k0)) add(k, lab, nm[kz + i], psi[kz + i], c0[i], "ts")
    add(k, lab, "theta0 = sigma0 rho0 (minus their MillsRatioAdt0)",
        psi[kz + k0 + 1L], -c0[["MillsRatioAdt0"]], "ts")
    for (i in seq_len(k1)) add(k, lab, nm[kz + k0 + 2L + i], psi[kz + k0 + 1L + i], c1[i], "ts")
    add(k, lab, "theta1 = sigma1 rho1 (their MillsRatioAdt1)",
        psi[kz + k0 + k1 + 2L], c1[["MillsRatioAdt1"]], "ts")
    dp <- r2$distParEst
    add(k, lab, nm[f$map$index$sigma[[1]]], ct[[f$map$index$sigma[[1]]]], dp[["sigma0"]],
        "doc", status = "documented", note = "D-ES-1: different variance formula")
    add(k, lab, nm[f$map$index$rho[[1]]], ct[[f$map$index$rho[[1]]]], dp[["rho0"]],
        "doc", status = "documented", note = "D-ES-1")
    add(k, lab, nm[f$map$index$sigma[[2]]], ct[[f$map$index$sigma[[2]]]], dp[["sigma1"]],
        "doc", status = "documented", note = "D-ES-1")
    add(k, lab, nm[f$map$index$rho[[2]]], ct[[f$map$index$rho[[2]]]], dp[["rho1"]],
        "doc", status = "documented", note = "D-ES-1")
  }
}

## ------------------------------------------- weighted and clustered fits
## (added in 0.8.1 at the owner's request; datasets and comparisons fixed
## before the run). sampleSelection ignores weights in Tobit-5 models, so:
##  D8   integer weights: our weighted fit against sampleSelection on the data
##       with each row replicated w times. Our sampling-weight sandwich equals
##       sandwich::vcovCL on the replicated data clustered by original row
##       (HC0, no cluster adjustment); our cluster estimator equals vcovCL
##       clustered by cluster (HC0, G/(G - 1)). Also endoSwitch's Weight.
##  D8b  continuous weights: endoSwitch's Weight only.
##  D9   clustered data (cluster components in x1, z1, u and the outcome
##       noise), unweighted: our sandwich, OPG and cluster covariances
##       against the sandwich package applied to sampleSelection's fit.
suppressPackageStartupMessages(library(sandwich))
gen_cluster <- function(seed, G = 100L, m = 20L) {
  set.seed(seed)
  N <- G * m; cl <- rep(seq_len(G), each = m)
  cg <- function(share) sqrt(share) * rnorm(G)[cl] + sqrt(1 - share) * rnorm(N)
  x1 <- cg(0.5); x2 <- rnorm(N); z1 <- cg(0.5); u <- cg(0.3)
  e1 <- 0.6 * u + sqrt(1 - 0.36) * cg(0.3)
  e0 <- 0.4 * u + sqrt(1 - 0.16) * cg(0.3)
  S <- as.integer(0.5 + 0.3 * x1 - 0.4 * z1 + u > 0)
  y <- ifelse(S == 1, 1.5 + 0.8 * x1 + 0.4 * x2 + e1, 1.0 + 0.5 * x1 + 0.2 * x2 + e0)
  data.frame(S, y, x1, x2, z1, cl)
}
d8 <- gen_base(2000, seed0 + 8)
set.seed(seed0 + 80); d8$w <- sample(1:3, nrow(d8), TRUE)
d8$cl <- rep(1:100, each = 20)
d8b <- gen_base(2000, seed0 + 9)
set.seed(seed0 + 90); d8b$w <- runif(nrow(d8b), 0.5, 2)
d9 <- gen_cluster(seed0 + 10)
ds_wc <- list(
  D8 = list(desc = "base design, N = 2000, integer weights 1-3 and 100 clusters", data = d8),
  D8b = list(desc = "base design, N = 2000, continuous weights U(0.5, 2)", data = d8b),
  D9 = list(desc = "clustered data, N = 2000 in 100 clusters (cluster share 0.5 in x1 and z1, 0.3 in the errors)",
            data = d9))
for (k in names(ds_wc)) saveRDS(ds_wc[[k]]$data, file.path(ddir, paste0(k, ".rds")))
fwc <- function(d, ...) capture(switch_fit(S ~ x1 + z1, list(regime_0 = y ~ x1 + x2,
                                                             regime_1 = y ~ x1 + x2),
                                           data = d, ...))$value
se_of <- function(V) sqrt(diag(V))
cmp_se <- function(k, lab, what, so, st, nm) {
  for (i in seq_along(nm)) add(k, lab, paste0("SE (", what, ") ", nm[i]), so[i], st[i], "se")
}
endo_X <- list(y = "y", s = "S", x = c("x1", "x2"), z = c("x1", "z1"))
endo_pick <- function(r, e) {
  b <- r$MLE.Results$estimate; dp <- r$distPar
  s <- sqrt(diag(solve(-r$MLE.Results$hessian)))
  ix <- function(v) c(v[c("Select.Const", paste0("Select.", e$z))],
                      v[c("Outcome.0.Const", paste0("Outcome.0.", e$x))])
  ix1 <- function(v) v[c("Outcome.1.Const", paste0("Outcome.1.", e$x))]
  list(theta = c(ix(b), dp["Outcome.0.Sigma", 1], dp["Outcome.0.Rho", 1], ix1(b),
                 dp["Outcome.1.Sigma", 1], dp["Outcome.1.Rho", 1]),
       se = c(ix(s), dp["Outcome.0.Sigma", 2], dp["Outcome.0.Rho", 2], ix1(s),
              dp["Outcome.1.Sigma", 2], dp["Outcome.1.Rho", 2]))
}

## D8: integer weights
k <- "D8"; cat(k, ":", ds_wc[[k]]$desc, "\n")
fw_h <- fwc(d8, weights = ~w, vcov = "hessian")
fw_s <- fwc(d8, weights = ~w)
fw_c <- fwc(d8, weights = ~w, cluster = ~cl)
nm <- names(coef(fw_h))
dx <- d8[rep(seq_len(nrow(d8)), d8$w), ]
dx$id <- rep(seq_len(nrow(d8)), d8$w)
ssx <- selection(S ~ x1 + z1, list(y ~ x1 + x2, y ~ x1 + x2), data = dx, method = "ml")
lab <- "sampleSelection ML on replicated rows (+ sandwich package)"
add(k, lab, "log-likelihood", fw_h$loglik, as.numeric(logLik(ssx)), "ll")
thx <- as.numeric(coef(ssx))
for (i in seq_along(nm)) add(k, lab, nm[i], coef(fw_h)[i], thx[i], "est")
for (i in seq_along(nm)) add(k, lab, nm[i], coef(fw_s)[i], thx[i], "est",
                             note = "fit with the default (sandwich) covariance")
cmp_se(k, lab, "Hessian", se_of(vcov(fw_h)), se_of(vcov(ssx)), nm)
cmp_se(k, lab, "sandwich", se_of(vcov(fw_s)),
       se_of(vcovCL(ssx, cluster = dx$id, type = "HC0", cadjust = FALSE)), nm)
cmp_se(k, lab, "cluster", se_of(vcov(fw_c)),
       se_of(vcovCL(ssx, cluster = dx$cl, type = "HC0", cadjust = TRUE)), nm)
eff_w <- our_effects(fw_h, coef(fw_h)); eff_wt <- our_effects(fw_h, thx)
for (q in names(eff_w)) add(k, lab, paste(q, "(weighted)"), eff_w[[q]], eff_wt[[q]], "eff",
                            note = "ours at both estimates")
lab <- "endoSwitch FIML, weighted"
re <- capture(endoSwitch(d8[, c("y", "S", "x1", "x2", "z1", "w")], "y", "S", c("x1", "x2"),
                         c("x1", "z1"), Weight = "w", treatEffect = TRUE,
                         control = list(reltol = 1e-14)))$value
pe <- endo_pick(re, endo_X)
add(k, lab, "log-likelihood", fw_h$loglik, re$MLE.Results$maximum, "ll")
for (i in seq_along(nm)) add(k, lab, nm[i], coef(fw_h)[i], pe$theta[i], "est")
cmp_se(k, lab, "Hessian", se_of(vcov(fw_h)), pe$se, nm)
te <- re$treatEffect
tatt <- as.numeric(te["A1", 3]); tatu <- as.numeric(te["A0", 3])
## endoSwitch averages its effects without the weights: our weighted
## effects differ by design, our unweighted formula at its estimates agrees
f_unw <- fwc(d8)
eff_u <- our_effects(f_unw, pe$theta)
add(k, lab, "ATT (ours weighted vs theirs)", eff_w[["ATT"]], tatt, "doc",
    status = "documented", note = "D-ES-2: endoSwitch averages effects without weights")
add(k, lab, "ATU (ours weighted vs theirs)", eff_w[["ATU"]], tatu, "doc",
    status = "documented", note = "D-ES-2")
add(k, lab, "ATT (our unweighted formula at their estimates)", eff_u[["ATT"]], tatt, "eff",
    note = "theirs rounded to 4 decimals")
add(k, lab, "ATU (our unweighted formula at their estimates)", eff_u[["ATU"]], tatu, "eff",
    note = "theirs rounded to 4 decimals")

## D8b: continuous weights (endoSwitch only)
k <- "D8b"; cat(k, ":", ds_wc[[k]]$desc, "\n")
fb_h <- fwc(d8b, weights = ~w, vcov = "hessian")
re <- capture(endoSwitch(d8b[, c("y", "S", "x1", "x2", "z1", "w")], "y", "S", c("x1", "x2"),
                         c("x1", "z1"), Weight = "w", treatEffect = FALSE,
                         control = list(reltol = 1e-14)))$value
pe <- endo_pick(re, endo_X)
lab <- "endoSwitch FIML, weighted"
add(k, lab, "log-likelihood", fb_h$loglik, re$MLE.Results$maximum, "ll")
for (i in seq_along(nm)) add(k, lab, nm[i], coef(fb_h)[i], pe$theta[i], "est")
cmp_se(k, lab, "Hessian", se_of(vcov(fb_h)), pe$se, nm)

## D9: clustered data, unweighted
k <- "D9"; cat(k, ":", ds_wc[[k]]$desc, "\n")
f9 <- list(hessian = fwc(d9, vcov = "hessian"), sandwich = fwc(d9, vcov = "sandwich"),
           opg = fwc(d9, vcov = "opg"), cluster = fwc(d9, cluster = ~cl))
ss9 <- selection(S ~ x1 + z1, list(y ~ x1 + x2, y ~ x1 + x2), data = d9, method = "ml")
th9 <- as.numeric(coef(ss9))
lab <- "sampleSelection ML + sandwich package"
add(k, lab, "log-likelihood", f9$hessian$loglik, as.numeric(logLik(ss9)), "ll")
for (i in seq_along(nm)) add(k, lab, nm[i], coef(f9$hessian)[i], th9[i], "est")
cmp_se(k, lab, "Hessian", se_of(vcov(f9$hessian)), se_of(vcov(ss9)), nm)
cmp_se(k, lab, "sandwich", se_of(vcov(f9$sandwich)), se_of(sandwich(ss9)), nm)
cmp_se(k, lab, "OPG", se_of(vcov(f9$opg)), se_of(vcovOPG(ss9)), nm)
cmp_se(k, lab, "cluster", se_of(vcov(f9$cluster)),
       se_of(vcovCL(ss9, cluster = d9$cl, type = "HC0", cadjust = TRUE)), nm)
for (q in c("sandwich", "opg", "cluster")) {
  for (i in seq_along(nm)) add(k, lab, paste0(nm[i], " (fit with ", q, ")"),
                               coef(f9[[q]])[i], th9[i], "est")
}

## -------------------------------------------- D-ES-1: large-sample check
## Two-step variance recovery at n = 200 000 and 400 000 (truth sigma0 = 0.8,
## rho0 = 0.4, sigma1 = 1.2, rho1 = 0.6): SwitchEconometrics (Heckman 1979),
## endoSwitch2Stage and sampleSelection 2step against the truth.
consist <- list()
for (n in c(200000, 400000)) {
  d <- gen_base(n, seed0 + 100 + n / 200000, sigma1 = 1.2, sigma0 = 0.8)
  tsf <- switch_fit(S ~ x1 + z1, list(regime_0 = y ~ x1 + x2, regime_1 = y ~ x1 + x2),
                    data = d, method = "two_step")
  ct <- coef(tsf); ix <- tsf$map$index
  r2 <- suppressWarnings(endoSwitch2Stage(d, "y", "S", c("x1", "x2"), c("x1", "z1")))
  s2 <- selection(S ~ x1 + z1, list(y ~ x1 + x2, y ~ x1 + x2), data = d, method = "2step")
  cs <- coef(s2)
  consist[[length(consist) + 1L]] <- data.frame(
    n = n, estimator = c("truth", "SwitchEconometrics two-step", "endoSwitch2Stage",
                         "sampleSelection 2step"),
    sigma0 = c(0.8, ct[[ix$sigma[[1]]]], r2$distParEst[["sigma0"]], cs[["sigma1"]]),
    rho0 = c(0.4, ct[[ix$rho[[1]]]], r2$distParEst[["rho0"]], cs[["rho1"]]),
    sigma1 = c(1.2, ct[[ix$sigma[[2]]]], r2$distParEst[["sigma1"]], cs[["sigma2"]]),
    rho1 = c(0.6, ct[[ix$rho[[2]]]], r2$distParEst[["rho1"]], cs[["rho2"]]))
}
consist <- do.call(rbind, consist)

## --------------------------------------------------------------- output
res <- do.call(rbind, rows)
write.csv(res, file.path(odir, "benchmark_g1.csv"), row.names = FALSE)
write.csv(consist, file.path(odir, "benchmark_g1_variance_check.csv"), row.names = FALSE)

fmt <- function(x) ifelse(is.na(x), "", formatC(x, digits = 6, format = "g"))
fmte <- function(x) ifelse(is.na(x), "", formatC(x, digits = 2, format = "e"))
md <- c("# Benchmarks, Generation 1: generated tables",
        "",
        sprintf("Generated %s by `benchmark_g1.R`. Protocol and tolerances: BENCHMARK_PROTOCOL.md section 3.",
                format(Sys.time(), "%Y-%m-%d %H:%M")),
        "", "## Software", "",
        "| Package | Version |", "| --- | --- |",
        sprintf("| R | %s |", getRversion()),
        vapply(c("SwitchEconometrics", "sampleSelection", "endoSwitch", "maxLik",
                 "sandwich", "mvtnorm", "data.table", "msm"),
               function(p) sprintf("| %s | %s |", p, packageVersion(p)), character(1)),
        "", "## Summary", "",
        "| Dataset | Benchmark | Checks | Passed | Failed | Documented differences |",
        "| --- | --- | --- | --- | --- | --- |")
for (k in unique(res$dataset)) for (b in unique(res$benchmark[res$dataset == k])) {
  s <- res[res$dataset == k & res$benchmark == b, ]
  md <- c(md, sprintf("| %s | %s | %d | %d | %d | %d |", k, b,
                      sum(s$status %in% c("pass", "FAIL")), sum(s$status == "pass"),
                      sum(s$status == "FAIL"), sum(s$status == "documented")))
}
tot <- res[res$status %in% c("pass", "FAIL"), ]
md <- c(md, sprintf("| **All** | | %d | %d | %d | %d |", nrow(tot),
                    sum(tot$status == "pass"), sum(tot$status == "FAIL"),
                    sum(res$status == "documented")))
fails <- res[res$status == "FAIL", ]
md <- c(md, "", "## Failed checks", "")
if (nrow(fails)) {
  md <- c(md, "| Dataset | Benchmark | Quantity | Ours | Theirs | Difference | Criterion | Tolerance |",
          "| --- | --- | --- | --- | --- | --- | --- | --- |",
          sprintf("| %s | %s | %s | %s | %s | %s | %s | %s |", fails$dataset, fails$benchmark,
                  fails$quantity, fmt(fails$ours), fmt(fails$theirs), fmte(fails$difference),
                  fmte(fails$criterion), fails$tolerance))
} else md <- c(md, "None.")
md <- c(md, "", "## Fits", "",
        "| Dataset | N (regime 1) | Package | Time (s) | Convergence | Warnings |",
        "| --- | --- | --- | --- | --- | --- |")
for (k in names(runs)) {
  R <- runs[[k]]
  for (p in setdiff(names(R), c("desc", "n", "n1"))) {
    x <- R[[p]]
    conv <- if (!is.null(x$code)) paste0("code ", x$code,
                                         if (!is.null(x$iterations)) paste0(", ", x$iterations, " iterations") else "",
                                         if (!is.null(x$message)) paste0(": ", x$message) else "") else ""
    md <- c(md, sprintf("| %s | %d (%d) | %s | %.2f | %s | %s |", k, R$n, R$n1,
                        if (p == "ours") "SwitchEconometrics FIML" else p, x$time, conv,
                        gsub("\\|", "/", paste(x$warnings, collapse = "; "))))
  }
}
md <- c(md, "", "## Two-step variance recovery (D-ES-1, D-SS-1)", "",
        "| n | Estimator | sigma0 | rho0 | sigma1 | rho1 |", "| --- | --- | --- | --- | --- | --- |",
        sprintf("| %d | %s | %.4f | %.4f | %.4f | %.4f |", consist$n, consist$estimator,
                consist$sigma0, consist$rho0, consist$sigma1, consist$rho1))
md <- c(md, "", "## Tables by dataset")
all_ds <- c(ds, ds_wc)
for (k in names(all_ds)) {
  s <- res[res$dataset == k, ]
  md <- c(md, "", sprintf("### %s: %s", k, all_ds[[k]]$desc), "",
          "| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |",
          "| --- | --- | --- | --- | --- | --- | --- |",
          sprintf("| %s | %s | %s | %s | %s | %s | %s |", s$benchmark, s$quantity, fmt(s$ours),
                  fmt(s$theirs), fmte(s$difference), fmte(s$criterion), s$status))
}
writeLines(md, file.path(odir, "BENCHMARK_G1_generated.md"), useBytes = TRUE)
cat(sprintf("%d checks: %d passed, %d failed; %d documented differences\n", nrow(tot),
            sum(tot$status == "pass"), sum(tot$status == "FAIL"), sum(res$status == "documented")))
