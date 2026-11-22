## Layer 7: effects engine (01_Econometric_Architecture/TREATMENT_EFFECTS.md).
##
## All conditional expectations depend on the parameters only through
##   psi = (gamma, beta_0, theta_0, beta_1, theta_1),  theta_j = sigma_j rho_j,
## which is also the parameter vector of the two-step estimator. For FIML
## fits the covariance of psi follows from the natural covariance by the delta
## method (d theta_j / d sigma_j = rho_j, d theta_j / d rho_j = sigma_j).

## Positions within psi; regimes in canonical order (S = 0, S = 1).
se_psi_index <- function(map, regimes) {
  kz <- length(map$index$gamma)
  k0 <- length(map$index$beta[[regimes[1L]]])
  k1 <- length(map$index$beta[[regimes[2L]]])
  list(gamma = seq_len(kz), beta0 = kz + seq_len(k0), theta0 = kz + k0 + 1L,
       beta1 = kz + k0 + 1L + seq_len(k1), theta1 = kz + k0 + k1 + 2L,
       P = kz + k0 + k1 + 2L)
}

se_psi_from_natural <- function(coef, map, regimes) {
  th <- function(r) coef[[map$index$sigma[[regimes[r]]]]] *
    coef[[map$index$rho[[regimes[r]]]]]
  unname(c(coef[map$index$gamma], coef[map$index$beta[[regimes[1L]]]], th(1L),
           coef[map$index$beta[[regimes[2L]]]], th(2L)))
}

## Covariance of psi for a fit.
se_psi_vcov <- function(object) {
  if (object$method == "two_step") return(unname(object$two_step$vcov_psi))
  map <- object$map
  reg <- object$regimes
  ix <- se_psi_index(map, reg)
  th <- object$coefficients
  J <- matrix(0, ix$P, map$p)
  J[cbind(ix$gamma, map$index$gamma)] <- 1
  J[cbind(ix$beta0, map$index$beta[[reg[1L]]])] <- 1
  J[cbind(ix$beta1, map$index$beta[[reg[2L]]])] <- 1
  for (r in 1:2) {
    it <- if (r == 1L) ix$theta0 else ix$theta1
    is <- map$index$sigma[[reg[r]]]
    ir <- map$index$rho[[reg[r]]]
    J[it, is] <- th[[ir]]
    J[it, ir] <- th[[is]]
  }
  J %*% object$vcov %*% t(J)
}

## Per-observation expectations (TREATMENT_EFFECTS.md s.2) and, optionally,
## their gradients with respect to psi (n x P matrices).
se_eff_components <- function(psi, Z, X0, X1, ix, grad = TRUE) {
  w <- drop(Z %*% psi[ix$gamma])
  xb0 <- drop(X0 %*% psi[ix$beta0])
  xb1 <- drop(X1 %*% psi[ix$beta1])
  th0 <- psi[[ix$theta0]]
  th1 <- psi[[ix$theta1]]
  m1 <- se_m1(w)
  m0 <- se_m0(w)
  EY <- cbind(EY1_S1 = xb1 + th1 * m1, EY1_S0 = xb1 + th1 * m0,
              EY0_S1 = xb0 + th0 * m1, EY0_S0 = xb0 + th0 * m0)
  out <- list(EY = EY, w = w, xb0 = xb0, xb1 = xb1, m1 = m1, m0 = m0,
              th0 = th0, th1 = th1)
  if (grad) {
    n <- nrow(Z)
    d1 <- se_d1(w)
    d0 <- se_d0(w)
    mk <- function(th, dk, X, ib, it, m) {
      G <- matrix(0, n, ix$P)
      G[, ix$gamma] <- (-th * dk) * Z
      G[, ib] <- X
      G[, it] <- m
      G
    }
    Gx <- matrix(0, n, ix$P)
    Gx[, ix$beta1] <- X1
    Gx[, ix$beta0] <- -X0
    out$grad <- list(EY1_S1 = mk(th1, d1, X1, ix$beta1, ix$theta1, m1),
                     EY1_S0 = mk(th1, d0, X1, ix$beta1, ix$theta1, m0),
                     EY0_S1 = mk(th0, d1, X0, ix$beta0, ix$theta0, m1),
                     EY0_S0 = mk(th0, d0, X0, ix$beta0, ix$theta0, m0),
                     ATE = Gx)
  }
  out
}

