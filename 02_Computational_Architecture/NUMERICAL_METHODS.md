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
