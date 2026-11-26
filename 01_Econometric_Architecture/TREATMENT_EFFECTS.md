# Treatment effects and counterfactuals (Generation 1)

Status: draft for the G1 econometric gate (WP1.1, 22 November 2026).
Specification section 11; plan decision D9. Checks V07, V15 and V16 in
[verify_math.R](verify_math.R).

## 1. Potential outcomes

$Y_i(1) = x_{1i}'\beta_1 + \varepsilon_{1i}$, $Y_i(0) = x_{0i}'\beta_0 + \varepsilon_{0i}$,
$Y_i = S_iY_i(1) + (1 - S_i)Y_i(0)$. All effects below are conditional on the
observed covariates of the sample (sample average effects). Bootstrap
standard errors (WP1.5) also reflect sampling variation in the covariates.

## 2. The four conditional expectations (checks V07, V16a)

With $w_i = z_i'\gamma$, $m_1(w) = \phi(w)/\Phi(w)$,
$m_0(w) = -\phi(w)/\{1 - \Phi(w)\}$ and
$E[\varepsilon_j \mid u] = \sigma_j\rho_j\,u$:

| | Regime-1 units ($S = 1$) | Regime-0 units ($S = 0$) |
| --- | --- | --- |
| Outcome under regime 1 | (a) $E[Y(1) \mid S=1] = x_1'\beta_1 + \sigma_1\rho_1\,m_1(w)$ *observed* | (c) $E[Y(1) \mid S=0] = x_1'\beta_1 + \sigma_1\rho_1\,m_0(w)$ *counterfactual* |
| Outcome under regime 0 | (b) $E[Y(0) \mid S=1] = x_0'\beta_0 + \sigma_0\rho_0\,m_1(w)$ *counterfactual* | (d) $E[Y(0) \mid S=0] = x_0'\beta_0 + \sigma_0\rho_0\,m_0(w)$ *observed* |

Cells (a) and (d) are the expected observed outcomes. Cells (b) and (c) are
counterfactuals. The specification's distinction between
$E(Y_1 \mid S = 1)$ and $E(Y_1 \mid S = 0)$ (section 5.8) is the distinction
between cells (a) and (c). This 2 x 2 layout follows Lokshin and Sajaia (2004)
and Di Falco, Veronesi and Yesuf (2011), and is printed by `switch_effects()`
with group means and group sizes.

## 3. Treatment effects (checks V15b, V15c)

Let $T_1 = \{i: S_i = 1\}$ with $n_1$ units, $T_0 = \{i : S_i = 0\}$ with $n_0$
units, and $\theta_j = \sigma_j\rho_j$.

| Effect | Definition | Sample estimator |
| --- | --- | --- |
| ATT | $E[Y(1) - Y(0) \mid S = 1]$ | $\frac{1}{n_1}\sum_{T_1}\left[x_{1i}'\beta_1 - x_{0i}'\beta_0 + (\theta_1 - \theta_0)\,m_1(w_i)\right]$ |
| ATU | $E[Y(1) - Y(0) \mid S = 0]$ | $\frac{1}{n_0}\sum_{T_0}\left[x_{1i}'\beta_1 - x_{0i}'\beta_0 + (\theta_1 - \theta_0)\,m_0(w_i)\right]$ |
| ATE | $E[Y(1) - Y(0)]$ | $\frac{1}{N}\sum_i\left[x_{1i}'\beta_1 - x_{0i}'\beta_0\right]$ |
| TH | $ATT - ATU$ (treatment heterogeneity) | difference of the above |
| BH$_1$ | $E[Y(1) \mid S=1] - E[Y(1) \mid S=0]$ (base heterogeneity, regime-1 outcome) | mean of (a) over $T_1$ minus mean of (c) over $T_0$ |
| BH$_0$ | $E[Y(0) \mid S=1] - E[Y(0) \mid S=0]$ (base heterogeneity, regime-0 outcome) | mean of (b) over $T_1$ minus mean of (d) over $T_0$ |

**Plan decision D9 (for the econometric gate).** The specification defines BH
as the "difference between the observed and counterfactual untreated outcome
for treated agents". Read literally, that is cell (a) minus cell (b), which is
the ATT. The package reports BH$_1$ and BH$_0$ as defined in the applied ESR
literature (Carter and Milon 2005; Di Falco, Veronesi and Yesuf 2011) and
prints the definitions with the results.

**Identities used as tests:**
- $BH_1 - BH_0 = TH$ exactly (V15b).
- In the population, $E[S\,m_1(w) + (1 - S)\,m_0(w) \mid z] = 0$, so
  $ATE = \pi\,ATT + (1 - \pi)\,ATU$, with $\pi = P(S = 1)$.
- In the sample this holds exactly when $\gamma$ is the probit MLE and $z$
  contains an intercept, because $\sum_i[S_i m_1(\hat w_i) + (1 - S_i)m_0(\hat w_i)]$
  is then the probit score for the intercept, which is zero (V15c).
- At the FIML estimate it holds only approximately. The package reports ATE
  as defined in the table and shows the share-weighted average alongside.

Observation-level quantities are returned by
`switch_effects(..., individual = TRUE)`: the four expectations and
$TT_i$ (for $i \in T_1$), $TU_i$ (for $i \in T_0$), and
$ATE_i = x_{1i}'\beta_1 - x_{0i}'\beta_0$. They support heterogeneity analysis
by subgroup (`by =`).

## 4. Interpretation guard rails

- None of these quantities depends on $\operatorname{Corr}(\varepsilon_1, \varepsilon_0)$
  ([IDENTIFICATION.md](IDENTIFICATION.md) section 3).
