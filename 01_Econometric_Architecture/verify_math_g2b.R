## verify_math_g2b.R -- numerical verification, G2 gate amendments
## SwitchEconometrics, 23 November 2026. Supplements verify_math_g2.R (which
## is unchanged) after the owner's gate decision:
##   X01-X02  the `endogenous` benchmark (gate question 2)
##   X10-X14  the normal-score multinomial logit model (gate question 3),
##            MULTINOMIAL_ESR.md section 11
##   X20-X24  the models with J = 8 regimes (gate question 9)
## The reference code is independent of the package sources.
##
## Run from this folder:
##   Rscript --no-init-file verify_math_g2b.R
## Requires mvtnorm and numDeriv. X01-X02 need `endogenous` 1.0 in the private
## library ../../runs/lib_g2 (workspace level) and are skipped without it.
## Writes verify_math_g2b_results.csv and exits with status 1 on any failure.

suppressPackageStartupMessages({ library(mvtnorm); library(numDeriv) })
set.seed(20261123)
t0 <- proc.time()[["elapsed"]]
res <- list()
record <- function(id, check, value, tol) {
  ok <- is.finite(value) && value <= tol
  res[[length(res) + 1L]] <<- data.frame(id = id, check = check,
    value = value, tol = tol, pass = ok, stringsAsFactors = FALSE)
  cat(sprintf("%-5s %-4s %-66s %.3g (tol %.3g)\n", id,
              if (ok) "ok" else "FAIL", check, value, tol))
}
## exact row-wise argmax (max.col() treats near-equal values as ties)
argmax <- function(M) {
  m <- M[, 1L]; s <- rep(1L, nrow(M))
  for (k in 2:ncol(M)) { b <- M[, k] > m; s[b] <- k; m[b] <- M[b, k] }
  s
}
zstat <- function(x, target) abs(mean(x) - target) / (sd(x) / sqrt(length(x)))
mills <- function(a) exp(dnorm(a, log = TRUE) - pnorm(a, log.p = TRUE))
simpson <- function(f, a, b, n = 400L) {
  x <- seq(a, b, length.out = n + 1L); w <- rep(c(2, 4), length.out = n + 1L)
  w[c(1L, n + 1L)] <- 1
  sum(w * f(x)) * (b - a) / (3 * n)
}
gauss_hermite <- function(n) {            # nodes/weights for weight phi(t)
  J <- matrix(0, n, n); k <- seq_len(n - 1L)
  J[cbind(k, k + 1L)] <- sqrt(k); J[cbind(k + 1L, k)] <- sqrt(k)
  ev <- eigen(J, symmetric = TRUE)
  list(x = ev$values, w = ev$vectors[1L, ]^2)
}

## ===========================================================================
## PART A  The `endogenous` benchmark (OBSERVATION_MECHANISMS.md s.8)
## ===========================================================================
## Treatment model: y = x'beta + S d'delta + eps, S = 1(w'gamma + u > 0),
## rho = Corr(u, eps). Per-observation log-likelihood (decision D6):
treat_ll <- function(th, y, X, D, W, S) {
  kw <- ncol(W); kx <- ncol(X); kd <- ncol(D)
  g <- th[seq_len(kw)]; b <- th[kw + seq_len(kx)]
  dl <- th[kw + kx + seq_len(kd)]
  sig <- exp(th[kw + kx + kd + 1L]); rho <- tanh(th[kw + kx + kd + 2L])
  e <- (y - X %*% b - S * (D %*% dl)) / sig
  q <- 2 * S - 1
  -log(sig) + dnorm(e, log = TRUE) +
    pnorm(q * (W %*% g + rho * e) / sqrt(1 - rho^2), log.p = TRUE)
}
lib_g2 <- normalizePath(file.path("..", "..", "runs", "lib_g2"),
                        mustWork = FALSE)
