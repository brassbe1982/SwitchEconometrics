## Layer 6: computational and statistical diagnostics (specification s.5.7
## and s.15).

#' Computational and statistical diagnostics of a fitted switching model
#'
#' Separates computational diagnostics (convergence, gradient, Hessian
#' eigenvalues and condition number, boundary flags, multistart results,
#' optimiser path and time) from statistical diagnostics (likelihood-ratio
#' and Wald tests of independent equations, intervals for the correlations,
#' identification checks and the parameters that are not identified), as
#' required by specification section 15.
#'
#' @param object A `switch_fit`.
#' @param x A `switch_diagnostics` object.
#' @param ... Not used.
#' @return An object of class `switch_diagnostics` with components
#'   `computational` and `statistical`.
#' @examples
#' set.seed(4)
#' n <- 500
#' d <- data.frame(x1 = rnorm(n), z1 = rnorm(n))
#' u <- rnorm(n)
#' d$S <- as.integer(0.2 + 0.5 * d$x1 - 0.7 * d$z1 + u > 0)
#' d$y <- ifelse(d$S == 1, 1 + d$x1 + 0.5 * u + rnorm(n),
#'               0.5 * d$x1 + 0.3 * u + rnorm(n))
#' fit <- switch_fit(S ~ x1 + z1, list(y ~ x1, y ~ x1), data = d)
#' switch_diagnostics(fit)
#' @export
switch_diagnostics <- function(object, ...) {
  if (!inherits(object, "switch_fit")) {
    se_abort("'object' must be a switch_fit", "argument")
  }
  ev <- object$diagnostics$hessian_eigen
  comp <- list(
    method = object$method, convergence = object$convergence,
    hessian_eigen_range = if (length(ev) && all(is.finite(ev))) range(ev),
    hessian_condition = object$diagnostics$hessian_condition,
    flags = object$diagnostics$flags, starts = object$starts,
    multistart_flat = object$diagnostics$multistart_flat,
    local_maxima = object$diagnostics$local_maxima)
  rho_names <- object$map$elements$name[unlist(object$map$index$rho)]
  stat <- list(
    lr = if (object$method == "fiml" && !is.null(object$data))
      tryCatch(suppressWarnings(switch_test(object, "lr_independence")),
               error = function(e) NULL),
    wald = tryCatch(switch_test(object, "wald_independence"),
                    error = function(e) NULL),
    rho = cbind(estimate = object$coefficients[rho_names],
                confint(object, parm = rho_names)),
    identification = object$identification)
  structure(list(computational = comp, statistical = stat),
            class = "switch_diagnostics")
}

#' @rdname switch_diagnostics
#' @export
print.switch_diagnostics <- function(x, ...) {
  c1 <- x$computational
  cv <- c1$convergence
  cat("Computational diagnostics\n")
  cat(sprintf("  method: %s; optimiser: %s (path: %s)\n", c1$method,
              cv$optimizer, paste(cv$path, collapse = " > ")))
  cat(sprintf("  convergence: %s (code %d)", cv$message, as.integer(cv$code)))
  if (c1$method == "fiml") {
    cat(sprintf("; %d iterations; max |gradient| %.2g; gradient norm %.2g; %.2f s\n",
                as.integer(cv$iterations), cv$gradient_max, cv$gradient_norm,
                cv$time))
    if (!is.null(c1$hessian_eigen_range)) {
      cat(sprintf("  Hessian eigenvalues in [%.3g, %.3g]; condition number %.3g\n",
                  c1$hessian_eigen_range[1], c1$hessian_eigen_range[2],
                  c1$hessian_condition))
    }
    st <- c1$starts
    cat(sprintf("  multistart: %d starts, %d converged, %d lower local maxima%s\n",
                nrow(st), sum(st$code == 0L), c1$local_maxima,
                if (isTRUE(c1$multistart_flat)) "; FLAT likelihood" else ""))
  } else cat("\n")
  fl <- c1$flags
  ftxt <- c(
    if (length(fl$rho_boundary)) paste("rho at boundary:", paste(fl$rho_boundary, collapse = ", ")),
    if (length(fl$sigma_boundary)) "degenerate sigma",
    if (isTRUE(fl$ill_conditioned)) "ill-conditioned Hessian",
    if (isTRUE(fl$hessian_not_nd)) "Hessian not negative definite")
  cat(sprintf("  flags: %s\n", if (length(ftxt)) paste(ftxt, collapse = "; ")
              else "none"))
  s <- x$statistical
  cat("\nStatistical diagnostics\n")
  if (!is.null(s$lr)) {
    cat(sprintf("  LR test of independent equations: chi2(2) = %.3f, p = %s\n",
                s$lr$statistic, format.pval(s$lr$p_value, digits = 4)))
  }
  if (!is.null(s$wald)) {
    cat(sprintf("  Wald test of independent equations: chi2(%d) = %.3f, p = %s\n",
                as.integer(s$wald$df), s$wald$statistic,
                format.pval(s$wald$p_value, digits = 4)))
  }
  cat("  Correlations with the selection disturbance:\n")
  print(signif(s$rho, 4))
  if (inherits(s$identification, "switch_validation")) {
    t <- s$identification$table
    w <- t[t$status %in% c("warning", "error"), ]
    cat(sprintf("  identification checks: %d warning(s)/error(s)%s\n", nrow(w),
                if (nrow(w)) paste0(" (", paste(w$code, collapse = ", "), ")") else ""))
    i11 <- t[t$code == "I11", ]
    if (nrow(i11)) cat("  not identified:", i11$value, "\n")
  }
  invisible(x)
}
