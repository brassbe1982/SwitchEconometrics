## Multinomial endogenous switching regression with multinomial-logit
## selection (version 1.2.0; MULTINOMIAL_ESR.md s.2-4; G2 acceptance tests
## G2-J8-1, G2-J8-2).

fo3 <- list(a = y ~ x1 + x2, b = y ~ x1 + x2, c = y ~ x1 + x2)
par3 <- c(0.2, 0.3, 0.8, -0.2,  -0.2, -0.3, 0.2, 0.8,
          1.0, 0.5, 0.2, 1, 0.5,  1.5, 0.8, 0.4, 1, 0.4,
          2.0, 0.3, -0.3, 1.2, -0.4)
sim_mnl_data <- function(n = 2500, seed = 4, potential = FALSE) {
  set.seed(seed)
  d <- data.frame(x1 = rnorm(n), x2 = rnorm(n), z1 = rnorm(n), z2 = rnorm(n),
                  g = factor(sample(c("u", "v"), n, replace = TRUE)),
                  cl = sample(1:50, n, replace = TRUE), w = runif(n, 0.5, 2))
  sp <- switch_model(regime ~ x1 + z1 + z2, fo3, model = "multinomial_esr")
  switch_simulate(sp, d, parameters = par3, seed = seed + 1L,
                  potential_outcomes = potential)
}
d3 <- sim_mnl_data()
f3 <- multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = d3)

test_that("first-step multinomial logit equals nnet::multinom", {
  skip_if_not_installed("nnet")
  sd <- f3$data
  ml <- est_mnl(sd$Z, sd$S, 3L, 1L)
  nn <- nnet::multinom(regime ~ x1 + z1 + z2, data = d3, trace = FALSE,
                       reltol = 1e-14, maxit = 1000)
  expect_equal(ml$gamma, as.vector(t(coef(nn))), tolerance = 1e-4)
  expect_equal(ml$loglik, as.numeric(logLik(nn)), tolerance = 1e-8)
  expect_true(ml$converged)
  expect_equal(rowSums(ml$P), rep(1, sd$n), tolerance = 1e-12)
  expect_lt(max(abs(colSums(ml$score_i))), 1e-6)
  expect_equal(sqrt(diag(ml$V)),
               as.vector(t(summary(nn)$standard.errors)), tolerance = 1e-3)
})

test_that("Lee likelihood: direct formula, analytic score and Hessian", {
  skip_if_not_installed("numDeriv")
  sd <- f3$data; map <- f3$map
  th <- f3$coef_working + seq(-0.08, 0.08, length.out = map$p)
  L <- lik_lee_mnl(th, sd, map, deriv = 2L)
  ## direct evaluation
  G <- rbind(0, matrix(th[1:8], 2, 4, byrow = TRUE))
  V <- cbind(1, d3$x1, d3$z1, d3$z2) %*% t(G)
  P <- exp(V) / rowSums(exp(V))
  ll <- numeric(nrow(d3))
  X <- cbind(1, d3$x1, d3$x2)
  for (j in 1:3) {
    s <- as.integer(d3$regime) == j
    b <- th[8 + (j - 1) * 5 + 1:3]
    sig <- exp(th[8 + (j - 1) * 5 + 4]); rho <- tanh(th[8 + (j - 1) * 5 + 5])
    e <- (d3$y[s] - X[s, ] %*% b) / sig
    ll[s] <- -log(sig) + dnorm(e, log = TRUE) +
      pnorm((qnorm(P[s, j]) + rho * e) / sqrt(1 - rho^2), log.p = TRUE)
  }
  expect_equal(L$ll_i, ll, tolerance = 1e-11)
  f <- function(t) sum(lik_lee_mnl(t, sd, map)$ll_i)
  expect_equal(unname(colSums(L$score_i)), numDeriv::grad(f, th),
               tolerance = 1e-6)
  expect_equal(unname(L$hessian), numDeriv::hessian(f, th), tolerance = 1e-5)
  w <- d3$w
  Lw <- lik_lee_mnl(th, sd, map, deriv = 2L, weights = w)
  fw <- function(t) sum(w * lik_lee_mnl(t, sd, map)$ll_i)
  expect_equal(unname(Lw$hessian), numDeriv::hessian(fw, th), tolerance = 1e-5)
  cmp <- loglik_observation(th, sd, map)
  expect_equal(cmp$loglik, ll, tolerance = 1e-11)
  expect_equal(cmp$log_prob_regime,
               log(P[cbind(seq_len(nrow(d3)), as.integer(d3$regime))]),
               tolerance = 1e-11)
})