have_endo <- dir.exists(file.path(lib_g2, "endogenous"))
if (have_endo) {
  suppressPackageStartupMessages(library(endogenous, lib.loc = lib_g2))
  n <- 3000L
  x1 <- rnorm(n); x2 <- rnorm(n); z1 <- rnorm(n)
  uu <- rnorm(n); ee <- 0.5 * uu + sqrt(1 - 0.25) * rnorm(n)
  ss <- as.numeric(0.2 + 0.5 * x1 + 0.8 * z1 + uu > 0)
  X <- cbind(1, x1, x2); W <- cbind(1, x1, z1)
  for (hyb in 1:2) {
    D <- if (hyb == 1L) matrix(1, n, 1L) else cbind(1, x1)
    dl0 <- if (hyb == 1L) 0.7 else c(0.7, -0.4)
    yy <- as.numeric(1 + 0.5 * x1 - 0.3 * x2 + ss * (D %*% dl0) + 1.2 * ee)
    ## hybrid() reads its variables from the calling environment
    assign("yy", yy, globalenv()); assign("ss", ss, globalenv())
    fit <- if (hyb == 1L) hybrid(yy ~ x1 + x2, ss ~ x1 + z1, se = "M") else
      hybrid(yy ~ x1 + x2, ss ~ x1 + z1, modifiers = ~ x1, se = "M")
    ## mapping: endogenous writes the mean as x'beta - S v'eta: delta = -eta
    th_e <- c(fit$alpha, fit$beta, -fit$eta, log(fit$sigma), atanh(fit$rho))
    f <- function(th) -sum(treat_ll(th, yy, X, D, W, ss))
    op <- optim(th_e, f, method = "BFGS",
                control = list(reltol = 1e-14, maxit = 500))
    for (it in 1:3) {                       # Newton polish of the maximum
      op$par <- op$par - solve(numDeriv::hessian(f, op$par),
                               numDeriv::grad(f, op$par))
    }
    op$value <- f(op$par)
    gr <- numDeriv::grad(f, op$par)
    V <- solve(numDeriv::hessian(f, op$par))
    ## compare on the natural scale (sigma, rho)
    nat <- function(th) { k <- length(th)
      c(th[seq_len(k - 2L)], exp(th[k - 1L]), tanh(th[k])) }
    Jn <- numDeriv::jacobian(nat, op$par)
    se_ours <- sqrt(diag(Jn %*% V %*% t(Jn)))
    se_endo <- sqrt(diag(fit$vcov))
    lab <- if (hyb == 1L) "constant shift" else "hybrid, modifiers ~ x1"
    record(sprintf("X0%da", hyb),
           paste0("endogenous::hybrid ML estimates = ours (", lab, ")"),
           max(abs(nat(th_e) - nat(op$par))), 5e-3)
    record(sprintf("X0%db", hyb),
           paste0("log-lik at its estimates within 1e-4 of our maximum (",
                  lab, ")"), f(th_e) - op$value, 1e-4)
    record(sprintf("X0%dc", hyb),
           paste0("its model-based std. errors = ours, rel. diff (", lab, ")"),
           max(abs(se_endo / se_ours - 1)), 0.03)
    record(sprintf("X0%dd", hyb), "our score at our maximum",
           max(abs(gr)), 1e-3)
  }
} else cat("X01-X02 skipped: `endogenous` not found in", lib_g2, "\n")

## ===========================================================================
## PART B  Normal-score multinomial logit model (MULTINOMIAL_ESR.md s.11)
## ===========================================================================
## Utilities U_k = v_k + eps*_k, eps*_k iid Gumbel; normal scores
## eta_k = qnorm(G(eps*_k)) iid N(0,1); outcome disturbance u = eps_j/sigma_j
## with (u, eta) jointly normal, Corr(u, eta_k) = r_k, sum r_k^2 < 1.
## S = k  iff  eta_m < h_m(eta_k) = qnorm(pnorm(eta_k)^{exp(v_m - v_k)}).
hfun <- function(t, a) qnorm(a * pnorm(t, log.p = TRUE), log.p = TRUE)

