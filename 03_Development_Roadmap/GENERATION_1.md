# Generation 1: Classical core (v0.1.0 → v1.0.0)

Status: in progress; WP1.1-WP1.8 done (22-23 November 2026), WP1.9 next.
- **Econometric gate approved by the owner on 22 November 2026**: the six
  questions of section 3 were accepted as proposed.
- **Computational gate requirement met on 22 November 2026** (AC1, AC2,
  AC4, AC5; ACCEPTANCE_TESTS.md section 2).

## 1. Frozen scope (specification section 16)

| Area | Content |
| --- | --- |
| Statistical | Cross-sectional data; binary endogenous selection (probit); two regime-specific continuous outcomes; Gaussian margins; Gaussian dependence of $(u, \varepsilon_1)$ and $(u, \varepsilon_0)$; regime-specific variances |
| Estimation | Two-step; FIML; multiple starting values; analytic score and Hessian with numerical verification; Hessian, OPG, sandwich and cluster covariances; parametric and nonparametric bootstrap |
| Post-estimation | Regime probabilities; the four conditional expectations; ATT, ATU, ATE, TH, BH1, BH0; counterfactual and policy predictions; LR and Wald tests of selection on unobservables |
| Software | Formula API; S3 class `switch_fit`; modular distribution and likelihood interfaces; testthat simulation tests; cross-software validation (R only); CRAN-compatible |

Not in G1: Heckman, treatment and Tobit-5 wrappers other than `esr()` (WP2.1,
plan decision D7); any Stata comparison (owner decision, 22 November 2026).

## 2. Work packages

