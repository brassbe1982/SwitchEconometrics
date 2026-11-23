# SwitchEconometrics 1.1.0

First step of Generation 2 (generalised selection): three models that use
the Gaussian likelihood of the binary switching regression with a different
observation mechanism. Results of `esr()` and `switch_fit(model = "esr")`
are unchanged from 1.0.0 (tested at 1e-8 against stored 1.0.0 results).

## New

* `heckman()`: sample selection model (Tobit-2), full-information maximum
  likelihood with analytic gradient and Hessian, and Heckman's two-step
  estimator with corrected covariances. The outcome and its regressors may
  be missing for units whose outcome is not observed.
* `treatment()`: endogenous treatment model with a shift,
  `y = x'beta + S d'delta + eps`. `shift = ~ 1` gives a constant shift;
  `shift = ~ modifiers` lets the treatment effect vary with covariates (the
  hybrid model with a structural shift). The likelihood is the switching
  regression likelihood under a linear restriction and uses the same
  engine; the two-step estimator is a regression on `(x, S d, h)` with the
  generalised residual `h` of the probit.
* `tobit5()`: a second interface to the model of `esr()`, with the two
  outcome equations matched to the regimes by position and possibly
  different response variables.
* `switch_fit()` and `switch_model()` accept `model = "heckman"`,
  `"treatment"` and `"tobit5"` and the new argument `shift`.
* The methods and post-estimation functions work with the new models:
  `summary()`, `confint()`, `predict()`, `residuals()`, `simulate()`,
  `switch_predict()`, `switch_test()`, `switch_validate()`,
  `switch_diagnostics()`, `switch_bootstrap()`, `switch_simulate()` and
  `switch_compare()`. For treatment fits `switch_effects()` and
  `switch_counterfactual()` give the averages of `d'delta`;
  `switch_compare()` gives the likelihood-ratio test of the treatment model
  against the switching regression with the same regressors.
* Requests the models do not define give a classed error
  (`switch_error_unsupported`): effects and regime scenarios for a Heckman
  fit, and effects for a Tobit-5 fit with two different response variables.

## Validation

* Likelihoods, estimates and standard errors agree with
  `sampleSelection::selection()` (Tobit-2, ML and two-step) and
  `sampleSelection::treatReg()` (ML), and the hybrid model with
  `endogenous::hybrid()`.

# SwitchEconometrics 1.0.0

First release for CRAN: Generation 1, the classical binary endogenous
switching regression. The code is that of 0.9.1.

## Features

* **Estimation:** full-information maximum likelihood with an analytic
  gradient and Hessian, multistart and fallback optimisers; two-step
  (Heckman-Lee) estimation with corrected covariances (`switch_fit()`,
  `esr()`).
* **Inference:**
  - Hessian, OPG, sandwich and cluster-robust covariances, and sampling
    weights;
  - confidence intervals on the transformed scale for sigma and rho;
  - likelihood-ratio and Wald tests, including linear hypotheses;
  - nonparametric and parametric bootstrap.
* **Identification checks** I1-I11 before and after fitting
  (`switch_validate()`) and computational diagnostics
  (`switch_diagnostics()`).
* **Treatment effects:**
  - the four conditional expectations, ATT, ATU, ATE, TH, BH1 and BH0;
  - by group or per unit;
  - delta-method or bootstrap standard errors (`switch_effects()`,
    `switch_predict()`).
* **Counterfactual and policy scenarios** (`switch_counterfactual()`),
  **simulation** (`switch_simulate()`), **model comparison**
  (`switch_compare()`), and the simulated dataset `firms`.
* **Three vignettes:** `classical-esr`, `treatment-effects` and
  `simulation-validation`.

## Validation

All six acceptance criteria of Generation 1 are met
(`04_Validation/results/EVIDENCE_G1.md` in the source repository).

* **Formulas.** Every formula is checked numerically (26 checks).
* **Monte Carlo study.** Pre-registered: 38 designs, 28 400 replications.
  - Bias, root-N and convergence checks pass.
  - Coverage reaches the nominal level as N grows. It is lower below
    N = 1000, as the vignette `simulation-validation` explains.