test_that("FIML recovers the parameters and does not depend on the base", {
  expect_identical(f3$convergence$code, 0L)
  expect_lt(f3$convergence$gradient_max, 1e-6)
  z <- (coef(f3) - par3) / sqrt(diag(vcov(f3)))
  expect_lt(max(abs(z)), 4)
  expect_identical(f3$base, "a")
  fb <- multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = d3, base = "c")
  expect_equal(fb$loglik, f3$loglik, tolerance = 1e-8)
  expect_identical(names(coef(fb))[1], "selection[a]:(Intercept)")
  expect_equal(coef(fb)[grep("^[abc]:", names(coef(fb)))],
               coef(f3)[grep("^[abc]:", names(coef(f3)))], tolerance = 1e-5)
  expect_equal(switch_predict(fb, type = "probability"),
               switch_predict(f3, type = "probability"), tolerance = 1e-5)
  ## outcome list in another order, and unnamed (matched by position)
  fr <- multinomial_switch(regime ~ x1 + z1 + z2, fo3[c("c", "a", "b")],
                           data = d3)
  expect_equal(coef(fr), coef(f3), tolerance = 1e-8)
  expect_message(fu <- multinomial_switch(regime ~ x1 + z1 + z2, unname(fo3),
                                          data = d3),
                 class = "switch_message_regime_mapping")
  expect_equal(coef(fu), coef(f3), tolerance = 1e-8)
  lr <- switch_test(f3, "lr_independence")
  expect_identical(as.integer(lr$df), 3L)
  expect_identical(as.integer(switch_test(f3, "wald_independence")$df), 3L)
})

test_that("Lee two-step: regression on m1(qnorm(P)), variance recovery, covariances", {
  t2 <- multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = d3,
                           method = "two_step")
  P <- t2$two_step$P
  for (j in 1:3) {
    s <- as.integer(d3$regime) == j
    w <- qnorm(P[s, j]); m <- dnorm(w) / pnorm(w)
    ols <- lm(d3$y[s] ~ d3$x1[s] + d3$x2[s] + m)
    lab <- c("a", "b", "c")[j]
    expect_equal(unname(t2$two_step$psi[t2$two_step$index_psi[[lab]]]),
                 unname(coef(ols)), tolerance = 1e-8)
    s2 <- mean(residuals(ols)^2) + coef(ols)[["m"]]^2 * mean(m * (m + w))
    expect_equal(coef(t2)[[paste0(lab, ":sigma")]], sqrt(s2), tolerance = 1e-8)
    expect_equal(coef(t2)[[paste0(lab, ":rho")]], coef(ols)[["m"]] / sqrt(s2),
                 tolerance = 1e-8)
  }
  z <- (coef(t2) - coef(f3)) / sqrt(diag(vcov(f3)))
  expect_lt(max(abs(z)), 2)
  ## model-based and sandwich standard errors are close
  r <- sqrt(diag(t2$two_step$vcov_sandwich)) / sqrt(diag(t2$two_step$vcov_psi))
  expect_true(all(r > 0.85 & r < 1.15))
  t2c <- multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = d3,
                            method = "two_step", cluster = ~ cl)
  expect_identical(t2c$vcov_type, "cluster")
  expect_true(all(is.na(diag(vcov(t2))[c("a:sigma", "a:rho")])))
})

