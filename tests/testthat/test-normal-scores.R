## Normal-score multinomial switching regression (version 1.2.0;
## MULTINOMIAL_ESR.md s.11; G2 acceptance test G2-NS-1) and the numerical
## routines it uses.

fo_ns3 <- list(a = y ~ x1 + x2, b = y ~ x1 + x2, c = y ~ x1 + x2)
par_ns3 <- c(0.2, 0.3, 0.8, -0.2,  -0.2, -0.3, 0.2, 0.8,
             1.0, 0.5, 0.2, 1, 0.4, -0.2, -0.2,
             1.5, 0.8, 0.4, 1, -0.3, 0.5, -0.2,
             2.0, 0.3, -0.3, 1.2, 0.1, -0.4, 0.3)
fo_ns2 <- fo_ns3[1:2]
par_ns2 <- c(0.2, 0.3, 0.8, -0.2, 1.0, 0.5, 0.2, 1, 0.4, -0.3,
             1.5, 0.8, 0.4, 1, -0.3, 0.5)
sim_ns <- function(n, seed, J = 3L, potential = FALSE) {
  set.seed(seed)
  d <- data.frame(x1 = rnorm(n), x2 = rnorm(n), z1 = rnorm(n), z2 = rnorm(n))
  sp <- switch_model(regime ~ x1 + z1 + z2, if (J == 3L) fo_ns3 else fo_ns2,
                     model = "multinomial_esr",
                     dependence_structure = "normal_scores")
  d <- switch_simulate(sp, d, parameters = if (J == 3L) par_ns3 else par_ns2,
                       seed = seed + 1L, potential_outcomes = potential)
  list(d = d, sp = sp)
}

test_that("quadrature rules are exact for polynomials", {
  gh <- se_gauss_hermite(24L)
  expect_equal(sum(gh$w), 1, tolerance = 1e-13)
  expect_equal(sum(gh$w * gh$x^2), 1, tolerance = 1e-12)
  expect_equal(sum(gh$w * gh$x^4), 3, tolerance = 1e-12)
  expect_equal(sum(gh$w * gh$x^6), 15, tolerance = 1e-11)
  gl <- se_gauss_legendre(12L)
  expect_equal(sum(gl$w), 2, tolerance = 1e-13)
  expect_equal(sum(gl$w * gl$x^2), 2 / 3, tolerance = 1e-13)
  expect_equal(sum(gl$w * gl$x^10), 2 / 11, tolerance = 1e-13)
})

test_that("bivariate normal distribution function equals mvtnorm", {
  skip_if_not_installed("mvtnorm")
  g <- expand.grid(h = c(-3, -1.2, 0, 0.7, 2.5), k = c(-2.5, -0.4, 0.3, 1.8))
  for (r in c(-0.995, -0.9, -0.6, -0.2, 0.3, 0.75, 0.95, 0.99)) {
    ref <- vapply(seq_len(nrow(g)), function(i) mvtnorm::pmvnorm(
      upper = c(g$h[i], g$k[i]), corr = matrix(c(1, r, r, 1), 2),
      algorithm = mvtnorm::TVPACK(1e-14))[[1]], numeric(1))
    expect_equal(se_pbvnorm(g$h, g$k, r), ref, tolerance = 1e-10,
                 info = paste("r =", r))
  }
  expect_equal(se_pbvnorm(0.3, -0.2, 0), pnorm(0.3) * pnorm(-0.2))
  m <- matrix(c(-1, 0, 1, 2), 2)
  expect_equal(dim(se_pbvnorm(m, m, 0.4)), c(2L, 2L))
  expect_error(se_pbvnorm(0, 0, 1), "correlation")
})

test_that("unit-ball transform of the correlations", {
  skip_if_not_installed("numDeriv")
  a <- c(0.7, -1.3, 0.2)
  r <- se_ball_natural(a)
  expect_lt(sum(r^2), 1)
  expect_equal(se_ball_working(r), a, tolerance = 1e-12)
  expect_equal(se_ball_jacobian(a), numDeriv::jacobian(se_ball_natural, a),
               tolerance = 1e-8)
  expect_error(se_ball_working(c(0.8, 0.7)), class = "switch_error_domain")
})

