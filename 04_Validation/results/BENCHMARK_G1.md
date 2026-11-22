# Cross-software benchmarks, Generation 1: results and interpretation

WP1.8, 22-23 November 2026 (versions 0.8.0 and 0.8.1).

**Sources.**
- Protocol and tolerances: [BENCHMARK_PROTOCOL.md](../BENCHMARK_PROTOCOL.md)
  section 3, fixed in WP1.1 before any estimator code existed. R
  implementations only (plan decision D11 as amended by the owner).
- Generated tables: [BENCHMARK_G1_generated.md](BENCHMARK_G1_generated.md).
- Every check: `benchmark_g1.csv`.
- Evidence for the differences: `benchmark_g1_diagnostics.csv`.

**Scope of 0.8.1.** At the owner's request it closes three open items:
- weighted and clustered fits had not been benchmarked (sections 4.4 and
  4.5);
- the FIML fit was slower than `sampleSelection` (section 6.2);
- the slow failure on a misspecified example (section 6.3).

## 1. Verdict

**1275 of 1378 checks pass; 103 exceed their tolerance. Every one of the
103 is explained with evidence (section 4). None of them points to an
error in SwitchEconometrics.**

| Group | Checks | Cause | Evidence |
| --- | --- | --- | --- |
| Dataset D6b (misspecified example from the `sampleSelection` vignette) | 62 | Neither package reaches a maximum. `sampleSelection` stops with code 3 where the gradient is 139. SwitchEconometrics moves to the boundary ρ = ±1, reports non-convergence, and has a log-likelihood 237 higher | E2 |
| `endoSwitch` standard errors | 36 | `endoSwitch` takes its Hessian from `maxLik::numericHessian`. A Richardson-extrapolated Hessian of its own log-likelihood equals our analytic Hessian | E1 |
| `endoSwitch` two-stage, dataset D7b | 5 | Its first-stage `glm()` stops on the default deviance rule, leaving a probit score of 1.2e-3. With a tight tolerance, `glm()` agrees with our probit | E3 |

**Agreement where both packages reach the maximum:**
- **`sampleSelection`** (10 datasets): estimates 3.3e-6, log-likelihood
  2.7e-11, standard errors 7.2e-6 (relative); two-step coefficients
  9.3e-10.
- **`endoSwitch`** (6 datasets, `reltol = 1e-14`): estimates 4.4e-8,
  log-likelihood 1.1e-13; effects and conditional expectations 4.7e-5. Our
  formulas evaluated at its estimates reproduce its values to 1.4e-14.
- **Never a worse point:** our log-likelihood is never below the
  benchmark's.

**Weighted and clustered fits (0.8.1).**
- Weighted estimates, log-likelihood, and Hessian, sandwich and cluster
  standard errors agree with `sampleSelection` on replicated rows combined
  with the `sandwich` package. The covariances agree to 2e-6.
- Sandwich, OPG and cluster standard errors on clustered data agree with
  the `sandwich` package to 7e-10.
- A Monte Carlo under clustering supports the cluster standard errors,
  including the two-step ones, for which no other software exists. With
  100 clusters, the FIML intervals for σ and ρ cover 0.89-0.91
  (section 4.5).

**Defects found in SwitchEconometrics and fixed** (section 6):
1. **Probit stopping rule (0.8.0).** The probit first stage stopped on
   `glm.fit`'s deviance rule. It is now polished to machine precision.
2. **Default fit time (0.8.1).** Each Newton iteration made a separate
   gradient evaluation. Now:
   - the default fit takes 1.2 s instead of 2.6 s at N = 10 000;
   - with one start it is 1.4-2.4 times faster than `sampleSelection` at
     N ≥ 2000.
3. **Fallbacks at the boundary (0.8.1).** Fallback optimisers ran after a
   likelihood had already reached ρ = ±1. D6b now stops in 3.5 s instead of
   51-82 s, with the same result.

**Documented differences in the other packages** (section 5):
- D-SS-1 (confirmed): the two-step variance recovery of `sampleSelection`
  is inconsistent.
- D-ES-1 (new): the same for `endoSwitch`.
- D-ES-2 (new): `endoSwitch` ignores the weights in its effects.

**AC3 is met with these documented differences** (section 7). The owner
approved this on 23 November 2026, on condition that the three open items
were addressed first; they are.

## 2. What was run

