## Simulation from the binary Gaussian ESR (API_SPECIFICATION.md s.2;
## IDENTIFICATION.md s.3 for the role of Corr(eps1, eps0)).

## Design matrices for a specification (no fit): terms from the formulas.
se_spec_design <- function(spec, data, labels) {
  tt <- function(f) stats::delete.response(stats::terms(f))
  pseudo <- list(terms = list(selection = tt(spec$selection$formula),
                              outcomes = stats::setNames(lapply(labels, function(l)
                                tt(spec$outcomes[[l]]$formula)), labels)),
                 xlevels = list(), contrasts = list(), regimes = labels)
  se_newdata_design(pseudo, data)
}

## One draw of (S, y, y1, y0) given the linear predictors.
se_sim_draw <- function(w, xb0, xb1, s0, s1, L) {
  m <- length(w)
  E <- matrix(stats::rnorm(3L * m), m) %*% L
  S <- as.integer(w + E[, 1L] > 0)
  y1 <- xb1 + s1 * E[, 2L]
  y0 <- xb0 + s0 * E[, 3L]
  list(S = S, y = ifelse(S == 1L, y1, y0), y1 = y1, y0 = y0)
}

## Cholesky factor of Corr(u, eps1, eps0) with an admissibility check of r10.
se_sim_chol <- function(r1, r0, r10) {
  h <- sqrt((1 - r1^2) * (1 - r0^2))
  if (!is.finite(r10) || abs(r10 - r1 * r0) >= h) {
    se_abort(sprintf(paste0(
      "r10 = %g is outside the admissible range (%.4f, %.4f) given rho_1 = %g ",
      "and rho_0 = %g"), r10, r1 * r0 - h, r1 * r0 + h, r1, r0), "domain")
  }
  chol(matrix(c(1, r1, r0, r1, 1, r10, r0, r10, 1), 3L))
}

