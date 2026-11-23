# Generation 2: Generalized selection (v1.1.0 → v1.5.0)

Status: **derivation set written and numerically verified (23 November
2026); G2 econometric gate put to the owner; no G2 model code exists.**
Package version unchanged at 1.0.0. Progress note:
[progress/WP2.0.md](progress/WP2.0.md).

## 1. Scope (specification sections 4B, 10.1, 11.3, 13)

- Observation mechanisms beyond switching, using the G1 Gaussian engine:
  - `heckman()`: Tobit-2, outcome observed only when $S = 1$;
  - `treatment()`: a common outcome equation with an intercept shift (or the
    hybrid structural-shift model);
  - `tobit5()` (plan decision D7).
- Multinomial regime selection with $J \ge 3$:
  - multinomial logit with outcome dependence: FIML via Lee (1983); two-step
    via Dubin and McFadden (1984) and Bourguignon, Fournier and Gurgand (2007);
  - multinomial probit with outcome dependence: FIML with $(J-1)$-dimensional
    conditional orthant probabilities (Genz-Bretz; GHK).

  MNL and MNP are distinct models, with different identification and
  disturbance dependence (specification section 4B).
- Ordered and sequential regime selection; nested logit where its
  consistency conditions hold.
- Multivariate selection (several binary selection equations) and several
  Gaussian outcomes per regime.
- Pairwise effects $ATE_{jk}$, $ATT_{jk}$: all $J(J-1)/2$ comparisons, also
  for subpopulations.

## 2. Work packages

| WP | Version | Content | Status |
| --- | --- | --- | --- |
| 2.0 | (1.0.0, documents only) | G2 derivation set, `verify_math_g2.R`, architecture updates, validation plans, gate questions | **done 2026-11-23**: 53/53 numerical checks; awaiting the owner's econometric gate |
| 2.1 | 1.1.0 | `heckman()`, `treatment()`, `tobit5()`; benchmarks against `sampleSelection` and `endogenous` | waiting for the gate |
| 2.2 | 1.2.0 | MNL-ESR (Lee FIML; DMF and BFG two-step) | waiting for the gate |
| 2.3 | 1.3.0 | MNP-ESR (FIML with Genz-Bretz and GHK; C++ after profiling) | waiting for the gate |
| 2.4 | 1.4.0 | Ordered and sequential selection; nested logit | waiting for the gate |
| 2.5 | 1.5.0 | Multivariate selection, multiple outcomes, pairwise effects; Monte Carlo; `switchSelection` benchmarks; vignette `multinomial-esr` | waiting for the gate |

## 3. Acceptance criteria

1. Monte Carlo recovery for each selection mechanism.
2. **Exact nesting.** With $J = 2$, MNP-ESR reduces to G1 with log-likelihood
   equal to 1e-8. The Heckman likelihood reduces to `sampleSelection` Tobit-2.
3. Benchmarks against `switchSelection`, `sampleSelection` and `endogenous`
   within the protocol tolerances.
4. Coverage within [0.93, 0.97] in gated cells.
5. Pairwise effects verified by simulation.
6. Checks on three operating systems.

The concrete tests are in
[ACCEPTANCE_TESTS.md](../04_Validation/ACCEPTANCE_TESTS.md) section 4.

## 4. Questions for the G2 econometric gate (owner)

Each question has a proposed answer and its reason. The documents are in
`01_Econometric_Architecture/`; "W.." are checks of `verify_math_g2.R`.

**The gate can be closed in stages.** Questions 1 and 2, with 10-12, are
enough to start WP2.1 (`heckman()`, `treatment()`, `tobit5()`), which uses
only the G1 engine. Questions 3-9 concern WP2.2-WP2.5.

### Observation mechanisms (WP2.1)

