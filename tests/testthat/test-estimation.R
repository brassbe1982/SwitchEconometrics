## FIML and two-step estimators, switch_fit() and switch_control()
## (LIKELIHOOD_DERIVATION.md s.7-10; acceptance criterion AC1).

fml <- list(regime_0 = y ~ x1 + x2, regime_1 = y ~ x1 + x2)

test_that("FIML recovers the true parameters and converges properly", {
  skip_on_cran()
  d <- sim_esr_data(5000, seed = 21)
  f <- switch_fit(S ~ x1 + z1, fml, data = d)
  expect_s3_class(f, "switch_fit")
  expect_identical(f$convergence$code, 0L)
  expect_lt(f$convergence$gradient_max, 1e-6)
  expect_true(all(f$diagnostics$hessian_eigen < 0))
  tr <- esr_truth(f$map)
  z <- (coef(f) - tr) / sqrt(diag(vcov(f)))
  expect_lt(max(abs(z)), 4)
})

test_that("FIML equals sampleSelection's ML estimates (AC3 preview)", {
  skip_if_not_installed("sampleSelection")
  d <- sim_esr_data(1500, seed = 9)
  f <- switch_fit(S ~ x1 + z1, fml, data = d)
  ss <- sampleSelection::selection(S ~ x1 + z1, list(y ~ x1 + x2, y ~ x1 + x2),
                                   data = d, method = "ml")
  expect_equal(f$loglik, as.numeric(logLik(ss)), tolerance = 1e-10)
  expect_equal(unname(coef(f)), as.numeric(coef(ss)), tolerance = 1e-6)
  expect_equal(unname(sqrt(diag(vcov(f)))), as.numeric(sqrt(diag(vcov(ss)))),
               tolerance = 1e-5)
})

test_that("two-step coefficients equal sampleSelection's; sigma uses Heckman's formula", {
  skip_if_not_installed("sampleSelection")
  d <- sim_esr_data(2000, seed = 9)
  ts <- switch_fit(S ~ x1 + z1, fml, data = d, method = "two_step")
  ss <- sampleSelection::selection(S ~ x1 + z1, list(y ~ x1 + x2, y ~ x1 + x2),
                                   data = d, method = "2step")
  cs <- coef(ss)
  psi <- ts$two_step$psi
  ## probit, regime-0 coefficients, regime-1 coefficients; the regime-0
  ## correction regressor of sampleSelection is phi/(1 - Phi) = -m0
  expect_equal(unname(psi[1:6]), unname(cs[1:6]), tolerance = 1e-6)
  expect_equal(unname(psi[7]), -unname(cs[7]), tolerance = 1e-6)
  expect_equal(unname(psi[8:11]), unname(cs[10:13]), tolerance = 1e-6)
  ## sigma_j^2 = mean(residual^2) + theta_j^2 mean(delta_j) (Heckman 1979);
  ## sampleSelection 1.2-16 uses (theta_j * mean(delta_j))^2 instead
  ## (BENCHMARK_PROTOCOL.md s.6), so sigma and rho are checked against the
  ## formula, not against sampleSelection
  w <- drop(ts$data$Z %*% psi[1:3])
  for (r in 1:2) {
    sel <- d$S == r - 1
    mm <- if (r == 2) dnorm(w[sel]) / pnorm(w[sel])
          else -dnorm(w[sel]) / pnorm(-w[sel])
    D <- mm * (mm + w[sel])
    fit <- lm(d$y[sel] ~ d$x1[sel] + d$x2[sel] + mm)
    th <- unname(coef(fit)[4])
    s2 <- mean(residuals(fit)^2) + th^2 * mean(D)
    lab <- c("regime_0", "regime_1")[r]
    expect_equal(unname(coef(ts)[paste0(lab, ":sigma")]), sqrt(s2),
                 tolerance = 1e-8)
    expect_equal(unname(coef(ts)[paste0(lab, ":rho")]), th / sqrt(s2),
                 tolerance = 1e-8)
  }
})

