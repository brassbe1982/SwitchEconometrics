# Monte Carlo design (Generation 1)

Status: pre-registered in WP1.1 (22 November 2026), before any estimator
code exists. To be executed in WP1.7. Specification sections 9.1-9.2.
The thresholds below are fixed now so that the results cannot shape them.

## 1. Base data-generating process (specification section 9.1)

| Element | Specification |
| --- | --- |
| Regressors | $x_1, x_2, z_1$ i.i.d. $N(0, 1)$, independent of each other |
| Selection | $z = (1, x_1, z_1)$, $\gamma = (0.5, 0.3, -0.4)$; $z_1$ is the exclusion variable |
| Outcomes | $x_1 = x_0 = (1, x_1, x_2)$; $\beta_1 = (1.5, 0.8, 0.4)$, $\beta_0 = (1.0, 0.5, 0.2)$ |
| Disturbances | $\sigma_1 = \sigma_0 = 1$; $\rho_1 = 0.6$, $\rho_0 = 0.4$; $\operatorname{Corr}(\varepsilon_1, \varepsilon_0) = \rho_1\rho_0$ (irrelevant for observed data) |
| Implied $P(S = 1)$ | $\Phi(0.5/\sqrt{1.25}) = 0.673$ |

## 2. Experimental factors

| Factor | Levels (base in bold) |
| --- | --- |
| Sample size $N$ | 250, 500, **1000**, 2000, 5000 |
| Endogeneity $(\rho_1, \rho_0)$ | (0, 0), **(0.6, 0.4)**, (0.7, −0.5), (0.85, 0.85) (near the boundary) |
| Selection rate | 0.2, 0.5, 0.8 via the intercept $\gamma_0 = \Phi^{-1}(p)\sqrt{1.25}$ (−0.941, 0, 0.941); **0.673** (base) |
| Exclusion strength (coefficient of $z_1$) | −1.0 (strong), **−0.4** (moderate), −0.1 (weak), none ($z_1$ dropped from $z$: functional-form identification only) |
| Variance ratio $\sigma_1/\sigma_0$ | **1**, 2 |
| Effect heterogeneity in observables | **$\beta_1 \neq \beta_0$** (base); homogeneous slopes $\beta_1 = (1.5, 0.5, 0.2)$ |

**Cells.**
- **Core grid:** $N \times (\rho_1, \rho_0)$ at base settings. 20 cells,
  $R = 1000$ replications each.
- **One factor at a time** around the base, at $N \in \{500, 2000\}$:
  - selection rate (3 levels): 6 cells;
  - exclusion strength (3 non-base levels): 6 cells;
  - variance ratio 2: 2 cells;
  - homogeneous slopes: 2 cells.

  16 cells, $R = 500$ each.
- **Multistart sub-study:** $N = 500$, weak and no exclusion, $R = 200$,
  `starts = 10`. It counts distinct local maxima and checks whether the
  two-step start reaches the global maximum.

Total: about 28 400 replications, each estimated by FIML and two-step.

## 3. Per-replication outputs

- FIML (`starts = 1` outside the sub-study):
  - estimates;
  - Hessian and sandwich standard errors;
  - convergence code, iterations, gradient maximum, boundary flags, time.
- Two-step:
  - estimates;
  - model-based and stacked-sandwich standard errors.
- Effects (ATT, ATU, ATE, TH, BH1, BH0) with delta-method standard errors.
  The estimand is the same formula evaluated at the true parameters on that
  replication's sample (an effect conditional on the covariates and regimes).

## 4. Performance measures (specification section 9.2)

For parameter $\theta$ with true value $\theta_0$ and estimates
$\hat\theta_r$ over the $R_c$ converged replications:

| Measure | Formula | Monte Carlo standard error |
| --- | --- | --- |
| Bias | $\bar{\hat\theta} - \theta_0$ | $s/\sqrt{R_c}$ |
| Relative bias | $(\bar{\hat\theta} - \theta_0)/\lvert\theta_0\rvert$ (only for $\lvert\theta_0\rvert \ge 0.2$) | |
| RMSE | $\sqrt{R_c^{-1}\sum(\hat\theta_r - \theta_0)^2}$ | delta method |
| Empirical SD | $s$ | $\approx s/\sqrt{2(R_c - 1)}$ |
| Mean estimated SE | $\overline{\widehat{se}}$ | |
| SE ratio | $\overline{\widehat{se}}/s$ | |
| Coverage of the 95% interval | share of intervals containing $\theta_0$ ($\rho$: interval on the atanh scale) | $\sqrt{c(1-c)/R_c}$ (0.0069 at $R = 1000$) |
| Convergence rate | $R_c/R$ | |
| Boundary frequency | share with $\lvert\hat\rho_j\rvert > 0.995$ | |
| Time | median and 90th percentile seconds per fit | |

