test_that("conditions carry the documented classes", {
  expect_error(se_abort("boom", "data"), class = "switch_error_data")
  expect_error(se_abort("boom", "data"), class = "switch_error")
  expect_warning(se_warn("careful", "convergence"),
                 class = "switch_warning_convergence")
  expect_message(se_inform("note", "missing"), class = "switch_message_missing")
  cnd <- tryCatch(se_abort("x", "unsupported", generation = 3L),
                  error = function(e) e)
  expect_identical(cnd$generation, 3L)
})

test_that("se_with_seed is reproducible and restores the RNG state", {
  set.seed(11); a <- runif(2)
  set.seed(11)
  r1 <- se_with_seed(99, rnorm(3))
  b <- runif(2)
  expect_identical(a, b)                 # global stream unaffected
  expect_identical(r1, se_with_seed(99, rnorm(3)))
  expect_identical(se_with_seed(NULL, 5), 5)
})

test_that("small helpers behave", {
  expect_identical(NULL %||% 2, 2)
  expect_identical(1 %||% 2, 1)
  expect_identical(se_deparse(y ~ x + z), "y ~ x + z")
  expect_error(se_check_string(c("a", "b"), "arg"),
               class = "switch_error_argument")
  expect_match(se_version(), "^[0-9]+\\.[0-9]+\\.[0-9]+")
})
