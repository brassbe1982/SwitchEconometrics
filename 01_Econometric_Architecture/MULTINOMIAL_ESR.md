# Multinomial endogenous switching regression (Generation 2, WP2.2-WP2.4)

Status: **draft for the G2 econometric gate** (23 November 2026). No code
exists for these models yet. Specification sections 3.1, 4 (Family B), 6.3
and 11.3. Checks W10-W16, W21-W28, W37-W38 in
[verify_math_g2.R](verify_math_g2.R).

Multinomial logit and multinomial probit selection are **two different
models** (specification section 4B). They differ in the distribution of the
selection disturbances, in what links them to the outcomes, and in what is
identified. Section 7 sets them side by side.

## 1. Common random-utility setting

For unit $i$ and regimes $j = 1, \dots, J$ ($J \ge 3$; the software's labels
are the levels of the selection variable or the names of the `outcomes`
list):

$$V_{ij} = z_i'\gamma_j + u_{ij}, \qquad S_i = \arg\max_j V_{ij}, \qquad y_{ji} = x_{ji}'\beta_j + \varepsilon_{ji} \text{ observed iff } S_i = j.$$

- **Base alternative.** Only utility differences matter, so
  $\gamma_b = 0$ for a base alternative $b$: by default the first level of
  the selection variable (regime 0 in the binary case), or
  `base = "<label>"`.
- **Regressors.** $z_i$ is common to all alternatives by default
  (specification section 6.3). A coefficient can be excluded from one
  alternative's utility by giving `selection` as a named list of formulas,
  one per non-base alternative.
- **Outcome regressors** $x_{ji}$ are observed for every unit, whatever its
  regime, as in G1. This is what makes counterfactuals computable.
- Write $v_{ij} = z_i'\gamma_j$ and $P_{ij} = \Pr(S_i = j \mid z_i)$.

## 2. Multinomial logit selection

