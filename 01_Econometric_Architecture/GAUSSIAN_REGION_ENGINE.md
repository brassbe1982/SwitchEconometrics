# The Gaussian selection-region engine (Generation 2)

Status: **draft for the G2 econometric gate** (23 November 2026). No code
exists for it yet. Specification sections 3.1-3.3, 4 (Family B) and 5.4-5.6.
Checks W20-W29, W32b, W34-W36 in [verify_math_g2.R](verify_math_g2.R).

Multinomial probit, ordered, sequential and multivariate selection with
Gaussian outcomes are one model: a Gaussian latent selection vector, a
regime defined by a rectangle in a linear transform of that vector, and
Gaussian outcome disturbances correlated with it. This document derives that
model once. The mechanism documents
([MULTINOMIAL_ESR.md](MULTINOMIAL_ESR.md) section 6,
[ORDERED_SEQUENTIAL.md](ORDERED_SEQUENTIAL.md),
[MULTIVARIATE_SELECTION.md](MULTIVARIATE_SELECTION.md)) then only state
their instance. Multinomial **logit** selection is not an instance: its
selection disturbances are not Gaussian (MULTINOMIAL_ESR.md sections 2-5).

## 1. Model

**Latent selection vector.** $U_i^* = W_i + \tilde u_i \in \mathbb R^d$, with
index vector $W_i = (z_{i1}'\gamma_1, \dots, z_{id}'\gamma_d)'$ and
$\tilde u_i \sim N_d(0, \Omega)$.

**Regimes.** Regime $j \in \{1, \dots, J\}$ occurs if and only if

$$l_j < A_j U_i^* \le h_j,$$

with a known invertible $d \times d$ matrix $A_j$ and limits
$l_j, h_j \in (\mathbb R \cup \{\pm\infty\})^d$ that may contain threshold
parameters. The regions of the $J$ regimes partition $\mathbb R^d$.

**Outcomes.** $y_{ji} = x_{ji}'\beta_j + \varepsilon_{ji}$, observed only in
regime $j$ (one outcome per regime here; several in section 10).

**Joint normality (assumption G-A3).** For each regime $j$,

