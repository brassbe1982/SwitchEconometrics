## Heckman sample selection, endogenous treatment and Tobit-5 (version 1.1.0;
## OBSERVATION_MECHANISMS.md; G2 acceptance criteria 2 and 3).

sim_obs_data <- function(n = 1500, seed = 3, rho = 0.6) {
  set.seed(seed)
  d <- data.frame(x1 = rnorm(n), x2 = rnorm(n), z1 = rnorm(n))
  u <- rnorm(n)
  e <- rho * u + sqrt(1 - rho^2) * rnorm(n)
  d$S <- as.integer(0.5 + 0.3 * d$x1 - 0.8 * d$z1 + u > 0)
  d$wage <- ifelse(d$S == 1, 1.5 + 0.8 * d$x1 + 0.4 * d$x2 + e, NA)
  d$y <- 1 + 0.5 * d$x1 + 0.2 * d$x2 + d$S * (0.5 + 0.3 * d$x1) + 1.2 * e
  d$g <- factor(sample(c("a", "b", "c"), n, replace = TRUE))
  d$cl <- sample(1:40, n, replace = TRUE)
  d$w <- runif(n, 0.5, 2)
  d
}
d <- sim_obs_data()
h <- heckman(S ~ x1 + z1, wage ~ x1 + x2, data = d)
tr <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d, shift = ~ x1)

test_that("Heckman: analytic score and Hessian equal numerical derivatives", {
  skip_if_not_installed("numDeriv")
  th <- h$coef_working + c(0.1, -0.05, 0.08, 0.1, -0.1, 0.05, 0.15, -0.2)
  f <- function(t) sum(lik_heckman_gaussian(t, h$data, h$map)$ll_i)
  L <- lik_heckman_gaussian(th, h$data, h$map, deriv = 2L)
  expect_equal(unname(colSums(L$score_i)), numDeriv::grad(f, th),
               tolerance = 1e-7)
  expect_equal(unname(L$hessian), numDeriv::hessian(f, th), tolerance = 1e-6)
  w <- d$w
  Lw <- lik_heckman_gaussian(th, h$data, h$map, deriv = 2L, weights = w)
  fw <- function(t) sum(w * lik_heckman_gaussian(t, h$data, h$map)$ll_i)
  expect_equal(unname(Lw$hessian), numDeriv::hessian(fw, th), tolerance = 1e-6)
})

test_that("Heckman likelihood is the ESR likelihood without the regime-0 density", {
  ## nesting identity (OBSERVATION_MECHANISMS.md s.2.5) against the G1 engine
  d2 <- d
  d2$y2 <- ifelse(d2$S == 1, d2$wage, d2$x2 + 0.3)        # any regime-0 outcome
  sp <- switch_model(S ~ x1 + z1, list(y2 ~ x1, y2 ~ x1 + x2))
  sd <- se_build_data(sp, d2)
  map <- se_parmap_esr(sd)
  th <- h$coef_working
  b0 <- c(0.2, -0.4); s0 <- 0.7
  the <- c(th[1:3], b0, log(s0), 0, th[4:8])
  ll_esr <- lik_esr_gaussian(the, sd, map)$ll_i
  ll_h <- lik_heckman_gaussian(th, h$data, h$map)$ll_i
  r0 <- sd$S == 0L
  dens0 <- dnorm(sd$y[r0], drop(sd$X[[1]][r0, ] %*% b0), s0, log = TRUE)
  expect_equal(ll_h[!r0], ll_esr[!r0], tolerance = 1e-12)
  expect_equal(ll_h[r0], ll_esr[r0] - dens0, tolerance = 1e-12)
})

test_that("Heckman FIML and two-step equal sampleSelection's Tobit-2", {
  skip_if_not_installed("sampleSelection")
  ss <- sampleSelection::selection(S ~ x1 + z1, wage ~ x1 + x2, data = d,
                                   method = "ml")
  expect_equal(h$loglik, as.numeric(logLik(ss)), tolerance = 1e-10)
  expect_equal(unname(coef(h)), as.numeric(coef(ss)), tolerance = 1e-6)
  expect_equal(unname(sqrt(diag(vcov(h)))), as.numeric(sqrt(diag(vcov(ss)))),
               tolerance = 1e-5)
  h2 <- heckman(S ~ x1 + z1, wage ~ x1 + x2, data = d, method = "two_step")
  s2 <- coef(sampleSelection::selection(S ~ x1 + z1, wage ~ x1 + x2, data = d,
                                        method = "2step"))
  expect_equal(unname(coef(h2)),
               unname(s2[names(s2) != "invMillsRatio"]), tolerance = 1e-6)
  expect_equal(unname(h2$two_step$theta), unname(s2[["invMillsRatio"]]),
               tolerance = 1e-6)
})

