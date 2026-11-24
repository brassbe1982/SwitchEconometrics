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
#' perturbed starts (`control`; three starts by default, so that lower local
#' maxima are detected; `switch_control(starts = 1)` runs one). Fallback
#' optimisers are used if a run fails, except when the run ends with a
#' correlation within \eqn{10^{-6}} of \eqn{\pm 1}: the log-likelihood then
#' rises towards the boundary, the fallbacks would climb to the same
#' boundary, and the path in `fit$convergence$path` ends with
#' `"boundary-stop"`. The fit reports whether it converged (largest gradient component below
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
#' @param outcomes List of outcome formulas, one per regime (see
#'   [switch_model()] and, for more than two regimes,
#'   [multinomial_switch()]).
#' @param data Data frame.
#' @param shift For `model = "treatment"`: one-sided formula of the effect
#'   modifiers (see [treatment()]).
#' @param base,correction,dependence_structure For
#'   `model = "multinomial_esr"`: the base alternative, the two-step
#'   correction and the dependence structure (see [multinomial_switch()]).
#' @param model Model type (`"esr"`; from version 1.1.0 also `"heckman"`,
#'   `"treatment"` and `"tobit5"`, see [heckman()]; from version 1.2.0 also
#'   `"multinomial_esr"`, see [multinomial_switch()]) or a `switch_spec`
#'   from [switch_model()].
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
                       control = switch_control(), shift = NULL, base = NULL,
                       correction = NULL, dependence_structure = NULL, ...) {
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
    if (!is.null(shift) || !is.null(base) || !is.null(correction) ||
        !is.null(dependence_structure)) {
      se_abort(paste0("give 'shift', 'base', 'correction' and ",
                      "'dependence_structure' to switch_model() when 'model' ",
                      "is a switch_spec"), "argument")
    }
  } else {
    if (is.null(selection) || is.null(outcomes)) {
      se_abort("'selection' and 'outcomes' are required unless 'model' is a switch_spec",
               "argument")
    }
    spec <- switch_model(selection, outcomes, model = model,
                         selection_family = selection_family,
                         outcome_family = outcome_family,
                         dependence = dependence, shift = shift, base = base,
                         correction = correction,
                         dependence_structure = dependence_structure)
  }
  obs <- se_is_obs(spec$model)
  multi <- se_is_multi(spec$model)
  if (multi) {
    if (method == "fiml" && spec$correction != "lee") {
      se_abort(sprintf(paste0(
        "correction = \"%s\" is a moment model without a likelihood; use ",
        "method = \"two_step\""), spec$correction), "unsupported")
    }
    if (method == "two_step" && spec$dependence$structure != "lee") {
      se_abort(paste0("the normal-score model is estimated by FIML; its ",
                      "two-step counterpart is correction = \"bfg2\""),
               "argument")
    }
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

  sd <- if (obs) se_build_data_obs(spec, data, weights = weights,
                                   cluster = cluster, subset = subset,
                                   missing = na_mode)
        else if (multi) se_build_data_multi(spec, data, weights = weights,
                                            cluster = cluster, subset = subset,
                                            missing = na_mode)
        else se_build_data(spec, data, weights = weights, cluster = cluster,
                           subset = subset, missing = na_mode)
  if (multi) {
    spec$regimes <- sd$regimes
    if (spec$regime_names_given) spec$outcomes <- spec$outcomes[sd$regimes]
    else names(spec$outcomes) <- sd$regimes
    sd$correction_fit <- method == "two_step" && spec$correction != "lee"
    sd$bootstrap_R <- control$bootstrap_R
    if (!sd$correction_fit) sd$correction <- "lee"
  }
  map <- se_parmap(sd)
  ns <- multi && identical(sd$structure, "normal_scores")
  if (ns) {
    if (sd$J > 3L) {
      se_abort(paste0("the normal-score model is available for 2 and 3 ",
                      "regimes in this version; use dependence_structure = ",
                      "\"lee\" or a two-step correction for more regimes"),
               "unsupported")
    }
    ## no analytic Hessian: quasi-Newton iterations unless the user chose
    if (identical(control$optimizer, "NR")) control$optimizer <- "BFGS"
  }

  ## two-step: the estimator itself, or the FIML start
  ts_type <- switch(vcov, hessian = "model", opg = "model",
                    sandwich = "robust", cluster = "cluster")
  ts <- tryCatch(
    if (ns) est_two_step_multi(sd, se_parmap_multi(sd, "lee"), "model",
                               type = "lee")
    else se_two_step(sd, map, if (method == "two_step") ts_type else "model"),
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
      message = if (isTRUE(ts$probit$converged)) "first step converged"
                else "first step did not converge",
      iterations = ts$probit$iterations, gradient_max = NA_real_,
      gradient_norm = NA_real_, optimizer = if (multi) "Newton (multinomial logit) + least squares"
                  else "IRLS + least squares",
      path = "two_step", time = NA_real_)
    est$starts <- NULL
    start_info <- NULL
  } else {
    start_list <- list()
    if (!is.null(control$start)) {
      start_list[[1L]] <- list(theta = se_par_working(map, control$start),
                               origin = "user")
    }
    if (ns) {
      start_list[[length(start_list) + 1L]] <- list(
        theta = se_ns_start(sd, map), origin = "bfg2")
      se_scale <- rep(NA_real_, map$p)
    } else if (!is.null(ts)) {
      th_ts <- est_two_step_start(ts, map)
      se_scale <- sqrt(pmax(diag(ts$vcov), 0))
      se_scale[!is.finite(se_scale)] <- NA_real_
      start_list[[length(start_list) + 1L]] <- list(theta = th_ts,
                                                    origin = "two_step")
    } else {
      th0 <- se_naive_start(sd, map)
      se_scale <- rep(NA_real_, map$p)
      start_list[[length(start_list) + 1L]] <- list(theta = th0,
                                                    origin = "probit_ols")
    }
    est <- est_fiml(sd, map, start_list, se_scale, control, vcov)
    start_info <- start_list[[1L]]$theta
  }

  fit <- new_switch_fit(est, spec, sd, map, ts, control, method, vcov, cl,
                        start_info)
  fit$identification <- tryCatch(
    if (obs) se_validate_obs(spec, sd, fit)
    else if (multi) se_validate_multi(spec, sd, fit)
    else se_validate_core(spec, sd, fit),
    error = function(e) NULL)
  if (multi) {
    fit$base_index <- sd$base
    fit$base <- sd$regimes[sd$base]
  }
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
  rho_b <- names(rho)[is.finite(rho) & abs(rho) > control$boundary_rho]
  if (!is.null(map$groups)) {
    ## correlations on a unit ball (normal-score model): a regime is at the
    ## boundary when its squared correlations sum to more than 0.99
    rho_b <- unlist(lapply(map$groups, function(g) {
      if (isTRUE(sum(th[g]^2) > 0.99)) names(th)[g]
    }))
    if (is.null(rho_b)) rho_b <- character()
  }
  flags <- list(
    rho_boundary = rho_b,
    sigma_boundary = names(sig)[is.finite(sig) &
                                  sig < 1e-6 * stats::sd(sd$y, na.rm = TRUE)],
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
    regimes = sd$regimes, regime_values = sd$regime_values,
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
  if (length(f$rho_boundary) && !is.null(fit$map$groups)) {
    se_warn(sprintf(paste0(
      "estimated %s at the boundary (squared correlations of the regime sum ",
      "to more than 0.99): inference is unreliable"),
      paste(f$rho_boundary, collapse = ", ")), "boundary")
  } else if (length(f$rho_boundary)) {
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
  ## the best maximum lies close to rho = +-1 and another start converged to
  ## a lower local maximum (owner's decision of 24 November 2026, after the
  ## Mroz example of BENCHMARK_PROTOCOL.md s.6.4, D-SS-2)
  near <- se_near_boundary_maximum(fit)
  if (!is.null(near)) {
    se_warn(sprintf(paste0(
      "the highest of the maxima found has %s = %.3f, close to the boundary, ",
      "and %d other start%s converged to a lower local maximum (best of them: ",
      "log-likelihood %.3f against %.3f). Compare the solutions (fit$starts); ",
      "switch_control(starts = 1) starts from the two-step estimates only"),
      near$name, near$rho, near$n, if (near$n == 1L) "" else "s",
      near$loglik_other, fit$loglik), "local_maximum")
  }
  if (isTRUE(fit$diagnostics$multistart_flat)) {
    se_warn(paste0("different parameter values reach the same maximum ",
                   "log-likelihood: the likelihood is flat (weak identification)"),
            "multistart")
  }
  invisible(fit)
}

## NULL, or the description of a best maximum close to the boundary of rho
## (|rho| > 0.95) when at least one other start converged to a lower local
## maximum.
se_near_boundary_maximum <- function(fit, limit = 0.95) {
  if (fit$method != "fiml" || is.null(fit$starts) ||
      !isTRUE(fit$diagnostics$local_maxima > 0)) return(NULL)
  rho <- fit$coefficients[unlist(fit$map$index$rho)]
  rho <- rho[is.finite(rho) & abs(rho) > limit]
  if (!length(rho)) return(NULL)
  st <- fit$starts
  lower <- st$code == 0L & is.finite(st$loglik) & st$loglik < fit$loglik - 1e-6
  if (!any(lower)) return(NULL)
  k <- which.max(abs(rho))
  list(name = names(rho)[k], rho = rho[[k]], n = sum(lower),
       loglik_other = max(st$loglik[lower]))
}

#' @rdname switch_fit
#' @export
esr <- function(selection, outcomes, data, method = "fiml", ...) {
  fit <- switch_fit(selection = selection, outcomes = outcomes, data = data,
                    model = "esr", method = method, ...)
  fit$call <- match.call()
  fit$record$call <- fit$call
  fit
}
