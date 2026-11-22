# SwitchEconometrics

*Unified Estimation of Endogenous Regime-Dependent Economic Systems*

`SwitchEconometrics` is an R package under development. It brings endogenous
switching regression, endogenous treatment, sample selection, multinomial
switching, copula-based dependence and longitudinal switching under one
statistical model, the **Generalized Endogenous Switching System**. Established
estimators are documented special cases of that model.

## Status

**Version 0.8.0: Generation 1, work package 1.8.** The classical binary ESR
is functionally complete:
- estimation by FIML or two-step (`switch_fit()`, `esr()`);
- inference (`summary()`, `confint()`, `switch_test()`,
  `switch_bootstrap()`);
- identification checks and diagnostics (`switch_validate()`,
  `switch_diagnostics()`);
- treatment effects (`switch_effects()`);
- predictions (`switch_predict()`);
- counterfactual and policy scenarios (`switch_counterfactual()`);
- simulation (`switch_simulate()`);
- model comparison (`switch_compare()`).

Cross-software benchmarks: FIML results equal the maximum-likelihood
estimates of `sampleSelection` and of the archived `endoSwitch`, including
the treatment effects of `endoSwitch`. See
`04_Validation/results/BENCHMARK_G1.md`.

The pre-registered Monte Carlo study has been run: 28 400 replications,
each fitted by FIML and two-step. 491 of the 501 pre-registered checks pass.
The 10 failures are diagnosed as finite-sample behaviour, not defects. The
owner accepted this diagnosis, so the recovery and inference criteria (AC1,
AC4) are met with documented exceptions. See
`04_Validation/results/MC_G1.md`.

Still to come in Generation 1:
- vignettes and CRAN preparation (0.9.0);
- the release (1.0.0).

Earlier versions are described in `NEWS.md`. The Generation 1 econometric
gate was approved on 22 November 2026. Version 0.1.0 provided:

- the package infrastructure (DESCRIPTION, tests, continuous-integration
  workflow);
- the authoritative specification and delivery plan
  (`00_Project_Governance/`, `03_Development_Roadmap/`);
- the complete Generation 1 derivations (`01_Econometric_Architecture/`),
  each formula verified numerically by `verify_math.R` (26 of 26 checks
  pass);
- the computational architecture and API contracts
  (`02_Computational_Architecture/`);
- the pre-registered Monte Carlo design, benchmark protocol and acceptance
  tests (`04_Validation/`).

## Roadmap

| Generation | Versions | Content |
| --- | --- | --- |
| G1 | 0.1.0 → 1.0.0 | Classical binary ESR: FIML and two-step; Hessian, sandwich, cluster and bootstrap inference; ATT, ATU, ATE and counterfactuals. First CRAN release. |
| G2 | 1.1.0 → 1.5.0 | Heckman and treatment models; multinomial (logit and probit), ordered, sequential and multivariate selection; pairwise effects |
| G3 | 2.0.0 → 2.5.0 | Copula dependence (Gaussian, Student-t, Archimedean, BB, vines); flexible margins; sensitivity analysis |
| G4 | 3.0.0 → 3.5.0 | Binary, count, ordinal, censored, fractional and duration outcomes; joint outcome systems; robust estimation |
| G5 | 4.0.0 → 4.5.0 | Random-effects, correlated random-effects and dynamic switching with initial conditions |
| G6 | 5.0.0 → | Spatial, hierarchical and Bayesian extensions |

## Planned interface (Generation 1)

All functions below work from version 0.6.0. `firms` is the simulated
example dataset shipped with the package.

```r
library(SwitchEconometrics)

fit <- switch_fit(
  selection = digital_adoption ~ internet_access + management_quality +
    firm_size + owner_education,
  outcomes = list(
    regime_0 = productivity ~ firm_size + capital + labour,
    regime_1 = productivity ~ firm_size + capital + labour
  ),
  data = firms, model = "esr", method = "fiml"
)
summary(fit)
switch_effects(fit)        # ATT, ATU, ATE, TH, BH and the 2 x 2 table
switch_validate(fit)       # identification diagnostics
```

## Installation

The package is not yet on CRAN. To install it from a source tarball:

```r
install.packages("SwitchEconometrics_0.1.0.tar.gz", repos = NULL, type = "source")
```

## Licence and funding

MIT © 2026 Ibrahim Niankara. Funded by BRASS Digital Lab.
