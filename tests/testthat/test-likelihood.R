## Binary Gaussian ESR likelihood engine (LIKELIHOOD_DERIVATION.md s.2-8;
## acceptance criterion AC2 in 04_Validation/ACCEPTANCE_TESTS.md).

random_theta <- function(map, sd_scale = 0.3, seed = 1) {
  set.seed(seed)
  se_par_working(map, esr_truth(map)) + rnorm(map$p, 0, sd_scale)
}

test_that("engine equals the independent reference implementation (AC2b)", {
  E <- esr_setup(500)
  R <- ref_setup(E$sd, E$map)
  for (k in 1:3) {
    th <- random_theta(E$map, 0.4, seed = k)
    L <- lik_esr_gaussian(th, E$sd, E$map, deriv = 2L)
    thr <- unname(th[R$perm])
    expect_equal(L$ll_i, ref_loglik_i(thr, R$d, R$ix), tolerance = 1e-12)
    expect_equal(unname(L$score_i[, R$perm]), ref_score_i(thr, R$d, R$ix),
                 tolerance = 1e-12)
    expect_equal(unname(L$hessian[R$perm, R$perm]),
                 ref_hessian(thr, R$d, R$ix), tolerance = 1e-12)
  }
})

test_that("contributions equal the integrated bivariate normal density", {
  E <- esr_setup(300)
  th <- random_theta(E$map, 0.3, seed = 7)
  thn <- se_par_natural(E$map, th)
  ll <- loglik_joint(th, E$sd, E$map)
  sd <- E$sd
  w <- drop(sd$Z %*% thn[E$map$index$gamma])
  err <- 0
  for (r in 1:2) {
    lab <- sd$regimes[r]
    sig <- thn[[E$map$index$sigma[[lab]]]]
    rho <- thn[[E$map$index$rho[[lab]]]]
    ids <- which(sd$S == r - 1L)[1:8]
    for (i in ids) {
      eps <- sd$y[i] - sum(sd$X[[lab]][i, ] * thn[E$map$index$beta[[lab]]])
      f <- function(u) ref_dbvn(u, eps, sig, rho)
      Lint <- if (r == 2L) integrate(f, -w[i], Inf, rel.tol = 1e-12)$value
              else integrate(f, -Inf, -w[i], rel.tol = 1e-12)$value
      err <- max(err, abs(exp(ll[i]) / Lint - 1))
    }
  }
  expect_lt(err, 1e-8)
})

test_that("contributions define a proper density of (S, y)", {
  E <- esr_setup(200)
  th <- random_theta(E$map, 0.3, seed = 3)
  sd <- E$sd
  one_obs <- function(i, s) {
    function(yv) {
      m <- length(yv)
      sd1 <- sd
      sd1$n <- m; sd1$S <- rep(s, m); sd1$y <- yv
      sd1$Z <- sd$Z[rep(i, m), , drop = FALSE]
      sd1$X <- lapply(sd$X, function(X) X[rep(i, m), , drop = FALSE])
      sd1$weights <- NULL
      exp(loglik_joint(th, sd1, E$map))
    }
  }
  for (i in c(1, 17, 101)) {
    w <- sum(sd$Z[i, ] * th[E$map$index$gamma])
    p1 <- integrate(one_obs(i, 1L), -Inf, Inf, rel.tol = 1e-12)$value
    p0 <- integrate(one_obs(i, 0L), -Inf, Inf, rel.tol = 1e-12)$value
    expect_equal(p1, pnorm(w), tolerance = 1e-9)
    expect_equal(p0, pnorm(-w), tolerance = 1e-9)
  }
})

test_that("analytic gradient and Hessian match numerical derivatives", {
  skip_if_not_installed("numDeriv")
  for (wt in c(FALSE, TRUE)) {
    E <- esr_setup(300, weights = if (wt) ~ w)
    for (k in 1:2) {
      th <- random_theta(E$map, 0.5, seed = 10 * k + wt)
      A <- loglik_switch(th, E$sd, E$map, deriv = 2L)
      gn <- numDeriv::grad(function(t) loglik_switch(t, E$sd, E$map)$loglik, th)
      Hn <- numDeriv::jacobian(function(t)
        loglik_switch(t, E$sd, E$map, deriv = 1L)$gradient, th)
      expect_lt(max(abs(A$gradient - gn)) / max(1, abs(gn)), 1e-6)
      expect_lt(max(abs(A$hessian - Hn)) / max(1, abs(Hn)), 1e-6)
      expect_equal(A$hessian, t(A$hessian))
    }
  }
})

test_that("weighted totals are weighted sums of the contributions", {
  E <- esr_setup(250, weights = ~ w)
  th <- random_theta(E$map, 0.2, seed = 2)
  A <- loglik_switch(th, E$sd, E$map, deriv = 1L)
  expect_equal(A$loglik, sum(E$sd$weights * A$ll_i))
  expect_equal(A$gradient, colSums(E$sd$weights * A$score_i))
  ## unit weights reproduce the unweighted likelihood
  sd1 <- E$sd; sd1$weights <- rep(1, sd1$n)
  sd0 <- E$sd; sd0$weights <- NULL
  expect_equal(loglik_switch(th, sd1, E$map, 2L)$hessian,
               loglik_switch(th, sd0, E$map, 2L)$hessian)
  L0 <- loglik_switch(th, sd0, E$map, deriv = 0L)
  expect_null(L0$gradient)
  expect_null(L0$hessian)
})