* **Benchmarks.** FIML equals the maximum-likelihood estimates of
  `sampleSelection` and of the archived `endoSwitch`. The robust and
  cluster standard errors equal those of the `sandwich` package.
* **Platforms.** `R CMD check` passes on Windows, macOS and Ubuntu (R
  release, devel and oldrel-1) and on win-builder.

# SwitchEconometrics 0.9.1

Generation 1, work package 1.9, continued (23 November 2026): the public
repository.

* The source is on GitHub: https://github.com/brassbe1982/SwitchEconometrics.
  `URL` and `BugReports` in DESCRIPTION point to it, and the README shows
  how to install from it.
* GitHub Actions runs `R CMD check` on Windows, macOS and Ubuntu (R
  release, devel and oldrel-1) on every push.

# SwitchEconometrics 0.9.0

Generation 1, work package 1.9 (23 November 2026): documentation and CRAN
preparation.

## Documentation

* Three vignettes:
  - `classical-esr`: specification, identification checks, FIML and
    two-step estimation, inference, bootstrap, diagnostics, and the
    estimates against the true parameters of `firms`;
  - `treatment-effects`: the four conditional expectations, ATT, ATU, ATE
    and heterogeneity, delta-method and bootstrap standard errors, effects
    by group and per unit, counterfactual and policy scenarios, and the
    distribution of gains, which depends on the non-identified correlation;
  - `simulation-validation`: the Monte Carlo and benchmark evidence,
    including the coverage of the intervals below N = 1000 (owner's decision
    in WP1.7) and of cluster-robust intervals with 100 clusters (WP1.8), and
    a recovery check for the user's own design.
* README rewritten for users. DESCRIPTION describes what this release does.
  New `cran-comments.md`.
* `?switch_fit` explains the default three starts and the boundary stop.

## Output

* `print()` of a specification aligns all labels ("Observation:",
  "Dependence:").
* `print()` of a fit no longer leaves a space before the closing
  parenthesis of the version.
* `print()` of effects omits the heterogeneity row when TH, BH1 and BH0 were
  not requested.
* `print()` of a Wald test of linear restrictions states them on the H0
  line; the matrix form reads "R theta = r".

# SwitchEconometrics 0.8.1

Generation 1, work package 1.8, continued (23 November 2026). This release
closes the open items of the benchmarks, at the owner's request.

## Improvements

* **Faster FIML.**
  - Newton-Raphson now obtains the gradient and the Hessian from one
    likelihood evaluation, instead of separate ones.
  - The likelihood kernel evaluates `pnorm()` once per regime.
  - Results are unchanged. A default fit at N = 10 000 takes 1.2 s instead
    of 2.6 s.
  - With `switch_control(starts = 1)`, a fit is faster than
    `sampleSelection`'s at N ≥ 2000. The default runs three starts to
    detect lower local maxima; `?switch_fit` now says so.
* **Boundary stop.** When an optimisation ends with a correlation within
  1e-6 of +-1, the fallback optimisers are skipped for that start, and
  `fit$convergence$path` ends with `"boundary-stop"`.
  - Before, a misspecified example of the `sampleSelection` vignette ran
    every fallback from every start to the same boundary, taking 51-82 s;
    it now takes 3.5 s, with the same result and warnings.
  - The fit still reports non-convergence and the boundary.

## Validation

* **Weighted and clustered fits** are now benchmarked
  (`04_Validation/results/BENCHMARK_G1.md` s.4.4-4.5).
  - Weighted estimates, log-likelihood, and Hessian, sandwich and cluster
    standard errors equal `sampleSelection` on replicated rows combined
    with the `sandwich` package (2e-6).
  - Sandwich, OPG and cluster standard errors on clustered data equal the
    `sandwich` package (7e-10).
  - A Monte Carlo under clustering (100 clusters) supports the
    cluster-robust standard errors of FIML and two-step: SE ratios
    0.93-1.04. The FIML intervals for sigma and rho cover 0.89-0.91; the
    vignettes (0.9.0) will say so.
* 1275 of 1378 benchmark checks pass, and every difference is explained.
  New documented difference D-ES-2: `endoSwitch` weights its likelihood but
  not its effects.
