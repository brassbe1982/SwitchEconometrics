## benchmark_g2.R -- cross-software benchmarks of Generation 2
## (protocol: 04_Validation/BENCHMARK_PROTOCOL.md sections 3 and 6).
##
## Usage (from the workspace root):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/benchmark_g2.R \
##       <library> <data dir> <output dir>
##   library     private library with SwitchEconometrics (the version to test)
##               and endogenous 1.0 (runs/lib_g2)
##   data dir    where the datasets are saved (runs/benchmarks_g2)
##   output dir  where BENCHMARK_G2_generated.md and benchmark_g2.csv are
##               written (04_Validation/results)
##
## Delivered in WP2.1 (decided before the run):
##   heckman()    against sampleSelection::selection(), ML and two-step
##   treatment()  against sampleSelection::treatReg(), ML and two-step, and
##                against endogenous::hybrid() (model-based standard errors)
##   tobit5()     against sampleSelection::selection() (Tobit-5), ML
## Tolerances: BENCHMARK_PROTOCOL.md section 3.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) stop("usage: benchmark_g2.R <library> <data dir> <output dir>")
lib <- normalizePath(args[1]); ddir <- args[2]; odir <- args[3]
dir.create(ddir, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
suppressPackageStartupMessages({
  library(SwitchEconometrics); library(sampleSelection); library(endogenous)
})
stopifnot(startsWith(normalizePath(find.package("SwitchEconometrics")), lib))
ns <- asNamespace("SwitchEconometrics")

tol <- list(ll = 1e-4, ll_worse = 1e-6, est = 1e-3, se = 0.01, ts = 1e-6,
            ts_se = 1e-4)
rows <- list()
## status: "within" / "outside" (a toleranced comparison), "documented" (a
## difference with an established cause, BENCHMARK_PROTOCOL.md s.6.4) or
## "not run"
rec <- function(dataset, model, benchmark, quantity, value, limit, pass,
                note = "", status = NULL) {
  status <- status %||% if (is.na(pass)) "not run" else if (pass) "within"
                        else "outside"
  rows[[length(rows) + 1L]] <<- data.frame(
    dataset = dataset, model = model, benchmark = benchmark,
    quantity = quantity, value = value, limit = limit, pass = pass,
    status = status, note = note, stringsAsFactors = FALSE)
}
`%||%` <- function(a, b) if (is.null(a)) b else a
dest <- function(a, b) max(abs(a - b) / pmax(1, abs(b)))
our_ll <- function(fit, theta_nat) {
  sum(ns$loglik_joint(ns$se_par_working(fit$map, unname(theta_nat)), fit$data,
                      fit$map))
}

## ----------------------------------------------------------------- data
gen <- function(design, N, seed) {
  set.seed(seed)
  x1 <- rnorm(N); x2 <- rnorm(N); z1 <- rnorm(N); u <- rnorm(N)
  e <- 0.6 * u + 0.8 * rnorm(N)
  S <- as.integer(0.5 + 0.3 * x1 - 0.4 * z1 + u > 0)
  y <- switch(design,
    H = ifelse(S == 1, 1.5 + 0.8 * x1 + 0.4 * x2 + e, NA_real_),
    T = 1 + 0.5 * x1 + 0.2 * x2 + 0.5 * S + e,
    Th = 1 + 0.5 * x1 + 0.2 * x2 + S * (0.5 + 0.3 * x1) + e)
  data.frame(S, y, x1, x2, z1)
}
sets <- list()
k <- 0L
for (design in c("H", "T", "Th")) for (N in c(2000L, 10000L)) {
  k <- k + 1L
  id <- sprintf("%s_N%d", design, N)
  sets[[id]] <- list(design = design, data = gen(design, N, 20261123L + k))
  saveRDS(sets[[id]]$data, file.path(ddir, paste0(id, ".rds")))
}

## --------------------------------------------------------------- Heckman
bench_heckman <- function(id, d, sel, out) {
  f <- suppressWarnings(heckman(sel, out, data = d))
  s <- selection(sel, out, data = d, method = "ml")
  dl <- f$loglik - as.numeric(logLik(s))
  if (dl > tol$ll) {
    ## our multistart found a higher maximum than the benchmark (D-SS-2):
    ## recorded, and the comparison is made at the benchmark's maximum,
    ## which our fit from the two-step start alone must reproduce
    rec(id, "heckman FIML (3 starts)", "sampleSelection ML",
        "log-likelihood: ours minus theirs", dl, NA, NA,
        sprintf(paste0("D-SS-2: the likelihood has two local maxima; ours ",
                       "(rho = %.3f) is higher than the benchmark's (rho = %.3f)"),
                coef(f)[["outcome:rho"]], coef(s)[["rho"]]),
        status = "documented")
    dll <- our_ll(f, coef(s)) - as.numeric(logLik(s))
    rec(id, "heckman likelihood", "sampleSelection ML",
        "our log-likelihood at its estimates minus its value", abs(dll),
        tol$ll, abs(dll) <= tol$ll)
    f <- suppressWarnings(heckman(sel, out, data = d,
                                  control = switch_control(starts = 1L)))
    dl <- f$loglik - as.numeric(logLik(s))
    id <- paste(id, "(starts = 1)")
  }
  rec(id, "heckman FIML", "sampleSelection ML", "log-likelihood difference",
      abs(dl), tol$ll, abs(dl) <= tol$ll && dl >= -tol$ll_worse)
  rec(id, "heckman FIML", "sampleSelection ML", "estimates",
      dest(unname(coef(f)), as.numeric(coef(s))), tol$est,
      dest(unname(coef(f)), as.numeric(coef(s))) <= tol$est)
  r <- max(abs(sqrt(diag(vcov(f))) / sqrt(diag(vcov(s))) - 1))
  rec(id, "heckman FIML", "sampleSelection ML", "standard errors (relative)",
      r, tol$se, r <= tol$se)
  id <- sub(" \\(starts = 1\\)$", "", id)
  f2 <- heckman(sel, out, data = d, method = "two_step")
  s2 <- selection(sel, out, data = d, method = "2step")
  c2 <- coef(s2)
  v <- max(abs(unname(coef(f2)) - unname(c2[names(c2) != "invMillsRatio"])),
           abs(f2$two_step$theta - c2[["invMillsRatio"]]))
  rec(id, "heckman two-step", "sampleSelection 2step",
      "estimates incl. sigma, rho, Mills coefficient", v, tol$ts, v <= tol$ts)
  ## standard errors of the outcome coefficients and the Mills coefficient
  ko <- f2$two_step$index_psi$outcome
  se_o <- sqrt(diag(f2$two_step$vcov_psi))[ko]
  vs <- tryCatch(sqrt(diag(vcov(s2))), error = function(e) NULL)
  if (!is.null(vs)) {
    io <- s2$param$index$betaO; im <- s2$param$index$Mills
    r2 <- max(abs(se_o / vs[c(io, im)] - 1), na.rm = TRUE)
    rec(id, "heckman two-step", "sampleSelection 2step",
        "outcome standard errors, our default (relative)", r2, NA, NA,
        paste0("D-SS-3: we use the expected (Fisher) information of the ",
               "probit, sampleSelection the observed one"),
        status = "documented")
    ## the same formula with the observed probit information
    sdd <- f2$data
    Z <- sdd$Z; g <- coef(f2)[f2$map$index$gamma]; w <- drop(Z %*% g)
    q <- 2 * sdd$S - 1
    lam <- dnorm(q * w) / pnorm(q * w)
    Vobs <- solve(crossprod(Z * sqrt(lam * (lam + q * w))))
    sl <- sdd$S == 1L
    m <- dnorm(w[sl]) / pnorm(w[sl]); D <- m * (m + w[sl])
    W <- cbind(sdd$X$outcome[sl, , drop = FALSE], m)
    sg <- coef(f2)[["outcome:sigma"]]; rh <- coef(f2)[["outcome:rho"]]
    WWi <- solve(crossprod(W)); WDZ <- crossprod(W * D, Z[sl, , drop = FALSE])
    Vb <- sg^2 * WWi %*% (crossprod(W * (1 - rh^2 * D), W) +
                            rh^2 * WDZ %*% Vobs %*% t(WDZ)) %*% WWi
    r3 <- max(abs(sqrt(diag(Vb)) / vs[c(io, im)] - 1), na.rm = TRUE)
    rec(id, "heckman two-step", "sampleSelection 2step",
        "outcome standard errors, our formula with the observed probit information (relative)",
        r3, tol$ts_se, r3 <= tol$ts_se)
  }
}
for (id in c("H_N2000", "H_N10000")) {
  bench_heckman(id, sets[[id]]$data, S ~ x1 + z1, y ~ x1 + x2)
}
## the documented Tobit-2 example of sampleSelection (Mroz 1987 data)
data("Mroz87", package = "sampleSelection")
Mroz87$kids <- (Mroz87$kids5 + Mroz87$kids618 > 0)
saveRDS(Mroz87, file.path(ddir, "Mroz87.rds"))
bench_heckman("Mroz87", Mroz87,
              lfp ~ age + I(age^2) + faminc + kids + educ,
              wage ~ exper + I(exper^2) + educ + city)

## ------------------------------------------------------------- treatment
bench_treat <- function(id, d, hyb) {
  sh <- if (hyb) ~ x1 else ~ 1
  fo <- if (hyb) y ~ x1 + x2 + S + S:x1 else y ~ x1 + x2 + S
  f <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d, shift = sh)
  s <- treatReg(S ~ x1 + z1, fo, data = d, method = "ml")
  dl <- f$loglik - as.numeric(logLik(s))
  rec(id, "treatment FIML", "sampleSelection treatReg ML",
      "log-likelihood difference", abs(dl), tol$ll,
      abs(dl) <= tol$ll && dl >= -tol$ll_worse)
  v <- dest(unname(coef(f)), as.numeric(coef(s)))
  rec(id, "treatment FIML", "sampleSelection treatReg ML", "estimates", v,
      tol$est, v <= tol$est)
  r <- max(abs(sqrt(diag(vcov(f))) / sqrt(diag(vcov(s))) - 1))
  rec(id, "treatment FIML", "sampleSelection treatReg ML",
      "standard errors (relative)", r, tol$se, r <= tol$se)
  ## two-step: conventions recorded, not assumed
  f2 <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d, shift = sh,
                  method = "two_step")
  s2 <- tryCatch(treatReg(S ~ x1 + z1, fo, data = d, method = "2step"),
                 error = function(e) e)
  if (inherits(s2, "error")) {
    rec(id, "treatment two-step", "sampleSelection treatReg 2step",
        "not run", NA, NA, NA,
        paste0("treatReg(method = \"2step\") stops with the error '",
               conditionMessage(s2), "' in sampleSelection ",
               as.character(utils::packageVersion("sampleSelection"))))
  } else {
    c2 <- coef(s2)
    kb <- length(f2$map$index$gamma) +
      seq_len(length(coef(f2)) - length(f2$map$index$gamma) - 2L)
    cb <- c2[!names(c2) %in% c("invMillsRatio", "sigma", "rho")]
    v2 <- max(abs(unname(coef(f2))[seq_along(cb)] - unname(cb)))
    rec(id, "treatment two-step", "sampleSelection treatReg 2step",
        "selection, outcome and shift coefficients", v2, tol$ts, v2 <= tol$ts)
    vm <- abs(f2$two_step$theta - c2[["invMillsRatio"]])
    rec(id, "treatment two-step", "sampleSelection treatReg 2step",
        "coefficient of the correction term", vm, tol$ts, vm <= tol$ts)
    vsr <- max(abs(coef(f2)[c("outcome:sigma", "outcome:rho")] -
                     c2[c("sigma", "rho")]))
    rec(id, "treatment two-step", "sampleSelection treatReg 2step",
        "sigma and rho", vsr, tol$ts, vsr <= tol$ts,
        "a difference here is a difference of variance-recovery formulas")
  }
  ## endogenous::hybrid: reads its variables from the global environment
  for (v in names(d)) assign(paste0("bg_", v), d[[v]], envir = globalenv())
  run_hy <- function(init) {
    if (hyb) hybrid(bg_y ~ bg_x1 + bg_x2, bg_S ~ bg_x1 + bg_z1,
                    modifiers = ~ bg_x1, se = "M", init = init)
    else hybrid(bg_y ~ bg_x1 + bg_x2, bg_S ~ bg_x1 + bg_z1, se = "M",
                init = init)
  }
  hy_note <- ""
  hy <- tryCatch(run_hy(NULL), error = function(e) e)
  if (inherits(hy, "error")) {
    ## its default start (rho = cor(S, y)) can fail in optim(); restart it
    ## from our two-step estimates (not from our FIML estimates)
    hy_note <- paste0("its default start failed (", conditionMessage(hy),
                      "); restarted from our two-step estimates")
    c2s <- coef(f2)
    kd <- length(f2$map$index$delta)
    idl <- f2$map$index$delta
    init <- unname(c2s)
    init[idl] <- -init[idl]
    hy <- tryCatch(run_hy(init), error = function(e) e)
  }
  if (inherits(hy, "error")) {
    rec(id, "treatment FIML", "endogenous hybrid", "not run", NA, NA, NA,
        paste(hy_note, "; restart failed:", conditionMessage(hy)))
    return(invisible(NULL))
  }
  th_e <- c(hy$alpha, hy$beta, -hy$eta, hy$sigma, hy$rho)   # delta = -eta
  dl <- f$loglik - our_ll(f, th_e)
  rec(id, "treatment FIML", "endogenous hybrid",
      "log-likelihood at both estimates (our engine)", abs(dl), tol$ll,
      abs(dl) <= tol$ll && dl >= -tol$ll_worse)
  v <- dest(unname(coef(f)), th_e)
  rec(id, "treatment FIML", "endogenous hybrid", "estimates (delta = -eta)", v,
      tol$est, v <= tol$est, hy_note)
  r <- max(abs(sqrt(diag(vcov(f))) / sqrt(diag(hy$vcov)) - 1))
  rec(id, "treatment FIML", "endogenous hybrid",
      "standard errors, se = \"M\" (relative)", r, tol$se, r <= tol$se)
  ## effects: ours at both sets of estimates
  e1 <- switch_effects(f, effects = c("ATT", "ATU", "ATE"), se = "none")$table
  g <- f; g$coefficients[] <- th_e
  e2 <- switch_effects(g, effects = c("ATT", "ATU", "ATE"), se = "none")$table
  ve <- dest(e1$estimate, e2$estimate)
  rec(id, "treatment FIML", "endogenous hybrid",
      "ATT, ATU, ATE at both estimates", ve, tol$est, ve <= tol$est)
}
for (id in c("T_N2000", "T_N10000")) bench_treat(id, sets[[id]]$data, FALSE)
for (id in c("Th_N2000", "Th_N10000")) bench_treat(id, sets[[id]]$data, TRUE)

