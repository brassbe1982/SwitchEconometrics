# Cross-software benchmarks, Generation 1: results and interpretation

WP1.8, 22-23 November 2026. Protocol and tolerances:
[BENCHMARK_PROTOCOL.md](../BENCHMARK_PROTOCOL.md) section 3, fixed in WP1.1
before any estimator code existed. R implementations only (plan decision
D11 as amended by the owner). The full generated tables are in
[BENCHMARK_G1_generated.md](BENCHMARK_G1_generated.md), every check is in
`benchmark_g1.csv`, and the evidence for the differences is in
`benchmark_g1_diagnostics.csv`.

## 1. Verdict

**1048 of 1145 checks pass; 97 exceed their tolerance. Every one of the
97 is explained with evidence (section 4). None of them points to an error
in SwitchEconometrics.** They fall into three groups:

| Group | Checks | Cause | Evidence |
| --- | --- | --- | --- |
| Dataset D6b (misspecified example from the `sampleSelection` vignette) | 62 | Neither package reaches a maximum: `sampleSelection` stops with code 3 where the gradient is 139; SwitchEconometrics moves to the boundary ρ = ±1 and reports non-convergence. Our log-likelihood is 237 higher | E2 |
| `endoSwitch` standard errors | 30 | `endoSwitch` takes its Hessian from `maxLik::numericHessian`. A Richardson-extrapolated Hessian of `endoSwitch`'s own log-likelihood equals our analytic Hessian | E1 |
| `endoSwitch` two-stage, dataset D7b | 5 | Its first-stage `glm()` stops on the default deviance rule, leaving a probit score of 1.2e-3; with a tight tolerance `glm()` agrees with our probit | E3 |

**Where both packages reach the maximum, the estimates agree:**
- With `sampleSelection` (10 datasets), FIML agrees to 3.3e-6 in the
  estimates, 2.7e-11 in the log-likelihood and 7.2e-6 (relative) in the
  standard errors. The two-step coefficients agree to 9.3e-10.
- With `endoSwitch` (6 datasets), FIML agrees to 4.4e-8 in the estimates
  and 1.1e-13 in the log-likelihood (with a tight `reltol`). Its effects
  and conditional expectations agree to 7.4e-5, and our formulas evaluated
  at its estimates reproduce its values to 1.4e-14.
- Our log-likelihood is never below the benchmark's.

**One defect in SwitchEconometrics was found and fixed** (section 6). The
probit first stage stopped on `glm.fit`'s deviance rule and could leave
score components of order 1e-4 with large-scale regressors. Our two-step
results moved by about 1e-6 in these datasets. The probit is now polished
with Newton steps (score below 1e-12), and a regression test guards it.

**Two documented differences in other packages** (section 5): the two-step
variance recovery of `sampleSelection` (D-SS-1, confirmed) and of
`endoSwitch` (D-ES-1, new) is inconsistent.

**AC3 is proposed as met, with these documented differences, for the
owner to confirm** (section 7).

## 2. What was run

| Item | Value |
| --- | --- |
| Software | SwitchEconometrics 0.8.0, `sampleSelection` 1.2-16, `endoSwitch` 1.0.0 (CRAN archive, 2020; installed into the private library `runs/lib_bench`), `maxLik` 1.6-10, `mvtnorm` 1.4-2, R 4.6.2 |
| Scripts | `scripts/benchmark_g1.R` (all checks and the generated tables); `scripts/benchmark_g1_diagnostics.R` (evidence E1-E3) |
| Data | saved in `runs/benchmarks_g1/` (workspace, not in git) |
| Comparisons | FIML: log-likelihood, every parameter, every standard error, ATT, ATU, ATE, TH, BH1, BH0 and the four conditional expectations (largest per-unit difference). Two-step: probit, outcome and selection-correction coefficients |
| Effects with `sampleSelection` | It reports none, so our formulas are evaluated at both sets of estimates (protocol) |
| `endoSwitch` FIML | Two runs per dataset: its default (BFGS with numerical derivatives), and BFGS with `reltol = 1e-14`, both decided before the run |

**Datasets** (protocol section 3):