test_that("Heckman two-step is the regime-1 part of the ESR two-step", {
  d2 <- d
  d2$y2 <- ifelse(d2$S == 1, d2$wage, d2$x2 + rnorm(nrow(d2)))
  e2 <- switch_fit(S ~ x1 + z1, list(y2 ~ x1, y2 ~ x1 + x2), data = d2,
                   method = "two_step")
  for (v in c("hessian", "sandwich")) {
    h2 <- heckman(S ~ x1 + z1, wage ~ x1 + x2, data = d, method = "two_step",
                  vcov = v)
    e2 <- switch_fit(S ~ x1 + z1, list(y2 ~ x1, y2 ~ x1 + x2), data = d2,
                     method = "two_step", vcov = v)
    i1 <- c(e2$two_step$index_psi$gamma, e2$two_step$index_psi$regime_1)
    expect_equal(unname(h2$two_step$psi), unname(e2$two_step$psi[i1]),
                 tolerance = 1e-10)
    expect_equal(unname(h2$two_step$vcov_psi),
                 unname(e2$two_step$vcov_psi[i1, i1]), tolerance = 1e-9)
  }
  expect_equal(unname(coef(h2)[c("outcome:sigma", "outcome:rho")]),
               unname(coef(e2)[c("regime_1:sigma", "regime_1:rho")]),
               tolerance = 1e-10)
})

test_that("Heckman accepts missing outcome regressors for unobserved units", {
  d2 <- d
  d2$x2[d2$S == 0] <- NA
  expect_no_message(h3 <- heckman(S ~ x1 + z1, wage ~ x1 + x2, data = d2))
  expect_equal(coef(h3), coef(h), tolerance = 1e-10)
  expect_identical(nobs(h3), nrow(d))
  p <- switch_predict(h3, type = "conditional")
  expect_true(all(is.na(p[d2$S == 0, ])) && !anyNA(p[d2$S == 1, ]))
  d2$wage[which(d2$S == 1)[1:3]] <- NA
  expect_message(h4 <- heckman(S ~ x1 + z1, wage ~ x1 + x2, data = d2),
                 class = "switch_message_missing")
  expect_identical(nobs(h4), nrow(d) - 3L)
})

test_that("Heckman predictions follow the formulas; effects are refused", {
  th <- coef(h)
  w <- drop(cbind(1, d$x1, d$z1) %*% th[1:3])
  xb <- drop(cbind(1, d$x1, d$x2) %*% th[4:6])
  tt <- th[["outcome:sigma"]] * th[["outcome:rho"]]
  p <- switch_predict(h, type = "conditional")
  expect_equal(p[, "EY_S1"], xb + tt * dnorm(w) / pnorm(w), tolerance = 1e-10)
  expect_equal(p[, "EY_S0"], xb - tt * dnorm(w) / pnorm(-w), tolerance = 1e-10)
  expect_equal(switch_predict(h, type = "probability"), pnorm(w),
               tolerance = 1e-12)
  expect_equal(switch_predict(h, type = "unconditional"), xb, tolerance = 1e-12)
  nd <- d[1:5, ]
  pn <- switch_predict(h, newdata = nd, type = "conditional", se = TRUE)
  expect_equal(pn$fit, p[1:5, ], tolerance = 1e-10)
  expect_true(all(pn$se.fit > 0))
  ## delta-method standard error against a numerical gradient
  skip_if_not_installed("numDeriv")
  f <- function(t) {
    o <- h; o$coefficients[] <- t
    switch_predict(o, newdata = nd[1, ], type = "conditional")[1, "EY_S0"]
  }
  g <- numDeriv::grad(f, coef(h))
  expect_equal(pn$se.fit[[1, "EY_S0"]], sqrt(drop(g %*% vcov(h) %*% g)),
               tolerance = 1e-6)
  expect_equal(fitted(h)[d$S == 1], p[d$S == 1, "EY_S1"], tolerance = 1e-12)
  expect_true(all(is.na(residuals(h)[d$S == 0])))
  expect_error(switch_effects(h), class = "switch_error_unsupported")
  expect_error(switch_counterfactual(h), class = "switch_error_unsupported")
})

