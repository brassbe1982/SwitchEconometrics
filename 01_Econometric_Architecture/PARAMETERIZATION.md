# Parameterisation and parameter transformations

Status: draft for the G1 econometric gate (WP1.1, 22 November 2026).
Specification sections 5.6 and 20 (item 3). Check V18 in
[verify_math.R](verify_math.R).

## 1. Principle

The optimiser works on an unconstrained working vector $\vartheta$. Every
value of $\vartheta$ maps to a valid statistical model. Clipping invalid
estimates after optimisation is never the constraint mechanism (specification
section 5.6). Natural parameters are reported; working parameters are
available with `coef(fit, type = "working")`.

## 2. Generation 1 transformations

| Natural | Working | Inverse | $d(\text{natural})/d(\text{working})$ | Second derivative |
| --- | --- | --- | --- | --- |
| $\gamma, \beta_1, \beta_0$ | identity | identity | 1 | 0 |
| $\sigma_j > 0$ | $\tau_j = \log\sigma_j$ | $\sigma_j = e^{\tau_j}$ | $\sigma_j$ | $\sigma_j$ |
| $\rho_j \in (-1, 1)$ | $\alpha_j = \operatorname{atanh}\rho_j$ | $\rho_j = \tanh\alpha_j$ | $1 - \rho_j^2$ | $-2\rho_j(1 - \rho_j^2)$ |

Why $\operatorname{atanh}$: it is the Fisher $z$-transformation. It is
unconstrained and symmetric about 0, and its sampling distribution is closer
to normal than that of $\hat\rho$. It also keeps the Hessian in closed form
(on this scale $1/\sqrt{1-\rho^2} = \cosh\alpha$ and
$\rho/\sqrt{1-\rho^2} = \sinh\alpha$; [LIKELIHOOD_DERIVATION.md](LIKELIHOOD_DERIVATION.md)
section 3).

## 3. Delta method

With $J = \partial\theta/\partial\vartheta' = \operatorname{diag}(1, \dots, 1, \sigma_1, \sigma_0, 1 - \rho_1^2, 1 - \rho_0^2)$:

$$\hat V_\theta = J\,\hat V_\vartheta\,J'.$$

For any smooth function $g(\theta)$ (effects, predictions), the standard
error uses $\nabla_\vartheta g = J'\nabla_\theta g$.

**Confidence intervals.**
- $\sigma_j$ and $\rho_j$: Wald intervals on the working scale, transformed
  back. These are asymmetric and always inside the parameter space.
- $\gamma$ and $\beta$: symmetric Wald intervals.
- `confint(type = "natural-wald")` gives symmetric intervals on the natural
  scale for comparison with other software.

## 4. Starting values

1. Two-step estimates ([LIKELIHOOD_DERIVATION.md](LIKELIHOOD_DERIVATION.md)
   section 9): $\hat\gamma$ from the probit, $\hat\beta_j$, $\hat\sigma_j$, and
   $\hat\rho_j$ truncated to $[-0.95, 0.95]$.
2. If the two-step fails (for example a singular regime design): probit for
   $\gamma$, OLS within regimes for $\beta_j$ and $\sigma_j$, $\rho_j = 0$.
3. Perturbed starts for multistart: $\vartheta^{(k)} = \vartheta^{(0)} + \xi^{(k)}$,
   with $\xi$ normal, standard deviation `perturb_sd` (default 0.5) times the
   two-step standard error for $\gamma$ and $\beta$, and 0.5 on the $\tau$ and
   $\alpha$ scales. A deterministic grid $\alpha_1, \alpha_0 \in \{-1, 0, 1\}$
   is added when `starts >= 10`.
4. User-supplied starting values through `control = switch_control(start = )`,
   on the natural scale.

## 5. Boundaries and conditioning

| Flag | Condition | Meaning |
| --- | --- | --- |
| `rho_boundary` | $\lvert\hat\rho_j\rvert > 0.995$ (i.e. $\lvert\hat\alpha_j\rvert > 2.99$) | Correlation at the edge; inference unreliable; often weak identification. |
| `sigma_boundary` | $\hat\sigma_j < 10^{-6}\operatorname{sd}(y)$ | Degenerate regime variance. |
| `hessian_not_nd` | the largest Hessian eigenvalue is $\ge 0$ | Not a strict local maximum. |
| `ill_conditioned` | Hessian condition number $> 10^{10}$ | Near-singular information; weak identification likely. |

All thresholds are fields of `switch_control()`. The flags appear in
`summary()` and `switch_diagnostics()`.

## 6. Later generations (specification section 5.6)

| Object | Transformation | Generation |
| --- | --- | --- |
| Degrees of freedom $\nu > 2$ | $\nu = 2 + e^{c}$ | G3 |
| Correlation matrix $R$ ($d \times d$) | Canonical partial correlations $\pi_{kl} = \tanh(\alpha_{kl})$, mapped to the Cholesky factor $L$ by the onion/vine construction of Lewandowski, Kurowicka and Joe (2009). This gives $R = LL'$ with a unit diagonal and positive definiteness by construction, and a one-to-one map with $d(d-1)/2$ free parameters. The spec's "normalise $LL'$ to unit diagonal" route is not one-to-one, because rows of $L$ can be rescaled. | G2 (multinomial probit, multivariate selection), G3 |
| Covariance matrix | $\Sigma = D R D$, $D = \operatorname{diag}(e^{\tau_k})$ | G2, G3 |
| Multinomial-probit covariance | Differences against the base alternative; one variance fixed to 1; the remaining structure as above | G2 |
| Copula parameters | Clayton $\theta = e^{c}$; Gumbel and Joe $\theta = 1 + e^{c}$; Frank $\theta \in \mathbb R\setminus\{0\}$ (identity, with 0 handled as the independence limit); Student-t $\rho = \tanh\alpha$, $\nu = 2 + e^{c}$; BB families on their product domains | G3 |
| Random-effect variances | $\log$ standard deviations plus correlations as above | G5 |

