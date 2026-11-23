# Ordered and sequential regime selection (Generation 2, WP2.4)

Status: **draft for the G2 econometric gate** (23 November 2026). No code
exists for these models yet. Specification section 4 (Family B). Checks
W30-W34 in [verify_math_g2.R](verify_math_g2.R). Both models are instances
of [GAUSSIAN_REGION_ENGINE.md](GAUSSIAN_REGION_ENGINE.md); the ordered model
also has closed forms, given here.

## 1. Ordered regime selection (ordered probit)

### 1.1 Model

Regimes $j = 1, \dots, J$ are ordered (for example no, partial and full
adoption). One latent index:

$$S_i^* = z_i'\gamma + u_i, \qquad S_i = j \iff \mu_{j-1} < S_i^* \le \mu_j, \qquad -\infty = \mu_0 < \mu_1 < \dots < \mu_{J-1} < \mu_J = \infty,$$

$$y_{ji} = x_{ji}'\beta_j + \varepsilon_{ji} \text{ observed iff } S_i = j, \qquad \begin{pmatrix} u_i \\ \varepsilon_{ji}\end{pmatrix} \sim N\!\left(0, \begin{pmatrix} 1 & \rho_j\sigma_j \\ \rho_j\sigma_j & \sigma_j^2\end{pmatrix}\right).$$

**Normalisation (gate question).** $z_i$ keeps its intercept and the first
threshold is fixed: $\mu_1 = 0$. The others are
$\mu_j = \mu_{j-1} + e^{\kappa_j}$, $j = 2, \dots, J - 1$, so the ordering
holds for every working vector. With $J = 2$ the model is then **literally**
the G1 model: $S = 2 \iff z'\gamma + u > 0$, with the same $\gamma$
(section 1.5). Software that reports cut points without an intercept
(`MASS::polr`, `switchSelection`) has cuts $\mu_j - \gamma_0$.

**Sign convention (D6).** $\rho_j = \operatorname{Corr}(u, \varepsilon_j)$
for every regime: a positive $\rho_j$ means that unobservables pushing
towards **higher** regimes raise the outcome in regime $j$.

Parameters: $\theta = (\gamma', \mu_2, \dots, \mu_{J-1}, \beta_1', \dots, \beta_J', \sigma_1, \dots, \sigma_J, \rho_1, \dots, \rho_J)'$.

### 1.2 Likelihood (check W30)

With $w = z'\gamma$, $e = (y - x_j'\beta_j)/\sigma_j$,
$s = \sinh\alpha_j$, $c = \cosh\alpha_j$ and, for a threshold $\mu$,
$a(\mu) = (\mu - w)\,c - e\,s = (\mu - w - \rho_je)/\sqrt{1-\rho_j^2}$:

$$L_{ji} = \frac{1}{\sigma_j}\,\phi(e)\,\mathcal A, \qquad \mathcal A = \Phi\!\left(a(\mu_j)\right) - \Phi\!\left(a(\mu_{j-1})\right),$$

with $\Phi(a(\pm\infty)) = 1, 0$. W30: equal to the bivariate density
integrated over $(\mu_{j-1} - w, \mu_j - w]$ to 9e-16.

$\log\mathcal A$ is evaluated without cancellation: when both arguments are
positive, $\mathcal A = \Phi(-a(\mu_{j-1})) - \Phi(-a(\mu_j))$; in the tails
the difference is formed in log space.

### 1.3 Score and Hessian (check W31)

Write $a_h = a(\mu_j)$, $a_l = a(\mu_{j-1})$, $\phi_h = \phi(a_h)$,
$\phi_l = \phi(a_l)$ (zero at an infinite threshold). First and second
derivatives of $a(\mu)$ with respect to the working parameters:

| | $\gamma$ | $\beta_j$ | $\tau_j$ | $\alpha_j$ | $\kappa_m$ ($\mu$ depends on it) |
| --- | --- | --- | --- | --- | --- |
| $\partial a$ | $-c\,z$ | $s\,x/\sigma$ | $s\,e$ | $(\mu - w)s - e\,c$ | $c\,e^{\kappa_m}$ |

