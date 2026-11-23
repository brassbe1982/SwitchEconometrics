# Generation 2: Generalized selection (v1.1.0 → v1.5.0)

Status: **WP2.1 done (versions 1.1.0 and 1.1.1, 24 November 2026):**
`heckman()`, `treatment()` and `tobit5()`. Two of 428 pre-registered Monte
Carlo checks failed (coverage in one Heckman cell); the owner recorded
them as a documented exception on 24 November 2026 (section 5). Progress
note: [progress/WP2.1.md](progress/WP2.1.md). The G2 econometric gate was
closed by the owner on 23 November 2026. Next: WP2.2. Earlier note:
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
| 2.0 | (1.0.0, documents only) | G2 derivation set, `verify_math_g2.R`, `verify_math_g2b.R`, architecture updates, validation plans, gate | **done 2026-11-23**: 53/53 and 25/25 numerical checks; gate closed by the owner |
| 2.1 | 1.1.0 | `heckman()`, `treatment()`, `tobit5()`; benchmarks against `sampleSelection` and `endogenous` | **done 2026-11-23**: 802 test expectations; check clean; benchmarks 48/48; Monte Carlo 426/428 (two coverage checks with the owner) |
| 2.2 | 1.2.0 | MNL-ESR: Lee FIML; normal-score FIML (section 5, question 3); DMF and BFG two-step; $J$ up to 8 and beyond | next |
| 2.3 | 1.3.0 | MNP-ESR (FIML with Genz-Bretz and GHK; $J$ up to 8 by GHK; C++ only with profiling evidence and the owner's approval) | open |
| 2.4 | 1.4.0 | Ordered and sequential selection; nested logit | open |
| 2.5 | 1.5.0 | Multivariate selection, multiple outcomes, pairwise effects; Monte Carlo; `switchSelection` benchmarks; comparative analysis; vignette `multinomial-esr` | open |

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

## 5. Gate decision (owner, 23 November 2026)

The owner approved the 12 proposals of section 4 with amendments. The
owner's words, verbatim:

> regarding what i must decide, i approve the 12 proposals with the
> following amendments:
>
> Question 2: yes, allow installing the archived endogenous source into the
> private library.
>
> Question 3: if you can find a better (less restrictive) option we can use
> (which will be a contribution by itself compared to the lee alternative);
> otherwise, i accept Lee's transformation as the multinomial-logit FIML
> model, with the extra counterfactual assumption.
>
> Question 5: yes, keep the multinomial-probit normalisation, with the
> restricted "independent" covariance as default and the unrestricted one
> as an option.
>
> Question 9: yes, analytic scores with a differenced Hessian, exact
> probabilities up to dimension 3, simulated ones beyond (experimental),
> and no compiled code without profiling evidence. Note here that I would
> like the developed framework to be flexible enough to cover/handle up to
> 8 regimes (at least) with the possibility of further regime extension in
> prospective upgrades if needed.
>
> Question 11: the Monte Carlo design and thresholds, which become fixed
> once you approve.

The owner also asked that G2 be framed as closing a gap in the literature,
with comparative analysis against existing work where possible, and that
everything needed for the development of G2 be verified.

### What was done with each amendment

| Question | Action | Evidence |
| --- | --- | --- |
| 2 | `endogenous` 1.0 installed from the CRAN archive into `runs/lib_g2` (not into the owner's libraries). Its convention: mean $x'\beta - S\,v'\eta$, so $\delta = -\eta$ | X01, X02: its ML estimates equal the reference maximiser of our likelihood to 5e-6, its model-based standard errors to 1.4e-5 (relative), for the constant shift and for the hybrid model |
| 3 | A less restrictive full-likelihood model with multinomial-logit selection was derived: the **normal-score model** (MULTINOMIAL_ESR.md section 11). It has $J$ dependence parameters per regime, needs no extra assumption for counterfactual means, and has the BFG normalised two-step as its limited-information estimator. Lee's model is kept beside it | X10-X14: event identity, proper density, joint law and all conditional means for $J = 2, 3, 8$. **Not yet verified:** its score (not derived), its behaviour in estimation, its novelty |
| 5 | Unchanged from the proposal | |
| 9 | $J \ge 8$ made a requirement: no limit on $J$ in the code; closed-form models (Lee, ordered, sequential with independent stages) for any $J$; multinomial probit and the normal-score model by GHK when $J \ge 5$ (experimental). New tests G2-J8-1..3 and Monte Carlo cells L8, O8, P8 | X14, X20-X24: joint laws at $J = 8$ for the normal-score, Lee, probit and ordered models; GHK in 7 dimensions: error of $\log P$ 0.017 with 500 Halton draws, 0.008 with 2000; one GHK pass for 2000 observations takes 2.3 s in R |
| 11 | Sections 8.1-8.5 of MONTE_CARLO_DESIGN.md are fixed as approved. Section 8.6 adds cells for the amendments (designs G, L8, O8, P8) without altering any approved cell or threshold | |

### Owner's further decisions (23 November 2026, second message)

The four points left open above were put to the owner, who answered,
verbatim:

> yes, build WP2.1; and consider the following as my decisions:
>
> Default multinomial-logit model: yes, keep Lee (fast) as default; and
> ensure to have the normal-score model (less restrictive, slower) as an
> option for users.
>
> Added Monte Carlo cells (MONTE_CARLO_DESIGN.md section 8.6): OK. (in
> particular, the normal-score design is gated at N = 5000 with a bias
> threshold of 0.05 for its correlations).
>
> endogMNP: yes, install this Bayesian multinomial-probit package for a
> comparison in WP2.3.
>
> Push: the two local commits stay unpushed until you say so. yes, keep
> them local untill necessary to push

Consequences:
1. `dependence = "lee"` is the default of the multinomial-logit FIML
   model; `dependence = "normal_scores"` is offered (WP2.2).
2. The cells of MONTE_CARLO_DESIGN.md section 8.6 are pre-registered with
   the owner's approval and are fixed like sections 8.1-8.5.
3. `endogMNP` may be installed into the private library `runs/lib_g2` for
   WP2.3. It is not on CRAN (checked 23 November 2026); the archive holds
   version 0.2-1.
4. Nothing is pushed. All G2 commits stay local until the owner says to
   push.

### Owner's decisions after WP2.1 (24 November 2026)

Three recommendations of the WP2.1 report were put to the owner:

> 1. The two failed coverage checks: record a documented exception with a
>    caution in the help page of `heckman()`, or have me add a remedy first
>    (for example profile-likelihood intervals for rho). I recommend the
>    exception: the shortfall is small and disappears with sample size.
> 2. Near-boundary maxima: keep the multistart default as it is, or add a
>    warning when the best maximum has rho close to ±1 and another start
>    converged elsewhere. I recommend adding the warning.
> 3. `endogMNP`: I propose dropping it for G2 and reconsidering it for
>    Generation 4 (discrete outcomes).

The owner's answer, verbatim: "proceed accordingly with all recommended
actions validated on my side".

Done in version 1.1.1:
1. **Exception EX-G2-1.** The two failed coverage checks of design H
   ($N = 1000$, $\rho = 0.6$, FIML: `outcome:sigma` 0.925,
   `outcome:rho` 0.926, limit 0.93) are accepted as a documented
   exception. The threshold is unchanged and the checks stay recorded as
   failed in `gate_checks_G2.csv`. The help page of `heckman()` carries
   the caution. The exception covers these two checks of the 1.1.0 run
   only; the rerun with the release candidate in WP2.5 is evaluated
   afresh.
2. **Warning** of class `switch_warning_local_maximum` when the highest
   maximum has $\lvert\hat\rho\rvert > 0.95$ and another start converged
   to a lower local maximum. The multistart default and all estimates are
   unchanged.
3. **`endogMNP` dropped for G2**; to be reconsidered for Generation 4.

**Still with the owner:** compiled code for the multinomial probit with
many regimes, only if profiling in WP2.3 shows that pure R is impractical;
the evidence is brought to the owner then.

## 6. Positioning: what G2 contributes, and what may be claimed

The owner's reading is that the thin benchmarks point to a gap that G2
closes. The evidence supports this **for software**, and only partly for
econometric theory. To keep the manuscript and the documentation honest:

**Supported by what was found (searches of 23 November 2026, not a
systematic review):**
- No R package was found that estimates a multinomial endogenous switching
  regression with continuous outcomes by full-information maximum
  likelihood. `switchSelection` offers two-step estimation for that case.
- No software was found that gives, in one framework, FIML and two-step
  estimation, identification diagnostics, all pairwise treatment effects
  with their conditioning groups, and counterfactual scenarios for
  logit-based, probit-based, ordered, sequential and multivariate
  selection.
- The pairwise effects with explicit statements of the assumption each
  counterfactual relies on (L-CI for Lee; none for the normal-score and
  probit models; reference completion for cross-regime dependence) are
  not reported by any of the packages examined.

**Not to be claimed:**
- That the models themselves are new. Lee (1983), Dubin and McFadden
  (1984), Bourguignon, Fournier and Gurgand (2007) and the multinomial
  probit selection model are established. Stata's `cmp` (Roodman 2011)
  already offers simulated-likelihood estimation of systems with
  multinomial probit equations, and `selmlog` and `mtreatreg` cover
  two-step and latent-factor approaches.
- That the normal-score model is new, until a proper literature search has
  been done. It is a natural full-likelihood counterpart of the BFG
  normalised correction and may exist under another name.
- That the absence of an external benchmark shows correctness. It means
  the validation of those models rests on simulation, exact nesting and
  internal comparisons only, which is weaker than an independent
  implementation.

**Comparative analysis planned:** BENCHMARK_PROTOCOL.md section 6.3.
