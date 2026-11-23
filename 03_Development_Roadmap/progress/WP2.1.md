# WP2.1: observation mechanisms (version 1.1.0)

Completed 23 November 2026 by the Generation 2 session. Package version
1.0.0 → **1.1.0**. Status: **done, with one point for the owner** (two
failed Monte Carlo coverage checks, section "For the owner").

## What was delivered

- **`heckman()`**: sample selection (Tobit-2). FIML with analytic score and
  Hessian (`R/lik_heckman_gaussian.R`); Heckman's two-step estimator with
  the model-based, sandwich and cluster covariances. The outcome and its
  regressors may be missing for units whose outcome is not observed.
- **`treatment()`**: one outcome equation with a shift,
  $y = x'\beta + S\,d'\delta + \varepsilon$; `shift = ~ 1` or
  `~ modifiers`. The likelihood is the G1 engine at $A\vartheta$ (score
  $A'g$, Hessian $A'HA$); the two-step estimator is one regression on
  $(x, S d, h)$ with corrected covariances.
- **`tobit5()`**: the G1 model with the equations matched by position and
  possibly different responses.
- `switch_fit()` and `switch_model()` accept the three models and the
  argument `shift`. All methods and post-estimation functions work with
  them, or refuse with a classed error where the model defines nothing
  (effects and regime scenarios for a Heckman fit; effects for a Tobit-5
  fit with two different responses).
- **Frozen G1 results**: `tests/testthat/fixtures/g1_frozen_1.0.0.rds`,
  produced with the installed release 1.0.0 by `data-raw/g1_frozen.R`
  before any shared file was edited, and compared at 1e-8 by
  `test-g1-frozen.R`.
- Validation scripts `04_Validation/scripts/mc_g2.R`, `mc_g2_report.R`,
  `benchmark_g2.R`; results `MC_G2.md`, `BENCHMARK_G2.md` and their
  generated tables.
- Documents: BENCHMARK_PROTOCOL.md 6.4 (and the `endogMNP` row of 6.3);
  SOFTWARE_ARCHITECTURE.md 7.5; API_SPECIFICATION.md 5.9;
  ACCEPTANCE_TESTS.md section 7; GENERATION_2.md (status, the owner's
  decisions of the second message recorded verbatim in section 5).

## Shared G1 files edited

`lik_esr_gaussian.R`, `est_two_step.R`, `eff_core.R`, `par_map.R`,
`est_optimizer.R` and `inf_vcov.R` are unchanged. Dispatch lines only
(model test `se_is_obs()`, or a generalised label or count) in:
`switch_fit.R`, `switch_model.R`, `spec_data.R` (positional matching for
`tobit5`), `spec_support.R`, `lik_interface.R`, `est_fiml.R` (the shift
block joins the coefficient blocks for the scaling of perturbed starts),
`inf_tests.R`, `inf_identification.R`, `inf_bootstrap.R`,
`switch_effects.R`, `switch_predict.R`, `switch_counterfactual.R`,
`sim_simulate.R`, `switch_compare.R`, `methods_summary.R`,
`methods_switch_fit.R`, `methods_model.R`.

## Evidence

| Check | Result |
| --- | --- |
| Test suite (source) | 14 files, **802 expectations, 0 failed**, 1 skipped (the parallel-bootstrap test, which runs only under `R CMD check`) |
| G1 results | the 650 G1 expectations pass unchanged; the frozen 1.0.0 results on `firms` are reproduced at 1e-8 (38 expectations); G1 Monte Carlo smoke run with 1.1.0 **identical** to `runs/mc_g1_0.8.1_smoke` (tolerance 1e-6, largest difference 0) |
| `R CMD check --as-cran` (Windows, R 4.6.2, tarball `runs/build/1.1.0`) | **0 errors, 0 warnings, 1 note** ("Skipping checking math rendering: package 'V8' unavailable": local, as in G1). CRAN incoming remote checks not run |
| New tests (`test-observation-models.R`, 114 expectations) | analytic score and Hessian against `numDeriv` (1e-7, 1e-6), also weighted; Heckman identity with the G1 engine (1e-12); treatment likelihood against the direct formula (1e-12); FIML against `sampleSelection` (log-likelihood 1e-10 and 1e-9); Heckman two-step equal to the regime-1 part of the G1 two-step, estimates and covariance (1e-10, 1e-9); treatment two-step against a direct least-squares computation; effects equal to averages of $d'\delta$ with their delta-method standard errors (1e-8); predictions, tests, validation, bootstrap, simulation, comparison, refusals, argument errors |
| Benchmarks | **48 of 48** toleranced comparisons within tolerance; 4 documented differences (D-SS-2, D-SS-3 three times); 4 not run (`treatReg` two-step stops with an error in `sampleSelection`) |
| Monte Carlo, designs H, T, Th (17 000 replications, pre-registered) | **428 gated checks, 426 passed, 2 failed** |

