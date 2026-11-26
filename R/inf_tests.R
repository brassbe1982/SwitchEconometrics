## Layer 6: hypothesis tests (LIKELIHOOD_DERIVATION.md s.8).

#' Tests of selection on unobservables and linear hypotheses
#'
#' Likelihood-ratio and Wald tests of \eqn{H_0: \rho_1 = \rho_0 = 0} (no
#' selection on unobservables under the maintained model), and Wald tests of
#' general linear hypotheses on the natural parameters.
#'
#' * `"lr_independence"` (FIML fits): \eqn{LR = 2(\hat\ell - \ell_R)} with
#'   \eqn{\ell_R} the maximised log-likelihood with both correlations fixed
#'   at 0 (a probit plus two Gaussian regressions), \eqn{\chi^2_2}. With
#'   sampling weights the log-likelihood is a pseudo-likelihood and the
#'   statistic is not \eqn{\chi^2}-distributed; a warning says so.
#' * `"wald_independence"`: Wald test of \eqn{\rho_1 = \rho_0 = 0} with the
#'   fit's covariance (natural scale). For two-step fits the equivalent
#'   hypothesis \eqn{\sigma_1\rho_1 = \sigma_0\rho_0 = 0} on the coefficients
#'   of the selection-correction terms is tested.
#' * `"wald"`: general linear hypothesis given by `hypothesis`, either a
#'   character vector of equations in parameter names, e.g.
#'   `c("regime_1:x1 = regime_0:x1", "regime_1:rho = 0")`, or a list with a
#'   matrix `R` and vector `r` for \eqn{R\theta = r}.
#'
#' Failure to reject independence does not show that regime assignment is
#' exogenous: the test is conditional on the maintained model and its
#' identifying assumptions.
#'
#' @param object A `switch_fit`.
#' @param type Type of test (see Details).
#' @param hypothesis For `type = "wald"`: the hypothesis.
#' @param ... Not used.
#' @return An object of class `switch_test` with elements `statistic`, `df`,
#'   `p_value`, `hypothesis`, `type` and `note`.
#' @examples
#' set.seed(1)
#' n <- 800
#' d <- data.frame(x1 = rnorm(n), x2 = rnorm(n), z1 = rnorm(n))
#' u <- rnorm(n)
#' d$S <- as.integer(0.5 + 0.3 * d$x1 - 0.4 * d$z1 + u > 0)
#' d$y <- ifelse(d$S == 1, 1.5 + 0.8 * d$x1 + 0.6 * u + 0.8 * rnorm(n),
#'               1.0 + 0.5 * d$x1 + 0.4 * u + 0.9 * rnorm(n))
#' fit <- switch_fit(S ~ x1 + z1, list(y ~ x1 + x2, y ~ x1 + x2), data = d)
#' switch_test(fit)
#' switch_test(fit, "wald", hypothesis = "regime_1:x1 = regime_0:x1")
#' @export
switch_test <- function(object, type = c("lr_independence",
                                         "wald_independence", "wald"),
                        hypothesis = NULL, ...) {
  if (!inherits(object, "switch_fit")) {
    se_abort("'object' must be a switch_fit", "argument")
  }
  type <- match.arg(type)
  switch(type,
    lr_independence = se_test_lr_independence(object),
    wald_independence = se_test_wald_independence(object),
    wald = {
      if (is.null(hypothesis)) se_abort("type = \"wald\" needs 'hypothesis'",
                                        "argument")
      h <- se_parse_hypothesis(hypothesis, names(object$coefficients))
      txt <- if (is.list(hypothesis)) {
        sprintf("R theta = r (%d restriction%s, natural scale)", nrow(h$R),
                if (nrow(h$R) == 1L) "" else "s")
      } else sprintf("%s (natural scale)", paste(h$labels, collapse = "; "))
      se_wald(object$coefficients, object$vcov, h$R, h$r, h$labels, "wald",
              txt, list_labels = FALSE)
    })
}

se_test_object <- function(type, statistic, df, hypothesis, note, extra = list()) {
  structure(c(list(type = type, statistic = statistic, df = df,
                   p_value = stats::pchisq(statistic, df, lower.tail = FALSE),
                   hypothesis = hypothesis, note = note), extra),
            class = "switch_test")
}

## Restricted FIML fit with the correlations fixed at 0.
se_fit_restricted_rho0 <- function(object) {
  sd <- object$data
  if (is.null(sd)) {
    se_abort("the likelihood-ratio test needs the data; refit with switch_control(keep_data = TRUE)",
             "argument")
  }
  rho_names <- object$map$elements$name[unlist(object$map$index$rho)]
  map_r <- se_par_fix(object$map, stats::setNames(rep(0, length(rho_names)),
                                                   rho_names))
  start <- est_naive_start(sd, map_r)
  ctl <- object$record$control
  ctl$starts <- 1L
  est_fiml(sd, map_r, list(list(theta = start, origin = "restricted")),
           rep(NA_real_, map_r$p), ctl, "hessian")
}

se_test_lr_independence <- function(object) {
  if (object$method != "fiml") {
    se_abort("the likelihood-ratio test needs a FIML fit; use type = \"wald_independence\"",
             "argument")
  }
  r <- se_fit_restricted_rho0(object)
  if (r$convergence$code != 0L) {
    se_warn("the restricted (rho = 0) fit did not converge", "test")
  }
  stat <- max(0, 2 * (object$loglik - r$loglik))
  note <- "Failure to reject does not show that regime assignment is exogenous."
  if (!is.null(object$weights)) {
    se_warn("with sampling weights the LR statistic is not chi-squared; use type = \"wald_independence\" with a sandwich covariance",
            "test")
    note <- paste(note, "Weighted pseudo-likelihood: LR not chi-squared.")
  }
  se_test_object("lr_independence", stat, 2L,
                 "rho_1 = rho_0 = 0 (LR, restricted model: probit + two regressions)",
                 note, list(loglik = object$loglik, loglik_restricted = r$loglik))
}