test_that("treatment likelihood is the ESR likelihood under the restriction", {
  skip_if_not_installed("numDeriv")
  sd <- tr$data; map <- tr$map
  th <- tr$coef_working + seq(-0.1, 0.1, length.out = map$p)
  L <- lik_treatment_gaussian(th, sd, map, deriv = 2L)
  ## direct evaluation of the treatment likelihood
  g <- th[1:3]; b <- th[4:6]; dl <- th[7:8]; sig <- exp(th[9]); rho <- tanh(th[10])
  e <- (d$y - cbind(1, d$x1, d$x2) %*% b - d$S * (cbind(1, d$x1) %*% dl)) / sig
  ll <- -log(sig) + dnorm(e, log = TRUE) +
    pnorm((2 * d$S - 1) * (cbind(1, d$x1, d$z1) %*% g + rho * e) /
            sqrt(1 - rho^2), log.p = TRUE)
  expect_equal(L$ll_i, drop(ll), tolerance = 1e-12)
  f <- function(t) sum(lik_treatment_gaussian(t, sd, map)$ll_i)
  expect_equal(unname(colSums(L$score_i)), numDeriv::grad(f, th),
               tolerance = 1e-7)
  expect_equal(unname(L$hessian), numDeriv::hessian(f, th), tolerance = 1e-6)
  ## modifiers that are not outcome regressors
  tr3 <- treatment(S ~ x1 + z1, y ~ x1, data = d, shift = ~ x2)
  expect_identical(names(coef(tr3))[6:7], c("shift:(Intercept)", "shift:x2"))
  th3 <- tr3$coef_working + 0.05
  f3 <- function(t) sum(lik_treatment_gaussian(t, tr3$data, tr3$map)$ll_i)
  L3 <- lik_treatment_gaussian(th3, tr3$data, tr3$map, deriv = 2L)
  expect_equal(unname(colSums(L3$score_i)), numDeriv::grad(f3, th3),
               tolerance = 1e-7)
  expect_equal(unname(L3$hessian), numDeriv::hessian(f3, th3), tolerance = 1e-6)
})

test_that("treatment FIML equals sampleSelection::treatReg", {
  skip_if_not_installed("sampleSelection")
  t0 <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d)
  s0 <- sampleSelection::treatReg(S ~ x1 + z1, y ~ x1 + x2 + S, data = d,
                                  method = "ml")
  expect_equal(t0$loglik, as.numeric(logLik(s0)), tolerance = 1e-9)
  expect_equal(unname(coef(t0)), as.numeric(coef(s0)), tolerance = 1e-5)
  expect_equal(unname(sqrt(diag(vcov(t0)))), as.numeric(sqrt(diag(vcov(s0)))),
               tolerance = 1e-4)
  s1 <- sampleSelection::treatReg(S ~ x1 + z1, y ~ x1 + x2 + S + S:x1,
                                  data = d, method = "ml")
  expect_equal(tr$loglik, as.numeric(logLik(s1)), tolerance = 1e-9)
  expect_equal(unname(coef(tr)), as.numeric(coef(s1)), tolerance = 1e-5)
})

test_that("treatment two-step: regression on (x, S d, h) with corrected covariance", {
  t2 <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d, shift = ~ x1,
                  method = "two_step")
  pr <- glm(S ~ x1 + z1, family = binomial("probit"), data = d,
            control = glm.control(epsilon = 1e-12))
  w <- predict(pr)
  hh <- ifelse(d$S == 1, dnorm(w) / pnorm(w), -dnorm(w) / pnorm(-w))
  ols <- lm(y ~ x1 + x2 + S + I(S * x1) + hh, data = d)
  expect_equal(unname(t2$two_step$psi[4:9]), unname(coef(ols)),
               tolerance = 1e-6)
  dd <- hh * (hh + w)
  s2 <- mean(residuals(ols)^2) + coef(ols)[["hh"]]^2 * mean(dd)
  expect_equal(coef(t2)[["outcome:sigma"]], sqrt(s2), tolerance = 1e-6)
  expect_equal(coef(t2)[["outcome:rho"]], coef(ols)[["hh"]] / sqrt(s2),
               tolerance = 1e-6)
  ## consistent with FIML within sampling error
  z <- (coef(t2)[1:8] - coef(tr)[1:8]) / sqrt(diag(vcov(t2))[1:8])
  expect_lt(max(abs(z)), 3)
  expect_true(all(is.na(diag(vcov(t2))[9:10])))
  t2r <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d, shift = ~ x1,
                   method = "two_step", vcov = "sandwich")
  expect_equal(sqrt(diag(vcov(t2r))[1:8]), sqrt(diag(vcov(t2))[1:8]),
               tolerance = 0.15)
  t2c <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d, shift = ~ x1,
                   method = "two_step", cluster = ~ cl)
  expect_identical(t2c$vcov_type, "cluster")
})

