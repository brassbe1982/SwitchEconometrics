# WP1.5: Inference and diagnostics

Version 0.5.0. Completed 22 November 2026. Status: **done.** One item is
raised for the owner: the falsification test (I10) amendment.

## What was done

| File | Content |
| --- | --- |
| `R/inf_tests.R` | `switch_test()`: LR test of independent equations (restricted FIML refit with rho fixed at 0 through the parameter map's fixed-parameter mechanism); Wald test of independence (rho on the natural scale for FIML; selection-correction coefficients for two-step); general linear Wald tests. The hypothesis parser replaces parameter names longest first, checks linearity numerically and rejects dependent restrictions |
| `R/methods_summary.R` | `confint()` (transformed-Wald default, natural-Wald option) and `summary()` with its print method |
| `R/inf_bootstrap.R` | `switch_bootstrap()`: nonparametric (observations or clusters), parametric (redraws regimes and outcomes; no assumption on Corr(eps1, eps0) needed); FIML refits from the original estimate with a two-step fallback; per-replicate L'Ecuyer streams; caller's RNG kind and state restored; failure counting with reasons; parallel PSOCK workers through a top-level worker function (no `:::`); `print`, `vcov`, `confint` methods |
| `R/inf_identification.R` | `switch_validate()` with the checks I1-I11 of IDENTIFICATION.md section 4, including a classification of how each parameter group is identified. Stored in every fit; `switch_fit()` warns when identification rests on functional form alone |
| `R/inf_diagnostics.R` | `switch_diagnostics()`: computational and statistical parts kept separate |
| `tests/testthat/test-inference.R` | 15 tests |
| `04_Validation/scripts/falsification_test_sim.R` | Evidence for the I10 amendment |

`parallel` moved into Imports. FIML covariance types were already
delivered in 0.4.0.

## Evidence

**Tests on the source:** 11 files, 528 expectations, 0 failures (60 s).
One skip: the parallel test, which needs the installed package. **Under
`R CMD check --as-cran`:** 522 pass. The parallel test ran and passed. The
two heavy local tests were skipped on CRAN. 0 errors, 0 warnings, 1 NOTE
(V8 absent).

- **LR test.** The restricted log-likelihood equals `glm` probit + two `lm`
  log-likelihoods to 1e-9, and the statistic equals 2(ℓ − ℓ_R). With
  weights, a classed warning says the statistic is not χ².
- **Wald tests.** Independence tests equal hand computations for FIML and
  two-step. String and matrix hypotheses agree, constants and coefficients
  are parsed, and non-linear, dependent, unknown or malformed hypotheses are
  refused.
- **Intervals.** rho intervals equal tanh(atanh(rho) ± z·se) and lie in
  (−1, 1); sigma intervals equal exp(log sigma ± z·se). Two-step sigma and
  rho have NA intervals.
- **Bootstrap.**
  - Reproducible; the RNG state and kind are restored.
  - Parallel (2 cores) equals serial.
  - The parametric two-step bootstrap gives finite standard errors for sigma
    and rho; clusters are resampled.
  - Failures are counted with reasons: about 37% of resamples lose a
    single-observation regressor, with reason "rank" and a warning.
  - FIML bootstrap standard errors (n = 1000, R = 200) are within 0.75-1.33
    of the Hessian standard errors (local test).
- **Identification.**
  - All codes I1-I11 are produced for a specification and for a fit.
  - The no-exclusion specification gives I4 warnings and the classification
    "normality (functional form) only".
  - An irrelevant exclusion (coefficient 0) gives an I5 warning.
  - A rank problem becomes an I1 error row; an unknown variable becomes an
    I0 row.
  - `switch_fit()` without exclusions raises two identification warnings,
    one per regime.
- **Regression.** The Monte Carlo smoke test with 0.5.0 (39 s, 200/200
  FIML converged) is identical to 0.4.0 (largest difference in estimates and
  standard errors: 0).

## Finding raised for the owner: the falsification test I10

The approved IDENTIFICATION.md let I10 raise a warning when the excluded
variables are significant in the regime-0 outcome regression (Di Falco,
Veronesi and Yesuf 2011). The first fit on correctly specified simulated
data produced that warning.

The reason: under selection on unobservables, E[y | S = 0, x, z] contains
sigma_0 rho_0 m_0(z'gamma), which depends on the excluded variables.

Simulation (n = 1000, 5% level; reproduced by the standalone script):

| | Valid exclusion, rho_0 = 0.4 (R = 400) | Invalid exclusion, direct effect 0.15 (R = 200) |
| --- | --- | --- |
| Literal test | 0.51 | 1.00 |
| Conditional on m_0(ŵ) | 0.05 | 0.05 |

The literal test is badly over-sized. The conditional version has the right
size but no power, consistent with the untestability of a just-identifying
exclusion restriction.

I10 now reports both p-values and is always a note. This is recorded as an
amendment in IDENTIFICATION.md section 6, pending the owner's confirmation.
It is also relevant for the research article.

## Not verified, and limits

- Bootstrap intervals are percentile and normal only (BCa and bootstrap-t
  come in G4, as planned).
- The bootstrap does not yet cover treatment effects (`statistics =
  "effects"` arrives in 0.6.0 with `switch_effects()`).
- Coverage of the tests and intervals is not yet established; that is the
  WP1.7 Monte Carlo study.
- Remote CRAN-incoming checks are off locally; GitHub Actions has not run.

## Next

WP1.6 (v0.6.0):
- `switch_effects()`: the four conditional expectations, ATT, ATU, ATE,
  TH, BH1 and BH0, with delta-method and bootstrap standard errors;
- `switch_predict()` and `predict()`, `fitted()`, `residuals()`;
- `switch_counterfactual()`, `switch_simulate()` and `simulate()`,
  `switch_compare()`, `anova()`, `update()`;
- the model-frame and model-matrix methods;
- the simulated dataset `firms`.
