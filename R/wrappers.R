## Model wrappers of Generation 2 (API_SPECIFICATION.md s.5.4). Each is
## switch_fit() with `model` set, as esr() is.

#' Sample selection, endogenous treatment and Tobit-5 models
#'
#' Three models that use the Gaussian likelihood of the binary endogenous
#' switching regression with a different observation mechanism:
#'
#' * `heckman()`: the sample selection model (Tobit-2). The outcome
#'   \eqn{y^* = x'\beta + \varepsilon} is observed only when the selection
#'   indicator is 1. For units with indicator 0 the outcome and its
#'   regressors may be missing.
#' * `treatment()`: one outcome equation for every unit with a shift when
#'   the regime is 1,
#'   \eqn{y = x'\beta + S\,d'\delta + \varepsilon}. With `shift = ~ 1` the
#'   shift is a constant (the classical endogenous dummy-variable model);
#'   with `shift = ~ modifiers` the treatment effect \eqn{d'\delta} varies
#'   with the modifiers (the hybrid model with a structural shift).
#' * `tobit5()`: a second interface to the model of [esr()] in which the
#'   two outcome equations are matched to the regimes by position (first
#'   equation: indicator 0) and may have different response variables.
#'
#' In all three, \eqn{S = 1} when \eqn{z'\gamma + u > 0}, and
#' \eqn{\rho = \mathrm{Corr}(u, \varepsilon)}.
#'
#' @details
#' **Estimation.** `method = "fiml"` maximises the likelihood with an
#' analytic gradient and Hessian. The treatment likelihood is the switching
#' regression likelihood under a linear restriction and uses the same
#' engine. `method = "two_step"` is Heckman's (1979) estimator for
#' `heckman()` and, for `treatment()`, a least-squares regression of the
#' outcome on \eqn{(x, S d, h)} over all units, where
#' \eqn{h = S\,\phi(w)/\Phi(w) - (1 - S)\,\phi(w)/(1 - \Phi(w))} is the
#' generalised residual of the probit; both have covariances corrected for
#' the first step.
#'
#' **Parameter names.** `selection:<term>`, `outcome:<term>`,
#' `shift:<term>` (treatment), `outcome:sigma`, `outcome:rho`.
#'
#' **Effects.** For a treatment fit [switch_effects()] returns the averages
#' of \eqn{d'\delta}: there is one disturbance, so the effect on the treated
#' and on the untreated differ only through the modifiers. A Heckman fit has
#' one potential outcome and no treatment effect; use [switch_predict()].
#' For `tobit5()` with two different response variables the effects are
#' refused, because a difference of two different variables is not a
#' treatment effect.
#'
#' **Identification.** Without a variable in the selection equation that is
#' excluded from the outcome equation, \eqn{\rho} (and, in the treatment
#' model, the shift) is identified only through the normality assumption;
#' [switch_validate()] reports this.
#'
#' These functions are new in version 1.1.0.
#'
#' @param selection Two-sided formula of the selection equation, as in
#'   [switch_fit()].
#' @param outcome Two-sided formula of the outcome equation. In
#'   `treatment()` it must not contain the regime indicator.
#' @param outcomes List of two two-sided formulas: the first is observed
#'   when the indicator is 0, the second when it is 1.
#' @param data A data frame.
#' @param shift One-sided formula of the effect modifiers \eqn{d}; it must
#'   contain the constant.
#' @param method `"fiml"` or `"two_step"`.
#' @param ... Further arguments of [switch_fit()]: `weights`, `cluster`,
#'   `subset`, `vcov`, `missing`, `control`.
#' @return An object of class `switch_fit`.
#' @references
#' Heckman, J. J. (1978). Dummy endogenous variables in a simultaneous
#' equation system. *Econometrica*, 46(4), 931--959. \doi{10.2307/1909757}
#'
#' Heckman, J. J. (1979). Sample selection bias as a specification error.
#' *Econometrica*, 47(1), 153--161. \doi{10.2307/1912352}
#'
#' Maddala, G. S. (1983). *Limited-Dependent and Qualitative Variables in
#' Econometrics*. Cambridge University Press.
#' @seealso [switch_fit()], [esr()], [switch_predict()], [switch_effects()]
#' @examples
#' set.seed(2)
#' n <- 600
#' d <- data.frame(x1 = rnorm(n), x2 = rnorm(n), z1 = rnorm(n))
#' u <- rnorm(n)
#' e <- 0.6 * u + 0.8 * rnorm(n)
#' d$S <- as.integer(0.5 + 0.3 * d$x1 - 0.8 * d$z1 + u > 0)
#'
#' ## sample selection: wage observed for participants only
#' d$wage <- ifelse(d$S == 1, 1.5 + 0.8 * d$x1 + 0.4 * d$x2 + e, NA)
#' h <- heckman(S ~ x1 + z1, wage ~ x1 + x2, data = d)
#' h
#' head(switch_predict(h, type = "conditional"))
#'
#' ## endogenous treatment: constant shift, and a shift that varies with x1
#' d$y <- 1 + 0.5 * d$x1 + 0.2 * d$x2 + d$S * (0.5 + 0.3 * d$x1) + e
#' tr <- treatment(S ~ x1 + z1, y ~ x1 + x2, data = d, shift = ~ x1)
#' coef(tr)
#' switch_effects(tr, effects = c("ATT", "ATU", "ATE"))
#'
#' ## Tobit-5 with different response variables in the two regimes
#' d$y0 <- ifelse(d$S == 0, 1 + 0.5 * d$x1 + e, NA)
#' d$y1 <- ifelse(d$S == 1, 2 + 0.3 * d$x2 + e, NA)
#' t5 <- tobit5(S ~ x1 + z1, list(y0 ~ x1, y1 ~ x2), data = d)
#' coef(t5)
#' @name observation-models
NULL

#' @rdname observation-models
#' @export
heckman <- function(selection, outcome, data, method = "fiml", ...) {
  fit <- switch_fit(selection = selection, outcomes = outcome, data = data,
                    model = "heckman", method = method, ...)
  fit$call <- match.call()
  fit$record$call <- fit$call
  fit
}

#' @rdname observation-models
#' @export
treatment <- function(selection, outcome, data, shift = ~ 1, method = "fiml",
                      ...) {
  fit <- switch_fit(selection = selection, outcomes = outcome, data = data,
                    model = "treatment", method = method, shift = shift, ...)
  fit$call <- match.call()
  fit$record$call <- fit$call
  fit
}

#' @rdname observation-models
#' @export
tobit5 <- function(selection, outcomes, data, method = "fiml", ...) {
  fit <- switch_fit(selection = selection, outcomes = outcomes, data = data,
                    model = "tobit5", method = method, ...)
  fit$call <- match.call()
  fit$record$call <- fit$call
  fit
}

## TRUE when the two outcome equations of a fit have different responses.
se_responses_differ <- function(object) {
  o <- object$spec$outcomes
  length(o) == 2L &&
    !identical(se_deparse(o[[1L]]$formula[[2L]]),
               se_deparse(o[[2L]]$formula[[2L]]))
}
