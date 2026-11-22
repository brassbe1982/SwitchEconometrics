## switch_model() (API_SPECIFICATION.md s.2)

test_that("a classical ESR specification is built and printed", {
  spec <- esr_spec()
  expect_s3_class(spec, "switch_spec")
  expect_identical(spec$model, "esr")
  expect_identical(spec$regimes, c("regime_0", "regime_1"))
  expect_identical(spec$selection$family, "probit")
  expect_identical(spec$outcomes$regime_1$family, "gaussian")
  expect_identical(spec$observation, "switching")
  expect_identical(spec$family, "continuous")
  expect_identical(spec$identification$exclusions,
                   list(regime_0 = "z1", regime_1 = "z1"))
  expect_output(print(spec), "Switching model specification")
  expect_output(print(spec), "regime_1: z1")
})

test_that("unnamed outcomes get default labels; names are checked", {
  s <- switch_model(S ~ x1 + z1, list(y ~ x1, y ~ x1))
  expect_identical(s$regimes, c("regime_0", "regime_1"))
  expect_false(s$regime_names_given)
  s2 <- switch_model(S ~ x1 + z1, list(non = y ~ x1, adopt = y ~ x1))
  expect_identical(s2$regimes, c("non", "adopt"))
  expect_error(switch_model(S ~ z1, list(a = y ~ x1, y ~ x1)),
               class = "switch_error_argument")
  expect_error(switch_model(S ~ z1, list(a = y ~ x1, a = y ~ x1)),
               class = "switch_error_argument")
  expect_error(switch_model(S ~ z1, list(selection = y ~ x1, b = y ~ x1)),
               class = "switch_error_argument")
  expect_error(switch_model(S ~ z1, list(`a:b` = y ~ x1, b = y ~ x1)),
               class = "switch_error_argument")
})

test_that("later-generation values name their generation", {
  e <- expect_error(esr_spec(dependence = "clayton"),
                    class = "switch_error_unsupported")
  expect_match(conditionMessage(e), "Generation 3")
  expect_identical(e$generation, 3)
  expect_error(esr_spec(model = "multinomial_esr"),
               class = "switch_error_unsupported")
  expect_error(esr_spec(outcome_family = "poisson"), "Generation 4")
  expect_error(esr_spec(selection_family = "multinomial_probit"),
               "Generation 2")
  expect_error(esr_spec(family = "binary"), class = "switch_error_unsupported")
  expect_error(switch_model(S ~ z1, list(y ~ x1, y ~ x1, y ~ x1),
                            regimes = 3), class = "switch_error_unsupported")
  expect_s3_class(esr_spec(family = "continuous"), "switch_spec")
})

test_that("invalid arguments give classed errors", {
  expect_error(esr_spec(dependence = "nonsense"),
               class = "switch_error_argument")
  expect_error(esr_spec(model = c("esr", "esr")),
               class = "switch_error_argument")
  expect_error(switch_model(~ z1, list(y ~ x1, y ~ x1)),
               class = "switch_error_argument")
  expect_error(switch_model(S ~ z1, y ~ x1), class = "switch_error_argument")
  expect_error(switch_model(S ~ z1, list(y ~ x1, ~ x1)),
               class = "switch_error_argument")
  expect_error(switch_model(S ~ z1, list(y ~ x1, y ~ x1), regimes = 3),
               class = "switch_error_argument")
  expect_error(switch_model(S ~ z1, list(y ~ x1, y ~ x1), regimes = 1.5),
               class = "switch_error_argument")
  expect_error(switch_model(S ~ ., list(y ~ x1, y ~ x1)),
               class = "switch_error_argument")
})

test_that("the regime indicator cannot be an outcome regressor", {
  expect_error(switch_model(S ~ z1, list(y ~ x1 + S, y ~ x1)),
               "cannot be a regressor", class = "switch_error_argument")
})

test_that("declared exclusion restrictions are checked", {
  s <- esr_spec(identification = "z1")
  expect_identical(s$identification$mode, "declared")
  expect_identical(s$identification$declared, "z1")
  expect_error(esr_spec(identification = "x9"), "do not appear",
               class = "switch_error_argument")
  expect_error(esr_spec(identification = "x1"), "appears in outcome",
               class = "switch_error_argument")
  expect_error(esr_spec(identification = 1), class = "switch_error_argument")
})

test_that("a specification without exclusions prints the identification note", {
  s <- switch_model(S ~ x1 + x2, list(y ~ x1 + x2, y ~ x1 + x2))
  expect_identical(lengths(s$identification$exclusions),
                   c(regime_0 = 0L, regime_1 = 0L))
  expect_output(print(s), "normality")
})