| Item | Value |
| --- | --- |
| Software | SwitchEconometrics 0.8.1; `sampleSelection` 1.2-16; `endoSwitch` 1.0.0 (CRAN archive, 2020; private library `runs/lib_bench`); `sandwich` 3.1-3; `maxLik` 1.6-10; `mvtnorm` 1.4-2; R 4.6.2 |
| Scripts | `scripts/benchmark_g1.R` (all checks and generated tables); `scripts/benchmark_g1_diagnostics.R` (evidence E1-E3); `scripts/cluster_mc_g1.R` (Monte Carlo under clustering) |
| Data | saved in `runs/benchmarks_g1/` (workspace, not in git) |
| Comparisons, FIML | log-likelihood, every parameter, every standard error, ATT, ATU, ATE, TH, BH1, BH0, and the four conditional expectations (largest per-unit difference) |
| Comparisons, two-step | probit, outcome and selection-correction coefficients |
| Effects with `sampleSelection` | It reports none, so our formulas are evaluated at both sets of estimates (protocol) |
| `endoSwitch` FIML | Two runs per dataset: its default (BFGS with numerical derivatives), and BFGS with `reltol = 1e-14`. Both were decided before the run |

**Datasets.** D1-D7 follow protocol section 3; D8-D9 were added in 0.8.1.
All were fixed before their run.

| Id | Data | N | `sampleSelection` | `endoSwitch` |
| --- | --- | --- | --- | --- |
| D1-D3 | base Monte Carlo design, (ρ₁, ρ₀) = (0.6, 0.4) | 500, 2000, 10 000 | yes | yes |
| D4 | weak exclusion (γ_z = −0.1) | 2000 | yes | yes |
| D5 | different regressors per regime (`verify_math.R` design) | 3000 | yes | no (same regressors in both regimes required) |
| D6a | `sampleSelection` vignette, Tobit-5, correct specification, its seed 0 | 500 | yes | no (as D5) |
| D6b | vignette, non-normal errors (ε² − 1), seed 5, `iterlim = 20` | 1000 | yes | no |
| D6c | vignette, no exclusion restriction, seed 6, `iterlim = 20` | 1000 | yes | no (selection and outcome regressors identical) |
| D6d | `?selection` Tobit-5 example (the page sets no seed; seed 0 added) | 500 | yes | no (as D5) |
| D7a | `endoSwitch` `ImpactData`, its documented example | 408 | yes | yes |
| D7b | `ImpactData`, larger specification (6 selection, 4 outcome regressors) | 408 | yes | yes |
| D8 | base design, integer weights 1-3, 100 clusters | 2000 | on replicated rows, with `sandwich` | yes (`Weight`) |
| D8b | base design, continuous weights U(0.5, 2) | 2000 | no (weights ignored in Tobit-5) | yes (`Weight`) |
| D9 | clustered data: 100 clusters of 20; cluster share 0.5 in x₁ and z₁, 0.3 in the errors | 2000 | with `sandwich` | no (no robust covariances) |

**Notes on the datasets:**
- For D6b and D6c the vignette limits the iterations to 20.
  `sampleSelection` was run with that limit and, as a supplementary run,
  with its default.
- `sampleSelection` warns that it ignores weights in Tobit-5 models. The
  weighted comparison with it therefore uses the identity below.

**Identity used for the weighted comparison.** With integer weights,
- our weighted log-likelihood and estimates equal those of the data with
  each row replicated *w* times;
- our sampling-weight sandwich H⁻¹(Σ wᵢ² sᵢsᵢ′)H⁻¹ equals
  `sandwich::vcovCL` on the replicated data, clustered by original row
  (HC0, no cluster adjustment);
- our cluster covariance equals `vcovCL` clustered by cluster (HC0,
  G/(G − 1)).

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
| D8: `sampleSelection` on replicated rows + `sandwich` | 1/1; 2.2e-11 | 26/26; 3.6e-7 | Hessian 13/13 (1.3e-6), sandwich 13/13 (2.0e-6), cluster 13/13 (2.0e-6) | 6/6; 5.8e-7 |
| D8, D8b: `endoSwitch` weighted | 2/2; 9.1e-13 | 26/26; 3.6e-8 | 20/26 (numerical Hessian, section 4.1) | D-ES-2 (section 5) |
| D9: `sampleSelection` + `sandwich` | 1/1; 0 | 52/52; 7.9e-11 | Hessian, sandwich, OPG, cluster: 52/52 (6.8e-10) | – |

