# Software architecture

Status: WP1.1, 22 November 2026. Specification sections 5 and 7; plan
decisions D1, D2 and D10.

## 1. Seven layers

The layers communicate only through the internal objects of section 3, so
that a new copula, margin or selection mechanism is added in one layer
without rewriting the estimators (specification section 5).

| Layer | Responsibility | File prefix in `R/` | First version |
| --- | --- | --- | --- |
| 1 Model specification | `switch_model()`, the `switch_spec` object, formula and data handling | `spec_`, plus `switch_model.R` | 0.2.0 |
| 2 Distributions | margin objects (`se_margin`), later copula objects (`se_copula`) | `dist_`, later `cop_` | 0.2.0 (Gaussian), 2.0.0 (copulas) |
| 3 Likelihood | per-observation log-likelihood, score, Hessian for each model | `lik_` | 0.3.0 |
| 4 Estimation | FIML, two-step, later control function, simulated ML, robust, Bayesian | `est_` | 0.4.0 |
| 5 Parameters | transformations, parameter maps, starting values, Jacobians | `par_` | 0.2.0 |
| 6 Inference and diagnostics | covariance, bootstrap, tests, diagnostics, identification report | `inf_` | 0.5.0 |
| 7 Interpretation | conditional expectations, effects, predictions, counterfactuals | `eff_` | 0.6.0 |
| Cross-cutting | user-facing API (`switch_*.R`), S3 methods (`methods_`), simulation (`sim_`), wrappers, data, utilities | | 0.2.0 onward |

R ignores subfolders of `R/`, so the specification's folder layout
(section 7) becomes these file-name prefixes (plan decision D2).

## 2. Planned G1 files

```
R/SwitchEconometrics-package.R   package documentation, imports
R/switch_model.R                 switch_model()                     (L1)
R/spec_data.R                    build_switch_data(): model frames, NA report
R/spec_check.R                   validation of switch_spec objects
R/dist_interface.R               se_margin constructor and contract (L2)
R/dist_gaussian.R                Gaussian margin
R/par_transforms.R               se_transform objects (identity, log, atanh, log-shift)
R/par_map.R                      parameter maps, packing, Jacobians, fixed parameters
R/par_start.R                    starting values
R/lik_utils.R                    stable log Phi, Mills ratio, delta (continued fraction)
R/lik_esr_gaussian.R             binary Gaussian ESR: ll_i, score_i, Hessian (L3)
R/est_optimizer.R                optimiser wrapper (maxLik NR/BFGS/BHHH, optim fallback) (L4)
R/est_fiml.R                     FIML driver with multistart
R/est_two_step.R                 Heckman-Lee two-step with corrected covariance
R/inf_vcov.R                     hessian / opg / sandwich / cluster, delta method (L6)
R/inf_bootstrap.R                nonparametric and parametric bootstrap engine
R/inf_tests.R                    LR and Wald tests
R/inf_diagnostics.R              computational and statistical diagnostics
R/inf_identification.R           identification checks I1-I11
R/eff_conditional.R              the four conditional expectations (L7)
R/eff_treatment.R                ATT, ATU, ATE, TH, BH1, BH0 with gradients
R/eff_counterfactual.R           scenarios and policy changes
R/sim_simulate.R                 data generation from a spec or a fit
R/switch_fit.R  switch_validate.R  switch_effects.R  switch_predict.R
R/switch_counterfactual.R  switch_simulate.R  switch_bootstrap.R
R/switch_compare.R  switch_diagnostics.R  switch_test.R   (user-facing API)
R/switch_control.R               switch_control()
R/methods_switch_fit.R           print, summary, coef, vcov, logLik, nobs, fitted,
                                 residuals, predict, simulate, confint, anova,
                                 update, model.frame, model.matrix, terms
R/methods_results.R              print/format methods of result objects
R/wrappers.R                     esr() (later heckman(), treatment(), tobit5(), ...)
R/data.R                         documentation of the simulated dataset `firms`
R/utils.R                        conditions, RNG handling, small helpers
```

## 3. Internal objects (the contracts between layers)

**`switch_spec`** (Layer 1). A list of class `switch_spec`:
- `model`: `"esr"` in G1.
- `selection`: formula, family `"probit"`.
- `outcomes`: a named list, one element per regime, each with a formula and
  family `"gaussian"`.
- `regimes`: labels.
- `observation`: `"switching"`.
- `dependence`: family `"gaussian"`, structure `"selection_pairs"`.
- `panel`, `spatial`: `NULL` in G1.
- `identification`: user-declared exclusions, or `"auto"`.
- `call`.