test_that("two-step model-based covariance equals the Heckman/Greene formula", {
  d <- sim_esr_data(800, seed = 4)
  ts <- switch_fit(S ~ x1 + z1, fml, data = d, method = "two_step")$two_step
  Z <- cbind(1, d$x1, d$z1)
  pr <- glm(S ~ x1 + z1, family = binomial("probit"), data = d,
            control = glm.control(epsilon = 1e-12))
  ## the probit agrees with glm up to IRLS convergence tolerance; the
  ## covariance formula is then evaluated at the package's first stage so
  ## that the assembly is checked to 1e-8
  expect_equal(unname(ts$psi[1:3]), unname(coef(pr)), tolerance = 1e-6)
  g <- ts$psi[1:3]; w <- drop(Z %*% g)
  Vg <- solve(crossprod(Z * sqrt(dnorm(w)^2 / (pnorm(w) * pnorm(-w)))))
  blk <- list()
  for (r in 1:2) {
    sel <- d$S == r - 1
    m <- if (r == 2) dnorm(w) / pnorm(w) else -dnorm(w) / pnorm(-w)
    D <- (m * (m + w))[sel]
    W <- cbind(1, d$x1, d$x2, m)[sel, ]
    b <- solve(crossprod(W), crossprod(W, d$y[sel]))
    e <- d$y[sel] - W %*% b
    th <- b[4]; s2 <- mean(e^2) + th^2 * mean(D); rho2 <- th^2 / s2
    WWi <- solve(crossprod(W)); WDZ <- crossprod(W * D, Z[sel, ])
    blk[[r]] <- list(V = s2 * WWi %*% (crossprod(W * (1 - rho2 * D), W) +
                                         rho2 * WDZ %*% Vg %*% t(WDZ)) %*% WWi,
                     P = WWi %*% (th * WDZ))
  }
  V <- ts$vcov_psi
  eq <- function(a, b) expect_equal(a, b, tolerance = 1e-8, ignore_attr = TRUE)
  eq(V[1:3, 1:3], Vg)
  eq(V[4:7, 4:7], blk[[1]]$V)
  eq(V[8:11, 8:11], blk[[2]]$V)
  eq(V[8:11, 4:7], blk[[2]]$P %*% Vg %*% t(blk[[1]]$P))
  eq(V[4:7, 1:3], blk[[1]]$P %*% Vg)
  ## natural-scale vcov: beta blocks filled, sigma and rho NA
  f <- switch_fit(S ~ x1 + z1, fml, data = d, method = "two_step")
  expect_true(all(is.na(vcov(f)["regime_0:rho", ])))
  expect_equal(unname(vcov(f)[4:6, 4:6]), unname(V[4:6, 4:6]))
  ## robust and model-based standard errors agree under a correct model
  fr <- switch_fit(S ~ x1 + z1, fml, data = d, method = "two_step",
                   vcov = "sandwich")
  ratio <- sqrt(diag(fr$two_step$vcov_psi)) / sqrt(diag(V))
  expect_true(all(ratio > 0.8 & ratio < 1.25))
})

test_that("frequency weights equal replicated data", {
  d <- sim_esr_data(300, seed = 13)
  set.seed(3)
  d$k <- sample(1:3, nrow(d), replace = TRUE)
  rep_d <- d[rep(seq_len(nrow(d)), d$k), ]
  fw <- switch_fit(S ~ x1 + z1, fml, data = d, weights = ~ k)
  fr <- switch_fit(S ~ x1 + z1, fml, data = rep_d)
  expect_identical(fw$vcov_type, "sandwich")
  expect_equal(fw$loglik, fr$loglik, tolerance = 1e-9)
  expect_equal(coef(fw), coef(fr), tolerance = 1e-6)
  tw <- switch_fit(S ~ x1 + z1, fml, data = d, weights = ~ k,
                   method = "two_step")
  tr <- switch_fit(S ~ x1 + z1, fml, data = rep_d, method = "two_step")
  ## equal up to the probit's IRLS convergence tolerance
  expect_equal(coef(tw), coef(tr), tolerance = 1e-6)
  expect_warning(switch_fit(S ~ x1 + z1, fml, data = d, weights = ~ k,
                            vcov = "hessian"), class = "switch_warning_vcov")
})

test_that("covariance types and clusters", {
  d <- sim_esr_data(600, seed = 5)
  fh <- switch_fit(S ~ x1 + z1, fml, data = d)
  fo <- switch_fit(S ~ x1 + z1, fml, data = d, vcov = "opg")
  fs <- switch_fit(S ~ x1 + z1, fml, data = d, vcov = "sandwich")
  fc <- switch_fit(S ~ x1 + z1, fml, data = d, cluster = ~ cl)
  expect_identical(fc$vcov_type, "cluster")
  expect_equal(coef(fh), coef(fc))
  for (f in list(fo, fs, fc)) {
    r <- sqrt(diag(vcov(f))) / sqrt(diag(vcov(fh)))
    expect_true(all(is.finite(r) & r > 0.5 & r < 2))
  }
  expect_false(isTRUE(all.equal(vcov(fh), vcov(fs))))
  tc <- switch_fit(S ~ x1 + z1, fml, data = d, cluster = "cl",
                   method = "two_step")
  expect_identical(tc$two_step$vcov_type, "cluster")
  expect_error(switch_fit(S ~ x1 + z1, fml, data = d, vcov = "cluster"),
               class = "switch_error_argument")
  expect_error(switch_fit(S ~ x1 + z1, fml, data = d, vcov = "opg",
                          method = "two_step"), class = "switch_error_argument")
})

