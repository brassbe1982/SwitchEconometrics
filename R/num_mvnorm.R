## Numerical routines for normal probabilities (NUMERICAL_METHODS.md s.7.2).
## Version 1.2.0: quadrature rules and the bivariate normal distribution
## function, vectorised over the limits for a common correlation.

## Gauss-Hermite rule for the weight function phi(x) (standard normal
## density) and Gauss-Legendre rule on (-1, 1), by the Golub-Welsch
## eigenvalue method; cached.
se_gauss_hermite <- function(n) {
  key <- paste0("gh", n)
  if (!is.null(se_cache[[key]])) return(se_cache[[key]])
  k <- seq_len(n - 1L)
  Jm <- matrix(0, n, n)
  Jm[cbind(k, k + 1L)] <- sqrt(k); Jm[cbind(k + 1L, k)] <- sqrt(k)
  ev <- eigen(Jm, symmetric = TRUE)
  o <- order(ev$values)
  se_cache[[key]] <- list(x = ev$values[o], w = ev$vectors[1L, o]^2)
  se_cache[[key]]
}

se_gauss_legendre <- function(n) {
  key <- paste0("gl", n)
  if (!is.null(se_cache[[key]])) return(se_cache[[key]])
  k <- seq_len(n - 1L)
  b <- k / sqrt(4 * k^2 - 1)
  Jm <- matrix(0, n, n)
  Jm[cbind(k, k + 1L)] <- b; Jm[cbind(k + 1L, k)] <- b
  ev <- eigen(Jm, symmetric = TRUE)
  o <- order(ev$values)
  se_cache[[key]] <- list(x = ev$values[o], w = 2 * ev$vectors[1L, o]^2)
  se_cache[[key]]
}

## Composite Gauss-Legendre rule for the weight function phi(x) on
## (-L, L): `panels` equal panels with m nodes each; the weights include
## phi(x). Used where the integrand has kinks or steep transitions, for
## which a Gauss-Hermite rule converges slowly (lik_normal_scores.R).
se_gl_composite <- function(panels, L = 8, m = 8L) {
  key <- paste0("glc", panels, "_", L, "_", m)
  if (!is.null(se_cache[[key]])) return(se_cache[[key]])
  g <- se_gauss_legendre(m)
  br <- seq(-L, L, length.out = panels + 1L)
  half <- diff(br) / 2
  x <- as.vector(outer(g$x, half) +
                   rep((br[-1L] + br[-length(br)]) / 2, each = m))
  w <- rep(g$w, panels) * rep(half, each = m) * stats::dnorm(x)
  se_cache[[key]] <- list(x = x, w = w)
  se_cache[[key]]
}

## P(X <= h, Y <= k) for a standard bivariate normal pair with correlation
## r (one value), h and k vectors or matrices of the same shape.
## Plackett's identity:
##   Phi2(h, k; r) = Phi(h) Phi(k) + (1 / 2 pi) int_0^{asin r}
##                   exp(-(h^2 + k^2 - 2 h k sin t) / (2 cos^2 t)) dt,
## by Gauss-Legendre quadrature with a number of nodes that grows with |r|.
## For |r| > 0.9 the integrand is sharply peaked near the end point, so the
## range is split there. The tests compare it with mvtnorm for
## correlations from -0.995 to 0.99.
se_pbvnorm <- function(h, k, r) {
  if (length(r) != 1L || !is.finite(r) || abs(r) >= 1) {
    stop("'r' must be one correlation in (-1, 1)")
  }
  out <- stats::pnorm(h) * stats::pnorm(k)
  if (r == 0) return(out)
  a <- asin(r)
  hs <- (h^2 + k^2) / 2
  hk <- h * k
  cuts <- if (abs(r) <= 0.5) c(0, a) else if (abs(r) <= 0.9)
    c(0, a / 2, a) else c(0, a * 0.5, a * 0.8, a * 0.95, a)
  nn <- if (abs(r) <= 0.5) 12L else 20L
  gl <- se_gauss_legendre(nn)
  acc <- 0
  for (s in seq_len(length(cuts) - 1L)) {
    lo <- cuts[s]; hi <- cuts[s + 1L]
    tt <- (lo + hi) / 2 + (hi - lo) / 2 * gl$x
    sn <- sin(tt); c2 <- cos(tt)^2
    for (i in seq_len(nn)) {
      acc <- acc + (hi - lo) / 2 * gl$w[i] * exp((sn[i] * hk - hs) / c2[i])
    }
  }
  out <- out + acc / (2 * pi)
  pmin(pmax(out, 0), 1)
}
