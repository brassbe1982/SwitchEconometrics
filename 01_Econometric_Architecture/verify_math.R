## verify_math.R -- numerical verification of every Generation 1 formula
## SwitchEconometrics, work package 1.1 (22 November 2026).
##
## Each check compares a closed-form expression from the G1 derivation
## documents (BINARY_ESR.md, LIKELIHOOD_DERIVATION.md, PARAMETERIZATION.md,
## TREATMENT_EFFECTS.md, IDENTIFICATION.md) with an independent numerical
## computation: numerical integration of the bivariate or trivariate normal
## density, numerical differentiation, or simulation. The reference code in
## this file is deliberately independent of the package sources; the package
## tests later compare the package functions with these references.
##
## Run from this folder:
##   Rscript --no-init-file verify_math.R
## Requires mvtnorm and numDeriv; sampleSelection is optional (check V17).
## Writes verify_math_results.csv next to this script and exits with status 1
## if any check fails.

suppressPackageStartupMessages({
  library(mvtnorm)
  library(numDeriv)
})
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(20261122)
t_start <- Sys.time()

res <- data.frame(id = character(), check = character(), doc = character(),
                  value = numeric(), tol = numeric(), pass = logical(),
                  stringsAsFactors = FALSE)
record <- function(id, check, doc, value, tol) {
  ok <- is.finite(value) && value <= tol
  res[nrow(res) + 1L, ] <<- list(id, check, doc, value, tol, ok)
  cat(sprintf("%-5s %-64s %10.3g <= %8.2g  %s\n", id, check, value, tol,
              if (ok) "PASS" else "FAIL"))
}

## ---------------------------------------------------------------------------
## Stable building blocks (NUMERICAL_METHODS.md, section 2)
## log Phi(a); inverse Mills ratio lambda(a) = phi(a) / Phi(a);
## delta(a) = lambda(a) * (a + lambda(a)) = -d lambda(a) / d a.
## ---------------------------------------------------------------------------
log_Phi <- function(a) pnorm(a, log.p = TRUE)
mills <- function(a) exp(dnorm(a, log = TRUE) - pnorm(a, log.p = TRUE))
## a + lambda(a) without cancellation for a <= -5, from the Laplace continued
## fraction of the Mills ratio: a + lambda(a) = 1/(x + 2/(x + 3/(x + ...))),
## x = -a.
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
## Generated regressors of the two-step estimator (LIKELIHOOD_DERIVATION.md
## s. 9): m1(w) = E[u | u > -w], m0(w) = E[u | u <= -w], and the truncated
## variance terms delta_k(w) = m_k (m_k + w), with dm_k/dw = -delta_k.
m1_fun <- function(w) mills(w)
m0_fun <- function(w) -mills(-w)
d1_fun <- function(w) delta_fun(w)
d0_fun <- function(w) delta_fun(-w)

## ---------------------------------------------------------------------------
## Reference likelihood (LIKELIHOOD_DERIVATION.md, sections 2-6)
## Working parameter vector:
##   theta = (gamma[kz], beta1[k1], beta0[k0], tau1, tau0, alpha1, alpha0),
##   sigma_j = exp(tau_j), rho_j = tanh(alpha_j).
## For an observation in regime j (q_1 = +1, q_0 = -1):
##   e = (y - x_j' beta_j) / sigma_j,  w = z' gamma,
##   a = q_j (w cosh(alpha_j) + e sinh(alpha_j)),
##   log L = -tau_j + log phi(e) + log Phi(a).
## ---------------------------------------------------------------------------
make_index <- function(kz, k1, k0) {
  list(g = seq_len(kz), b1 = kz + seq_len(k1), b0 = kz + k1 + seq_len(k0),
       t1 = kz + k1 + k0 + 1L, t0 = kz + k1 + k0 + 2L,
       a1 = kz + k1 + k0 + 3L, a0 = kz + k1 + k0 + 4L,
       p = kz + k1 + k0 + 4L)
}
blocks <- function(ix, j) {
  if (j == 1) list(b = ix$b1, t = ix$t1, a = ix$a1, q = 1)
  else list(b = ix$b0, t = ix$t0, a = ix$a0, q = -1)
}
pieces <- function(th, d, ix, j) {
  B <- blocks(ix, j)
  sel <- d$S == j
  X <- if (j == 1) d$X1[sel, , drop = FALSE] else d$X0[sel, , drop = FALSE]
  Z <- d$Z[sel, , drop = FALSE]
  sig <- exp(th[B$t]); s <- sinh(th[B$a]); cc <- cosh(th[B$a])
  w <- drop(Z %*% th[ix$g])
  e <- drop(d$y[sel] - X %*% th[B$b]) / sig
  a <- B$q * (w * cc + e * s)
  list(sel = sel, X = X, Z = Z, sig = sig, s = s, cc = cc, w = w, e = e,
       a = a, q = B$q, lam = mills(a), del = delta_fun(a), B = B,
       ll = -th[B$t] + dnorm(e, log = TRUE) + log_Phi(a))
}
loglik_i <- function(th, d, ix) {
  out <- numeric(d$n)
  for (j in c(1, 0)) { P <- pieces(th, d, ix, j); out[P$sel] <- P$ll }
  out
}
loglik <- function(th, d, ix) sum(loglik_i(th, d, ix))

