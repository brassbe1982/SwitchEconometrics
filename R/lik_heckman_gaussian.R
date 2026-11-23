## Layer 3: likelihood engines of the observation mechanisms (Generation 2).
## Derivation: 01_Econometric_Architecture/OBSERVATION_MECHANISMS.md s.2-3;
## verified by verify_math_g2.R (W01-W05).
## Contract of lik_esr_gaussian(): ll_i and score_i unweighted, hessian
## weighted.

## Heckman (Tobit-2). Working parameters: gamma, beta, tau = log sigma,
## alpha = atanh rho.
##   S = 1: log L = -tau - log(2 pi)/2 - e^2/2 + log Phi(w cosh(alpha) +
##                  e sinh(alpha)),  e = (y - x'beta)/sigma
##          (the regime-1 block of the binary ESR);
##   S = 0: log L = log Phi(-w).
lik_heckman_gaussian <- function(theta_w, sd, map, deriv = 0L,
                                 weights = sd$weights) {
  n <- sd$n
  p <- map$p
  wn <- map$elements$working_name
  ig <- map$index$gamma
  ib <- map$index$beta$outcome
  it <- map$index$sigma$outcome
  ia <- map$index$rho$outcome
  ll <- numeric(n)
  G <- if (deriv >= 1L) matrix(0, n, p, dimnames = list(NULL, wn))
  H <- if (deriv >= 2L) matrix(0, p, p, dimnames = list(wn, wn))
  put <- function(r, c, v) {
    H[r, c] <<- H[r, c] + v
    if (!identical(r, c)) H[c, r] <<- H[c, r] + t(v)
  }
  w_all <- drop(sd$Z %*% theta_w[ig])
  om_all <- if (is.null(weights)) rep(1, n) else weights

  ## unobserved units: probit term
  s0 <- sd$S == 0L
  if (any(s0)) {
    Z0 <- sd$Z[s0, , drop = FALSE]
    lp0 <- se_log_Phi(-w_all[s0])
    ll[s0] <- lp0
    if (deriv >= 1L) {
      lam0 <- se_mills(-w_all[s0], lp0)
      G[s0, ig] <- -lam0 * Z0
      if (deriv >= 2L) {
        put(ig, ig, crossprod(Z0, (om_all[s0] * -se_delta(-w_all[s0], lam0)) *
                                Z0))
      }
    }
  }

  ## observed units: Gaussian block with q = +1
  sel <- sd$S == 1L
  X <- sd$X$outcome[sel, , drop = FALSE]
  Z <- sd$Z[sel, , drop = FALSE]
  tau <- theta_w[[it]]
  al <- theta_w[[ia]]
  sig <- exp(tau); s <- sinh(al); cc <- cosh(al)
  w <- w_all[sel]
  e <- drop(sd$y[sel] - X %*% theta_w[ib]) / sig
  a <- w * cc + e * s
  lp <- se_log_Phi(a)
  ll[sel] <- -tau - 0.5 * log(2 * pi) - 0.5 * e^2 + lp
  if (deriv >= 1L) {
    lam <- se_mills(a, lp)
    v <- w * s + e * cc
    G[sel, ig] <- (lam * cc) * Z
    G[sel, ib] <- ((e - lam * s) / sig) * X
    G[sel, it] <- -1 + e^2 - lam * e * s
    G[sel, ia] <- lam * v
    if (deriv >= 2L) {
      om <- om_all[sel]
      del <- se_delta(a, lam)
      put(ig, ig, crossprod(Z, (om * -del * cc^2) * Z))
      put(ig, ib, crossprod(Z, (om * del * cc * s / sig) * X))
      put(ig, it, matrix(colSums((om * del * cc * s * e) * Z), ncol = 1L))
      put(ig, ia, matrix(colSums((om * (-del * cc * v + lam * s)) * Z),
                         ncol = 1L))
      put(ib, ib, crossprod(X, (om * -(1 + del * s^2) / sig^2) * X))
      put(ib, it, matrix(colSums(
        (om * (-2 * e - del * e * s^2 + lam * s) / sig) * X), ncol = 1L))
      put(ib, ia, matrix(colSums(
        (om * (del * s * v - lam * cc) / sig) * X), ncol = 1L))
      put(it, it, matrix(sum(om * (-2 * e^2 - del * e^2 * s^2 + lam * s * e))))
      put(it, ia, matrix(sum(om * (del * e * s * v - lam * e * cc))))
      put(ia, ia, matrix(sum(om * (-del * v^2 + lam * a))))
    }
  }
  list(ll_i = ll, score_i = G, hessian = H)
}

## Per-observation decomposition (as lik_esr_gaussian_components); the
## outcome parts are NA for unobserved units.
lik_heckman_gaussian_components <- function(theta_w, sd, map) {
  th <- se_par_natural(map, theta_w)
  w <- drop(sd$Z %*% th[map$index$gamma])
  sel <- sd$S == 1L
  sig <- th[[map$index$sigma$outcome]]
  rho <- th[[map$index$rho$outcome]]
  out <- data.frame(regime = sd$regimes[sd$S + 1L], y = sd$y,
                    log_prob_regime = se_log_Phi((2 * sd$S - 1) * w),
                    log_density_outcome = NA_real_,
                    log_selection_conditional = NA_real_,
                    stringsAsFactors = FALSE)
  mu <- drop(sd$X$outcome[sel, , drop = FALSE] %*% th[map$index$beta$outcome])
  e <- (sd$y[sel] - mu) / sig
  out$log_density_outcome[sel] <- stats::dnorm(sd$y[sel], mu, sig, log = TRUE)
  out$log_selection_conditional[sel] <-
    se_log_Phi((w[sel] + rho * e) / sqrt(1 - rho^2))
  out$loglik <- ifelse(sel, out$log_density_outcome +
                         out$log_selection_conditional, out$log_prob_regime)
  out$log_density_conditional <- out$loglik - out$log_prob_regime
  out$log_density_conditional[!sel] <- NA_real_
  out$dependence_correction <- out$log_selection_conditional -
    out$log_prob_regime
  out
}

## Treatment model: the binary ESR engine at A theta (linear restriction);
## score A'g, Hessian A'HA (OBSERVATION_MECHANISMS.md s.3.2-3.3).
lik_treatment_gaussian <- function(theta_w, sd, map, deriv = 0L,
                                   weights = sd$weights) {
  A <- map$A
  L <- lik_esr_gaussian(se_treat_to_esr(map, theta_w), sd, map$esr,
                        deriv = deriv, weights = weights)
  wn <- map$elements$working_name
  out <- list(ll_i = L$ll_i, score_i = NULL, hessian = NULL)
  if (deriv >= 1L) {
    out$score_i <- L$score_i %*% A
    colnames(out$score_i) <- wn
  }
  if (deriv >= 2L) {
    out$hessian <- crossprod(A, L$hessian %*% A)
    dimnames(out$hessian) <- list(wn, wn)
  }
  out
}

lik_treatment_gaussian_components <- function(theta_w, sd, map) {
  lik_esr_gaussian_components(se_treat_to_esr(map, theta_w), sd, map$esr)
}
