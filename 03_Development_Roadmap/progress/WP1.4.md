# WP1.4: FIML and two-step estimators, switch_fit()

Version 0.4.0. Completed 22 November 2026. Status: **done.**

## What was done

| File | Content |
| --- | --- |
| `R/est_two_step.R` | Probit (IRLS, weights; separation detection), selection-corrected regime regressions, Heckman variance recovery. Covariances: model-based Heckman/Greene with the first-stage, cross-regime and first-stage cross blocks; stacked M-estimation sandwich; cluster version. FIML starting values (rho truncated to ±0.95) and a fallback start (probit + OLS, rho = 0) |
| `R/est_optimizer.R` | Objective on the free working parameters with a one-point cache; `maxLik` Newton-Raphson as primary optimiser; BFGS, BHHH and `optim` fallbacks, each polished by NR; convergence judged by our own criteria (max \|gradient\| < tolerance and a negative definite Hessian), with codes 0-4 as in NUMERICAL_METHODS.md |
| `R/est_fiml.R` | Multistart: the two-step start (or the user start first), seeded perturbations scaled by the two-step standard errors, and an atanh-rho grid when `starts >= 10`. Best converged maximum; agreement table; flat-likelihood and local-maxima detection |
| `R/inf_vcov.R` | FIML covariances: hessian, OPG, sandwich, cluster. Moved forward from WP1.5, because weighted and clustered fits need them; WP1.5 keeps bootstrap, tests, diagnostics and `switch_validate()` |
| `R/switch_control.R`, `R/switch_fit.R` | `switch_control()`; `switch_fit()` with the API of API_SPECIFICATION.md (`model` as string or spec, the `estimator` synonym, future arguments named by generation, vcov defaults, never-silent warnings); `esr()`; the reproducibility record |
| `R/methods_switch_fit.R` | `print`, `coef` (natural/working, by part), `vcov`, `logLik` (NA for two-step), `nobs` |
| `04_Validation/scripts/mc_g1.R` | Monte Carlo driver for the pre-registered design: modes smoke, core, ofat, multistart and full; L'Ecuyer streams; results independent of the number of cores |
| `tests/testthat/test-estimation.R` | 16 tests |

`maxLik` moved into Imports.

## Evidence

**Tests on the source: 10 files, 434 expectations, 0 failures (29 s).**
- **FIML against `sampleSelection` 1.2-16 ML** (n = 2000): identical
  log-likelihood, coefficients within 3.1e-10, standard errors within
  1.1e-9. The test asserts 1e-6 and 1e-5 at n = 1500.
- **Recovery** (n = 5000, local only): every estimate within 4 standard
  errors of the truth; converged; Hessian negative definite.
- **Frequency weights:** weighted fit and fit on replicated data are equal
  (log-likelihood to 1e-9, coefficients to 1e-6), for FIML and two-step.
- **Two-step covariance:** equals an independently coded Heckman/Greene
  formula to 1e-8, for all blocks including cross-regime and first stage.
  Robust and model-based standard errors are within 0.8-1.25 of each other.
- **Multistart:** reproducible; the RNG state is restored; all 6 starts
  converge to the same optimum (max parameter difference < 1e-4); the grid
  appears with 10 starts.
- **Fallbacks:** BFGS, BHHH and `optim` each reach a converged optimum
  after the NR polish.
- **Failure paths:** `maxit = 1` gives a fit with
  `switch_warning_convergence`; boundary detection gives
  `switch_warning_boundary`.

**`R CMD check --as-cran`** on `SwitchEconometrics_0.4.0.tar.gz`: 0 errors,
0 warnings, 1 NOTE (V8 absent, environment-only). Example time: 0.6 s for
`switch_fit`. Tests under check: 37 s.