## Analytic per-observation score (LIKELIHOOD_DERIVATION.md, section 5)
score_i <- function(th, d, ix) {
  G <- matrix(0, d$n, ix$p)
  for (j in c(1, 0)) {
    P <- pieces(th, d, ix, j)
    G[P$sel, ix$g] <- P$lam * P$q * P$cc * P$Z
    G[P$sel, P$B$b] <- (P$e - P$lam * P$q * P$s) / P$sig * P$X
    G[P$sel, P$B$t] <- -1 + P$e^2 - P$lam * P$q * P$e * P$s
    G[P$sel, P$B$a] <- P$lam * P$q * (P$w * P$s + P$e * P$cc)
  }
  G
}

## Analytic Hessian (LIKELIHOOD_DERIVATION.md, section 6)
hessian_an <- function(th, d, ix) {
  H <- matrix(0, ix$p, ix$p)
  put <- function(r, c, v) {
    H[r, c] <<- H[r, c] + v
    if (!identical(r, c)) H[c, r] <<- H[c, r] + t(v)
  }
  for (j in c(1, 0)) {
    P <- pieces(th, d, ix, j)
    Z <- P$Z; X <- P$X; e <- P$e; w <- P$w; s <- P$s; cc <- P$cc
    q <- P$q; sig <- P$sig; lam <- P$lam; del <- P$del; a <- P$a
    v <- w * s + e * cc
    g <- ix$g; b <- P$B$b; tt <- P$B$t; al <- P$B$a
    put(g, g, crossprod(Z, -del * cc^2 * Z))
    put(g, b, crossprod(Z, del * cc * s / sig * X))
    put(g, tt, matrix(colSums(del * cc * s * e * Z), ncol = 1))
    put(g, al, matrix(colSums((-del * cc * v + lam * q * s) * Z), ncol = 1))
    put(b, b, crossprod(X, -(1 + del * s^2) / sig^2 * X))
    put(b, tt, matrix(colSums((-2 * e - del * e * s^2 + lam * q * s) / sig * X),
                      ncol = 1))
    put(b, al, matrix(colSums((del * s * v - lam * q * cc) / sig * X), ncol = 1))
    put(tt, tt, matrix(sum(-2 * e^2 - del * e^2 * s^2 + lam * q * s * e)))
    put(tt, al, matrix(sum(del * e * s * v - lam * q * e * cc)))
    put(al, al, matrix(sum(-del * v^2 + lam * a)))
  }
  H
}

## ---------------------------------------------------------------------------
## Simulation design (as in 04_Validation/MONTE_CARLO_DESIGN.md, but with
## different regressor sets per equation to catch indexing errors):
##   z = (1, x1, z1), x1-regime = (1, x1, x2), x0-regime = (1, x1).
## ---------------------------------------------------------------------------
truth <- list(gamma = c(0.5, 0.3, -0.4), beta1 = c(1.5, 0.8, 0.4),
              beta0 = c(1.0, 0.5), sigma1 = 1.2, sigma0 = 0.8,
              rho1 = 0.6, rho0 = 0.4)
ix <- make_index(3, 3, 2)
to_work <- function(P) c(P$gamma, P$beta1, P$beta0, log(P$sigma1),
                         log(P$sigma0), atanh(P$rho1), atanh(P$rho0))
th0 <- to_work(truth)

sim_esr <- function(n, P, r10 = P$rho1 * P$rho0) {
  x1 <- rnorm(n); x2 <- rbinom(n, 1, 0.5); z1 <- rnorm(n)
  Z <- cbind(1, x1, z1); X1 <- cbind(1, x1, x2); X0 <- cbind(1, x1)
  R <- matrix(c(1, P$rho1, P$rho0, P$rho1, 1, r10, P$rho0, r10, 1), 3)
  E <- matrix(rnorm(3 * n), n) %*% chol(R)
  S <- as.integer(drop(Z %*% P$gamma) + E[, 1] > 0)
  y <- ifelse(S == 1, drop(X1 %*% P$beta1) + P$sigma1 * E[, 2],
              drop(X0 %*% P$beta0) + P$sigma0 * E[, 3])
  list(n = n, S = S, y = y, Z = Z, X1 = X1, X0 = X0,
       df = data.frame(S = S, y = y, x1 = x1, x2 = x2, z1 = z1))
}

