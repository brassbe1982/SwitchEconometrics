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
## Delivered in WP2.2 (decided before the run):
##   multinomial logit first step against mlogit::mlogit() and
##                nnet::multinom() (3 and 8 regimes)
##   multinomial_switch(method = "two_step", correction = "bfg1") against
##                switchSelection::msel(type3 = "logit", estimator = "2step"),
##                whose selectivity terms are those of "bfg1" (its help
##                page; convention confirmed on simulated data)
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

## ---------------------------------------- multinomial logit selection
## Data: design L of MONTE_CARLO_DESIGN.md s.8.2 (3 regimes) and the
## selection part of design L8 (8 regimes), generated here with base R.
gen_multi <- function(J, N, seed) {
  set.seed(seed)
  x1 <- rnorm(N); x2 <- rnorm(N); z1 <- rnorm(N); z2 <- rnorm(N)
  if (J == 3L) {
    G <- rbind(c(0.2, 0.3, 0.8, -0.2), c(-0.2, -0.3, 0.2, 0.8))
    B <- rbind(c(1.0, 0.5, 0.2), c(1.5, 0.8, 0.4), c(2.0, 0.3, -0.3))
    sig <- c(1, 1, 1.2); rho <- c(0.5, 0.4, -0.4)
  } else {
    G <- rbind(c(0.2, 0.3, 0.8, -0.2), c(-0.2, -0.3, 0.2, 0.8),
               c(0.1, 0.2, -0.6, 0.4), c(0, -0.2, 0.5, 0.5),
               c(-0.1, 0.4, -0.4, -0.6), c(0.1, -0.1, 0.9, 0.3),
               c(-0.1, 0.1, -0.3, 0.9))
    B <- cbind(1 + 0.25 * (0:7), 0.5, 0.2)
    sig <- rep(1, 8); rho <- c(0.5, 0.4, -0.4, 0.3, -0.3, 0.5, 0.2, -0.5)
  }
  V <- cbind(0, cbind(1, x1, z1, z2) %*% t(G))
  gum <- -log(-log(matrix(runif(N * J), N, J)))
  Ut <- V + gum
  S <- integer(N); best <- rep(-Inf, N)
  for (k in seq_len(J)) { b <- Ut[, k] > best; S[b] <- k; best[b] <- Ut[b, k] }
  xb <- cbind(1, x1, x2) %*% t(B)
  y <- numeric(N)
  for (j in seq_len(J)) {
    es <- apply(Ut[, -j, drop = FALSE], 1L, max) - gum[, j]
    lF <- es - log(exp(es) + rowSums(exp(V[, -j, drop = FALSE])))
    yj <- xb[, j] + sig[j] * (rho[j] * (-qnorm(lF, log.p = TRUE)) +
                                sqrt(1 - rho[j]^2) * rnorm(N))
    y[S == j] <- yj[S == j]
  }
  labs <- paste0("r", seq_len(J))
  data.frame(regime = factor(labs[S], levels = labs), y, x1, x2, z1, z2)
}
msets <- list(L_N2000 = gen_multi(3L, 2000L, 20261201L),
              L_N10000 = gen_multi(3L, 10000L, 20261202L),
              L8_N8000 = gen_multi(8L, 8000L, 20261203L))
for (id in names(msets)) saveRDS(msets[[id]], file.path(ddir, paste0(id, ".rds")))
have <- function(p) requireNamespace(p, quietly = TRUE)

