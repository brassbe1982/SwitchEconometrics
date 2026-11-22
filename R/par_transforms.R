## Layer 5: parameter transformations.
## Derivations: 01_Econometric_Architecture/PARAMETERIZATION.md.
##
## A transformation maps an unconstrained working value w to a natural
## parameter value. Each object provides
##   to_natural(w), to_working(x)  (the inverse, with a domain check),
##   d1(w) = d natural / d w,  d2(w) = d^2 natural / d w^2,
##   the bounds of the natural domain and a label for working names.

new_se_transform <- function(name, to_natural, to_working, d1, d2, lower,
                             upper, label) {
  structure(list(name = name, to_natural = to_natural,
                 to_working = to_working, d1 = d1, d2 = d2,
                 lower = lower, upper = upper, label = label),
            class = "se_transform")
}

se_domain_check <- function(x, ok, name, domain) {
  bad <- !is.na(x) & !ok
  if (any(bad)) {
    se_abort(sprintf(
      "value(s) %s outside the domain %s of transformation '%s'",
      paste(format(x[bad][seq_len(min(3L, sum(bad)))], digits = 6),
            collapse = ", "),
      domain, name), "domain")
  }
}

## Transformation objects, by name:
##   "identity"    natural = w
##   "log"         natural = exp(w)          (standard deviations)
##   "atanh"       natural = tanh(w)         (correlations)
##   "log_shift2"  natural = 2 + exp(w)      (degrees of freedom, nu > 2)
se_transform <- function(name = c("identity", "log", "atanh", "log_shift2")) {
  name <- match.arg(name)
  switch(name,
    identity = new_se_transform(
      "identity", function(w) w, function(x) x,
      function(w) rep(1, length(w)), function(w) rep(0, length(w)),
      -Inf, Inf, "%s"),
    log = new_se_transform(
      "log", exp,
      function(x) { se_domain_check(x, x > 0, "log", "(0, Inf)"); log(x) },
      exp, exp, 0, Inf, "log(%s)"),
    atanh = new_se_transform(
      "atanh", tanh,
      function(x) {
        se_domain_check(x, abs(x) < 1, "atanh", "(-1, 1)")
        atanh(x)
      },
      function(w) 1 / cosh(w)^2,
      function(w) -2 * tanh(w) / cosh(w)^2,
      -1, 1, "atanh(%s)"),
    log_shift2 = new_se_transform(
      "log_shift2", function(w) 2 + exp(w),
      function(x) {
        se_domain_check(x, x > 2, "log_shift2", "(2, Inf)")
        log(x - 2)
      },
      exp, exp, 2, Inf, "log(%s - 2)")
  )
}

## ---------------------------------------------------------------------------
## Correlation matrices through canonical partial correlations (CPCs)
## (Lewandowski, Kurowicka and Joe 2009; PARAMETERIZATION.md section 6).
## Working vector alpha has d(d-1)/2 elements ordered as the upper triangle
## in column-major order: (1,2), (1,3), (2,3), (1,4), ...; CPC z = tanh(alpha).
## An upper-triangular W with unit-norm columns is built by
##   w_{1j} = z_{1j},  w_{ij} = z_{ij} sqrt(1 - sum_{k<i} w_{kj}^2),
##   w_{jj} = sqrt(1 - sum_{k<j} w_{kj}^2),
## and R = W'W is a correlation matrix (unit diagonal, positive definite) for
## every finite alpha. The map is one-to-one.
## ---------------------------------------------------------------------------
se_corr_from_cpc <- function(alpha, d) {
  if (length(alpha) != d * (d - 1L) / 2L) {
    se_abort(sprintf("a %d x %d correlation matrix needs %d working values",
                     d, d, d * (d - 1L) / 2L), "argument")
  }
  z <- tanh(alpha)
  zero <- 0 * if (length(z)) z[1L] else 0
  W <- matrix(zero, d, d)
  W[1L, 1L] <- 1 + zero
  k <- 0L
  if (d >= 2L) for (j in 2:d) {
    s <- 1 + zero
    for (i in seq_len(j - 1L)) {
      k <- k + 1L
      W[i, j] <- z[k] * sqrt(s)
      s <- s - W[i, j]^2
    }
    W[j, j] <- sqrt(s)
  }
  R <- t(W) %*% W
  if (!is.complex(R)) diag(R) <- 1
  R
}

## Inverse map: correlation matrix -> working vector (atanh of the CPCs).
se_cpc_from_corr <- function(R, tol = 1e-10) {
  se_check_corr(R, tol)
  d <- nrow(R)
  W <- chol(R)
  alpha <- numeric(d * (d - 1L) / 2L)
  k <- 0L
  if (d >= 2L) for (j in 2:d) {
    s <- 1
    for (i in seq_len(j - 1L)) {
      k <- k + 1L
      alpha[k] <- atanh(W[i, j] / sqrt(s))
      s <- s - W[i, j]^2
    }
  }
  alpha
}

## Validity of a correlation matrix: square, symmetric, unit diagonal,
## positive definite.
se_check_corr <- function(R, tol = 1e-10) {
  if (!is.matrix(R) || nrow(R) != ncol(R) || !is.numeric(R)) {
    se_abort("a correlation matrix must be a square numeric matrix", "domain")
  }
  if (max(abs(R - t(R))) > tol) se_abort("correlation matrix is not symmetric",
                                        "domain")
  if (max(abs(diag(R) - 1)) > tol) {
    se_abort("correlation matrix does not have a unit diagonal", "domain")
  }
  ev <- eigen(R, symmetric = TRUE, only.values = TRUE)$values
  if (min(ev) <= tol) {
    se_abort("correlation matrix is not positive definite", "domain")
  }
  invisible(TRUE)
}

## Jacobian d R[upper.tri] / d alpha' by complex-step differentiation, which
## is exact to rounding error because the construction is analytic.
se_corr_jacobian <- function(alpha, d, h = 1e-20) {
  m <- length(alpha)
  J <- matrix(0, m, m)
  for (k in seq_len(m)) {
    a <- complex(real = alpha, imaginary = 0)
    a[k] <- complex(real = alpha[k], imaginary = h)
    R <- se_corr_from_cpc(a, d)
    J[, k] <- Im(R[upper.tri(R)]) / h
  }
  J
}

## Covariance matrix from a correlation matrix and standard deviations.
se_cov_from_corr <- function(R, sd) {
  sd * R * rep(sd, each = length(sd))
}