Non-zero second derivatives: $\gamma\alpha$: $-s\,z$; $\beta\tau$:
$-s\,x/\sigma$; $\beta\alpha$: $c\,x/\sigma$; $\tau\tau$: $-s\,e$;
$\tau\alpha$: $c\,e$; $\alpha\alpha$: $a$; $\kappa_m\kappa_m$:
$c\,e^{\kappa_m}$; $\kappa_m\alpha$: $s\,e^{\kappa_m}$.
$\partial\mu_j/\partial\kappa_m = e^{\kappa_m}$ for $2 \le m \le j$.

$$\frac{\partial\log L}{\partial\vartheta} = \frac{\partial}{\partial\vartheta}\!\left[-\tau_j - \tfrac12e^2\right] + g_{\mathcal A}, \qquad g_{\mathcal A} = \frac{\phi_h\nabla a_h - \phi_l\nabla a_l}{\mathcal A},$$

$$\frac{\partial^2\log L}{\partial\vartheta\,\partial\vartheta'} = \frac{\partial^2}{\partial\vartheta\,\partial\vartheta'}\!\left[-\tau_j - \tfrac12e^2\right] + \frac{-a_h\phi_h\nabla a_h\nabla a_h' + \phi_h\nabla^2a_h + a_l\phi_l\nabla a_l\nabla a_l' - \phi_l\nabla^2a_l}{\mathcal A} - g_{\mathcal A}g_{\mathcal A}'.$$

The outcome-density part is that of G1. The Hessian is fully analytic, so
Newton-Raphson and the G1 inference apply. W31: score and Hessian equal the
numerical derivatives to 4.5e-8 and 1.3e-7.

### 1.4 Conditional moments and the two-step estimator (check W33)

For regime $k$, with $\underline a = \mu_{k-1} - w$ and $\bar a = \mu_k - w$:

$$m_k(w) = E[u \mid S = k] = \frac{\phi(\underline a) - \phi(\bar a)}{\Phi(\bar a) - \Phi(\underline a)}, \qquad \operatorname{Var}(u \mid S = k) = 1 + \frac{\underline a\,\phi(\underline a) - \bar a\,\phi(\bar a)}{\Phi(\bar a) - \Phi(\underline a)} - m_k(w)^2 =: 1 - \delta_k(w),$$

$$\frac{\partial m_k}{\partial w} = -\delta_k(w), \qquad E[Y_j \mid S = k] = x_j'\beta_j + \sigma_j\rho_j\,m_k(w) \quad \text{for all } j, k.$$

With $J = 2$ these are $m_1$, $m_0$, $\delta_1$, $\delta_0$ of G1. W33:
moments against integration and the derivative against a numerical one,
5e-11.

