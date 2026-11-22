## Simulated binary ESR data for the tests (design of verify_math.R, with
## the same regressors in both outcome equations).
sim_esr_data <- function(n = 400, seed = 1, rho1 = 0.6, rho0 = 0.4) {
  set.seed(seed)
  x1 <- rnorm(n); x2 <- rnorm(n); z1 <- rnorm(n)
  u <- rnorm(n)
  e1 <- rho1 * u + sqrt(1 - rho1^2) * rnorm(n)
  e0 <- rho0 * u + sqrt(1 - rho0^2) * rnorm(n)
  S <- as.integer(0.5 + 0.3 * x1 - 0.4 * z1 + u > 0)
  y <- ifelse(S == 1, 1.5 + 0.8 * x1 + 0.4 * x2 + 1.2 * e1,
              1.0 + 0.5 * x1 + 0.2 * x2 + 0.8 * e0)
  data.frame(S = S, y = y, x1 = x1, x2 = x2, z1 = z1,
             g = factor(sample(c("a", "b", "c"), n, replace = TRUE)),
             w = runif(n, 0.5, 2), cl = sample(1:40, n, replace = TRUE))
}

esr_spec <- function(...) {
  switch_model(selection = S ~ x1 + z1,
               outcomes = list(regime_0 = y ~ x1 + x2,
                               regime_1 = y ~ x1 + x2), ...)
}
