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
