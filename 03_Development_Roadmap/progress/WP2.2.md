# WP2.2: multinomial-logit selection (version 1.2.0)

Recorded 24 November 2026 by the Generation 2 session. Package version
1.1.1 → **1.2.0**. Status: **delivered, with two open points for the
owner** (section "For the owner"): three failed Monte Carlo coverage
checks in design L, and the Monte Carlo of the normal-score model, which
was still running when this note was written.

## What was delivered

- **`multinomial_switch()`** and `switch_fit(model = "multinomial_esr")`:
  switching regression with any number of regimes chosen by a multinomial
  logit with a base regime.
  - FIML for Lee's (1983) model, analytic score and Hessian
    (`R/lik_lee.R`), the default as the owner decided.
  - Two-step estimators with the corrections of Lee, Dubin-McFadden and
    BFG (variants 1 and 2): closed-form corrected covariance for Lee,
    stacked sandwich for all, bootstrap over both steps as the default for
    the three moment models (`R/est_two_step_multi.R`).
  - Pairwise effects (ATE, ATT, ATU, TH, and the effect given a third
    regime) with the $J \times J$ table of means and delta-method standard
    errors; predictions; simulation with potential outcomes;
    identification checks I1 to I11 with a new check I4b (directions moved
    by the exclusions against the number of correction terms).
- **Normal-score model** (`dependence_structure = "normal_scores"`, the
  less restrictive option the owner asked for): FIML for 2 or 3 regimes,
  analytic score, Hessian by differences of the score. **Marked
  experimental** in the help page and in NEWS.
- Example data `financing` (simulated, 3000 firms, three regimes).
- Validation scripts: `mc_g2.R` generalised to several estimators per
  design; `mc_g2_report.R` rewritten with the gates of
  MONTE_CARLO_DESIGN.md sections 8.3, 8.4 and 8.6; `benchmark_g2.R`
  extended.
- Documents: API_SPECIFICATION.md 5.10, SOFTWARE_ARCHITECTURE.md 7.6,
  NUMERICAL_METHODS.md 7.8, BENCHMARK_PROTOCOL.md 6.5, ACCEPTANCE_TESTS.md
  section 7, `results/MC_G2.md`, `results/BENCHMARK_G2.md`,
  GENERATION_2.md (status).

## Shared G1 files edited

`lik_esr_gaussian.R`, `est_two_step.R`, `eff_core.R`, `inf_vcov.R` and
`est_fiml.R` are unchanged. Dispatch lines (`se_is_multi()`) in
`switch_fit.R`, `switch_model.R`, `spec_support.R`, `spec_observation.R`,
`lik_interface.R`, `est_two_step_obs.R`, `inf_tests.R`,
`inf_identification.R`, `inf_bootstrap.R`, `switch_effects.R`,
`switch_predict.R`, `switch_counterfactual.R`, `sim_simulate.R`,
`switch_compare.R`, `methods_summary.R`, `methods_switch_fit.R`. Three
files gained behaviour that the binary models do not use: `par_map.R`
(transform of a group of correlations onto the unit ball),
`est_optimizer.R` (`se_optimize_costly()`, a coarse-rule objective and a
group boundary test) and `switch_control.R` (`bootstrap_R`).

## Evidence

| Item | Result |
| --- | --- |
| Package tests (final code) | **1060 expectations, 0 failed, 1 skipped** (the parallel-bootstrap test, which runs under `R CMD check`); 250 of them are new (`test-multinomial.R`, `test-normal-scores.R`) |
| `R CMD check --as-cran` (Windows, R 4.6.2, tarball `runs/build/1.2.0`) | **0 errors, 0 warnings, 1 note** (`V8` absent locally). CRAN incoming remote checks not run. The fit test of the normal-score model is skipped on CRAN and under this check (it ran in the test suite) |
| G1 results | frozen 1.0.0 test passes at 1e-8; G1 Monte Carlo smoke run with 1.2.0 **identical** to `runs/mc_g1_0.8.1_smoke` (1e-6) |
| WP2.1 results | smoke run of H, T, Th with 1.2.0 equals the 1.1.1 smoke summary (1e-16); the rewritten report reproduces the WP2.1 gate (428 checks, 426 passed) |
| Benchmarks | 66 toleranced comparisons, **66 within**, 8 documented differences, 4 not run. New: first step against `mlogit` and `nnet`; `"bfg1"` against `msel` (differences D-MS-1 and D-MS-2, both with an established cause) |
| Monte Carlo, designs L, D, Lw, L8 | 8500 replications, no errors, all FIML fits converged. Gate with H and T: **964 checks, 959 passed, 5 failed** (2 are EX-G2-1; 3 new, below) |
| Monte Carlo, designs G and LN (normal-score model) | **running** (`runs/mc_g2_1.2.0_full_ns`); smoke run: 14 of 20 fits at the boundary at $N = 2000$ |
| 8 and 10 regimes | package test fits both with Lee's model; cell L8 passes all 69 gated checks |

