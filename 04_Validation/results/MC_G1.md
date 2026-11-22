# Monte Carlo study, Generation 1: results and interpretation

WP1.7, 22 November 2026. Design and thresholds:
[MONTE_CARLO_DESIGN.md](../MONTE_CARLO_DESIGN.md), pre-registered in WP1.1
before any estimator code existed. The full generated tables are in
[MC_G1_generated.md](MC_G1_generated.md). The per-check gate results are in
`gate_checks_G1.csv` and the per-cell summaries in `mc_g1_summary.csv`.

## 1. Verdict

**Owner decision, 22 November 2026: the diagnosis is accepted (section 9,
option 1).**
- AC1 and AC4 are met, with the ten failed checks and the AC4(b) result
  recorded as documented exceptions.
- The thresholds are unchanged.

**The pre-registered gate is not passed: 491 of 501 gated checks pass and 10
fail.** Under MONTE_CARLO_DESIGN.md section 5, a failed check blocks
acceptance criteria AC1 and AC4 "until the cause is understood and fixed",
and the thresholds are not changed. Both criteria therefore stayed open until
the owner's decision.

The diagnosis in section 4 finds **no defect in the estimators or in the
standard-error formulas**. The failures fall into three groups:
- **Conservative standard errors for σ when ρ = 0** (2 checks). The
  mechanism is identified: at ρ = 0, σ depends on ρ only quadratically.
- **Finite-sample under-coverage at N = 1000–2000** with moderate endogeneity
  (7 checks, 5 of them in the base cell N = 1000, ρ = (0.6, 0.4)). The
  Hessian standard errors equal the true asymptotic ones; at these sample
  sizes the estimator varies more than asymptotic theory predicts.
- **Monte Carlo noise** in checks at the edge of the range (1 check, on the
  conservative side).

The rule's "fixed" assumes a defect, and none was found. Whether to accept
the diagnosis was therefore the owner's decision (section 9).

Everything else came out as expected:
- every bias, root-N and convergence check passes (C1, C2, C3, C6: 165/165);
- every two-step coverage check passes (C8: 48/48);
- at N = 5000, mean coverage is 0.949 for parameters and 0.949 for effects;
- sandwich standard errors (not gated) behave like the Hessian ones, and a
  full rerun reproduced every result exactly (section 6).

## 2. What was run

| Item | Value |
| --- | --- |
| Package | SwitchEconometrics 0.6.0 from the private library `runs/lib`. The estimator code is unchanged in 0.7.0 |
| Cells | 20 core (R = 1000), 16 one-factor-at-a-time (R = 500), 2 multistart (R = 200, `starts = 10`) |
| Replications | 28 400, each fitted by FIML and by two-step, with effects (delta method) |
| Random numbers | L'Ecuyer-CMRG, master seed 20261122, one stream per cell, substream r for replication r |
| Computing | 2 worker processes on a 4-core machine shared with another job; 1.6 hours of cell time (rerun with sandwich standard errors: 2.5 hours) |
| Convergence | FIML converged in 100% of replications in every cell, except 99.0% (N = 250) and 99.9% (N = 500) in the near-boundary cell (0.85, 0.85) and 99.8% in the no-exclusion cell at N = 500 |
| Reproducibility | A full rerun with the same seeds, made to record the sandwich standard errors, reproduced every estimate, standard error and effect exactly (section 6) |

## 3. Gate results (gated cells: FIML, core grid, N ≥ 1000, ρ ∈ {(0, 0), (0.6, 0.4), (0.7, −0.5)})

| Criterion | Threshold | Checks | Passed | Failed |
| --- | --- | --- | --- | --- |
| C1 relative bias of γ, β, σ | ≤ 5% (\|bias\| ≤ 0.01 if \|truth\| < 0.2) | 99 | 99 | 0 |
| C2 bias of ρ | ≤ 0.03 | 18 | 18 | 0 |
| C3 root-N | √5000 RMSE₅₀₀₀ / √1000 RMSE₁₀₀₀ ∈ [0.8, 1.2] | 39 | 39 | 0 |
| C4 SE ratio (Hessian) | [0.90, 1.10] | 117 | 116 | 1 |
| C5 coverage 95% | [0.93, 0.97] | 117 | 111 | 6 |
| C6 convergence | ≥ 99% | 9 | 9 | 0 |
| C7 effects relative bias | ≤ 5% | 27 | 26 | 1 |
| C7 effects coverage | [0.93, 0.97] | 27 | 25 | 2 |
| C8 two-step coverage (β, θ_j, N ≥ 2000) | [0.93, 0.97] | 48 | 48 | 0 |
| **All** | | **501** | **491** | **10** |

