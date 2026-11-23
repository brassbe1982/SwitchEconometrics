# Acceptance tests

Status: WP1.1, 22 November 2026. Specification section 16 (G1 acceptance
criteria). G1 is incomplete until all six criteria are demonstrated
(specification section 16). Status column: open / met (with evidence and
date).

## 1. Generation 1

| # | Criterion (specification) | Concrete tests | Evidence | Status |
| --- | --- | --- | --- | --- |
| AC1 | Recover known parameters in controlled simulation experiments | (a) Monte Carlo thresholds of [MONTE_CARLO_DESIGN.md](MONTE_CARLO_DESIGN.md) section 5 (bias, root-$N$, convergence) in the gated cells; (b) fast `testthat` recovery test: $N = 5000$, one dataset, every estimate within 4 standard errors (on CRAN) | `results/MC_G1.md`; `tests/testthat/test-estimation.R` ("FIML recovers the true parameters", runs on CRAN from 0.7.0) | **met 2026-11-22 (v0.7.0), with a documented exception** (owner accepted the WP1.7 diagnosis, MC_G1.md s.9).<br>• (a) all 165 bias, root-N and convergence checks of the parameters pass (C1, C2, C3, C6); 1 effect-bias check fails (C7: ATU at N = 1000, 9.7%, a second-order bias falling like 1/N), recorded as an understood finite-sample property;<br>• (b) the recovery test passes and runs on CRAN |
| AC2 | Reproduce classical ESR likelihood results | (a) `verify_math.R` V01-V03, V06, V19 (contributions equal integrated densities; proper density; information equality; factorisation at $\rho = 0$); (b) package log-likelihood equals the reference implementation to $10^{-10}$; (c) equals `sampleSelection`'s log-likelihood at identical parameter values to $10^{-8}$ | `verify_math_results.csv` (26/26 pass, 22 Nov 2026); `tests/testthat/test-likelihood.R` | **met 2026-11-22 (v0.3.0)**: (a) 26/26; (b) package equals reference, max difference 8.9e-16; (c) package log-likelihood at `sampleSelection` 1.2-16's ML estimates equals its value exactly, and our gradient there is 9.8e-7 |
| AC3 | Match benchmark estimates within documented numerical tolerances | [BENCHMARK_PROTOCOL.md](BENCHMARK_PROTOCOL.md) section 3 for `sampleSelection` (ML and two-step) and `endoSwitch` | `results/BENCHMARK_G1.md`; `scripts/benchmark_g1.R`, `scripts/benchmark_g1_diagnostics.R`, `scripts/cluster_mc_g1.R` | **met 2026-11-23 (v0.8.1), with documented differences**: the owner approved this on condition that the open items (weighted and clustered fits, FIML speed, slow failure on D6b) were addressed first, which 0.8.1 does. 1275 of 1378 checks pass, and each of the 103 differences beyond tolerance is explained with evidence (BENCHMARK_G1.md s.4):<br>• `sampleSelection` ML: estimates, log-likelihood, standard errors and effects agree in every dataset where it reaches a maximum (10 of 11; D6b has no valid reference);<br>• two-step: agrees with `sampleSelection` to 9.3e-10 in all 11 datasets;<br>• `endoSwitch` FIML: estimates, log-likelihood and effects agree in all 6 datasets and with weights; 36 of 194 standard errors differ by 1-4% because of its numerical Hessian;<br>• `endoSwitch` two-stage: D7b differs by its `glm()` tolerance;<br>• weighted and clustered fits: 177/177 against `sampleSelection` with the `sandwich` package; cluster standard errors checked by Monte Carlo |
| AC4 | Produce reliable standard errors and confidence intervals | (a) Monte Carlo SE ratio and coverage thresholds (FIML Hessian, effects, two-step) in the gated cells; (b) bootstrap and Hessian standard errors agree within 10% at $N = 2000$; (c) analytic Hessian equals the numerical one (V05; package test) | `results/MC_G1.md`; `results/ac4b_bootstrap_G1.csv`; `tests/testthat/test-inference.R` | **met 2026-11-22 (v0.7.0), with documented exceptions** (owner accepted the WP1.7 diagnosis, MC_G1.md s.9).<br>• (a) 9 of 309 SE-ratio and coverage checks fail (C4, C5, C7 coverage; C8 passes). The diagnosis finds no defect: Hessian SEs equal the asymptotic SEs at the truth within 2.3%, except σ at ρ = 0 (conservative); see MC_G1.md s.4. Recorded as understood finite-sample properties.<br>• (b) 27 of 30 ratios within 10%: `firms` 15/15; base design 12/15, where the external truth shows the Hessian is accurate and the bootstrap overstates (MC_G1.md s.8). Recorded as an exception.<br>• (c) met (V05 and package test) |
| AC5 | Correctly calculate all four conditional counterfactual expectations | (a) V07, V08, V16 (integration and simulation); (b) package expectations equal the reference formulas to $10^{-10}$ and the numerical integrals to $10^{-7}$; (c) identities $BH_1 - BH_0 = TH$ and $ATE = \pi ATT + (1-\pi)ATU$ at the probit MLE; (d) delta-method gradients equal numerical ones (V15a) | `verify_math_results.csv`; `tests/testthat/test-effects.R` | **met 2026-11-22 (v0.6.0)**: (a) V07, V08, V16; (b) package expectations equal 2-D integrals to 1e-7 and the reference effects to 1e-10; (c) identities exact (two-step share-weighted ATE to 1e-6); (d) analytic gradients equal numerical ones (1e-7). In addition, counterfactual means, ATT and ATU match simulated potential outcomes at n = 200 000 within 4 Monte Carlo SEs |
| AC6 | Pass automated package checks across supported platforms | `R CMD check --as-cran` with 0 errors and 0 warnings, notes explained in `cran-comments.md`; GitHub Actions R-CMD-check green on Windows, macOS and Ubuntu (release, devel, oldrel-1), once the owner creates the repository; win-builder and macOS builder (owner approval) | check logs in `03_Development_Roadmap/progress/`; `cran-comments.md` | **met 2026-11-23 (v0.9.1), with two documented exceptions** (owner: "Yes, mark AC6 met").<br>• Local `R CMD check --as-cran` with vignettes: 0 errors, 0 warnings, 1 NOTE (V8 absent locally).<br>• GitHub Actions (https://github.com/brassbe1982/SwitchEconometrics), run 2, commit 67650d5: **all 9 jobs pass** (Windows, macOS, Ubuntu; R release, devel, oldrel-1). Run 1 had 8/9: macOS R-devel failed before the package check because Matrix, needed only by the suggested `sampleSelection`, does not compile on that runner; that job now checks without the suggested packages (exception 1).<br>• win-builder R-release and R-devel: 0 errors, 0 warnings, 1 NOTE each ("New submission"; the cited authors' surnames, explained in `cran-comments.md`).<br>• macOS builder: refused by the service (HTTP 502); the three macOS jobs of GitHub Actions stand in (exception 2).<br>• Release 1.0.0 (same code): GitHub Actions run 5, all 9 jobs pass; win-builder R-release and R-devel 1 NOTE each (the same note); macOS builder HTTP 502 again. Submitted to CRAN on 2026-11-23 with the owner's go-ahead (WP1.10) |

## 2. Gate record (G1)

| Gate | Requirement | Date | Signed |
| --- | --- | --- | --- |
| Econometric | Owner approves BINARY_ESR, LIKELIHOOD_DERIVATION, IDENTIFICATION, PARAMETERIZATION, TREATMENT_EFFECTS and GENERAL_MODEL, including decisions D8 and D9 | 2026-11-22 | Ibrahim Niankara (approved in session: "Approve, start WP1.2"; all six questions of GENERATION_1.md s.3 accepted as proposed). Amendment I10 (IDENTIFICATION.md s.6) confirmed on 2026-11-22. I6 threshold lowered to R² > 0.80 by the owner on 2026-11-22 after the Monte Carlo study (gate question 5; IDENTIFICATION.md s.7; v0.7.1) |
| Computational | AC1, AC2, AC4, AC5 met | 2026-11-22 | Requirement met: AC2 (v0.3.0) and AC5 (v0.6.0) met; AC1 and AC4 met with documented exceptions after Ibrahim Niankara accepted the WP1.7 Monte Carlo diagnosis in session ("Accept the diagnosis"; MC_G1.md s.9). Pre-registered thresholds unchanged |
| Software | AC3, AC6 met; documentation complete | 2026-11-23 | Requirement met. AC3 met (owner's conditional approval in session, conditions met in v0.8.1). AC6 met with two documented exceptions (Ibrahim Niankara in session: "Yes, mark AC6 met"; v0.9.1). Documentation complete: three vignettes, README, help pages (WP1.9) |

## 3. Later generations (template)

Each generation's `GENERATION_n.md` defines criteria of the same kind:
1. Monte Carlo recovery.
2. Exact nesting of the previous generation's model (log-likelihood equal to
   $10^{-8}$ under the restriction).
3. Benchmark agreement where a benchmark exists.
4. Reliable inference.
5. Correct effects on the economic scale.
6. Automated checks.

## 4. Generation 2

Status: **proposed at the G2 econometric gate** (23 November 2026).
Criteria from [GENERATION_2.md](../03_Development_Roadmap/GENERATION_2.md).
Sections 1-3 are the Generation 1 record and are unchanged.

| # | Criterion | Concrete tests | Evidence | Status |
| --- | --- | --- | --- | --- |
| G2-AC1 | Monte Carlo recovery for each selection mechanism | (a) the bias, root-$N$ and convergence thresholds of [MONTE_CARLO_DESIGN.md](MONTE_CARLO_DESIGN.md) section 8.4 in the gated cells of designs H, T, L, D, P, O, S, V, K, N; (b) one fast recovery test per model on CRAN (one dataset, every estimate within 4 standard errors) | `results/MC_G2.md`; `tests/testthat/` | open |
| G2-AC2 | Exact nesting | (a) region engine with $J = 2$ (multinomial probit, ordered, sequential, multivariate with $M = 1$) equals the frozen G1 log-likelihood per observation to $10^{-8}$, and the fitted model equals the 1.0.0 fit to $10^{-6}$ in the estimates; (b) Heckman log-likelihood equals `sampleSelection` Tobit-2 at identical parameters to $10^{-8}$, and satisfies the identity of OBSERVATION_MECHANISMS.md s.2.5 to $10^{-8}$; (c) treatment log-likelihood equals the restricted ESR to $10^{-10}$; (d) nested logit with $\lambda = 1$ equals the multinomial logit; (e) the frozen 1.0.0 results of `esr()` to $10^{-8}$ at every G2 version | `verify_math_g2_results.csv` (W03, W04, W05, W07, W22, W32, W37b: reference level, 23 Nov 2026); package tests | open (reference level verified) |
| G2-AC3 | Benchmarks within the protocol tolerances | [BENCHMARK_PROTOCOL.md](BENCHMARK_PROTOCOL.md) section 6: `sampleSelection` (Tobit-2, `treatReg`), `switchSelection::msel` (ordered and multivariate FIML; multinomial two-step), `endogenous` if approved | `results/BENCHMARK_G2.md` | open |
| G2-AC4 | Coverage within [0.93, 0.97] in gated cells | (a) the standard-error ratio and coverage thresholds of section 8.4; (b) differenced Hessians equal `numDeriv` Hessians of the log-likelihood to $10^{-5}$; (c) bootstrap and default standard errors within 10% at the largest gated $N$ of one design per engine (L, P, O) | `results/MC_G2.md`; package tests | open |
| G2-AC5 | Pairwise effects verified by simulation | (a) W12, W27, W33, W38 (reference level); (b) package $J \times J$ conditional expectations equal the reference formulas to $10^{-10}$; (c) $ATE_{jk}$, $ATT_{jk}$, $ATU_{jk}$ of every pair match simulated potential outcomes at $n = 200\,000$ within 4 Monte Carlo standard errors, for each selection mechanism; (d) the adding-up identity and $ATE_{jk} + ATE_{kl} = ATE_{jl}$ exactly; (e) effect gradients equal numerical ones | `verify_math_g2_results.csv`; `tests/testthat/test-effects-g2.R` | open (reference level verified) |
| G2-AC6 | Checks on three operating systems | `R CMD check --as-cran` 0 errors, 0 warnings; GitHub Actions on Windows, macOS, Ubuntu; win-builder; macOS builder (owner's approval each) | check logs; `cran-comments.md` | open |

## 5. Gate record (G2)

| Gate | Requirement | Date | Signed |
| --- | --- | --- | --- |
| Econometric | Owner approves OBSERVATION_MECHANISMS, GAUSSIAN_REGION_ENGINE, MULTINOMIAL_ESR, ORDERED_SEQUENTIAL, MULTIVARIATE_SELECTION, the G2 sections of TREATMENT_EFFECTS, IDENTIFICATION, PARAMETERIZATION and GENERAL_MODEL, and the questions of GENERATION_2.md section 4 | | open: put to the owner on 23 November 2026 |
| Computational | G2-AC1, G2-AC2, G2-AC4, G2-AC5 met | | open |
| Software | G2-AC3, G2-AC6 met; documentation complete (vignette `multinomial-esr`) | | open |