$u_{ij}$ independent standard Gumbel, $G(u) = \exp(-e^{-u})$,
$E[u] = \gamma_E$ (Euler's constant), $\operatorname{Var}(u) = \pi^2/6$:

$$P_{ij} = \frac{e^{v_{ij}}}{\sum_k e^{v_{ik}}}.$$

First-step maximum likelihood (used by every two-step estimator and as
starting values): score $\sum_i(\mathbf 1\{S_i = k\} - P_{ik})\,z_i$ for
$\gamma_k$, Hessian blocks $-\sum_i P_{ik}(\mathbf 1\{k = l\} - P_{il})\,z_iz_i'$;
the log-likelihood is globally concave. The package tests compare it with
`nnet::multinom()` and `mlogit` (WP2.2).

The independence of irrelevant alternatives is part of this model. It is
relaxed by the nested logit (section 5) and the multinomial probit
(section 6).

## 3. Full-information model: Lee (1983)

### 3.1 The transformation (checks W10, W15)

For regime $j$ define the scalar index

$$\epsilon^*_{ij} = \max_{k \ne j}V_{ik} - u_{ij}, \qquad S_i = j \iff \epsilon^*_{ij} < v_{ij}.$$

Its distribution function is known from the choice model: it is the
probability of choosing $j$ when its systematic utility is $c$,

$$F_{ij}(c) = \Pr(\epsilon^*_{ij} < c \mid z_i) = P_j(v_{i,-j}, c) = \frac{e^{c}}{e^{c} + \sum_{k \ne j}e^{v_{ik}}} \quad \text{(multinomial logit)}.$$

Lee's transformation maps it to a standard normal variable. **Sign
convention (D6 applied to each regime):**

$$u^*_{ij} = -\Phi^{-1}\!\left(F_{ij}(\epsilon^*_{ij})\right) \sim N(0, 1), \qquad S_i = j \iff u^*_{ij} > -w_{ij}, \qquad w_{ij} = \Phi^{-1}(P_{ij}).$$

A large $u^*_{ij}$ means unobservables that favour regime $j$. W10 confirms
both statements on $10^6$ simulated draws: the event identity holds for
every draw, and $u^*_j$ has mean 0 and variance 1 (largest
$\lvert z\rvert = 1.74$).

**Assumption (Lee).** For each regime $j$, conditional on $z_i$,
$(u^*_{ij}, \varepsilon_{ji})$ is bivariate normal with correlation $\rho_j$
and $\operatorname{Var}(\varepsilon_{ji}) = \sigma_j^2$: a Gaussian copula
between the maximum-utility index of regime $j$ and its outcome
disturbance.

- $\rho_j > 0$: unobservables that favour regime $j$ raise the outcome in
  regime $j$.
- **This differs from the base-difference convention of the Gaussian
  models.** In a two-regime model, G1's $\rho_0$ is the correlation of
  $\varepsilon_0$ with the propensity for regime **1**; Lee's $\rho$ of the
  base regime is its correlation with the propensity for the **base**
  regime, so it has the opposite sign. The software prints the definition
  with the estimates.
- Lee's own paper states the correlation with $\Phi^{-1}(F(\epsilon^*))$,
  which is $-\rho_j$ here.

### 3.2 Likelihood (check W11)

Exactly as in G1 regime 1, with the index $w_{ij}$ in place of $z_i'\gamma$:

$$L_{ji} = \frac{1}{\sigma_j}\,\phi(e_{ji})\,\Phi\!\left(\frac{w_{ij} + \rho_j e_{ji}}{\sqrt{1 - \rho_j^2}}\right), \qquad e_{ji} = \frac{y_i - x_{ji}'\beta_j}{\sigma_j}, \qquad w_{ij} = \Phi^{-1}(P_{ij}).$$

$\int L_{ji}\,dy = \Phi(w_{ij}) = P_{ij}$, and these sum to 1 (W11a, 6e-17).
W11b simulates the model ($10^6$ draws; Gumbel utilities, then
$\varepsilon_j = \sigma_j(\rho_j u^*_j + \sqrt{1-\rho_j^2}\,\nu_j)$) and
confirms $\Pr(S = j, Y_j \le y) = \int_{-\infty}^y L_j$ for the three
regimes (largest $\lvert z\rvert = 1.42$).

Parameters: $\theta = (\gamma_2', \dots, \gamma_J', \beta_1', \dots, \beta_J', \sigma_1, \dots, \sigma_J, \rho_1, \dots, \rho_J)'$
(base alternative 1), working $\sigma_j = e^{\tau_j}$,
$\rho_j = \tanh\alpha_j$. $w_{ij}$ is computed as
`qnorm(log P, log.p = TRUE)`, which is stable for small probabilities.

With $J = 2$ this is a **logit**-selection model with a Gaussian copula. It
is not the G1 model (probit selection). It coincides with the Generation 3
copula ESR with a logistic selection margin, and is tested against it there.

### 3.3 Score and Hessian (check W16)

For an observation in regime $j$, with $s = \sinh\alpha_j$,
$c = \cosh\alpha_j$, $a = w c + e s$, $v = w s + e c$,
$\lambda = \lambda(a)$, $\delta = \delta(a)$, $\lambda_w = \lambda(w) = \phi(w)/P_j$:

$$\frac{\partial w}{\partial\gamma_k} = g_k\,z, \qquad g_k = \frac{\mathbf 1\{j = k\} - P_k}{\lambda_w}, \qquad
  \frac{\partial^2 w}{\partial\gamma_k\,\partial\gamma_l'} = h_{kl}\,zz',$$

$$h_{kl} = \frac{(\mathbf 1\{j=k\} - P_k)(\mathbf 1\{j=l\} - P_l) - P_k(\mathbf 1\{k=l\} - P_l)}{\lambda_w} + w\,g_kg_l.$$

**Score.** $\partial\log L/\partial\gamma_k = \lambda c\,g_k\,z$ for
$k = 2, \dots, J$. The components for $\beta_j$, $\tau_j$, $\alpha_j$ are
the G1 regime-1 expressions (LIKELIHOOD_DERIVATION.md section 5 with
$q = 1$).

**Hessian.** The $(\beta_j, \tau_j, \alpha_j)$ block is the G1 block with
$q = 1$. The blocks involving $\gamma$:

| Block | Contribution |
| --- | --- |
| $\gamma_k\gamma_l'$ | $\left(-\delta c^2 g_kg_l + \lambda c\,h_{kl}\right) zz'$ |
| $\gamma_k\beta_j'$ | $\delta c s\,g_k/\sigma\; zx'$ |
| $\gamma_k\tau_j$ | $\delta c s\,e\,g_k\; z$ |
| $\gamma_k\alpha_j$ | $(-\delta c v + \lambda s)\,g_k\; z$ |

Every regime contributes to every $\gamma_k$. The Hessian is fully analytic:
Newton-Raphson, the four covariance estimators and the tests of G1 apply
unchanged. W16: score and Hessian equal the numerical derivatives to 6.8e-9
and 8.8e-8.

**Test of selection on unobservables:** $H_0: \rho_1 = \dots = \rho_J = 0$,
likelihood ratio with $J$ degrees of freedom; the restricted log-likelihood
is the multinomial logit plus $J$ Gaussian regressions.

### 3.4 Lee's two-step estimator

1. Multinomial logit: $\hat\gamma$, $\hat V_\gamma$, $\hat w_{ij} = \Phi^{-1}(\hat P_{ij})$.
2. OLS of $y_i$ on $(x_{ji}', m_1(\hat w_{ij}))$ among $S_i = j$:
   $E[y \mid S = j] = x_j'\beta_j + \theta_j m_1(w_j)$, $\theta_j = \sigma_j\rho_j$.
3. $\hat\sigma_j^2 = \overline{\hat\eta_j^2} + \hat\theta_j^2\,\overline{\delta_1(\hat w_j)}$,
   $\hat\rho_j = \hat\theta_j/\hat\sigma_j$.
4. Corrected covariance: the G1 formula with the probit Jacobian replaced
   by the multinomial one. With $G_j$ the $n_j \times (J-1)k_z$ matrix of
   rows $\partial w_{ij}/\partial\gamma' = (g_2 z_i', \dots, g_J z_i')$ and
   $\Delta_j = \operatorname{diag}\{\delta_1(\hat w_{ij})\}$:

   $$\hat V(\hat b_j) = \hat\sigma_j^2 (W_j'W_j)^{-1}\left[W_j'(I - \hat\rho_j^2\Delta_j)W_j + \hat\rho_j^2 (W_j'\Delta_jG_j)\hat V_\gamma(G_j'\Delta_jW_j)\right](W_j'W_j)^{-1}.$$

Steps 2 and 3 hold because $(u^*_j, \varepsilon_j)$ is bivariate normal and
the regime is the event $u^*_j > -w_j$: the truncated moments are those of
G1 (V07, V08). The covariance of step 4 is the G1 algebra with a different
Jacobian; it is checked by Monte Carlo in WP2.2 before release.

These estimates start the FIML iterations.

### 3.5 Conditional expectations and the counterfactual assumption (checks W12, W15, W38b)

**Observed regime:** $E[\varepsilon_j \mid S = j] = \theta_j\,m_1(w_j)$.
This follows from Lee's assumption alone.

**Other regimes.** Lee's assumption fixes the joint law of
$(u^*_j, \varepsilon_j)$ only. $E[\varepsilon_j \mid S = k]$ for a specific
$k \ne j$ also needs how $\varepsilon_j$ relates to the rest of the utility
vector. **Assumption L-CI (for the gate):** $\varepsilon_j$ depends on the
utilities only through $u^*_j$, that is,
$\varepsilon_j = \sigma_j(\rho_j u^*_j + \sqrt{1-\rho_j^2}\,\nu_j)$ with
$\nu_j$ independent of $(u_1, \dots, u_J)$. Then

$$E[\varepsilon_j \mid S = k] = \theta_j\,E[u^*_j \mid S = k].$$

**A general identity.** For any random-utility model with choice
probabilities $P(\cdot)$, any $k \ne j$ and $c \ge v_j$:

$$\Pr(\epsilon^*_j \le c,\; S = k) = P_k(v) - P_k(v_{-j}, c).$$

(The event is that $k$ is best among the alternatives other than $j$, and
$u_j$ lies between $V_k - c$ and $V_k - v_j$; the two terms are the choice
probabilities of $k$ when alternative $j$ has systematic utility $v_j$ and
$c$.) W15 confirms it by simulation (largest $\lvert z\rvert = 1.81$).

**Multinomial logit.** Here $P_k(v_{-j}, c) = P_k(v)\,(1 - F_j(c))/(1 - P_j)$,
so given $S = k$ the variable $F_j(\epsilon^*_j)$ is uniform on $(P_j, 1)$
**for every $k \ne j$**. Hence

$$E[u^*_j \mid S = k] = m_0(w_j) = -\frac{\phi(w_j)}{1 - \Phi(w_j)} \quad \text{for all } k \ne j,$$

$$E[Y_j \mid S = k] = x_j'\beta_j + \theta_j\,m_0(w_j) \quad (k \ne j), \qquad E[Y_j \mid S = j] = x_j'\beta_j + \theta_j\,m_1(w_j).$$

Under the multinomial logit, the counterfactual mean of regime $j$'s outcome
is the same for the units of every other regime with the same covariates.
W12 confirms all nine conditional means by simulation (largest
$\lvert z\rvert = 2.09$); W38b confirms that the general quadrature formula
of section 5.3 returns $m_0(w_j)$ in the logit case (4e-10).

### 3.6 What Lee's model restricts

One parameter $\rho_j$ carries the whole dependence between
$\varepsilon_j$ and the $J - 1$ utility differences that decide regime $j$.
Schmertmann (1994) and Bourguignon, Fournier and Gurgand (2007) point out
that this constrains the signs and sizes of the underlying covariances, and
the latter report Monte Carlo evidence that Lee's correction can be biased
when the restriction fails while the Dubin-McFadden corrections are more
robust. The package states this in the documentation and offers the
corrections of section 4 and the multinomial probit as alternatives. Lee's
model is the only one of the logit-based specifications with a full
likelihood.

## 4. Two-step corrections of Dubin-McFadden and Bourguignon-Fournier-Gurgand

These are regression (moment) models. They assume only how the conditional
mean of $\varepsilon_j$ depends on the Gumbel utilities, so there is no
FIML counterpart.

### 4.1 Dubin and McFadden (1984) (check W13)

**Assumption (linearity).**
$E[\varepsilon_j \mid u_1, \dots, u_J] = \sigma_j\frac{\sqrt 6}{\pi}\sum_k r_{jk}\,(u_k - \gamma_E)$,
with $r_{jk} = \operatorname{Corr}(\varepsilon_j, u_k)$.

**Gumbel moments (W13, largest $\lvert z\rvert = 1.22$).**

$$E[u_j - \gamma_E \mid S = j] = -\log P_j, \qquad E[u_k - \gamma_E \mid S = j] = \frac{P_k\log P_k}{1 - P_k} \quad (k \ne j).$$

**Original Dubin-McFadden restriction** $\sum_k r_{jk} = 0$. Then, with
$a_{jk} = \sigma_j\frac{\sqrt 6}{\pi}r_{jk}$,

$$E[y \mid S = j] = x_j'\beta_j + \sum_{k \ne j} a_{jk}\left[\frac{P_k\log P_k}{1 - P_k} + \log P_j\right] \qquad (J - 1 \text{ terms}).$$

### 4.2 Bourguignon, Fournier and Gurgand (2007) (check W14)

**Variant 1 (no restriction on $\sum_k r_{jk}$).**

$$E[y \mid S = j] = x_j'\beta_j + a_{jj}\,(-\log P_j) + \sum_{k \ne j}a_{jk}\,\frac{P_k\log P_k}{1 - P_k} \qquad (J \text{ terms}).$$

**Variant 2 (normalised disturbances).** Let
$u^+_k = \Phi^{-1}(G(u_k))$, a standard normal variable, and assume
$E[\varepsilon_j \mid u] = \sigma_j\sum_k r^+_{jk}u^+_k$. With

$$m(P) = \int\Phi^{-1}\!\left(G(v - \log P)\right)g(v)\,dv, \qquad g(v) = e^{-v - e^{-v}},$$

$$E[u^+_j \mid S = j] = m(P_j), \qquad E[u^+_k \mid S = j] = \frac{m(P_k)\,P_k}{P_k - 1} \quad (k \ne j),$$

$$E[y \mid S = j] = x_j'\beta_j + a^+_{jj}\,m(P_j) + \sum_{k \ne j}a^+_{jk}\,\frac{m(P_k)P_k}{P_k - 1}, \qquad a^+_{jk} = \sigma_jr^+_{jk}.$$

$m(P)$ is a one-dimensional integral, computed by Gauss-Legendre quadrature
on a fixed grid. W14 confirms the nine moments by simulation (largest
$\lvert z\rvert = 1.36$).

### 4.3 Estimation and inference

| `correction =` | Model | Terms per regime |
| --- | --- | --- |
| `"lee"` | section 3.4 | 1 |
| `"dmf"` | Dubin-McFadden with $\sum_k r_{jk} = 0$ | $J - 1$ |
| `"bfg1"` | BFG variant 1 | $J$ |
| `"bfg2"` | BFG variant 2 | $J$ |

1. Multinomial logit; the correction terms at $\hat P_{ij}$.
2. OLS within each regime.
3. **Standard errors: the bootstrap** over both steps (plan, WP2.2),
   resampling units or clusters, `R = 999` by default; the failure share is
   reported. The stacked M-estimation sandwich (moments: multinomial-logit
   score and $S_{ij}W_{ji}\eta_{ji}$; Jacobian from the derivatives of the
   correction terms with respect to $\gamma$) is derived in the same way as
   in G1. It is offered only after the WP2.2 Monte Carlo shows that it
   agrees with the bootstrap; it is not verified here.
4. The residuals are heteroskedastic by construction, so plain OLS standard
   errors are never reported.

**What is reported.** $\beta_j$ and the correction coefficients $a_{jk}$
(or $a^+_{jk}$). $\sigma_j$ and the correlations are **not** reported for
these three corrections in G2: their recovery needs the conditional
variances of the Gumbel terms, which are not derived in this document.

**Collinearity.** The $J$ correction terms are smooth functions of the same
probabilities. The identification report gives their condition number and
the $R^2$ of each on $x_j$ and the others (the analogue of I6).

### 4.4 Conditional expectations under these corrections

Under the linearity assumption, for any $j$ and $k$:

$$E[\varepsilon_j \mid S = k] = a_{jk}\,(-\log P_k) + \sum_{l \ne k}a_{jl}\,\frac{P_l\log P_l}{1 - P_l},$$

and the analogue with $m(\cdot)$ for variant 2. All $a_{jl}$ come from the
regime-$j$ regression (with $a_{jj} = -\sum_{l \ne j}a_{jl}$ under the
Dubin-McFadden restriction), so the counterfactual means are identified
without a further assumption. Unlike Lee's model, they differ across the
conditioning regimes $k$.

## 5. Nested logit selection (WP2.4)

### 5.1 Model and consistency conditions (check W37a)

Alternatives are partitioned into nests $g$, with dissimilarity parameters
$\lambda_g$. With $I_g = \log\sum_{k \in g}e^{v_k/\lambda_g}$:

$$P_j = \frac{e^{v_j/\lambda_{g(j)}}}{e^{I_{g(j)}}}\cdot\frac{e^{\lambda_{g(j)}I_{g(j)}}}{\sum_h e^{\lambda_hI_h}}.$$

**Consistency with random-utility maximisation.** For
$0 < \lambda_g \le 1$ the model is a generalised extreme value model for all
covariate values (McFadden 1978): the disturbances of a nest have Gumbel
margins and correlation $1 - \lambda_g^2$. For $\lambda_g > 1$ it is
consistent only locally, on a data-dependent region (Börsch-Supan 1990).

**Proposed for the gate:**
- $\lambda_g = 1/(1 + e^{-c_g}) \in (0, 1)$ by parameterisation; values
  above 1 cannot occur and are not offered.
- A nest with one alternative has $\lambda_g = 1$ (fixed; not identified).
- $\lambda_g = 1$ for all nests is the multinomial logit (W37b). It is on
  the boundary of the parameter space, so the likelihood-ratio test of the
  multinomial logit against the nested logit uses the boundary (mixture
  chi-square) reference distribution, and a `lambda_boundary` flag
  ($\hat\lambda_g > 0.995$) is reported.
- The nesting structure is supplied by the user (`nests = list(...)`).

W37a simulates the nested logit from its random-utility representation
($u_j = \lambda_g(\xi_j + \log\varsigma_g)$, $\xi_j$ Gumbel, $\varsigma_g$
positive stable with index $\lambda_g$) and confirms the probabilities and
the Gumbel margin (largest $\lvert z\rvert = 2.56$).

### 5.2 Derivatives of the probabilities (check W37b)

With $P(k \mid g) = e^{v_k/\lambda_g - I_g}$ and $P(g) = \sum_{k \in g}P_k$:

$$\frac{\partial\log P_j}{\partial v_k} = \frac{\mathbf 1\{k = j\}}{\lambda_{g(j)}} + \mathbf 1\{k \in g(j)\}\,P(k \mid g(j))\,\frac{\lambda_{g(j)} - 1}{\lambda_{g(j)}} - P_k,$$

$$\frac{\partial\log P_j}{\partial\lambda_h} = \mathbf 1\{h = g(j)\}\left[-\frac{v_j}{\lambda_h^2} + I_h + (\lambda_h - 1)\frac{\partial I_h}{\partial\lambda_h}\right] - P(h)\left[I_h + \lambda_h\frac{\partial I_h}{\partial\lambda_h}\right], \qquad \frac{\partial I_h}{\partial\lambda_h} = -\sum_{k \in h}P(k \mid h)\frac{v_k}{\lambda_h^2}.$$

W37b: equal to numerical derivatives to 3e-11.

### 5.3 Outcome dependence: Lee's transformation (check W38a)

Lee's transformation needs only the choice probabilities, so the model of
section 3 applies with $P_j$ of section 5.1:

$$L_{ji} = \frac{1}{\sigma_j}\phi(e_{ji})\,\Phi\!\left(\frac{w_{ij} + \rho_je_{ji}}{\sqrt{1 - \rho_j^2}}\right), \qquad w_{ij} = \Phi^{-1}(P_{ij}), \qquad \frac{\partial w_{ij}}{\partial\vartheta} = \frac{1}{\lambda(w_{ij})}\frac{\partial\log P_{ij}}{\partial\vartheta}.$$

- **Score:** analytic, from section 5.2 and the G1 block.
- **Hessian:** the symmetrised central difference of the analytic score
  (GAUSSIAN_REGION_ENGINE.md section 5).
- **Two-step:** Lee's (section 3.4), with the nested-logit first step. The
  Dubin-McFadden and BFG corrections rest on independent Gumbel utilities
  and are **refused** with nested-logit selection.

**Counterfactual means under L-CI.** The uniformity result of section 3.5
does not hold for the nested logit. From the general identity there, with
$F_j(c) = P_j(v_{-j}, c)$:

$$E[u^*_j \mid S = k] = \frac{1}{P_k}\int_{v_j}^{\infty}-\Phi^{-1}\!\left(F_j(c)\right)\,d\!\left[-P_k(v_{-j}, c)\right],$$

a one-dimensional integral for each pair, by Gauss-Legendre quadrature.
W38a confirms it against the simulated nested logit for all six pairs
(largest $\lvert z\rvert = 1.74$). The counterfactual mean of regime $j$'s
outcome now depends on the conditioning regime $k$: units in the same nest
as $j$ differ from units outside it.

## 6. Multinomial probit selection (WP2.3)

### 6.1 Model

$(u_{i1}, \dots, u_{iJ}, \varepsilon_{1i}, \dots, \varepsilon_{Ji})$ jointly
normal. The model is the instance of
[GAUSSIAN_REGION_ENGINE.md](GAUSSIAN_REGION_ENGINE.md) with $d = J - 1$:

- **Latent vector:** differences against the base alternative $b$,
  $U^*_m = V_m - V_b$, $\tilde u_m = u_m - u_b$, for the $J - 1$ non-base
  alternatives $m$; $\tilde u \sim N(0, \Omega)$.
- **Regions:** regime $j$ iff $A_jU^* > 0$, where $A_b = -I$ and, for
  $j \ne b$, the rows of $A_j$ give $V_j - V_b = U^*_j$ and
  $V_j - V_m = U^*_j - U^*_m$ for $m \ne b, j$.
- **Outcome dependence:** $\psi_j = \operatorname{Corr}(\tilde u, \varepsilon_j) \in \mathbb R^{J-1}$:
  the correlations of the regime-$j$ outcome disturbance with **each
  utility difference against the base**, for every regime $j$ (the
  convention of the engine, section 1). With $J = 2$ these are G1's
  $\rho_1$ and $\rho_0$.

The contribution of an observation in regime $j$ is a $(J-1)$-dimensional
conditional orthant probability times the outcome density
(GAUSSIAN_REGION_ENGINE.md section 2).

### 6.2 Normalisation of the selection covariance (gate question)

Location and scale of utilities are not identified. The location is fixed by
differencing against the base. **Proposed scale normalisation:**
$\operatorname{Var}(\tilde u_1) = \Omega_{11} = 1$ for the first non-base
alternative. $\Omega$ then has $J(J-1)/2 - 1$ free elements.

| `selection_covariance =` | $\Omega$ | Free parameters |
| --- | --- | --- |
| `"independent"` (**proposed default**) | $u_j$ i.i.d. $N(0, \tfrac12)$: $\Omega = \tfrac12(I + \mathbf 1\mathbf 1')$ (unit variances, correlations $\tfrac12$) | 0 |
| `"unrestricted"` | $\Omega = DR_\Omega D$, $D_{11} = 1$ | $J(J-1)/2 - 1$ |

Why the default is the restricted one: with regressors common to all
alternatives, the free elements of $\Omega$ are identified only through the
functional form, and are known to be fragile in practice without
alternative-specific exclusions (Keane 1992). The unrestricted structure is
offered, with the identification check of section 8, and the two are
compared by a likelihood-ratio test (interior null).

`switchSelection::msel(type3 = "probit")` uses the same kind of
normalisation (one alternative's disturbance set to zero, the first variance
set to 1), with the **last** alternative as base.

### 6.3 Estimation

- Score, Hessian, covariance, optimisation: GAUSSIAN_REGION_ENGINE.md
  section 5. Probabilities: section 8 there (deterministic for $J \le 4$).
- Two-step: section 7 there, with $J - 1$ correction terms per regime (the
  truncated means of the utility differences).
- Tests: $H_0$: all $\psi_j = 0$, likelihood ratio with $J(J-1)$ degrees of
  freedom; the restricted model is the multinomial probit plus $J$
  regressions.

### 6.4 Conditional expectations

For all $j$, $k$: $E[Y_j \mid S = k] = x_j'\beta_j + \kappa_j'm_k(W)$
(GAUSSIAN_REGION_ENGINE.md section 6; W27a). No assumption beyond joint
normality is needed.

## 7. The logit and probit models side by side

| | MNL with Lee | MNL with DMF / BFG | Nested logit with Lee | MNP |
| --- | --- | --- | --- | --- |
| Selection disturbances | i.i.d. Gumbel | i.i.d. Gumbel | GEV, $\lambda_g \in (0, 1]$ | multivariate normal |
| Substitution pattern | IIA | IIA | IIA within nests only | unrestricted or independent |
| Link to the outcome of regime $j$ | Gaussian copula with one index $u^*_j$ | linear conditional mean in all $J$ utilities | Gaussian copula with $u^*_j$ | joint normality with all $J - 1$ differences |
| Dependence parameters per regime | 1 ($\rho_j$) | $J - 1$ or $J$ ($a_{jk}$) | 1 | $J - 1$ ($\psi_j$) |
| Estimators | FIML, two-step | two-step only | FIML, Lee two-step | FIML, two-step |
| Selection probability | closed form | closed form | closed form | $(J-1)$-dimensional integral |
| Counterfactual means $E[Y_j \mid S = k]$ | need L-CI; equal for all $k \ne j$ | from linearity; differ by $k$ | need L-CI; differ by $k$ | from joint normality; differ by $k$ |
| Nests G1 at $J = 2$ | no (logit) | no | no | **yes, exactly** |

The estimates of the dependence parameters are not comparable across the
columns: $\rho_j$ (Lee) is a correlation with regime $j$'s own index,
$\psi_j$ (probit) a vector of correlations with base differences, $a_{jk}$ a
scaled correlation with a Gumbel utility.

## 8. Identification (specification section 3.5)

| Parameter group | Identified by | Classification |
| --- | --- | --- |
| $\gamma_j$, $j \ne b$ | the choice model, base and scale normalisation, rank of $z$, no separation | structural |
| $\lambda_g$ (nested logit) | substitution patterns within the nest; with regressors common to all alternatives, through the functional form only | distributional / functional form |
| $\Omega$ free elements (MNP) | functional form unless a variable is excluded from some utilities | distributional / functional form; **weak** without exclusions (Keane 1992) |
| $\beta_j$, $\sigma_j$ | regime-$j$ data given the dependence parameters | structural |
| $\rho_j$ (Lee); $\psi_j$ (MNP); $a_{jk}$ (DMF, BFG) | variation of the regime-$j$ correction terms not explained by $x_j$ | by exclusion if the excluded variables move the correction terms in as many directions as there are terms; otherwise functional form |
| $\operatorname{Corr}(\varepsilon_j, \varepsilon_k)$, $j \ne k$ | nothing | **not identified** (GAUSSIAN_REGION_ENGINE.md section 11) |

**Minimum exclusion restrictions (gate question).** As in G1 (assumption
A7), none is *required*: the models are formally identified by their
distributional assumptions. The software **recommends and checks**:

1. At least one variable in the selection system that is excluded from the
   regime-$j$ outcome equation, for every regime (I4 per regime).
2. For models with several correction terms per regime (MNP, DMF, BFG):
   the matrix of selection coefficients of the excluded variables,
   $\Gamma_E$ ($(J-1) \times$ number of excluded variables), should have
   rank equal to the number of correction terms, $\min(J - 1, \cdot)$; a
   lower rank is reported as "identified in part through the functional
   form".
3. For `selection_covariance = "unrestricted"`: at least one coefficient
   excluded from one utility; otherwise a warning that $\Omega$ rests on the
   functional form.
4. The collinearity diagnostic I6 for every correction term.

The diagnostics I1-I11 of [IDENTIFICATION.md](IDENTIFICATION.md) section 8
state the multinomial versions.

## 9. Relation to existing R implementations

| Package | What it offers | Use |
| --- | --- | --- |
| `nnet::multinom`, `mlogit` | multinomial logit | first-step check (coefficients, log-likelihood) |
| `switchSelection::msel` 2.1.0 | multinomial selection with continuous outcomes by **two-step only**: the Dubin-McFadden correction terms of section 4.1 without the sum restriction for the logit (our `"bfg1"`), and a multinomial-probit two-step. The last alternative is its base. | benchmark for `"bfg1"` and for the MNP two-step; conventions to be established by simulation in WP2.2 and WP2.3 before any comparison |
| none found | FIML for the Lee model, the nested logit with outcomes, or the MNP-ESR | simulation-only validation, plus the nesting tests (BENCHMARK_PROTOCOL.md section 6) |

The statements about `msel` come from its help page (read 23 November
2026). Nothing has been run against it yet.

## 10. What is not verified

- The corrected covariance of Lee's two-step (section 3.4, step 4) and the
  stacked sandwich for the Dubin-McFadden and BFG corrections (section 4.3).
- The multinomial-logit first step against other packages (section 2).
- $\sigma_j$ and the correlations under the Dubin-McFadden and BFG
  corrections are not derived (section 4.3).
- Multinomial probit with $J \ge 4$: the checks use $J = 3$ (W21, W23,
  W27); the derivative formulas are checked for $d = 3$ rectangles (W20),
  and GHK for $d \le 4$ (W25).
- All `switchSelection` conventions (section 9).

## 11. Normal-score model: a less restrictive full-likelihood alternative to Lee (gate amendment, 23 November 2026)

Added after the owner's decision on gate question 3 ("if you can find a
better (less restrictive) option we can use ... otherwise, I accept Lee's
transformation"). Checks "X.." are in `verify_math_g2b.R`. Lee's model
(section 3) stays in the package; this model is offered beside it.

### 11.1 Model

Selection is the multinomial logit of section 2: $U_k = v_k + \varepsilon^*_k$
with $\varepsilon^*_k$ i.i.d. Gumbel, cdf $G$. Define the **normal scores**

$$\eta_k = \Phi^{-1}\!\left(G(\varepsilon^*_k)\right), \qquad k = 1, \dots, J,$$

which are i.i.d. $N(0, 1)$. For each regime $j$ the standardised outcome
disturbance $u_j = \varepsilon_j / \sigma_j$ is **jointly normal with all
$J$ scores**:

$$u_j = \sum_{k=1}^J r_{jk}\,\eta_k + \sqrt{1 - \textstyle\sum_k r_{jk}^2}\;\nu_j, \qquad \nu_j \sim N(0,1) \text{ independent of } \eta,$$

with $r_{jk} = \operatorname{Corr}(u_j, \eta_k)$ and $\sum_k r_{jk}^2 < 1$.
There are $J$ dependence parameters per regime instead of Lee's one.

This is the assumption of the normalised correction of Bourguignon,
Fournier and Gurgand (section 4.2: a conditional mean linear in the normal
scores), strengthened to joint normality so that a likelihood exists. Their
two-step estimator `"bfg2"` is therefore the limited-information estimator
of this model.

### 11.2 Selection event in the scores (check X10)

$S = k$ if and only if $\eta_m < h_{m|k}(\eta_k)$ for every $m \ne k$, with

$$h_{m|k}(t) = \Phi^{-1}\!\left(\Phi(t)^{a_{mk}}\right), \qquad a_{mk} = e^{v_m - v_k},$$

because $G(G^{-1}(p) + d) = p^{\exp(-d)}$. It is computed on the log scale
as `qnorm(a * pnorm(t, log.p = TRUE), log.p = TRUE)`.

### 11.3 Likelihood (checks X11, X13, X14)

For an observation in regime $j$ with $e = (y - x'\beta_j)/\sigma_j$ and
$r = (r_{j1}, \dots, r_{jJ})$:

$$L = \frac{1}{\sigma_j}\,\phi(e)\int \phi\!\left(t;\, r_j e,\, 1 - r_j^2\right)\,\Phi_{J-1}\!\left(h_{\cdot|j}(t) - \mu(t, e);\ \Sigma_c\right)dt,$$

where $r_j$ is short for $r_{jj}$, $r_{-j}$ collects the other $J - 1$
correlations, and, given $(\eta_j = t, u_j = e)$, the other scores are
normal with

$$\mu(t, e) = r_{-j}\,\frac{e - r_j t}{1 - r_j^2}, \qquad \Sigma_c = I - \frac{r_{-j}r_{-j}'}{1 - r_j^2}.$$

The contribution integrates over $y$ to the multinomial-logit probability
$P_j$ (X11a: 6e-16 for $J = 3$; X13 for $J = 2$; X14a: 1.4e-7 for $J = 8$)
and reproduces the simulated joint law of $(S, Y_j)$ (X11b, X14b).

Computation: a Gauss-Hermite rule over $t$ and a $(J - 1)$-dimensional
normal rectangle probability with a covariance that does not depend on the
observation. This is the probability routine of the Gaussian region engine
(GAUSSIAN_REGION_ENGINE.md section 5): deterministic for $J \le 4$, GHK
beyond. With $r_{-j} = 0$ the rectangle factorises and the likelihood is a
one-dimensional integral for any $J$.

### 11.4 Conditional expectations: no additional assumption (check X12)

The joint law of $\varepsilon_j$ and all utilities is specified, so every
counterfactual mean is defined by the model itself:

$$E[\varepsilon_j \mid S = k] = \sigma_j\sum_m r_{jm}\,E[\eta_m \mid S = k], \qquad E[\eta_k \mid S = k] = m(P_k),\quad E[\eta_m \mid S = k] = \frac{m(P_m)P_m}{P_m - 1},$$

with $m(\cdot)$ of section 4.2 (check W14). These means differ across the
regimes $k$ (X12c), unlike Lee's under L-CI. Agreement of the formula with
the likelihood contribution: 1.6e-14 (X12a); with simulation: X12b, and
X14c for $J = 8$.

### 11.5 Comparison with Lee's model

| | Lee (section 3) | Normal-score model |
| --- | --- | --- |
| Selection | multinomial logit | multinomial logit |
| Dependence parameters per regime | 1 | $J$ (restrictions available: own score only; a common value for the other alternatives) |
| Counterfactual means for $k \ne j$ | need assumption L-CI; equal across $k$ | from the model; differ across $k$ |
| Sign pattern of the implied correlations with the other utilities | restricted (section 3.6) | free |
| Likelihood | closed form | one-dimensional quadrature of a $(J-1)$-dimensional normal probability |
| Matching two-step estimator | `"lee"` | `"bfg2"` |
| Nests the other | no | no (compared by information criteria and a Vuong test) |

Both keep the independence of irrelevant alternatives of the logit; the
multinomial probit (section 6) is the model that relaxes it.

### 11.6 Identification

As for the Dubin-McFadden and BFG corrections without the sum restriction:
the $J$ correlations of a regime are identified through $J$ different
functions of the choice probabilities, so diagnostics I4b applies
(exclusions must move the probabilities in enough directions). With
$J = 2$ the two correlations are identified through the functional form
only; the software warns and recommends the restricted version.

### 11.7 Status and limits

- **Verified:** the event identity, the likelihood as a proper density, the
  joint law and all conditional means, for $J = 2, 3, 8$ (X10-X14).
- **Not verified:** the analytic score (not derived yet; it uses the same
  Plackett derivatives as the region engine plus the derivative of
  $h_{m|k}$); estimation behaviour (no estimator exists; Monte Carlo design
  G, MONTE_CARLO_DESIGN.md section 8.6); the accuracy needed from the
  Gauss-Hermite rule in estimation.
- **Novelty not established.** The searches run on 23 November 2026 found
  no earlier statement of this full-likelihood model, but they were not a
  systematic review. The manuscript must not claim it as new before a
  proper literature search.
