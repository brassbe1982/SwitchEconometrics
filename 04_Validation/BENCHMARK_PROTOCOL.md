# Cross-software benchmark protocol

Status: WP1.1, 22 November 2026. Specification section 9.3; plan decision
D11 as amended by the owner (22 November 2026): R implementations only, no
Stata. **Executed for G1 in WP1.8 (22-23 November 2026)**: results in
[results/BENCHMARK_G1.md](results/BENCHMARK_G1.md); execution record in
section 5b.

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
| `endoSwitch` | 1.0.0 | archived on CRAN (2020); source downloaded from the CRAN archive and installed into the private library `runs/lib_bench` in WP1.8 (approved) | G1 FIML and treatment effects (historical reference) |
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

## 5a. Documented differences found during development

**D-SS-1: `sampleSelection` 1.2-16, Tobit-5 two-step (`heckit5fit`).**
Found in WP1.4 on 22 November 2026.

What `sampleSelection` does:
- It recovers $\sigma_j$ as `sqrt(se^2 + (betaL * delta)^2)`, i.e.
  $\hat\sigma_j^2 = s_j^2 + (\hat\theta_j\bar\delta_j)^2$. The Heckman (1979)
  and Greene (2012) consistent estimator is
  $\hat\sigma_j^2 = \overline{\hat\eta_j^2} + \hat\theta_j^2\bar\delta_j$,
  derived in LIKELIHOOD_DERIVATION.md section 9 and verified in V08 and V13.
- It uses the degrees-of-freedom-corrected residual standard error.
- It clips $\hat\rho_j$ to $\pm 0.99$.
- Its two-step covariance matrix fills only the probit block; outcome
  coefficients have no standard errors (NA).

Evidence (simulated data of the test suite; truth $\sigma_0 = 0.8$,
$\rho_0 = 0.4$, $\sigma_1 = 1.2$, $\rho_1 = 0.6$):

| n | SwitchEconometrics $\hat\sigma_0, \hat\rho_0, \hat\sigma_1, \hat\rho_1$ | `sampleSelection` |
| --- | --- | --- |
| 200 000 | 0.797, 0.376, 1.200, 0.604 | 0.784, 0.381, 1.144, 0.634 |
| 400 000 | 0.801, 0.405, 1.201, 0.602 | 0.786, 0.413, 1.145, 0.631 |

The shared parts agree to 4e-10: the probit, the outcome coefficients and
the correction-term coefficients (with the sign of the regime-0 regressor
mapped).

Consequences for the two-step benchmark:
- The probit, outcome and correction coefficients are compared at the
  two-step tolerance.
- $\hat\sigma_j$ and $\hat\rho_j$ are compared with the Heckman formula
  computed independently in the test suite, not with `sampleSelection`.
- Two-step standard errors are compared with the independent formula (test
  suite) and by Monte Carlo (WP1.7), because `sampleSelection` does not
  report them.

The FIML (`method = "ml"`) results of `sampleSelection` are unaffected and
agree with ours to 3e-10 in the coefficients and 1e-9 in the standard
errors.

Reporting this upstream would be an external action, so it is left to the
owner. The finding may also be relevant for the research article.

**D-ES-1: `endoSwitch` 1.0.0, `endoSwitch2Stage()`.** Found in WP1.8 on 22
November 2026.
- It recovers the variances as σ̂ⱼ² = mean(e² + θ̂ⱼ² λⱼ wᵢ), with λ₁ = φ/Φ,
  λ₀ = φ/(1 − Φ) and w the probit index.
- The Heckman (1979) estimator adds θ̂ⱼ² mean δⱼ, with δ₁ = λ₁(λ₁ + w) and
  δ₀ = λ₀(λ₀ − w). The λⱼ² term is missing, and for regime 0 the sign of
  the w term is wrong.
- At n = 200 000 and 400 000 its σ̂₁ is 1.139 against a truth of 1.2. The
  error does not shrink with n
  ([results/BENCHMARK_G1.md](results/BENCHMARK_G1.md) section 5).