* **Acceptance criterion AC3 is met** with documented differences (owner,
  23 November 2026).

# SwitchEconometrics 0.8.0

Generation 1, work package 1.8 (22-23 November 2026): cross-software
benchmarks against `sampleSelection` 1.2-16 and the archived `endoSwitch`
1.0.0.

## Bug fix

* The probit first stage of the two-step estimator (also used for FIML
  starting values and the identification checks) is now solved to machine
  precision.
  - Before, it stopped on `glm.fit()`'s deviance rule. With regressors on
    large scales, such as age or farm size, that could leave score
    components of order 1e-4 and move the two-step results by about 1e-6.
  - Newton steps on the exact probit Hessian now follow `glm.fit()`. A
    step is kept only if it lowers the largest score component, and the
    steps are skipped after non-convergence or separation.
  - FIML estimates are unchanged beyond the optimiser tolerance.

## Validation

* Benchmarks (`04_Validation/results/BENCHMARK_G1.md`): 11 datasets,
  including the Tobit-5 examples of `sampleSelection` and the `ImpactData`
  of `endoSwitch`. 1048 of 1145 checks pass.
  - FIML equals `sampleSelection`'s ML estimates (3.3e-6), log-likelihood
    (2.7e-11) and standard errors (7.2e-6), and `endoSwitch`'s estimates
    (4.4e-8), log-likelihood (1.1e-13), treatment effects and conditional
    expectations.
  - The two-step coefficients equal `sampleSelection`'s to 9.3e-10.
  - Every one of the 97 differences beyond tolerance is explained with
    evidence: `endoSwitch` takes its standard errors from a numerical
    Hessian (1-4% off), its first-stage `glm()` stops early, and neither
    package converges on the vignette's misspecified example.
* New documented difference D-ES-1: `endoSwitch2Stage()` recovers sigma
  and rho with an inconsistent formula, like `sampleSelection`'s two-step
  (D-SS-1).
* Acceptance criterion AC3 was proposed as met with these documented
  differences (confirmed in 0.8.1).

# SwitchEconometrics 0.7.1

Owner's decision of 22 November 2026 on the identification diagnostics,
based on the Monte Carlo evidence of 0.7.0.

## Changes

* `switch_validate()`: check I6 now warns when the R2 of the
  selection-correction term on the outcome regressors exceeds 0.80. The
  previous threshold was 0.95.
  - In the Monte Carlo study, the 0.95 rule flagged only 15-27% of samples
    with a weak exclusion restriction, where FIML's rho is biased. The 0.80
    rule flags 75-92% of them, and still none in the base and
    strong-exclusion designs.
  - The message now says that rho is weakly identified and its estimate may
    be biased.
  - I6 still raises no R warning at fit time; estimates are unchanged.
  - Details are in IDENTIFICATION.md section 7.

# SwitchEconometrics 0.7.0

Generation 1, work package 1.7 (22 November 2026): the pre-registered Monte
Carlo study. No change to the estimators or to the user interface.

## Validation

* The full study of `04_Validation/MONTE_CARLO_DESIGN.md` was run: 38 cells
  and 28 400 replications, each fitted by FIML and two-step, with effects.
  Results and interpretation are in `04_Validation/results/MC_G1.md`.
* **Gate: 491 of 501 pre-registered checks pass.**
  - All checks of bias, root-N, convergence and two-step coverage pass.
  - 10 checks of standard-error ratio, coverage and effect bias fail. 7 of
    them are at N = 1000-2000.
* **Diagnosis:** no defect in the estimators or in the standard-error
  formulas.
  - The Hessian standard errors equal the asymptotic standard errors at the
    true parameters.
  - The failures come from finite-sample behaviour at N = 1000-2000, from
    conservative standard errors of sigma when rho = 0 exactly, and from
    Monte Carlo noise.
  - At N = 5000, mean coverage is 0.949.
* The owner accepted the diagnosis. Acceptance criteria AC1 and AC4 are met
  with the failed checks recorded as documented exceptions. The
  pre-registered thresholds are unchanged.
