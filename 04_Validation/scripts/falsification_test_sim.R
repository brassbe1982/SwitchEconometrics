## falsification_test_sim.R -- size and power of the exclusion-restriction
## falsification test (Di Falco, Veronesi and Yesuf 2011) under the binary
## Gaussian ESR (evidence for IDENTIFICATION.md section 6).
##
## Usage (from the workspace root, base R only):
##   Rscript --no-init-file SwitchEconometrics/04_Validation/scripts/falsification_test_sim.R
## Result of 22 November 2026 (R 4.6.2), 5% level, n = 1000:
##   valid exclusion (rho0 = 0.4), R = 400: literal 0.510, conditional 0.050
##   invalid exclusion (direct effect 0.15), R = 200: literal 1.000,
##   conditional 0.050

sim <- function(n, seed, direct = 0) {
  set.seed(seed)
  x1 <- rnorm(n); x2 <- rnorm(n); z1 <- rnorm(n); u <- rnorm(n)
  e1 <- 0.6 * u + sqrt(1 - 0.36) * rnorm(n)
  e0 <- 0.4 * u + sqrt(1 - 0.16) * rnorm(n)
  S <- as.integer(0.5 + 0.3 * x1 - 0.4 * z1 + u > 0)
  y <- ifelse(S == 1, 1.5 + 0.8 * x1 + 0.4 * x2 + 1.2 * e1,
              1.0 + 0.5 * x1 + 0.2 * x2 + 0.8 * e0 + direct * z1)
  data.frame(S, y, x1, x2, z1)
}
pvals <- function(d) {
  w <- predict(glm(S ~ x1 + z1, family = binomial("probit"), data = d))
  d0 <- d[d$S == 0, ]
  d0$m0 <- -dnorm(w[d$S == 0]) / pnorm(-w[d$S == 0])
  c(literal = anova(lm(y ~ x1 + x2, d0), lm(y ~ x1 + x2 + z1, d0))$`Pr(>F)`[2],
    conditional = anova(lm(y ~ x1 + x2 + m0, d0),
                        lm(y ~ x1 + x2 + m0 + z1, d0))$`Pr(>F)`[2])
}
size <- t(sapply(1:400, function(k) pvals(sim(1000, 1000 + k))))
power <- t(sapply(1:200, function(k) pvals(sim(1000, 5000 + k, direct = 0.15))))
cat("rejection rate at 5%, valid exclusion (rho0 = 0.4), R = 400:\n")
print(round(colMeans(size < 0.05), 3))
cat("rejection rate at 5%, invalid exclusion (direct effect 0.15), R = 200:\n")
print(round(colMeans(power < 0.05), 3))
