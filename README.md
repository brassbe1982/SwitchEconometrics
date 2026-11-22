# SwitchEconometrics

*Unified Estimation of Endogenous Regime-Dependent Economic Systems*

`SwitchEconometrics` is an R package for endogenous switching regression and
related models. Its long-term aim is to bring endogenous switching, endogenous
treatment, sample selection, multinomial switching, copula-based dependence
and longitudinal switching under one statistical model, the **Generalized
Endogenous Switching System**. Established estimators are documented special
cases of that model.

The current version covers the **classical binary endogenous switching
regression** (Generation 1). The later generations are planned (see the
roadmap below).

## What it does

- **Estimation:** full-information maximum likelihood with an analytic
  gradient and Hessian, or two-step (Heckman-Lee) estimation
  (`switch_fit()`, `esr()`).
- **Inference:** Hessian, OPG, sandwich and cluster-robust covariances;
  confidence intervals; likelihood-ratio and Wald tests, including linear
  hypotheses; nonparametric and parametric bootstrap (`summary()`,
  `confint()`, `switch_test()`, `switch_bootstrap()`).
- **Identification checks** before and after fitting: exclusion
  restrictions and their strength, collinearity of the selection
  correction, multistart agreement, boundary flags, and the parameters
  that cannot be identified (`switch_validate()`, `switch_diagnostics()`).
- **Treatment effects:** the four conditional expectations, ATT, ATU, ATE,
  treatment and base heterogeneity, by group or per unit, with
  delta-method or bootstrap standard errors (`switch_effects()`,
  `switch_predict()`).
- **Counterfactual and policy scenarios** (`switch_counterfactual()`),
  **simulation** from a specification or a fit (`switch_simulate()`), and
  **model comparison** (`switch_compare()`).

## Example

`firms` is a simulated dataset shipped with the package. Its true
parameters are documented in `?firms`.

```r
library(SwitchEconometrics)

fit <- switch_fit(
  selection = digital_adoption ~ internet_access + management_quality +
    firm_size + owner_education,
  outcomes = list(
    regime_0 = productivity ~ firm_size + capital + labour,
    regime_1 = productivity ~ firm_size + capital + labour
  ),
  data = firms
)
summary(fit)
switch_effects(fit)        # ATT, ATU, ATE, TH, BH and the 2 x 2 table
switch_validate(fit)       # identification checks
```

## Documentation

Three vignettes:
- `vignette("classical-esr", package = "SwitchEconometrics")`:
  specification, identification checks, FIML and two-step estimation,
  inference and diagnostics.
- `vignette("treatment-effects", package = "SwitchEconometrics")`: the
  conditional expectations and effects, standard errors, heterogeneity,
  counterfactual scenarios, and what the model cannot identify.
- `vignette("simulation-validation", package = "SwitchEconometrics")`:
  Monte Carlo and benchmark evidence. It includes the finite-sample
  behaviour of the intervals below N = 1000, and how to check recovery
  for your own design.

## Validation

**Monte Carlo study.** Pre-registered before the estimator code existed:
38 designs and 28 400 replications, each fitted by FIML and two-step.
- Bias, root-N consistency and convergence checks pass.
- Interval coverage reaches the nominal level as N grows. It is too low
  below N = 1000; the vignette `simulation-validation` gives the numbers.

**Cross-software benchmarks.**
- FIML equals the maximum-likelihood estimates of `sampleSelection` and of
  the archived `endoSwitch`, including the treatment effects of
  `endoSwitch`, with and without weights.
- Sandwich, OPG and cluster-robust standard errors equal those of the
  `sandwich` package.

**Where the evidence is.** The pre-registered design, the scripts and the
results are in the folder `04_Validation/` of the source repository:
`results/MC_G1.md` and `results/BENCHMARK_G1.md`.

## Status

**Version 0.9.0: Generation 1, work package 1.9** (documentation and CRAN
preparation).
- Acceptance criteria 1-5 of Generation 1 are met.
- Criterion 6 (clean checks on Windows, macOS and Linux) awaits the public
  repository and its continuous integration.

The release 1.0.0 is planned for CRAN. Changes are described in `NEWS.md`.

## Roadmap

| Generation | Versions | Content |
| --- | --- | --- |
| G1 | 0.1.0 → 1.0.0 | Classical binary ESR: FIML and two-step; Hessian, sandwich, cluster and bootstrap inference; ATT, ATU, ATE and counterfactuals. First CRAN release. |
| G2 | 1.1.0 → 1.5.0 | Heckman and treatment models; multinomial (logit and probit), ordered, sequential and multivariate selection; pairwise effects |
| G3 | 2.0.0 → 2.5.0 | Copula dependence (Gaussian, Student-t, Archimedean, BB, vines); flexible margins; sensitivity analysis |
| G4 | 3.0.0 → 3.5.0 | Binary, count, ordinal, censored, fractional and duration outcomes; joint outcome systems; robust estimation |
| G5 | 4.0.0 → 4.5.0 | Random-effects, correlated random-effects and dynamic switching with initial conditions |
| G6 | 5.0.0 → | Spatial, hierarchical and Bayesian extensions |

## Installation

The package is not yet on CRAN. To install it from a source tarball built
with `R CMD build`:

```r
install.packages("SwitchEconometrics_0.9.0.tar.gz", repos = NULL, type = "source")
```

## Citation

Run `citation("SwitchEconometrics")` for the reference to the package.

## Licence and funding

MIT © 2026 Ibrahim Niankara. Funded by BRASS Digital Lab.
