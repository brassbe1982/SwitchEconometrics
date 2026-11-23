## Layer 3: model-independent likelihood interface (specification s.5.4).
## Every function takes the full working parameter vector, a switch_data
## object and its parameter map. Estimators, covariance estimators and
## diagnostics only use these functions; the engine is chosen from the model
## stored in the data object.

se_lik_engine <- function(sd) {
  key <- paste(sd$model, sd$selection_family, sd$outcome_family,
               sd$dependence, sep = "/")
  switch(key,
    "esr/probit/gaussian/gaussian" = ,
    "tobit5/probit/gaussian/gaussian" = list(
      lik = lik_esr_gaussian, components = lik_esr_gaussian_components),
    "heckman/probit/gaussian/gaussian" = list(
      lik = lik_heckman_gaussian,
      components = lik_heckman_gaussian_components),
    "treatment/probit/gaussian/gaussian" = list(
      lik = lik_treatment_gaussian,
      components = lik_treatment_gaussian_components),
    se_abort(sprintf("no likelihood engine for model %s", key),
             "unsupported"))
}

## Total (weighted) log-likelihood, gradient and Hessian on the working scale.
## deriv = 0: loglik; 1: + gradient; 2: + hessian. The per-observation
## (unweighted) contributions and scores are returned as ll_i and score_i.
loglik_switch <- function(theta_w, sd, map, deriv = 0L) {
  eng <- se_lik_engine(sd)
  L <- eng$lik(theta_w, sd, map, deriv = deriv, weights = sd$weights)
  om <- sd$weights %||% rep(1, sd$n)
  out <- list(loglik = sum(om * L$ll_i), ll_i = L$ll_i)
  if (deriv >= 1L) {
    out$gradient <- colSums(om * L$score_i)
    out$score_i <- L$score_i
  }
  if (deriv >= 2L) out$hessian <- L$hessian
  out
}

## Per-observation decomposition (data frame): regime, y, log P(S = j),
## log f_j(y) (marginal outcome density), log P(S = j | eps_j),
## loglik = log L_i, log f(y | S = j) (conditional density) and the
## dependence correction log P(S = j | eps_j) - log P(S = j).
## Identities: loglik = log_prob_regime + log_density_conditional
##                    = log_density_outcome + log_selection_conditional.
loglik_observation <- function(theta_w, sd, map) {
  se_lik_engine(sd)$components(theta_w, sd, map)
}

## log L_i, the joint density of the observed regime and outcome.
loglik_joint <- function(theta_w, sd, map) {
  se_lik_engine(sd)$lik(theta_w, sd, map, deriv = 0L)$ll_i
}

## log P(S_i = s_i | z_i) (conditional = FALSE) or
## log P(S_i = s_i | eps_i, z_i) (conditional = TRUE).
loglik_selection <- function(theta_w, sd, map, conditional = FALSE) {
  cmp <- loglik_observation(theta_w, sd, map)
  if (conditional) cmp$log_selection_conditional else cmp$log_prob_regime
}

## log f_j(y_i) (conditional = FALSE, marginal regime-j density) or
## log f(y_i | S_i = j) (conditional = TRUE).
loglik_outcome <- function(theta_w, sd, map, conditional = FALSE) {
  cmp <- loglik_observation(theta_w, sd, map)
  if (conditional) cmp$log_density_conditional else cmp$log_density_outcome
}
