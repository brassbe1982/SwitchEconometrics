## Identification checks and residuals for multinomial regime selection
## (IDENTIFICATION.md s.4 and s.8; MULTINOMIAL_ESR.md s.8).

se_validate_multi <- function(spec, sd, fit = NULL) {
  rows <- list()
  add <- function(code, check, status, value = "", message = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      code = code, check = check, status = status, value = as.character(value),
      message = message, stringsAsFactors = FALSE)
  }
  labs <- sd$regimes; J <- sd$J; n <- sd$n; K <- J - 1L
  type <- if (identical(sd$structure, "normal_scores")) "bfg2"
          else sd$correction %||% "lee"
  rank_row <- function(X, what) {
    q <- qr(X, tol = 1e-7)
    if (q$rank < ncol(X)) {
      add("I1", what, "error", sprintf("rank %d of %d", q$rank, ncol(X)),
          paste("aliased:", paste(colnames(X)[q$pivot[(q$rank + 1L):ncol(X)]],
                                  collapse = ", ")))
      FALSE
    } else {
      add("I1", what, "ok", sprintf("rank %d of %d", q$rank, ncol(X)))
      TRUE
    }
  }
  rank_ok <- rank_row(sd$Z, "rank of the selection design")
  for (j in seq_len(J)) {
    Xr <- sd$X[[j]][sd$S == j, , drop = FALSE]
    rank_ok <- (if (nrow(Xr)) rank_row(Xr, sprintf(
      "rank of the '%s' design within its regime", labs[j])) else FALSE) &&
      rank_ok
  }
  for (j in seq_len(J)) {
    nj <- sum(sd$S == j); kj <- ncol(sd$X[[j]])
    st <- if (nj <= kj + 2L) "error" else if (nj / n < 0.02) "warning"
          else if (nj < 10 * (kj + 2L)) "note" else "ok"
    add("I2", sprintf("size of regime '%s'", labs[j]), st,
        sprintf("n = %d (%.1f%%), %d outcome coefficients", nj, 100 * nj / n, kj),
        switch(st, error = "too few observations for the outcome equation",
               warning = "regime share below 2%",
               note = "fewer than 10 observations per outcome parameter", ""))
  }

  ml <- NULL
  if (!is.null(fit$two_step)) {
    ml <- list(gamma = fit$two_step$probit$gamma, V = fit$two_step$Vg,
               P = fit$two_step$P, separation = fit$two_step$probit$separation,
               converged = fit$two_step$probit$converged)
  } else if (rank_ok) {
    ml <- tryCatch(est_mnl(sd$Z, sd$S, J, sd$base, sd$weights),
                   error = function(e) NULL)
  }
  if (is.null(ml)) {
    add("I3", "separation in the selection model", "skipped", "",
        "multinomial logit not estimable")
  } else {
    st <- if (isTRUE(ml$separation) || !isTRUE(ml$converged)) "warning" else "ok"
    add("I3", "separation in the selection model", st,
        sprintf("fitted probabilities in [%.2g, %.2g]", min(ml$P), max(ml$P)),
        if (st == "warning") "fitted probabilities numerically 0 or 1, or the multinomial logit did not converge" else "")
  }

  kz <- ncol(sd$Z)
  pos <- function(k) (k - 1L) * kz + seq_len(kz)
  for (j in seq_len(J)) {
    lab <- labs[j]
    ex <- sd$exclusions[[lab]]
    if (!length(ex)) {
      add("I4", sprintf("variables excluded from '%s'", lab), "warning", "none",
          sprintf(paste0(
            "Identification of the dependence parameters of '%s' depends ",
            "entirely on the functional form of the selection model: no ",
            "selection variable is excluded from this outcome equation."), lab))
      add("I5", sprintf("strength of exclusions for '%s'", lab), "skipped", "",
          "no excluded variables")
      next
    }
    add("I4", sprintf("variables excluded from '%s'", lab), "ok",
        paste(ex, collapse = ", "))
    if (is.null(ml)) {
      add("I5", sprintf("strength of exclusions for '%s'", lab), "skipped", "",
          "multinomial logit not estimable")
      next
    }
    E <- match(ex, colnames(sd$Z))
    ii <- unlist(lapply(seq_len(K), function(k) pos(k)[E]))
    g <- ml$gamma[ii]
    V <- ml$V[ii, ii, drop = FALSE]
    chi2 <- tryCatch(drop(t(g) %*% solve(V, g)), error = function(e) NA_real_)
    df <- length(ii)
    p <- stats::pchisq(chi2, df, lower.tail = FALSE)
    ratio <- chi2 / df
    st <- if (!is.finite(chi2) || p > 0.05) "warning"
          else if (ratio < 10) "note" else "ok"
    add("I5", sprintf("strength of exclusions for '%s'", lab), st,
        sprintf("chi2(%d) = %.2f, p = %.3g, chi2/df = %.1f", df, chi2, p, ratio),
        switch(st,
               warning = "excluded variables not jointly significant in the selection model: weak or irrelevant exclusion restriction",
               note = "significant but weak by the heuristic chi2/df < 10", ""))
    ## I4b: directions in which the exclusions move the selection indices
    nterm <- switch(type, lee = 1L, dmf = K, J)
    Gm <- matrix(ml$gamma, K, kz, byrow = TRUE)[, E, drop = FALSE]
    rk <- qr(Gm, tol = 1e-7)$rank
    need <- min(nterm, K)
    add("I4b", sprintf("directions moved by the exclusions for '%s'", lab),
        if (rk >= need) "ok" else "note",
        sprintf("%d excluded variable(s) move the selection indices in %d direction(s); %d correction term(s)",
                length(E), rk, nterm),
        if (rk < need) paste(
          "fewer directions than correction terms: some terms are identified",
          "through the functional form only") else "")
  }

  if (!is.null(ml)) {
    for (j in seq_len(J)) {
      lab <- labs[j]
      sel <- sd$S == j
      X <- sd$X[[lab]][sel, , drop = FALSE]
      C <- se_correction_terms(ml$P[sel, , drop = FALSE], j, type)$C
      r2 <- vapply(seq_len(ncol(C)), function(t) {
        R <- cbind(X, C[, -t, drop = FALSE])
        f <- stats::lm.fit(R, C[, t])
        1 - sum(f$residuals^2) / sum((C[, t] - mean(C[, t]))^2)
      }, numeric(1))
      kap <- kappa(cbind(X, C), exact = FALSE)
      st <- if (max(r2) > 0.80) (if (type == "lee") "warning" else "note")
            else "ok"
      add("I6", sprintf("collinearity of the correction term(s) for '%s'", lab),
          st, sprintf("largest R2 = %.3f, condition number %.3g", max(r2), kap),
          switch(st,
                 warning = "selection-correction term highly collinear with the outcome regressors (R2 > 0.80): rho is weakly identified",
                 note = "correction terms are smooth functions of the same probabilities and are highly collinear: their coefficients are imprecise",
                 ""))
    }
    add("I7", "range of the choice probabilities", "note",
        sprintf("smallest fitted probability of the chosen regime %.3g",
                min(ml$P[cbind(seq_len(n), sd$S)])),
        "a narrow range of probabilities weakens identification by functional form")
  }

  if (is.null(fit)) {
    add("I8", "boundary and conditioning", "skipped", "", "model not fitted")
    add("I9", "multistart agreement", "skipped", "", "model not fitted")
  } else {
    fl <- fit$diagnostics$flags
    bad <- c(if (length(fl$rho_boundary)) paste("boundary:",
                                                paste(fl$rho_boundary, collapse = ", ")),
             if (length(fl$sigma_boundary)) "degenerate sigma",
             if (isTRUE(fl$ill_conditioned)) "ill-conditioned Hessian",
             if (isTRUE(fl$hessian_not_nd)) "Hessian not negative definite")
    add("I8", "boundary and conditioning", if (length(bad)) "warning" else "ok",
        if (length(bad)) paste(bad, collapse = "; ") else
          if (fit$method == "fiml") sprintf("condition number %.3g",
                                            fit$diagnostics$hessian_condition)
          else "two-step")
    if (fit$method == "fiml") {
      st <- if (isTRUE(fit$diagnostics$multistart_flat)) "warning"
            else if (isTRUE(fit$diagnostics$local_maxima > 0)) "note" else "ok"
      add("I9", "multistart agreement", st,
          sprintf("%d starts, %d converged, %d local maxima", nrow(fit$starts),
                  sum(fit$starts$code == 0L), fit$diagnostics$local_maxima),
          switch(st, warning = "different parameters reach the same maximum: flat likelihood",
                 note = "lower local maxima exist; the best was retained", ""))
    } else {
      add("I9", "multistart agreement", "skipped", "", "two-step fit")
    }
  }
  add("I10", "falsification test of exclusions", "skipped", "",
      "defined for the binary switching model only")
  add("I11", "parameters not identified", "note",
      sprintf("%d cross-regime outcome correlations", J * (J - 1L) / 2L),
      paste0("outcomes of different regimes are never observed together: ",
             "their correlations do not enter the likelihood and are not ",
             "estimated",
             if (type == "lee") "; counterfactual means rely on assumption L-CI"
             else ""))

  tab <- do.call(rbind, rows)
  cls <- data.frame(
    parameters = c("selection coefficients",
                   paste0(labs, ": coefficients", if (type == "lee") " and sigma"),
                   paste0(labs, if (type == "lee") ": rho"
                          else ": correction coefficients"),
                   "cross-regime outcome correlations"),
    identified_by = c(
      "multinomial logit with a base alternative (structural)",
      rep("regime data given rank (structural)", J),
      vapply(labs, function(l) if (!length(sd$exclusions[[l]]))
        "functional form of the selection model only"
        else "exclusion restriction (given the distributional assumptions)",
        character(1)),
      "not identified"),
    stringsAsFactors = FALSE)
  structure(list(table = tab, classification = cls, fitted = !is.null(fit),
                 n = n, regimes = labs), class = "switch_validation")
}

se_residuals_multi <- function(object, type) {
  sd <- object$data
  r <- sd$y - se_predict_multi(object, NULL, "observed", FALSE)
  if (type == "response") return(r)
  if (!identical(object$map$kind, "lee")) {
    se_abort(paste0("Pearson residuals are available for Lee's model only ",
                    "in this version"), "unsupported")
  }
  th <- object$coefficients
  map <- object$map
  P <- se_predict_multi(object, NULL, "probability", FALSE)
  s <- numeric(sd$n)
  for (j in seq_len(sd$J)) {
    lab <- sd$regimes[j]
    sel <- sd$S == j
    v <- th[[map$index$sigma[[lab]]]]^2 *
      (1 - th[[map$index$rho[[lab]]]]^2 * se_d1(stats::qnorm(P[sel, j])))
    s[sel] <- ifelse(v > 0, sqrt(v), NA_real_)
  }
  r / s
}
