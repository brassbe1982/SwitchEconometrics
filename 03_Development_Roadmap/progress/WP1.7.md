# WP1.7: Pre-registered Monte Carlo study

Version 0.7.0. Completed 22 November 2026. Status: **study done and
reported. The gate is not passed as pre-registered (491 of 501 checks), so
AC1 and AC4 remain open pending the owner's decision.**

## What was done

| File | Content |
| --- | --- |
| `04_Validation/scripts/mc_g1.R` | Driver changes:<br>• two-step selection-correction coefficients recorded (for C8);<br>• resumable cells;<br>• parallel bug fixed (argument clash with `parLapply()`);<br>• FIML sandwich and two-step stacked-sandwich standard errors recorded (design s.3; the first full run had omitted them) |
| `04_Validation/scripts/mc_g1_report.R` | New. Evaluates C1-C8 with the thresholds written into the script, lists every failed check, writes the generated tables (including sandwich results and time per fit) and the CSV files |
| `04_Validation/scripts/mc_g1_identification.R` | New, supplementary. Behaviour of the I5 and I6 identification diagnostics in the exclusion-strength cells, linked to the FIML results of the same replications |
| `04_Validation/scripts/ac4b_bootstrap_check.R` | New. AC4(b): bootstrap and Hessian standard errors at N = 2000 |
| `04_Validation/results/MC_G1.md` | Results and interpretation |
| `04_Validation/results/MC_G1_generated.md`, `gate_checks_G1.csv`, `mc_g1_summary.csv`, `ac4b_bootstrap_G1.csv`, `ident_G1_summary.csv` | Generated outputs |
| `04_Validation/MONTE_CARLO_DESIGN.md` | Section 7, the execution record with its two departures; sections 1-6 unchanged |
| `tests/testthat/test-estimation.R` | The AC1(b) recovery test now runs on CRAN, as the criterion requires |

## Evidence

**The study.**
- 38 cells, 28 400 replications.
- FIML converged in 100% of fits in every cell except three: the
  near-boundary cell at N = 250 (99.0%) and N = 500 (99.9%), and the
  no-exclusion cell at N = 500 (99.8%).
- 1.6 hours of cell time on 2 workers.

**Gate: 491 of 501 checks pass** (MC_G1.md s.3):
- C1, C2, C3, C6 and C8 pass completely (213 checks).
- C4: 1 failure. C5: 6 failures. C7: 3 failures.

**Diagnosis** (MC_G1.md s.4):
- **Monte Carlo standard errors** of every failed check (bootstrap over
  replications).
- **Oracle comparison:** the Hessian SE agrees with the asymptotic SE at the
  true parameters to within 2.3% in all four cells checked (N = 1000 to
  5000), except σ at ρ = 0, where it is 1.20-1.23 times larger.
- **σ at ρ = 0:** the estimated variance of σ̂ rises with ρ̂² (t = 42 and
  56).
- **Coverage converges with N:** pooled coverage rises from 0.926 to 0.949
  for parameters and from 0.896 to 0.949 for effects between N = 250 and
  5000.
- **Multiplicity:** 3.5 C5 failures are expected under the estimated spread
  of true coverages (90% range 1-7); 6 were observed.

**AC4(b)** (MC_G1.md s.8): 27 of 30 ratios within 10%.
- `firms`: 15/15.
- Base design: 12/15. There the Hessian SEs match the true spread within 6%,
  and the bootstrap overstates it by 14-27%.

**I5/I6 study** (MC_G1.md s.7):
- 6000 replications in 8 cells.
- No false alarms in the base and strong designs.
- With a weak exclusion at N = 2000, only 15-44% of samples are flagged.
- Proposal to the owner: I6 threshold R² > 0.80.

**Package (0.7.0).**
- Tests on the source: 631 expectations, 0 failures (150 s, machine
  shared).
- `R CMD check --as-cran`: 0 errors, 0 warnings, 1 NOTE (V8 absent,
  environment only).
- Under check, 624 pass and 4 are skipped on CRAN; the recovery test no
  longer skips.

**Sandwich rerun** (MC_G1.md s.6), into `runs/mc_g1_0.6.0_full_sandwich/`,
2.5 hours of cell time:
- **Exact reproduction:** 511 200 comparisons of estimates, Hessian SEs,
  effects, effect SEs, codes and log-likelihoods; maximum difference 0.
- **Same gate:** the gate CSV is byte-identical to the first run's.
- **Coverage:** sandwich results are present in all 56 800 fits.
- **FIML sandwich in the gated cells** (thresholds applied for information
  only): 1 SE-ratio and 4 coverage values out of range, against 1 and 6 for
  the Hessian. Mean coverage 0.947 against 0.948. The σ-at-ρ = 0
  conservatism and the N = 1000 under-coverage appear under both, which
  confirms the diagnosis.
- **Two-step stacked sandwich:** all 66 coverages in the gated cells at
  N ≥ 2000 lie within [0.93, 0.97].
- **Small samples:** at N = 250 the Hessian intervals cover better (0.928
  against 0.922).

The generated tables and CSV files come from this rerun.

## Not verified, and limits

- The coverage of bootstrap intervals has not been evaluated by simulation.
  Only bootstrap standard errors were compared with Hessian standard errors
  (AC4(b), one dataset each).
- Sandwich and cluster standard errors were not evaluated under
  misspecification or clustering. The study's design is correctly
  specified and independent.
- The documentation does not yet tell users about finite-sample coverage at
  N ≤ 1000. This is carried to WP1.9 (vignette `simulation-validation`).

## Next

- The owner decides on the diagnosis (MC_G1.md section 9).
- WP1.8 (v0.8.0): the benchmark report, `sampleSelection` and archived
  `endoSwitch` (AC3).
