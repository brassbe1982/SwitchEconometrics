# Binary endogenous switching regression (Generation 1)

Status: draft for the G1 econometric gate (WP1.1, 22 November 2026).
Companion documents: [LIKELIHOOD_DERIVATION.md](LIKELIHOOD_DERIVATION.md),
[IDENTIFICATION.md](IDENTIFICATION.md), [PARAMETERIZATION.md](PARAMETERIZATION.md),
[TREATMENT_EFFECTS.md](TREATMENT_EFFECTS.md). Every formula is checked
numerically by [verify_math.R](verify_math.R).

This is Family A of the specification (section 4) and the first restricted
instance of the Generalized Endogenous Switching System
([GENERAL_MODEL.md](GENERAL_MODEL.md)).

## 1. Model

For units $i = 1, \dots, N$:

**Selection equation**

$$S_i^* = z_i'\gamma + u_i, \qquad S_i = \mathbf 1\{S_i^* > 0\}.$$

**Regime-specific outcome equations**

$$y_{1i} = x_{1i}'\beta_1 + \varepsilon_{1i} \quad (\text{regime } 1, S_i = 1), \qquad
  y_{0i} = x_{0i}'\beta_0 + \varepsilon_{0i} \quad (\text{regime } 0, S_i = 0).$$

**Observation mechanism ("switching")**

$$y_i = S_i\, y_{1i} + (1 - S_i)\, y_{0i}.$$

For every unit we observe $(S_i, y_i, z_i, x_{1i}, x_{0i})$. Exactly one
potential outcome is observed. Both regressor vectors are observed for every
unit, which is what makes counterfactual predictions possible.

Dimensions: $z_i \in \mathbb R^{k_z}$, $x_{1i} \in \mathbb R^{k_1}$,
$x_{0i} \in \mathbb R^{k_0}$. The regressor sets may differ between the two
outcome equations.

## 2. Assumptions

| Label | Assumption |
| --- | --- |
| A1 | **Random sampling.** $(S_i, y_i, z_i, x_{1i}, x_{0i})$ are independent and identically distributed across $i$. |
| A2 | **Exogenous regressors.** $(u_i, \varepsilon_{1i}, \varepsilon_{0i})$ is independent of $(z_i, x_{1i}, x_{0i})$. |
| A3 | **Trivariate normality.** $(u_i, \varepsilon_{1i}, \varepsilon_{0i})' \sim N(0, \Sigma)$ with $\Sigma = \begin{pmatrix} 1 & \rho_1\sigma_1 & \rho_0\sigma_0 \\ \rho_1\sigma_1 & \sigma_1^2 & \sigma_{10} \\ \rho_0\sigma_0 & \sigma_{10} & \sigma_0^2 \end{pmatrix}$. |
| A4 | **Scale normalisation.** $\operatorname{Var}(u_i) = 1$. The scale of $\gamma$ is not identified otherwise. |
| A5 | **Interior parameters.** $\sigma_1, \sigma_0 > 0$ and $\lvert\rho_1\rvert, \lvert\rho_0\rvert < 1$. |
| A6 | **Rank and support.** $E[z_i z_i']$ is non-singular; $E[x_{ji}x_{ji}' \mid S_i = j]$ is non-singular for $j = 0, 1$; $0 < P(S_i = 1 \mid z_i) < 1$ on a set of positive probability. In the sample: no perfect separation in the selection equation, and each regime has more observations than outcome parameters. |
| A7 | **Exclusion restriction (recommended, not required).** $z_i$ contains at least one variable with a non-zero coefficient that is excluded from $x_{1i}$ and $x_{0i}$. Without it, $\rho_1$ and $\rho_0$ are identified only through the normality assumption ([IDENTIFICATION.md](IDENTIFICATION.md)). |
| A8 | **Weights (optional).** Known positive sampling weights $\omega_i$ give a weighted pseudo-likelihood. Inference then uses the sandwich covariance. |

$\sigma_{10} = \operatorname{Cov}(\varepsilon_{1i}, \varepsilon_{0i})$ never
enters the likelihood, because $y_{1i}$ and $y_{0i}$ are never observed
together. It is not identified and is not a model parameter (plan decision D8,
[IDENTIFICATION.md](IDENTIFICATION.md) section 3). A3 only requires that some
admissible $\sigma_{10}$ exists. For any $\rho_1, \rho_0 \in (-1, 1)$ one does,
for example $\sigma_{10} = \rho_1\rho_0\sigma_1\sigma_0$.

## 3. Sign convention (plan decision D6)

- $S_i = 1$ if and only if $z_i'\gamma + u_i > 0$, with $u_i \sim N(0, 1)$.
- $\rho_j = \operatorname{Corr}(u_i, \varepsilon_{ji})$ for both regimes.
- A positive $\rho_j$ means that unobservables raising the propensity to be in
  regime 1 also raise the outcome in regime $j$.

Every expression in the G1 documents is derived from this single convention.
Benchmarks against other software convert explicitly (section 6).

## 4. Parameters

Natural parameter vector, of dimension $p = k_z + k_1 + k_0 + 4$:

