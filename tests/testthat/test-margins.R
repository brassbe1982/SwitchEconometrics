## Distribution engine and the Gaussian margin (specification s.5.3)

test_that("the Gaussian distribution matches the stats functions", {
  g <- distribution("gaussian", list(location = 1, scale = 2))
  expect_s3_class(g, "se_distribution")
  x <- c(-3, 0, 1, 4.5)
  expect_equal(g$pdf(x), dnorm(x, 1, 2))
  expect_equal(g$cdf(x), pnorm(x, 1, 2))
  expect_equal(g$cdf(x, lower.tail = FALSE), pnorm(x, 1, 2, lower.tail = FALSE))
  expect_equal(g$quantile(c(0.1, 0.5, 0.975)), qnorm(c(0.1, 0.5, 0.975), 1, 2))
  expect_equal(g$logpdf(x), dnorm(x, 1, 2, log = TRUE))
  expect_equal(g$logcdf(-60), pnorm(-60, 1, 2, log.p = TRUE))
  expect_true(is.finite(g$logcdf(-80)))
  set.seed(5); a <- g$rng(4)
  set.seed(5); expect_identical(a, rnorm(4, 1, 2))
  expect_equal(g$cdf(g$quantile(c(0.01, 0.3, 0.99))), c(0.01, 0.3, 0.99))
})

test_that("defaults and parameter checks", {
  g <- distribution("gaussian")
  expect_identical(g$parameters, list(location = 0, scale = 1))
  expect_output(print(g), "gaussian")
  expect_error(distribution("gaussian", list(sd = 1)),
               class = "switch_error_argument")
  expect_error(distribution("gaussian", list(scale = 0)),
               class = "switch_error_domain")
  expect_error(distribution("gaussian", list(scale = NA_real_)),
               class = "switch_error_argument")
  expect_error(distribution("gaussian", list(1, 2)),
               class = "switch_error_argument")
  expect_error(distribution("student_t"), class = "switch_error_unsupported")
  expect_error(distribution("student_t"), "Generation 3")
  expect_error(distribution("cauchy"), class = "switch_error_argument")
})

test_that("Gaussian log-density and log-cdf derivatives (working scale)", {
  skip_if_not_installed("numDeriv")
  m <- se_margin_gaussian()
  x <- c(-2.5, -0.3, 0.8, 3.1)
  w0 <- c(0.4, log(1.7))                       # (location, log scale)
  par_of <- function(w) list(location = w[1], scale = exp(w[2]))
  ga <- m$grad_logd(x, par_of(w0))
  gn <- t(vapply(x, function(xx) numDeriv::grad(function(w)
    m$logd(xx, par_of(w)), w0), numeric(2)))
  expect_equal(unname(ga), gn, tolerance = 1e-8)
  expect_identical(colnames(ga), c("location", "log(scale)"))
  for (lt in c(TRUE, FALSE)) {
    ga <- m$grad_logp(x, par_of(w0), lower.tail = lt)
    gn <- t(vapply(x, function(xx) numDeriv::grad(function(w)
      m$logp(xx, par_of(w), lower.tail = lt), w0), numeric(2)))
    expect_equal(unname(ga), gn, tolerance = 1e-8, info = lt)
  }
})

test_that("the margin object satisfies the interface contract", {
  m <- se_margin_gaussian()
  expect_s3_class(m, "se_margin")
  expect_identical(m$parameters$transform, c("identity", "log"))
  bad <- m; bad$logp <- NULL
  expect_error(validate_se_margin(bad), class = "switch_error_internal")
})
