# The Generalized Endogenous Switching System (GESS)

Status: draft for the G1 econometric gate (WP1.1, 22 November 2026).
Formalises specification section 3. Each generation adds a derivation
document that specialises this model. [BINARY_ESR.md](BINARY_ESR.md) is the
G1 instance.

## 1. Components

A GESS is a tuple $(\mathcal S, \mathcal Y, \mathcal O, \mathcal C, \mathcal H)$:

| Component | Content | Specification |
| --- | --- | --- |
| $\mathcal S$: selection system | how the regime $S_{it} \in \{1, \dots, J\}$ is generated | s. 3.1 |
| $\mathcal Y$: outcome system | regime-specific outcome models $Y_{itjk}$, $k = 1, \dots, K$ | s. 3.1, 4D |
| $\mathcal O$: observation mechanism | which outcomes are observed, given the regime | s. 10.2 |
| $\mathcal C$: dependence system | joint distribution of the selection and outcome disturbances | s. 3.2 |
| $\mathcal H$: heterogeneity system | random effects, dynamics, spatial and hierarchical terms | s. 4E, 4F |

Indices: unit $i = 1, \dots, N$; time $t = 1, \dots, T_i$; regime
$j = 1, \dots, J$; outcome $k = 1, \dots, K$. In the binary case the software
labels the regimes 0 and 1, internally indexed 1 and 2.

## 2. Selection system $\mathcal S$

Latent utilities $V_{itj} = Z_{itj}'\gamma_j + \kappa_{itj} + u_{itj}$, where
$\kappa$ collects the terms of $\mathcal H$ (lagged regimes $\lambda S_{i,t-1}$,
random effects $c_i$, spatial terms). The mechanism maps utilities to the
regime:

| Mechanism | Rule | Generation |
| --- | --- | --- |
| Binary threshold | $S = \mathbf 1\{V > 0\}$ (one utility, $J = 2$) | G1 |
| Unordered (random utility) | $S = \arg\max_j V_j$, with Gaussian $u$ (multinomial probit) or Gumbel $u$ (multinomial logit), normalised against a base alternative | G2 |
| Ordered | $S = j \iff \mu_{j-1} < V \le \mu_j$ | G2 |
| Sequential | a tree of binary thresholds | G2 |
| Multivariate | several binary thresholds $S^{(1)}, \dots, S^{(M)}$; the regime is their combination | G2 |

## 3. Outcome system $\mathcal Y$

