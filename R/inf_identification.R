## Layer 6: identification diagnostics I1-I11
## (01_Econometric_Architecture/IDENTIFICATION.md, section 4).

#' Validate the identification of a switching model
#'
#' Runs the identification checks of the package's identification
#' architecture (specification section 3.5) on a specification with data,
#' or on a fitted model.
#'
#' | Code | Check |
#' | --- | --- |
#' | I1 | rank of the selection design and of each outcome design within its regime |
#' | I2 | regime sizes |
#' | I3 | separation in the selection equation |
#' | I4 | variables excluded from each outcome equation (none: identification by functional form only) |
#' | I5 | joint significance and strength of the excluded variables in the probit (Wald; heuristic flag for chi2/df < 10) |
#' | I6 | collinearity of the selection-correction term with the outcome regressors (R-squared, condition number) |
#' | I7 | range of the selection index |
#' | I8 | boundary and conditioning flags (fitted models) |
#' | I9 | multistart agreement (fitted models) |
#' | I10 | falsification test of the exclusion restriction among regime-0 units (Di Falco, Veronesi and Yesuf 2011), reported for information only: under selection on unobservables the literal test rejects valid exclusions, and its version conditional on the selection-correction term has no power |
#' | I11 | parameters that are not identified (the correlation of the two outcome disturbances, with its admissible range) |
#'
#' No data test can establish that an exclusion restriction is valid; the
#' checks detect weak, missing or collinear identifying variation.
#'
#' @param model A `switch_spec` (then `data` is required) or a `switch_fit`.
#' @param data,weights,cluster,subset Data and options as in [switch_fit()]
#'   (used with a `switch_spec`).
#' @param x A `switch_validation` object.
#' @param ... Not used.
#' @return An object of class `switch_validation` with a `table` of the
#'   checks (code, check, status, value, message) and a `classification` of
#'   how each parameter group is identified.
#' @references
#' Di Falco, S., Veronesi, M. and Yesuf, M. (2011). Does adaptation to
#' climate change provide food security? A micro-perspective from Ethiopia.
#' *American Journal of Agricultural Economics*, 93(3), 829--846.
#' \doi{10.1093/ajae/aar006}
#' @examples
#' set.seed(3)
#' n <- 500
#' d <- data.frame(x1 = rnorm(n), z1 = rnorm(n))
#' u <- rnorm(n)
#' d$S <- as.integer(0.2 + 0.5 * d$x1 - 0.7 * d$z1 + u > 0)
#' d$y <- ifelse(d$S == 1, 1 + d$x1 + 0.5 * u + rnorm(n),
#'               0.5 * d$x1 + 0.3 * u + rnorm(n))
#' spec <- switch_model(S ~ x1 + z1, list(y ~ x1, y ~ x1))
#' switch_validate(spec, d)
#' @export
switch_validate <- function(model, data = NULL, weights = NULL, cluster = NULL,
                            subset = NULL, ...) {
  if (inherits(model, "switch_fit")) {
    if (is.null(model$data)) {
      if (inherits(model$identification, "switch_validation")) {
        return(model$identification)
      }
      se_abort("the fit holds no data; refit with switch_control(keep_data = TRUE)",
               "argument")
    }
    return(se_validate_core(model$spec, model$data, model))
  }
  if (!inherits(model, "switch_spec")) {
    se_abort("'model' must be a switch_spec or a switch_fit", "argument")
  }
  if (is.null(data)) se_abort("'data' is required with a switch_spec", "argument")
  sd <- tryCatch(se_build_data(model, data, weights = weights,
                               cluster = cluster, subset = subset,
                               missing = "drop", check_rank = FALSE),
                 error = function(e) e)
  if (inherits(sd, "error")) {
    tab <- data.frame(code = "I0", check = "data and specification",
                      status = "error", value = "",
                      message = conditionMessage(sd), stringsAsFactors = FALSE)
    return(structure(list(table = tab, classification = NULL, fitted = FALSE),
                     class = "switch_validation"))
  }
  se_validate_core(model, sd, NULL)
}

