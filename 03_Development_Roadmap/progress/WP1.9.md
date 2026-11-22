# WP1.9: Documentation and CRAN preparation

Versions 0.9.0 and 0.9.1. Completed 23 November 2026. Status:
**documentation and CRAN preparation done; the package is public on GitHub.**
- GitHub Actions passes on all 9 jobs.
- win-builder R-release and R-devel give 1 NOTE each (new submission; the
  cited authors' surnames).
- The macOS builder was unavailable (HTTP 502).
- **AC6 is met (owner, 23 November 2026: "Yes, mark AC6 met")**, with two
  documented exceptions: the macOS builder was unavailable, and the macOS
  R-devel CI job runs without the suggested packages.
- With AC3 and AC6 met and the documentation complete, the software gate's
  requirement is met. All six Generation 1 criteria are met.

## What was done

| File | Content |
| --- | --- |
| `vignettes/classical-esr.Rmd` | Specification, identification checks (I1-I11 explained), FIML and two-step estimation, `switch_compare()`, confidence intervals, LR and Wald tests including a linear hypothesis, covariance options, bootstrap (R = 99), diagnostics, the estimates against the true parameters of `firms`, weak identification, reproducibility record |
| `vignettes/treatment-effects.Rmd` | The four conditional expectations, the effect definitions, delta-method and bootstrap standard errors, the naive difference, effects by region and per unit, counterfactual (`all_regime_1`) and policy (internet access for all) scenarios, the non-identified correlation and its effect on the share of firms that gain (sensitivity over the admissible range) |
| `vignettes/simulation-validation.Rmd` | Precomputed tables from the WP1.7 and WP1.8 studies, with a recovery check and the code for a small Monte Carlo of the user's own design. The tables cover: coverage and SE ratios by N; the finite-sample coverage below N = 1000 (owner's decision in WP1.7); the ATU bias; σ at ρ = 0; exclusion strength with the I6 flags; cluster-robust coverage with 100 clusters (WP1.8); benchmark agreement |
| `README.md` | Rewritten for users: what the package does, example, vignettes, validation, status, roadmap, installation, citation |
| `DESCRIPTION` | Description of what this release does (no claims about later generations); Suggests `knitr`, `rmarkdown`; `VignetteBuilder: knitr` |
| `cran-comments.md` | New: test environments, notes, timing, downstream dependencies |
| `R/switch_model.R`, `R/methods_switch_fit.R`, `R/switch_effects.R`, `R/inf_tests.R` | Output fixes found while writing the vignettes: label alignment of the specification, version in the fit header, no empty heterogeneity row, the Wald H0 line |
| `tests/testthat/` | Assertions for the output fixes |
| `.gitignore`, `.Rbuildignore` | Vignette build artifacts |

**What was already in place.**
- `inst/CITATION` and the GitHub Actions workflow
  (`.github/workflows/R-CMD-check.yaml`: Windows, macOS and Ubuntu; R
  release, devel and oldrel-1) exist since WP1.1 and are unchanged.
- Every example already ran in under 1 s (check timings of 0.8.1).

## Evidence

- **Vignettes** render in 11.2 s, 7.9 s and 2.4 s. Every number quoted in
  their text was checked against the result files or computed inline.
- **Remote checks not run.** The checker of this environment refused the
  remote CRAN incoming checks (`_R_CHECK_CRAN_INCOMING_REMOTE_`, which
  checks URLs and DOIs over the network). They were not run. win-builder
  runs them.

**Package check (0.9.0, local):**
- Tests on the source: 650 expectations (7 new), 0 failures.
- `R CMD build` creates the three vignettes.
- `R CMD check --as-cran`: 0 errors, 0 warnings, 1 NOTE (V8 absent,
  environment only).
- Under check, 638 tests pass and 5 are skipped on CRAN. Re-building the
  vignettes takes 26 s.

