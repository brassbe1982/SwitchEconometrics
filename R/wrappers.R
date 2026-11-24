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
#' **Cautions.**
#' * *Small samples.* In the simulation study of the package, the 95%
#'   intervals of \eqn{\sigma} and \eqn{\rho} of the sample selection model
#'   covered the true values in about 92.5% of the samples when 1000 units
#'   were sampled (about 670 observed outcomes), \eqn{\rho = 0.6} and the
#'   excluded variable was of moderate strength; coverage was 93% to 94.5%
#'   with 2000 units and 95% with 5000. With fewer than about 1000 observed
#'   outcomes these intervals are somewhat too short;
#'   [switch_bootstrap()] is an alternative.
#' * *Local maxima.* The likelihood of the sample selection model can have
#'   more than one local maximum, one of them close to \eqn{\rho = \pm 1}.
#'   The default fit uses several starting values and reports the highest
#'   maximum; when that maximum has \eqn{|\rho| > 0.95} and another start
#'   converged to a lower one, a warning of class
#'   `switch_warning_local_maximum` is given and both are listed in
#'   `fit$starts`. `switch_control(starts = 1)` starts from the two-step
#'   estimates only, which reproduces published results such as those for
#'   the Mroz (1987) data. A maximum near the boundary is a reason to
#'   question the specification, not evidence for either solution.
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