**How to read the table.**
- Estimates and effects are scaled as in the protocol: |d| / max(1,
  |value|).
- Standard errors are relative differences.
- "Ratios" are our standard error divided by `endoSwitch`'s.

## 4. Differences beyond tolerance, and the weighted and clustered checks

### 4.1 `endoSwitch` standard errors (36 checks; evidence E1)

**What differs.** At the same optimum, `endoSwitch`'s standard errors
differ from ours by up to 4.3%: 30 checks unweighted and 6 weighted, mostly
for the regime-0 parameters. The estimates agree to 4.4e-8 unweighted and
3.6e-8 weighted. Its standard errors also change by up to 3.7% between its
own two runs, whose estimates differ by less than 1e-4.

**Evidence** (E1; datasets D2, D3, D4), at `endoSwitch`'s own estimates:

| Source of the Hessian | Agreement |
| --- | --- |
| Hessian reported by `endoSwitch` vs `maxLik::numericHessian` of its log-likelihood function | identical (difference 0) |
| Richardson-extrapolated Hessian (`numDeriv`) of `endoSwitch`'s own function vs the SwitchEconometrics analytic Hessian | standard errors within 4e-9 (D2, D4) and 2.5e-3 (D3) |
| Reported `endoSwitch` standard errors vs the analytic ones | 1.4% (D2), 3.2% (D3), 2.6% (D4) |

**Conclusion.**
- The difference is the error of a first-order finite-difference Hessian.
- The likelihood itself is the same: at the common optimum the
  log-likelihoods agree to 1.1e-13.
- Our analytic Hessian equals the numerical one (V05), and the analytic
  standard errors of `sampleSelection` agree with ours to 7.2e-6.

### 4.2 Dataset D6b (62 checks; evidence E2)

D6b is the vignette's illustration of misspecification: the errors are
ε² − 1, not normal.

