# Identification architecture

Status: draft for the G1 econometric gate (WP1.1, 22 November 2026).
Specification sections 3.5 and 15. Implemented by `switch_validate()`
(WP1.5). Check V12 in [verify_math.R](verify_math.R).

## 1. What is identified in the binary Gaussian ESR

| Parameter group | Identified by | Classification (spec section 3.5) |
| --- | --- | --- |
| $\gamma$ | the probit for $S$, with the normalisation $\operatorname{Var}(u) = 1$ (A4) and the rank of $z$ (A6) | Structurally identified |
| $\beta_j$, $\sigma_j$ | regime-$j$ data, given the rank of $x_j$ within regime $j$ (A6) and $\rho_j$ | Structurally identified |
| $\rho_j$ (and the intercept of $\beta_j$ jointly with it) | variation in $m_j(w)$ not explained by $x_j$. A credible **exclusion restriction** (A7) supplies it; without one it comes only from the non-linearity of $m_j$ under normality. | By exclusion restriction if present and strong; otherwise **distributional / functional-form identification only** |
| $\sigma_{10}$, i.e. $\operatorname{Corr}(\varepsilon_1, \varepsilon_0)$ | nothing: it does not enter the likelihood | **Not identified** (section 3) |

## 2. Exclusion restrictions and functional form

Let $E_j$ be the variables in $z$ that are excluded from $x_j$ (excluded
instruments for regime $j$). Three situations arise.

1. **$E_j$ non-empty with jointly significant, sizeable coefficients.** $\rho_j$
   is identified by the exclusion restriction (given its validity, which no
   data test can prove).
2. **$E_j$ non-empty but weak.** $m_j(\hat w)$ is close to collinear with $x_j$.
   Estimates of $\rho_j$ and the regime-$j$ intercept are unstable, with large
   standard errors and possible multistart disagreement.
3. **$E_j$ empty** ($z \subseteq$ span of $x_j$). Identification rests entirely
   on the non-linearity of $m_j$ under normality. The specification (section
   3.5) requires a warning:

   > Identification of rho_j depends entirely on the nonlinear functional form
   > of the normal distribution: no variable in the selection equation is
   > excluded from the regime-j outcome equation.

## 3. The across-regime correlation is not identified (plan decision D8)

$y_{1i}$ and $y_{0i}$ are never observed together. The joint density of
$(S_i, y_i)$ therefore depends only on the bivariate distributions of
$(u, \varepsilon_1)$ and $(u, \varepsilon_0)$ (V12a: $P(S = 1, Y \le y)$ is
the same for every admissible $\operatorname{Corr}(\varepsilon_1, \varepsilon_0)$).
This is the classical result discussed by Koop and Poirier (1997) and Poirier
and Tobias (2003).

**Admissible range.** Positive definiteness of the correlation matrix of
$(u, \varepsilon_1, \varepsilon_0)$ requires

$$r_{10} = \operatorname{Corr}(\varepsilon_1, \varepsilon_0) \in \left[\rho_1\rho_0 - \sqrt{(1-\rho_1^2)(1-\rho_0^2)},\;\rho_1\rho_0 + \sqrt{(1-\rho_1^2)(1-\rho_0^2)}\right],$$

with zero determinant at the end points (V12b). The value
$r_{10} = \rho_1\rho_0$ (zero partial correlation given $u$) is always
admissible, so the parameter space for $(\rho_1, \rho_0)$ is all of
$(-1, 1)^2$.

**Consequences for the software.**
- $\sigma_{10}$ is never estimated or reported as an estimate.
- Quantities that depend on it are given either as bounds over the admissible
  range or under an explicitly stated assumption (default: $r_{10} = \rho_1\rho_0$),
  never as point estimates presented as identified. Examples are the
  distribution of individual gains $Y_1 - Y_0$ (for instance
  $\operatorname{Var}(Y_1 - Y_0) = \sigma_1^2 + \sigma_0^2 - 2r_{10}\sigma_1\sigma_0$)
  and counterfactual expectations conditional on the observed outcome.
- Averages of conditional means (ATT, ATU, ATE, TH, BH) do not depend on
  $r_{10}$ and are point-identified.
- Simulation of observed data (`switch_simulate()`, `simulate()`) does not
  depend on $r_{10}$. Simulation of both potential outcomes does, and uses
  the stated assumption.

## 4. Diagnostics produced by `switch_validate()` (WP1.5)

`switch_validate()` accepts a specification with data (before fitting) or a
fitted model. It returns a `switch_validation` object with one row per
diagnostic and a status (`ok`, `note`, `warning`, `error`).

| Code | Diagnostic | Rule | Status if violated |
| --- | --- | --- | --- |
| I1 | Rank of $z$, of $x_1$ in regime 1, of $x_0$ in regime 0 | QR rank = number of columns | error |
| I2 | Regime sizes | $n_j > k_j + 2$ for both regimes; $\min(n_1, n_0)/n \ge 0.02$ | error / warning |
| I3 | Separation in the selection equation | probit fitted probabilities not within $10^{-10}$ of 0 or 1 for any observation; finite coefficients | warning |
| I4 | Excluded variables per regime | list of $E_1$ and $E_0$; empty set triggers the section 2 warning | warning |
| I5 | Strength of excluded variables | Wald $\chi^2$ of $E_j$ in the probit, its p-value and $\chi^2/\text{df}$. Heuristic flag if $\chi^2/\text{df} < 10$ (by analogy with the first-stage F rule of thumb; labelled as a heuristic) | note / warning |
| I6 | Collinearity of the generated regressor | $R^2$ of $m_j(\hat w)$ on $x_j$ within regime $j$; warning if $R^2 > 0.95$; condition number of $(x_j, m_j)$ | warning |
| I7 | Range of the selection index | share of $\hat w_i$ with $\lvert\hat w_i\rvert > 3$; a narrow range weakens functional-form identification | note |
| I8 | Boundary and conditioning (fitted models) | flags of [PARAMETERIZATION.md](PARAMETERIZATION.md) section 5 | warning |
| I9 | Multistart agreement (fitted models) | converged starts within $10^{-6}$ in log-likelihood must agree within $10^{-3}$ in parameters | warning |
| I10 | Falsification test of the exclusion restriction (Di Falco, Veronesi and Yesuf 2011) | among regime-0 units, the excluded variables should not be jointly significant in the outcome regression. Reported as an informal check; it cannot validate the restriction. | note |
| I11 | Non-identified parameters | always lists $\operatorname{Corr}(\varepsilon_1, \varepsilon_0)$ with its explanation | note |

Panel and spatial identification (specification section 3.5, items 5 and 6)
are added in Generations 5 and 6.

## 5. Monte Carlo evidence

The WP1.7 study ([04_Validation/MONTE_CARLO_DESIGN.md](../04_Validation/MONTE_CARLO_DESIGN.md))
includes strong, moderate, weak and no-exclusion cells. They show how these
diagnostics relate to bias, coverage and convergence, so the thresholds above
can be revisited on evidence before v1.0.0.