It contains no data. `spec_check()` validates it.

**`switch_data`** (internal). Built by `build_switch_data(spec, data, weights,
cluster, subset, missing)`. Fields:
- the integer regime vector `S`, the outcome `y`, and the design matrices
  `Z`, `X[[regime]]`;
- weights and cluster ids;
- `terms` and `xlevels` for `predict()`;
- the row index of the estimation sample;
- `na_report`: the rows removed and the variables responsible.

Rows are never removed without the report and a message (specification
section 14.1).

**`se_margin`** (Layer 2). A list:
- `name`, `parameters` (names, transformations, bounds);
- functions `d`, `p`, `q`, `r`, `logd`, `logp`;
- derivatives where available, and `valid()`.

The `se_copula` object (G3) mirrors this, with cdf, pdf, h-functions and
their inverses, derivatives, Kendall's tau and validity.

**`se_transform`** (Layer 5): `to_working()`, `to_natural()`, `jacobian()`
(d natural / d working), `d2()`.

**`se_parmap`** (Layer 5):
- parameter names on both scales;
- an index per block (`gamma`, `beta[[regime]]`, `sigma[[regime]]`,
  `rho[[regime]]`);
- a transformation per element;
- a fixed-value mask, so that restricted models (for example $\rho = 0$ for
  the LR test) reuse the same engine.

**Likelihood engine contract** (Layer 3). Every model implements

```r
lik_<model>(theta_w, data, map, deriv = 0L)
# returns list(ll_i = numeric n,                    # always
#              score_i = n x p matrix,              # if deriv >= 1
#              hessian = p x p matrix)              # if deriv == 2
```

on the working scale, with weights applied by the caller. Estimators,
covariance estimators and diagnostics only call this interface. G1 provides
`lik_esr_gaussian`.

**`switch_estimate`** (Layer 4, internal). The common result of every
estimator:
- working and natural coefficients;
- the working covariance and its type;
- the log-likelihood (`NA` for two-step);
- the convergence list: code, message, iterations, gradient norm, optimiser,
  time;
- the starts table;
- for two-step, the generated regressors and the joint covariance.

**`switch_fit`** (user-facing; fields in API_SPECIFICATION.md section 3) wraps
the estimate with the specification, data summary, diagnostics,
identification report and reproducibility record.

## 4. Data flow

```
switch_fit(...)
  -> switch_model() / spec_check()                  L1
  -> build_switch_data()                            L1
  -> par_map(), par_start() (two-step)              L5, L4
  -> est_fiml() -> est_optimizer() -> lik_esr_gaussian()   L4 -> L3
  -> inf_vcov(), inf_diagnostics(), inf_identification()   L6
  -> new_switch_fit()
switch_effects(fit) / predict(fit) / switch_counterfactual(fit)   L7
switch_bootstrap(fit) -> refits through est_*()                   L6
```

## 5. Extension points

| Future addition | Where it plugs in |
| --- | --- |
| New outcome margin (G3, G4) | a new `dist_*.R` implementing the `se_margin` contract; likelihoods that use margins generically need no change |
| New copula family (G3) | a new `cop_*.R` implementing `se_copula` |
| New selection mechanism (G2) | `sel_*.R` (selection probability given the outcome disturbances) plus a likelihood assembling it |
| New observation mechanism (G2, G4) | a branch in the likelihood assembly keyed on `spec$observation` |
| New estimator (control function, robust, Bayesian) | `est_*.R` returning a `switch_estimate`; `method =` dispatch in `switch_fit()` |
| Panel and spatial (G5, G6) | `pan_*.R`, `spa_*.R` handling the integration over $\mathcal H$ around the cross-sectional contributions |
| C++ kernels (after profiling) | `src/` with R fallbacks of identical output, tested against each other |

## 6. S3 classes

| Class | Created by |
| --- | --- |
| `switch_spec` | `switch_model()` |
| `switch_fit` | `switch_fit()`, `esr()` |
| `switch_effects` | `switch_effects()` |
| `switch_counterfactual` | `switch_counterfactual()` |
| `switch_validation` | `switch_validate()` |
| `switch_diagnostics` | `switch_diagnostics()` |
| `switch_bootstrap` | `switch_bootstrap()` |
| `switch_comparison` | `switch_compare()` |
| `switch_test` | `switch_test()` |

Every class has `print` and `format` methods. Result objects also have
`as.data.frame` methods for tables.
