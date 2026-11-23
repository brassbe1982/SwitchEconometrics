# Observation mechanisms on the Gaussian binary engine (Generation 2, WP2.1)

Status: **draft for the G2 econometric gate** (23 November 2026). No code
exists for these models yet. Specification sections 10.1 and 10.2; plan
decision D7. Every formula is checked by
[verify_math_g2.R](verify_math_g2.R) (checks W01-W08).

This document covers the three models that reuse the Generation 1 engine
with a different observation mechanism or a parameter restriction:
`heckman()`, `treatment()` and `tobit5()`. Model, assumptions A1-A8 and the
sign convention are those of [BINARY_ESR.md](BINARY_ESR.md) unless stated.

## 1. Common elements

- **Selection equation and sign convention (D6).** $S_i = \mathbf 1\{z_i'\gamma + u_i > 0\}$,
  $u_i \sim N(0, 1)$, $w_i = z_i'\gamma$.
- **Notation.** $\lambda(a) = \phi(a)/\Phi(a)$,
  $\delta(a) = \lambda(a)\{a + \lambda(a)\}$,
  $m_1(w) = \lambda(w)$, $m_0(w) = -\lambda(-w)$,
  $\delta_1(w) = \delta(w)$, $\delta_0(w) = \delta(-w)$
  ([LIKELIHOOD_DERIVATION.md](LIKELIHOOD_DERIVATION.md) sections 4 and 9).
- **The Gaussian block.** For one outcome disturbance with scale
  $\sigma = e^\tau$ and correlation $\rho = \tanh\alpha$ with $u$, and for an
  observation whose selection event is $q(w + u) > 0$ with $q = \pm 1$:

  $$\log L = -\tau + \log\phi(e) + \log\Phi(a), \qquad a = q\,(w\cosh\alpha + e\sinh\alpha), \qquad e = (y - \text{mean})/\sigma.$$

  Its score and Hessian with respect to $(\gamma, \text{mean parameters}, \tau, \alpha)$
  are those of LIKELIHOOD_DERIVATION.md sections 5 and 6. The three models
  below are assembled from this block.

## 2. Heckman sample selection (Tobit-2): `heckman()`

### 2.1 Model

$$y_i^* = x_i'\beta + \varepsilon_i, \qquad y_i = y_i^* \text{ observed only if } S_i = 1,$$

$$\begin{pmatrix} u_i \\ \varepsilon_i \end{pmatrix} \sim N\!\left(0, \begin{pmatrix} 1 & \rho\sigma \\ \rho\sigma & \sigma^2 \end{pmatrix}\right).$$

For $S_i = 0$ only $(S_i, z_i)$ is used; $x_i$ may be missing there. This is
a different **observation mechanism** from switching, not a parameter
restriction (specification section 10.2;
[GENERAL_MODEL.md](GENERAL_MODEL.md) section 4). The outcome is observed in
the regime coded $S = 1$ (D6); a user whose data code the observed group
differently states it in the call.

Parameters: $\theta = (\gamma', \beta', \sigma, \rho)'$, working
$\vartheta = (\gamma', \beta', \tau, \alpha)'$. Software names:
`selection:<term>`, `outcome:<term>`, `outcome:sigma`, `outcome:rho`.

### 2.2 Likelihood (checks W01, W04)

$$L_i = \left[\frac{1}{\sigma}\,\phi(e_i)\,\Phi\!\left(\frac{w_i + \rho e_i}{\sqrt{1-\rho^2}}\right)\right]^{S_i}\left[\Phi(-w_i)\right]^{1 - S_i}, \qquad e_i = \frac{y_i - x_i'\beta}{\sigma}.$$

The first factor is the regime-1 contribution of G1. The second is the
probability of the unobserved state. $\int L_i(S=1)\,dy + \Phi(-w_i) = 1$
(W01).

### 2.3 Score and Hessian (check W02)

- **Observed units ($S_i = 1$):** the Gaussian block with $q = +1$:
  the regime-1 formulas of LIKELIHOOD_DERIVATION.md sections 5 and 6.
- **Unobserved units ($S_i = 0$):** a probit term,

  $$\frac{\partial\log L_i}{\partial\gamma} = -\lambda(-w_i)\,z_i, \qquad \frac{\partial^2\log L_i}{\partial\gamma\,\partial\gamma'} = -\delta(-w_i)\,z_i z_i',$$

  and zero for the other parameters.

The Hessian is analytic. Covariance estimators, tests and the FIML algorithm
are those of G1 (LIKELIHOOD_DERIVATION.md sections 7, 8 and 10); the
likelihood-ratio test of $\rho = 0$ has one degree of freedom and its
restricted log-likelihood is the probit plus one Gaussian regression.

### 2.4 Two-step estimator (Heckman 1979)

Probit for $\hat\gamma$; OLS of $y_i$ on $(x_i', m_1(\hat w_i))$ among
$S_i = 1$; $\hat\theta = \widehat{\sigma\rho}$ is the coefficient of
$m_1$. Variance recovery and the first-stage-corrected covariance are the
regime-1 formulas of LIKELIHOOD_DERIVATION.md section 9 without change:

$$\hat\sigma^2 = \frac{1}{n_1}\sum_{S_i=1}\hat\eta_i^2 + \hat\theta^2\,\frac{1}{n_1}\sum_{S_i=1}\delta_1(\hat w_i), \qquad \hat\rho = \hat\theta/\hat\sigma.$$

These were verified in G1 (V07-V09, V13, V14). The stacked M-estimation
(sandwich and cluster) covariance is the G1 one restricted to one regime.

### 2.5 Nesting (check W03)

For any $(\beta_0, \sigma_0)$,

$$\ell_{\text{Heckman}}(\gamma, \beta, \sigma, \rho) = \ell_{\text{ESR}}(\gamma, \beta_1 = \beta, \sigma_1 = \sigma, \rho_1 = \rho, \beta_0, \sigma_0, \rho_0 = 0) - \sum_{S_i = 0}\log\left[\frac{1}{\sigma_0}\phi(e_{0i})\right].$$

The Heckman likelihood is the ESR likelihood with the regime-0 outcome
density removed. W03 confirms the identity to 3e-13; the package test of
WP2.1 uses it against the frozen 1.0.0 engine.

### 2.6 Predictions

| Quantity | Formula |
| --- | --- |
| $P(S = 1 \mid z)$ | $\Phi(w)$ |
| $E[y^* \mid x]$ (population, "unconditional") | $x'\beta$ |
| $E[y^* \mid S = 1, x, z]$ (observed group) | $x'\beta + \sigma\rho\,m_1(w)$ |
| $E[y^* \mid S = 0, x, z]$ (unobserved group) | $x'\beta + \sigma\rho\,m_0(w)$ |

There is no treatment effect in this model: there is one potential outcome.
`switch_effects()` refuses a `heckman` fit with a classed error that names
`switch_predict()`.

## 3. Endogenous treatment with a structural shift: `treatment()`

### 3.1 Model

One outcome equation for every unit, with the regime entering as a shift:

$$y_i = x_i'\beta + S_i\,d_i'\delta + \varepsilon_i, \qquad \begin{pmatrix} u_i \\ \varepsilon_i \end{pmatrix} \sim N\!\left(0, \begin{pmatrix} 1 & \rho\sigma \\ \rho\sigma & \sigma^2 \end{pmatrix}\right).$$

- $d_i$ is a sub-vector of $x_i$ that contains the constant: the **effect
  modifiers**. With $d_i = 1$ this is the classical endogenous-treatment
  (dummy endogenous variable) model with an intercept shift $\delta$
  (Heckman 1978; Maddala 1983). With further modifiers it is the hybrid
  model with a structural shift, in which the treatment effect
  $d_i'\delta$ varies with observed covariates.
- One disturbance: $\sigma$ and $\rho$ are common to both regimes.

Parameters: $\theta = (\gamma', \beta', \delta', \sigma, \rho)'$. Software
names: `selection:<term>`, `outcome:<term>`, `shift:<term>`,
`outcome:sigma`, `outcome:rho`.

### 3.2 Likelihood as a restriction of the ESR (checks W05a, W07)

With $e_i = (y_i - x_i'\beta - S_i d_i'\delta)/\sigma$ and $q_i = 2S_i - 1$:

$$L_i = \frac{1}{\sigma}\,\phi(e_i)\,\Phi\!\left(q_i\,\frac{w_i + \rho e_i}{\sqrt{1-\rho^2}}\right).$$

This is the binary ESR likelihood under the **linear restriction**
$\vartheta_{\text{ESR}} = A\,\vartheta_T$:

| ESR parameter | Treatment parameters |
| --- | --- |
| $\gamma$ | $\gamma$ |
| $\beta_0$ | $\beta$ |
| $\beta_1$ | $\beta + E\delta$, where $E$ places the elements of $\delta$ at the positions of $d$ in $x$ |
| $\tau_1 = \tau_0$ | $\tau$ |
| $\alpha_1 = \alpha_0$ | $\alpha$ |

The equality is exact because $\operatorname{Cov}(\varepsilon_1, \varepsilon_0)$
never enters the ESR likelihood (BINARY_ESR.md section 5). W05a confirms it
per observation to 2e-15.

### 3.3 Score and Hessian (checks W05b, W05c)

By the chain rule for a linear map, with $g$ and $H$ the G1 score and
Hessian evaluated at $A\vartheta_T$:

$$\frac{\partial\ell_T}{\partial\vartheta_T} = A'g, \qquad \frac{\partial^2\ell_T}{\partial\vartheta_T\,\partial\vartheta_T'} = A'HA.$$

Per-observation scores are $s_i^T = A's_i$, so the OPG, sandwich and cluster
covariances of G1 carry over. The software implements the restriction with
the parameter map (a linear-restriction matrix in `se_parmap`), so the G1
engine is called unchanged.

**Tests.** The likelihood-ratio and Wald tests of $\rho = 0$ have one
degree of freedom. The treatment model is nested in the ESR with the same
regressors: a likelihood-ratio test of the restrictions of the table
($k_x - k_d$ slope equalities, $\sigma_1 = \sigma_0$, $\rho_1 = \rho_0$) is
offered by `switch_compare()`.

### 3.4 Two-step estimator (checks W06, W08)

From $E[\varepsilon \mid u] = \sigma\rho u$ and the truncated normal:

$$E[y_i \mid S_i, x_i, z_i] = x_i'\beta + S_i d_i'\delta + \theta\,h_i, \qquad h_i = S_i\,m_1(w_i) + (1 - S_i)\,m_0(w_i), \quad \theta = \sigma\rho,$$

$$\operatorname{Var}(\varepsilon_i \mid S_i, z_i) = \sigma^2\left(1 - \rho^2\,\delta_{S_i}(w_i)\right).$$

$h_i$ is the generalised residual of the probit (W06).

1. Probit for $\hat\gamma$ and $\hat V_\gamma$.
2. OLS of $y_i$ on $W_i = (x_i', S_i d_i', \hat h_i)'$ over **all** units
   gives $\hat b = (\hat\beta', \hat\delta', \hat\theta)'$ and residuals
   $\hat\eta_i$.
3. $\hat\sigma^2 = \frac1n\sum_i\hat\eta_i^2 + \hat\theta^2\,\frac1n\sum_i\delta_{S_i}(\hat w_i)$,
   $\hat\rho = \hat\theta/\hat\sigma$.
4. Model-based covariance, with $\Delta = \operatorname{diag}\{\delta_{S_i}(\hat w_i)\}$
   and $\partial h_i/\partial w_i = -\delta_{S_i}(w_i)$ in both regimes:

   $$\hat V(\hat b) = \hat\sigma^2\,(W'W)^{-1}\left[W'(I - \hat\rho^2\Delta)W + \hat\rho^2\,(W'\Delta Z)\,\hat V_\gamma\,(Z'\Delta W)\right](W'W)^{-1},$$

   $$\widehat{\operatorname{Cov}}(\hat b, \hat\gamma) = (W'W)^{-1}\hat\theta\,(W'\Delta Z)\,\hat V_\gamma.$$

5. The stacked M-estimation covariance is as in G1, with the moments (probit
   score, $W_i\eta_i$).

**Evidence.** W08a: at $n = 400\,000$ the two-step $\hat\sigma$, $\hat\rho$
and $\hat\delta$ are within 0.0097 of the truth. W08b: over 400 replications
at $n = 1000$, the ratio of the mean estimated standard error to the
empirical standard deviation is within 5.6% of 1 for every coefficient
(tolerance 10%; the Monte Carlo standard error of the ratio is about 3.5%).

### 3.5 Effects

With one disturbance, $\theta_1 - \theta_0 = 0$ in the ESR formulas of
[TREATMENT_EFFECTS.md](TREATMENT_EFFECTS.md) section 3, so there is no
selection on gains:

| Effect | Value |
| --- | --- |
| $TT_i = TU_i = ATE_i$ | $d_i'\delta$ |
| ATE | $\frac1N\sum_i d_i'\delta$ |
| ATT | $\frac{1}{n_1}\sum_{S_i=1} d_i'\delta$ |
| ATU | $\frac{1}{n_0}\sum_{S_i=0} d_i'\delta$ |
| TH | $ATT - ATU$: differences in the modifiers only; 0 when $d = 1$ |
| BH$_0$ | mean of $x'\beta + \theta m_1(w)$ over $T_1$ minus mean of $x'\beta + \theta m_0(w)$ over $T_0$ |
| BH$_1$ | BH$_0$ + TH (the same expression with $d'\delta$ added to both means), so $BH_1 - BH_0 = TH$ as in G1 |

The four conditional expectations, counterfactual scenarios and their
delta-method standard errors are the G1 expressions evaluated at
$A\hat\vartheta_T$, with gradients $A'\nabla g$.

## 4. Tobit-5: `tobit5()`

Amemiya's Tobit type 5 has one selection equation and two outcome equations,
$y_{1i}$ observed when $S_i = 1$ and $y_{0i}$ when $S_i = 0$. Its likelihood
is the binary ESR likelihood of G1 (specification section 10.1: "two-regime
selection likelihood"). The two responses may be different variables; the
G1 data builder already evaluates one response per regime.

`tobit5()` is therefore a **second interface to the G1 model**, not a new
likelihood:

| | `esr()` | `tobit5()` |
| --- | --- | --- |
| Likelihood, estimators, inference | G1 | identical |
| Outcome list | named or positional regimes | positional: first equation is observed when $S = 0$, second when $S = 1$ (the `sampleSelection::selection()` convention) |
| Responses | usually one variable | may differ between the equations |
| Effects | ATT, ATU, ATE, TH, BH | the same when both responses are the same variable; refused with a classed error when they differ, because a difference of two different variables is not a treatment effect |

## 5. Relation to existing R implementations

| Package | Function | Mapping | Status |
| --- | --- | --- | --- |
| `sampleSelection` 1.2-16 | `selection(S ~ z, y ~ x)` (Tobit-2, ML) | coefficients in the order selection, outcome, `sigma`, `rho`; same sign of `rho` | **verified** (W04): our log-likelihood at its ML estimates equals its value exactly; our score there is 1.8e-6 |
| `sampleSelection` 1.2-16 | `treatReg(S ~ z, y ~ x + S)` (ML) | the coefficient of `S` is $\delta$; `sigma`, `rho` with the same sign | **verified** for a constant shift (W07): log-likelihoods equal to 9e-13; our score there is 8e-7 |
| `sampleSelection` 1.2-16 | two-step (`heckit`, `treatReg` two-step) | coefficient of the inverse Mills ratio is $\theta$ | to be established by simulation in WP2.1 before any comparison, as D-SS-1 was for Tobit-5 |
| `endogenous` | `hybrid()` (structural shift with effect modifiers) | expected to match section 3 | **not verified**: the package is not installed and is no longer on CRAN (checked 23 November 2026 against cloud.r-project.org). Installing it from the CRAN archive needs the owner's approval. Until then the hybrid model is validated by `treatReg` (constant shift), by the exact nesting in the ESR (W05) and by Monte Carlo |

## 6. Identification

The classification of [IDENTIFICATION.md](IDENTIFICATION.md) applies with
these changes.

| Model | Change |
| --- | --- |
| Heckman | One regime: I1, I2, I4-I7 apply to the observed regime only. The $\rho$ of the unobserved regime does not exist. I11 (non-identified parameters) is empty. |
| Treatment | $\rho$ is identified from both regimes, through $h_i$, whose sign changes with $S_i$. I6 uses the $R^2$ of $\hat h_i$ on $(x_i, S_i d_i)$ over all units. Without an exclusion restriction, identification of $(\delta, \rho)$ rests on the normality of $u$: the warning of IDENTIFICATION.md section 2 applies. I11 is empty: there is one outcome disturbance. |
| Tobit-5 | As G1. |

## 7. What is not verified

- The `endogenous::hybrid()` conventions (section 5).
- The two-step conventions of `sampleSelection` for Tobit-2 and `treatReg`
  (section 5).
- The two-step treatment covariance is checked by one Monte Carlo design
  (W08b); the G2 Monte Carlo study
  ([MONTE_CARLO_DESIGN.md](../04_Validation/MONTE_CARLO_DESIGN.md) section 8)
  covers more designs.