### The ten failed checks

Monte Carlo standard errors are bootstrap standard errors over the
replications of the cell. "Hessian / oracle" compares the mean Hessian
standard error with the asymptotic standard error at the true parameters
(section 4.4).

| # | Check | N | (ρ₁, ρ₀) | Parameter | Value (MC SE) | Range | SE ratio | Group |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | C4 SE ratio | 1000 | (0, 0) | σ₁ | 1.100 (0.026) | [0.90, 1.10] | 1.100 | A: σ at ρ = 0 |
| 2 | C5 coverage | 1000 | (0, 0) | σ₀ | 0.971 (0.005) | [0.93, 0.97] | 1.046 | A: σ at ρ = 0 |
| 3 | C5 coverage | 1000 | (0.6, 0.4) | β₀ intercept | 0.925 (0.008) | [0.93, 0.97] | 0.934 | B: finite sample |
| 4 | C5 coverage | 1000 | (0.6, 0.4) | σ₁ | 0.928 (0.008) | [0.93, 0.97] | 0.984 | B: finite sample |
| 5 | C5 coverage | 1000 | (0.7, −0.5) | γ (z₁) | 0.971 (0.005) | [0.93, 0.97] | 1.019 | C: noise |
| 6 | C5 coverage | 2000 | (0.6, 0.4) | σ₀ | 0.928 (0.008) | [0.93, 0.97] | 0.987 | B: finite sample |
| 7 | C5 coverage | 5000 | (0.7, −0.5) | σ₀ | 0.926 (0.008) | [0.93, 0.97] | 0.968 | B: finite sample |
| 8 | C7 relative bias | 1000 | (0.6, 0.4) | ATU | 9.7% (3.4%) | ≤ 5% | – | B: finite sample |
| 9 | C7 coverage | 1000 | (0.6, 0.4) | ATT | 0.928 (0.008) | [0.93, 0.97] | 0.934 | B: finite sample |
| 10 | C7 coverage | 1000 | (0.6, 0.4) | ATE | 0.925 (0.008) | [0.93, 0.97] | 0.931 | B: finite sample |

## 4. Diagnosis

### 4.1 How many failures a correct estimator would produce

The thresholds have no allowance for the number of checks:
- At R = 1000 the coverage range [0.93, 0.97] is about ±2.9 Monte Carlo
  standard errors around 0.95.
- An interval with exactly 95% coverage falls outside the range in 0.3% of
  checks. With 192 coverage checks (C5, C7, C8), the chance of at least one
  failure is 44%.
- Real coverages also differ slightly between parameters in finite samples.
  Across the 117 C5 checks:
  - the mean is 0.948;
  - the spread is 0.0091, against 0.0070 from binomial noise alone, which
    implies a spread of the true coverages of 0.0058;
  - under that model the expected number of C5 failures is 3.5 (90% range
    1–7). Six were observed.

So the number of C5 failures alone would not show a defect. The pattern
matters more. It is examined next.

### 4.2 Group A: σ at ρ = 0 (checks 1–2; conservative)

In the (0, 0) cell, the Hessian standard errors of σ₀ and σ₁ are too large at
every N ≥ 500, and their intervals over-cover (0.958–0.974):

| N | SE ratio σ₀ / σ₁ | coverage σ₀ / σ₁ |
| --- | --- | --- |
| 500 | 1.025 / 1.048 | 0.965 / 0.974 |
| 1000 | 1.046 / 1.100 | 0.971 / 0.966 |
| 2000 | 1.037 / 1.033 | 0.962 / 0.962 |
| 5000 | 1.013 / 1.061 | 0.958 / 0.965 |

**Mechanism.** In the selected sample, Var(y | S) involves σ²(1 − ρ²δ). At
ρ = 0 the first derivative of the likelihood's σ–ρ trade-off is zero, so σ̂
depends on ρ̂ only through ρ̂². The Hessian at the estimate is evaluated
where ρ̂ ≠ 0 (its standard deviation is about 0.2 at N = 1000). There it sees
a linear trade-off that does not exist at the truth. For a quadratic
dependence, this linearisation overstates the extra variance by about a
factor of two.