cat("SwitchEconometrics G1 numerical verification\n")
cat(sprintf("%-5s %-64s %10s    %8s\n", "id", "check", "value", "tol"))

## ---------------------------------------------------------------------------
## V01-V02  Likelihood contributions equal the integrated bivariate density
##          f(y, S=j) = int_{selection set} f(u, eps_j) du
## ---------------------------------------------------------------------------
d <- sim_esr(400, truth)
thr <- th0 + rnorm(ix$p, 0, 0.15)
ll_obs <- loglik_i(thr, d, ix)
err <- c(r1 = 0, r0 = 0)
for (j in c(1, 0)) {
  idx <- sample(which(d$S == j), 10)
  B <- blocks(ix, j)
  sig <- exp(thr[B$t]); rho <- tanh(thr[B$a])
  S2 <- matrix(c(1, rho * sig, rho * sig, sig^2), 2)
  for (i in idx) {
    X <- if (j == 1) d$X1[i, ] else d$X0[i, ]
    eps <- d$y[i] - sum(X * thr[B$b])
    w <- sum(d$Z[i, ] * thr[ix$g])
    f <- function(u) dmvnorm(cbind(u, eps), sigma = S2)
    Lint <- if (j == 1) integrate(f, -w, Inf, rel.tol = 1e-12)$value
            else integrate(f, -Inf, -w, rel.tol = 1e-12)$value
    err[paste0("r", j)] <- max(err[paste0("r", j)],
                               abs(exp(ll_obs[i]) / Lint - 1))
  }
}
record("V01", "L_1i equals integrated density, regime 1 (max rel. error)",
       "LIKELIHOOD_DERIVATION s.2", err["r1"], 1e-8)
record("V02", "L_0i equals integrated density, regime 0 (max rel. error)",
       "LIKELIHOOD_DERIVATION s.2", err["r0"], 1e-8)

## ---------------------------------------------------------------------------
## V03  Proper density: int L_1(y) dy = Phi(w), int L_0(y) dy = 1 - Phi(w)
## ---------------------------------------------------------------------------
e03 <- 0
for (k in 1:5) {
  w <- rnorm(1, 0, 1.5); xb <- rnorm(1); sig <- exp(rnorm(1, 0, 0.3))
  rho <- runif(1, -0.95, 0.95)
  L1 <- function(y) { e <- (y - xb) / sig
    dnorm(e) / sig * pnorm((w + rho * e) / sqrt(1 - rho^2)) }
  L0 <- function(y) { e <- (y - xb) / sig
    dnorm(e) / sig * pnorm(-(w + rho * e) / sqrt(1 - rho^2)) }
  e03 <- max(e03,
             abs(integrate(L1, -Inf, Inf, rel.tol = 1e-12)$value - pnorm(w)),
             abs(integrate(L0, -Inf, Inf, rel.tol = 1e-12)$value - pnorm(-w)))
}
record("V03", "Densities integrate to P(S=1) and P(S=0) (max abs. error)",
       "LIKELIHOOD_DERIVATION s.2", e03, 1e-9)

## ---------------------------------------------------------------------------
## V04-V05  Analytic score and Hessian against numerical derivatives
## ---------------------------------------------------------------------------
e04 <- e05 <- 0
for (k in 1:3) {
  thk <- th0 + rnorm(ix$p, 0, 0.25)
  ga <- colSums(score_i(thk, d, ix))
  gn <- grad(function(t) loglik(t, d, ix), thk)
  e04 <- max(e04, max(abs(ga - gn)) / max(1, abs(gn)))
  Ha <- hessian_an(thk, d, ix)
  Hn <- jacobian(function(t) colSums(score_i(t, d, ix)), thk)
  e05 <- max(e05, max(abs(Ha - Hn)) / max(1, abs(Hn)),
             max(abs(Ha - t(Ha))))
}
record("V04", "Analytic score = numerical gradient (max rel. diff.)",
       "LIKELIHOOD_DERIVATION s.5", e04, 1e-6)
record("V05", "Analytic Hessian = numerical Jacobian of score (max rel.)",
       "LIKELIHOOD_DERIVATION s.6", e05, 1e-6)

## ---------------------------------------------------------------------------
## V06  Information-matrix equality at the true parameters (n = 200000):
##      mean score ~ 0 and -H/n ~ OPG/n
## ---------------------------------------------------------------------------
dbig <- sim_esr(200000, truth)
Sb <- score_i(th0, dbig, ix)
zmax <- max(abs(colMeans(Sb)) / (apply(Sb, 2, sd) / sqrt(dbig$n)))
Hb <- hessian_an(th0, dbig, ix)
rel06 <- norm(-Hb - crossprod(Sb), "F") / norm(-Hb, "F")
record("V06a", "Mean score at truth, max |z| (n = 200000)",
       "LIKELIHOOD_DERIVATION s.7", zmax, 4.5)
