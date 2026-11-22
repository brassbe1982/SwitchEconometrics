#' Numerical controls for switch_fit()
#'
#' Settings of the FIML optimisation: multistart, optimiser, convergence
#' tolerance and boundary detection (NUMERICAL_METHODS.md section 3 and
#' PARAMETERIZATION.md sections 4-5 of the package's architecture documents).
#'
#' @param starts Number of starting values. The first is the two-step
#'   estimate (with \eqn{\rho} truncated to \eqn{[-0.95, 0.95]}); further
#'   starts perturb it. With `starts >= 10` the first nine extra starts are a
#'   grid of \eqn{\operatorname{atanh}\rho \in \{-1, 0, 1\}^2}.
#' @param maxit Iteration limit of each optimiser run.
#' @param gradient_tolerance Convergence requires the largest absolute
#'   gradient component (working scale) to be below this value and the
#'   Hessian to be negative definite.
#' @param reltol Relative tolerance of the log-likelihood, kept for the
#'   reproducibility record and used by later optimisers.
#' @param optimizer Primary optimiser: `"NR"` (Newton-Raphson with the
#'   analytic Hessian, default), `"BFGS"`, `"BHHH"` or `"optim"`. The others
#'   are fallbacks, each followed by a Newton-Raphson polish.
#' @param start Optional starting values on the natural scale (a named
#'   vector or list with all parameter names, or an unnamed vector in
#'   parameter order). Used as the first start, before the two-step start.
#' @param perturb_sd Scale of the random perturbations: multiples of the
#'   two-step standard errors for coefficients, and absolute values on the
#'   \eqn{\log\sigma} and \eqn{\operatorname{atanh}\rho} scales.
#' @param seed Seed of the perturbations. The global random-number state is
#'   restored afterwards.
#' @param boundary_rho Estimates with \eqn{|\hat\rho| >} `boundary_rho` are
#'   flagged as boundary solutions.
#' @param hessian_condition Hessian condition numbers above this value are
#'   flagged as ill-conditioned.
#' @param keep_data Keep the estimation data in the fitted object (needed
#'   later by `predict()` without new data, the bootstrap and `update()`).
#' @param trace Reserved for progress output (0 = silent).
#' @return A list of class `switch_control`.
#' @examples
#' switch_control(starts = 5, gradient_tolerance = 1e-8)
#' @export
switch_control <- function(starts = 3L, maxit = 500L,
                           gradient_tolerance = 1e-6, reltol = 1e-10,
                           optimizer = c("NR", "BFGS", "BHHH", "optim"),
                           start = NULL, perturb_sd = 0.5, seed = 20261122L,
                           boundary_rho = 0.995, hessian_condition = 1e10,
                           keep_data = TRUE, trace = 0L) {
  optimizer <- match.arg(optimizer)
  pos_int <- function(x, nm) {
    if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < 1 ||
        x != round(x)) {
      se_abort(sprintf("'%s' must be a positive whole number", nm), "argument")
    }
    as.integer(x)
  }
  pos_num <- function(x, nm, upper = Inf) {
    if (!is.numeric(x) || length(x) != 1L || is.na(x) || x <= 0 || x > upper) {
      se_abort(sprintf("'%s' must be a positive number%s", nm,
                       if (is.finite(upper)) sprintf(" not above %g", upper)
                       else ""), "argument")
    }
    as.numeric(x)
  }
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L ||
                         is.na(seed))) {
    se_abort("'seed' must be NULL or a single number", "argument")
  }
  if (!is.logical(keep_data) || length(keep_data) != 1L || is.na(keep_data)) {
    se_abort("'keep_data' must be TRUE or FALSE", "argument")
  }
  structure(list(
    starts = pos_int(starts, "starts"), maxit = pos_int(maxit, "maxit"),
    gradient_tolerance = pos_num(gradient_tolerance, "gradient_tolerance"),
    reltol = pos_num(reltol, "reltol"), optimizer = optimizer, start = start,
    perturb_sd = pos_num(perturb_sd, "perturb_sd"), seed = seed,
    boundary_rho = pos_num(boundary_rho, "boundary_rho", 1),
    hessian_condition = pos_num(hessian_condition, "hessian_condition"),
    keep_data = keep_data, trace = as.integer(trace)),
    class = "switch_control")
}