1. **What `treatment()` and `tobit5()` are.**
   *Proposed:*
   - `treatment()` is one outcome equation with a shift $S\,d'\delta$,
     $d = 1$ by default (intercept shift) or `shift = ~ modifiers` (the
     hybrid structural-shift model), with one $\sigma$ and one $\rho$. It is
     the ESR under a linear restriction, so the G1 engine is reused exactly
     (W05: equal per observation to 2e-15).
   - `tobit5()` is a second interface to the G1 likelihood with the
     `sampleSelection` ordering of the two outcome equations; it allows
     different response variables and then reports no treatment effects.
   - `heckman()` observes the outcome when $S = 1$.

   *Reason:* specification section 10.1-10.2; these are the definitions
   under which the likelihoods equal `sampleSelection`'s (W04, W07).
   ([OBSERVATION_MECHANISMS.md](../01_Econometric_Architecture/OBSERVATION_MECHANISMS.md))
2. **The `endogenous` benchmark.** The package is no longer on CRAN.
   *Proposed:* the owner decides whether to allow installing its archived
   source into the private library `runs/lib_g2` (as for `endoSwitch` in
   G1). Without it, the hybrid model is validated by `treatReg`, the exact
   nesting in the ESR and Monte Carlo, and G2 acceptance criterion 3 is
   recorded as met without `endogenous`, with the reason.

### Multinomial models (WP2.2-WP2.4)

3. **Lee's transformation as the MNL-ESR FIML model** (question of the
   plan). *Proposed: yes.* A Gaussian copula with correlation $\rho_j$
   between regime $j$'s maximum-utility index and its outcome disturbance;
   sign convention: $\rho_j > 0$ means unobservables favouring regime $j$
   raise its outcome. Two consequences to accept with it:
   - **Counterfactual means need one more assumption (L-CI):** the outcome
     disturbance depends on the utilities only through that index. Under
     it, and under the multinomial logit, $E[Y_j \mid S = k]$ is the same
     for every $k \ne j$ (W12).
   - With $J = 2$ the model has logit selection and is **not** G1; G1 is
     nested by the multinomial probit.

   *Reason:* it is the only logit-based specification with a full
   likelihood; its restrictions (Schmertmann 1994; Bourguignon et al. 2007)
   are documented, and the two-step corrections and the probit are offered
   beside it.
   ([MULTINOMIAL_ESR.md](../01_Econometric_Architecture/MULTINOMIAL_ESR.md)
   section 3)
4. **Two-step corrections with multinomial-logit selection.** *Proposed:*
   `correction = "lee"`, `"dmf"` (with the sum restriction), `"bfg1"`
   (without it), `"bfg2"` (normalised); bootstrap standard errors for the
   last three; $\sigma_j$ and correlations not reported for them in G2
   (their recovery is not derived). *Reason:* the plan names
   Dubin-McFadden and Bourguignon-Fournier-Gurgand; the moment formulas are
   verified (W13, W14). (MULTINOMIAL_ESR.md section 4)
5. **MNP covariance normalisation** (question of the plan). *Proposed:*
   utility differences against a base alternative (first level by
   default), $\operatorname{Var}$ of the first difference fixed at 1;
   default `selection_covariance = "independent"`, with `"unrestricted"`
   offered and checked. Outcome dependence: $J - 1$ correlations per
   regime with the base differences. *Reason:* with $J = 2$ this is G1
   exactly (W22: 1.8e-15); the unrestricted covariance is identified only
   through the functional form when regressors are common to all
   alternatives (Keane 1992). (MULTINOMIAL_ESR.md section 6)
6. **Minimum exclusion restrictions per regime** (question of the plan).
   *Proposed:* none is required (formal identification through the
   distributional assumptions, as assumption A7 of G1); the software
   recommends and checks (a) one excluded variable per regime, (b) for
   models with several correction terms per regime, that the excluded
   variables move the selection indices in as many directions as there are
   terms (new diagnostic I4b), (c) a coefficient excluded from one utility
   when the selection covariance is unrestricted (new diagnostic I12).
   (MULTINOMIAL_ESR.md section 8;
   [IDENTIFICATION.md](../01_Econometric_Architecture/IDENTIFICATION.md)
   section 8)