test_that("specification objects, synonyms and argument errors", {
  d <- sim_esr_data(400, seed = 6)
  spec <- switch_model(S ~ x1 + z1, fml)
  f1 <- switch_fit(model = spec, data = d)
  f2 <- switch_fit(S ~ x1 + z1, fml, data = d)
  f3 <- switch_fit(model = spec, data = d, estimator = "fiml")
  f4 <- esr(S ~ x1 + z1, fml, data = d)
  expect_identical(coef(f1), coef(f2))
  expect_identical(coef(f3), coef(f2))
  expect_identical(coef(f4), coef(f2))
  t1 <- switch_fit(model = spec, data = d, estimator = "two_step")
  expect_identical(t1$method, "two_step")
  expect_error(switch_fit(model = spec, data = d, method = "fiml",
                          estimator = "two_step"),
               class = "switch_error_argument")
  expect_error(switch_fit(S ~ x1 + z1, fml, data = d, model = spec),
               class = "switch_error_argument")
  expect_error(switch_fit(data = d), class = "switch_error_argument")
  expect_error(switch_fit(S ~ x1 + z1, fml, data = d, foo = 1),
               "unused argument", class = "switch_error_argument")
  expect_error(switch_fit(S ~ x1 + z1, fml, data = d, copula_df = 5),
               "Generation 3", class = "switch_error_unsupported")
  expect_error(switch_fit(S ~ x1 + z1, fml, data = d, method = "robust"),
               "Generation 4", class = "switch_error_unsupported")
  expect_error(switch_fit(S ~ x1 + z1, fml, data = d, control = list()),
               class = "switch_error_argument")
})

test_that("multistart is reproducible, agrees and restores the RNG", {
  d <- sim_esr_data(500, seed = 8)
  set.seed(42); a <- runif(1)
  set.seed(42)
  f1 <- switch_fit(S ~ x1 + z1, fml, data = d,
                   control = switch_control(starts = 6))
  b <- runif(1)
  expect_identical(a, b)
  f2 <- switch_fit(S ~ x1 + z1, fml, data = d,
                   control = switch_control(starts = 6))
  expect_identical(coef(f1), coef(f2))
  st <- f1$starts
  expect_identical(nrow(st), 6L)
  expect_identical(st$origin[1], "two_step")
  conv <- st$code == 0L
  expect_true(all(conv))
  expect_lt(max(st$max_abs_diff[conv]), 1e-4)
  expect_identical(sum(st$best), 1L)
  f10 <- switch_fit(S ~ x1 + z1, fml, data = d,
                    control = switch_control(starts = 10))
  expect_true(any(grepl("^grid", f10$starts$origin)))
})

test_that("user starting values come first", {
  d <- sim_esr_data(400, seed = 2)
  m <- switch_model(S ~ x1 + z1, fml)
  tr <- esr_truth(se_parmap_esr(se_build_data(m, d)))
  f <- switch_fit(model = m, data = d,
                  control = switch_control(starts = 1, start = tr))
  expect_identical(f$starts$origin, c("user", "two_step"))
  expect_equal(f$record$start, tr)
})

test_that("failures and boundary solutions are reported, never silent", {
  d <- sim_esr_data(400, seed = 3)
  expect_warning(f <- switch_fit(S ~ x1 + z1, fml, data = d,
                                 control = switch_control(maxit = 1,
                                                          starts = 1)),
                 class = "switch_warning_convergence")
  expect_false(f$convergence$code == 0L)
  expect_warning(switch_fit(S ~ x1 + z1, fml, data = d,
                            control = switch_control(boundary_rho = 0.2)),
                 class = "switch_warning_boundary")
})