| Id | Data | N | `sampleSelection` | `endoSwitch` |
| --- | --- | --- | --- | --- |
| D1-D3 | base Monte Carlo design, (ρ₁, ρ₀) = (0.6, 0.4) | 500, 2000, 10 000 | yes | yes |
| D4 | weak exclusion (γ_z = −0.1) | 2000 | yes | yes |
| D5 | different regressors per regime (`verify_math.R` design) | 3000 | yes | no (same regressors in both regimes required) |
| D6a | `sampleSelection` vignette, Tobit-5, correct specification, its seed 0 | 500 | yes | no (as D5) |
| D6b | vignette, non-normal errors (ε² − 1), seed 5, `iterlim = 20` | 1000 | yes | no |
| D6c | vignette, no exclusion restriction, seed 6, `iterlim = 20` | 1000 | yes | no (selection and outcome regressors identical) |
| D6d | `?selection` Tobit-5 example; the page sets no seed, so seed 0 was added | 500 | yes | no (as D5) |
| D7a | `endoSwitch` `ImpactData`, its documented example | 408 | yes | yes |
| D7b | `ImpactData`, larger specification (6 selection and 4 outcome regressors), chosen before the run | 408 | yes | yes |

For D6b and D6c the vignette limits the iterations to 20. `sampleSelection`
was run with that limit and, as a supplementary run, with its default.

## 3. Results

Excluding D6b (section 4.2):

| Benchmark | Log-likelihood | Estimates | Standard errors | Effects and conditional expectations |
| --- | --- | --- | --- | --- |
| `sampleSelection` ML | 10/10; largest difference 2.7e-11 | 126/126; 3.3e-6 | 126/126; 7.2e-6 relative | 100/100; 5.8e-6 |
| `sampleSelection` two-step | – | 106/106; 9.3e-10 | not reported by `sampleSelection` (D-SS-1) | – |
| `endoSwitch` FIML, default | 6/6; 9.9e-8 | 84/84; 3.5e-5 | 71/84; ratios 0.969-1.017 | 54/54; 7.4e-5 |
| `endoSwitch` FIML, `reltol = 1e-14` | 6/6; 1.1e-13 | 84/84; 4.4e-8 | 67/84; ratios 0.957-1.034 | 54/54; 4.7e-5 |
| `endoSwitch`: our formulas at its estimates | – | – | – | 48/48; 1.4e-14 |
| `endoSwitch` two-stage | – | 67/72; 6.2e-6 | not compared (naive OLS standard errors) | – |

Estimates and effects are scaled as in the protocol: |d| / max(1, |value|).
"Ratios" are our standard error divided by `endoSwitch`'s.

**Speed** (seconds per FIML fit; shared machine, indicative only):

| | N = 408-500 | N = 2000-3000 | N = 10 000 |
| --- | --- | --- | --- |
| SwitchEconometrics | 0.23-0.33 | 0.53-0.58 | 2.0 |
| `sampleSelection` | 0.06-0.09 | 0.15-0.23 | 0.69 |
| `endoSwitch` | 2.5-10.6 | 5.6-6.8 | 12.1 |

SwitchEconometrics is about 3-4 times slower than `sampleSelection`. A fit
also computes the two-step starting values and the identification checks.

## 4. Differences beyond tolerance

### 4.1 `endoSwitch` standard errors (30 checks; evidence E1)

**What differs.** At the same optimum (estimates within 4.4e-8),
`endoSwitch`'s standard errors differ from ours by up to 4.3%, mostly for
the regime-0 parameters. They also change by up to 3.7% between its own
two runs, whose estimates differ by less than 1e-4.

**Evidence** (`benchmark_g1_diagnostics.R`, E1; datasets D2, D3, D4), at
`endoSwitch`'s own estimates:

| Source of the Hessian | Agreement |
| --- | --- |
| Hessian reported by `endoSwitch` vs `maxLik::numericHessian` of its log-likelihood function | identical (difference 0) |
| Richardson-extrapolated Hessian (`numDeriv`) of `endoSwitch`'s own function vs the SwitchEconometrics analytic Hessian | standard errors within 4e-9 (D2, D4) and 2.5e-3 (D3) |
| Reported `endoSwitch` standard errors vs the analytic ones | 1.4% (D2), 3.2% (D3), 2.6% (D4) |

