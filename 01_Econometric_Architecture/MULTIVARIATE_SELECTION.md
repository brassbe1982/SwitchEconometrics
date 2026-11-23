# Multivariate selection and several outcomes per regime (Generation 2, WP2.5)

Status: **draft for the G2 econometric gate** (23 November 2026). No code
exists for these models yet. Specification sections 4 (Family B), 10.1
(`multiswitch()`) and 13. Checks W35 and W36 in
[verify_math_g2.R](verify_math_g2.R). Both extensions are instances of
[GAUSSIAN_REGION_ENGINE.md](GAUSSIAN_REGION_ENGINE.md).

## 1. Multivariate selection: model

$M$ binary selection equations, all observed for every unit (for example
digital adoption and export status):

$$S^{(m)}_i = \mathbf 1\{z_{mi}'\gamma_m + u_{mi} > 0\}, \quad m = 1, \dots, M, \qquad (u_{1i}, \dots, u_{Mi})' \sim N(0, R_u),$$

with $R_u$ a correlation matrix (a multivariate probit; unit variances).

**Regimes.** Each observed combination $s = (s^{(1)}, \dots, s^{(M)})$ is a
regime: up to $2^M$ regimes, labelled by the combination (for example
`adopt=1.export=0`). A regime may have an outcome equation,

$$y_{si} = x_{si}'\beta_s + \varepsilon_{si} \quad \text{observed iff } S_i = s, \qquad \operatorname{Corr}(u, \varepsilon_s) = \psi_s \in \mathbb R^M,$$

or none. A regime without an outcome equation contributes its probability
only: the outcome is not observed there (the selection mechanism of
[OBSERVATION_MECHANISMS.md](OBSERVATION_MECHANISMS.md) section 2). With
$M = 1$ and both regimes having outcomes this is G1; with $M = 1$ and one
outcome it is the Heckman model.

**Sign convention (D6).** $\psi_{s,m} = \operatorname{Corr}(u_m, \varepsilon_s)$:
the correlation with the propensity for $S^{(m)} = 1$, in every regime.

## 2. Likelihood (check W35a)

Engine instance with $d = M$, $A_s = I$, limits $(0, \infty)$ where
$s^{(m)} = 1$ and $(-\infty, 0]$ where $s^{(m)} = 0$:

$$L_{si} = \frac{1}{\sigma_s}\phi(e_{si})\;\Pr\!\left(\text{sign pattern } s \mid \varepsilon_{si}\right), \qquad u \mid e \sim N\!\left(\psi_s e,\; R_u - \psi_s\psi_s'\right),$$

and $L_{si} = \Pr(\text{sign pattern } s)$ for a regime without an outcome.
W35a: for $M = 2$, $\int_{-\infty}^yL_s$ equals the trivariate normal
probability of $\{S = s, Y_s \le y\}$ (difference 0 to machine precision).

## 3. Parameters, estimation, identification (check W35b)

- **Parameters.** $\gamma_m$ per equation; $M(M-1)/2$ correlations in
  $R_u$; per regime with an outcome: $\beta_s$, $\sigma_s$, $\psi_s$ ($M$
  correlations). Parameterised as in the engine (section 3 there).
- **Estimation.** FIML by the engine (W35b: score equal to the numerical
  gradient to 9e-10); two-step by its section 7 (multivariate probit first
  step, $M$ correction terms per regime).
- **Probabilities.** Deterministic for $M \le 3$; GHK beyond (engine
  section 8).
- **Identification.** $R_u$ is identified from the joint distribution of the
  observed indicators (structural, given the multivariate probit). $\psi_s$
  needs, per regime, variation of the $M$ correction terms not explained by
  $x_s$: the rank condition of
  [MULTINOMIAL_ESR.md](MULTINOMIAL_ESR.md) section 8, item 2, with $M$ in
  place of $J - 1$. Regimes with few observations are reported by I2.
  Cross-regime outcome correlations are not identified (engine section 11).
- **Proposed limit for G2:** $M \le 3$ by the deterministic route is the
  validated case; $M \ge 4$ runs through GHK and is experimental.

Sequential selection ([ORDERED_SEQUENTIAL.md](ORDERED_SEQUENTIAL.md)
section 2) is the same system in which later equations are observed only
for units that passed the earlier ones.

## 4. Several Gaussian outcomes per regime (check W36)

Regime $j$ of any Gaussian-region model (and of G1) may have $K_j \ge 1$
outcome equations, all observed in that regime:

$$y_{jki} = x_{jki}'\beta_{jk} + \varepsilon_{jki}, \quad k = 1, \dots, K_j, \qquad \varepsilon_{ji} \sim N_{K_j}(0, \Sigma^\varepsilon_j), \qquad C_j = \operatorname{Cov}(\tilde u, \varepsilon_j).$$

**Likelihood.**

$$L_{ji} = \phi_{K_j}\!\left(\varepsilon_{ji}; \Sigma^\varepsilon_j\right)\;\Pr\!\left(l_j < A_j(W + \tilde u) \le h_j \mid \varepsilon_{ji}\right), \qquad \tilde u \mid \varepsilon_j \sim N\!\left(C_j(\Sigma^\varepsilon_j)^{-1}\varepsilon_j,\; \Omega - C_j(\Sigma^\varepsilon_j)^{-1}C_j'\right).$$

W36 (binary selection, $K = 2$): integrating the contribution over $y_2$
gives the $K = 1$ contribution of G1, and the contribution equals the
trivariate density integrated over the selection region (4e-15).

**What is identified.** The outcomes of one regime are observed together,
so their covariance $\Sigma^\varepsilon_j$ **is** identified, unlike the
covariance between regimes. Parameters per regime: $\beta_{jk}$,
$\sigma_{jk}$, $K_j(K_j-1)/2$ within-regime outcome correlations, and
$d\,K_j$ correlations with the selection disturbances.

**Parameterisation.** The correlation matrix of
$(\tilde u, \varepsilon_{j1}, \dots, \varepsilon_{jK_j})$ is built from
canonical partial correlations with the selection block first (engine
section 3), adding $K_j$ Cholesky columns: column $k$ has $d + k - 1$
free partial correlations. Positive definiteness and the shared selection
block hold by construction.

**Why estimate jointly.** The selection parameters and correlations are
estimated from all outcomes at once, and effects on several outcomes get a
joint covariance (for example a test that a regime raises productivity and
lowers emissions). Equation-by-equation estimates are consistent but ignore
both.

**Conditional expectations and effects** are computed outcome by outcome
with the formulas of the engine (section 6 there): the marginal model of
$(\tilde u, \varepsilon_{jk})$ is the $K = 1$ model. Effects are reported
per outcome, with the joint covariance across outcomes available.

**Two-step.** Equation by equation, with the common first step.

**Limits proposed for G2.** Gaussian outcomes only (mixed outcome types are
Generation 4, WP4.4). All $K_j$ outcomes of a regime observed for every unit
in it: a unit with a missing outcome is handled by the `missing =` rule
(dropped with a report, or an error). The same outcome variables in every
regime are required for effects; regimes may have different regressors.