record("V06b", "||-H - OPG|| / ||H|| at truth (n = 200000)",
       "LIKELIHOOD_DERIVATION s.7", rel06, 0.03)

## ---------------------------------------------------------------------------
## V07-V08  Conditional means and variances of eps_j given the regime, by
##          two-dimensional numerical integration
##   E[eps_j | S=1] = sigma_j rho_j m1(w),  E[eps_j | S=0] = sigma_j rho_j m0(w)
##   Var(eps_j | S=k) = sigma_j^2 (1 - rho_j^2 delta_k(w))
## ---------------------------------------------------------------------------
e07 <- e08 <- 0
for (k in 1:3) {
  w <- rnorm(1, 0, 1.2); sig <- exp(rnorm(1, 0, 0.3)); rho <- runif(1, -0.9, 0.9)
  S2 <- matrix(c(1, rho * sig, rho * sig, sig^2), 2)
  inner <- function(u, pow) sapply(u, function(uu)
    integrate(function(e) e^pow * dmvnorm(cbind(uu, e), sigma = S2),
              -Inf, Inf, rel.tol = 1e-11)$value)
  for (reg in c(1, 0)) {
    lo <- if (reg == 1) -w else -Inf
    hi <- if (reg == 1) Inf else -w
    pr <- if (reg == 1) pnorm(w) else pnorm(-w)
    m1 <- integrate(function(u) inner(u, 1), lo, hi, rel.tol = 1e-10)$value / pr
    m2 <- integrate(function(u) inner(u, 2), lo, hi, rel.tol = 1e-10)$value / pr
    mk <- if (reg == 1) m1_fun(w) else m0_fun(w)
    dk <- if (reg == 1) d1_fun(w) else d0_fun(w)
    e07 <- max(e07, abs(m1 - sig * rho * mk))
    e08 <- max(e08, abs((m2 - m1^2) - sig^2 * (1 - rho^2 * dk)))
  }
}
record("V07", "E[eps_j | S=k] = sigma rho m_k(w) (max abs. error)",
       "TREATMENT_EFFECTS s.2", e07, 1e-7)
record("V08", "Var(eps_j | S=k) = sigma^2 (1 - rho^2 delta_k) (max abs.)",
       "LIKELIHOOD_DERIVATION s.9", e08, 1e-7)

## ---------------------------------------------------------------------------
## V09  dm_k/dw = -delta_k(w), including far tails
## V10  Stable delta(a) equals -d lambda / d a for a in [-40, 6]
## V11  Mills-ratio bounds -a < lambda(a) < -a - 1/a for a in [-40, -5]
## ---------------------------------------------------------------------------
ws <- c(-12, -8, -3, -1, 0, 0.7, 2, 5, 9, 12)
e09 <- max(abs(sapply(ws, function(w) grad(m1_fun, w)) + d1_fun(ws)) /
             pmax(1, d1_fun(ws)),
           abs(sapply(ws, function(w) grad(m0_fun, w)) + d0_fun(ws)) /
             pmax(1, d0_fun(ws)))
record("V09", "dm_k/dw = -delta_k(w) (max rel. diff.)",
       "LIKELIHOOD_DERIVATION s.9", e09, 1e-7)
as <- c(seq(-40, -5, by = 2.5), -4.9, -3, -1, 0, 1, 3, 6)
dl <- sapply(as, function(a) grad(mills, a))
e10 <- max(abs(delta_fun(as) + dl) / pmax(abs(dl), 1e-300))
record("V10", "Stable delta(a) = -lambda'(a) on [-40, 6] (max rel. diff.)",
       "NUMERICAL_METHODS s.2", e10, 1e-6)
ab <- seq(-40, -5, by = 0.25)
viol <- sum(!(mills(ab) > -ab & mills(ab) < -ab - 1 / ab))
record("V11", "Mills ratio inside its bounds on [-40, -5] (violations)",
       "NUMERICAL_METHODS s.2", viol, 0)