- Distributional effects need $\operatorname{Corr}(\varepsilon_1, \varepsilon_0)$:
  the distribution, variance and quantiles of individual gains, and
  $P(Y(1) > Y(0))$. In G1 they are reported only as bounds over the
  admissible range, or under the stated assumption $r_{10} = \rho_1\rho_0$
  (specification section 5.8: "where identified and supported").
- The same applies to counterfactuals conditional on an observed outcome,
  such as $E[Y(0) \mid S = 1, Y(1) = y]$.

## 5. Standard errors (check V15a)

**Delta method (default).** Each effect is a smooth function $g(\vartheta)$
of the working parameters. With $D_j(w) = \delta_j(w)$ so that
$\partial m_j/\partial\gamma = -D_j(w)\,z$, and $\bar f_{T}$ denoting a mean
over $T_1$ or $T_0$:

| Effect | $\partial/\partial\gamma$ | $\partial/\partial\beta_1$ | $\partial/\partial\beta_0$ | $\partial/\partial\tau_1$ | $\partial/\partial\tau_0$ | $\partial/\partial\alpha_1$ | $\partial/\partial\alpha_0$ |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ATT | $(\theta_1 - \theta_0)\,\overline{(-D_1 z)}_{T_1}$ | $\bar x_{1,T_1}$ | $-\bar x_{0,T_1}$ | $\theta_1\bar m_{1,T_1}$ | $-\theta_0\bar m_{1,T_1}$ | $\sigma_1(1-\rho_1^2)\bar m_{1,T_1}$ | $-\sigma_0(1-\rho_0^2)\bar m_{1,T_1}$ |
| ATU | $(\theta_1 - \theta_0)\,\overline{(-D_0 z)}_{T_0}$ | $\bar x_{1,T_0}$ | $-\bar x_{0,T_0}$ | $\theta_1\bar m_{0,T_0}$ | $-\theta_0\bar m_{0,T_0}$ | $\sigma_1(1-\rho_1^2)\bar m_{0,T_0}$ | $-\sigma_0(1-\rho_0^2)\bar m_{0,T_0}$ |
| ATE | 0 | $\bar x_1$ | $-\bar x_0$ | 0 | 0 | 0 | 0 |
| BH$_1$ | $\theta_1[\overline{(-D_1 z)}_{T_1} - \overline{(-D_0 z)}_{T_0}]$ | $\bar x_{1,T_1} - \bar x_{1,T_0}$ | 0 | $\theta_1\Delta\bar m$ | 0 | $\sigma_1(1-\rho_1^2)\Delta\bar m$ | 0 |
| BH$_0$ | $\theta_0[\overline{(-D_1 z)}_{T_1} - \overline{(-D_0 z)}_{T_0}]$ | 0 | $\bar x_{0,T_1} - \bar x_{0,T_0}$ | 0 | $\theta_0\Delta\bar m$ | 0 | $\sigma_0(1-\rho_0^2)\Delta\bar m$ |

Here $\Delta\bar m = \bar m_{1,T_1} - \bar m_{0,T_0}$, and TH is the ATT row
minus the ATU row. Then $\operatorname{se}(g) = \sqrt{\nabla g'\,\hat V_\vartheta\,\nabla g}$.
For two-step fits, $\hat V$ is the joint covariance of
$(\hat\gamma, \hat b_1, \hat b_0)$ including the cross terms
([LIKELIHOOD_DERIVATION.md](LIKELIHOOD_DERIVATION.md) section 9), with the
gradient expressed in $(\gamma, \beta_j, \theta_j)$.

**Bootstrap.** Nonparametric (resampling units or clusters) or parametric
(redrawing $(S, y)$ from the fitted model). Percentile and normal intervals;
the share of failed replications is reported.

## 6. Counterfactual and policy scenarios (check V16b)

`switch_counterfactual()` evaluates, per observation and on average:

| Scenario | Expected outcome |
| --- | --- |
| Observed regime assignment (baseline) | $E[Y \mid x, z] = \Phi(w)\,[x_1'\beta_1 + \theta_1 m_1(w)] + \{1 - \Phi(w)\}\,[x_0'\beta_0 + \theta_0 m_0(w)] = x_1'\beta_1\Phi(w) + x_0'\beta_0\{1 - \Phi(w)\} + (\theta_1 - \theta_0)\,\phi(w)$ |
| Everyone in regime 1 | $E[Y(1) \mid x] = x_1'\beta_1$; for actual regime-0 units, cell (c) |
| Everyone in regime 0 | $E[Y(0) \mid x] = x_0'\beta_0$; for actual regime-1 units, cell (b) |
| Policy change $z \to z^*$ (for example better internet access) | the baseline formula evaluated at $w^* = z^{*\prime}\gamma$; the adoption probability changes from $\Phi(w)$ to $\Phi(w^*)$ |

The policy formula keeps the dependence between selection and outcome
disturbances: the units who switch regime under the policy are selected on
$u$, and their outcome disturbances are correlated with $u$. This is what the
term $(\theta_1 - \theta_0)\phi(w^*)$ captures. Simulating the regime choice
independently of the outcome disturbances would omit it (specification
section 11.4).

Distributions of outcome changes come from simulating $(u, \varepsilon_1, \varepsilon_0)$
from the fitted model. Under the policy scenario this needs no assumption on
$r_{10}$, because only the realised regime's outcome enters. For individual
gains $Y(1) - Y(0)$ the bounds and assumption of section 4 apply.