## Effects for the units in `set` (logical), with sampling weights `om`
## (TREATMENT_EFFECTS.md s.3); gradients with respect to psi if available.
se_eff_compute <- function(cmp, S, om, set) {
  T1 <- set & S == 1L
  T0 <- set & S == 0L
  if (!any(T1) || !any(T0)) {
    se_abort("each group needs units in both regimes to compute the effects",
             "data")
  }
  wm <- function(v, s) sum(om[s] * v[s]) / sum(om[s])
  EY <- cmp$EY
  a <- wm(EY[, "EY1_S1"], T1); b <- wm(EY[, "EY0_S1"], T1)
  c <- wm(EY[, "EY1_S0"], T0); d <- wm(EY[, "EY0_S0"], T0)
  ate <- wm(cmp$xb1 - cmp$xb0, set)
  est <- c(ATT = a - b, ATU = c - d, ATE = ate, TH = (a - b) - (c - d),
           BH1 = a - c, BH0 = b - d)
  pi1 <- sum(om[T1]) / sum(om[set])
  out <- list(estimate = est,
              means = c(EY1_S1 = a, EY0_S1 = b, EY1_S0 = c, EY0_S0 = d),
              n = c(S1 = sum(T1), S0 = sum(T0)),
              ate_weighted = pi1 * (a - b) + (1 - pi1) * (c - d))
  if (!is.null(cmp$grad)) {
    wg <- function(G, s) colSums(om[s] * G[s, , drop = FALSE]) / sum(om[s])
    Ga <- wg(cmp$grad$EY1_S1, T1); Gb <- wg(cmp$grad$EY0_S1, T1)
    Gc <- wg(cmp$grad$EY1_S0, T0); Gd <- wg(cmp$grad$EY0_S0, T0)
    G <- rbind(ATT = Ga - Gb, ATU = Gc - Gd, ATE = wg(cmp$grad$ATE, set),
               TH = (Ga - Gb) - (Gc - Gd), BH1 = Ga - Gc, BH0 = Gb - Gd)
    out$gradient <- G
  }
  out
}

## Effect values only (used by the bootstrap): overall or by group.
se_eff_values <- function(coef, sd, map, groups = NULL, set = NULL) {
  ix <- se_psi_index(map, sd$regimes)
  psi <- se_psi_from_natural(coef, map, sd$regimes)
  cmp <- se_eff_components(psi, sd$Z, sd$X[[1L]], sd$X[[2L]], ix, grad = FALSE)
  om <- sd$weights %||% rep(1, sd$n)
  set <- set %||% rep(TRUE, sd$n)
  if (is.null(groups)) return(se_eff_compute(cmp, sd$S, om, set)$estimate)
  lev <- levels(groups)
  unlist(lapply(lev, function(l) {
    e <- se_eff_compute(cmp, sd$S, om, set & !is.na(groups) & groups == l)$estimate
    stats::setNames(e, paste0(names(e), "[", l, "]"))
  }))
}

## Resolve `by` / `subset` given as a vector for the estimation sample, a
## vector for the full data, or a formula / column name with `data`.
se_eff_resolve <- function(arg, object, data, name) {
  if (is.null(arg)) return(NULL)
  n <- object$nobs
  idx <- object$data$index
  if (inherits(arg, "formula") || (is.character(arg) && length(arg) == 1L &&
                                   n != 1L)) {
    if (is.null(data)) {
      se_abort(sprintf(paste0("'%s' given as a formula or column name needs ",
                              "'data' (the data frame used for fitting)"), name),
               "argument")
    }
    return(se_resolve_aux(arg, data, name)[idx])
  }
  if (length(arg) == n) return(arg)
  if (!is.null(data) && length(arg) == nrow(data)) return(arg[idx])
  se_abort(sprintf("'%s' must have length nobs(object) = %d", name, n),
           "argument")
}
