# WP2.0: Generation 2 derivation set and econometric gate

Package version unchanged: 1.0.0. Documents only. Completed 23 November
2026 by the Generation 2 session (handoff `HANDOFF_G2.md`, workspace root).
Status: **done; awaiting the owner's G2 econometric gate.** No G2 model
code was written.

## Step 0: the ground (handoff section 6)

| Item | Found |
| --- | --- |
| Repository | `main`, clean, at `6081cbd`, in sync with `origin/main` (no unpushed commit); one worktree |
| R | 4.6.2 (2026-10-29 ucrt) |
| Installed | `sampleSelection` 1.2-16, `switchSelection` 2.1.0, `mlogit` 2.0-0, `nnet` 7.3-21, `mvtnorm` 1.4-2, `Rcpp` 1.1.2, `RcppArmadillo` 15.6.2-1, `numDeriv` 2016.8-1.1, `maxLik` 1.6-10, `randtoolbox` 2.0.5, `testthat` 3.3.2, `roxygen2` 8.1.1; SwitchEconometrics 1.0.0 in the personal library |
| Missing | `endogenous`: not installed, and **not on CRAN** (absent from `available.packages()` at cloud.r-project.org on 23 November 2026). The CRAN archive was not consulted |

## What was done

1. **Derivation documents** (`01_Econometric_Architecture/`):

   | Document | Content |
   | --- | --- |
   | `OBSERVATION_MECHANISMS.md` (new) | `heckman()` (Tobit-2), `treatment()` (shift and hybrid model, as a linear restriction of the ESR), `tobit5()`; likelihoods, scores, Hessians, two-step estimators with corrected covariances, effects, identification, benchmark mappings |
   | `GAUSSIAN_REGION_ENGINE.md` (new) | One model for multinomial probit, ordered, sequential and multivariate selection: Gaussian latent vector, regimes as rectangles of a linear transform; likelihood; parameterisation by canonical partial correlations with a shared selection block; Plackett derivatives; score and Hessian strategy; truncated moments; two-step; GHK; nesting of G1; cross-regime dependence |
   | `MULTINOMIAL_ESR.md` (new) | Multinomial logit with Lee's transformation (likelihood, analytic score and Hessian, two-step, counterfactual assumption L-CI); Dubin-McFadden and Bourguignon-Fournier-Gurgand corrections; nested logit and its consistency conditions; multinomial probit and its normalisation; the models side by side; identification |
   | `ORDERED_SEQUENTIAL.md` (new) | Ordered probit selection in closed form (analytic Hessian); sequential selection as an engine instance; what is identified at each stage |
   | `MULTIVARIATE_SELECTION.md` (new) | Several binary selection equations; several Gaussian outcomes per regime |
   | `TREATMENT_EFFECTS.md` s.7-11 | $J \times J$ conditional expectations; pairwise $ATE_{jk}$, $ATT_{jk}$, $ATU_{jk}$, $TE_{jk \mid l}$; standard errors; scenarios |
   | `IDENTIFICATION.md` s.8 | G2 versions of I1-I11; new diagnostics I4b and I12 |
   | `PARAMETERIZATION.md` s.7, `GENERAL_MODEL.md` s.9 | G2 transformations; G2 instances of the general model |

2. **`verify_math_g2.R`** (new, beside `verify_math.R`, which is unchanged)
   with `verify_math_g2_results.csv`.
3. **Architecture updates** (`02_Computational_Architecture/`):
   `NUMERICAL_METHODS.md` s.7, `SOFTWARE_ARCHITECTURE.md` s.7,
   `API_SPECIFICATION.md` s.5 (the specification's section 6.3 syntax runs
   as written; no G1 signature changes).
4. **Validation plans** (`04_Validation/`): `MONTE_CARLO_DESIGN.md` s.8
   (14 designs, about 34 000 replications, thresholds proposed for
   pre-registration), `BENCHMARK_PROTOCOL.md` s.6, `ACCEPTANCE_TESTS.md`
   s.4-5 (G2 criteria and gate record; the G1 rows are untouched).
5. **`GENERATION_2.md`**: status column and 12 gate questions, each with a
   proposed answer and reason.
6. **`05_References/REFERENCES.bib`**: 14 entries added, all marked "to be
   verified".

## Evidence

**`verify_math_g2.R`: 53 of 53 checks pass** (175 s; R 4.6.2, mvtnorm 1.4-2,
numDeriv 2016.8-1.1, sampleSelection 1.2-16).

