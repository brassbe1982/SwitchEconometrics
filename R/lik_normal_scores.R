## Layer 3: likelihood engine of the normal-score multinomial switching
## regression (MULTINOMIAL_ESR.md s.11; verified at the reference level by
## verify_math_g2b.R X10-X14).
##
## Selection is the multinomial logit. With eta_k = qnorm(G(u_k)) the normal
## scores of the Gumbel utility disturbances, the standardised outcome
## disturbance of regime j is jointly normal with all J scores,
## Corr(eps_j / sigma_j, eta_k) = r_jk, sum_k r_jk^2 < 1.
##
## Contribution of an observation in regime j, e = (y - x'beta_j)/sigma_j:
##   L = (1/sigma_j) phi(e) I,
##   I = int phi(x) Phi_{J-1}( (h_m(t) - mu_m) / sd_m ; R_c ) dx,
##   t = r_j e + s x, s = sqrt(1 - r_j^2),
##   h_m(t) = qnorm(pnorm(t)^{exp(v_m - v_j)}),  mu_m = r_m (e - r_j x / s),
##   sd_m = sqrt(1 - r_m^2 / s^2),  Corr_c(m, n) = -(r_m r_n / s^2)/(sd_m sd_n),
## by a composite Gauss-Legendre rule in x (se_ns_rule). Deterministic for
## J = 2 (univariate) and J = 3 (bivariate normal distribution function).
## J >= 4 is not available in this version.
##
## Quadrature. As sum_k r_jk^2 approaches 1 the integrand develops kinks
## and steep transitions in x (the conditional distribution of the scores
## given e becomes singular). The number of panels therefore doubles as
## s0 = sqrt(1 - sum_k r_jk^2) falls below 0.35, 0.18 and 0.09. Calibration
## (WP2.2 progress note): largest error of log I over 400 observations
## below 1e-5 at these thresholds and below 1e-8 for s0 >= 0.5. A
## 24-node Gauss-Hermite rule had errors of 1e-3 in the interior and 0.1
## to 0.4 near the boundary, enough to create spurious maxima there.
##
## Working parameters of the correlations of a regime: a in R^J with
## r = a / sqrt(1 + |a|^2) (onto the open unit ball).
##
## Derivatives. The integral depends on the parameters only through e, the
## J - 1 utility differences v_m - v_j, and r. Its derivatives with respect
## to these quantities are analytic (differentiation under the integral
## sign, se_ns_integral), as is the chain rule to gamma, beta_j, sigma_j
## and the working correlations. The Hessian is the symmetrised forward
## difference of this score (gate decision 9).

se_ball_natural <- function(a) a / sqrt(1 + sum(a^2))
se_ball_working <- function(r) {
  q <- sum(r^2)
  if (q >= 1) se_abort("the correlations of a regime must satisfy sum r^2 < 1",
                       "domain")
  r / sqrt(1 - q)
}
## d r / d a' at a
se_ball_jacobian <- function(a) {
  r <- se_ball_natural(a)
  sqrt(1 - sum(r^2)) * (diag(length(a)) - tcrossprod(r))
}

## Integration rule for a regime with correlations r: 14 panels of 8 nodes
## on (-8, 8) (map$nodes panels, if set), doubled near the boundary.
se_ns_rule <- function(r, panels = 14L) {
  s0 <- sqrt(max(1 - sum(r^2), 0))
  mult <- if (s0 >= 0.35) 1L else if (s0 >= 0.18) 2L else if (s0 >= 0.09) 4L
          else 8L
  se_gl_composite(as.integer(panels) * mult)
}