| WP | Version | Content | Evidence | Status |
| --- | --- | --- | --- | --- |
| 1.1 | 0.1.0 | Governance, architecture and G1 derivation documents; `verify_math.R`; package skeleton; git | 26/26 numerical checks; clean `R CMD check` of the skeleton | **done**; econometric gate approved 2026-11-22 |
| 1.2 | 0.2.0 | `switch_model()`, data builder (`se_build_data()`), Gaussian margin and `distribution()`, transformations including the CPC correlation-matrix map, parameter map | 279 test expectations; `--as-cran` 1 environment-only NOTE | **done** 2026-11-22 |
| 1.3 | 0.3.0 | `lik_esr_gaussian()` (log-likelihood, score, Hessian, weights); `loglik_switch()`, `loglik_observation()`, `loglik_joint()`, `loglik_selection()`, `loglik_outcome()` | reference difference 8.9e-16; derivatives 2e-10; `sampleSelection` log-likelihood identical (AC2 met); 332 expectations | **done** 2026-11-22 |
| 1.4 | 0.4.0 | `est_two_step()` (model, robust and cluster covariances), `est_fiml()` with multistart and optimiser fallbacks, all four FIML covariance types (moved forward from WP1.5), `switch_fit()`, `switch_control()`, `esr()`, basic methods; Monte Carlo driver | FIML equals `sampleSelection` ML (3e-10); recovery; frequency weights equal replicated data; 434 expectations; Monte Carlo smoke test 200/200 converged (Marquardt NR fix) | **done** 2026-11-22 |
| 1.5 | 0.5.0 | `switch_test()` (LR, Wald, linear hypotheses), `confint()`, `summary()`, `switch_bootstrap()` (nonparametric, parametric, cluster; parallel equals serial), `switch_validate()` (I1-I11), `switch_diagnostics()`; covariances were delivered in 0.4.0 | 528 expectations; LR equals closed form; bootstrap SEs within 0.75-1.33 of the Hessian SEs; smoke Monte Carlo identical to 0.4.0; I10 amendment (IDENTIFICATION.md s.6) | **done** 2026-11-22 |
| 1.6 | 0.6.0 | `switch_effects()`, `switch_predict()` with `predict`/`fitted`/`residuals`, `switch_counterfactual()`, `switch_simulate()` with `simulate`, `switch_compare()`/`anova`, `update`, model methods, bootstrap of effects, dataset `firms` (`esr()` and the record were delivered in 0.4.0) | **AC5 met**; 631 expectations; smoke Monte Carlo with effects | **done** 2026-11-22 |
| 1.7 | 0.7.0, 0.7.1 | Monte Carlo study ([MONTE_CARLO_DESIGN.md](../04_Validation/MONTE_CARLO_DESIGN.md)): 38 cells, 28 400 replications; gate evaluation script; sandwich rerun; supplementary I5/I6 study; AC4(b) bootstrap check | `MC_G1.md`:<br>• gate 491/501 (10 failures diagnosed: no defect; finite sample, σ at ρ = 0, noise);<br>• AC4(b) 27/30;<br>• diagnosis accepted by the owner: **AC1 and AC4 met** with documented exceptions;<br>• 0.7.1: I6 threshold lowered to R² > 0.80 (owner's decision) | **done** 2026-11-22 |
| 1.8 | 0.8.0 | Benchmarks ([BENCHMARK_PROTOCOL.md](../04_Validation/BENCHMARK_PROTOCOL.md)) against `sampleSelection` 1.2-16 and the archived `endoSwitch` 1.0.0: 11 datasets; benchmark and diagnostics scripts; probit accuracy fix | `BENCHMARK_G1.md`:<br>• 1048/1145 checks pass; all 97 differences explained (numerical Hessian of `endoSwitch`, its `glm()` tolerance, non-convergence on a misspecified example);<br>• new documented difference D-ES-1;<br>• AC3 proposed as met, owner to confirm | **done** 2026-11-23 (owner decision on AC3 pending) |
| 1.9 | 0.9.0 | Vignettes `classical-esr`, `treatment-effects`, `simulation-validation` (must state the finite-sample coverage at N ≤ 1000 found in WP1.7, as part of the owner's decision); README; CRAN preparation; GitHub Actions (owner creates the repository) | `--as-cran` clean (AC6) | |
| 1.10 | 1.0.0 | Release: evidence table, gates, CRAN submission (owner) | gate record | |

## 3. Questions for the econometric gate (owner)

1. Plan decision D8: $\operatorname{Corr}(\varepsilon_1, \varepsilon_0)$ is
   treated as not identified. It is never estimated; bounds or the stated
   assumption $r_{10} = \rho_1\rho_0$ are used for quantities that need it
   ([IDENTIFICATION.md](../01_Econometric_Architecture/IDENTIFICATION.md)
   section 3).
2. Plan decision D9: BH is reported as BH1 and BH0 (Carter and Milon 2005;
   Di Falco et al. 2011), and TH = ATT − ATU
   ([TREATMENT_EFFECTS.md](../01_Econometric_Architecture/TREATMENT_EFFECTS.md)
   section 3).
3. Sample ATE is defined as the mean of $x_1'\beta_1 - x_0'\beta_0$. The
   share-weighted average of ATT and ATU is shown alongside, because the two
   coincide exactly only at the probit MLE.
4. Default FIML covariance: the inverse observed information. Sandwich is the
   default with weights.
5. Identification diagnostics and their heuristic thresholds (I5:
   $\chi^2/\text{df} < 10$; I6: $R^2 > 0.95$), to be revisited after the
   Monte Carlo study. Revisited in WP1.7
   ([MC_G1.md](../04_Validation/results/MC_G1.md) section 7). **The owner
   decided on 22 November 2026 to lower the I6 warning threshold to
   $R^2 > 0.80$**, applied in 0.7.1
   ([IDENTIFICATION.md](../01_Econometric_Architecture/IDENTIFICATION.md)
   section 7). The I5 rule is unchanged.
6. Monte Carlo design and pre-registered thresholds
   ([MONTE_CARLO_DESIGN.md](../04_Validation/MONTE_CARLO_DESIGN.md)).

**Amendment confirmed by the owner on 22 November 2026 (raised in
WP1.5):** the falsification test I10 is reported for information only and
never raises a warning. The reason is simulation evidence that it rejects
valid exclusions under selection on unobservables
([IDENTIFICATION.md](../01_Econometric_Architecture/IDENTIFICATION.md)
section 6).

**Decision by the owner on 22 November 2026 (raised in WP1.7):** the
diagnosis of the Monte Carlo study is accepted
([MC_G1.md](../04_Validation/results/MC_G1.md) sections 4 and 9).
- The 10 failed gate checks and the AC4(b) result (27 of 30) are recorded
  as understood finite-sample properties, with no defect.
- AC1 and AC4 are met with these documented exceptions.
- The pre-registered thresholds are unchanged.
- The `simulation-validation` vignette (WP1.9) must state the finite-sample
  coverage at N ≤ 1000.