test_that("normal-score likelihood equals an independent reference (J = 3)", {
  skip_if_not_installed("mvtnorm")
  o <- sim_ns(300, 5)
  sd <- se_build_data_multi(o$sp, o$d); map <- se_parmap_multi(sd)
  expect_identical(map$kind, "ns")
  th <- se_par_working(map, par_ns3) + 0.03
  thn <- se_par_natural(map, th)
  L <- lik_ns_mnl(th, sd, map)
  ref <- function(i) {
    j <- sd$S[i]; lab <- sd$regimes[j]
    v <- c(0, sum(sd$Z[i, ] * thn[1:4]), sum(sd$Z[i, ] * thn[5:8]))
    r <- thn[map$index$rho[[lab]]]; sig <- thn[[map$index$sigma[[lab]]]]
    e <- (sd$y[i] - sum(sd$X[[lab]][i, ] * thn[map$index$beta[[lab]]])) / sig
    oth <- setdiff(1:3, j); a <- exp(v[oth] - v[j]); rj <- r[j]; ro <- r[oth]
    Sc <- diag(2) - tcrossprod(ro) / (1 - rj^2)
    val <- stats::integrate(function(t) vapply(t, function(tt)
      dnorm(tt, rj * e, sqrt(1 - rj^2)) * mvtnorm::pmvnorm(
        upper = qnorm(a * pnorm(tt, log.p = TRUE), log.p = TRUE) -
          ro * (e - rj * tt) / (1 - rj^2),
        sigma = Sc, algorithm = mvtnorm::TVPACK(1e-12))[[1]], numeric(1)),
      rj * e - 8, rj * e + 8, rel.tol = 1e-10)$value
    -log(sig) + dnorm(e, log = TRUE) + log(val)
  }
  ii <- c(which(sd$S == 1)[1:4], which(sd$S == 2)[1:4], which(sd$S == 3)[1:4])
  expect_equal(L$ll_i[ii], vapply(ii, ref, numeric(1)), tolerance = 1e-8)
})

test_that("integration rule of the normal-score model near the boundary", {
  expect_equal(sum(se_gl_composite(14L)$w), 1, tolerance = 1e-13)
  expect_equal(sum(se_gl_composite(14L)$w * se_gl_composite(14L)$x^2), 1,
               tolerance = 1e-12)
  expect_length(se_ns_rule(c(0.4, -0.2, -0.2))$x, 14L * 8L)
  expect_length(se_ns_rule(c(0.7, 0.5, 0.45))$x, 28L * 8L)    # s0 = 0.24
  expect_length(se_ns_rule(c(0.7, 0.5, 0.5))$x, 56L * 8L)     # s0 = 0.1
  expect_length(se_ns_rule(c(0.7, 0.5, 0.509))$x, 112L * 8L)  # s0 = 0.03
  ## accuracy against a rule with 3200 nodes, interior and near the boundary
  set.seed(1)
  e <- rnorm(200); LA <- cbind(rnorm(200, 0, 0.9), rnorm(200, 0, 0.9))
  fine <- se_gl_composite(400L)
  for (q in c(0.3, 0.8, 0.9, 0.97, 0.995)) {
    for (v in list(c(0.5, -0.4, 0.6), c(0.5, 0, 0.8), c(0.9, 0.3, -0.2))) {
      r <- v / sqrt(sum(v^2)) * sqrt(q)
      I <- se_ns_integral(e, LA, r[1], r[2:3], se_ns_rule(r))
      I0 <- se_ns_integral(e, LA, r[1], r[2:3], fine)
      expect_lt(max(abs(log(I) - log(I0))), if (q <= 0.8) 1e-7 else 2e-5)
    }
  }
})

