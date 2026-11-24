# Numerical methods

Status: WP1.1, 22 November 2026. Specification sections 5.4-5.7.
Checks V09-V11 in [verify_math.R](../01_Econometric_Architecture/verify_math.R).

## 1. Policy

1. **Analytic first.** Closed forms wherever they exist. G1 is fully
   analytic: likelihood, score and Hessian.
2. **Deterministic quadrature where practical.** Gauss-Hermite or
   Gauss-Legendre with adaptive tolerances, for copula treatment effects (G3)
   and random effects (G5).
3. **Simulation only when necessary.** GHK on Halton draws for
   high-dimensional normal probabilities (G2 multinomial probit, G5). Draws
   are seeded and recorded.
4. Every analytic derivative has a numerical-derivative test
   (`numDeriv`, in Suggests).

## 2. Stable evaluation of normal quantities

| Quantity | Implementation |
| --- | --- |
| $\log\Phi(a)$ | `pnorm(a, log.p = TRUE)` (accurate in both tails) |
| $\lambda(a) = \phi(a)/\Phi(a)$ | `exp(dnorm(a, log = TRUE) - pnorm(a, log.p = TRUE))`; finite for $a \in [-40, 40]$ and beyond |
| $\delta(a) = \lambda(a)\{a + \lambda(a)\}$ | For $a > -5$, direct. For $a \le -5$, $a + \lambda(a)$ suffers cancellation, so it is computed as $1/(x + 2/(x + 3/(x + \cdots)))$ with $x = -a$: the tail of the Laplace continued fraction of the Mills ratio, backward recursion of depth 300. Verified against $-\lambda'(a)$ on $[-40, 6]$ (V10, relative error < 5e-9). |
| $m_0(w) = -\lambda(-w)$, $\delta_0(w) = \delta(-w)$ | reuse of the above |
| Mills-ratio bounds | $-a < \lambda(a) < -a - 1/a$ for $a < 0$ (V11), used as a unit test of the implementation |

The log-likelihood is accumulated in log space. Probabilities are never
formed and then logged.

## 3. Optimisation

- **Primary:** `maxLik::maxNR` with the analytic gradient and Hessian on the
  working scale.
  - Marquardt's correction of non-concave steps (`qac = "marquardt"`).
  - Stop when the log-likelihood changes by less than 1e-12.
  - This replaces the default step halving since 0.4.0. With step halving, a
    Monte Carlo replication stalled near the optimum for 500 iterations
    (91 s); with Marquardt it took 4 iterations. See progress note WP1.4.
- **Fallbacks:** `maxLik::maxBFGS`, then `maxLik::maxBHHH` (analytic
  gradient, OPG Hessian), then `stats::optim(method = "BFGS")`. These are
  used when a step fails or a non-finite value appears. The optimiser used is
  recorded.
- **Convergence** requires all of:
  - $\max_k\lvert\partial\ell/\partial\vartheta_k\rvert <$ `gradient_tolerance`
    (default $10^{-6}$);
  - relative change in $\ell$ below `reltol`;
  - all Hessian eigenvalues $< 0$.
  Codes: 0 converged; 1 iteration limit; 2 non-negative-definite Hessian at
  the optimum; 3 non-finite log-likelihood; 4 all starts failed.
- **Multistart** ([PARAMETERIZATION.md](../01_Econometric_Architecture/PARAMETERIZATION.md)
  section 4): every start is optimised. The best converged log-likelihood is
  reported. Disagreement among starts within $10^{-6}$ of it (parameters
  differing by more than $10^{-3}$) is flagged as possible weak
  identification. Distinct local maxima are listed in `fit$starts`.
- **Hessian inversion:** symmetric eigen-decomposition. A covariance is
  reported only if all eigenvalues are negative. The condition number
  $\lvert\lambda_{\max}\rvert/\lvert\lambda_{\min}\rvert$ is always reported.
  No generalised inverses are used silently.

## 4. Two-step numerics

The probit uses `glm.fit` (IRLS) with a tight tolerance ($10^{-10}$), with
separation detected via I3. The regime regressions use QR (`lm.fit`).
Covariances use the formulas of [LIKELIHOOD_DERIVATION.md](../01_Econometric_Architecture/LIKELIHOOD_DERIVATION.md)
section 9, with `crossprod` and `solve` on the QR factors where possible.

## 5. Random numbers and reproducibility

- Default RNG kinds; user seeds are applied with the global state saved and
  restored.