- `endoSwitch` uses these values only as FIML starting values, but the
  exported function returns them to users.
- As for D-SS-1, the two-stage coefficients are compared at the two-step
  tolerance, and σⱼ and ρⱼ are listed as documented differences.

## 5b. Execution record for G1 (WP1.8)

- **Run.** Scripts `scripts/benchmark_g1.R` and
  `scripts/benchmark_g1_diagnostics.R`, with SwitchEconometrics 0.8.0.
  Every tolerance of section 3 was applied unchanged.
- **Datasets D6.**
  - The `sampleSelection` vignette's three Tobit-5 examples were
    regenerated with its own code and seeds.
  - The `?selection` Tobit-5 example sets no seed, so seed 0 was added.
  - The estimation calls pass the generated variables in a data frame
    instead of the global environment; the values are identical.
  - Where the vignette limits the iterations (`iterlim = 20`),
    `sampleSelection` was also run with its default, as a supplementary
    run.
- **Dataset D7.** Two specifications on `ImpactData`, both fixed before
  the run:
  - the documented example of `endoSwitch`;
  - a larger specification.
- **`endoSwitch` FIML.** Run with its default and with
  `reltol = 1e-14`, both decided before the run.
- **Where `endoSwitch` does not apply.** Its interface needs the same
  outcome regressors in both regimes, and selection regressors different
  from them, so it is not applied to D5 and D6.
- **Outcome.** 1048 of 1145 checks pass. Each of the 97 differences beyond
  tolerance is explained with evidence (BENCHMARK_G1.md section 4).
- **Fix in SwitchEconometrics.** The benchmarks exposed one weakness in
  SwitchEconometrics: the probit's stopping rule. It was fixed in 0.8.0
  (BENCHMARK_G1.md section 6), and the benchmarks were rerun.
- **0.8.1, at the owner's request.** Weighted and clustered fits were
  added, each fixed before its run:
  - D8, integer weights: compared with `sampleSelection` on replicated rows
    and the `sandwich` package (`sampleSelection` ignores weights in
    Tobit-5), and with `endoSwitch`'s `Weight`;
  - D8b, continuous weights: compared with `endoSwitch` only;
  - D9, clustered data: compared with `sampleSelection` and the `sandwich`
    package;
  - a Monte Carlo under clustering (`scripts/cluster_mc_g1.R`), because no
    software computes two-step cluster-robust standard errors.

  New documented difference **D-ES-2**: `endoSwitch` weights its
  likelihood but not its effects. Outcome: 1275 of 1378 checks pass, and
  all 103 differences are explained. AC3 is met with documented
  differences (owner, 23 November 2026).

## 5. Later generations

| Generation | Benchmarks | Where none exists |
| --- | --- | --- |
| G2 | `switchSelection::msel` (multinomial and multivariate), `sampleSelection` (Tobit-2, `treatReg`), `endogenous` | MNP-ESR with outcome dependence: simulation-only validation |
| G3 | `GJRM` (copula sample-selection and bivariate models where the specifications coincide); `copula` and `VineCopula` for the copula functions | copula ESR as such: nesting (Gaussian = G1) plus Monte Carlo |
| G4 | `GJRM`, `ssmrob`, `sampleSelection` (binary outcomes with selection) | mixed multivariate outcomes: Monte Carlo |
| G5, G6 | no R implementation of panel or spatial ESR is known | Monte Carlo and nesting tests only; stated in the release notes |

## 6. Generation 2 benchmarks

Status: **proposed at the G2 econometric gate** (23 November 2026).
Sections 1-5 are unchanged. Tolerances are those of section 3 unless a row
says otherwise; they are fixed before the runs.

### 6.1 Benchmark packages for G2