test_that("correction terms and their derivatives", {
  skip_if_not_installed("numDeriv")
  ## m(P) of BFG variant 2 against direct integration
  sp <- se_bfg_m_spline()
  for (p in c(0.02, 0.3, 0.7, 0.97)) {
    ref <- integrate(function(v) qnorm(-exp(-(v - log(p))), log.p = TRUE) *
                       exp(-v - exp(-v)), -6, 45, rel.tol = 1e-11)$value
    expect_equal(sp(log(p)), ref, tolerance = 1e-6)
  }
  expect_lt(abs(sp(0)), 1e-8)                 # m(1) = E[normal score] = 0
  sd <- f3$data
  g0 <- coef(f3)[1:8]
  Z <- sd$Z[1:40, ]
  Pfun <- function(g) exp(se_mnl_logP(Z, matrix(g, 2, 4, byrow = TRUE), 1L))
  P <- Pfun(g0)
  for (type in c("lee", "dmf", "bfg1", "bfg2")) {
    for (j in 1:3) {
      ct <- se_correction_terms(P, j, type)
      for (t in seq_len(ncol(ct$C))) {
        Jn <- numDeriv::jacobian(function(g)
          se_correction_terms(Pfun(g), j, type)$C[, t], g0)
        expect_equal(se_term_jacobian(ct$dC[[t]], P, Z, 2:3), Jn,
                     tolerance = 1e-5, ignore_attr = TRUE,
                     info = paste(type, j, t))
      }
    }
  }
  ## Dubin-McFadden terms (MULTINOMIAL_ESR.md s.4.1)
  ct <- se_correction_terms(P, 2L, "dmf")
  expect_equal(ct$C[, 1], P[, 1] * log(P[, 1]) / (1 - P[, 1]) + log(P[, 2]),
               tolerance = 1e-12)
  b1 <- se_correction_terms(P, 2L, "bfg1")$C
  expect_equal(b1[, 2], -log(P[, 2]), tolerance = 1e-12)
  expect_equal(b1[, 3], P[, 3] * log(P[, 3]) / (1 - P[, 3]), tolerance = 1e-12)
})

test_that("Dubin-McFadden and BFG two-step fits", {
  ctl <- switch_control(bootstrap_R = 40)
  for (cr in c("dmf", "bfg1", "bfg2")) {
    t2 <- multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = d3,
                             method = "two_step", correction = cr,
                             control = ctl)
    nth <- if (cr == "dmf") 2L else 3L
    expect_identical(sum(grepl("theta\\[", names(coef(t2)))), 3L * nth)
    expect_false(any(grepl("sigma|rho", names(coef(t2)))))
    expect_false(anyNA(vcov(t2)))
    expect_identical(t2$two_step$bootstrap$R, 40L)
    ## the slopes agree with the FIML slopes within sampling error
    sl <- grep("^[abc]:x", names(coef(t2)), value = TRUE)
    expect_lt(max(abs((coef(t2)[sl] - coef(f3)[sl]) /
                        sqrt(diag(vcov(f3))[sl]))), 3)
    e <- switch_effects(t2, effects = "ATT", pairs = c("b", "a"))
    expect_identical(e$table$assumption, "")
    expect_true(is.finite(e$table$std_error))
    expect_output(print(summary(t2)), "Moment model")
    expect_error(residuals(t2, "pearson"), class = "switch_error_unsupported")
    expect_error(simulate(t2), class = "switch_error_unsupported")
  }
  ## the bootstrap is reproducible and the sandwich is available
  a <- multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = d3,
                          method = "two_step", correction = "dmf",
                          control = ctl)
  b <- multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = d3,
                          method = "two_step", correction = "dmf",
                          control = ctl)
  expect_identical(vcov(a), vcov(b))
  s <- multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = d3,
                          method = "two_step", correction = "dmf",
                          vcov = "sandwich")
  expect_null(s$two_step$bootstrap)
  expect_equal(unname(vcov(s)), unname(a$two_step$vcov_sandwich),
               tolerance = 1e-10)
  expect_error(multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = d3,
                                  correction = "dmf"),
               class = "switch_error_unsupported")
})