test_that("accessor methods and the reproducibility record", {
  d <- sim_esr_data(400, seed = 12)
  f <- switch_fit(S ~ x1 + z1, fml, data = d)
  expect_length(coef(f), 13L)
  expect_named(coef(f, part = "selection"),
               c("selection:(Intercept)", "selection:x1", "selection:z1"))
  expect_named(coef(f, part = "ancillary"),
               c("regime_0:sigma", "regime_0:rho", "regime_1:sigma",
                 "regime_1:rho"))
  expect_length(coef(f, part = "regime_1"), 5L)
  expect_equal(unname(coef(f, "working")["regime_1:atanh(rho)"]),
               atanh(unname(coef(f)["regime_1:rho"])))
  expect_error(coef(f, part = "nope"), class = "switch_error_argument")
  expect_identical(dim(vcov(f)), c(13L, 13L))
  expect_identical(dim(vcov(f, "working", part = "selection")), c(3L, 3L))
  ll <- logLik(f)
  expect_s3_class(ll, "logLik")
  expect_identical(attr(ll, "df"), 13L)
  expect_identical(nobs(f), 400L)
  expect_equal(AIC(f), -2 * f$loglik + 26)
  expect_output(print(f), "Endogenous switching regression")
  expect_output(print(f), "converged")
  rec <- f$record
  expect_true(all(c("date", "R", "packages", "control", "seed", "start",
                    "optimizer", "data", "sample_index", "integration") %in%
                    names(rec)))
  expect_identical(rec$integration, "analytic")
  t2 <- switch_fit(S ~ x1 + z1, fml, data = d, method = "two_step")
  expect_true(is.na(logLik(t2)))
  expect_error(coef(t2, "working"), class = "switch_error_argument")
  expect_output(print(t2), "two-step")
  fk <- switch_fit(S ~ x1 + z1, fml, data = d,
                   control = switch_control(keep_data = FALSE))
  expect_null(fk$data)
  expect_false(is.null(fk$terms))
})

test_that("switch_control validates its arguments", {
  expect_s3_class(switch_control(), "switch_control")
  expect_error(switch_control(starts = 0), class = "switch_error_argument")
  expect_error(switch_control(maxit = 2.5), class = "switch_error_argument")
  expect_error(switch_control(gradient_tolerance = -1),
               class = "switch_error_argument")
  expect_error(switch_control(boundary_rho = 1.5),
               class = "switch_error_argument")
  expect_error(switch_control(seed = "a"), class = "switch_error_argument")
  expect_error(switch_control(keep_data = NA), class = "switch_error_argument")
  expect_error(switch_control(optimizer = "nope"))
})

test_that("a known slow Newton-Raphson path converges quickly (regression)", {
  ## Monte Carlo smoke cell 2, replication 40 (WP1.4): with maxNR's default
  ## step halving this fit stalled for 500 iterations (91 s)
  old_kind <- RNGkind()
  on.exit({ RNGkind(old_kind[1], old_kind[2], old_kind[3]); set.seed(NULL) })
  RNGkind("L'Ecuyer-CMRG"); set.seed(20261122)
  s <- .Random.seed
  for (j in 1:2) s <- parallel::nextRNGStream(s)
  for (r in 1:40) s <- parallel::nextRNGSubStream(s)
  assign(".Random.seed", s, envir = globalenv())
  N <- 1000
  x1 <- rnorm(N); x2 <- rnorm(N); z1 <- rnorm(N); u <- rnorm(N)
  e1 <- 0.6 * u + sqrt(1 - 0.36) * rnorm(N)
  e0 <- 0.4 * u + sqrt(1 - 0.16) * rnorm(N)
  S <- as.integer(0.5 + 0.3 * x1 - 0.4 * z1 + u > 0)
  y <- ifelse(S == 1, 1.5 + 0.8 * x1 + 0.4 * x2 + e1,
              1 + 0.5 * x1 + 0.2 * x2 + e0)
  d <- data.frame(S, y, x1, x2, z1)
  t0 <- proc.time()[["elapsed"]]
  f <- switch_fit(S ~ x1 + z1, fml, data = d,
                  control = switch_control(starts = 1))
  expect_identical(f$convergence$code, 0L)
  expect_lt(f$convergence$iterations, 50L)
  expect_lt(proc.time()[["elapsed"]] - t0, 10)
  expect_equal(f$loglik, -1844.906632, tolerance = 1e-9)
})

test_that("fallback starting values and optimisers work", {
  E <- esr_setup(400, seed = 4)
  th <- est_naive_start(E$sd, E$map)
  expect_identical(unname(th[unlist(E$map$index$rho)]), c(0, 0))
  ctl <- switch_control()
  obj <- se_objective(E$sd, E$map)
  for (m in c("BFGS", "BHHH", "optim")) {
    r <- se_optimize(obj, th, switch_control(optimizer = m))
    expect_identical(r$check$code, 0L, info = m)
    expect_identical(r$path[1], m)
  }
})