| Package | State on 23 November 2026 | G2 role |
| --- | --- | --- |
| `sampleSelection` 1.2-16 | installed | Tobit-2 (`selection`, ML and two-step); `treatReg` (ML and two-step); Tobit-5 as in G1 |
| `switchSelection` 2.1.0 | installed | `msel`: FIML for multivariate **ordered/binary** selection with continuous outcomes; two-step for **multinomial** selection (logit: Dubin-McFadden terms without the sum restriction; probit) |
| `nnet` 7.3-21, `mlogit` 2.0-0 | installed | multinomial-logit first step |
| `mvtnorm` 1.4-2 | installed | reference for the normal probabilities |
| `endogenous` 1.0 | not on CRAN (archived). **Installed on 23 November 2026 from the CRAN archive** (`src/contrib/Archive/endogenous/endogenous_1.0.tar.gz`, pure R, imports `mvtnorm`) into the private library `runs/lib_g2`, with the owner's approval (gate question 2) | hybrid structural-shift model. Convention established (checks X01-X02 of `verify_math_g2b.R`): it writes the mean as $x'\beta - S\,v'\eta$, so $\delta = -\eta$; $\rho$ as in decision D6; it has no `data` argument (variables are read from the calling environment); `se = "M"` is the inverse numerical Hessian of `optim` |

### 6.2 Comparisons

| Model | Benchmark | Quantities | Notes |
| --- | --- | --- | --- |
| `heckman()` FIML | `sampleSelection::selection(..., method = "ml")` | coefficients, $\sigma$, $\rho$, log-likelihood, standard errors | mapping verified at the likelihood level (W04) |
| `heckman()` two-step | `selection(..., method = "2step")` | probit, outcome and Mills-ratio coefficients | $\sigma$, $\rho$ and standard-error conventions to be established by simulation in WP2.1 first; any difference is documented as D-SS-1 was |
| `treatment()` FIML | `sampleSelection::treatReg(..., method = "ml")` | as Heckman, plus $\delta$ | mapping verified for a constant shift (W07); with modifiers `treatReg` takes interaction regressors, to be confirmed in WP2.1 |
| `treatment()` two-step | `treatReg(..., method = "2step")` | coefficients | conventions to be established in WP2.1 |
| `treatment()` with `shift = ~ modifiers` | `endogenous::hybrid()` | coefficients, $\sigma$, $\rho$, standard errors (`se = "M"`); log-likelihood by our engine at both estimates (it returns none) | approved and installed. Reference result before any package code: estimates equal to 5e-6, model-based standard errors to 1.4e-5 relative (X01, X02) |
| `tobit5()` | `sampleSelection::selection()` Tobit-5 | as G1 | the G1 benchmark rerun through the new interface |
| MNL first step | `nnet::multinom`, `mlogit` | coefficients, log-likelihood | tolerance $10^{-6}$ on coefficients after tightening their convergence settings |
| MNL two-step `"bfg1"` | `msel(type3 = "logit", estimator = "2step")` | $\beta_j$ and correction coefficients | its base is the last alternative; conventions by simulation in WP2.2 |
| MNP two-step | `msel(type3 = "probit", estimator = "2step")` | $\beta_j$ and correction coefficients | its correction terms are defined through the gradient of the log-probability; whether they span the same regressors as ours is to be established in WP2.3 |
| MNL with Lee, FIML; nested logit; MNP-ESR FIML | **none found** | | simulation-only (designs L, N, P) plus nesting tests; stated in the release notes |
| Ordered selection FIML | `msel` with one ordered equation and continuous outcomes, `estimator = "ml"` | coefficients, cuts ($\mu_j - \gamma_0$), $\sigma_j$, $\rho_j$, log-likelihood, standard errors | conventions by simulation in WP2.4 |
| Multivariate selection FIML | `msel` with two binary equations, `estimator = "ml"` | as above, plus $R_u$ | conventions by simulation in WP2.5 |
| Sequential selection | `msel` with `groups` excluding unobserved later stages, if its observability rules reproduce the model | | to be established in WP2.4; otherwise simulation-only |
| Several outcomes per regime | `msel` with several continuous equations | | to be established in WP2.5 |
| Pairwise effects | none reports them in our definitions | | our formulas evaluated at both sets of estimates, as for `sampleSelection` in G1; and simulation (G2 acceptance criterion 5) |

