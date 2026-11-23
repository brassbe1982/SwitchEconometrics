# Monte Carlo results, Generation 2

Design and pre-registered thresholds:
[MONTE_CARLO_DESIGN.md](../MONTE_CARLO_DESIGN.md) section 8 (approved by the
owner on 23 November 2026, before any estimator code existed). Generated
tables: [MC_G2_generated.md](MC_G2_generated.md), `mc_g2_summary.csv`,
`mc_g2_cells.csv`, `gate_checks_G2.csv`, produced by `scripts/mc_g2.R` and
`scripts/mc_g2_report.R`. This note is extended in each work package; the
gate is evaluated again on the rerun with the release candidate in WP2.5.

## WP2.1: designs H, T and Th (version 1.1.0, 23 November 2026)

Run: `runs/mc_g2_1.1.0_full`, 18 cells, 17 000 replications, 3 cores,
32 minutes; FIML with one start (the two-step start) and the two-step
estimator in every replication. No fit failed and every FIML fit converged
(convergence rate 1.000 in all cells).

**Gate: 428 checks, 426 passed, 2 failed.**

| Criterion (section 8.4) | H | T |
| --- | --- | --- |
| Relative bias of coefficients and $\sigma$ ($\le 5\%$) | 42 / 42 | 48 / 48 |
| Bias of $\rho$ ($\le 0.03$) | 6 / 6 | 6 / 6 |
| Root-$N$ ratio of the RMSE ([0.8, 1.2]) | 16 / 16 | 22 / 22 |
| Standard-error ratio ([0.90, 1.10]) | 48 / 48 | 66 / 66 |
| 95% coverage, FIML ([0.93, 0.97]) | **46 / 48** | 66 / 66 |
| 95% coverage, two-step ($N \ge 2000$) | 16 / 16 | 20 / 20 |
| Convergence ($\ge 99\%$) | 6 / 6 | 6 / 6 |
| ATE and ATT: relative bias ($\le 5\%$) | n/a | 12 / 12 |

### The two failed checks

Both are in the Heckman cell with $N = 1000$ and $\rho = 0.6$ (about 673
observed outcomes), FIML:

| Quantity | Coverage | Limit | SE ratio | Bias |
| --- | --- | --- | --- | --- |
| `outcome:sigma` | 0.925 | [0.93, 0.97] | 0.985 | 0.0011 |
| `outcome:rho` | 0.926 | [0.93, 0.97] | 0.936 | $-0.0083$ |

**Diagnosis (no defect found).**
- The coverage of the same two parameters rises with $N$ in this design:
  0.923 and 0.915 at $N = 500$ (not gated), 0.925 and 0.926 at 1000,
  0.931 and 0.945 at 2000, 0.951 and 0.949 at 5000. This is the pattern
  of a small-sample effect, not of a wrong variance formula.
- The sampling distribution of $\hat\rho$ at $N = 1000$ is skewed
  (skewness $-0.86$) and its standard error is too small on average (ratio
  0.936). With the symmetric interval on the natural scale the coverage of
  $\rho$ would be 0.904; the interval on the $\operatorname{atanh}$ scale,
  which the package reports, gives 0.926. The two parameters miss
  together in 4.3% of the replications: one event, counted twice.
- The estimator itself is not in question: bias and the root-$N$ behaviour
  pass, the likelihood, estimates and standard errors equal those of
  `sampleSelection` (BENCHMARK_G2.md), and the same code passes all 66
  coverage checks of the treatment design, where every unit contributes to
  the outcome equation.
- Statistically, 925 of 1000 is not distinguishable from the limit 0.93
  ($p = 0.28$) but it is below 0.95 ($p = 0.0004$): the under-coverage at
  this sample size is real and small.

**Consequence.** The threshold is not changed (handoff section 3).
Following MONTE_CARLO_DESIGN.md section 8.4 the diagnosis went to the
owner, who on 24 November 2026 accepted the two checks as a documented
exception (EX-G2-1, ACCEPTANCE_TESTS.md section 7). They stay recorded as
failed in `gate_checks_G2.csv`. From version 1.1.1 the help page of
`heckman()` says that intervals for $\rho$ and $\sigma$ are somewhat too
short with fewer than about 1000 observed outcomes and an exclusion of
moderate strength.

### Reported, not gated

- **$N = 500$:** coverage of $\rho$ 0.915 (H) and 0.927 (T) at
  $\rho = 0.6$; standard-error ratio of $\rho$ 0.840 (H). Bias of $\rho$
  $-0.025$ (H).
- **Design Th (hybrid, $R = 500$):** at $N = 1000$ the largest relative
  bias is 1.7% (FIML) and 2.3% (two-step); standard-error ratios from
  0.906 to 1.044; coverage of $\sigma$ and $\rho$ 0.912 and 0.922. At
  $N = 5000$ all standard-error ratios are within 2% of 1 for $\sigma$ and
  $\rho$ and their coverage is 0.942.
- **Sandwich standard errors (FIML):** ratios close to the default ones in
  the gated cells; at $N \le 1000$ with $\rho = 0$ the sandwich standard
  error of $\sigma$ is too large (ratio 1.125 to 1.131 in design H).
- **Two-step $\hat\rho$ outside $(-1, 1)$:** 24 of 1000 replications in
  design H at $N = 500$, $\rho = 0.6$; 1 at $N = 1000$; 3 in design T at
  $N = 500$; none at $N \ge 2000$.
- **Computing time:** 0.07 to 0.16 s per FIML fit.

### A defect found by this study and fixed before the release of 1.1.0

The first run (kept in `runs/mc_g2_1.1.0_full_run1`) showed the
identification check I6 (collinearity of the correction term) raising a
warning in every replication of the treatment designs. Cause: for the
treatment model the check regressed the generalised residual $h$ on
$(x, S d)$ over all units; $h$ changes sign with $S$, so that $R^2$ is high
by construction and says nothing about identification. The check now
reports the larger of the two within-group $R^2$ values, as in the
switching model, and a package test covers it. The estimates are not
affected (the first and the final run give identical estimates). In the final run I6 warns in none of the 17 000 replications.

### What this study does not show

- Sampling weights, cluster-robust covariances, the bootstrap and
  predictions were not part of it.
- One selection design only (the G1 base design, exclusion coefficient
  $-0.4$); stronger or weaker exclusions were not varied for these models.
- Coverage is gated with $R = 1000$: a true coverage of 0.95 falls outside
  [0.93, 0.97] with probability 0.003 per check, so chance alone does not
  explain the two failures.