| Area | Checks | Result |
| --- | --- | --- |
| Heckman | W01-W04 | contribution equals the integrated density (4e-16); analytic score and Hessian equal numerical ones (5e-10, 1e-9); nesting identity with the ESR (3e-13); our log-likelihood at `sampleSelection`'s Tobit-2 ML estimates equals its value (difference 0), score there 1.8e-6 |
| Treatment | W05-W08 | log-likelihood equals the restricted ESR per observation (2e-15); score $A'g$ and Hessian $A'HA$ equal numerical ones (4e-9, 3e-9); conditional mean and variance (3e-14); our log-likelihood at `treatReg`'s ML estimates equals its value (9e-13); two-step consistent at $n = 400\,000$ (0.0097) and its standard errors within 5.6% of the empirical standard deviations (400 replications, $n = 1000$) |
| Multinomial logit, Lee | W10-W12, W15, W16 | the transformation and the event identity (exact; $\lvert z\rvert \le 1.74$); proper density (6e-17); simulated joint law ($\lvert z\rvert \le 1.42$); all nine conditional means including the invariance under L-CI ($\lvert z\rvert \le 2.09$); the general random-utility identity ($\lvert z\rvert \le 1.81$); analytic score and Hessian (7e-9, 9e-8) |
| Dubin-McFadden, BFG | W13, W14 | conditional Gumbel moments and the normalised moments ($\lvert z\rvert \le 1.22$, 1.36) |
| Region engine | W20-W29 | Plackett derivatives (2e-11); MNP contribution against the trivariate normal (1e-16); **$J = 2$ equals G1** in log-likelihood and score (2e-15, 1e-15); MNP score against the numerical gradient (3e-9); the proposed Hessian (central difference of the analytic score) against the numerical Hessian (4e-9; 25 observations); valid parameterisation; GHK error 5.5e-4 (500 draws) and 1.7e-4 (2000); truncated means and covariances (6e-16, 4e-12); MNP conditional expectations by simulation ($\lvert z\rvert \le 1.26$); adding-up (6e-17); cross-regime completion |
| Ordered | W30-W33 | contribution (9e-16); analytic score and Hessian (4e-8, 1e-7); **$J = 2$ equals G1** (9e-16); equals the region engine (9e-16); conditional moments (5e-11) |
| Sequential, multivariate, $K = 2$ | W34-W36 | contributions against closed forms and the trivariate normal (9e-16, 0); scores against numerical gradients (3e-9, 9e-10); $K = 2$ marginalises to $K = 1$ (4e-15) |
| Nested logit | W37, W38 | simulated probabilities ($\lvert z\rvert \le 2.56$); derivatives (3e-11); Lee counterfactual moment by quadrature against simulation ($\lvert z\rvert \le 1.74$); logit special case (4e-10) |

Simulation checks pass when the largest $\lvert z\rvert$ is at most 4, as in
G1.

**Other facts established**
- `switchSelection::msel` 2.1.0 (help page read, nothing run): for
  multinomial selection with continuous outcomes it offers **two-step
  only**; FIML with continuous outcomes exists for ordered/binary
  multivariate selection. Consequence: no external FIML benchmark for Lee's
  model, the nested logit or the MNP-ESR (BENCHMARK_PROTOCOL.md s.6).
- Regime shares of the Monte Carlo designs were simulated before fixing
  them, for the designs whose shares the table gives (no regime below
  0.15). They were not computed for designs Pu, Lw and Pw.

## Not verified, and limits

- **No package code**, so no test suite, `R CMD check` or version change in
  this work package. The G1 suite and `verify_math.R` were not rerun: no
  file they read was changed.
- **Corrected two-step covariances** other than the treatment model's
  (W08b): Lee's two-step, the ordered two-step, and the stacked sandwich
  for the region models and for the Dubin-McFadden and BFG corrections are
  derived by the G1 algebra but not checked by simulation yet. Each is
  checked by Monte Carlo in its work package before it is offered.
- **$\sigma_j$ and correlations under the Dubin-McFadden and BFG
  corrections** are not derived; the documents say they are not reported.
- **Multinomial probit with $J \ge 4$:** the model checks use $J = 3$; the
  derivative formulas are checked for three-dimensional rectangles and GHK
  up to dimension 4, on 18 regions only.
- **Benchmark conventions** not yet established by simulation: every
  `switchSelection` mapping; `sampleSelection`'s two-step conventions for
  Tobit-2 and `treatReg`; `treatReg` with interaction terms; `endogenous`
  (not installed).
- **Numerical routines not written:** the vectorised bivariate and
  trivariate normal cdf, the quadrature node counts, and the package's own
  finite differences are specified, with the tests they must pass.
- **References:** the 14 new entries are from memory and marked "to be
  verified".
- **Computing time** of the region models is unknown until WP2.3; the
  Monte Carlo design assumes the pure-R route is fast enough on 3 cores.

## Disappointing or notable results

None of the checks failed. Three findings narrow what G2 can claim:
1. Lee's model needs an additional assumption (L-CI) for counterfactual
   means, and under the multinomial logit it makes them equal across all
   other regimes.
2. With multinomial-logit selection and $J = 2$, Lee's model is not G1.
   Only the multinomial probit nests G1 exactly.
3. No external FIML benchmark exists for three of the G2 models, and
   `endogenous` has left CRAN.

## For the econometric gate (owner)

The 12 questions of `GENERATION_2.md` section 4, with proposed answers. The
gate can be closed in stages: questions 1, 2 and 10-12 are enough to start
WP2.1.

## Next

After the gate: WP2.1 (1.1.0). Its first step is to freeze the 1.0.0
results on `firms` as test references, before any shared engine file is
edited.