## ---------------------------------------------------------------------------
## V12  sigma_10 is not identified: P(S=1, Y <= y) from the trivariate normal
##      is the same for any admissible Corr(eps1, eps0); the admissible range
##      (Koop and Poirier 1997) has zero determinant at its end points.
## ---------------------------------------------------------------------------
e12a <- e12b <- 0
for (k in 1:4) {
  r1 <- runif(1, -0.9, 0.9); r0 <- runif(1, -0.9, 0.9)
  w <- rnorm(1); s1 <- exp(rnorm(1, 0, 0.3)); s0 <- exp(rnorm(1, 0, 0.3))
  half <- sqrt((1 - r1^2) * (1 - r0^2))
  lo <- r1 * r0 - half; hi <- r1 * r0 + half
  Rr <- function(r10) matrix(c(1, r1, r0, r1, 1, r10, r0, r10, 1), 3)
  e12b <- max(e12b, abs(det(Rr(lo))), abs(det(Rr(hi))),
              abs(det(Rr(r1 * r0)) - (1 - r1^2) * (1 - r0^2)))
  Sig <- function(r10) diag(c(1, s1, s0)) %*% Rr(r10) %*% diag(c(1, s1, s0))
  yv <- rnorm(1, 0, s1)
  pr <- sapply(c(lo + 0.1 * (hi - lo), r1 * r0, hi - 0.1 * (hi - lo)),
               function(r10) pmvnorm(lower = c(-w, -Inf, -Inf),
                                     upper = c(Inf, yv, Inf), sigma = Sig(r10),
                                     algorithm = Miwa(steps = 4097))[1])
  e12a <- max(e12a, diff(range(pr)))
}
record("V12a", "P(S=1, Y<=y) invariant to Corr(eps1, eps0) (range)",
       "IDENTIFICATION s.3", e12a, 1e-9)
record("V12b", "det R = 0 at the admissible bounds of Corr(eps1, eps0)",
       "IDENTIFICATION s.3", e12b, 1e-12)

## ---------------------------------------------------------------------------
## Two-step estimator (LIKELIHOOD_DERIVATION.md, section 9)
## ---------------------------------------------------------------------------
two_step <- function(d) {
  pr <- glm.fit(d$Z, d$S, family = binomial(link = "probit"),
                control = glm.control(epsilon = 1e-14, maxit = 100))
  g <- pr$coefficients
  w <- drop(d$Z %*% g)
  p <- pnorm(w); f <- dnorm(w)
  Ig <- crossprod(d$Z * sqrt(f^2 / (p * (1 - p))))
  Vg <- solve(Ig)
  out <- list(gamma = g, Vg = Vg, Ig = Ig, w = w)
  for (j in c(1, 0)) {
    sel <- d$S == j
    X <- if (j == 1) d$X1[sel, , drop = FALSE] else d$X0[sel, , drop = FALSE]
    m <- if (j == 1) m1_fun(w[sel]) else m0_fun(w[sel])
    D <- if (j == 1) d1_fun(w[sel]) else d0_fun(w[sel])
    W <- cbind(X, m); Zs <- d$Z[sel, , drop = FALSE]
    fit <- lm.fit(W, d$y[sel])
    b <- fit$coefficients; th <- b[length(b)]; eh <- fit$residuals
    s2 <- mean(eh^2) + th^2 * mean(D)
    rho <- th / sqrt(s2)
    WWi <- solve(crossprod(W))
    WDZ <- crossprod(W * D, Zs)
    V <- s2 * WWi %*% (crossprod(W * (1 - rho^2 * D), W) +
                         rho^2 * WDZ %*% Vg %*% t(WDZ)) %*% WWi
    out[[paste0("r", j)]] <- list(b = b, theta = th, sigma = sqrt(s2),
                                  rho = rho, V = V, WWi = WWi, WDZ = WDZ,
                                  W = W, e = eh, sel = sel)
  }
  out$C10 <- out$r1$WWi %*% (out$r1$theta * out$r1$WDZ) %*% out$Vg %*%
    t(out$r0$theta * out$r0$WDZ) %*% out$r0$WWi
  ## Stacked M-estimator sandwich (heteroskedasticity-robust alternative)
  k1 <- ncol(out$r1$W); k0 <- ncol(out$r0$W); kz <- ncol(d$Z)
  sg <- (d$S - p) * f / (p * (1 - p)) * d$Z
  M <- matrix(0, d$n, kz + k1 + k0)
  M[, seq_len(kz)] <- sg
  M[out$r1$sel, kz + seq_len(k1)] <- out$r1$e * out$r1$W
  M[out$r0$sel, kz + k1 + seq_len(k0)] <- out$r0$e * out$r0$W
  A <- matrix(0, kz + k1 + k0, kz + k1 + k0)
  A[seq_len(kz), seq_len(kz)] <- -Ig
  A[kz + seq_len(k1), seq_len(kz)] <- out$r1$theta * out$r1$WDZ
  A[kz + seq_len(k1), kz + seq_len(k1)] <- -crossprod(out$r1$W)
  A[kz + k1 + seq_len(k0), seq_len(kz)] <- out$r0$theta * out$r0$WDZ
  A[kz + k1 + seq_len(k0), kz + k1 + seq_len(k0)] <- -crossprod(out$r0$W)
  Ai <- solve(A)
  out$Vrob <- Ai %*% crossprod(M) %*% t(Ai)
  out$kz <- kz; out$k1 <- k1; out$k0 <- k0
  out
}

