## Stable evaluation of normal-distribution quantities used by the
## likelihoods, margins and two-step estimator.
## Derivations: 02_Computational_Architecture/NUMERICAL_METHODS.md s.2;
## verified by checks V09-V11 of verify_math.R.

## log Phi(a) (lower.tail = TRUE) or log(1 - Phi(a)).
se_log_Phi <- function(a, lower.tail = TRUE) {
  stats::pnorm(a, lower.tail = lower.tail, log.p = TRUE)
}

## Inverse Mills ratio lambda(a) = phi(a) / Phi(a), computed in log space.
se_mills <- function(a) {
  exp(stats::dnorm(a, log = TRUE) - stats::pnorm(a, log.p = TRUE))
}

## a + lambda(a). For a <= -5 direct evaluation cancels, so the tail of the
## Laplace continued fraction is used:
##   a + lambda(a) = 1 / (x + 2 / (x + 3 / (x + ...))),  x = -a.
se_a_plus_mills <- function(a) {
  out <- a + se_mills(a)
  neg <- !is.na(a) & is.finite(a) & a <= -5
  if (any(neg)) {
    x <- -a[neg]
    t <- 0
    for (k in 300:2) t <- k / (x + t)
    out[neg] <- 1 / (x + t)
  }
  out
}

## delta(a) = lambda(a) (a + lambda(a)) = -d lambda / d a, in (0, 1).
se_delta <- function(a) {
  out <- se_mills(a) * se_a_plus_mills(a)
  out[!is.na(a) & a == Inf] <- 0
  out[!is.na(a) & a == -Inf] <- 1
  out
}

## Generated regressors of the two-step estimator and their derivatives:
##   m1(w) = E[u | u > -w],  m0(w) = E[u | u <= -w],
##   delta_1(w) = delta(w),  delta_0(w) = delta(-w),  dm_k/dw = -delta_k(w).
se_m1 <- function(w) se_mills(w)
se_m0 <- function(w) -se_mills(-w)
se_d1 <- function(w) se_delta(w)
se_d0 <- function(w) se_delta(-w)
