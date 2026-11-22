## Stable normal quantities (NUMERICAL_METHODS.md s.2; verify_math.R V09-V11)

test_that("log Phi and the Mills ratio agree with direct formulas", {
  a <- seq(-6, 6, by = 0.25)
  expect_equal(se_log_Phi(a), log(pnorm(a)), tolerance = 1e-12)
  expect_equal(se_log_Phi(a, lower.tail = FALSE), log(pnorm(-a)),
               tolerance = 1e-12)
  expect_equal(se_mills(a), dnorm(a) / pnorm(a), tolerance = 1e-12)
})

test_that("the Mills ratio is finite and inside its bounds far in the tail", {
  a <- seq(-40, -5, by = 0.25)
  l <- se_mills(a)
  expect_true(all(is.finite(l)))
  expect_true(all(l > -a & l < -a - 1 / a))
})

test_that("delta equals minus the derivative of the Mills ratio", {
  skip_if_not_installed("numDeriv")
  a <- c(seq(-40, -5, by = 2.5), -4.9, -3, -1, 0, 1, 3, 6)
  dl <- vapply(a, function(x) numDeriv::grad(se_mills, x), numeric(1))
  expect_lt(max(abs(se_delta(a) + dl) / abs(dl)), 1e-6)
})

test_that("delta lies in (0, 1), with the correct limits", {
  a <- seq(-50, 30, by = 0.5)
  d <- se_delta(a)
  expect_true(all(d > 0 & d < 1))
  expect_identical(se_delta(c(-Inf, Inf)), c(1, 0))
  expect_true(is.na(se_delta(NA_real_)))
})

test_that("generated regressors have dm_k/dw = -delta_k", {
  skip_if_not_installed("numDeriv")
  w <- c(-12, -8, -3, -1, 0, 0.7, 2, 5, 9, 12)
  g1 <- vapply(w, function(x) numDeriv::grad(se_m1, x), numeric(1))
  g0 <- vapply(w, function(x) numDeriv::grad(se_m0, x), numeric(1))
  expect_lt(max(abs(g1 + se_d1(w)) / pmax(1, se_d1(w))), 1e-7)
  expect_lt(max(abs(g0 + se_d0(w)) / pmax(1, se_d0(w))), 1e-7)
  ## population identity Phi m1 + (1 - Phi) m0 = 0
  expect_equal(pnorm(w) * se_m1(w) + pnorm(-w) * se_m0(w), rep(0, length(w)),
               tolerance = 1e-12)
})
