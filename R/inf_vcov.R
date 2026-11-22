## Layer 6: covariance estimators of the FIML estimator
## (LIKELIHOOD_DERIVATION.md s.7). H is the weighted Hessian and score_i the
## unweighted per-observation scores, both on the free working parameters.
##   hessian   (-H)^{-1}
##   opg       (sum w_i^2 s_i s_i')^{-1}
##   sandwich  H^{-1} (sum w_i^2 s_i s_i') H^{-1}
##   cluster   G/(G-1) H^{-1} (sum_g S_g S_g') H^{-1},  S_g = sum_{i in g} w_i s_i
## A covariance is returned only if the Hessian is negative definite
## (NUMERICAL_METHODS.md s.3); otherwise a matrix of NA.

inf_vcov_fiml <- function(type, H, score_i, weights = NULL, cluster = NULL) {
  p <- ncol(H)
  na <- matrix(NA_real_, p, p)
  if (!all(is.finite(H))) return(na)
  ev <- eigen((H + t(H)) / 2, symmetric = TRUE)
  if (any(ev$values >= 0)) return(na)
  Hinv <- -(ev$vectors %*% (t(ev$vectors) / ev$values))   # (-H)^{-1}
  om <- weights %||% rep(1, nrow(score_i))
  ws <- om * score_i
  V <- switch(type,
    hessian = Hinv,
    opg = tryCatch(solve(crossprod(ws)), error = function(e) na),
    sandwich = Hinv %*% crossprod(ws) %*% Hinv,
    cluster = {
      if (is.null(cluster)) se_abort("vcov = \"cluster\" needs a cluster variable",
                                     "argument")
      G <- max(cluster)
      Sg <- rowsum(ws, cluster)
      G / (G - 1) * Hinv %*% crossprod(Sg) %*% Hinv
    },
    se_abort(sprintf("unknown covariance type '%s'", type), "argument"))
  (V + t(V)) / 2
}