## The integral I for the rows of one regime. e: vector; LA: n x (J-1)
## matrix of v_m - v_j for the other alternatives (in order); rj: own
## correlation; ro: correlations with the other alternatives. With
## deriv = TRUE also the derivatives of I with respect to e, to the columns
## of LA and to (rj, ro), by differentiation under the integral sign:
##   d Phi(k) = phi(k) dk,
##   d Phi2(k1, k2; c) = phi(k1) Phi((k2 - c k1)/q) dk1
##                     + phi(k2) Phi((k1 - c k2)/q) dk2 + phi2(k1, k2; c) dc,
## q = sqrt(1 - c^2), and dH/dlogp = Phi(H)/phi(H) for H = qnorm(p).
se_ns_integral <- function(e, LA, rj, ro, gh, deriv = FALSE) {
  n <- length(e); d <- length(ro)
  s2 <- 1 - rj^2
  s <- sqrt(s2)
  Q <- length(gh$x)
  xm <- matrix(gh$x, n, Q, byrow = TRUE)
  Tm <- rj * e + s * xm                                 # n x Q
  lpT <- stats::pnorm(Tm, log.p = TRUE)
  sdm <- sqrt(1 - ro^2 / s2)
  cm <- e - (rj / s) * xm                               # n x Q
  lp <- H <- kk <- vector("list", d)
  for (m in seq_len(d)) {
    lp[[m]] <- exp(LA[, m]) * lpT
    H[[m]] <- stats::qnorm(lp[[m]], log.p = TRUE)
    kk[[m]] <- (H[[m]] - ro[m] * cm) / sdm[m]
  }
  rc <- if (d == 2L) -(ro[1L] * ro[2L] / s2) / (sdm[1L] * sdm[2L]) else 0
  val <- if (d == 1L) stats::pnorm(kk[[1L]]) else
    se_pbvnorm(kk[[1L]], kk[[2L]], rc)
  I <- drop(val %*% gh$w)
  if (!deriv) return(I)
  W <- vector("list", d)
  if (d == 1L) {
    W[[1L]] <- stats::dnorm(kk[[1L]])
  } else {
    q <- sqrt(1 - rc^2)
    W[[1L]] <- stats::dnorm(kk[[1L]]) * stats::pnorm((kk[[2L]] - rc * kk[[1L]]) / q)
    W[[2L]] <- stats::dnorm(kk[[2L]]) * stats::pnorm((kk[[1L]] - rc * kk[[2L]]) / q)
  }
  lamT <- exp(stats::dnorm(Tm, log = TRUE) - lpT)        # phi(t) / Phi(t)
  dE <- numeric(n)
  dLA <- matrix(0, n, d)
  dR <- matrix(0, n, 1L + d)
  for (m in seq_len(d)) {
    Wm <- W[[m]]
    int <- function(M) {
      M <- Wm * M
      M[Wm == 0 | !is.finite(M)] <- 0
      drop(M %*% gh$w)
    }
    hp <- exp(lp[[m]] - stats::dnorm(H[[m]], log = TRUE))  # dH / dlogp
    dHt <- hp * exp(LA[, m]) * lamT                        # dH / dt
    dE <- dE + int((dHt * rj - ro[m]) / sdm[m])
    dLA[, m] <- int(hp * lp[[m]] / sdm[m])
    dR[, 1L] <- dR[, 1L] + int((dHt * cm + ro[m] * xm / s^3) / sdm[m] +
                                 kk[[m]] * ro[m]^2 * rj / (s2^2 * sdm[m]^2))
    dR[, 1L + m] <- int(-cm / sdm[m] + kk[[m]] * (ro[m] / s2) / sdm[m]^2)
  }
  if (d == 2L) {
    k1 <- kk[[1L]]; k2 <- kk[[2L]]
    Wr <- exp(-(k1^2 - 2 * rc * k1 * k2 + k2^2) / (2 * q^2)) / (2 * pi * q)
    Wr[!is.finite(Wr)] <- 0
    Ir <- drop(Wr %*% gh$w)
    D1 <- s2 - ro[1L]^2; D2 <- s2 - ro[2L]^2
    sq <- sqrt(D1 * D2)
    dR[, 1L] <- dR[, 1L] + Ir * rc * rj * (D1 + D2) / (D1 * D2)
    dR[, 2L] <- dR[, 2L] + Ir * (-ro[2L] * s2 / (D1 * sq))
    dR[, 3L] <- dR[, 3L] + Ir * (-ro[1L] * s2 / (D2 * sq))
  }
  list(I = I, dE = dE, dLA = dLA, dR = dR)
}