- Parallel bootstrap and Monte Carlo use L'Ecuyer-CMRG streams
  (`parallel::nextRNGStream`). Results depend only on `seed` and the number
  of streams.
- The seed, the RNG kind and the number of draws are stored in the
  reproducibility record.

## 6. Later generations (planned)

| Need | Method | Generation |
| --- | --- | --- |
| $(J-1)$-dimensional normal orthant probabilities | Genz-Bretz (`mvtnorm::pmvnorm`, fixed seed and tolerance) for exact evaluation; GHK on Halton draws for smooth simulated likelihood; C++ after profiling | G2 |
| Copula h-functions and inverses | closed forms where available; otherwise Newton steps with bracketing | G3 |
| Expectations under copulas | adaptive Gauss-Kronrod (`integrate`) with fixed tolerances, or Gauss-Legendre on the probability scale | G3 |
| Random-effects integrals | adaptive Gauss-Hermite (dimension up to 3), simulated ML with Halton draws above; Laplace via TMB as an option | G5 |
| Spatial probit | GHK or recursive importance sampling; sparse linear algebra | G6 |
| Bayesian | Gibbs sampling with data augmentation; R-hat and effective sample size | G6 |

## 7. Generation 2 methods

Status: **draft for the G2 econometric gate** (23 November 2026). Sections
1-6 are unchanged. Checks W20, W25, W26 in
[verify_math_g2.R](../01_Econometric_Architecture/verify_math_g2.R).

### 7.1 Which derivatives are analytic

| Model | Score | Hessian | Default optimiser |
| --- | --- | --- | --- |
| Heckman, treatment, Tobit-5 | analytic | analytic | Newton-Raphson (as G1) |
| Multinomial logit with Lee | analytic | analytic | Newton-Raphson |
| Ordered probit | analytic | analytic | Newton-Raphson |
| Nested logit with Lee | analytic | central difference of the analytic score | BFGS, then BHHH |
| Region models with $d \ge 2$ (MNP, sequential, multivariate), deterministic probabilities | analytic (Plackett derivatives and the exact Jacobian of the parameter map) | central difference of the analytic score, symmetrised; step $10^{-5}\max(1, \lvert\vartheta_k\rvert)$ | BFGS, then BHHH |
| The same with GHK probabilities ($d \ge 4$) | analytic derivative of the simulator for fixed draws, or central differences of the simulated log-likelihood; decided in WP2.3 on accuracy evidence | not used for inference: sandwich or OPG | BFGS |

The type of Hessian is stored in the fit (`"analytic"` or
`"score_difference"`). Every differenced Hessian is compared in the tests
with `numDeriv::hessian` of the log-likelihood (tolerance 1e-5 relative).

### 7.2 Normal probabilities

| Need | Method |
| --- | --- |
| $\log\{\Phi(b) - \Phi(a)\}$ (ordered) | both arguments moved to the lower tail when positive; `pnorm(log.p = TRUE)` and a log-difference when either is beyond 5 in absolute value |
| $w = \Phi^{-1}(P)$ (Lee) | `qnorm(log P, log.p = TRUE)`; $1/\lambda(w)$ from `mills()` |
| Bivariate normal cdf | own vectorised R implementation of the Genz (2004) algorithm (Gauss-Legendre on the correlation integral); tested against `mvtnorm` (TVPACK) to 1e-10 |
| Trivariate normal cdf | own vectorised R implementation by one-dimensional Gauss-Legendre integration of the conditional bivariate cdf (Genz 2004); tested against `mvtnorm` (TVPACK) to 1e-8 |
| Rectangles | inclusion-exclusion over the finite corners; coordinates with infinite limits on both sides are dropped first |
| $d \ge 4$ | GHK on Halton draws (GAUSSIAN_REGION_ENGINE.md s.8) for estimation; `mvtnorm::pmvnorm(algorithm = GenzBretz(maxpts = 25000 d, abseps = 1e-6), seed = 20261123)` for the reported log-likelihood, with the summed error estimate |

`mvtnorm` becomes an Import when first used (D10): for $d \ge 4$ and as the
reference in the tests. Vectorisation over observations is what makes the
pure-R route feasible: `pmvnorm()` evaluates one probability per call. If
profiling in WP2.3 shows the R implementations to be the bottleneck, the
evidence goes to the owner before any compiled code is added (D10; handoff
section 7).

**Small probabilities.** A regime probability below $10^{-300}$ makes the
log-likelihood non-finite; the optimiser treats the point as infeasible
(code 3 only if it is the final point).