#' Simulate data from an endogenous switching model
#'
#' Draws the regime and the observed outcome for the covariates in `data`
#' under given parameters: \eqn{S = 1\{z'\gamma + u > 0\}},
#' \eqn{y = x_S'\beta_S + \varepsilon_S}, with \eqn{(u, \varepsilon_1,
#' \varepsilon_0)} jointly normal.
#'
#' The distribution of the observed data does not depend on the correlation
#' `r10` of \eqn{\varepsilon_1} and \eqn{\varepsilon_0}, which is not
#' identified. The joint distribution of both potential outcomes
#' (`potential_outcomes = TRUE`) does: it is simulated under the stated
#' value of `r10`, by default \eqn{\rho_1\rho_0} (no dependence between the
#' outcome disturbances beyond the common selection disturbance). `r10` must
#' lie in the admissible range
#' \eqn{\rho_1\rho_0 \pm \sqrt{(1-\rho_1^2)(1-\rho_0^2)}}.
#'
#' `simulate()` simulates from a fitted model for its estimation sample.
#'
#' @param model A `switch_spec` (then `parameters` is required; the first
#'   outcome equation is regime 0) or a `switch_fit` (default parameters:
#'   the estimates).
#' @param data Data frame with the covariates. The responses are created
#'   or overwritten; they must be plain variable names in the formulas.
#' @param parameters Natural-scale parameters: a named vector or list with
#'   the parameter names of the model (see `coef()` of a fit), or an
#'   unnamed vector in that order.
#' @param nsim Number of simulated data sets.
#' @param seed Seed; the global random-number state is restored afterwards.
#' @param potential_outcomes Add both potential outcomes as columns
#'   `.potential_<regime>`.
#' @param r10 Assumed correlation of the two outcome disturbances (used only
#'   for the potential outcomes).
#' @param object A `switch_fit` (for `simulate()`).
#' @param ... Not used.
#' @return `switch_simulate()`: a data frame (or a list of `nsim` data
#'   frames) with attribute `r10`. `simulate()`: a data frame with columns
#'   `S_1`, `y_1`, ..., `S_nsim`, `y_nsim` for the estimation sample.
#' @examples
#' spec <- switch_model(adopt ~ x1 + z1,
#'                      list(regime_0 = y ~ x1, regime_1 = y ~ x1))
#' cov <- data.frame(x1 = rnorm(200), z1 = rnorm(200))
#' par <- c("selection:(Intercept)" = 0.2, "selection:x1" = 0.5,
#'          "selection:z1" = -0.8,
#'          "regime_0:(Intercept)" = 1, "regime_0:x1" = 0.5,
#'          "regime_0:sigma" = 1, "regime_0:rho" = 0.3,
#'          "regime_1:(Intercept)" = 2, "regime_1:x1" = 0.8,
#'          "regime_1:sigma" = 1.2, "regime_1:rho" = 0.5)
#' sim <- switch_simulate(spec, cov, par, seed = 1)
#' head(sim)
#' @export
switch_simulate <- function(model, data, parameters = NULL, nsim = 1L,
                            seed = NULL, potential_outcomes = FALSE,
                            r10 = NULL) {
  if ((inherits(model, "switch_fit") || inherits(model, "switch_spec")) &&
      se_is_obs(model$model)) {
    if (!is.null(r10)) {
      se_abort("'r10' applies to the switching model only", "argument")
    }
    return(se_simulate_obs(model, data, parameters, nsim, seed,
                           potential_outcomes))
  }
  if (inherits(model, "switch_fit")) {
    spec <- model$spec
    labels <- model$regimes
    des <- se_newdata_design(model, data)
    parameters <- parameters %||% model$coefficients
    rvals <- model$regime_values
  } else if (inherits(model, "switch_spec")) {
    spec <- model
    labels <- spec$regimes
    if (is.null(parameters)) {
      se_abort("'parameters' is required when 'model' is a switch_spec",
               "argument")
    }
    des <- se_spec_design(spec, data, labels)
    rvals <- NULL
  } else {
    se_abort("'model' must be a switch_spec or a switch_fit", "argument")
  }
  if (!any(des$ok)) se_abort("no complete rows in 'data'", "data")
  if (!is.numeric(nsim) || length(nsim) != 1L || nsim < 1) {
    se_abort("'nsim' must be a positive whole number", "argument")
  }
  sel_lhs <- spec$selection$formula[[2L]]
  out_lhs <- lapply(labels, function(l) spec$outcomes[[l]]$formula[[2L]])
  if (!is.name(sel_lhs) || !all(vapply(out_lhs, is.name, logical(1)))) {
    se_abort("simulation needs plain variable names as responses", "argument")
  }
  sel_var <- as.character(sel_lhs)
  yv <- vapply(out_lhs, as.character, character(1))

  map <- se_parmap_esr(list(Z = des$Z, X = des$X, regimes = labels))
  th <- se_par_natural(map, se_par_working(map, parameters))
  g <- function(b, l) th[[map$index[[b]][[l]]]]
  s0 <- g("sigma", labels[1L]); r0 <- g("rho", labels[1L])
  s1 <- g("sigma", labels[2L]); r1 <- g("rho", labels[2L])
  r10 <- r10 %||% (r1 * r0)
  L <- se_sim_chol(r1, r0, r10)
  w <- drop(des$Z %*% th[map$index$gamma])
  xb0 <- drop(des$X[[1L]] %*% th[map$index$beta[[labels[1L]]]])
  xb1 <- drop(des$X[[2L]] %*% th[map$index$beta[[labels[2L]]]])
  ok <- des$ok
  fill <- function(v) { out <- rep(NA, length(ok)); out[ok] <- v; out }
  one <- function() {
    dr <- se_sim_draw(w, xb0, xb1, s0, s1, L)
    out <- data
    sv <- fill(dr$S)
    out[[sel_var]] <- if (!is.null(rvals) && !identical(rvals, c("0", "1"))) {
      if (identical(rvals, c("FALSE", "TRUE"))) as.logical(sv)
      else factor(rvals[sv + 1L], levels = rvals)
    } else sv
    if (yv[1L] == yv[2L]) {
      out[[yv[1L]]] <- fill(dr$y)
    } else {
      out[[yv[1L]]] <- fill(ifelse(dr$S == 0L, dr$y0, NA_real_))
      out[[yv[2L]]] <- fill(ifelse(dr$S == 1L, dr$y1, NA_real_))
    }
    if (potential_outcomes) {
      out[[paste0(".potential_", labels[1L])]] <- fill(dr$y0)
      out[[paste0(".potential_", labels[2L])]] <- fill(dr$y1)
    }
    attr(out, "r10") <- c(r10 = r10)
    out
  }
  sims <- se_with_seed(seed, lapply(seq_len(nsim), function(k) one()))
  if (nsim == 1L) sims[[1L]] else sims
}

#' @rdname switch_simulate
#' @export
simulate.switch_fit <- function(object, nsim = 1, seed = NULL, ...) {
  sd <- object$data
  if (is.null(sd)) se_abort("simulate() needs the data; refit with keep_data = TRUE",
                            "argument")
  if (se_is_obs(object$model)) return(se_simulate_fit_obs(object, nsim, seed))
  map <- object$map
  th <- object$coefficients
  reg <- sd$regimes
  g <- function(b, l) th[[map$index[[b]][[l]]]]
  r0 <- g("rho", reg[1L]); r1 <- g("rho", reg[2L])
  if (abs(r0) >= 1 || abs(r1) >= 1) {
    se_abort("cannot simulate: an estimated rho lies outside (-1, 1)", "domain")
  }
  L <- se_sim_chol(r1, r0, r1 * r0)
  w <- drop(sd$Z %*% th[map$index$gamma])
  xb0 <- drop(sd$X[[1L]] %*% th[map$index$beta[[reg[1L]]]])
  xb1 <- drop(sd$X[[2L]] %*% th[map$index$beta[[reg[2L]]]])
  draws <- se_with_seed(seed, lapply(seq_len(nsim), function(k)
    se_sim_draw(w, xb0, xb1, g("sigma", reg[1L]), g("sigma", reg[2L]), L)))
  out <- do.call(cbind, lapply(seq_len(nsim), function(k)
    stats::setNames(data.frame(draws[[k]]$S, draws[[k]]$y),
                    paste0(c("S_", "y_"), k))))
  attr(out, "seed") <- seed
  out
}
