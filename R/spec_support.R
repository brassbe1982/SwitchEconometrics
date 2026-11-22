## Which argument values exist in which generation. Single source of truth for
## the "planned for Generation n" errors (API_SPECIFICATION.md s.2).

se_generations <- c("1" = "0.1.0-1.0.0", "2" = "1.1.0-1.5.0",
                    "3" = "2.0.0-2.5.0", "4" = "3.0.0-3.5.0",
                    "5" = "4.0.0-4.5.0", "6" = "5.0.0 and later")

se_support_table <- function() {
  rows <- list(
    model = c(esr = 1, multinomial_esr = 2, ordered_esr = 2,
              sequential_esr = 2, multivariate_esr = 2, heckman = 2,
              treatment = 2, tobit5 = 2, panel_esr = 5, dynamic_esr = 5,
              hierarchical_esr = 6, spatial_esr = 6),
    selection_family = c(probit = 1, multinomial_probit = 2,
                         multinomial_logit = 2, nested_logit = 2,
                         ordered_probit = 2, ordered_logit = 2,
                         sequential_probit = 2, logit = 3),
    outcome_family = c(gaussian = 1, student_t = 3, skew_normal = 3,
                       probit = 4, logit = 4, poisson = 4,
                       negative_binomial = 4, ordered_probit = 4,
                       ordered_logit = 4, tobit = 4, beta = 4, weibull = 4,
                       lognormal = 4, loglogistic = 4),
    dependence = c(gaussian = 1, student_t = 3, clayton = 3, gumbel = 3,
                   frank = 3, joe = 3, bb1 = 3, bb6 = 3, bb7 = 3, bb8 = 3,
                   vine = 3),
    family = c(continuous = 1, binary = 4, count = 4, ordinal = 4,
               censored = 4, fractional = 4, duration = 4),
    method = c(fiml = 1, two_step = 1, simulated_ml = 2,
               control_function = 4, robust = 4, laplace = 5, bayesian = 6),
    distribution = c(gaussian = 1, student_t = 3, skew_normal = 3,
                     logistic = 3)
  )
  do.call(rbind, lapply(names(rows), function(a)
    data.frame(argument = a, value = names(rows[[a]]),
               generation = unname(rows[[a]]), stringsAsFactors = FALSE)))
}

## Check an argument value: unknown values and values of later generations
## give classed errors ("argument" and "unsupported").
se_check_choice <- function(argument, value, current_generation = 1L) {
  se_check_string(value, argument)
  tab <- se_support_table()
  tab <- tab[tab$argument == argument, , drop = FALSE]
  i <- match(value, tab$value)
  if (is.na(i)) {
    se_abort(sprintf("unknown %s \"%s\"; known values: %s", argument, value,
                     paste(tab$value, collapse = ", ")), "argument")
  }
  g <- tab$generation[i]
  if (g > current_generation) {
    se_abort(sprintf(paste0(
      "%s = \"%s\" is planned for Generation %d (versions %s) and is not ",
      "available in SwitchEconometrics %s"), argument, value, g,
      se_generations[[as.character(g)]], se_version()), "unsupported",
      generation = g)
  }
  invisible(value)
}
