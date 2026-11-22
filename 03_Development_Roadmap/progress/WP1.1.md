# WP1.1: G1 mathematical and computational specification, package skeleton

Version 0.1.0. Completed 22 November 2026. Status: **done; awaiting the
owner's G1 econometric gate.**

## What was done

1. **Plan amended** (owner's decision at approval). Stata is removed from the
   whole development plan and process (DELIVERY_PLAN 1.1 change log, D11). It
   may be cited in the research article only.
2. **Benchmark packages installed** (approved): `sampleSelection` 1.2-16,
   `switchSelection` 2.1.0, `ssmrob` 1.0, `systemfit` 1.1-30.
3. **`sampleSelection` Tobit-5 conventions established by simulation**
   (n = 20 000):
   - its first outcome equation is regime 0 and its second is regime 1;
   - `rho1` and `rho2` carry the same sign as our $\rho_0$ and $\rho_1$;
   - two-step `invMillsRatio1` = $-\sigma_0\rho_0$.

   Recorded in BINARY_ESR.md section 6.
4. **Documents written**, covering all 12 items of specification section 20.

   | Folder | Documents |
   | --- | --- |
   | `00_Project_Governance` | SPECIFICATION (verbatim), PROJECT_CHARTER, SCIENTIFIC_SCOPE, DEVELOPMENT_POLICY |
   | `01_Econometric_Architecture` | GENERAL_MODEL, BINARY_ESR, LIKELIHOOD_DERIVATION, IDENTIFICATION, PARAMETERIZATION, TREATMENT_EFFECTS, verify_math.R |
   | `02_Computational_Architecture` | SOFTWARE_ARCHITECTURE, API_SPECIFICATION, NUMERICAL_METHODS, PERFORMANCE_POLICY |
   | `03_Development_Roadmap` | DELIVERY_PLAN (v1.1), GENERATION_1 to GENERATION_6 |
   | `04_Validation` | MONTE_CARLO_DESIGN (pre-registered thresholds), BENCHMARK_PROTOCOL, ACCEPTANCE_TESTS |
   | `05_References` | REFERENCES.bib |

5. **Package skeleton:**
   - DESCRIPTION, MIT licence (LICENSE and LICENSE.md), README, NEWS,
     CONTRIBUTING, inst/CITATION;
   - package documentation (roxygen2), a testthat suite;
   - .Rbuildignore (governance folders excluded), .gitignore, .gitattributes
     (LF), the RStudio project file;
   - GitHub Actions workflow (9 configurations; runs once the repository
     exists on GitHub).
6. **Workspace tool** `tools/check_package.R` (outside the repository): it
   roxygenises, runs the tests, builds and runs `--as-cran`.
7. **Local git repository** initialised with identity Ibrahim Niankara
   <Ibrahim.niankara@aau.ac.ae>; first commit made.

## Evidence

- **`verify_math.R`: 26 of 26 checks pass** (31 s; R 4.6.2, mvtnorm 1.4-2,
  numDeriv 2016.8-1.1, sampleSelection 1.2-16). Highlights:
  - the likelihood equals the integrated bivariate density (relative error
    4e-16);
  - analytic score and Hessian match numerical derivatives (3.8e-9 and
    1.4e-10);
  - the information-matrix equality holds at n = 200 000 (relative
    difference 0.0097);
  - conditional means and variances match two-dimensional integration
    (2e-11);
  - the stable delta(a) is accurate on [−40, 6] (5e-9);
  - P(S=1, Y≤y) is invariant to Corr(ε₁, ε₀);
  - effect gradients match numerical ones (5e-11);
  - our log-likelihood at `sampleSelection`'s ML estimates equals its
    reported value (9e-13).
- **Tests on the source:** 1 file, 6 expectations, 0 failures (0.8 s).
- **`R CMD check --as-cran`** on `SwitchEconometrics_0.1.0.tar.gz`: **Status
  OK** (0 errors, 0 warnings, 0 notes). Tests, the PDF manual and the HTML
  manual were all checked.

## Not verified, and limits

- **Remote CRAN-incoming checks** were off in this local run
  (`_R_CHECK_CRAN_INCOMING_REMOTE_=false`). A first CRAN submission will at
  least get the "New submission" note.
- **GitHub Actions** has not run: there is no GitHub repository yet (owner's
  action).
- **No estimator code exists yet.** The package-level acceptance criteria
  (AC1-AC6) are open, except the reference-level parts of AC2 and AC5 that
  `verify_math.R` covers.
- **Two-step Monte Carlo (V14).** The largest deviation of the SE/SD ratio
  from 1 is 5.5% (tolerance 10%; Monte Carlo SE about 2%). It is within
  tolerance but noted for the WP1.7 study.
- **V12a** shows no difference at all. `mvtnorm` integrates the unbounded
  dimension exactly, so the check confirms the marginalisation; the
  non-identification argument itself is analytic (IDENTIFICATION.md
  section 3).
- **References.** Volumes, pages and DOIs marked "to be verified" in
  REFERENCES.bib have not been checked against the publishers.

## For the econometric gate (owner)

The six questions in GENERATION_1.md section 3:
1. D8: non-identification of Corr(ε₁, ε₀) and the use of bounds or a stated
   assumption.
2. D9: the BH₁/BH₀ definitions.
3. The sample ATE definition.
4. The default covariance estimators.
5. The identification-diagnostic thresholds.
6. The pre-registered Monte Carlo design.

## Next

WP1.2 (v0.2.0) starts after the econometric gate: `switch_model()`, data
handling, the Gaussian margin, transformations and the parameter map.
