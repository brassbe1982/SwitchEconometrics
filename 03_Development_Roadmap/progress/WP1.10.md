# WP1.10: Release 1.0.0

Version 1.0.0. 23 November 2026. Status: **submitted to CRAN on 23 November 2026 and confirmed by the
maintainer; awaiting CRAN's decision**

## What was done

| File | Content |
| --- | --- |
| `04_Validation/results/EVIDENCE_G1.md` | Evidence table for AC1-AC6, the three gates, every documented exception and limit in one place, how to reproduce each result, and the release record |
| `DESCRIPTION` | Version 1.0.0; no code changes from 0.9.1 |
| `NEWS.md` | 1.0.0: what Generation 1 provides and how it was validated |
| `README.md` | Status: Generation 1 complete; 1.0.0 prepared for CRAN |
| `cran-comments.md` | Rewritten for the first submission: test environments for 1.0.0 and 0.9.1 (same code), the one NOTE and its explanation, timing |

The release followed `tools/CRAN_RELEASE_GUIDE.md` (skill
`switch-cran-release`) for the first time.

## Evidence

**`tools/CRAN_prepare.R full` on 1.0.0** (report
`release/cran_prepare_1.0.0.md`):

| Stage | Result |
| --- | --- |
| preflight | maintainer `Ibrahim.niankara@aau.ac.ae`; URL and BugReports; NEWS 1.0.0; AC1-AC6 met |
| tests | complete suite 650 expectations, CRAN mode 643, without Suggests 603; 0 failures |
| verify | `verify_math.R` 26/26 |
| build, check | tarball 183 KB; `--as-cran` 1 NOTE (V8 absent locally) |
| manual | PDF built |
| regression | Monte Carlo smoke test identical to the 0.8.1 reference (largest difference 0 in every field) |
| benchmarks | 1378 checks: 1275 pass, 103 differ, 70 documented; the same counts as BENCHMARK_G1.md, where every difference is explained |

**Outside checks on 1.0.0** (pushed as f813103 with the owner's yes, 23
November 2026):

| Environment | Result |
| --- | --- |
| GitHub Actions run 5: Windows, macOS and Ubuntu; R release, devel and oldrel-1 | all 9 jobs pass (the macOS R-devel job checks without Suggests, as for 0.9.1) |
| win-builder R-devel (r90926), results `ApelQEJHS0Y8` | 1 NOTE: "New submission" and the cited surnames Falco, Heckman, Lokshin, Sajaia, Veronesi, Yesuf; tests 28 s; vignettes 15 s |
| win-builder R-release (R 4.6.2), results `J8KpYTfC0RX8` | the same NOTE; tests 27 s; vignettes 16 s |
| macOS builder | upload refused by the service (HTTP 502), as for 0.9.1 |

Both `00check.log` files were read in full: every other check is OK,
including the remote CRAN incoming checks, the PDF and HTML manuals and the
re-building of the vignettes. The NOTE is the expected one, explained in
`cran-comments.md`.

## Submission

| Step | Record |
| --- | --- |
| Owner's go-ahead | Ibrahim Niankara in session, after being shown the tarball, maintainer, `cran-comments.md` text and the policy agreement: "Submit and push". This is also the owner's sign-off of Generation 1 |
| Upload | `tools/CRAN_prepare.R submit --yes`, 23 November 2026, 03:49:20 UTC: "Package submission successful". Tarball `SwitchEconometrics_1.0.0.tar.gz`, 186 954 bytes, git HEAD 3c10ffe (package files as in f813103). The comments as sent are kept in `release/cran-comments_1.0.0_as_submitted.md` (outside the repository) |
| Confirmation | The maintainer clicked CRAN's confirmation e-mail ("Clicked it") |
| CRAN incoming | Afterwards the package was in `https://cran.r-project.org/incoming/pretest/` (the automatic pre-tests) |
| CRAN decision | pending |

## Next

1. CRAN's decision. If CRAN asks for changes, start the release procedure
   again with 1.0.1 and answer every point in `cran-comments.md`.
2. Tag `v1.0.0` and a GitHub release with the NEWS section, each with the
   owner's go-ahead.
3. On acceptance: the CRAN installation line and the CRAN page in the
   README, in the next version; release record and memory updated.