test_that("treatment effects are averages of d'delta with delta-method errors", {
  eff <- switch_effects(tr)$table
  D <- cbind(1, d$x1)
  dl <- coef(tr)[c("shift:(Intercept)", "shift:x1")]
  V <- vcov(tr)[names(dl), names(dl)]
  te <- drop(D %*% dl)
  val <- function(s) c(mean(te[s]), sqrt(drop(colMeans(D[s, ]) %*% V %*%
                                                 colMeans(D[s, ]))))
  expect_equal(unlist(eff[eff$effect == "ATE", c("estimate", "std_error")]),
               val(rep(TRUE, nrow(d))), tolerance = 1e-8, ignore_attr = TRUE)
  expect_equal(unlist(eff[eff$effect == "ATT", c("estimate", "std_error")]),
               val(d$S == 1), tolerance = 1e-8, ignore_attr = TRUE)
  expect_equal(unlist(eff[eff$effect == "ATU", c("estimate", "std_error")]),
               val(d$S == 0), tolerance = 1e-8, ignore_attr = TRUE)
  bh <- eff$estimate[eff$effect == "BH1"] - eff$estimate[eff$effect == "BH0"]
  expect_equal(bh, eff$estimate[eff$effect == "TH"], tolerance = 1e-10)
  ## constant shift: every effect equals delta
  t0 <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d)
  e0 <- switch_effects(t0, effects = c("ATT", "ATU", "ATE"))$table
  expect_equal(e0$estimate, rep(coef(t0)[["shift:(Intercept)"]], 3),
               tolerance = 1e-10)
  expect_equal(e0$std_error,
               rep(sqrt(vcov(t0)["shift:(Intercept)", "shift:(Intercept)"]), 3),
               tolerance = 1e-8)
  ## by groups, two-step, predictions and scenarios run through the same view
  expect_identical(nrow(switch_effects(tr, effects = "ATT", by = ~ g,
                                       data = d)$table), 3L)
  t2 <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d, shift = ~ x1,
                  method = "two_step")
  e2 <- switch_effects(t2, effects = "ATE")$table
  dl2 <- t2$two_step$psi[c("shift:(Intercept)", "shift:x1")]
  V2 <- t2$two_step$vcov_psi[names(dl2), names(dl2)]
  expect_equal(c(e2$estimate, e2$std_error),
               c(mean(D %*% dl2), sqrt(drop(colMeans(D) %*% V2 %*% colMeans(D)))),
               tolerance = 1e-8)
  p <- switch_predict(tr, type = "conditional")
  expect_equal(p[, "EY1_S1"] - p[, "EY0_S1"], te, tolerance = 1e-10)
  expect_equal(p[, "EY1_S0"] - p[, "EY0_S0"], te, tolerance = 1e-10)
  expect_equal(switch_predict(tr, newdata = d[1:4, ], type = "conditional"),
               p[1:4, ], tolerance = 1e-10)
  cf <- switch_counterfactual(tr, "all_regime_1")
  expect_equal(cf$summary$mean_change_given_observed_regime[3],
               mean(te[d$S == 0]), tolerance = 1e-8)
  expect_length(residuals(tr, "pearson"), nrow(d))
})

