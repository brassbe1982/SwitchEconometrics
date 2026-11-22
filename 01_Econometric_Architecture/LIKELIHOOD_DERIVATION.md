# Likelihood, score, Hessian and two-step estimator of the binary ESR

Status: draft for the G1 econometric gate (WP1.1, 22 November 2026).
Model, assumptions and sign convention: [BINARY_ESR.md](BINARY_ESR.md).
Numerical checks: [verify_math.R](verify_math.R). Section numbers match the
`doc` column of `verify_math_results.csv`.

Notation: $\phi$ and $\Phi$ are the standard normal density and cdf;
$w_i = z_i'\gamma$; for regime $j \in \{0, 1\}$,
$e_{ji} = (y_i - x_{ji}'\beta_j)/\sigma_j$ and $r_j = \sqrt{1 - \rho_j^2}$;
$q_1 = +1$, $q_0 = -1$.

## 1. Strategy

The contribution of unit $i$ is the joint density of the observed outcome and
the probability of the observed regime (specification section 3.3):

$$L_i = f(y_i, S_i = j \mid z_i, x_{ji}) = f_j(y_i)\; P(S_i = j \mid \varepsilon_{ji} = y_i - x_{ji}'\beta_j, z_i).$$

The second factor is a conditional probability given the outcome disturbance.
Replacing it by the unconditional $P(S_i = j)$ would remove the endogeneity
the model is meant to capture.

## 2. Likelihood contributions (checks V01-V03)

Under A3, $(u_i, \varepsilon_{ji})$ is bivariate normal, so

$$u_i \mid \varepsilon_{ji} \sim N\!\left(\rho_j\,\varepsilon_{ji}/\sigma_j,\; 1 - \rho_j^2\right).$$

**Regime 1** ($S_i = 1 \iff u_i > -w_i$):

$$P(u_i > -w_i \mid \varepsilon_{1i}) = \Phi\!\left(\frac{w_i + \rho_1 e_{1i}}{r_1}\right), \qquad
L_{1i} = \frac{1}{\sigma_1}\,\phi(e_{1i})\,\Phi\!\left(\frac{w_i + \rho_1 e_{1i}}{r_1}\right).$$

**Regime 0** ($S_i = 0 \iff u_i \le -w_i$):

$$L_{0i} = \frac{1}{\sigma_0}\,\phi(e_{0i})\,\Phi\!\left(-\,\frac{w_i + \rho_0 e_{0i}}{r_0}\right).$$

Both are the expressions of specification section 3.4. Under the
convention of [BINARY_ESR.md](BINARY_ESR.md) section 3 they hold exactly as
written there.

**Unified form.** For an observation in regime $j$:

$$\log L_{ji} = -\log\sigma_j + \log\phi(e_{ji}) + \log\Phi(a_{ji}), \qquad
  a_{ji} = q_j\,\frac{w_i + \rho_j e_{ji}}{r_j}.$$

**Proper density.** $\int L_{1i}\,dy = \Phi(w_i)$ and
$\int L_{0i}\,dy = 1 - \Phi(w_i)$, so the contributions define a valid joint
distribution of $(S_i, y_i)$ (V03). V01-V02 confirm that $L_{ji}$ equals the
bivariate normal density integrated over the selection region, to machine
precision.

**Sample log-likelihood**, with optional weights $\omega_i$ (default 1):

$$\ell(\theta) = \sum_{i=1}^N \omega_i\left[S_i \log L_{1i} + (1 - S_i)\log L_{0i}\right].$$

## 3. Working parameterisation

$\vartheta = (\gamma', \beta_1', \beta_0', \tau_1, \tau_0, \alpha_1, \alpha_0)'$,
with $\sigma_j = e^{\tau_j}$ and $\rho_j = \tanh\alpha_j$
([PARAMETERIZATION.md](PARAMETERIZATION.md)). Because
$1/r_j = \cosh\alpha_j$ and $\rho_j/r_j = \sinh\alpha_j$, the index becomes
linear in $(w, e)$:

$$a_{ji} = q_j\left(w_i\cosh\alpha_j + e_{ji}\sinh\alpha_j\right).$$

This removes the square root and keeps every derivative in closed form.

## 4. Building blocks

Write $\lambda(a) = \phi(a)/\Phi(a)$ (inverse Mills ratio) and
$\delta(a) = \lambda(a)\{a + \lambda(a)\} = -\lambda'(a)$, so that
$0 < \delta < 1$. For one observation in regime $j$ (indices $i, j$ dropped),
with $s = \sinh\alpha$, $c = \cosh\alpha$, $v = ws + ec$:

| | $\partial/\partial\gamma$ | $\partial/\partial\beta$ | $\partial/\partial\tau$ | $\partial/\partial\alpha$ |
| --- | --- | --- | --- | --- |
| $e$ | 0 | $-x/\sigma$ | $-e$ | 0 |
| $a$ | $q c\, z$ | $-q s\, x/\sigma$ | $-q s\, e$ | $q v$ |

Second derivatives of $e$: $\partial^2 e/\partial\beta\partial\tau = x/\sigma$,
$\partial^2 e/\partial\tau^2 = e$, all others zero.

Second derivatives of $a$:
- $\partial^2 a/\partial\gamma\partial\alpha = q s\, z$
- $\partial^2 a/\partial\beta\partial\tau = q s\, x/\sigma$
- $\partial^2 a/\partial\beta\partial\alpha = -q c\, x/\sigma$
- $\partial^2 a/\partial\tau^2 = q s\, e$
- $\partial^2 a/\partial\tau\partial\alpha = -q c\, e$
- $\partial^2 a/\partial\alpha^2 = a$
- all others zero.

Since $\log L = -\tau - e^2/2 - \tfrac12\log 2\pi + \log\Phi(a)$:

$$\frac{\partial^2\log L}{\partial\vartheta_k\partial\vartheta_l}
 = -\left(\frac{\partial e}{\partial\vartheta_k}\frac{\partial e}{\partial\vartheta_l} + e\,\frac{\partial^2 e}{\partial\vartheta_k\partial\vartheta_l}\right)
 - \delta\,\frac{\partial a}{\partial\vartheta_k}\frac{\partial a}{\partial\vartheta_l}
 + \lambda\,\frac{\partial^2 a}{\partial\vartheta_k\partial\vartheta_l}.$$

## 5. Score (check V04)

For an observation in regime $j$, the non-zero score components are:

$$\frac{\partial\log L}{\partial\gamma} = \lambda\, q c\; z, \qquad
  \frac{\partial\log L}{\partial\beta_j} = \frac{e - \lambda q s}{\sigma}\; x,$$
$$\frac{\partial\log L}{\partial\tau_j} = -1 + e^2 - \lambda q s\, e, \qquad
  \frac{\partial\log L}{\partial\alpha_j} = \lambda q\,(w s + e c).$$

Regime-1 observations contribute to $(\gamma, \beta_1, \tau_1, \alpha_1)$ and
regime-0 observations to $(\gamma, \beta_0, \tau_0, \alpha_0)$. The total score
is $\sum_i \omega_i\, s_i(\vartheta)$.

## 6. Hessian (check V05)

For an observation in regime $j$, with $v = ws + ec$, the non-zero blocks are
(symmetric counterparts implied):

| Block | Contribution |
| --- | --- |
| $\gamma\gamma'$ | $-\delta c^2\; z z'$ |
| $\gamma\beta_j'$ | $\delta c s/\sigma\; z x'$ |
| $\gamma\tau_j$ | $\delta c s\, e\; z$ |
| $\gamma\alpha_j$ | $(-\delta c v + \lambda q s)\; z$ |
| $\beta_j\beta_j'$ | $-(1 + \delta s^2)/\sigma^2\; x x'$ |
| $\beta_j\tau_j$ | $(-2e - \delta e s^2 + \lambda q s)/\sigma\; x$ |
| $\beta_j\alpha_j$ | $(\delta s v - \lambda q c)/\sigma\; x$ |
| $\tau_j\tau_j$ | $-2e^2 - \delta e^2 s^2 + \lambda q s\, e$ |
| $\tau_j\alpha_j$ | $\delta e s v - \lambda q c\, e$ |
| $\alpha_j\alpha_j$ | $-\delta v^2 + \lambda a$ |

Blocks linking regime-1 and regime-0 parameters are zero. The $\gamma\gamma'$
block sums contributions from both regimes. With $\rho_j = 0$ ($s = 0$,
$c = 1$), the $\gamma$ block reduces to the probit Hessian and the
$(\beta_j, \tau_j)$ block to the Gaussian regression Hessian.

## 7. Covariance estimators (check V06)

With $H = \sum_i\omega_i\,\partial^2\log L_i/\partial\vartheta\partial\vartheta'$,
$s_i = \partial\log L_i/\partial\vartheta$ and $\hat\vartheta$ the FIML
estimate:

| `vcov =` | Estimator | When |
| --- | --- | --- |
| `"hessian"` (default) | $\hat V = (-H)^{-1}$ (observed information; specification section 5.7) | Correct model, unweighted. |
| `"opg"` | $\left(\sum_i \omega_i^2 s_i s_i'\right)^{-1}$ (BHHH) | Diagnostic comparison only. |
| `"sandwich"` | $H^{-1}\left(\sum_i\omega_i^2 s_i s_i'\right)H^{-1}$ | Weights, or suspected misspecification (quasi-ML). |
| `"cluster"` | $\frac{G}{G-1}\,H^{-1}\left(\sum_g S_g S_g'\right)H^{-1}$, $S_g = \sum_{i\in g}\omega_i s_i$ | Clustered sampling, $G$ clusters. |

The information-matrix equality $-E[H] = E[\sum_i s_i s_i']$ holds at the true
parameters. V06 confirms it numerically (relative difference 0.0097 at
n = 200 000), together with a zero mean score. This is an independent check
that $L_i$ is the correct density. The working-scale covariance is
transformed to natural parameters by the delta method
([PARAMETERIZATION.md](PARAMETERIZATION.md) section 3).

## 8. Tests of selection on unobservables (check V19)

**Likelihood-ratio test.** $H_0: \rho_1 = \rho_0 = 0$. Under $H_0$ the
likelihood factorises into a probit for $S$ and two Gaussian regressions, so

$$\ell_R = \ell_{\text{probit}}(\hat\gamma) + \ell_{\text{OLS},1}(\hat\beta_1, \hat\sigma_1^{ML}) + \ell_{\text{OLS},0}(\hat\beta_0, \hat\sigma_0^{ML}),$$

and $LR = 2(\hat\ell - \ell_R) \sim \chi^2_2$. Since $\rho = 0$ is interior to
the parameter space, the standard $\chi^2$ limit applies. V19 confirms the
factorisation to machine precision.

**Wald tests.** Joint test of $\rho_1 = \rho_0 = 0$, individual tests, and
general linear hypotheses $R\theta = r$ on the natural scale using the delta
method. Confidence intervals for $\rho_j$ are formed on the $\alpha_j$ scale
and transformed back.

Failing to reject $H_0$ does not show that regime assignment is exogenous
(research review section 7.3); the software output says so.

## 9. Two-step estimator (checks V07-V09, V13, V14)

**Step 1.** Probit of $S_i$ on $z_i$ gives $\hat\gamma$ and its covariance
$\hat V_\gamma$ (inverse Fisher information). Set $\hat w_i = z_i'\hat\gamma$.

**Step 2.** From the truncated normal:

$$E[u \mid S = 1, z] = m_1(w) = \frac{\phi(w)}{\Phi(w)}, \qquad
  E[u \mid S = 0, z] = m_0(w) = -\frac{\phi(w)}{1 - \Phi(w)},$$

and $E[\varepsilon_j \mid u] = \sigma_j\rho_j u$. Hence

$$E[y \mid S = j, x_j, z] = x_j'\beta_j + \theta_j\, m_j(w), \qquad \theta_j = \sigma_j\rho_j.$$

OLS of $y_i$ on $W_{ji} = (x_{ji}', m_j(\hat w_i))'$ within regime $j$ gives
$\hat b_j = (\hat\beta_j', \hat\theta_j)'$ and residuals $\hat\eta_{ji}$.

**Variance recovery.** With
$\delta_j(w) = m_j(w)\{m_j(w) + w\}$ (so that $\delta_1(w) = \delta(w)$ and
$\delta_0(w) = \delta(-w)$, both in $(0, 1)$), the truncated variance is

$$\operatorname{Var}(\varepsilon_j \mid S = j, z) = \sigma_j^2\left(1 - \rho_j^2\,\delta_j(w)\right)$$

(V08). The consistent estimator (Heckman 1979) is

$$\hat\sigma_j^2 = \frac{1}{n_j}\sum_{S_i = j}\hat\eta_{ji}^2 + \hat\theta_j^2\,\frac{1}{n_j}\sum_{S_i = j}\delta_j(\hat w_i), \qquad
  \hat\rho_j = \hat\theta_j/\hat\sigma_j.$$

$\hat\sigma_j^2 > 0$ always. $\lvert\hat\rho_j\rvert$ can exceed 1 in finite
samples. The software then reports the value, flags it, and truncates it to
$\pm 0.95$ only when it is used as a FIML starting value.

**Derivative of the generated regressor:** $dm_j/dw = -\delta_j(w)$ (V09).

**Model-based covariance** (Heckman 1979; Greene 2012, ch. 19), within regime
$j$ ($W_j$ and $Z_j$ are the regime-$j$ rows, $\Delta_j = \operatorname{diag}\{\delta_j(\hat w_i)\}$):

$$\hat V(\hat b_j) = \hat\sigma_j^2\,(W_j'W_j)^{-1}\left[W_j'(I - \hat\rho_j^2\Delta_j)W_j + \hat\rho_j^2\,(W_j'\Delta_j Z_j)\hat V_\gamma(Z_j'\Delta_j W_j)\right](W_j'W_j)^{-1}.$$

The second term is the first-stage correction. Treating $m_j(\hat w)$ as an
observed regressor would omit it (research review section 7.5).

Effects need the **cross-regime and first-stage covariances**. Using
$\hat b_j - b_j \approx (W_j'W_j)^{-1}W_j'\eta_j + (W_j'W_j)^{-1}\theta_j W_j'\Delta_j Z_j(\hat\gamma - \gamma)$:

$$\widehat{\operatorname{Cov}}(\hat b_1, \hat b_0) = (W_1'W_1)^{-1}\hat\theta_1 (W_1'\Delta_1 Z_1)\,\hat V_\gamma\,(Z_0'\Delta_0 W_0)\hat\theta_0\,(W_0'W_0)^{-1},$$
$$\widehat{\operatorname{Cov}}(\hat b_j, \hat\gamma) = (W_j'W_j)^{-1}\hat\theta_j(W_j'\Delta_j Z_j)\hat V_\gamma.$$

**Robust (stacked M-estimation) covariance.** Stack the moments: the probit
score, $S_i W_{1i}\eta_{1i}$ and $(1 - S_i)W_{0i}\eta_{0i}$. Their expected
Jacobian $A$ has blocks $-\mathcal I_\gamma$, $-W_j'W_j$ and
$\hat\theta_j W_j'\Delta_j Z_j$ (regime $j$ against $\gamma$). Then
$\hat V = A^{-1}\left(\sum_i m_i m_i'\right)A^{-\prime}$. This is valid under
heteroskedasticity and extends to clusters.

**Monte Carlo check** (V14, R = 1000, n = 1500). The ratio of the mean
estimated standard error to the empirical standard deviation stays within 6%
of 1 for every coefficient and for $\hat\theta_1 - \hat\theta_0$ (which uses
the cross-regime covariance), for both covariance estimators. The Monte Carlo
standard error of that ratio is about 2%, so the largest deviation (5.5%) is
noted for follow-up in the WP1.7 Monte Carlo study.

The two-step covariance with `sampleSelection` (model-based formula expected
to coincide) is verified in WP1.8. The point estimates
$\hat\sigma_j, \hat\rho_j$ have no closed-form standard errors in the
two-step; the software reports them as derived quantities, with bootstrap
standard errors on request.

## 10. FIML algorithm (summary; details in NUMERICAL_METHODS.md)

1. Build and check the estimation sample; report removed rows (never
   silently).
2. Starting values: the two-step estimates, with $\hat\rho_j$ truncated to
   $[-0.95, 0.95]$, mapped to the working scale.
3. Maximise $\ell(\vartheta)$ by Newton-Raphson with the analytic score and
   Hessian (`maxLik`). Fall back to BFGS, then BHHH, then `optim`, if a step
   fails.
4. Multistart: the two-step start plus `starts - 1` perturbed starts (seeded,
   with the global random-number state restored). Keep the best
   log-likelihood and report the agreement table.
5. Convergence: maximum absolute gradient below `gradient_tolerance`
   (default $10^{-6}$) and a negative definite Hessian. Report the eigenvalues,
   the condition number and boundary flags ($\lvert\hat\rho_j\rvert > 0.995$).
6. Covariance (section 7) and the reproducibility record (specification
   section 14.2).