For regime $j$ and outcome $k$: a **marginal outcome model** $M_{jk}$ (family,
link, linear predictor $\eta_{jk} = X_{jk}'\beta_{jk}$, ancillary parameters).
It is linked to a **latent disturbance** $\varepsilon_{jk}$ through its
distributional transform:
- **continuous outcomes:** $U_{jk} = F_{jk}(Y_{jk} \mid \eta_{jk})$;
- **discrete outcomes:** the pair $\left(F_{jk}(y^- \mid \eta), F_{jk}(y \mid \eta)\right)$,
  i.e. a probability rectangle.

Keeping the marginal outcome model separate from the latent disturbance is
required by specification section 3.2, because discrete margins cannot be
given an arbitrary continuous disturbance.

## 4. Observation mechanism $\mathcal O$

| Mechanism | Observed | Likelihood | Generation |
| --- | --- | --- | --- |
| Switching | $S$; the outcomes of the selected regime only | $P(S = j, Y_j \in dy)$ | G1 (binary), G2 |
| Selection (Heckman) | $S$; outcomes only for regimes in an observed set (e.g. $S = 1$) | $P(S \notin \text{obs})$ or $P(S = j, Y \in dy)$ | G2 (Gaussian), G4 (general) |
| Treatment | $S$; one outcome equation with a regime shift | switching likelihood with cross-regime restrictions | G2 |
| Censoring or missing outcomes | interval or partly observed outcomes | interval probabilities | G4 |

Selection and switching are different observation mechanisms and remain
distinct in the likelihood engine (specification section 10.2).

## 5. Dependence system $\mathcal C$

Let $\eta = (u_1, \dots, u_{J'}, \varepsilon_{11}, \dots, \varepsilon_{JK})$,
with selection margins $F_{u}$ and outcome margins $F_{jk}$. By Sklar's
theorem, $F_\eta = C_\theta(F_{u_1}, \dots, F_{\varepsilon_{JK}})$
(specification section 3.2).

**Identified sub-structure.** Only margins of $C_\theta$ whose components can
be observed together enter the likelihood. Under switching, for regime $j$
these are the selection disturbances and the outcome disturbances of regime
$j$. Dependence between outcome disturbances of different regimes is not
identified ([IDENTIFICATION.md](IDENTIFICATION.md) section 3; plan decision
D8). Every dependence specification is therefore stated as a family of
identified margins (for example a vine rooted at the selection disturbance)
plus explicit assumptions for the unidentified parts.

**Validity.** A dependence specification is accepted only if it defines a
valid distribution: positive-definite correlation matrices, admissible copula
parameters, and compatible lower-dimensional margins. Arbitrary family and
dimension combinations are refused (specification section 4C).

## 6. Likelihood

For unit $i$ (cross-section; panel units multiply over $t$ and integrate over
$\mathcal H$):

$$L_i = \int P\!\left(S_i = s_i,\; Y_i \in dy_i \mid X_i, Z_i, b\right)\,dG(b),$$

where $b$ are the random effects of $\mathcal H$ (absent in G1-G4).

**Binary selection, one continuous outcome per regime, copula $C$.** Let
$U = F_u(u)$, $V_j = F_j(\varepsilon_j)$ and
$h_{u\mid j}(a \mid b) = \partial C_{uj}(a, b)/\partial b$. Then

$$P(S = 1, Y \in dy) = f_1(y)\left[1 - h_{u\mid 1}\!\left(F_u(-w) \mid F_1(e_1)\right)\right]dy,$$
$$P(S = 0, Y \in dy) = f_0(y)\; h_{u\mid 0}\!\left(F_u(-w) \mid F_0(e_0)\right)dy.$$

**Nesting of G1 (specification section 10.2).** With the Gaussian copula,
$h(a \mid b) = \Phi\!\left((\Phi^{-1}(a) - \rho\,\Phi^{-1}(b))/\sqrt{1-\rho^2}\right)$.
With standard normal $F_u$ and Gaussian outcome margins this gives
$1 - h = \Phi\!\left((w + \rho e_1)/\sqrt{1-\rho^2}\right)$, which is exactly the
G1 contribution $L_{1i}$ of [LIKELIHOOD_DERIVATION.md](LIKELIHOOD_DERIVATION.md)
section 2. The same holds for regime 0. The G1 engine is therefore the GESS
restricted to:
- $J = 2$;
- probit selection;
- Gaussian margins;
- Gaussian dependence on the identified pairs;
- $\operatorname{Var}(u) = 1$.

This is tested as an exact equality in WP3.3.

**Discrete outcomes** replace $f_j(y)$ and the h-function by copula rectangle
probabilities (G4). **Multinomial selection** replaces the one-dimensional
selection event by a $(J-1)$-dimensional region, evaluated analytically (MNL
via Lee's transformation) or by GHK/Genz-Bretz integration (MNP) (G2).

## 7. The six families as restrictions

| Family | $\mathcal S$ | $\mathcal Y$ | $\mathcal O$ | $\mathcal C$ | $\mathcal H$ |
| --- | --- | --- | --- | --- | --- |
| A Classical binary ESR (G1) | binary probit | 2 Gaussian | switching | Gaussian pairs $(u, \varepsilon_j)$ | none |
| B Generalized switching (G2) | MNP / MNL / ordered / sequential / multivariate | Gaussian, $K \ge 1$ | switching, selection, treatment | Gaussian | none |
| C Copula switching (G3) | binary or multinomial | flexible continuous | switching | copulas, vines | none |
| D Mixed outcomes (G4) | as above | continuous, binary, count, ordinal, censored, fractional, duration | switching, selection, censoring | copulas with discrete margins | none |
| E Panel and dynamic (G5) | with $\lambda S_{i,t-1}$, $c_i$ | as above | as above | as above, plus over time | random effects, initial conditions |
| F Spatial and hierarchical (G6) | with spatial and nested terms | as above | as above | as above | spatial, multilevel, Bayesian |

## 8. Estimation strategies

Several estimators share one specification and may have different objective
functions (specification section 10.3):
- FIML (all families);
- two-step and control function (A, B, D, E);
- simulated ML (B with MNP, E);
- Laplace approximation (E, F);
- robust estimating equations (D);
- Bayesian estimation (F).

## 9. Generation 2 instances (draft for the G2 gate, 23 November 2026)

Sections 1-8 are unchanged. Family B is specified by these documents:

| Component | G2 instances | Document |
| --- | --- | --- |
| $\mathcal O$: selection (Heckman), treatment (restricted switching), Tobit-5 (switching) | binary Gaussian engine of G1 | [OBSERVATION_MECHANISMS.md](OBSERVATION_MECHANISMS.md) |
| $\mathcal S$ with Gaussian disturbances: multinomial probit, ordered, sequential, multivariate | one model: a Gaussian latent vector, regimes as rectangles of a linear transform of it | [GAUSSIAN_REGION_ENGINE.md](GAUSSIAN_REGION_ENGINE.md), with [MULTINOMIAL_ESR.md](MULTINOMIAL_ESR.md) s.6, [ORDERED_SEQUENTIAL.md](ORDERED_SEQUENTIAL.md), [MULTIVARIATE_SELECTION.md](MULTIVARIATE_SELECTION.md) |
| $\mathcal S$ with extreme-value disturbances: multinomial and nested logit | Lee's transformation (a Gaussian copula between the regime's maximum-utility index and its outcome), or two-step conditional-mean corrections | [MULTINOMIAL_ESR.md](MULTINOMIAL_ESR.md) s.2-5 |
| $\mathcal Y$ with $K \ge 1$ Gaussian outcomes per regime | within-regime covariance identified | [MULTIVARIATE_SELECTION.md](MULTIVARIATE_SELECTION.md) s.4 |
| Effects with $J$ regimes | $J \times J$ conditional expectations; pairwise effects | [TREATMENT_EFFECTS.md](TREATMENT_EFFECTS.md) s.7-11 |

In the notation of section 6, the Lee model is the binary-selection formula
with $F_u(-w)$ replaced by $1 - P_j$ and the Gaussian copula:
$P(S = j, Y \in dy) = f_j(y)\left[1 - h\!\left(1 - P_j \mid F_j(e_j)\right)\right]dy$.
The Gaussian region models replace the h-function by a conditional rectangle
probability of dimension $d$.
