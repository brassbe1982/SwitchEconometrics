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

## WP2.2: designs L, D, Lw and L8 (version 1.2.0, 24 November 2026)

Run: `runs/mc_g2_1.2.0_full_lee`, 11 cells, 8500 replications, 3 cores,
2 h 36 min. The run used an interim build of 1.2.0; the final build gives
identical results on the smoke cells of these four designs (largest
difference 0, `runs/mc_g2_1.2.0_smoke` against
`runs/mc_g2_1.2.0_smoke_interim`). No fit stopped with an error and every
FIML fit converged in every cell. The driver was generalised for this work
package; its smoke run for H, T and Th reproduces the 1.1.1 smoke summary
(largest difference 1e-16), and the rewritten report reproduces the WP2.1
gate (428 checks, 426 passed).

**Gate, all designs delivered so far (H, T, L, D, L8): 964 checks, 959
passed, 5 failed** (2 are the Heckman checks of exception EX-G2-1; 3 are
new, in design L). Design G (normal-score model) is not in this count: its
run was still in progress when this section was written (see below).

| Criterion (sections 8.3, 8.4, 8.6) | L (FIML Lee, $N \ge 2000$) | D ($N = 5000$) | L8 ($N = 8000$) |
| --- | --- | --- | --- |
| Relative bias of coefficients and $\sigma$ ($\le 5\%$; $\lvert\text{bias}\rvert \le 0.01$ for small truths) | 80 / 80 | $\beta$: 9 / 9 (`"dmf"`), 9 / 9 (`"bfg1"`) | 60 / 60 |
| Bias of $\rho_j$ ($\le 0.03$) | 12 / 12 | | 8 / 8 (largest 0.0299) |
| Bias of $a_{jk}$ ($\le 0.03$) | | 6 / 6 (`"dmf"`), 9 / 9 (`"bfg1"`, largest 0.029) | |
| ATE and ATT, all pairs: relative bias ($\le 5\%$) | 24 / 24 | | not computed for $J = 8$ in the driver |
| Root-$N$ ratio of the RMSE ([0.8, 1.2]) | 58 / 58 | | |
| Standard-error ratio ([0.90, 1.10]) | 116 / 116 | | |
| 95% coverage, FIML ([0.93, 0.97]) | **113 / 116** | | |
| 95% coverage, Lee two-step, $N = 5000$ | 24 / 24 | | |
| Convergence ($\ge 99\%$) | 4 / 4 | | 1 / 1 |

### The three failed checks (design L, FIML, $N = 2000$)

| Cell | Quantity | Coverage | Limit | SE ratio | Bias |
| --- | --- | --- | --- | --- | --- |
| dependent | `r1:sigma` | 0.918 | [0.93, 0.97] | 0.958 | 0.00004 |
| independent ($\rho = 0$) | `r1:sigma` | 0.977 | [0.93, 0.97] | 1.099 | 0.0065 |
| dependent | `selection[r2]:z1` | 0.926 | [0.93, 0.97] | 0.946 | 0.0025 |

**Diagnosis (no defect found).**
- `r1:sigma`: the same two deviations appear at $N = 1000$ (0.918 and
  0.978, not gated) and are gone at $N = 5000$ (0.940 and 0.962): a
  small-sample effect. In the dependent cell at $N = 2000$ the estimate
  $\hat\sigma_1$ and its standard error have correlation 0.82 across
  replications ($\hat\sigma_1$ and $\lvert\hat\rho_1\rvert$: 0.83), so the
  symmetric interval misses on one side: 6.7% of the intervals lie below
  the truth and 1.6% above. Regime 1 is the base regime and has the
  largest correlation (0.5). This is the behaviour of $\sigma$ in the
  Heckman cell of exception EX-G2-1. Under independence the standard error
  is slightly too large (ratio 1.099, inside its band) and the interval
  over-covers.
- `selection[r2]:z1`: isolated. The same coefficient has coverage 0.945 to
  0.955 in the other five cells of design L, and its standard-error ratio
  in this cell is 0.946 (inside the band). Read as sampling variation; this
  cannot be proved from one run.
- The mean coverage over the 116 gated FIML coverage checks of design L is
  0.948. Bias, root-$N$ behaviour and the standard-error ratios all pass,
  the score and Hessian are analytic and tested against numerical
  derivatives, and the first step equals `mlogit` (BENCHMARK_G2.md).

**Consequence.** The thresholds are not changed. Following
MONTE_CARLO_DESIGN.md section 8.4 the diagnosis went to the owner, who on
24 November 2026 accepted the three checks as a documented exception
(EX-G2-2, ACCEPTANCE_TESTS.md section 7). They stay recorded as failed in
`gate_checks_G2.csv`. From version 1.2.1 the help page of
`multinomial_switch()` says that intervals for the $\sigma_j$ are not
reliable in samples of about 2000 observations or fewer.

