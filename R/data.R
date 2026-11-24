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

#' Simulated firms: financing regime and productivity
#'
#' Simulated data on 3000 firms that finance themselves internally, through
#' a bank or through a digital lender, generated from a multinomial
#' endogenous switching regression with known parameters (multinomial-logit
#' choice, Lee's dependence), for examples and tests. No real firms are
#' represented. The generating script is `data-raw/financing.R` in the
#' source repository (seed 20261124).
#'
#' @format A data frame with 3000 rows and 8 variables:
#' \describe{
#'   \item{firm_id}{firm identifier}
#'   \item{financing}{factor: financing regime, `internal` (base), `bank` or `digital`}
#'   \item{productivity}{log labour productivity (the outcome)}
#'   \item{firm_size}{log number of employees}
#'   \item{capital}{log capital per worker}
#'   \item{collateral}{standardised collateral index (excluded from the outcome equations)}
#'   \item{financial_access}{1 if a bank branch is nearby (excluded from the outcome equations)}
#'   \item{digital_infrastructure}{standardised index of digital infrastructure (excluded from the outcome equations)}
#' }
#'
#' @details
#' Data-generating process (true parameters), with `firm_size` centred at 3
#' in the utilities:
#' \itemize{
#'   \item utility of `bank`: \eqn{-0.6 + 0.15(\mathrm{firm\_size} - 3) +
#'     0.8\,\mathrm{collateral} + 0.5\,\mathrm{financial\_access}};
#'   \item utility of `digital`: \eqn{-0.8 - 0.10(\mathrm{firm\_size} - 3) +
#'     0.1\,\mathrm{collateral} + 0.3\,\mathrm{financial\_access} +
#'     0.9\,\mathrm{digital\_infrastructure}}; `internal` is the base;
#'     Gumbel disturbances;
#'   \item productivity under `internal`: \eqn{0.5 + 0.05\,\mathrm{firm\_size}
#'     + 0.30\,\mathrm{capital}}, \eqn{\sigma = 0.45}, \eqn{\rho = 0.30};
#'   \item under `bank`: \eqn{0.7 + 0.08\,\mathrm{firm\_size} +
#'     0.33\,\mathrm{capital}}, \eqn{\sigma = 0.50}, \eqn{\rho = 0.45};
#'   \item under `digital`: \eqn{0.9 + 0.04\,\mathrm{firm\_size} +
#'     0.36\,\mathrm{capital}}, \eqn{\sigma = 0.55}, \eqn{\rho = -0.25}.
#' }
#' \eqn{\rho} is the correlation of a regime's outcome disturbance with the
#' normal transform of its own selection index (Lee 1983).
#' @source Simulated with `data-raw/financing.R`.
#' @examples
#' table(financing$financing)
#' fit <- multinomial_switch(
#'   financing ~ firm_size + collateral + financial_access +
#'     digital_infrastructure,
#'   list(internal = productivity ~ firm_size + capital,
#'        bank = productivity ~ firm_size + capital,
#'        digital = productivity ~ firm_size + capital),
#'   data = financing)
#' summary(fit)
"financing"
