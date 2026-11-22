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
| win-builder R-release (R 4.6.2, Windows Server 2022), 0.9.1, 23 Nov 2026 | 0 errors, 0 warnings, 1 note ("New submission"; possibly misspelled words, below). The incoming checks, the HTML manual (math rendering) and the PDF manual are OK |
| win-builder R-devel | uploaded 23 Nov 2026; result e-mail not yet received |
| macOS builder | upload refused by the service (HTTP 502, 23 Nov 2026); the macOS jobs of GitHub Actions stand in |
| GitHub Actions (run 1, 0.9.1): Windows, macOS and Ubuntu; R release, devel and oldrel-1 | 8 of 9 jobs pass. macOS R-devel stopped before the package check, while installing dependencies: Matrix 1.7-6, needed by a suggested package, failed to compile from source on the runner (`Csparse.o`). From run 2 that job checks without the suggested packages |

## Notes

- **"New submission".**
- **"Possibly misspelled words in DESCRIPTION": Falco, Heckman, Lokshin,
  Sajaia, Veronesi, Yesuf.** These are the surnames of the authors of the
  cited methods: Di Falco, Veronesi and Yesuf (2011); Heckman (1979);
  Lokshin and Sajaia (2004).
- **Locally, "Skipping checking math rendering: package 'V8' unavailable".**
  V8 is not installed on the development machine. win-builder, which has
  V8, checks the HTML manual without a note.

## Tests and examples

- Every example runs in under 1 second.
- The test suite takes about 1-2 minutes. Longer tests are skipped on CRAN
  with `skip_on_cran()`.
- The vignettes take about 20 seconds in total. Heavier results (the Monte
  Carlo study and the benchmarks) are precomputed and quoted in the text;
  they are not recomputed when the vignettes are built.

## Downstream dependencies

None (new package).
