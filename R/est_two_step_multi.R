## Layer 4: two-step estimators with multinomial-logit selection
## (MULTINOMIAL_ESR.md s.3.4 and s.4). Any number of regimes.
##
##   "lee"   Lee (1983): one term m_1(w_j), w_j = qnorm(P_j); sigma_j and
##           rho_j recovered as in the binary model; model-based covariance
##           (first-step corrected), stacked sandwich or cluster covariance.
##   "dmf"   Dubin and McFadden (1984) with sum_k r_jk = 0: J - 1 terms.
##   "bfg1"  Bourguignon, Fournier and Gurgand (2007), variant 1: J terms.
##   "bfg2"  variant 2 (normalised Gumbel disturbances): J terms.
## The last three are moment models: beta_j and the coefficients of the
## correction terms are reported, sigma_j and correlations are not. Their
## covariance is the bootstrap over both steps; the stacked M-estimation
## sandwich is computed as well and stored for comparison.

## ---- correction terms -----------------------------------------------------
## m(P) = E[qnorm(G(u)) | alternative chosen with probability P] of BFG
## variant 2, tabulated once on log P and interpolated by a cubic spline.
se_cache <- new.env(parent = emptyenv())
se_bfg_m_spline <- function() {
  if (!is.null(se_cache$bfg_m)) return(se_cache$bfg_m)
  x <- c(seq(-30, -2, length.out = 281L), seq(-1.995, -0.1, by = 0.005),
         seq(-0.099, 0, by = 0.001))
  f <- function(lp) stats::integrate(function(v)
    stats::qnorm(-exp(-(v - lp)), log.p = TRUE) * exp(-v - exp(-v)),
    -6, 45, rel.tol = 1e-11, subdivisions = 400L)$value
  se_cache$bfg_m <- stats::splinefun(x, vapply(x, f, numeric(1)),
                                     method = "fmm")
  se_cache$bfg_m
}

## Own and other forms of the conditional Gumbel moments, and their
## derivatives with respect to the probability.
##   dmf, bfg1: own(P) = -log P;  other(P) = P log P / (1 - P)
##   bfg2:      own(P) = m(P);    other(P) = m(P) P / (P - 1)
se_gumbel_forms <- function(P, type) {
  P <- pmin(pmax(P, 1e-300), 1 - 1e-12)
  lp <- log(P)
  if (type == "bfg2") {
    sp <- se_bfg_m_spline()
    lpc <- pmax(lp, -30)
    m <- dm <- P                                   # keep the dimensions
    m[] <- sp(lpc); dm[] <- sp(lpc, deriv = 1L) / P
    list(own = m, d_own = dm, other = m * P / (P - 1),
         d_other = dm * P / (P - 1) - m / (P - 1)^2)
  } else {
    list(own = -lp, d_own = -1 / P, other = P * lp / (1 - P),
         d_other = (lp + 1 - P) / (1 - P)^2)
  }
}

## Basis B_k: n x J matrix whose column l is own(P_l) if l = k and
## other(P_l) otherwise, so that E[eps_j | S = k] = B_k a_j
## (MULTINOMIAL_ESR.md s.4.4). dB is the matrix of derivatives of each
## column with respect to its own probability.
se_gumbel_basis <- function(P, k, type) {
  fm <- se_gumbel_forms(P, type)
  B <- fm$other; dB <- fm$d_other
  B[, k] <- fm$own[, k]; dB[, k] <- fm$d_own[, k]
  list(B = B, dB = dB)
}

## Labels of the correction coefficients of a regime.
se_correction_labels <- function(sd, lab) {
  if (sd$correction == "dmf") setdiff(sd$regimes, lab) else sd$regimes
}