## 7. Generation 2 transformations

Status: **draft for the G2 econometric gate** (23 November 2026). Sections
1-6 are unchanged. Checks W05, W24 in [verify_math_g2.R](verify_math_g2.R).

### 7.1 Working parameters

| Natural parameter | Model | Working | Map |
| --- | --- | --- | --- |
| $\gamma$, $\gamma_j$, $\gamma_m$, $\beta$, $\beta_j$, $\delta$ | all | identity | |
| $\sigma$, $\sigma_j$, $\sigma_{jk}$ | all | $\tau = \log\sigma$ | $e^\tau$ |
| $\rho$ (Heckman, treatment), $\rho_j$ (Lee, nested logit, ordered) | | $\alpha = \operatorname{atanh}\rho$ | $\tanh\alpha$ |
| Treatment restrictions $\beta_1 = \beta + E\delta$, $\sigma_1 = \sigma_0$, $\rho_1 = \rho_0$ | treatment | linear map $\vartheta_{\text{ESR}} = A\vartheta_T$ | [OBSERVATION_MECHANISMS.md](OBSERVATION_MECHANISMS.md) s.3.2 |
| Thresholds $\mu_2 < \dots < \mu_{J-1}$ ($\mu_1 = 0$) | ordered | $\kappa_j = \log(\mu_j - \mu_{j-1})$ | $\mu_j = \mu_{j-1} + e^{\kappa_j}$ |
| Dissimilarity $\lambda_g \in (0, 1)$ | nested logit | $c_g = \operatorname{logit}\lambda_g$ | $1/(1 + e^{-c_g})$; $d\lambda/dc = \lambda(1 - \lambda)$ |
| Selection correlation matrix $R_\Omega$ or $R_u$ | MNP, sequential, multivariate | $d(d-1)/2$ values $\alpha^u$ | canonical partial correlations (section 6; `se_corr_from_cpc()`) |
| Selection standard deviations (MNP), first fixed at 1 | MNP `"unrestricted"` | $\tau^u_m = \log\operatorname{sd}(\tilde u_m)$, $m \ge 2$ | $e^{\tau^u_m}$ |
| Outcome-selection correlations $\psi_j \in \mathbb R^d$ | region models | $d$ values $\alpha^{(j)}$ per regime (fewer for sequential) | further Cholesky columns: $\ell_{j,m} = \tanh(\alpha^{(j)}_m)\sqrt{1 - \sum_{k<m}\ell_{j,k}^2}$, $\psi_j = \mathcal W'\ell_j$ ([GAUSSIAN_REGION_ENGINE.md](GAUSSIAN_REGION_ENGINE.md) s.3) |
| Within-regime outcome correlations ($K \ge 2$) | several outcomes | the same construction, one column per outcome | [MULTIVARIATE_SELECTION.md](MULTIVARIATE_SELECTION.md) s.4 |

**Order of the selection components.** The partial-correlation construction
depends on the order of the components of $\tilde u$. The order is fixed by
the model (alternatives in level order after the base; stages in order;
selection equations in the order given), and it is recorded in the fit. The
natural parameters ($\psi_j$, $\Omega$) and the likelihood do not depend on
it; only the working scale does.

### 7.2 Delta method and intervals

- Natural-scale covariance: $J\hat V_\vartheta J'$ with
  $J = \partial\theta/\partial\vartheta'$; closed form for the scalar
  transformations, complex-step for the correlation-matrix maps (exact to
  rounding, as `se_corr_jacobian()`).
- Intervals: on the working scale and transformed back for $\sigma$,
  $\rho$, $\lambda$ and the threshold increments. For the elements of
  $\psi_j$ and $\Omega$ with $d \ge 2$ a working value does not correspond
  to a single natural parameter, so their default interval is the
  natural-scale Wald interval, truncated to the admissible range and marked;
  the bootstrap percentile interval is the alternative.

### 7.3 Starting values

1. Two-step estimates of the model (its derivation document), with
   dependence parameters moved inside the admissible set where needed
   ($\lvert\rho\rvert \le 0.95$; $\psi_j'R_\Omega^{-1}\psi_j \le 0.9$).
2. If the two-step fails: first-step selection estimates, within-regime OLS,
   zero dependence.
3. Perturbed starts as in section 4, with standard deviation 0.5 on the
   working scale of every dependence parameter.
4. Nested logit: $\lambda_g = 0.8$ unless supplied. MNP `"unrestricted"`:
   $\Omega$ of the `"independent"` structure.

### 7.4 Boundary flags added in G2

| Flag | Condition |
| --- | --- |
| `lambda_boundary` | $\hat\lambda_g > 0.995$ or $< 0.05$ |
| `omega_boundary` | a correlation of $\hat\Omega$ or $\hat R_u$ beyond 0.995 in absolute value, or a ratio of standard deviations beyond $10^{1.5}$ |
| `psi_boundary` | $\hat\psi_j'\hat R_\Omega^{-1}\hat\psi_j > 0.99$ |
| `threshold_boundary` | $\hat\mu_j - \hat\mu_{j-1} < 10^{-4}$ |
