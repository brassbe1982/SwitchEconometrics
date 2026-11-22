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
