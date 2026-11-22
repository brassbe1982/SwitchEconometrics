# Development policy

Adopted 22 November 2026 (WP1.1). Specification sections 14 and 17.

## 1. Work-package cycle

Each work package (WP) in [DELIVERY_PLAN.md](../03_Development_Roadmap/DELIVERY_PLAN.md)
goes through these steps:

1. Update or write the derivation documents; extend `verify_math.R` for the
   new formulas.
2. Implement in the layer files of
   [SOFTWARE_ARCHITECTURE.md](../02_Computational_Architecture/SOFTWARE_ARCHITECTURE.md).
3. Write tests:
   - unit tests against independent computations;
   - analytic-against-numerical derivative tests;
   - nesting tests;
   - fast recovery tests;
   - regression references.
4. Run the full test suite on the source, then `R CMD build` and
   `R CMD check --as-cran` on the tarball.
5. Bump the version and add a `NEWS.md` entry.
6. Write a progress note `03_Development_Roadmap/progress/WPx.y.md`: what was
   done, evidence, anything not verified, disappointing results.
7. Make one local git commit (standing authorisation, plan decision D12).

## 2. Versioning (specification section 14.3; plan decision D3)

- **Major:** generation boundary, or a breaking API or statistical-model
  change.
- **Minor:** a work package with new functionality.
- **Patch:** fixes and numerical corrections.

A change to the statistical definition of an existing estimator is documented
in `NEWS.md` even when the API is unchanged. Defaults reproduce the previous
version unless the change is announced.

## 3. Testing and numerical tolerances

| Comparison | Tolerance |
| --- | --- |
| Closed form against independent closed form, or integration | 1e-8 relative |
| Analytic against numerical derivatives (`numDeriv`, Richardson) | 1e-6 relative |
| Package against reference implementation (same formula) | 1e-10 |
| Regression references between versions | 1e-8 |
| Simulation-based checks | 4 Monte Carlo standard errors |
| Cross-software estimates | [04_Validation/BENCHMARK_PROTOCOL.md](../04_Validation/BENCHMARK_PROTOCOL.md) |

- Heavy tests are marked `skip_on_cran()`. They are kept and never weakened
  to pass.
- A failing test is investigated, not loosened.
- Delete `tests/testthat/_problems/` before building.

## 4. Dependencies (specification section 8; plan decision D10)

- **Imports:** `stats` and `utils` (base R), `maxLik`, `mvtnorm`, each added
  only when first used.
- **Suggests** (always called conditionally via `requireNamespace()` or
  `skip_if_not_installed()`):
  - `numDeriv`, `testthat`, `knitr`, `rmarkdown`;
  - `sandwich`, `copula`, `VineCopula`;
  - benchmark packages;
  - `TMB`, `spdep`.
- Never import `GJRM`, `sampleSelection` or `switchSelection` (specification
  section 8, item 4).

## 5. Code conventions

- **Files and style:** flat `R/` with layer prefixes; snake_case; two-space
  indentation; lines of at most 80 characters; ASCII only in R code and Rd
  (non-ASCII written as `\uxxxx`).
- **Documentation and conditions:** roxygen2 with markdown. Every exported
  function has examples that run in under 5 s. Errors and warnings are
  classed (`switch_error_*`, `switch_warning_*`).
- **Behaviour:**
  - no silent removal of observations or variables (specification section
    14.1);
  - no start-up messages;
  - no writing outside `tempdir()`;
  - the global random-number state is restored when a function draws random
    numbers;
  - at most 2 cores in examples, tests and vignettes.
- **Line endings:** LF in the repository (`.gitattributes`). R scripts are
  written by the editor tools, not by PowerShell redirection, which adds a
  BOM.

## 6. Repository events

- **Local:** one commit per completed WP, with the identity
  "Ibrahim Niankara <Ibrahim.niankara@aau.ac.ae>" set per repository.
- **External:** pushes, GitHub repository creation, win-builder and macOS
  builder uploads, and CRAN submissions happen only on the owner's explicit
  go-ahead at the time, showing what will be sent.

## 7. Rules for AI coding agents (specification section 17)

Agents implement the documented architecture. They do not make independent
assumptions about the econometric model.

- When a derivation is missing or ambiguous, the agent writes it into the
  relevant document and marks it for the econometric gate, rather than coding
  a guess.
- Reports state what was run and what was not.
