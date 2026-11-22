## Parameter transformations (PARAMETERIZATION.md; verify_math.R V18)

test_that("scalar transformations round-trip", {
  w <- c(-3, -0.4, 0, 0.7, 2.5)
  for (nm in c("identity", "log", "atanh", "log_shift2")) {
    tr <- se_transform(nm)
    expect_s3_class(tr, "se_transform")
    expect_equal(tr$to_working(tr$to_natural(w)), w, tolerance = 1e-12,
                 info = nm)
  }
  expect_equal(se_transform("log")$to_natural(0), 1)
  expect_equal(se_transform("atanh")$to_natural(atanh(0.6)), 0.6)
  expect_equal(se_transform("log_shift2")$to_natural(log(3)), 5)
})

test_that("first and second derivatives match numerical derivatives", {
  skip_if_not_installed("numDeriv")
  w <- c(-2.2, -0.5, 0, 0.3, 1.8)
  for (nm in c("identity", "log", "atanh", "log_shift2")) {
    tr <- se_transform(nm)
    n1 <- vapply(w, function(x) numDeriv::grad(tr$to_natural, x), numeric(1))
    n2 <- vapply(w, function(x) numDeriv::grad(tr$d1, x), numeric(1))
    expect_equal(tr$d1(w), n1, tolerance = 1e-8, info = nm)
    expect_equal(tr$d2(w), n2, tolerance = 1e-7, info = nm)
  }
})

test_that("values outside the natural domain are refused", {
  expect_error(se_transform("log")$to_working(c(1, -1)),
               class = "switch_error_domain")
  expect_error(se_transform("atanh")$to_working(1),
               class = "switch_error_domain")
  expect_error(se_transform("log_shift2")$to_working(2),
               class = "switch_error_domain")
  expect_error(se_transform("nope"))
})

test_that("CPC construction always gives a valid correlation matrix", {
  set.seed(3)
  for (d in 2:6) {
    for (k in 1:5) {
      a <- rnorm(d * (d - 1) / 2, 0, 1.5)
      R <- se_corr_from_cpc(a, d)
      expect_true(se_check_corr(R))
      expect_equal(se_cpc_from_corr(R), a, tolerance = 1e-9)
    }
  }
  expect_equal(se_corr_from_cpc(atanh(0.3), 2)[1, 2], 0.3)
  expect_equal(se_corr_from_cpc(numeric(0), 1), matrix(1, 1, 1))
  expect_error(se_corr_from_cpc(1:2, 3), class = "switch_error_argument")
})

test_that("complex-step Jacobian of the correlation map is exact", {
  skip_if_not_installed("numDeriv")
  set.seed(4)
  for (d in 2:5) {
    a <- rnorm(d * (d - 1) / 2)
    Jc <- se_corr_jacobian(a, d)
    Jn <- numDeriv::jacobian(function(x) {
      R <- se_corr_from_cpc(x, d); R[upper.tri(R)] }, a)
    expect_equal(Jc, Jn, tolerance = 1e-8)
  }
})

test_that("invalid correlation matrices are refused", {
  expect_error(se_check_corr(matrix(c(1, 1.2, 1.2, 1), 2)),
               class = "switch_error_domain")
  expect_error(se_check_corr(matrix(c(2, 0, 0, 1), 2)),
               class = "switch_error_domain")
  expect_error(se_check_corr(matrix(c(1, 0.2, 0.3, 1), 2)),
               class = "switch_error_domain")
  expect_error(se_check_corr(matrix(1:6, 2)), class = "switch_error_domain")
})

test_that("covariance from correlation and standard deviations", {
  R <- se_corr_from_cpc(c(0.2, -0.4, 0.5), 3)
  sd <- c(1, 2, 0.5)
  expect_equal(se_cov_from_corr(R, sd), diag(sd) %*% R %*% diag(sd))
})