## joint density of (u = e, S = k): phi(e) * P(S = k | u = e), with the
## inner (J-1)-rectangle given (eta_k, u) and an outer integral over eta_k
ns_dens <- function(e, k, v, r, gh = NULL) {
  J <- length(v); o <- setdiff(seq_len(J), k)
  a <- exp(v[o] - v[k]); rk <- r[k]; ro <- r[o]
  Sc <- diag(J - 1L) - tcrossprod(ro) / (1 - rk^2)
  inner <- function(t) vapply(t, function(tt) {
    mu <- ro * (e - rk * tt) / (1 - rk^2)
    if (J == 2L) pnorm((hfun(tt, a) - mu) / sqrt(Sc[1L]))
    else as.numeric(pmvnorm(upper = hfun(tt, a) - mu, sigma = Sc,
      algorithm = if (J <= 4L) TVPACK(1e-12) else
        GenzBretz(maxpts = 2e5, abseps = 1e-7)))
  }, 0)
  sdk <- sqrt(1 - rk^2)
  val <- if (is.null(gh))
    integrate(function(t) dnorm(t, rk * e, sdk) * inner(t),
              rk * e - 8.5 * sdk, rk * e + 8.5 * sdk,
              rel.tol = 1e-10, subdivisions = 400L)$value
  else sum(gh$w * inner(rk * e + sdk * gh$x))
  dnorm(e) * val
}
mnlP <- function(v) exp(v - max(v)) / sum(exp(v - max(v)))
## BFG normalised moments: E[eta_k | S = k] = m(P_k);
## E[eta_m | S = k] = m(P_m) P_m / (P_m - 1), m != k
bfg_m <- function(P) integrate(function(x)
  qnorm(-exp(-(x - log(P))), log.p = TRUE) * exp(-x - exp(-x)), -6, 40,
  rel.tol = 1e-11)$value
bfg_M <- function(P) {                    # M[m, k] = E[eta_m | S = k]
  J <- length(P); mm <- vapply(P, bfg_m, 0)
  M <- matrix(mm * P / (P - 1), J, J); diag(M) <- mm; M
}
sim_ns <- function(N, v, r) {
  J <- length(v); U <- matrix(runif(N * J), N, J)
  eta <- qnorm(U); S <- argmax(sweep(-log(-log(U)), 2L, v, "+"))
  list(S = S, eta = eta,
       u = as.numeric(eta %*% r) + sqrt(1 - sum(r^2)) * rnorm(N))
}

v3 <- c(0, 0.4, -0.3); r3 <- c(0.5, -0.3, 0.2); P3 <- mnlP(v3)
sm <- sim_ns(2e6L, v3, r3)

## X10  event identity: S = k iff eta_m < h_m(eta_k) for all m != k (exact)
ev <- vapply(1:3, function(k) {
  o <- setdiff(1:3, k)
  inr <- sm$eta[, o[1L]] < hfun(sm$eta[, k], exp(v3[o[1L]] - v3[k])) &
         sm$eta[, o[2L]] < hfun(sm$eta[, k], exp(v3[o[2L]] - v3[k]))
  sum(inr != (sm$S == k))
}, 0)
record("X10", "normal scores: S = k iff eta_m < h_m(eta_k) (mismatches)",
       sum(ev), 0)

## X11  proper density: the contribution integrates to P_k, k = 1..3;
##      simulated joint law P(S = k, u <= c)
dens3 <- function(k) function(e) vapply(e, ns_dens, 0, k = k, v = v3, r = r3)
tot <- vapply(1:3, function(k) simpson(dens3(k), -8, 8, 160L), 0)
record("X11a", "normal scores: int of contribution = P_k (J = 3)",
       max(abs(tot - P3)), 1e-8)
zz <- 0
for (k in 1:3) for (cc in c(-0.8, 0.3, 1.1)) {
  pr <- simpson(dens3(k), -8, cc, 120L)
  zz <- max(zz, zstat(as.numeric(sm$S == k & sm$u <= cc), pr))
}
record("X11b", "normal scores: simulated P(S = k, u <= c), max |z|", zz, 4)