**Datasets** (fixed seeds, saved in `runs/benchmarks_g2/`): one dataset per
Monte Carlo design of MONTE_CARLO_DESIGN.md section 8.2 at $N = 2000$ and
$N = 10\,000$; the documented examples of `sampleSelection` for Tobit-2 and
`treatReg` (with their own code and seeds); the examples of the `msel` help
page that match a G2 model.

**Additional tolerance for G2.** FIML log-likelihoods that involve bivariate
or trivariate normal probabilities: $\lvert\Delta\ell\rvert \le 10^{-3}$
(other packages may integrate numerically with looser tolerances); the
"ours $\ge$ theirs $- 10^{-6}$" rule of section 3 is kept when both
log-likelihoods are evaluated by our engine at the two estimates.

**Reporting:** `04_Validation/results/BENCHMARK_G2.md`, generated by
`04_Validation/scripts/benchmark_g2.R`, with the structure of section 4.

### 6.3 Comparative analysis with existing software (added at the gate closing, 23 November 2026)

The owner asked that G2 be developed as closing a gap and that comparisons
with existing software be made wherever possible. What exists, as far as
the searches of 23 November 2026 show (not a systematic review):

| Software | What it offers | Use in G2 |
| --- | --- | --- |
| `switchSelection::msel` (R, CRAN) | two-step for multinomial (logit, probit) selection with continuous outcomes; FIML for ordered/binary multivariate selection | benchmark (section 6.2) |
| `sampleSelection` (R, CRAN) | Tobit-2, Tobit-5, `treatReg` | benchmark |
| `endogenous` (R, archived) | Heckman selection and hybrid model | benchmark (installed) |
| `endogMNP` 0.2-1 (R, archived on CRAN; 2010) | Bayesian multinomial probit with endogenous selection (Burgette and Nordheim). Its help page shows that **the outcome is itself a discrete choice** (argument `outBase`, the base category of the outcome), not a continuous variable | **not usable for G2.** The owner approved its installation (23 November 2026); the source from the CRAN archive does not compile under R 4.6.2 (its C code calls LAPACK with signatures that R no longer accepts), and it was not patched. Because its outcome is discrete it would not be a benchmark for the continuous-outcome models of G2 in any case; it is a candidate comparison for Generation 4 (discrete outcomes), where a decision on patching it can be put to the owner. **Dropped for G2 by the owner's decision of 24 November 2026** |
| Stata `cmp` (Roodman 2011) | mixed-process models by simulated likelihood (GHK), including multinomial probit equations and observation-specific models, which can express switching regressions | not runnable here (Stata is out of the plan, decision D11); cited as the closest existing full-likelihood implementation for the probit case |
| Stata `selmlog` (Bourguignon, Fournier, Gurgand) | two-step Lee, Dubin-McFadden and BFG corrections | not runnable; our `"dmf"`, `"bfg1"`, `"bfg2"` are checked by simulation (design D) and against `msel` where conventions agree |
| Stata `mtreatreg` (Deb and Trivedi) | multinomial treatment with latent factors, simulated likelihood, common outcome equation | not runnable; a different model (mixed logit selection); cited |

**Internal comparisons** replace the missing external FIML benchmarks and
are reported in `BENCHMARK_G2.md` and `MC_G2.md`:
1. FIML against its own two-step estimator for every model (same data).
2. Lee against the normal-score model, the Dubin-McFadden/BFG corrections
   and the multinomial probit on the same data sets, in both directions of
   misspecification (designs L, D, G, P).
3. Exact nesting: $J = 2$ probit and ordered models against G1.

What may be claimed, and what may not, is in GENERATION_2.md section 6.

