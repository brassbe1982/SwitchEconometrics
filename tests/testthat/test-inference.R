## Tests, intervals, summaries, bootstrap, identification checks and
## diagnostics (WP1.5; LIKELIHOOD_DERIVATION.md s.7-8; IDENTIFICATION.md s.4).

fml <- list(regime_0 = y ~ x1 + x2, regime_1 = y ~ x1 + x2)
fit_cache <- new.env()
get_fit <- function(method = "fiml", n = 1000, seed = 3) {
  key <- paste(method, n, seed)
  if (is.null(fit_cache[[key]])) {
    fit_cache[[key]] <- switch_fit(S ~ x1 + z1, fml,
                                   data = sim_esr_data(n, seed = seed),
                                   method = method)
  }
  fit_cache[[key]]
}

test_that("the LR test of independence equals the closed-form restricted fit", {
  f <- get_fit()
  d <- sim_esr_data(1000, seed = 3)
  pr <- glm(S ~ x1 + z1, family = binomial("probit"), data = d,
            control = glm.control(epsilon = 1e-14))
  llr <- as.numeric(logLik(pr)) +
    as.numeric(logLik(lm(y ~ x1 + x2, d, subset = S == 0))) +
    as.numeric(logLik(lm(y ~ x1 + x2, d, subset = S == 1)))
  t <- switch_test(f)
  expect_s3_class(t, "switch_test")
  expect_equal(t$loglik_restricted, llr, tolerance = 1e-9)
  expect_equal(t$statistic, 2 * (f$loglik - llr), tolerance = 1e-7)
  expect_identical(t$df, 2L)
  expect_equal(t$p_value, pchisq(t$statistic, 2, lower.tail = FALSE))
  expect_lt(t$p_value, 0.01)                       # rho = 0.6 / 0.4 in the data
  expect_output(print(t), "Likelihood-ratio test")
  expect_error(switch_test(get_fit("two_step")), class = "switch_error_argument")
  fk <- switch_fit(S ~ x1 + z1, fml, data = d,
                   control = switch_control(keep_data = FALSE))
  expect_error(switch_test(fk), "keep_data", class = "switch_error_argument")
  dw <- d; dw$w <- runif(nrow(d), 0.5, 2)
  fw <- switch_fit(S ~ x1 + z1, fml, data = dw, weights = ~ w)
  expect_warning(switch_test(fw), class = "switch_warning_test")
})

test_that("Wald tests of independence (FIML and two-step)", {
  f <- get_fit()
  i <- c("regime_0:rho", "regime_1:rho")
  th <- coef(f)[i]
  w <- drop(t(th) %*% solve(vcov(f)[i, i], th))
  t <- switch_test(f, "wald_independence")
  expect_equal(t$statistic, w)
  expect_identical(t$df, 2L)
  ts <- get_fit("two_step")
  t2 <- switch_test(ts, "wald_independence")
  ii <- c("regime_0:lambda", "regime_1:lambda")
  lam <- ts$two_step$psi[ii]
  expect_equal(t2$statistic,
               drop(t(lam) %*% solve(ts$two_step$vcov_psi[ii, ii], lam)))
})

test_that("general linear Wald hypotheses are parsed correctly", {
  f <- get_fit()
  nm <- names(coef(f))
  t1 <- switch_test(f, "wald", hypothesis = "regime_1:x1 = regime_0:x1")
  R <- matrix(0, 1, length(nm))
  R[1, match("regime_1:x1", nm)] <- 1
  R[1, match("regime_0:x1", nm)] <- -1
  t2 <- switch_test(f, "wald", hypothesis = list(R = R, r = 0))
  expect_equal(t1$statistic, t2$statistic)
  d <- coef(f)["regime_1:x1"] - coef(f)["regime_0:x1"]
  v <- drop(R %*% vcov(f) %*% t(R))
  expect_equal(t1$statistic, unname(d^2 / v))
  t3 <- switch_test(f, "wald", hypothesis = c("2*regime_1:x1 - regime_0:x1 = 1",
                                              "regime_1:rho = 0.5"))
  expect_identical(t3$df, 2L)
  expect_equal(unname(t3$R[1, match(c("regime_1:x1", "regime_0:x1"), nm)]),
               c(2, -1))
  expect_equal(t3$r, c(1, 0.5))
  expect_error(switch_test(f, "wald", hypothesis = "regime_1:x1 * regime_0:x1 = 0"),
               "not linear", class = "switch_error_argument")
  expect_error(switch_test(f, "wald", hypothesis = "nothing = 0"),
               "names no parameter", class = "switch_error_argument")
  expect_error(switch_test(f, "wald", hypothesis = "regime_1:x1 = 0 = 1"),
               class = "switch_error_argument")
  expect_error(switch_test(f, "wald", hypothesis = c("regime_1:x1 = 0",
                                                     "2*regime_1:x1 = 0")),
               "dependent", class = "switch_error_argument")
  expect_error(switch_test(f, "wald"), class = "switch_error_argument")
  expect_error(switch_test(get_fit("two_step"), "wald",
                           hypothesis = "regime_1:rho = 0"),
               "bootstrap", class = "switch_error_argument")
})