## 5. Pre-registered acceptance thresholds

**Gated cells:** FIML, core grid, $N \ge 1000$,
$(\rho_1, \rho_0) \in \{(0, 0), (0.6, 0.4), (0.7, -0.5)\}$. Nine cells.

| Criterion | Threshold |
| --- | --- |
| Relative bias of $\gamma$, $\beta$, $\sigma$ ($\lvert\theta_0\rvert \ge 0.2$) | $\le 5\%$ ($\lvert\text{bias}\rvert \le 0.01$ otherwise) |
| Bias of $\rho_j$ | $\le 0.03$ in absolute value |
| Root-$N$ behaviour | $\sqrt{5000}\,\text{RMSE}_{5000} / \sqrt{1000}\,\text{RMSE}_{1000} \in [0.8, 1.2]$ |
| SE ratio (Hessian) | $\in [0.90, 1.10]$ |
| 95% coverage | $\in [0.93, 0.97]$ |
| Convergence rate | $\ge 99\%$ |
| ATT, ATU, ATE | relative bias $\le 5\%$, coverage $\in [0.93, 0.97]$ |
| Two-step ($\beta$, $\theta_j$) | coverage of model-based intervals $\in [0.93, 0.97]$ at $N \ge 2000$ |

**Reported but not gated** (honest discussion required in `MC_G1.md`):
- $N < 1000$;
- the near-boundary cell (0.85, 0.85);
- weak and no-exclusion cells;
- the OFAT cells;
- the sandwich standard errors.

Failing a gated threshold blocks acceptance criteria 1 and 4
([ACCEPTANCE_TESTS.md](ACCEPTANCE_TESTS.md)) until the cause is understood
and fixed. The threshold is not changed after the fact.

## 6. Execution and reproducibility

- **Driver:** `04_Validation/scripts/mc_g1.R` (WP1.7). It uses the installed
  package version and records it.
- **Random numbers:** L'Ecuyer-CMRG streams; master seed 20261122; one
  stream per cell; replication $r$ uses substream $r$. Results depend only on
  the seed, not on the number of cores.
- **Storage:** raw output in `runs/mc_g1_<version>/` (workspace, not in git),
  one compressed file per cell. The summary tables and figures go to
  `04_Validation/results/MC_G1.md`.
- A small version ($R = 50$, four cells) runs as a smoke test at every
  version from 0.4.0 on.

## 7. Execution record (WP1.7, 22 November 2026)

Sections 1-6 above are unchanged since pre-registration. This section records
how the study was run and every departure from the plan.

- **Run.** Package 0.6.0 (estimator code identical in 0.7.0), all 38 cells,
  28 400 replications, 2 worker processes (the machine was shared with
  another job). Raw output in `runs/mc_g1_0.6.0_full/`. Gate evaluation by
  `scripts/mc_g1_report.R`, with the thresholds of section 5 written into the
  script. Results and interpretation: [results/MC_G1.md](results/MC_G1.md).
- **Departure 1: sandwich standard errors.** Section 3 lists them as
  per-replication outputs, but the first run did not record them (a driver
  omission). The whole study was rerun with the same seeds
  (`runs/mc_g1_0.6.0_full_sandwich/`); the driver now also stores the FIML
  sandwich and the two-step stacked sandwich. Outcome:
  - estimates, Hessian standard errors, effects, codes and log-likelihoods
    are identical to the first run (511 200 comparisons, maximum
    difference 0);
  - the gate CSV is byte-identical;
  - sandwich results are present in all 56 800 fits.

  The reported tables come from the rerun (MC_G1.md section 6).
- **Departure 2: supplementary analyses (not pre-registered, not gated).**
  They are reported as diagnostics only:
  - Monte Carlo standard errors of the failed checks (bootstrap over
    replications);
  - "oracle" standard errors from the average information at the true
    parameters, to separate standard-error formulas from finite-sample
    behaviour;
  - the behaviour of the identification diagnostics I5 and I6 in the
    exclusion-strength cells (`scripts/mc_g1_identification.R`). Econometric
    gate question 5 asked for this.
- **AC4(b)** (bootstrap and Hessian standard errors within 10% at
  N = 2000) is checked by `scripts/ac4b_bootstrap_check.R`. It is defined in
  ACCEPTANCE_TESTS.md, not in this design.
- **Thresholds.** Not changed. Ten of the 501 gated checks failed. Under
  section 5, acceptance criteria AC1 and AC4 stay blocked until the owner
  decides on the diagnosis in MC_G1.md section 4.
