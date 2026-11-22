## User-facing estimation function (API_SPECIFICATION.md s.2-3).

#' Estimate an endogenous switching model
#'
#' Estimates the classical binary endogenous switching regression by
#' full-information maximum likelihood (`method = "fiml"`, default) or by the
#' two-step (Heckman-Lee) estimator (`method = "two_step"`).
#'
#' **Model.** \eqn{S = 1\{z'\gamma + u > 0\}};
#' \eqn{y = x_1'\beta_1 + \varepsilon_1} if \eqn{S = 1} and
#' \eqn{y = x_0'\beta_0 + \varepsilon_0} if \eqn{S = 0};
#' \eqn{(u, \varepsilon_j)} bivariate normal with \eqn{\mathrm{Var}(u) = 1},
#' \eqn{\mathrm{sd}(\varepsilon_j) = \sigma_j} and
#' \eqn{\mathrm{Corr}(u, \varepsilon_j) = \rho_j}. The correlation of
#' \eqn{\varepsilon_1} and \eqn{\varepsilon_0} is not identified and is not
#' estimated.
#'
#' **FIML** maximises the exact log-likelihood with its analytic gradient and
#' Hessian, by Newton-Raphson from the two-step estimate and further
#' perturbed starts (`control`). Fallback optimisers are used if a run fails.
#' The fit reports whether it converged (largest gradient component below
#' `gradient_tolerance` and a negative definite Hessian), the multistart
#' results and boundary flags. A failed optimisation returns the fit with a
#' warning of class `switch_warning_convergence`; it never fails silently.
#'
#' **Two-step.** Probit, then least squares within each regime with the
#' selection-correction term; \eqn{\sigma_j} and \eqn{\rho_j} are recovered
#' from the residual variance. Standard errors account for the first-stage
#' estimation. \eqn{\sigma_j} and \eqn{\rho_j} are derived quantities without
#' closed-form standard errors (`NA` in `vcov()`). The coefficients of the
#' correction terms (\eqn{\sigma_j\rho_j}) and their full covariance are in
#' `fit$two_step`.
#'
#' **Covariance** (`vcov`):
#' * `"hessian"`: inverse observed information (FIML), or the
#'   first-stage-corrected formula of Heckman (1979) (two-step);
#' * `"opg"`: outer product of gradients (FIML only);
#' * `"sandwich"`: robust sandwich (FIML), or the stacked M-estimation
#'   sandwich (two-step);
#' * `"cluster"`: cluster-robust version of `"sandwich"`.
#'
#' The default is `"cluster"` when `cluster` is given, `"sandwich"` when
#' `weights` are given, and `"hessian"` otherwise.
#'
#' @param selection Two-sided formula of the selection equation (see
#'   [switch_model()]). Must be `NULL` when `model` is a `switch_spec`.
#' @param outcomes List of two outcome formulas (see [switch_model()]).
#' @param data Data frame.
#' @param model Model type (`"esr"`) or a `switch_spec` from
#'   [switch_model()].
#' @param selection_family,outcome_family,dependence Families; see
#'   [switch_model()].
#' @param method `"fiml"` or `"two_step"`.
#' @param estimator Synonym of `method` (specification section 10.3).
#' @param weights,cluster,subset Sampling weights, cluster identifiers and a
#'   logical subset: each a one-sided formula, a column name or a vector of
#'   length `nrow(data)`.
#' @param vcov Covariance estimator (see Details).
#' @param missing `"drop"` removes rows with missing values, with a message
#'   and a record in `fit$na_report`; `"fail"` makes them an error.
#' @param control Numerical controls from [switch_control()].
#' @param ... Not used; unknown arguments give an error.
#' @return An object of class `switch_fit`.
#' @references
#' Heckman, J. J. (1979). Sample selection bias as a specification error.
#' *Econometrica*, 47(1), 153--161. \doi{10.2307/1912352}
#'
#' Lokshin, M. and Sajaia, Z. (2004). Maximum likelihood estimation of
#' endogenous switching regression models. *The Stata Journal*, 4(3),
#' 282--289. \doi{10.1177/1536867X0400400306}
#' @examples
#' set.seed(1)
#' n <- 500
#' d <- data.frame(x1 = rnorm(n), x2 = rnorm(n), z1 = rnorm(n))
#' u <- rnorm(n)
#' e1 <- 0.6 * u + 0.8 * rnorm(n); e0 <- 0.4 * u + sqrt(0.84) * rnorm(n)
#' d$S <- as.integer(0.5 + 0.3 * d$x1 - 0.4 * d$z1 + u > 0)
#' d$y <- ifelse(d$S == 1, 1.5 + 0.8 * d$x1 + 0.4 * d$x2 + e1,
#'               1.0 + 0.5 * d$x1 + 0.2 * d$x2 + e0)
#' fit <- switch_fit(S ~ x1 + z1, list(regime_0 = y ~ x1 + x2,
#'                                     regime_1 = y ~ x1 + x2), data = d)
#' fit
#' coef(fit)
#' fit2 <- switch_fit(S ~ x1 + z1, list(y ~ x1 + x2, y ~ x1 + x2), data = d,
#'                    method = "two_step")
#' coef(fit2)
#' @export
switch_fit <- function(selection = NULL, outcomes = NULL, data, model = "esr",
                       selection_family = "probit", outcome_family = "gaussian",
                       dependence = "gaussian", method = "fiml",
                       estimator = NULL, weights = NULL, cluster = NULL,
                       subset = NULL,
                       vcov = c("hessian", "opg", "sandwich", "cluster"),
                       missing = c("drop", "fail"),
                       control = switch_control(), ...) {
  cl <- match.call()
  se_check_dots(list(...))
  na_mode <- match.arg(missing)
  if (!inherits(control, "switch_control")) {
    se_abort("'control' must be created by switch_control()", "argument")
  }
  if (!is.null(estimator)) {
    if (!missing(method) && !identical(method, estimator)) {
      se_abort("'method' and 'estimator' are synonyms; give only one",
               "argument")
    }
    method <- estimator
  }
  se_check_choice("method", method)

  if (inherits(model, "switch_spec")) {
    if (!is.null(selection) || !is.null(outcomes)) {
      se_abort("give either a switch_spec as 'model' or the formulas, not both",
               "argument")
    }
    spec <- model
  } else {
    if (is.null(selection) || is.null(outcomes)) {
      se_abort("'selection' and 'outcomes' are required unless 'model' is a switch_spec",
               "argument")
    }
    spec <- switch_model(selection, outcomes, model = model,
                         selection_family = selection_family,
                         outcome_family = outcome_family,
                         dependence = dependence)
  }

  vcov <- if (missing(vcov)) {
    if (!is.null(cluster)) "cluster" else if (!is.null(weights)) "sandwich"
    else "hessian"
  } else match.arg(vcov)
  if (vcov == "cluster" && is.null(cluster)) {
    se_abort("vcov = \"cluster\" needs 'cluster'", "argument")
  }
  if (method == "two_step" && vcov == "opg") {
    se_abort("vcov = \"opg\" is defined for FIML only", "argument")
  }
  if (!is.null(weights) && vcov %in% c("hessian", "opg")) {
    se_warn(sprintf(paste0(
      "vcov = \"%s\" assumes an unweighted likelihood; with sampling weights ",
      "use \"sandwich\" or \"cluster\""), vcov), "vcov")
  }

  sd <- se_build_data(spec, data, weights = weights, cluster = cluster,
                      subset = subset, missing = na_mode)
  map <- se_parmap_esr(sd)

  ## two-step: the estimator itself, or the FIML start
  ts_type <- switch(vcov, hessian = "model", opg = "model",
                    sandwich = "robust", cluster = "cluster")
  ts <- tryCatch(est_two_step(sd, map, if (method == "two_step") ts_type
                              else "model"),
                 error = function(e) e)
  if (inherits(ts, "error")) {
    if (method == "two_step") stop(ts)
    se_warn(paste0("two-step estimation failed (", conditionMessage(ts),
                   "); FIML starts from probit and OLS with rho = 0"),
            "two_step")
    ts <- NULL
  }

  if (method == "two_step") {
    if (any(ts$rho_out_of_range)) {
      se_warn(sprintf(paste0(
        "two-step: estimated rho outside [-1, 1] for %s; the two-step ",
        "variance recovery is unreliable in this sample"),
        paste(names(ts$rho_out_of_range)[ts$rho_out_of_range],
              collapse = ", ")), "two_step")
    }
    if (isTRUE(ts$probit$separation)) {
      se_warn("selection equation: fitted probabilities numerically 0 or 1 (separation)",
              "separation")
    }
    est <- ts
    est$coef_working <- NULL
    est$loglik <- NA_real_
    est$convergence <- list(
      code = if (isTRUE(ts$probit$converged)) 0L else 1L,
      message = if (isTRUE(ts$probit$converged)) "probit converged"
                else "probit did not converge",
      iterations = ts$probit$iterations, gradient_max = NA_real_,
      gradient_norm = NA_real_, optimizer = "IRLS + least squares",
      path = "two_step", time = NA_real_)
    est$starts <- NULL
    start_info <- NULL
  } else {
    start_list <- list()
    if (!is.null(control$start)) {
      start_list[[1L]] <- list(theta = se_par_working(map, control$start),
                               origin = "user")
    }
    if (!is.null(ts)) {
      th_ts <- est_two_step_start(ts, map)
      se_scale <- sqrt(pmax(diag(ts$vcov), 0))
      se_scale[!is.finite(se_scale)] <- NA_real_
      start_list[[length(start_list) + 1L]] <- list(theta = th_ts,
                                                    origin = "two_step")
    } else {
      th0 <- est_naive_start(sd, map)
      se_scale <- rep(NA_real_, map$p)
      start_list[[length(start_list) + 1L]] <- list(theta = th0,
                                                    origin = "probit_ols")
    }
    est <- est_fiml(sd, map, start_list, se_scale, control, vcov)
    start_info <- start_list[[1L]]$theta
  }

  fit <- new_switch_fit(est, spec, sd, map, ts, control, method, vcov, cl,
                        start_info)
  fit$identification <- tryCatch(se_validate_core(spec, sd, fit),
                                 error = function(e) NULL)
  if (!control$keep_data) fit$data <- NULL
  se_fit_warnings(fit)
  fit
}

