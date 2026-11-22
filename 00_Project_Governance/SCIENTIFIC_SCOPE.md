# Scientific scope

Adopted 22 November 2026 (WP1.1). Specification sections 1-4.

## 1. Problem addressed

The package addresses endogenous regime selection: units select into mutually
exclusive regimes partly on unobservables that also affect regime-specific
outcomes. The same machinery covers non-random observation (sample selection)
and endogenous treatment.

It is **not** a general solution to endogeneity (research review section 2).
Simultaneity, measurement error and dynamic endogeneity of regressors are
outside its scope, unless they arise through the regime-selection mechanism
modelled here.

## 2. Scope by generation

| Family (spec section 4) | In scope | Explicitly not claimed |
| --- | --- | --- |
| A, G1 | binary probit selection; two Gaussian continuous outcomes; FIML and two-step; Hessian, sandwich, cluster and bootstrap inference; ATT, ATU, ATE, TH, BH; counterfactuals and policy scenarios; identification diagnostics | point estimates of $\operatorname{Corr}(\varepsilon_1, \varepsilon_0)$ or of distributional gains (bounds or stated assumptions only) |
| B, G2 | MNL and MNP selection (kept distinct), ordered, sequential and multivariate selection; $J \ge 3$; several outcomes per regime; Heckman and treatment observation mechanisms; pairwise effects | nested logit where its consistency conditions fail |
| C, G3 | Gaussian, Student-t, Archimedean (Clayton, Gumbel, Frank, Joe), BB1/6/7/8 copulas on identified pairs; vines; flexible continuous margins; dependence diagnostics and sensitivity analysis | that a flexible copula "solves" endogeneity; it changes the identifying assumptions (spec section 15) |
| D, G4 | binary, count, ordinal, censored, fractional and duration outcomes; selection for all types; joint mixed outcomes; robust estimating equations; advanced bootstrap | |
| E, G5 | random and correlated random effects; dynamic selection with initial-conditions treatment; unbalanced panels; temporal dependence | fixed-effects switching (incidental parameters), unless a valid estimator is derived at the G5 gate |
| F, G6 | hierarchical, spatial-outcome and spatial-selection models; Bayesian engine; sustainability indicators | non-parametric and semiparametric dependence (spec section 4C: research extension, not scheduled) |

## 3. Scientific standards

- Every estimator is derived in a document before it is coded, and every
  formula is verified numerically.
- Every model is validated by Monte Carlo before being labelled stable
  (spec section 9).
- Cross-software validation uses R implementations only (owner decision of 22
  November 2026): `sampleSelection`, `endoSwitch` (archived), `switchSelection`,
  `GJRM`, `ssmrob`, `endogenous`.
- Identification assumptions are reported with every fit (spec section 3.5).
