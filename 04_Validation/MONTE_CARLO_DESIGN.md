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
  section 5, acceptance criteria AC1 and AC4 were blocked until the owner
  decided on the diagnosis in MC_G1.md section 4.
- **Owner decision, 22 November 2026.** The diagnosis is accepted. The ten
  failures are recorded as understood finite-sample properties with no
  defect (MC_G1.md section 9, option 1), and AC1 and AC4 are met with
  documented exceptions. Sections 1-6, including the thresholds, stay as
  pre-registered.

---

# Generation 2

## 8. Monte Carlo design for Generation 2

Status: **pre-registered. The owner approved the G2 econometric gate on 23
November 2026** (gate question 11), before any G2 estimator code existed.
The designs and thresholds of sections 8.1-8.5 are fixed and are not
changed after results are seen (handoff section 3). Section 8.6 adds cells
that follow from the owner's amendments to the gate; they were written on
the same day, also before any estimator code, and no existing cell or
threshold was altered. Sections 1-7 (Generation 1) are unchanged.

### 8.1 Common elements

- Regressors $x_1, x_2, z_1, z_2$ i.i.d. $N(0, 1)$. Outcome design
  $(1, x_1, x_2)$ in every regime. $z_1$ and $z_2$ are excluded from the
  outcome equations.
- Outcome parameters for three-regime designs:
  $\beta_1 = (1.0, 0.5, 0.2)$, $\beta_2 = (1.5, 0.8, 0.4)$,
  $\beta_3 = (2.0, 0.3, -0.3)$; $\sigma = (1, 1, 1.2)$.
- Performance measures: section 4. Effects: $ATE_{jk}$ and $ATT_{jk}$ for
  all pairs; the estimand is the same formula at the true parameters on the
  replication's sample.
- Each fit records estimates, standard errors (default covariance and
  sandwich), convergence code, iterations, gradient maximum, boundary
  flags, the identification diagnostics I4b, I5, I6, I12, and time.
- FIML uses `starts = 1` (the two-step start).
- Regime shares below were computed by simulation ($2 \times 10^6$ draws)
  on 23 November 2026.

### 8.2 Designs