test_that("normal-score likelihood: reference and independence (J = 2)", {
  o <- sim_ns(300, 6, J = 2L)
  sd <- se_build_data_multi(o$sp, o$d); map <- se_parmap_multi(sd)
  th <- se_par_working(map, par_ns2) - 0.02
  thn <- se_par_natural(map, th)
  L <- lik_ns_mnl(th, sd, map)
  ref <- function(i) {
    j <- sd$S[i]; lab <- sd$regimes[j]
    v <- c(0, sum(sd$Z[i, ] * thn[1:4]))
    r <- thn[map$index$rho[[lab]]]; sig <- thn[[map$index$sigma[[lab]]]]
    e <- (sd$y[i] - sum(sd$X[[lab]][i, ] * thn[map$index$beta[[lab]]])) / sig
    m <- 3L - j; a <- exp(v[m] - v[j]); rj <- r[j]; rm <- r[m]
    val <- stats::integrate(function(t) dnorm(t, rj * e, sqrt(1 - rj^2)) *
      pnorm((qnorm(a * pnorm(t, log.p = TRUE), log.p = TRUE) -
               rm * (e - rj * t) / (1 - rj^2)) / sqrt(1 - rm^2 / (1 - rj^2))),
      rj * e - 8, rj * e + 8, rel.tol = 1e-11)$value
    -log(sig) + dnorm(e, log = TRUE) + log(val)
  }
  ii <- c(which(sd$S == 1)[1:5], which(sd$S == 2)[1:5])
  expect_equal(L$ll_i[ii], vapply(ii, ref, numeric(1)), tolerance = 1e-8)
  ## zero correlations: multinomial logit probability times normal density
  t0 <- thn; t0[unlist(map$index$rho)] <- 0
  L0 <- lik_ns_mnl(se_par_working(map, t0), sd, map)
  lP <- se_mnl_logP(sd$Z, matrix(t0[1:4], 1), sd$base)
  dens <- numeric(sd$n)
  for (j in 1:2) {
    lab <- sd$regimes[j]; sel <- sd$S == j
    dens[sel] <- dnorm(sd$y[sel], sd$X[[lab]][sel, ] %*% t0[map$index$beta[[lab]]],
                       t0[[map$index$sigma[[lab]]]], log = TRUE)
  }
  expect_equal(L0$ll_i, lP[cbind(seq_len(sd$n), sd$S)] + dens, tolerance = 1e-10)
})

test_that("analytic score equals the numerical gradient (G2-NS-1)", {
  skip_if_not_installed("numDeriv")
  for (J in 3:2) {
    o <- sim_ns(400, 3, J = J)
    sd <- se_build_data_multi(o$sp, o$d); map <- se_parmap_multi(sd)
    set.seed(1)
    th <- se_par_working(map, if (J == 3L) par_ns3 else par_ns2) +
      rnorm(map$p, 0, 0.1)
    fl <- function(t) sum(lik_ns_mnl(t, sd, map)$ll_i)
    L <- lik_ns_mnl(th, sd, map, 1L)
    expect_equal(dim(L$score_i), c(sd$n, map$p))
    expect_lt(max(abs(colSums(L$score_i) - numDeriv::grad(fl, th))), 1e-6)
    ## weighted
    w <- runif(sd$n, 0.5, 2)
    flw <- function(t) sum(w * lik_ns_mnl(t, sd, map)$ll_i)
    expect_lt(max(abs(colSums(w * L$score_i) - numDeriv::grad(flw, th))), 1e-6)
  }
  ## differenced Hessian against the numerical Hessian of the log-likelihood
  L2 <- lik_ns_mnl(th, sd, map, 2L)
  Hn <- numDeriv::hessian(fl, th)
  expect_equal(unname(L2$hessian), Hn, tolerance = 1e-4,
               ignore_attr = TRUE)
  expect_equal(L2$hessian, t(L2$hessian))
})

test_that("normal-score model: simulated data follow the model", {
  o <- sim_ns(60000, 9, potential = TRUE)
  d <- o$d
  expect_equal(as.numeric(table(d$regime)) / nrow(d),
               colMeans(exp(se_mnl_logP(
                 cbind(1, d$x1, d$z1, d$z2),
                 matrix(par_ns3[1:8], 2, byrow = TRUE), 1L))),
               tolerance = 0.01)
  ## E[eps_j] = 0 over the population; selected means differ
  po <- as.matrix(d[, paste0(".potential_", c("a", "b", "c"))])
  xb <- cbind(1.0 + 0.5 * d$x1 + 0.2 * d$x2, 1.5 + 0.8 * d$x1 + 0.4 * d$x2,
              2.0 + 0.3 * d$x1 - 0.3 * d$x2)
  expect_lt(max(abs(colMeans(po - xb))), 0.02)
  expect_equal(unname(apply(po - xb, 2, sd)), c(1, 1, 1.2), tolerance = 0.01)
  ## own correlation positive in all three regimes: selected mean above zero
  for (j in 1:3) {
    expect_gt(mean((po - xb)[as.integer(d$regime) == j, j]), 0.05)
  }
})