test_that("confidence intervals respect the parameter space", {
  f <- get_fit()
  ci <- confint(f)
  z <- qnorm(0.975)
  k <- match("regime_1:rho", rownames(ci))
  aw <- coef(f, "working")[k]
  sw <- sqrt(vcov(f, "working")[k, k])
  expect_equal(unname(ci[k, ]), unname(tanh(aw + c(-1, 1) * z * sw)))
  expect_true(all(abs(ci[grepl("rho", rownames(ci)), ]) < 1))
  ks <- match("regime_0:sigma", rownames(ci))
  expect_equal(unname(ci[ks, ]),
               unname(exp(coef(f, "working")[ks] + c(-1, 1) * z *
                            sqrt(vcov(f, "working")[ks, ks]))))
  cn <- confint(f, type = "natural-wald")
  se <- sqrt(diag(vcov(f)))
  expect_equal(unname(cn[, 2] - coef(f)), unname(z * se))
  expect_equal(ci[1:6, ], cn[1:6, ])
  expect_identical(rownames(confint(f, "selection:z1")), "selection:z1")
  expect_identical(dim(confint(f, 1:2, level = 0.9)), c(2L, 2L))
  expect_error(confint(f, "nope"), class = "switch_error_argument")
  ct <- confint(get_fit("two_step"))
  expect_true(all(is.na(ct["regime_1:rho", ])))
  expect_false(anyNA(ct["regime_1:x1", ]))
})

test_that("summaries print complete tables", {
  f <- get_fit()
  s <- summary(f)
  expect_s3_class(s, "summary.switch_fit")
  expect_named(s$coefficients, c("selection", "regime_0", "regime_1"))
  expect_identical(colnames(s$coefficients$selection),
                   c("Estimate", "Std. Error", "z value", "Pr(>|z|)"))
  expect_equal(s$aic, AIC(f))
  expect_equal(s$bic, BIC(f))
  expect_s3_class(s$tests$lr, "switch_test")
  out <- capture.output(print(s))
  expect_true(any(grepl("Selection equation", out)))
  expect_true(any(grepl("LR test", out)))
  expect_true(any(grepl("Disturbance parameters", out)))
  st <- summary(get_fit("two_step"))
  expect_false(is.null(st$lambda))
  expect_output(print(st), "Selection-correction coefficients")
})

test_that("the bootstrap is reproducible and restores the RNG", {
  f <- get_fit(n = 600, seed = 7)
  kind0 <- RNGkind()
  set.seed(99); a <- runif(3)
  set.seed(99)
  b1 <- switch_bootstrap(f, R = 20, seed = 11)
  expect_identical(runif(3), a)
  expect_identical(RNGkind(), kind0)
  b2 <- switch_bootstrap(f, R = 20, seed = 11)
  expect_identical(b1$replicates, b2$replicates)
  expect_s3_class(b1, "switch_bootstrap")
  expect_identical(b1$successful, 20L)
  expect_identical(dim(vcov(b1)), c(13L, 13L))
  expect_identical(dim(confint(b1)), c(13L, 2L))
  expect_identical(dim(confint(b1, type = "normal")), c(13L, 2L))
  expect_error(confint(b1, level = 0.9), class = "switch_error_argument")
  expect_output(print(b1), "Bootstrap of a FIML fit")
  expect_error(switch_bootstrap(f, R = 1), class = "switch_error_argument")
  expect_error(switch_bootstrap(f, statistics = "effects"),
               class = "switch_error_argument")
})

test_that("parametric and cluster bootstraps; two-step sigma and rho get SEs", {
  ts <- get_fit("two_step", n = 600, seed = 7)
  bp <- switch_bootstrap(ts, R = 25, type = "parametric", seed = 3)
  expect_true(all(is.finite(bp$se)))
  expect_true(all(bp$se[c("regime_0:rho", "regime_1:rho")] > 0))
  d <- sim_esr_data(600, seed = 7)
  fc <- switch_fit(S ~ x1 + z1, fml, data = d, cluster = ~ cl,
                   method = "two_step")
  bc <- switch_bootstrap(fc, R = 15, seed = 4)
  expect_true(bc$clustered)
  expect_identical(bc$n_clusters, length(unique(d$cl)))
  bu <- switch_bootstrap(fc, R = 15, seed = 4, cluster = FALSE)
  expect_false(bu$clustered)
})

