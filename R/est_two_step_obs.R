## Layer 4: two-step estimators of the observation mechanisms (Generation 2).
## Derivation: OBSERVATION_MECHANISMS.md s.2.4 (Heckman 1979) and s.3.4
## (treatment, pooled control function); verified by verify_math_g2.R
## (W06, W08) and by the tests against est_two_step().
##
## Both are one least-squares regression with a generated regressor:
##   Heckman:   rows S = 1, W = (x, m_1(w)),            D = delta_1(w);
##   treatment: all rows,   W = (x, S d, h),  h = S m_1(w) + (1 - S) m_0(w),
##                                                      D = delta_S(w).
## In both, the coefficient of the generated regressor is theta = sigma rho,
## its derivative with respect to w is -D, and
## Var(eps | S, z) = sigma^2 (1 - rho^2 D), so the covariance formulas of
## est_two_step() apply to the single regression.

est_two_step_obs <- function(sd, map, vcov_type = c("model", "robust",
                                                    "cluster")) {
  vcov_type <- match.arg(vcov_type)
  if (vcov_type == "cluster" && is.null(sd$cluster)) {
    se_abort("vcov = \"cluster\" needs a cluster variable", "argument")
  }
  pr <- est_probit(sd$Z, sd$S, sd$weights)
  om_all <- sd$weights %||% rep(1, sd$n)
  kz <- ncol(sd$Z)
  Vg <- tryCatch(solve(pr$info), error = function(e)
    se_abort("the probit information matrix is singular", "rank"))
  if (sd$model == "heckman") {
    sel <- sd$S == 1L
    w <- pr$w[sel]
    W <- cbind(sd$X$outcome[sel, , drop = FALSE], lambda = se_m1(w))
    D <- se_d1(w)
  } else {
    sel <- rep(TRUE, sd$n)
    w <- pr$w
    one <- sd$S == 1L
    Ds <- sd$S * sd$D
    colnames(Ds) <- paste0("shift:", colnames(sd$D))
    W <- cbind(sd$X[[1L]], Ds,
               lambda = ifelse(one, se_m1(w), se_m0(w)))
    D <- ifelse(one, se_d1(w), se_d0(w))
  }
  Z <- sd$Z[sel, , drop = FALSE]
  om <- om_all[sel]
  fit <- stats::lm.wfit(W, sd$y[sel], om)
  b <- fit$coefficients
  if (anyNA(b)) {
    se_abort(sprintf(paste0(
      "two-step: the selection-correction term is collinear with the ",
      "outcome regressors (aliased: %s); identification by functional form ",
      "fails in this sample"), paste(names(b)[is.na(b)], collapse = ", ")),
      "rank")
  }
  eta <- sd$y[sel] - drop(W %*% b)
  kb <- length(b)
  th <- b[[kb]]
  s2 <- sum(om * eta^2) / sum(om) + th^2 * sum(om * D) / sum(om)
  sigma <- sqrt(s2)
  rho <- th / sigma

  P <- kz + kb
  ig <- seq_len(kz)
  io <- kz + seq_len(kb)
  psi <- c(pr$gamma, b)
  bn <- names(b)
  bn <- ifelse(startsWith(bn, "shift:"), bn, paste0("outcome:", bn))
  bn[kb] <- "outcome:theta"
  names(psi) <- c(paste0("selection:", colnames(sd$Z)), bn)
  V <- matrix(0, P, P, dimnames = list(names(psi), names(psi)))
  if (vcov_type == "model") {
    WWi <- solve(crossprod(W))
    WDZ <- crossprod(W * D, Z)
    V[ig, ig] <- Vg
    V[io, io] <- s2 * WWi %*% (crossprod(W * (1 - rho^2 * D), W) +
                                 rho^2 * WDZ %*% Vg %*% t(WDZ)) %*% WWi
    Cg <- WWi %*% (th * WDZ) %*% Vg
    V[io, ig] <- Cg
    V[ig, io] <- t(Cg)
  } else {
    M <- matrix(0, sd$n, P)
    M[, ig] <- om_all * pr$score_i
    M[sel, io] <- (om * eta) * W
    A <- matrix(0, P, P)
    A[ig, ig] <- -pr$info
    A[io, ig] <- th * crossprod(W * (om * D), Z)
    A[io, io] <- -crossprod(W * om, W)
    B <- if (vcov_type == "cluster") {
      G <- max(sd$cluster)
      Sg <- rowsum(M, sd$cluster)
      G / (G - 1) * crossprod(Sg)
    } else crossprod(M)
    Ai <- solve(A)
    V[] <- Ai %*% B %*% t(Ai)
  }
  V <- (V + t(V)) / 2

  coefs <- numeric(map$p)
  names(coefs) <- map$elements$name
  pos_map <- c(map$index$gamma, map$index$beta$outcome, map$index$delta)
  coefs[pos_map] <- psi[seq_len(P - 1L)]
  coefs[map$index$sigma$outcome] <- sigma
  coefs[map$index$rho$outcome] <- rho
  Vn <- matrix(NA_real_, map$p, map$p,
               dimnames = list(names(coefs), names(coefs)))
  Vn[pos_map, pos_map] <- V[seq_len(P - 1L), seq_len(P - 1L)]
  list(method = "two_step", coefficients = coefs, vcov = Vn,
       vcov_type = vcov_type, psi = psi, vcov_psi = V,
       index_psi = list(gamma = ig, outcome = io),
       theta = c(outcome = th),
       rho_out_of_range = c(outcome = abs(rho) >= 1),
       probit = pr[c("gamma", "loglik", "converged", "iterations",
                     "separation", "warnings")],
       Vg = Vg, w = pr$w)
}

## Fallback FIML start: probit, least squares, rho = 0.
est_naive_start_obs <- function(sd, map) {
  pr <- est_probit(sd$Z, sd$S, sd$weights)
  om <- sd$weights %||% rep(1, sd$n)
  th <- numeric(map$p)
  th[map$index$gamma] <- pr$gamma
  if (sd$model == "heckman") {
    sel <- sd$S == 1L
    W <- sd$X$outcome[sel, , drop = FALSE]
  } else {
    sel <- rep(TRUE, sd$n)
    W <- cbind(sd$X[[1L]], sd$S * sd$D)
  }
  fit <- stats::lm.wfit(W, sd$y[sel], om[sel])
  th[c(map$index$beta$outcome, map$index$delta)] <- fit$coefficients
  th[map$index$sigma$outcome] <- sqrt(sum(om[sel] * fit$residuals^2) /
                                        sum(om[sel]))
  th[map$index$rho$outcome] <- 0
  se_par_working(map, th)
}

## Dispatch used by switch_fit(), the tests and the bootstrap.
se_two_step <- function(sd, map, vcov_type = "model") {
  if (se_is_obs(sd$model)) est_two_step_obs(sd, map, vcov_type)
  else if (se_is_multi(sd$model)) est_two_step_multi(
    sd, map, vcov_type, type = sd$correction %||% "lee",
    bootstrap_R = sd$bootstrap_R %||% 999L)
  else est_two_step(sd, map, vcov_type)
}
se_naive_start <- function(sd, map) {
  if (se_is_obs(sd$model)) est_naive_start_obs(sd, map)
  else if (se_is_multi(sd$model)) est_naive_start_multi(sd, map)
  else est_naive_start(sd, map)
}
se_parmap <- function(sd) {
  if (se_is_obs(sd$model)) se_parmap_obs(sd)
  else if (se_is_multi(sd$model)) se_parmap_multi(sd)
  else se_parmap_esr(sd)
}