### 6.4 Execution record and documented differences (WP2.1, 23 November 2026)

Script `04_Validation/scripts/benchmark_g2.R`; results in
`results/BENCHMARK_G2.md`. Version 1.1.0 installed in `runs/lib_g2`.

| Id | Difference | Cause (established, not assumed) |
| --- | --- | --- |
| D-SS-2 | On the Mroz (1987) example of `sampleSelection`, our default fit (3 starts) reaches a log-likelihood of $-1479.65$ with $\hat\rho = 0.993$; `sampleSelection` reports $-1581.26$ with $\hat\rho = -0.13$ | The Tobit-2 likelihood of this example has two local maxima. Our likelihood evaluated at the `sampleSelection` estimates equals its log-likelihood, and our fit from the two-step start alone (`starts = 1`) reproduces its estimates and standard errors within the tolerances. The multistart finds the higher maximum from two perturbed starts; it lies close to the boundary $\rho = 1$, which the fit reports (one lower local maximum recorded in `fit$starts`; identification check I9). Neither package is in error |
| D-SS-3 | Two-step standard errors of the outcome coefficients differ from `sampleSelection` by up to $2.3 \times 10^{-4}$ (relative) | We use the expected (Fisher) information of the probit for $\hat V_\gamma$, as in Generation 1; `sampleSelection` uses the observed information. With the observed information in the same formula the standard errors agree to $2 \times 10^{-10}$ or better (toleranced row of the benchmark) |
| not run | `treatment()` two-step against `treatReg(method = "2step")` | `treatReg(..., method = "2step")` stops with the error "unknown type" in `sampleSelection` 1.2-16. The treatment two-step estimator therefore has no external benchmark; it is checked against a direct least-squares computation in the package tests, by check W08 of `verify_math_g2.R` and by Monte Carlo designs T and Th |
| note | `endogenous::hybrid()` with its default starting values stops in `optim()` ("non-finite finite-difference value") on 2 of the 4 benchmark datasets | Its optimiser works on the untransformed $\rho$ and starts from the sample correlation of the treatment and the outcome. It is then restarted from **our two-step estimates** (not from our FIML estimates), and converges to our FIML estimates within the tolerances |

Convention established for the Heckman two-step: $\hat\sigma$ and
$\hat\rho$ of `sampleSelection`'s Tobit-2 two-step equal ours to
$10^{-10}$ (unlike its Tobit-5 two-step, D-SS-1).

### 6.5 Execution record and documented differences (WP2.2, 24 November 2026)

Version 1.2.0 in `runs/lib_g2`; `switchSelection` 2.1.0, `mlogit` 2.0.0,
`nnet` 7.3-21 from the R library of this machine. Comparisons decided
before the run: multinomial logit first step against `mlogit` and `nnet`;
two-step `"bfg1"` against `msel(type3 = "logit", estimator = "2step")`,
whose convention was read from its help page and confirmed on one
simulated data set that is not among the benchmark data sets.

| Id | Difference | Cause (established, not assumed) |
| --- | --- | --- |
| D-MS-1 | Stacked-sandwich standard errors of the outcome and correction coefficients differ from msel's by up to 1.3% | msel uses the Jacobian of the sample moments; ours leaves out the mean-zero residual term of the cross block. With the sample Jacobian (numerical derivative of the stacked moments) in the same formula the standard errors agree to 5.4e-6 (toleranced row) |
| D-MS-2 | Outcome and correction coefficients differ from msel's by 5.2e-6 ($N = 2000$) and 1.4e-6 ($N = 10\,000$), outside the tolerance 1e-6 | msel's multinomial logit is not converged to that precision (largest score element 9e-4 and 1.8e-3 at its estimates, below 3e-13 at ours). Our second step at msel's first-step estimates agrees to 2e-15 (toleranced row) |
| none available | FIML of Lee's model; `"dmf"`; `"bfg2"`; the normal-score model | no software available here estimates them (section 6.3) |
