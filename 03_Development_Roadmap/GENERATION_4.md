# Generation 4: Generalized outcomes and robust estimation (v3.0.0 → v3.5.0)

Status: planned. Specification sections 3.2, 4D, 10.3.

## Scope

- Outcome margins, each with its marginal outcome model kept separate from
  the latent disturbance (specification section 3.2):
  - binary (probit, logit);
  - ordinal (ordered probit and logit);
  - count (Poisson, NB2; Terza 1998);
  - censored (Tobit);
  - fractional (beta);
  - duration (Weibull, log-normal, log-logistic; right censoring).
- Discrete likelihood contributions as copula rectangle probabilities.
- Sample selection for every outcome type; double selection.
- **Joint multivariate outcome systems** per regime with mixed types, for
  example continuous productivity, binary innovation and a count of new
  products. They use a valid joint likelihood with mixed margins.
- **Robust estimation:** `method = "robust"`, with robust two-step
  estimating equations, robust Wald tests and influence functions (Zhelonkin,
  Genton and Ronchetti 2016). It shares the specification but has its own
  objective function (specification section 10.3).
- **Advanced inference:** cluster, wild-score and bootstrap-t methods; BCa
  intervals; bootstrap convergence diagnostics.
- **Effects on the economic scale:** probabilities and expected counts, not
  latent-index coefficients (specification section 11.2).

## Work packages

| WP | Version | Content |
| --- | --- | --- |
| 4.1 | 3.0.0 | Binary, ordinal and count outcomes |
| 4.2 | 3.1.0 | Censored, fractional and duration outcomes |
| 4.3 | 3.2.0 | Sample selection for all types; double selection |
| 4.4 | 3.3.0 | Joint mixed-outcome systems |
| 4.5 | 3.4.0 | Robust estimation; `ssmrob` benchmark |
| 4.6 | 3.5.0 | Advanced inference; Monte Carlo |

## Acceptance criteria

1. Monte Carlo recovery per outcome type.
2. Nesting:
   - a Gaussian continuous margin reproduces G3;
   - binary outcomes with selection reproduce the bivariate probit with
     selection.
3. Benchmarks against GJRM, `ssmrob` and `sampleSelection`.
4. Coverage.
5. Effects on the economic scale verified by simulation.
6. Checks.
