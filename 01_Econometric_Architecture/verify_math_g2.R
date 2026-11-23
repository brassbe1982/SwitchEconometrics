## verify_math_g2.R -- numerical verification of the Generation 2 formulas
## SwitchEconometrics, G2 derivation set (23 November 2026).
##
## Each check compares a formula of the G2 derivation documents
##   OBS  OBSERVATION_MECHANISMS.md     (Heckman, treatment, Tobit-5)
##   MNL  MULTINOMIAL_ESR.md            (MNL: Lee, DMF, BFG; nested logit; MNP)
##   REG  GAUSSIAN_REGION_ENGINE.md     (Gaussian selection regions)
##   ORD  ORDERED_SEQUENTIAL.md         (ordered and sequential selection)
##   MUL  MULTIVARIATE_SELECTION.md     (multivariate selection, K outcomes)
##   TE   TREATMENT_EFFECTS.md s.7      (pairwise effects)
## with an independent numerical computation: numerical integration,
## numerical differentiation, simulation, or an exact nesting identity.
## The reference code is independent of the package sources.
##
## Run from this folder:
##   Rscript --no-init-file verify_math_g2.R
## Requires mvtnorm and numDeriv; sampleSelection is optional (W04, W07).
## Writes verify_math_g2_results.csv next to this script and exits with
## status 1 if any check fails. verify_math.R (Generation 1) is unchanged.

suppressPackageStartupMessages({
  library(mvtnorm)
  library(numDeriv)
})
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(20261123)
t_start <- Sys.time()

res <- data.frame(id = character(), check = character(), doc = character(),
                  value = numeric(), tol = numeric(), pass = logical(),
                  stringsAsFactors = FALSE)
record <- function(id, check, doc, value, tol) {
  ok <- is.finite(value) && value <= tol
  res[nrow(res) + 1L, ] <<- list(id, check, doc, value, tol, ok)
  cat(sprintf("%-5s %-66s %10.3g <= %8.2g  %s\n", id, check, value, tol,
              if (ok) "PASS" else "FAIL"))
}
rdiff <- function(a, b) max(abs(a - b) / (1 + abs(b)))

## ---------------------------------------------------------------------------
## Stable building blocks (NUMERICAL_METHODS.md s.2), as in verify_math.R
## ---------------------------------------------------------------------------
log_Phi <- function(a) pnorm(a, log.p = TRUE)
mills <- function(a) exp(dnorm(a, log = TRUE) - pnorm(a, log.p = TRUE))
a_plus_lambda <- function(a) {
  out <- a + mills(a)
  neg <- a <= -5
  if (any(neg)) {
    x <- -a[neg]
    t <- 0
    for (k in 300:2) t <- k / (x + t)
    out[neg] <- 1 / (x + t)
  }
  out
}
delta_fun <- function(a) mills(a) * a_plus_lambda(a)
m1_fun <- function(w) mills(w)
m0_fun <- function(w) -mills(-w)
d1_fun <- function(w) delta_fun(w)
d0_fun <- function(w) delta_fun(-w)

## ---------------------------------------------------------------------------
## The Gaussian block of LIKELIHOOD_DERIVATION.md s.4-6 for one regime:
## log L = -tau + log phi(e) + log Phi(a), a = q (w cosh(al) + e sinh(al)).
## Returns ll, the score columns (gamma, beta, tau, alpha) and the summed
## Hessian. Used for the ESR reference, Heckman and the treatment model.
## ---------------------------------------------------------------------------
gauss_block <- function(Z, X, w, e, sig, al, q) {
  s <- sinh(al); cc <- cosh(al)
  a <- q * (w * cc + e * s)
  lam <- mills(a); del <- delta_fun(a)
  v <- w * s + e * cc
  kz <- ncol(Z); kx <- ncol(X)
  G <- cbind(lam * q * cc * Z, (e - lam * q * s) / sig * X,
             -1 + e^2 - lam * q * e * s, lam * q * v)
  p <- kz + kx + 2L
  H <- matrix(0, p, p)
  g <- seq_len(kz); b <- kz + seq_len(kx); tt <- kz + kx + 1L; aa <- p
  H[g, g] <- crossprod(Z, -del * cc^2 * Z)
  H[g, b] <- crossprod(Z, del * cc * s / sig * X)
  H[g, tt] <- colSums(del * cc * s * e * Z)
  H[g, aa] <- colSums((-del * cc * v + lam * q * s) * Z)
  H[b, b] <- crossprod(X, -(1 + del * s^2) / sig^2 * X)
  H[b, tt] <- colSums((-2 * e - del * e * s^2 + lam * q * s) / sig * X)
  H[b, aa] <- colSums((del * s * v - lam * q * cc) / sig * X)
  H[tt, tt] <- sum(-2 * e^2 - del * e^2 * s^2 + lam * q * s * e)
  H[tt, aa] <- sum(del * e * s * v - lam * q * e * cc)
  H[aa, aa] <- sum(-del * v^2 + lam * a)
  H[lower.tri(H)] <- t(H)[lower.tri(H)]
  list(ll = -log(sig) + dnorm(e, log = TRUE) + log_Phi(a), G = G, H = H)
}

## G1 reference: binary ESR, working vector
## (gamma[kz], beta1[k1], beta0[k0], tau1, tau0, alpha1, alpha0).
esr_index <- function(kz, k1, k0) {
  list(g = seq_len(kz), b1 = kz + seq_len(k1), b0 = kz + k1 + seq_len(k0),
       t1 = kz + k1 + k0 + 1L, t0 = kz + k1 + k0 + 2L,
       a1 = kz + k1 + k0 + 3L, a0 = kz + k1 + k0 + 4L,
       p = kz + k1 + k0 + 4L)
}
esr_eval <- function(th, d, ix, deriv = FALSE) {
  ll <- numeric(d$n); G <- matrix(0, d$n, ix$p); H <- matrix(0, ix$p, ix$p)
  for (j in c(1, 0)) {
    sel <- d$S == j
    X <- (if (j == 1) d$X1 else d$X0)[sel, , drop = FALSE]
    Z <- d$Z[sel, , drop = FALSE]
    bi <- if (j == 1) ix$b1 else ix$b0
    ti <- if (j == 1) ix$t1 else ix$t0
    ai <- if (j == 1) ix$a1 else ix$a0
    sig <- exp(th[ti])
    B <- gauss_block(Z, X, drop(Z %*% th[ix$g]),
                     drop(d$y[sel] - X %*% th[bi]) / sig, sig, th[ai],
                     if (j == 1) 1 else -1)
    ll[sel] <- B$ll
    id <- c(ix$g, bi, ti, ai)
    G[sel, id] <- B$G
    H[id, id] <- H[id, id] + B$H
  }
  if (deriv) list(ll = ll, G = G, H = H) else ll
}

cat("SwitchEconometrics G2 numerical verification\n")
cat(sprintf("%-5s %-66s %10s    %8s\n", "id", "check", "value", "tol"))

## ===========================================================================
## PART A  Observation mechanisms (OBSERVATION_MECHANISMS.md)
## ===========================================================================
truthA <- list(gamma = c(0.5, 0.3, -0.4), beta = c(1.5, 0.8, 0.4),
               sigma = 1.2, rho = 0.6)
sim_bin <- function(n, P) {
  x1 <- rnorm(n); x2 <- rbinom(n, 1, 0.5); z1 <- rnorm(n)
  Z <- cbind(1, x1, z1); X <- cbind(1, x1, x2)
  u <- rnorm(n); eps <- P$rho * u + sqrt(1 - P$rho^2) * rnorm(n)
  S <- as.integer(drop(Z %*% P$gamma) + u > 0)
  list(n = n, S = S, Z = Z, X = X, u = u, eps = eps,
       df = data.frame(S = S, x1 = x1, x2 = x2, z1 = z1))
}

## --- Heckman (Tobit-2): working vector (gamma[3], beta[3], tau, alpha) -----
heck_eval <- function(th, d, deriv = FALSE) {
  w <- drop(d$Z %*% th[1:3])
  sel <- d$S == 1
  sig <- exp(th[7])
  B <- gauss_block(d$Z[sel, , drop = FALSE], d$X[sel, , drop = FALSE],
                   w[sel], drop(d$y[sel] - d$X[sel, , drop = FALSE] %*%
                                  th[4:6]) / sig, sig, th[8], 1)
  ll <- pnorm(-w, log.p = TRUE)
  ll[sel] <- B$ll
  if (!deriv) return(ll)
  G <- matrix(0, d$n, 8)
  G[sel, ] <- B$G
  Z0 <- d$Z[!sel, , drop = FALSE]
  G[!sel, 1:3] <- -mills(-w[!sel]) * Z0
  H <- B$H
  H[1:3, 1:3] <- H[1:3, 1:3] + crossprod(Z0, -delta_fun(-w[!sel]) * Z0)
  list(ll = ll, G = G, H = H)
}
dH <- sim_bin(600, truthA)
dH$y <- drop(dH$X %*% truthA$beta) + truthA$sigma * dH$eps
dH$y[dH$S == 0] <- NA
thH <- c(truthA$gamma, truthA$beta, log(truthA$sigma), atanh(truthA$rho)) +
  rnorm(8, 0, 0.1)

## W01  Heckman contribution = integrated bivariate density; proper density
e01 <- 0
sig <- exp(thH[7]); rho <- tanh(thH[8])
S2 <- matrix(c(1, rho * sig, rho * sig, sig^2), 2)
llH <- heck_eval(thH, dH)
for (i in sample(which(dH$S == 1), 10)) {
  eps <- dH$y[i] - sum(dH$X[i, ] * thH[4:6]); w <- sum(dH$Z[i, ] * thH[1:3])
  Lint <- integrate(function(u) dmvnorm(cbind(u, eps), sigma = S2), -w, Inf,
                    rel.tol = 1e-12)$value
  e01 <- max(e01, abs(exp(llH[i]) / Lint - 1))
}
for (k in 1:5) {
  w <- rnorm(1); xb <- rnorm(1)
  L1 <- function(y) { e <- (y - xb) / sig
    dnorm(e) / sig * pnorm((w + rho * e) / sqrt(1 - rho^2)) }
  e01 <- max(e01, abs(integrate(L1, -Inf, Inf, rel.tol = 1e-12)$value +
                        pnorm(-w) - 1))
}
record("W01", "Heckman: L(S=1) = integrated density; sum of masses = 1",
       "OBS s.2.2", e01, 1e-8)

## W02  Heckman analytic score and Hessian against numerical derivatives
EH <- heck_eval(thH, dH, deriv = TRUE)
fH <- function(th) sum(heck_eval(th, dH))
record("W02a", "Heckman: analytic score = numerical gradient",
       "OBS s.2.3", rdiff(colSums(EH$G), grad(fH, thH)), 1e-6)