test_that("tests, validation, comparison and printing work for the new models", {
  lr <- switch_test(tr, "lr_independence")
  expect_identical(as.integer(lr$df), 1L)
  r0 <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d, shift = ~ x1,
                  control = switch_control(starts = 1))
  ols <- lm(y ~ x1 + x2 + S + I(S * x1), data = d)
  pr <- glm(S ~ x1 + z1, family = binomial("probit"), data = d)
  ll0 <- as.numeric(logLik(pr)) +
    sum(dnorm(residuals(ols), 0, sqrt(mean(residuals(ols)^2)), log = TRUE))
  expect_equal(lr$loglik_restricted, ll0, tolerance = 1e-6)
  expect_identical(as.integer(switch_test(h, "wald_independence")$df), 1L)
  w <- switch_test(tr, "wald", hypothesis = "shift:x1 = 0")
  expect_equal(w$statistic, (coef(tr)[["shift:x1"]] /
                               sqrt(vcov(tr)["shift:x1", "shift:x1"]))^2,
               tolerance = 1e-8)
  v <- switch_validate(tr)
  expect_s3_class(v, "switch_validation")
  expect_true(all(c("I1", "I4", "I6", "I11") %in% v$table$code))
  ## I6 uses the within-group R2: no false alarm from the sign change of
  ## the generalised residual (found in the WP2.1 Monte Carlo, design T)
  set.seed(8); n <- 1000
  dt <- data.frame(x1 = rnorm(n), x2 = rnorm(n), z1 = rnorm(n)); u <- rnorm(n)
  dt$S <- as.integer(0.5 + 0.3 * dt$x1 - 0.4 * dt$z1 + u > 0)
  dt$y <- 1 + 0.5 * dt$x1 + 0.2 * dt$x2 + 0.5 * dt$S + 0.6 * u + 0.8 * rnorm(n)
  vt <- switch_validate(treatment(S ~ x1 + z1, y ~ x1 + x2, data = dt))
  expect_identical(vt$table$status[vt$table$code == "I6"], "ok")
  vn <- switch_validate(switch_model(S ~ x1, y ~ x1 + x2, model = "treatment"),
                        dt)
  expect_identical(vn$table$status[vn$table$code == "I6"], "warning")
  sp <- switch_model(S ~ x1, wage ~ x1 + x2, model = "heckman")
  v0 <- switch_validate(sp, d)
  expect_identical(v0$table$status[v0$table$code == "I4"], "warning")
  expect_output(print(sp), "heckman")
  expect_output(print(summary(h)), "Sample selection model")
  expect_output(print(summary(tr)), "Shift when the regime")
  expect_output(print(tr), "Endogenous treatment model")
  expect_identical(names(coef(tr, part = "shift")),
                   c("shift:(Intercept)", "shift:x1"))
  expect_identical(dim(model.matrix(tr, "shift")), c(nrow(d), 2L))
  ## treatment nested in the switching regression: LR test with 3 df
  e1 <- esr(S ~ x1 + z1, list(y ~ x1 + x2, y ~ x1 + x2), data = d)
  cmp <- switch_compare(tr, e1)
  expect_identical(as.integer(cmp$tests$df), 3L)
  expect_equal(cmp$tests$LR, 2 * (e1$loglik - tr$loglik), tolerance = 1e-8)
  expect_true(e1$loglik >= tr$loglik)
  expect_s3_class(switch_diagnostics(h), "switch_diagnostics")
})

test_that("bootstrap and simulation work for the new models", {
  b <- switch_bootstrap(tr, R = 8, seed = 2)
  expect_identical(b$successful, 8L)
  expect_identical(colnames(b$replicates), names(coef(tr)))
  be <- switch_bootstrap(tr, R = 6, seed = 2, statistics = "effects")
  expect_true(all(c("ATT", "ATE") %in% names(be$estimate)))
  h2 <- heckman(S ~ x1 + z1, wage ~ x1 + x2, data = d, method = "two_step")
  bp <- switch_bootstrap(h2, R = 6, seed = 2, type = "parametric")
  expect_identical(bp$successful, 6L)
  expect_error(switch_bootstrap(h, R = 4, statistics = "effects"),
               class = "switch_error_unsupported")
  s <- simulate(h, nsim = 2, seed = 4)
  expect_identical(dim(s), c(nrow(d), 4L))
  expect_true(all(is.na(s$y_1[s$S_1 == 0])))
  sm <- switch_simulate(tr, d, seed = 5, potential_outcomes = TRUE)
  expect_equal(sm$.potential_treated - sm$.potential_untreated,
               drop(cbind(1, d$x1) %*% coef(tr)[7:8]), tolerance = 1e-10)
  sh <- switch_simulate(switch_model(S ~ x1 + z1, wage ~ x1 + x2,
                                     model = "heckman"), d,
                        parameters = coef(h), seed = 6)
  expect_true(all(is.na(sh$wage[sh$S == 0])) && !anyNA(sh$wage[sh$S == 1]))
})