The Monte Carlo of L, D, Lw and L8 was run with an interim build of 1.2.0
(before the last changes to the normal-score code). The final build gives
identical smoke results for these designs (largest difference 0), so the
run was not repeated.

## Defects found and fixed during the work package

1. **`max.col()` breaks near-ties at random** and was used once to pick the
   chosen regime in a generator; replaced by an exact argmax.
2. **BFG variant 2:** the spline of $m(P)$ had an error of 1.3e-6; the
   grid was refined (error about 1e-10).
3. **Normal-score model, integration rule.** The first implementation used
   a Gauss-Hermite rule with 24 nodes, as planned. Near the boundary of the
   correlation region it was wrong by 0.1 to 0.4 in $\log I$ per
   observation and by about 11 in the log-likelihood of one sample, and
   the optimiser converged to spurious maxima there. Replaced by a
   composite Gauss-Legendre rule whose number of panels grows near the
   boundary (NUMERICAL_METHODS.md 7.8, with the calibration table); a
   package test bounds its error.
4. **Normal-score model, score.** The score was first obtained by central
   differences of the integral (13 integrals per evaluation); it is now
   analytic (one integral with derivative terms).
5. **Normal-score model, optimisation.** Fits that run to the boundary
   took more than 30 minutes. The optimiser now treats
   $\sum_k r_{jk}^2 > 0.992$ as the boundary, stops there and reports
   non-convergence with the boundary flag; the search uses a coarser rule
   and the final Newton steps, covariance and reported log-likelihood the
   accurate one.

## Deviations from the plan

- The argument is `dependence_structure`, not `dependence`; the options
  `dependence_terms = "own"` and `"own_common"` are not implemented; no
  `quadrature_nodes` control (API_SPECIFICATION.md 5.10).
- The normal-score model is limited to 3 regimes (the plan foresaw the
  general case through the region engine of WP2.3).
- Not available for multinomial fits in 1.2.0, refused with a classed
  error: bootstrap standard errors of the effects,
  `switch_counterfactual()`, selection formulas that differ between
  alternatives.
- The vignette `multinomial-esr` is not written (planned for the
  documentation step of G2).

## Not verified

- Linux and macOS: nothing was pushed, so no GitHub Actions run exists
  for 1.2.0.
- FIML of Lee's model, `"dmf"`, `"bfg2"` and the normal-score model have
  no external benchmark (none exists in software available here).
- The normal-score model: the Monte Carlo design G has not finished; no
  claim about its finite-sample behaviour is made beyond the smoke run.
  Its fit test covers 2 regimes only; 3-regime fits were run by hand on
  three samples (one converged at $N = 5000$, two ended at the boundary at
  $N = 2000$).
- Effects with 8 regimes are tested on one data set only.
- Sampling weights and cluster covariances of the multinomial models are
  covered by unit tests, not by simulation.

## For the owner

1. **Three failed coverage checks in design L** (FIML, $N = 2000$):
   `r1:sigma` 0.918 (dependent cell) and 0.977 (independent cell),
   `selection[r2]:z1` 0.926, against [0.93, 0.97]. Diagnosis in
   `results/MC_G2.md`: small-sample behaviour of $\sigma$ in the base
   regime, the same as in exception EX-G2-1, gone at $N = 5000$; one
   isolated coefficient; no defect found. The thresholds are unchanged.
   Decision needed: accept as a documented exception (with a caution in
   the help page, as for `heckman()`), or ask for more work.
2. **Normal-score model.** Its cross-regime correlations are weakly
   identified: at the design's true values the information implies
   standard errors of 0.32 to 0.62 at $N = 2000$ and 0.20 to 0.39 at
   $N = 5000$, and 14 of 20 smoke fits at $N = 2000$ ended at the
   boundary. The gate of design G (bias at most 0.05 and convergence at
   least 97% at $N = 5000$) may therefore fail; the result will be
   reported when the run ends (about one to two days of computing on 3
   cores). The model stays marked experimental meanwhile.
3. **Push.** `main` holds the local commits of WP2.0, WP2.1 and this work
   package; nothing was pushed, as instructed.

## Addendum: version 1.2.1 (24 November 2026)

The owner answered point 1 with "Yes, accept". Recorded as exception
EX-G2-2 (GENERATION_2.md section 5, ACCEPTANCE_TESTS.md section 7,
`results/MC_G2.md`); the help page of `multinomial_switch()` gained the
caution on intervals; version 1.2.1 with a NEWS entry. No code other than
documentation changed. Evidence for 1.2.1: 1060 test
expectations, 0 failed, 1 skipped; `R CMD check --as-cran` 0 errors, 0
warnings, 1 note (`V8` absent locally; tarball `runs/build/1.2.1`).
1.2.1 is **not** installed in `runs/lib_g2`, which the running Monte
Carlo uses (1.2.0, identical code apart from documentation). A wording
error in `results/MC_G2.md` (eight-regime coverage attributed to the
wrong parameter type) was corrected.

Point 2 (normal-score model) stays open until its Monte Carlo run ends.