**Evidence** (cell N = 1000, (0, 0)):
- The estimated variance of σ̂ rises with ρ̂²:
  - regime 0: Var-hat(σ̂₀) = 0.00142 + 0.0249 ρ̂₀², with t = 42;
  - regime 1: Var-hat(σ̂₁) = 0.00073 + 0.0097 ρ̂₁², with t = 56.
- Against the oracle (the asymptotic standard error at the true parameters),
  the Hessian standard error is 1.23 (σ₀) and 1.20 (σ₁) times larger. For
  every other parameter the ratio is 0.99–1.03.
- The intervals for σ on the log scale behave the same (0.967 for both). The
  scale of the interval is not the cause.

**Consequences:**
- The error is conservative: intervals too wide.
- It occurs only at ρ_j = 0 exactly, where no selection correction is needed.
- It shrinks with N, because ρ̂² falls like 1/N.

There is nothing to correct in the code.

### 4.3 Group B: finite-sample under-coverage with moderate endogeneity (checks 3, 4, 6–10)

**Where the failures sit.** Five of the ten failures (checks 3, 4, 8, 9, 10)
are in one cell, the base design at N = 1000. There the empirical spread of
the parameters linked to ρ exceeds the asymptotic spread.

**Oracle results**, N = 1000, (0.6, 0.4):

| Parameter | Oracle SE / empirical SD | Hessian SE / empirical SD | Hessian / oracle |
| --- | --- | --- | --- |
| β₀ intercept | 0.946 | 0.934 | 0.988 |
| β₀ (x₁) | 0.948 | 0.952 | 1.004 |
| atanh ρ₀ | 0.950 | 0.949 | 0.999 |
| β₁ intercept | 0.956 | 0.971 | 1.016 |
| atanh ρ₁ | 0.943 | 0.960 | 1.018 |
| all 13 parameters | 0.94–1.02 | 0.93–1.03 | 0.977–1.018 |

**Reading the oracle results.**
- The Hessian standard errors equal the asymptotic standard errors at the
  truth to within 2.3%. The formulas are right.
- The estimator itself varies about 5% more than first-order asymptotics
  predict at N = 1000.
- The effects are smooth functions of these parameters and inherit the same
  gap: SE ratios 0.93–0.96 and coverage 0.925–0.931.

**The gap closes as N grows.** In the (0.6, 0.4) cell:

| N | SE ratio ATT / ATU / ATE | coverage ATT / ATU / ATE | SE ratio β₀ intercept |
| --- | --- | --- | --- |
| 250 | 0.919 / 0.884 / 0.913 | 0.915 / 0.904 / 0.913 | 0.922 |
| 500 | 0.954 / 0.923 / 0.957 | 0.927 / 0.914 / 0.931 | 0.965 |
| 1000 | 0.934 / 0.959 / 0.931 | 0.928 / 0.931 / 0.925 | 0.934 |
| 2000 | 0.967 / 0.959 / 0.969 | 0.942 / 0.933 / 0.934 | 0.965 |
| 5000 | 1.030 / 1.011 / 1.031 | 0.954 / 0.952 / 0.955 | 1.029 |

Pooled over the three gated ρ configurations:

| N | mean coverage, parameters | mean coverage, ATT/ATU/ATE | mean SE ratio, parameters | mean SE ratio, effects |
| --- | --- | --- | --- | --- |
| 250 | 0.926 | 0.896 | 0.941 | 0.885 |
| 500 | 0.941 | 0.926 | 0.971 | 0.946 |
| 1000 | 0.948 | 0.939 | 0.991 | 0.975 |
| 2000 | 0.948 | 0.943 | 0.997 | 0.984 |
| 5000 | 0.949 | 0.949 | 1.000 | 1.004 |

**ATU relative bias (check 8).**
- The ATU bias in this configuration falls roughly like 1/N: 0.058, 0.025,
  0.021, 0.006 and 0.003 for N = 250 to 5000. That is the usual
  second-order bias of a nonlinear function of a maximum-likelihood
  estimate.
- The relative criterion bites because the ATU is small here (0.214). At
  N = 1000 the 95% Monte Carlo interval for the relative bias is about
  3–16%, so the failure is not just noise.
- At N = 2000 the relative bias is 2.7%, and at N = 5000 it is 1.2%.

