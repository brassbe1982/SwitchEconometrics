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