## V13  Two-step consistency on a very large sample
dl2 <- sim_esr(400000, truth)
ts <- two_step(dl2)
est13 <- c(ts$gamma, head(ts$r1$b, -1), head(ts$r0$b, -1), ts$r1$sigma,
           ts$r0$sigma, ts$r1$rho, ts$r0$rho)
tru13 <- c(truth$gamma, truth$beta1, truth$beta0, truth$sigma1, truth$sigma0,
           truth$rho1, truth$rho0)
record("V13", "Two-step estimates near truth, n = 400000 (max abs. diff.)",
       "LIKELIHOOD_DERIVATION s.9", max(abs(est13 - tru13)), 0.02)

## V14  Two-step covariance formulas against Monte Carlo (R = 1000, n = 1500)
Rmc <- 1000
est <- seMod <- seRob <- matrix(NA_real_, Rmc, 0)
keep <- list()
for (r in seq_len(Rmc)) {
  dr <- sim_esr(1500, truth)
  tr <- two_step(dr)
  i1 <- tr$kz + seq_len(tr$k1); i0 <- tr$kz + tr$k1 + seq_len(tr$k0)
  th1 <- tr$k1; th0i <- tr$k0
  vd <- tr$r1$V[th1, th1] + tr$r0$V[th0i, th0i] - 2 * tr$C10[th1, th0i]
  vdr <- tr$Vrob[i1[th1], i1[th1]] + tr$Vrob[i0[th0i], i0[th0i]] -
    2 * tr$Vrob[i1[th1], i0[th0i]]
  keep[[r]] <- c(est = c(tr$r1$b, tr$r0$b, tr$r1$theta - tr$r0$theta),
                 mod = c(sqrt(diag(tr$r1$V)), sqrt(diag(tr$r0$V)), sqrt(vd)),
                 rob = c(sqrt(diag(tr$Vrob))[c(i1, i0)], sqrt(vdr)))
}
K <- do.call(rbind, keep)
np <- (ncol(K)) / 3
sdemp <- apply(K[, seq_len(np)], 2, sd)
ratio_mod <- colMeans(K[, np + seq_len(np)]) / sdemp
ratio_rob <- colMeans(K[, 2 * np + seq_len(np)]) / sdemp
record("V14a", "Two-step model-based SE / empirical SD, max |ratio - 1|",
       "LIKELIHOOD_DERIVATION s.9", max(abs(ratio_mod - 1)), 0.10)
record("V14b", "Two-step stacked-sandwich SE / empirical SD, max |r - 1|",
       "LIKELIHOOD_DERIVATION s.9", max(abs(ratio_rob - 1)), 0.10)

