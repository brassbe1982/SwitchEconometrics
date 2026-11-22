# Generation 2: Generalized selection (v1.1.0 → v1.5.0)

Status: planned. The derivation documents are written at the start of the
generation and go to the G2 econometric gate before coding.

## Scope (specification sections 4B, 10.1, 11.3, 13)

- Observation mechanisms beyond switching, using the G1 Gaussian engine:
  - `heckman()`: Tobit-2, outcome observed only when $S = 1$;
  - `treatment()`: a common outcome equation with an intercept shift (or the
    hybrid structural-shift model);
  - `tobit5()` (plan decision D7).
- Multinomial regime selection with $J \ge 3$:
  - multinomial logit with outcome dependence: FIML via Lee (1983); two-step
    via Dubin and McFadden (1984) and Bourguignon, Fournier and Gurgand (2007);
  - multinomial probit with outcome dependence: FIML with $(J-1)$-dimensional
    conditional orthant probabilities (Genz-Bretz; GHK).

  MNL and MNP are distinct models, with different identification and
  disturbance dependence (specification section 4B).
- Ordered and sequential regime selection; nested logit where its
  consistency conditions hold.
- Multivariate selection (several binary selection equations) and several
  Gaussian outcomes per regime.
- Pairwise effects $ATE_{jk}$, $ATT_{jk}$: all $J(J-1)/2$ comparisons, also
  for subpopulations.

## Work packages

| WP | Version | Content |
| --- | --- | --- |
| 2.1 | 1.1.0 | `heckman()`, `treatment()`, `tobit5()`; benchmarks against `sampleSelection` and `endogenous` |
| 2.2 | 1.2.0 | MNL-ESR (Lee FIML; DMF and BFG two-step) |
| 2.3 | 1.3.0 | MNP-ESR (FIML with Genz-Bretz and GHK; C++ after profiling) |
| 2.4 | 1.4.0 | Ordered and sequential selection; nested logit |
| 2.5 | 1.5.0 | Multivariate selection, multiple outcomes, pairwise effects; Monte Carlo; `switchSelection` benchmarks; vignette `multinomial-esr` |

## Acceptance criteria

1. Monte Carlo recovery for each selection mechanism.
2. **Exact nesting.** With $J = 2$, MNP-ESR reduces to G1 with log-likelihood
   equal to 1e-8. The Heckman likelihood reduces to `sampleSelection` Tobit-2.
3. Benchmarks against `switchSelection`, `sampleSelection` and `endogenous`
   within the protocol tolerances.
4. Coverage within [0.93, 0.97] in gated cells.
5. Pairwise effects verified by simulation.
6. Checks on three operating systems.

## Questions for the G2 econometric gate

- MNP covariance normalisation and the minimum exclusion restrictions per
  regime.
- Whether Lee's transformation (a Gaussian copula between the maximum-utility
  index and the outcome) is the intended MNL-ESR FIML model.
- How cross-regime outcome dependence (not identified) is reported for
  $J \ge 3$.
