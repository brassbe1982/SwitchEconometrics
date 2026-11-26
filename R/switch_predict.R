## Layer 7: predictions (API_SPECIFICATION.md s.2; TREATMENT_EFFECTS.md
## s.2 and s.6).

## Design matrices for new data, built with the fit's terms, factor levels
## and contrasts. Rows with missing values give NA predictions.
se_newdata_design <- function(object, newdata) {
  if (!is.data.frame(newdata)) se_abort("'newdata' must be a data frame", "data")
  mk <- function(tt, xlev, contr, what) {
    mf <- tryCatch(stats::model.frame(tt, newdata, na.action = stats::na.pass,
                                      xlev = xlev),
                   error = function(e) se_abort(sprintf(
                     "cannot evaluate the %s variables in 'newdata': %s", what,
                     conditionMessage(e)), "data"))
    list(mf = mf, ok = stats::complete.cases(mf), contr = contr, tt = tt)
  }
  parts <- c(list(selection = mk(object$terms$selection,
                                 object$xlevels$selection,
                                 object$contrasts$selection, "selection")),
             stats::setNames(lapply(object$regimes, function(l)
               mk(object$terms$outcomes[[l]], object$xlevels[[l]],
                  object$contrasts[[l]], sprintf("'%s' outcome", l))),
               object$regimes))
  ok <- Reduce(`&`, lapply(parts, `[[`, "ok"))
  mm <- function(p) {
    if (!any(ok)) return(NULL)
    m <- stats::model.matrix(p$tt, p$mf[ok, , drop = FALSE],
                             contrasts.arg = p$contr)
    dimnames(m) <- list(NULL, colnames(m))
    m
  }
  list(Z = mm(parts$selection),
       X = stats::setNames(lapply(object$regimes, function(l) mm(parts[[l]])),
                           object$regimes),
       ok = ok, n = nrow(newdata))
}

## Regime indicator in new data (for type = "observed"), coded as in the fit.
se_newdata_regime <- function(object, newdata) {
  f <- object$spec$selection$formula
  s <- tryCatch(eval(f[[2L]], newdata, environment(f)), error = function(e)
    se_abort("type = \"observed\" needs the regime indicator in 'newdata'",
             "data"))
  if (is.logical(s)) return(as.integer(s))
  if (is.numeric(s)) return(ifelse(s %in% c(0, 1), as.integer(s), NA_integer_))
  vals <- object$regime_values %||% c("0", "1")
  match(as.character(s), vals) - 1L
}