record("W02b", "Heckman: analytic Hessian = numerical Hessian",
       "OBS s.2.3", rdiff(EH$H, hessian(fH, thH)), 1e-6)

## W03  Nesting: Heckman log-lik = ESR log-lik with rho0 = 0 minus the
##      regime-0 Gaussian regression part (any beta0, sigma0)
ixE <- esr_index(3, 3, 3)
dE <- dH; dE$X1 <- dH$X; dE$X0 <- dH$X
dE$y[dH$S == 0] <- rnorm(sum(dH$S == 0))
b0 <- rnorm(3); t0 <- rnorm(1, 0, 0.2)
thE <- c(thH[1:3], thH[4:6], b0, thH[7], t0, thH[8], 0)
e0 <- drop(dE$y[dE$S == 0] - dE$X0[dE$S == 0, ] %*% b0) / exp(t0)
record("W03", "Heckman log-lik = ESR(rho0 = 0) - regime-0 regression part",
       "OBS s.2.5",
       abs(sum(esr_eval(thE, dE, ixE)) - sum(-t0 + dnorm(e0, log = TRUE)) -
             sum(llH)), 1e-9)

## W04  Same likelihood as sampleSelection Tobit-2 (convention mapping)
if (requireNamespace("sampleSelection", quietly = TRUE)) {
  d4 <- sim_bin(3000, truthA)
  d4$y <- drop(d4$X %*% truthA$beta) + truthA$sigma * d4$eps
  d4$df$y <- ifelse(d4$S == 1, d4$y, NA)
  f4 <- sampleSelection::selection(S ~ x1 + z1, y ~ x1 + x2, data = d4$df,
                                   method = "ml")
  cf <- coef(f4)
  stopifnot(length(cf) == 8)
  th4 <- c(cf[1:6], log(cf[7]), atanh(cf[8]))
  record("W04a", "Heckman: our log-lik at sampleSelection ML = its log-lik",
         "OBS s.5", abs(sum(heck_eval(th4, d4)) - as.numeric(logLik(f4))),
         1e-6)
  record("W04b", "Heckman: our score at sampleSelection ML estimate",
         "OBS s.5", max(abs(colSums(heck_eval(th4, d4, TRUE)$G))), 1e-2)
} else cat("W04   sampleSelection not installed: skipped\n")

## --- Treatment model: y = x'beta + S d'delta + eps for every unit ----------
## working vector (gamma[3], beta[3], delta[2], tau, alpha); d = (1, x1).
## It is the ESR under theta_ESR = A theta_T (linear restriction).
truthT <- c(truthA, list(delta = c(0.7, -0.3)))
sim_treat <- function(n, P) {
  d <- sim_bin(n, P)
  d$D <- d$X[, 1:2, drop = FALSE]
  d$y <- drop(d$X %*% P$beta) + d$S * drop(d$D %*% P$delta) +
    P$sigma * d$eps
  d$X1 <- d$X; d$X0 <- d$X; d$df$y <- d$y
  d
}
A_T <- matrix(0, ixE$p, 10)
A_T[cbind(ixE$g, 1:3)] <- 1
A_T[cbind(ixE$b1, 4:6)] <- 1; A_T[cbind(ixE$b1[1:2], 7:8)] <- 1
A_T[cbind(ixE$b0, 4:6)] <- 1
A_T[ixE$t1, 9] <- 1; A_T[ixE$t0, 9] <- 1
A_T[ixE$a1, 10] <- 1; A_T[ixE$a0, 10] <- 1
treat_ll_i <- function(th, d) {
  w <- drop(d$Z %*% th[1:3]); sig <- exp(th[9])
  e <- drop(d$y - d$X %*% th[4:6] - d$S * (d$D %*% th[7:8])) / sig
  q <- 2 * d$S - 1
  -th[9] + dnorm(e, log = TRUE) +
    log_Phi(q * (w * cosh(th[10]) + e * sinh(th[10])))
}
dT <- sim_treat(600, truthT)
thT <- c(truthT$gamma, truthT$beta, truthT$delta, log(truthT$sigma),
         atanh(truthT$rho)) + rnorm(10, 0, 0.1)

## W05  Treatment likelihood = restricted ESR; score A'g; Hessian A'HA
ET <- esr_eval(drop(A_T %*% thT), dT, ixE, deriv = TRUE)
fT <- function(th) sum(treat_ll_i(th, dT))
record("W05a", "Treatment log-lik_i = ESR log-lik_i at A theta (max abs.)",
       "OBS s.3.2", max(abs(ET$ll - treat_ll_i(thT, dT))), 1e-10)
record("W05b", "Treatment score A'g = numerical gradient",
       "OBS s.3.3", rdiff(drop(crossprod(A_T, colSums(ET$G))), grad(fT, thT)),
       1e-6)
record("W05c", "Treatment Hessian A'HA = numerical Hessian",
       "OBS s.3.3", rdiff(crossprod(A_T, ET$H %*% A_T), hessian(fT, thT)),
       1e-6)

## W06  Treatment conditional mean and variance given (S, z):
##      E[eps | S, w] = sigma rho h_S(w), Var = sigma^2 (1 - rho^2 delta_S(w))
e06 <- 0
for (k in 1:6) {
  w <- rnorm(1); rho <- runif(1, -0.9, 0.9); sg <- exp(rnorm(1, 0, 0.3))
  r <- sqrt(1 - rho^2)
  for (S in 0:1) {
    lo <- if (S == 1) -w else -Inf; hi <- if (S == 1) Inf else -w
    pr <- if (S == 1) pnorm(w) else pnorm(-w)
    m1 <- integrate(function(u) sg * rho * u * dnorm(u), lo, hi,
                    rel.tol = 1e-12)$value / pr
    m2 <- integrate(function(u) sg^2 * (rho^2 * u^2 + r^2) * dnorm(u), lo, hi,
                    rel.tol = 1e-12)$value / pr
    h <- if (S == 1) m1_fun(w) else m0_fun(w)
    dl <- if (S == 1) d1_fun(w) else d0_fun(w)
    e06 <- max(e06, abs(m1 - sg * rho * h),
               abs(m2 - m1^2 - sg^2 * (1 - rho^2 * dl)))
  }
}
record("W06", "Treatment: E and Var of eps given (S, w) (max abs.)",
       "OBS s.3.4", e06, 1e-8)

## W07  Same likelihood as sampleSelection::treatReg (constant shift)
if (requireNamespace("sampleSelection", quietly = TRUE)) {
  P7 <- truthT; P7$delta <- c(0.7, 0)
  d7 <- sim_treat(3000, P7)
  f7 <- sampleSelection::treatReg(S ~ x1 + z1, y ~ x1 + x2 + S,
                                  data = d7$df, method = "ml")
  cf <- coef(f7)
  stopifnot(length(cf) == 9, names(cf)[7] == "S")
  th7 <- c(cf[1:3], cf[4:6], cf[7], 0, log(cf[8]), atanh(cf[9]))
  record("W07a", "Treatment: our log-lik at treatReg ML = its log-lik",
         "OBS s.5", abs(sum(treat_ll_i(th7, d7)) - as.numeric(logLik(f7))),
         1e-6)
  g7 <- drop(crossprod(A_T, colSums(esr_eval(drop(A_T %*% th7), d7, ixE,
                                             TRUE)$G)))[-8]
  record("W07b", "Treatment: our score at treatReg ML estimate",
         "OBS s.5", max(abs(g7)), 1e-2)
} else cat("W07   sampleSelection not installed: skipped\n")

## W08  Treatment two-step (pooled control function): consistency at large n
##      and the corrected covariance by Monte Carlo (R = 400, n = 1000)
treat_two_step <- function(d) {
  pr <- suppressWarnings(glm.fit(d$Z, d$S, family = binomial("probit"),
                                 control = glm.control(epsilon = 1e-12)))
  g <- pr$coefficients; w <- drop(d$Z %*% g)
  Vg <- chol2inv(chol(crossprod(d$Z, (dnorm(w)^2 / (pnorm(w) * pnorm(-w))) *
                                  d$Z)))
  h <- ifelse(d$S == 1, m1_fun(w), m0_fun(w))
  dl <- ifelse(d$S == 1, d1_fun(w), d0_fun(w))
  W <- cbind(d$X, d$S * d$D, h)
  WtWi <- chol2inv(chol(crossprod(W)))
  b <- drop(WtWi %*% crossprod(W, d$y))
  eta <- drop(d$y - W %*% b); th <- b[length(b)]
  s2 <- mean(eta^2) + th^2 * mean(dl); r2 <- th^2 / s2
  M <- crossprod(W, dl * d$Z)
  V <- s2 * WtWi %*% (crossprod(W, (1 - r2 * dl) * W) +
                        r2 * M %*% Vg %*% t(M)) %*% WtWi
  list(b = b, se = sqrt(diag(V)), sigma = sqrt(s2), rho = th / sqrt(s2))
}
big <- treat_two_step(sim_treat(400000, truthT))
record("W08a", "Treatment two-step: sigma, rho, delta at n = 400 000 (abs.)",
       "OBS s.3.4",
       max(abs(c(big$sigma - truthT$sigma, big$rho - truthT$rho,
                 big$b[4:5] - truthT$delta))), 0.02)
mc <- t(replicate(400, { o <- treat_two_step(sim_treat(1000, truthT))
  c(o$b, o$se) }))
ratio <- colMeans(mc[, 7:12]) / apply(mc[, 1:6], 2, sd)
record("W08b", "Treatment two-step: mean SE / empirical SD - 1 (max abs.)",
       "OBS s.3.4", max(abs(ratio - 1)), 0.10)

## ===========================================================================
## PART B  Multinomial logit selection (MULTINOMIAL_ESR.md s.2-4)
## ===========================================================================
mnl_P <- function(V) { E <- exp(V - apply(V, 1, max)); E / rowSums(E) }
euler <- -digamma(1)

## --- Simulation at a fixed covariate point, J = 3 --------------------------
v0 <- c(0, 0.4, -0.3); P0 <- drop(mnl_P(matrix(v0, 1)))
nS <- 1000000L
U <- matrix(-log(-log(runif(3 * nS))), nS, 3)
V <- sweep(U, 2, v0, "+")
Sb <- max.col(V, ties.method = "first")
zstat <- function(x, target) abs(mean(x) - target) / (sd(x) / sqrt(length(x)))

