# Generation 5: Panel and dynamic switching (v4.0.0 → v4.5.0)

Status: planned. Specification sections 4E, 6.5, 12.1.

## Scope

- **Panel infrastructure:**
  - `panel = list(id, time)`;
  - unbalanced panels and within-unit lags;
  - clustered inference by default;
  - simulated dataset `firm_panel`.
- **Random-effects switching:**
  - a selection effect $c_i$ and regime effects $a_{ij}$, jointly normal;
  - adaptive Gauss-Hermite quadrature up to dimension 3, simulated ML with
    Halton draws above that, and Laplace via TMB as an option (Suggests).
- **Correlated random effects** (Mundlak 1978; Chamberlain 1984). Panel
  two-step estimators (Wooldridge 1995; Murtazashvili and Wooldridge 2016).
- **Dynamic selection** $S^*_{it} = Z_{it}'\gamma + \lambda S_{i,t-1} + c_i + u_{it}$:
  - explicit initial-conditions treatment (Wooldridge 2005; Heckman 1981);
  - reporting that separates state dependence from persistent heterogeneity
    (specification section 12.1).
- Time-varying treatment effects, regime-transition matrices, AR(1) outcome
  disturbances.

## Work packages

| WP | Version | Content |
| --- | --- | --- |
| 5.1 | 4.0.0 | Panel infrastructure |
| 5.2 | 4.1.0 | Random-effects switching |
| 5.3 | 4.2.0 | Correlated random effects; panel two-step |
| 5.4 | 4.3.0 | Dynamic selection with initial conditions |
| 5.5 | 4.4.0 | Dynamic effects, transitions, temporal dependence |
| 5.6 | 4.5.0 | Monte Carlo study; vignette `panel-esr` |

## Acceptance criteria

1. Monte Carlo recovery, including the initial-conditions designs.
2. **Nesting:** with zero random-effect variances and $\lambda = 0$, the model
   reproduces the cross-sectional log-likelihood on pooled data.
3. Quadrature accuracy: the log-likelihood is stable to 1e-6 as the number of
   nodes increases.
4. Coverage with clustered inference.
5. Dynamic effects verified by simulation.
6. Checks.

No external R benchmark for panel ESR is known. Validation relies on
simulation and nesting, and this is stated in the release notes.
