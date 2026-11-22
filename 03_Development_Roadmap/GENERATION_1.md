# Generation 1: Classical core (v0.1.0 → v1.0.0)

Status: in progress. WP1.1 done (22 November 2026). **Econometric gate
approved by the owner on 22 November 2026**: the six questions of section 3
were accepted as proposed. WP1.2 started.

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
| 1.5 | 0.5.0 | Covariances, bootstrap, tests, diagnostics, `switch_validate()` | unit tests; coverage spot checks | |
| 1.6 | 0.6.0 | Effects, predictions, counterfactuals, simulation, S3 methods, `esr()`, dataset `firms`, reproducibility record | AC5 tests | |
| 1.7 | 0.7.0 | Monte Carlo study ([MONTE_CARLO_DESIGN.md](../04_Validation/MONTE_CARLO_DESIGN.md)) | `MC_G1.md` (AC1, AC4) | |
| 1.8 | 0.8.0 | Benchmarks ([BENCHMARK_PROTOCOL.md](../04_Validation/BENCHMARK_PROTOCOL.md)) | `BENCHMARK_G1.md` (AC2, AC3) | |
| 1.9 | 0.9.0 | Vignettes `classical-esr`, `treatment-effects`, `simulation-validation`; README; CRAN preparation; GitHub Actions (owner creates the repository) | `--as-cran` clean (AC6) | |
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
   Monte Carlo study.
6. Monte Carlo design and pre-registered thresholds
   ([MONTE_CARLO_DESIGN.md](../04_Validation/MONTE_CARLO_DESIGN.md)).
