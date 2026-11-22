## Layer 4: two-step (Heckman-Lee) estimator of the binary Gaussian ESR.
## Derivation: 01_Econometric_Architecture/LIKELIHOOD_DERIVATION.md s.9;
## verified by verify_math.R V07-V09, V13, V14.
##
## Step 1: probit of S on z (weighted if weights are given).
## Step 2: within regime j, (weighted) least squares of y on
##         W_j = (x_j, m_j(w)), m_1(w) = phi/Phi, m_0(w) = -phi/(1 - Phi);
##         the coefficient of m_j is theta_j = sigma_j rho_j.
## Variance recovery: sigma_j^2 = mean(eta^2) + theta_j^2 mean(delta_j(w)),
##         rho_j = theta_j / sigma_j.
## Covariance of psi = (gamma, b_0, b_1), b_j = (beta_j, theta_j):
##   "model"   Heckman (1979) / Greene (2012) first-stage-corrected formula,
##             with the cross-regime and first-stage covariances;
##   "robust"  stacked M-estimation sandwich A^{-1} B A^{-T};
##   "cluster" the same with cluster sums in B and factor G / (G - 1).

## Probit by IRLS (glm.fit, quasibinomial so that non-integer weights give no
## warning; the coefficients are those of the binomial probit).
est_probit <- function(Z, S, weights = NULL) {
  om <- weights %||% rep(1, length(S))
  warn <- character()
  fit <- withCallingHandlers(
    stats::glm.fit(Z, S, weights = om,
                   family = stats::quasibinomial(link = "probit"),
                   control = stats::glm.control(epsilon = 1e-10, maxit = 100)),
    warning = function(w) {
      warn <<- c(warn, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  g <- fit$coefficients
  if (anyNA(g)) {
    se_abort(sprintf("probit coefficient(s) not estimable: %s",
                     paste(colnames(Z)[is.na(g)], collapse = ", ")), "rank")
  }
  separated <- any(grepl("fitted probabilities numerically 0 or 1", warn))
  if (isTRUE(fit$converged) && !separated) g <- se_probit_polish(Z, S, om, g)
  w <- drop(Z %*% g)
  l1 <- se_mills(w); l0 <- se_mills(-w)
  info <- crossprod(Z * sqrt(om * l1 * l0))          # Fisher information
  score_i <- (S * l1 - (1 - S) * l0) * Z              # unweighted scores
  p <- stats::pnorm(w)
  list(gamma = stats::setNames(g, colnames(Z)), w = w, info = info,
       score_i = score_i,
       loglik = sum(om * (S * se_log_Phi(w) + (1 - S) * se_log_Phi(-w))),
       converged = isTRUE(fit$converged), iterations = fit$iter,
       separation = any(p < 1e-10 | p > 1 - 1e-10) || separated,
       warnings = warn)
}

## Newton steps on the exact probit Hessian after glm.fit. glm.fit stops on
## the relative change of the deviance, which can leave score components of
## order 1e-4 when regressors are on large scales (found in the WP1.8
## benchmarks, BENCHMARK_G1.md s.4). A step is kept only if it reduces the
## largest score component, so the polish cannot move away from the optimum.
se_probit_polish <- function(Z, S, om, g, maxit = 20L) {
  q <- 2 * S - 1
  pieces <- function(g) {
    qw <- q * drop(Z %*% g)
    lam <- se_mills(qw)
    list(score = colSums(om * q * lam * Z), d = lam * (lam + qw))
  }
  cur <- pieces(g)
  for (it in seq_len(maxit)) {
    H <- crossprod(Z * sqrt(om * cur$d))           # minus the Hessian
    step <- tryCatch(solve(H, cur$score), error = function(e) NULL)
    if (is.null(step) || !all(is.finite(step))) break
    new <- pieces(g + step)
    if (!all(is.finite(new$score)) ||
        max(abs(new$score)) >= max(abs(cur$score))) break
    g <- g + step
    cur <- new
    if (max(abs(step)) <= 1e-13 * (1 + max(abs(g)))) break
  }
  g
}

est_two_step <- function(sd, map, vcov_type = c("model", "robust", "cluster")) {
  vcov_type <- match.arg(vcov_type)
  if (vcov_type == "cluster" && is.null(sd$cluster)) {
    se_abort("vcov = \"cluster\" needs a cluster variable", "argument")
  }
  pr <- est_probit(sd$Z, sd$S, sd$weights)
  om <- sd$weights %||% rep(1, sd$n)
  kz <- ncol(sd$Z)
  Vg <- tryCatch(solve(pr$info), error = function(e)
    se_abort("the probit information matrix is singular", "rank"))
  reg <- list()
  for (r in 1:2) {
    lab <- sd$regimes[r]
    sel <- sd$S == (r - 1L)
    X <- sd$X[[lab]][sel, , drop = FALSE]
    w <- pr$w[sel]
    m <- if (r == 2L) se_m1(w) else se_m0(w)
    D <- if (r == 2L) se_d1(w) else se_d0(w)
    W <- cbind(X, lambda = m)
    ok <- om[sel]
    fit <- stats::lm.wfit(W, sd$y[sel], ok)
    b <- fit$coefficients
    if (anyNA(b)) {
      se_abort(sprintf(paste0(
        "two-step: the selection-correction term is collinear with the ",
        "regressors of '%s' (aliased: %s); identification by functional form ",
        "fails in this sample"), lab, paste(names(b)[is.na(b)], collapse = ", ")),
        "rank")
    }
    eta <- sd$y[sel] - drop(W %*% b)
    th <- b[[length(b)]]
    s2 <- sum(ok * eta^2) / sum(ok) + th^2 * sum(ok * D) / sum(ok)
    reg[[lab]] <- list(sel = sel, W = W, Z = sd$Z[sel, , drop = FALSE],
                       b = b, theta = th, sigma = sqrt(s2), rho = th / sqrt(s2),
                       eta = eta, D = D, om = ok)
  }
  labs <- sd$regimes
  kb <- vapply(reg, function(x) length(x$b), integer(1))
  P <- kz + sum(kb)
  idx <- list(gamma = seq_len(kz), kz + seq_len(kb[1]),
              kz + kb[1] + seq_len(kb[2]))
  names(idx)[2:3] <- labs
  psi <- c(pr$gamma, reg[[1]]$b, reg[[2]]$b)
  names(psi) <- c(paste0("selection:", colnames(sd$Z)),
                  paste0(labs[1], ":", names(reg[[1]]$b)),
                  paste0(labs[2], ":", names(reg[[2]]$b)))

  V <- matrix(0, P, P, dimnames = list(names(psi), names(psi)))
  if (vcov_type == "model") {
    V[idx$gamma, idx$gamma] <- Vg
    piece <- list()
    for (lab in labs) {
      R <- reg[[lab]]
      WWi <- solve(crossprod(R$W))
      WDZ <- crossprod(R$W * R$D, R$Z)
      V[idx[[lab]], idx[[lab]]] <- R$sigma^2 * WWi %*%
        (crossprod(R$W * (1 - R$rho^2 * R$D), R$W) +
           R$rho^2 * WDZ %*% Vg %*% t(WDZ)) %*% WWi
      Cg <- WWi %*% (R$theta * WDZ) %*% Vg
      V[idx[[lab]], idx$gamma] <- Cg
      V[idx$gamma, idx[[lab]]] <- t(Cg)
      piece[[lab]] <- WWi %*% (R$theta * WDZ)
    }
    C <- piece[[labs[2]]] %*% Vg %*% t(piece[[labs[1]]])
    V[idx[[labs[2]]], idx[[labs[1]]]] <- C
    V[idx[[labs[1]]], idx[[labs[2]]]] <- t(C)
  } else {
    M <- matrix(0, sd$n, P)
    M[, idx$gamma] <- om * pr$score_i
    A <- matrix(0, P, P)
    A[idx$gamma, idx$gamma] <- -pr$info
    for (lab in labs) {
      R <- reg[[lab]]
      M[R$sel, idx[[lab]]] <- (R$om * R$eta) * R$W
      A[idx[[lab]], idx$gamma] <- R$theta * crossprod(R$W * (R$om * R$D), R$Z)
      A[idx[[lab]], idx[[lab]]] <- -crossprod(R$W * R$om, R$W)
    }
    B <- if (vcov_type == "cluster") {
      G <- max(sd$cluster)
      Sg <- rowsum(M, sd$cluster)
      G / (G - 1) * crossprod(Sg)
    } else crossprod(M)
    Ai <- solve(A)
    V[] <- Ai %*% B %*% t(Ai)
  }
  V <- (V + t(V)) / 2

  ## natural coefficients in parameter-map order; sigma and rho are derived
  ## quantities without closed-form standard errors (NA in vcov)
  coefs <- numeric(map$p)
  names(coefs) <- map$elements$name
  coefs[map$index$gamma] <- pr$gamma
  Vn <- matrix(NA_real_, map$p, map$p, dimnames = list(names(coefs),
                                                      names(coefs)))
  pos_map <- c(map$index$gamma)
  pos_psi <- idx$gamma
  for (lab in labs) {
    R <- reg[[lab]]
    ib <- map$index$beta[[lab]]
    coefs[ib] <- R$b[-length(R$b)]
    coefs[map$index$sigma[[lab]]] <- R$sigma
    coefs[map$index$rho[[lab]]] <- R$rho
    pos_map <- c(pos_map, ib)
    pos_psi <- c(pos_psi, idx[[lab]][-length(idx[[lab]])])
  }
  Vn[pos_map, pos_map] <- V[pos_psi, pos_psi]

  rho_out <- vapply(reg, function(R) abs(R$rho) >= 1, logical(1))
  list(method = "two_step", coefficients = coefs, vcov = Vn,
       vcov_type = vcov_type, psi = psi, vcov_psi = V, index_psi = idx,
       theta = vapply(reg, function(R) R$theta, numeric(1)),
       rho_out_of_range = rho_out, probit = pr[c("gamma", "loglik",
                                                 "converged", "iterations",
                                                 "separation", "warnings")],
       Vg = Vg, w = pr$w)
}

## FIML starting values (working scale, full vector) from a two-step result:
## rho truncated to [-0.95, 0.95] (LIKELIHOOD_DERIVATION.md s.9).
est_two_step_start <- function(ts, map) {
  th <- ts$coefficients
  for (i in unlist(map$index$rho)) th[i] <- max(-0.95, min(0.95, th[i]))
  se_par_working(map, th)
}

## Fallback start when the two-step fails: probit, OLS within regimes,
## rho = 0.
est_naive_start <- function(sd, map) {
  pr <- est_probit(sd$Z, sd$S, sd$weights)
  om <- sd$weights %||% rep(1, sd$n)
  th <- numeric(map$p)
  th[map$index$gamma] <- pr$gamma
  for (r in 1:2) {
    lab <- sd$regimes[r]
    sel <- sd$S == (r - 1L)
    fit <- stats::lm.wfit(sd$X[[lab]][sel, , drop = FALSE], sd$y[sel], om[sel])
    th[map$index$beta[[lab]]] <- fit$coefficients
    th[map$index$sigma[[lab]]] <- sqrt(sum(om[sel] * fit$residuals^2) /
                                         sum(om[sel]))
    th[map$index$rho[[lab]]] <- 0
  }
  se_par_working(map, th)
}