## Version 0.9.1: public repository and outside checks (23 November 2026)

The owner asked for a repository like TriCopula's and approved the uploads.

**Repository.**
- https://github.com/brassbe1982/SwitchEconometrics was created in the
  built-in browser with the owner's GitHub session: public, described like
  TriCopula's, no README, licence or `.gitignore` from GitHub.
- An audit before the push found the 139 tracked files clean: no personal
  e-mail, passwords, keys, tokens or local paths, and nothing over 1 MB.
- Unlike TriCopula's, the repository also holds the project folders
  `00_`-`05_`, as the delivery plan's layout provides. They stay out of the
  tarball.
- `main` was pushed with Git Credential Manager (the stored sign-in).

**Package changes (0.9.1):**
- `URL` and `BugReports` in DESCRIPTION;
- installation from GitHub in the README;
- the version in `cran-comments.md`.

**Release tooling** (workspace, outside the repository), adapted from
TriCopula:
- `tools/CRAN_prepare.R`, with stages preflight, tests (complete, CRAN
  mode, without Suggests), verify, build, check, manual, regression (Monte
  Carlo smoke against a reference), benchmarks, install, gha, winbuilder,
  macbuilder and submit;
- `tools/compare_mc_runs.R`;
- `tools/CRAN_RELEASE_GUIDE.md` (access, release schedule for all six
  generations, procedure, pitfalls);
- the skill `.claude/skills/switch-cran-release/SKILL.md`.

**Results:**

| Check | Result |
| --- | --- |
| `CRAN_prepare.R local` (first run of the script) | Tests 650 / 643 (CRAN mode) / 603 (without Suggests) expectations, 0 failures. `verify_math.R` 26/26. Tarball 182 KB. `--as-cran` 1 NOTE (V8). Manual PDF built |
| GitHub Actions run 1 | 8 of 9 jobs pass: Windows, Ubuntu (release, devel, oldrel-1) and macOS (release, oldrel-1). macOS R-devel failed while installing dependencies: Matrix 1.7-6, needed by a suggested package, does not compile from source on that runner. The package check did not start there |
| win-builder R-release (R 4.6.2) | 0 errors, 0 warnings, 1 NOTE: "New submission" and the cited authors' surnames in DESCRIPTION. Incoming checks, the HTML manual (math rendering, which needs V8) and the PDF manual are OK |
| win-builder R-devel (2026-11-17 r90926) | 0 errors, 0 warnings, 1 NOTE, the same as R-release. Tests, vignettes, and the PDF and HTML manuals are OK |
| GitHub Actions run 2 | the workflow now runs the macOS R-devel job without the suggested packages (`dependencies: "hard"`, `_R_CHECK_FORCE_SUGGESTS_=false`), so the package check runs there too. **All 9 jobs pass** (commit 67650d5) |
| macOS builder | upload refused by the service: HTTP 502 |

## Acceptance criterion AC6

| Part | Status |
| --- | --- |
| `R CMD check --as-cran` locally: 0 errors, 0 warnings, notes explained | met: 1 NOTE (V8 absent), explained in `cran-comments.md` |
| GitHub Actions on Windows, macOS and Ubuntu (release, devel, oldrel-1) | needs the owner to create the GitHub repository and approve the push |
| win-builder (R-devel, R-release) and macOS builder | need the owner's approval for each upload |

## Not verified, and limits

- The remote incoming checks (URLs, DOIs) were not run locally.
- Math rendering in the Rd files is not checked locally: V8 is absent.
  CRAN's machines have V8.
- The vignettes were checked on Windows only.

## Next

- Owner actions for AC6: create the GitHub repository, approve the push,
  and approve the win-builder and macOS-builder uploads.
- After that, set `URL` and `BugReports` in DESCRIPTION to the repository.
- WP1.10 (v1.0.0): the evidence table for AC1-AC6, the computational and
  software gates, and the CRAN submission (owner).