## Failures and disappointing results

1. **Two pre-registered coverage checks fail** (design H, $N = 1000$,
   $\rho = 0.6$, FIML): coverage of `outcome:sigma` 0.925 and of
   `outcome:rho` 0.926, limit 0.93. Diagnosis in `MC_G2.md`: a small-sample
   effect (skewed $\hat\rho$, standard error 6% too small on average) that
   disappears by $N = 5000$; no defect found; the threshold was not
   changed.
2. **A defect in my own identification check, found by the Monte Carlo and
   fixed.** I6 warned in every treatment replication because of how the
   check was defined for that model. It now uses the within-group $R^2$.
   The Monte Carlo was rerun with the final code: the summary is identical to the first run in every number (largest difference 0), and I6 warns in none of the 17 000 replications.
3. **The Mroz example has two local maxima (D-SS-2).** With the default
   three starts `heckman()` reports a solution with $\hat\rho = 0.993$ and
   a log-likelihood 101.6 above the textbook solution; with
   `switch_control(starts = 1)` it reproduces the textbook numbers. Users
   who compare with published Heckman results on that example will see
   different numbers by default.
4. **`endogMNP` could not be installed** (approved by the owner). Its
   archived source does not compile under R 4.6.2, and its outcome is a
   discrete choice, so it is not a benchmark for the continuous-outcome
   models of G2. It was not patched.
5. `sampleSelection::treatReg(method = "2step")` stops with an error, so
   the treatment two-step estimator has no external benchmark.
6. `endogenous::hybrid()` failed from its own starting values on 2 of 4
   datasets and was restarted from our two-step estimates.
7. First run of the new tests: 2 of 112 expectations failed, both errors
   in the tests themselves (a name attribute; integer against double).
8. The first version of `mc_g2.R` failed (an argument named `cl` collided
   with `parLapplyLB`); fixed before any result was produced.

## Not verified

- macOS and Linux: nothing was pushed, so there is no GitHub Actions run,
  win-builder or macOS-builder check of 1.1.0.
- Cluster-robust covariances and sampling weights of the new models: the
  code paths run in the tests (the weighted Hessian is checked
  numerically), but their sampling behaviour was not simulated.
- The parametric bootstrap and `switch_simulate()` for the new models are
  tested for running and for exact identities, not for their sampling
  properties.
- The hybrid design Th has $R = 500$ and is not gated.
- The vignettes do not yet describe the new models (planned with the
  vignette of WP2.5); the README still describes version 1.0.0.
- `verify_math.R`, `verify_math_g2.R` and `verify_math_g2b.R` were not
  rerun (no file they read was changed).
- The 14 references added in WP2.0 are still unchecked against their
  sources.

## For the owner

1. **The two failed coverage checks** (G2 acceptance criterion 4, design H
   at $N = 1000$): accept as a documented exception with a caution in the
   help page of `heckman()`, or ask for a remedy before G2 is accepted
   (for example profile-likelihood intervals for $\rho$).
2. **Default number of starts on data like the Mroz example**: keep the
   multistart default (it reports the higher maximum and records the lower
   one), or add a warning when the best maximum has $\lvert\hat\rho\rvert$
   close to 1 and another start converged elsewhere.
3. `endogMNP`: drop it for G2 (proposed), and reconsider it for
   Generation 4.
4. Nothing was pushed. Local commits ahead of `origin/main`: the two of
   WP2.0 and the one of this work package.

## Next

WP2.2 (1.2.0): multinomial logit selection: Lee FIML (default), the
normal-score model (option), the Dubin-McFadden and BFG two-step
corrections, any number of regimes (tested to 8 and 10); designs L, D, Lw,
G and L8 of the Monte Carlo plan.