lik_ns_mnl <- function(theta_w, sd, map, deriv = 0L, weights = sd$weights) {
  if (deriv >= 2L) {
    L <- lik_ns_mnl(theta_w, sd, map, 1L, weights)
    om <- if (is.null(weights)) rep(1, sd$n) else weights
    g0 <- colSums(om * L$score_i)
    p <- map$p
    H <- matrix(0, p, p)
    free <- which(!map$fixed)
    for (i in free) {
      h <- 1e-5 * (1 + abs(theta_w[i]))
      tp <- theta_w; tp[i] <- tp[i] + h
      H[, i] <- (colSums(om * lik_ns_mnl(tp, sd, map, 1L, weights)$score_i) -
                   g0) / h
    }
    H <- (H + t(H)) / 2
    dimnames(H) <- list(map$elements$working_name, map$elements$working_name)
    L$hessian <- H
    attr(L$hessian, "type") <- "score_difference"
    return(L)
  }
  n <- sd$n; p <- map$p; J <- sd$J; kz <- map$kz
  if (J > 3L) {
    se_abort(paste0("the normal-score model is available for 2 and 3 regimes ",
                    "in this version"), "unsupported")
  }
  wn <- map$elements$working_name
  ig <- map$index$gamma
  alts <- setdiff(seq_len(J), sd$base)
  V <- matrix(0, n, J)
  V[, alts] <- sd$Z %*% t(matrix(theta_w[ig], J - 1L, kz, byrow = TRUE))
  ll <- numeric(n)
  Gs <- if (deriv >= 1L) matrix(0, n, p, dimnames = list(NULL, wn))
  pos <- function(k) ig[(k - 1L) * kz + seq_len(kz)]    # k-th non-base alt
  for (j in seq_len(J)) {
    lab <- sd$regimes[j]
    sel <- sd$S == j
    if (!any(sel)) next
    ib <- map$index$beta[[lab]]
    it <- map$index$sigma[[lab]]
    ia <- map$index$rho[[lab]]
    X <- sd$X[[lab]][sel, , drop = FALSE]
    Z <- sd$Z[sel, , drop = FALSE]
    tau <- theta_w[[it]]; sig <- exp(tau)
    a <- theta_w[ia]
    r <- se_ball_natural(a)
    oth <- setdiff(seq_len(J), j)
    e <- drop(sd$y[sel] - X %*% theta_w[ib]) / sig
    LA <- V[sel, oth, drop = FALSE] - V[sel, j]
    gh <- se_ns_rule(r, map$nodes %||% 14L)
    II <- se_ns_integral(e, LA, r[j], r[oth], gh, deriv = deriv >= 1L)
    I0 <- if (is.list(II)) II$I else II
    ll[sel] <- -tau - 0.5 * log(2 * pi) - 0.5 * e^2 + log(I0)
    if (deriv >= 1L) {
      de <- II$dE / I0
      dLA <- II$dLA / I0
      dRf <- matrix(0, sum(sel), J)
      dRf[, j] <- II$dR[, 1L]
      dRf[, oth] <- II$dR[, -1L]
      Gs[sel, ia] <- (dRf %*% se_ball_jacobian(a)) / I0
      Gs[sel, ib] <- ((e - de) / sig) * X
      Gs[sel, it] <- -1 + e^2 - e * de
      ## v_m - v_j: gamma of alternative m gets +dLA_m; gamma of j gets -sum
      for (m in seq_along(oth)) {
        km <- match(oth[m], alts)
        if (!is.na(km)) Gs[sel, pos(km)] <- Gs[sel, pos(km)] + dLA[, m] * Z
      }
      kj <- match(j, alts)
      if (!is.na(kj)) Gs[sel, pos(kj)] <- Gs[sel, pos(kj)] - rowSums(dLA) * Z
    }
  }
  list(ll_i = ll, score_i = Gs, hessian = NULL)
}

