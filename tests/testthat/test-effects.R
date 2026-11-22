## Treatment effects, predictions, counterfactuals (WP1.6;
## TREATMENT_EFFECTS.md; acceptance criterion AC5).

fml <- list(regime_0 = y ~ x1 + x2, regime_1 = y ~ x1 + x2)
eff_cache <- new.env()
efit <- function(method = "fiml", n = 1500, seed = 3, ...) {
  key <- paste(method, n, seed)
  if (is.null(eff_cache[[key]])) {
    eff_cache[[key]] <- switch_fit(S ~ x1 + z1, fml,
                                   data = sim_esr_data(n, seed = seed),
                                   method = method, ...)
  }
  eff_cache[[key]]
}
eff_value <- function(fit, psi, set = NULL) {
  sd <- fit$data
  ix <- se_psi_index(fit$map, sd$regimes)
  cmp <- se_eff_components(psi, sd$Z, sd$X[[1]], sd$X[[2]], ix, grad = FALSE)
  se_eff_compute(cmp, sd$S, sd$weights %||% rep(1, sd$n),
                 set %||% rep(TRUE, sd$n))$estimate
}

test_that("conditional expectations equal two-dimensional integrals (AC5b)", {
  f <- efit()
  sd <- f$data
  th <- coef(f)
  e <- switch_effects(f, individual = TRUE)$individual
  w <- drop(sd$Z %*% th[f$map$index$gamma])
  for (i in c(3, 11)) {
    for (j in 1:2) {
      lab <- sd$regimes[j]
      sig <- th[[paste0(lab, ":sigma")]]; rho <- th[[paste0(lab, ":rho")]]
      xb <- sum(sd$X[[lab]][i, ] * th[f$map$index$beta[[lab]]])
      inner <- function(u) vapply(u, function(uu) integrate(function(ee)
        ee * ref_dbvn(uu, ee, sig, rho), -Inf, Inf, rel.tol = 1e-11)$value,
        numeric(1))
      e1 <- integrate(inner, -w[i], Inf, rel.tol = 1e-10)$value / pnorm(w[i])
      e0 <- integrate(inner, -Inf, -w[i], rel.tol = 1e-10)$value / pnorm(-w[i])
      k1 <- if (j == 2) "EY1_S1" else "EY0_S1"
      k0 <- if (j == 2) "EY1_S0" else "EY0_S0"
      expect_equal(e[[k1]][i], xb + e1, tolerance = 1e-7)
      expect_equal(e[[k0]][i], xb + e0, tolerance = 1e-7)
    }
  }
})

test_that("effects equal the reference implementation (AC5b)", {
  f <- efit()
  R <- ref_setup(f$data, f$map)
  ref <- ref_effects(unname(coef(f, "working")[R$perm]), R$d, R$ix)
  tab <- switch_effects(f, se = "none")$table
  expect_equal(stats::setNames(tab$estimate, tab$effect), ref, tolerance = 1e-10)
})

test_that("identities between the effects (AC5c)", {
  f <- efit()
  e <- switch_effects(f)
  est <- stats::setNames(e$table$estimate, e$table$effect)
  expect_equal(unname(est["BH1"] - est["BH0"]), unname(est["TH"]), tolerance = 1e-12)
  ## share-weighted ATT/ATU equals ATE exactly at the probit MLE (two-step)
  t2 <- switch_effects(efit("two_step"))
  est2 <- stats::setNames(t2$table$estimate, t2$table$effect)
  expect_equal(unname(t2$ate_weighted), unname(est2["ATE"]), tolerance = 1e-6)
  ind <- switch_effects(f, individual = TRUE)$individual
  expect_equal(mean(ind$TT, na.rm = TRUE), unname(est["ATT"]))
  expect_equal(mean(ind$TU, na.rm = TRUE), unname(est["ATU"]))
  expect_equal(mean(ind$ATE_i), unname(est["ATE"]))
})