### Reported, not gated

- **Design L, $N = 1000$ (FIML Lee):** largest relative bias 5.3% (an
  effect); coverage from 0.918 to 0.958.
- **Two-step Lee on design L:** biases as FIML at every $N$ (largest
  relative bias 1.3% at $N = 5000$).
- **Dubin-McFadden and BFG corrections on design L** (data from Lee's
  model, where their linearity assumption does not hold): the outcome
  intercepts are biased by up to 7% at every $N$ and the bias does not
  shrink with $N$; at $N \ge 2000$ ATE and ATT are biased by up to 23%
  (`"dmf"`) and 15% (`"bfg1"`, `"bfg2"`), at $N = 1000$ by up to 31%. Coverage of the effects falls to 0.80 for `"dmf"`
  at $N = 5000$.
- **Lee's correction on design D** (data linear in the Gumbel
  disturbances): outcome coefficients biased by up to 7.8% and effects by
  up to 12% at $N = 5000$, with coverage down to 0.71. Each model is
  biased on the other's data, in both directions.
- **Design D, `"bfg2"`:** the outcome coefficients are within 2.7% at
  $N = 5000$; its correction coefficients are not comparable with the
  $a_{jk}$ of the design (different normalisation) and are not gated.
- **Design D, standard errors at $N = 2000$:** bootstrap (199 replicates)
  ratios 0.935 to 1.060 and stacked-sandwich ratios 0.929 to 1.045 for
  `"dmf"`, `"bfg1"` and `"bfg2"`; neither is clearly better. A bootstrap
  fit takes about 3.2 s, a sandwich fit 0.1 s.
- **Design Lw (weak exclusions, $N = 2000$):** relative bias up to 13%
  (coefficients), 28% ($\rho_j$) and 24% (effects); coverage 0.83 to 0.95.
  The identification check I6 warned in 248 of 500 replications. This is
  the expected behaviour without usable exclusions; the cell documents
  it.
- **Design L8:** at $N = 4000$ the bias of one $\rho_j$ is 0.054;
  coverage ranges from 0.916 to 0.950 for the $\rho_j$ and from 0.846 to
  0.958 for the $\sigma_j$. At $N = 8000$ (gated for bias and
  convergence, both passed) coverage ranges from 0.912 to 0.970 for the
  $\rho_j$ and from 0.866 to 0.962 for the $\sigma_j$, and the
  standard-error ratios from 0.930 to 1.120 ($R = 500$, not gated). With
  about 1000 observations per regime at $N = 8000$, intervals for the
  $\sigma_j$ and $\rho_j$ of an 8-regime model are not yet reliable.
  (The version of this paragraph recorded with 1.2.0 attributed the two
  lowest values to the dependence parameters; they belong to a
  $\sigma_j$. Corrected in 1.2.1.)
- **Computing time per fit:** FIML Lee 0.16 to 0.25 s (3 regimes), 0.85 s
  (8 regimes, $N = 8000$); two-step 0.1 to 0.4 s.

### Design G and cell LN (normal-score model): run in progress

The run `runs/mc_g2_1.2.0_full_ns` (designs G and LN, 1300 fits of the
normal-score model) was started on 24 November 2026 and had not finished
when version 1.2.0 was recorded. **G2-NS-1 is therefore open.** What is
known:
- Smoke run (`runs/mc_g2_1.2.0_smoke_G`, $N = 2000$, 20 replications): no
  errors; **14 of the 20 fits ended at the boundary of the correlation
  region** (not converged, flagged), 6 converged; mean time 276 s per fit
  with three fits running at once.
- On one simulated sample of 40 000 observations the score at the true
  parameters is centred (chi-square 25.1 on 29 degrees of freedom), so
  the likelihood and the simulator agree. The outer-product information
  at the truth implies standard errors of 0.32 to 0.62 for the
  correlations with the other regimes' disturbances at $N = 2000$ and
  0.20 to 0.39 at $N = 5000$ (0.15 to 0.19 for the own correlations at
  $N = 5000$). With such standard errors and a bounded parameter region,
  boundary estimates are frequent at $N = 2000$, and the pre-registered
  bias limit of 0.05 at $N = 5000$ is demanding.
The gate result of design G will be added to this note when the run ends.

### What this study does not show (WP2.2)

- Effects for 8 regimes were not part of the driver; the package test
  checks them on one data set.
- Sampling weights, cluster-robust covariances and predictions were not
  part of it.
- One selection design for 3 regimes (and its weak-exclusion variant).
