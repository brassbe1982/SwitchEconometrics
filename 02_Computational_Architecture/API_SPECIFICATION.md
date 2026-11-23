# API specification (Generation 1)

Status: WP1.1, 22 November 2026. Contracts for the G1 public functions.
Specification sections 6 and 10.3; plan decision D4. Later generations
extend the argument values (for example `model = "multinomial_esr"`) without
changing these signatures.

## 1. Conventions

- **Regimes.** The selection response may be logical, 0/1 numeric, or a
  factor with two levels (the second level is regime 1). The `outcomes` list
  has length 2. If its names match the regime values (`"0"`/`"1"`,
  `"regime_0"`/`"regime_1"`, or the factor levels), elements are matched by
  name. Otherwise they are matched by position, first = regime 0 (with a
  message). Regime labels are the list names, or `regime_0`/`regime_1`.
- **Missing values** (`missing =`). Rows with missing values in $z$, $x_1$,
  $x_0$, weights or cluster, or in the outcome of their own regime, are
  removed with a message and recorded in `fit$na_report` (`"drop"`, the
  default), or cause an error (`"fail"`). The outcome may be `NA` in the
  regime where it is not observed.
- **Random numbers.** Functions that draw random numbers take `seed`. When
  `seed` is given, the global random-number state is saved and restored on
  exit.
- **Conditions.** Errors and warnings carry classes
  `switch_error_<topic>` and `switch_warning_<topic>`, so that they can be
  caught programmatically. No start-up messages.
- **Scales.** Results are on the natural scale unless `type = "working"` is
  requested.

## 2. Functions

### `switch_model()`

```r
switch_model(selection, outcomes, regimes = 2L, model = "esr",
             selection_family = "probit", outcome_family = "gaussian",
             dependence = "gaussian", family = NULL, identification = "auto")
```

Builds and validates a `switch_spec`. It holds no data. `family` is the
outcome type of specification section 5.2; in G1 only `"continuous"` is
accepted, and it implies `outcome_family = "gaussian"`. `identification`
accepts `"auto"` (exclusions detected from the formulas) or a list naming
the intended excluded variables, which are then checked.
G1 values: `regimes = 2`, `model = "esr"`, `selection_family = "probit"`,
`outcome_family = "gaussian"`, `dependence = "gaussian"`. Other values give
`switch_error_unsupported`, naming the generation that will add them.

### `distribution()` (implemented in 0.2.0)

```r
distribution(name, parameters = list())
```

Distribution engine of specification section 5.3. It returns an
`se_distribution` with `pdf`, `cdf`, `quantile`, `rng`, `logpdf` and
`logcdf` bound to the given natural parameters. 0.2.0 provides `"gaussian"`
(`location`, `scale`). Families of later generations give
`switch_error_unsupported`. Lifecycle: experimental until 1.0.0.

**Implementation status (0.2.0):**
- `switch_model()`: complete, including name-based regime matching and
  declared exclusions.
- The internal data builder `se_build_data()`: missing-value report, weights,
  cluster and subset in all three forms, regime coding, finiteness and rank
  checks.

### `switch_fit()` (implemented in 0.4.0)

**Implementation notes (0.4.0):**
- All four covariance types are implemented in 0.4.0, earlier than planned
  (WP1.5), because weighted and clustered fits need them.
- For the two-step method, `vcov = "hessian"` means the model-based
  first-stage-corrected formula, and `"sandwich"`/`"cluster"` mean the
  stacked M-estimation sandwich. `"opg"` is FIML-only.
- `esr()` is available from 0.4.0.
- Basic methods are available (`print`, `coef`, `vcov`, `logLik`, `nobs`).
  `summary()` and the other methods follow in 0.5.0-0.6.0.

```r
switch_fit(selection = NULL, outcomes = NULL, data, model = "esr",
           selection_family = "probit", outcome_family = "gaussian",
           dependence = "gaussian", method = "fiml", estimator = NULL,
           weights = NULL, cluster = NULL, subset = NULL,
           vcov = c("hessian", "opg", "sandwich", "cluster"),
           missing = c("drop", "fail"), control = switch_control(), ...)
```

- `model`: either a model-type string (with `selection` and `outcomes`
  formulas), or a `switch_spec` object, in which case `selection` and
  `outcomes` must be `NULL` (specification sections 6.2 and 10.3).
