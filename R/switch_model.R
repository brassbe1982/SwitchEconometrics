## Layer 1: model specification.
## Contracts: 02_Computational_Architecture/API_SPECIFICATION.md s.2;
## model: 01_Econometric_Architecture/BINARY_ESR.md.

#' Specify an endogenous switching model
#'
#' Builds and validates the specification of a switching model without data:
#' the regime-selection equation, the regime-specific outcome equations, the
#' outcome and selection families and the dependence structure. The
#' specification can be estimated with `switch_fit()` (from version 0.4.0)
#' and checked with `switch_validate()` (from version 0.5.0).
#'
#' Version 0.2.0 supports the classical binary endogenous switching
#' regression (Generation 1): a probit selection equation
#' \eqn{S = 1\{z'\gamma + u > 0\}}, two Gaussian outcome equations
#' \eqn{y_j = x_j'\beta_j + \varepsilon_j} and jointly normal
#' \eqn{(u, \varepsilon_1, \varepsilon_0)}. Values planned for later
#' generations (for example `model = "multinomial_esr"`) give an error of
#' class `switch_error_unsupported` that names the generation adding them.
#'
#' @param selection Two-sided formula of the selection equation. The response
#'   is the regime indicator: logical, 0/1 or a two-level factor (the second
#'   level is regime 1).
#' @param outcomes List of two two-sided formulas, one per regime. Elements
#'   named after the regime values (`"0"`/`"1"`, `"regime_0"`/`"regime_1"`,
#'   `"FALSE"`/`"TRUE"` or the factor levels) are matched by name when the
#'   data are attached; otherwise the first element is regime 0 (S = 0). The
#'   names are the regime labels used in parameter names; unnamed lists get
#'   `regime_0` and `regime_1`.
#' @param regimes Number of regimes; must equal `length(outcomes)`. Only 2
#'   in Generation 1.
#' @param model Model type: `"esr"`.
#' @param selection_family Distribution of the selection disturbance:
#'   `"probit"`.
#' @param outcome_family Distribution of the outcome disturbances:
#'   `"gaussian"`.
#' @param dependence Dependence of the disturbances: `"gaussian"`.
#' @param family Outcome type (specification section 5.2): `NULL` or
#'   `"continuous"`.
#' @param identification `"auto"` (excluded variables detected from the
#'   formulas) or a character vector of variables declared as exclusion
#'   restrictions. Declared variables must appear in the selection equation
#'   and in no outcome equation.
#' @return An object of class `switch_spec`.
#' @seealso [distribution()]
#' @references
#' Lokshin, M. and Sajaia, Z. (2004). Maximum likelihood estimation of
#' endogenous switching regression models. *The Stata Journal*, 4(3),
#' 282--289. \doi{10.1177/1536867X0400400306}
#' @examples
#' spec <- switch_model(
#'   selection = adopt ~ x1 + z1,
#'   outcomes = list(regime_0 = y ~ x1 + x2, regime_1 = y ~ x1 + x2)
#' )
#' spec
#'
#' ## later generations are named in the error
#' try(switch_model(adopt ~ x1 + z1,
#'                  list(y ~ x1, y ~ x1), dependence = "clayton"))
#' @export
switch_model <- function(selection, outcomes, regimes = 2L, model = "esr",
                         selection_family = "probit",
                         outcome_family = "gaussian", dependence = "gaussian",
                         family = NULL, identification = "auto") {
  cl <- match.call()
  se_check_choice("model", model)
  se_check_choice("selection_family", selection_family)
  se_check_choice("outcome_family", outcome_family)
  se_check_choice("dependence", dependence)
  if (!is.null(family)) se_check_choice("family", family)

  if (!inherits(selection, "formula") || length(selection) != 3L) {
    se_abort("'selection' must be a two-sided formula, e.g. regime ~ z1 + z2",
             "argument")
  }
  if (inherits(outcomes, "formula") || !is.list(outcomes)) {
    se_abort("'outcomes' must be a list of formulas, one per regime",
             "argument")
  }
  two_sided <- vapply(outcomes, function(f)
    inherits(f, "formula") && length(f) == 3L, logical(1))
  if (!length(outcomes) || !all(two_sided)) {
    se_abort("every element of 'outcomes' must be a two-sided formula",
             "argument")
  }
  if (!is.numeric(regimes) || length(regimes) != 1L || is.na(regimes) ||
      regimes != round(regimes) || regimes < 2) {
    se_abort("'regimes' must be a whole number of at least 2", "argument")
  }
  if (regimes != length(outcomes)) {
    se_abort(sprintf(
      "'regimes' (%d) must equal the number of outcome equations (%d)",
      as.integer(regimes), length(outcomes)), "argument")
  }
  if (regimes > 2) {
    se_abort(sprintf(paste0(
      "models with %d regimes are planned for Generation 2 (versions %s) and ",
      "are not available in SwitchEconometrics %s"), as.integer(regimes),
      se_generations[["2"]], se_version()), "unsupported", generation = 2L)
  }

  nm <- names(outcomes)
  named <- !is.null(nm)
  if (named && (any(is.na(nm)) || !all(nzchar(nm)))) {
    se_abort("name either all outcome equations or none", "argument")
  }
  if (!named) nm <- paste0("regime_", seq_along(outcomes) - 1L)
  if (anyDuplicated(nm)) se_abort("outcome equation names must be unique",
                                  "argument")
  if ("selection" %in% nm) {
    se_abort("'selection' is reserved and cannot name an outcome equation",
             "argument")
  }
  if (any(grepl(":", nm, fixed = TRUE))) {
    se_abort("outcome equation names cannot contain ':'", "argument")
  }
  names(outcomes) <- nm

  rhs_vars <- function(f) all.vars(f[[3L]])
  all_f <- c(list(selection), outcomes)
  if (any(vapply(all_f, function(f) "." %in% all.vars(f), logical(1)))) {
    se_abort("'.' in formulas is not supported; list the variables explicitly",
             "argument")
  }
  sel_resp <- all.vars(selection[[2L]])
  rhs_sel <- rhs_vars(selection)
  rhs_out <- lapply(outcomes, rhs_vars)
  for (lab in nm) {
    bad <- intersect(sel_resp, rhs_out[[lab]])
    if (length(bad)) {
      se_abort(sprintf(paste0(
        "the regime indicator '%s' cannot be a regressor in outcome ",
        "equation '%s'"), bad[1L], lab), "argument")
    }
  }
  exclusions <- lapply(rhs_out, function(v) setdiff(rhs_sel, v))

  if (identical(identification, "auto")) {
    ident <- list(mode = "auto", declared = NULL)
  } else if (is.character(identification) && length(identification) &&
             !anyNA(identification)) {
    miss <- setdiff(identification, rhs_sel)
    if (length(miss)) {
      se_abort(sprintf(
        "declared exclusion(s) %s do not appear in the selection equation",
        paste(miss, collapse = ", ")), "argument")
    }
    for (lab in nm) {
      bad <- intersect(identification, rhs_out[[lab]])
      if (length(bad)) {
        se_abort(sprintf(
          "declared exclusion '%s' appears in outcome equation '%s'",
          bad[1L], lab), "argument")
      }
    }
    ident <- list(mode = "declared", declared = identification)
  } else {
    se_abort("'identification' must be \"auto\" or a character vector of variable names",
             "argument")
  }
  ident$exclusions <- exclusions

  structure(list(
    model = model,
    regimes = nm,
    regime_names_given = named,
    selection = list(formula = selection, family = selection_family),
    outcomes = lapply(outcomes, function(f)
      list(formula = f, family = outcome_family)),
    observation = "switching",
    dependence = list(family = dependence, structure = "selection_pairs"),
    family = family %||% "continuous",
    panel = NULL,
    spatial = NULL,
    identification = ident,
    call = cl), class = "switch_spec")
}

