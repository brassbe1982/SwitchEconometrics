## Submission

Version 0.9.1, pre-release checks. The first CRAN submission is planned as
version 1.0.0.

This is a new submission. SwitchEconometrics estimates endogenous switching
regression models (the classical binary model in this release): FIML and
two-step estimation, identification checks, treatment effects and
counterfactual scenarios.

## Test environments

| Environment | Result |
| --- | --- |
| Local: Windows 11 Pro, R 4.6.2 (x86_64-w64-mingw32), `R CMD check --as-cran` | 0 errors, 0 warnings, 1 note (V8, below); remote incoming checks not run locally |
| win-builder (R-devel, R-release) | to be run (maintainer's approval) |
| macOS builder | to be run (maintainer's approval) |
| GitHub Actions: Windows, macOS and Ubuntu; R release, devel and oldrel-1 | to be run once the public repository exists |

## Notes

- **"New submission"** will appear on CRAN's incoming checks.
- **Locally, "Skipping checking math rendering: package 'V8' unavailable".**
  V8 is not installed on the development machine; the note is specific to
  that environment.

## Tests and examples

- Every example runs in under 1 second.
- The test suite takes about 1-2 minutes. Longer tests are skipped on CRAN
  with `skip_on_cran()`.
- The vignettes take about 20 seconds in total. Heavier results (the Monte
  Carlo study and the benchmarks) are precomputed and quoted in the text;
  they are not recomputed when the vignettes are built.

## Downstream dependencies

None (new package).