**Conclusion.**
- The difference is the error of a first-order finite-difference Hessian.
  The likelihood itself is the same: at the common optimum the two
  log-likelihoods agree to 1.1e-13.
- The analytic Hessian of SwitchEconometrics equals the numerical one
  (V05), and `sampleSelection`'s analytic standard errors agree with ours
  to 7.2e-6.

### 4.2 Dataset D6b (62 checks; evidence E2)

D6b is the vignette's illustration of misspecification: the errors are
ε² − 1, not normal.
- `sampleSelection` stops after 4 iterations with code 3 ("Last step could
  not find a value above the current. Boundary of parameter space?"), with
  and without the vignette's `iterlim = 20`. Its standard errors for three
  parameters are NaN.
- At its end point the gradient of the log-likelihood is 139 (largest
  component, working scale): the point is not a maximum. Our likelihood
  function reproduces its log-likelihood there (−1665.94).
- SwitchEconometrics continues to ρ₀ = −1, ρ₁ = +1 (log-likelihood
  −1428.77, 237 higher) and reports non-convergence, the boundary and an
  ill-conditioned Hessian. The fit took 51-82 s in the two runs.

Neither package has a valid optimum here, so the comparison has no
reference value. Our package does not stop at a worse point, and it warns
correctly.

### 4.3 `endoSwitch` two-stage on D7b (5 checks; evidence E3)

- The differences are 1.0e-6 to 6.2e-6, on the probit and on two outcome
  coefficients.
- `endoSwitch2Stage` fits the probit with `glm()` at its default
  convergence rule. In D7b, with regressors such as age and farm size, that
  leaves a largest score component of 1.2e-3.
- Refitted with `epsilon = 1e-14`, `glm()` agrees with our probit to
  2.5e-8. The `sampleSelection` probit agrees with ours to 1.4e-11.

## 5. Documented differences in the benchmark packages

| Id | Package | Difference | Status |
| --- | --- | --- | --- |
| D-SS-1 | `sampleSelection` 1.2-16, two-step | variance recovery (θ̂δ̄)² instead of θ̂²δ̄; outcome standard errors not reported | found in WP1.4; confirmed again below |
| D-ES-1 | `endoSwitch` 1.0.0, `endoSwitch2Stage()` | σ̂ⱼ² = mean(e² + θ̂ⱼ² λⱼ wᵢ). The Heckman (1979) estimator adds θ̂ⱼ² mean δⱼ with δ₁ = λ₁(λ₁ + w) and δ₀ = λ₀(λ₀ − w). The λⱼ² term is missing, and for regime 0 the sign of the w term is wrong | new; used by `endoSwitch` only for its FIML starting values, but returned to users by the exported function |

**Large-sample check** (base design with σ₀ = 0.8, σ₁ = 1.2, ρ₀ = 0.4,
ρ₁ = 0.6):

| n | Estimator | σ₀ | ρ₀ | σ₁ | ρ₁ |
| --- | --- | --- | --- | --- | --- |
| | truth | 0.8000 | 0.4000 | 1.2000 | 0.6000 |
| 200 000 | SwitchEconometrics two-step | 0.7959 | 0.3774 | 1.2008 | 0.5944 |
| 200 000 | `endoSwitch2Stage` | 0.7797 | 0.3853 | 1.1394 | 0.6264 |
| 200 000 | `sampleSelection` 2step | 0.7834 | 0.3834 | 1.1467 | 0.6224 |
| 400 000 | SwitchEconometrics two-step | 0.8000 | 0.3903 | 1.2008 | 0.5990 |
| 400 000 | `endoSwitch2Stage` | 0.7827 | 0.3990 | 1.1386 | 0.6317 |
| 400 000 | `sampleSelection` 2step | 0.7866 | 0.3970 | 1.1458 | 0.6277 |

**Consequences:**
- The other two estimators miss σ₁ by about 0.06 at both sample sizes, so
  the error does not shrink with n. They are inconsistent.
- SwitchEconometrics recovers the truth within sampling error. Its ρ̂₀ is
  0.377 and 0.390. The standard error of θ̂₀ = σ̂₀ρ̂₀ is 0.0116 and 0.0083,
  about 0.015 and 0.010 for ρ̂₀, so these gaps are 1.5 and 1.0 standard
  errors.
- In the benchmark, σⱼ and ρⱼ of both two-step estimators are therefore
  listed as documented differences (68 entries), not as checks.

**Other differences, not compared:**
- `endoSwitch` reports standard errors of its effects from paired t-tests
  of the unit-level predictions. They ignore the estimation uncertainty of
  the parameters, so they are not comparable with our delta-method
  standard errors.
- `endoSwitch` weights the likelihood but not the effects.

Reporting D-SS-1 and D-ES-1 upstream is an external action and is left to
the owner. `endoSwitch` is archived, so an upstream fix is unlikely.

## 6. Defect found in SwitchEconometrics and fixed (0.8.0)

| Item | Detail |
| --- | --- |
| Found | The first benchmark run: two-step differences of 1e-6 to 7e-6 with both packages, on D6c and D7b |
| Cause | The probit first stage stopped on `glm.fit`'s relative-deviance rule (`epsilon = 1e-10`). With large-scale regressors the score was left at 3.6e-5 (D6c) and 2.7e-4 (D7b); the `sampleSelection` probit reached 2e-11 and 8e-10 |
| Fix | `R/est_two_step.R`: after `glm.fit`, Newton steps on the exact probit Hessian. A step is kept only if it lowers the largest score component. The polish is skipped when `glm.fit` did not converge or reports separation |
| Result | Score below 1.1e-13 on D6c and D7b. Two-step coefficients agree with `sampleSelection` to 9.3e-10 in all 11 datasets (before: up to 1.1e-6) |
| Test | `test-estimation.R`: "the probit first stage is solved to machine precision" (largest score 5.0e-5 before the fix, 4.4e-14 after) |
| Effect on earlier results | Two-step estimates moved by about 1e-6 in the benchmark datasets (D7b: 1.1e-6), and FIML results agree with `sampleSelection` as before (3.3e-6). The Monte Carlo study (0.6.0) is unaffected at the precision it reports |

## 7. Acceptance criterion AC3

AC3: "Match benchmark estimates within documented numerical tolerances"
(protocol: `sampleSelection` ML and two-step, and `endoSwitch`).

| Part | Result |
| --- | --- |
| `sampleSelection` ML | met in every dataset where `sampleSelection` reaches a maximum (10 of 11); D6b has no valid reference (section 4.2) |
| `sampleSelection` two-step | met in all 11 datasets; σ and ρ excluded by D-SS-1 |
| `endoSwitch` FIML | estimates, log-likelihood and effects met in all 6 datasets; standard errors exceed the 1% tolerance in 30 of 168 comparisons, explained by its numerical Hessian (section 4.1) |
| `endoSwitch` two-stage | met in 5 of 6 datasets; D7b explained by its `glm()` tolerance (section 4.3); σ and ρ excluded by D-ES-1 |

**Proposal for the owner:** mark AC3 as met, with these documented
differences. Every difference beyond tolerance has a cause shown by
evidence, and the cause lies in the other package (numerical Hessian,
probit stopping rule, non-convergence on a misspecified model). The one
cause that lay in SwitchEconometrics has been fixed.

## 8. Files

| File | Content |
| --- | --- |
| `04_Validation/scripts/benchmark_g1.R` | all benchmark checks; writes the generated tables and CSV files |
| `04_Validation/scripts/benchmark_g1_diagnostics.R` | evidence E1-E3 |
| `04_Validation/results/BENCHMARK_G1_generated.md` | software versions, summary, failed checks, fits, the variance-recovery table and one table per dataset |
| `04_Validation/results/benchmark_g1.csv`, `benchmark_g1_variance_check.csv`, `benchmark_g1_diagnostics.csv` | generated data |
| `runs/benchmarks_g1/`, `runs/lib_bench/`, `runs/downloads/endoSwitch_1.0.0/` | datasets, private library and the archived source (workspace, not in git; MD5 of the source tarball 3462320a4dcd333ab94af83479943a0b) |