$$\theta = (\gamma', \beta_1', \beta_0', \sigma_1, \sigma_0, \rho_1, \rho_0)'.$$

Optimisation uses the unconstrained working parameters
$\vartheta = (\gamma', \beta_1', \beta_0', \tau_1, \tau_0, \alpha_1, \alpha_0)'$
with $\sigma_j = e^{\tau_j}$ and $\rho_j = \tanh\alpha_j$
([PARAMETERIZATION.md](PARAMETERIZATION.md)).

Parameter names in the software (regime labels default to `regime_0` and
`regime_1`, or come from the names of the `outcomes` list):

| Natural | Software name | Working name |
| --- | --- | --- |
| $\gamma_k$ | `selection:<term>` | same |
| $\beta_{1k}$ | `regime_1:<term>` | same |
| $\beta_{0k}$ | `regime_0:<term>` | same |
| $\sigma_1$, $\sigma_0$ | `regime_1:sigma`, `regime_0:sigma` | `regime_1:log(sigma)`, ... |
| $\rho_1$, $\rho_0$ | `regime_1:rho`, `regime_0:rho` | `regime_1:atanh(rho)`, ... |

## 5. Special and nested cases

| Restriction | Resulting model | Use in G1 |
| --- | --- | --- |
| $\rho_1 = \rho_0 = 0$ | Exogenous switching. The likelihood factorises into a probit plus two Gaussian regressions (checked numerically, V19). | Restricted model of the likelihood-ratio test of selection on unobservables. |
| $x_1 = x_0 = x$; $\beta_1$ and $\beta_0$ equal except the intercept; $\sigma_1 = \sigma_0$; $\rho_1 = \rho_0$ | Endogenous treatment model with a common outcome equation and an intercept shift (Maddala 1983). Under these restrictions the switching likelihood equals the treatment likelihood exactly, because $\sigma_{10}$ does not enter. | Basis of `treatment()` in G2 (WP2.1, plan decision D7). |
| $y_i$ observed only when $S_i = 1$ | Heckman (1979) sample selection (Tobit-2). This is a different observation mechanism, not a parameter restriction. | `heckman()` in G2 (WP2.1). |
| Gaussian copula with Gaussian margins, $J = 2$ | The GESS restricted as in specification section 10.2. | Nesting test of G3 (WP3.3). |

## 6. Relation to existing R implementations

Cross-software comparisons use R implementations only (plan decision D11, as
amended by the owner on 22 November 2026).

**`sampleSelection` 1.2-16, Tobit-5.** Verified by simulation on 22
November 2026: n = 20 000, true $\rho_1 = 0.6$ and $\rho_0 = 0.4$; ML estimates
`rho2` = 0.574 and `rho1` = 0.380. Check V17 also shows that our
log-likelihood at `sampleSelection`'s estimates equals its reported value.
The mapping is:

| `sampleSelection::selection(S ~ z, list(y ~ x0, y ~ x1))` | SwitchEconometrics |
| --- | --- |
| selection equation `S:` | $\gamma$ |
| first outcome equation (`O1`), `sigma1`, `rho1` | regime 0: $\beta_0$, $\sigma_0$, $\rho_0$ (same sign) |
| second outcome equation (`O2`), `sigma2`, `rho2` | regime 1: $\beta_1$, $\sigma_1$, $\rho_1$ (same sign) |
| two-step `invMillsRatio1` (regressor $\phi/(1-\Phi)$) | $-\sigma_0\rho_0$ (our regressor $m_0 = -\phi/(1-\Phi)$) |
| two-step `invMillsRatio2` (regressor $\phi/\Phi$) | $\sigma_1\rho_1$ |

**`endoSwitch` 1.0.0 (archived from CRAN).** The mapping was established
in WP1.8 (22 November 2026): on six datasets, the log-likelihoods at the
common optimum agree to 1.1e-13 and the estimates to 4.4e-8
([BENCHMARK_G1.md](../04_Validation/results/BENCHMARK_G1.md)). Its
log-likelihood is the Lokshin-Sajaia form with the same signs as ours.

| `endoSwitch(data, OutcomeDep, SelectDep, OutcomeCov, SelectCov)` | SwitchEconometrics |
| --- | --- |
| `Select.<var>`, then `Select.Const` (constant last) | $\gamma$ (intercept first) |
| `Outcome.0.<var>`, `Outcome.0.Const` | regime 0 ($S = 0$): $\beta_0$ |
| `Outcome.1.<var>`, `Outcome.1.Const` | regime 1 ($S = 1$): $\beta_1$ |
| `Outcome.0.SigmaX`, `Outcome.1.SigmaX` | $\log\sigma_0$, $\log\sigma_1$ (our working scale) |
| `Outcome.0.RhoX`, `Outcome.1.RhoX` | $\operatorname{atanh}\rho_0$, $\operatorname{atanh}\rho_1$ (same sign) |
| `distPar` | $\sigma_0, \sigma_1, \rho_0, \rho_1$ with delta-method standard errors |
| `treatEffect`: ATT, ATU, "Heterogeneity" row | ATT, ATU; BH1, BH0 and TH (same definitions; rounded to 4 decimals) |
| `endoSwitch2Stage`: coefficient of `MillsRatioAdt1` ($\phi/\Phi$) | $\sigma_1\rho_1$ |
| `endoSwitch2Stage`: coefficient of `MillsRatioAdt0` ($\phi/(1-\Phi)$) | $-\sigma_0\rho_0$ |

**Restrictions of its interface:**
- The same outcome regressors (`OutcomeCov`) in both regimes.
- Selection regressors that differ from them.
- Numeric columns only.

**Lokshin and Sajaia (2004).** Their log-likelihood (their eq. 4) has the same
form: $\ln\Phi(\eta_{1i})$ for regime 1 and $\ln\{1 - \Phi(\eta_{2i})\}$ for
regime 2, with $\eta_{ji} = (\gamma Z_i + \rho_j\varepsilon_{ji}/\sigma_j)/\sqrt{1-\rho_j^2}$.
This coincides with section 2 of [LIKELIHOOD_DERIVATION.md](LIKELIHOOD_DERIVATION.md)
when their regime 2 is our regime 0. Their paper is cited as the
methodological reference for FIML estimation. The SwitchEconometrics
conditional expectations are derived independently from the convention of
section 3 ([TREATMENT_EFFECTS.md](TREATMENT_EFFECTS.md)) and verified
numerically (V07, V16).
