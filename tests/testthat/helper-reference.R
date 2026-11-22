## Independent reference implementation of the binary Gaussian ESR
## likelihood, score and Hessian: a copy of the reference code of
## 01_Econometric_Architecture/verify_math.R (which verified it against
## numerical integration, numerical derivatives and sampleSelection), with
## names prefixed ref_. It shares no code with the package. Parameter order:
## (gamma, beta1, beta0, tau1, tau0, alpha1, alpha0).

ref_mills <- function(a) exp(dnorm(a, log = TRUE) - pnorm(a, log.p = TRUE))
ref_a_plus_lambda <- function(a) {
  out <- a + ref_mills(a)
  neg <- a <= -5
  if (any(neg)) {
    x <- -a[neg]
    t <- 0
    for (k in 300:2) t <- k / (x + t)
    out[neg] <- 1 / (x + t)
  }
  out
}
ref_delta <- function(a) ref_mills(a) * ref_a_plus_lambda(a)

ref_index <- function(kz, k1, k0) {
  list(g = seq_len(kz), b1 = kz + seq_len(k1), b0 = kz + k1 + seq_len(k0),
       t1 = kz + k1 + k0 + 1L, t0 = kz + k1 + k0 + 2L,
       a1 = kz + k1 + k0 + 3L, a0 = kz + k1 + k0 + 4L,
       p = kz + k1 + k0 + 4L)
}
ref_blocks <- function(ix, j) {
  if (j == 1) list(b = ix$b1, t = ix$t1, a = ix$a1, q = 1)
  else list(b = ix$b0, t = ix$t0, a = ix$a0, q = -1)
}
ref_pieces <- function(th, d, ix, j) {
  B <- ref_blocks(ix, j)
  sel <- d$S == j
  X <- if (j == 1) d$X1[sel, , drop = FALSE] else d$X0[sel, , drop = FALSE]
  Z <- d$Z[sel, , drop = FALSE]
  sig <- exp(th[B$t]); s <- sinh(th[B$a]); cc <- cosh(th[B$a])
  w <- drop(Z %*% th[ix$g])
  e <- drop(d$y[sel] - X %*% th[B$b]) / sig
  a <- B$q * (w * cc + e * s)
  list(sel = sel, X = X, Z = Z, sig = sig, s = s, cc = cc, w = w, e = e,
       a = a, q = B$q, lam = ref_mills(a), del = ref_delta(a), B = B,
       ll = -th[B$t] + dnorm(e, log = TRUE) + pnorm(a, log.p = TRUE))
}
ref_loglik_i <- function(th, d, ix) {
  out <- numeric(d$n)
  for (j in c(1, 0)) { P <- ref_pieces(th, d, ix, j); out[P$sel] <- P$ll }
  out
}
ref_score_i <- function(th, d, ix) {
  G <- matrix(0, d$n, ix$p)
  for (j in c(1, 0)) {
    P <- ref_pieces(th, d, ix, j)
    G[P$sel, ix$g] <- P$lam * P$q * P$cc * P$Z
    G[P$sel, P$B$b] <- (P$e - P$lam * P$q * P$s) / P$sig * P$X
    G[P$sel, P$B$t] <- -1 + P$e^2 - P$lam * P$q * P$e * P$s
    G[P$sel, P$B$a] <- P$lam * P$q * (P$w * P$s + P$e * P$cc)
  }
  G
}
ref_hessian <- function(th, d, ix) {
  H <- matrix(0, ix$p, ix$p)
  put <- function(r, c, v) {
    H[r, c] <<- H[r, c] + v
    if (!identical(r, c)) H[c, r] <<- H[c, r] + t(v)
  }
  for (j in c(1, 0)) {
    P <- ref_pieces(th, d, ix, j)
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

## Reference treatment effects (copy of effects_fun in verify_math.R),
## reference parameter order, unweighted.
ref_effects <- function(th, d, ix) {
  s1 <- exp(th[ix$t1]); s0 <- exp(th[ix$t0])
  r1 <- tanh(th[ix$a1]); r0 <- tanh(th[ix$a0])
  w <- drop(d$Z %*% th[ix$g])
  m1 <- ref_mills(w); m0 <- -ref_mills(-w)
  xb1 <- drop(d$X1 %*% th[ix$b1]); xb0 <- drop(d$X0 %*% th[ix$b0])
  EY1S1 <- xb1 + s1 * r1 * m1; EY1S0 <- xb1 + s1 * r1 * m0
  EY0S1 <- xb0 + s0 * r0 * m1; EY0S0 <- xb0 + s0 * r0 * m0
  T1 <- d$S == 1; T0 <- !T1
  ATT <- mean(EY1S1[T1] - EY0S1[T1]); ATU <- mean(EY1S0[T0] - EY0S0[T0])
  c(ATT = ATT, ATU = ATU, ATE = mean(xb1 - xb0), TH = ATT - ATU,
    BH1 = mean(EY1S1[T1]) - mean(EY1S0[T0]),
    BH0 = mean(EY0S1[T1]) - mean(EY0S0[T0]))
}

## Bridge between the package (parameter map order) and the reference order.
ref_setup <- function(sd, map) {
  d <- list(n = sd$n, S = sd$S, y = sd$y, Z = sd$Z,
            X1 = sd$X[[sd$regimes[2]]], X0 = sd$X[[sd$regimes[1]]])
  ix <- ref_index(ncol(d$Z), ncol(d$X1), ncol(d$X0))
  l1 <- sd$regimes[2]; l0 <- sd$regimes[1]
  perm <- c(map$index$gamma, map$index$beta[[l1]], map$index$beta[[l0]],
            map$index$sigma[[l1]], map$index$sigma[[l0]],
            map$index$rho[[l1]], map$index$rho[[l0]])
  list(d = d, ix = ix, perm = perm)
}

## Bivariate normal density written out directly (independent of the
## factorisation used by the likelihood).
ref_dbvn <- function(u, eps, sigma, rho) {
  q <- (u^2 - 2 * rho * u * eps / sigma + (eps / sigma)^2) / (1 - rho^2)
  exp(-q / 2) / (2 * pi * sigma * sqrt(1 - rho^2))
}

## Package objects for a simulated dataset.
esr_setup <- function(n = 400, seed = 1, weights = NULL, ...) {
  d <- sim_esr_data(n, seed, ...)
  sd <- se_build_data(esr_spec(), d, weights = weights)
  list(data = d, sd = sd, map = se_parmap_esr(sd))
}

## True parameters of sim_esr_data on the natural scale, map order.
esr_truth <- function(map, rho1 = 0.6, rho0 = 0.4) {
  v <- c(0.5, 0.3, -0.4, 1.0, 0.5, 0.2, 0.8, rho0, 1.5, 0.8, 0.4, 1.2, rho1)
  stats::setNames(v, map$elements$name)
}