| Id | Model | Selection design and parameters | Dependence | Regime shares |
| --- | --- | --- | --- | --- |
| H | Heckman | $z = (1, x_1, z_1)$, $\gamma = (0.5, 0.3, -0.4)$ (G1 base); $\beta = (1.5, 0.8, 0.4)$, $\sigma = 1$ | $\rho \in \{0, 0.6\}$ | observed 0.673 |
| T | Treatment, constant shift | as H; $\beta = (1.0, 0.5, 0.2)$, $\delta = 0.5$, $\sigma = 1$ | $\rho \in \{0, 0.6\}$ | treated 0.673 |
| Th | Treatment, hybrid | as T with $d = (1, x_1)$, $\delta = (0.5, 0.3)$ | $\rho = 0.6$ | 0.673 |
| L | MNL with Lee, $J = 3$ | $z = (1, x_1, z_1, z_2)$; $\gamma_2 = (0.2, 0.3, 0.8, -0.2)$, $\gamma_3 = (-0.2, -0.3, 0.2, 0.8)$; base 1 | $\rho = (0.5, 0.4, -0.4)$ or $(0, 0, 0)$ | 0.307, 0.402, 0.291 |
| D | MNL, linear Gumbel dependence (Dubin-McFadden data-generating process) | as L | $r_1 = (0.4, -0.2, -0.2)$, $r_2 = (-0.3, 0.5, -0.2)$, $r_3 = (0.1, -0.4, 0.3)$ (rows sum to 0) | as L |
| P | MNP, $J = 3$ | $\gamma$ as L; $\Omega = \tfrac12(I + \mathbf 1\mathbf 1')$ | $\psi_1 = (-0.4, -0.2)$, $\psi_2 = (0.5, 0.2)$, $\psi_3 = (0.1, 0.5)$ | 0.283, 0.437, 0.281 |
| Pu | MNP, unrestricted truth | as P with $\operatorname{sd}(\tilde u_2) = 1.3$, $\operatorname{Corr}(\tilde u_1, \tilde u_2) = 0.2$ | as P | not computed |
| O | Ordered, $J = 3$ | $z = (1, x_1, z_1)$, $\gamma = (0.4, 0.3, 0.8)$, $\mu_2 = 1.2$ | $\rho = (0.5, 0.4, -0.4)$ or $(0, 0, 0)$ | 0.381, 0.348, 0.271 |
| S | Sequential, $J = 3$ | stage 1: $(1, x_1, z_1)$, $(0.6, 0.3, 0.8)$; stage 2: $(1, x_1, z_2)$, $(0.2, -0.3, 0.8)$; independent stages | $\rho_1 = 0.5$; $\rho_2 = (0.3, -0.4)$; $\rho_3 = (0.3, 0.5)$ | 0.325, 0.304, 0.371 |
| V | Multivariate, $M = 2$, four regimes | eq. 1: $(1, x_1, z_1)$, $(0.3, 0.3, 0.8)$; eq. 2: $(1, x_1, z_2)$, $(-0.2, -0.3, 0.8)$; $\operatorname{Corr}(u_1, u_2) = 0.4$; $\beta_{00} = (1, 0.5, 0.2)$, $\beta_{10} = (1.5, 0.8, 0.4)$, $\beta_{01} = (1.2, 0.3, 0.1)$, $\beta_{11} = (2, 0.6, 0.3)$; $\sigma = 1$ | $\psi_{00} = (0.3, 0.2)$, $\psi_{10} = (0.5, -0.2)$, $\psi_{01} = (-0.3, 0.4)$, $\psi_{11} = (0.4, 0.4)$ | 0.257, 0.303, 0.153, 0.287 |
| K | Binary selection, $K = 2$ outcomes per regime | G1 base; second outcome with $\beta$ of the first reversed in sign, $\sigma = 1$, within-regime correlation 0.3 | outcome 1: $\rho_1 = 0.6$, $\rho_0 = 0.4$ (G1 base); outcome 2: correlation with $u$ of 0.3 in regime 1 and $-0.3$ in regime 0 | 0.673 in regime 1 |
| N | Nested logit with Lee, nests $\{1\}$, $\{2, 3\}$ | $\gamma$ as L; $\lambda = 0.6$ | $\rho = (0.5, 0.4, -0.4)$ | 0.347, 0.394, 0.259 |
| Lw, Pw | Weak identification: L and P with the coefficients of $z_1$, $z_2$ multiplied by 0.25 | | as L, P | not computed |

In design D, $\varepsilon_j = \sigma_j\left[\frac{\sqrt6}{\pi}\sum_kr_{jk}(u_k - \gamma_E) + \sqrt{1 - \sum_kr_{jk}^2}\,\nu_j\right]$.

### 8.3 Cells and estimators

| Design | $N$ | $R$ | Estimators | Gated cells |
| --- | --- | --- | --- | --- |
| H | 500, 1000, 2000, 5000 $\times$ 2 values of $\rho$ | 1000 | FIML, two-step | FIML, $N \ge 1000$; two-step coverage at $N \ge 2000$ |
| T | 500, 1000, 2000, 5000 $\times$ 2 | 1000 | FIML, two-step | as H |
| Th | 1000, 5000 | 500 | FIML, two-step | none (reported) |
| L | 1000, 2000, 5000 $\times$ 2 | 1000 | FIML; two-step `"lee"`; `"dmf"`, `"bfg1"`, `"bfg2"` (point estimates of $\beta$) | FIML, $N \ge 2000$; Lee two-step coverage at $N = 5000$ |
| D | 2000, 5000 | 500 | `"dmf"`, `"bfg1"`, `"bfg2"`, `"lee"` two-step; bootstrap (199 replicates) and stacked-sandwich standard errors at $N = 2000$ | bias of $\beta$ and $a_{jk}$ for `"dmf"` and `"bfg1"` at $N = 5000$ |
| P | 1000, 2000, 5000 | 1000 at $N \ge 2000$, 500 at 1000 | FIML `"independent"`; two-step | FIML `"independent"`, $N \ge 2000$ |
| P | 2000, 5000 | 500 | FIML `"unrestricted"` | none (reported) |
| Pu | 5000 | 300 | FIML `"unrestricted"` and `"independent"` (misspecified) | none (reported) |
| O | 1000, 2000, 5000 $\times$ 2 | 1000 | FIML, two-step | FIML, $N \ge 2000$; two-step coverage at $N = 5000$ |
| S | 2000, 5000 | 1000 at 5000, 500 at 2000 | FIML `"independent"`; `"unrestricted"` at 5000 ($R = 300$, reported) | FIML `"independent"`, $N = 5000$ |
| V | 2000, 5000 | 1000 at 5000, 500 at 2000 | FIML, two-step | FIML, $N = 5000$ |
| K | 2000 | 1000 | FIML | FIML |
| N | 2000, 5000 | 500 | FIML | $\beta_j$, $\sigma_j$ and $ATE_{jk}$ at $N = 5000$ (bias and convergence only) |
| Lw, Pw | 2000 | 500 | FIML | none (reported, with the identification diagnostics) |

About 34 000 replications. The region-model cells are the expensive ones;
all runs use at most 3 cores (handoff section 4).

### 8.4 Pre-registered thresholds (gated cells)

| Criterion | Threshold |
| --- | --- |
| Relative bias of selection coefficients, thresholds, $\beta$, $\delta$, $\sigma$ ($\lvert\theta_0\rvert \ge 0.2$) | $\le 5\%$ ($\lvert\text{bias}\rvert \le 0.01$ otherwise) |
| Bias of dependence parameters with one per regime ($\rho$, $\rho_j$: H, T, L, O, K) | $\le 0.03$ in absolute value |
| Bias of dependence parameters of region models with $d = 2$ ($\psi_{jm}$, selection correlation: P, S, V) | $\le 0.05$ in absolute value |
| Root-$N$ behaviour, where two gated sample sizes exist | $\sqrt{N_2}\,\text{RMSE}_{N_2}/\sqrt{N_1}\,\text{RMSE}_{N_1} \in [0.8, 1.2]$ for the smallest and largest gated $N$ |
| Standard-error ratio (default covariance) | $\in [0.90, 1.10]$ |
| 95% coverage (G2 acceptance criterion 4) | $\in [0.93, 0.97]$ |
| Convergence rate | $\ge 99\%$ (H, T, L, O, K); $\ge 97\%$ (P, S, V, N) |
| $ATE_{jk}$, $ATT_{jk}$, all pairs | relative bias $\le 5\%$ when $\lvert\text{effect}\rvert \ge 0.2$, $\lvert\text{bias}\rvert \le 0.02$ otherwise; coverage $\in [0.93, 0.97]$ |
| Two-step, where gated | coverage of $\beta$ and of the correction coefficients $\in [0.93, 0.97]$ |
| Design D | relative bias of $\beta$ $\le 5\%$; $\lvert\text{bias}\rvert$ of $a_{jk}$ $\le 0.03$ |

Coverage is gated only in cells with $R = 1000$ (Monte Carlo standard error
0.0069), as in G1.

**Reported but not gated**, with an honest discussion required in
`MC_G2.md`: every cell not listed as gated in section 8.3; the sandwich
standard errors; the unrestricted covariance structures; the nested-logit
$\gamma$, $\lambda$ and $\rho$; the weak-identification cells; the
Dubin-McFadden and BFG corrections applied to design L (where their
linearity assumption does not hold) and Lee's correction applied to design
D; computing times.

Failing a gated threshold blocks G2 acceptance criteria 1 and 4 until the
cause is understood and, if it is a defect, fixed. The threshold is not
changed. A diagnosis that finds no defect goes to the owner, as in WP1.7.

### 8.5 Execution

- **Driver:** `04_Validation/scripts/mc_g2.R`, modelled on `mc_g1.R`; gate
  evaluation by `mc_g2_report.R` with the thresholds of section 8.4 written
  into the script.
- **Random numbers:** L'Ecuyer-CMRG streams, master seed 20261123, one
  stream per cell, substream per replication.
- **Storage:** `runs/mc_g2_<version>_<mode>/`; private library
  `runs/lib_g2`; summaries in `04_Validation/results/MC_G2.md`.
- **Timing.** Each design is run in the work package that delivers its
  model (H, T, Th: WP2.1; L, D, Lw: WP2.2; P, Pu, Pw: WP2.3; O, S, N:
  WP2.4; V, K: WP2.5), so that problems surface early. All cells are rerun
  with the release candidate in WP2.5, and the gate is evaluated on that
  rerun.
- **Smoke test** ($R = 20$, one cell per delivered design at its smallest
  $N$): at every version from the design's work package on, compared with
  the previous version by `tools/compare_mc_runs.R`.
- The G1 smoke regression (`runs/mc_g1_0.8.1_smoke`) keeps running at every
  G2 version.

### 8.6 Cells added at the gate closing (23 November 2026)

Reason: the owner's amendments to gate questions 3 (a less restrictive
alternative to Lee) and 9 (the framework must handle at least 8 regimes).
The thresholds are those of section 8.4; nothing above is changed. The
owner has not reviewed these additions cell by cell; they are reported to
the owner with the gate-closing note.