#' Multinomial endogenous switching regression
#'
#' Switching regression with \eqn{J \ge 2} regimes chosen by a multinomial
#' logit: unit \eqn{i} is in the regime with the largest utility
#' \eqn{z_i'\gamma_j + u_{ij}} (Gumbel disturbances, \eqn{\gamma = 0} for
#' the base regime), and the outcome \eqn{y = x_j'\beta_j + \varepsilon_j}
#' of that regime is observed. `multinomial_switch()` is [switch_fit()] with
#' `model = "multinomial_esr"`.
#'
#' @details
#' **Full-information maximum likelihood** (`method = "fiml"`) uses the
#' transformation of Lee (1983): for each regime the outcome disturbance and
#' a normal transform of that regime's selection index are bivariate normal
#' with correlation \eqn{\rho_j}. \eqn{\rho_j > 0} means that unobservables
#' favouring regime \eqn{j} raise its outcome. The gradient and the Hessian
#' are analytic.
#'
#' **Two-step estimation** (`method = "two_step"`) fits the multinomial logit
#' and then one regression per regime with selection-correction terms:
#'
#' | `correction` | Terms per regime | Reference |
#' | --- | --- | --- |
#' | `"lee"` | 1 | Lee (1983) |
#' | `"dmf"` | \eqn{J - 1} | Dubin and McFadden (1984), with their restriction that the correlations sum to zero |
#' | `"bfg1"` | \eqn{J} | Bourguignon, Fournier and Gurgand (2007), variant without that restriction |
#' | `"bfg2"` | \eqn{J} | the same with normalised disturbances |
#'
#' For `"lee"` the covariance is corrected for the first step in closed
#' form (or the stacked sandwich with `vcov = "sandwich"` or `"cluster"`),
#' and \eqn{\sigma_j} and \eqn{\rho_j} are recovered. The other three are
#' moment models: the coefficients of the correction terms are reported as
#' `<regime>:theta[<alternative>]`, there are no \eqn{\sigma_j} or
#' correlations, and the default standard errors are bootstrap standard
#' errors over both steps (`switch_control(bootstrap_R = )` replicates).
#'
#' **Effects.** [switch_effects()] gives, for every pair of regimes, the
#' average treatment effect and the effects on the units of either regime,
#' with the \eqn{J \times J} table of mean expected outcomes. Under Lee's
#' model the counterfactual means need one further assumption (the outcome
#' disturbance of a regime depends on the utilities only through that
#' regime's selection index); the output names it. With multinomial-logit
#' selection it implies that the counterfactual mean of a regime's outcome
#' is the same for the units of every other regime with the same
#' covariates. The Dubin-McFadden and BFG corrections do not need it.
#'
#' **Number of regimes.** Any number the data support; every regime needs
#' enough observations for its outcome equation.
#'
#' **Normal-score model (experimental).**
#' `switch_fit(model = "multinomial_esr", dependence_structure = "normal_scores")`
#' replaces Lee's single correlation per regime by one correlation with the
#' utility disturbance of every regime: with \eqn{\eta_k} the normal
#' transform of \eqn{u_k}, the outcome disturbance of regime \eqn{j} and
#' \eqn{(\eta_1, \dots, \eta_J)} are jointly normal with correlations
#' `<regime>:rho[<alternative>]`, whose squares sum to less than one within
#' a regime. Counterfactual means then follow from the model without the
#' further assumption that Lee's model needs. It is estimated by FIML for 2
#' or 3 regimes. Three cautions. The likelihood is an integral computed
#' numerically, and a fit takes minutes where Lee's model takes seconds.
#' The correlations of a regime with the disturbances of the other regimes
#' are weakly identified in samples of a few thousand observations (they
#' play the role of the Dubin-McFadden correction terms, which are highly
#' collinear): their standard errors are large. And the estimate can lie on
#' the boundary of the admissible region (squares summing to one), in which
#' case the fit reports that it did not converge and flags the boundary.
#'
#' The multinomial logit assumes independence of irrelevant alternatives.
#'
#' @param selection Two-sided formula; the response is a factor (or a
#'   variable that is turned into one) whose levels are the regimes.
#' @param outcomes List of two-sided formulas, one per regime, named with the
#'   levels of the regime variable (an unnamed list is matched by position,
#'   with a message).
#' @param data A data frame.
#' @param method `"fiml"` or `"two_step"`.
#' @param base Label of the base regime (default: the first level).
#' @param correction Two-step correction (see Details).
#' @param ... Further arguments of [switch_fit()].
#' @return An object of class `switch_fit`.
#' @references
#' Bourguignon, F., Fournier, M. and Gurgand, M. (2007). Selection bias
#' corrections based on the multinomial logit model: Monte Carlo
#' comparisons. *Journal of Economic Surveys*, 21(1), 174--205.
#' \doi{10.1111/j.1467-6419.2007.00503.x}
#'
#' Dubin, J. A. and McFadden, D. L. (1984). An econometric analysis of
#' residential electric appliance holdings and consumption. *Econometrica*,
#' 52(2), 345--362. \doi{10.2307/1911493}
#'
#' Lee, L.-F. (1983). Generalized econometric models with selectivity.
#' *Econometrica*, 51(2), 507--512. \doi{10.2307/1912003}
#' @seealso [switch_fit()], [switch_effects()], [switch_predict()]
#' @examples
#' set.seed(3)
#' n <- 900
#' d <- data.frame(x1 = rnorm(n), z1 = rnorm(n), z2 = rnorm(n))
#' sp <- switch_model(regime ~ x1 + z1 + z2,
#'                    list(a = y ~ x1, b = y ~ x1, c = y ~ x1),
#'                    model = "multinomial_esr")
#' par <- c(0.2, 0.3, 0.8, -0.2,   -0.2, -0.3, 0.2, 0.8,
#'          1.0, 0.5, 1, 0.5,   1.5, 0.8, 1, 0.4,   2.0, 0.3, 1.2, -0.4)
#' d <- switch_simulate(sp, d, parameters = par, seed = 4)
#' fit <- multinomial_switch(regime ~ x1 + z1 + z2,
#'                           list(a = y ~ x1, b = y ~ x1, c = y ~ x1), data = d)
#' fit
#' switch_effects(fit, effects = c("ATE", "ATT"))
#' @export
multinomial_switch <- function(selection, outcomes, data, method = "fiml",
                               base = NULL, correction = "lee", ...) {
  fit <- switch_fit(selection = selection, outcomes = outcomes, data = data,
                    model = "multinomial_esr", method = method, base = base,
                    correction = correction, ...)
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