se_validate_core <- function(spec, sd, fit = NULL) {
  rows <- list()
  add <- function(code, check, status, value = "", message = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      code = code, check = check, status = status, value = as.character(value),
      message = message, stringsAsFactors = FALSE)
  }
  labs <- sd$regimes
  n <- sd$n

  ## I1 rank
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
  for (r in 1:2) {
    Xr <- sd$X[[r]][sd$S == r - 1L, , drop = FALSE]
    rank_ok <- (if (nrow(Xr)) rank_row(Xr, sprintf(
      "rank of the '%s' design within its regime", labs[r])) else FALSE) &&
      rank_ok
  }

  ## I2 regime sizes
  for (r in 1:2) {
    nj <- sum(sd$S == r - 1L)
    kj <- ncol(sd$X[[r]])
    st <- if (nj <= kj + 2L) "error" else if (nj / n < 0.02) "warning" else "ok"
    add("I2", sprintf("size of regime '%s'", labs[r]), st,
        sprintf("n = %d (%.1f%%), %d outcome coefficients", nj, 100 * nj / n, kj),
        switch(st, error = "too few observations for the outcome equation",
               warning = "regime share below 2%", ""))
  }

  ## probit (from the fit's two-step if available)
  pr <- NULL
  if (!is.null(fit$two_step)) {
    pr <- list(gamma = fit$two_step$probit$gamma, Vg = fit$two_step$Vg,
               w = fit$two_step$w, separation = fit$two_step$probit$separation,
               converged = fit$two_step$probit$converged)
  } else if (rank_ok && all(sd$S %in% 0:1) && length(unique(sd$S)) == 2L) {
    pr <- tryCatch({
      p <- est_probit(sd$Z, sd$S, sd$weights)
      p$Vg <- solve(p$info)
      p
    }, error = function(e) NULL)
  }

  ## I3 separation
  if (is.null(pr)) {
    add("I3", "separation in the selection equation", "skipped", "",
        "probit not estimable")
  } else {
    st <- if (isTRUE(pr$separation) || !isTRUE(pr$converged)) "warning" else "ok"
    add("I3", "separation in the selection equation", st,
        sprintf("fitted probabilities in [%.2g, %.2g]",
                min(stats::pnorm(pr$w)), max(stats::pnorm(pr$w))),
        if (st == "warning") "fitted probabilities numerically 0 or 1, or the probit did not converge" else "")
  }

  ## I4 excluded variables; I5 strength
  excl <- sd$exclusions
  for (r in 1:2) {
    lab <- labs[r]
    ex <- excl[[lab]]
    if (!length(ex)) {
      add("I4", sprintf("variables excluded from '%s'", lab), "warning", "none",
          sprintf(paste0(
            "Identification of rho for '%s' depends entirely on the nonlinear ",
            "functional form of the normal distribution: no variable in the ",
            "selection equation is excluded from this outcome equation."), lab))
      add("I5", sprintf("strength of exclusions for '%s'", lab), "skipped", "",
          "no excluded variables")
      next
    }
    add("I4", sprintf("variables excluded from '%s'", lab), "ok",
        paste(ex, collapse = ", "))
    if (is.null(pr)) {
      add("I5", sprintf("strength of exclusions for '%s'", lab), "skipped", "",
          "probit not estimable")
      next
    }
    E <- match(ex, colnames(sd$Z))
    g <- pr$gamma[E]
    V <- pr$Vg[E, E, drop = FALSE]
    chi2 <- tryCatch(drop(t(g) %*% solve(V, g)), error = function(e) NA_real_)
    df <- length(E)
    p <- stats::pchisq(chi2, df, lower.tail = FALSE)
    ratio <- chi2 / df
    st <- if (!is.finite(chi2) || p > 0.05) "warning"
          else if (ratio < 10) "note" else "ok"
    add("I5", sprintf("strength of exclusions for '%s'", lab), st,
        sprintf("chi2(%d) = %.2f, p = %.3g, chi2/df = %.1f", df, chi2, p, ratio),
        switch(st,
               warning = "excluded variables not jointly significant in the selection equation: weak or irrelevant exclusion restriction",
               note = "significant but weak by the heuristic chi2/df < 10",
               ""))
  }

  ## I6 collinearity of the correction term with x_j; I7 index range
  if (!is.null(pr)) {
    for (r in 1:2) {
      lab <- labs[r]
      sel <- sd$S == r - 1L
      X <- sd$X[[lab]][sel, , drop = FALSE]
      m <- if (r == 2L) se_m1(pr$w[sel]) else se_m0(pr$w[sel])
      f <- stats::lm.fit(X, m)
      r2 <- 1 - sum(f$residuals^2) / sum((m - mean(m))^2)
      kap <- kappa(cbind(X, m), exact = FALSE)
      st <- if (r2 > 0.95) "warning" else "ok"
      add("I6", sprintf("collinearity of the correction term for '%s'", lab), st,
          sprintf("R2 = %.3f, condition number %.3g", r2, kap),
          if (st == "warning") "selection-correction term nearly collinear with the outcome regressors" else "")
    }
    add("I7", "range of the selection index", "note",
        sprintf("sd(z'gamma) = %.2f; %.1f%% with |z'gamma| > 3", stats::sd(pr$w),
                100 * mean(abs(pr$w) > 3)),
        "a narrow index range weakens identification by functional form")
  }

  ## I8, I9 fitted-model checks
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

  ## I10 falsification test among regime-0 units: informational only
  ## (IDENTIFICATION.md s.6, amendment of 22 November 2026). Under selection
  ## on unobservables E[y | S = 0, x, z] = x'beta_0 + sigma_0 rho_0 m_0(z'gamma)
  ## depends on z, so the literal test rejects valid exclusions; conditioning
  ## on m_0 restores the size but removes the power against direct effects.
  ex0 <- excl[[labs[1L]]]
  if (length(ex0) && !is.null(pr)) {
    sel <- sd$S == 0L
    X0 <- sd$X[[1L]][sel, , drop = FALSE]
    Ze <- sd$Z[sel, ex0, drop = FALSE]
    y0 <- sd$y[sel]
    m0 <- se_m0(pr$w[sel])
    ftest <- function(Xr, Xf) {
      full <- stats::lm.fit(Xf, y0)
      restr <- stats::lm.fit(Xr, y0)
      q <- ncol(Xf) - ncol(Xr)
      dfr <- length(y0) - full$rank
      if (full$rank != ncol(Xf) || dfr <= 0) return(NA_real_)
      Fst <- ((sum(restr$residuals^2) - sum(full$residuals^2)) / q) /
        (sum(full$residuals^2) / dfr)
      stats::pf(Fst, q, dfr, lower.tail = FALSE)
    }
    p_lit <- ftest(X0, cbind(X0, Ze))
    p_con <- ftest(cbind(X0, m0), cbind(X0, m0, Ze))
    add("I10", sprintf("falsification test of exclusions ('%s' units)", labs[1L]),
        "note",
        sprintf("literal test p = %.3g; conditional on the correction term p = %.3g",
                p_lit, p_con),
        paste("informational only: under selection on unobservables the literal",
              "test (Di Falco et al. 2011) rejects valid exclusions, and the test",
              "conditional on the selection-correction term has no power against",
              "direct effects; a just-identifying exclusion restriction cannot be",
              "tested with the data"))
  } else {
    add("I10", "falsification test of exclusions", "skipped", "",
        if (!length(ex0)) "no excluded variables" else "probit not estimable")
  }

  ## I11 non-identified parameters
  rng <- ""
  if (!is.null(fit)) {
    rho <- fit$coefficients[unlist(fit$map$index$rho)]
    if (all(is.finite(rho)) && all(abs(rho) < 1)) {
      h <- sqrt((1 - rho[1]^2) * (1 - rho[2]^2))
      rng <- sprintf("admissible range [%.3f, %.3f] at the estimates",
                     rho[1] * rho[2] - h, rho[1] * rho[2] + h)
    }
  }
  add("I11", "parameters not identified", "note",
      paste0("Corr(eps_1, eps_0)", if (nzchar(rng)) paste0(": ", rng) else ""),
      "never observed jointly: does not enter the likelihood and is not estimated")

  tab <- do.call(rbind, rows)
  i5 <- tab[tab$code == "I5", ]
  rho_id <- vapply(labs, function(l) {
    if (!length(excl[[l]])) return("normality (functional form) only")
    s <- i5$status[grepl(sprintf("'%s'", l), i5$check, fixed = TRUE)]
    if (length(s) && s == "warning") "weak exclusion restriction and normality"
    else "exclusion restriction (given normality)"
  }, character(1))
  cls <- data.frame(
    parameters = c("selection coefficients", paste0(labs, ": coefficients and sigma"),
                   paste0(labs, ": rho"), "Corr(eps_1, eps_0)"),
    identified_by = c("probit with Var(u) = 1 (structural)",
                      rep("regime data given rank (structural)", 2), rho_id,
                      "not identified"),
    stringsAsFactors = FALSE)
  structure(list(table = tab, classification = cls, fitted = !is.null(fit),
                 n = n, regimes = labs), class = "switch_validation")
}

#' @rdname switch_validate
#' @export
print.switch_validation <- function(x, ...) {
  cat("Identification checks (SwitchEconometrics)",
      if (isTRUE(x$fitted)) "- fitted model" else "- specification and data",
      "\n")
  t <- x$table
  print(data.frame(code = t$code, status = t$status, check = t$check,
                   value = t$value), row.names = FALSE, right = FALSE)
  msg <- t[t$status %in% c("error", "warning") & nzchar(t$message), ]
  if (nrow(msg)) {
    cat("\nWarnings and errors:\n")
    for (i in seq_len(nrow(msg))) {
      cat(sprintf("  %s (%s): %s\n", msg$code[i], msg$status[i], msg$message[i]))
    }
  }
  if (!is.null(x$classification)) {
    cat("\nHow the parameters are identified:\n")
    print(x$classification, row.names = FALSE, right = FALSE)
  }
  cat("\nNo data test can establish that an exclusion restriction is valid.\n")
  invisible(x)
}
