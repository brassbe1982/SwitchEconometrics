# WP1.2: Model specification, distribution and parameter engines

Version 0.2.0. Completed 22 November 2026. Status: **done.**

The G1 econometric gate was approved by the owner on 22 November 2026: the
six questions of GENERATION_1.md section 3 were accepted as proposed. This is
recorded in ACCEPTANCE_TESTS.md section 2.

## What was done

| Layer | Files | Content |
| --- | --- | --- |
| 1 Specification | `R/switch_model.R`, `R/spec_support.R`, `R/spec_data.R` | Exported `switch_model()` with its `print`/`format` methods; a support table that names the generation of every planned argument value; the internal data builder `se_build_data()` |
| 2 Distributions | `R/dist_interface.R`, `R/dist_gaussian.R` | The `se_margin` contract (d, p, q, r, logd, logp, gradients on the working scale); the Gaussian margin; exported `distribution()` (experimental) |
| 5 Parameters | `R/par_transforms.R`, `R/par_map.R` | Transformations identity, log, atanh and log_shift2 (2 + exp), each with d1 and d2; the CPC correlation-matrix map and its inverse; an exact complex-step Jacobian; the parameter map (`se_parmap_esr()`, natural/working conversion, delta method, fixing parameters) |
| Utilities | `R/utils.R`, `R/lik_utils.R` | Classed conditions; `se_with_seed()`; stable log Phi, Mills ratio, delta (continued fraction for a <= -5), and the generated regressors m0, m1, d0, d1 |

**Behaviour of `se_build_data()`, as contracted in API_SPECIFICATION
section 1:**
- Rows with missing values are removed only with a message of class
  `switch_message_missing` and a `na_report` (counts per variable, removed
  rows); `missing = "fail"` makes this an error.
- An outcome may be missing in the regime where it is not observed.
- Regimes are matched by name (regime values, `regime_0`/`regime_1`, factor
  levels), otherwise by position with a message.
- Weights, cluster and subset are accepted as a formula, a column name or a
  vector.
- Infinite values give an error, as does rank deficiency of $z$ or of $x_j$
  within regime $j$; aliased columns are named.
- Factor levels and contrasts are stored for prediction.

## Evidence

- **Tests on the source: 8 files, 279 expectations, 0 failures, 0 skipped
  (14 s).** They cover:
  - transformation round trips, and first and second derivatives against
    `numDeriv`;
  - valid correlation matrices for d = 2-6 from random working values, the
    inverse to 1e-9, and the complex-step Jacobian against `numDeriv` to
    1e-8;
  - Gaussian functions identical to `stats`; log-density and log-cdf
    gradients (both tails) against `numDeriv` to 1e-8;
  - delta(a) = -lambda'(a) on [-40, 6] to 1e-6 relative; Mills-ratio bounds;
    dm_k/dw = -delta_k;
  - every `switch_model()` and data-builder contract above, including
    classed errors and messages.
- **`R CMD check --as-cran`** on `SwitchEconometrics_0.2.0.tar.gz`: 0 errors,
  0 warnings, 1 NOTE. The NOTE is "Skipping checking math rendering: package
  'V8' unavailable": V8 is not installed on this machine (toolchain notes),
  and the NOTE does not occur on systems with V8.

## Not verified, and limits

- Remote CRAN-incoming checks were off (local run); GitHub Actions has not
  run (no repository yet).
- The first roxygen pass printed a transient warning about the link to
  `switch_model` (not yet documented at that moment). The Rd cross-reference
  check of `R CMD check` passed.
- Nothing estimates yet. The parameter map is tested on its own; its use by
  the likelihood starts in WP1.3.

## Next

WP1.3 (v0.3.0): `lik_esr_gaussian()`, the per-observation log-likelihood,
analytic score and Hessian on the working scale with weights. It will be
compared with the `verify_math.R` reference implementation to 1e-10 and with
numerical derivatives.
