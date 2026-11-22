## benchmark_g1_diagnostics.R -- evidence for the benchmark differences that
## exceed the tolerances of BENCHMARK_PROTOCOL.md section 3
## (BENCHMARK_G1.md section 4).
##
## Usage (from the workspace root, after benchmark_g1.R):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/benchmark_g1_diagnostics.R \
##       <library> <data dir> <output .csv>
##
## E1  endoSwitch standard errors: at endoSwitch's own estimates, standard
##     errors from (a) the SwitchEconometrics analytic Hessian, (b) a
##     Richardson-extrapolated numerical Hessian of endoSwitch's own
##     log-likelihood function (numDeriv), (c) maxLik::numericHessian of
##     endoSwitch's function (the Hessian maxLik reports after BFGS without an
##     analytic gradient), against the standard errors endoSwitch reports.
## E2  dataset D6b: gradient of the log-likelihood at sampleSelection's
##     estimates; boundary behaviour of the SwitchEconometrics fit.
## E3  two-step differences of order 1e-6: probit score at each package's
##     probit estimates, and glm refitted with a tight tolerance.

args <- commandArgs(trailingOnly = TRUE)
lib <- normalizePath(args[1]); ddir <- args[2]; out <- args[3]
.libPaths(c(lib, .libPaths()))
suppressPackageStartupMessages({
  library(SwitchEconometrics); library(sampleSelection); library(endoSwitch)
  library(numDeriv); library(maxLik)
})
ns <- asNamespace("SwitchEconometrics")
rd <- function(k) readRDS(file.path(ddir, paste0(k, ".rds")))
rows <- list()
rec <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)

## our natural-scale covariance at any natural parameter vector
our_vcov_at <- function(f, theta_n) {
  thw <- ns$se_par_working(f$map, unname(theta_n))
  obj <- ns$se_objective(f$data, f$map)
  fr <- obj$free
  val <- obj$eval_at(unname(thw[fr]), 2L)
  Vw <- matrix(0, f$map$p, f$map$p)
  Vw[fr, fr] <- solve(-val$hessian[fr, fr, drop = FALSE])
  list(V = ns$se_par_vcov_natural(f$map, thw, Vw), grad = val$gradient)
}

## ---------------------------------------------------------------- E1
endo_fn <- function(dd, e) {
  envir <- new.env()
  fn <- endoSwitch:::maxLogFunc
  environment(fn) <- envir
  dt <- data.table::as.data.table(dd)
  assign("data", dt, envir); assign("OutcomeDep", e$y, envir)
  assign("SelectDep", e$s, envir); assign("OutcomeCov", e$x, envir)
  assign("SelectCov", e$z, envir); assign("Weight", NA, envir)
  assign("OutcomeParNum", length(e$x) + 1, envir)
  assign("SelectParNum", length(e$z) + 1, envir)
  assign("TotParNum", 2 * (length(e$x) + 1) + length(e$z) + 1 + 4, envir)
  assign("verbose", FALSE, envir); assign("envir", envir, envir)
  fn
}
X <- c("x1", "x2"); Z <- c("x1", "z1")
e1_sets <- list(D2 = list(y = "y", s = "S", x = X, z = Z),
                D3 = list(y = "y", s = "S", x = X, z = Z),
                D4 = list(y = "y", s = "S", x = X, z = Z))