* **AC4(b)** (bootstrap and Hessian standard errors within 10% at N = 2000)
  passes on `firms` (15/15) but not on the base-design dataset (12/15).
  There, comparison with the Monte Carlo truth shows that the Hessian
  standard errors are accurate and the bootstrap overstates them.
* **Supplementary study of the identification diagnostics.**
  - I5 and I6 raise no false alarms in the base and strong-exclusion
    designs.
  - With a weak exclusion at N = 2000, the current thresholds flag only
    15-44% of samples, although FIML's rho is biased.
  - A lower I6 threshold (R2 > 0.80) is proposed to the owner. Defaults are
    unchanged.
* **Sandwich standard errors** (FIML sandwich, two-step stacked sandwich)
  are now recorded in the study. The first full run had omitted them.
  - A full rerun with the same seeds reproduced every estimate, standard
    error and effect exactly, and gave the same gate result.
  - Under the study's correctly specified design, sandwich and Hessian
    standard errors agree on average.
  - At N = 250 the Hessian intervals cover better (0.928 against 0.922).
* The recovery test of acceptance criterion AC1(b) now also runs on CRAN.

# SwitchEconometrics 0.6.0

Generation 1, work package 1.6 (22 November 2026): economic interpretation.

## New features

* `switch_effects()`:
  - computes the four conditional expectations of the potential outcomes
    and ATT, ATU, ATE, TH, BH1 and BH0, with the 2 x 2 table of
    Lokshin-Sajaia / Di Falco layout and the share-weighted ATE;
  - standard errors by the delta method (analytic gradients) or by the
    bootstrap;
  - groups (`by`) and subsets for heterogeneity analysis;
  - weighted means with sampling weights;
  - optional per-observation output.