#' Predictions from a fitted switching model
#'
#' | `type` | Prediction |
#' | --- | --- |
#' | `"probability"` | \eqn{P(S = 1 \mid z) = \Phi(z'\gamma)} |
#' | `"selection_index"` | \eqn{z'\gamma} |
#' | `"linear"` | \eqn{x_j'\beta_j} for both regimes (\eqn{E[Y(j) \mid x]}); matrix with one column per regime |
#' | `"conditional"` | the four conditional expectations `EY1_S1`, `EY1_S0`, `EY0_S1`, `EY0_S0` (matrix) |
#' | `"observed"` | the conditional expectation in the observed regime (needs the regime indicator) |
#' | `"unconditional"` | \eqn{E[Y \mid x, z] = \Phi(w)x_1'\beta_1 + (1-\Phi(w))x_0'\beta_0 + (\sigma_1\rho_1 - \sigma_0\rho_0)\phi(w)} |
#'
#' `EY1_S0` is the expected outcome under regime 1 for units observed in
#' regime 0, a counterfactual. With `se = TRUE`, delta-method standard errors
#' are returned. `fitted()` returns the in-sample `"observed"` predictions
#' and `residuals()` the differences between the outcome and its conditional
#' mean in the observed regime (`"response"`), optionally divided by the
#' conditional standard deviation
#' \eqn{\sigma_j\sqrt{1 - \rho_j^2\delta_j(w)}} (`"pearson"`).
#'
#' @param object A `switch_fit`.
#' @param newdata Optional data frame; by default the estimation sample (the
#'   fit must keep its data).
#' @param type Prediction type (see table).
#' @param se Return delta-method standard errors.
#' @param ... Not used.
#' @return A vector or matrix of predictions with `NA` for rows of `newdata`
#'   with missing values; with `se = TRUE` a list with `fit` and `se.fit`.
#' @examples
#' fit <- switch_fit(
#'   digital_adoption ~ internet_access + management_quality + firm_size +
#'     owner_education,
#'   list(productivity ~ firm_size + capital + labour,
#'        productivity ~ firm_size + capital + labour),
#'   data = firms)
#' head(switch_predict(fit, type = "conditional"))
#' switch_predict(fit, newdata = firms[1:3, ], type = "probability", se = TRUE)
#' @export
switch_predict <- function(object, newdata = NULL,
                           type = c("probability", "selection_index", "linear",
                                    "conditional", "observed", "unconditional"),
                           se = FALSE, ...) {
  if (!inherits(object, "switch_fit")) {
    se_abort("'object' must be a switch_fit", "argument")
  }
  type <- match.arg(type)
  reg <- object$regimes
  if (is.null(newdata)) {
    sd <- object$data
    if (is.null(sd)) {
      se_abort("no 'newdata' and the fit holds no data; refit with keep_data = TRUE",
               "argument")
    }
    Z <- sd$Z; X <- sd$X; ok <- rep(TRUE, sd$n); n <- sd$n
    S <- sd$S
  } else {
    des <- se_newdata_design(object, newdata)
    Z <- des$Z; X <- des$X; ok <- des$ok; n <- des$n
    S <- if (type == "observed") se_newdata_regime(object, newdata)[ok]
    if (type == "observed" && anyNA(S)) {
      se_abort("the regime indicator in 'newdata' has missing or invalid values",
               "data")
    }
  }
  map <- object$map
  ix <- se_psi_index(map, reg)
  psi <- se_psi_from_natural(object$coefficients, map, reg)
  if (!any(ok)) {
    se_abort("no complete rows in 'newdata'", "data")
  }
  cmp <- se_eff_components(psi, Z, X[[1L]], X[[2L]], ix, grad = se)
  w <- cmp$w
  P <- ix$P
  val <- switch(type,
    probability = stats::pnorm(w),
    selection_index = w,
    linear = stats::setNames(data.frame(cmp$xb0, cmp$xb1), reg),
    conditional = cmp$EY,
    observed = ifelse(S == 1L, cmp$EY[, "EY1_S1"], cmp$EY[, "EY0_S0"]),
    unconditional = stats::pnorm(w) * cmp$xb1 + stats::pnorm(-w) * cmp$xb0 +
      (cmp$th1 - cmp$th0) * stats::dnorm(w))
  if (type == "linear") val <- as.matrix(val)
  sev <- NULL
  if (se) {
    V <- se_psi_vcov(object)
    if (anyNA(V)) se_abort("the covariance matrix contains NA", "argument")
    sefun <- function(G) sqrt(pmax(rowSums((G %*% V) * G), 0))
    blank <- function() matrix(0, length(w), P)
    sev <- switch(type,
      probability = { G <- blank(); G[, ix$gamma] <- stats::dnorm(w) * Z; sefun(G) },
      selection_index = { G <- blank(); G[, ix$gamma] <- Z; sefun(G) },
      linear = {
        G0 <- blank(); G0[, ix$beta0] <- X[[1L]]
        G1 <- blank(); G1[, ix$beta1] <- X[[2L]]
        m <- cbind(sefun(G0), sefun(G1)); colnames(m) <- reg; m
      },
      conditional = {
        m <- vapply(colnames(cmp$EY), function(k) sefun(cmp$grad[[k]]),
                    numeric(length(w)))
        matrix(m, ncol = 4L, dimnames = list(NULL, colnames(cmp$EY)))
      },
      observed = {
        G <- cmp$grad$EY0_S0
        G[S == 1L, ] <- cmp$grad$EY1_S1[S == 1L, ]
        sefun(G)
      },
      unconditional = {
        G <- blank()
        Pw <- stats::pnorm(w); f <- stats::dnorm(w)
        G[, ix$gamma] <- (f * ((cmp$xb1 - cmp$xb0) - (cmp$th1 - cmp$th0) * w)) * Z
        G[, ix$beta1] <- Pw * X[[2L]]
        G[, ix$beta0] <- (1 - Pw) * X[[1L]]
        G[, ix$theta1] <- f
        G[, ix$theta0] <- -f
        sefun(G)
      })
  }
  expand <- function(v) {
    if (all(ok)) return(v)
    if (is.matrix(v)) {
      out <- matrix(NA_real_, n, ncol(v), dimnames = list(NULL, colnames(v)))
      out[ok, ] <- v
    } else {
      out <- rep(NA_real_, n)
      out[ok] <- v
    }
    out
  }
  val <- expand(val)
  if (se) list(fit = val, se.fit = expand(sev)) else val
}

#' @rdname switch_predict
#' @export
predict.switch_fit <- function(object, newdata = NULL,
                               type = c("probability", "selection_index",
                                        "linear", "conditional", "observed",
                                        "unconditional"),
                               se = FALSE, ...) {
  switch_predict(object, newdata = newdata, type = match.arg(type), se = se)
}

#' @rdname switch_predict
#' @export
fitted.switch_fit <- function(object, type = "observed", ...) {
  switch_predict(object, type = type)
}

#' @rdname switch_predict
#' @export
residuals.switch_fit <- function(object, type = c("response", "pearson"), ...) {
  type <- match.arg(type)
  sd <- object$data
  if (is.null(sd)) se_abort("residuals need the data; refit with keep_data = TRUE",
                            "argument")
  r <- sd$y - switch_predict(object, type = "observed")
  if (type == "response") return(r)
  map <- object$map
  th <- object$coefficients
  w <- drop(sd$Z %*% th[map$index$gamma])
  s <- numeric(sd$n)
  for (k in 1:2) {
    lab <- sd$regimes[k]
    sel <- sd$S == k - 1L
    sig <- th[[map$index$sigma[[lab]]]]
    rho <- th[[map$index$rho[[lab]]]]
    dk <- if (k == 2L) se_d1(w[sel]) else se_d0(w[sel])
    v <- sig^2 * (1 - rho^2 * dk)
    s[sel] <- ifelse(v > 0, sqrt(v), NA_real_)
  }
  r / s
}
