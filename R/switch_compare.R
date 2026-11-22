#' Compare fitted switching models
#'
#' Tabulates log-likelihood, number of parameters, AIC, BIC, the correlations
#' and the treatment effects of several fits, and gives likelihood-ratio
#' tests for nested FIML fits on the same estimation sample. Fits are
#' treated as nested when the parameter names of the smaller model are a
#' subset of those of the larger model. `anova()` gives the sequential
#' likelihood-ratio tests between fits in the order given.
#'
#' @param ... `switch_fit` objects (named arguments give the model names).
#' @param test `"lr"` for likelihood-ratio tests of nested pairs, or
#'   `"none"`.
#' @param object A `switch_fit` (for `anova()`).
#' @param x A `switch_comparison` object.
#' @param digits Significant digits printed.
#' @return `switch_compare()`: an object of class `switch_comparison` with
#'   `table` and `tests`. `anova()`: an `anova` data frame.
#' @examples
#' f1 <- switch_fit(
#'   digital_adoption ~ internet_access + management_quality + firm_size +
#'     owner_education,
#'   list(productivity ~ firm_size + capital + labour,
#'        productivity ~ firm_size + capital + labour), data = firms)
#' f0 <- switch_fit(
#'   digital_adoption ~ internet_access + management_quality + firm_size +
#'     owner_education,
#'   list(productivity ~ firm_size + capital, productivity ~ firm_size + capital),
#'   data = firms)
#' switch_compare(restricted = f0, full = f1)
#' anova(f0, f1)
#' @export
switch_compare <- function(..., test = c("lr", "none")) {
  test <- match.arg(test)
  fits <- list(...)
  nm <- names(fits)
  dn <- vapply(as.list(substitute(list(...)))[-1L], function(e)
    paste(deparse(e, width.cutoff = 60L), collapse = ""), character(1))
  if (is.null(nm)) nm <- dn else nm[!nzchar(nm)] <- dn[!nzchar(nm)]
  if (length(fits) < 1L || !all(vapply(fits, inherits, logical(1), "switch_fit"))) {
    se_abort("give one or more switch_fit objects", "argument")
  }
  rows <- lapply(seq_along(fits), function(k) {
    f <- fits[[k]]
    rho <- f$coefficients[unlist(f$map$index$rho)]
    eff <- if (!is.null(f$data)) tryCatch(
      switch_effects(f, effects = c("ATT", "ATU", "ATE"), se = "none")$table,
      error = function(e) NULL)
    ev <- function(e) if (is.null(eff)) NA_real_ else eff$estimate[eff$effect == e]
    ll <- f$loglik
    data.frame(model = nm[k], method = f$method, nobs = f$nobs, npar = f$npar,
               loglik = ll,
               AIC = if (is.finite(ll)) -2 * ll + 2 * f$npar else NA_real_,
               BIC = if (is.finite(ll)) -2 * ll + log(f$nobs) * f$npar else NA_real_,
               rho_0 = unname(rho[1L]), rho_1 = unname(rho[2L]),
               ATT = ev("ATT"), ATU = ev("ATU"), ATE = ev("ATE"),
               converged = f$convergence$code == 0L, stringsAsFactors = FALSE)
  })
  tab <- do.call(rbind, rows)
  tests <- NULL
  if (test == "lr" && length(fits) > 1L) {
    tr <- list()
    for (i in seq_along(fits)) for (j in seq_along(fits)) {
      if (i >= j) next
      r <- se_lr_nested(fits[[i]], fits[[j]], nm[i], nm[j])
      if (!is.null(r)) tr[[length(tr) + 1L]] <- r
    }
    if (length(tr)) tests <- do.call(rbind, tr)
  }
  structure(list(table = tab, tests = tests), class = "switch_comparison")
}

## LR test of two fits if they are nested FIML fits on the same sample.
se_lr_nested <- function(a, b, na, nb) {
  if (a$method != "fiml" || b$method != "fiml") return(NULL)
  if (a$nobs != b$nobs ||
      !identical(a$record$sample_index, b$record$sample_index)) return(NULL)
  if (!is.null(a$data) && !is.null(b$data) &&
      (!identical(a$data$y, b$data$y) || !identical(a$data$S, b$data$S))) {
    return(NULL)
  }
  a_small <- a$npar <= b$npar
  small <- if (a_small) a else b
  big <- if (a_small) b else a
  if (small$npar == big$npar ||
      !all(names(small$coefficients) %in% names(big$coefficients))) return(NULL)
  stat <- max(0, 2 * (big$loglik - small$loglik))
  df <- big$npar - small$npar
  data.frame(restricted = if (a_small) na else nb,
             unrestricted = if (a_small) nb else na,
             LR = stat, df = df,
             p_value = stats::pchisq(stat, df, lower.tail = FALSE),
             stringsAsFactors = FALSE)
}

#' @rdname switch_compare
#' @export
print.switch_comparison <- function(x, digits = 4L, ...) {
  tb <- x$table
  num <- vapply(tb, is.double, logical(1))
  tb[num] <- lapply(tb[num], signif, digits = digits)
  print(tb, row.names = FALSE)
  if (!is.null(x$tests)) {
    cat("\nLikelihood-ratio tests of nested FIML fits:\n")
    tt <- x$tests
    tt$LR <- signif(tt$LR, digits)
    tt$p_value <- format.pval(tt$p_value, digits = digits)
    print(tt, row.names = FALSE)
  }
  invisible(x)
}

#' @rdname switch_compare
#' @export
anova.switch_fit <- function(object, ...) {
  fits <- c(list(object), list(...))
  if (length(fits) < 2L) {
    se_abort(paste0("anova() needs at least two nested fits; for the test of ",
                    "independent equations use switch_test()"), "argument")
  }
  nm <- paste("Model", seq_along(fits))
  out <- data.frame(npar = vapply(fits, `[[`, integer(1), "npar"),
                    logLik = vapply(fits, `[[`, numeric(1), "loglik"),
                    Df = NA_integer_, Chisq = NA_real_, `Pr(>Chisq)` = NA_real_,
                    check.names = FALSE, row.names = nm)
  for (k in 2:length(fits)) {
    r <- se_lr_nested(fits[[k - 1L]], fits[[k]], nm[k - 1L], nm[k])
    if (is.null(r)) {
      se_abort(sprintf("%s and %s are not nested FIML fits on the same sample",
                       nm[k - 1L], nm[k]), "argument")
    }
    out$Df[k] <- r$df
    out$Chisq[k] <- r$LR
    out$`Pr(>Chisq)`[k] <- r$p_value
  }
  structure(out, heading = c("Likelihood-ratio tests of switching models\n",
                             paste0(nm, ": ", vapply(fits, function(f)
                               paste(deparse(f$call, width.cutoff = 500L),
                                     collapse = ""), character(1)), "\n")),
            class = c("anova", "data.frame"))
}