## W10  Lee's index: eps*_j = max_{k != j} V_k - u_j has cdf
##      F_j(c) = e^c / (e^c + sum_{k != j} e^{v_k}); S = j iff eps*_j < v_j;
##      u*_j = -qnorm(F_j(eps*_j)) is N(0,1) and S = j iff u*_j > -w_j.
ustar <- matrix(0, nS, 3); z10 <- 0; id10 <- TRUE
for (j in 1:3) {
  es <- apply(V[, -j, drop = FALSE], 1, max) - U[, j]
  den <- sum(exp(v0[-j]))
  Fj <- exp(es) / (exp(es) + den)
  ustar[, j] <- -qnorm(Fj)
  id10 <- id10 && all((Sb == j) == (ustar[, j] > -qnorm(P0[j])))
  z10 <- max(z10, zstat(ustar[, j], 0), zstat(ustar[, j]^2, 1),
             zstat(as.numeric(es < 0.2), exp(0.2) / (exp(0.2) + den)))
}
record("W10a", "Lee: S = j iff u*_j > -qnorm(P_j) (0 = identity holds)",
       "MNL s.3.1", as.numeric(!id10), 0)
record("W10b", "Lee: F_j cdf and N(0,1) law of u*_j (max |z|, simulation)",
       "MNL s.3.1", z10, 4)

## W11  Lee contribution: proper density, and the simulated joint law of
##      (S, Y_j) under eps_j = sigma_j (rho_j u*_j + r_j nu_j)
sgL <- c(1.0, 1.3, 0.8); rhL <- c(0.5, -0.4, 0.7); wL <- qnorm(P0)
EPS <- sapply(1:3, function(j) sgL[j] * (rhL[j] * ustar[, j] +
                                           sqrt(1 - rhL[j]^2) * rnorm(nS)))
e11 <- 0; z11 <- 0
for (j in 1:3) {
  Lj <- function(y) { e <- y / sgL[j]
    dnorm(e) / sgL[j] * pnorm((wL[j] + rhL[j] * e) / sqrt(1 - rhL[j]^2)) }
  e11 <- max(e11, abs(integrate(Lj, -Inf, Inf, rel.tol = 1e-12)$value -
                        P0[j]))
  y0 <- 0.3 * sgL[j]
  z11 <- max(z11, zstat(as.numeric(Sb == j & EPS[, j] <= y0),
                        integrate(Lj, -Inf, y0, rel.tol = 1e-12)$value))
}
record("W11a", "Lee: contributions integrate to P_j (max abs.)",
       "MNL s.3.2", e11, 1e-9)
record("W11b", "Lee: P(S = j, Y_j <= y) = integral of L_j (max |z|)",
       "MNL s.3.2", z11, 4)

## W12  Lee conditional means: E[eps_j | S = j] = theta_j m1(w_j);
##      E[eps_j | S = k] = theta_j m0(w_j) for every k != j (invariance)
z12 <- 0
for (j in 1:3) for (k in 1:3) {
  target <- sgL[j] * rhL[j] * (if (k == j) m1_fun(wL[j]) else m0_fun(wL[j]))
  z12 <- max(z12, zstat(EPS[Sb == k, j], target))
}
record("W12", "Lee: E[eps_j | S = k], all (j, k) (max |z|, simulation)",
       "MNL s.3.5", z12, 4)

## W13  Dubin-McFadden moments: E[u_j - E u | S = j] = -log P_j;
##      E[u_k - E u | S = j] = P_k log P_k / (1 - P_k), k != j
z13 <- 0
for (j in 1:3) for (k in 1:3) {
  target <- if (k == j) -log(P0[j]) else P0[k] * log(P0[k]) / (1 - P0[k])
  z13 <- max(z13, zstat(U[Sb == j, k] - euler, target))
}
record("W13", "DMF: E[u_k - E u | S = j], all (j, k) (max |z|, simulation)",
       "MNL s.4.1", z13, 4)

## W14  BFG normalised variant: u+_k = qnorm(G(u_k)); E[u+_j | S = j] = m(P_j)
##      = int qnorm(G(v - log P_j)) g(v) dv; E[u+_k | S = j] = m(P_k) P_k /
##      (P_k - 1), k != j
bfg_m <- function(P) integrate(function(v) {
  qnorm(-exp(-(v - log(P))), log.p = TRUE) * exp(-v - exp(-v)) },
  -6, 40, rel.tol = 1e-10)$value      # the Gumbel density is < 1e-170 outside
Up <- qnorm(-exp(-U), log.p = TRUE)
z14 <- 0
for (j in 1:3) for (k in 1:3) {
  target <- if (k == j) bfg_m(P0[j]) else bfg_m(P0[k]) * P0[k] / (P0[k] - 1)
  z14 <- max(z14, zstat(Up[Sb == j, k], target))
}
record("W14", "BFG: E[u+_k | S = j], all (j, k) (max |z|, simulation)",
       "MNL s.4.2", z14, 4)

## W15  General RUM identity behind Lee-type counterfactuals:
##      P(eps*_k <= c, S = j) = P_j(v) - P_j(v with v_k := c), c >= v_k
z15 <- 0
for (j in 1:3) for (k in setdiff(1:3, j)) for (cc in v0[k] + c(0.3, 1.2)) {
  es <- apply(V[, -k, drop = FALSE], 1, max) - U[, k]
  v2 <- v0; v2[k] <- cc
  z15 <- max(z15, zstat(as.numeric(es <= cc & Sb == j),
                        P0[j] - drop(mnl_P(matrix(v2, 1)))[j]))
}
record("W15", "RUM: P(eps*_k <= c, S = j) = P_j(v) - P_j(v_-k, c) (max |z|)",
       "MNL s.3.5", z15, 4)
rm(U, V, Up, EPS, ustar)

## --- Lee FIML reference, J = 3 ---------------------------------------------
## working vector: gamma_2[3], gamma_3[3], beta_1[2], beta_2[3], beta_3[2],
## tau_1..3, alpha_1..3; base alternative 1 (gamma_1 = 0).
ixL <- list(g = list(NULL, 1:3, 4:6), b = list(7:8, 9:11, 12:13),
            t = 14:16, a = 17:19, p = 19L)
sim_mnl <- function(n) {
  x1 <- rnorm(n); x2 <- rbinom(n, 1, 0.5); z1 <- rnorm(n)
  Z <- cbind(1, x1, z1)
  X <- list(cbind(1, x1), cbind(1, x1, x2), cbind(1, x2))
  list(n = n, Z = Z, X = X, x1 = x1, x2 = x2, z1 = z1)
}
lee_eval <- function(th, d, ix, deriv = FALSE) {
  Vm <- cbind(0, d$Z %*% th[ix$g[[2]]], d$Z %*% th[ix$g[[3]]])
  P <- mnl_P(Vm)
  ll <- numeric(d$n); G <- matrix(0, d$n, ix$p); H <- matrix(0, ix$p, ix$p)
  for (j in 1:3) {
    sel <- d$S == j
    X <- d$X[[j]][sel, , drop = FALSE]; Z <- d$Z[sel, , drop = FALSE]
    Pj <- P[sel, , drop = FALSE]
    w <- qnorm(log(Pj[, j]), log.p = TRUE)
    sig <- exp(th[ix$t[j]]); al <- th[ix$a[j]]
    e <- drop(d$y[sel] - X %*% th[ix$b[[j]]]) / sig
    ## beta, tau, alpha blocks: the G1 block with q = +1 and index w_j
    B <- gauss_block(matrix(1, sum(sel), 1), X, w, e, sig, al, 1)
    ll[sel] <- B$ll
    if (!deriv) next
    s <- sinh(al); cc <- cosh(al); a <- w * cc + e * s
    lam <- mills(a); del <- delta_fun(a); v <- w * s + e * cc
    lw <- mills(w)
    id <- c(ix$b[[j]], ix$t[j], ix$a[j])
    G[sel, id] <- B$G[, -1]
    H[id, id] <- H[id, id] + B$H[-1, -1]
    gk <- lapply(1:3, function(k) ((j == k) - Pj[, k]) / lw)
    for (k in 2:3) {
      G[sel, ix$g[[k]]] <- lam * cc * gk[[k]] * Z
      Hb <- crossprod(Z, del * cc * s * gk[[k]] / sig * X)
      Ht <- colSums(del * cc * s * e * gk[[k]] * Z)
      Ha <- colSums((-del * cc * v + lam * s) * gk[[k]] * Z)
      H[ix$g[[k]], ix$b[[j]]] <- H[ix$g[[k]], ix$b[[j]]] + Hb
      H[ix$b[[j]], ix$g[[k]]] <- H[ix$b[[j]], ix$g[[k]]] + t(Hb)
      H[ix$g[[k]], ix$t[j]] <- H[ix$g[[k]], ix$t[j]] + Ht
      H[ix$t[j], ix$g[[k]]] <- H[ix$t[j], ix$g[[k]]] + Ht
      H[ix$g[[k]], ix$a[j]] <- H[ix$g[[k]], ix$a[j]] + Ha
      H[ix$a[j], ix$g[[k]]] <- H[ix$a[j], ix$g[[k]]] + Ha
      for (l in 2:3) {
        hkl <- (((j == k) - Pj[, k]) * ((j == l) - Pj[, l]) -
                  Pj[, k] * ((k == l) - Pj[, l])) / lw + w * gk[[k]] * gk[[l]]
        H[ix$g[[k]], ix$g[[l]]] <- H[ix$g[[k]], ix$g[[l]]] +
          crossprod(Z, (-del * cc^2 * gk[[k]] * gk[[l]] + lam * cc * hkl) * Z)
      }
    }
  }
  if (deriv) list(ll = ll, G = G, H = H) else ll
}
dL <- sim_mnl(500)
gL <- list(c(0.2, 0.5, -0.6), c(-0.3, -0.4, 0.5))
VL <- cbind(0, dL$Z %*% gL[[1]], dL$Z %*% gL[[2]]) -
  log(-log(matrix(runif(1500), 500)))
dL$S <- max.col(VL, ties.method = "first")
dL$y <- rnorm(500, 1 + 0.5 * dL$x1, 1.2)
thL <- c(gL[[1]], gL[[2]], 1, 0.5, 1.2, 0.4, 0.3, 0.8, -0.2,
         log(c(1.1, 1.3, 0.9)), atanh(c(0.5, -0.4, 0.6))) + rnorm(19, 0, 0.1)
EL <- lee_eval(thL, dL, ixL, deriv = TRUE)
fL <- function(th) sum(lee_eval(th, dL, ixL))
record("W16a", "Lee FIML: analytic score = numerical gradient",
       "MNL s.3.3", rdiff(colSums(EL$G), grad(fL, thL)), 1e-6)