for (id in names(msets)) {
  d <- msets[[id]]
  labs <- levels(d$regime); J <- length(labs)
  fo <- stats::setNames(rep(list(y ~ x1 + x2), J), labs)
  f <- multinomial_switch(regime ~ x1 + z1 + z2, fo, data = d,
                          method = "two_step", correction = "bfg1",
                          vcov = "sandwich")
  ts <- f$two_step
  g <- ts$probit$gamma
  names(g) <- names(ts$psi)[ts$index_psi$gamma]
  seg <- sqrt(diag(ts$Vg))
  ## ---- first step against mlogit
  if (have("mlogit") && have("dfidx")) {
    dd <- dfidx::dfidx(d[, c("regime", "x1", "z1", "z2")], choice = "regime",
                       shape = "wide")
    ml <- mlogit::mlogit(regime ~ 0 | x1 + z1 + z2, data = dd,
                         reflevel = labs[1])
    cm <- stats::coef(ml)
    nm <- unlist(lapply(labs[-1], function(a) sprintf(
      "%s:%s", c("(Intercept)", "x1", "z1", "z2"), a)))
    stopifnot(all(nm %in% names(cm)))
    dl <- ts$probit$loglik - as.numeric(stats::logLik(ml))
    rec(id, "multinomial logit (first step)", "mlogit",
        "log-likelihood difference", abs(dl), tol$ll,
        abs(dl) <= tol$ll && dl >= -tol$ll_worse)
    v <- dest(unname(g), unname(cm[nm]))
    rec(id, "multinomial logit (first step)", "mlogit", "estimates", v,
        tol$est, v <= tol$est)
    sm <- sqrt(diag(stats::vcov(ml)))[nm]
    v <- max(abs(seg / sm - 1))
    rec(id, "multinomial logit (first step)", "mlogit",
        "standard errors (relative)", v, tol$se, v <= tol$se)
  } else {
    rec(id, "multinomial logit (first step)", "mlogit", "all", NA, NA, NA,
        "mlogit or dfidx not installed")
  }
  if (have("nnet")) {
    nn <- nnet::multinom(regime ~ x1 + z1 + z2, data = d, trace = FALSE,
                         reltol = 1e-14, maxit = 2000)
    dl <- ts$probit$loglik - as.numeric(stats::logLik(nn))
    rec(id, "multinomial logit (first step)", "nnet::multinom",
        "log-likelihood difference", abs(dl), tol$ll,
        abs(dl) <= tol$ll && dl >= -tol$ll_worse)
  }
  if (J != 3L) next
  ## ---- "bfg1" two-step against msel
  if (!have("switchSelection")) {
    rec(id, "two-step \"bfg1\"", "switchSelection::msel 2step", "all", NA, NA,
        NA, "switchSelection not installed")
    next
  }
  d$zz <- as.integer(d$regime) - 1L
  m <- switchSelection::msel(
    formula3 = zz ~ x1 + z1 + z2, formula2 = y ~ x1 + x2, data = d,
    groups3 = 0:2, groups2 = matrix(0:2, ncol = 1), estimator = "2step",
    type3 = "logit")
  bench <- "switchSelection::msel 2step (logit)"
  ## msel: outcome coefficients by regime (3 x 6: beta, then the three
  ## selectivity terms); selection coefficients relative to the LAST
  ## alternative
  i2 <- m$ind$coef2[[1]]
  est_m <- as.vector(t(matrix(m$par[i2], 3)))
  se_m <- as.vector(t(matrix(m$se[i2], 3)))
  io <- unlist(ts$index_psi[labs])
  Gm <- matrix(g, 2, 4, byrow = TRUE)
  g_m <- matrix(m$par[m$ind$coef3], 2)
  ## the second step recomputed at msel's first-step estimates, and the
  ## multinomial-logit score at both first-step estimates
  sdd <- f$data
  second <- function(G) {
    P <- exp(ns$se_mnl_logP(sdd$Z, G, sdd$base))
    sc <- unlist(lapply(1:2, function(k) colSums(((sdd$S == k + 1) -
                                                    P[, k + 1]) * sdd$Z)))
    b <- unlist(lapply(1:3, function(j) {
      sel <- sdd$S == j
      W <- cbind(sdd$X[[j]][sel, ], ns$se_correction_terms(
        P[sel, , drop = FALSE], j, "bfg1")$C)
      stats::lm.fit(W, sdd$y[sel])$coefficients
    }))
    list(b = unname(b), score = max(abs(sc)))
  }
  at_ours <- second(Gm)
  at_msel <- second(rbind(g_m[2, ] - g_m[1, ], -g_m[1, ]))
  v <- dest(unname(ts$psi[io]), est_m)
  v2 <- dest(at_msel$b, est_m)
  if (v <= tol$ts) {
    rec(id, "two-step \"bfg1\"", bench,
        "outcome and correction coefficients", v, tol$ts, TRUE)
  } else {
    rec(id, "two-step \"bfg1\"", bench,
        "outcome and correction coefficients", v, tol$ts, FALSE,
        sprintf(paste0("D-MS-2: outside the tolerance. Largest multinomial-",
                       "logit score at msel's first-step estimates %.1e, at ",
                       "ours %.1e"), at_msel$score, at_ours$score),
        status = if (v2 <= tol$ts) "documented" else "outside")
  }
  rec(id, "two-step \"bfg1\"", bench,
      "outcome and correction coefficients, our second step at msel's first-step estimates",
      v2, tol$ts, v2 <= tol$ts)
  v <- dest(c(-Gm[2, ], Gm[1, ] - Gm[2, ]), c(g_m[1, ], g_m[2, ]))
  rec(id, "two-step \"bfg1\"", bench,
      "selection coefficients (after change of base)", v, tol$est, v <= tol$est)
  se_o <- sqrt(diag(ts$vcov_sandwich))[io]
  v <- max(abs(se_o / se_m - 1))
  rec(id, "two-step \"bfg1\"", bench,
      "standard errors, our stacked sandwich (relative)", v, NA, NA,
      paste0("D-MS-1: msel differentiates the sample moments; our sandwich ",
             "uses the expected derivative of the second-step moments with ",
             "respect to the selection coefficients"),
      status = "documented")
  ## the same sandwich with the Jacobian of the sample moments
  psi <- ts$psi; idx <- ts$index_psi; sd <- f$data
  mom_i <- function(pv) {
    lP <- ns$se_mnl_logP(sd$Z, matrix(pv[idx$gamma], 2, 4, byrow = TRUE),
                         sd$base)
    P <- exp(lP)
    M <- matrix(0, sd$n, length(pv))
    for (k in 1:2) M[, (k - 1) * 4 + 1:4] <- ((sd$S == k + 1) - P[, k + 1]) * sd$Z
    for (j in 1:3) {
      sel <- sd$S == j
      W <- cbind(sd$X[[j]][sel, ], ns$se_correction_terms(
        P[sel, , drop = FALSE], j, "bfg1")$C)
      M[sel, idx[[labs[j]]]] <- drop(sd$y[sel] - W %*% pv[idx[[labs[j]]]]) * W
    }
    M
  }
  M0 <- mom_i(psi)
  A <- numDeriv::jacobian(function(pv) colSums(mom_i(pv)), psi)
  Ai <- solve(A)
  se_s <- sqrt(diag(Ai %*% crossprod(M0) %*% t(Ai)))[io]
  v <- max(abs(se_s / se_m - 1))
  rec(id, "two-step \"bfg1\"", bench,
      "standard errors, sandwich with the sample Jacobian (relative)", v,
      tol$ts_se, v <= tol$ts_se)
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
        sprintf("- %s", paste(vapply(c("switchSelection", "mlogit", "nnet"),
                                     function(p) paste(p, if (have(p)) ver(p)
                                                       else "not installed"),
                                     ""), collapse = "; ")),
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