test_that("delta-method gradients equal numerical derivatives (AC5d)", {
  skip_if_not_installed("numDeriv")
  for (m in c("fiml", "two_step")) {
    f <- efit(m)
    sd <- f$data
    ix <- se_psi_index(f$map, sd$regimes)
    psi <- se_psi_from_natural(coef(f), f$map, sd$regimes)
    cmp <- se_eff_components(psi, sd$Z, sd$X[[1]], sd$X[[2]], ix)
    ga <- se_eff_compute(cmp, sd$S, rep(1, sd$n), rep(TRUE, sd$n))$gradient
    gn <- numDeriv::jacobian(function(p) eff_value(f, p), psi)
    expect_lt(max(abs(ga - gn)) / max(1, abs(gn)), 1e-7)
  }
  ## natural-scale covariance of psi for FIML: delta method by hand
  f <- efit()
  Vp <- se_psi_vcov(f)
  J <- numDeriv::jacobian(function(t) se_psi_from_natural(
    stats::setNames(t, names(coef(f))), f$map, f$regimes), coef(f))
  expect_equal(Vp, J %*% vcov(f) %*% t(J), tolerance = 1e-8)
})

test_that("expectations match simulated potential outcomes (AC5)", {
  skip_on_cran()
  spec <- switch_model(S ~ x1 + z1, fml)
  set.seed(1)
  n <- 200000
  cov <- data.frame(x1 = rnorm(n), x2 = rnorm(n), z1 = rnorm(n))
  truth <- c(0.5, 0.3, -0.4, 1.0, 0.5, 0.2, 0.8, 0.4, 1.5, 0.8, 0.4, 1.2, 0.6)
  sim <- switch_simulate(spec, cov, truth, seed = 2, potential_outcomes = TRUE)
  sd <- se_build_data(spec, sim)
  map <- se_parmap_esr(sd)
  ix <- se_psi_index(map, sd$regimes)
  psi <- se_psi_from_natural(stats::setNames(truth, map$elements$name), map,
                             sd$regimes)
  cmp <- se_eff_components(psi, sd$Z, sd$X[[1]], sd$X[[2]], ix, grad = FALSE)
  y1 <- sim$.potential_regime_1; y0 <- sim$.potential_regime_0
  S <- sim$S == 1
  zscore <- function(v, target) abs(mean(v) - target) / (sd(v) / sqrt(length(v)))
  expect_lt(zscore(y0[S], mean(cmp$EY[S, "EY0_S1"])), 4)   # counterfactual
  expect_lt(zscore(y1[!S], mean(cmp$EY[!S, "EY1_S0"])), 4) # counterfactual
  expect_lt(zscore(y1[S] - y0[S], mean(cmp$EY[S, 1] - cmp$EY[S, 3])), 4)   # ATT
  expect_lt(zscore(y1[!S] - y0[!S], mean(cmp$EY[!S, 2] - cmp$EY[!S, 4])), 4) # ATU
})

test_that("groups, subsets, weights and individual effects", {
  f <- efit()
  d <- sim_esr_data(1500, seed = 3)
  g <- switch_effects(f, by = d$x2 > 0)
  s <- switch_effects(f, subset = d$x2 > 0)
  gt <- g$table[g$table$group == "TRUE", ]
  expect_equal(gt$estimate, s$table$estimate)
  expect_equal(gt$std_error, s$table$std_error)
  gf <- switch_effects(f, by = ~ x2 > 0, data = d)
  expect_equal(gf$table$estimate, g$table$estimate)
  expect_error(switch_effects(f, by = ~ g), "needs 'data'",
               class = "switch_error_argument")
  expect_error(switch_effects(f, by = 1:3), class = "switch_error_argument")
  expect_error(switch_effects(f, effects = "LATE"),
               class = "switch_error_argument")
  expect_output(print(g), "group TRUE")
  ## no empty heterogeneity row when TH, BH1 and BH0 are not requested
  g2 <- switch_effects(f, effects = c("ATT", "ATU"))
  expect_false(any(grepl("heterogeneity", capture.output(print(g2)))))
  expect_output(print(switch_effects(f)), "heterogeneity")
  ## frequency weights equal replicated data
  set.seed(3); d$k <- sample(1:3, nrow(d), replace = TRUE)
  fw <- switch_fit(S ~ x1 + z1, fml, data = d, weights = ~ k)
  fr <- switch_fit(S ~ x1 + z1, fml, data = d[rep(seq_len(nrow(d)), d$k), ])
  expect_equal(switch_effects(fw, se = "none")$table$estimate,
               switch_effects(fr, se = "none")$table$estimate, tolerance = 1e-6)
  fk <- switch_fit(S ~ x1 + z1, fml, data = d,
                   control = switch_control(keep_data = FALSE))
  expect_error(switch_effects(fk), class = "switch_error_argument")
})

