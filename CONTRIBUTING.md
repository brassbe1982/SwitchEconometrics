# Contributing to SwitchEconometrics

Read these before changing code:
- `00_Project_Governance/DEVELOPMENT_POLICY.md`;
- the derivation documents in `01_Econometric_Architecture/`;
- the API contracts in `02_Computational_Architecture/API_SPECIFICATION.md`.

Rules for every change:

- Statistical changes start with the derivation document and an extension of
  `01_Econometric_Architecture/verify_math.R`. Code follows the documented
  model; it does not invent one.
- Every change needs tests (unit, derivative, nesting, recovery) and a passing
  `R CMD check --as-cran`.
- Version bump and `NEWS.md` entry for every change. Statistical definitions
  that change are announced even when the API does not.
- No silent removal of observations, no start-up messages, at most 2 cores
  in examples and tests, ASCII-only R code.
- Report honestly what was run and what was not.

Bug reports should include a reproducible example, `sessionInfo()`, and the
output of `switch_diagnostics()` for the fit concerned.
