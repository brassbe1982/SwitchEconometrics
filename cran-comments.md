## Submission

SwitchEconometrics 1.0.0. This is a new submission: the first release of the
package.

SwitchEconometrics estimates endogenous switching regression models (the
classical binary model in this release): FIML and two-step estimation,
identification checks, treatment effects and counterfactual scenarios.

## Test environments

| Environment | Version | Result |
| --- | --- | --- |
| Local: Windows 11 Pro, R 4.6.2, `R CMD check --as-cran` | 1.0.0 | 0 errors, 0 warnings, 1 note (V8, below) |
| GitHub Actions: Windows, macOS and Ubuntu; R release, devel and oldrel-1 | 1.0.0 | to be run |
| win-builder R-release and R-devel | 1.0.0 | to be run |
| win-builder R-release (R 4.6.2) and R-devel (r90926) | 0.9.1 (same code) | 0 errors, 0 warnings, 1 note each (below) |
| GitHub Actions, all 9 jobs | 0.9.1 (same code) | pass |
| macOS builder | 0.9.1 | upload refused by the service (HTTP 502, 23 Nov 2026); the macOS jobs of GitHub Actions stand in |

The macOS R-devel job of GitHub Actions checks without the suggested
packages: the suggested benchmark package `sampleSelection` needs Matrix,
which did not compile from source on that runner in November 2026.

## R CMD check results

0 errors | 0 warnings | 1 note

- **"New submission".**
- **"Possibly misspelled words in DESCRIPTION": Falco, Heckman, Lokshin,
  Sajaia, Veronesi, Yesuf.** These are the surnames of the authors of the
  cited methods: Di Falco, Veronesi and Yesuf (2011); Heckman (1979);
  Lokshin and Sajaia (2004).

Locally there is also "Skipping checking math rendering: package 'V8'
unavailable". V8 is not installed on the development machine.
win-builder, which has V8, checks the HTML manual without a note.

## Tests and examples

- Every example runs in under 1 second.
- The test suite takes under 1 minute on CRAN (28 s on win-builder).
  Longer tests are skipped on CRAN with `skip_on_cran()`.
- The vignettes take about 20 seconds in total. Heavier results (the Monte
  Carlo study and the benchmarks) are precomputed and quoted in the text;
  they are not recomputed when the vignettes are built.

## Downstream dependencies

None (new package).