## X12  conditional means for every (regime of the disturbance, regime
##      chosen): E[u | S = k] = sum_m r_m E[eta_m | S = k] (the BFG
##      normalised moments), against the contribution and simulation.
##      No assumption beyond the model is needed for k != j.
M3 <- bfg_M(P3)
mean_form <- as.numeric(r3 %*% M3)
mean_dens <- vapply(1:3, function(k)
  simpson(function(e) e * dens3(k)(e), -8, 8, 160L), 0) / P3
record("X12a", "normal scores: E[u | S = k] from contribution = r'M",
       max(abs(mean_form - mean_dens)), 1e-7)
record("X12b", "normal scores: E[u | S = k] by simulation, max |z|",
       max(vapply(1:3, function(k) zstat(sm$u[sm$S == k], mean_form[k]), 0)),
       4)
record("X12c", "normal scores: E[u | S = k] differs across k (min gap > 0.05)",
       as.numeric(min(dist(mean_form)) < 0.05), 0)

## X13  J = 2: logit selection with two correlations (not G1)
v2 <- c(0, 0.6); r2 <- c(0.45, -0.35); P2 <- mnlP(v2)
tot2 <- vapply(1:2, function(k) simpson(function(e)
  vapply(e, ns_dens, 0, k = k, v = v2, r = r2), -8, 8, 160L), 0)
record("X13", "normal scores: int of contribution = P_k (J = 2)",
       max(abs(tot2 - P2)), 1e-8)

## X14  J = 8: contribution with a 7-dimensional inner rectangle (Genz-Bretz)
##      and Gauss-Hermite outer rule, against simulation
v8 <- c(0, 0.5, -0.4, 0.3, -0.2, 0.6, 0.1, -0.5)
r8 <- c(0.35, -0.25, 0.2, 0.3, -0.15, 0.1, -0.3, 0.25)
P8 <- mnlP(v8); gh <- gauss_hermite(32L)
sm8 <- sim_ns(2e6L, v8, r8)
dens8 <- function(k) function(e)
  vapply(e, ns_dens, 0, k = k, v = v8, r = r8, gh = gh)
zz <- 0; tot8 <- 0
for (k in c(1L, 6L)) {
  eg <- seq(-6, 6, length.out = 49L); dv <- dens8(k)(eg)
  w <- rep(c(2, 4), length.out = 49L); w[c(1L, 49L)] <- 1
  tot8 <- max(tot8, abs(sum(w * dv) * 0.25 / 3 - P8[k]))
  idx <- which(eg <= 0.5 + 1e-12)              # 27 points: even panel count
  pr <- sum(w[idx] * c(rep(1, 26L), 0.5) * dv[idx]) * 0.25 / 3
  zz <- max(zz, zstat(as.numeric(sm8$S == k & sm8$u <= 0.5), pr))
}
record("X14a", "normal scores, J = 8: int of contribution = P_k", tot8, 2e-5)
record("X14b", "normal scores, J = 8: simulated P(S = k, u <= 0.5), max |z|",
       zz, 4)
M8 <- bfg_M(P8); mf8 <- as.numeric(r8 %*% M8)
record("X14c", "normal scores, J = 8: E[u | S = k] = r'M, all k, max |z|",
       max(vapply(1:8, function(k) zstat(sm8$u[sm8$S == k], mf8[k]), 0)), 4)