record("W16b", "Lee FIML: analytic Hessian = numerical Hessian",
       "MNL s.3.3", rdiff(EL$H, hessian(fL, thL)), 1e-6)

## ===========================================================================
## PART C  Gaussian region engine (GAUSSIAN_REGION_ENGINE.md)
## ===========================================================================
## P(X <= b) for a standardised normal vector with correlation matrix R.
## Infinite coordinates are marginalised; deterministic for d <= 3 (TVPACK).
pcdf <- function(b, R) {
  if (any(b == -Inf)) return(0)
  keep <- which(b < Inf)
  d <- length(keep)
  if (d == 0L) return(1)
  if (d == 1L) return(pnorm(b[keep]))
  alg <- if (d <= 3L) TVPACK(abseps = 1e-14) else
    GenzBretz(maxpts = 2e6, abseps = 1e-8)
  as.numeric(pmvnorm(upper = b[keep], corr = R[keep, keep, drop = FALSE],
                     algorithm = alg))
}
## P(l < X <= h) by inclusion-exclusion over the corners.
rect <- function(l, h, R) {
  d <- length(l)
  tot <- 0
  for (m in 0:(2^d - 1)) {
    low <- bitwAnd(m, 2^(0:(d - 1))) > 0
    b <- ifelse(low, l, h)
    if (any(b == -Inf)) next
    tot <- tot + (-1)^sum(low) * pcdf(b, R)
  }
  tot
}
## conditional rectangle of the other coordinates given X[idx] = val
rect_cond <- function(l, h, R, idx, val) {
  rest <- setdiff(seq_along(l), idx)
  if (!length(rest)) return(1)
  B <- R[rest, idx, drop = FALSE] %*% solve(R[idx, idx, drop = FALSE])
  mu <- drop(B %*% val)
  Sg <- R[rest, rest, drop = FALSE] - B %*% R[idx, rest, drop = FALSE]
  sd <- sqrt(diag(Sg))
  rect((l[rest] - mu) / sd, (h[rest] - mu) / sd, Sg / (sd %o% sd))
}
## Plackett-type derivatives of the rectangle probability
rect_grad <- function(l, h, R) {
  d <- length(l)
  dl <- dh <- numeric(d)
  for (k in 1:d) {
    if (is.finite(h[k])) dh[k] <- dnorm(h[k]) * rect_cond(l, h, R, k, h[k])
    if (is.finite(l[k])) dl[k] <- -dnorm(l[k]) * rect_cond(l, h, R, k, l[k])
  }
  pr <- which(upper.tri(R), arr.ind = TRUE)
  dR <- numeric(nrow(pr))
  for (r in seq_len(nrow(pr))) {
    k <- pr[r, 1]; m <- pr[r, 2]
    for (a in list(c(l[k], -1), c(h[k], 1))) for (b in list(c(l[m], -1),
                                                           c(h[m], 1))) {
      if (!is.finite(a[1]) || !is.finite(b[1])) next
      dR[r] <- dR[r] + a[2] * b[2] *
        dmvnorm(c(a[1], b[1]), sigma = R[c(k, m), c(k, m)]) *
        rect_cond(l, h, R, c(k, m), c(a[1], b[1]))
    }
  }
  list(dl = dl, dh = dh, dR = dR, pairs = pr)
}

## W20  Rectangle-probability derivatives against numerical differentiation
e20 <- 0
for (d in 2:3) for (rep in 1:3) {
  Rr <- cov2cor(crossprod(matrix(rnorm(d * (d + 2)), d + 2)))
  l <- rnorm(d, -0.8, 0.5); h <- l + runif(d, 0.6, 2)
  if (rep == 2) h[1] <- Inf
  if (rep == 3) l[d] <- -Inf
  gr <- rect_grad(l, h, Rr)
  fin_l <- is.finite(l); fin_h <- is.finite(h)
  f <- function(x) {
    l2 <- l; h2 <- h; R2 <- Rr
    l2[fin_l] <- x[seq_len(sum(fin_l))]
    h2[fin_h] <- x[sum(fin_l) + seq_len(sum(fin_h))]
    rr <- x[sum(fin_l) + sum(fin_h) + seq_len(nrow(gr$pairs))]
    R2[gr$pairs] <- rr; R2[gr$pairs[, 2:1, drop = FALSE]] <- rr
    rect(l2, h2, R2)
  }
  x0 <- c(l[fin_l], h[fin_h], Rr[gr$pairs])
  e20 <- max(e20, rdiff(c(gr$dl[fin_l], gr$dh[fin_h], gr$dR), grad(f, x0)))
}
record("W20", "Rectangle probability: Plackett derivatives, d = 2, 3",
       "REG s.4", e20, 1e-6)

## --- Parameter maps (complex-safe, for exact complex-step Jacobians) -------
## Upper-triangular W with R = W'W from canonical partial correlations
cpcW <- function(alpha, d) {
  z <- tanh(alpha)
  W <- matrix(0 * (if (length(z)) z[1] else 0), d, d)
  W[1, 1] <- 1
  k <- 0L
  if (d >= 2L) for (j in 2:d) {
    s <- 1 + 0 * W[1, 1]
    for (i in seq_len(j - 1L)) {
      k <- k + 1L
      W[i, j] <- z[k] * sqrt(s); s <- s - W[i, j]^2
    }
    W[j, j] <- sqrt(s)
  }
  W
}
## extra Cholesky column of an outcome disturbance: l_i = z_i sqrt(1 - ...)
cpc_row <- function(alpha) {
  z <- tanh(alpha); l <- z; s <- 1 + 0 * z[1]
  for (i in seq_along(z)) { l[i] <- z[i] * sqrt(s); s <- s - l[i]^2 }
  l
}

## Generic engine. A model supplies cond(th, i) returning, for observation i
## in its regime: logf (log density of the outcome part), m and S (mean and
## covariance of X = A (W + u) given the outcome), and limits l, h.
eng_ll_i <- function(model, th) {
  vapply(seq_len(model$n), function(i) {
    C <- model$cond(th, i)
    sd <- sqrt(diag(C$S))
    Re(C$logf) + log(rect((C$l - C$m) / sd, (C$h - C$m) / sd,
                          C$S / (sd %o% sd)))
  }, 0)
}
eng_pack <- function(C) {
  sd <- sqrt(diag(C$S)); R <- C$S / (sd %o% sd)
  l <- C$l; h <- C$h
  l[!is.finite(Re(l))] <- 0; h[!is.finite(Re(h))] <- 0
  c(C$logf, C$m, sd, R[upper.tri(R)], l, h)
}
## score: Plackett derivatives chained with the exact complex-step Jacobian
## of (logf, m, sd, R, l, h) with respect to the working parameters
eng_score_i <- function(model, th) {
  p <- length(th)
  t(vapply(seq_len(model$n), function(i) {
    C <- model$cond(th, i); d <- length(C$m)
    fl <- is.finite(C$l); fh <- is.finite(C$h)
    sd <- sqrt(diag(C$S)); R <- C$S / (sd %o% sd)
    ls <- (C$l - C$m) / sd; hs <- (C$h - C$m) / sd
    Pr <- rect(ls, hs, R); gr <- rect_grad(ls, hs, R)
    nr <- d * (d - 1) / 2
    Jc <- vapply(seq_len(p), function(k) {
      tc <- complex(real = th, imaginary = 0)
      tc[k] <- complex(real = th[k], imaginary = 1e-20)
      Im(eng_pack(model$cond(tc, i))) / 1e-20
    }, numeric(1 + 2 * d + nr + 2 * d))
    Jf <- Jc[1, ]; Jm <- Jc[1 + seq_len(d), , drop = FALSE]
    Js <- Jc[1 + d + seq_len(d), , drop = FALSE]
    JR <- Jc[1 + 2 * d + seq_len(nr), , drop = FALSE]
    Jl <- Jc[1 + 2 * d + nr + seq_len(d), , drop = FALSE]
    Jh <- Jc[1 + 3 * d + nr + seq_len(d), , drop = FALSE]
    g <- Jf
    for (k in seq_len(d)) {
      if (fh[k]) g <- g + gr$dh[k] * (Jh[k, ] - Jm[k, ] - hs[k] * Js[k, ]) /
          sd[k] / Pr
      if (fl[k]) g <- g + gr$dl[k] * (Jl[k, ] - Jm[k, ] - ls[k] * Js[k, ]) /
          sd[k] / Pr
    }
    if (nr) g <- g + drop(gr$dR %*% JR) / Pr
    g
  }, numeric(p)))
}

## --- Multinomial probit ESR, J = 3 (base alternative 1) --------------------
## working vector: gamma_2[3], gamma_3[3], beta_1[2], beta_2[3], beta_3[2],
## tau_1..3 (outcome log sd), tu (log sd of u_3 - u_1), au (CPC of Omega),
## al_j[2] for j = 1..3 (CPCs of eps_j against the selection differences).
ixM <- list(g = list(NULL, 1:3, 4:6), b = list(7:8, 9:11, 12:13), t = 14:16,
            tu = 17L, au = 18L, al = list(19:20, 21:22, 23:24), p = 24L)
A_mnp <- list(-diag(2), rbind(c(1, 0), c(1, -1)), rbind(c(0, 1), c(-1, 1)))
mnp_parts <- function(th, ix) {
  D <- diag(c(1 + 0 * th[1], exp(th[ix$tu])))
  Wc <- cpcW(th[ix$au], 2)
  R <- t(Wc) %*% Wc
  psi <- lapply(1:3, function(j) drop(t(Wc) %*% cpc_row(th[ix$al[[j]]])))
  list(D = D, R = R, Om = D %*% R %*% D, psi = psi,
       cv = lapply(psi, function(p) drop(D %*% p)))
}
mnp_model <- function(d, ix) {
  list(n = d$n, cond = function(th, i) {
    j <- d$S[i]; P <- mnp_parts(th, ix)
    Wv <- c(sum(d$Z[i, ] * th[ix$g[[2]]]), sum(d$Z[i, ] * th[ix$g[[3]]]))
    e <- (d$y[i] - sum(d$X[[j]][i, ] * th[ix$b[[j]]])) / exp(th[ix$t[j]])
    A <- A_mnp[[j]]; cv <- P$cv[[j]]
    list(logf = -th[ix$t[j]] - e^2 / 2 - log(2 * pi) / 2,
         m = drop(A %*% (Wv + cv * e)),
         S = A %*% (P$Om - cv %o% cv) %*% t(A),
         l = c(0, 0), h = c(Inf, Inf))
  })
}
thM <- c(0.2, 0.5, -0.6, -0.3, -0.4, 0.5, 1, 0.5, 1.2, 0.4, 0.3, 0.8, -0.2,
         log(c(1.1, 1.3, 0.9)), log(1.2), atanh(0.4),
         atanh(c(0.5, 0.2)), atanh(c(-0.4, 0.3)), atanh(c(0.3, -0.5)))