### 7.3 Halton draws and GHK

- Radical-inverse sequences in bases 2, 3, 5, 7, 11, ... (one per
  dimension), first 20 points discarded, consecutive blocks of $R$ points
  per observation; generated in R, no random numbers.
- $R$ = `switch_control(draws = 500)`; stored in the reproducibility record
  together with the method (`"deterministic"` or `"ghk-halton"`).
- Uniforms are kept inside $[10^{-12}, 1 - 10^{-12}]$; interval
  probabilities are floored at $10^{-300}$.
- W25: with 500 draws the largest absolute error over 18 test regions
  ($d \le 4$) was 5.5e-4; with 2000 draws 1.7e-4.

### 7.4 Quadrature

| Integral | Method |
| --- | --- |
| $m(P)$ of the BFG normalised correction | Gauss-Legendre on $v \in [-6, 40]$ (the range used in W14; the Gumbel density is below $10^{-170}$ outside it). The number of nodes is fixed in WP2.2 so that the result agrees with `integrate()` to 1e-8 over $P \in [10^{-6}, 1 - 10^{-6}]$ |
| Lee counterfactual moment under the nested logit | Gauss-Legendre on $t = F_j(c) \in (P_j, 1)$; the number of nodes is fixed in WP2.4 against `integrate()` (the formula itself is checked by simulation in W38a) |

### 7.5 Numerical differentiation used in estimation and effects

- **Truncated-mean Jacobian** $\partial t_k/\partial W'$ (two-step
  covariance and truncated covariance): central differences with one
  Richardson step. W26b shows that the identity behind it holds to 4e-12
  when the Jacobian is computed by `numDeriv`; the package's own
  differences are tested against `numDeriv`.
- **Effect gradients** for region models and the nested logit: central
  differences with one Richardson step (steps $10^{-4}$ and
  $5 \times 10^{-5}$ times $\max(1, \lvert\vartheta_k\rvert)$); tested
  against `numDeriv::jacobian`.
- These are implemented in the package (`numDeriv` stays in Suggests and is
  used only by tests).

### 7.6 Reproducibility

Estimation uses no random numbers in G2 except the multistart perturbations
(seeded as in G1) and the Genz-Bretz evaluation for $d \ge 4$ (fixed seed
passed to `pmvnorm`). The record adds: probability method, number of draws,
Hessian type, base alternative, component order, nesting structure.

### 7.7 Gate amendments (23 November 2026): eight regimes and the normal-score model

- **Number of regimes.** The owner requires at least $J = 8$, with room for
  more. No routine may contain a constant that limits $J$; storage and
  loops are sized from the data. The closed-form models (Lee, ordered,
  sequential with independent stages, nested logit) cost $O(NJ)$ per
  evaluation for any $J$.
- **Probabilities by dimension $d$** (multinomial probit: $d = J - 1$;
  normal-score model: $d = J - 1$ inside a one-dimensional rule):
  deterministic for $d \le 3$; GHK on Halton draws for $d \ge 4$, marked
  experimental. Measured on 24 seven-dimensional regime rectangles with
  probabilities from 3e-4 to 0.19 (check X21 of `verify_math_g2b.R`): the
  largest error of $\log P$ is 0.017 with 500 draws and 0.008 with 2000.
  The default of 500 draws is therefore too coarse for likelihood-ratio
  comparisons at $d = 7$; the fit reports the number of draws, and the
  documentation recommends at least 2000 for $d \ge 6$ and a rerun with
  more draws as a stability check.
- **Cost.** One vectorised GHK pass in R for 2000 observations, $d = 7$,
  500 draws: 2.3 s (X23, this machine). A score evaluation by Plackett
  derivatives needs on the order of $d + d(d-1)/2$ such passes of one
  dimension less. Whether the pure-R route is practical at $J = 8$ is
  decided by profiling in WP2.3; compiled code needs the owner's approval.
- **Normal-score model** (MULTINOMIAL_ESR.md section 11): Gauss-Hermite
  rule in $\eta_j$ centred at $r_je$ with scale $\sqrt{1 - r_j^2}$ (32
  nodes reproduced $P_k$ to 1.4e-7 at $J = 8$, X14a); inner rectangle by
  the engine's routine with the covariance $\Sigma_c$ computed once per
  regime and evaluation. The node count is a control argument; the tests
  of WP2.2 fix its default by comparing 32, 48 and 64 nodes.
