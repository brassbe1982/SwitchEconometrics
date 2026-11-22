# Cross-software benchmark protocol

Status: WP1.1, 22 November 2026. Specification section 9.3; plan decision
D11 as amended by the owner (22 November 2026): R implementations only, no
Stata. To be executed for G1 in WP1.8.

## 1. Principles

- Same data, same estimation sample, same model, same exclusion
  restrictions, same distributional assumptions (specification section 9.3).
- Conventions are mapped explicitly and verified by simulation before any
  comparison ([BINARY_ESR.md](../01_Econometric_Architecture/BINARY_ESR.md)
  section 6).
- Differences are explained through likelihood definitions,
  parameterisations, optimisation and variance calculations. They are never
  dismissed as the other package's error without evidence (research review,
  Stage 5).
- Every benchmark run records package versions, the data seed and the code.

## 2. Benchmark packages

| Package | Version | Status | Role |
| --- | --- | --- | --- |
| `sampleSelection` | 1.2-16 | installed 22 Nov 2026 | G1 Tobit-5 ML and two-step; G2 Tobit-2 and `treatReg` |
| `endoSwitch` | 1.0.0 | archived on CRAN (2025); source download approved, done in WP1.8 | G1 FIML and treatment effects (historical reference) |
| `switchSelection` | 2.1.0 | installed | G2 multinomial and multivariate selection (`msel`) |
| `GJRM` | 0.2-6.9 | installed | G3 copula selection models where they coincide; G4 discrete outcomes |
| `ssmrob` | 1.0 | installed | G4 robust two-step |
| `endogenous` | 1.0 | to install in G2 (approval needed) | G2 hybrid structural-shift treatment model |

## 3. G1 benchmarks

**Datasets** (fixed seeds, saved in `runs/benchmarks_g1/`):

| Id | Data |
| --- | --- |
| D1-D3 | base Monte Carlo design, $N$ = 500, 2000, 10 000 |
| D4 | weak exclusion, $N = 2000$ |
| D5 | different regressor sets per regime (as in `verify_math.R`), $N = 3000$ |
| D6 | the Tobit-5 examples documented in `sampleSelection`'s help pages and vignettes, reproduced with their own code and seeds |
| D7 | the example data shipped with `endoSwitch`, if any |

**Quantities compared** (specification section 9.3):
- selection coefficients, outcome coefficients, $\sigma_j$, $\rho_j$;
- log-likelihood;
- standard errors;
- ATT and ATU;
- the four conditional expectations.

`sampleSelection` reports no treatment effects. For it, effects are compared
by evaluating the SwitchEconometrics effect formulas at both sets of
estimates; differences then come only from the parameter estimates.

**Tolerances**

| Comparison | Requirement |
| --- | --- |
| FIML log-likelihood | $\lvert\Delta\ell\rvert \le 10^{-4}$, and ours $\ge$ theirs $- 10^{-6}$ (we must never stop at a worse point) |
| FIML estimates | $\lvert\Delta\theta\rvert \le 10^{-3}\max(1, \lvert\theta\rvert)$ |
| FIML standard errors | relative difference $\le 1\%$ (other packages may use numerical Hessians) |
| Effects and conditional expectations | $\lvert\Delta\rvert \le 10^{-3}\max(1, \lvert\cdot\rvert)$ |
| Two-step estimates | $\lvert\Delta\rvert \le 10^{-6}$ (deterministic algebra; probit tolerance) |
| Two-step standard errors | relative $\le 10^{-4}$ where the same formula is used; otherwise the formula difference is documented |

## 4. Reporting

`04_Validation/results/BENCHMARK_G1.md` contains:
- one table per dataset, with columns quantity, SwitchEconometrics,
  benchmark, difference, tolerance, pass;
- package versions;
- explanations for every difference larger than its tolerance;
- the script `04_Validation/scripts/benchmark_g1.R` that regenerates it.

## 5. Later generations

| Generation | Benchmarks | Where none exists |
| --- | --- | --- |
| G2 | `switchSelection::msel` (multinomial and multivariate), `sampleSelection` (Tobit-2, `treatReg`), `endogenous` | MNP-ESR with outcome dependence: simulation-only validation |
| G3 | `GJRM` (copula sample-selection and bivariate models where the specifications coincide); `copula` and `VineCopula` for the copula functions | copula ESR as such: nesting (Gaussian = G1) plus Monte Carlo |
| G4 | `GJRM`, `ssmrob`, `sampleSelection` (binary outcomes with selection) | mixed multivariate outcomes: Monte Carlo |
| G5, G6 | no R implementation of panel or spatial ESR is known | Monte Carlo and nesting tests only; stated in the release notes |