for (k in names(e1_sets)) {
  e <- e1_sets[[k]]
  dd <- rd(k)[, c("y", "S", "x1", "x2", "z1")]
  f <- switch_fit(S ~ x1 + z1, list(regime_0 = y ~ x1 + x2, regime_1 = y ~ x1 + x2), data = dd)
  r <- endoSwitch(dd, e$y, e$s, e$x, e$z, treatEffect = FALSE)
  b <- r$MLE.Results$estimate
  ## endoSwitch working order -> natural vectors in our order
  ord <- c("Select.Const", paste0("Select.", e$z), "Outcome.0.Const", paste0("Outcome.0.", e$x),
           "Outcome.0.SigmaX", "Outcome.0.RhoX", "Outcome.1.Const", paste0("Outcome.1.", e$x),
           "Outcome.1.SigmaX", "Outcome.1.RhoX")
  nat <- function(v) { v <- v[ord]; s <- grep("SigmaX", ord); h <- grep("RhoX", ord)
                       v[s] <- exp(v[s]); v[h] <- tanh(v[h]); v }
  dnat <- function(v, se) { names(se) <- names(v); v <- v[ord]; se <- se[ord]
                            s <- grep("SigmaX", ord)
                            h <- grep("RhoX", ord); se[s] <- exp(v[s]) * se[s]
                            se[h] <- (1 - tanh(v[h])^2) * se[h]; se }
  th_n <- nat(b)
  se_rep <- dnat(b, sqrt(diag(solve(-r$MLE.Results$hessian))))
  fn <- endo_fn(dd, e)
  H_rich <- numDeriv::hessian(fn, b)
  H_mlk <- maxLik::numericHessian(fn, t0 = b)
  se_rich <- dnat(b, sqrt(diag(solve(-H_rich))))
  se_mlk <- dnat(b, sqrt(diag(solve(-H_mlk))))
  oa <- our_vcov_at(f, th_n)
  se_an <- sqrt(diag(oa$V))
  se_ours <- sqrt(diag(vcov(f)))
  nm <- names(coef(f))
  rec(check = "E1", dataset = k, quantity = nm,
      se_reported_endoSwitch = unname(se_rep),
      se_maxLik_numericHessian = unname(se_mlk),
      se_richardson_endoSwitch_fn = unname(se_rich),
      se_analytic_at_their_estimates = unname(se_an),
      se_ours_at_our_estimates = unname(se_ours))
  cat(sprintf("E1 %s: max |reported/maxLik-numeric - 1| = %.2e; max |Richardson/analytic - 1| = %.2e; max |reported/analytic - 1| = %.2e; loglik fn at their est %.6f vs reported %.6f\n",
              k, max(abs(se_rep / se_mlk - 1)), max(abs(se_rich / se_an - 1)),
              max(abs(se_rep / se_an - 1)), fn(b), r$MLE.Results$maximum))
}

## ---------------------------------------------------------------- E2
d6b <- rd("D6b")
f <- suppressWarnings(switch_fit(ys ~ xs, list(regime_0 = yo1 ~ xo1, regime_1 = yo2 ~ xo2), data = d6b))
ss <- selection(ys ~ xs, list(yo1 ~ xo1, yo2 ~ xo2), data = d6b, iterlim = 20)
th_ss <- as.numeric(coef(ss))
thw <- ns$se_par_working(f$map, th_ss)
obj <- ns$se_objective(f$data, f$map)
v_ss <- obj$eval_at(unname(thw[obj$free]), 1L)
v_ours <- obj$eval_at(unname(coef(f, "working")[obj$free]), 1L)
rec(check = "E2", dataset = "D6b",
    quantity = c("loglik at sampleSelection estimates (our function)",
                 "loglik reported by sampleSelection",
                 "max |gradient| at sampleSelection estimates (working scale)",
                 "loglik at SwitchEconometrics end point",
                 "rho0, rho1 at SwitchEconometrics end point",
                 "SwitchEconometrics convergence code"),
    se_reported_endoSwitch = NA, se_maxLik_numericHessian = NA,
    se_richardson_endoSwitch_fn = NA, se_analytic_at_their_estimates = NA,
    se_ours_at_our_estimates = NA,
    value = c(v_ss$loglik, as.numeric(logLik(ss)), max(abs(v_ss$gradient)),
              v_ours$loglik, NA, f$convergence$code),
    text = c("", "", "", "", paste(signif(coef(f)[unlist(f$map$index$rho)], 6), collapse = ", "), ""))