test_that("bootstrap of the effects", {
  f <- efit(n = 600, seed = 5)
  b <- switch_bootstrap(f, R = 15, statistics = "effects", seed = 2)
  expect_identical(colnames(b$replicates), c("ATT", "ATU", "ATE", "TH", "BH1", "BH0"))
  e1 <- switch_effects(f, se = "bootstrap", R = 15, seed = 2)
  expect_equal(e1$table$std_error, unname(b$se))
  d <- sim_esr_data(600, seed = 5)
  eg <- switch_effects(f, effects = "ATT", se = "bootstrap", R = 15, seed = 2,
                       by = d$x2 > 0)
  expect_true(all(is.finite(eg$table$std_error)))
})

test_that("delta-method and bootstrap standard errors are similar (local)", {
  skip_on_cran()
  f <- efit(n = 1500, seed = 3)
  ed <- switch_effects(f)
  eb <- switch_effects(f, se = "bootstrap", R = 200, seed = 9)
  r <- eb$table$std_error / ed$table$std_error
  expect_true(all(r > 0.7 & r < 1.5))
})

test_that("predictions of every type", {
  f <- efit()
  sd <- f$data
  th <- coef(f)
  w <- drop(sd$Z %*% th[f$map$index$gamma])
  expect_equal(switch_predict(f), pnorm(w))
  expect_equal(switch_predict(f, type = "selection_index"), w)
  lin <- switch_predict(f, type = "linear")
  expect_identical(colnames(lin), c("regime_0", "regime_1"))
  expect_equal(lin[, "regime_1"], drop(sd$X$regime_1 %*% th[9:11]))
  cond <- switch_predict(f, type = "conditional")
  ind <- switch_effects(f, individual = TRUE)$individual
  expect_equal(unname(cond[, "EY0_S1"]), ind$EY0_S1)
  obs <- switch_predict(f, type = "observed")
  expect_equal(obs, fitted(f))
  expect_equal(obs, ifelse(sd$S == 1, cond[, "EY1_S1"], cond[, "EY0_S0"]))
  un <- switch_predict(f, type = "unconditional")
  th1 <- th[["regime_1:sigma"]] * th[["regime_1:rho"]]
  th0 <- th[["regime_0:sigma"]] * th[["regime_0:rho"]]
  expect_equal(un, pnorm(w) * lin[, 2] + pnorm(-w) * lin[, 1] +
                 (th1 - th0) * dnorm(w))
  ## new data reproduce the in-sample predictions; NA rows give NA
  d <- sim_esr_data(1500, seed = 3)
  expect_equal(switch_predict(f, newdata = d, type = "unconditional"), un)
  expect_equal(predict(f, newdata = d, type = "observed"), obs)
  d2 <- d[1:5, ]; d2$x1[2] <- NA
  p <- switch_predict(f, newdata = d2, type = "conditional")
  expect_true(all(is.na(p[2, ])))
  expect_false(anyNA(p[-2, ]))
  expect_error(switch_predict(f, newdata = d[, c("x1", "x2")], type = "probability"),
               class = "switch_error_data")
})

test_that("prediction standard errors equal the delta method", {
  skip_if_not_installed("numDeriv")
  f <- efit()
  d <- sim_esr_data(1500, seed = 3)[1:4, ]
  V <- se_psi_vcov(f)
  psi0 <- se_psi_from_natural(coef(f), f$map, f$regimes)
  des <- se_newdata_design(f, d)
  ix <- se_psi_index(f$map, f$regimes)
  fun <- function(p) {
    cmp <- se_eff_components(p, des$Z, des$X[[1]], des$X[[2]], ix, grad = FALSE)
    pnorm(cmp$w) * cmp$xb1 + pnorm(-cmp$w) * cmp$xb0 +
      (cmp$th1 - cmp$th0) * dnorm(cmp$w)
  }
  G <- numDeriv::jacobian(fun, psi0)
  se_num <- sqrt(rowSums((G %*% V) * G))
  p <- switch_predict(f, newdata = d, type = "unconditional", se = TRUE)
  expect_equal(unname(p$se.fit), se_num, tolerance = 1e-6)
  pc <- switch_predict(f, newdata = d, type = "conditional", se = TRUE)
  expect_identical(dim(pc$se.fit), c(4L, 4L))
  expect_true(all(pc$se.fit > 0))
})

test_that("residuals", {
  f <- efit(n = 3000, seed = 6)
  r <- residuals(f)
  expect_equal(r, f$data$y - fitted(f))
  rp <- residuals(f, "pearson")
  expect_lt(abs(mean(rp)), 0.1)
  expect_gt(sd(rp), 0.9); expect_lt(sd(rp), 1.1)
})

