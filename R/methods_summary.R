## confint() and summary() for switch_fit (API_SPECIFICATION.md s.4;
## PARAMETERIZATION.md s.3).

#' Confidence intervals and summaries of fitted switching models
#'
#' `confint()` gives Wald confidence intervals. With
#' `type = "transformed-wald"` (default), intervals for \eqn{\sigma_j} and
#' \eqn{\rho_j} are formed on the \eqn{\log\sigma} and
#' \eqn{\operatorname{atanh}\rho} scales and transformed back, so they lie
#' inside the parameter space; `"natural-wald"` gives symmetric intervals on
#' the natural scale. Two-step fits have no closed-form intervals for
#' \eqn{\sigma_j} and \eqn{\rho_j} (`NA`; see [switch_bootstrap()]).
#'
#' `summary()` gives coefficient tables by equation with standard errors,
#' z statistics and p-values; the ancillary parameters with intervals; the
#' likelihood-ratio (FIML) and Wald tests of independent equations;
#' convergence information; and the identification checks.
#'
#' @param object A `switch_fit`.
#' @param parm Parameter names or indices (default: all).
#' @param level Confidence level.
#' @param type Interval type (see Description).
#' @param x A `summary.switch_fit` object.
#' @param digits Significant digits.
#' @param ... Not used.
#' @return `confint()`: matrix with lower and upper limits.
#'   `summary()`: object of class `summary.switch_fit`.
#' @name switch_fit-summary
NULL

#' @rdname switch_fit-summary
#' @export
confint.switch_fit <- function(object, parm, level = 0.95,
                               type = c("transformed-wald", "natural-wald"),
                               ...) {
  type <- match.arg(type)
  est <- object$coefficients
  nm <- names(est)
  idx <- if (missing(parm)) seq_along(est)
         else if (is.character(parm)) match(parm, nm) else parm
  if (anyNA(idx) || any(idx < 1L | idx > length(est))) {
    se_abort("unknown parameter(s) in 'parm'", "argument")
  }
  z <- stats::qnorm(1 - (1 - level) / 2)
  se <- sqrt(pmax(diag(object$vcov), 0))
  lo <- est - z * se
  hi <- est + z * se
  if (type == "transformed-wald" && !is.null(object$coef_working)) {
    tr <- object$map$elements$transform
    sew <- sqrt(pmax(diag(object$vcov_working), 0))
    for (k in which(tr != "identity")) {
      t <- se_transform(tr[k])
      lo[k] <- t$to_natural(object$coef_working[k] - z * sew[k])
      hi[k] <- t$to_natural(object$coef_working[k] + z * sew[k])
    }
  }
  out <- cbind(lo, hi)[idx, , drop = FALSE]
  pct <- paste(format(100 * c((1 - level) / 2, 1 - (1 - level) / 2),
                      trim = TRUE, scientific = FALSE, digits = 3), "%")
  dimnames(out) <- list(nm[idx], pct)
  out
}

#' @rdname switch_fit-summary
#' @export
summary.switch_fit <- function(object, level = 0.95, ...) {
  e <- object$map$elements
  est <- object$coefficients
  se <- sqrt(pmax(diag(object$vcov), 0))
  se[is.na(diag(object$vcov))] <- NA_real_
  zval <- est / se
  tab <- cbind(Estimate = est, `Std. Error` = se, `z value` = zval,
               `Pr(>|z|)` = 2 * stats::pnorm(-abs(zval)))
  ci <- confint(object, level = level)
  eqs <- se_equations(object)
  coef_tables <- lapply(eqs, function(eq) {
    i <- which(e$equation == eq & e$block %in% c("gamma", "beta", "delta"))
    m <- tab[i, , drop = FALSE]
    rownames(m) <- e$term[i]
    m
  })
  names(coef_tables) <- eqs
  eq_titles <- vapply(eqs, function(eq) se_equation_title(object, eq),
                      character(1))
  ia <- which(e$block %in% c("sigma", "rho"))
  anc <- cbind(tab[ia, 1:2, drop = FALSE], ci[ia, , drop = FALSE])

  tests <- list()
  if (object$method == "fiml" && !is.null(object$data)) {
    tests$lr <- tryCatch(suppressWarnings(switch_test(object, "lr_independence")),
                         error = function(e) NULL)
  }
  tests$wald <- tryCatch(switch_test(object, "wald_independence"),
                         error = function(e) NULL)
  lambda <- NULL
  if (object$method == "two_step") {
    ts <- object$two_step
    i <- se_theta_positions(object)
    th <- ts$psi[i]
    s <- sqrt(diag(ts$vcov_psi)[i])
    lambda <- cbind(Estimate = th, `Std. Error` = s, `z value` = th / s,
                    `Pr(>|z|)` = 2 * stats::pnorm(-abs(th / s)))
    rownames(lambda) <- if (se_is_obs(object$model)) "sigma*rho"
                        else if (se_is_multi(object$model)) names(th)
                        else paste0(object$regimes, ": sigma*rho")
  }
  ll <- object$loglik
  structure(list(
    call = object$call, method = object$method, vcov_type = object$vcov_type,
    model = object$model, titles = eq_titles,
    nrho = length(unlist(object$map$index$rho)),
    nobs = object$nobs, n_regime = object$n_regime, regimes = object$regimes,
    loglik = ll, aic = if (is.finite(ll)) -2 * ll + 2 * object$npar else NA,
    bic = if (is.finite(ll)) -2 * ll + log(object$nobs) * object$npar else NA,
    coefficients = coef_tables, ancillary = anc, lambda = lambda, level = level,
    tests = tests, convergence = object$convergence,
    flags = object$diagnostics$flags,
    multistart = if (!is.null(object$starts)) c(
      starts = nrow(object$starts), converged = sum(object$starts$code == 0L),
      local_maxima = object$diagnostics$local_maxima),
    identification = object$identification,
    weights = !is.null(object$weights), clusters = object$data$n_clusters),
    class = "summary.switch_fit")
}

