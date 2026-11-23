# Benchmarks, Generation 2

Protocol: [BENCHMARK_PROTOCOL.md](../BENCHMARK_PROTOCOL.md) sections 3 and 6.
Generated tables: [BENCHMARK_G2_generated.md](BENCHMARK_G2_generated.md)
(`benchmark_g2.csv`), produced by `scripts/benchmark_g2.R`. This note is
extended in each work package.

## WP2.1 (version 1.1.0, 23 November 2026)

Software: SwitchEconometrics 1.1.0 (installed in the private library
`runs/lib_g2`), `sampleSelection` 1.2-16, `endogenous` 1.0 (CRAN archive),
R 4.6.2. Datasets: designs H, T and Th of MONTE_CARLO_DESIGN.md section 8.2
with $\rho = 0.6$ at $N = 2000$ and $N = 10\,000$ (seeds 20261124-20261129),
and the Mroz (1987) Tobit-2 example of `sampleSelection`; saved in
`runs/benchmarks_g2/`.

**Result: 48 toleranced comparisons, 48 within tolerance, 0 outside;
4 documented differences; 4 comparisons not run.**

| Model | Benchmark | Result |
| --- | --- | --- |
| `heckman()` FIML | `sampleSelection::selection(method = "ml")` | log-likelihoods equal (largest difference 5e-11 on the simulated data); estimates within 7e-7; standard errors within 3.8e-6 (relative). Mroz example: see D-SS-2 |
| `heckman()` two-step | `selection(method = "2step")` | all coefficients, $\hat\sigma$, $\hat\rho$ and the coefficient of the inverse Mills ratio within 6e-11; standard errors: D-SS-3 |
| `treatment()` FIML, constant shift and hybrid | `sampleSelection::treatReg(method = "ml")` | log-likelihoods within 6e-11; estimates within 1e-6; standard errors within 3e-6 |
| `treatment()` FIML, constant shift and hybrid | `endogenous::hybrid()` | estimates within 2.1e-5 (its optimiser is less precise); model-based standard errors within 1.3e-4; ATT, ATU and ATE at both estimates within 2.1e-5 |
| `treatment()` two-step | `treatReg(method = "2step")` | **not run**: the benchmark function stops with an error |
| `tobit5()` FIML | `selection()` (Tobit-5, ML) | log-likelihoods within 2e-10; estimates within 1e-6 |

### Documented differences

BENCHMARK_PROTOCOL.md section 6.4 gives the cause of each.

- **D-SS-2 (Mroz example, two local maxima).** With the default three
  starts our fit reaches a log-likelihood 101.6 higher than the published
  solution, at $\hat\rho = 0.993$. From the two-step start alone it
  reproduces the published solution within the tolerances, and our
  likelihood at the published estimates equals the published
  log-likelihood. A user who wants the textbook numbers uses
  `switch_control(starts = 1)`; the default reports the higher maximum
  and records the lower one. A maximum this close to $\rho = 1$ deserves
  suspicion of the model for these data, not trust in either solution;
  `switch_validate()` and the Hessian condition number (1e12 with the
  unscaled income variable) say so.
- **D-SS-3 (probit information in the two-step covariance).** Differences
  of at most 2.3e-4 (relative) in the two-step standard errors.

### What these benchmarks do not show

- The treatment two-step estimator has no external benchmark.
- `endogenous::hybrid()` could not be run from its own starting values on
  two datasets; there it was started from our two-step estimates, so that
  comparison is less independent than the others.
- Robust and cluster covariances, weights, predictions and effects other
  than ATT, ATU and ATE were not benchmarked (no benchmark package reports
  them in our definitions).