test_that("pairwise effects follow their definitions", {
  skip_if_not_installed("numDeriv")
  e <- switch_effects(f3)
  tb <- e$table
  expect_identical(nrow(tb), 12L)
  th <- coef(f3)
  X <- cbind(1, d3$x1, d3$x2)
  xb <- sapply(c("a", "b", "c"), function(l) X %*% th[paste0(l, c(":(Intercept)",
                                                             ":x1", ":x2"))])
  P <- switch_predict(f3, type = "probability")
  w <- qnorm(P)
  tt <- sapply(c("a", "b", "c"), function(l) th[[paste0(l, ":sigma")]] *
                 th[[paste0(l, ":rho")]])
  m1 <- dnorm(w) / pnorm(w); m0 <- -dnorm(w) / pnorm(-w)
  S <- as.integer(d3$regime)
  get <- function(eff, r, a) tb$estimate[tb$effect == eff & tb$regime == r &
                                         tb$against == a]
  expect_equal(get("ATE", "b", "a"), mean(xb[, 2] - xb[, 1]), tolerance = 1e-10)
  sb <- S == 2; sa <- S == 1
  att <- mean((xb[sb, 2] + tt[2] * m1[sb, 2]) - (xb[sb, 1] + tt[1] * m0[sb, 1]))
  atu <- mean((xb[sa, 2] + tt[2] * m0[sa, 2]) - (xb[sa, 1] + tt[1] * m1[sa, 1]))
  expect_equal(get("ATT", "b", "a"), att, tolerance = 1e-10)
  expect_equal(get("ATU", "b", "a"), atu, tolerance = 1e-10)
  expect_equal(get("TH", "b", "a"), att - atu, tolerance = 1e-10)
  ## ATE_ca = ATE_cb + ATE_ba exactly
  expect_equal(get("ATE", "c", "a"), get("ATE", "c", "b") + get("ATE", "b", "a"),
               tolerance = 1e-12)
  ## delta-method standard error against an independent numerical gradient
  fa <- function(t) {
    o <- f3; o$coefficients[] <- t
    switch_effects(o, effects = "ATT", pairs = c("b", "a"), se = "none")$table$estimate
  }
  g <- numDeriv::grad(fa, coef(f3))
  expect_equal(tb$std_error[tb$effect == "ATT" & tb$regime == "b"],
               sqrt(drop(g %*% vcov(f3) %*% g)), tolerance = 1e-5)
  ## the J x J table: diagonal equals the mean fitted outcome by regime
  expect_equal(unname(diag(e$means$all)),
               as.numeric(tapply(fitted(f3), d3$regime, mean)), tolerance = 1e-10)
  ## TE given a third regime; under L-CI and the logit it equals ATU-type means
  eg <- switch_effects(f3, effects = "ATE", pairs = list(c("b", "a")),
                       given = "c")$table
  sc <- S == 3
  expect_equal(eg$estimate[eg$effect == "TE"],
               mean((xb[sc, 2] + tt[2] * m0[sc, 2]) -
                      (xb[sc, 1] + tt[1] * m0[sc, 1])), tolerance = 1e-10)
  expect_identical(eg$given[eg$effect == "TE"], "c")
  expect_identical(unique(tb$assumption[tb$effect != "ATE"]), "L-CI")
  expect_identical(nrow(switch_effects(f3, effects = "ATT", by = ~ g,
                                       data = d3)$table), 6L)
  expect_output(print(e), "assumption L-CI")
  expect_error(switch_effects(f3, pairs = list(c("a", "zz"))),
               class = "switch_error_argument")
  expect_error(switch_effects(f3, se = "bootstrap"),
               class = "switch_error_unsupported")
})

