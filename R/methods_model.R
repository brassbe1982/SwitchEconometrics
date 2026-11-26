## Model-frame, model-matrix and terms methods for switch_fit
## (API_SPECIFICATION.md s.4).

#' Model frames, design matrices and terms of a fitted switching model
#'
#' @param formula,object,x A `switch_fit`.
#' @param part `"selection"` or a regime label.
#' @param ... Not used.
#' @return `model.frame()`: the model frame of the estimation sample for the
#'   chosen equation; `model.matrix()`: its design matrix; `terms()`: its
#'   terms (without response).
#' @examples
#' fit <- switch_fit(
#'   digital_adoption ~ internet_access + management_quality + firm_size +
#'     owner_education,
#'   list(productivity ~ firm_size + capital + labour,
#'        productivity ~ firm_size + capital + labour), data = firms)
#' head(model.matrix(fit, "regime_1"))
#' terms(fit)
#' @name switch_fit-model
NULL

se_check_part <- function(x, part) {
  if (!is.character(part) || length(part) != 1L ||
      !part %in% c("selection", x$regimes)) {
    se_abort(sprintf("'part' must be \"selection\" or a regime label (%s)",
                     paste(x$regimes, collapse = ", ")), "argument")
  }
  part
}

#' @rdname switch_fit-model
#' @export
model.frame.switch_fit <- function(formula, part = "selection", ...) {
  part <- se_check_part(formula, part)
  if (is.null(formula$data)) {
    se_abort("the fit holds no data; refit with keep_data = TRUE", "argument")
  }
  formula$data$frames[[part]]
}

#' @rdname switch_fit-model
#' @export
model.matrix.switch_fit <- function(object, part = "selection", ...) {
  part <- se_check_part(object, part)
  if (is.null(object$data)) {
    se_abort("the fit holds no data; refit with keep_data = TRUE", "argument")
  }
  if (part == "selection") object$data$Z else object$data$X[[part]]
}

#' @rdname switch_fit-model
#' @export
terms.switch_fit <- function(x, part = "selection", ...) {
  part <- se_check_part(x, part)
  if (part == "selection") x$terms$selection else x$terms$outcomes[[part]]
}