**The σ checks (4, 6, 7).**
- Their SE ratios are 0.97–0.99, and the oracle comparison puts the Hessian
  standard error within 3% of the asymptotic one (N = 2000 cell: 0.971).
- The under-coverage comes from the shape of the sampling distribution of
  σ̂: skewness 0.26–0.54 and excess kurtosis up to 0.43.
- Log-scale intervals do no better (0.928–0.934). The scale of the interval
  is not the cause.
- Check 7 is at N = 5000, where the mean coverage over all parameters is
  0.949. That value is 2.9 Monte Carlo standard errors below 0.95 and is the
  weakest of the seven. Its oracle comparison is in section 4.5.

### 4.4 Oracle standard errors (method)

The oracle covariance is the inverse of the average observed information at
the true parameters, averaged over 200 regenerated replications of the cell.
The regenerated data reproduce the stored estimates to 3e-8. The oracle is
the first-order asymptotic covariance. Two comparisons separate the two
possible sources of a low SE ratio:
- Hessian / oracle tests the formulas;
- oracle / empirical SD tests the asymptotic approximation itself.

### 4.5 Group C and the N = 5000 σ₀ check

- **Check 5** (γ for z₁, coverage 0.971):
  - It errs on the conservative side, and its SE ratio is 1.019.
  - Its sample distribution is lighter-tailed than normal (excess kurtosis
    −0.41), so fewer estimates fall beyond 1.96 standard deviations.
  - At N = 500, 2000 and 5000 the same parameter covers 0.943, 0.940 and
    0.948. This is noise at the edge of the range.
- **Check 7** (σ₀ at N = 5000, (0.7, −0.5)):
  - The Hessian standard error equals the oracle (ratio 0.996). Every
    parameter of the cell agrees to within 1.3%.
  - The SE ratio of 0.968 is 1.3 Monte Carlo standard errors from 1.
  - A normal estimator with that SE ratio would cover about 0.942, slightly
    less with the observed excess kurtosis (0.43). The observed 0.926 is
    about 1.5 Monte Carlo standard errors below that.
  - In this configuration σ₀ is consistently on the low side: it covers
    0.930, 0.934 and 0.926 at N = 1000, 2000 and 5000, while its standard
    errors are correct (SE ratios 0.993, 0.977 and 0.968; Hessian equal to
    oracle).
  - The likely cause is the shape of σ̂₀'s sampling distribution:
    - regime 0 holds only a third of the sample, with ρ₀ = −0.5;
    - skewness is 0.26 and excess kurtosis 0.43 at N = 5000, more than a
      sample standard deviation from 1600 normal observations would show.
  - Monte Carlo noise of about 1.5 standard errors comes on top. A
    natural-scale Wald interval for σ₀ in this design covers about 93%,
    not 95%. This is a property of the Wald interval, not of the standard
    error.

## 5. Results outside the gate (reported, not gated)

### 5.1 Small samples (N = 250, 500)
- **Convergence:** FIML converges in every replication (99.0% in the
  near-boundary cell at N = 250).
- **Bias:**
  - At N = 250, the relative bias of γ, β and σ reaches 13–14% in the
    endogenous designs. It is 3.8–4.4% at N = 500.
  - The bias of ρ is −0.06 to +0.07 at N = 250 and at most 0.023 in absolute
    value at N = 500.
- **Inference:**
  - Coverage is 0.87–0.96 at N = 250 and 0.91–0.97 at N = 500.
  - The ρ intervals are the weakest: SE ratios 0.77–0.91 at N = 250.
  - Effect coverage is 0.85–0.94 at N = 250 and 0.90–0.96 at N = 500.
- **The WP1.6 smoke flag** (ATU coverage 0.84 at N = 500, R = 50) is
  confirmed in direction but smaller: with R = 1000, ATU coverage at N = 500
  is 0.902–0.961 across the four ρ configurations.

### 5.2 Near-boundary cell (0.85, 0.85)
- At N ≥ 1000 the bias, SE-ratio, coverage and convergence thresholds would
  all be met, had the cell been gated (root-N was not evaluated for it):
  - relative bias at most 1.0%;
  - SE ratios 0.926–1.06;
  - coverage 0.935–0.963;
  - effect coverage 0.934–0.963.
- At N = 250:
  - 1% of fits do not converge, and 0.4% end with |ρ̂| > 0.995;
  - the ρ SE ratios are 0.74.