$$\begin{pmatrix} \tilde u_i \\ \varepsilon_{ji} \end{pmatrix} \sim N\!\left(0, \begin{pmatrix} \Omega & \sigma_j D\psi_j \\ \sigma_j\psi_j'D & \sigma_j^2 \end{pmatrix}\right), \qquad \Omega = D\,R_\Omega\,D,$$

where $D$ is the diagonal matrix of the standard deviations of $\tilde u$,
$R_\Omega$ its correlation matrix, and
$\psi_j = \operatorname{Corr}(\tilde u, \varepsilon_j) \in \mathbb R^d$.

**Sign convention (D6 extended).** $\psi_{jm}$ is the correlation between
the outcome disturbance of regime $j$ and the $m$-th component of the latent
selection vector **as defined for the model** (for example the utility
difference against the base alternative), for every regime. It is not
re-signed by regime. With $d = 1$ this is $\rho_j = \operatorname{Corr}(u, \varepsilon_j)$
of G1.

Assumptions A1, A2, A5, A6 and A8 of [BINARY_ESR.md](BINARY_ESR.md) carry
over with the obvious changes. The dependence between outcome disturbances
of different regimes is not part of the model (section 11).

## 2. Likelihood (check W21)

Conditional on $\varepsilon_{ji} = \sigma_j e$,

$$\tilde u \mid e \sim N\!\left(D\psi_j\,e,\; D\,(R_\Omega - \psi_j\psi_j')\,D\right).$$

Let $X = A_j(W + \tilde u)$. Then $X \mid e \sim N(\mu_{j}(e), \Sigma_j)$ with

$$\mu_j(e) = A_j\,(W + D\psi_j\,e), \qquad \Sigma_j = A_j D\,(R_\Omega - \psi_j\psi_j')\,D A_j'.$$

The contribution of an observation in regime $j$ is the outcome density
times the **conditional** probability of the regime (specification section
3.3):

$$L_{ji} = \frac{1}{\sigma_j}\,\phi(e_{ji})\;\Pr\!\left(l_j < X \le h_j \mid e_{ji}\right), \qquad e_{ji} = \frac{y_i - x_{ji}'\beta_j}{\sigma_j}.$$

With $s_k = \sqrt{\Sigma_{j,kk}}$, standardised limits
$\tilde l_k = (l_{jk} - \mu_{jk})/s_k$, $\tilde h_k = (h_{jk} - \mu_{jk})/s_k$
and the correlation matrix $R_j$ of $\Sigma_j$, the probability is a
standard normal rectangle probability $\Pi_d(\tilde l, \tilde h; R_j)$.

**Proper density.** $\int L_{ji}\,dy = \Pr(l_j < A_j(W + \tilde u) \le h_j)$,
and these sum to 1 over $j$. W21 confirms, for the multinomial probit with
$J = 3$, that $\int_{-\infty}^{y} L_{ji}$ equals the trivariate normal
probability of $\{S = j, Y_j \le y\}$ to 1e-16.

## 3. Parameterisation (check W24)

Every working vector maps to a valid model (specification section 5.6;
[PARAMETERIZATION.md](PARAMETERIZATION.md) section 6).

- **Selection correlation matrix.** $R_\Omega = \mathcal W'\mathcal W$, with
  $\mathcal W$ the upper-triangular factor built from $d(d-1)/2$ canonical
  partial correlations $\tanh(\alpha^u)$ (the map `se_corr_from_cpc()` of
  G1).
- **Selection scales.** $D = \operatorname{diag}(e^{\tau^u_1}, \dots, e^{\tau^u_d})$,
  with the elements fixed by the model's scale normalisation set to 1
  (section 9).
- **Outcome correlations.** For regime $j$, $d$ working values $\alpha^{(j)}$
  give one further Cholesky column
  $\ell_{j,m} = \tanh(\alpha^{(j)}_m)\sqrt{1 - \sum_{k<m}\ell_{j,k}^2}$, and

  $$\psi_j = \mathcal W'\ell_j.$$

  $\tanh(\alpha^{(j)}_m)$ is the partial correlation of $\varepsilon_j$ with
  $\tilde u_m$ given $\tilde u_1, \dots, \tilde u_{m-1}$. The
  $(d+1) \times (d+1)$ correlation matrix of $(\tilde u, \varepsilon_j)$ is
  positive definite for every working vector, and **all regimes share the
  same $R_\Omega$ block by construction** (W24: 200 random working vectors
  of the $J = 3$ multinomial probit, 600 matrices, smallest eigenvalue
  positive).
- **Outcome scales.** $\sigma_j = e^{\tau_j}$.
- With $d = 1$: $\psi_j = \tanh\alpha^{(j)}$, the G1 parameterisation.

Natural parameters reported: $\gamma$, thresholds, $\beta_j$, $\sigma_j$,
the elements of $\psi_j$, and the free standard deviations and correlations
of $\Omega$. Their covariance follows from the delta method with the
Jacobian of the map, computed by complex-step differentiation, which is
exact to rounding because the map is analytic (as `se_corr_jacobian()` in
G1).

## 4. Rectangle probabilities and their derivatives (check W20)

For $X \sim N_d(0, R)$ with correlation matrix $R$ and
$\Pi = \Pr(l < X \le h)$:

$$\frac{\partial\Pi}{\partial h_k} = \phi(h_k)\,\Pr\!\left(l_{-k} < X_{-k} \le h_{-k} \mid X_k = h_k\right), \qquad
  \frac{\partial\Pi}{\partial l_k} = -\phi(l_k)\,\Pr\!\left(l_{-k} < X_{-k} \le h_{-k} \mid X_k = l_k\right),$$

$$\frac{\partial\Pi}{\partial r_{km}} = \sum_{a \in \{l_k, h_k\}}\sum_{b \in \{l_m, h_m\}} \varsigma_a\varsigma_b\;\phi_2(a, b; r_{km})\;\Pr\!\left(\text{rest in its rectangle} \mid X_k = a, X_m = b\right),$$

with $\varsigma = +1$ for an upper and $-1$ for a lower limit, and infinite
limits contributing zero. The first two follow by differentiating the
integral; the third from Plackett's (1954) identity
$\partial\phi_d/\partial r_{km} = \partial^2\phi_d/\partial x_k\partial x_m$.
The conditional probabilities are normal rectangle probabilities of
dimension $d - 1$ and $d - 2$ with the usual conditional mean and
covariance. For $d = 2$ every derivative is in closed form ($\phi$, $\Phi$,
$\phi_2$); for $d = 3$ the derivatives need at most the bivariate normal
cdf.

W20 compares these with numerical derivatives for $d = 2, 3$ and finite,
semi-infinite and mixed limits: largest relative difference 1.9e-11.

## 5. Score, Hessian and covariance (checks W22b, W23, W34b, W35b)

**Score (analytic).**

$$\frac{\partial\log L_{ji}}{\partial\vartheta} = \frac{\partial}{\partial\vartheta}\left[-\tau_j - \tfrac12 e_{ji}^2\right] + \frac{1}{\Pi}\left[\sum_k \frac{\partial\Pi}{\partial\tilde h_k}\frac{\partial\tilde h_k}{\partial\vartheta} + \sum_k \frac{\partial\Pi}{\partial\tilde l_k}\frac{\partial\tilde l_k}{\partial\vartheta} + \sum_{k<m}\frac{\partial\Pi}{\partial r_{km}}\frac{\partial r_{km}}{\partial\vartheta}\right].$$

The derivatives of $\Pi$ are those of section 4. The derivatives of
$(\tilde l, \tilde h, R_j)$ with respect to $\vartheta$ are derivatives of
the algebraic map of sections 2 and 3 ($\tanh$, $\exp$, square roots and
matrix products). They are obtained by the chain rule, with the map's
Jacobian either coded in closed form or computed by complex-step
differentiation; both are exact to rounding, and the tests compare them.

Evidence: with $J = 2$ the engine score equals the G1 analytic score to
1e-15 (W22b); for the multinomial probit ($J = 3$), sequential ($J = 3$) and
bivariate selection models it equals the numerical gradient to 3.2e-9 (W23,
W34b, W35b).

**Hessian.** An analytic Hessian would need the second derivatives of
$\Pi$ (rectangle probabilities of dimension $d - 3$ and $d - 4$ and a long
chain rule). **Proposed for the gate:** for the region models the Hessian is
the symmetrised central difference of the analytic score,

$$\hat H_{\cdot k} = \frac{g(\hat\vartheta + \epsilon_k e_k) - g(\hat\vartheta - \epsilon_k e_k)}{2\epsilon_k}, \qquad \epsilon_k = 10^{-5}\max(1, \lvert\hat\vartheta_k\rvert), \qquad \hat H \leftarrow \tfrac12(\hat H + \hat H'),$$

computed once at the optimum. It is valid only where the probabilities are
evaluated deterministically (section 8). Models with $d = 1$ (ordered
selection) keep a fully analytic Hessian (ORDERED_SEQUENTIAL.md section 1).

Evidence (W29): for the multinomial probit with $J = 3$ (24 parameters, 25
observations) this matrix equals the numerical Hessian of the
log-likelihood to 4.3e-9 (relative, tolerance 1e-5).

**Optimisation.** BFGS with the analytic score (`maxLik::maxBFGS`), then
BHHH, started from the two-step estimates (section 7). Newton-Raphson with
the differenced Hessian is an option, not the default.

**Covariance.** As in G1 (LIKELIHOOD_DERIVATION.md section 7): observed
information from $\hat H$ (default), OPG, sandwich and cluster sandwich from
the per-observation analytic scores. For simulated likelihoods (GHK, section
8) the default is the **sandwich**, because the differenced Hessian of a
simulated likelihood carries simulation noise; this is stated in the output.

## 6. Truncated moments (checks W26, W27)

For $X \sim N_d(0, \Sigma)$ with standard deviations $s_k$, correlation
matrix $R$ and $\Pi = \Pr(l < X \le h)$:

$$E[X \mid l < X \le h] = \frac{1}{\Pi}\,\Sigma\,F, \qquad F_k = \frac{1}{s_k}\left[\phi(\tilde l_k)\,\Pi_{-k}(\tilde l_k) - \phi(\tilde h_k)\,\Pi_{-k}(\tilde h_k)\right] = -\frac{1}{s_k}\left(\frac{\partial\Pi}{\partial\tilde l_k} + \frac{\partial\Pi}{\partial\tilde h_k}\right),$$

with $\Pi_{-k}(c)$ the conditional rectangle probability of section 4
(Tallis 1961 for orthants; the rectangle form is the same argument). With
$d = 1$ and the region $u > -w$ this is $m_1(w) = \phi(w)/\Phi(w)$.

**Selection-correction vectors.** For regime $k$, with
$X = A_k\tilde u \sim N(0, A_k\Omega A_k')$ and limits $l_k - A_kW$,
$h_k - A_kW$:

$$t_k(W) = E[\tilde u \mid S = k] = A_k^{-1}\,E[X \mid \text{rectangle}], \qquad m_k(W) = D^{-1}t_k(W).$$

**Conditional expectations of outcome disturbances.** From
$E[\varepsilon_j \mid \tilde u] = \sigma_j\,\psi_j'R_\Omega^{-1}D^{-1}\tilde u$:

$$E[\varepsilon_j \mid S = k] = \kappa_j'\,m_k(W), \qquad \kappa_j = \sigma_j\,R_\Omega^{-1}\psi_j \in \mathbb R^d.$$

This holds for every pair $(j, k)$, including counterfactual ones
($k \ne j$): the joint normality of $(\tilde u, \varepsilon_j)$ determines
it. No further assumption is needed. With $d = 1$, $\kappa_j = \sigma_j\rho_j = \theta_j$.

**Adding up.** $\sum_k \Pr(S = k)\,t_k(W) = 0$ (W27b, to 6e-17).

**Truncated covariance.** For $v \sim N(\mu, \Sigma)$ truncated to a fixed
region, $\partial E[v \mid \text{region}]/\partial\mu' = \operatorname{Var}(v \mid \text{region})\,\Sigma^{-1}$
(an exponential-family identity). Hence

$$\operatorname{Var}(\tilde u \mid S = k) = \left(I + \frac{\partial t_k(W)}{\partial W'}\right)\Omega.$$

With $d = 1$ this is $1 - \delta_k(w)$. The Jacobian $\partial t_k/\partial W'$
is also what the two-step covariance needs. It is computed by central
differences of the closed-form $t_k$ (W26b: equal to the truncated
covariance by direct integration to 4e-12).

Evidence: W26a (truncated means, $d = 2$, against one-dimensional
integration: 6e-16); W27a (all nine $E[\varepsilon_j \mid S = k]$ of the
multinomial probit against simulation, largest $\lvert z\rvert = 1.26$).

## 7. Two-step estimator

1. **First step.** Maximum likelihood for the selection system alone: the
   engine of sections 2-5 with no outcome part ($L_i = \Pr(S_i = j)$),
   giving $\hat\gamma$, the thresholds, $\hat\Omega$ and their covariance.
2. **Second step.** For each regime $j$, OLS of $y_i$ on
   $(x_{ji}', \hat m_j(\hat W_i)')$ among $S_i = j$:

   $$E[y_i \mid S_i = j, x, z] = x_{ji}'\beta_j + \kappa_j'\,m_j(W_i).$$

   There are $d$ correction terms per regime.
3. **Variance recovery.** From
   $\operatorname{Var}(\varepsilon_j \mid S = j, W) = \sigma_j^2 - \kappa_j'\left[R_\Omega - V_j(W)\right]\kappa_j$
   with $V_j(W) = \operatorname{Var}(D^{-1}\tilde u \mid S = j)$:

   $$\hat\sigma_j^2 = \frac{1}{n_j}\sum_{S_i = j}\hat\eta_{ji}^2 + \hat\kappa_j'\left[\hat R_\Omega - \frac{1}{n_j}\sum_{S_i = j}\hat V_j(\hat W_i)\right]\hat\kappa_j, \qquad \hat\psi_j = \hat R_\Omega\hat\kappa_j/\hat\sigma_j.$$

   With $d = 1$ this is the Heckman (1979) estimator of G1.
4. **Covariance.** The stacked M-estimation sandwich of G1
   (LIKELIHOOD_DERIVATION.md section 9), with moments (first-step score,
   $S_{ij}W_{ji}\eta_{ji}$) and the Jacobian block
   $\sum_{S_i = j}W_{ji}\,\kappa_j'\,\partial m_j/\partial(\text{first-step parameters})'$.
   The bootstrap is the alternative.

The two-step estimates are the starting values of FIML. $\hat\psi_j$ is
moved inside the admissible set (shrunk so that
$\hat\psi_j'\hat R_\Omega^{-1}\hat\psi_j \le 0.9$) only for that purpose,
as $\hat\rho_j$ was truncated in G1.

**Not verified here:**
- The stacked covariance of step 4 for $d \ge 2$. It is the same
  M-estimation algebra as G1, but it is checked by Monte Carlo in its work
  package before it is offered; until then two-step standard errors for
  $d \ge 2$ come from the bootstrap.
- The variance recovery of step 3 for $d \ge 2$ as an estimator. Its
  ingredients are verified (the truncated covariance, W26b; the case
  $d = 1$, V08 of G1); its finite-sample behaviour is part of the G2 Monte
  Carlo study.

## 8. Evaluating the probabilities (check W25)

| Dimension $d$ of the rectangle | Method | Use |
| --- | --- | --- |
| 1 | `pnorm` differences in log space | ordered selection; binary |
| 2, 3 | deterministic: bivariate and trivariate normal cdf (Genz 2004), rectangles by inclusion-exclusion over the corners | default for $J \le 4$ multinomial probit, two or three selection equations, up to three sequential stages |
| $\ge 4$ | **GHK** (Geweke 1991; Hajivassiliou and McFadden 1998; Keane 1994) on Halton draws for estimation; Genz-Bretz (`mvtnorm::pmvnorm`, fixed seed) to report the log-likelihood at the optimum with its error estimate | experimental until its own Monte Carlo study |

**GHK.** With $\Sigma = LL'$ (lower Cholesky factor) and uniforms
$\nu_{rk}$, $r = 1, \dots, R$: for $k = 1, \dots, d$,

$$a_k = \Phi\!\left(\frac{l_k - \sum_{m<k}L_{km}\eta_m}{L_{kk}}\right), \quad b_k = \Phi\!\left(\frac{h_k - \sum_{m<k}L_{km}\eta_m}{L_{kk}}\right), \quad \eta_k = \Phi^{-1}\!\left(a_k + \nu_{rk}(b_k - a_k)\right),$$

and $\hat\Pi = R^{-1}\sum_r\prod_k(b_k - a_k)$. It is unbiased, strictly
positive and smooth in the parameters for fixed draws.

- **Draws.** Halton sequences with the first $d$ primes as bases, the first
  20 points discarded; observation $i$ uses points
  $20 + (i-1)R + 1, \dots, 20 + iR$. The draws are a deterministic function
  of $(n, d, R)$: no random numbers are used, so results do not depend on a
  seed. $R$ is `switch_control(draws = 500)`.
- **Accuracy found** (W25; 18 random rectangles and orthants,
  $d = 2, 3, 4$): largest absolute error of the probability 5.5e-4 with 500
  draws and 1.7e-4 with 2000 draws. This is a small sample of regions; the
  effect of $R$ on the estimates is studied in WP2.3 before a default is
  fixed for $d \ge 4$.
- The simulated maximum-likelihood estimator is consistent only as
  $R \to \infty$ with $n$; the fit records $R$, and
  `switch_diagnostics()` reports the change in the estimates when $R$ is
  doubled, on request.

## 9. Instances and nesting (checks W22, W32b)

| Mechanism | $d$ | $U^*$ | $A_j$, limits | Scale normalisation | Free dependence parameters |
| --- | --- | --- | --- | --- | --- |
| Binary probit (G1) | 1 | $z'\gamma + u$ | regime 1: $(0, \infty)$; regime 0: $(-\infty, 0]$ | $\operatorname{Var}(u) = 1$ | $\rho_1, \rho_0$ |
| Multinomial probit | $J - 1$ | utility differences against the base alternative | $A_j$ maps base differences to differences against alternative $j$; orthant $(0, \infty)^{J-1}$ | $\operatorname{Var}(\tilde u_1) = 1$ | $J(J-1)/2 - 1$ in $\Omega$; $J - 1$ per regime |
| Ordered probit | 1 | $z'\gamma + u$ | $(\mu_{j-1}, \mu_j]$ | $\operatorname{Var}(u) = 1$, $\mu_1 = 0$ | $\rho_j$ per regime |
| Sequential probit | $J - 1$ | one index per stage | $A_j = I$; pass: $(0, \infty)$; stop: $(-\infty, 0]$; later stages: $(-\infty, \infty)$ | unit variances | stage correlations; $\min(j, J-1)$ per regime |
| Multivariate probit | $M$ | one index per selection equation | $A_j = I$; $(0, \infty)$ or $(-\infty, 0]$ per equation | unit variances | $M(M-1)/2$; $M$ per regime |

**Exact nesting of G1.** With $d = 1$, $A_1 = 1$, $A_0 = -1$ and limits
$(0, \infty)$, $\Sigma_j = 1 - \rho_j^2$ and
$L_{ji} = \sigma_j^{-1}\phi(e)\,\Phi\!\left(q_j(w + \rho_j e)/\sqrt{1 - \rho_j^2}\right)$:
the G1 contribution. W22a: the engine log-likelihood with $J = 2$ equals the
G1 reference per observation to 1.8e-15. This is G2 acceptance criterion 2.

## 10. Several outcomes per regime (check W36)

With $K$ Gaussian outcomes in regime $j$,
$\varepsilon_j \sim N_K(0, \Sigma^\varepsilon_j)$ and
$C_j = \operatorname{Cov}(\tilde u, \varepsilon_j)$ ($d \times K$):

$$L_{ji} = \phi_K(\varepsilon_{ji}; \Sigma^\varepsilon_j)\;\Pr\!\left(l_j < A_j(W + \tilde u) \le h_j \mid \varepsilon_{ji}\right), \qquad \tilde u \mid \varepsilon_j \sim N\!\left(C_j(\Sigma^\varepsilon_j)^{-1}\varepsilon_j,\; \Omega - C_j(\Sigma^\varepsilon_j)^{-1}C_j'\right).$$

The parameterisation of section 3 adds $K$ Cholesky columns per regime
instead of one. Details: [MULTIVARIATE_SELECTION.md](MULTIVARIATE_SELECTION.md)
section 4.

## 11. Cross-regime dependence (check W28)

$\operatorname{Corr}(\varepsilon_j, \varepsilon_k)$ for $j \ne k$ never
enters the likelihood: two regimes are never observed together
([IDENTIFICATION.md](IDENTIFICATION.md) section 3; plan decision D8). For
$J \ge 3$ there are $J(J-1)/2$ such correlations.

**Admissible set.** Write $\omega_j^2 = \psi_j'R_\Omega^{-1}\psi_j < 1$.
Every admissible joint correlation matrix of
$(\tilde u, \varepsilon_1, \dots, \varepsilon_J)$ has

$$\operatorname{Corr}(\varepsilon_j, \varepsilon_k) = \psi_j'R_\Omega^{-1}\psi_k + \sqrt{(1 - \omega_j^2)(1 - \omega_k^2)}\;\pi_{jk},$$

where $(\pi_{jk})$ is the partial correlation matrix of the outcome
disturbances given $\tilde u$ and may be **any** $J \times J$ correlation
matrix.

- **Reference completion:** $\pi_{jk} = 0$ (conditional independence given
  the selection disturbances), i.e.
  $\operatorname{Corr}(\varepsilon_j, \varepsilon_k) = \psi_j'R_\Omega^{-1}\psi_k$.
  It is always admissible and reduces to $r_{10} = \rho_1\rho_0$ of G1.
- **Pairwise bounds:** $\pi_{jk} \in [-1, 1]$ gives an interval for each
  pair. Each end point is attained by a valid (singular) joint distribution
  (W28), so each interval is sharp for its pair. The intervals are **not
  jointly attainable** in general, because $(\pi_{jk})$ must be positive
  semi-definite.
