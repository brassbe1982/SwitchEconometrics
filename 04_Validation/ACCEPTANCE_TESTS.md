# Acceptance tests

Status: WP1.1, 22 November 2026. Specification section 16 (G1 acceptance
criteria). G1 is incomplete until all six criteria are demonstrated
(specification section 16). Status column: open / met (with evidence and
date).

## 1. Generation 1

| # | Criterion (specification) | Concrete tests | Evidence | Status |
| --- | --- | --- | --- | --- |
| AC1 | Recover known parameters in controlled simulation experiments | (a) Monte Carlo thresholds of [MONTE_CARLO_DESIGN.md](MONTE_CARLO_DESIGN.md) section 5 (bias, root-$N$, convergence) in the gated cells; (b) fast `testthat` recovery test: $N = 5000$, one dataset, every estimate within 4 standard errors (on CRAN) | `results/MC_G1.md`; `tests/testthat/test-estimation.R` ("FIML recovers the true parameters", runs on CRAN from 0.7.0) | **open (2026-11-22, v0.7.0): blocked by 1 failed gate check.**<br>• (a) all 165 bias, root-N and convergence checks of the parameters pass (C1, C2, C3, C6); 1 effect-bias check fails (C7: ATU at N = 1000, 9.7%, a second-order bias falling like 1/N);<br>• (b) the recovery test passes and runs on CRAN.<br>Owner decision pending (MC_G1.md s.9) |
| AC2 | Reproduce classical ESR likelihood results | (a) `verify_math.R` V01-V03, V06, V19 (contributions equal integrated densities; proper density; information equality; factorisation at $\rho = 0$); (b) package log-likelihood equals the reference implementation to $10^{-10}$; (c) equals `sampleSelection`'s log-likelihood at identical parameter values to $10^{-8}$ | `verify_math_results.csv` (26/26 pass, 22 Nov 2026); `tests/testthat/test-likelihood.R` | **met 2026-11-22 (v0.3.0)**: (a) 26/26; (b) package equals reference, max difference 8.9e-16; (c) package log-likelihood at `sampleSelection` 1.2-16's ML estimates equals its value exactly, and our gradient there is 9.8e-7 |
| AC3 | Match benchmark estimates within documented numerical tolerances | [BENCHMARK_PROTOCOL.md](BENCHMARK_PROTOCOL.md) section 3 for `sampleSelection` (ML and two-step) and `endoSwitch` | `results/BENCHMARK_G1.md` | open |
| AC4 | Produce reliable standard errors and confidence intervals | (a) Monte Carlo SE ratio and coverage thresholds (FIML Hessian, effects, two-step) in the gated cells; (b) bootstrap and Hessian standard errors agree within 10% at $N = 2000$; (c) analytic Hessian equals the numerical one (V05; package test) | `results/MC_G1.md`; `results/ac4b_bootstrap_G1.csv`; `tests/testthat/test-inference.R` | **open (2026-11-22, v0.7.0).**<br>• (a) 9 of 309 SE-ratio and coverage checks fail (C4, C5, C7 coverage, C8). The diagnosis finds no defect: Hessian SEs equal the asymptotic SEs at the truth within 2.3%, except σ at ρ = 0 (conservative); see MC_G1.md s.4.<br>• (b) 27 of 30 ratios within 10%: `firms` 15/15; base design 12/15, where the external truth shows the Hessian is accurate and the bootstrap overstates (MC_G1.md s.8).<br>• (c) met (V05 and package test).<br>Owner decision pending (MC_G1.md s.9) |
| AC5 | Correctly calculate all four conditional counterfactual expectations | (a) V07, V08, V16 (integration and simulation); (b) package expectations equal the reference formulas to $10^{-10}$ and the numerical integrals to $10^{-7}$; (c) identities $BH_1 - BH_0 = TH$ and $ATE = \pi ATT + (1-\pi)ATU$ at the probit MLE; (d) delta-method gradients equal numerical ones (V15a) | `verify_math_results.csv`; `tests/testthat/test-effects.R` | **met 2026-11-22 (v0.6.0)**: (a) V07, V08, V16; (b) package expectations equal 2-D integrals to 1e-7 and the reference effects to 1e-10; (c) identities exact (two-step share-weighted ATE to 1e-6); (d) analytic gradients equal numerical ones (1e-7). In addition, counterfactual means, ATT and ATU match simulated potential outcomes at n = 200 000 within 4 Monte Carlo SEs |
| AC6 | Pass automated package checks across supported platforms | `R CMD check --as-cran` with 0 errors and 0 warnings, notes explained in `cran-comments.md`; GitHub Actions R-CMD-check green on Windows, macOS and Ubuntu (release, devel, oldrel-1), once the owner creates the repository; win-builder and macOS builder (owner approval) | check logs in `03_Development_Roadmap/progress/` | open |

## 2. Gate record (G1)

| Gate | Requirement | Date | Signed |
| --- | --- | --- | --- |
| Econometric | Owner approves BINARY_ESR, LIKELIHOOD_DERIVATION, IDENTIFICATION, PARAMETERIZATION, TREATMENT_EFFECTS and GENERAL_MODEL, including decisions D8 and D9 | 2026-11-22 | Ibrahim Niankara (approved in session: "Approve, start WP1.2"; all six questions of GENERATION_1.md s.3 accepted as proposed). Amendment I10 (IDENTIFICATION.md s.6) confirmed on 2026-11-22 |
| Computational | AC1, AC2, AC4, AC5 met | | |
| Software | AC3, AC6 met; documentation complete | | |

## 3. Later generations (template)

Each generation's `GENERATION_n.md` defines criteria of the same kind:
1. Monte Carlo recovery.
2. Exact nesting of the previous generation's model (log-likelihood equal to
   $10^{-8}$ under the restriction).
3. Benchmark agreement where a benchmark exists.
4. Reliable inference.
5. Correct effects on the economic scale.
6. Automated checks.
