# WP1.8: Cross-software benchmarks

Version 0.8.0. Completed 23 November 2026. Status: **benchmarks run and
reported. 1048 of 1145 checks pass, and every difference beyond tolerance
is explained with evidence. AC3 is proposed as met with documented
differences; the owner decides.**

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

## Not verified, and limits

- Weighted and clustered fits were not benchmarked. (`endoSwitch` weights
  its likelihood but not its effects.)
- `endoSwitch`'s effect standard errors (paired t-tests of the
  predictions) are not comparable with our delta-method ones, so they were
  not compared.
- On D6b our FIML fit took 51-82 s before reporting non-convergence. This
  was not investigated further.
- SwitchEconometrics FIML is about 3-4 times slower than `sampleSelection`
  per fit.
- Reporting D-SS-1 and D-ES-1 upstream is left to the owner.

## Next

- The owner confirms AC3 (BENCHMARK_G1.md s.7).
- WP1.9 (v0.9.0): vignettes `classical-esr`, `treatment-effects` and
  `simulation-validation`, the latter with the finite-sample coverage at
  N ≤ 1000. Also README, CRAN preparation, and GitHub Actions once the
  owner creates the repository.