cat(sprintf("E2 D6b: loglik(ours fn at SS est) %.6f vs SS %.6f; max|grad| at SS est %.3g; our end loglik %.4f; rho %s; code %d\n",
            v_ss$loglik, as.numeric(logLik(ss)), max(abs(v_ss$gradient)), v_ours$loglik,
            paste(signif(coef(f)[unlist(f$map$index$rho)], 6), collapse = ", "), f$convergence$code))
## log-likelihood as rho1 approaches 1 with the other parameters profiled
## out would be costly; record instead the path of the fit's diagnostics
cat("E2 D6b warnings:", paste(f$warnings %||% "", collapse = " / "), "\n")

## ---------------------------------------------------------------- E3
probit_score <- function(g, Z, S) {
  w <- drop(Z %*% g)
  lam <- ifelse(S == 1, dnorm(w) / pnorm(w), -dnorm(w) / pnorm(-w))
  max(abs(colSums(lam * Z)))
}
e3 <- list(
  D6c = list(sel = ys ~ xs, out = list(regime_0 = yo1 ~ xs, regime_1 = yo2 ~ xs), endo = NULL),
  D7b = list(sel = CA ~ Age + Education + Land_holding + Access_to_credit + Perception +
               Number_of_extension_contacts,
             out = list(regime_0 = Output ~ Age + Education + Land_holding + Access_to_credit,
                        regime_1 = Output ~ Age + Education + Land_holding + Access_to_credit),
             endo = TRUE))
for (k in names(e3)) {
  D <- e3[[k]]; dd <- rd(k)
  ts <- suppressWarnings(switch_fit(D$sel, D$out, data = dd, method = "two_step"))
  Zm <- ts$data$Z; Sv <- ts$data$S
  g_ours <- ts$two_step$probit$gamma
  s2 <- selection(D$sel, unname(D$out), data = dd, method = "2step")
  g_ss <- as.numeric(coef(s2))[seq_along(g_ours)]
  sc <- c(ours = probit_score(g_ours, Zm, Sv), sampleSelection = probit_score(g_ss, Zm, Sv))
  dif <- c(sampleSelection = max(abs(g_ss - g_ours)))
  if (!is.null(D$endo)) {
    df <- as.data.frame(dd); df$S_ <- as.integer(Sv)
    g_glm <- coef(suppressWarnings(glm(D$sel, family = binomial("probit"), data = dd)))
    g_tight <- coef(suppressWarnings(glm(D$sel, family = binomial("probit"), data = dd,
                                         control = glm.control(epsilon = 1e-14, maxit = 100))))
    sc <- c(sc, glm_default = probit_score(g_glm, Zm, Sv), glm_tight = probit_score(g_tight, Zm, Sv))
    dif <- c(dif, glm_default = max(abs(g_glm - g_ours)), glm_tight = max(abs(g_tight - g_ours)))
  }
  rec(check = "E3", dataset = k, quantity = c(paste("probit max |score| at", names(sc)),
                                              paste("probit max |difference| from ours,", names(dif))),
      se_reported_endoSwitch = NA, se_maxLik_numericHessian = NA,
      se_richardson_endoSwitch_fn = NA, se_analytic_at_their_estimates = NA,
      se_ours_at_our_estimates = NA, value = c(sc, dif), text = "")
  cat(sprintf("E3 %s: probit max|score| %s; max|diff| from ours %s\n", k,
              paste(names(sc), signif(sc, 3), collapse = ", "),
              paste(names(dif), signif(dif, 3), collapse = ", ")))
}

fill <- function(x) { for (v in c("value", "text")) if (is.null(x[[v]])) x[[v]] <- if (v == "value") NA_real_ else ""; x }
res <- do.call(rbind, lapply(rows, fill))
write.csv(res, out, row.names = FALSE)
cat("written:", out, "\n")