PM <- mnp_parts(thM, ixM)
## simulate (u, eps_1..3) with eps_j conditionally independent given u
sim_mnp <- function(n, th, ix) {
  d <- sim_mnl(n); P <- mnp_parts(th, ix)
  us <- matrix(rnorm(2 * n), n) %*% chol(P$R)       # standardised differences
  ut <- us %*% P$D
  Vd <- cbind(0, d$Z %*% th[ix$g[[2]]] + ut[, 1], d$Z %*% th[ix$g[[3]]] +
                ut[, 2])
  d$S <- max.col(Vd, ties.method = "first")
  Ri <- solve(P$R)
  d$eps <- sapply(1:3, function(j) {
    k <- drop(Ri %*% P$psi[[j]])
    exp(th[ix$t[j]]) * (drop(us %*% k) +
                          sqrt(1 - sum(P$psi[[j]] * k)) * rnorm(n)) })
  d$y <- vapply(seq_len(n), function(i) sum(d$X[[d$S[i]]][i, ] *
            th[ix$b[[d$S[i]]]]) + d$eps[i, d$S[i]], 0)
  d$us <- us
  d
}
dM <- sim_mnp(60, thM, ixM)
modM <- mnp_model(dM, ixM)
thMr <- thM + rnorm(24, 0, 0.05)

## W21  MNP-ESR contribution: P(S = j, Y <= y0) from the joint (J)-variate
##      normal equals the integral of the contribution (all three regimes)
e21 <- 0
for (j in 1:3) {
  i <- which(dM$S == j)[1]
  Wv <- c(sum(dM$Z[i, ] * thM[ixM$g[[2]]]), sum(dM$Z[i, ] * thM[ixM$g[[3]]]))
  sg <- exp(thM[ixM$t[j]]); A <- A_mnp[[j]]; cv <- PM$cv[[j]]
  Lj <- function(e) vapply(e, function(ee) {
    S <- A %*% (PM$Om - cv %o% cv) %*% t(A); sd <- sqrt(diag(S))
    m <- drop(A %*% (Wv + cv * ee))
    dnorm(ee) * rect(-m / sd, c(Inf, Inf), S / (sd %o% sd)) }, 0)
  e0 <- 0.4
  ## joint of (A u, eps_j / sigma_j): covariance blocks
  Sj <- rbind(cbind(A %*% PM$Om %*% t(A), A %*% cv), c(A %*% cv, 1))
  ## event: A u > -A W and eps <= e0  ->  (-A u, eps) <= (A W, e0)
  Fm <- diag(c(-1, -1, 1)); Sf <- Fm %*% Sj %*% Fm; sdf <- sqrt(diag(Sf))
  joint <- pcdf(c(drop(A %*% Wv), e0) / sdf, Sf / (sdf %o% sdf))
  e21 <- max(e21, abs(integrate(Lj, -Inf, e0, rel.tol = 1e-10)$value - joint))
}
record("W21", "MNP-ESR: integral of contribution = trivariate normal (abs.)",
       "REG s.2", e21, 1e-8)

## W22  Exact nesting: the engine with J = 2 equals the G1 log-likelihood
dB <- sim_bin(300, truthA)
dB$X1 <- dB$X; dB$X0 <- dB$X[, 1:2]
dB$y <- ifelse(dB$S == 1, drop(dB$X1 %*% truthA$beta) + 1.2 * dB$eps,
               drop(dB$X0 %*% c(1, 0.5)) + 0.8 * rnorm(300))
ixB <- esr_index(3, 3, 2)
thB <- c(truthA$gamma, truthA$beta, 1, 0.5, log(1.2), log(0.8), atanh(0.6),
         atanh(-0.3)) + rnorm(12, 0, 0.1)
mod2 <- list(n = dB$n, cond = function(th, i) {
  j <- dB$S[i]
  bi <- if (j == 1) ixB$b1 else ixB$b0
  X <- if (j == 1) dB$X1[i, ] else dB$X0[i, ]
  ti <- if (j == 1) ixB$t1 else ixB$t0
  psi <- tanh(th[if (j == 1) ixB$a1 else ixB$a0])
  e <- (dB$y[i] - sum(X * th[bi])) / exp(th[ti])
  A <- if (j == 1) 1 else -1
  list(logf = -th[ti] - e^2 / 2 - log(2 * pi) / 2,
       m = A * (sum(dB$Z[i, ] * th[ixB$g]) + psi * e),
       S = matrix(1 - psi^2), l = 0, h = Inf)
})
record("W22a", "Nesting: region engine with J = 2 = G1 log-lik_i (max abs.)",
       "REG s.9", max(abs(eng_ll_i(mod2, thB) - esr_eval(thB, dB, ixB))),
       1e-10)
record("W22b", "Nesting: region-engine score with J = 2 = G1 analytic score",
       "REG s.9", rdiff(eng_score_i(mod2, thB),
                        esr_eval(thB, dB, ixB, TRUE)$G), 1e-8)

## W23  MNP-ESR score (Plackett + exact Jacobian) = numerical gradient
fM <- function(th) sum(eng_ll_i(modM, th))
record("W23", "MNP-ESR (J = 3): engine score = numerical gradient",
       "REG s.5", rdiff(colSums(eng_score_i(modM, thMr)), grad(fM, thMr)),
       1e-6)

## W29  Hessian strategy of the region models: the symmetrised central
##      difference of the analytic score equals the numerical Hessian of
##      the log-likelihood (first 25 observations, to limit the run time)
modM2 <- modM; modM2$n <- 25L
gsumM <- function(th) colSums(eng_score_i(modM2, th))
Hd <- vapply(seq_along(thMr), function(k) {
  h <- 1e-5 * max(1, abs(thMr[k])); e <- replace(numeric(24), k, h)
  (gsumM(thMr + e) - gsumM(thMr - e)) / (2 * h) }, numeric(24))
Hd <- (Hd + t(Hd)) / 2
record("W29", "MNP-ESR: differenced analytic score = numerical Hessian",
       "REG s.5", rdiff(Hd, hessian(function(th) sum(eng_ll_i(modM2, th)),
                                    thMr)), 1e-5)

## W24  Parameterisation: every working vector gives valid joint matrices,
##      with the selection block shared by all regimes
e24 <- Inf; e24b <- 0
for (rep in 1:200) {
  th <- rnorm(24, 0, 1.5); P <- mnp_parts(th, ixM)
  for (j in 1:3) {
    Rj <- rbind(cbind(P$R, P$psi[[j]]), c(P$psi[[j]], 1))
    e24 <- min(e24, min(eigen(Rj, symmetric = TRUE, only.values = TRUE)$values))
    e24b <- max(e24b, abs(diag(Rj) - 1))
  }
}
record("W24", "CPC map: joint correlation matrices positive definite",
       "REG s.3", as.numeric(!(e24 > 0)) + e24b, 1e-12)

## W25  GHK simulator on Halton draws against deterministic probabilities
halton <- function(n, base) {
  vapply(seq_len(n), function(i) { f <- 1; r <- 0
    while (i > 0) { f <- f / base; r <- r + f * (i %% base); i <- i %/% base }
    r }, 0)
}
ghk <- function(l, h, Sigma, U) {
  L <- t(chol(Sigma)); d <- length(l)
  eta <- matrix(0, nrow(U), d); pr <- rep(1, nrow(U))
  for (k in 1:d) {
    off <- if (k > 1) drop(eta[, 1:(k - 1), drop = FALSE] %*% L[k, 1:(k - 1)])
           else 0
    lo <- pnorm((l[k] - off) / L[k, k]); hi <- pnorm((h[k] - off) / L[k, k])
    pr <- pr * (hi - lo)
    eta[, k] <- qnorm(lo + U[, k] * (hi - lo))
  }
  mean(pr)
}
primes <- c(2, 3, 5, 7)
Uh <- sapply(primes, function(b) halton(2020, b))[-(1:20), ]
e25 <- c(0, 0)
for (d in 2:4) for (rep in 1:6) {
  Sg <- crossprod(matrix(rnorm(d * (d + 2)), d + 2)) / (d + 2)
  l <- rnorm(d, -0.5, 0.6); h <- rep(Inf, d)
  if (rep > 3) h <- l + runif(d, 0.8, 2.5)
  sd <- sqrt(diag(Sg)); Rg <- Sg / (sd %o% sd)
  exact <- if (d <= 3) rect(l / sd, h / sd, Rg) else
    as.numeric(pmvnorm(lower = l, upper = h, sigma = Sg,
                       algorithm = GenzBretz(maxpts = 5e6, abseps = 1e-7)))
  e25[1] <- max(e25[1], abs(ghk(l, h, Sg, Uh[1:500, 1:d]) - exact))
  e25[2] <- max(e25[2], abs(ghk(l, h, Sg, Uh[, 1:d]) - exact))
}
record("W25a", "GHK, 500 Halton draws: max abs. error of the probability",
       "REG s.8", e25[1], 1e-2)
record("W25b", "GHK, 2000 Halton draws: max abs. error of the probability",
       "REG s.8", e25[2], 5e-3)

## W26  Truncated mean of a normal vector over a rectangle (Tallis), and the
##      truncated covariance from the location derivative
tmean <- function(l, h, Sigma) {
  sd <- sqrt(diag(Sigma)); R <- Sigma / (sd %o% sd)
  P <- rect(l / sd, h / sd, R); gr <- rect_grad(l / sd, h / sd, R)
  list(P = P, mean = drop(Sigma %*% (-(gr$dl + gr$dh) / sd)) / P)
}
e26 <- 0; e26b <- 0
for (rep in 1:4) {
  Sg <- crossprod(matrix(rnorm(8), 4)) / 4
  l <- rnorm(2, -0.6, 0.5); h <- if (rep <= 2) c(Inf, Inf) else l + c(1.5, 2)
  tm <- tmean(l, h, Sg)
  cs <- Sg[1, 2] / Sg[1, 1]; s2 <- sqrt(Sg[2, 2] - Sg[1, 2]^2 / Sg[1, 1])
  s1 <- sqrt(Sg[1, 1])
  mom <- function(fun) integrate(function(x) vapply(x, function(xx) {
    lo <- (l[2] - cs * xx) / s2; hi <- (h[2] - cs * xx) / s2
    dnorm(xx / s1) / s1 * fun(xx, lo, hi) }, 0), l[1], h[1],
    rel.tol = 1e-11)$value
  p0 <- mom(function(x, lo, hi) pnorm(hi) - pnorm(lo))
  mx1 <- mom(function(x, lo, hi) x * (pnorm(hi) - pnorm(lo))) / p0
  ex2 <- function(x, lo, hi) cs * x * (pnorm(hi) - pnorm(lo)) +
    s2 * (dnorm(lo) - dnorm(hi))
  mx2 <- mom(ex2) / p0
  e26 <- max(e26, abs(tm$P - p0), abs(tm$mean - c(mx1, mx2)))
  ## Var(X | rect) = (d E[v | rect] / d mu') Sigma for v ~ N(mu, Sigma)
  Jt <- jacobian(function(mu) mu + tmean(l - mu, h - mu, Sg)$mean, c(0, 0))
  v11 <- mom(function(x, lo, hi) x^2 * (pnorm(hi) - pnorm(lo))) / p0 - mx1^2
  v12 <- mom(function(x, lo, hi) x * ex2(x, lo, hi)) / p0 - mx1 * mx2
  e26b <- max(e26b, abs((Jt %*% Sg)[1, ] - c(v11, v12)))
}
record("W26a", "Truncated normal mean over rectangles, d = 2 (max abs.)",
       "REG s.6", e26, 1e-8)
