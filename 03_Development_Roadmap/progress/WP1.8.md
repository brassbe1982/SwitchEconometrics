# WP1.8: Cross-software benchmarks

Versions 0.8.0 and 0.8.1. Completed 23 November 2026. Status: **benchmarks
run and reported.**
- 0.8.0: 1048 of 1145 checks pass, and every difference beyond tolerance
  is explained with evidence.
- 0.8.1 closes the three open items the owner named: weighted and
  clustered fits, FIML speed, and the slow failure on D6b. Now 1275 of 1378
  checks pass, and all differences are explained.
- **AC3 is met with documented differences**: the owner approved this on
  condition that these items were closed first.

## What was done

| File | Content |
| --- | --- |
| `04_Validation/scripts/benchmark_g1.R` | New. Runs every check of BENCHMARK_PROTOCOL.md section 3 on 11 datasets and writes the generated tables and CSV files |
| `04_Validation/scripts/benchmark_g1_diagnostics.R` | New. Evidence for the differences beyond tolerance: E1 (`endoSwitch` Hessian), E2 (D6b), E3 (probit stopping rules) |
| `04_Validation/results/BENCHMARK_G1.md` | Results and interpretation |
| `04_Validation/results/BENCHMARK_G1_generated.md`, `benchmark_g1.csv`, `benchmark_g1_variance_check.csv`, `benchmark_g1_diagnostics.csv` | Generated outputs |
| `R/est_two_step.R` | Bug fix: the probit is polished with Newton steps after `glm.fit()` (`se_probit_polish()`) |
| `tests/testthat/test-estimation.R` | New test "the probit first stage is solved to machine precision" |
| `04_Validation/BENCHMARK_PROTOCOL.md` | D-ES-1 (section 5a); execution record (section 5b) |
| `01_Econometric_Architecture/BINARY_ESR.md` | `endoSwitch` mapping (section 6) |

**Software.** `endoSwitch` 1.0.0 was downloaded from the CRAN archive, as
approved:
- 33 191 bytes, MD5 3462320a4dcd333ab94af83479943a0b;
- its R code was read before installation: plain R, with no system calls
  or downloads;
- installed into the private library `runs/lib_bench`, together with
  SwitchEconometrics 0.8.0.

The owner's R libraries were not changed. The dependencies (`data.table`,
`msm`, `maxLik`) were already installed.

## Evidence

**Checks** (BENCHMARK_G1.md s.3), excluding D6b:
- `sampleSelection` ML (10 datasets): log-likelihood 2.7e-11, estimates
  3.3e-6, standard errors 7.2e-6 relative, effects 5.8e-6.
- `sampleSelection` two-step (11 datasets): 9.3e-10.
- `endoSwitch` FIML (6 datasets, `reltol = 1e-14`): log-likelihood
  1.1e-13, estimates 4.4e-8, effects and conditional expectations 4.7e-5;
  our formulas at its estimates reproduce its values to 1.4e-14.

**The 97 differences beyond tolerance** (BENCHMARK_G1.md s.4):
- **62 checks, D6b.** Neither package reaches a maximum on the vignette's
  misspecified example. `sampleSelection` stops where the gradient is 139;
  ours goes to ρ = ±1, warns, and has a log-likelihood 237 higher.
- **30 `endoSwitch` standard errors.** Its Hessian is exactly
  `maxLik::numericHessian`. A Richardson Hessian of its own function equals
  our analytic one (4e-9 on D2 and D4).
- **5 `endoSwitch` two-stage values, D7b.** Its `glm()` stops with a probit
  score of 1.2e-3; refitted with a tight tolerance, it agrees with ours
  (2.5e-8).

**Defect found and fixed** (BENCHMARK_G1.md s.6):
- Our probit stopped on `glm.fit()`'s deviance rule; the score was 3.6e-5
  on D6c and 2.7e-4 on D7b.
- After the fix it is below 1.1e-13, and the two-step agrees with
  `sampleSelection` to 9.3e-10 (before: 1.1e-6).
- The new test fails on the old code (score 5.0e-5) and passes on the new
  one (4.4e-14).