### 5.3 One factor at a time (N = 500 and 2000)

| Factor | Finding |
| --- | --- |
| Exclusion strength | The dominant factor:<br>• **Strong** exclusion (γ_z = −1): unbiased, with coverage 0.93–0.96 at both N.<br>• **Weak** exclusion (−0.1): FIML is badly biased for ρ (−0.24/−0.26 at N = 500; −0.12 at N = 2000), with coverage down to 0.77–0.83.<br>• **No** exclusion (identification by functional form only): ρ bias −0.30 to −0.40, coverage down to 0.69, effect coverage 0.69–0.84 |
| Selection rate | At 0.2 and N = 500:<br>• ρ bias −0.06/−0.04;<br>• effect coverage 0.88–0.93.<br>At N = 2000 all rates are fine (coverage 0.92–0.97) |
| Variance ratio 2, homogeneous slopes | Close to the base design:<br>• coverage 0.89–0.96 at N = 500 (base 0.92–0.96);<br>• coverage 0.92–0.96 at N = 2000 (base 0.93–0.97);<br>• ρ bias −0.04 to −0.02 at N = 500 and at most 0.015 in absolute value at N = 2000 |

These are the known limits of the model: without a strong exclusion
restriction the selection correlation is poorly identified. The package's
identification checks I4 and I5 exist to warn about this. Their behaviour in
these cells is examined in section 7.

### 5.4 Multistart sub-study (N = 500, `starts = 10`)

| Cell | Share with a lower local maximum | Two-step start reached the best optimum |
| --- | --- | --- |
| Weak exclusion | 28.5% | 58.5% |
| No exclusion | 57.0% | 46.0% |

- With weak or no exclusion, the likelihood often has several local maxima,
  and the two-step start finds the highest one only about half the time.
  Multistart is therefore needed in such designs.
- Even the best of ten starts stays biased (ρ bias −0.20 to −0.34). The
  problem is weak identification, not optimisation.

### 5.5 Two-step estimator
- **Model-based coverage** for β and θ_j is 0.951–0.953 on average at every
  N, including N = 250. The range over checks is 0.925–0.974.
- **Efficiency:** the two-step estimator is less efficient than FIML.

  | (ρ₁, ρ₀) | median RMSE ratio, outcome parameters (two-step / FIML) | largest ratio |
  | --- | --- | --- |
  | (0, 0) | about 1.00 | – |
  | (0.6, 0.4) | 1.01–1.10 | – |
  | (0.7, −0.5) | 1.06–1.13 | up to 1.8 |
  | (0.85, 0.85) | 1.32–1.43 | up to 2.2 |

### 5.6 Time per fit
First run (core grid, median):
- FIML: 0.11–0.15 s at N ≤ 2000 and 0.26 s at N = 5000.
- Two-step: 0.06–0.13 s.

The timer covers the fit only; the sandwich computation is outside it. The
rerun measured the same fits at:
- FIML: 0.20–0.25 s at N ≤ 2000 and 0.37 s at N = 5000;
- two-step: 0.13–0.18 s.

The times therefore depend on the load of the shared machine and are only
indicative. The generated tables show the rerun's times.

## 6. Sandwich standard errors and the reproducibility rerun

**Why.** Design section 3 asks for sandwich standard errors in every
replication. The first full run did not record them. The driver was
corrected and the whole study was rerun with the same seeds into
`runs/mc_g1_0.6.0_full_sandwich/` (2.5 hours of cell time). Sandwich
standard errors are reported here but not gated: section 5 of the design
gates the default (Hessian) standard errors.

**Reproducibility.** The rerun was compared with the first run:
- **Identical results.** Every estimate, Hessian standard error (natural and
  working scale), effect, effect standard error, convergence code and
  log-likelihood is identical: 511 200 comparisons over 38 cells, maximum
  absolute difference 0.
- **Sandwich recorded everywhere.** All 56 800 fits have sandwich results:
  28 400 FIML and 28 400 two-step.
- **Same gate result.** The rerun's gate evaluation (`gate_checks_G1.csv`)
  is byte-for-byte identical to the first run's: 491 of 501, with the same
  ten failures.
- **Source of the tables.** All tables in this report and in
  `MC_G1_generated.md` come from the rerun. Only the times per fit differ
  (section 5.6).

