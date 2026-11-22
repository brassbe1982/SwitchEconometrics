#' SwitchEconometrics: Unified Estimation of Endogenous Regime-Dependent
#' Economic Systems
#'
#' A unified framework for endogenous switching regression, endogenous
#' treatment, sample selection, multinomial switching, copula-based
#' dependence and longitudinal switching, built on one general statistical
#' model, the Generalized Endogenous Switching System.
#'
#' @section Development status:
#' Generation 1 (classical binary endogenous switching regression) is under
#' development. Version 0.2.0 provides the model-specification layer
#' ([switch_model()]), the distribution engine ([distribution()]) and the
#' parameter-transformation engine; the likelihood and the estimators are
#' added in versions 0.3.0 to 1.0.0.
#' The authoritative econometric specification, the derivations and the
#' delivery plan are kept in the source repository (folders
#' `00_Project_Governance` to `05_References`).
#'
#' @references
#' Heckman, J. J. (1979). Sample selection bias as a specification error.
#' *Econometrica*, 47(1), 153--161. \doi{10.2307/1912352}
#'
#' Lokshin, M. and Sajaia, Z. (2004). Maximum likelihood estimation of
#' endogenous switching regression models. *The Stata Journal*, 4(3),
#' 282--289. \doi{10.1177/1536867X0400400306}
#'
#' @keywords internal
#' @importFrom stats dnorm pnorm qnorm rnorm
"_PACKAGE"
