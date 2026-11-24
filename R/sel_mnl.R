## Multinomial logit selection (MULTINOMIAL_ESR.md s.2): probabilities and
## first-step maximum likelihood. Used by every two-step estimator of the
## multinomial models and for the FIML starting values. Any J >= 2.

## n x J matrix of log choice probabilities. G is the (J-1) x kz matrix of
## coefficients of the non-base alternatives (rows in level order); `base`
## is the index of the base alternative among the J regimes.
se_mnl_logP <- function(Z, G, base) {
  J <- nrow(G) + 1L
  V <- matrix(0, nrow(Z), J)
  V[, -base] <- Z %*% t(G)
  mx <- V[cbind(seq_len(nrow(V)), max.col(V, ties.method = "first"))]
  V - (mx + log(rowSums(exp(V - mx))))
}

## First-step ML by Newton's method (the log-likelihood is globally concave).
## S in 1..J. Returns gamma as a vector ordered by alternative, its
## covariance (inverse information), unweighted scores, and the fitted
## probabilities.
est_mnl <- function(Z, S, J, base, weights = NULL, maxit = 100L,
                    tol = 1e-10) {
  n <- nrow(Z); kz <- ncol(Z); K <- J - 1L
  om <- weights %||% rep(1, n)
  alts <- setdiff(seq_len(J), base)
  Y <- outer(S, alts, `==`) * 1                      # n x K indicators
  g <- matrix(0, K, kz)
  pos <- function(k) (k - 1L) * kz + seq_len(kz)
  eval_at <- function(g) {
    lP <- se_mnl_logP(Z, g, base)
    P <- exp(lP)
    Pk <- P[, alts, drop = FALSE]
    R <- Y - Pk
    score <- as.vector(crossprod(Z, om * R))         # by alternative
    H <- matrix(0, K * kz, K * kz)
    for (k in seq_len(K)) for (l in k:K) {
      wkl <- om * Pk[, k] * ((k == l) - Pk[, l])
      B <- crossprod(Z, wkl * Z)
      H[pos(k), pos(l)] <- B
      if (l != k) H[pos(l), pos(k)] <- B
    }
    list(loglik = sum(om * lP[cbind(seq_len(n), S)]), score = score,
         info = H, P = P, R = R)
  }
  cur <- eval_at(g)
  converged <- FALSE
  it <- 0L
  for (it in seq_len(maxit)) {
    step <- tryCatch(solve(cur$info, cur$score), error = function(e) NULL)
    if (is.null(step) || !all(is.finite(step))) break
    lam <- 1
    repeat {                                         # step halving
      gn <- g + lam * matrix(step, K, kz, byrow = TRUE)
      new <- eval_at(gn)
      if (is.finite(new$loglik) && new$loglik >= cur$loglik - 1e-12) break
      lam <- lam / 2
      if (lam < 1e-8) break
    }
    if (lam < 1e-8) break
    done <- max(abs(lam * step)) <= tol * (1 + max(abs(gn))) &&
      max(abs(new$score)) <= 1e-6 * (1 + abs(new$loglik))
    g <- gn
    cur <- new
    if (done) { converged <- TRUE; break }
  }
  V <- tryCatch(solve(cur$info), error = function(e)
    se_abort("the multinomial-logit information matrix is singular", "rank"))
  score_i <- matrix(0, n, K * kz)
  for (k in seq_len(K)) score_i[, pos(k)] <- cur$R[, k] * Z
  pmin_ <- min(cur$P[cbind(seq_len(n), S)])
  list(gamma = as.vector(t(g)), G = g, V = V, info = cur$info,
       score_i = score_i, P = cur$P, loglik = cur$loglik,
       converged = converged, iterations = it,
       separation = any(cur$P > 1 - 1e-10) || pmin_ < 1e-12,
       warnings = character())
}
