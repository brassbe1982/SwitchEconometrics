# Generation 1: acceptance evidence for release 1.0.0

WP1.10, 23 November 2026. This table brings together the evidence for the
six acceptance criteria of Generation 1 (specification section 16;
[ACCEPTANCE_TESTS.md](../ACCEPTANCE_TESTS.md)). Every result below was
produced by a script or test in this repository and is reported in the
document named. The status of each criterion is the one recorded in
ACCEPTANCE_TESTS.md, including the owner's decisions.

## 1. Acceptance criteria

| # | Criterion | Main evidence | Result | Status |
| --- | --- | --- | --- | --- |
| AC1 | Recover known parameters in controlled simulation experiments | Pre-registered Monte Carlo study: 38 designs, 28 400 replications ([MC_G1.md](MC_G1.md)); recovery test on CRAN | All 165 bias, root-N and convergence checks of the parameters pass. One effect-bias check fails (ATU at N = 1000: 9.7%, a second-order bias that falls like 1/N). The recovery test (N = 5000, every estimate within 4 SE) passes on CRAN | **met** with 1 documented exception (owner, 22 Nov 2026) |
| AC2 | Reproduce classical ESR likelihood results | `verify_math.R` (26 checks); `test-likelihood.R` | 26/26 checks pass. The package log-likelihood equals the independent reference implementation to 8.9e-16, and `sampleSelection`'s log-likelihood exactly at its estimates | **met** (22 Nov 2026) |
| AC3 | Match benchmark estimates within documented tolerances | 14 benchmark datasets against `sampleSelection` 1.2-16, the archived `endoSwitch` 1.0.0 and the `sandwich` package ([BENCHMARK_G1.md](BENCHMARK_G1.md)) | 1275 of 1378 checks pass; each of the 103 differences beyond tolerance is explained with evidence (another package's numerical Hessian or loose probit, or no maximum on a misspecified example). Two-step coefficients match to 9.3e-10; FIML estimates to 3.3e-6 (`sampleSelection`) and 4.4e-8 (`endoSwitch`) | **met** with documented differences (owner, 23 Nov 2026) |
| AC4 | Reliable standard errors and confidence intervals | Monte Carlo SE ratios and coverage ([MC_G1.md](MC_G1.md)); bootstrap check (`ac4b_bootstrap_G1.csv`); analytic against numerical Hessian | 300 of 309 SE-ratio and coverage checks pass. The 9 failures are finite-sample (N = 1000-2000) or σ at ρ = 0 (conservative). The Hessian standard errors equal the asymptotic ones at the truth within 2.3%. Bootstrap and Hessian agree on 27 of 30; where they do not, the Hessian is accurate | **met** with documented exceptions (owner, 22 Nov 2026) |
| AC5 | All four conditional counterfactual expectations correct | `verify_math.R` V07, V08, V16; `test-effects.R` | The expectations equal numerical integrals to 1e-7 and the reference formulas to 1e-10. The identities BH1 − BH0 = TH and the share-weighted ATE hold exactly. Delta-method gradients equal numerical ones. ATT and ATU match simulated potential outcomes at n = 200 000 | **met** (22 Nov 2026) |
| AC6 | Automated package checks across supported platforms | `R CMD check --as-cran`; GitHub Actions; win-builder | Local check: 0 errors, 0 warnings. GitHub Actions: all 9 jobs (Windows, macOS, Ubuntu; R release, devel, oldrel-1). win-builder R-release and R-devel: 1 NOTE each (new submission; authors' surnames) | **met** with 2 documented exceptions (owner, 23 Nov 2026) |

## 2. Gates

| Gate | Requirement | Date | Basis |
| --- | --- | --- | --- |
| Econometric | Owner approves the derivations and decisions D8, D9 | 22 Nov 2026 | Approved in session ("Approve, start WP1.2"). Amendments I10 (falsification test informational) and I6 (threshold R² > 0.80) also confirmed |
| Computational | AC1, AC2, AC4, AC5 | 22 Nov 2026 | Owner accepted the WP1.7 Monte Carlo diagnosis |
| Software | AC3, AC6; documentation complete | 23 Nov 2026 | AC3 approved after the 0.8.1 items were closed; AC6 confirmed ("Yes, mark AC6 met"); three vignettes, README, help pages |

## 3. Documented exceptions and limits, in one place

**Accepted by the owner:**

| # | Exception or limit | Where it is explained | Where users are told |
| --- | --- | --- | --- |
| E1 | Interval coverage below nominal at small N (mean over parameters 0.928 at N = 250 and 0.943 at N = 500; effects 0.903 and 0.931); ATU biased upward (10% at N = 1000) | MC_G1.md s.4.3 | vignette `simulation-validation` |
| E2 | Standard errors of σ conservative when ρ = 0 exactly | MC_G1.md s.4.2 | vignette `simulation-validation` |
| E3 | Bootstrap and Hessian standard errors differ by more than 10% for 3 of 30 parameters on one dataset; the Hessian is the accurate one there | MC_G1.md s.8 | – |
| E4 | Benchmark differences caused by the other packages: `endoSwitch`'s numerical Hessian (standard errors 1-4% off), its probit tolerance, inconsistent two-step variance recovery in both other packages (D-SS-1, D-ES-1), `endoSwitch`'s unweighted effects (D-ES-2), and no maximum on a misspecified example | BENCHMARK_G1.md s.4-5 | vignette `simulation-validation` |
| E5 | The macOS builder was unavailable (HTTP 502). The macOS R-devel CI job checks without the suggested packages (Matrix does not compile on that runner) | WP1.9 progress note | – |

**Other limits users are told about:**
- Cluster-robust intervals for FIML σ and ρ cover 0.89-0.91 with 100
  clusters (BENCHMARK_G1.md s.4.5; vignette `simulation-validation`).
- Weak or missing exclusion restrictions bias ρ. The identification checks
  I4, I5 and I6 warn about them (MC_G1.md s.5.3 and s.7; vignette
  `classical-esr`).
- The correlation of the two outcome disturbances is not identified.
  Distributional results depend on an assumption about it (vignette
  `treatment-effects`).

## 4. How to reproduce

Every script is in `04_Validation/scripts/`, `01_Econometric_Architecture/`
or `tests/testthat/`. The raw outputs of the long runs are kept outside the
repository; the summaries are in `04_Validation/results/`.

| Evidence | Command (from the workspace root) | Time |
| --- | --- | --- |
| Formula checks | `Rscript --no-init-file verify_math.R` (in `01_Econometric_Architecture/`) | ~1 min |
| Tests | `testthat::test_local("SwitchEconometrics")` | ~1.5 min |
| Monte Carlo study | `04_Validation/scripts/mc_g1.R full <library> <outdir> <cores>`, then `mc_g1_report.R` | ~2 h on 2 cores |
| Identification and bootstrap studies | `mc_g1_identification.R`, `ac4b_bootstrap_check.R` | not timed |
| Benchmarks | `benchmark_g1.R`, `benchmark_g1_diagnostics.R`, `cluster_mc_g1.R` | ~6, 2 and 4 min |
| Release checks | `tools/CRAN_prepare.R full` (outside the repository) | ~25 min |

## 5. Release record

| Step | Date | Record |
| --- | --- | --- |
| Release candidate | 23 Nov 2026 | Commit f813103: version 1.0.0, code as in 0.9.1. `tools/CRAN_prepare.R full` passed every stage: tests 650 / 643 / 603 expectations, `verify_math.R` 26/26, `--as-cran` 1 NOTE (V8 absent locally), Monte Carlo smoke run identical to 0.8.1, benchmarks 1275/1378 as in BENCHMARK_G1.md |
| Outside checks | 23 Nov 2026 | GitHub Actions run 5: all 9 jobs pass. win-builder R-release (4.6.2) and R-devel (r90926): 1 NOTE each ("New submission"; cited surnames). macOS builder: upload refused by the service (HTTP 502) |
| CRAN submission | 23 Nov 2026, 03:49 UTC | `SwitchEconometrics_1.0.0.tar.gz` (186 954 bytes) with the owner's go-ahead ("Submit and push"), which is also the owner's sign-off of Generation 1. Confirmed by the maintainer; then in CRAN `incoming/pretest/` |
| CRAN decision | pending | |
