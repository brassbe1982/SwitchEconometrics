# Generation 3: Copula dependence (v2.0.0 → v2.5.0)

Status: planned. This is the major methodological contribution (specification
section 4C).

## Scope

- **Copula engine** (`copula_spec()`, `se_copula`):
  - families: Gaussian and Student-t (priority 1); Clayton, Gumbel, Frank and
    Joe with rotations, and BB1, BB6, BB7, BB8 (priority 2); C- and D-vines
    (priority 3);
  - each family provides the cdf, pdf, h-functions and their inverses,
    derivatives, Kendall's tau, tail dependence and validity checks;
  - components are adapted from TriCopula (same author, MIT) where possible,
    and cross-checked against `copula` and `VineCopula`.
- **Flexible margins:** Student-t and skew-normal outcomes; logistic selection
  error.
- **Copula binary ESR.** Built on the identified pairs $(u, \varepsilon_j)$,
  with the across-regime dependence handled as in plan decision D8 (vine
  rooted at $u$ plus a stated assumption). Trivariate Gaussian and Student-t,
  and validated nested Archimedean copulas, for multi-outcome and multinomial
  systems.
- **Effects** by quadrature over conditional distributions; counterfactual
  simulation by conditional sampling; distributional effects with bounds.
- **Dependence diagnostics and sensitivity:**
  - AIC and BIC;
  - Vuong and Clarke tests;
  - tail dependence;
  - a sensitivity table of ATT, ATU and ATE across families.

## Work packages

| WP | Version | Content |
| --- | --- | --- |
| 3.1 | 2.0.0 | Copula engine and families |
| 3.2 | 2.1.0 | Flexible margins |
| 3.3 | 2.2.0 | Copula ESR likelihood; exact nesting of G1 |
| 3.4 | 2.3.0 | Multivariate copulas and vines |
| 3.5 | 2.4.0 | Effects and counterfactuals under copulas |
| 3.6 | 2.5.0 | Diagnostics, sensitivity, Monte Carlo, GJRM benchmarks, vignette `copula-esr` |

## Acceptance criteria

1. The copula functions match `copula`/`VineCopula` to 1e-8, and their
   derivatives match numerical ones.
2. Gaussian copula with Gaussian margins equals the G1 log-likelihood and
   estimates to 1e-8.
3. Monte Carlo recovery and coverage per family.
4. GJRM agreement where the models coincide.
5. Effects verified by simulation.
6. Checks on three operating systems.

## Questions for the G3 econometric gate

- Choice of the conditional pair copula for $(\varepsilon_1, \varepsilon_0 \mid u)$:
  default independence, with a sensitivity range.
- Admissible Archimedean constructions for three disturbances.
- Identification statements for non-Gaussian dependence (specification
  section 15).
