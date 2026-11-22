# WP1.6: Treatment effects, predictions, counterfactuals, simulation

Version 0.6.0. Completed 22 November 2026. Status: **done. AC5 met.**

The owner confirmed the I10 amendment of WP1.5 on 22 November 2026; it is
recorded in IDENTIFICATION.md section 6 and ACCEPTANCE_TESTS.md section 2.

## What was done

| File | Content |
| --- | --- |
| `R/eff_core.R` | Effects engine on psi = (gamma, beta_0, sigma_0 rho_0, beta_1, sigma_1 rho_1). All expectations depend on the parameters only through psi, so one engine serves FIML (psi covariance by the delta method from the natural covariance) and two-step (its own psi covariance). Per-observation expectations with analytic gradients; group means with weights; effect values for the bootstrap; resolution of `by`/`subset` |
| `R/switch_effects.R` | `switch_effects()`: the 2 x 2 table, ATT, ATU, ATE, TH, BH1, BH0; delta or bootstrap standard errors; groups, subsets, per-observation output; share-weighted ATE alongside ATE |
| `R/switch_predict.R` | `switch_predict()` with six types, new-data design (fit's levels and contrasts, NA rows), delta-method standard errors; `predict`, `fitted`, `residuals` (response, pearson) |
| `R/switch_counterfactual.R` | `switch_counterfactual()`: all-regime-1, all-regime-0 and policy scenarios; changes in expected outcomes and regime-1 shares with delta-method standard errors; changes conditional on the observed regime; quantiles of per-unit changes |
| `R/sim_simulate.R` | `switch_simulate()` (specification or fit; r10 assumption with admissibility check; observed data do not depend on r10); `simulate.switch_fit()` |
| `R/switch_compare.R` | `switch_compare()` and `anova()`. Nested LR tests only for FIML fits on the same sample: same index, outcome and regimes. The check on outcome and regime vectors was added after review showed that index equality alone would accept different data |
| `R/methods_model.R` | `model.frame`, `model.matrix`, `terms` by equation; model frames now stored in the data object |
| `R/inf_bootstrap.R` | `statistics = "effects"`, with groups and subsets carried by original row index through resampling |
| `R/data.R`, `data-raw/firms.R`, `data/firms.rda` | Simulated `firms` data: 2000 firms, seed 20261122, documented true parameters; adoption share 0.486 |
| `esr()` | records its own call, so that `update()` works |
| `04_Validation/scripts/mc_g1.R` | effects in the Monte Carlo (estimand: effect at the true parameters on each replication's sample) |
| tests | `test-effects.R` (18 tests); reference effects added to `helper-reference.R` |

## Evidence

**Tests on the source:** 12 files, 631 expectations, 0 failures (78 s).
**Under `R CMD check --as-cran`:** 619 pass, 5 heavy tests skipped on CRAN.
0 errors, 0 warnings, 1 NOTE (V8 absent). Every example runs in under
1.3 s.

**AC5 (correct conditional counterfactual expectations): met.**
- The package's four expectations equal two-dimensional integrals of the
  bivariate normal density to 1e-7 (two observations, both regimes, at the
  FIML estimates).
- The effects equal the reference implementation of `verify_math.R` to
  1e-10.
- BH1 − BH0 = TH exactly. For two-step fits (probit estimate) the
  share-weighted ATE equals ATE to 1e-6; ATT and ATU equal the means of the
  per-unit effects.
- Analytic effect gradients equal `numDeriv` Jacobians (1e-7), for FIML and
  two-step. The FIML psi covariance equals a numerical delta method (1e-8).
- n = 200 000 simulated at the true parameters: E[Y(0) | S = 1],
  E[Y(1) | S = 0], ATT and ATU from the formulas match the simulated
  potential outcomes within 4 Monte Carlo SEs.

**Other evidence:**
- **Groups:** group results equal subset results, and formula `by` with
  `data` equals vector `by`.
- **Weights:** weighted effects equal replicated-data effects (1e-6).
- **Predictions:**
  - new data reproduce in-sample predictions;
  - NA rows give NA;
  - delta-method standard errors equal a numerical delta method (1e-6).
- **Residuals:** Pearson residuals have mean about 0 and sd in [0.9, 1.1]
  (n = 3000).
- **Counterfactuals:**
  - the all-regime-1 scenario mean equals the mean of x1'b1;
  - the conditional change for regime-0 units equals ATU, with the same
    standard error;
  - unchanged policy data give 0;
  - delta-method standard errors equal a numerical delta method (1e-6).
- **Simulation:**
  - reproducible, with the RNG restored;
  - observed regimes identical for r10 = 0 and the default;
  - r10 outside the admissible range is refused;
  - factor regime indicators are reproduced;
  - a refit on 8000 simulated observations recovers the parameters (local
    test).
- **Comparison:** LR equals 2Δℓ; fits on different data get no test.
- **`firms`:** FIML estimates within 3 standard errors of the true
  parameters (largest |z| = 1.2). ATT 0.758 (SE 0.057), ATU 0.368 (0.057),
  ATE 0.557 (0.043): positive selection on gains, as built in.

**Monte Carlo smoke test with effects** (0.6.0, R = 50, `runs/mc_g1_0.6.0_smoke/`):
- 200/200 FIML converged, 43 s; parameter estimates identical to 0.5.0.
- **Effect biases:** all within 1.95 Monte Carlo SEs.
- **Coverage of the 95% delta-method intervals:** 0.84-0.96. The low end
  is the N = 500 cell, where ATU coverage is 0.84 (z = −3.6) and the SE
  ratios for ATU and BH1 are 0.72-0.75.
- With R = 50 this is not conclusive. It is the first sign that delta-method
  effect standard errors may be too small at N = 500. The WP1.7 study (N
  from 250 to 5000, R = 1000) will establish it. N = 500 is not a gated cell
  in the pre-registered design, but the result will be reported either way.

## Not verified, and limits

- Distributional effects that depend on Corr(eps1, eps0) are deliberately
  not estimated (plan decision D8). They are available only through
  `switch_simulate(potential_outcomes = TRUE, r10 = )` under a stated
  assumption.
- Coverage of the effect intervals at the pre-registered sample sizes is
  open until WP1.7.
- Remote CRAN-incoming checks are off locally; GitHub Actions has not run.

## Next

WP1.7 (v0.7.0): the pre-registered Monte Carlo study (core grid R = 1000,
one-factor-at-a-time cells R = 500, multistart sub-study; about 28 400
replications, each fitted by FIML and two-step) and the report `MC_G1.md`
against the thresholds of MONTE_CARLO_DESIGN.md. Estimated run time: several
hours on 3-4 cores, run in the background.
