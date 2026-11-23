#' Counterfactual and policy scenarios
#'
#' Compares the expected outcome under the observed regime assignment with
#' the expected outcome under a scenario (specification section 11.4;
#' TREATMENT_EFFECTS.md section 6):
#'
#' * `"all_regime_1"`: every unit in regime 1, \eqn{E[Y(1) \mid x] = x_1'\beta_1};
#' * `"all_regime_0"`: every unit in regime 0, \eqn{E[Y(0) \mid x] = x_0'\beta_0};
#' * `"policy"`: covariates changed to those in `newdata` (for example better
#'   internet access); regime choices respond through
#'   \eqn{\Phi(z^{*\prime}\gamma)}.
#'
#' The baseline and policy expectations are
#' \eqn{E[Y \mid x, z] = \Phi(w)x_1'\beta_1 + (1 - \Phi(w))x_0'\beta_0 +
#' (\sigma_1\rho_1 - \sigma_0\rho_0)\phi(w)}. The last term keeps the
#' dependence between selection and outcome disturbances: units that switch
#' regime are selected on unobservables correlated with their outcomes.
#' Simulating the regime choice independently of the outcome disturbances
#' would omit it.
#'
#' For the two `all_` scenarios, the change conditional on the observed
#' regime is also reported (for regime-0 units under `"all_regime_1"`:
#' \eqn{E[Y(1) \mid S = 0] - E[Y(0) \mid S = 0]}, whose mean is the ATU).
#' Standard errors use the delta method with the covariates fixed. The
#' distribution of *individual* outcome changes for units that switch regime
#' depends on the unidentified correlation of the two outcome disturbances;
#' it is available only under an explicit assumption via
#' `switch_simulate(potential_outcomes = TRUE, r10 = )`.
#'
#' @param object A `switch_fit` fitted with `keep_data = TRUE`.
#' @param scenario Scenario (see Description).
#' @param newdata For `"policy"`: the data with changed covariates, either
#'   the full data frame used for fitting (`nrow` as the original data) or
#'   the estimation sample (`nobs(object)` rows, same order).
#' @param se `"delta"` or `"none"`.
#' @param by,data Optional grouping, as in [switch_effects()].
#' @param level Confidence level.
#' @param x A `switch_counterfactual` object.
#' @param digits Significant digits printed.
#' @param ... Not used.
#' @return An object of class `switch_counterfactual` with `summary` (mean
#'   baseline, scenario and change, with standard errors and intervals; the
#'   change in the share in regime 1), `individual` (per-observation
#'   probabilities, expectations and changes) and `quantiles` of the
#'   per-observation changes.
#' @examples
#' fit <- switch_fit(
#'   digital_adoption ~ internet_access + management_quality + firm_size +
#'     owner_education,
#'   list(productivity ~ firm_size + capital + labour,
#'        productivity ~ firm_size + capital + labour),
#'   data = firms)
#' switch_counterfactual(fit, "all_regime_1")
#' policy <- firms
#' policy$internet_access <- 1          # universal internet access
#' switch_counterfactual(fit, "policy", newdata = policy)
#' @export
switch_counterfactual <- function(object,
                                  scenario = c("all_regime_1", "all_regime_0",
                                               "policy"),
                                  newdata = NULL, se = c("delta", "none"),
                                  by = NULL, data = NULL, level = 0.95, ...) {
  if (!inherits(object, "switch_fit")) {
    se_abort("'object' must be a switch_fit", "argument")
  }
  if (identical(object$model, "heckman")) {
    se_refuse_heckman("Counterfactual regime scenarios")
  }
  if (identical(object$model, "tobit5") && se_responses_differ(object)) {
    se_abort(paste0("counterfactual scenarios are not defined for a Tobit-5 ",
                    "fit with two different response variables"), "unsupported")
  }
  object <- se_esr_view(object)
  sd <- object$data
  if (is.null(sd)) {
    se_abort("counterfactuals need the estimation data; refit with keep_data = TRUE",
             "argument")
  }
  scenario <- match.arg(scenario)
  se <- match.arg(se)
  reg <- sd$regimes
  map <- object$map
  ix <- se_psi_index(map, reg)
  psi <- se_psi_from_natural(object$coefficients, map, reg)
  om <- sd$weights %||% rep(1, sd$n)
  need_g <- se == "delta"

  ## unconditional expectation and its gradient for a set of covariates
  uncond <- function(Z, X0, X1) {
    cmp <- se_eff_components(psi, Z, X0, X1, ix, grad = FALSE)
    w <- cmp$w; Pw <- stats::pnorm(w); f <- stats::dnorm(w)
    ey <- Pw * cmp$xb1 + (1 - Pw) * cmp$xb0 + (cmp$th1 - cmp$th0) * f
    G <- Gp <- NULL
    if (need_g) {
      G <- matrix(0, length(w), ix$P)
      G[, ix$gamma] <- (f * ((cmp$xb1 - cmp$xb0) - (cmp$th1 - cmp$th0) * w)) * Z
      G[, ix$beta1] <- Pw * X1
      G[, ix$beta0] <- (1 - Pw) * X0
      G[, ix$theta1] <- f
      G[, ix$theta0] <- -f
      Gp <- matrix(0, length(w), ix$P)
      Gp[, ix$gamma] <- f * Z
    }
    list(ey = ey, p = Pw, G = G, Gp = Gp, cmp = cmp)
  }
  base <- uncond(sd$Z, sd$X[[1L]], sd$X[[2L]])
  cmp0 <- se_eff_components(psi, sd$Z, sd$X[[1L]], sd$X[[2L]], ix, grad = need_g)
  cond_change <- NULL
  if (scenario == "policy") {
    if (is.null(newdata)) se_abort("scenario \"policy\" needs 'newdata'", "argument")
    nd <- if (nrow(newdata) == sd$na_report$n_input &&
              nrow(newdata) != sd$n) newdata[sd$index, , drop = FALSE]
          else if (nrow(newdata) == sd$n) newdata
          else se_abort(sprintf(paste0(
            "'newdata' must have the rows of the original data (%d) or of the ",
            "estimation sample (%d)"), sd$na_report$n_input, sd$n), "data")
    des <- se_newdata_design(object, nd)
    if (!all(des$ok)) se_abort("'newdata' has missing values in model variables",
                               "data")
    scen <- uncond(des$Z, des$X[[1L]], des$X[[2L]])
  } else {
    one <- scenario == "all_regime_1"
    ey <- if (one) cmp0$xb1 else cmp0$xb0
    G <- NULL
    if (need_g) {
      G <- matrix(0, sd$n, ix$P)
      if (one) G[, ix$beta1] <- sd$X[[2L]] else G[, ix$beta0] <- sd$X[[1L]]
    }
    scen <- list(ey = ey, p = rep(if (one) 1 else 0, sd$n), G = G,
                 Gp = if (need_g) matrix(0, sd$n, ix$P))
    EY <- cmp0$EY
    cond_change <- if (one) ifelse(sd$S == 0L, EY[, "EY1_S0"] - EY[, "EY0_S0"], 0)
                   else ifelse(sd$S == 1L, EY[, "EY0_S1"] - EY[, "EY1_S1"], 0)
    if (need_g) {
      Gc <- if (one) cmp0$grad$EY1_S0 - cmp0$grad$EY0_S0
            else cmp0$grad$EY0_S1 - cmp0$grad$EY1_S1
      Gc[if (one) sd$S == 1L else sd$S == 0L, ] <- 0
    }
  }

  ## groups: all units, units by observed regime, optional by-groups
  grp <- se_eff_resolve(by, object, data, "by")
  sets <- list(all = rep(TRUE, sd$n))
  sets[[sprintf("observed %s", reg[2L])]] <- sd$S == 1L
  sets[[sprintf("observed %s", reg[1L])]] <- sd$S == 0L
  if (!is.null(grp)) {
    grp <- droplevels(as.factor(grp))
    for (l in levels(grp)) sets[[paste0("group ", l)]] <- !is.na(grp) & grp == l
  }
  V <- if (need_g) se_psi_vcov(object)
  z <- stats::qnorm(1 - (1 - level) / 2)
  wm <- function(v, s) sum(om[s] * v[s]) / sum(om[s])
  wg <- function(G, s) colSums(om[s] * G[s, , drop = FALSE]) / sum(om[s])
  sev <- function(g) sqrt(max(drop(t(g) %*% V %*% g), 0))
  rows <- lapply(names(sets), function(nm) {
    s <- sets[[nm]]
    chg <- wm(scen$ey - base$ey, s)
    dp <- wm(scen$p - base$p, s)
    sc <- sp <- sc2 <- NA_real_
    if (need_g) {
      sc <- sev(wg(scen$G - base$G, s))
      sp <- sev(wg(scen$Gp - base$Gp, s))
    }
    out <- data.frame(units = nm, n = sum(s), mean_baseline = wm(base$ey, s),
                      mean_scenario = wm(scen$ey, s), mean_change = chg,
                      std_error = sc, lower = chg - z * sc, upper = chg + z * sc,
                      share_regime1_baseline = wm(base$p, s),
                      share_regime1_scenario = wm(scen$p, s),
                      change_share = dp, std_error_share = sp,
                      stringsAsFactors = FALSE)
    if (!is.null(cond_change)) {
      out$mean_change_given_observed_regime <- wm(cond_change, s)
      out$std_error_given_observed_regime <- if (need_g) sev(wg(Gc, s)) else NA_real_
    }
    out
  })
  summ <- do.call(rbind, rows)
  ind <- data.frame(index = sd$index, regime = reg[sd$S + 1L],
                    prob_baseline = base$p, prob_scenario = scen$p,
                    ey_baseline = base$ey, ey_scenario = scen$ey,
                    change = scen$ey - base$ey)
  if (!is.null(cond_change)) ind$change_given_observed_regime <- cond_change
  structure(list(scenario = scenario, summary = summ, individual = ind,
                 quantiles = stats::quantile(ind$change,
                                             c(0.05, 0.25, 0.5, 0.75, 0.95)),
                 se = se, level = level, regimes = reg),
            class = "switch_counterfactual")
}

#' @rdname switch_counterfactual
#' @export
print.switch_counterfactual <- function(x, digits = 4L, ...) {
  lab <- switch(x$scenario,
                all_regime_1 = sprintf("every unit in regime '%s'", x$regimes[2L]),
                all_regime_0 = sprintf("every unit in regime '%s'", x$regimes[1L]),
                policy = "policy change of the covariates")
  cat("Counterfactual scenario:", lab, "\n")
  s <- x$summary
  keep <- c("units", "n", "mean_baseline", "mean_scenario", "mean_change",
            "std_error", "share_regime1_baseline", "share_regime1_scenario",
            if ("mean_change_given_observed_regime" %in% names(s))
              "mean_change_given_observed_regime")
  out <- s[keep]
  num <- vapply(out, is.numeric, logical(1)) & names(out) != "n"
  out[num] <- lapply(out[num], signif, digits = digits)
  print(out, row.names = FALSE)
  cat("Quantiles of the per-unit change in expected outcome:\n")
  print(signif(x$quantiles, digits))
  cat("Expectations integrate over the selection disturbance and keep its dependence",
      "with the outcome\ndisturbances; standard errors:",
      if (x$se == "delta") "delta method (covariates fixed).\n" else "not computed.\n")
  invisible(x)
}