## Regressors of the correction for the rows of regime j, with the pieces
## needed for the Jacobian with respect to gamma. Returns C (n_j x T) and
## dC (list of T matrices n_j x J: derivative of term t with respect to each
## probability).
se_correction_terms <- function(P, j, type) {
  J <- ncol(P)
  if (type == "lee") {
    w <- stats::qnorm(P[, j])
    lamw <- stats::dnorm(w) / P[, j]
    dC <- matrix(0, nrow(P), J)
    dC[, j] <- -se_delta(w, lamw) / stats::dnorm(w)     # dm1/dw * dw/dP_j
    return(list(C = cbind(lambda = se_m1(w)), dC = list(dC), w = w))
  }
  bs <- se_gumbel_basis(P, j, type)
  if (type == "dmf") {
    oth <- setdiff(seq_len(J), j)
    C <- bs$B[, oth, drop = FALSE] - bs$B[, j]
    dC <- lapply(oth, function(l) {
      d <- matrix(0, nrow(P), J)
      d[, l] <- bs$dB[, l]; d[, j] <- -bs$dB[, j]
      d
    })
  } else {
    C <- bs$B
    dC <- lapply(seq_len(J), function(l) {
      d <- matrix(0, nrow(P), J)
      d[, l] <- bs$dB[, l]
      d
    })
  }
  list(C = C, dC = dC)
}

## d c / d gamma (n x K kz) of one term from its derivatives with respect to
## the probabilities: dP_l / dgamma_a = P_l (1{l = a} - P_a) z.
se_term_jacobian <- function(dCt, P, Z, alts) {
  s <- rowSums(dCt * P)                       # sum_l dc/dP_l P_l
  do.call(cbind, lapply(alts, function(a) (dCt[, a] * P[, a] - s * P[, a]) * Z))
}

## ---- estimation -----------------------------------------------------------
## Point estimates and the pieces for the covariances.
se_ts_multi_core <- function(Z, S, y, X, J, base, type, om, labels,
                             pieces = TRUE) {
  alts <- setdiff(seq_len(J), base)
  ml <- est_mnl(Z, S, J, base, om)
  reg <- vector("list", J)
  for (j in seq_len(J)) {
    sel <- S == j
    Pj <- ml$P[sel, , drop = FALSE]
    ct <- se_correction_terms(Pj, j, type)
    C <- ct$C
    colnames(C) <- if (type == "lee") "lambda" else sprintf(
      "theta[%s]", if (type == "dmf") labels[-j] else labels)
    W <- cbind(X[[j]][sel, , drop = FALSE], C)
    fit <- stats::lm.wfit(W, y[sel], om[sel])
    b <- fit$coefficients
    if (anyNA(b)) {
      se_abort(sprintf(paste0(
        "two-step: the selection-correction terms are collinear with the ",
        "regressors of '%s' (aliased: %s)"), labels[j],
        paste(names(b)[is.na(b)], collapse = ", ")), "rank")
    }
    r <- list(sel = sel, b = b, kx = ncol(X[[j]]), nt = ncol(C))
    if (pieces) {
      r$W <- W
      r$eta <- y[sel] - drop(W %*% b)
      r$om <- om[sel]
      a <- b[r$kx + seq_len(r$nt)]
      ## derivative of the fitted correction a'c with respect to gamma
      r$Jac <- Reduce(`+`, lapply(seq_len(r$nt), function(t)
        a[t] * se_term_jacobian(ct$dC[[t]], Pj, Z[sel, , drop = FALSE], alts)))
      if (type == "lee") {
        r$D <- se_d1(ct$w)
        r$G <- se_term_jacobian(ct$dC[[1L]], Pj, Z[sel, , drop = FALSE], alts) /
          (-r$D)                                         # dw/dgamma
      }
    }
    reg[[j]] <- r
  }
  list(mnl = ml, reg = reg)
}