## Unknown arguments; arguments of later generations name their generation.
se_check_dots <- function(dots) {
  if (!length(dots)) return(invisible())
  nm <- names(dots) %||% rep("", length(dots))
  future <- c(copula_df = 3L, panel = 5L, selection_lag = 5L,
              random_effects = 5L, spatial = 6L, weights_matrix = 6L)
  k <- nm[nm %in% names(future)]
  if (length(k)) {
    g <- future[[k[1L]]]
    se_abort(sprintf(paste0(
      "argument '%s' is planned for Generation %d (versions %s) and is not ",
      "available in SwitchEconometrics %s"), k[1L], g,
      se_generations[[as.character(g)]], se_version()), "unsupported",
      generation = g)
  }
  se_abort(sprintf("unused argument(s): %s",
                   paste(ifelse(nzchar(nm), nm, "<unnamed>"), collapse = ", ")),
           "argument")
}

new_switch_fit <- function(est, spec, sd, map, ts, control, method, vcov, cl,
                           start_w) {
  th <- est$coefficients
  rho <- th[unlist(map$index$rho)]
  sig <- th[unlist(map$index$sigma)]
  flags <- list(
    rho_boundary = names(rho)[is.finite(rho) & abs(rho) > control$boundary_rho],
    sigma_boundary = names(sig)[is.finite(sig) &
                                  sig < 1e-6 * stats::sd(sd$y)],
    hessian_not_nd = method == "fiml" && est$convergence$code == 2L,
    ill_conditioned = method == "fiml" &&
      isTRUE(est$hessian_condition > control$hessian_condition))
  pkgs <- c(SwitchEconometrics = se_version(),
            maxLik = as.character(getNamespaceVersion("maxLik")))
  record <- list(
    date = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    R = R.version.string, platform = R.version$platform, packages = pkgs,
    call = cl, control = control, seed = control$seed,
    start = if (!is.null(start_w)) se_par_natural(map, start_w),
    optimizer = est$convergence$optimizer,
    optimizer_path = est$convergence$path,
    data = list(n = sd$n, n_regime = sd$n_regime, k_selection = ncol(sd$Z),
                k_outcome = vapply(sd$X, ncol, integer(1))),
    sample_index = sd$index, integration = "analytic")
  structure(list(
    call = cl, spec = spec, model = spec$model, method = method,
    coefficients = th, coef_working = est$coef_working,
    vcov = est$vcov, vcov_working = est$vcov_working,
    vcov_type = vcov, loglik = est$loglik,
    npar = sum(!map$fixed), nobs = sd$n, n_regime = sd$n_regime,
    regimes = sd$regimes,
    two_step = ts, convergence = est$convergence, starts = est$starts,
    diagnostics = list(hessian_eigen = est$hessian_eigen,
                       hessian_condition = est$hessian_condition,
                       flags = flags, multistart_flat = est$multistart_flat,
                       local_maxima = est$local_maxima),
    identification = NULL,
    map = map,
    data = sd,
    terms = sd$terms, xlevels = sd$xlevels, contrasts = sd$contrasts,
    na_report = sd$na_report, weights = sd$weights, cluster = sd$cluster,
    record = record), class = "switch_fit")
}

