## Parameter maps (SOFTWARE_ARCHITECTURE.md s.3; PARAMETERIZATION.md s.3)

esr_map <- function(n = 200) se_parmap_esr(se_build_data(esr_spec(), sim_esr_data(n)))

test_that("the ESR parameter map has the documented order and names", {
  m <- esr_map()
  expect_s3_class(m, "se_parmap")
  expect_identical(m$p, 13L)
  expect_identical(m$elements$name, c(
    "selection:(Intercept)", "selection:x1", "selection:z1",
    "regime_0:(Intercept)", "regime_0:x1", "regime_0:x2", "regime_0:sigma",
    "regime_0:rho",
    "regime_1:(Intercept)", "regime_1:x1", "regime_1:x2", "regime_1:sigma",
    "regime_1:rho"))
  expect_identical(m$elements$working_name[c(7, 8, 12, 13)],
                   c("regime_0:log(sigma)", "regime_0:atanh(rho)",
                     "regime_1:log(sigma)", "regime_1:atanh(rho)"))
  expect_identical(m$index$gamma, 1:3)
  expect_identical(m$index$beta$regime_1, 9:11)
  expect_identical(m$index$sigma$regime_0, 7L)
  expect_identical(m$index$rho$regime_1, 13L)
  expect_output(print(m), "13 parameters")
})

test_that("natural and working scales round-trip; Jacobian is diagonal", {
  m <- esr_map()
  th_n <- c(0.5, 0.3, -0.4, 1, 0.5, 0.2, 0.8, 0.4, 1.5, 0.8, 0.4, 1.2, 0.6)
  th_w <- se_par_working(m, th_n)
  expect_equal(unname(th_w[c(7, 8, 12, 13)]),
               c(log(0.8), atanh(0.4), log(1.2), atanh(0.6)))
  expect_equal(unname(se_par_natural(m, th_w)), th_n, tolerance = 1e-12)
  j <- se_par_jacobian(m, th_w)
  expect_equal(unname(j[c(1, 7, 8, 12, 13)]),
               c(1, 0.8, 1 - 0.4^2, 1.2, 1 - 0.6^2), tolerance = 1e-12)
  V <- crossprod(matrix(rnorm(169), 13)) / 13
  Vn <- se_par_vcov_natural(m, th_w, V)
  expect_equal(unname(Vn), diag(unname(j)) %*% V %*% diag(unname(j)),
               tolerance = 1e-12)
  expect_identical(rownames(Vn), m$elements$name)
})

test_that("named natural vectors are matched by name", {
  m <- esr_map()
  th_n <- stats::setNames(seq(0.1, 0.9, length.out = 13) / 2, m$elements$name)
  expect_equal(se_par_working(m, rev(th_n)), se_par_working(m, th_n))
  expect_equal(se_par_working(m, as.list(th_n)), se_par_working(m, th_n))
  expect_error(se_par_working(m, th_n[-1]), "missing",
               class = "switch_error_argument")
  bad <- th_n; names(bad)[1] <- "selection:zz"
  expect_error(se_par_working(m, bad), "unknown", class = "switch_error_argument")
  expect_error(se_par_working(m, 1:3), class = "switch_error_argument")
  bad2 <- th_n; bad2["regime_0:rho"] <- 1
  expect_error(se_par_working(m, bad2), class = "switch_error_domain")
})

test_that("parameters can be fixed for restricted models", {
  m <- se_par_fix(esr_map(), c("regime_0:rho" = 0, "regime_1:rho" = 0))
  expect_identical(sum(m$fixed), 2L)
  expect_identical(se_par_free(m), c(1:7, 9:12))
  full <- se_par_expand(m, seq_len(11) / 10)
  expect_identical(unname(full[c(8, 13)]), c(0, 0))
  expect_equal(unname(se_par_reduce(m, full)), seq_len(11) / 10)
  expect_error(se_par_expand(m, 1:3), class = "switch_error_internal")
  expect_error(se_par_fix(m, c(nope = 0)), class = "switch_error_argument")
  expect_output(print(m), "2 fixed")
})
