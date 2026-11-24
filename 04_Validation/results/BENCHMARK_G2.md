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

## WP2.2 (version 1.2.0, 24 November 2026)

Software: SwitchEconometrics 1.2.0 (`runs/lib_g2`), `switchSelection`
2.1.0, `mlogit` 2.0.0, `nnet` 7.3-21, R 4.6.2. Datasets: design L (3
regimes) at $N = 2000$ and $N = 10\,000$ and design L8 (8 regimes) at
$N = 8000$, generated in the script with base R (seeds 20261201-20261203)
and saved in `runs/benchmarks_g2/`. The comparisons and tolerances were
written into the script before it was run on these data.

**Result, all of G2 so far: 66 toleranced comparisons, 66 within
tolerance, 0 outside; 8 documented differences; 4 comparisons not run**
(the four `treatReg` two-step rows of WP2.1). The 18 new toleranced
comparisons:

| Model | Benchmark | Result |
| --- | --- | --- |
| Multinomial logit (first step), 3 and 8 regimes | `mlogit::mlogit()` | log-likelihoods equal (difference 0 at the printed precision); estimates within 2.7e-7; standard errors within 1.4e-14 (relative) |
| Multinomial logit (first step) | `nnet::multinom()` | log-likelihoods within 7.3e-12 |
| Two-step `correction = "bfg1"`, 3 regimes | `switchSelection::msel(type3 = "logit", estimator = "2step")` | outcome and correction coefficients: differences 5.2e-6 and 1.4e-6, **outside the tolerance 1e-6** (D-MS-2); our second step at msel's first-step estimates: within 2.0e-15; selection coefficients after the change of base: within 2.9e-6 (tolerance 1e-3); standard errors: D-MS-1 |

### Documented differences (WP2.2)

- **D-MS-1 (Jacobian of the two-step sandwich).** Our stacked-sandwich
  standard errors of the outcome and correction coefficients differ from
  msel's by up to 1.3% ($N = 2000$) and 0.4% ($N = 10\,000$). msel
  differentiates the sample moments; our sandwich uses the expected
  derivative of the second-step moments with respect to the selection
  coefficients (the term containing the residuals, which has mean zero, is
  left out, as in Generation 1). With the Jacobian of the sample moments in
  the same formula our standard errors equal msel's to 5.4e-6 (toleranced
  row, limit 1e-4). The standard errors of the selection coefficients are
  the same in both.
- **D-MS-2 (precision of msel's first step).** The direct comparison of the
  outcome and correction coefficients is outside the tolerance that was
  set (5.2e-6 and 1.4e-6 against 1e-6). Cause: at msel's first-step
  estimates the largest element of the multinomial-logit score is 9e-4 and
  1.8e-3; at ours it is below 3e-13. With msel's first-step estimates our
  second step reproduces its coefficients to 2e-15.
- Convention established: msel takes the **last** alternative as the base
  of the multinomial logit, and its selectivity terms for `type3 =
  "logit"` are those of our `"bfg1"` (own regime $-\log P_j$, other
  regimes $P_k\log P_k/(1 - P_k)$), not those of `"dmf"` with the
  sum-to-zero restriction.

### What these benchmarks do not show (WP2.2)

- **The FIML estimator of Lee's model has no external benchmark**: no
  software available here estimates it. It is checked against the direct
  formula and numerical derivatives in the package tests, against its own
  two-step estimator and by Monte Carlo (designs L and L8).
- `"dmf"` and `"bfg2"` have no external benchmark (Stata's `selmlog` is not
  available); they are checked by simulation (design D) and through the
  code they share with `"bfg1"`.
- The normal-score model has no external benchmark; its likelihood is
  checked against an independent numerical reference built on `mvtnorm`.
- Effects, predictions, weights and cluster covariances of the multinomial
  models were not benchmarked.