### 6.1 FIML: sandwich against Hessian

Gated cells, with the C4 and C5 thresholds applied to the sandwich standard
errors for information only:

| | Hessian (gated) | Sandwich (not gated) |
| --- | --- | --- |
| SE ratio outside [0.90, 1.10] | 1 of 117 | 1 of 117 |
| Coverage outside [0.93, 0.97] | 6 of 117 | 4 of 117 |
| Mean coverage | 0.948 | 0.947 |
| Mean \|SE ratio − 1\| | 0.020 | 0.019 |
| Mean \|coverage − 0.95\| | 0.0073 | 0.0074 |

The sandwich's five out-of-range values:
- σ₁ SE ratio 1.115 at N = 1000, (0, 0);
- coverage of β₀ intercept 0.926 and σ₁ 0.924 at N = 1000, (0.6, 0.4);
- coverage of σ₀ 0.928 at N = 1000, (0.7, −0.5), where the Hessian
  interval gives 0.930;
- coverage of σ₀ 0.926 at N = 5000, (0.7, −0.5).

Four of the five are also Hessian failures.

**What this shows:**
- **No difference on average.** Under correct specification the two
  estimators agree on average, as theory predicts. Neither is more
  accurate.
- **Group A confirmed (section 4.2).** At ρ = 0 the sandwich is as
  conservative for σ as the Hessian:
  - SE ratios 1.056 (σ₀) and 1.115 (σ₁) at N = 1000;
  - coverage 0.961 and 0.966.

  Both are evaluated at the estimate, where the spurious linear σ–ρ
  trade-off exists. The effect therefore comes from the model at ρ = 0, not
  from the Hessian formula.
- **Group B confirmed (section 4.3).** The sandwich does not remove the
  finite-sample under-coverage at N = 1000 with moderate endogeneity. The
  shortfall comes from the estimator's excess sampling variation, not from
  the variance formula.
- **Small samples favour the Hessian.** At N = 250 the sandwich standard
  errors are larger on average, yet their intervals cover less. That points
  to more variable standard errors; their variability was not measured
  directly.
  - mean SE ratio 0.962 against 0.936;
  - mean coverage 0.922 against 0.928;
  - for ρ, SE ratios 0.79–0.92 (Hessian 0.74–0.91) but coverage 0.85–0.92
    (Hessian 0.87–0.94).

  This supports the default chosen at the econometric gate (question 4):
  the Hessian without weights, the sandwich with weights.

### 6.2 Two-step: stacked sandwich against model-based

**Coverage.**
- Mean coverage of γ and β (stacked sandwich): 0.945 at N = 250 and
  0.949–0.951 at N ≥ 500. Model-based: 0.950–0.952.
- Selection-correction coefficients θ_j: 0.941–0.974 over all cells
  (model-based 0.944–0.974).

**Gated cells at N ≥ 2000.** All 66 stacked-sandwich coverages for γ, β and
θ_j are within [0.93, 0.97], with range 0.935–0.967. The 48 model-based C8
checks also pass.

**Near-boundary cell (0.85, 0.85) at N = 5000 (not gated).** The θ_j
intervals are slightly conservative under both covariances:
- coverage 0.970–0.974 (stacked sandwich) and 0.965–0.974 (model-based);
- SE ratios 1.03–1.09.

**Limit.** The study's design is correctly specified, with independent
observations. It shows only that the sandwich costs little where it is not
needed. Its behaviour under misspecification or clustering is not tested
here.

## 7. Identification diagnostics I5 and I6 (supplementary; econometric gate question 5)

**Why.** The econometric gate approved the heuristic thresholds of
`switch_validate()` "to be revisited after the Monte Carlo study":
- I5 notes a weak exclusion when χ²/df < 10;
- I6 warns when the R² of the selection-correction term on the outcome
  regressors exceeds 0.95.

**How.** `scripts/mc_g1_identification.R` regenerated the data of eight
cells (identical to the stored replications) and ran `switch_validate()` on
each replication. It then linked the flags to the FIML results of the same
replication. Output: `results/ident_G1_summary.csv`.