## --------------------------------------------------------------- Tobit-5
for (id in c("Th_N2000", "Th_N10000")) {
  d <- sets[[id]]$data
  d$y0 <- ifelse(d$S == 0, d$y, NA); d$y1 <- ifelse(d$S == 1, d$y, NA)
  f <- tobit5(S ~ x1 + z1, list(y0 ~ x1 + x2, y1 ~ x1 + x2), data = d)
  s <- selection(S ~ x1 + z1, list(y0 ~ x1 + x2, y1 ~ x1 + x2), data = d,
                 method = "ml")
  dl <- f$loglik - as.numeric(logLik(s))
  rec(id, "tobit5 FIML", "sampleSelection ML (Tobit-5)",
      "log-likelihood difference", abs(dl), tol$ll,
      abs(dl) <= tol$ll && dl >= -tol$ll_worse)
  v <- dest(unname(coef(f)), as.numeric(coef(s)))
  rec(id, "tobit5 FIML", "sampleSelection ML (Tobit-5)", "estimates", v,
      tol$est, v <= tol$est)
}

## ---------------------------------------------------------------- output
B <- do.call(rbind, rows)
utils::write.csv(B, file.path(odir, "benchmark_g2.csv"), row.names = FALSE)
ver <- function(p) as.character(utils::packageVersion(p))
done <- B[B$status %in% c("within", "outside"), ]
md <- c("# Benchmarks, Generation 2 (generated)", "",
        "Generated by `04_Validation/scripts/benchmark_g2.R`; do not edit.",
        "Protocol and tolerances: BENCHMARK_PROTOCOL.md sections 3 and 6.", "",
        sprintf("- SwitchEconometrics %s; sampleSelection %s; endogenous %s; %s",
                ver("SwitchEconometrics"), ver("sampleSelection"),
                ver("endogenous"), R.version.string),
        sprintf("- date: %s", format(Sys.time())), "",
        sprintf(paste0("Toleranced comparisons: **%d, within tolerance %d, ",
                       "outside %d**; documented differences: %d; not run: %d."),
                nrow(done), sum(done$pass), sum(!done$pass),
                sum(B$status == "documented"), sum(B$status == "not run")),
        "",
        "| Dataset | Model | Benchmark | Quantity | Largest difference | Tolerance | Within | Note |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
        sprintf("| %s | %s | %s | %s | %s | %s | %s | %s |", B$dataset, B$model,
                B$benchmark, B$quantity, formatC(B$value, format = "e", digits = 2),
                formatC(B$limit, format = "g"),
                ifelse(B$status == "within", "yes",
                       ifelse(B$status == "outside", "**no**", B$status)),
                B$note))
writeLines(md, file.path(odir, "BENCHMARK_G2_generated.md"), useBytes = TRUE)
cat(sprintf("comparisons: %d, within tolerance %d, outside %d\n", nrow(done),
            sum(done$pass), sum(!done$pass)))
cat(sprintf("documented differences: %d; not run: %d\n",
            sum(B$status == "documented"), sum(B$status == "not run")))
print(B[B$status != "within", c("dataset", "model", "quantity", "value",
                                "status")], row.names = FALSE)