test_that("counterfactual scenarios", {
  f <- efit()
  sd <- f$data
  cf1 <- switch_counterfactual(f, "all_regime_1")
  lin <- switch_predict(f, type = "linear")
  s <- cf1$summary
  expect_equal(s$mean_scenario[1], mean(lin[, "regime_1"]))
  expect_equal(s$mean_baseline[1],
               mean(switch_predict(f, type = "unconditional")))
  est <- switch_effects(f)$table
  atu <- est$estimate[est$effect == "ATU"]
  expect_equal(s$mean_change_given_observed_regime[3], atu)  # regime-0 units
  expect_equal(s$mean_change_given_observed_regime[2], 0)
  expect_equal(s$std_error_given_observed_regime[3],
               est$std_error[est$effect == "ATU"], tolerance = 1e-10)
  cf0 <- switch_counterfactual(f, "all_regime_0")
  att <- est$estimate[est$effect == "ATT"]
  expect_equal(cf0$summary$mean_change_given_observed_regime[2], -att)
  ## unchanged covariates: no change
  d <- sim_esr_data(1500, seed = 3)
  cp <- switch_counterfactual(f, "policy", newdata = d)
  expect_equal(cp$summary$mean_change, rep(0, 3), tolerance = 1e-12)
  ## higher z1 lowers adoption (gamma_z1 < 0); the change is consistent
  d2 <- d; d2$z1 <- d2$z1 + 1
  cp2 <- switch_counterfactual(f, "policy", newdata = d2)
  expect_lt(cp2$summary$change_share[1], 0)
  expect_equal(cp2$summary$mean_change[1], mean(cp2$individual$change))
  expect_output(print(cp2), "policy")
  expect_error(switch_counterfactual(f, "policy"), class = "switch_error_argument")
  expect_error(switch_counterfactual(f, "policy", newdata = d[1:10, ]),
               class = "switch_error_data")
})

test_that("counterfactual standard errors equal the delta method", {
  skip_if_not_installed("numDeriv")
  f <- efit()
  d <- sim_esr_data(1500, seed = 3); d$z1 <- d$z1 + 1
  cp <- switch_counterfactual(f, "policy", newdata = d)
  V <- se_psi_vcov(f)
  ix <- se_psi_index(f$map, f$regimes)
  des <- se_newdata_design(f, d)
  sd <- f$data
  un <- function(p, Z, X0, X1) {
    cmp <- se_eff_components(p, Z, X0, X1, ix, grad = FALSE)
    pnorm(cmp$w) * cmp$xb1 + pnorm(-cmp$w) * cmp$xb0 +
      (cmp$th1 - cmp$th0) * dnorm(cmp$w)
  }
  fun <- function(p) mean(un(p, des$Z, des$X[[1]], des$X[[2]]) -
                            un(p, sd$Z, sd$X[[1]], sd$X[[2]]))
  g <- numDeriv::grad(fun, se_psi_from_natural(coef(f), f$map, f$regimes))
  expect_equal(cp$summary$std_error[1], sqrt(drop(t(g) %*% V %*% g)),
               tolerance = 1e-6)
})

test_that("simulation from specifications and fits", {
  spec <- switch_model(S ~ x1 + z1, fml)
  cov <- sim_esr_data(300, seed = 1)[, c("x1", "x2", "z1")]
  truth <- c(0.5, 0.3, -0.4, 1.0, 0.5, 0.2, 0.8, 0.4, 1.5, 0.8, 0.4, 1.2, 0.6)
  set.seed(5); a <- runif(1)
  set.seed(5)
  s1 <- switch_simulate(spec, cov, truth, seed = 9)
  expect_identical(runif(1), a)
  s2 <- switch_simulate(spec, cov, truth, seed = 9)
  expect_identical(s1, s2)
  expect_true(all(s1$S %in% 0:1))
  expect_equal(attr(s1, "r10"), c(r10 = 0.24))
  sp <- switch_simulate(spec, cov, truth, seed = 9, potential_outcomes = TRUE,
                        r10 = 0)
  expect_identical(sp$S, s1$S)                 # observed data do not depend on r10
  expect_true(all(c(".potential_regime_0", ".potential_regime_1") %in% names(sp)))
  expect_equal(sp$y, ifelse(sp$S == 1, sp$.potential_regime_1,
                            sp$.potential_regime_0))
  expect_length(switch_simulate(spec, cov, truth, nsim = 3), 3L)
  expect_error(switch_simulate(spec, cov), class = "switch_error_argument")
  expect_error(switch_simulate(spec, cov, truth, r10 = 0.99),
               class = "switch_error_domain")
  expect_error(switch_simulate(switch_model(S ~ x1 + z1,
                                            list(log(y) ~ x1, log(y) ~ x1)),
                               cov, truth[-c(6, 11)]),
               "plain variable", class = "switch_error_argument")
  ## from a fit with a factor regime indicator
  d <- sim_esr_data(300, seed = 2)
  d$S <- factor(ifelse(d$S == 1, "yes", "no"), levels = c("no", "yes"))
  f <- switch_fit(S ~ x1 + z1, list(no = y ~ x1 + x2, yes = y ~ x1 + x2),
                  data = d)
  sf <- switch_simulate(f, d, seed = 1)
  expect_s3_class(sf$S, "factor")
  expect_identical(levels(sf$S), c("no", "yes"))
  sm <- simulate(f, nsim = 2, seed = 4)
  expect_identical(names(sm), c("S_1", "y_1", "S_2", "y_2"))
  expect_identical(sm, simulate(f, nsim = 2, seed = 4))
})