| Cell (γ_z) | N | FIML ρ bias | FIML ρ coverage | median χ²/df (I5) | I5 flags (χ²/df < 10 or p > 0.05) | median R² (I6) | I6 flags (R² > 0.95) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| strong (−1.0) | 500 | 0.000 | 0.946 | 125 | 0% | 0.07 | 0% |
| base (−0.4) | 500 | −0.019 | 0.930 | 38 | 0% | 0.36 | 0% |
| weak (−0.1) | 500 | −0.249 | 0.772 | 3.0 | 91% | 0.89 | 27% |
| none | 500 | −0.381 | 0.774 | – (I4 warns) | – | 0.998 | 100% |
| strong (−1.0) | 2000 | 0.002 | 0.945 | 500 | 0% | 0.06 | 0% |
| base (−0.4) | 2000 | −0.008 | 0.940 | 154 | 0% | 0.33 | 0% |
| weak (−0.1) | 2000 | −0.120 | 0.854 | 10.9 | 44% | 0.90 | 15% |
| none | 2000 | −0.311 | 0.723 | – (I4 warns) | – | 0.998 | 100% |

**Findings:**
- **No false alarms.** Neither diagnostic flags the strong or base designs,
  where FIML performs well.
- **No exclusion.** I4 warns in every replication, and I6 flags 100% of
  them.
- **Weak exclusion: the current thresholds miss too much.** At N = 2000:
  - The exclusion is statistically significant (median χ²/df 10.9), so I5
    flags only 44% of replications and I6 only 15%.
  - Yet FIML's ρ is still biased by −0.12, with coverage 0.85.
  - Within the cell, ρ coverage among I5-flagged replications (0.84) hardly
    differs from coverage among unflagged ones (0.87). The weakness belongs
    to the design, not to individual samples.
- **The R² of the correction term separates the designs better than the
  χ² of the exclusion.** Its 95th percentile is 0.56 in the base design;
  its 5th percentile in the weak design is 0.64 (N = 500) or 0.78
  (N = 2000).

| Alternative threshold | base, N = 500 / 2000 | weak, N = 500 / 2000 |
| --- | --- | --- |
| I6 R² > 0.80 | 0% / 0% | 75% / 92% |
| I6 R² > 0.70 | 0.2% / 0% | 91% / 100% |
| I5 χ²/df < 30 | 22% / 0% | 100% / 99% |

**Proposal for the owner.** Lower the I6 warning threshold from R² > 0.95
to R² > 0.80, and keep the I5 rule as a note.

**Decision (22 November 2026).** The owner accepted the proposal. It is
applied in version 0.7.1 (IDENTIFICATION.md section 7); the I5 rule is
unchanged.

**Caveat:** this rests on one family of designs:
- normal regressors;
- one excluded variable;
- selection rate 0.67.

The other selection rates and multiple exclusions were not examined.

## 8. AC4(b): bootstrap versus Hessian standard errors at N = 2000

**How.** `scripts/ac4b_bootstrap_check.R`:
- two datasets of N = 2000, chosen before the run;
- nonparametric bootstrap, R = 999, seed 20261122;
- ρ compared on the atanh scale;
- criterion: every ratio of bootstrap SE to Hessian SE in [0.90, 1.10].

Output: `results/ac4b_bootstrap_G1.csv`.

| Dataset | Parameters within 10% | Range of ratios | Outside |
| --- | --- | --- | --- |
| `firms` | 15 of 15 | 0.953–1.090 | – |
| Base design, (ρ₁, ρ₀) = (0.6, 0.4) | 12 of 15 | 0.985–1.204 | β₁ intercept 1.185, σ₁ 1.154, atanh ρ₁ 1.204 |

**AC4(b) as defined is not met** (27 of 30).

**Diagnosis.** The base dataset comes from exactly the design of the Monte
Carlo cell N = 2000, (0.6, 0.4), so both standard errors can be compared
with the true sampling standard deviation (SD over the 1000 replications of
that cell):

| Parameter | True SD | Hessian SE (ratio to true) | Bootstrap SE (ratio to true) | Sandwich / Hessian | OPG / Hessian |
| --- | --- | --- | --- | --- | --- |
| β₁ intercept | 0.0575 | 0.0569 (0.99) | 0.0674 (1.17) | 1.135 | 0.899 |
| σ₁ | 0.0339 | 0.0334 (0.99) | 0.0385 (1.14) | 1.187 | 0.852 |
| atanh ρ₁ | 0.131 | 0.138 (1.06) | 0.167 (1.27) | 1.172 | 0.868 |

**What the table shows:**
- In this dataset the Hessian standard errors are the accurate ones. The
  bootstrap overstates the true spread by 14–27%.