test_that("effects at the true parameters match simulated potential outcomes", {
  ## G2 acceptance criterion 5(c): within 4 Monte Carlo standard errors
  big <- sim_mnl_data(60000, seed = 21, potential = TRUE)
  t2 <- multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = big,
                           method = "two_step")
  o <- t2
  psi <- o$two_step$psi
  psi[] <- c(par3[1:8], par3[9:11], par3[12] * par3[13], par3[14:16],
             par3[17] * par3[18], par3[19:21], par3[22] * par3[23])
  o$two_step$psi <- psi
  tb <- switch_effects(o, se = "none")$table
  po <- as.matrix(big[, paste0(".potential_", c("a", "b", "c"))])
  S <- as.integer(big$regime)
  zmax <- 0
  for (i in seq_len(nrow(tb))) {
    if (tb$effect[i] == "TH") next
    j <- match(tb$regime[i], c("a", "b", "c"))
    k <- match(tb$against[i], c("a", "b", "c"))
    dd <- po[, j] - po[, k]
    s <- switch(tb$effect[i], ATE = rep(TRUE, nrow(big)), ATT = S == j,
                ATU = S == k)
    zmax <- max(zmax, abs(mean(dd[s]) - tb$estimate[i]) /
                  (sd(dd[s]) / sqrt(sum(s))))
  }
  expect_lt(zmax, 4)
})

test_that("predictions of the multinomial model", {
  p <- switch_predict(f3, type = "probability")
  expect_identical(colnames(p), c("a", "b", "c"))
  expect_equal(rowSums(p), rep(1, nrow(d3)), tolerance = 1e-12)
  cm <- switch_predict(f3, type = "conditional")
  expect_identical(dim(cm), c(nrow(d3), 9L))
  ## L-CI with the logit: the counterfactual mean is the same for both
  ## other regimes
  expect_equal(cm[, "EY[a]_S[b]"], cm[, "EY[a]_S[c]"], tolerance = 1e-12)
  S <- as.integer(d3$regime)
  own <- cm[cbind(seq_len(nrow(d3)), (S - 1L) * 3L + S)]
  expect_equal(fitted(f3), own, tolerance = 1e-12)
  un <- switch_predict(f3, type = "unconditional")
  expect_equal(un, rowSums(p * cm[, c(1, 5, 9)]), tolerance = 1e-12)
  nd <- d3[1:6, ]
  pn <- switch_predict(f3, newdata = nd, type = "conditional", se = TRUE)
  expect_equal(pn$fit, cm[1:6, ], tolerance = 1e-10)
  expect_true(all(pn$se.fit > 0))
  expect_equal(switch_predict(f3, newdata = nd, type = "observed"), own[1:6],
               tolerance = 1e-10)
  nd$x1[2] <- NA
  expect_true(is.na(switch_predict(f3, newdata = nd, type = "linear")[2, 1]))
  expect_identical(dim(switch_predict(f3, type = "selection_index")),
                   c(nrow(d3), 2L))
  expect_length(residuals(f3, "pearson"), nrow(d3))
})

test_that("eight and ten regimes work without changes (G2-J8-1, G2-J8-2)", {
  skip_on_cran()
  mk <- function(J, n, seed) {
    set.seed(seed)
    labs <- paste0("r", seq_len(J))
    d <- data.frame(x1 = rnorm(n), z1 = rnorm(n), z2 = rnorm(n))
    fo <- stats::setNames(rep(list(y ~ x1), J), labs)
    sp <- switch_model(regime ~ x1 + z1 + z2, fo, model = "multinomial_esr")
    g <- as.vector(t(cbind(runif(J - 1, -0.2, 0.2), runif(J - 1, -0.4, 0.4),
                           runif(J - 1, -0.9, 0.9), runif(J - 1, -0.9, 0.9))))
    rho <- rep(c(0.5, -0.4, 0.3, -0.3), length.out = J)
    par <- c(g, unlist(lapply(seq_len(J), function(j)
      c(1 + 0.25 * (j - 1), 0.5, 1, rho[j]))))
    list(data = switch_simulate(sp, d, parameters = par, seed = seed + 1L),
         fo = fo, par = par)
  }
  s8 <- mk(8L, 6000L, 31)
  f8 <- multinomial_switch(regime ~ x1 + z1 + z2, s8$fo, data = s8$data,
                           control = switch_control(starts = 1))
  expect_identical(f8$convergence$code, 0L)
  expect_identical(length(coef(f8)), 7L * 4L + 8L * 4L)
  expect_lt(max(abs((coef(f8) - s8$par) / sqrt(diag(vcov(f8))))), 4.5)
  e8 <- switch_effects(f8, effects = c("ATE", "ATT"))
  expect_identical(nrow(e8$table), 2L * 28L)
  expect_identical(dim(e8$means$all), c(8L, 8L))
  expect_identical(dim(switch_predict(f8, type = "conditional")),
                   c(6000L, 64L))
  expect_output(print(summary(f8)), "alternative 'r8' against 'r1'")
  expect_s3_class(switch_validate(f8), "switch_validation")
  t8 <- multinomial_switch(regime ~ x1 + z1 + z2, s8$fo, data = s8$data,
                           method = "two_step", correction = "bfg1",
                           vcov = "sandwich")
  expect_identical(sum(grepl("theta\\[", names(coef(t8)))), 64L)
  s10 <- mk(10L, 8000L, 41)
  f10 <- multinomial_switch(regime ~ x1 + z1 + z2, s10$fo, data = s10$data,
                            control = switch_control(starts = 1))
  expect_identical(f10$convergence$code, 0L)
  expect_identical(length(f10$regimes), 10L)
})