test_that("normal-score model is refused beyond three regimes", {
  set.seed(2)
  n <- 400
  d <- data.frame(x1 = rnorm(n), z1 = rnorm(n),
                  regime = factor(sample(letters[1:4], n, replace = TRUE)),
                  y = rnorm(n))
  fo <- stats::setNames(rep(list(y ~ x1), 4), letters[1:4])
  expect_error(switch_fit(regime ~ x1 + z1, fo, data = d,
                          model = "multinomial_esr",
                          dependence_structure = "normal_scores"),
               class = "switch_error_unsupported")
})

test_that("boundary rule of the optimiser for the normal-score model", {
  o <- sim_ns(300, 6, J = 2L)
  sd <- se_build_data_multi(o$sp, o$d); map <- se_parmap_multi(sd)
  obj <- se_objective(sd, map)
  expect_true(obj$costly_hessian)
  expect_false(is.null(obj$coarse))
  tw <- se_par_working(map, par_ns2)
  expect_false(obj$at_boundary(tw[obj$free]))
  tb <- par_ns2; tb[map$index$rho[["b"]]] <- c(0.6, 0.798)   # sum r^2 = 0.9968
  expect_true(obj$at_boundary(se_par_working(map, tb)[obj$free]))
  ## coarse and accurate rules agree closely in the interior
  expect_equal(obj$coarse$fn(tw[obj$free]), obj$fn(tw[obj$free]),
               tolerance = 1e-6)
})

test_that("normal-score model: a two-regime fit", {
  skip_on_cran()
  o <- sim_ns(1500, 16, J = 2L, potential = TRUE)
  f <- suppressWarnings(switch_fit(
    regime ~ x1 + z1 + z2, fo_ns2, data = o$d, model = "multinomial_esr",
    dependence_structure = "normal_scores",
    control = switch_control(starts = 1L)))
  expect_s3_class(f, "switch_fit")
  expect_identical(f$map$kind, "ns")
  expect_true(f$convergence$code %in% 0:1)
  expect_identical(f$convergence$path[1], "BFGS")
  th <- coef(f)
  expect_true(all(is.finite(th)))
  for (l in c("a", "b")) expect_lt(sum(th[f$map$index$rho[[l]]]^2), 1)
  ## not below the log-likelihood at the true parameters minus sampling slack
  ll0 <- sum(lik_ns_mnl(se_par_working(f$map, par_ns2), f$data, f$map)$ll_i)
  expect_gt(f$loglik, ll0 - 1e-6)
  if (f$convergence$code == 0L) {
    expect_true(all(is.finite(diag(vcov(f)))))
    expect_length(f$diagnostics$flags$rho_boundary, 0L)
    expect_lt(max(abs(colSums(lik_ns_mnl(f$coef_working, f$data, f$map,
                                         1L)$score_i))), 1e-5)
  } else {
    expect_identical(utils::tail(f$convergence$path, 1), "boundary-stop")
  }
  ## selection and outcome coefficients near the truth
  i <- c(f$map$index$gamma, unlist(f$map$index$beta))
  expect_lt(max(abs(th[i] - par_ns2[i])), 0.35)
  e <- switch_effects(f, effects = c("ATE", "ATT"), se = "none")
  expect_s3_class(e, "switch_effects_multi")
  po <- as.matrix(o$d[, c(".potential_a", ".potential_b")])
  expect_lt(abs(e$table$estimate[e$table$effect == "ATE"] -
                  mean(po[, 2] - po[, 1])), 0.4)
  expect_equal(dim(predict(f, type = "conditional")), c(1500L, 4L))
  s <- switch_simulate(f, o$d, seed = 1)
  expect_equal(nrow(s), 1500L)
  expect_true(all(levels(s$regime) == c("a", "b")))
})
