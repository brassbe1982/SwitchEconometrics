## Layer 2: the distribution (margin) interface.
## Specification section 5.3; SOFTWARE_ARCHITECTURE.md s.3.
##
## An se_margin object describes a distribution family. Its functions take
## natural parameter values in a named list `par` (elements recycled):
##   d(x, par), p(q, par, lower.tail), q(p, par), r(n, par),
##   logd(x, par), logp(q, par, lower.tail),
##   grad_logd(x, par), grad_logp(q, par, lower.tail):
##     matrices of derivatives with respect to the WORKING parameters
##     (one column per parameter, named by the working name).
## `parameters` is a data frame with columns name, transform, default,
## description; the transformation maps working to natural values.

new_se_margin <- function(name, type, parameters, d, p, q, r, logd, logp,
                          grad_logd, grad_logp, support = c(-Inf, Inf),
                          generation = 1L) {
  m <- structure(list(name = name, type = type, parameters = parameters,
                      d = d, p = p, q = q, r = r, logd = logd, logp = logp,
                      grad_logd = grad_logd, grad_logp = grad_logp,
                      support = support, generation = generation),
                 class = "se_margin")
  validate_se_margin(m)
}

validate_se_margin <- function(m) {
  fns <- c("d", "p", "q", "r", "logd", "logp", "grad_logd", "grad_logp")
  ok <- vapply(fns, function(f) is.function(m[[f]]), logical(1))
  if (!all(ok)) {
    se_abort(sprintf("margin '%s' lacks function(s): %s", m$name,
                     paste(fns[!ok], collapse = ", ")), "internal")
  }
  if (!is.data.frame(m$parameters) ||
      !all(c("name", "transform", "default") %in% names(m$parameters))) {
    se_abort("margin parameters must be a data frame with name, transform, default",
             "internal")
  }
  m
}

## Margin family by name.
se_margin_get <- function(name) {
  se_check_choice("distribution", name)
  switch(name, gaussian = se_margin_gaussian())
}

## Complete and validate natural parameter values for a margin.
se_margin_par <- function(m, parameters) {
  if (!is.list(parameters)) parameters <- as.list(parameters)
  pn <- m$parameters$name
  if (length(parameters) && (is.null(names(parameters)) ||
                             !all(nzchar(names(parameters))))) {
    se_abort("'parameters' must be a named list", "argument")
  }
  extra <- setdiff(names(parameters), pn)
  if (length(extra)) {
    se_abort(sprintf("unknown parameter(s) %s for distribution '%s'; valid: %s",
                     paste(extra, collapse = ", "), m$name,
                     paste(pn, collapse = ", ")), "argument")
  }
  par <- stats::setNames(as.list(m$parameters$default), pn)
  par[names(parameters)] <- parameters
  for (k in seq_along(pn)) {
    v <- par[[k]]
    if (!is.numeric(v) || !length(v) || anyNA(v)) {
      se_abort(sprintf("parameter '%s' must be numeric without missing values",
                       pn[k]), "argument")
    }
    se_transform(m$parameters$transform[k])$to_working(v)  # domain check
  }
  par
}

#' Probability distributions of the distribution engine
#'
#' Creates a distribution from the distribution engine of SwitchEconometrics
#' (specification section 5.3), with its density, distribution function,
#' quantile function, random generation and their logarithms bound to the
#' given parameter values. The engine supplies the margins of the switching
#' models; this function makes them available directly.
#'
#' @param name Name of the distribution family. Version 0.2.0 provides
#'   `"gaussian"` (parameters `location` and `scale`). Families of later
#'   generations (for example `"student_t"`, Generation 3) give an error
#'   naming the generation that adds them.
#' @param parameters Named list of natural parameter values. Missing
#'   parameters take their defaults (Gaussian: `location = 0`, `scale = 1`).
#'   Values are checked against the parameter domain (for example
#'   `scale > 0`).
#' @return An object of class `se_distribution`: a list with elements
#'   `name`, `parameters`, `margin` (the family) and the functions
#'   `pdf(x)`, `cdf(q, lower.tail = TRUE)`, `quantile(p)`, `rng(n)`,
#'   `logpdf(x)` and `logcdf(q, lower.tail = TRUE)`.
#' @section Lifecycle: Experimental; the interface may still change before
#'   version 1.0.0.
#' @examples
#' g <- distribution("gaussian", list(location = 1, scale = 2))
#' g
#' g$pdf(c(0, 1, 2))
#' g$cdf(1)
#' g$logcdf(-30)          # accurate far in the tail
#' g$quantile(0.975)
#' @export
distribution <- function(name, parameters = list()) {
  m <- se_margin_get(name)
  par <- se_margin_par(m, parameters)
  structure(list(
    name = name, parameters = par, margin = m,
    pdf = function(x) m$d(x, par),
    cdf = function(q, lower.tail = TRUE) m$p(q, par, lower.tail),
    quantile = function(p) m$q(p, par),
    rng = function(n) m$r(n, par),
    logpdf = function(x) m$logd(x, par),
    logcdf = function(q, lower.tail = TRUE) m$logp(q, par, lower.tail)),
    class = "se_distribution")
}

#' @export
print.se_distribution <- function(x, ...) {
  pv <- vapply(x$parameters, function(v)
    paste(format(v, digits = 6), collapse = ", "), character(1))
  cat(sprintf("Distribution '%s' (%s): %s\n", x$name, x$margin$type,
              paste(names(pv), pv, sep = " = ", collapse = "; ")))
  invisible(x)
}