test_that("inference helpers, simulation and refusals for multinomial fits", {
  v <- switch_validate(f3)
  expect_true(all(c("I1", "I4", "I4b", "I5", "I6", "I11") %in% v$table$code))
  sp <- switch_model(regime ~ x1, fo3, model = "multinomial_esr")
  v0 <- switch_validate(sp, d3)
  expect_true(all(v0$table$status[v0$table$code == "I4"] == "warning"))
  expect_output(print(sp), "3 regimes")
  expect_output(print(f3), "Multinomial endogenous switching regression")
  expect_s3_class(switch_diagnostics(f3), "switch_diagnostics")
  expect_s3_class(switch_compare(f3), "switch_comparison")
  b <- switch_bootstrap(f3, R = 5, seed = 3)
  expect_identical(b$successful, 5L)
  bp <- switch_bootstrap(f3, R = 4, seed = 3, type = "parametric")
  expect_identical(bp$successful, 4L)
  s <- simulate(f3, nsim = 2, seed = 9)
  expect_identical(dim(s), c(nrow(d3), 4L))
  expect_identical(levels(s$S_1), c("a", "b", "c"))
  w <- switch_test(f3, "wald", hypothesis = "a:rho = b:rho")
  expect_identical(as.integer(w$df), 1L)
  expect_identical(names(coef(f3, part = "selection[b]")),
                   paste0("selection[b]:", c("(Intercept)", "x1", "z1", "z2")))
  expect_error(switch_counterfactual(f3), class = "switch_error_unsupported")
  expect_error(multinomial_switch(regime ~ x1 + z1, fo3[1:2], data = d3),
               class = "switch_error_data")
  expect_error(multinomial_switch(regime ~ x1 + z1,
                                  list(a = y ~ x1, b = y ~ x1, zz = y ~ x1),
                                  data = d3), class = "switch_error_data")
  expect_error(multinomial_switch(regime ~ x1 + z1, fo3, data = d3,
                                  base = "q"), class = "switch_error_argument")
  expect_error(multinomial_switch(regime ~ x1 + z1, fo3, data = d3,
                                  correction = "heckman"),
               class = "switch_error_argument")
  expect_error(switch_fit(regime ~ x1 + z1, fo3, data = d3,
                          model = "multinomial_esr", method = "two_step",
                          dependence_structure = "normal_scores"),
               class = "switch_error_argument")
  expect_error(switch_fit(S ~ x1, list(y ~ x1, y ~ x1), data = d3,
                          base = "a"), class = "switch_error_argument")
  fw <- multinomial_switch(regime ~ x1 + z1 + z2, fo3, data = d3,
                           weights = ~ w)
  expect_identical(fw$vcov_type, "sandwich")
})