* `switch_predict()` / `predict()`: types probability, selection_index,
  linear, conditional, observed and unconditional. They work for new data
  (using the fit's factor levels and contrasts; missing rows give NA) and
  give delta-method standard errors. `fitted()`; `residuals()` (response,
  pearson).
* `switch_counterfactual()`:
  - scenarios: everyone in regime 1, everyone in regime 0, or a policy
    change of covariates;
  - mean changes in expected outcomes and in the regime-1 share, with
    delta-method standard errors, by observed regime and by group;
  - for the `all_` scenarios, the change conditional on the observed regime
    (its mean is the ATU, or minus the ATT).
* `switch_simulate()` and `simulate()`: simulate from a specification or a
  fit. Potential outcomes are simulated under an explicit, admissibility
  checked assumption on Corr(eps1, eps0) (default rho1*rho0).
* `switch_compare()`, `anova()`: comparison tables and likelihood-ratio
  tests of nested FIML fits on the same sample.
* `update()` works for `switch_fit()` and `esr()` fits. Also
  `model.frame()`, `model.matrix()` and `terms()` by equation.
* `switch_bootstrap(statistics = "effects")`: bootstrap of the effects,
  recomputed on each bootstrap sample (including groups).
* New simulated dataset `firms` (2000 firms; digital adoption and
  productivity) with documented true parameters.

## Validation (acceptance criterion AC5 met)

* The conditional expectations equal two-dimensional numerical integrals to
  1e-7.
* The effects equal the reference implementation to 1e-10.
* BH1 - BH0 = TH, and the share-weighted ATE equals ATE at the probit
  estimate.
* Analytic effect gradients equal numerical derivatives.
* On 200 000 simulated observations, the counterfactual means, ATT and ATU
  match the simulated potential outcomes within 4 Monte Carlo SEs.

# SwitchEconometrics 0.5.0

Generation 1, work package 1.5 (22 November 2026): inference and
diagnostics.

## New features

* `switch_test()`:
  - likelihood-ratio test of independent equations (rho_1 = rho_0 = 0),
    using a restricted FIML refit that equals the probit-plus-regressions
    closed form;
  - Wald test of independence (on the selection-correction coefficients for
    two-step fits);
  - Wald tests of general linear hypotheses written in parameter names
    (e.g. `"regime_1:x1 = regime_0:x1"`) or as `list(R = , r = )`.
* `confint()`. The default intervals for sigma and rho are formed on the
  log / atanh scale and lie inside the parameter space.
* `summary()`:
  - coefficient tables by equation;
  - disturbance parameters with intervals;
  - LR and Wald tests of independence;
  - convergence, multistart and identification information;
  - for two-step fits, the selection-correction coefficients with standard
    errors.
* `switch_bootstrap()`:
  - nonparametric (observations or clusters) and parametric bootstrap;
  - one L'Ecuyer stream per replicate, so results do not depend on `cores`
    (parallel equals serial, tested);
  - the caller's random-number state and kind are restored;
  - failed replicates are counted with reasons, and a warning is given above
    10%;
  - gives two-step standard errors for sigma and rho.
* `switch_validate()`: identification checks I1-I11 on a specification with
  data or on a fit. Data errors and rank problems are reported, not thrown.
  Every fit stores the checks. `switch_fit()` warns (class
  `switch_warning_identification`) when identification rests on the normal
  functional form alone (specification section 3.5).
* `switch_diagnostics()`: computational and statistical diagnostics, kept
  separate (specification section 15).

## Methodological note

* The falsification test of exclusion restrictions (I10, Di Falco et al.
  2011) is reported for information only. In a simulation with valid
  exclusions and rho_0 = 0.4, the literal test rejects 51% of the time at
  the 5% level. Its version conditional on the selection-correction term has
  the right size but no power. See IDENTIFICATION.md section 6, pending the
  owner's confirmation.

# SwitchEconometrics 0.4.0

Generation 1, work package 1.4 (22 November 2026). First version that
estimates.

## New features

* `switch_fit()` estimates the classical binary endogenous switching
  regression by full-information maximum likelihood (`method = "fiml"`) or
  by the two-step Heckman-Lee estimator (`method = "two_step"`; `estimator`
  is a synonym). `model` accepts a model type with formulas, or a
  `switch_spec`.
  - **FIML:** Newton-Raphson with the analytic gradient and Hessian
    (Marquardt correction of non-concave steps), started from the two-step
    estimate. Further perturbed starts (and a grid in
    atanh(rho) for 10 or more starts) are seeded, and the global
    random-number state is restored. BFGS, BHHH and `optim` serve as
    fallbacks. Convergence is judged by the largest gradient component and
    a negative definite Hessian.
  - **Failure reporting:** failed optimisations, boundary solutions
    (|rho| > 0.995), ill-conditioned Hessians and flat likelihoods each
    return the fit with a classed warning; none is silent.
  - **Two-step:** probit, then selection-corrected regressions within the
    regimes, with sigma and rho from Heckman's variance formula. The
    covariance accounts for the first stage and is model-based
    (Heckman/Greene), stacked-sandwich robust or cluster-robust, including
    the cross-regime and first-stage blocks.
  - **Covariance types:** `"hessian"`, `"opg"`, `"sandwich"`, `"cluster"`.
    The default is sandwich with weights and cluster with clusters.
  - **Reproducibility record** in every fit: package versions, controls,
    seed, starting values, optimiser path, data dimensions and estimation
    sample.
* `switch_control()` collects the numerical controls.
* `esr()` is the compatibility wrapper for the classical ESR.
* Methods `print()`, `coef()` (natural or working scale, by part), `vcov()`,
  `logLik()` and `nobs()`.

## Validation

* FIML equals `sampleSelection`'s Tobit-5 ML estimates: identical
  log-likelihood, coefficients to 3e-10, standard errors to 1e-9.
* Weighted fits with frequency weights equal fits on the replicated data.
* The two-step coefficients equal `sampleSelection`'s. Its sigma and rho
  differ, because `sampleSelection` 1.2-16 squares the product of the
  correction coefficient and the mean delta. Ours follows Heckman (1979)
  and recovers the true values on 400 000 observations; theirs does not.
  This is documented in BENCHMARK_PROTOCOL.md (D-SS-1).
* Monte Carlo driver `04_Validation/scripts/mc_g1.R` implementing the
  pre-registered design, with a smoke mode.

# SwitchEconometrics 0.3.0

Generation 1, work package 1.3 (22 November 2026).

## Likelihood engine (internal)

* Binary Gaussian ESR likelihood with the analytic score and the analytic
  Hessian of LIKELIHOOD_DERIVATION.md, on the working scale (log sigma,
  atanh rho), with sampling weights.
  - Evaluation is stable for correlations near +/-1 and for outlying
    outcomes, using log Phi, the Mills ratio and a continued fraction in the
    far tail.
  - Speed: about 18 ms per evaluation with the Hessian at n = 5000.
* Model-independent interface of specification section 5.4:
  - `loglik_switch()`: the weighted total, gradient and Hessian;
  - `loglik_observation()`: the per-observation decomposition into the
    regime probability, marginal and conditional outcome densities,
    conditional selection probability and dependence correction;
  - `loglik_joint()`, `loglik_selection()` and `loglik_outcome()`.
* Acceptance criterion AC2 met at package level:
  - the engine equals the independent reference implementation of
    `verify_math.R` (maximum difference 8.9e-16);
  - contributions equal the integrated bivariate normal density and
    integrate to the regime probabilities;
  - the log-likelihood at `sampleSelection`'s Tobit-5 ML estimates equals
    `sampleSelection`'s value.
* `sampleSelection` added to Suggests for the benchmark test, which runs
  only when the package is installed.

# SwitchEconometrics 0.2.0

Generation 1, work package 1.2 (22 November 2026). The Generation 1
econometric gate (derivation documents, decisions D8 and D9) was approved by
the owner on 22 November 2026.

## New features

* `switch_model()` specifies a classical binary endogenous switching model
  (probit selection, two Gaussian outcome equations, Gaussian dependence)
  without data. It checks:
  - formulas and regime labels;
  - that the regime indicator is not used as an outcome regressor;
  - declared exclusion restrictions.

  It detects excluded variables. Values planned for later generations give
  an error of class `switch_error_unsupported` naming the generation.
* `distribution()` gives access to the distribution engine (specification
  section 5.3): density, distribution, quantile and random generation, with
  log versions, for the Gaussian family. Experimental.

## Internal infrastructure

* Data builder: builds design matrices for all units. It never removes rows
  silently: removals come with a message of class `switch_message_missing`
  and a `na_report`. It handles:
  - regime indicators coded as logical, 0/1 or a two-level factor;
  - matching of outcome equations to regimes by name or position;
  - weights, clusters and subsets given as a formula, a column name or a
    vector;
  - finiteness and within-regime rank checks.
* Parameter-transformation engine:
  - identity, log, atanh and 2 + exp transformations, with first and second
    derivatives;
  - correlation matrices through canonical partial correlations, valid for
    every working value, with an exact complex-step Jacobian.
* Parameter map: natural and working names, the delta method, and fixed
  parameters for restricted models.
* Stable normal quantities: log Phi, the inverse Mills ratio, and
  delta(a) = -lambda'(a) through a continued fraction in the far tail.
* Classed conditions (`switch_error_*`, `switch_warning_*`,
  `switch_message_*`) and seeded evaluation that restores the global
  random-number state.

# SwitchEconometrics 0.1.0

Initial development architecture (Generation 1, work package 1.1;
22 November 2026).

* Package skeleton: DESCRIPTION, MIT licence, CITATION, testthat (edition 3),
  GitHub Actions R-CMD-check workflow on Windows, macOS and Linux.
* Authoritative specification and delivery plan (42 work packages, six
  generations), with the owner's decision of 22 November 2026 that excludes
  Stata from the development process.
* Generation 1 derivations: model and assumptions, likelihood, analytic score
  and Hessian, two-step estimator with first-stage-corrected and robust
  covariances, identification (including the non-identification of the
  across-regime correlation), parameterisation, and the four conditional
  expectations with ATT, ATU, ATE, TH and BH.
* `verify_math.R`: 26 numerical checks of every Generation 1 formula against
  integration, numerical differentiation, simulation and `sampleSelection`.
  All 26 pass.
* Pre-registered Monte Carlo design, benchmark protocol (R implementations
  only) and acceptance tests.
* No estimators yet; they are added in versions 0.2.0 to 1.0.0.