## ---------------------------------------------------------------------------
## Treatment effects (TREATMENT_EFFECTS.md, sections 3-5)
## ---------------------------------------------------------------------------
effects_fun <- function(th, d, ix) {
  s1 <- exp(th[ix$t1]); s0 <- exp(th[ix$t0])
  r1 <- tanh(th[ix$a1]); r0 <- tanh(th[ix$a0])
  w <- drop(d$Z %*% th[ix$g]); m1 <- m1_fun(w); m0 <- m0_fun(w)
  xb1 <- drop(d$X1 %*% th[ix$b1]); xb0 <- drop(d$X0 %*% th[ix$b0])
  EY1S1 <- xb1 + s1 * r1 * m1; EY1S0 <- xb1 + s1 * r1 * m0
  EY0S1 <- xb0 + s0 * r0 * m1; EY0S0 <- xb0 + s0 * r0 * m0
  T1 <- d$S == 1; T0 <- !T1
  ATT <- mean(EY1S1[T1] - EY0S1[T1]); ATU <- mean(EY1S0[T0] - EY0S0[T0])
  c(ATT = ATT, ATU = ATU, ATE = mean(xb1 - xb0), TH = ATT - ATU,
    BH1 = mean(EY1S1[T1]) - mean(EY1S0[T0]),
    BH0 = mean(EY0S1[T1]) - mean(EY0S0[T0]))
}
effects_grad <- function(th, d, ix) {
  s1 <- exp(th[ix$t1]); s0 <- exp(th[ix$t0])
  r1 <- tanh(th[ix$a1]); r0 <- tanh(th[ix$a0])
  q1 <- s1 * r1; q0 <- s0 * r0                     # theta_j = sigma_j rho_j
  w <- drop(d$Z %*% th[ix$g])
  m1 <- m1_fun(w); m0 <- m0_fun(w); D1 <- d1_fun(w); D0 <- d0_fun(w)
  T1 <- d$S == 1; T0 <- !T1
  mT <- function(v) if (is.matrix(v)) colMeans(v[T1, , drop = FALSE]) else mean(v[T1])
  mU <- function(v) if (is.matrix(v)) colMeans(v[T0, , drop = FALSE]) else mean(v[T0])
  G <- matrix(0, 6, ix$p, dimnames = list(c("ATT", "ATU", "ATE", "TH", "BH1", "BH0"), NULL))
  dz1 <- mT(-D1 * d$Z); dz0 <- mU(-D0 * d$Z)
  ## ATT
  G["ATT", ix$g] <- (q1 - q0) * dz1
  G["ATT", ix$b1] <- mT(d$X1); G["ATT", ix$b0] <- -mT(d$X0)
  G["ATT", ix$t1] <- q1 * mT(m1); G["ATT", ix$t0] <- -q0 * mT(m1)
  G["ATT", ix$a1] <- s1 * (1 - r1^2) * mT(m1)
  G["ATT", ix$a0] <- -s0 * (1 - r0^2) * mT(m1)
  ## ATU
  G["ATU", ix$g] <- (q1 - q0) * dz0
  G["ATU", ix$b1] <- mU(d$X1); G["ATU", ix$b0] <- -mU(d$X0)
  G["ATU", ix$t1] <- q1 * mU(m0); G["ATU", ix$t0] <- -q0 * mU(m0)
  G["ATU", ix$a1] <- s1 * (1 - r1^2) * mU(m0)
  G["ATU", ix$a0] <- -s0 * (1 - r0^2) * mU(m0)
  ## ATE
  G["ATE", ix$b1] <- colMeans(d$X1); G["ATE", ix$b0] <- -colMeans(d$X0)
  ## TH
  G["TH", ] <- G["ATT", ] - G["ATU", ]
  ## BH1, BH0
  G["BH1", ix$g] <- q1 * (dz1 - dz0)
  G["BH1", ix$b1] <- mT(d$X1) - mU(d$X1)
  G["BH1", ix$t1] <- q1 * (mT(m1) - mU(m0))
  G["BH1", ix$a1] <- s1 * (1 - r1^2) * (mT(m1) - mU(m0))
  G["BH0", ix$g] <- q0 * (dz1 - dz0)
  G["BH0", ix$b0] <- mT(d$X0) - mU(d$X0)
  G["BH0", ix$t0] <- q0 * (mT(m1) - mU(m0))
  G["BH0", ix$a0] <- s0 * (1 - r0^2) * (mT(m1) - mU(m0))
  G
}
the <- th0 + rnorm(ix$p, 0, 0.2)
Ga <- effects_grad(the, d, ix)
Gn <- jacobian(function(t) effects_fun(t, d, ix), the)
record("V15a", "Effect gradients (delta method) = numerical Jacobian",
       "TREATMENT_EFFECTS s.5", max(abs(Ga - Gn)) / max(1, abs(Gn)), 1e-7)
ef <- effects_fun(the, d, ix)
record("V15b", "Identity BH1 - BH0 = TH",
       "TREATMENT_EFFECTS s.3", abs(ef["BH1"] - ef["BH0"] - ef["TH"]), 1e-12)
## At the probit MLE (with an intercept) the sample ATE equals the
## share-weighted average of ATT and ATU.
tsd <- two_step(d)
thp <- the; thp[ix$g] <- tsd$gamma
efp <- effects_fun(thp, d, ix); pi1 <- mean(d$S)
record("V15c", "ATE = pi ATT + (1 - pi) ATU at the probit MLE",
       "TREATMENT_EFFECTS s.3",
       abs(pi1 * efp["ATT"] + (1 - pi1) * efp["ATU"] - efp["ATE"]), 1e-8)

## ---------------------------------------------------------------------------
## V16  Counterfactual and policy expectations by simulation (4e6 draws)
##   E[eps0 | S=1] = sigma0 rho0 m1(w)  (counterfactual mean for adopters)
##   E[Y* | x, z*] = x1'b1 Phi(w*) + x0'b0 (1 - Phi(w*))
##                   + (sigma1 rho1 - sigma0 rho0) phi(w*)
## ---------------------------------------------------------------------------
Nd <- 4e6
R3 <- matrix(c(1, truth$rho1, truth$rho0, truth$rho1, 1, 0.1,
               truth$rho0, 0.1, 1), 3)
E3 <- matrix(rnorm(3 * Nd), Nd) %*% chol(R3)
wst <- 0.35; xb1 <- 2.1; xb0 <- 1.2
S1 <- wst + E3[, 1] > 0
e0 <- truth$sigma0 * E3[, 3]; e1 <- truth$sigma1 * E3[, 2]
z16a <- abs(mean(e0[S1]) - truth$sigma0 * truth$rho0 * m1_fun(wst)) /
  (sd(e0[S1]) / sqrt(sum(S1)))
