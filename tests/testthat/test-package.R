test_that("package metadata is consistent with the development plan", {
  desc <- utils::packageDescription("SwitchEconometrics")
  expect_identical(desc$Package, "SwitchEconometrics")
  expect_true(package_version(desc$Version) >= "0.1.0")
  expect_match(desc$License, "MIT")
})

test_that("the package attaches without start-up messages", {
  expect_silent(suppressPackageStartupMessages(
    library(SwitchEconometrics, quietly = TRUE)))
  out <- utils::capture.output(
    res <- tryCatch(loadNamespace("SwitchEconometrics"),
                    message = function(m) m),
    type = "message")
  expect_length(out, 0L)
  expect_false(inherits(res, "message"))
})