record("W26b", "Truncated covariance = location Jacobian x Sigma (max abs.)",
       "REG s.6", e26b, 1e-6)

## W27  MNP conditional expectations E[eps_j | S = k] and the adding-up
##      identity sum_k P_k E[u | S = k] = 0, at a fixed covariate point
Wv <- c(0.3, -0.2); nS <- 600000L
us <- matrix(rnorm(2 * nS), nS) %*% chol(PM$R); ut <- us %*% PM$D
Sb <- max.col(cbind(0, Wv[1] + ut[, 1], Wv[2] + ut[, 2]),
              ties.method = "first")
Ri <- solve(PM$R)
tmk <- lapply(1:3, function(k) {
  A <- A_mnp[[k]]
  tm <- tmean(-drop(A %*% Wv), c(Inf, Inf), A %*% PM$Om %*% t(A))
  list(P = tm$P, Eu = drop(solve(A, tm$mean))) })
add_up <- Reduce(`+`, lapply(tmk, function(x) x$P * x$Eu))
z27 <- 0
for (j in 1:3) {
  kap <- drop(Ri %*% PM$psi[[j]]); sg <- exp(thM[ixM$t[j]])
  epsj <- sg * (drop(us %*% kap) + sqrt(1 - sum(PM$psi[[j]] * kap)) *
                  rnorm(nS))
  for (k in 1:3) {
    target <- sg * sum(kap * (tmk[[k]]$Eu / diag(PM$D)))
    z27 <- max(z27, zstat(epsj[Sb == k], target))
  }
}
record("W27a", "MNP: E[eps_j | S = k], all (j, k) (max |z|, simulation)",
       "TE s.7", z27, 4)
record("W27b", "Adding up: sum_k P_k E[u | S = k] = 0 and sum_k P_k = 1",
       "TE s.7", max(abs(add_up), abs(sum(sapply(tmk, `[[`, "P")) - 1)), 1e-8)
rm(us, ut)

## W28  Cross-regime dependence: the conditional-independence completion is
##      a valid joint law; the pairwise bounds are attained with a singular
##      but positive semi-definite matrix
Rfull <- function(pi12) {
  K <- sapply(PM$psi, function(p) drop(Ri %*% p))            # 2 x 3
  res_sd <- sqrt(1 - colSums(sapply(PM$psi, identity) * K))
  Pi <- diag(3); Pi[1, 2] <- Pi[2, 1] <- pi12
  Ce <- t(K) %*% PM$R %*% K + (res_sd %o% res_sd) * Pi
  rbind(cbind(PM$R, sapply(PM$psi, identity)),
        cbind(t(sapply(PM$psi, identity)), Ce))
}
ev0 <- min(eigen(Rfull(0), symmetric = TRUE, only.values = TRUE)$values)
ev1 <- min(eigen(Rfull(1), symmetric = TRUE, only.values = TRUE)$values)
record("W28", "Cross-regime completion: PD inside, singular PSD at the bound",
       "REG s.11", as.numeric(!(ev0 > 1e-8)) + abs(ev1) +
         max(abs(diag(Rfull(1)) - 1)), 1e-10)

## ===========================================================================
## PART D  Ordered, sequential and multivariate selection; several outcomes;
##         nested logit
## ===========================================================================
## --- Ordered probit selection, J = 3 ---------------------------------------
## S = j iff mu_{j-1} < z'gamma + u <= mu_j, mu_0 = -Inf, mu_1 = 0,
## mu_2 = exp(kappa), mu_3 = Inf. Working vector: gamma[3], kappa,
## beta_1[2], beta_2[3], beta_3[2], tau_1..3, alpha_1..3.
ixO <- list(g = 1:3, k = 4L, b = list(5:6, 7:9, 10:11), t = 12:14,
            a = 15:17, p = 17L)
ord_eval <- function(th, d, ix, deriv = FALSE) {
  mu <- c(-Inf, 0, exp(th[ix$k]), Inf)
  ll <- numeric(d$n); G <- matrix(0, d$n, ix$p); H <- matrix(0, ix$p, ix$p)
  for (i in seq_len(d$n)) {
    j <- d$S[i]; z <- d$Z[i, ]; x <- d$X[[j]][i, ]
    sig <- exp(th[ix$t[j]]); s <- sinh(th[ix$a[j]]); cc <- cosh(th[ix$a[j]])
    w <- sum(z * th[ix$g]); e <- (d$y[i] - sum(x * th[ix$b[[j]]])) / sig
    lim <- function(m, dm) {            # index a, gradient and Hessian
      if (!is.finite(m)) return(list(phi = 0, a = 0, g = numeric(ix$p),
                                     h = matrix(0, ix$p, ix$p), P = m > 0))
      a <- (m - w) * cc - e * s
      g <- numeric(ix$p); h <- matrix(0, ix$p, ix$p)
      g[ix$g] <- -cc * z; g[ix$b[[j]]] <- s * x / sig
      g[ix$t[j]] <- s * e; g[ix$a[j]] <- (m - w) * s - e * cc
      g[ix$k] <- cc * dm
      h[ix$g, ix$a[j]] <- -s * z
      h[ix$b[[j]], ix$t[j]] <- -s * x / sig
      h[ix$b[[j]], ix$a[j]] <- cc * x / sig
      h[ix$t[j], ix$a[j]] <- cc * e
      h[ix$k, ix$a[j]] <- s * dm
      h <- h + t(h)
      h[ix$t[j], ix$t[j]] <- -s * e; h[ix$a[j], ix$a[j]] <- a
      h[ix$k, ix$k] <- cc * dm
      list(phi = dnorm(a), a = a, g = g, h = h, P = pnorm(a))
    }
    hi <- lim(mu[j + 1], if (j + 1 == 3) mu[3] else 0)
    lo <- lim(mu[j], if (j == 3) mu[3] else 0)
    Aij <- if (is.finite(mu[j + 1]) && is.finite(mu[j]) && lo$a > 0)
      pnorm(-lo$a) - pnorm(-hi$a) else hi$P - lo$P
    ll[i] <- -th[ix$t[j]] + dnorm(e, log = TRUE) + log(Aij)
    if (!deriv) next
    gd <- numeric(ix$p); gd[ix$b[[j]]] <- e * x / sig
    gd[ix$t[j]] <- -1 + e^2
    gA <- (hi$phi * hi$g - lo$phi * lo$g) / Aij
    G[i, ] <- gd + gA
    Hd <- matrix(0, ix$p, ix$p)
    Hd[ix$b[[j]], ix$b[[j]]] <- -tcrossprod(x) / sig^2
    Hd[ix$b[[j]], ix$t[j]] <- Hd[ix$t[j], ix$b[[j]]] <- -2 * e * x / sig
    Hd[ix$t[j], ix$t[j]] <- -2 * e^2
    H <- H + Hd - tcrossprod(gA) +
      (-hi$a * hi$phi * tcrossprod(hi$g) + hi$phi * hi$h +
         lo$a * lo$phi * tcrossprod(lo$g) - lo$phi * lo$h) / Aij
  }
  if (deriv) list(ll = ll, G = G, H = H) else ll
}
dO <- sim_mnl(400)
thO <- c(0.3, 0.5, -0.6, log(1.1), 1, 0.5, 1.2, 0.4, 0.3, 0.8, -0.2,
         log(c(1.1, 1.3, 0.9)), atanh(c(0.5, -0.4, 0.6)))
uO <- rnorm(400)
dO$S <- 1L + (drop(dO$Z %*% thO[1:3]) + uO > 0) +
  (drop(dO$Z %*% thO[1:3]) + uO > 1.1)
dO$y <- rnorm(400, 1 + 0.5 * dO$x1 + 0.4 * uO, 1.1)
thOr <- thO + rnorm(17, 0, 0.1)

## W30  Ordered contribution = integrated bivariate density; proper density
e30 <- 0
llO <- ord_eval(thOr, dO, ixO)
muO <- c(-Inf, 0, exp(thOr[4]), Inf)
for (i in c(which(dO$S == 1)[1:4], which(dO$S == 2)[1:4],
            which(dO$S == 3)[1:4])) {
  j <- dO$S[i]; sg <- exp(thOr[ixO$t[j]]); rho <- tanh(thOr[ixO$a[j]])
  eps <- dO$y[i] - sum(dO$X[[j]][i, ] * thOr[ixO$b[[j]]])
  w <- sum(dO$Z[i, ] * thOr[1:3])
  S2 <- matrix(c(1, rho * sg, rho * sg, sg^2), 2)
  Lint <- integrate(function(u) dmvnorm(cbind(u, eps), sigma = S2),
                    muO[j] - w, muO[j + 1] - w, rel.tol = 1e-12)$value
  e30 <- max(e30, abs(exp(llO[i]) / Lint - 1))
}
record("W30", "Ordered: contribution = integrated density (max rel.)",
       "ORD s.1.2", e30, 1e-8)

## W31  Ordered analytic score and Hessian against numerical derivatives
EO <- ord_eval(thOr, dO, ixO, deriv = TRUE)
fO <- function(th) sum(ord_eval(th, dO, ixO))
record("W31a", "Ordered: analytic score = numerical gradient",
       "ORD s.1.3", rdiff(colSums(EO$G), grad(fO, thOr)), 1e-6)
record("W31b", "Ordered: analytic Hessian = numerical Hessian",
       "ORD s.1.3", rdiff(EO$H, hessian(fO, thOr)), 1e-6)