## ===========================================================================
## PART C  Eight regimes (gate question 9)
## ===========================================================================
## X20  Lee, J = 8: joint law and the 7 counterfactual means of one regime
N <- 2e6L
E8 <- matrix(-log(-log(runif(N * 8L))), N, 8L)
U8 <- sweep(E8, 2L, v8, "+"); S8 <- argmax(U8)
zz1 <- 0; zz2 <- 0
for (j in c(1L, 8L)) {
  lee <- apply(U8[, -j, drop = FALSE], 1L, max) - E8[, j]   # eps*_j
  Fj <- 1 / (1 + sum(exp(v8[-j])) * exp(-lee))
  us <- -qnorm(Fj); rho <- if (j == 1L) 0.6 else -0.45
  ej <- rho * us + sqrt(1 - rho^2) * rnorm(N)
  wj <- qnorm(P8[j])
  for (cc in c(-0.5, 0.7)) {
    pr <- integrate(function(e) dnorm(e) *
      pnorm((wj + rho * e) / sqrt(1 - rho^2)), -Inf, cc, rel.tol = 1e-11)$value
    zz1 <- max(zz1, zstat(as.numeric(S8 == j & ej <= cc), pr))
  }
  zz2 <- max(zz2, zstat(ej[S8 == j], rho * mills(wj)),
             vapply(setdiff(1:8, j), function(k)
               zstat(ej[S8 == k], -rho * mills(-wj)), 0))
}
record("X20a", "Lee, J = 8: simulated P(S = j, eps_j <= c), max |z|", zz1, 4)
record("X20b", "Lee, J = 8: E[eps_j | S = k], own and 7 others, max |z|",
       zz2, 4)

## X21-X23  multinomial probit, J = 8: seven utility differences against the
## base, unrestricted covariance Omega with Omega[1,1] = 1, one outcome
## disturbance; regime regions as rectangles of A_j U*.
d <- 7L
B <- matrix(rnorm(d * d), d, d) * 0.35 + diag(d)
Om <- tcrossprod(B); Om <- Om / Om[1L, 1L]
psi <- c(0.3, -0.2, 0.25, 0.1, -0.15, 0.2, -0.1) * sqrt(diag(Om))  # Cov(u,eps)
psi <- psi * sqrt(0.5 / as.numeric(crossprod(psi, solve(Om, psi))))  # R^2 = 0.5
Sg <- rbind(cbind(Om, psi), c(psi, 1))
stopifnot(min(eigen(Sg, symmetric = TRUE)$values) > 0)
Wm <- c(0.3, -0.2, 0.4, 0.1, -0.3, 0.2, 0)
Areg <- function(j) {                     # rows: differences that must be > 0
  if (j == 1L) return(-diag(d))
  A <- -diag(d); A[, j - 1L] <- 1; A[j - 1L, ] <- 0; A[j - 1L, j - 1L] <- 1
  A
}
Z <- rmvnorm(N, sigma = Sg)
Us <- sweep(Z[, 1:d], 2L, Wm, "+")
Sm <- argmax(cbind(0, Us))
halton <- function(n, base) vapply(seq_len(n), function(i) {
  f <- 1; r <- 0; while (i > 0) { f <- f / base; r <- r + f * (i %% base)
    i <- i %/% base }; r }, 0)
primes <- c(2, 3, 5, 7, 11, 13, 17)
## vectorised GHK: P(X > 0 componentwise), X ~ N(mean_i, Sigma), n rows
ghk_pos <- function(Mean, Sigma, Udraw) {
  L <- t(chol(Sigma)); n <- nrow(Mean); R <- nrow(Udraw); dd <- ncol(Mean)
  X <- array(0, c(n, R, dd)); lw <- matrix(0, n, R)
  for (i in seq_len(dd)) {
    cm <- matrix(Mean[, i], n, R)
    if (i > 1L) for (k in seq_len(i - 1L)) cm <- cm + L[i, k] * X[, , k]
    lo <- -cm / L[i, i]                     # need x_i > lo
    pu <- pnorm(lo, lower.tail = FALSE, log.p = TRUE)
    lw <- lw + pu
    uu <- matrix(Udraw[, i], n, R, byrow = TRUE)
    X[, , i] <- -qnorm(uu * exp(pu))        # draw from the upper tail
  }
  rowMeans(exp(lw))
}
set.seed(11); npt <- 24L
je <- sample(1:8, npt, replace = TRUE); ee <- rnorm(npt)
exact <- numeric(npt); g500 <- numeric(npt); g2000 <- numeric(npt)
Ud <- function(R) vapply(primes, function(p) halton(R + 20L, p)[-(1:20)],
                         numeric(R))