#' @export
format.switch_spec <- function(x, ...) {
  lab <- c("Model", "Observation", "Selection", "Dependence", "Excluded",
           x$regimes)
  w <- max(nchar(lab)) + 2L
  pad <- function(s) formatC(paste0(s, ":"), width = -w)
  ex <- vapply(x$identification$exclusions, function(v)
    if (length(v)) paste(v, collapse = ", ") else "none", character(1))
  c("Switching model specification (SwitchEconometrics)",
    sprintf("  %s%s", pad("Model"),
            if (x$model == "esr") "esr (binary endogenous switching regression)"
            else x$model),
    sprintf("  %s%s", pad("Observation"), x$observation),
    sprintf("  %s%s   [%s]", pad("Selection"),
            se_deparse(x$selection$formula), x$selection$family),
    vapply(x$regimes, function(r) sprintf("  %s%s   [%s]", pad(r),
           se_deparse(x$outcomes[[r]]$formula), x$outcomes[[r]]$family),
           character(1)),
    sprintf("  %s%s (selection disturbance with each regime's outcome)",
            pad("Dependence"), x$dependence$family),
    sprintf("  %s%s", pad("Excluded"),
            paste(names(ex), ex, sep = ": ", collapse = " | ")))
}

#' @export
print.switch_spec <- function(x, ...) {
  cat(format(x), sep = "\n")
  if (any(lengths(x$identification$exclusions) == 0L)) {
    cat("  Note: an outcome equation has no excluded selection variable;",
        "identification of its rho\n        then rests on the normality",
        "assumption alone.\n")
  }
  invisible(x)
}
