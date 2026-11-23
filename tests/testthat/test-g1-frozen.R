## Generation 1 results are frozen at version 1.0.0: every later version must
## reproduce them at 1e-8 (handoff rule; SOFTWARE_ARCHITECTURE.md s.7.1).

test_that("the 1.0.0 results on firms are reproduced at 1e-8", {
  skip_on_cran()                       # 9 fits; the rule is enforced in CI
  ref <- readRDS(test_path("fixtures", "g1_frozen_1.0.0.rds"))
  now <- g1_frozen_results()
  expect_identical(ref$version, "1.0.0")
  expect_identical(now$code, ref$code)
  keys <- setdiff(names(ref), c("version", "R", "code", "gradient_max",
                                "fixed", "effects", "effects_by"))
  expect_true(all(keys %in% names(now)))
  for (k in keys) {
    expect_equal(now[[k]], ref[[k]], tolerance = 1e-8, info = k)
  }
  for (k in names(ref$fixed)) {
    expect_equal(now$fixed[[k]], ref$fixed[[k]], tolerance = 1e-10,
                 info = paste("fixed", k))
  }
  expect_identical(now$effects$effect, ref$effects$effect)
  expect_identical(now$effects_by$group, ref$effects_by$group)
  for (k in c("estimate", "std_error", "lower", "upper")) {
    expect_equal(now$effects[[k]], ref$effects[[k]], tolerance = 1e-8,
                 info = paste("effects", k))
  }
  for (k in c("estimate", "std_error")) {
    expect_equal(now$effects_by[[k]], ref$effects_by[[k]], tolerance = 1e-8,
                 info = paste("effects_by", k))
  }
})

test_that("the likelihood at a fixed point equals the 1.0.0 value (runs on CRAN)", {
  ref <- readRDS(test_path("fixtures", "g1_frozen_1.0.0.rds"))
  fit <- esr(digital_adoption ~ internet_access + management_quality +
               firm_size + owner_education,
             list(regime_0 = productivity ~ firm_size + capital + labour,
                  regime_1 = productivity ~ firm_size + capital + labour),
             data = firms)
  L <- loglik_switch(ref$fixed$theta, fit$data, fit$map, deriv = 2L)
  expect_equal(L$loglik, ref$fixed$loglik, tolerance = 1e-12)
  expect_equal(L$gradient, ref$fixed$gradient, tolerance = 1e-10)
  expect_equal(L$hessian, ref$fixed$hessian, tolerance = 1e-10)
  expect_equal(fit$loglik, ref$loglik, tolerance = 1e-10)
  expect_equal(coef(fit), ref$coef, tolerance = 1e-7)
})