U500 <- Ud(500L); U2000 <- Ud(2000L)
Oc <- Om - tcrossprod(psi)                  # Var(u | eps = e)
for (i in seq_len(npt)) {
  A <- Areg(je[i]); mu <- as.numeric(A %*% (Wm + psi * ee[i]))
  Sa <- A %*% Oc %*% t(A)
  exact[i] <- as.numeric(pmvnorm(lower = rep(0, d), mean = mu, sigma = Sa,
    algorithm = GenzBretz(maxpts = 2e6, abseps = 1e-8)))
  g500[i] <- ghk_pos(matrix(mu, 1L), Sa, U500)
  g2000[i] <- ghk_pos(matrix(mu, 1L), Sa, U2000)
}
cat(sprintf("      7-dim rectangles: probabilities from %.2e to %.2e\n",
            min(exact), max(exact)))
record("X21a", "GHK, d = 7, 500 Halton draws: max abs error of log P",
       max(abs(log(g500) - log(exact))), 0.05)
record("X21b", "GHK, d = 7, 2000 Halton draws: max abs error of log P",
       max(abs(log(g2000) - log(exact))), 0.02)
## X22  joint law: P(S = j, eps <= c) = int phi(e) P(rect | e) de, with the
##      inner probability by Genz-Bretz, against simulation (regimes 1, 5)
zz <- 0
for (j in c(1L, 5L)) {
  A <- Areg(j); Sa <- A %*% Oc %*% t(A)
  pr <- simpson(function(e) vapply(e, function(x) dnorm(x) *
    as.numeric(pmvnorm(lower = rep(0, d),
      mean = as.numeric(A %*% (Wm + psi * x)), sigma = Sa,
      algorithm = GenzBretz(maxpts = 5e5, abseps = 1e-7))), 0), -7, 0.4, 74L)
  zz <- max(zz, zstat(as.numeric(Sm == j & Z[, d + 1L] <= 0.4), pr))
}
record("X22", "MNP, J = 8: simulated P(S = j, eps <= c), max |z|", zz, 4)
## X23  time of one vectorised GHK pass in R: n = 2000, d = 7, 500 draws
Mn <- matrix(rnorm(2000L * d, 0.2), 2000L, d)
tm <- system.time(pp <- ghk_pos(Mn, Oc, U500))[["elapsed"]]
cat(sprintf("      GHK pass (n = 2000, d = 7, R = 500): %.2f s\n", tm))
record("X23", "GHK pass n = 2000, d = 7, R = 500 finishes (seconds)", tm, 60)

## X24  ordered selection, J = 8: joint law of a middle and an end category
mu <- c(-Inf, 0, 0.5, 0.9, 1.4, 1.8, 2.3, 2.9, Inf); wo <- 1.3; rh <- 0.55
uo <- rnorm(N); eo <- rh * uo + sqrt(1 - rh^2) * rnorm(N)
So <- findInterval(wo + uo, mu[2:8]) + 1L
zz <- 0
for (j in c(1L, 4L, 8L)) {
  pr <- integrate(function(e) dnorm(e) *
    (pnorm((mu[j + 1L] - wo - rh * e) / sqrt(1 - rh^2)) -
     pnorm((mu[j] - wo - rh * e) / sqrt(1 - rh^2))), -Inf, 0.2,
    rel.tol = 1e-11)$value
  zz <- max(zz, zstat(as.numeric(So == j & eo <= 0.2), pr))
}
record("X24", "ordered, J = 8: simulated P(S = j, eps <= c), max |z|", zz, 4)

## ---------------------------------------------------------------------------
out <- do.call(rbind, res)
write.csv(out, "verify_math_g2b_results.csv", row.names = FALSE)
cat(sprintf("\n%d checks, %d passed, %d failed; %.1f s\n", nrow(out),
            sum(out$pass), sum(!out$pass), proc.time()[["elapsed"]] - t0))
if (any(!out$pass)) quit(status = 1L)