test_that("FIML recovers the parameters of both models", {
  dd <- sim_obs_data(6000, seed = 11)
  hh <- heckman(S ~ x1 + z1, wage ~ x1 + x2, data = dd)
  z <- (coef(hh) - c(0.5, 0.3, -0.8, 1.5, 0.8, 0.4, 1, 0.6)) /
    sqrt(diag(vcov(hh)))
  expect_lt(max(abs(z)), 4)
  tt <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = dd, shift = ~ x1)
  z <- (coef(tt) - c(0.5, 0.3, -0.8, 1, 0.5, 0.2, 0.5, 0.3, 1.2, 0.6)) /
    sqrt(diag(vcov(tt)))
  expect_lt(max(abs(z)), 4)
  expect_identical(tt$convergence$code, 0L)
})

test_that("tobit5 is the switching regression with positional equations", {
  e1 <- esr(S ~ x1 + z1, list(y ~ x1 + x2, y ~ x1 + x2), data = d)
  t5 <- tobit5(S ~ x1 + z1, list(regime_1 = y ~ x1 + x2, regime_0 = y ~ x1 + x2),
               data = d)
  expect_equal(unname(coef(t5)), unname(coef(e1)), tolerance = 1e-10)
  expect_equal(t5$loglik, e1$loglik, tolerance = 1e-10)
  expect_identical(t5$model, "tobit5")
  expect_s3_class(switch_effects(t5), "switch_effects")
  d2 <- d
  d2$y0 <- ifelse(d2$S == 0, d2$y, NA)
  d2$y1 <- ifelse(d2$S == 1, d2$y, NA)
  t5b <- tobit5(S ~ x1 + z1, list(y0 ~ x1 + x2, y1 ~ x1 + x2), data = d2)
  expect_equal(unname(coef(t5b)), unname(coef(e1)), tolerance = 1e-10)
  expect_error(switch_effects(t5b), class = "switch_error_unsupported")
  expect_error(switch_counterfactual(t5b), class = "switch_error_unsupported")
  skip_if_not_installed("sampleSelection")
  ss <- sampleSelection::selection(S ~ x1 + z1, list(y0 ~ x1 + x2, y1 ~ x1 + x2),
                                   data = d2, method = "ml")
  expect_equal(t5b$loglik, as.numeric(logLik(ss)), tolerance = 1e-9)
})

test_that("argument errors of the new models are classed", {
  expect_error(heckman(S ~ x1 + z1, list(wage ~ x1, wage ~ x2), data = d),
               class = "switch_error_argument")
  expect_error(treatment(S ~ x1 + z1, y ~ x1 + S, data = d),
               class = "switch_error_argument")
  expect_error(treatment(S ~ x1 + z1, y ~ x1, data = d, shift = ~ 0 + x1),
               class = "switch_error_argument")
  expect_error(treatment(S ~ x1 + z1, y ~ x1, data = d, shift = y ~ x1),
               class = "switch_error_argument")
  expect_error(switch_fit(S ~ x1 + z1, list(y ~ x1, y ~ x1), data = d,
                          shift = ~ x1), class = "switch_error_argument")
  expect_error(switch_fit(S ~ x1 + z1, wage ~ x1, data = d, model = "heckman",
                          shift = ~ 1), class = "switch_error_argument")
  expect_error(switch_fit(S ~ x1 + z1, list(y ~ x1, y ~ x1, y ~ x1), data = d,
                          model = "multinomial_esr"),
               class = "switch_error_unsupported")
  d0 <- d; d0$S <- 1L
  expect_error(suppressMessages(heckman(S ~ x1 + z1, wage ~ x1, data = d0)),
               class = "switch_error_data")
  expect_error(treatment(S ~ x1 + z1, y ~ x1 + x2, data = d,
                         shift = ~ I(2 * x1) + x1),
               class = "switch_error_rank")
  hw <- heckman(S ~ x1 + z1, wage ~ x1 + x2, data = d, weights = ~ w)
  expect_identical(hw$vcov_type, "sandwich")
  hk <- heckman(S ~ x1 + z1, wage ~ x1 + x2, data = d,
                control = switch_control(keep_data = FALSE))
  expect_null(hk$data)
  expect_equal(switch_predict(hk, newdata = d[1:3, ], type = "linear"),
               switch_predict(h, newdata = d[1:3, ], type = "linear"),
               tolerance = 1e-10)
})