**Benchmark finding D-SS-1** (BENCHMARK_PROTOCOL.md section 5a):
`sampleSelection`'s Tobit-5 two-step recovers sigma with
$(\hat\theta\bar\delta)^2$ instead of $\hat\theta^2\bar\delta$. At
n = 400 000 our two-step gives sigma1 = 1.201 (true 1.2) against 1.145
from `sampleSelection`. All shared quantities agree to 4e-10.
`sampleSelection` also reports no two-step standard errors for the outcome
equations.

### Monte Carlo smoke test, and an optimiser fix it triggered

Driver `mc_g1.R smoke`: R = 50 per cell, FIML (`starts = 1`) and two-step.
Package installed in the private library `runs/lib`, so the owner's R
libraries are untouched.

**First run** (`runs/mc_g1_0.4.0_smoke/`):
- All 200 FIML fits converged, but cells 2 and 3 took 128 s and 111 s
  instead of about 10 s.
- Diagnosis: in replication 40 of cell 2, `maxNR` with its default step
  halving reached the optimum after about 8 iterations and then stalled
  until the iteration limit: 500 iterations, 13 347 function evaluations,
  91 s. Its gradient stayed at 1.3e-7, just above `maxNR`'s internal
  stopping threshold.
- Our convergence check (1e-6) accepted the result correctly, so the
  estimates were right; only the time was wasted.
- With Marquardt's correction the same fit needs 4 iterations and reaches a
  gradient of 2.6e-12. BFGS + NR needs 0.2 s.

**Fix:**
- `maxNR` now runs with `qac = "marquardt"` and stops on an absolute
  log-likelihood change < 1e-12. BHHH also stops on the 1e-12 change.
- A regression test rebuilds that replication exactly (L'Ecuyer streams) and
  requires < 50 iterations and < 10 s.
- The local test suite went from 41 s to 29 s.

**Second run** (`runs/mc_g1_0.4.0_smoke_marquardt/`): 34 s in total instead
of about 263 s. FIML estimates and log-likelihoods are identical to the first
run up to 4.3e-9.

| Cell | FIML converged | max \|bias\| | max \|rel. bias\| | bias of rho1/rho0 | 95% coverage | SE ratio | median s/fit |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N = 1000, rho = 0/0 | 50/50 | 0.047 | 0.054 | −0.031/0.027 | 0.92-0.98 | 0.82-1.07 | 0.07 |
| N = 1000, rho = 0.6/0.4 | 50/50 | 0.029 | 0.058 | 0.023/0.029 | 0.90-0.98 | 0.88-1.15 | 0.14 |
| N = 1000, rho = 0.7/−0.5 | 50/50 | 0.031 | 0.062 | 0.031/−0.006 | 0.88-1.00 | 0.74-1.32 | 0.11 |
| N = 500, rho = 0.6/0.4 | 50/50 | 0.046 | 0.092 | −0.009/−0.046 | 0.90-0.98 | 0.64-1.24 | 0.06 |

Two-step (gamma, beta): coverage 0.90-0.98, SE ratio 0.88-1.31.

With R = 50, the Monte Carlo standard error of a coverage rate is about
0.03 and that of an SE ratio about 0.10. These figures show that the
pipeline works and nothing is grossly wrong. They are not evidence for AC1
or AC4, which require the pre-registered study (WP1.7).

During this work package, five other `Rscript` processes started at 13:09
(not by this session) kept all four cores busy. Timings above were measured
under that load.

## Next

WP1.5 (v0.5.0):
- `switch_bootstrap()` (nonparametric and parametric);
- `switch_test()` (LR and Wald tests of independence; general Wald tests);
- `switch_diagnostics()`;
- `switch_validate()` (identification checks I1-I11);
- `summary()` with standard-error tables.

## Not verified, and limits

- The Monte Carlo smoke test is not the pre-registered study (WP1.7): 50
  replications per cell give Monte Carlo standard errors of about 0.03 for
  coverage.
- `summary()`, standard-error tables, effects and predictions are not yet
  available (WP1.5-1.6).
- Remote CRAN-incoming checks are off locally; GitHub Actions has not run.
