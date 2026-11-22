# WP1.3: Likelihood engine of the binary Gaussian ESR

Version 0.3.0. Completed 22 November 2026. Status: **done.**

## What was done

- **`R/lik_esr_gaussian.R`.** `lik_esr_gaussian()` computes:
  - the per-observation log-likelihood;
  - the per-observation analytic score;
  - the weighted analytic Hessian.

  It works on the working scale, in parameter-map order, and implements
  LIKELIHOOD_DERIVATION.md sections 2-6 term by term.
  `lik_esr_gaussian_components()` gives the per-observation decomposition
  required by specification section 5.4. It uses the Gaussian margin of the
  distribution engine for the outcome density, so that Layer 3 visibly
  builds on Layer 2.
- **`R/lik_interface.R`.** The model-independent interface (`loglik_switch()`,
  `loglik_observation()`, `loglik_joint()`, `loglik_selection()`,
  `loglik_outcome()`) and the engine dispatch `se_lik_engine()`. The data
  object now records model, families and dependence, so that dispatch needs
  no other input.
- **Contract change, recorded in SOFTWARE_ARCHITECTURE.md section 3.** The
  engine applies weights to the Hessian, because per-observation Hessians
  are never stored. `ll_i` and `score_i` stay unweighted.
- **`tests/testthat/helper-reference.R`.** A copy of `verify_math.R`'s
  independent reference implementation, sharing no code with the package,
  plus a bridge between the two parameter orders.
- **`tests/testthat/test-likelihood.R`.** 11 tests, 53 expectations.
- **DESCRIPTION.** `sampleSelection` added to Suggests; it is used
  conditionally in one test.

## Evidence

Measured on 22 November 2026; R 4.6.2, numDeriv 2016.8-1.1,
sampleSelection 1.2-16.

| Check | Result |
| --- | --- |
| Engine against reference implementation (n = 500, random parameters) | max \|Δ log L_i\| 8.9e-16; score and Hessian identical |
| Contributions against the bivariate normal density integrated over the selection region (written out independently) | relative error < 1e-8 (test tolerance), 16 observations |
| Proper density: $\int L\,dy = \Phi(w)$ and $1 - \Phi(w)$ through the package engine | to 1e-9 |
| Analytic gradient and Hessian against `numDeriv`, with and without weights | 2.1e-10 and 2.6e-11 relative |
| Stability: $\rho = \pm 0.998$ with outliers up to 40 | all finite; equal to the reference |
| Identities of the decomposition; no dependence correction at $\rho = 0$ | exact |
| $\rho = 0$ factorisation against `glm` (probit) plus two `lm` fits | to 1e-10 |
| Information-matrix equality at the truth, n = 20 000 | relative difference < 0.05; mean-score \|z\| < 4.5 |
| **`sampleSelection` Tobit-5 (n = 1500)** | our log-likelihood at its ML estimates equals its value (difference 0); our gradient there 9.8e-7 |
| Speed (`loglik_switch`, n = 5000 / 20 000) | 18 / 75 ms with Hessian; 2.5 / 11 ms log-likelihood only |

- **Tests on the source:** 9 files, 332 expectations, 0 failures, 0 skipped
  (22 s).
- **`R CMD check --as-cran`** on `SwitchEconometrics_0.3.0.tar.gz`: 0 errors,
  0 warnings, 1 NOTE (V8 absent; environment-only, as in 0.2.0).

**Acceptance criterion AC2 (reproduce classical ESR likelihood results) is
met** (ACCEPTANCE_TESTS.md).

## Not verified, and limits

- Remote CRAN-incoming checks are off locally, and GitHub Actions has not
  run (no repository yet).
- The `sampleSelection` comparison covers the log-likelihood at given
  parameters. Comparing estimates and standard errors is WP1.8, after the
  estimators exist.
- Nothing estimates yet.

## Next

WP1.4 (v0.4.0):
- the two-step estimator with its corrected and robust covariances;
- FIML through `maxLik` (analytic gradient and Hessian, fallbacks,
  multistart);
- `switch_fit()` and `switch_control()`;
- recovery tests and a Monte Carlo smoke test.

`maxLik` and `mvtnorm` move into Imports when first used (maxLik in WP1.4).
