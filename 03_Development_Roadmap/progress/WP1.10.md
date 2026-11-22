# WP1.10: Release 1.0.0

Version 1.0.0. 23 November 2026. Status: **STATUS_110**

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

CHECKS_110_OUTSIDE

## Next

NEXT_110
