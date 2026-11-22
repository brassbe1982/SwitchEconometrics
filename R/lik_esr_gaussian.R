## Layer 3: likelihood engine of the binary Gaussian ESR (Generation 1).
## Derivation: 01_Econometric_Architecture/LIKELIHOOD_DERIVATION.md, s.2-6;
## verified numerically by verify_math.R (V01-V06) and tests/testthat.
##
## Working parameters (parameter map se_parmap_esr): gamma, and per regime
## beta_j, tau_j = log sigma_j, alpha_j = atanh rho_j. For an observation in
## regime j, with q_1 = +1, q_0 = -1, w = z'gamma, e = (y - x_j'beta_j)/sigma_j:
##   a = q_j (w cosh(alpha_j) + e sinh(alpha_j)),
##   log L = -tau_j - log(2 pi)/2 - e^2/2 + log Phi(a).
##
## Contract (SOFTWARE_ARCHITECTURE.md s.3): returns
##   ll_i     per-observation log-likelihood (unweighted), length n;
##   score_i  per-observation score (unweighted), n x p    (deriv >= 1);
##   hessian  WEIGHTED sum of per-observation Hessians      (deriv == 2).
## Per-observation Hessians are never stored, so the weights enter the
## Hessian here; ll_i and score_i stay unweighted so that callers can form
## weighted sums, OPG and sandwich estimators.

lik_esr_gaussian <- function(theta_w, sd, map, deriv = 0L,
                             weights = sd$weights) {
  n <- sd$n
  p <- map$p
  wn <- map$elements$working_name
  ll <- numeric(n)
  G <- if (deriv >= 1L) matrix(0, n, p, dimnames = list(NULL, wn))
  H <- if (deriv >= 2L) matrix(0, p, p, dimnames = list(wn, wn))
  put <- function(r, c, v) {
    H[r, c] <<- H[r, c] + v
    if (!identical(r, c)) H[c, r] <<- H[c, r] + t(v)
  }
  ig <- map$index$gamma
  w_all <- drop(sd$Z %*% theta_w[ig])
  for (r in 1:2) {
    lab <- sd$regimes[r]
    q <- if (r == 2L) 1 else -1
    sel <- sd$S == (r - 1L)
    if (!any(sel)) next
    ib <- map$index$beta[[lab]]
    it <- map$index$sigma[[lab]]
    ia <- map$index$rho[[lab]]
    X <- sd$X[[lab]][sel, , drop = FALSE]
    Z <- sd$Z[sel, , drop = FALSE]
    tau <- theta_w[[it]]
    al <- theta_w[[ia]]
    sig <- exp(tau); s <- sinh(al); cc <- cosh(al)
    w <- w_all[sel]
    e <- drop(sd$y[sel] - X %*% theta_w[ib]) / sig
    a <- q * (w * cc + e * s)
    ll[sel] <- -tau - 0.5 * log(2 * pi) - 0.5 * e^2 + se_log_Phi(a)
    if (deriv >= 1L) {
      lam <- se_mills(a)
      v <- w * s + e * cc
      G[sel, ig] <- (lam * q * cc) * Z
      G[sel, ib] <- ((e - lam * q * s) / sig) * X
      G[sel, it] <- -1 + e^2 - lam * q * e * s
      G[sel, ia] <- lam * q * v
      if (deriv >= 2L) {
        om <- if (is.null(weights)) rep(1, sum(sel)) else weights[sel]
        del <- se_delta(a)
        put(ig, ig, crossprod(Z, (om * -del * cc^2) * Z))
        put(ig, ib, crossprod(Z, (om * del * cc * s / sig) * X))
        put(ig, it, matrix(colSums((om * del * cc * s * e) * Z), ncol = 1L))
        put(ig, ia, matrix(colSums((om * (-del * cc * v + lam * q * s)) * Z),
                           ncol = 1L))
        put(ib, ib, crossprod(X, (om * -(1 + del * s^2) / sig^2) * X))
        put(ib, it, matrix(colSums(
          (om * (-2 * e - del * e * s^2 + lam * q * s) / sig) * X), ncol = 1L))
        put(ib, ia, matrix(colSums(
          (om * (del * s * v - lam * q * cc) / sig) * X), ncol = 1L))
        put(it, it, matrix(sum(om * (-2 * e^2 - del * e^2 * s^2 +
                                       lam * q * s * e))))
        put(it, ia, matrix(sum(om * (del * e * s * v - lam * q * e * cc))))
        put(ia, ia, matrix(sum(om * (-del * v^2 + lam * a))))
      }
    }
  }
  list(ll_i = ll, score_i = G, hessian = H)
}

## Per-observation decomposition of the likelihood contribution
## (specification section 5.4: observed regime, observed outcome, probability
## of the selected regime, conditional outcome density, dependence
## correction). Uses the Gaussian margin of the distribution engine for the
## outcome density.
lik_esr_gaussian_components <- function(theta_w, sd, map) {
  th <- se_par_natural(map, theta_w)
  m <- se_margin_gaussian()
  w <- drop(sd$Z %*% theta_w[map$index$gamma])
  out <- data.frame(regime = sd$regimes[sd$S + 1L], y = sd$y,
                    log_prob_regime = NA_real_, log_density_outcome = NA_real_,
                    log_selection_conditional = NA_real_,
                    stringsAsFactors = FALSE)
  for (r in 1:2) {
    lab <- sd$regimes[r]
    q <- if (r == 2L) 1 else -1
    sel <- sd$S == (r - 1L)
    sig <- th[[map$index$sigma[[lab]]]]
    rho <- th[[map$index$rho[[lab]]]]
    mu <- drop(sd$X[[lab]][sel, , drop = FALSE] %*% th[map$index$beta[[lab]]])
    e <- (sd$y[sel] - mu) / sig
    out$log_prob_regime[sel] <- se_log_Phi(q * w[sel])
    out$log_density_outcome[sel] <-
      m$logd(sd$y[sel], list(location = mu, scale = sig))
    out$log_selection_conditional[sel] <-
      se_log_Phi(q * (w[sel] + rho * e) / sqrt(1 - rho^2))
  }
  out$loglik <- out$log_density_outcome + out$log_selection_conditional
  out$log_density_conditional <- out$loglik - out$log_prob_regime
  out$dependence_correction <- out$log_selection_conditional -
    out$log_prob_regime
  out
}