**Two-step.** Ordered probit; then OLS of $y$ on $(x_j', m_j(\hat w))$ in
regime $j$ with $\theta_j = \sigma_j\rho_j$;
$\hat\sigma_j^2 = \overline{\hat\eta_j^2} + \hat\theta_j^2\,\overline{\delta_j(\hat w)}$.
The corrected covariance is the G1 formula with the first-step parameter
vector $(\gamma, \kappa)$ and the Jacobian
$\partial m_j/\partial(\gamma, \kappa)'$ in place of $-\delta_jz'$
(the threshold derivatives are
$\partial m_j/\partial\mu_j$ and $\partial m_j/\partial\mu_{j-1}$, in closed
form from the expression above). It is checked by Monte Carlo in WP2.4.

### 1.5 Nesting (check W32)

- $J = 2$: the likelihood equals the G1 likelihood for the same parameter
  values, per observation, to 9e-16 (W32a), with ordered regime 1 = G1
  regime 0.
- The closed forms of this section equal the region engine with $d = 1$
  and limits $(\mu_{j-1}, \mu_j]$: log-likelihood and score per observation
  to 9e-16 (W32b).

### 1.6 Identification

One correlation per regime, one correction term per regime; the G1
diagnostics apply regime by regime. A middle regime's correction term
$m_k(w)$ is bounded and less variable than a tail regime's, so $\rho_k$ of a
narrow middle regime is typically the most weakly identified parameter; I6
is reported per regime. The proportional-index assumption (one $\gamma$ for
all thresholds) is part of the model and is not tested by the package in G2.

## 2. Sequential regime selection

### 2.1 Model

Regimes are reached through $J - 1$ ordered binary decisions (for example:
adopt or not; if adopted, upgrade or not). At stage $m$, a unit that has
reached it **continues** if and only if

$$z_{mi}'\gamma_m + u_{mi} > 0, \qquad m = 1, \dots, J - 1.$$

Regime $j < J$: the unit passes stages $1, \dots, j - 1$ and stops at stage
$j$. Regime $J$: it passes all stages. Each stage has its own regressors
and coefficients. Unit variances; $(u_1, \dots, u_{J-1}, \varepsilon_j)$
jointly normal.

It is the engine instance with $d = J - 1$, $A_j = I$ and limits per stage:
$(0, \infty)$ for a passed stage, $(-\infty, 0]$ for the stopping stage, and
$(-\infty, \infty)$ for stages after the stop.

### 2.2 Likelihood (check W34a)

For regime $j$ only the stages $1, \dots, \min(j, J-1)$ enter:

$$L_{ji} = \frac{1}{\sigma_j}\phi(e_{ji})\,\Pr\!\left(u_1 > -w_1, \dots, u_{j-1} > -w_{j-1},\; u_j \le -w_j \mid \varepsilon_{ji}\right),$$

a normal orthant probability of dimension $\min(j, J-1)$. For regime 1 it is
the G1 regime-0 form $\Phi(-(w_1 + \rho_{1}e)/\sqrt{1 - \rho_{1}^2})$:
later stages integrate out (W34a, 9e-16 for the closed form and for the
trivariate normal check of regimes 2 and 3).

### 2.3 Parameters and what is identified (check W34b)

- **Stage correlations** $R_u$ (gate question). The later stages are
  observed only for units that passed the earlier ones, so
  $\operatorname{Corr}(u_m, u_{m'})$ is identified only through the
  functional form or through variables excluded from one stage.
  **Proposed:** `stage_dependence = "independent"` ($R_u = I$) is the
  default; `"unrestricted"` is offered with the warning of
  [IDENTIFICATION.md](IDENTIFICATION.md) section 8.
- **Outcome correlations.** Regime $j$'s likelihood involves
  $(u_1, \dots, u_{\min(j, J-1)}, \varepsilon_j)$ only. Regime $j$ therefore
  has $\min(j, J-1)$ correlation parameters:
  $\operatorname{Corr}(u_m, \varepsilon_j)$ for the stages it went through.
  Correlations with later stages do not enter the likelihood; they are not
  parameters and are listed as not identified. In the parameterisation of
  the engine (section 3 there) the corresponding partial correlations are
  fixed at zero, which does not restrict the likelihood, because $R_u$ is
  built stage by stage.
- Score and covariance: the engine. W34b: score equal to the numerical
  gradient to 3e-9 ($J = 3$, correlated stages).

### 2.4 Conditional expectations

$E[Y_j \mid S = k] = x_j'\beta_j + \kappa_j'm_k(W)$ needs the correlations
of $\varepsilon_j$ with the stages that define regime $k$. For $k \le j$
these are identified. For $k > j$ (units that went further than
regime $j$'s stopping stage) the correlations of $\varepsilon_j$ with the
later stages are not identified. **Proposed:** these counterfactual means
are computed under the stated assumption that the non-identified partial
correlations are zero, and are marked as assumption-based in the output;
effects that use them carry the same mark.

### 2.5 Nesting

$J = 2$ is G1. With independent stages and all outcome correlations zero the
likelihood factorises into $J - 1$ probits on the units at risk at each
stage and $J$ regressions; this is the restricted model of the
likelihood-ratio test of selection on unobservables.