## Warnings that every fit must surface (never silent).
se_fit_warnings <- function(fit) {
  if (fit$method == "fiml" && fit$convergence$code != 0L) {
    se_warn(sprintf("FIML did not converge: %s (code %d); results are not reliable",
                    fit$convergence$message, fit$convergence$code),
            "convergence")
  }
  f <- fit$diagnostics$flags
  if (length(f$rho_boundary)) {
    se_warn(sprintf("estimated %s at the boundary (|rho| > %g): inference is unreliable",
                    paste(f$rho_boundary, collapse = ", "),
                    fit$record$control$boundary_rho), "boundary")
  }
  if (length(f$sigma_boundary)) {
    se_warn(sprintf("degenerate variance: %s",
                    paste(f$sigma_boundary, collapse = ", ")), "boundary")
  }
  if (isTRUE(f$ill_conditioned)) {
    se_warn(sprintf("ill-conditioned Hessian (condition number %.3g)",
                    fit$diagnostics$hessian_condition), "conditioning")
  }
  idn <- fit$identification
  if (inherits(idn, "switch_validation")) {
    i4 <- idn$table[idn$table$code == "I4" & idn$table$status == "warning", ]
    for (m in i4$message) se_warn(m, "identification")
  }
  if (isTRUE(fit$diagnostics$multistart_flat)) {
    se_warn(paste0("different parameter values reach the same maximum ",
                   "log-likelihood: the likelihood is flat (weak identification)"),
            "multistart")
  }
  invisible(fit)
}

#' @rdname switch_fit
#' @export
esr <- function(selection, outcomes, data, method = "fiml", ...) {
  switch_fit(selection = selection, outcomes = outcomes, data = data,
             model = "esr", method = method, ...)
}