- `method`: `"fiml"` or `"two_step"` in G1. `estimator` is a synonym, and
  giving both with different values is an error.
- `weights`, `cluster`, `subset`: a one-sided formula, a column name, or a
  vector of length `nrow(data)`. `vcov = "cluster"` requires `cluster`.
  Weights default `vcov` to `"sandwich"`.
- Returns a `switch_fit` (section 3). An optimisation failure is never
  silent: the fit is returned with `convergence$code != 0` and a
  `switch_warning_convergence`. `summary()` repeats the warning.

### `switch_control()`

```r
switch_control(starts = 3L, maxit = 500L, gradient_tolerance = 1e-6,
               reltol = 1e-10, optimizer = c("NR", "BFGS", "BHHH", "optim"),
               start = NULL, perturb_sd = 0.5, seed = 20261122L,
               boundary_rho = 0.995, hessian_condition = 1e10,
               keep_data = TRUE, trace = 0L)
```

`starts = 1` uses only the two-step start. `start` takes natural-scale
starting values (a named vector or list). `keep_data` keeps the model frame,
which is needed by `predict()` without `newdata`, by the bootstrap and by
`update()`.

### `esr()`

```r
esr(selection, outcomes, data, method = "fiml", ...)
```

Equivalent to `switch_fit(selection, outcomes, data, model = "esr",
method = method, ...)`. This is the compatibility representation of the
classical ESR (specification section 10.1).

### `switch_validate()` (implemented in 0.5.0)

```r
switch_validate(model, data = NULL, weights = NULL, cluster = NULL,
                subset = NULL, ...)
```

Implemented in 0.5.0 with these details:
- Data or specification errors give a single `I0` error row instead of an
  exception.
- I10 is always a note (IDENTIFICATION.md section 6).
- `switch_test()`, `switch_bootstrap()` (statistics `"coef"`; `"effects"`
  in 0.6.0), `switch_diagnostics()`, `confint()` and `summary()` are also
  implemented in 0.5.0.

`model` is a `switch_spec` (then `data` is required) or a `switch_fit`.
Returns a `switch_validation`: the table of diagnostics I1-I11
([01_Econometric_Architecture/IDENTIFICATION.md](../01_Econometric_Architecture/IDENTIFICATION.md)
section 4), a classification of each parameter group, and the warnings.
`switch_fit()` runs it and stores the result in `fit$identification`.

### `switch_effects()` (implemented in 0.6.0)

**Implementation notes (0.6.0):**
- **`switch_effects()`:** also takes `data =`, so that `by` and `subset`
  can be given as formulas or column names.
- **`switch_counterfactual()`:** also takes `data =` and `level =`.
- **`switch_bootstrap()`:** `statistics = "effects"` is available.
- **`switch_simulate()`:** with a `switch_spec`, the first outcome equation
  is regime 0. Responses must be plain variable names. Potential outcomes
  are named `.potential_<regime>`.
- **`simulate.switch_fit()`:** returns columns `S_k` and `y_k`.

```r
switch_effects(object, effects = c("ATT", "ATU", "ATE", "TH", "BH"),
               se = c("delta", "bootstrap", "none"), level = 0.95,
               by = NULL, subset = NULL, individual = FALSE,
               R = 999L, seed = NULL, ...)
```

Returns a `switch_effects` object with:
- `table`: effect, estimate, std_error, statistic, p_value, lower, upper;
  `"BH"` expands to BH1 and BH0;
- `means`: the 2 x 2 table of conditional expectations with group sizes;
- `individual` (if requested): per-observation expectations and effects;
- `definitions`: the formula text for each effect;
- `by`: grouped tables when `by` is given.

### `switch_predict()` and `predict.switch_fit()`

```r
switch_predict(object, newdata = NULL,
               type = c("probability", "selection_index", "linear",
                        "conditional", "observed", "unconditional"),
               se = FALSE, ...)
```