| Id | Model | Design | Dependence | Regime shares (simulated, $2 \times 10^6$ draws) |
| --- | --- | --- | --- | --- |
| G | Normal-score multinomial logit, $J = 3$ (MULTINOMIAL_ESR.md section 11) | selection as L | $r_1 = (0.4, -0.2, -0.2)$, $r_2 = (-0.3, 0.5, -0.2)$, $r_3 = (0.1, -0.4, 0.3)$ | as L |
| L8 | MNL with Lee, $J = 8$ | $z = (1, x_1, z_1, z_2)$; $\gamma_2, \dots, \gamma_8$ = $(0.2, 0.3, 0.8, -0.2)$, $(-0.2, -0.3, 0.2, 0.8)$, $(0.1, 0.2, -0.6, 0.4)$, $(0, -0.2, 0.5, 0.5)$, $(-0.1, 0.4, -0.4, -0.6)$, $(0.1, -0.1, 0.9, 0.3)$, $(-0.1, 0.1, -0.3, 0.9)$; $\beta_j = (1 + 0.25(j-1),\ 0.5,\ 0.2)$, $\sigma_j = 1$ | $\rho = (0.5, 0.4, -0.4, 0.3, -0.3, 0.5, 0.2, -0.5)$ | 0.102, 0.157, 0.098, 0.139, 0.111, 0.138, 0.138, 0.117 |
| O8 | Ordered, $J = 8$ | $z = (1, x_1, z_1)$, $\gamma = (1.3, 0.3, 0.8)$, $\mu = (0, 0.5, 0.9, 1.4, 1.8, 2.3, 2.9)$; $\beta_j$, $\sigma_j$ as L8 | $\rho$ as L8 | 0.162, 0.111, 0.109, 0.150, 0.117, 0.128, 0.111, 0.112 |
| P8 | MNP, $J = 8$ (GHK, 7 dimensions) | $\gamma$ as L8; $\Omega = \tfrac12(I + \mathbf 1\mathbf 1')$; $\beta_j$, $\sigma_j$ as L8 | each regime correlated with its own utility difference only (base regime: with the first difference), correlation $0.8\rho_j$ with $\rho$ of L8 | 0.067, 0.187, 0.078, 0.154, 0.088, 0.160, 0.149, 0.116 |

| Design | $N$ | $R$ | Estimators | Gated cells |
| --- | --- | --- | --- | --- |
| G | 2000, 5000 | 500 | FIML normal-score; two-step `"bfg2"`; FIML Lee (misspecified, reported) | FIML normal-score at $N = 5000$: bias and convergence ($\ge 97\%$); bias threshold for $r_{jk}$: 0.05, as for the dependence parameters of the two-dimensional region models. Coverage reported ($R = 500$) |
| L | 5000 | 300 | FIML normal-score on Lee data (misspecified) | none (reported) |
| L8 | 4000, 8000 | 500 | FIML Lee; two-step `"lee"` | FIML at $N = 8000$: bias and convergence ($\ge 99\%$). Coverage reported |
| O8 | 4000, 8000 | 500 | FIML; two-step | FIML at $N = 8000$: bias and convergence ($\ge 99\%$). Coverage reported |
| P8 | 8000 | 100 | FIML `"independent"` with GHK (500 and 2000 Halton draws) | none: reported, with computing time. If a fit exceeds 2 hours on one core the cell is reported as not completed |

About 3000 further replications. Designs G, L8: WP2.2; P8: WP2.3; O8:
WP2.4.
