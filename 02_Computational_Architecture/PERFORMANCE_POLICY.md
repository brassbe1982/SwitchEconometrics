# Performance policy

Status: WP1.1, 22 November 2026. Specification section 8; plan decision D10.

1. **Correctness before speed.** Optimise only code that is tested and
   profiled (`utils::Rprof`; `bench` when installed). Every optimisation keeps
   the regression references to 1e-8.
2. **Vectorised R first.** Per-observation quantities are computed as
   vectors and matrices. No loops over observations in R.
3. **C++ only after profiling** (specification section 8.3). A kernel moves
   to C++ (Rcpp/RcppArmadillo) only if:
   - it takes more than 50% of run time in a realistic profile; and
   - the expected speed-up exceeds 3x.

   The R version stays as the reference. Both are tested against each other
   to 1e-12. G1 stays free of compiled code; the expected first candidates are
   GHK for the multinomial probit (G2) and quadrature loops (G5).
4. **Time budgets.**

   | Item | Budget |
   | --- | --- |
   | Each documented example | < 5 s on a CRAN check machine |
   | Test suite on CRAN (`skip_on_cran()` for heavy tests) | < 2 min |
   | Vignettes | < 1 min each to build; heavy results precomputed and shipped in `inst/` with the script that produced them |
   | G1 FIML fit, n = 5000, `starts = 3` | target < 2 s on the development machine |
   | Full local test suite | reported in each progress note |
5. **Parallelism.** Opt-in (`cores =`), never by default. At most 2 cores in
   examples, tests and vignettes (CRAN policy).
6. **Memory.** No $n \times n$ matrices in cross-sectional models. Score
   matrices ($n \times p$) are formed only when needed: covariance, OPG,
   bootstrap.