lik_ns_mnl_components <- function(theta_w, sd, map) {
  th <- se_par_natural(map, theta_w)
  J <- sd$J
  G <- matrix(th[map$index$gamma], J - 1L, map$kz, byrow = TRUE)
  lP <- se_mnl_logP(sd$Z, G, sd$base)
  ll <- lik_ns_mnl(theta_w, sd, map)$ll_i
  out <- data.frame(regime = sd$regimes[sd$S], y = sd$y,
                    log_prob_regime = lP[cbind(seq_len(sd$n), sd$S)],
                    log_density_outcome = NA_real_, stringsAsFactors = FALSE)
  for (j in seq_len(J)) {
    lab <- sd$regimes[j]
    sel <- sd$S == j
    mu <- drop(sd$X[[lab]][sel, , drop = FALSE] %*% th[map$index$beta[[lab]]])
    out$log_density_outcome[sel] <- stats::dnorm(
      sd$y[sel], mu, th[[map$index$sigma[[lab]]]], log = TRUE)
  }
  out$log_selection_conditional <- ll - out$log_density_outcome
  out$loglik <- ll
  out$log_density_conditional <- ll - out$log_prob_regime
  out$dependence_correction <- out$log_selection_conditional -
    out$log_prob_regime
  out
}

## Starting values: multinomial logit; the BFG variant 2 regression gives
## beta_j and a_jk = sigma_j r_jk; sigma_j from the residual variance and
## the fitted correction; correlations shrunk into the unit ball.
se_ns_start <- function(sd, map) {
  om <- sd$weights %||% rep(1, sd$n)
  core <- tryCatch(se_ts_multi_core(sd$Z, sd$S, sd$y, sd$X, sd$J, sd$base,
                                    "bfg2", om, sd$regimes, pieces = TRUE),
                   error = function(e) NULL)
  if (is.null(core)) return(est_naive_start_multi(sd, map))
  th <- numeric(map$p)
  th[map$index$gamma] <- core$mnl$gamma
  for (j in seq_len(sd$J)) {
    lab <- sd$regimes[j]
    r <- core$reg[[j]]
    th[map$index$beta[[lab]]] <- r$b[seq_len(r$kx)]
    a <- r$b[r$kx + seq_len(r$nt)]
    sig <- sqrt(sum(r$om * r$eta^2) / sum(r$om) + 0.5 * sum(a^2))
    rr <- a / sig
    q <- sqrt(sum(rr^2))
    if (!is.finite(q) || q > 0.8) rr <- rr * 0.8 / q
    if (!all(is.finite(rr))) rr <- rep(0, length(a))
    th[map$index$sigma[[lab]]] <- sig
    th[map$index$rho[[lab]]] <- rr
  }
  se_par_working(map, th)
}

## One draw from the normal-score model: regimes and the potential outcomes
## of all regimes (idiosyncratic parts independent across regimes).
se_sim_draw_ns <- function(V, xb, sigma, R) {
  n <- nrow(V); J <- ncol(V)
  U <- matrix(stats::runif(n * J), n, J)
  eta <- stats::qnorm(U)
  Ut <- V - log(-log(U))
  S <- integer(n); best <- rep(-Inf, n)
  for (k in seq_len(J)) {
    b <- Ut[, k] > best
    S[b] <- k; best[b] <- Ut[b, k]
  }
  Y <- matrix(0, n, J)
  for (j in seq_len(J)) {
    Y[, j] <- xb[, j] + sigma[j] * (drop(eta %*% R[j, ]) +
                                      sqrt(1 - sum(R[j, ]^2)) * stats::rnorm(n))
  }
  list(S = S, Y = Y)
}
