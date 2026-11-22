# Generation 6: Spatial, hierarchical and Bayesian (v5.0.0 and beyond)

Status: planned research extensions. They are not part of the first CRAN
release (specification section 4F). Every component is `experimental` until
its Monte Carlo validation passes.

## Scope

- **Hierarchical switching:** nested random effects (firm within province
  within region within country), by quadrature or Laplace.
- **Spatial outcome dependence:** SAR in regime outcomes with selection. The
  estimator is chosen in the G6 derivation document; spatial models with
  selection involve partially observed networks.
- **Spatial regime selection:** SAR/SEM latent selection, by GHK or
  recursive importance sampling for moderate $N$.
  - Spatial dependence is distinguished from spatial heterogeneity and from
    general cross-sectional dependence.
  - Correlated errors are never interpreted as spatial autoregression
    automatically (specification section 4F).
- **Bayesian engine:** a distinct estimation engine (specification section
  12.4):
  - Gibbs sampling with data augmentation for Gaussian switching (Chib and
    Hamilton 2000; Koop and Poirier 1997);
  - documented priors and convergence diagnostics (R-hat, effective sample
    size);
  - posterior treatment effects;
  - partial pooling across countries and regions.
- **Joint sustainability indicators** (economic, social and environmental
  outcomes; specification section 12.3), and cross-country random
  coefficients.

## Work packages

| WP | Version | Content |
| --- | --- | --- |
| 6.1 | 5.0.0 | Hierarchical switching |
| 6.2 | 5.1.0 | Spatial outcome dependence |
| 6.3 | 5.2.0 | Spatial regime selection; diagnostics |
| 6.4 | 5.3.0 | Bayesian engine |
| 6.5 | 5.4.0 | Sustainability indicators; cross-country heterogeneity; vignette `spatial-esr` |

## Acceptance criteria

1. Monte Carlo recovery and coverage, including posterior coverage for the
   Bayesian engine.
2. Nesting:
   - $W = 0$ reproduces the non-spatial model;
   - flat-prior posterior modes approximate FIML.
3. Convergence diagnostics.
4. Documented computational limits (maximum $N$ for spatial selection).
5. Checks.