| `type` | Returns |
| --- | --- |
| `probability` | $\Phi(w)$ |
| `selection_index` | $w$ |
| `linear` | $x_j'\beta_j$ for both regimes ($n \times 2$) |
| `conditional` | the four expectations ($n \times 4$, named `EY1_S1`, `EY1_S0`, `EY0_S1`, `EY0_S0`) |
| `observed` | the expectation in the observed regime (needs the regime in `newdata`) |
| `unconditional` | $E[Y \mid x, z]$ ([TREATMENT_EFFECTS.md](../01_Econometric_Architecture/TREATMENT_EFFECTS.md) section 6) |

`se = TRUE` adds delta-method standard errors. `predict.switch_fit` calls
`switch_predict`.

### `switch_counterfactual()`

```r
switch_counterfactual(object, scenario = c("all_regime_1", "all_regime_0",
                      "policy"), newdata = NULL, se = c("delta", "none"),
                      by = NULL, ...)
```

`"policy"` requires `newdata`: the data with modified selection covariates.
Returns per-observation baseline and scenario expectations, changes in
$P(S = 1)$, and averages with standard errors.

### `switch_simulate()` and `simulate.switch_fit()`

```r
switch_simulate(model, data, parameters, nsim = 1L, seed = NULL,
                potential_outcomes = FALSE, r10 = NULL)
```

Simulates the regime and the observed outcome for the covariates in `data`,
under natural-scale `parameters` (a named list or vector). Returns a data
frame, or a list of `nsim` data frames, with the regime and outcome columns
replaced. `potential_outcomes = TRUE` adds both potential outcomes. This
requires an assumption on $\operatorname{Corr}(\varepsilon_1, \varepsilon_0)$:
`r10`, defaulting to $\rho_1\rho_0$ and stated in an attribute.
`simulate(fit, nsim, seed)` simulates from the fitted model.

### `switch_bootstrap()`

```r
switch_bootstrap(object, R = 999L, type = c("nonparametric", "parametric"),
                 cluster = NULL, statistics = c("coef", "effects"),
                 cores = 1L, seed = NULL, ...)
```

Refits with the original method and control, using the original estimate as
the starting value. Returns a `switch_bootstrap`:
- the replicates;
- the failure count and the reasons;
- bootstrap standard errors and covariance;
- percentile and normal intervals.