**Documented differences:**
- D-SS-1 is confirmed.
- D-ES-1 is new: the two-stage variance recovery of `endoSwitch` is
  inconsistent (σ̂₁ 1.139 against a truth of 1.2 at n = 400 000).

**Package check (0.8.0):**
- Tests on the source: 638 expectations (1 new), 0 failures.
- `R CMD check --as-cran`: 0 errors, 0 warnings, 1 NOTE (V8 absent,
  environment only).
- Under check, 631 pass and 4 are skipped on CRAN.

## Version 0.8.1: the three open items (owner's request)

| Item | What was done | Result |
| --- | --- | --- |
| Weighted and clustered fits not benchmarked | D8 (integer weights; `sampleSelection` on replicated rows with the `sandwich` package, and `endoSwitch` `Weight`); D8b (continuous weights, `endoSwitch`); D9 (clustered data, `sampleSelection` with `sandwich`); `scripts/cluster_mc_g1.R` (R = 500, 100 clusters) | 177/177 checks against `sampleSelection` with `sandwich`, the covariances to 2e-6. Weighted `endoSwitch` estimates 3.6e-8, but 6 standard errors are off by 1.3-3.4% (numerical Hessian). Monte Carlo: cluster SE ratios 0.93-1.04; two-step cluster coverage 0.93-0.96; FIML σ, ρ coverage 0.89-0.91 with 100 clusters (to the WP1.9 vignette). New documented difference D-ES-2 |
| FIML 3-4 times slower than `sampleSelection` | Profiled: the default runs 3 starts, and each Newton iteration evaluated value, gradient and Hessian separately. Newton now takes the gradient from the Hessian evaluation, and the kernel reuses `pnorm()` | N = 10 000: default 2.56 → 1.22 s; one start 0.35 s against 0.83 s for `sampleSelection`. Benchmark results outside D6b unchanged |
| D6b took 51-82 s | Every start ran every fallback optimiser up to ρ = ±1. Fallbacks are now skipped once a run ends within 1e-6 of ±1 (`boundary-stop` in the path) | 3.5 s, same end point and warnings; new test |

The details are in BENCHMARK_G1.md sections 4.4, 4.5, 6.2 and 6.3.

**Monte Carlo smoke test (0.8.1; design s.6), against 0.6.0:**
- 200/200 FIML fits converge.
- FIML estimates, standard errors and effects differ from 0.6.0 by at most
  9e-9, and the log-likelihood by 2e-13. This is the optimiser tolerance:
  the starting values moved slightly with the probit fix.
- The two-step differs by at most 1.4e-6, from the probit fix.

**Package check (0.8.1):**
- Tests on the source: 643 expectations (5 new), 0 failures.
- `R CMD check --as-cran`: 0 errors, 0 warnings, 1 NOTE (V8 absent,
  environment only).
- Under check, 631 pass and 5 are skipped on CRAN, including the new
  boundary test.

## Not verified, and limits

- `endoSwitch`'s effect standard errors (paired t-tests of the
  predictions) are not comparable with our delta-method ones, so they were
  not compared.
- **Cluster-robust intervals for FIML σ and ρ** cover 0.89-0.91 with 100
  clusters. This goes into the WP1.9 vignette `simulation-validation`;
  small-cluster corrections are a possible later extension.
- **The default FIML fit** runs three starts, deliberately. It stays
  1.5-3 times slower than a single-start fit in `sampleSelection`;
  `switch_control(starts = 1)` matches or beats it at N ≥ 2000.
- **The boundary stop** skips the fallbacks for a start that reaches
  |ρ| = 1. An interior maximum reachable only by a fallback from that start
  would be missed from that start; the other starts remain.
- **Upstream reports** of D-SS-1, D-ES-1 and D-ES-2 are left to the owner.

## Next
- WP1.9 (v0.9.0): vignettes `classical-esr`, `treatment-effects` and
  `simulation-validation`, the latter with the finite-sample coverage at
  N ≤ 1000. Also README, CRAN preparation, and GitHub Actions once the
  owner creates the repository.