7. **Cross-regime outcome dependence for $J \ge 3$** (question of the
   plan). *Proposed:* as decision D8: never estimated; the $J(J-1)/2$
   correlations are listed as not identified; quantities that need them
   use the reference completion (conditional independence given the
   selection disturbances, which reduces to $r_{10} = \rho_1\rho_0$) or
   pairwise bounds, with the statement that the bounds are sharp pair by
   pair but not jointly (W28).
   ([GAUSSIAN_REGION_ENGINE.md](../01_Econometric_Architecture/GAUSSIAN_REGION_ENGINE.md)
   section 11)
8. **Ordered, sequential and nested-logit conventions.** *Proposed:*
   - ordered: intercept kept, first threshold fixed at 0, so that $J = 2$
     is G1 literally (W32);
   - sequential: default independent stage disturbances, unrestricted
     offered; counterfactual means that need non-identified correlations
     are computed under a stated zero-partial-correlation assumption and
     marked;
   - nested logit: $\lambda_g \in (0, 1)$ by parameterisation (values above
     1 not offered), Lee-type likelihood, Dubin-McFadden corrections
     refused.

   ([ORDERED_SEQUENTIAL.md](../01_Econometric_Architecture/ORDERED_SEQUENTIAL.md);
   MULTINOMIAL_ESR.md section 5)

### Estimation and effects

9. **Derivatives and probabilities for the Gaussian region models.**
   *Proposed:* analytic score (Plackett derivatives; W20, W23); Hessian by
   central differences of the analytic score; deterministic probabilities
   up to dimension 3 ($J \le 4$, $M \le 3$); GHK on Halton draws beyond,
   marked experimental, with sandwich standard errors; effect standard
   errors by the delta method with numerically differentiated effects for
   these models. No compiled code unless profiling evidence is brought to
   the owner. *Reason:* an analytic Hessian needs second derivatives of
   multivariate normal rectangles; where probabilities are deterministic
   the differenced score reproduced the numerical Hessian of the
   log-likelihood to 4.3e-9 in the one case checked (W29: multinomial
   probit, $J = 3$).
   (GAUSSIAN_REGION_ENGINE.md sections 5 and 8)
10. **Pairwise effects.** *Proposed:* $ATE_{jk}$, $ATT_{jk}$ (conditional
    on $S = j$), $ATU_{jk}$ (conditional on $S = k$), $TH_{jk}$, and
    $TE_{jk \mid l}$ on request; the $J \times J$ table of conditional
    expectations; every effect carries its conditioning group and, where
    it applies, the stated assumption it relies on.
    ([TREATMENT_EFFECTS.md](../01_Econometric_Architecture/TREATMENT_EFFECTS.md)
    sections 7-11)

### Validation

11. **Monte Carlo design and pre-registered thresholds**
    ([MONTE_CARLO_DESIGN.md](../04_Validation/MONTE_CARLO_DESIGN.md)
    section 8). Approval fixes them. Points to look at: which cells are
    gated; the looser bias threshold (0.05) for the correlations of the
    two-dimensional region models; the convergence threshold of 97% for
    those models; the nested logit gated only on $\beta$, $\sigma$ and
    $ATE$.
12. **Benchmark protocol for G2**
    ([BENCHMARK_PROTOCOL.md](../04_Validation/BENCHMARK_PROTOCOL.md)
    section 6): no external benchmark was found for FIML with Lee's model,
    the nested logit with outcomes or the MNP-ESR; they are validated by
    simulation and nesting only.

### Smaller design decisions (confirm or change)

- Default `selection_family` of `multinomial_switch()`: multinomial logit
  (closed-form FIML).
- Multivariate selection: every observed combination is a regime; a
  combination without an outcome equation contributes its probability only.
- Several outcomes per regime: Gaussian only, all observed within the
  regime.
- Removing an alternative from the choice set as a counterfactual scenario
  is not offered in G2.