est_two_step_multi <- function(sd, map, vcov_type = c("model", "robust",
                                                      "cluster"),
                               type = sd$correction %||% "lee",
                               bootstrap_R = 199L, seed = 20261123L) {
  vcov_type <- match.arg(vcov_type)
  if (vcov_type == "cluster" && is.null(sd$cluster)) {
    se_abort("vcov = \"cluster\" needs a cluster variable", "argument")
  }
  J <- sd$J; labs <- sd$regimes; kz <- ncol(sd$Z); K <- J - 1L
  om <- sd$weights %||% rep(1, sd$n)
  core <- se_ts_multi_core(sd$Z, sd$S, sd$y, sd$X, J, sd$base, type, om, labs)
  ml <- core$mnl
  reg <- stats::setNames(core$reg, labs)
  ng <- K * kz
  kb <- vapply(reg, function(r) length(r$b), integer(1))
  off <- ng + c(0L, cumsum(kb)[-J])
  idx <- c(list(gamma = seq_len(ng)),
           stats::setNames(lapply(seq_len(J), function(j) off[j] +
                                    seq_len(kb[j])), labs))
  psi <- c(ml$gamma, unlist(lapply(reg, `[[`, "b"), use.names = FALSE))
  gname <- map$elements$name[map$index$gamma]
  names(psi) <- c(gname, unlist(lapply(labs, function(l) {
    nb <- names(reg[[l]]$b)
    nb[nb == "lambda"] <- "theta"
    paste0(l, ":", nb)
  })))
  P <- length(psi)
  Vg <- ml$V

  ## stacked M-estimation sandwich (always computed; cluster sums if asked)
  M <- matrix(0, sd$n, P)
  M[, idx$gamma] <- om * ml$score_i
  A <- matrix(0, P, P)
  A[idx$gamma, idx$gamma] <- -ml$info
  for (l in labs) {
    r <- reg[[l]]
    M[r$sel, idx[[l]]] <- (r$om * r$eta) * r$W
    A[idx[[l]], idx$gamma] <- -crossprod(r$W * r$om, r$Jac)
    A[idx[[l]], idx[[l]]] <- -crossprod(r$W * r$om, r$W)
  }
  sandwich <- function(cluster) {
    B <- if (!is.null(cluster)) {
      Gc <- max(cluster)
      Gc / (Gc - 1) * crossprod(rowsum(M, cluster))
    } else crossprod(M)
    Ai <- solve(A)
    V <- Ai %*% B %*% t(Ai)
    (V + t(V)) / 2
  }
  V_sand <- sandwich(NULL)

  coefs <- numeric(map$p)
  names(coefs) <- map$elements$name
  coefs[map$index$gamma] <- ml$gamma
  theta <- list(); rho_out <- stats::setNames(rep(FALSE, J), labs)
  boot <- NULL
  if (type == "lee") {
    V <- matrix(0, P, P)
    sig <- rho <- numeric(J)
    for (j in seq_len(J)) {
      r <- reg[[j]]
      th <- r$b[[length(r$b)]]
      s2 <- sum(r$om * r$eta^2) / sum(r$om) + th^2 * sum(r$om * r$D) / sum(r$om)
      sig[j] <- sqrt(s2); rho[j] <- th / sig[j]
      theta[[labs[j]]] <- th
    }
    rho_out[] <- abs(rho) >= 1
    if (vcov_type == "model") {
      V[idx$gamma, idx$gamma] <- Vg
      piece <- list()
      for (j in seq_len(J)) {
        l <- labs[j]; r <- reg[[j]]
        WWi <- solve(crossprod(r$W))
        WDG <- crossprod(r$W * r$D, r$G)
        V[idx[[l]], idx[[l]]] <- sig[j]^2 * WWi %*%
          (crossprod(r$W * (1 - rho[j]^2 * r$D), r$W) +
             rho[j]^2 * WDG %*% Vg %*% t(WDG)) %*% WWi
        piece[[l]] <- WWi %*% (theta[[l]] * WDG)
        Cg <- piece[[l]] %*% Vg
        V[idx[[l]], idx$gamma] <- Cg
        V[idx$gamma, idx[[l]]] <- t(Cg)
      }
      for (a in seq_len(J - 1L)) for (b in (a + 1L):J) {
        Cc <- piece[[labs[a]]] %*% Vg %*% t(piece[[labs[b]]])
        V[idx[[labs[a]]], idx[[labs[b]]]] <- Cc
        V[idx[[labs[b]]], idx[[labs[a]]]] <- t(Cc)
      }
      V <- (V + t(V)) / 2
    } else {
      V <- if (vcov_type == "cluster") sandwich(sd$cluster) else V_sand
    }
    for (j in seq_len(J)) {
      l <- labs[j]
      coefs[map$index$beta[[l]]] <- reg[[j]]$b[seq_len(reg[[j]]$kx)]
      coefs[map$index$sigma[[l]]] <- sig[j]
      coefs[map$index$rho[[l]]] <- rho[j]
    }
    pos_map <- c(map$index$gamma, unlist(lapply(labs, function(l)
      map$index$beta[[l]])))
    pos_psi <- c(idx$gamma, unlist(lapply(labs, function(l)
      idx[[l]][-length(idx[[l]])])))
  } else {
    for (j in seq_len(J)) {
      l <- labs[j]; r <- reg[[j]]
      coefs[map$index$beta[[l]]] <- r$b[seq_len(r$kx)]
      coefs[map$index$theta[[l]]] <- r$b[r$kx + seq_len(r$nt)]
    }
    pos_map <- seq_len(map$p)
    pos_psi <- seq_len(P)
    V <- if (vcov_type == "cluster") sandwich(sd$cluster)
         else if (vcov_type == "robust") V_sand
         else {
           boot <- se_ts_multi_bootstrap(sd, type, psi, bootstrap_R, seed)
           boot$vcov
         }
  }
  dimnames(V) <- dimnames(V_sand) <- list(names(psi), names(psi))
  Vn <- matrix(NA_real_, map$p, map$p,
               dimnames = list(names(coefs), names(coefs)))
  Vn[pos_map, pos_map] <- V[pos_psi, pos_psi]
  list(method = "two_step", coefficients = coefs, vcov = Vn,
       vcov_type = vcov_type, psi = psi, vcov_psi = V, index_psi = idx,
       vcov_sandwich = V_sand, correction = type,
       theta = unlist(theta), rho_out_of_range = rho_out,
       probit = list(gamma = ml$gamma, loglik = ml$loglik,
                     converged = ml$converged, iterations = ml$iterations,
                     separation = ml$separation, warnings = character()),
       Vg = Vg, P = ml$P, bootstrap = boot)
}

