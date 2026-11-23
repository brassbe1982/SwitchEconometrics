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
lik_<model>(theta_w, data, map, deriv = 0L, weights = data$weights)
# returns list(ll_i = numeric n,                    # always, unweighted
#              score_i = n x p matrix,              # if deriv >= 1, unweighted
#              hessian = p x p matrix)              # if deriv == 2, WEIGHTED sum
```

This is on the working scale. Per-observation Hessians are never stored, so
the engine applies the weights to the Hessian. `ll_i` and `score_i` stay
unweighted so that callers can form OPG and sandwich estimators.

The model-independent interface of specification section 5.4 sits on top
(`R/lik_interface.R`, version 0.3.0):
- `loglik_switch()`: weighted total, gradient and Hessian; the function the
  estimators call.
- `loglik_observation()`: per-observation decomposition into the probability
  of the regime, the marginal and conditional outcome densities, the
  conditional selection probability and the dependence correction.
- `loglik_joint()`, `loglik_selection()`, `loglik_outcome()`.

The engine is chosen from the model stored in the data object
(`se_lik_engine()`). G1 provides `lik_esr_gaussian`.

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

## 7. Generation 2 (draft for the G2 gate, 23 November 2026)

Sections 1-6 are unchanged. G2 uses the extension points of section 5; no
layer contract changes, and `esr()` keeps the G1 code path.

### 7.1 Protecting the G1 results

Before any shared file is edited (WP2.1, first step): a test file
`tests/testthat/test-g1-frozen.R` with the 1.0.0 results on `firms`
(estimates, log-likelihood, standard errors of the four covariance types,
two-step results, effects), compared at 1e-8 at every later version. The
G1 test suite and the Monte Carlo smoke regression
(`runs/mc_g1_0.8.1_smoke`, tolerance 1e-6) run unchanged.

### 7.2 Planned files

```
R/wrappers.R              heckman(), treatment(), tobit5(), multinomial_switch(),
                          multiswitch()                                 (WP2.1-2.5)
R/lik_heckman_gaussian.R  Heckman: Gaussian block + probit term         (WP2.1)
R/par_map.R               + linear-restriction matrix (treatment), blocks for
                          thresholds, selection covariance, psi          (WP2.1-2.3)
R/sel_mnl.R               multinomial logit: probabilities, derivatives,
                          first-step ML                                  (WP2.2)
R/lik_lee.R               Lee likelihood for any choice-probability function
                          (score, Hessian for MNL)                       (WP2.2)
R/est_two_step_multi.R    Lee, DMF, BFG and region two-step estimators   (WP2.2-2.3)
R/num_mvnorm.R            bivariate/trivariate normal cdf, rectangle
                          probabilities, Plackett derivatives, Halton, GHK (WP2.3)
R/num_truncated.R         truncated normal means and covariances         (WP2.3)
R/num_quadrature.R        Gauss-Legendre nodes; BFG m(P); Lee moments    (WP2.2, 2.4)
R/sel_region.R            region definitions (A_j, limits) for MNP, ordered,
                          sequential, multivariate                       (WP2.3-2.5)
R/lik_region_gaussian.R   the Gaussian region engine, K >= 1 outcomes    (WP2.3, 2.5)
R/est_selection.R         first-step ML of selection systems (no outcomes) (WP2.3)
R/lik_ordered_gaussian.R  ordered probit selection, closed forms         (WP2.4)
R/sel_nested_logit.R      nested logit probabilities and derivatives     (WP2.4)
R/eff_multi.R             J x J conditional expectations, pairwise effects,
                          scenarios                                      (WP2.2-2.5)
R/inf_identification.R    + I4b, I12 and the G2 versions of I1-I11       (each WP)
R/sim_simulate.R          + simulation from every G2 model               (each WP)
R/data.R                  + one simulated multi-regime dataset (documented
                          data-generating process; name fixed in WP2.2)
```

No `src/` directory is planned. Compiled code is added only after profiling
and the owner's decision (D10).

### 7.3 Changes to the internal objects

| Object | G2 additions |
| --- | --- |
| `switch_spec` | `model` values of API_SPECIFICATION.md s.5; `observation` in `"switching"`, `"selection"`, `"treatment"`; `selection` becomes a list with `family`, `formulas` (one or several), `base`, `nests`, `covariance`, `stage_dependence`; `outcomes[[regime]]` may hold several equations; `shift` (treatment) |
| `switch_data` | `S` integer in $1..J$ with `regimes` labels; `Z` a list of selection designs; `y` and `X` lists by regime and outcome; `at_risk` (sequential); `y` is `NA` where not observed |
| `se_parmap` | blocks `gamma[[k]]`, `cut`, `sel_sd`, `sel_cpc`, `beta[[j]][[k]]`, `sigma`, `dep[[j]]`; `restriction` (linear map to an engine's parameters); `order` of the selection components |
| Likelihood contract | unchanged: `lik_<model>(theta_w, data, map, deriv, weights)`; `deriv = 2` returns the Hessian with `attr(, "type")` `"analytic"` or `"score_difference"`; engines without Hessian support return `NULL` and the optimiser uses BFGS/BHHH |
| `switch_estimate` | `probability` (method, draws, error estimate); `correction` (two-step type) |
| `switch_fit$record` | the additions of NUMERICAL_METHODS.md s.7.6 |

`se_lik_engine()` dispatches on `(model, selection family)`:

| Model | Engine |
| --- | --- |
| `esr`, `tobit5` | `lik_esr_gaussian` (G1, unchanged) |
| `treatment` | `lik_esr_gaussian` through the restriction map |
| `heckman` | `lik_heckman_gaussian` |
| `multinomial_esr` with `multinomial_logit` or `nested_logit` | `lik_lee` |
| `multinomial_esr` with `multinomial_probit`; `sequential_esr`; `multivariate_esr` | `lik_region_gaussian` |
| `ordered_esr` | `lik_ordered_gaussian` (tested against `lik_region_gaussian`) |

### 7.4 Tests added per work package

Reference implementations in `tests/testthat/helper-reference-g2.R`, taken
from `verify_math_g2.R`; package against reference at 1e-10; derivative
tests; the nesting tests of G2 acceptance criterion 2 (region engine with
$J = 2$ against the frozen G1 engine; Heckman identity; treatment
restriction); recovery tests; frozen references for each new model from its
first version.