- **`max.col()` is not used for the regime of maximum utility** in
  simulation code: it treats values within a relative tolerance as ties
  and breaks them at random (found while writing check X10). The
  simulation scripts use an exact row-wise argmax.

### 7.8 As built in WP2.2 (version 1.2.0)

- **Lee's model:** closed form, analytic score and Hessian, cost $O(NJ)$;
  fitted with 3, 8 and 10 regimes in the tests.
- **BFG variant 2:** the function $m(P)$ is tabulated once per session on a
  grid of $\log P$ (denser near $P = 1$) and interpolated by a cubic
  spline; error of the interpolant about $10^{-10}$ against direct
  numerical integration.
- **Bivariate normal distribution function** (`se_pbvnorm`): Plackett's
  identity with Gauss-Legendre nodes (12 for $\lvert r\rvert \le 0.5$, 20
  per subinterval above, the range split near the end point for
  $\lvert r\rvert > 0.9$); agrees with `mvtnorm` (TVPACK) to $10^{-10}$
  for correlations from $-0.995$ to $0.99$ (package test).
- **Normal-score model, integration rule. The plan of section 7.7 (a
  Gauss-Hermite rule) was not kept.** Measured on 400 simulated
  observations of one regime against a rule with 3200 nodes (largest error
  of $\log I$ over the observations; composite rules on $(-7, 7)$, which
  have the panel width of the rule finally used within 2%):

  | Correlations of the regime | Gauss-Hermite 24 | Gauss-Hermite 96 | composite Gauss-Legendre, 12 panels of 8 | 24 panels | 48 panels | 96 panels |
  | --- | --- | --- | --- | --- | --- | --- |
  | $\sum r^2 = 0.30$ | 9e-4 | 3e-10 | 2e-9 | 4e-14 | | |
  | $\sum r^2 = 0.80$ | 2e-3 | 2e-8 | 5e-9 | 2e-13 | | |
  | $\sum r^2 = 0.96$ | 3e-2 | 3e-4 | 5e-6 | 7e-10 | | |
  | $\sum r^2 = 0.99$ | 6e-2 | 5e-3 | 4e-4 | 4e-7 | 2e-11 | |
  | $\sum r^2 = 0.998$ | 7e-2 | 9e-3 | 2e-3 | 2e-4 | 6e-7 | 6e-11 |
  | one other correlation zero, conditional sd 0.25 ($\sum r^2 = 0.95$) | 0.19 | 1e-2 | 3e-4 | 2e-7 | 4e-12 | |
  | the same, conditional sd 0.08 ($\sum r^2 = 0.995$) | 0.36 | 0.16 | 6e-2 | 7e-3 | 3e-5 | 1e-9 |

  Near $\sum_k r_{jk}^2 = 1$ the conditional distribution of the scores
  given the outcome disturbance becomes singular and the integrand has
  kinks and steep transitions, for which a Gauss-Hermite rule converges
  slowly. With 24 Gauss-Hermite nodes the first implementation produced
  **spurious maxima at the boundary**: on one simulated sample
  ($N = 2000$) the optimiser reported a log-likelihood of $-4618.98$ at a
  point whose log-likelihood, computed with 384 and more nodes, is about
  $-4630$, with a gradient far from zero.
  The engine therefore uses a composite Gauss-Legendre rule on $(-8, 8)$
  with 8 nodes per panel: 14 panels when
  $s_0 = \sqrt{1 - \sum_k r_{jk}^2} \ge 0.35$, 28 for $s_0 \ge 0.18$, 56
  for $s_0 \ge 0.09$ and 112 below. The package test requires an error of
  $\log I$ below $10^{-7}$ for $\sum r^2 \le 0.8$ and below $2 \times
  10^{-5}$ up to $\sum r^2 = 0.995$. The rule changes at three values of
  $s_0$; the log-likelihood has jumps of at most that size there.
- **Normal-score model, derivatives.** The score is analytic
  (differentiation under the integral sign; it equals the numerical
  gradient to $10^{-7}$ in the tests). The Hessian is the symmetrised
  forward difference of the score. Optimisation: BFGS on the score, then
  at most three Newton steps with one differenced Hessian
  (`se_optimize_costly()`); Newton-Raphson iterations are not used because
  each Hessian costs as many score evaluations as there are parameters.
- **Only $J \le 3$** for the normal-score model: the inner probability is
  univariate or bivariate. $J \ge 4$ needs the trivariate routine or GHK
  of WP2.3 and is refused with a classed error.
