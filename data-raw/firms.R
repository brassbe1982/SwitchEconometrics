## data-raw/firms.R -- generates the simulated example data `firms`
## (documented in R/data.R). Run from the package root:
##   Rscript --no-init-file data-raw/firms.R
## The data are simulated; no real firms are represented.

RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(20261122)
n <- 2000

region <- factor(sample(c("Centre", "East", "North", "South", "West"), n,
                        replace = TRUE, prob = c(0.20, 0.20, 0.20, 0.25, 0.15)))
firm_size <- round(rnorm(n, 3, 1), 3)                 # log employees
internet_access <- rbinom(n, 1, 0.6)
management_quality <- round(rnorm(n), 3)              # standardised score
owner_education <- pmin(pmax(round(rnorm(n, 12, 3)), 6), 20)   # years
capital <- round(2 + 0.2 * firm_size + rnorm(n, 0, 0.8), 3)    # log capital per worker
labour <- round(7.5 + rnorm(n, 0, 0.2), 3)            # log hours per worker

## disturbances: Corr(u, e1) = 0.45, Corr(u, e0) = -0.25,
## Corr(e1, e0) = 0.45 * (-0.25) (not identified; irrelevant for the data)
rho1 <- 0.45; rho0 <- -0.25; sigma1 <- 0.50; sigma0 <- 0.45
R <- matrix(c(1, rho1, rho0, rho1, 1, rho1 * rho0, rho0, rho1 * rho0, 1), 3)
E <- matrix(rnorm(3 * n), n) %*% chol(R)
u <- E[, 1]; e1 <- sigma1 * E[, 2]; e0 <- sigma0 * E[, 3]

w <- -2.1 + 0.9 * internet_access + 0.5 * management_quality +
  0.25 * firm_size + 0.06 * owner_education
digital_adoption <- as.integer(w + u > 0)
prod1 <- 0.8 + 0.08 * firm_size + 0.35 * capital + 0.10 * labour + e1
prod0 <- 0.5 + 0.05 * firm_size + 0.30 * capital + 0.10 * labour + e0
productivity <- round(ifelse(digital_adoption == 1, prod1, prod0), 4)

firms <- data.frame(firm_id = seq_len(n), region, digital_adoption,
                    productivity, internet_access, management_quality,
                    firm_size, owner_education, capital, labour)
dir.create("data", showWarnings = FALSE)
save(firms, file = "data/firms.rda", compress = "xz")
cat("firms:", nrow(firms), "rows; adoption share", mean(digital_adoption), "\n")