test_that("evaluation is stable for extreme correlations and outliers", {
  E <- esr_setup(200)
  R <- ref_setup(E$sd, E$map)
  th <- se_par_working(E$map, esr_truth(E$map))
  th[E$map$index$rho$regime_1] <- 3.5        # rho ~ 0.998
  th[E$map$index$rho$regime_0] <- -3.5
  sd <- E$sd
  sd$y[which(sd$S == 1)[1:3]] <- c(-40, -25, 30)
  sd$y[which(sd$S == 0)[1:3]] <- c(40, -30, 25)
  L <- lik_esr_gaussian(th, sd, E$map, deriv = 2L)
  expect_true(all(is.finite(L$ll_i)))
  expect_true(all(is.finite(L$score_i)))
  expect_true(all(is.finite(L$hessian)))
  R$d$y <- sd$y
  expect_equal(L$ll_i, ref_loglik_i(unname(th[R$perm]), R$d, R$ix),
               tolerance = 1e-12)
})

test_that("the per-observation decomposition satisfies its identities", {
  E <- esr_setup(300)
  th <- random_theta(E$map, 0.2, seed = 4)
  cmp <- loglik_observation(th, E$sd, E$map)
  expect_named(cmp, c("regime", "y", "log_prob_regime", "log_density_outcome",
                      "log_selection_conditional", "loglik",
                      "log_density_conditional", "dependence_correction"))
  expect_equal(cmp$loglik, loglik_joint(th, E$sd, E$map), tolerance = 1e-12)
  expect_equal(cmp$loglik, cmp$log_prob_regime + cmp$log_density_conditional)
  expect_identical(cmp$regime, E$sd$regimes[E$sd$S + 1L])
  expect_identical(loglik_selection(th, E$sd, E$map), cmp$log_prob_regime)
  expect_identical(loglik_selection(th, E$sd, E$map, conditional = TRUE),
                   cmp$log_selection_conditional)
  expect_identical(loglik_outcome(th, E$sd, E$map), cmp$log_density_outcome)
  expect_identical(loglik_outcome(th, E$sd, E$map, conditional = TRUE),
                   cmp$log_density_conditional)
  ## with rho = 0 there is no dependence correction
  th0 <- th
  th0[unlist(E$map$index$rho)] <- 0
  c0 <- loglik_observation(th0, E$sd, E$map)
  expect_equal(c0$dependence_correction, rep(0, E$sd$n), tolerance = 1e-14)
})

test_that("at rho = 0 the likelihood is probit plus two regressions", {
  E <- esr_setup(400)
  d <- E$data
  pr <- glm(S ~ x1 + z1, family = binomial(link = "probit"), data = d,
            control = glm.control(epsilon = 1e-14))
  l0 <- lm(y ~ x1 + x2, data = d, subset = S == 0)
  l1 <- lm(y ~ x1 + x2, data = d, subset = S == 1)
  s_ml <- function(m) sqrt(mean(residuals(m)^2))
  thn <- c(coef(pr), coef(l0), s_ml(l0), 0, coef(l1), s_ml(l1), 0)
  th <- se_par_working(E$map, unname(thn))
  expect_equal(loglik_switch(th, E$sd, E$map)$loglik,
               as.numeric(logLik(pr)) + as.numeric(logLik(l0)) +
                 as.numeric(logLik(l1)), tolerance = 1e-10)
})

test_that("information-matrix equality holds at the true parameters", {
  E <- esr_setup(20000, seed = 5)
  th <- se_par_working(E$map, esr_truth(E$map))
  A <- loglik_switch(th, E$sd, E$map, deriv = 2L)
  S <- A$score_i
  z <- abs(colMeans(S)) / (apply(S, 2, sd) / sqrt(nrow(S)))
  expect_lt(max(z), 4.5)
  expect_lt(norm(-A$hessian - crossprod(S), "F") / norm(A$hessian, "F"), 0.05)
})

test_that("log-likelihood equals sampleSelection's at its ML estimates (AC2c)", {
  skip_if_not_installed("sampleSelection")
  E <- esr_setup(1500, seed = 9)
  f <- sampleSelection::selection(S ~ x1 + z1, list(y ~ x1 + x2, y ~ x1 + x2),
                                  data = E$data, method = "ml")
  cf <- stats::coef(f)
  ## sampleSelection's Tobit-5 order (S:, O1 = regime 0 with sigma1, rho1,
  ## O2 = regime 1 with sigma2, rho2) coincides with the parameter-map order
  ## (BINARY_ESR.md s.6)
  expect_length(cf, E$map$p)
  th <- se_par_working(E$map, unname(cf))
  A <- loglik_switch(th, E$sd, E$map, deriv = 1L)
  expect_equal(A$loglik, as.numeric(stats::logLik(f)), tolerance = 1e-10)
  expect_lt(max(abs(A$gradient)), 1e-2)
})

test_that("unsupported model combinations have no engine", {
  E <- esr_setup(50)
  sd <- E$sd
  sd$outcome_family <- "student_t"
  th <- se_par_working(E$map, esr_truth(E$map))
  expect_error(loglik_switch(th, sd, E$map), class = "switch_error_unsupported")
})
