## Layer 3: likelihood engine of the multinomial switching regression with
## multinomial-logit selection and Lee's (1983) transformation.
## Derivation: 01_Econometric_Architecture/MULTINOMIAL_ESR.md s.3; verified
## by verify_math_g2.R (W10-W12, W16) and verify_math_g2b.R (X20).
##
## For an observation in regime j, with P_j its choice probability,
## w = qnorm(P_j), e = (y - x_j'beta_j)/sigma_j, tau = log sigma,
## alpha = atanh rho:
##   log L = -tau - log(2 pi)/2 - e^2/2 + log Phi(w cosh(alpha) + e sinh(alpha)),
## the regime-1 block of the binary model with the index w. The index
## depends on every selection coefficient:
##   dw/dgamma_k = g_k z,  g_k = (1{j = k} - P_k) / lambda(w).
## Contract of lik_esr_gaussian(): ll_i and score_i unweighted, hessian
## weighted. Any number of regimes.

lik_lee_mnl <- function(theta_w, sd, map, deriv = 0L, weights = sd$weights) {
  n <- sd$n; p <- map$p; J <- sd$J; kz <- map$kz
  wn <- map$elements$working_name
  ig <- map$index$gamma
  alts <- setdiff(seq_len(J), sd$base)
  K <- J - 1L
  G <- matrix(theta_w[ig], K, kz, byrow = TRUE)
  lP <- se_mnl_logP(sd$Z, G, sd$base)
  ll <- numeric(n)
  Gs <- if (deriv >= 1L) matrix(0, n, p, dimnames = list(NULL, wn))
  H <- if (deriv >= 2L) matrix(0, p, p, dimnames = list(wn, wn))
  put <- function(r, c, v) {
    H[r, c] <<- H[r, c] + v
    if (!identical(r, c)) H[c, r] <<- H[c, r] + t(v)
  }
  om_all <- if (is.null(weights)) rep(1, n) else weights
  for (j in seq_len(J)) {
    lab <- sd$regimes[j]
    sel <- sd$S == j
    if (!any(sel)) next
    ib <- map$index$beta[[lab]]
    it <- map$index$sigma[[lab]]
    ia <- map$index$rho[[lab]]
    X <- sd$X[[lab]][sel, , drop = FALSE]
    Z <- sd$Z[sel, , drop = FALSE]
    tau <- theta_w[[it]]; al <- theta_w[[ia]]
    sig <- exp(tau); s <- sinh(al); cc <- cosh(al)
    lPj <- lP[sel, j]
    w <- stats::qnorm(lPj, log.p = TRUE)
    e <- drop(sd$y[sel] - X %*% theta_w[ib]) / sig
    a <- w * cc + e * s
    lp <- se_log_Phi(a)
    ll[sel] <- -tau - 0.5 * log(2 * pi) - 0.5 * e^2 + lp
    if (deriv >= 1L) {
      lam <- se_mills(a, lp)
      v <- w * s + e * cc
      lamw <- exp(stats::dnorm(w, log = TRUE) - lPj)        # lambda(w)
      Pk <- exp(lP[sel, alts, drop = FALSE])               # n_j x K
      ind <- matrix(as.numeric(alts == j), sum(sel), K, byrow = TRUE)
      gk <- (ind - Pk) / lamw                              # dw/dgamma_k = g_k z
      ## Zg = (g_2 z, ..., g_J z): n_j x (K kz), columns ordered by alternative
      Zg <- do.call(cbind, lapply(seq_len(K), function(k) gk[, k] * Z))
      Gs[sel, ig] <- (lam * cc) * Zg
      Gs[sel, ib] <- ((e - lam * s) / sig) * X
      Gs[sel, it] <- -1 + e^2 - lam * e * s
      Gs[sel, ia] <- lam * v
      if (deriv >= 2L) {
        om <- om_all[sel]
        del <- se_delta(a, lam)
        ## gamma-gamma: -delta c^2 g_k g_l + lambda c h_kl, with
        ## h_kl = (lambda_w + w) g_k g_l - P_k (1{k = l} - P_l) / lambda_w
        qq <- lam * cc / lamw
        Zp <- do.call(cbind, lapply(seq_len(K), function(k) Pk[, k] * Z))
        Hgg <- crossprod(Zg, (om * (-del * cc^2 + lam * cc *
                                      se_a_plus_mills(w, lamw))) * Zg) +
          crossprod(Zp, (om * qq) * Zp)
        for (k in seq_len(K)) {
          pk <- (k - 1L) * kz + seq_len(kz)
          Hgg[pk, pk] <- Hgg[pk, pk] - crossprod(Z, (om * qq * Pk[, k]) * Z)
        }
        H[ig, ig] <- H[ig, ig] + Hgg
        put(ig, ib, crossprod(Zg, (om * del * cc * s / sig) * X))
        put(ig, it, matrix(colSums((om * del * cc * s * e) * Zg), ncol = 1L))
        put(ig, ia, matrix(colSums((om * (-del * cc * v + lam * s)) * Zg),
                           ncol = 1L))
        put(ib, ib, crossprod(X, (om * -(1 + del * s^2) / sig^2) * X))
        put(ib, it, matrix(colSums(
          (om * (-2 * e - del * e * s^2 + lam * s) / sig) * X), ncol = 1L))
        put(ib, ia, matrix(colSums(
          (om * (del * s * v - lam * cc) / sig) * X), ncol = 1L))
        put(it, it, matrix(sum(om * (-2 * e^2 - del * e^2 * s^2 +
                                       lam * s * e))))
        put(it, ia, matrix(sum(om * (del * e * s * v - lam * e * cc))))
        put(ia, ia, matrix(sum(om * (-del * v^2 + lam * a))))
      }
    }
  }
  list(ll_i = ll, score_i = Gs, hessian = H)
}

## Per-observation decomposition (as lik_esr_gaussian_components).
lik_lee_mnl_components <- function(theta_w, sd, map) {
  th <- se_par_natural(map, theta_w)
  J <- sd$J
  G <- matrix(th[map$index$gamma], J - 1L, map$kz, byrow = TRUE)
  lP <- se_mnl_logP(sd$Z, G, sd$base)
  out <- data.frame(regime = sd$regimes[sd$S], y = sd$y,
                    log_prob_regime = lP[cbind(seq_len(sd$n), sd$S)],
                    log_density_outcome = NA_real_,
                    log_selection_conditional = NA_real_,
                    stringsAsFactors = FALSE)
  for (j in seq_len(J)) {
    lab <- sd$regimes[j]
    sel <- sd$S == j
    sig <- th[[map$index$sigma[[lab]]]]
    rho <- th[[map$index$rho[[lab]]]]
    mu <- drop(sd$X[[lab]][sel, , drop = FALSE] %*% th[map$index$beta[[lab]]])
    e <- (sd$y[sel] - mu) / sig
    w <- stats::qnorm(lP[sel, j], log.p = TRUE)
    out$log_density_outcome[sel] <- stats::dnorm(sd$y[sel], mu, sig, log = TRUE)
    out$log_selection_conditional[sel] <-
      se_log_Phi((w + rho * e) / sqrt(1 - rho^2))
  }
  out$loglik <- out$log_density_outcome + out$log_selection_conditional
  out$log_density_conditional <- out$loglik - out$log_prob_regime
  out$dependence_correction <- out$log_selection_conditional -
    out$log_prob_regime
  out
}