## W32  Ordered with J = 2 (mu_1 = 0) is the G1 likelihood exactly; the
##      ordered model is also an instance of the region engine
ord2 <- function(th, d, ix) {
  w <- drop(d$Z %*% th[ix$g]); out <- numeric(d$n)
  for (j in c(1, 0)) {
    sel <- d$S == j
    X <- (if (j == 1) d$X1 else d$X0)[sel, , drop = FALSE]
    bi <- if (j == 1) ix$b1 else ix$b0; ti <- if (j == 1) ix$t1 else ix$t0
    al <- th[if (j == 1) ix$a1 else ix$a0]
    e <- drop(d$y[sel] - X %*% th[bi]) / exp(th[ti])
    lo <- if (j == 1) 0 else -Inf; hi <- if (j == 1) Inf else 0
    a <- function(m) (m - w[sel]) * cosh(al) - e * sinh(al)
    out[sel] <- -th[ti] + dnorm(e, log = TRUE) +
      log((if (is.finite(hi)) pnorm(a(hi)) else 1) -
            (if (is.finite(lo)) pnorm(a(lo)) else 0))
  }
  out
}
record("W32a", "Nesting: ordered selection with J = 2 = G1 log-lik_i",
       "ORD s.1.5", max(abs(ord2(thB, dB, ixB) - esr_eval(thB, dB, ixB))),
       1e-10)
modO <- list(n = 40L, cond = function(th, i) {
  j <- dO$S[i]; mu <- c(-Inf, 0, exp(th[ixO$k]), Inf)
  psi <- tanh(th[ixO$a[j]])
  e <- (dO$y[i] - sum(dO$X[[j]][i, ] * th[ixO$b[[j]]])) / exp(th[ixO$t[j]])
  list(logf = -th[ixO$t[j]] - e^2 / 2 - log(2 * pi) / 2,
       m = sum(dO$Z[i, ] * th[ixO$g]) + psi * e, S = matrix(1 - psi^2),
       l = mu[j], h = mu[j + 1])
})
record("W32b", "Ordered = region engine: log-lik_i and score_i (max)",
       "REG s.9", max(abs(eng_ll_i(modO, thOr) - llO[1:40]),
                      rdiff(eng_score_i(modO, thOr), EO$G[1:40, ])), 1e-8)

## W33  Ordered conditional moments: m_j(w) = E[u | S = j], and
##      d m_j / d w = -(1 - Var(u | S = j))
ord_m <- function(w, lo, hi) (dnorm(lo - w) - dnorm(hi - w)) /
  (pnorm(hi - w) - pnorm(lo - w))
ord_v <- function(w, lo, hi) {
  a <- lo - w; b <- hi - w
  ta <- if (is.finite(a)) a * dnorm(a) else 0
  tb <- if (is.finite(b)) b * dnorm(b) else 0
  1 + (ta - tb) / (pnorm(b) - pnorm(a)) - ord_m(w, lo, hi)^2
}
e33 <- 0
for (cut in list(c(-Inf, 0), c(0, 1.1), c(1.1, Inf))) {
  w <- 0.37
  pr <- pnorm(cut[2] - w) - pnorm(cut[1] - w)
  m1 <- integrate(function(u) u * dnorm(u), cut[1] - w, cut[2] - w,
                  rel.tol = 1e-12)$value / pr
  m2 <- integrate(function(u) u^2 * dnorm(u), cut[1] - w, cut[2] - w,
                  rel.tol = 1e-12)$value / pr
  e33 <- max(e33, abs(ord_m(w, cut[1], cut[2]) - m1),
             abs(ord_v(w, cut[1], cut[2]) - (m2 - m1^2)),
             abs(grad(function(x) ord_m(x, cut[1], cut[2]), w) +
                   1 - ord_v(w, cut[1], cut[2])))
}
record("W33", "Ordered: E, Var of u given S = j and dm/dw (max abs.)",
       "ORD s.1.4", e33, 1e-8)

## --- Sequential selection, J = 3 (two stages) ------------------------------
## Stage m: continue iff z'gamma_m + u_m > 0. Regime 1: stop at stage 1;
## regime 2: pass stage 1, stop at stage 2; regime 3: pass both.
## Working vector: gamma_1[3], gamma_2[3], beta_1[2], beta_2[3], beta_3[2],
## tau_1..3, au (CPC of Corr(u_1, u_2)), al_1[1], al_2[2], al_3[2].
ixS <- list(g = list(1:3, 4:6), b = list(7:8, 9:11, 12:13), t = 14:16,
            au = 17L, al = list(18L, 19:20, 21:22), p = 22L)
seq_lim <- list(list(l = c(-Inf, -Inf), h = c(0, Inf)),
                list(l = c(0, -Inf), h = c(Inf, 0)),
                list(l = c(0, 0), h = c(Inf, Inf)))
seq_parts <- function(th, ix) {
  Wc <- cpcW(th[ix$au], 2)
  list(R = t(Wc) %*% Wc, psi = lapply(1:3, function(j) {
    a <- th[ix$al[[j]]]
    if (length(a) < 2) a <- c(a, 0 * a[1])   # non-identified CPC fixed at 0
    drop(t(Wc) %*% cpc_row(a)) }))
}
seq_model <- function(d, ix, n = d$n) {
  list(n = n, cond = function(th, i) {
    j <- d$S[i]; P <- seq_parts(th, ix); psi <- P$psi[[j]]
    Wv <- c(sum(d$Z[i, ] * th[ix$g[[1]]]), sum(d$Z[i, ] * th[ix$g[[2]]]))
    e <- (d$y[i] - sum(d$X[[j]][i, ] * th[ix$b[[j]]])) / exp(th[ix$t[j]])
    list(logf = -th[ix$t[j]] - e^2 / 2 - log(2 * pi) / 2,
         m = Wv + psi * e, S = P$R - psi %o% psi,
         l = seq_lim[[j]]$l, h = seq_lim[[j]]$h)
  })
}
thS <- c(0.6, 0.5, -0.6, 0.2, -0.4, 0.5, 1, 0.5, 1.2, 0.4, 0.3, 0.8, -0.2,
         log(c(1.1, 1.3, 0.9)), atanh(0.3), atanh(0.5), atanh(c(-0.4, 0.3)),
         atanh(c(0.3, -0.5)))
dS <- sim_mnl(60)
uS <- matrix(rnorm(120), 60) %*% chol(seq_parts(thS, ixS)$R)
c1 <- drop(dS$Z %*% thS[1:3]) + uS[, 1] > 0
c2 <- drop(dS$Z %*% thS[4:6]) + uS[, 2] > 0
dS$S <- ifelse(!c1, 1L, ifelse(!c2, 2L, 3L))
dS$y <- rnorm(60, 1 + 0.5 * dS$x1 + 0.4 * uS[, 1], 1.1)
modS <- seq_model(dS, ixS)
thSr <- thS + rnorm(22, 0, 0.05)

## W34  Sequential: regime-1 contribution has the binary closed form (the
##      later stage integrates out); regimes 2, 3 against the trivariate
##      normal; score against the numerical gradient
llS <- eng_ll_i(modS, thSr)
PS <- seq_parts(thSr, ixS)
e34 <- 0
for (i in which(dS$S == 1)) {
  e <- (dS$y[i] - sum(dS$X[[1]][i, ] * thSr[ixS$b[[1]]])) / exp(thSr[14])
  w <- sum(dS$Z[i, ] * thSr[1:3]); rho <- tanh(thSr[ixS$al[[1]]])
  e34 <- max(e34, abs(llS[i] - (-thSr[14] + dnorm(e, log = TRUE) +
                                  log_Phi(-(w + rho * e) / sqrt(1 - rho^2)))))
}
for (j in 2:3) {
  i <- which(dS$S == j)[1]; psi <- PS$psi[[j]]
  Wv <- c(sum(dS$Z[i, ] * thSr[1:3]), sum(dS$Z[i, ] * thSr[4:6]))
  Lj <- function(e) vapply(e, function(ee) {
    S <- PS$R - psi %o% psi; sd <- sqrt(diag(S)); m <- Wv + psi * ee
    dnorm(ee) * rect((seq_lim[[j]]$l - m) / sd, (seq_lim[[j]]$h - m) / sd,
                     S / (sd %o% sd)) }, 0)
  Sj <- rbind(cbind(PS$R, psi), c(psi, 1))
  sgn <- if (j == 2) c(-1, 1, 1) else c(-1, -1, 1)     # make all bounds upper
  Fm <- diag(sgn); Sf <- Fm %*% Sj %*% Fm
  joint <- pcdf(c(-sgn[1:2] * Wv, 0.4), Sf)
  e34 <- max(e34, abs(integrate(Lj, -Inf, 0.4, rel.tol = 1e-10)$value -
                        joint))
}
record("W34a", "Sequential: contributions = closed form / trivariate normal",
       "ORD s.2.2", e34, 1e-8)
fS <- function(th) sum(eng_ll_i(modS, th))
record("W34b", "Sequential (J = 3): engine score = numerical gradient",
       "ORD s.2.3", rdiff(colSums(eng_score_i(modS, thSr)), grad(fS, thSr)),
       1e-6)

## --- Multivariate selection, M = 2 binary equations, four regimes ----------
## Regime (s1, s2); every regime has its own outcome equation here (common
## regressors). Working vector: gamma_1[3], gamma_2[3], beta_r[2] (r = 1..4),
## tau_r, au, al_r[2].
ixV <- list(g = list(1:3, 4:6), b = lapply(0:3, function(r) 6 + 2 * r + 1:2),
            t = 15:18, au = 19L,
            al = lapply(0:3, function(r) 19 + 2 * r + 1:2), p = 27L)
mv_model <- function(d, ix) {
  list(n = d$n, cond = function(th, i) {
    r <- d$S[i]; s <- c(d$S1[i], d$S2[i])
    Wc <- cpcW(th[ix$au], 2); R <- t(Wc) %*% Wc
    psi <- drop(t(Wc) %*% cpc_row(th[ix$al[[r]]]))
    Wv <- c(sum(d$Z[i, ] * th[ix$g[[1]]]), sum(d$Z[i, ] * th[ix$g[[2]]]))
    e <- (d$y[i] - sum(d$X[[1]][i, ] * th[ix$b[[r]]])) / exp(th[ix$t[r]])
    list(logf = -th[ix$t[r]] - e^2 / 2 - log(2 * pi) / 2,
         m = Wv + psi * e, S = R - psi %o% psi,
         l = ifelse(s == 1, 0, -Inf), h = ifelse(s == 1, Inf, 0))
  })
}
dV <- sim_mnl(60)
thV <- c(0.3, 0.5, -0.6, -0.2, -0.4, 0.5, rnorm(8, 1, 0.3),
         log(c(1.1, 1.3, 0.9, 1)), atanh(0.4), atanh(runif(8, -0.5, 0.5)))
