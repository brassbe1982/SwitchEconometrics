# SwitchEconometrics: delivery plan

Plan version 1.1, 22 November 2026. Status: **approved by the project owner
on 22 November 2026**, with one change (see the change log).

**Change log**

- 1.1 (22 November 2026, owner's decision at approval): Stata (`movestay`,
  `etregress`, `eregress`) is removed from the whole development plan and
  process, because Stata is not available on the development machine. There
  are no Stata benchmarks, do-files or comparison scripts, and no Stata
  conventions to match. Stata may be cited in the research article on
  SwitchEconometrics only as an existing Stata-based option for endogenous
  switching analysis. The specification's mentions of Stata benchmarks
  (sections 2, 4A, 9.3, 13, 16 and 20) are superseded by this decision.
- 1.0 (22 November 2026): first version.

This plan turns the specification (`00_Project_Governance/SPECIFICATION.md`,
the owner's document of 22 November 2026) into work packages, each with a
deliverable, the evidence that closes it and a version number. The background
review "Initial research details for SwitchEconometrics.txt" (workspace root)
supplies the benchmark software list and the core references.

---

## 0. Starting point (checked 22 November 2026)

**Workspace.** Cleared. Everything that was here (a copy of the earlier
TriCopula project: package, manuscript, JSS submission, simulation and
validation runs, GJRM sources, CRAN scripts, a TriCopula-only Claude skill)
was moved, unchanged, to `_ARCHIVE_for_manual_deletion_2026-11-22/` (18
items; file counts verified before and after). The original TriCopula
project is untouched in its own folder,
`Claude workspace/TriCopula Development Environment`.

**Toolchain on this machine.**

| Available | Missing |
| --- | --- |
| R 4.6.2 (ucrt), Rtools 4.5 (C++ builds work) | `sampleSelection`, `switchSelection`, `ssmrob`, `systemfit` (benchmarks) |
| `maxLik` 1.6-10, `mvtnorm` 1.4-2, `numDeriv`, `sandwich`, `MASS`, `Matrix`, `nnet` | `TMB`, `spdep`, `fastGHQuad` (Generations 5-6, optional) |
| `copula` 1.1-7, `VineCopula` 2.6.1, `GJRM` 0.2-6.9, `VGAM`, `mlogit`, `lme4`, `randtoolbox`, `statmod` | `endoSwitch` (archived from CRAN in 2025) |
| `testthat` 3.3.2, `roxygen2` 8.1.1, `devtools`, `rcmdcheck`, `covr`, `knitr`, `rmarkdown`, `Rcpp`, `RcppArmadillo` | |
| MiKTeX (PDF manual), pandoc via RStudio, Git for Windows | |

**Reusable own code.** TriCopula 0.17.5 (MIT, same author) already has
bivariate copula families with rotations, h-functions, analytic gradients,
flexible margins and sandwich covariances. Generation 3 will adapt those
components, with attribution, after review. It will not import TriCopula
wholesale, because TriCopula models three continuous responses without regime
selection.

---

## 1. Delivery principles (taken from the specification)

1. **One model, many specifications.** Every estimator is a configuration of
   the Generalized Endogenous Switching System (spec section 3). Generation 1
   is the first restricted instance of it, not a separate prototype (spec
   section 20).
2. **Staged generations.** Each generation ends in a usable release (spec
   section 13), in the order Classical ESR → Multinomial → Copula → Mixed
   outcomes and robust estimation → Panel and dynamic → Spatial,
   hierarchical and Bayesian.
3. **Three approval gates per generation** (spec section 17.1). The
   econometric gate is the owner's sign-off on that generation's derivation
   documents. The computational and software gates are closed by evidence:
   numerical verification, Monte Carlo results and `R CMD check`.
4. **Done means demonstrated.** A feature is "stable" only after its
   acceptance tests pass. Until then it carries `lifecycle: experimental` in
   its documentation. Running code is not enough (spec sections 9.2 and 17.1).
5. **Honest reporting.** Disappointing Monte Carlo or benchmark results are
   reported as they are. A specification item that turns out to be
   unidentified or not computable as written is documented and refused by the
   software, never approximated silently.

---

## 2. Decisions this plan makes (ambiguities in the specification)

The owner can overturn any of these at the approval step.

| # | Issue | Decision |
| --- | --- | --- |
| D1 | Where the package sits relative to the spec section 17 governance folders | `SwitchEconometrics/` is both the git repository and the package root. The folders `00_Project_Governance/` to `05_References/` sit inside it, as spec section 17 shows, and are excluded from the built package by `.Rbuildignore`. Heavy Monte Carlo output goes to `runs/` in the workspace, outside the repository. |
| D2 | Spec section 7 puts R code in subfolders (`R/selection/`, `R/copulas/`, ...), but R ignores subfolders of `R/` | The `R/` folder stays flat and the layer becomes a file-name prefix: `spec_`, `dist_`, `cop_`, `par_`, `lik_`, `est_`, `inf_`, `eff_`, `pan_`, `spa_`, `sim_`, `methods_` (for example `R/lik_binary_gaussian.R`). The layering is the same; only the folder form changes. |
| D3 | Two version schemes: spec section 13 (G1 0.1.0→1.0.0, G2 1.1→1.5, ...) and the "for example" list in section 14.3 | Section 13 applies. Minor versions mark work packages, patch versions mark fixes. |
| D4 | The `switch_fit()` signature differs between sections 6.2 (`model = "esr"`, `method = "fiml"`) and 10.3 (`model = specification`, `estimator = "fiml"`) | `model` accepts either a model-type string (with formulas passed directly) or a `switch_spec` object from `switch_model()`. `method` is the estimator argument, and `estimator` is accepted as a documented synonym so that both spellings in the specification work. |
| D5 | The research notes' G1-G6 table (section 15) differs from the specification's roadmap | The specification (section 13) applies. |
| D6 | Sign convention (spec section 3.4) | S = 1 if and only if Z'γ + u > 0, with u ~ N(0, 1) and ρ_j = Corr(u, ε_j). Every formula is derived from this one convention. The benchmark scripts convert other packages' conventions explicitly, for example where `sampleSelection` or `endoSwitch` order the regimes or sign ρ₀ differently. |
| D7 | Heckman (Tobit-2) and endogenous-treatment wrappers are in the compatibility matrix (section 10.1) but outside the frozen G1 scope (section 16) | G1 stays as frozen. `heckman()`, `treatment()` and `tobit5()` open G2 (v1.1.0), because they reuse the G1 Gaussian engine with a different observation mechanism (section 10.2). G4 then extends sample selection to non-Gaussian and discrete outcomes. |
| D8 | **Identification of the trivariate dependence** (sections 4C and 15) | In the binary ESR likelihood only the (u, ε₁) and (u, ε₀) dependence enters, because ε₁ and ε₀ are never observed together. Their joint dependence is therefore not identified (Koop and Poirier, 1997; Poirier and Tobias, 2003). G1 does not estimate σ₁₀. In G3 the "trivariate" copula is built as a vine rooted at u: two identified pair copulas, with the conditional (ε₁, ε₀ given u) pair fixed by a stated assumption. Exchangeable trivariate Archimedean copulas are offered only where a validity and identification check passes, because they force equal dependence for every pair. Quantities that need the (ε₁, ε₀) dependence, such as the distribution of Y₁ − Y₀, are reported as Fréchet-Hoeffding bounds or under that stated assumption. This decision goes to the G1 econometric gate. |
| D9 | The spec section 11.2 definition of BH ("observed and counterfactual untreated outcome for treated agents") is ambiguous | The effects engine reports base heterogeneity for both regimes as in Carter and Milon (2005) and Di Falco, Veronesi and Yesuf (2011): BH₁ = E[Y₁ given S=1] − E[Y₁ given S=0] and BH₀ = E[Y₀ given S=1] − E[Y₀ given S=0]. It also reports TH = ATT − ATU, and states the definitions in the output. To be confirmed at the G1 econometric gate. |
| D10 | Dependency policy (section 8) | Imports: `stats`, `maxLik`, `mvtnorm`. Everything else goes in Suggests and is called conditionally: `numDeriv` (derivative checks), `copula`/`VineCopula` (cross-checks of our own copula code), `sandwich`, `TMB`, `spdep`, and the benchmark packages. The package stays free of compiled code through G1; C++ comes in only after profiling (expected for multinomial probit in G2 and quadrature in G5). |
| D11 | Stata benchmarks (sections 9.3 and 16), with no Stata on this machine | **Owner's decision, 22 November 2026:** Stata is removed from the development plan and process altogether. Cross-software validation uses R implementations only: `sampleSelection`, the archived `endoSwitch`, `switchSelection`, `GJRM`, `ssmrob` and `endogenous`. G1 acceptance criterion 3 is met against `sampleSelection` and `endoSwitch`. Stata may be cited in the research article as an existing Stata-based option. |
| D12 | Repository events | Local `git init` in `SwitchEconometrics/`, with one commit per finished work package (if the owner approves this standing authorisation). Every push, GitHub repository creation, win-builder or macOS-builder upload and CRAN submission needs the owner's go-ahead at the time. |

---

## 3. Target repository layout

```
SwitchEconometrics Development Environment/        (workspace)
├── Initial research details for SwitchEconometrics.txt   (owner's notes, untouched)
├── _ARCHIVE_for_manual_deletion_2026-11-22/      (old content, for the owner to delete)
├── runs/                                         (Monte Carlo and benchmark output; not in git)
└── SwitchEconometrics/                           (git repository = package root)
    ├── 00_Project_Governance/   SPECIFICATION.md, PROJECT_CHARTER.md, SCIENTIFIC_SCOPE.md, DEVELOPMENT_POLICY.md
    ├── 01_Econometric_Architecture/   GENERAL_MODEL.md, BINARY_ESR.md, LIKELIHOOD_DERIVATION.md,
    │                                  IDENTIFICATION.md, PARAMETERIZATION.md, TREATMENT_EFFECTS.md, verify_math.R
    ├── 02_Computational_Architecture/ SOFTWARE_ARCHITECTURE.md, API_SPECIFICATION.md,
    │                                  NUMERICAL_METHODS.md, PERFORMANCE_POLICY.md
    ├── 03_Development_Roadmap/  DELIVERY_PLAN.md (this file), GENERATION_1.md ... GENERATION_6.md, progress/
    ├── 04_Validation/           MONTE_CARLO_DESIGN.md, BENCHMARK_PROTOCOL.md, ACCEPTANCE_TESTS.md,
    │                            scripts/ (Monte Carlo and benchmark drivers), results/ (summaries)
    ├── 05_References/           REFERENCES.bib
    ├── DESCRIPTION, NAMESPACE, LICENSE, README.md, NEWS.md, CONTRIBUTING.md, inst/CITATION
    ├── R/                       flat; prefixed by layer (decision D2)
    ├── src/                     from G2 onward, only after profiling
    ├── data/                    simulated `firms`, later `firm_panel` (documented data-generating processes)
    ├── tests/testthat/          unit, nesting, recovery and regression-reference tests
    ├── vignettes/               classical-esr, treatment-effects, multinomial-esr, copula-esr,
    │                            simulation-validation (later panel-esr, spatial-esr)
    ├── man/                     roxygen2
    └── .github/workflows/       R-CMD-check on Windows, macOS and Linux
```

---

## 4. Work breakdown

Every work package (WP) follows the same cycle:

1. Update the derivation documents.
2. Implement.
3. Write unit tests, including analytic-against-numerical derivative checks.
4. Run the full test suite and `R CMD check --as-cran`.
5. Bump the version and add a `NEWS.md` entry.
6. Write a progress note in `03_Development_Roadmap/progress/`.
7. Commit locally (per decision D12).

From the first fitted model on, frozen regression references are compared to
within 1e-8 at every version.

### Generation 1: Classical core (v0.1.0 → v1.0.0). First CRAN release.

| WP | Version | Deliverable | Closed by |
| --- | --- | --- | --- |
| 1.1 | 0.1.0 | **G1 mathematical and computational specification** (all 12 items of spec section 20): model and assumptions; trivariate Gaussian likelihood; parameter vector and transformations; analytic score and Hessian; two-step estimator and its corrected covariance (Heckman 1979; Murphy and Topel 1985); FIML algorithm; identification conditions; the four conditional expectations, ATT, ATU, ATE, TH and BH; Monte Carlo design; benchmark protocol; acceptance criteria; API contracts. Also the governance documents, `REFERENCES.bib`, the package skeleton (DESCRIPTION, LICENSE, CITATION, testthat, GitHub Actions workflow file), `git init`, and a clean `R CMD check` on the skeleton. | `verify_math.R` checks every formula numerically: likelihood against numerical integration of the trivariate normal, score and Hessian against `numDeriv`, conditional expectations against simulation. Then **econometric gate (owner)**. |
| 1.2 | 0.2.0 | Layers 1, 2 and 5: `switch_model()` and the `switch_spec` object; formula and model-frame handling (missing values reported, never dropped silently); the distribution interface with its Gaussian implementation; the parameter-transformation engine (exp, tanh, 2+exp, Cholesky / partial-correlation parameterisation of correlation matrices, Jacobians for the delta method). | Unit tests: round trips, Jacobians against numerical derivatives, validity of correlation matrices. |
| 1.3 | 0.3.0 | Layer 3: Gaussian binary ESR likelihood (`loglik_observation`, `loglik_selection`, `loglik_outcome`, `loglik_joint`, `loglik_switch`) with analytic score and Hessian, stable log Φ, and weights. | Matches direct trivariate-normal integration to 1e-10; analytic derivatives match numerical ones to 1e-6. |
| 1.4 | 0.4.0 | Layer 4: two-step estimator (probit, selection-corrected regime regressions, recovery of σ and ρ, first-stage-corrected covariance); FIML through `maxLik` (Newton-Raphson with the analytic Hessian, BFGS/BHHH and `optim` fallbacks); two-step starting values; multistart, restarts and boundary detection; `switch_fit()`. | Recovery on simulated data; multistart agreement. |
| 1.5 | 0.5.0 | Layer 6: covariance options (observed information, outer product of gradients, sandwich, cluster sandwich, delta method to natural-scale parameters); `switch_bootstrap()` (nonparametric and parametric, at most 2 cores on CRAN); `switch_diagnostics()` (gradient norm, Hessian eigenvalues and condition number, boundary flags, multistart table); `switch_validate()` (exclusion restrictions, strength of the excluded variables, a warning when identification rests on functional form alone, collinearity); Wald and LR tests of ρ₁ = ρ₀ = 0. | Unit tests; coverage spot checks. |
| 1.6 | 0.6.0 | Layer 7: per-observation conditional expectations (all four); ATT, ATU, ATE, TH, BH₁ and BH₀ with delta-method and bootstrap standard errors; `switch_effects()`, `switch_predict()`, `switch_counterfactual()` (all adopt, none adopt, a policy shift in Z, keeping the selection-outcome dependence); `switch_simulate()`; `switch_compare()`; S3 methods (`print`, `summary`, `coef`, `vcov`, `logLik`, `nobs`, `fitted`, `residuals`, `predict`, `simulate`, `confint`, `anova`, `update`, `model.frame`, `model.matrix`); the reproducibility record of spec section 14.2 stored in every fit; wrapper `esr()`; simulated dataset `firms`. | Expectations match simulation (acceptance criterion 5). |
| 1.7 | 0.7.0 | Monte Carlo study (spec section 9). Grid: N ∈ {250, 500, 1000, 2000, 5000}; selection rate ∈ {0.2, 0.5, 0.8}; (ρ₁, ρ₀) ∈ {(0, 0), (0.6, 0.4), (0.7, −0.5), (0.85, 0.85)}; strength of the exclusion restriction (strong, weak, none); variance ratio; effect heterogeneity. 1000 replications in the core cells and 500 elsewhere. Every measure of spec section 9.2 (bias, relative bias, RMSE, empirical SD, mean standard error, coverage, convergence and boundary rates, time), for both FIML and two-step. | `04_Validation/results/MC_G1.md` (acceptance criteria 1 and 4). |
| 1.8 | 0.8.0 | Cross-software validation: `sampleSelection::selection()` (Tobit-5, two-step and ML) on its documented examples and on simulated data; archived `endoSwitch` (FIML, treatment effects); a tolerance table covering coefficients, σ, ρ, log-likelihood, standard errors, ATT, ATU and counterfactual means. | `04_Validation/results/BENCHMARK_G1.md` (acceptance criteria 2 and 3). |
| 1.9 | 0.9.0 | Documentation and CRAN preparation: vignettes `classical-esr`, `treatment-effects` and `simulation-validation` (heavy results precomputed); every example under 5 s; README; `cran-comments.md`; `R CMD check --as-cran` clean locally; GitHub Actions on three operating systems after the owner creates the repository; win-builder and macOS builder (owner's approval). | Acceptance criterion 6. |
| 1.10 | 1.0.0 | Release: evidence table for acceptance criteria 1-6; computational and software gates; CRAN submission (the owner's action or approval). | Owner sign-off. |

### Generation 2: Generalized selection (v1.1.0 → v1.5.0)

| WP | Version | Deliverable |
| --- | --- | --- |
| 2.1 | 1.1.0 | Observation-mechanism layer (spec section 10.2): `heckman()` (Tobit-2: outcome observed only when S = 1), `treatment()` (common outcome equation with a structural shift, as in Maddala 1983 and the hybrid model of `endogenous`), `tobit5()`. Benchmarks against `sampleSelection::selection()` and `treatReg()`, and `endogenous`. |
| 2.2 | 1.2.0 | Multinomial-logit ESR with J ≥ 3: FIML following Lee (1983), with a Gaussian link between the maximum-utility index and each outcome; Dubin-McFadden (1984) and Bourguignon, Fournier and Gurgand (2007) two-step estimators with bootstrap standard errors. |
| 2.3 | 1.3.0 | Multinomial-probit ESR: FIML with (J−1)-dimensional conditional orthant probabilities (GHK on Halton draws with fixed seeds, Genz-Bretz through `mvtnorm` for exact evaluation); MNP covariance normalisation and identification checks. MNP and MNL are kept as distinct models (spec section 4B). C++ after profiling. |
| 2.4 | 1.4.0 | Ordered regime selection (ordered probit) and sequential selection (nested binary probits); nested logit where its consistency conditions hold. |
| 2.5 | 1.5.0 | Multivariate selection (several jointly normal binary selection equations, as in `switchSelection::msel`) and several Gaussian outcomes per regime; pairwise ATE_jk and ATT_jk (all J(J−1)/2 comparisons, with subpopulations); Monte Carlo study; benchmarks against `switchSelection`; vignette `multinomial-esr`. Gates. |

### Generation 3: Copula dependence (v2.0.0 → v2.5.0)

| WP | Version | Deliverable |
| --- | --- | --- |
| 3.1 | 2.0.0 | Copula engine with a common `copula_spec()` interface: Gaussian, Student-t, Clayton, Gumbel, Frank, Joe (with rotations), BB1, BB6, BB7, BB8. Each provides cdf, pdf, h-functions and their inverses, derivatives, Kendall's τ and tail-dependence mappings, and validity checks. Adapted from TriCopula where possible; cross-checked against `copula` and `VineCopula`. |
| 3.2 | 2.1.0 | Flexible margins through the full distribution interface: Student-t and skew-normal outcomes, logistic selection error. |
| 3.3 | 2.2.0 | Copula binary ESR likelihood, L = f_j(e) · P(S = j given ε_j = e), through h-functions, with the identified pair structure of decision D8 and analytic gradients by the chain rule. **Nesting test:** Gaussian copula with Gaussian margins reproduces the G1 log-likelihood and estimates to 1e-8. |
| 3.4 | 2.3.0 | Multivariate dependence for multi-outcome and multinomial systems: trivariate Gaussian and Student-t, validated nested Archimedean copulas, C- and D-vines. |
| 3.5 | 2.4.0 | Treatment effects under copulas (conditional expectations by adaptive quadrature over the conditional distributions); counterfactual simulation that keeps the dependence (conditional sampling through inverse h-functions); distributional effects with bounds (decision D8). |
| 3.6 | 2.5.0 | Dependence diagnostics and sensitivity: AIC, BIC and Vuong/Clarke tests across families; tail-dependence reporting; a copula sensitivity table for ATT, ATU and ATE; Monte Carlo per family; GJRM benchmarks where the models coincide; vignette `copula-esr`. Gates. |

### Generation 4: Generalized outcomes and robust estimation (v3.0.0 → v3.5.0)

| WP | Version | Deliverable |
| --- | --- | --- |
| 4.1 | 3.0.0 | Discrete-outcome machinery that keeps the marginal outcome model separate from the latent disturbance (spec section 3.2): binary (probit, logit), ordinal (ordered probit, logit) and count (Poisson, NB2; Terza 1998) outcomes, with likelihood contributions as copula rectangle probabilities. |
| 4.2 | 3.1.0 | Censored (Tobit), fractional (beta) and duration (Weibull, log-normal, log-logistic, with right censoring) outcomes. |
| 4.3 | 3.2.0 | Sample selection for every outcome type (for example binary and count outcomes observed only under selection) and double selection; benchmarks against GJRM and `sampleSelection`. |
| 4.4 | 3.3.0 | Joint multivariate outcome systems per regime with mixed types (for example productivity, innovation and new-product counts, spec section 4D) through a valid mixed-margin joint likelihood. |
| 4.5 | 3.4.0 | Robust estimation (`method = "robust"`): robust two-step estimating equations, robust Wald tests and influence functions (Zhelonkin, Genton and Ronchetti 2016); benchmarks against `ssmrob`. |
| 4.6 | 3.5.0 | Advanced inference: cluster, wild-score and bootstrap-t methods, BCa intervals, bootstrap convergence diagnostics; effects on the economic scale (probabilities, expected counts); Monte Carlo studies. Gates. |

### Generation 5: Panel and dynamic switching (v4.0.0 → v4.5.0)

| WP | Version | Deliverable |
| --- | --- | --- |
| 5.1 | 4.0.0 | Panel infrastructure: `panel = list(id, time)`, unbalanced panels, within-unit lags, clustering defaults, simulated dataset `firm_panel`. |
| 5.2 | 4.1.0 | Random-effects switching (selection effect c_i and regime effects a_ij, jointly normal), integrated by adaptive Gauss-Hermite quadrature up to dimension 3 and by simulated ML on Halton draws above that; Laplace through TMB as an option (Suggests). |
| 5.3 | 4.2.0 | Correlated random effects (Mundlak 1978; Chamberlain 1984); panel two-step estimators (Wooldridge 1995; Murtazashvili and Wooldridge 2016). |
| 5.4 | 4.3.0 | Dynamic selection with λ S_{i,t−1} and explicit initial-conditions treatment (Wooldridge 2005; Heckman 1981 approximation); reporting that separates state dependence from persistent heterogeneity. |
| 5.5 | 4.4.0 | Time-varying treatment effects, regime-transition matrices, AR(1) outcome disturbances. |
| 5.6 | 4.5.0 | Monte Carlo study, vignette `panel-esr`. Gates. |

### Generation 6: Spatial, hierarchical and Bayesian (v5.0.0 and beyond)

Research extensions (spec section 4F). Each stays `experimental` until its
Monte Carlo validation passes, and none is required for the first CRAN
release.

| WP | Version | Deliverable |
| --- | --- | --- |
| 6.1 | 5.0.0 | Hierarchical switching: nested random effects (firm within province within region) by quadrature or Laplace. |
| 6.2 | 5.1.0 | Spatial outcome dependence (SAR in the regime outcomes, with selection), using an estimator chosen in the G6 derivation document. |
| 6.3 | 5.2.0 | Spatial regime selection (SAR/SEM latent selection) by GHK or recursive importance sampling for moderate N; diagnostics that separate spatial dependence from spatial heterogeneity and cross-sectional dependence (spec section 4F). |
| 6.4 | 5.3.0 | Bayesian engine: Gibbs sampling with data augmentation for Gaussian switching (Chib and Hamilton 2000; Koop and Poirier 1997), documented priors, R-hat and effective-sample-size diagnostics, posterior treatment effects, partial pooling across countries and regions. |
| 6.5 | 5.4.0 | Joint sustainability indicators (economic, social and environmental outcomes; spec section 12.3) and cross-country random coefficients; vignette `spatial-esr`. Gates. |

**Size.** About 42 work packages. Each generation is a release the owner can
use and cite before the next one starts.

---

## 5. Quality system (every work package)

- **Tests:** unit tests for every margin, copula and likelihood against an
  independent computation; nesting tests (a restricted general model equals
  the special case); fast recovery tests on CRAN, with heavy tests marked
  `skip_on_cran()` (kept, never weakened); frozen regression references.
- **Numerical verification:** `verify_math.R` for each generation, re-run at
  every version.
- **Monte Carlo:** drivers in `04_Validation/scripts/`, raw output in
  `runs/`, summaries in `04_Validation/results/`. Seeds recorded.
- **Checks:** `R CMD check --as-cran` at every version, and GitHub Actions on
  three operating systems once the repository is on GitHub.
- **Reporting:** a progress note per work package, `NEWS.md` per version,
  and an acceptance-evidence table per generation.

---

## 6. What only the owner can do or decide

1. Approve this plan and decisions D1-D12.
2. Confirm the package metadata. Proposed, as for TriCopula: author and
   maintainer Ibrahim Niankara <Ibrahim.niankara@aau.ac.ae>; funder BRASS
   Digital Lab; licence MIT + file LICENSE.
3. Allow installation from CRAN of `sampleSelection`, `switchSelection`,
   `ssmrob` and `systemfit` (benchmarks, needed in G1/G2), and later `TMB`,
   `spdep` and `fastGHQuad`. Allow download of the archived `endoSwitch` 1.0.0
   source from the CRAN archive (benchmark only).
4. Create the GitHub repository and approve pushes, external check uploads
   and each CRAN submission.
5. Sign off each generation's econometric gate, starting with the G1
   derivation documents (WP1.1).

Items 1-3 were approved on 22 November 2026, together with the standing
authorisation for one local commit per finished work package (D12).

---

## 7. Risks and honest limits

- **Scale.** This is a multi-session programme. The plan front-loads the
  validated core, so G1 is useful on its own.
- **Research-grade components.** G6 (spatial probit selection, spatial
  outcomes under selection, Bayesian engine) is research-grade, as the
  specification says. Some parts may stay experimental.
- **Identification limits.** Some requested quantities are not identified
  (decision D8). The package will report bounds or stated assumptions rather
  than point estimates for them.
- **Computation.** Multinomial probit, high-dimensional copulas and spatial
  selection are computationally heavy. C++ and quadrature come in only after
  profiling.
- **CRAN check time** limits which tests run on CRAN. Heavy tests are kept
  for local and continuous-integration runs.

---

## 8. Next steps once approved

1. **WP1.1:** create the skeleton and `git init`; write the governance and
   architecture documents, the complete G1 derivation set and
   `verify_math.R`; check the empty package clean. Then stop for the owner's
   econometric gate.
2. Install the benchmark packages (if allowed), so that the WP1.3-1.4 code
   can be compared against `sampleSelection` from the first fitted model.
3. Proceed through WP1.2-WP1.10, with a progress note after each work
   package.