test_that("refits on simulated data recover the parameters (local)", {
  skip_on_cran()
  spec <- switch_model(S ~ x1 + z1, fml)
  cov <- sim_esr_data(8000, seed = 11)[, c("x1", "x2", "z1")]
  truth <- c(0.5, 0.3, -0.4, 1.0, 0.5, 0.2, 0.8, 0.4, 1.5, 0.8, 0.4, 1.2, 0.6)
  sim <- switch_simulate(spec, cov, truth, seed = 12)
  f <- switch_fit(model = spec, data = sim)
  expect_lt(max(abs((coef(f) - truth) / sqrt(diag(vcov(f))))), 4)
})

test_that("comparison, anova, update and model methods", {
  d <- sim_esr_data(1500, seed = 3)
  f1 <- efit()
  f0 <- switch_fit(S ~ x1 + z1, list(y ~ x1, y ~ x1), data = d)
  cmp <- switch_compare(small = f0, big = f1)
  expect_s3_class(cmp, "switch_comparison")
  expect_identical(cmp$table$model, c("small", "big"))
  expect_equal(cmp$tests$LR, 2 * (f1$loglik - f0$loglik))
  expect_identical(cmp$tests$df, 2L)
  expect_output(print(cmp), "Likelihood-ratio")
  a <- anova(f0, f1)
  expect_s3_class(a, "anova")
  expect_equal(a$Chisq[2], cmp$tests$LR)
  expect_error(anova(f1), class = "switch_error_argument")
  fother <- switch_fit(S ~ x1 + z1, fml, data = sim_esr_data(1500, seed = 4))
  expect_null(switch_compare(f1, fother)$tests)
  expect_error(anova(f1, fother), class = "switch_error_argument")
  ## update re-evaluates the call; esr() records its own call
  u <- update(f0, method = "two_step")
  expect_identical(u$method, "two_step")
  fe <- esr(S ~ x1 + z1, fml, data = d)
  expect_identical(update(fe, method = "two_step")$method, "two_step")
  ## model frames, matrices and terms
  expect_identical(dim(model.matrix(f1, "regime_1")), c(1500L, 3L))
  expect_identical(model.matrix(f1), f1$data$Z)
  expect_true(all(c("S", "x1", "z1") %in% names(model.frame(f1))))
  expect_s3_class(terms(f1, "regime_0"), "terms")
  expect_error(model.matrix(f1, "nope"), class = "switch_error_argument")
})

test_that("the simulated firms data", {
  expect_identical(dim(firms), c(2000L, 10L))
  expect_equal(mean(firms$digital_adoption), 0.486)
  f <- switch_fit(digital_adoption ~ internet_access + management_quality +
                    firm_size + owner_education,
                  list(regime_0 = productivity ~ firm_size + capital + labour,
                       regime_1 = productivity ~ firm_size + capital + labour),
                  data = firms)
  truth <- c(-2.1, 0.9, 0.5, 0.25, 0.06, 0.5, 0.05, 0.30, 0.10, 0.45, -0.25,
             0.8, 0.08, 0.35, 0.10, 0.50, 0.45)
  expect_lt(max(abs((coef(f) - truth) / sqrt(diag(vcov(f))))), 3)
})