## Bootstrap over both steps (units, or clusters when the data have them).
se_ts_multi_bootstrap <- function(sd, type, psi, R, seed) {
  rows <- if (is.null(sd$cluster)) NULL else split(seq_len(sd$n), sd$cluster)
  om <- sd$weights %||% rep(1, sd$n)
  one <- function() {
    idx <- if (is.null(rows)) sample.int(sd$n, sd$n, replace = TRUE) else
      unlist(rows[sample.int(length(rows), length(rows), replace = TRUE)],
             use.names = FALSE)
    out <- tryCatch({
      S <- sd$S[idx]
      if (any(tabulate(S, sd$J) == 0L)) stop("empty regime")
      cr <- se_ts_multi_core(sd$Z[idx, , drop = FALSE], S, sd$y[idx],
                             lapply(sd$X, function(X) X[idx, , drop = FALSE]),
                             sd$J, sd$base, type, om[idx], sd$regimes,
                             pieces = FALSE)
      if (!cr$mnl$converged) stop("first step did not converge")
      c(cr$mnl$gamma, unlist(lapply(cr$reg, `[[`, "b"), use.names = FALSE))
    }, error = function(e) NULL)
    out
  }
  draws <- se_with_seed(seed, lapply(seq_len(R), function(r) one()))
  ok <- !vapply(draws, is.null, logical(1))
  if (sum(ok) < max(10L, length(psi) + 1L)) {
    se_abort(sprintf("only %d of %d bootstrap replicates succeeded", sum(ok), R),
             "bootstrap")
  }
  B <- do.call(rbind, draws[ok])
  list(vcov = stats::cov(B), R = R, successful = sum(ok), seed = seed,
       clustered = !is.null(rows))
}

## FIML starting values from Lee's two-step; fallback: multinomial logit,
## least squares within regimes, rho = 0.
est_naive_start_multi <- function(sd, map) {
  om <- sd$weights %||% rep(1, sd$n)
  ml <- est_mnl(sd$Z, sd$S, sd$J, sd$base, sd$weights)
  th <- numeric(map$p)
  th[map$index$gamma] <- ml$gamma
  for (j in seq_len(sd$J)) {
    lab <- sd$regimes[j]
    sel <- sd$S == j
    fit <- stats::lm.wfit(sd$X[[lab]][sel, , drop = FALSE], sd$y[sel], om[sel])
    th[map$index$beta[[lab]]] <- fit$coefficients
    th[map$index$sigma[[lab]]] <- sqrt(sum(om[sel] * fit$residuals^2) /
                                         sum(om[sel]))
    th[map$index$rho[[lab]]] <- 0
  }
  se_par_working(map, th)
}
