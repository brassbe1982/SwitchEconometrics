## data-raw/financing.R -- generates the simulated example data `financing`
## (documented in R/data.R). Run from the package root:
##   Rscript --no-init-file data-raw/financing.R
## The data are simulated; no real firms are represented.
##
## Data-generating process: multinomial-logit choice of a financing regime
## (internal, bank, digital) and regime-specific productivity equations with
## the dependence of Lee (1983): for each regime the outcome disturbance is
## eps_j = sigma_j (rho_j u*_j + sqrt(1 - rho_j^2) nu_j), where u*_j is the
## normal transform of that regime's selection index (MULTINOMIAL_ESR.md
## s.3) and nu_j is independent noise.

RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(20261124)
n <- 3000

firm_size <- round(rnorm(n, 3, 1), 3)                    # log employees
capital <- round(2 + 0.2 * firm_size + rnorm(n, 0, 0.8), 3)
collateral <- round(rnorm(n), 3)                         # standardised
financial_access <- rbinom(n, 1, 0.5)
digital_infrastructure <- round(rnorm(n), 3)             # standardised

labs <- c("internal", "bank", "digital")
V <- cbind(0,
           -0.6 + 0.15 * (firm_size - 3) + 0.8 * collateral +
             0.5 * financial_access,
           -0.8 - 0.10 * (firm_size - 3) + 0.1 * collateral +
             0.3 * financial_access + 0.9 * digital_infrastructure)
U <- V - log(-log(matrix(runif(3 * n), n, 3)))           # Gumbel utilities
S <- ifelse(U[, 1] >= U[, 2] & U[, 1] >= U[, 3], 1L,
            ifelse(U[, 2] >= U[, 3], 2L, 3L))      # exact argmax

xb <- cbind(0.5 + 0.05 * firm_size + 0.30 * capital,
            0.7 + 0.08 * firm_size + 0.33 * capital,
            0.9 + 0.04 * firm_size + 0.36 * capital)
sigma <- c(0.45, 0.50, 0.55)
rho <- c(0.30, 0.45, -0.25)
productivity <- numeric(n)
for (j in 1:3) {
  es <- apply(U[, -j, drop = FALSE], 1, max) - (U[, j] - V[, j])   # eps*_j
  lF <- es - log(exp(es) + rowSums(exp(V[, -j, drop = FALSE])))
  us <- -qnorm(lF, log.p = TRUE)
  eps <- sigma[j] * (rho[j] * us + sqrt(1 - rho[j]^2) * rnorm(n))
  productivity[S == j] <- (xb[, j] + eps)[S == j]
}

financing <- data.frame(
  firm_id = seq_len(n),
  financing = factor(labs[S], levels = labs),
  productivity = round(productivity, 4),
  firm_size, capital, collateral, financial_access, digital_infrastructure)
dir.create("data", showWarnings = FALSE)
save(financing, file = "data/financing.rda", compress = "xz")
cat("financing:", nrow(financing), "rows; shares",
    round(prop.table(table(financing$financing)), 3), "\n")