se_test_wald_independence <- function(object) {
  if (object$method == "fiml") {
    i <- unlist(object$map$index$rho)
    th <- object$coefficients[i]
    V <- object$vcov[i, i, drop = FALSE]
    hyp <- "rho_1 = rho_0 = 0 (Wald, natural scale)"
  } else {
    ts <- object$two_step
    i <- unlist(lapply(object$regimes, function(l) ts$index_psi[[l]][
      length(ts$index_psi[[l]])]))
    th <- ts$psi[i]
    V <- ts$vcov_psi[i, i, drop = FALSE]
    hyp <- "sigma_1 rho_1 = sigma_0 rho_0 = 0 (Wald on the selection-correction coefficients)"
  }
  R <- diag(length(th))
  se_wald(th, V, R, rep(0, length(th)), names(th), "wald_independence", hyp,
          note = "Failure to reject does not show that regime assignment is exogenous.")
}

se_wald <- function(theta, V, R, r, labels, type, hypothesis, note = NULL,
                    list_labels = TRUE) {
  R <- matrix(R, ncol = length(theta))
  d <- drop(R %*% theta) - r
  M <- R %*% V %*% t(R)
  if (anyNA(M)) {
    se_abort(paste0("the covariance of the tested parameters is not available ",
                    "(two-step sigma and rho have no closed-form standard errors; ",
                    "use switch_bootstrap())"), "argument")
  }
  stat <- tryCatch(drop(t(d) %*% solve(M, d)), error = function(e)
    se_abort("the hypothesis covariance matrix is singular", "argument"))
  se_test_object(type, stat, nrow(R),
                 if (length(labels) && list_labels)
                   paste(c(hypothesis, labels), collapse = "\n  ")
                 else hypothesis, note,
                 list(estimate = stats::setNames(d + r, labels), R = R, r = r))
}

## Parse linear hypotheses written in parameter names. Each equation
## "lhs = rhs" becomes one row of R theta = r. Parameter names are replaced
## (longest first) by placeholders; the resulting expression must be linear.
se_parse_hypothesis <- function(hypothesis, names) {
  p <- length(names)
  if (is.list(hypothesis) && !is.null(hypothesis$R)) {
    R <- as.matrix(hypothesis$R)
    if (ncol(R) != p) {
      se_abort(sprintf("'R' must have %d columns", p), "argument")
    }
    r <- hypothesis$r %||% rep(0, nrow(R))
    if (length(r) != nrow(R)) se_abort("'r' must have one value per row of 'R'",
                                       "argument")
    return(list(R = R, r = r, labels = paste0("row ", seq_len(nrow(R)))))
  }
  if (!is.character(hypothesis) || !length(hypothesis)) {
    se_abort("'hypothesis' must be a character vector or list(R = , r = )",
             "argument")
  }
  ord <- order(nchar(names), decreasing = TRUE)
  rows <- lapply(hypothesis, function(h) {
    parts <- strsplit(h, "=", fixed = TRUE)[[1L]]
    if (length(parts) != 2L) {
      se_abort(sprintf("hypothesis '%s' must contain exactly one '='", h),
               "argument")
    }
    txt <- sprintf("(%s) - (%s)", parts[1L], parts[2L])
    used <- FALSE
    for (k in ord) {
      if (grepl(names[k], txt, fixed = TRUE)) {
        used <- TRUE
        txt <- gsub(names[k], sprintf(" .p[%d] ", k), txt, fixed = TRUE)
      }
    }
    if (!used) {
      se_abort(sprintf("hypothesis '%s' names no parameter; parameters are e.g. %s",
                       h, paste(utils_head(names, 3), collapse = ", ")),
               "argument")
    }
    ex <- tryCatch(parse(text = txt)[[1L]], error = function(e)
      se_abort(sprintf("cannot parse hypothesis '%s'", h), "argument"))
    f <- function(v) {
      out <- tryCatch(eval(ex, list(.p = v), baseenv()), error = function(e) NA)
      if (!is.numeric(out) || length(out) != 1L) NA_real_ else out
    }
    f0 <- f(numeric(p))
    Rrow <- vapply(seq_len(p), function(k) {
      e <- numeric(p); e[k] <- 1; f(e) - f0 }, numeric(1))
    z <- seq(0.3, 1.7, length.out = p)
    if (anyNA(c(f0, Rrow)) ||
        abs(f(z) - (f0 + sum(Rrow * z))) > 1e-8 * (1 + abs(f(z)))) {
      se_abort(sprintf("hypothesis '%s' is not linear in the parameters", h),
               "argument")
    }
    list(R = Rrow, r = -f0)
  })
  R <- do.call(rbind, lapply(rows, `[[`, "R"))
  if (qr(R)$rank < nrow(R)) {
    se_abort("the hypotheses are linearly dependent", "argument")
  }
  list(R = R, r = vapply(rows, `[[`, numeric(1), "r"), labels = hypothesis)
}

#' @export
print.switch_test <- function(x, digits = 4L, ...) {
  title <- switch(x$type, lr_independence = "Likelihood-ratio test",
                  wald_independence = "Wald test",
                  wald = "Wald test of linear restrictions")
  cat(title, "\n  H0: ", x$hypothesis, "\n", sep = "")
  cat(sprintf("  statistic = %s, df = %d, p-value = %s\n",
              format(x$statistic, digits = digits), as.integer(x$df),
              format.pval(x$p_value, digits = digits)))
  if (!is.null(x$note)) cat("  Note:", x$note, "\n")
  invisible(x)
}