- The bootstrap distribution has no outliers: IQR- and MAD-based spreads
  give the same ratios (1.14–1.22). No replicate has |ρ₁*| > 0.95.
- The sandwich also exceeds the Hessian, and the outer-product estimator
  falls below it. In this sample the information-matrix equality holds
  poorly for the regime-1 parameters linked to ρ₁. The resampling and
  score-based estimators reflect that sample-specific variation; the
  curvature does not.
- Bootstrap percentile intervals for atanh ρ₁ are asymmetric: half-widths
  0.368 below and 0.284 above, against the Wald half-width of 0.271.

**Conclusion.** A single-dataset comparison of two random standard errors
cannot tell which one is unreliable. Here the external truth shows that the
Hessian is right.

**Recommendation.** Redefine AC4(b) as a Monte Carlo property: compare the
mean bootstrap SE with the empirical SD over replications, as C4 does for
the Hessian. That would need a bootstrap Monte Carlo of about 40 000 fits.
This is the owner's decision.

**Outcome.** Under the owner's decision of section 9, the AC4(b) result is
recorded as a documented exception. The redefinition was not needed for
that and has not been made.

## 9. Acceptance criteria and the owner's decision

| Criterion | Evidence in this study | Status under the pre-registered rules | Status after the owner's decision |
| --- | --- | --- | --- |
| AC1 recovery | **(a)** All 165 bias, root-N and convergence checks of the parameters pass. One effect-bias check fails (ATU at N = 1000, 9.7%; second-order bias falling like 1/N).<br>**(b)** The N = 5000 recovery test passes and now runs on CRAN | blocked by the one failed C7 bias check | **met** with a documented exception |
| AC4 inference | **(a)** 9 SE-ratio and coverage checks fail (section 4).<br>**(b)** 27/30 (section 8).<br>**(c)** Analytic Hessian equals the numerical one (met) | blocked by (a) and (b) | **met** with documented exceptions |

**Decision.** On 22 November 2026 the owner chose option 1 ("Accept the
diagnosis"). The options as they were put:
1. **Accept the diagnosis.**
   - Record the 10 failed gate checks and the AC4(b) result as understood
     finite-sample properties, with no defect, like the I10 amendment.
   - Mark AC1 and AC4 as met with documented exceptions.
   - The documentation (WP1.9, vignette `simulation-validation`) then
     states the finite-sample coverage at N ≤ 1000.
2. **Run a pre-declared confirmation study** before deciding:
   - the five cells with failures, rerun with fresh random-number streams
     and R = 5000, against the same thresholds;
   - for AC4(b), the bootstrap Monte Carlo of section 8.
   - About 3–4 hours of computing.
   - Expect the noise-type failures (checks 5 and 7) to clear. The
     finite-sample ones at N = 1000 (ATU bias, effect coverage near 0.93)
     may well fail again: they reflect true finite-sample behaviour.
3. **Keep AC1 and AC4 open** and continue with WP1.8 (benchmarks), deciding
   at the G1 computational gate.

**Recommendation:** option 1. The study answers the question the gate is
there for: no part of the estimation or inference code is wrong.
- The oracle comparison shows the Hessian formulas are correct to within
  2.3%, except for σ at ρ = 0, where the error is conservative and
  explained.
- Coverage converges to the nominal level as N grows.

The failures measure how far N = 1000–2000 is from asymptotics in this
model. That is information for users, not a defect to fix. Separately, the
I6 threshold (section 7) was a decision for the owner: R² > 0.80 was
adopted in 0.7.1.

## 10. Files

| File | Content |
| --- | --- |
| `04_Validation/scripts/mc_g1.R` | driver (per-replication fits, effects, sandwich standard errors) |
| `04_Validation/scripts/mc_g1_report.R` | gate evaluation and generated tables (thresholds fixed in the script) |
| `04_Validation/scripts/mc_g1_identification.R` | supplementary I5/I6 study |
| `04_Validation/scripts/ac4b_bootstrap_check.R` | AC4(b) |
| `04_Validation/results/MC_G1_generated.md`, `gate_checks_G1.csv`, `mc_g1_summary.csv` | generated outputs |
| `runs/mc_g1_0.6.0_full/`, `runs/mc_g1_0.6.0_full_sandwich/` | raw output, one file per cell (workspace, not in git) |