#' @rdname switch_fit-summary
#' @export
print.summary.switch_fit <- function(x, digits = max(3L, getOption("digits") - 3L),
                                     ...) {
  cat(se_model_title(x$model %||% "esr"), " (SwitchEconometrics ",
      se_version(), ")\n\n", sep = "")
  cat("Call:\n", paste(deparse(x$call, width.cutoff = 70L), collapse = "\n"),
      "\n\n", sep = "")
  meth <- if (x$method == "fiml") "full-information maximum likelihood"
          else "two-step (Heckman-Lee)"
  cat(sprintf("Method: %s; covariance: %s%s\n", meth, x$vcov_type,
              if (!is.null(x$clusters)) sprintf(" (%d clusters)", x$clusters)
              else ""))
  cat(sprintf("Observations: %d (%s)\n", x$nobs,
              paste(x$regimes, x$n_regime, sep = ": ", collapse = ", ")))
  if (is.finite(x$loglik)) {
    cat(sprintf("Log-likelihood: %s   AIC: %s   BIC: %s\n",
                format(x$loglik, digits = digits + 3L),
                format(x$aic, digits = digits + 3L),
                format(x$bic, digits = digits + 3L)))
  }
  for (eq in names(x$coefficients)) {
    cat(sprintf("\n%s:\n", x$titles[[eq]] %||%
                  if (eq == "selection") "Selection equation (probit)"
                  else sprintf("Outcome equation, regime '%s'", eq)))
    stats::printCoefmat(x$coefficients[[eq]], digits = digits,
                        signif.legend = FALSE)
  }
  if (nrow(x$ancillary)) {
    cat(sprintf("\nDisturbance parameters (%g%% intervals%s):\n", 100 * x$level,
                if (x$method == "fiml") " on the log(sigma) / atanh(rho) scale"
                else ""))
    print(signif(x$ancillary, digits))
    if (se_is_multi(x$model) && any(grepl("rho\\[", rownames(x$ancillary)))) {
      cat("rho[k] of a regime: correlation of its outcome disturbance with the normal score\n",
          "of the utility disturbance of alternative k (normal-score model).\n",
          sep = "")
    } else if (se_is_multi(x$model)) {
      cat("rho of a regime: correlation of its outcome disturbance with its own selection\n",
          "index (Lee 1983); positive when unobservables favouring the regime raise its outcome.\n",
          sep = "")
    }
  }
  if (!is.null(x$lambda)) {
    cat("\nSelection-correction coefficients (two-step):\n")
    stats::printCoefmat(x$lambda, digits = digits, signif.legend = FALSE)
    cat(if (nrow(x$ancillary))
      "sigma and rho are derived two-step quantities; use switch_bootstrap() for their standard errors.\n"
      else "Moment model: sigma and correlations are not defined; standard errors as stated above.\n")
  }
  cat(if (identical(x$nrho, 1L)) "\nIndependent equations (H0: rho = 0):\n"
      else if (se_is_multi(x$model))
        "\nNo selection on unobservables (H0: all dependence parameters = 0):\n"
      else "\nIndependent equations (H0: rho_1 = rho_0 = 0):\n")
  if (!is.null(x$tests$lr)) {
    cat(sprintf("  LR test:   chi2(%d) = %.3f, p = %s\n",
                as.integer(x$tests$lr$df), x$tests$lr$statistic,
                format.pval(x$tests$lr$p_value, digits = 4)))
  }
  if (!is.null(x$tests$wald)) {
    cat(sprintf("  Wald test: chi2(%d) = %.3f, p = %s\n", as.integer(x$tests$wald$df),
                x$tests$wald$statistic,
                format.pval(x$tests$wald$p_value, digits = 4)))
  }
  cat("  (Failure to reject does not show that regime assignment is exogenous.)\n")
  if (x$method == "fiml") {
    cv <- x$convergence
    cat(sprintf("\nConvergence: %s; max |gradient| %.2g; %s; %d iterations",
                cv$message, cv$gradient_max, cv$optimizer,
                as.integer(cv$iterations)))
    if (!is.null(x$multistart)) {
      cat(sprintf("; starts %d (converged %d, local maxima %d)",
                  x$multistart[["starts"]], x$multistart[["converged"]],
                  x$multistart[["local_maxima"]]))
    }
    cat("\n")
  }
  fl <- x$flags
  if (length(fl$rho_boundary) || isTRUE(fl$ill_conditioned) ||
      isTRUE(fl$hessian_not_nd)) {
    cat("Warning flags:",
        paste(c(if (length(fl$rho_boundary)) "rho at boundary",
                if (isTRUE(fl$ill_conditioned)) "ill-conditioned Hessian",
                if (isTRUE(fl$hessian_not_nd)) "Hessian not negative definite"),
              collapse = "; "), "\n")
  }
  idn <- x$identification
  if (inherits(idn, "switch_validation")) {
    w <- idn$table[idn$table$status %in% c("warning", "error"), , drop = FALSE]
    cat(sprintf("Identification checks: %d warning(s)%s\n", nrow(w),
                if (nrow(w)) paste0(": ", paste(w$code, collapse = ", "),
                                    " (see switch_validate())") else ""))
  }
  if (x$weights) cat("Sampling weights were used (pseudo-likelihood).\n")
  invisible(x)
}