uV <- matrix(rnorm(120), 60) %*% chol(matrix(c(1, 0.4, 0.4, 1), 2))
dV$S1 <- as.integer(drop(dV$Z %*% thV[1:3]) + uV[, 1] > 0)
dV$S2 <- as.integer(drop(dV$Z %*% thV[4:6]) + uV[, 2] > 0)
dV$S <- 1L + dV$S1 + 2L * dV$S2
dV$y <- rnorm(60, 1 + 0.5 * dV$x1 + 0.4 * uV[, 1], 1.1)
modV <- mv_model(dV, ixV)

## W35  Multivariate selection: contribution against the trivariate normal;
##      score against the numerical gradient; M = 1 is G1 (W22)
e35 <- 0
i <- which(dV$S1 == 1 & dV$S2 == 0)[1]; r <- dV$S[i]
Wc <- cpcW(thV[ixV$au], 2); RV <- t(Wc) %*% Wc
psi <- drop(t(Wc) %*% cpc_row(thV[ixV$al[[r]]]))
Wv <- c(sum(dV$Z[i, ] * thV[1:3]), sum(dV$Z[i, ] * thV[4:6]))
Lj <- function(e) vapply(e, function(ee) {
  S <- RV - psi %o% psi; sd <- sqrt(diag(S)); m <- Wv + psi * ee
  dnorm(ee) * rect((c(0, -Inf) - m) / sd, (c(Inf, 0) - m) / sd,
                   S / (sd %o% sd)) }, 0)
Sj <- rbind(cbind(RV, psi), c(psi, 1)); Fm <- diag(c(-1, 1, 1))
e35 <- abs(integrate(Lj, -Inf, 0.4, rel.tol = 1e-10)$value -
             pcdf(c(Wv[1], -Wv[2], 0.4), Fm %*% Sj %*% Fm))
record("W35a", "Multivariate selection: contribution = trivariate normal",
       "MUL s.2", e35, 1e-8)
fV <- function(th) sum(eng_ll_i(modV, th))
record("W35b", "Multivariate selection (M = 2): score = numerical gradient",
       "MUL s.3", rdiff(colSums(eng_score_i(modV, thV)), grad(fV, thV)),
       1e-6)

## W36  Several outcomes per regime (K = 2, binary selection): the K = 2
##      contribution integrates over y_2 to the K = 1 contribution, and
##      equals the trivariate density integrated over the selection region
e36 <- 0
for (rep in 1:4) {
  w <- rnorm(1, 0, 0.8)
  R3 <- cov2cor(crossprod(matrix(rnorm(15), 5)))      # (u, eps_1, eps_2)
  sg <- exp(rnorm(2, 0, 0.3)); Dm <- diag(c(1, sg))
  S3 <- Dm %*% R3 %*% Dm
  Se <- S3[2:3, 2:3]; C <- S3[1, 2:3]
  cond_var <- 1 - drop(C %*% solve(Se, C))
  LK2 <- function(e1, e2) {
    ee <- c(e1, e2)
    dmvnorm(ee, sigma = Se) *
      pnorm((w + drop(C %*% solve(Se, ee))) / sqrt(cond_var))
  }
  e1 <- rnorm(1, 0, sg[1])
  marg <- integrate(function(x) vapply(x, function(xx) LK2(e1, xx), 0),
                    -Inf, Inf, rel.tol = 1e-11)$value
  rho1 <- R3[1, 2]
  LK1 <- dnorm(e1 / sg[1]) / sg[1] *
    pnorm((w + rho1 * e1 / sg[1]) / sqrt(1 - rho1^2))
  e2 <- rnorm(1, 0, sg[2])
  dens <- integrate(function(u) vapply(u, function(uu)
    dmvnorm(c(uu, e1, e2), sigma = S3), 0), -w, Inf, rel.tol = 1e-11)$value
  e36 <- max(e36, abs(marg / LK1 - 1), abs(LK2(e1, e2) / dens - 1))
}
record("W36", "K = 2 outcomes: marginalises to K = 1; equals joint density",
       "MUL s.4", e36, 1e-8)

## --- Nested logit selection: nests {1}, {2, 3}, dissimilarity lambda -------
nl_logP <- function(v, lam, nest = c(1L, 2L, 2L)) {
  lamj <- lam[nest]
  I <- tapply(seq_along(v), nest, function(id) {
    x <- v[id] / lam[nest[id[1]]]; max(x) + log(sum(exp(x - max(x)))) })
  lg <- lam * I
  v / lamj + (lamj - 1) * I[nest] - (max(lg) + log(sum(exp(lg - max(lg)))))
}
nl_P <- function(v, lam) exp(nl_logP(v, lam))
## analytic derivatives of log P_j (MNL s.5.2)
nl_dlogP <- function(v, lam, nest = c(1L, 2L, 2L)) {
  P <- nl_P(v, lam); J <- length(v)
  Pg <- tapply(P, nest, sum); cond <- P / Pg[nest]
  I <- tapply(seq_along(v), nest, function(id) {
    x <- v[id] / lam[nest[id[1]]]; max(x) + log(sum(exp(x - max(x)))) })
  dI <- tapply(seq_along(v), nest, function(id)
    -sum(cond[id] * v[id]) / lam[nest[id[1]]]^2)
  dv <- matrix(0, J, J); dlam <- matrix(0, J, length(lam))
  for (j in 1:J) {
    g <- nest[j]
    for (k in 1:J) dv[j, k] <- (j == k) / lam[g] +
      (nest[k] == g) * cond[k] * (lam[g] - 1) / lam[g] - P[k]
    for (hh in seq_along(lam)) dlam[j, hh] <-
      (hh == g) * (-v[j] / lam[g]^2 + I[g] + (lam[g] - 1) * dI[g]) -
      Pg[hh] * (I[hh] + lam[hh] * dI[hh])
  }
  list(dv = dv, dlam = dlam)
}
vN <- c(0, 0.4, -0.3); lamN <- c(1, 0.6)
## simulation: u_j = lambda_g (xi_j + log S_g), S_g positive stable
rstable_pos <- function(n, a) {
  if (a == 1) return(rep(1, n))
  U <- runif(n, 0, pi); W <- rexp(n)
  sin(a * U) / sin(U)^(1 / a) * (sin((1 - a) * U) / W)^((1 - a) / a)
}
nS <- 800000L
xi <- matrix(-log(rexp(3 * nS)), nS, 3)
sN <- log(rstable_pos(nS, lamN[2]))
UN <- cbind(xi[, 1], lamN[2] * (xi[, 2] + sN), lamN[2] * (xi[, 3] + sN))
VN <- sweep(UN, 2, vN, "+"); SbN <- max.col(VN, ties.method = "first")
PN <- nl_P(vN, lamN)
z37 <- max(vapply(1:3, function(j) zstat(as.numeric(SbN == j), PN[j]), 0),
           zstat(as.numeric(UN[, 2] <= 0.5), exp(-exp(-0.5))))
record("W37a", "Nested logit: P_j and Gumbel margins (max |z|, simulation)",
       "MNL s.5.1", z37, 4)
dN <- nl_dlogP(vN, lamN)
record("W37b", "Nested logit: d log P / d(v, lambda) = numerical; MNL limit",
       "MNL s.5.2",
       max(rdiff(dN$dv, jacobian(function(v) nl_logP(v, lamN), vN)),
           rdiff(dN$dlam[, 2], drop(jacobian(function(l)
             nl_logP(vN, c(1, l)), lamN[2]))),
           abs(nl_P(vN, c(1, 1)) - drop(mnl_P(matrix(vN, 1))))), 1e-7)

## W38  Lee-type counterfactual moment for a general RUM selection model:
##      F_k(c) = P_k(v with v_k := c); m_{k|j} = E[u*_k | S = j]
##      = (1 / P_j) int_{v_k}^{Inf} -qnorm(F_k(c)) d[-P_j(v_-k, c)]
lee_cf <- function(v, k, j, Pfun) {
  Pj_c <- function(cc) vapply(cc, function(x) { v2 <- v; v2[k] <- x
    Pfun(v2)[j] }, 0)
  Fk <- function(cc) vapply(cc, function(x) { v2 <- v; v2[k] <- x
    Pfun(v2)[k] }, 0)
  dens <- function(cc) -(Pj_c(cc + 1e-5) - Pj_c(cc - 1e-5)) / 2e-5
  ## upper limit v_k + 25: the neglected tail mass is below 1e-9
  integrate(function(cc) -qnorm(Fk(cc)) * dens(cc), v[k], v[k] + 25,
            rel.tol = 1e-9, subdivisions = 400L)$value / Pfun(v)[j]
}
z38 <- 0; e38 <- 0
for (k in 1:3) {
  es <- apply(VN[, -k, drop = FALSE], 1, max) - UN[, k]
  Fk <- vapply(es[1:200000], function(x) { v2 <- vN; v2[k] <- x
    nl_P(v2, lamN)[k] }, 0)
  us <- -qnorm(Fk)
  for (j in setdiff(1:3, k)) {
    z38 <- max(z38, zstat(us[SbN[1:200000] == j],
                          lee_cf(vN, k, j, function(v) nl_P(v, lamN))))
    ## MNL special case: the moment is m0(w_k) for every j != k
    e38 <- max(e38, abs(lee_cf(vN, k, j, function(v) nl_P(v, c(1, 1))) -
                          m0_fun(qnorm(nl_P(vN, c(1, 1))[k]))))
  }
}
record("W38a", "Nested-logit Lee moment E[u*_k | S = j] (max |z|, simul.)",
       "MNL s.5.3", z38, 4)
record("W38b", "General Lee moment reduces to m0(w_k) under MNL (max abs.)",
       "MNL s.3.5", e38, 1e-6)

## ---------------------------------------------------------------------------
## Summary
## ---------------------------------------------------------------------------
el <- as.numeric(difftime(Sys.time(), t_start, units = "secs"))
cat(sprintf("\n%d checks, %d passed, %d failed; %.1f s; R %s, mvtnorm %s, numDeriv %s%s\n",
            nrow(res), sum(res$pass), sum(!res$pass), el,
            getRversion(), packageVersion("mvtnorm"), packageVersion("numDeriv"),
            if (requireNamespace("sampleSelection", quietly = TRUE))
              paste0(", sampleSelection ", packageVersion("sampleSelection")) else ""))
utils::write.csv(res, "verify_math_g2_results.csv", row.names = FALSE)
if (any(!res$pass)) quit(status = 1)
