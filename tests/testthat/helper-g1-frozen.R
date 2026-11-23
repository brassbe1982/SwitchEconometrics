## Generation 1 results that must not change (SOFTWARE_ARCHITECTURE.md s.7.1).
## The same function produced tests/testthat/fixtures/g1_frozen_1.0.0.rds with
## the released version 1.0.0 (data-raw/g1_frozen.R) and is rerun by
## test-g1-frozen.R at every later version.
g1_frozen_results <- function() {
  sel <- digital_adoption ~ internet_access + management_quality + firm_size +
    owner_education
  out <- list(regime_0 = productivity ~ firm_size + capital + labour,
              regime_1 = productivity ~ firm_size + capital + labour)
  fit <- esr(sel, out, data = firms)
  res <- list(
    coef = coef(fit), loglik = fit$loglik,
    coef_working = fit$coef_working,
    gradient_max = fit$convergence$gradient_max,
    code = fit$convergence$code)
  for (v in c("hessian", "opg", "sandwich")) {
    f <- switch_fit(sel, out, data = firms, vcov = v)
    res[[paste0("se_", v)]] <- sqrt(diag(vcov(f)))
  }
  f <- switch_fit(sel, out, data = firms, cluster = ~ region)
  res$se_cluster <- sqrt(diag(vcov(f)))
  ## likelihood, score and Hessian at a fixed point (no optimiser involved)
  th0 <- fit$coef_working * 0.9 + 0.05
  L <- SwitchEconometrics:::loglik_switch(th0, fit$data, fit$map, deriv = 2L)
  res$fixed <- list(theta = th0, loglik = L$loglik, gradient = L$gradient,
                    hessian = L$hessian, ll_head = L$ll_i[1:10])
  ## two-step
  for (v in c("hessian", "sandwich")) {
    ts <- switch_fit(sel, out, data = firms, method = "two_step", vcov = v)
    res[[paste0("ts_coef_", v)]] <- coef(ts)
    res[[paste0("ts_se_", v)]] <- sqrt(diag(vcov(ts)))
  }
  ## effects, predictions, counterfactual
  eff <- switch_effects(fit)
  res$effects <- eff$table[, c("effect", "estimate", "std_error", "lower",
                               "upper")]
  res$effects_by <- switch_effects(fit, effects = "ATT", by = ~ region,
                                   data = firms)$table[, c("group", "estimate",
                                                           "std_error")]
  for (ty in c("probability", "selection_index", "linear", "conditional",
               "observed", "unconditional")) {
    p <- switch_predict(fit, type = ty)
    res[[paste0("pred_", ty)]] <- if (is.data.frame(p) || is.matrix(p))
      as.matrix(p[1:25, , drop = FALSE]) else p[1:25]
  }
  res
}