Ystar <- ifelse(S1, xb1 + e1, xb0 + e0)
pol <- xb1 * pnorm(wst) + xb0 * pnorm(-wst) +
  (truth$sigma1 * truth$rho1 - truth$sigma0 * truth$rho0) * dnorm(wst)
z16b <- abs(mean(Ystar) - pol) / (sd(Ystar) / sqrt(Nd))
record("V16a", "E[eps0 | S=1] by simulation, |z| (4e6 draws)",
       "TREATMENT_EFFECTS s.2", z16a, 4)
record("V16b", "Policy expectation E[Y* | x, z*] by simulation, |z|",
       "TREATMENT_EFFECTS s.6", z16b, 4)
rm(E3, e0, e1, Ystar, S1)

## ---------------------------------------------------------------------------
## V17  Same likelihood as sampleSelection tobit-5 (convention mapping of
##      BINARY_ESR.md s.6): our log-likelihood at sampleSelection's ML
##      estimates equals its reported log-likelihood.
## ---------------------------------------------------------------------------
if (requireNamespace("sampleSelection", quietly = TRUE)) {
  d17 <- sim_esr(3000, truth)
  f17 <- sampleSelection::selection(S ~ x1 + z1, list(y ~ x1, y ~ x1 + x2),
                                    data = d17$df, method = "ml")
  cf <- coef(f17)
  stopifnot(length(cf) == 12)
  ## positions: S 1:3 | O1 (S = 0): 4:5, sigma1 6, rho1 7 |
  ##            O2 (S = 1): 8:10, sigma2 11, rho2 12
  th17 <- c(cf[1:3], cf[8:10], cf[4:5], log(cf[11]), log(cf[6]),
            atanh(cf[12]), atanh(cf[7]))
  record("V17a", "Our log-lik at sampleSelection ML = its log-lik (abs.)",
         "BINARY_ESR s.6",
         abs(loglik(th17, d17, ix) - as.numeric(logLik(f17))), 1e-6)
  g17 <- colSums(score_i(th17, d17, ix))
  record("V17b", "Our score at sampleSelection ML estimate (max abs.)",
         "BINARY_ESR s.6", max(abs(g17)), 1e-2)
} else {
  cat("V17   sampleSelection not installed: skipped\n")
}

## ---------------------------------------------------------------------------
## V18  Delta-method Jacobians of the transformations
##      d sigma / d tau = sigma,  d rho / d alpha = 1 - rho^2
## ---------------------------------------------------------------------------
tv <- c(-1.3, 0, 0.4, 2.2)
e18 <- max(abs(sapply(tv, function(t) grad(exp, t)) - exp(tv)),
           abs(sapply(tv, function(t) grad(tanh, t)) - (1 - tanh(tv)^2)))
record("V18", "Jacobians of exp and tanh transformations (max abs.)",
       "PARAMETERIZATION s.3", e18, 1e-9)

## ---------------------------------------------------------------------------
## V19  Nesting: at rho1 = rho0 = 0 the likelihood factorises into probit +
##      two Gaussian regressions (restricted model of the LR test)
## ---------------------------------------------------------------------------
pr19 <- glm(S ~ x1 + z1, family = binomial(link = "probit"), data = d$df,
            control = glm.control(epsilon = 1e-14))
l1 <- lm(y ~ x1 + x2, data = d$df, subset = S == 1)
l0 <- lm(y ~ x1, data = d$df, subset = S == 0)
sig_ml <- function(m) sqrt(mean(residuals(m)^2))
th19 <- c(coef(pr19), coef(l1), coef(l0), log(sig_ml(l1)), log(sig_ml(l0)),
          0, 0)
lr <- as.numeric(logLik(pr19)) + as.numeric(logLik(l1)) +
  as.numeric(logLik(l0))
record("V19", "rho = 0 likelihood = probit + two OLS log-liks (abs.)",
       "LIKELIHOOD_DERIVATION s.8", abs(loglik(th19, d, ix) - lr), 1e-8)

## ---------------------------------------------------------------------------
## Summary
## ---------------------------------------------------------------------------
el <- as.numeric(difftime(Sys.time(), t_start, units = "secs"))
cat(sprintf("\n%d checks, %d passed, %d failed; %.1f s; R %s, mvtnorm %s, numDeriv %s%s\n",
            nrow(res), sum(res$pass), sum(!res$pass), el,
            getRversion(), packageVersion("mvtnorm"), packageVersion("numDeriv"),
            if (requireNamespace("sampleSelection", quietly = TRUE))
              paste0(", sampleSelection ", packageVersion("sampleSelection")) else ""))
utils::write.csv(res, "verify_math_results.csv", row.names = FALSE)
if (any(!res$pass)) quit(status = 1)