`cores > 1` uses `parallel`. Examples and tests use at most 2 cores (CRAN
policy). Results are reproducible for a given `seed` and `cores`
(L'Ecuyer-CMRG streams).

### `switch_test()`

```r
switch_test(object, type = c("lr_independence", "wald_independence",
            "wald"), hypothesis = NULL, ...)
```

- `lr_independence` and `wald_independence` test $\rho_1 = \rho_0 = 0$.
- `wald` tests a general linear hypothesis given as a matrix and vector, or
  as a character vector such as `"regime_1:x1 = regime_0:x1"`.

Returns a `switch_test` with the statistic, df, p-value and a note on
interpretation ([LIKELIHOOD_DERIVATION.md](../01_Econometric_Architecture/LIKELIHOOD_DERIVATION.md)
section 8).

### `switch_compare()`

```r
switch_compare(..., test = c("lr", "none"))
```

Takes `switch_fit` objects (named). Returns a table of log-likelihood, number
of parameters, AIC, BIC, $\hat\rho_j$, ATT, ATU and ATE, plus LR tests for
nested pairs fitted on the same estimation sample.

### `switch_diagnostics()`

```r
switch_diagnostics(object, ...)
```

Returns two parts (specification section 15):
- **computational:** convergence code and message, iterations, gradient
  maximum and norm, Hessian eigenvalue range and condition number, boundary
  flags, multistart agreement, optimiser and time;
- **statistical:** the LR and Wald tests of independence, intervals for
  $\rho_j$, the identification summary and the non-identified parameters.

## 3. The `switch_fit` object

| Field | Content |
| --- | --- |
| `call`, `spec`, `model`, `method` | how the fit was requested |
| `coefficients` | natural-scale estimates (named). The order is by equation: selection coefficients; then the S = 0 regime (outcome coefficients, `sigma`, `rho`); then the S = 1 regime. This is the order of the parameter map `se_parmap_esr()`. The derivation documents write $\theta$ in a different but equivalent order. |
| `coef_working`, `vcov`, `vcov_working`, `vcov_type` | estimates and covariances |
| `loglik`, `npar`, `nobs`, `n_regime` | fit summaries (`loglik` is `NA` for two-step) |
| `two_step` | the two-step estimate (starting values for FIML; the main result for `method = "two_step"`) |
| `convergence` | code, message, iterations, gradient_max, gradient_norm, optimizer, time |
| `starts` | table: start id, origin, log-likelihood, convergence code, iterations, max \|Δparameter\| to the best |
| `diagnostics` | Hessian eigenvalues, condition number, boundary flags |
| `identification` | `switch_validation` |
| `data` | `switch_data` (if `keep_data`); `terms`, `xlevels` and `na_report` always |
| `weights`, `cluster` | as used |
| `record` | reproducibility record: date; R and package versions (SwitchEconometrics, maxLik, mvtnorm); platform; control settings; seed; starting values; optimiser; data dimensions and estimation-sample index; integration method (`"analytic"` in G1) (specification section 14.2) |

## 4. Methods for `switch_fit`

| Method | Notes |
| --- | --- |
| `print`, `summary` (`print.summary`) | coefficient tables by equation; $\sigma$ and $\rho$ with transformed-scale intervals; LR test of independence; convergence and identification warnings |
| `coef(object, type = c("natural", "working"), part = c("all", "selection", <regime>, "ancillary"))` | |
| `vcov(object, type = c("natural", "working"))` | |
| `logLik` | with `df` and `nobs` attributes, so that `AIC()` and `BIC()` work |
| `nobs` | |
| `fitted(object, type = "observed")` | as `switch_predict` |
| `residuals(object, type = c("response", "pearson"))` | relative to the conditional mean in the observed regime |
| `predict` | as `switch_predict` |
| `simulate` | as `switch_simulate` |
| `confint(object, parm, level, type = c("transformed-wald", "natural-wald"))` | |
| `anova(object, ...)` | LR tests between nested fits |
| `update` | |
| `model.frame`, `model.matrix(object, part)`, `terms(object, part)` | |

## 5. Generation 2 (draft for the G2 gate, 23 November 2026)

Sections 1-4 are unchanged: no G1 signature changes, and every G1 call
returns the 1.0.0 result. G2 adds argument values, a few arguments with
defaults, and wrappers. Specification sections 6.3 and 10.1; plan decisions
D4 and D7. Functions are `lifecycle: experimental` until the acceptance
tests of their work package pass.

### 5.1 `model` and `selection_family`

| `model` | `selection_family` (default first) | Version | Wrapper |
| --- | --- | --- | --- |
| `"esr"` | `"probit"` | 1.0.0 | `esr()` |
| `"tobit5"` | `"probit"` | 1.1.0 | `tobit5()` |
| `"heckman"` | `"probit"` | 1.1.0 | `heckman()` |
| `"treatment"` | `"probit"` | 1.1.0 | `treatment()` |
| `"multinomial_esr"` | `"multinomial_logit"` | 1.2.0 | `multinomial_switch()` |
| `"multinomial_esr"` | `"multinomial_probit"` | 1.3.0 | `multinomial_switch()` |
| `"multinomial_esr"` | `"nested_logit"` | 1.4.0 | `multinomial_switch()` |
| `"ordered_esr"` | `"ordered_probit"` | 1.4.0 | none (`switch_fit()`) |
| `"sequential_esr"` | `"sequential_probit"` | 1.4.0 | none |
| `"multivariate_esr"` | `"multivariate_probit"` | 1.5.0 | `multiswitch()` |

The specification's example (section 6.3) runs as written:

```r
switch_fit(selection = financing_regime ~ firm_size + collateral +
             financial_access + digital_infrastructure,
           outcomes = list(internal = productivity ~ x1 + x2 + x3,
                           bank     = productivity ~ x1 + x2 + x3,
                           digital  = productivity ~ x1 + x2 + x3),
           data = firms, model = "multinomial_esr",
           selection_family = "multinomial_probit",
           dependence = "gaussian", method = "fiml")
```

`dependence = "gaussian"` means joint normality for the probit families and
the Gaussian copula of Lee (1983) for the logit families.

### 5.2 Formulas

| Model | `selection` | `outcomes` |
| --- | --- | --- |
| Heckman | one formula | one formula (or a list of length 1); the response may be `NA` when $S = 0$ |
| Treatment | one formula | one formula **without** the regime variable; `shift = ~ 1` (default) or `~ modifiers` gives $d_i$ |
| Tobit-5 | one formula | list of two, positional: first observed when $S = 0$ |
| Multinomial | one formula with a factor response of $J \ge 3$ levels (common regressors), or a named list of formulas, one per non-base alternative | named list, one element per regime, matched to the levels by name |
| Ordered | one formula with an ordered factor (or integer) response | as multinomial |
| Sequential | list of formulas, one per stage, each with a binary response that is `NA` for units that stopped earlier | list of $J$, in the order: stopped at stage 1, ..., passed all |
| Multivariate | named list of formulas, one per binary equation | named list; names are the combinations, for example `"1.0"`, in the order of the equations; combinations without an element have no outcome |
| Several outcomes | | an element of `outcomes` may itself be a list of formulas |

### 5.3 New arguments (all with defaults; ignored with a classed error if they do not apply to the model)

| Argument | Values | Meaning |
| --- | --- | --- |
| `base` | a regime label; default the first level | base alternative of multinomial models |
| `shift` | one-sided formula; default `~ 1` | effect modifiers of the treatment model |
| `nests` | named list of character vectors | nesting structure of the nested logit |
| `selection_covariance` | `"independent"`, `"unrestricted"` | MNP covariance of the utility differences |
| `stage_dependence` | `"independent"`, `"unrestricted"` | correlation between sequential stages |
| `correction` | `"lee"`, `"dmf"`, `"bfg1"`, `"bfg2"` | two-step correction with multinomial-logit selection (`method = "two_step"`) |

`method`: `"fiml"` and `"two_step"` as in G1. FIML is refused for
`correction` other than `"lee"` (they are moment models). `vcov` as in G1;
`"hessian"` uses the Hessian type of NUMERICAL_METHODS.md s.7.1, and the
default becomes `"sandwich"` when probabilities are simulated.

`switch_control()` gains `draws = 500L`,
`probability = c("auto", "deterministic", "ghk")` and
`bootstrap_R = 999L` (two-step standard errors that need the bootstrap).

### 5.4 Wrappers

```r
heckman(selection, outcome, data, method = "fiml", ...)
treatment(selection, outcome, data, shift = ~ 1, method = "fiml", ...)
tobit5(selection, outcomes, data, method = "fiml", ...)
multinomial_switch(selection, outcomes, data,
                   selection_family = "multinomial_logit",
                   method = "fiml", ...)
multiswitch(selection, outcomes, data, method = "fiml", ...)
```

Each is `switch_fit()` with `model` set, as `esr()` is.

### 5.5 Parameter names

| Parameter | Name |
| --- | --- |
| Selection coefficients | `selection:<term>` (one equation); `selection[<alternative, stage or equation>]:<term>` |
| Thresholds | `selection:cut[<j>]` |
| Nested-logit dissimilarity | `selection:lambda[<nest>]` |
| Selection covariance | `selection:sd[<alt>]`, `selection:cor[<a>,<b>]` |
| Outcome coefficients | `<regime>:<term>`; `outcome:<term>` (Heckman, treatment); with several outcomes `<regime>[<response>]:<term>` |
| Shift | `shift:<term>` |
| Scales | `<regime>:sigma` |
| Dependence, one per regime | `<regime>:rho` |
| Dependence, several per regime | `<regime>:rho[<alternative, stage or equation>]` |
| Two-step correction coefficients | `<regime>:theta`, `<regime>:theta[<term>]` |
| Within-regime outcome correlations | `<regime>:cor[<response a>,<response b>]` |

`summary()` prints, under the dependence parameters, the sentence that
defines them for the model (they are not comparable across models:
MULTINOMIAL_ESR.md section 7).

### 5.6 Post-estimation

- **`switch_effects()`** gains `pairs = "all"` (or a list of regime pairs)
  and `given = NULL` (conditioning regimes for $TE_{jk \mid l}$). `effects`
  accepts `"ATE"`, `"ATT"`, `"ATU"`, `"TH"` (`"BH"` only for two regimes).
  The table has the columns effect, regime, against, group, estimate,
  std_error, statistic, p_value, lower, upper, and `assumption` (empty, or
  the name of the stated assumption the estimate relies on: `"L-CI"`,
  `"zero partial correlation"`). `means` is the $J \times J$ table.
- **`switch_predict()`**: `"probability"` returns an $n \times J$ matrix;
  `"conditional"` the $J \times J$ expectations per unit (columns
  `EY<j>_S<k>`); the other types as in G1. For Heckman: `"probability"`,
  `"linear"`, `"conditional"` (observed and unobserved group),
  `"unconditional"`.
- **`switch_counterfactual()`**: `scenario = "all_regime"` with
  `regime = "<label>"`, and `"policy"`; the G1 names stay for two regimes.
- **`switch_test()`**: `lr_independence` and `wald_independence` test all
  dependence parameters of the model. New type `"lr_structure"` compares
  the restricted and unrestricted selection covariance, or the multinomial
  and nested logit (with the boundary reference distribution).
- **`switch_simulate()`**: `potential_outcomes = TRUE` uses the reference
  completion of GAUSSIAN_REGION_ENGINE.md s.11 (conditional independence
  given the selection disturbances), or a user `completion =` matrix of
  partial correlations; stated in an attribute.
- **`switch_bootstrap()`, `switch_validate()`, `switch_diagnostics()`,
  `switch_compare()`**: unchanged signatures; contents extended
  (IDENTIFICATION.md s.8).

### 5.7 Refusals

Requests that the derivation documents do not cover give
`switch_error_unsupported` with the reason: FIML with the Dubin-McFadden or
BFG corrections; these corrections with the nested logit; $\lambda > 1$;
effects for a Heckman fit; effects between different response variables;
removing an alternative from the choice set; non-Gaussian outcomes
(Generation 4); copulas other than Gaussian (Generation 3).

### 5.8 Gate amendments (23 November 2026)

- **`dependence`** (new argument of `switch_fit()` and
  `multinomial_switch()`, used with `selection_family = "mnl"` and
  `method = "fiml"`): `"lee"` (default until the owner decides otherwise
  after WP2.2) or `"normal_scores"` (MULTINOMIAL_ESR.md section 11).
  With `"normal_scores"`, `dependence_terms = "all"` (default: $J$
  correlations per regime), `"own"` (the regime's own score only) or
  `"own_common"` (own score and one common correlation with the others).
  Parameter names: `rho_<j>.<k>` for $\operatorname{Corr}(u_j, \eta_k)$,
  with the regime labels in place of the numbers.
- **Number of regimes:** any $J \ge 2$ that the data support; tested up
  to $J = 8$ (and $J = 10$ for Lee's model). A classed warning
  (`switch_warning_small_regime`) when a regime has fewer observations
  than 10 times its number of outcome parameters; a classed error when a
  regime's outcome design is rank deficient.
- **`control = switch_control(draws = )`:** default 500 for $d \le 5$
  and 2000 for $d \ge 6$ (NUMERICAL_METHODS.md section 7.7);
  `quadrature_nodes = 32L` for the normal-score model.
- **Benchmark mapping for `treatment(shift = )`:** `endogenous::hybrid()`
  reports $\eta = -\delta$.

### 5.9 As built in version 1.1.0, and the owner's decision on the default

- `switch_fit()` and `switch_model()` have the new argument `shift`
  (default `NULL`; `~ 1` for the treatment model).
- Regime labels: `not_observed`, `observed` (Heckman); `untreated`,
  `treated` (treatment). Equations: `selection`, `outcome`, `shift`.
- `switch_predict()` for a Heckman fit: `"conditional"` has the columns
  `EY_S1` and `EY_S0`; `"linear"` and `"unconditional"` are $x'\beta$;
  `"observed"` is `NA` for units without an observed outcome.
- `switch_simulate(potential_outcomes = TRUE)`: `.latent` (Heckman);
  `.potential_untreated`, `.potential_treated` (treatment; one disturbance,
  so no completion is needed).
- `switch_compare()` gives the likelihood-ratio test of a treatment fit
  against the switching regression with the same regressors when the
  modifiers are among the outcome regressors.
- Refused with `switch_error_unsupported`: `switch_effects()` and
  `switch_counterfactual()` for a Heckman fit and for a Tobit-5 fit with
  two different responses; the effects bootstrap for a Heckman fit.
- **Owner's decision (23 November 2026):** `dependence = "lee"` stays the
  default of the multinomial-logit FIML model; `"normal_scores"` is an
  option (section 5.8).
