#' Simulated firms: digital adoption and productivity
#'
#' Simulated data on 2000 firms choosing whether to adopt digital
#' technology, generated from a classical binary endogenous switching
#' regression with known parameters, for examples and tests. No real firms
#' are represented. The generating script is `data-raw/firms.R` in the
#' source repository (seed 20261122).
#'
#' @format A data frame with 2000 rows and 10 variables:
#' \describe{
#'   \item{firm_id}{firm identifier}
#'   \item{region}{factor with 5 regions (no effect in the data-generating process)}
#'   \item{digital_adoption}{regime indicator: 1 if the firm adopted digital technology}
#'   \item{productivity}{log labour productivity (the outcome)}
#'   \item{internet_access}{1 if the firm has internet access (excluded from the outcome equations)}
#'   \item{management_quality}{standardised management score (excluded from the outcome equations)}
#'   \item{firm_size}{log number of employees}
#'   \item{owner_education}{years of education of the owner (excluded from the outcome equations)}
#'   \item{capital}{log capital per worker}
#'   \item{labour}{log hours per worker}
#' }
#'
#' @details
#' Data-generating process (true parameters):
#' \itemize{
#'   \item selection: \eqn{S = 1\{-2.1 + 0.9\,\mathrm{internet\_access} +
#'     0.5\,\mathrm{management\_quality} + 0.25\,\mathrm{firm\_size} +
#'     0.06\,\mathrm{owner\_education} + u > 0\}};
#'   \item regime 1 (adopters): \eqn{\mathrm{productivity} = 0.8 +
#'     0.08\,\mathrm{firm\_size} + 0.35\,\mathrm{capital} +
#'     0.10\,\mathrm{labour} + \varepsilon_1}, \eqn{\sigma_1 = 0.50};
#'   \item regime 0: \eqn{\mathrm{productivity} = 0.5 +
#'     0.05\,\mathrm{firm\_size} + 0.30\,\mathrm{capital} +
#'     0.10\,\mathrm{labour} + \varepsilon_0}, \eqn{\sigma_0 = 0.45};
#'   \item \eqn{\mathrm{Corr}(u, \varepsilon_1) = 0.45},
#'     \eqn{\mathrm{Corr}(u, \varepsilon_0) = -0.25}: firms with
#'     unobservably higher returns to adoption are more likely to adopt.
#' }
#' The adoption share in the data is 0.486.
#' @source Simulated with `data-raw/firms.R`.
#' @examples
#' summary(firms)
#' fit <- switch_fit(
#'   digital_adoption ~ internet_access + management_quality + firm_size +
#'     owner_education,
#'   list(regime_0 = productivity ~ firm_size + capital + labour,
#'        regime_1 = productivity ~ firm_size + capital + labour),
#'   data = firms)
#' summary(fit)
"firms"