test_that("bootstrap failures are counted and reported", {
  d <- sim_esr_data(300, seed = 5)
  d$rare <- 0
  d$rare[which(d$S == 1)[1]] <- 1             # one observation: ~37% of
                                              # resamples omit it
  f <- switch_fit(S ~ x1 + z1, list(y ~ x1, y ~ x1 + rare), data = d,
                  method = "two_step")
  expect_warning(b <- switch_bootstrap(f, R = 40, seed = 1),
                 class = "switch_warning_bootstrap")
  expect_gt(b$failures$n, 0L)
  expect_true("rank" %in% names(b$failures$reasons))
  expect_identical(b$successful + b$failures$n, 40L)
})

test_that("bootstrap standard errors agree with the Hessian (local)", {
  skip_on_cran()
  f <- get_fit(n = 1000, seed = 3)
  b <- switch_bootstrap(f, R = 200, seed = 8)
  r <- b$se / sqrt(diag(vcov(f)))
  expect_true(all(r > 0.75 & r < 1.33))
})

test_that("parallel bootstrap equals serial bootstrap", {
  skip_if(Sys.getenv("_R_CHECK_PACKAGE_NAME_") == "",
          "needs the installed package (runs under R CMD check)")
  f <- get_fit(n = 400, seed = 2)
  b1 <- switch_bootstrap(f, R = 6, seed = 5, cores = 1)
  b2 <- switch_bootstrap(f, R = 6, seed = 5, cores = 2)
  expect_equal(b1$replicates, b2$replicates)
})

test_that("identification checks on a specification with data", {
  d <- sim_esr_data(800, seed = 4)
  v <- switch_validate(switch_model(S ~ x1 + z1, fml), d)
  expect_s3_class(v, "switch_validation")
  expect_false(v$fitted)
  expect_true(all(paste0("I", 1:11) %in% v$table$code))
  expect_true(all(v$table$status[v$table$code %in% c("I1", "I2", "I4")] == "ok"))
  expect_identical(v$table$status[v$table$code == "I10"], "note")
  expect_identical(unique(v$table$status[v$table$code %in% c("I8", "I9")]),
                   "skipped")
  expect_output(print(v), "Identification checks")
  ## no exclusion: functional-form warning and classification
  v0 <- switch_validate(switch_model(S ~ x1 + x2, fml), d)
  expect_true(all(v0$table$status[v0$table$code == "I4"] == "warning"))
  expect_true(any(grepl("normality", v0$classification$identified_by)))
  ## irrelevant exclusion: I5 warning
  dw <- sim_esr_data(800, seed = 4, gz = 0)
  vw <- switch_validate(switch_model(S ~ x1 + z1, fml), dw)
  expect_true(all(vw$table$status[vw$table$code == "I5"] == "warning"))
  ## rank problems and data errors are reported, not thrown
  d$x3 <- d$x1
  vr <- switch_validate(switch_model(S ~ x1 + z1, list(y ~ x1 + x3, y ~ x1)), d)
  expect_true(any(vr$table$code == "I1" & vr$table$status == "error"))
  ve <- switch_validate(switch_model(S ~ x1 + nothere, fml), d)
  expect_identical(ve$table$code, "I0")
  expect_error(switch_validate(switch_model(S ~ x1 + z1, fml)),
               class = "switch_error_argument")
})

test_that("identification checks on fitted models; functional-form warning", {
  f <- get_fit()
  v <- switch_validate(f)
  expect_true(v$fitted)
  expect_identical(v$table$status[v$table$code == "I9"], "ok")
  expect_match(v$table$value[v$table$code == "I11"], "admissible range")
  expect_s3_class(f$identification, "switch_validation")
  d <- sim_esr_data(800, seed = 4)
  ws <- list()
  withCallingHandlers(switch_fit(S ~ x1 + x2, fml, data = d),
                      warning = function(w) {
                        ws[[length(ws) + 1L]] <<- w
                        invokeRestart("muffleWarning")
                      })
  expect_length(ws, 2L)                          # one per regime
  expect_true(all(vapply(ws, inherits, logical(1),
                         "switch_warning_identification")))
})

test_that("diagnostics separate computational and statistical parts", {
  f <- get_fit()
  dg <- switch_diagnostics(f)
  expect_s3_class(dg, "switch_diagnostics")
  expect_named(dg, c("computational", "statistical"))
  expect_true(all(dg$computational$hessian_eigen_range < 0))
  expect_s3_class(dg$statistical$lr, "switch_test")
  out <- capture.output(print(dg))
  expect_true(any(grepl("Computational diagnostics", out)))
  expect_true(any(grepl("not identified", out)))
  expect_output(print(switch_diagnostics(get_fit("two_step"))),
                "Statistical diagnostics")
})
