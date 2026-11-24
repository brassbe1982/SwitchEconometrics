#' Treatment effects of an endogenous switching model
#'
#' Computes the four conditional expectations of the potential outcomes and
#' the treatment effects of the classical endogenous switching regression
#' (specification section 11; TREATMENT_EFFECTS.md of the architecture
#' documents).
#'
#' With \eqn{w = z'\gamma}, \eqn{m_1 = \phi(w)/\Phi(w)},
#' \eqn{m_0 = -\phi(w)/(1 - \Phi(w))} and
#' \eqn{\theta_j = \sigma_j\rho_j}:
#' \itemize{
#'   \item (a) \eqn{E[Y(1) \mid S = 1] = x_1'\beta_1 + \theta_1 m_1} (observed),
#'   \item (b) \eqn{E[Y(0) \mid S = 1] = x_0'\beta_0 + \theta_0 m_1} (counterfactual),
#'   \item (c) \eqn{E[Y(1) \mid S = 0] = x_1'\beta_1 + \theta_1 m_0} (counterfactual),
#'   \item (d) \eqn{E[Y(0) \mid S = 0] = x_0'\beta_0 + \theta_0 m_0} (observed).
#' }
#' ATT is the mean of (a) - (b) over regime-1 units; ATU the mean of (c) - (d)
#' over regime-0 units; ATE the mean of \eqn{x_1'\beta_1 - x_0'\beta_0} over
#' all units; TH = ATT - ATU (treatment heterogeneity); BH1 = mean (a) minus
#' mean (c) and BH0 = mean (b) minus mean (d) (base heterogeneity; Carter and
#' Milon 2005; Di Falco, Veronesi and Yesuf 2011), so that BH1 - BH0 = TH.
#' The share-weighted average of ATT and ATU is reported alongside ATE; the
#' two coincide exactly only at the probit estimate of the selection
#' equation. With sampling weights all means are weighted.
#'
#' The effects are sample averages conditional on the covariates.
#' Delta-method standard errors (`se = "delta"`) treat the covariates as
#' fixed; bootstrap standard errors (`se = "bootstrap"`, via
#' [switch_bootstrap()]) also reflect their sampling variation. None of these
#' quantities depends on the unidentified correlation of the two outcome
#' disturbances; distributional effects (for example the variance of
#' \eqn{Y(1) - Y(0)}) do and are not reported as estimates.
#'
#' @param object A `switch_fit` fitted with `keep_data = TRUE`.
#' @param effects Effects to report: any of `"ATT"`, `"ATU"`, `"ATE"`,
#'   `"TH"`, `"BH"` (`"BH"` gives BH1 and BH0).
#' @param se `"delta"`, `"bootstrap"` or `"none"`.
#' @param level Confidence level.
#' @param by Optional grouping for heterogeneity analysis: a vector for the
#'   estimation sample (length `nobs(object)`), a vector for the full data,
#'   or a one-sided formula or column name evaluated in `data`.
#' @param subset Optional logical restriction of the units, given like `by`.
#' @param individual Return the per-observation expectations and effects.
#' @param data The data frame used for fitting (needed when `by` or `subset`
#'   is a formula or column name).
#' @param R,seed Bootstrap replicates and seed (`se = "bootstrap"`).
#' @param pairs For a multinomial fit: `"all"` (every pair of regimes) or a
#'   list of pairs of regime labels, each `c(regime, against)`.
#' @param given For a multinomial fit: labels of regimes for whose units the
#'   effect of each pair is also reported (effect `"TE"`).
#' @param x A `switch_effects` object.
#' @param digits Significant digits printed.
#' @param ... Not used.
#' @return An object of class `switch_effects` with elements `table`
#'   (effect, group, estimate, std_error, statistic, p_value, lower, upper),
#'   `means` (the 2 x 2 table of group means with group sizes, per group),
#'   `ate_weighted`, `individual` (if requested) and `definitions`.
#' @references
#' Carter, D. W. and Milon, J. W. (2005). Price knowledge in household demand
#' for utility services. *Land Economics*, 81(2), 265--283.
#'
#' Di Falco, S., Veronesi, M. and Yesuf, M. (2011). Does adaptation to
#' climate change provide food security? A micro-perspective from Ethiopia.
#' *American Journal of Agricultural Economics*, 93(3), 829--846.
#' \doi{10.1093/ajae/aar006}
#' @section Other models:
#' For a fit of [treatment()] the effects are averages of the shift
#' \eqn{d'\delta} over the treated (ATT), the untreated (ATU) and all units
#' (ATE); with a constant shift they all equal \eqn{\delta} and TH is zero.
#' A fit of [heckman()] has one potential outcome, and a fit of [tobit5()]
#' with two different response variables has no common outcome scale: both
#' are refused with an error of class `switch_error_unsupported`.
#'
#' For a multinomial fit ([multinomial_switch()]) the effects are reported
#' for pairs of regimes: for the pair (regime \eqn{j}, against \eqn{k}),
#' ATE is the mean of \eqn{x_j'\beta_j - x_k'\beta_k} over all units, ATT
#' the mean of \eqn{E[Y(j) - Y(k) \mid S = j]} over the units of regime
#' \eqn{j}, ATU the mean of \eqn{E[Y(j) - Y(k) \mid S = k]} over the units
#' of regime \eqn{k}, and TH their difference. The result has the class
#' `switch_effects_multi`; its element `means` is the table of the mean
#' expected outcome of every regime for the units of every regime. Standard
#' errors are delta-method standard errors; `by` and `subset` work as for
#' the binary model; `se = "bootstrap"` and `"BH"` are not available for
#' multinomial fits in this version.
#' @examples
#' fit <- switch_fit(
#'   digital_adoption ~ internet_access + management_quality + firm_size +
#'     owner_education,
#'   list(regime_0 = productivity ~ firm_size + capital + labour,
#'        regime_1 = productivity ~ firm_size + capital + labour),
#'   data = firms)
#' eff <- switch_effects(fit)
#' eff
#' switch_effects(fit, effects = "ATT", by = ~ region, data = firms)
#' @export
switch_effects <- function(object, effects = c("ATT", "ATU", "ATE", "TH", "BH"),
                           se = c("delta", "bootstrap", "none"), level = 0.95,
                           by = NULL, subset = NULL, individual = FALSE,
                           data = NULL, R = 999L, seed = NULL, pairs = "all",
                           given = NULL, ...) {
  if (!inherits(object, "switch_fit")) {
    se_abort("'object' must be a switch_fit", "argument")
  }
  if (se_is_multi(object$model)) {
    return(se_effects_multi(object, effects, match.arg(se), level, by, subset,
                            data, pairs, given, individual))
  }
  if (identical(object$model, "heckman")) se_refuse_heckman("Treatment effects")
  if (identical(object$model, "tobit5") && se_responses_differ(object)) {
    se_abort(paste0("effects are not defined for a Tobit-5 fit with two ",
                    "different response variables: their difference is not a ",
                    "treatment effect"), "unsupported")
  }
  fit0 <- object
  object <- se_esr_view(object)
  sd <- object$data
  if (is.null(sd)) {
    se_abort("effects need the estimation data; refit with switch_control(keep_data = TRUE)",
             "argument")
  }
  ok_eff <- c("ATT", "ATU", "ATE", "TH", "BH")
  if (!is.character(effects) || !all(effects %in% ok_eff)) {
    se_abort(sprintf("'effects' must be among %s", paste(ok_eff, collapse = ", ")),
             "argument")
  }
  keep <- unlist(lapply(effects, function(e) if (e == "BH") c("BH1", "BH0") else e))
  se <- match.arg(se)
  n <- sd$n
  sel <- se_eff_resolve(subset, object, data, "subset")
  sel <- if (is.null(sel)) rep(TRUE, n) else !is.na(sel) & as.logical(sel)
  grp <- se_eff_resolve(by, object, data, "by")
  if (!is.null(grp)) grp <- droplevels(as.factor(grp))

  map <- object$map
  ix <- se_psi_index(map, sd$regimes)
  psi <- se_psi_from_natural(object$coefficients, map, sd$regimes)
  cmp <- se_eff_components(psi, sd$Z, sd$X[[1L]], sd$X[[2L]], ix,
                           grad = se == "delta")
  om <- sd$weights %||% rep(1, n)
  sets <- if (is.null(grp)) list(all = sel)
          else stats::setNames(lapply(levels(grp), function(l)
            sel & !is.na(grp) & grp == l), levels(grp))
  res <- lapply(sets, function(s) se_eff_compute(cmp, sd$S, om, s))

  z <- stats::qnorm(1 - (1 - level) / 2)
  boot <- NULL
  if (se == "delta") {
    V <- se_psi_vcov(object)
    if (anyNA(V)) se_abort("the covariance matrix contains NA; use se = \"bootstrap\"",
                           "argument")
  }
  if (se == "bootstrap") {
    boot <- switch_bootstrap(fit0, R = R, statistics = "effects", seed = seed,
                             level = level,
                             .effects = list(by = grp, subset = sel))
  }
  rows <- list()
  for (g in names(res)) {
    r <- res[[g]]
    for (e in keep) {
      est <- r$estimate[[e]]
      key <- if (is.null(grp)) e else paste0(e, "[", g, "]")
      s <- switch(se, none = NA_real_,
                  delta = sqrt(drop(t(r$gradient[e, ]) %*% V %*% r$gradient[e, ])),
                  bootstrap = boot$se[[key]])
      ci <- switch(se, none = c(NA, NA), delta = est + c(-1, 1) * z * s,
                   bootstrap = unname(boot$ci_percentile[key, ]))
      rows[[length(rows) + 1L]] <- data.frame(
        effect = e, group = g, estimate = est, std_error = s,
        statistic = est / s, p_value = 2 * stats::pnorm(-abs(est / s)),
        lower = ci[1L], upper = ci[2L], stringsAsFactors = FALSE)
    }
  }
  tab <- do.call(rbind, rows)
  rownames(tab) <- NULL
  ind <- NULL
  if (individual) {
    EY <- cmp$EY
    ind <- data.frame(index = sd$index, regime = sd$regimes[sd$S + 1L],
                      EY, TT = ifelse(sd$S == 1L, EY[, 1] - EY[, 3], NA),
                      TU = ifelse(sd$S == 0L, EY[, 2] - EY[, 4], NA),
                      ATE_i = cmp$xb1 - cmp$xb0, row.names = NULL)
    if (!is.null(grp)) ind$group <- grp
  }
  structure(list(
    table = tab,
    means = lapply(res, function(r) list(means = r$means, n = r$n)),
    ate_weighted = vapply(res, function(r) r$ate_weighted, numeric(1)),
    individual = ind, se = se, level = level, regimes = sd$regimes,
    method = object$method, bootstrap = boot,
    definitions = c(
      ATT = "mean over regime-1 units of E[Y(1)|S=1] - E[Y(0)|S=1]",
      ATU = "mean over regime-0 units of E[Y(1)|S=0] - E[Y(0)|S=0]",
      ATE = "mean over all units of x1'b1 - x0'b0",
      TH = "ATT - ATU (treatment heterogeneity)",
      BH1 = "mean E[Y(1)|S=1] over regime-1 units minus mean E[Y(1)|S=0] over regime-0 units",
      BH0 = "mean E[Y(0)|S=1] over regime-1 units minus mean E[Y(0)|S=0] over regime-0 units")),
    class = "switch_effects")
}