**`sampleSelection`:**
- It stops after 4 iterations with code 3 ("Last step could not find a
  value above the current. Boundary of parameter space?"). This happens
  with and without the vignette's `iterlim = 20`.
- Its standard errors for three parameters are NaN.
- At its end point the gradient of the log-likelihood is 139 (largest
  component, working scale), so the point is not a maximum. Our likelihood
  function reproduces its log-likelihood there (−1665.94).

**SwitchEconometrics:**
- It continues to ρ₀ = −1, ρ₁ = +1, with a log-likelihood of −1428.77, 237
  higher.
- It reports non-convergence, the boundary and an ill-conditioned Hessian.
- Since 0.8.1 it stops in 3.5 s (section 6.3).

Neither package has a valid optimum here, so the comparison has no
reference value. Our package does not stop at a worse point, and it warns
correctly.

### 4.3 `endoSwitch` two-stage on D7b (5 checks; evidence E3)

- The differences are 1.0e-6 to 6.2e-6, on the probit and two outcome
  coefficients.
- `endoSwitch2Stage` fits the probit with `glm()` at its default
  convergence rule. With regressors such as age and farm size, that leaves
  a largest score component of 1.2e-3.
- Refitted with `epsilon = 1e-14`, `glm()` agrees with our probit to
  2.5e-8. The `sampleSelection` probit agrees with ours to 1.4e-11.

### 4.4 Weighted and clustered fits against other software (0.8.1)

**D8, integer weights, against `sampleSelection` on the replicated rows**
(all 72 checks pass):
- log-likelihood 2.2e-11, estimates 3.6e-7;
- weighted effects at both estimates 5.8e-7;
- standard errors from the Hessian 1.3e-6, the sampling-weight sandwich
  2.0e-6 and the cluster covariance 2.0e-6, against `sandwich::vcovCL`.

This confirms our weighted likelihood and all three weighted covariances
with an independent implementation.

**D8 and D8b, against `endoSwitch`'s `Weight`:**
- log-likelihood 9.1e-13 and estimates 3.6e-8, for integer and continuous
  weights;
- six Hessian standard errors exceed 1% (1.3-3.4%), for the reason of
  section 4.1.

**D9, clustered data, against the `sandwich` package applied to
`sampleSelection`'s fit** (all 105 checks pass):
- Hessian, sandwich (`sandwich()`), OPG (`vcovOPG()`) and cluster
  (`vcovCL(type = "HC0", cadjust = TRUE)`) standard errors agree to
  6.8e-10;
- estimates agree to 7.9e-11 for every covariance choice.

### 4.5 Clustered data: Monte Carlo of the cluster-robust standard errors (0.8.1)

**Why.** No R package computes cluster-robust standard errors for the
two-step ESR, so a simulation is their external check. It also covers the
coverage of the FIML cluster standard errors, which the formula checks of
section 4.4 cannot show. The run is `scripts/cluster_mc_g1.R`, and its
output is `cluster_mc_G1.csv`.

**Design** (fixed before the run; supplementary, not gated):
- N = 2000 in 100 clusters of 20;
- the design of D9: cluster share 0.5 in x₁ and z₁, 0.3 in the errors;
- R = 500, seed 20261123; 234 s on 2 workers.

| Estimator and covariance | SE ratio (mean SE / empirical SD) | 95% coverage |
| --- | --- | --- |
| FIML, Hessian (ignores clustering) | 0.47-1.03 | 0.65-0.96 |
| FIML, cluster: γ and β | 0.94-1.03 | 0.92-0.95 |
| FIML, cluster: σ and ρ | 0.93-0.96 | 0.89-0.91 |
| Two-step, model-based (ignores clustering) | 0.47-1.03 | 0.65-0.95 |
| Two-step, cluster: γ, β, θ | 0.94-1.04 | 0.93-0.96 |

**Findings:**
- **Clustering matters in this design.** Ignoring it understates standard
  errors by up to half. Only x₂, which has no cluster component, keeps
  correct standard errors.
- **The cluster covariances repair this.** For the two-step, which no other
  software implements, the ratios are 0.94-1.04 and coverage 0.93-0.96.
- **FIML σ and ρ fall short with 100 clusters.** Their cluster standard
  errors are 4-7% too small, and coverage is 0.89-0.91; the Monte Carlo
  error is about 0.01. This is the known downward bias of cluster-robust
  variance estimators with a moderate number of clusters (only the
  G/(G − 1) correction is applied). The formula itself agrees with
  `vcovCL` exactly (section 4.4).
- **Carried to WP1.9.** The `simulation-validation` vignette will state
  this, with the finite-sample coverage at N ≤ 1000. Small-cluster
  corrections (for example CR2) are a possible later extension; they are
  not planned for G1.

## 5. Documented differences in the benchmark packages

| Id | Package | Difference | Status |
| --- | --- | --- | --- |
| D-SS-1 | `sampleSelection` 1.2-16, two-step | Variance recovery uses (θ̂δ̄)² instead of θ̂²δ̄; outcome standard errors are not reported | found in WP1.4; confirmed again below |
| D-ES-1 | `endoSwitch` 1.0.0, `endoSwitch2Stage()` | σ̂ⱼ² = mean(e² + θ̂ⱼ² λⱼ wᵢ). The Heckman (1979) estimator adds θ̂ⱼ² mean δⱼ, with δ₁ = λ₁(λ₁ + w) and δ₀ = λ₀(λ₀ − w). The λⱼ² term is missing, and for regime 0 the sign of the w term is wrong | new. `endoSwitch` uses these values only as FIML starting values, but the exported function returns them to users |
| D-ES-2 | `endoSwitch` 1.0.0, `endoSwitch(Weight = )` | The weights enter the likelihood but not the effects, which are unweighted means. On D8 its ATT is 0.9284 against our weighted 0.9313; our unweighted formula at its estimates reproduces its values (2.3e-5, its rounding to 4 decimals) | new; documented, not a check |

**Large-sample check of the variance recovery** (base design with
σ₀ = 0.8, σ₁ = 1.2, ρ₀ = 0.4, ρ₁ = 0.6):

| n | Estimator | σ₀ | ρ₀ | σ₁ | ρ₁ |
| --- | --- | --- | --- | --- | --- |
| | truth | 0.8000 | 0.4000 | 1.2000 | 0.6000 |
| 200 000 | SwitchEconometrics two-step | 0.7959 | 0.3774 | 1.2008 | 0.5944 |
| 200 000 | `endoSwitch2Stage` | 0.7797 | 0.3853 | 1.1394 | 0.6264 |
| 200 000 | `sampleSelection` 2step | 0.7834 | 0.3834 | 1.1467 | 0.6224 |
| 400 000 | SwitchEconometrics two-step | 0.8000 | 0.3903 | 1.2008 | 0.5990 |
| 400 000 | `endoSwitch2Stage` | 0.7827 | 0.3990 | 1.1386 | 0.6317 |
| 400 000 | `sampleSelection` 2step | 0.7866 | 0.3970 | 1.1458 | 0.6277 |

**What the table shows:**
- **The other two are inconsistent.** They miss σ₁ by about 0.06 at both
  sample sizes, so the error does not shrink with n.
- **SwitchEconometrics recovers the truth within sampling error.** Its ρ̂₀
  is 0.377 and 0.390. The standard error of θ̂₀ = σ̂₀ρ̂₀ is 0.0116 and
  0.0083, about 0.015 and 0.010 for ρ̂₀, so these gaps are 1.5 and 1.0
  standard errors.
- **Consequence for the benchmark.** σⱼ and ρⱼ of both two-step estimators
  are listed as documented differences (68 entries), not as checks.

**Effect standard errors of `endoSwitch`.** It reports them from paired
t-tests of the unit-level predictions. These ignore the estimation
uncertainty of the parameters and are not comparable with our delta-method
standard errors.

**Upstream reports.** Reporting D-SS-1, D-ES-1 and D-ES-2 upstream is an
external action and is left to the owner. `endoSwitch` is archived, so an
upstream fix is unlikely.

## 6. Defects found in SwitchEconometrics and fixed

### 6.1 Probit stopping rule (0.8.0)

| Item | Detail |
| --- | --- |
| Found | The first benchmark run showed two-step differences of 1e-6 to 7e-6 with both packages, on D6c and D7b |
| Cause | The probit first stage stopped on `glm.fit`'s relative-deviance rule (`epsilon = 1e-10`). With large-scale regressors the score was left at 3.6e-5 (D6c) and 2.7e-4 (D7b); the `sampleSelection` probit reached 2e-11 and 8e-10 |
| Fix | `R/est_two_step.R`: after `glm.fit`, Newton steps on the exact probit Hessian. A step is kept only if it lowers the largest score component. The steps are skipped when `glm.fit` did not converge or reports separation |
| Result | Score below 1.1e-13 on D6c and D7b. The two-step agrees with `sampleSelection` to 9.3e-10 in all 11 datasets (before: up to 1.1e-6) |
| Test | "the probit first stage is solved to machine precision": largest score 5.0e-5 before the fix, 4.4e-14 after |
| Effect on earlier results | Two-step estimates moved by about 1e-6 (D7b: 1.1e-6). FIML results agree with `sampleSelection` as before (3.3e-6). The Monte Carlo study (0.6.0) is unaffected at the precision it reports |

### 6.2 FIML time (0.8.1)

**Cause.** A profile of a default fit at N = 10 000 showed two things:
- **Three optimisations.** The default runs three starts: the two-step
  start and two perturbed starts, used to detect lower local maxima (check
  I9). That made 23 Newton iterations in all, against one start for
  `sampleSelection`.
- **Three evaluations per iteration.** Each iteration evaluated the
  likelihood three times: value, gradient, and gradient with Hessian (41,
  41 and 42 evaluations). In addition, the kernel called `pnorm()` up to
  four times on the same argument.

**Changes** (`R/est_optimizer.R`, `R/lik_esr_gaussian.R`,
`R/lik_utils.R`):
- Newton-Raphson obtains the gradient and the Hessian from one evaluation.
- The kernel evaluates `pnorm()` once per regime and passes it on.

Both changes compute the same quantities from the same intermediate
values. The gradient-only evaluations fell from 41 to 0, and every
benchmark result outside D6b is unchanged.

**Time per fit** (median of 3; seconds):

| | N = 500 | N = 2000 | N = 10 000 |
| --- | --- | --- | --- |
| SwitchEconometrics default (3 starts), 0.8.0 | 0.33 | 0.72 | 2.56 |
| SwitchEconometrics default (3 starts), 0.8.1 | 0.27 | 0.45 | 1.22 |
| SwitchEconometrics, one start (`switch_control(starts = 1)`), 0.8.1 | 0.11 | 0.14 | 0.35 |
| `sampleSelection` (one start) | 0.09 | 0.20 | 0.83 |

**What remains:**
- **Same work.** For the same work (one start), SwitchEconometrics is now
  faster than `sampleSelection` at N ≥ 2000, and 0.02 s slower at N = 500.
- **Default fit.** The default stays 1.5-3 times slower because it
  deliberately runs three starts. That cost buys the local-maxima check,
  which matters with weak exclusions (MC_G1.md s.5.4). The help page of
  `switch_fit()` now says so and names `starts = 1`.

### 6.3 Boundary stop (0.8.1)

| Item | Detail |
| --- | --- |
| Cause | On D6b every start ran the whole fallback chain (Newton, BFGS, Newton, BHHH, Newton, optim, Newton), each up to its iteration limit, while the log-likelihood rose towards ρ = ±1 (working parameters ±22). All of them ended at the same boundary value: 64 s, and 51-82 s in the benchmark runs |
| Fix | `se_optimize()`: when a run ends with a correlation within 1e-6 of ±1, the remaining fallbacks for that start are skipped and the path records `"boundary-stop"`. The other starts still run, and the fit still reports non-convergence and the boundary |
| Result | D6b: 3.5 s, same end point (log-likelihood −1428.774, ρ = ±1, same warnings) |
| Test | "a likelihood rising to \|rho\| = 1 skips the fallback optimisers" (misspecified errors, n = 400) |
| Limit | A start that climbs to the boundary no longer tries the fallbacks. If an interior maximum existed that only a fallback optimiser could find from that start, it would be missed from that start; the other starts remain |

## 7. Acceptance criterion AC3

AC3: "Match benchmark estimates within documented numerical tolerances"
(protocol: `sampleSelection` ML and two-step, and `endoSwitch`).

| Part | Result |
| --- | --- |
| `sampleSelection` ML | met in every dataset where `sampleSelection` reaches a maximum (10 of 11); D6b has no valid reference (section 4.2) |
| `sampleSelection` two-step | met in all 11 datasets; σ and ρ excluded by D-SS-1 |
| `endoSwitch` FIML | estimates, log-likelihood and effects met in all 6 datasets, and with weights (D8, D8b). Standard errors exceed the 1% tolerance in 36 of 194 comparisons, explained by its numerical Hessian (section 4.1) |
| `endoSwitch` two-stage | met in 5 of 6 datasets; D7b explained by its `glm()` tolerance (section 4.3); σ and ρ excluded by D-ES-1 |
| Weighted and clustered fits (0.8.1) | met: 177 of 177 checks against `sampleSelection` with the `sandwich` package; cluster-robust standard errors also checked by Monte Carlo (section 4.5) |

**Decision.** AC3 is **met with documented differences**. The owner
approved this on 23 November 2026, on condition that three open items were
addressed first. They are:
- weighted and clustered fits: sections 4.4 and 4.5;
- FIML speed: section 6.2;
- the slow failure on D6b: section 6.3.

## 8. Remaining limits

| Limit | Where it goes |
| --- | --- |
| Cluster-robust intervals for FIML σ and ρ cover 0.89-0.91 with 100 clusters | WP1.9 vignette `simulation-validation`; small-cluster corrections are a possible later extension |
| The default FIML fit runs three starts and is 1.5-3 times slower than a single-start fit in another package | documented in `?switch_fit`; `switch_control(starts = 1)` |
| Two-step σ and ρ have no standard errors | by design (MC_G1.md); the delta method for them is not planned in G1 |
| Upstream reports of D-SS-1, D-ES-1, D-ES-2 | owner's decision |

## 9. Files

| File | Content |
| --- | --- |
| `04_Validation/scripts/benchmark_g1.R` | all benchmark checks; writes the generated tables and CSV files |
| `04_Validation/scripts/benchmark_g1_diagnostics.R` | evidence E1-E3 |
| `04_Validation/scripts/cluster_mc_g1.R` | Monte Carlo under clustering |
| `04_Validation/results/BENCHMARK_G1_generated.md` | software versions, summary, failed checks, fits, the variance-recovery table, one table per dataset |
| `04_Validation/results/benchmark_g1.csv`, `benchmark_g1_variance_check.csv`, `benchmark_g1_diagnostics.csv`, `cluster_mc_G1.csv` | generated data |
| `runs/benchmarks_g1/`, `runs/lib_bench/`, `runs/downloads/endoSwitch_1.0.0/` | datasets, private library and the archived source (workspace, not in git; MD5 of the source tarball 3462320a4dcd333ab94af83479943a0b) |
