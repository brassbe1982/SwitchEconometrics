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