#' @rdname switch_effects
#' @export
print.switch_effects <- function(x, digits = 4L, ...) {
  r1 <- x$regimes[2L]; r0 <- x$regimes[1L]
  for (g in names(x$means)) {
    m <- x$means[[g]]$means; nn <- x$means[[g]]$n
    eff <- x$table[x$table$group == g, ]
    gv <- function(e) { v <- eff$estimate[eff$effect == e]
      if (length(v)) format(v, digits = digits) else "" }
    cat(sprintf("Conditional expectations and effects%s\n",
                if (g == "all") "" else sprintf(" - group %s", g)))
    tab <- matrix(c(
      format(m[["EY1_S1"]], digits = digits), format(m[["EY0_S1"]], digits = digits), gv("ATT"),
      format(m[["EY1_S0"]], digits = digits), format(m[["EY0_S0"]], digits = digits), gv("ATU"),
      gv("BH1"), gv("BH0"), gv("TH")), 3, byrow = TRUE,
      dimnames = list(c(sprintf("%s units (n = %d)", r1, nn[["S1"]]),
                        sprintf("%s units (n = %d)", r0, nn[["S0"]]),
                        "heterogeneity"),
                      c(sprintf("outcome under %s", r1),
                        sprintf("outcome under %s", r0), "effect")))
    ## the heterogeneity row only when TH, BH1 or BH0 was requested
    if (all(tab[3L, ] == "")) tab <- tab[1:2, , drop = FALSE]
    print(noquote(tab), right = TRUE)
    cat("\n")
  }
  tb <- x$table
  num <- c("estimate", "std_error", "statistic", "p_value", "lower", "upper")
  tb[num] <- lapply(tb[num], signif, digits = digits)
  if (all(tb$group == "all")) tb$group <- NULL
  print(tb, row.names = FALSE)
  cat(sprintf("\nStandard errors: %s%s. Share-weighted pi*ATT + (1-pi)*ATU: %s.\n",
              switch(x$se, delta = "delta method (covariates fixed)",
                     bootstrap = sprintf("bootstrap (%d replicates, percentile intervals)",
                                         x$bootstrap$successful),
                     none = "not computed"),
              if (x$se != "none") sprintf(", %g%% intervals", 100 * x$level) else "",
              paste(format(x$ate_weighted, digits = digits), collapse = ", ")))
  invisible(x)
}
