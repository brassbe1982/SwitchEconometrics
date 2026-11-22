# Project charter: SwitchEconometrics

Adopted 22 November 2026 (WP1.1).

**Purpose.** Deliver `SwitchEconometrics`, an R package that unifies
endogenous switching, endogenous treatment, sample selection, multinomial
switching, copula dependence and longitudinal, spatial and hierarchical
switching under one statistical model, the Generalized Endogenous Switching
System ([GENERAL_MODEL.md](../01_Econometric_Architecture/GENERAL_MODEL.md)).
Tagline: *Unified Estimation of Endogenous Regime-Dependent Economic Systems*.

**Owner and maintainer.** Ibrahim Niankara (author, maintainer, econometric
approval). Funder: BRASS Digital Lab. Licence: MIT.

**Authoritative documents** (in order of precedence):
1. owner decisions recorded in [DELIVERY_PLAN.md](../03_Development_Roadmap/DELIVERY_PLAN.md)
   section 2 and its change log;
2. the specification, [SPECIFICATION.md](SPECIFICATION.md);
3. the derivation and architecture documents in `01_` and `02_`.

The background review is "Initial research details for
SwitchEconometrics.txt" (workspace root).

**Deliverables.** Six generations of releases (specification section 13), each
a usable package version:

| Generation | Versions | Deliverable |
| --- | --- | --- |
| G1 | 0.1.0 → 1.0.0 | Classical binary ESR (first CRAN release) |
| G2 | 1.1.0 → 1.5.0 | Generalized multiregime switching |
| G3 | 2.0.0 → 2.5.0 | Copula-based switching |
| G4 | 3.0.0 → 3.5.0 | Mixed outcomes, sample selection, robust estimation |
| G5 | 4.0.0 → 4.5.0 | Panel and dynamic switching |
| G6 | 5.0.0 → | Spatial, hierarchical and Bayesian extensions |

**Governance.** Three approval gates per generation (specification section
17.1):
- **Econometric:** the owner signs off the derivation documents.
- **Computational:** numerical verification and Monte Carlo evidence.
- **Software:** tests, documentation and `R CMD check --as-cran` on three
  operating systems.

No feature becomes stable because its code runs.

**Out of scope** (owner decision, 22 November 2026): Stata in any form during
development, meaning benchmarks, do-files and convention matching. Stata
commands may be cited in the research article as existing alternatives.

**Success criteria.** The acceptance criteria of each generation
([04_Validation/ACCEPTANCE_TESTS.md](../04_Validation/ACCEPTANCE_TESTS.md)),
demonstrated with evidence and reported honestly.
