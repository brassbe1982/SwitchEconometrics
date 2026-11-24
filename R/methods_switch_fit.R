## Basic S3 methods for switch_fit (API_SPECIFICATION.md s.4). summary(),
## predict(), fitted(), confint() and the other methods follow in 0.5.0-0.6.0.

#' Methods for fitted switching models
#'
#' Accessors for objects returned by [switch_fit()].
#'
#' @param object,x A `switch_fit` object.
#' @param type `"natural"` (default) for \eqn{\gamma, \beta, \sigma, \rho};
#'   `"working"` for the optimisation scale (\eqn{\log\sigma},
#'   \eqn{\operatorname{atanh}\rho}; FIML only).
#' @param part `"all"`, `"selection"`, a regime label, or `"ancillary"`
#'   (\eqn{\sigma} and \eqn{\rho}).
#' @param digits Number of significant digits printed.
#' @param ... Not used.
#' @return `coef()`: named vector; `vcov()`: matrix; `logLik()`: object of
#'   class `logLik` (`NA` for two-step fits, which do not maximise a
#'   likelihood); `nobs()`: number of observations used.
#' @name switch_fit-methods
NULL

se_part_index <- function(object, part) {
  e <- object$map$elements
  if (identical(part, "all")) return(seq_len(nrow(e)))
  if (identical(part, "ancillary")) return(which(e$block %in% c("sigma", "rho")))
  if (identical(part, "selection")) return(which(e$block == "gamma"))
  eqs <- setdiff(se_equations(object), "selection")
  if (part %in% eqs) {
    return(which(e$equation == part))
  }
  se_abort(sprintf("unknown part '%s'; use \"all\", \"selection\", \"ancillary\" or %s (%s)",
                   part, if (se_is_obs(object$model)) "an equation"
                   else "a regime label", paste(eqs, collapse = ", ")),
           "argument")
}

#' @rdname switch_fit-methods
#' @export
coef.switch_fit <- function(object, type = c("natural", "working"),
                            part = "all", ...) {
  type <- match.arg(type)
  i <- se_part_index(object, part)
  if (type == "working") {
    if (is.null(object$coef_working)) {
      se_abort("working-scale coefficients exist for FIML fits only", "argument")
    }
    return(object$coef_working[i])
  }
  object$coefficients[i]
}

#' @rdname switch_fit-methods
#' @export
vcov.switch_fit <- function(object, type = c("natural", "working"),
                            part = "all", ...) {
  type <- match.arg(type)
  i <- se_part_index(object, part)
  if (type == "working") {
    if (is.null(object$vcov_working)) {
      se_abort("a working-scale covariance exists for FIML fits only",
               "argument")
    }
    return(object$vcov_working[i, i, drop = FALSE])
  }
  object$vcov[i, i, drop = FALSE]
}

#' @rdname switch_fit-methods
#' @export
logLik.switch_fit <- function(object, ...) {
  structure(object$loglik, df = object$npar, nobs = object$nobs,
            class = "logLik")
}

#' @rdname switch_fit-methods
#' @export
nobs.switch_fit <- function(object, ...) object$nobs

#' @rdname switch_fit-methods
#' @export
print.switch_fit <- function(x, digits = max(3L, getOption("digits") - 3L),
                             ...) {
  meth <- if (x$method == "fiml") {
    sprintf("FIML (%s; %d start%s)", x$convergence$optimizer,
            nrow(x$starts), if (nrow(x$starts) == 1L) "" else "s")
  } else "two-step (Heckman-Lee)"
  cat(sprintf("%s (SwitchEconometrics %s)\n", se_model_title(x$model),
              se_version()))
  cat(sprintf("Method: %s; covariance: %s\n", meth, x$vcov_type))
  cat(sprintf("Observations: %d (%s)\n", x$nobs,
              paste(x$regimes, x$n_regime, sep = ": ", collapse = ", ")))
  if (x$method == "fiml") {
    cat(sprintf("Log-likelihood: %s\n", format(x$loglik, digits = digits + 3L)))
  }
  e <- x$map$elements
  for (eq in se_equations(x)) {
    i <- which(e$equation == eq)
    cat(sprintf("\n%s:\n", if (eq == "selection") "Selection equation"
                else se_equation_title(x, eq)))
    v <- x$coefficients[i]
    names(v) <- e$term[i]
    print(v, digits = digits)
  }
  conv <- x$convergence
  if (x$method == "fiml") {
    cat(sprintf("\nConvergence: %s (max |gradient| %.2g)\n", conv$message,
                conv$gradient_max))
  } else if (!identical(x$map$kind, "moments")) {
    cat("\nsigma and rho are derived two-step quantities (no closed-form standard errors).\n")
  }
  invisible(x)
}
