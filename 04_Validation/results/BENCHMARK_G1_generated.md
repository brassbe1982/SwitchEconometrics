# Benchmarks, Generation 1: generated tables

Generated 2026-11-23 00:47 by `benchmark_g1.R`. Protocol and tolerances: BENCHMARK_PROTOCOL.md section 3.

## Software

| Package | Version |
| --- | --- |
| R | 4.6.2 |
| SwitchEconometrics | 0.8.1 |
| sampleSelection | 1.2.16 |
| endoSwitch | 1.0.0 |
| maxLik | 1.6.10 |
| sandwich | 3.1.3 |
| mvtnorm | 1.4.2 |
| data.table | 1.18.6.1 |
| msm | 1.9 |

## Summary

| Dataset | Benchmark | Checks | Passed | Failed | Documented differences |
| --- | --- | --- | --- | --- | --- |
| D1 | sampleSelection ML | 37 | 37 | 0 | 0 |
| D1 | sampleSelection two-step | 11 | 11 | 0 | 4 |
| D1 | endoSwitch FIML | 40 | 37 | 3 | 0 |
| D1 | endoSwitch FIML (reltol 1e-14) | 40 | 40 | 0 | 0 |
| D1 | endoSwitch two-stage | 11 | 11 | 0 | 4 |
| D2 | sampleSelection ML | 37 | 37 | 0 | 0 |
| D2 | sampleSelection two-step | 11 | 11 | 0 | 4 |
| D2 | endoSwitch FIML | 40 | 37 | 3 | 0 |
| D2 | endoSwitch FIML (reltol 1e-14) | 40 | 36 | 4 | 0 |
| D2 | endoSwitch two-stage | 11 | 11 | 0 | 4 |
| D3 | sampleSelection ML | 37 | 37 | 0 | 0 |
| D3 | sampleSelection two-step | 11 | 11 | 0 | 4 |
| D3 | endoSwitch FIML | 40 | 37 | 3 | 0 |
| D3 | endoSwitch FIML (reltol 1e-14) | 40 | 36 | 4 | 0 |
| D3 | endoSwitch two-stage | 11 | 11 | 0 | 4 |
| D4 | sampleSelection ML | 37 | 37 | 0 | 0 |
| D4 | sampleSelection two-step | 11 | 11 | 0 | 4 |
| D4 | endoSwitch FIML | 40 | 36 | 4 | 0 |
| D4 | endoSwitch FIML (reltol 1e-14) | 40 | 32 | 8 | 0 |
| D4 | endoSwitch two-stage | 11 | 11 | 0 | 4 |
| D5 | sampleSelection ML | 35 | 35 | 0 | 0 |
| D5 | sampleSelection two-step | 10 | 10 | 0 | 4 |
| D6a | sampleSelection ML | 31 | 31 | 0 | 0 |
| D6a | sampleSelection two-step | 8 | 8 | 0 | 4 |
| D6b | sampleSelection ML | 31 | 0 | 31 | 0 |
| D6b | sampleSelection ML (default iterations) | 31 | 0 | 31 | 0 |
| D6b | sampleSelection two-step | 8 | 8 | 0 | 4 |
| D6c | sampleSelection ML | 31 | 31 | 0 | 0 |
| D6c | sampleSelection ML (default iterations) | 31 | 31 | 0 | 0 |
| D6c | sampleSelection two-step | 8 | 8 | 0 | 4 |
| D6d | sampleSelection ML | 31 | 31 | 0 | 0 |
| D6d | sampleSelection two-step | 8 | 8 | 0 | 4 |
| D7a | sampleSelection ML | 33 | 33 | 0 | 0 |
| D7a | sampleSelection two-step | 9 | 9 | 0 | 4 |
| D7a | endoSwitch FIML | 36 | 36 | 0 | 0 |
| D7a | endoSwitch FIML (reltol 1e-14) | 36 | 36 | 0 | 0 |
| D7a | endoSwitch two-stage | 9 | 9 | 0 | 4 |
| D7b | sampleSelection ML | 53 | 53 | 0 | 0 |
| D7b | sampleSelection two-step | 19 | 19 | 0 | 4 |
| D7b | endoSwitch FIML | 56 | 56 | 0 | 0 |
| D7b | endoSwitch FIML (reltol 1e-14) | 56 | 55 | 1 | 0 |
| D7b | endoSwitch two-stage | 19 | 14 | 5 | 4 |
| D8 | sampleSelection ML on replicated rows (+ sandwich package) | 72 | 72 | 0 | 0 |
| D8 | endoSwitch FIML, weighted | 29 | 25 | 4 | 2 |
| D8b | endoSwitch FIML, weighted | 27 | 25 | 2 | 0 |
| D9 | sampleSelection ML + sandwich package | 105 | 105 | 0 | 0 |
| **All** | | 1378 | 1275 | 103 | 70 |

## Failed checks

| Dataset | Benchmark | Quantity | Ours | Theirs | Difference | Criterion | Tolerance |
| --- | --- | --- | --- | --- | --- | --- | --- |
| D1 | endoSwitch FIML | SE regime_0:(Intercept) | 0.225615 | 0.221796 | 3.82e-03 | 1.72e-02 | |ours/theirs - 1| <= 0.01 |
| D1 | endoSwitch FIML | SE regime_0:sigma | 0.0826353 | 0.0816299 | 1.01e-03 | 1.23e-02 | |ours/theirs - 1| <= 0.01 |
| D1 | endoSwitch FIML | SE regime_0:rho | 0.171478 | 0.168792 | 2.69e-03 | 1.59e-02 | |ours/theirs - 1| <= 0.01 |
| D2 | endoSwitch FIML | SE regime_0:(Intercept) | 0.150927 | 0.152992 | -2.07e-03 | 1.35e-02 | |ours/theirs - 1| <= 0.01 |
| D2 | endoSwitch FIML | SE regime_0:sigma | 0.0589294 | 0.0596799 | -7.51e-04 | 1.26e-02 | |ours/theirs - 1| <= 0.01 |
| D2 | endoSwitch FIML | SE regime_0:rho | 0.0969501 | 0.0981908 | -1.24e-03 | 1.26e-02 | |ours/theirs - 1| <= 0.01 |
| D2 | endoSwitch FIML (reltol 1e-14) | SE regime_0:(Intercept) | 0.150927 | 0.147532 | 3.40e-03 | 2.30e-02 | |ours/theirs - 1| <= 0.01 |
| D2 | endoSwitch FIML (reltol 1e-14) | SE regime_0:x1 | 0.0490232 | 0.0484607 | 5.63e-04 | 1.16e-02 | |ours/theirs - 1| <= 0.01 |
| D2 | endoSwitch FIML (reltol 1e-14) | SE regime_0:sigma | 0.0589294 | 0.057856 | 1.07e-03 | 1.86e-02 | |ours/theirs - 1| <= 0.01 |
| D2 | endoSwitch FIML (reltol 1e-14) | SE regime_0:rho | 0.0969501 | 0.0948382 | 2.11e-03 | 2.23e-02 | |ours/theirs - 1| <= 0.01 |
| D3 | endoSwitch FIML | SE regime_0:(Intercept) | 0.0686261 | 0.070722 | -2.10e-03 | 2.96e-02 | |ours/theirs - 1| <= 0.01 |
| D3 | endoSwitch FIML | SE regime_0:sigma | 0.0173278 | 0.0176435 | -3.16e-04 | 1.79e-02 | |ours/theirs - 1| <= 0.01 |
| D3 | endoSwitch FIML | SE regime_0:rho | 0.0600947 | 0.0620008 | -1.91e-03 | 3.07e-02 | |ours/theirs - 1| <= 0.01 |
| D3 | endoSwitch FIML (reltol 1e-14) | SE regime_0:(Intercept) | 0.0686261 | 0.071703 | -3.08e-03 | 4.29e-02 | |ours/theirs - 1| <= 0.01 |
| D3 | endoSwitch FIML (reltol 1e-14) | SE regime_0:x1 | 0.0205996 | 0.0210747 | -4.75e-04 | 2.25e-02 | |ours/theirs - 1| <= 0.01 |
| D3 | endoSwitch FIML (reltol 1e-14) | SE regime_0:sigma | 0.0173278 | 0.0177908 | -4.63e-04 | 2.60e-02 | |ours/theirs - 1| <= 0.01 |
| D3 | endoSwitch FIML (reltol 1e-14) | SE regime_0:rho | 0.0600947 | 0.0628033 | -2.71e-03 | 4.31e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML | SE regime_0:(Intercept) | 0.249729 | 0.256217 | -6.49e-03 | 2.53e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML | SE regime_0:x1 | 0.0672661 | 0.0685655 | -1.30e-03 | 1.90e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML | SE regime_0:sigma | 0.102634 | 0.105141 | -2.51e-03 | 2.38e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML | SE regime_0:rho | 0.142056 | 0.145766 | -3.71e-03 | 2.55e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML (reltol 1e-14) | SE regime_0:(Intercept) | 0.249729 | 0.241484 | 8.24e-03 | 3.41e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML (reltol 1e-14) | SE regime_0:x1 | 0.0672661 | 0.0660315 | 1.23e-03 | 1.87e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML (reltol 1e-14) | SE regime_0:sigma | 0.102634 | 0.0993718 | 3.26e-03 | 3.28e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML (reltol 1e-14) | SE regime_0:rho | 0.142056 | 0.137402 | 4.65e-03 | 3.39e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML (reltol 1e-14) | SE regime_1:(Intercept) | 0.10382 | 0.105342 | -1.52e-03 | 1.44e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML (reltol 1e-14) | SE regime_1:x1 | 0.0419302 | 0.0424079 | -4.78e-04 | 1.13e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML (reltol 1e-14) | SE regime_1:sigma | 0.047527 | 0.0481828 | -6.56e-04 | 1.36e-02 | |ours/theirs - 1| <= 0.01 |
| D4 | endoSwitch FIML (reltol 1e-14) | SE regime_1:rho | 0.172069 | 0.174703 | -2.63e-03 | 1.51e-02 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | log-likelihood | -1428.77 | -1665.94 | 2.37e+02 | 2.37e+02 | |d| <= 1e-4 and ours >= theirs - 1e-6 |
| D6b | sampleSelection ML | selection:(Intercept) | -0.378344 | -0.536975 | 1.59e-01 | 1.59e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | selection:xs | -0.000345487 | 0.312683 | -3.13e-01 | 3.13e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | regime_0:(Intercept) | -0.734828 | -0.706792 | -2.80e-02 | 2.80e-02 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | regime_0:xo1 | 1.00052 | 0.916029 | 8.45e-02 | 8.45e-02 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | regime_0:sigma | 0.701835 | 0.677701 | 2.41e-02 | 2.41e-02 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | regime_0:rho |      -1 | -0.971365 | -2.86e-02 | 2.86e-02 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | regime_1:(Intercept) | -2.20897 | 0.144572 | -2.35e+00 | 2.35e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | regime_1:xo2 | 1.00134 | 1.11962 | -1.18e-01 | 1.06e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | regime_1:sigma | 3.19684 | 2.31432 | 8.83e-01 | 3.81e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | regime_1:rho |       1 | 0.170386 | 8.30e-01 | 8.30e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | SE selection:(Intercept) | 0.0351033 | 0.0580821 | -2.30e-02 | 3.96e-01 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | SE selection:xs | 1.71806e-05 | 0.0939452 | -9.39e-02 | 1.00e+00 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | SE regime_0:(Intercept) | 0.022801 | 0.0357325 | -1.29e-02 | 3.62e-01 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | SE regime_0:xo1 | 8.4507e-06 | 0.0562603 | -5.63e-02 | 1.00e+00 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | SE regime_0:sigma | 0.0184666 | 0.017602 | 8.65e-04 | 4.91e-02 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | SE regime_0:rho | 2.67811e-16 |  |  |  | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | SE regime_1:(Intercept) | 0.137797 |  |  |  | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | SE regime_1:xo2 | 6.52868e-06 | 0.501385 | -5.01e-01 | 1.00e+00 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | SE regime_1:sigma | 0.15754 | 0.0761466 | 8.14e-02 | 1.07e+00 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | SE regime_1:rho | 2.23517e-16 |  |  |  | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML | ATT | 2.66576 | 2.33755 | 3.28e-01 | 1.40e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | ATU | -3.70767 | 0.519653 | -4.23e+00 | 4.23e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | ATE | -1.46351 | 0.963689 | -2.43e+00 | 2.43e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | TH | 6.37343 |  1.8179 | 4.56e+00 | 2.51e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | BH1 | 5.23961 | 0.710698 | 4.53e+00 | 4.53e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | BH0 | -1.13383 | -1.1072 | -2.66e-02 | 2.40e-02 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | EY1_S1 (largest unit difference) | 1.15986 | 0.608286 | 5.52e-01 | 5.52e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | EY1_S0 (largest unit difference) | -3.17826 | 0.974023 | -4.15e+00 | 4.15e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | EY0_S1 (largest unit difference) | -0.489103 | -0.728164 | 2.39e-01 | 2.39e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML | EY0_S0 (largest unit difference) | 0.65272 | 0.424411 | 2.28e-01 | 2.28e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | log-likelihood | -1428.77 | -1665.94 | 2.37e+02 | 2.37e+02 | |d| <= 1e-4 and ours >= theirs - 1e-6 |
| D6b | sampleSelection ML (default iterations) | selection:(Intercept) | -0.378344 | -0.536975 | 1.59e-01 | 1.59e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | selection:xs | -0.000345487 | 0.312683 | -3.13e-01 | 3.13e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | regime_0:(Intercept) | -0.734828 | -0.706792 | -2.80e-02 | 2.80e-02 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | regime_0:xo1 | 1.00052 | 0.916029 | 8.45e-02 | 8.45e-02 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | regime_0:sigma | 0.701835 | 0.677701 | 2.41e-02 | 2.41e-02 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | regime_0:rho |      -1 | -0.971365 | -2.86e-02 | 2.86e-02 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | regime_1:(Intercept) | -2.20897 | 0.144572 | -2.35e+00 | 2.35e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | regime_1:xo2 | 1.00134 | 1.11962 | -1.18e-01 | 1.06e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | regime_1:sigma | 3.19684 | 2.31432 | 8.83e-01 | 3.81e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | regime_1:rho |       1 | 0.170386 | 8.30e-01 | 8.30e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | SE selection:(Intercept) | 0.0351033 | 0.0580821 | -2.30e-02 | 3.96e-01 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML (default iterations) | SE selection:xs | 1.71806e-05 | 0.0939452 | -9.39e-02 | 1.00e+00 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML (default iterations) | SE regime_0:(Intercept) | 0.022801 | 0.0357325 | -1.29e-02 | 3.62e-01 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML (default iterations) | SE regime_0:xo1 | 8.4507e-06 | 0.0562603 | -5.63e-02 | 1.00e+00 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML (default iterations) | SE regime_0:sigma | 0.0184666 | 0.017602 | 8.65e-04 | 4.91e-02 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML (default iterations) | SE regime_0:rho | 2.67811e-16 |  |  |  | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML (default iterations) | SE regime_1:(Intercept) | 0.137797 |  |  |  | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML (default iterations) | SE regime_1:xo2 | 6.52868e-06 | 0.501385 | -5.01e-01 | 1.00e+00 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML (default iterations) | SE regime_1:sigma | 0.15754 | 0.0761466 | 8.14e-02 | 1.07e+00 | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML (default iterations) | SE regime_1:rho | 2.23517e-16 |  |  |  | |ours/theirs - 1| <= 0.01 |
| D6b | sampleSelection ML (default iterations) | ATT | 2.66576 | 2.33755 | 3.28e-01 | 1.40e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | ATU | -3.70767 | 0.519653 | -4.23e+00 | 4.23e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | ATE | -1.46351 | 0.963689 | -2.43e+00 | 2.43e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | TH | 6.37343 |  1.8179 | 4.56e+00 | 2.51e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | BH1 | 5.23961 | 0.710698 | 4.53e+00 | 4.53e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | BH0 | -1.13383 | -1.1072 | -2.66e-02 | 2.40e-02 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | EY1_S1 (largest unit difference) | 1.15986 | 0.608286 | 5.52e-01 | 5.52e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | EY1_S0 (largest unit difference) | -3.17826 | 0.974023 | -4.15e+00 | 4.15e+00 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | EY0_S1 (largest unit difference) | -0.489103 | -0.728164 | 2.39e-01 | 2.39e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D6b | sampleSelection ML (default iterations) | EY0_S0 (largest unit difference) | 0.65272 | 0.424411 | 2.28e-01 | 2.28e-01 | |d| <= 1e-3 max(1, |theirs|) |
| D7b | endoSwitch FIML (reltol 1e-14) | SE selection:Perception | 0.332994 | 0.336678 | -3.68e-03 | 1.09e-02 | |ours/theirs - 1| <= 0.01 |
| D7b | endoSwitch two-stage | selection:(Intercept) | -2.34024 | -2.34025 | 3.72e-06 | 3.72e-06 | |d| <= 1e-6 |
| D7b | endoSwitch two-stage | selection:Access_to_credit | 2.94889 | 2.94888 | 3.71e-06 | 3.71e-06 | |d| <= 1e-6 |
| D7b | endoSwitch two-stage | selection:Perception | 2.17597 | 2.17596 | 6.17e-06 | 6.17e-06 | |d| <= 1e-6 |
| D7b | endoSwitch two-stage | regime_0:Access_to_credit | 0.249967 | 0.249968 | -1.02e-06 | 1.02e-06 | |d| <= 1e-6 |
| D7b | endoSwitch two-stage | regime_1:(Intercept) | 2.72785 | 2.72785 | -1.03e-06 | 1.03e-06 | |d| <= 1e-6 |
| D8 | endoSwitch FIML, weighted | SE (Hessian) regime_0:(Intercept) | 0.106529 | 0.110323 | -3.79e-03 | 3.44e-02 | |ours/theirs - 1| <= 0.01 |
| D8 | endoSwitch FIML, weighted | SE (Hessian) regime_0:x1 | 0.0331757 | 0.0336765 | -5.01e-04 | 1.49e-02 | |ours/theirs - 1| <= 0.01 |
| D8 | endoSwitch FIML, weighted | SE (Hessian) regime_0:sigma | 0.0222223 | 0.0225179 | -2.96e-04 | 1.31e-02 | |ours/theirs - 1| <= 0.01 |
| D8 | endoSwitch FIML, weighted | SE (Hessian) regime_0:rho | 0.103439 | 0.107046 | -3.61e-03 | 3.37e-02 | |ours/theirs - 1| <= 0.01 |
| D8b | endoSwitch FIML, weighted | SE (Hessian) regime_0:(Intercept) | 0.0988983 | 0.100769 | -1.87e-03 | 1.86e-02 | |ours/theirs - 1| <= 0.01 |
| D8b | endoSwitch FIML, weighted | SE (Hessian) regime_0:rho | 0.0940319 | 0.0957435 | -1.71e-03 | 1.79e-02 | |ours/theirs - 1| <= 0.01 |

## Fits

| Dataset | N (regime 1) | Package | Time (s) | Convergence | Warnings |
| --- | --- | --- | --- | --- | --- |
| D1 | 500 (351) | SwitchEconometrics FIML | 0.28 | code 0 |  |
| D1 | 500 (351) | sampleSelection ML | 0.10 | code 1, 5 iterations: gradient close to zero (gradtol) |  |
| D1 | 500 (351) | sampleSelection two-step | 0.04 |  |  |
| D1 | 500 (351) | endoSwitch FIML | 6.09 | code 0, 67 iterations: successful convergence  |  |
| D1 | 500 (351) | endoSwitch FIML (reltol 1e-14) | 5.16 | code 0, 68 iterations: successful convergence  |  |
| D1 | 500 (351) | endoSwitch two-stage | 0.02 |  |  |
| D2 | 2000 (1355) | SwitchEconometrics FIML | 0.40 | code 0 |  |
| D2 | 2000 (1355) | sampleSelection ML | 0.19 | code 8, 4 iterations: successive function values within relative tolerance limit (reltol) |  |
| D2 | 2000 (1355) | sampleSelection two-step | 0.08 |  |  |
| D2 | 2000 (1355) | endoSwitch FIML | 6.25 | code 0, 80 iterations: successful convergence  |  |
| D2 | 2000 (1355) | endoSwitch FIML (reltol 1e-14) | 6.81 | code 0, 82 iterations: successful convergence  |  |
| D2 | 2000 (1355) | endoSwitch two-stage | 0.04 |  |  |
| D3 | 10000 (6767) | SwitchEconometrics FIML | 1.18 | code 0 |  |
| D3 | 10000 (6767) | sampleSelection ML | 0.80 | code 8, 4 iterations: successive function values within relative tolerance limit (reltol) |  |
| D3 | 10000 (6767) | sampleSelection two-step | 0.35 |  |  |
| D3 | 10000 (6767) | endoSwitch FIML | 13.80 | code 0, 92 iterations: successful convergence  |  |
| D3 | 10000 (6767) | endoSwitch FIML (reltol 1e-14) | 15.31 | code 0, 93 iterations: successful convergence  |  |
| D3 | 10000 (6767) | endoSwitch two-stage | 0.09 |  |  |
| D4 | 2000 (1350) | SwitchEconometrics FIML | 0.40 | code 0 |  |
| D4 | 2000 (1350) | sampleSelection ML | 0.20 | code 8, 5 iterations: successive function values within relative tolerance limit (reltol) |  |
| D4 | 2000 (1350) | sampleSelection two-step | 0.09 |  |  |
| D4 | 2000 (1350) | endoSwitch FIML | 6.42 | code 0, 78 iterations: successful convergence  |  |
| D4 | 2000 (1350) | endoSwitch FIML (reltol 1e-14) | 7.52 | code 0, 80 iterations: successful convergence  |  |
| D4 | 2000 (1350) | endoSwitch two-stage | 0.03 |  |  |
| D5 | 3000 (1988) | SwitchEconometrics FIML | 0.41 | code 0 |  |
| D5 | 3000 (1988) | sampleSelection ML | 0.26 | code 8, 4 iterations: successive function values within relative tolerance limit (reltol) |  |
| D5 | 3000 (1988) | sampleSelection two-step | 0.12 |  |  |
| D6a | 500 (328) | SwitchEconometrics FIML | 0.24 | code 0 |  |
| D6a | 500 (328) | sampleSelection ML | 0.11 | code 1, 11 iterations: gradient close to zero (gradtol) |  |
| D6a | 500 (328) | sampleSelection two-step | 0.03 |  |  |
| D6b | 1000 (240) | SwitchEconometrics FIML | 3.53 | code 1 | FIML did not converge: gradient not below tolerance (code 1); results are not reliable; estimated regime_0:rho, regime_1:rho at the boundary (/rho/ > 0.995): inference is unreliable; ill-conditioned Hessian (condition number 1.37e+19) |
| D6b | 1000 (240) | sampleSelection ML | 0.13 | code 3, 4 iterations: Last step could not find a value above the current.
Boundary of parameter space?  
Consider switching to a more robust optimisation method temporarily. |  |
| D6b | 1000 (240) | sampleSelection ML (default iterations) | 0.13 | code 3, 4 iterations: Last step could not find a value above the current.
Boundary of parameter space?  
Consider switching to a more robust optimisation method temporarily. |  |
| D6b | 1000 (240) | sampleSelection two-step | 0.06 |  |  |
| D6c | 1000 (374) | SwitchEconometrics FIML | 0.32 | code 0 | Identification of rho for 'regime_0' depends entirely on the nonlinear functional form of the normal distribution: no variable in the selection equation is excluded from this outcome equation.; Identification of rho for 'regime_1' depends entirely on the nonlinear functional form of the normal distribution: no variable in the selection equation is excluded from this outcome equation.; two-step: estimated rho outside [-1, 1] for regime_0, regime_1; the two-step variance recovery is unreliable in this sample; estimated regime_0:rho, regime_1:rho at the boundary (/rho/ > 0.995): inference is unreliable; Identification of rho for 'regime_0' depends entirely on the nonlinear functional form of the normal distribution: no variable in the selection equation is excluded from this outcome equation.; Identification of rho for 'regime_1' depends entirely on the nonlinear functional form of the normal distribution: no variable in the selection equation is excluded from this outcome equation. |
| D6c | 1000 (374) | sampleSelection ML | 0.19 | code 8, 16 iterations: successive function values within relative tolerance limit (reltol) |  |
| D6c | 1000 (374) | sampleSelection ML (default iterations) | 0.19 | code 8, 16 iterations: successive function values within relative tolerance limit (reltol) |  |
| D6c | 1000 (374) | sampleSelection two-step | 0.05 |  |  |
| D6d | 500 (334) | SwitchEconometrics FIML | 0.25 | code 0 |  |
| D6d | 500 (334) | sampleSelection ML | 0.10 | code 8, 7 iterations: successive function values within relative tolerance limit (reltol) |  |
| D6d | 500 (334) | sampleSelection two-step | 0.05 |  |  |
| D7a | 408 (225) | SwitchEconometrics FIML | 0.25 | code 0 |  |
| D7a | 408 (225) | sampleSelection ML | 0.06 | code 8, 2 iterations: successive function values within relative tolerance limit (reltol) |  |
| D7a | 408 (225) | sampleSelection two-step | 0.03 |  |  |
| D7a | 408 (225) | endoSwitch FIML | 3.02 | code 0, 74 iterations: successful convergence  |  |
| D7a | 408 (225) | endoSwitch FIML (reltol 1e-14) | 3.13 | code 0, 72 iterations: successful convergence  |  |
| D7a | 408 (225) | endoSwitch two-stage | 0.02 |  |  |
| D7b | 408 (225) | SwitchEconometrics FIML | 0.26 | code 0 |  |
| D7b | 408 (225) | sampleSelection ML | 0.10 | code 8, 4 iterations: successive function values within relative tolerance limit (reltol) |  |
| D7b | 408 (225) | sampleSelection two-step | 0.04 |  |  |
| D7b | 408 (225) | endoSwitch FIML | 12.36 | code 0, 129 iterations: successful convergence  |  |
| D7b | 408 (225) | endoSwitch FIML (reltol 1e-14) | 12.89 | code 0, 131 iterations: successful convergence  |  |
| D7b | 408 (225) | endoSwitch two-stage | 0.01 |  |  |

## Two-step variance recovery (D-ES-1, D-SS-1)

| n | Estimator | sigma0 | rho0 | sigma1 | rho1 |
| --- | --- | --- | --- | --- | --- |
| 200000 | truth | 0.8000 | 0.4000 | 1.2000 | 0.6000 |
| 200000 | SwitchEconometrics two-step | 0.7959 | 0.3774 | 1.2008 | 0.5944 |
| 200000 | endoSwitch2Stage | 0.7797 | 0.3853 | 1.1394 | 0.6264 |
| 200000 | sampleSelection 2step | 0.7834 | 0.3834 | 1.1467 | 0.6224 |
| 400000 | truth | 0.8000 | 0.4000 | 1.2000 | 0.6000 |
| 400000 | SwitchEconometrics two-step | 0.8000 | 0.3903 | 1.2008 | 0.5990 |
| 400000 | endoSwitch2Stage | 0.7827 | 0.3990 | 1.1386 | 0.6317 |
| 400000 | sampleSelection 2step | 0.7866 | 0.3970 | 1.1458 | 0.6277 |

## Tables by dataset

### D1: base Monte Carlo design, (rho1, rho0) = (0.6, 0.4), N = 500

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -918.358 | -918.358 | 0.00e+00 | 0.00e+00 | pass |
| sampleSelection ML | selection:(Intercept) | 0.597044 | 0.597044 | -7.70e-13 | 7.70e-13 | pass |
| sampleSelection ML | selection:x1 | 0.310769 | 0.310769 | 1.84e-13 | 1.84e-13 | pass |
| sampleSelection ML | selection:z1 | -0.485833 | -0.485833 | -1.16e-13 | 1.16e-13 | pass |
| sampleSelection ML | regime_0:(Intercept) | 0.986571 | 0.986571 | -4.68e-11 | 4.68e-11 | pass |
| sampleSelection ML | regime_0:x1 | 0.451652 | 0.451652 | -9.41e-12 | 9.41e-12 | pass |
| sampleSelection ML | regime_0:x2 | 0.119998 | 0.119998 | 4.71e-13 | 4.71e-13 | pass |
| sampleSelection ML | regime_0:sigma | 0.959803 | 0.959803 | -9.53e-12 | 9.53e-12 | pass |
| sampleSelection ML | regime_0:rho | 0.490912 | 0.490912 | -4.45e-11 | 4.45e-11 | pass |
| sampleSelection ML | regime_1:(Intercept) | 1.56329 | 1.56329 | -1.35e-12 | 8.66e-13 | pass |
| sampleSelection ML | regime_1:x1 | 0.862247 | 0.862247 | 3.89e-13 | 3.89e-13 | pass |
| sampleSelection ML | regime_1:x2 | 0.380867 | 0.380867 | 5.97e-14 | 5.97e-14 | pass |
| sampleSelection ML | regime_1:sigma | 0.998438 | 0.998438 | 7.00e-13 | 7.00e-13 | pass |
| sampleSelection ML | regime_1:rho | 0.641145 | 0.641145 | 1.85e-12 | 1.85e-12 | pass |
| sampleSelection ML | SE selection:(Intercept) | 0.0638396 | 0.0638396 | -2.18e-14 | 3.42e-13 | pass |
| sampleSelection ML | SE selection:x1 | 0.0646008 | 0.0646008 | 1.18e-14 | 1.82e-13 | pass |
| sampleSelection ML | SE selection:z1 | 0.0636328 | 0.0636328 | -1.10e-13 | 1.72e-12 | pass |
| sampleSelection ML | SE regime_0:(Intercept) | 0.225615 | 0.225615 | 1.77e-11 | 7.83e-11 | pass |
| sampleSelection ML | SE regime_0:x1 | 0.0867184 | 0.0867184 | 1.88e-12 | 2.17e-11 | pass |
| sampleSelection ML | SE regime_0:x2 | 0.0714673 | 0.0714673 | 5.74e-13 | 8.04e-12 | pass |
| sampleSelection ML | SE regime_0:sigma | 0.0826353 | 0.0826353 | 6.19e-14 | 7.49e-13 | pass |
| sampleSelection ML | SE regime_0:rho | 0.171478 | 0.171478 | 2.39e-11 | 1.40e-10 | pass |
| sampleSelection ML | SE regime_1:(Intercept) | 0.0895554 | 0.0895554 | -1.88e-13 | 2.10e-12 | pass |
| sampleSelection ML | SE regime_1:x1 | 0.0570463 | 0.0570463 | 4.76e-15 | 8.35e-14 | pass |
| sampleSelection ML | SE regime_1:x2 | 0.0523053 | 0.0523053 | -5.47e-15 | 1.05e-13 | pass |
| sampleSelection ML | SE regime_1:sigma | 0.0590022 | 0.0590022 | 1.46e-14 | 2.47e-13 | pass |
| sampleSelection ML | SE regime_1:rho | 0.130381 | 0.130381 | -9.16e-13 | 7.03e-12 | pass |
| sampleSelection ML | ATT | 0.720547 | 0.720547 | 6.82e-11 | 6.82e-11 | pass |
| sampleSelection ML | ATU | 0.301241 | 0.301241 | -7.34e-12 | 7.34e-12 | pass |
| sampleSelection ML | ATE | 0.595898 | 0.595898 | 4.57e-11 | 4.57e-11 | pass |
| sampleSelection ML | TH | 0.419306 | 0.419306 | 7.55e-11 | 7.55e-11 | pass |
| sampleSelection ML | BH1 | 1.29944 | 1.29944 | 3.31e-12 | 2.55e-12 | pass |
| sampleSelection ML | BH0 | 0.880138 | 0.880138 | -7.22e-11 | 7.22e-11 | pass |
| sampleSelection ML | EY1_S1 (largest unit difference) | 0.196761 | 0.196761 | 2.12e-12 | 2.12e-12 | pass |
| sampleSelection ML | EY1_S0 (largest unit difference) | 0.460844 | 0.460844 | -6.72e-12 | 6.72e-12 | pass |
| sampleSelection ML | EY0_S1 (largest unit difference) | 0.515647 | 0.515647 | -9.86e-11 | 9.86e-11 | pass |
| sampleSelection ML | EY0_S0 (largest unit difference) | 0.427201 | 0.427201 | 6.78e-11 | 6.78e-11 | pass |
| sampleSelection two-step | selection:(Intercept) | 0.590986 | 0.590986 | 6.33e-10 | 6.33e-10 | pass |
| sampleSelection two-step | selection:x1 | 0.311993 | 0.311993 | 5.22e-10 | 5.22e-10 | pass |
| sampleSelection two-step | selection:z1 | -0.469061 | -0.469061 | -7.52e-10 | 7.52e-10 | pass |
| sampleSelection two-step | regime_0:(Intercept) | 1.14374 | 1.14374 | -8.21e-10 | 8.21e-10 | pass |
| sampleSelection two-step | regime_0:x1 | 0.483321 | 0.483321 | 2.26e-11 | 2.26e-11 | pass |
| sampleSelection two-step | regime_0:x2 | 0.118401 | 0.118401 | -1.15e-12 | 1.15e-12 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | 0.617226 | 0.617226 | -9.25e-10 | 9.25e-10 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 1.59278 | 1.59278 | 4.31e-10 | 4.31e-10 | pass |
| sampleSelection two-step | regime_1:x1 | 0.854919 | 0.854919 | -3.50e-12 | 3.50e-12 | pass |
| sampleSelection two-step | regime_1:x2 | 0.375054 | 0.375054 | 7.59e-13 | 7.59e-13 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | 0.572797 | 0.572797 | -6.41e-10 | 6.41e-10 | pass |
| sampleSelection two-step | regime_0:sigma |  1.0066 | 0.974933 | 3.17e-02 |  | documented |
| sampleSelection two-step | regime_1:sigma | 0.982126 | 0.945131 | 3.70e-02 |  | documented |
| sampleSelection two-step | regime_0:rho | 0.613177 | 0.633096 | -1.99e-02 |  | documented |
| sampleSelection two-step | regime_1:rho | 0.583221 | 0.60605 | -2.28e-02 |  | documented |
| endoSwitch FIML | log-likelihood | -918.358 | -918.358 | 3.75e-10 | 3.75e-10 | pass |
| endoSwitch FIML | selection:(Intercept) | 0.597044 | 0.597045 | -4.17e-07 | 4.17e-07 | pass |
| endoSwitch FIML | selection:x1 | 0.310769 | 0.310769 | -6.50e-08 | 6.50e-08 | pass |
| endoSwitch FIML | selection:z1 | -0.485833 | -0.485832 | -4.96e-07 | 4.96e-07 | pass |
| endoSwitch FIML | regime_0:(Intercept) | 0.986571 | 0.986571 | -3.28e-07 | 3.28e-07 | pass |
| endoSwitch FIML | regime_0:x1 | 0.451652 | 0.451652 | 8.77e-08 | 8.77e-08 | pass |
| endoSwitch FIML | regime_0:x2 | 0.119998 | 0.119998 | -4.85e-08 | 4.85e-08 | pass |
| endoSwitch FIML | regime_0:sigma | 0.959803 | 0.959804 | -4.28e-07 | 4.28e-07 | pass |
| endoSwitch FIML | regime_0:rho | 0.490912 | 0.490913 | -5.40e-07 | 5.40e-07 | pass |
| endoSwitch FIML | regime_1:(Intercept) | 1.56329 | 1.56329 | -1.36e-06 | 8.67e-07 | pass |
| endoSwitch FIML | regime_1:x1 | 0.862247 | 0.862247 | 2.08e-07 | 2.08e-07 | pass |
| endoSwitch FIML | regime_1:x2 | 0.380867 | 0.380867 | -4.87e-07 | 4.87e-07 | pass |
| endoSwitch FIML | regime_1:sigma | 0.998438 | 0.998438 | 7.34e-07 | 7.34e-07 | pass |
| endoSwitch FIML | regime_1:rho | 0.641145 | 0.641143 | 2.28e-06 | 2.28e-06 | pass |
| endoSwitch FIML | SE selection:(Intercept) | 0.0638396 | 0.0638264 | 1.32e-05 | 2.08e-04 | pass |
| endoSwitch FIML | SE selection:x1 | 0.0646008 | 0.0645189 | 8.19e-05 | 1.27e-03 | pass |
| endoSwitch FIML | SE selection:z1 | 0.0636328 | 0.0635728 | 6.00e-05 | 9.43e-04 | pass |
| endoSwitch FIML | SE regime_0:(Intercept) | 0.225615 | 0.221796 | 3.82e-03 | 1.72e-02 | FAIL |
| endoSwitch FIML | SE regime_0:x1 | 0.0867184 | 0.0859146 | 8.04e-04 | 9.36e-03 | pass |
| endoSwitch FIML | SE regime_0:x2 | 0.0714673 | 0.0714728 | -5.41e-06 | 7.57e-05 | pass |
| endoSwitch FIML | SE regime_0:sigma | 0.0826353 | 0.0816299 | 1.01e-03 | 1.23e-02 | FAIL |
| endoSwitch FIML | SE regime_0:rho | 0.171478 | 0.168792 | 2.69e-03 | 1.59e-02 | FAIL |
| endoSwitch FIML | SE regime_1:(Intercept) | 0.0895554 | 0.0898563 | -3.01e-04 | 3.35e-03 | pass |
| endoSwitch FIML | SE regime_1:x1 | 0.0570463 | 0.0570216 | 2.47e-05 | 4.33e-04 | pass |
| endoSwitch FIML | SE regime_1:x2 | 0.0523053 | 0.0523067 | -1.39e-06 | 2.66e-05 | pass |
| endoSwitch FIML | SE regime_1:sigma | 0.0590022 | 0.0591024 | -1.00e-04 | 1.70e-03 | pass |
| endoSwitch FIML | SE regime_1:rho | 0.130381 | 0.130949 | -5.67e-04 | 4.33e-03 | pass |
| endoSwitch FIML | ATT | 0.720547 |  0.7205 | 4.68e-05 | 4.68e-05 | pass |
| endoSwitch FIML | ATU | 0.301241 |  0.3012 | 4.11e-05 | 4.11e-05 | pass |
| endoSwitch FIML | TH | 0.419306 |  0.4193 | 5.73e-06 | 5.73e-06 | pass |
| endoSwitch FIML | BH1 | 1.29944 |  1.2994 | 4.33e-05 | 3.34e-05 | pass |
| endoSwitch FIML | BH0 | 0.880138 |  0.8801 | 3.76e-05 | 3.76e-05 | pass |
| endoSwitch FIML | EY1_S1 (largest unit difference) | 0.790124 | 0.790121 | 2.73e-06 | 2.73e-06 | pass |
| endoSwitch FIML | EY1_S1 formula at their estimates (largest unit difference) | 2.80849 | 2.80849 | -8.88e-16 | 3.16e-16 | pass |
| endoSwitch FIML | EY0_S1 (largest unit difference) | 0.386683 | 0.386684 | -1.01e-06 | 1.01e-06 | pass |
| endoSwitch FIML | EY0_S1 formula at their estimates (largest unit difference) | 2.03362 | 2.03362 | -4.44e-16 | 2.18e-16 | pass |
| endoSwitch FIML | EY1_S0 (largest unit difference) | -0.363195 | -0.363188 | -7.02e-06 | 7.02e-06 | pass |
| endoSwitch FIML | EY1_S0 formula at their estimates (largest unit difference) | 1.81522 | 1.81522 | -8.66e-15 | 4.77e-15 | pass |
| endoSwitch FIML | EY0_S0 (largest unit difference) | 0.753483 | 0.753481 | 1.58e-06 | 1.58e-06 | pass |
| endoSwitch FIML | EY0_S0 formula at their estimates (largest unit difference) | 0.753481 | 0.753481 | -6.22e-15 | 6.22e-15 | pass |
| endoSwitch FIML (reltol 1e-14) | log-likelihood | -918.358 | -918.358 | 1.14e-13 | 1.14e-13 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:(Intercept) | 0.597044 | 0.597044 | 1.04e-09 | 1.04e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:x1 | 0.310769 | 0.310769 | 5.95e-10 | 5.95e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:z1 | -0.485833 | -0.485833 | 2.56e-10 | 2.56e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:(Intercept) | 0.986571 | 0.986571 | 3.07e-09 | 3.07e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:x1 | 0.451652 | 0.451652 | -4.67e-10 | 4.67e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:x2 | 0.119998 | 0.119998 | 3.24e-10 | 3.24e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:sigma | 0.959803 | 0.959803 | 5.54e-10 | 5.54e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:rho | 0.490912 | 0.490912 | 7.96e-09 | 7.96e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:(Intercept) | 1.56329 | 1.56329 | 5.72e-10 | 3.66e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:x1 | 0.862247 | 0.862247 | 1.08e-09 | 1.08e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:x2 | 0.380867 | 0.380867 | 1.45e-09 | 1.45e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:sigma | 0.998438 | 0.998438 | -2.72e-09 | 2.72e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:rho | 0.641145 | 0.641145 | -8.24e-10 | 8.24e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:(Intercept) | 0.0638396 | 0.0638433 | -3.69e-06 | 5.78e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:x1 | 0.0646008 | 0.0645889 | 1.19e-05 | 1.84e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:z1 | 0.0636328 | 0.0635367 | 9.61e-05 | 1.51e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:(Intercept) | 0.225615 | 0.223598 | 2.02e-03 | 9.02e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:x1 | 0.0867184 | 0.0863524 | 3.66e-04 | 4.24e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:x2 | 0.0714673 | 0.0714567 | 1.07e-05 | 1.50e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:sigma | 0.0826353 | 0.0820378 | 5.97e-04 | 7.28e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:rho | 0.171478 | 0.170276 | 1.20e-03 | 7.06e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:(Intercept) | 0.0895554 | 0.0890375 | 5.18e-04 | 5.82e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:x1 | 0.0570463 | 0.0569075 | 1.39e-04 | 2.44e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:x2 | 0.0523053 | 0.0522981 | 7.22e-06 | 1.38e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:sigma | 0.0590022 | 0.0586424 | 3.60e-04 | 6.13e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:rho | 0.130381 | 0.129127 | 1.25e-03 | 9.71e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | ATT | 0.720547 |  0.7205 | 4.68e-05 | 4.68e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | ATU | 0.301241 |  0.3012 | 4.11e-05 | 4.11e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | TH | 0.419306 |  0.4193 | 5.73e-06 | 5.73e-06 | pass |
| endoSwitch FIML (reltol 1e-14) | BH1 | 1.29944 |  1.2994 | 4.33e-05 | 3.34e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | BH0 | 0.880138 |  0.8801 | 3.76e-05 | 3.76e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 (largest unit difference) | 0.790124 | 0.790124 | -5.88e-09 | 5.88e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 formula at their estimates (largest unit difference) | 2.63635 | 2.63635 | 8.88e-16 | 3.37e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 (largest unit difference) | 0.98661 | 0.98661 | 1.28e-08 | 1.28e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 formula at their estimates (largest unit difference) | 1.47128 | 1.47128 | -4.44e-16 | 3.02e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 (largest unit difference) | 1.00881 | 1.00881 | 6.42e-09 | 6.37e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 formula at their estimates (largest unit difference) | 1.81521 | 1.81521 | 7.77e-15 | 4.28e-15 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 (largest unit difference) | 0.753483 | 0.753483 | -1.95e-08 | 1.95e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 formula at their estimates (largest unit difference) | 0.753483 | 0.753483 | 5.55e-15 | 5.55e-15 | pass |
| endoSwitch two-stage | selection:(Intercept) | 0.590986 | 0.590986 | 1.71e-07 | 1.71e-07 | pass |
| endoSwitch two-stage | selection:x1 | 0.311993 | 0.311993 | 2.84e-07 | 2.84e-07 | pass |
| endoSwitch two-stage | selection:z1 | -0.469061 | -0.469061 | -2.18e-07 | 2.18e-07 | pass |
| endoSwitch two-stage | regime_0:(Intercept) | 1.14374 | 1.14374 | -2.27e-07 | 2.27e-07 | pass |
| endoSwitch two-stage | regime_0:x1 | 0.483321 | 0.483321 | 6.28e-08 | 6.28e-08 | pass |
| endoSwitch two-stage | regime_0:x2 | 0.118401 | 0.118401 | -6.35e-10 | 6.35e-10 | pass |
| endoSwitch two-stage | theta0 = sigma0 rho0 (minus their MillsRatioAdt0) | 0.617226 | 0.617227 | -2.57e-07 | 2.57e-07 | pass |
| endoSwitch two-stage | regime_1:(Intercept) | 1.59278 | 1.59278 | 1.24e-07 | 1.24e-07 | pass |
| endoSwitch two-stage | regime_1:x1 | 0.854919 | 0.854919 | 2.93e-08 | 2.93e-08 | pass |
| endoSwitch two-stage | regime_1:x2 | 0.375054 | 0.375054 | -6.26e-10 | 6.26e-10 | pass |
| endoSwitch two-stage | theta1 = sigma1 rho1 (their MillsRatioAdt1) | 0.572797 | 0.572797 | -2.01e-07 | 2.01e-07 | pass |
| endoSwitch two-stage | regime_0:sigma |  1.0066 | 0.968811 | 3.78e-02 |  | documented |
| endoSwitch two-stage | regime_0:rho | 0.613177 | 0.637097 | -2.39e-02 |  | documented |
| endoSwitch two-stage | regime_1:sigma | 0.982126 | 0.942101 | 4.00e-02 |  | documented |
| endoSwitch two-stage | regime_1:rho | 0.583221 |   0.608 | -2.48e-02 |  | documented |

### D2: base Monte Carlo design, N = 2000

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -3796.82 | -3796.82 | 1.36e-12 | 1.36e-12 | pass |
| sampleSelection ML | selection:(Intercept) | 0.52323 | 0.52323 | -2.61e-10 | 2.61e-10 | pass |
| sampleSelection ML | selection:x1 | 0.313457 | 0.313457 | 1.18e-09 | 1.18e-09 | pass |
| sampleSelection ML | selection:z1 | -0.39309 | -0.39309 | -6.62e-09 | 6.62e-09 | pass |
| sampleSelection ML | regime_0:(Intercept) | 1.24384 | 1.24384 | -1.97e-07 | 1.58e-07 | pass |
| sampleSelection ML | regime_0:x1 | 0.580859 | 0.580859 | -3.73e-08 | 3.73e-08 | pass |
| sampleSelection ML | regime_0:x2 | 0.178778 | 0.178778 | -3.87e-09 | 3.87e-09 | pass |
| sampleSelection ML | regime_0:sigma | 1.09871 | 1.09871 | -5.90e-08 | 5.37e-08 | pass |
| sampleSelection ML | regime_0:rho | 0.567954 | 0.567955 | -1.48e-07 | 1.48e-07 | pass |
| sampleSelection ML | regime_1:(Intercept) | 1.49882 | 1.49882 | 2.83e-09 | 1.89e-09 | pass |
| sampleSelection ML | regime_1:x1 | 0.803678 | 0.803678 | -6.55e-10 | 6.55e-10 | pass |
| sampleSelection ML | regime_1:x2 | 0.400394 | 0.400394 | -4.75e-11 | 4.75e-11 | pass |
| sampleSelection ML | regime_1:sigma | 0.992715 | 0.992715 | -1.94e-09 | 1.94e-09 | pass |
| sampleSelection ML | regime_1:rho |  0.6258 |  0.6258 | -5.03e-09 | 5.03e-09 | pass |
| sampleSelection ML | SE selection:(Intercept) | 0.0309995 | 0.0309995 | 6.75e-12 | 2.18e-10 | pass |
| sampleSelection ML | SE selection:x1 | 0.0312737 | 0.0312737 | 6.65e-11 | 2.13e-09 | pass |
| sampleSelection ML | SE selection:z1 | 0.030316 | 0.030316 | 5.04e-10 | 1.66e-08 | pass |
| sampleSelection ML | SE regime_0:(Intercept) | 0.150927 | 0.150927 | 5.84e-08 | 3.87e-07 | pass |
| sampleSelection ML | SE regime_0:x1 | 0.0490232 | 0.0490232 | 5.85e-09 | 1.19e-07 | pass |
| sampleSelection ML | SE regime_0:x2 | 0.0385296 | 0.0385296 | 8.91e-10 | 2.31e-08 | pass |
| sampleSelection ML | SE regime_0:sigma | 0.0589294 | 0.0589294 | 6.71e-09 | 1.14e-07 | pass |
| sampleSelection ML | SE regime_0:rho | 0.0969501 | 0.09695 | 6.22e-08 | 6.42e-07 | pass |
| sampleSelection ML | SE regime_1:(Intercept) | 0.0523281 | 0.0523281 | 2.85e-10 | 5.44e-09 | pass |
| sampleSelection ML | SE regime_1:x1 | 0.0295453 | 0.0295453 | 2.77e-11 | 9.39e-10 | pass |
| sampleSelection ML | SE regime_1:x2 | 0.0242336 | 0.0242336 | 2.98e-13 | 1.23e-11 | pass |
| sampleSelection ML | SE regime_1:sigma | 0.0328216 | 0.0328216 | -1.17e-10 | 3.57e-09 | pass |
| sampleSelection ML | SE regime_1:rho |   0.074 |   0.074 | 1.00e-09 | 1.36e-08 | pass |
| sampleSelection ML | ATT | 0.289996 | 0.289995 | 2.94e-07 | 2.94e-07 | pass |
| sampleSelection ML | ATU | 0.181366 | 0.181366 | -1.25e-10 | 1.25e-10 | pass |
| sampleSelection ML | ATE | 0.254961 | 0.254961 | 1.99e-07 | 1.99e-07 | pass |
| sampleSelection ML | TH | 0.108629 | 0.108629 | 2.94e-07 | 2.94e-07 | pass |
| sampleSelection ML | BH1 | 1.30052 | 1.30052 | -1.04e-08 | 7.98e-09 | pass |
| sampleSelection ML | BH0 | 1.19189 | 1.19189 | -3.05e-07 | 2.56e-07 | pass |
| sampleSelection ML | EY1_S1 (largest unit difference) | 0.851112 | 0.851112 | 4.45e-09 | 4.45e-09 | pass |
| sampleSelection ML | EY1_S0 (largest unit difference) | 0.890454 | 0.890454 | 1.21e-08 | 1.21e-08 | pass |
| sampleSelection ML | EY0_S1 (largest unit difference) | 1.02733 | 1.02733 | -4.14e-07 | 4.03e-07 | pass |
| sampleSelection ML | EY0_S0 (largest unit difference) | 0.034464 | 0.0344637 | 2.78e-07 | 2.78e-07 | pass |
| sampleSelection two-step | selection:(Intercept) | 0.521594 | 0.521594 | 3.51e-11 | 3.51e-11 | pass |
| sampleSelection two-step | selection:x1 | 0.309791 | 0.309791 | 3.31e-11 | 3.31e-11 | pass |
| sampleSelection two-step | selection:z1 | -0.390161 | -0.390161 | -4.21e-11 | 4.21e-11 | pass |
| sampleSelection two-step | regime_0:(Intercept) | 1.30098 | 1.30098 | -6.32e-11 | 6.32e-11 | pass |
| sampleSelection two-step | regime_0:x1 | 0.588909 | 0.588909 | 2.01e-13 | 2.01e-13 | pass |
| sampleSelection two-step | regime_0:x2 | 0.178928 | 0.178928 | 6.98e-14 | 6.98e-14 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | 0.678685 | 0.678685 | -7.02e-11 | 7.02e-11 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 1.50104 | 1.50104 | 3.41e-11 | 3.41e-11 | pass |
| sampleSelection two-step | regime_1:x1 | 0.804397 | 0.804397 | -5.08e-13 | 5.08e-13 | pass |
| sampleSelection two-step | regime_1:x2 | 0.398592 | 0.398592 | -1.33e-14 | 1.33e-14 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | 0.615957 | 0.615957 | -5.13e-11 | 5.13e-11 | pass |
| sampleSelection two-step | regime_0:sigma | 1.11825 |   1.075 | 4.32e-02 |  | documented |
| sampleSelection two-step | regime_1:sigma | 0.991446 | 0.943848 | 4.76e-02 |  | documented |
| sampleSelection two-step | regime_0:rho | 0.606919 | 0.631336 | -2.44e-02 |  | documented |
| sampleSelection two-step | regime_1:rho | 0.621271 | 0.652602 | -3.13e-02 |  | documented |
| endoSwitch FIML | log-likelihood | -3796.82 | -3796.82 | 6.18e-09 | 6.18e-09 | pass |
| endoSwitch FIML | selection:(Intercept) | 0.52323 | 0.52323 | -3.86e-07 | 3.86e-07 | pass |
| endoSwitch FIML | selection:x1 | 0.313457 | 0.313457 | 1.15e-08 | 1.15e-08 | pass |
| endoSwitch FIML | selection:z1 | -0.39309 | -0.393089 | -8.30e-07 | 8.30e-07 | pass |
| endoSwitch FIML | regime_0:(Intercept) | 1.24384 | 1.24385 | -1.28e-05 | 1.03e-05 | pass |
| endoSwitch FIML | regime_0:x1 | 0.580859 | 0.580862 | -3.05e-06 | 3.05e-06 | pass |
| endoSwitch FIML | regime_0:x2 | 0.178778 | 0.178779 | -9.55e-07 | 9.55e-07 | pass |
| endoSwitch FIML | regime_0:sigma | 1.09871 | 1.09872 | -3.82e-06 | 3.48e-06 | pass |
| endoSwitch FIML | regime_0:rho | 0.567954 | 0.567964 | -9.40e-06 | 9.40e-06 | pass |
| endoSwitch FIML | regime_1:(Intercept) | 1.49882 | 1.49882 | 5.40e-07 | 3.60e-07 | pass |
| endoSwitch FIML | regime_1:x1 | 0.803678 | 0.803678 | -8.63e-08 | 8.63e-08 | pass |
| endoSwitch FIML | regime_1:x2 | 0.400394 | 0.400394 | -7.24e-10 | 7.24e-10 | pass |
| endoSwitch FIML | regime_1:sigma | 0.992715 | 0.992715 | -5.63e-07 | 5.63e-07 | pass |
| endoSwitch FIML | regime_1:rho |  0.6258 | 0.625801 | -9.78e-07 | 9.78e-07 | pass |
| endoSwitch FIML | SE selection:(Intercept) | 0.0309995 | 0.0310017 | -2.23e-06 | 7.21e-05 | pass |
| endoSwitch FIML | SE selection:x1 | 0.0312737 | 0.0312743 | -6.14e-07 | 1.96e-05 | pass |
| endoSwitch FIML | SE selection:z1 | 0.030316 | 0.030434 | -1.18e-04 | 3.88e-03 | pass |
| endoSwitch FIML | SE regime_0:(Intercept) | 0.150927 | 0.152992 | -2.07e-03 | 1.35e-02 | FAIL |
| endoSwitch FIML | SE regime_0:x1 | 0.0490232 | 0.0494301 | -4.07e-04 | 8.23e-03 | pass |
| endoSwitch FIML | SE regime_0:x2 | 0.0385296 | 0.0385512 | -2.16e-05 | 5.59e-04 | pass |
| endoSwitch FIML | SE regime_0:sigma | 0.0589294 | 0.0596799 | -7.51e-04 | 1.26e-02 | FAIL |
| endoSwitch FIML | SE regime_0:rho | 0.0969501 | 0.0981908 | -1.24e-03 | 1.26e-02 | FAIL |
| endoSwitch FIML | SE regime_1:(Intercept) | 0.0523281 | 0.0524336 | -1.05e-04 | 2.01e-03 | pass |
| endoSwitch FIML | SE regime_1:x1 | 0.0295453 | 0.0296053 | -6.00e-05 | 2.03e-03 | pass |
| endoSwitch FIML | SE regime_1:x2 | 0.0242336 | 0.0242436 | -1.00e-05 | 4.14e-04 | pass |
| endoSwitch FIML | SE regime_1:sigma | 0.0328216 | 0.0329191 | -9.75e-05 | 2.96e-03 | pass |
| endoSwitch FIML | SE regime_1:rho |   0.074 | 0.0742976 | -2.98e-04 | 4.01e-03 | pass |
| endoSwitch FIML | ATT | 0.289996 |    0.29 | -4.46e-06 | 4.46e-06 | pass |
| endoSwitch FIML | ATU | 0.181366 |  0.1814 | -3.36e-05 | 3.36e-05 | pass |
| endoSwitch FIML | TH | 0.108629 |  0.1086 | 2.91e-05 | 2.91e-05 | pass |
| endoSwitch FIML | BH1 | 1.30052 |  1.3005 | 2.14e-05 | 1.65e-05 | pass |
| endoSwitch FIML | BH0 | 1.19189 |  1.1919 | -7.72e-06 | 6.48e-06 | pass |
| endoSwitch FIML | EY1_S1 (largest unit difference) | -0.783261 | -0.78326 | -3.66e-07 | 3.66e-07 | pass |
| endoSwitch FIML | EY1_S1 formula at their estimates (largest unit difference) | 4.02327 | 4.02327 | 8.88e-16 | 2.21e-16 | pass |
| endoSwitch FIML | EY0_S1 (largest unit difference) | 0.977826 | 0.977848 | -2.19e-05 | 2.19e-05 | pass |
| endoSwitch FIML | EY0_S1 formula at their estimates (largest unit difference) | 2.49354 | 2.49354 | -8.88e-16 | 3.56e-16 | pass |
| endoSwitch FIML | EY1_S0 (largest unit difference) | 0.851883 | 0.851881 | 2.53e-06 | 2.53e-06 | pass |
| endoSwitch FIML | EY1_S0 formula at their estimates (largest unit difference) | 2.65125 | 2.65125 | -1.78e-15 | 6.70e-16 | pass |
| endoSwitch FIML | EY0_S0 (largest unit difference) | -0.215451 | -0.215462 | 1.07e-05 | 1.07e-05 | pass |
| endoSwitch FIML | EY0_S0 formula at their estimates (largest unit difference) |  1.6926 |  1.6926 | -1.78e-15 | 1.05e-15 | pass |
| endoSwitch FIML (reltol 1e-14) | log-likelihood | -3796.82 | -3796.82 | 0.00e+00 | 0.00e+00 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:(Intercept) | 0.52323 | 0.52323 | 1.29e-09 | 1.29e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:x1 | 0.313457 | 0.313457 | -4.23e-10 | 4.23e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:z1 | -0.39309 | -0.39309 | 5.61e-10 | 5.61e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:(Intercept) | 1.24384 | 1.24384 | -6.77e-09 | 5.44e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:x1 | 0.580859 | 0.580859 | -1.57e-09 | 1.57e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:x2 | 0.178778 | 0.178778 | 8.52e-10 | 8.52e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:sigma | 1.09871 | 1.09871 | -4.07e-09 | 3.71e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:rho | 0.567954 | 0.567954 | -2.61e-09 | 2.61e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:(Intercept) | 1.49882 | 1.49882 | -4.42e-10 | 2.95e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:x1 | 0.803678 | 0.803678 | -5.17e-10 | 5.17e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:x2 | 0.400394 | 0.400394 | 1.42e-10 | 1.42e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:sigma | 0.992715 | 0.992715 | 1.65e-09 | 1.65e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:rho |  0.6258 |  0.6258 | 9.04e-11 | 9.04e-11 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:(Intercept) | 0.0309995 | 0.0310109 | -1.14e-05 | 3.67e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:x1 | 0.0312737 | 0.0312781 | -4.40e-06 | 1.41e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:z1 | 0.030316 | 0.0302588 | 5.72e-05 | 1.89e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:(Intercept) | 0.150927 | 0.147532 | 3.40e-03 | 2.30e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:x1 | 0.0490232 | 0.0484607 | 5.63e-04 | 1.16e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:x2 | 0.0385296 | 0.0385138 | 1.59e-05 | 4.12e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:sigma | 0.0589294 | 0.057856 | 1.07e-03 | 1.86e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:rho | 0.0969501 | 0.0948382 | 2.11e-03 | 2.23e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:(Intercept) | 0.0523281 | 0.0525284 | -2.00e-04 | 3.81e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:x1 | 0.0295453 | 0.0295971 | -5.18e-05 | 1.75e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:x2 | 0.0242336 | 0.0242365 | -2.95e-06 | 1.22e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:sigma | 0.0328216 | 0.0329462 | -1.25e-04 | 3.78e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:rho |   0.074 | 0.0744242 | -4.24e-04 | 5.70e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | ATT | 0.289996 |    0.29 | -4.46e-06 | 4.46e-06 | pass |
| endoSwitch FIML (reltol 1e-14) | ATU | 0.181366 |  0.1814 | -3.36e-05 | 3.36e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | TH | 0.108629 |  0.1086 | 2.91e-05 | 2.91e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | BH1 | 1.30052 |  1.3005 | 2.14e-05 | 1.65e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | BH0 | 1.19189 |  1.1919 | -7.72e-06 | 6.48e-06 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 (largest unit difference) | 0.930205 | 0.930205 | -1.05e-09 | 1.05e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 formula at their estimates (largest unit difference) | 2.62747 | 2.62747 | -8.88e-16 | 3.38e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 (largest unit difference) | 0.832243 | 0.832243 | -1.32e-08 | 1.32e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 formula at their estimates (largest unit difference) | 2.19739 | 2.19739 | -4.44e-16 | 2.02e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 (largest unit difference) | 0.851883 | 0.851883 | -3.31e-09 | 3.31e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 formula at their estimates (largest unit difference) | 0.647815 | 0.647815 | 1.33e-15 | 1.33e-15 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 (largest unit difference) | 0.671426 | 0.671426 | -6.99e-09 | 6.99e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 formula at their estimates (largest unit difference) | 1.40545 | 1.40545 | 1.11e-15 | 7.90e-16 | pass |
| endoSwitch two-stage | selection:(Intercept) | 0.521594 | 0.521594 | 1.76e-09 | 1.76e-09 | pass |
| endoSwitch two-stage | selection:x1 | 0.309791 | 0.309791 | 3.74e-09 | 3.74e-09 | pass |
| endoSwitch two-stage | selection:z1 | -0.390161 | -0.390161 | -3.52e-09 | 3.52e-09 | pass |
| endoSwitch two-stage | regime_0:(Intercept) | 1.30098 | 1.30098 | -5.42e-09 | 5.42e-09 | pass |
| endoSwitch two-stage | regime_0:x1 | 0.588909 | 0.588909 | 4.72e-10 | 4.72e-10 | pass |
| endoSwitch two-stage | regime_0:x2 | 0.178928 | 0.178928 | 9.99e-12 | 9.99e-12 | pass |
| endoSwitch two-stage | theta0 = sigma0 rho0 (minus their MillsRatioAdt0) | 0.678685 | 0.678685 | -5.51e-09 | 5.51e-09 | pass |
| endoSwitch two-stage | regime_1:(Intercept) | 1.50104 | 1.50104 | 2.60e-09 | 2.60e-09 | pass |
| endoSwitch two-stage | regime_1:x1 | 0.804397 | 0.804397 | 2.45e-10 | 2.45e-10 | pass |
| endoSwitch two-stage | regime_1:x2 | 0.398592 | 0.398592 | -1.12e-12 | 1.12e-12 | pass |
| endoSwitch two-stage | theta1 = sigma1 rho1 (their MillsRatioAdt1) | 0.615957 | 0.615957 | -4.56e-09 | 4.56e-09 | pass |
| endoSwitch two-stage | regime_0:sigma | 1.11825 | 1.06208 | 5.62e-02 |  | documented |
| endoSwitch two-stage | regime_0:rho | 0.606919 | 0.639017 | -3.21e-02 |  | documented |
| endoSwitch two-stage | regime_1:sigma | 0.991446 | 0.937585 | 5.39e-02 |  | documented |
| endoSwitch two-stage | regime_1:rho | 0.621271 | 0.656961 | -3.57e-02 |  | documented |

### D3: base Monte Carlo design, N = 10 000

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -19127.4 | -19127.4 | 1.46e-11 | 1.46e-11 | pass |
| sampleSelection ML | selection:(Intercept) | 0.507192 | 0.507192 | 2.57e-09 | 2.57e-09 | pass |
| sampleSelection ML | selection:x1 | 0.285577 | 0.285577 | -2.82e-10 | 2.82e-10 | pass |
| sampleSelection ML | selection:z1 | -0.394614 | -0.394614 | -8.75e-09 | 8.75e-09 | pass |
| sampleSelection ML | regime_0:(Intercept) | 0.898658 | 0.898658 | -6.11e-09 | 6.11e-09 | pass |
| sampleSelection ML | regime_0:x1 | 0.510015 | 0.510015 | -1.22e-09 | 1.22e-09 | pass |
| sampleSelection ML | regime_0:x2 | 0.201481 | 0.201481 | 7.40e-12 | 7.40e-12 | pass |
| sampleSelection ML | regime_0:sigma | 0.986397 | 0.986397 | -1.20e-09 | 1.20e-09 | pass |
| sampleSelection ML | regime_0:rho | 0.299398 | 0.299398 | -5.51e-09 | 5.51e-09 | pass |
| sampleSelection ML | regime_1:(Intercept) | 1.52295 | 1.52295 | 9.07e-08 | 5.96e-08 | pass |
| sampleSelection ML | regime_1:x1 | 0.785421 | 0.785421 | -2.17e-08 | 2.17e-08 | pass |
| sampleSelection ML | regime_1:x2 | 0.383632 | 0.383632 | -1.46e-10 | 1.46e-10 | pass |
| sampleSelection ML | regime_1:sigma | 1.00002 | 1.00002 | -4.21e-08 | 4.21e-08 | pass |
| sampleSelection ML | regime_1:rho | 0.587428 | 0.587428 | -1.67e-07 | 1.67e-07 | pass |
| sampleSelection ML | SE selection:(Intercept) | 0.013754 | 0.013754 | 1.18e-11 | 8.60e-10 | pass |
| sampleSelection ML | SE selection:x1 | 0.0138935 | 0.0138935 | 1.22e-10 | 8.79e-09 | pass |
| sampleSelection ML | SE selection:z1 | 0.0138518 | 0.0138518 | 4.75e-10 | 3.43e-08 | pass |
| sampleSelection ML | SE regime_0:(Intercept) | 0.0686261 | 0.0686261 | -1.22e-09 | 1.78e-08 | pass |
| sampleSelection ML | SE regime_0:x1 | 0.0205996 | 0.0205996 | -1.43e-10 | 6.93e-09 | pass |
| sampleSelection ML | SE regime_0:x2 | 0.0168321 | 0.0168321 | 1.33e-13 | 7.92e-12 | pass |
| sampleSelection ML | SE regime_0:sigma | 0.0173278 | 0.0173278 | -3.59e-10 | 2.07e-08 | pass |
| sampleSelection ML | SE regime_0:rho | 0.0600947 | 0.0600947 | -9.20e-10 | 1.53e-08 | pass |
| sampleSelection ML | SE regime_1:(Intercept) | 0.0241413 | 0.0241412 | 1.07e-08 | 4.42e-07 | pass |
| sampleSelection ML | SE regime_1:x1 | 0.0130396 | 0.0130396 | 9.19e-10 | 7.05e-08 | pass |
| sampleSelection ML | SE regime_1:x2 | 0.0111634 | 0.0111634 | 2.05e-10 | 1.84e-08 | pass |
| sampleSelection ML | SE regime_1:sigma | 0.0145595 | 0.0145595 | 2.46e-09 | 1.69e-07 | pass |
| sampleSelection ML | SE regime_1:rho | 0.035088 | 0.035088 | 2.77e-08 | 7.88e-07 | pass |
| sampleSelection ML | ATT | 0.800445 | 0.800445 | 4.69e-09 | 4.69e-09 | pass |
| sampleSelection ML | ATU | 0.250122 | 0.250121 | 2.89e-07 | 2.89e-07 | pass |
| sampleSelection ML | ATE | 0.622415 | 0.622415 | 9.69e-08 | 9.69e-08 | pass |
| sampleSelection ML | TH | 0.550323 | 0.550324 | -2.84e-07 | 2.84e-07 | pass |
| sampleSelection ML | BH1 | 1.20249 | 1.20249 | -2.94e-07 | 2.44e-07 | pass |
| sampleSelection ML | BH0 | 0.652165 | 0.652165 | -9.41e-09 | 9.41e-09 | pass |
| sampleSelection ML | EY1_S1 (largest unit difference) | 1.05243 | 1.05243 | -1.68e-07 | 1.59e-07 | pass |
| sampleSelection ML | EY1_S0 (largest unit difference) | 0.348298 | 0.348298 | 5.25e-07 | 5.25e-07 | pass |
| sampleSelection ML | EY0_S1 (largest unit difference) | 0.985998 | 0.985998 | -9.85e-09 | 9.85e-09 | pass |
| sampleSelection ML | EY0_S0 (largest unit difference) | -0.282365 | -0.282365 | -1.73e-09 | 1.73e-09 | pass |
| sampleSelection two-step | selection:(Intercept) | 0.507335 | 0.507335 | 1.45e-11 | 1.45e-11 | pass |
| sampleSelection two-step | selection:x1 | 0.282123 | 0.282123 | 1.33e-11 | 1.33e-11 | pass |
| sampleSelection two-step | selection:z1 | -0.392585 | -0.392585 | -1.82e-11 | 1.82e-11 | pass |
| sampleSelection two-step | regime_0:(Intercept) | 0.911965 | 0.911965 | -1.29e-11 | 1.29e-11 | pass |
| sampleSelection two-step | regime_0:x1 | 0.511596 | 0.511596 | 1.35e-14 | 1.35e-14 | pass |
| sampleSelection two-step | regime_0:x2 |  0.2016 |  0.2016 | 5.00e-16 | 5.00e-16 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | 0.307864 | 0.307864 | -1.43e-11 | 1.43e-11 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 1.50527 | 1.50527 | 1.51e-11 | 1.51e-11 | pass |
| sampleSelection two-step | regime_1:x1 | 0.790368 | 0.790368 | -1.07e-13 | 1.07e-13 | pass |
| sampleSelection two-step | regime_1:x2 | 0.384065 | 0.384065 | -3.33e-16 | 3.33e-16 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | 0.622457 | 0.622457 | -2.27e-11 | 2.27e-11 | pass |
| sampleSelection two-step | regime_0:sigma | 0.988798 | 0.978913 | 9.89e-03 |  | documented |
| sampleSelection two-step | regime_1:sigma | 1.00948 | 0.960694 | 4.88e-02 |  | documented |
| sampleSelection two-step | regime_0:rho | 0.311352 | 0.314496 | -3.14e-03 |  | documented |
| sampleSelection two-step | regime_1:rho | 0.61661 | 0.647924 | -3.13e-02 |  | documented |
| endoSwitch FIML | log-likelihood | -19127.4 | -19127.4 | 9.92e-08 | 9.92e-08 | pass |
| endoSwitch FIML | selection:(Intercept) | 0.507192 | 0.507188 | 3.92e-06 | 3.92e-06 | pass |
| endoSwitch FIML | selection:x1 | 0.285577 | 0.285577 | -1.52e-09 | 1.52e-09 | pass |
| endoSwitch FIML | selection:z1 | -0.394614 | -0.394616 | 2.02e-06 | 2.02e-06 | pass |
| endoSwitch FIML | regime_0:(Intercept) | 0.898658 | 0.898651 | 7.23e-06 | 7.23e-06 | pass |
| endoSwitch FIML | regime_0:x1 | 0.510015 | 0.510012 | 2.42e-06 | 2.42e-06 | pass |
| endoSwitch FIML | regime_0:x2 | 0.201481 | 0.201483 | -2.50e-06 | 2.50e-06 | pass |
| endoSwitch FIML | regime_0:sigma | 0.986397 | 0.986396 | 1.70e-06 | 1.70e-06 | pass |
| endoSwitch FIML | regime_0:rho | 0.299398 | 0.299392 | 6.16e-06 | 6.16e-06 | pass |
| endoSwitch FIML | regime_1:(Intercept) | 1.52295 | 1.52296 | -3.08e-06 | 2.02e-06 | pass |
| endoSwitch FIML | regime_1:x1 | 0.785421 | 0.785421 | 3.17e-07 | 3.17e-07 | pass |
| endoSwitch FIML | regime_1:x2 | 0.383632 | 0.383633 | -2.51e-07 | 2.51e-07 | pass |
| endoSwitch FIML | regime_1:sigma | 1.00002 | 1.00002 | 5.40e-07 | 5.40e-07 | pass |
| endoSwitch FIML | regime_1:rho | 0.587428 | 0.587424 | 4.25e-06 | 4.25e-06 | pass |
| endoSwitch FIML | SE selection:(Intercept) | 0.013754 | 0.0137493 | 4.70e-06 | 3.42e-04 | pass |
| endoSwitch FIML | SE selection:x1 | 0.0138935 | 0.013898 | -4.51e-06 | 3.24e-04 | pass |
| endoSwitch FIML | SE selection:z1 | 0.0138518 | 0.0138542 | -2.40e-06 | 1.73e-04 | pass |
| endoSwitch FIML | SE regime_0:(Intercept) | 0.0686261 | 0.070722 | -2.10e-03 | 2.96e-02 | FAIL |
| endoSwitch FIML | SE regime_0:x1 | 0.0205996 | 0.0207796 | -1.80e-04 | 8.66e-03 | pass |
| endoSwitch FIML | SE regime_0:x2 | 0.0168321 | 0.0168254 | 6.68e-06 | 3.97e-04 | pass |
| endoSwitch FIML | SE regime_0:sigma | 0.0173278 | 0.0176435 | -3.16e-04 | 1.79e-02 | FAIL |
| endoSwitch FIML | SE regime_0:rho | 0.0600947 | 0.0620008 | -1.91e-03 | 3.07e-02 | FAIL |
| endoSwitch FIML | SE regime_1:(Intercept) | 0.0241413 | 0.0240947 | 4.66e-05 | 1.93e-03 | pass |
| endoSwitch FIML | SE regime_1:x1 | 0.0130396 | 0.0130206 | 1.90e-05 | 1.46e-03 | pass |
| endoSwitch FIML | SE regime_1:x2 | 0.0111634 | 0.0111611 | 2.21e-06 | 1.98e-04 | pass |
| endoSwitch FIML | SE regime_1:sigma | 0.0145595 | 0.0145289 | 3.06e-05 | 2.11e-03 | pass |
| endoSwitch FIML | SE regime_1:rho | 0.035088 | 0.0349766 | 1.11e-04 | 3.19e-03 | pass |
| endoSwitch FIML | ATT | 0.800445 |  0.8005 | -5.51e-05 | 5.51e-05 | pass |
| endoSwitch FIML | ATU | 0.250122 |  0.2501 | 2.17e-05 | 2.17e-05 | pass |
| endoSwitch FIML | TH | 0.550323 |  0.5503 | 2.33e-05 | 2.33e-05 | pass |
| endoSwitch FIML | BH1 | 1.20249 |  1.2025 | -1.21e-05 | 1.00e-05 | pass |
| endoSwitch FIML | BH0 | 0.652165 |  0.6522 | -3.54e-05 | 3.54e-05 | pass |
| endoSwitch FIML | EY1_S1 (largest unit difference) | 0.729907 | 0.72991 | -2.69e-06 | 2.69e-06 | pass |
| endoSwitch FIML | EY1_S1 formula at their estimates (largest unit difference) | 2.25626 | 2.25626 | -8.88e-16 | 3.94e-16 | pass |
| endoSwitch FIML | EY0_S1 (largest unit difference) | 0.987653 | 0.987634 | 1.94e-05 | 1.94e-05 | pass |
| endoSwitch FIML | EY0_S1 formula at their estimates (largest unit difference) | 2.20741 | 2.20741 | 8.88e-16 | 4.02e-16 | pass |
| endoSwitch FIML | EY1_S0 (largest unit difference) | 0.790954 | 0.790966 | -1.16e-05 | 1.16e-05 | pass |
| endoSwitch FIML | EY1_S0 formula at their estimates (largest unit difference) | 1.82658 | 1.82658 | -2.00e-15 | 1.09e-15 | pass |
| endoSwitch FIML | EY0_S0 (largest unit difference) | -0.0526761 | -0.0526612 | -1.49e-05 | 1.49e-05 | pass |
| endoSwitch FIML | EY0_S0 formula at their estimates (largest unit difference) |  2.1577 |  2.1577 | -1.33e-15 | 6.17e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | log-likelihood | -19127.4 | -19127.4 | 0.00e+00 | 0.00e+00 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:(Intercept) | 0.507192 | 0.507192 | -1.00e-09 | 1.00e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:x1 | 0.285577 | 0.285577 | 3.26e-10 | 3.26e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:z1 | -0.394614 | -0.394614 | 9.54e-10 | 9.54e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:(Intercept) | 0.898658 | 0.898658 | 1.01e-08 | 1.01e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:x1 | 0.510015 | 0.510015 | 2.76e-09 | 2.76e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:x2 | 0.201481 | 0.201481 | -6.00e-10 | 6.00e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:sigma | 0.986397 | 0.986397 | 1.62e-09 | 1.62e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:rho | 0.299398 | 0.299398 | 9.61e-09 | 9.61e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:(Intercept) | 1.52295 | 1.52295 | 8.31e-10 | 5.46e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:x1 | 0.785421 | 0.785421 | -3.18e-10 | 3.18e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:x2 | 0.383632 | 0.383632 | -1.07e-09 | 1.07e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:sigma | 1.00002 | 1.00002 | 4.51e-10 | 4.51e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:rho | 0.587428 | 0.587428 | -1.21e-09 | 1.21e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:(Intercept) | 0.013754 | 0.0137495 | 4.46e-06 | 3.24e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:x1 | 0.0138935 | 0.0139037 | -1.02e-05 | 7.34e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:z1 | 0.0138518 | 0.0139053 | -5.35e-05 | 3.85e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:(Intercept) | 0.0686261 | 0.071703 | -3.08e-03 | 4.29e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:x1 | 0.0205996 | 0.0210747 | -4.75e-04 | 2.25e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:x2 | 0.0168321 | 0.0168476 | -1.55e-05 | 9.18e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:sigma | 0.0173278 | 0.0177908 | -4.63e-04 | 2.60e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:rho | 0.0600947 | 0.0628033 | -2.71e-03 | 4.31e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:(Intercept) | 0.0241413 | 0.0242741 | -1.33e-04 | 5.47e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:x1 | 0.0130396 | 0.0130782 | -3.86e-05 | 2.95e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:x2 | 0.0111634 | 0.0111639 | -5.43e-07 | 4.86e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:sigma | 0.0145595 | 0.0146493 | -8.98e-05 | 6.13e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:rho | 0.035088 | 0.0353854 | -2.97e-04 | 8.40e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | ATT | 0.800445 |  0.8004 | 4.49e-05 | 4.49e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | ATU | 0.250122 |  0.2501 | 2.17e-05 | 2.17e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | TH | 0.550323 |  0.5503 | 2.33e-05 | 2.33e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | BH1 | 1.20249 |  1.2025 | -1.21e-05 | 1.00e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | BH0 | 0.652165 |  0.6522 | -3.54e-05 | 3.54e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 (largest unit difference) | -0.3366 | -0.3366 | 4.90e-09 | 4.90e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 formula at their estimates (largest unit difference) | 2.40329 | 2.40329 | -8.88e-16 | 3.70e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 (largest unit difference) | 0.634101 | 0.634101 | 2.27e-08 | 2.27e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 formula at their estimates (largest unit difference) | 2.18034 | 2.18034 | -8.88e-16 | 4.07e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 (largest unit difference) | -0.805064 | -0.805064 | 7.16e-09 | 7.16e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 formula at their estimates (largest unit difference) | 3.24877 | 3.24877 | -1.78e-15 | 5.47e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 (largest unit difference) | -0.0569832 | -0.0569832 | -9.64e-09 | 9.64e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 formula at their estimates (largest unit difference) | 2.02962 | 2.02962 | 8.88e-16 | 4.38e-16 | pass |
| endoSwitch two-stage | selection:(Intercept) | 0.507335 | 0.507335 | 1.59e-09 | 1.59e-09 | pass |
| endoSwitch two-stage | selection:x1 | 0.282123 | 0.282123 | 2.69e-09 | 2.69e-09 | pass |
| endoSwitch two-stage | selection:z1 | -0.392585 | -0.392585 | -3.20e-09 | 3.20e-09 | pass |
| endoSwitch two-stage | regime_0:(Intercept) | 0.911965 | 0.911965 | -2.38e-09 | 2.38e-09 | pass |
| endoSwitch two-stage | regime_0:x1 | 0.511596 | 0.511596 | 7.58e-11 | 7.58e-11 | pass |
| endoSwitch two-stage | regime_0:x2 |  0.2016 |  0.2016 | 1.24e-14 | 1.24e-14 | pass |
| endoSwitch two-stage | theta0 = sigma0 rho0 (minus their MillsRatioAdt0) | 0.307864 | 0.307864 | -2.41e-09 | 2.41e-09 | pass |
| endoSwitch two-stage | regime_1:(Intercept) | 1.50527 | 1.50527 | 2.49e-09 | 2.49e-09 | pass |
| endoSwitch two-stage | regime_1:x1 | 0.790368 | 0.790368 | 8.82e-11 | 8.82e-11 | pass |
| endoSwitch two-stage | regime_1:x2 | 0.384065 | 0.384065 | 4.39e-13 | 4.39e-13 | pass |
| endoSwitch two-stage | theta1 = sigma1 rho1 (their MillsRatioAdt1) | 0.622457 | 0.622457 | -4.27e-09 | 4.27e-09 | pass |
| endoSwitch two-stage | regime_0:sigma | 0.988798 | 0.976023 | 1.28e-02 |  | documented |
| endoSwitch two-stage | regime_0:rho | 0.311352 | 0.315427 | -4.08e-03 |  | documented |
| endoSwitch two-stage | regime_1:sigma | 1.00948 | 0.955086 | 5.44e-02 |  | documented |
| endoSwitch two-stage | regime_1:rho | 0.61661 | 0.651729 | -3.51e-02 |  | documented |

### D4: weak exclusion (gamma_z = -0.1), N = 2000

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -3859.83 | -3859.83 | 3.64e-12 | 3.64e-12 | pass |
| sampleSelection ML | selection:(Intercept) | 0.472666 | 0.472666 | 3.48e-09 | 3.48e-09 | pass |
| sampleSelection ML | selection:x1 | 0.37084 | 0.37084 | 8.61e-10 | 8.61e-10 | pass |
| sampleSelection ML | selection:z1 | -0.150926 | -0.150926 | 1.46e-08 | 1.46e-08 | pass |
| sampleSelection ML | regime_0:(Intercept) | -0.347252 | -0.347251 | -6.29e-07 | 6.29e-07 | pass |
| sampleSelection ML | regime_0:x1 | 0.191216 | 0.191216 | -1.38e-07 | 1.38e-07 | pass |
| sampleSelection ML | regime_0:x2 | 0.213504 | 0.213504 | -1.31e-09 | 1.31e-09 | pass |
| sampleSelection ML | regime_0:sigma | 1.10523 | 1.10523 | 2.64e-07 | 2.39e-07 | pass |
| sampleSelection ML | regime_0:rho | -0.636482 | -0.636481 | -3.43e-07 | 3.43e-07 | pass |
| sampleSelection ML | regime_1:(Intercept) | 1.57968 | 1.57968 | -9.57e-09 | 6.06e-09 | pass |
| sampleSelection ML | regime_1:x1 | 0.798518 | 0.798518 | 3.69e-09 | 3.69e-09 | pass |
| sampleSelection ML | regime_1:x2 | 0.405008 | 0.405008 | -2.19e-11 | 2.19e-11 | pass |
| sampleSelection ML | regime_1:sigma | 0.974143 | 0.974143 | 4.45e-09 | 4.45e-09 | pass |
| sampleSelection ML | regime_1:rho | 0.470142 | 0.470142 | 1.75e-08 | 1.75e-08 | pass |
| sampleSelection ML | SE selection:(Intercept) | 0.0300945 | 0.0300945 | -3.48e-11 | 1.16e-09 | pass |
| sampleSelection ML | SE selection:x1 | 0.0308694 | 0.0308694 | -2.97e-10 | 9.61e-09 | pass |
| sampleSelection ML | SE selection:z1 | 0.0289914 | 0.0289914 | -2.44e-09 | 8.42e-08 | pass |
| sampleSelection ML | SE regime_0:(Intercept) | 0.249729 | 0.249729 | -1.24e-07 | 4.97e-07 | pass |
| sampleSelection ML | SE regime_0:x1 | 0.0672661 | 0.0672661 | -2.03e-08 | 3.03e-07 | pass |
| sampleSelection ML | SE regime_0:x2 | 0.0364018 | 0.0364018 | 7.89e-10 | 2.17e-08 | pass |
| sampleSelection ML | SE regime_0:sigma | 0.102634 | 0.102634 | 1.39e-08 | 1.35e-07 | pass |
| sampleSelection ML | SE regime_0:rho | 0.142056 | 0.142056 | -1.75e-07 | 1.23e-06 | pass |
| sampleSelection ML | SE regime_1:(Intercept) | 0.10382 | 0.10382 | -4.07e-09 | 3.92e-08 | pass |
| sampleSelection ML | SE regime_1:x1 | 0.0419302 | 0.0419302 | -8.29e-10 | 1.98e-08 | pass |
| sampleSelection ML | SE regime_1:x2 | 0.0254501 | 0.0254501 | -1.76e-12 | 6.90e-11 | pass |
| sampleSelection ML | SE regime_1:sigma | 0.047527 | 0.047527 | 4.98e-11 | 1.05e-09 | pass |
| sampleSelection ML | SE regime_1:rho | 0.172069 | 0.172069 | -9.10e-09 | 5.29e-08 | pass |
| sampleSelection ML | ATT | 2.62689 | 2.62689 | 9.28e-07 | 3.53e-07 | pass |
| sampleSelection ML | ATU | 0.500242 | 0.500242 | -1.79e-08 | 1.79e-08 | pass |
| sampleSelection ML | ATE | 1.93557 | 1.93557 | 6.23e-07 | 3.22e-07 | pass |
| sampleSelection ML | TH | 2.12665 | 2.12665 | 9.46e-07 | 4.45e-07 | pass |
| sampleSelection ML | BH1 | 1.17508 | 1.17508 | 3.20e-08 | 2.72e-08 | pass |
| sampleSelection ML | BH0 | -0.951574 | -0.951573 | -9.14e-07 | 9.14e-07 | pass |
| sampleSelection ML | EY1_S1 (largest unit difference) | 0.689277 | 0.689277 | -9.18e-09 | 9.18e-09 | pass |
| sampleSelection ML | EY1_S0 (largest unit difference) | 0.748865 | 0.748865 | -3.81e-08 | 3.81e-08 | pass |
| sampleSelection ML | EY0_S1 (largest unit difference) | 0.346713 | 0.346714 | -1.22e-06 | 1.22e-06 | pass |
| sampleSelection ML | EY0_S0 (largest unit difference) | 0.872578 | 0.872579 | -1.99e-07 | 1.99e-07 | pass |
| sampleSelection two-step | selection:(Intercept) | 0.472709 | 0.472709 | 8.15e-13 | 8.15e-13 | pass |
| sampleSelection two-step | selection:x1 | 0.367849 | 0.367849 | 1.21e-12 | 1.21e-12 | pass |
| sampleSelection two-step | selection:z1 | -0.15614 | -0.15614 | -5.75e-13 | 5.75e-13 | pass |
| sampleSelection two-step | regime_0:(Intercept) | -0.0421697 | -0.0421697 | 1.90e-12 | 1.90e-12 | pass |
| sampleSelection two-step | regime_0:x1 | 0.259173 | 0.259173 | 1.27e-13 | 1.27e-13 | pass |
| sampleSelection two-step | regime_0:x2 | 0.214508 | 0.214508 | 1.61e-15 | 1.61e-15 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | -0.431093 | -0.431093 | 1.94e-12 | 1.94e-12 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 1.64731 | 1.64731 | 6.14e-13 | 6.14e-13 | pass |
| sampleSelection two-step | regime_1:x1 | 0.776661 | 0.776661 | -1.81e-14 | 1.81e-14 | pass |
| sampleSelection two-step | regime_1:x2 | 0.404901 | 0.404901 | -6.11e-16 | 6.11e-16 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | 0.331202 | 0.331202 | -9.49e-13 | 9.49e-13 | pass |
| sampleSelection two-step | regime_0:sigma | 1.00475 | 0.987674 | 1.71e-02 |  | documented |
| sampleSelection two-step | regime_1:sigma | 0.948907 | 0.935696 | 1.32e-02 |  | documented |
| sampleSelection two-step | regime_0:rho | -0.429057 | -0.436473 | 7.42e-03 |  | documented |
| sampleSelection two-step | regime_1:rho | 0.349035 | 0.353963 | -4.93e-03 |  | documented |
| endoSwitch FIML | log-likelihood | -3859.83 | -3859.83 | 2.83e-08 | 2.83e-08 | pass |
| endoSwitch FIML | selection:(Intercept) | 0.472666 | 0.472668 | -1.76e-06 | 1.76e-06 | pass |
| endoSwitch FIML | selection:x1 | 0.37084 | 0.37084 | 2.58e-07 | 2.58e-07 | pass |
| endoSwitch FIML | selection:z1 | -0.150926 | -0.150924 | -1.93e-06 | 1.93e-06 | pass |
| endoSwitch FIML | regime_0:(Intercept) | -0.347252 | -0.347242 | -1.02e-05 | 1.02e-05 | pass |
| endoSwitch FIML | regime_0:x1 | 0.191216 | 0.191218 | -2.34e-06 | 2.34e-06 | pass |
| endoSwitch FIML | regime_0:x2 | 0.213504 | 0.213505 | -1.37e-06 | 1.37e-06 | pass |
| endoSwitch FIML | regime_0:sigma | 1.10523 | 1.10522 | 5.47e-06 | 4.95e-06 | pass |
| endoSwitch FIML | regime_0:rho | -0.636482 | -0.636477 | -5.04e-06 | 5.04e-06 | pass |
| endoSwitch FIML | regime_1:(Intercept) | 1.57968 | 1.57966 | 2.03e-05 | 1.29e-05 | pass |
| endoSwitch FIML | regime_1:x1 | 0.798518 | 0.798525 | -6.82e-06 | 6.82e-06 | pass |
| endoSwitch FIML | regime_1:x2 | 0.405008 | 0.405008 | -6.65e-07 | 6.65e-07 | pass |
| endoSwitch FIML | regime_1:sigma | 0.974143 | 0.974152 | -9.48e-06 | 9.48e-06 | pass |
| endoSwitch FIML | regime_1:rho | 0.470142 | 0.470177 | -3.50e-05 | 3.50e-05 | pass |
| endoSwitch FIML | SE selection:(Intercept) | 0.0300945 | 0.030088 | 6.52e-06 | 2.17e-04 | pass |
| endoSwitch FIML | SE selection:x1 | 0.0308694 | 0.0308589 | 1.05e-05 | 3.39e-04 | pass |
| endoSwitch FIML | SE selection:z1 | 0.0289914 | 0.0289955 | -4.10e-06 | 1.41e-04 | pass |
| endoSwitch FIML | SE regime_0:(Intercept) | 0.249729 | 0.256217 | -6.49e-03 | 2.53e-02 | FAIL |
| endoSwitch FIML | SE regime_0:x1 | 0.0672661 | 0.0685655 | -1.30e-03 | 1.90e-02 | FAIL |
| endoSwitch FIML | SE regime_0:x2 | 0.0364018 | 0.0363843 | 1.75e-05 | 4.82e-04 | pass |
| endoSwitch FIML | SE regime_0:sigma | 0.102634 | 0.105141 | -2.51e-03 | 2.38e-02 | FAIL |
| endoSwitch FIML | SE regime_0:rho | 0.142056 | 0.145766 | -3.71e-03 | 2.55e-02 | FAIL |
| endoSwitch FIML | SE regime_1:(Intercept) | 0.10382 | 0.103778 | 4.23e-05 | 4.08e-04 | pass |
| endoSwitch FIML | SE regime_1:x1 | 0.0419302 | 0.0418921 | 3.81e-05 | 9.09e-04 | pass |
| endoSwitch FIML | SE regime_1:x2 | 0.0254501 | 0.0254521 | -1.95e-06 | 7.66e-05 | pass |
| endoSwitch FIML | SE regime_1:sigma | 0.047527 | 0.0474894 | 3.76e-05 | 7.92e-04 | pass |
| endoSwitch FIML | SE regime_1:rho | 0.172069 | 0.171922 | 1.47e-04 | 8.56e-04 | pass |
| endoSwitch FIML | ATT | 2.62689 |  2.6269 | -7.77e-06 | 2.96e-06 | pass |
| endoSwitch FIML | ATU | 0.500242 |  0.5002 | 4.25e-05 | 4.25e-05 | pass |
| endoSwitch FIML | TH | 2.12665 |  2.1267 | -5.02e-05 | 2.36e-05 | pass |
| endoSwitch FIML | BH1 | 1.17508 |  1.1751 | -2.46e-05 | 2.09e-05 | pass |
| endoSwitch FIML | BH0 | -0.951574 | -0.9516 | 2.56e-05 | 2.56e-05 | pass |
| endoSwitch FIML | EY1_S1 (largest unit difference) | 0.689277 | 0.689287 | -1.00e-05 | 1.00e-05 | pass |
| endoSwitch FIML | EY1_S1 formula at their estimates (largest unit difference) | 3.82146 | 3.82146 | 8.88e-16 | 2.32e-16 | pass |
| endoSwitch FIML | EY0_S1 (largest unit difference) | -0.381909 | -0.381887 | -2.18e-05 | 2.18e-05 | pass |
| endoSwitch FIML | EY0_S1 formula at their estimates (largest unit difference) | -1.64218 | -1.64218 | 4.44e-16 | 2.70e-16 | pass |
| endoSwitch FIML | EY1_S0 (largest unit difference) | 0.755581 | 0.755507 | 7.43e-05 | 7.43e-05 | pass |
| endoSwitch FIML | EY1_S0 formula at their estimates (largest unit difference) | 1.91029 | 1.91029 | 1.11e-15 | 5.81e-16 | pass |
| endoSwitch FIML | EY0_S0 (largest unit difference) | 0.580049 | 0.580057 | -7.73e-06 | 7.73e-06 | pass |
| endoSwitch FIML | EY0_S0 formula at their estimates (largest unit difference) | 0.951415 | 0.951415 | -8.88e-16 | 8.88e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | log-likelihood | -3859.83 | -3859.83 | 0.00e+00 | 0.00e+00 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:(Intercept) | 0.472666 | 0.472666 | 7.25e-09 | 7.25e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:x1 | 0.37084 | 0.37084 | 8.64e-10 | 8.64e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:z1 | -0.150926 | -0.150926 | -1.56e-09 | 1.56e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:(Intercept) | -0.347252 | -0.347252 | 1.62e-08 | 1.62e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:x1 | 0.191216 | 0.191216 | 5.96e-09 | 5.96e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:x2 | 0.213504 | 0.213504 | 3.39e-09 | 3.39e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:sigma | 1.10523 | 1.10523 | -9.24e-09 | 8.36e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:rho | -0.636482 | -0.636482 | 1.57e-08 | 1.57e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:(Intercept) | 1.57968 | 1.57968 | 9.01e-09 | 5.70e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:x1 | 0.798518 | 0.798518 | -4.47e-09 | 4.47e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:x2 | 0.405008 | 0.405008 | 1.05e-09 | 1.05e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:sigma | 0.974143 | 0.974143 | -5.75e-10 | 5.75e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:rho | 0.470142 | 0.470142 | -1.32e-08 | 1.32e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:(Intercept) | 0.0300945 | 0.0300968 | -2.31e-06 | 7.67e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:x1 | 0.0308694 | 0.0308753 | -5.87e-06 | 1.90e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:z1 | 0.0289914 | 0.0289699 | 2.14e-05 | 7.40e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:(Intercept) | 0.249729 | 0.241484 | 8.24e-03 | 3.41e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:x1 | 0.0672661 | 0.0660315 | 1.23e-03 | 1.87e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:x2 | 0.0364018 | 0.0364109 | -9.12e-06 | 2.50e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:sigma | 0.102634 | 0.0993718 | 3.26e-03 | 3.28e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:rho | 0.142056 | 0.137402 | 4.65e-03 | 3.39e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:(Intercept) | 0.10382 | 0.105342 | -1.52e-03 | 1.44e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:x1 | 0.0419302 | 0.0424079 | -4.78e-04 | 1.13e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:x2 | 0.0254501 | 0.0254583 | -8.16e-06 | 3.21e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:sigma | 0.047527 | 0.0481828 | -6.56e-04 | 1.36e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:rho | 0.172069 | 0.174703 | -2.63e-03 | 1.51e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | ATT | 2.62689 |  2.6269 | -7.77e-06 | 2.96e-06 | pass |
| endoSwitch FIML (reltol 1e-14) | ATU | 0.500242 |  0.5002 | 4.25e-05 | 4.25e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | TH | 2.12665 |  2.1266 | 4.98e-05 | 2.34e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | BH1 | 1.17508 |  1.1751 | -2.46e-05 | 2.09e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | BH0 | -0.951574 | -0.9516 | 2.56e-05 | 2.56e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 (largest unit difference) | 0.885759 | 0.885759 | 6.10e-09 | 6.10e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 formula at their estimates (largest unit difference) | 2.95652 | 2.95652 | -8.88e-16 | 3.00e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 (largest unit difference) | 0.462444 | 0.462444 | 4.44e-08 | 4.44e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 formula at their estimates (largest unit difference) | -1.49467 | -1.49467 | 4.44e-16 | 2.97e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 (largest unit difference) | 0.164536 | 0.164536 | 2.87e-08 | 2.87e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 formula at their estimates (largest unit difference) | 2.13498 | 2.13498 | -8.88e-16 | 4.16e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 (largest unit difference) | -0.772509 | -0.772509 | -1.93e-08 | 1.93e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 formula at their estimates (largest unit difference) | 1.05189 | 1.05189 | 1.33e-15 | 1.27e-15 | pass |
| endoSwitch two-stage | selection:(Intercept) | 0.472709 | 0.472709 | -2.08e-09 | 2.08e-09 | pass |
| endoSwitch two-stage | selection:x1 | 0.367849 | 0.367849 | 6.67e-09 | 6.67e-09 | pass |
| endoSwitch two-stage | selection:z1 | -0.15614 | -0.15614 | 1.63e-09 | 1.63e-09 | pass |
| endoSwitch two-stage | regime_0:(Intercept) | -0.0421697 | -0.0421697 | 2.14e-09 | 2.14e-09 | pass |
| endoSwitch two-stage | regime_0:x1 | 0.259173 | 0.259173 | -1.51e-09 | 1.51e-09 | pass |
| endoSwitch two-stage | regime_0:x2 | 0.214508 | 0.214508 | 3.92e-11 | 3.92e-11 | pass |
| endoSwitch two-stage | theta0 = sigma0 rho0 (minus their MillsRatioAdt0) | -0.431093 | -0.431093 | 1.51e-09 | 1.51e-09 | pass |
| endoSwitch two-stage | regime_1:(Intercept) | 1.64731 | 1.64731 | -2.49e-09 | 2.49e-09 | pass |
| endoSwitch two-stage | regime_1:x1 | 0.776661 | 0.776661 | 1.73e-09 | 1.73e-09 | pass |
| endoSwitch two-stage | regime_1:x2 | 0.404901 | 0.404901 | -7.45e-12 | 7.45e-12 | pass |
| endoSwitch two-stage | theta1 = sigma1 rho1 (their MillsRatioAdt1) | 0.331202 | 0.331202 | 3.65e-09 | 3.65e-09 | pass |
| endoSwitch two-stage | regime_0:sigma | 1.00475 | 0.980613 | 2.41e-02 |  | documented |
| endoSwitch two-stage | regime_0:rho | -0.429057 | -0.439616 | 1.06e-02 |  | documented |
| endoSwitch two-stage | regime_1:sigma | 0.948907 | 0.932541 | 1.64e-02 |  | documented |
| endoSwitch two-stage | regime_1:rho | 0.349035 | 0.355161 | -6.13e-03 |  | documented |

### D5: different regressors per regime (verify_math.R design), N = 3000

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -5835.69 | -5835.69 | 9.09e-13 | 9.09e-13 | pass |
| sampleSelection ML | selection:(Intercept) | 0.478278 | 0.478278 | 1.44e-09 | 1.44e-09 | pass |
| sampleSelection ML | selection:x1 | 0.302416 | 0.302416 | 1.04e-09 | 1.04e-09 | pass |
| sampleSelection ML | selection:z1 | -0.4202 | -0.4202 | -5.50e-09 | 5.50e-09 | pass |
| sampleSelection ML | regime_0:(Intercept) | 0.754801 | 0.754801 | -8.07e-10 | 8.07e-10 | pass |
| sampleSelection ML | regime_0:x1 | 0.479261 | 0.479261 | -1.22e-10 | 1.22e-10 | pass |
| sampleSelection ML | regime_0:sigma | 0.742513 | 0.742513 | -5.19e-11 | 5.19e-11 | pass |
| sampleSelection ML | regime_0:rho | 0.0964652 | 0.0964652 | -1.04e-09 | 1.04e-09 | pass |
| sampleSelection ML | regime_1:(Intercept) | 1.47218 | 1.47218 | 4.59e-08 | 3.11e-08 | pass |
| sampleSelection ML | regime_1:x1 | 0.816844 | 0.816844 | -1.17e-08 | 1.17e-08 | pass |
| sampleSelection ML | regime_1:x2 | 0.371975 | 0.371975 | -7.77e-10 | 7.77e-10 | pass |
| sampleSelection ML | regime_1:sigma | 1.21957 | 1.21957 | -2.33e-08 | 1.91e-08 | pass |
| sampleSelection ML | regime_1:rho | 0.649305 | 0.649305 | -6.45e-08 | 6.45e-08 | pass |
| sampleSelection ML | SE selection:(Intercept) | 0.025137 | 0.025137 | 2.95e-11 | 1.17e-09 | pass |
| sampleSelection ML | SE selection:x1 | 0.0260603 | 0.0260603 | 1.61e-10 | 6.18e-09 | pass |
| sampleSelection ML | SE selection:z1 | 0.0249773 | 0.0249773 | 4.95e-10 | 1.98e-08 | pass |
| sampleSelection ML | SE regime_0:(Intercept) | 0.093349 | 0.093349 | -1.16e-09 | 1.24e-08 | pass |
| sampleSelection ML | SE regime_0:x1 | 0.0288847 | 0.0288847 | -9.24e-11 | 3.20e-09 | pass |
| sampleSelection ML | SE regime_0:sigma | 0.0173869 | 0.0173869 | -4.56e-11 | 2.62e-09 | pass |
| sampleSelection ML | SE regime_0:rho | 0.120105 | 0.120105 | -1.52e-09 | 1.27e-08 | pass |
| sampleSelection ML | SE regime_1:(Intercept) | 0.05619 | 0.05619 | 8.07e-09 | 1.44e-07 | pass |
| sampleSelection ML | SE regime_1:x1 | 0.0295681 | 0.0295681 | 7.51e-10 | 2.54e-08 | pass |
| sampleSelection ML | SE regime_1:x2 | 0.0486843 | 0.0486843 | 4.53e-10 | 9.31e-09 | pass |
| sampleSelection ML | SE regime_1:sigma | 0.0319001 | 0.0319001 | 2.58e-09 | 8.10e-08 | pass |
| sampleSelection ML | SE regime_1:rho | 0.053112 | 0.0531119 | 1.84e-08 | 3.47e-07 | pass |
| sampleSelection ML | ATT | 1.30745 | 1.30745 | -1.35e-09 | 1.03e-09 | pass |
| sampleSelection ML | ATU | 0.119379 | 0.119379 | 1.39e-07 | 1.39e-07 | pass |
| sampleSelection ML | ATE | 0.906061 | 0.906061 | 4.63e-08 | 4.63e-08 | pass |
| sampleSelection ML | TH | 1.18807 | 1.18807 | -1.40e-07 | 1.18e-07 | pass |
| sampleSelection ML | BH1 | 1.47795 | 1.47795 | -1.42e-07 | 9.58e-08 | pass |
| sampleSelection ML | BH0 | 0.289885 | 0.289885 | -1.25e-09 | 1.25e-09 | pass |
| sampleSelection ML | EY1_S1 (largest unit difference) | 0.928783 | 0.928783 | -5.59e-08 | 5.59e-08 | pass |
| sampleSelection ML | EY1_S0 (largest unit difference) | 0.937519 | 0.937519 | 2.59e-07 | 2.59e-07 | pass |
| sampleSelection ML | EY0_S1 (largest unit difference) | 0.997829 | 0.997829 | -1.28e-09 | 1.28e-09 | pass |
| sampleSelection ML | EY0_S0 (largest unit difference) | 0.561132 | 0.561132 | -3.04e-10 | 3.04e-10 | pass |
| sampleSelection two-step | selection:(Intercept) | 0.480485 | 0.480485 | 4.21e-11 | 4.21e-11 | pass |
| sampleSelection two-step | selection:x1 | 0.305306 | 0.305306 | 3.92e-11 | 3.92e-11 | pass |
| sampleSelection two-step | selection:z1 | -0.422832 | -0.422832 | -5.47e-11 | 5.47e-11 | pass |
| sampleSelection two-step | regime_0:(Intercept) | 0.750549 | 0.750549 | -6.38e-12 | 6.38e-12 | pass |
| sampleSelection two-step | regime_0:x1 | 0.478673 | 0.478673 | 1.90e-13 | 1.90e-13 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | 0.0673375 | 0.0673375 | -7.44e-12 | 7.44e-12 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 1.46324 | 1.46324 | 5.90e-11 | 5.90e-11 | pass |
| sampleSelection two-step | regime_1:x1 | 0.818246 | 0.818246 | -1.76e-12 | 1.76e-12 | pass |
| sampleSelection two-step | regime_1:x2 | 0.37398 | 0.37398 | -1.27e-13 | 1.27e-13 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | 0.807271 | 0.807271 | -8.76e-11 | 8.76e-11 | pass |
| sampleSelection two-step | regime_0:sigma | 0.742269 | 0.742691 | -4.22e-04 |  | documented |
| sampleSelection two-step | regime_1:sigma | 1.22429 | 1.15702 | 6.73e-02 |  | documented |
| sampleSelection two-step | regime_0:rho | 0.0907185 | 0.090667 | 5.15e-05 |  | documented |
| sampleSelection two-step | regime_1:rho | 0.659377 | 0.697715 | -3.83e-02 |  | documented |

### D6a: sampleSelection vignette, Tobit-5, correct specification (seed 0, N = 500)

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -895.82 | -895.82 | 0.00e+00 | 0.00e+00 | pass |
| sampleSelection ML | selection:(Intercept) | -0.154975 | -0.154975 | -2.05e-10 | 2.05e-10 | pass |
| sampleSelection ML | selection:xs |  1.1408 |  1.1408 | 4.14e-10 | 3.63e-10 | pass |
| sampleSelection ML | regime_0:(Intercept) | 0.0270773 | 0.0270773 | -7.50e-10 | 7.50e-10 | pass |
| sampleSelection ML | regime_0:xo1 | 0.839587 | 0.839587 | 6.11e-11 | 6.11e-11 | pass |
| sampleSelection ML | regime_0:sigma | 0.931911 | 0.931911 | -4.26e-10 | 4.26e-10 | pass |
| sampleSelection ML | regime_0:rho | 0.88988 | 0.88988 | -3.74e-10 | 3.74e-10 | pass |
| sampleSelection ML | regime_1:(Intercept) | 0.158273 | 0.158273 | 4.27e-11 | 4.27e-11 | pass |
| sampleSelection ML | regime_1:xo2 | 0.837529 | 0.837529 | -3.27e-13 | 3.27e-13 | pass |
| sampleSelection ML | regime_1:sigma | 0.90697 | 0.90697 | -7.00e-12 | 7.00e-12 | pass |
| sampleSelection ML | regime_1:rho | 0.176954 | 0.176954 | -8.59e-11 | 8.59e-11 | pass |
| sampleSelection ML | SE selection:(Intercept) | 0.105105 | 0.105105 | 5.87e-11 | 5.58e-10 | pass |
| sampleSelection ML | SE selection:xs | 0.178518 | 0.178518 | 1.52e-10 | 8.51e-10 | pass |
| sampleSelection ML | SE regime_0:(Intercept) | 0.163952 | 0.163952 | 3.94e-10 | 2.40e-09 | pass |
| sampleSelection ML | SE regime_0:xo1 | 0.149676 | 0.149676 | 5.20e-11 | 3.48e-10 | pass |
| sampleSelection ML | SE regime_0:sigma | 0.0921072 | 0.0921072 | 1.90e-10 | 2.07e-09 | pass |
| sampleSelection ML | SE regime_0:rho | 0.0535321 | 0.0535321 | 3.34e-10 | 6.23e-09 | pass |
| sampleSelection ML | SE regime_1:(Intercept) | 0.188454 | 0.188454 | -4.92e-11 | 2.61e-10 | pass |
| sampleSelection ML | SE regime_1:xo2 | 0.170658 | 0.170658 | 1.16e-13 | 6.81e-13 | pass |
| sampleSelection ML | SE regime_1:sigma | 0.0443404 | 0.0443404 | -1.43e-11 | 3.22e-10 | pass |
| sampleSelection ML | SE regime_1:rho | 0.331389 | 0.331389 | -1.06e-10 | 3.20e-10 | pass |
| sampleSelection ML | ATT | -0.204142 | -0.204142 | 1.11e-09 | 1.11e-09 | pass |
| sampleSelection ML | ATU | 0.779819 | 0.779819 | 9.53e-11 | 9.53e-11 | pass |
| sampleSelection ML | ATE | 0.134173 | 0.134173 | 7.63e-10 | 7.63e-10 | pass |
| sampleSelection ML | TH | -0.983961 | -0.983961 | 1.01e-09 | 1.01e-09 | pass |
| sampleSelection ML | BH1 | 0.278259 | 0.278259 | -1.26e-10 | 1.26e-10 | pass |
| sampleSelection ML | BH0 | 1.26222 | 1.26222 | -1.14e-09 | 9.02e-10 | pass |
| sampleSelection ML | EY1_S1 (largest unit difference) | 0.323427 | 0.323427 | 6.88e-12 | 6.88e-12 | pass |
| sampleSelection ML | EY1_S0 (largest unit difference) | 0.0336518 | 0.0336518 | 1.36e-10 | 1.36e-10 | pass |
| sampleSelection ML | EY0_S1 (largest unit difference) | 0.783841 | 0.783841 | -1.28e-09 | 1.28e-09 | pass |
| sampleSelection ML | EY0_S0 (largest unit difference) | -0.375733 | -0.375733 | 2.66e-10 | 2.66e-10 | pass |
| sampleSelection two-step | selection:(Intercept) | -0.158753 | -0.158753 | -1.92e-15 | 1.92e-15 | pass |
| sampleSelection two-step | selection:xs | 1.14778 | 1.14778 | 7.99e-15 | 7.99e-15 | pass |
| sampleSelection two-step | regime_0:(Intercept) | 0.128854 | 0.128854 | -5.44e-15 | 5.44e-15 | pass |
| sampleSelection two-step | regime_0:xo1 | 0.843038 | 0.843038 | 0.00e+00 | 0.00e+00 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | 0.931773 | 0.931773 | -6.00e-15 | 6.00e-15 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 0.173059 | 0.173059 | 6.94e-16 | 6.94e-16 | pass |
| sampleSelection two-step | regime_1:xo2 | 0.837403 | 0.837403 | 0.00e+00 | 0.00e+00 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | 0.132607 | 0.132607 | -9.71e-16 | 9.71e-16 | pass |
| sampleSelection two-step | regime_0:sigma | 0.991641 | 0.897002 | 9.46e-02 |  | documented |
| sampleSelection two-step | regime_1:sigma |  0.9048 |  0.9065 | -1.70e-03 |  | documented |
| sampleSelection two-step | regime_0:rho | 0.939628 |    0.99 | -5.04e-02 |  | documented |
| sampleSelection two-step | regime_1:rho | 0.14656 | 0.146285 | 2.75e-04 |  | documented |

### D6b: sampleSelection vignette, Tobit-5, non-normal errors (seed 5, N = 1000, iterlim = 20)

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -1428.77 | -1665.94 | 2.37e+02 | 2.37e+02 | FAIL |
| sampleSelection ML | selection:(Intercept) | -0.378344 | -0.536975 | 1.59e-01 | 1.59e-01 | FAIL |
| sampleSelection ML | selection:xs | -0.000345487 | 0.312683 | -3.13e-01 | 3.13e-01 | FAIL |
| sampleSelection ML | regime_0:(Intercept) | -0.734828 | -0.706792 | -2.80e-02 | 2.80e-02 | FAIL |
| sampleSelection ML | regime_0:xo1 | 1.00052 | 0.916029 | 8.45e-02 | 8.45e-02 | FAIL |
| sampleSelection ML | regime_0:sigma | 0.701835 | 0.677701 | 2.41e-02 | 2.41e-02 | FAIL |
| sampleSelection ML | regime_0:rho |      -1 | -0.971365 | -2.86e-02 | 2.86e-02 | FAIL |
| sampleSelection ML | regime_1:(Intercept) | -2.20897 | 0.144572 | -2.35e+00 | 2.35e+00 | FAIL |
| sampleSelection ML | regime_1:xo2 | 1.00134 | 1.11962 | -1.18e-01 | 1.06e-01 | FAIL |
| sampleSelection ML | regime_1:sigma | 3.19684 | 2.31432 | 8.83e-01 | 3.81e-01 | FAIL |
| sampleSelection ML | regime_1:rho |       1 | 0.170386 | 8.30e-01 | 8.30e-01 | FAIL |
| sampleSelection ML | SE selection:(Intercept) | 0.0351033 | 0.0580821 | -2.30e-02 | 3.96e-01 | FAIL |
| sampleSelection ML | SE selection:xs | 1.71806e-05 | 0.0939452 | -9.39e-02 | 1.00e+00 | FAIL |
| sampleSelection ML | SE regime_0:(Intercept) | 0.022801 | 0.0357325 | -1.29e-02 | 3.62e-01 | FAIL |
| sampleSelection ML | SE regime_0:xo1 | 8.4507e-06 | 0.0562603 | -5.63e-02 | 1.00e+00 | FAIL |
| sampleSelection ML | SE regime_0:sigma | 0.0184666 | 0.017602 | 8.65e-04 | 4.91e-02 | FAIL |
| sampleSelection ML | SE regime_0:rho | 2.67811e-16 |  |  |  | FAIL |
| sampleSelection ML | SE regime_1:(Intercept) | 0.137797 |  |  |  | FAIL |
| sampleSelection ML | SE regime_1:xo2 | 6.52868e-06 | 0.501385 | -5.01e-01 | 1.00e+00 | FAIL |
| sampleSelection ML | SE regime_1:sigma | 0.15754 | 0.0761466 | 8.14e-02 | 1.07e+00 | FAIL |
| sampleSelection ML | SE regime_1:rho | 2.23517e-16 |  |  |  | FAIL |
| sampleSelection ML | ATT | 2.66576 | 2.33755 | 3.28e-01 | 1.40e-01 | FAIL |
| sampleSelection ML | ATU | -3.70767 | 0.519653 | -4.23e+00 | 4.23e+00 | FAIL |
| sampleSelection ML | ATE | -1.46351 | 0.963689 | -2.43e+00 | 2.43e+00 | FAIL |
| sampleSelection ML | TH | 6.37343 |  1.8179 | 4.56e+00 | 2.51e+00 | FAIL |
| sampleSelection ML | BH1 | 5.23961 | 0.710698 | 4.53e+00 | 4.53e+00 | FAIL |
| sampleSelection ML | BH0 | -1.13383 | -1.1072 | -2.66e-02 | 2.40e-02 | FAIL |
| sampleSelection ML | EY1_S1 (largest unit difference) | 1.15986 | 0.608286 | 5.52e-01 | 5.52e-01 | FAIL |
| sampleSelection ML | EY1_S0 (largest unit difference) | -3.17826 | 0.974023 | -4.15e+00 | 4.15e+00 | FAIL |
| sampleSelection ML | EY0_S1 (largest unit difference) | -0.489103 | -0.728164 | 2.39e-01 | 2.39e-01 | FAIL |
| sampleSelection ML | EY0_S0 (largest unit difference) | 0.65272 | 0.424411 | 2.28e-01 | 2.28e-01 | FAIL |
| sampleSelection ML (default iterations) | log-likelihood | -1428.77 | -1665.94 | 2.37e+02 | 2.37e+02 | FAIL |
| sampleSelection ML (default iterations) | selection:(Intercept) | -0.378344 | -0.536975 | 1.59e-01 | 1.59e-01 | FAIL |
| sampleSelection ML (default iterations) | selection:xs | -0.000345487 | 0.312683 | -3.13e-01 | 3.13e-01 | FAIL |
| sampleSelection ML (default iterations) | regime_0:(Intercept) | -0.734828 | -0.706792 | -2.80e-02 | 2.80e-02 | FAIL |
| sampleSelection ML (default iterations) | regime_0:xo1 | 1.00052 | 0.916029 | 8.45e-02 | 8.45e-02 | FAIL |
| sampleSelection ML (default iterations) | regime_0:sigma | 0.701835 | 0.677701 | 2.41e-02 | 2.41e-02 | FAIL |
| sampleSelection ML (default iterations) | regime_0:rho |      -1 | -0.971365 | -2.86e-02 | 2.86e-02 | FAIL |
| sampleSelection ML (default iterations) | regime_1:(Intercept) | -2.20897 | 0.144572 | -2.35e+00 | 2.35e+00 | FAIL |
| sampleSelection ML (default iterations) | regime_1:xo2 | 1.00134 | 1.11962 | -1.18e-01 | 1.06e-01 | FAIL |
| sampleSelection ML (default iterations) | regime_1:sigma | 3.19684 | 2.31432 | 8.83e-01 | 3.81e-01 | FAIL |
| sampleSelection ML (default iterations) | regime_1:rho |       1 | 0.170386 | 8.30e-01 | 8.30e-01 | FAIL |
| sampleSelection ML (default iterations) | SE selection:(Intercept) | 0.0351033 | 0.0580821 | -2.30e-02 | 3.96e-01 | FAIL |
| sampleSelection ML (default iterations) | SE selection:xs | 1.71806e-05 | 0.0939452 | -9.39e-02 | 1.00e+00 | FAIL |
| sampleSelection ML (default iterations) | SE regime_0:(Intercept) | 0.022801 | 0.0357325 | -1.29e-02 | 3.62e-01 | FAIL |
| sampleSelection ML (default iterations) | SE regime_0:xo1 | 8.4507e-06 | 0.0562603 | -5.63e-02 | 1.00e+00 | FAIL |
| sampleSelection ML (default iterations) | SE regime_0:sigma | 0.0184666 | 0.017602 | 8.65e-04 | 4.91e-02 | FAIL |
| sampleSelection ML (default iterations) | SE regime_0:rho | 2.67811e-16 |  |  |  | FAIL |
| sampleSelection ML (default iterations) | SE regime_1:(Intercept) | 0.137797 |  |  |  | FAIL |
| sampleSelection ML (default iterations) | SE regime_1:xo2 | 6.52868e-06 | 0.501385 | -5.01e-01 | 1.00e+00 | FAIL |
| sampleSelection ML (default iterations) | SE regime_1:sigma | 0.15754 | 0.0761466 | 8.14e-02 | 1.07e+00 | FAIL |
| sampleSelection ML (default iterations) | SE regime_1:rho | 2.23517e-16 |  |  |  | FAIL |
| sampleSelection ML (default iterations) | ATT | 2.66576 | 2.33755 | 3.28e-01 | 1.40e-01 | FAIL |
| sampleSelection ML (default iterations) | ATU | -3.70767 | 0.519653 | -4.23e+00 | 4.23e+00 | FAIL |
| sampleSelection ML (default iterations) | ATE | -1.46351 | 0.963689 | -2.43e+00 | 2.43e+00 | FAIL |
| sampleSelection ML (default iterations) | TH | 6.37343 |  1.8179 | 4.56e+00 | 2.51e+00 | FAIL |
| sampleSelection ML (default iterations) | BH1 | 5.23961 | 0.710698 | 4.53e+00 | 4.53e+00 | FAIL |
| sampleSelection ML (default iterations) | BH0 | -1.13383 | -1.1072 | -2.66e-02 | 2.40e-02 | FAIL |
| sampleSelection ML (default iterations) | EY1_S1 (largest unit difference) | 1.15986 | 0.608286 | 5.52e-01 | 5.52e-01 | FAIL |
| sampleSelection ML (default iterations) | EY1_S0 (largest unit difference) | -3.17826 | 0.974023 | -4.15e+00 | 4.15e+00 | FAIL |
| sampleSelection ML (default iterations) | EY0_S1 (largest unit difference) | -0.489103 | -0.728164 | 2.39e-01 | 2.39e-01 | FAIL |
| sampleSelection ML (default iterations) | EY0_S0 (largest unit difference) | 0.65272 | 0.424411 | 2.28e-01 | 2.28e-01 | FAIL |
| sampleSelection two-step | selection:(Intercept) | -0.545095 | -0.545095 | 5.88e-15 | 5.88e-15 | pass |
| sampleSelection two-step | selection:xs | 0.324414 | 0.324414 | 2.70e-14 | 2.70e-14 | pass |
| sampleSelection two-step | regime_0:(Intercept) | -0.569474 | -0.569474 | 6.55e-15 | 6.55e-15 | pass |
| sampleSelection two-step | regime_0:xo1 | 0.949384 | 0.949384 | 0.00e+00 | 0.00e+00 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | -0.153783 | -0.153783 | 1.47e-14 | 1.47e-14 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 0.144481 | 0.144481 | 8.68e-14 | 8.68e-14 | pass |
| sampleSelection two-step | regime_1:xo2 | 1.11957 | 1.11957 | -2.22e-16 | 2.22e-16 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | 0.393679 | 0.393679 | -6.87e-14 | 6.87e-14 | pass |
| sampleSelection two-step | regime_0:sigma | 0.638859 | 0.635494 | 3.36e-03 |  | documented |
| sampleSelection two-step | regime_1:sigma | 2.30615 | 2.31431 | -8.15e-03 |  | documented |
| sampleSelection two-step | regime_0:rho | -0.240715 | -0.241989 | 1.27e-03 |  | documented |
| sampleSelection two-step | regime_1:rho | 0.170708 | 0.170107 | 6.01e-04 |  | documented |

### D6c: sampleSelection vignette, Tobit-5, no exclusion restriction (seed 6, N = 1000, iterlim = 20)

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -1936.43 | -1936.43 | 2.73e-11 | 2.73e-11 | pass |
| sampleSelection ML | selection:(Intercept) | -0.352828 | -0.352828 | -2.60e-09 | 2.60e-09 | pass |
| sampleSelection ML | selection:xs | 0.835381 | 0.835381 | -1.94e-08 | 1.94e-08 | pass |
| sampleSelection ML | regime_0:(Intercept) | -0.554476 | -0.554476 | -1.47e-09 | 1.47e-09 | pass |
| sampleSelection ML | regime_0:xs | 0.81764 | 0.81764 | -1.81e-09 | 1.81e-09 | pass |
| sampleSelection ML | regime_0:sigma | 0.591869 | 0.591869 | -1.55e-10 | 1.55e-10 | pass |
| sampleSelection ML | regime_0:rho | 0.155683 | 0.155683 | -3.37e-09 | 3.37e-09 | pass |
| sampleSelection ML | regime_1:(Intercept) | 0.645712 | 0.645715 | -3.34e-06 | 3.34e-06 | pass |
| sampleSelection ML | regime_1:xs | 0.352021 | 0.352019 | 1.79e-06 | 1.79e-06 | pass |
| sampleSelection ML | regime_1:sigma | 1.97257 | 1.97257 | 1.76e-07 | 8.92e-08 | pass |
| sampleSelection ML | regime_1:rho | -0.015411 | -0.0154126 | 1.59e-06 | 1.59e-06 | pass |
| sampleSelection ML | SE selection:(Intercept) | 0.0423995 | 0.0423995 | -4.79e-11 | 1.13e-09 | pass |
| sampleSelection ML | SE selection:xs | 0.0756005 | 0.0756005 | -1.66e-10 | 2.20e-09 | pass |
| sampleSelection ML | SE regime_0:(Intercept) | 0.0633864 | 0.0633864 | 3.22e-10 | 5.08e-09 | pass |
| sampleSelection ML | SE regime_0:xs | 0.060482 | 0.060482 | -3.66e-10 | 6.05e-09 | pass |
| sampleSelection ML | SE regime_0:sigma | 0.0185334 | 0.0185334 | -4.35e-11 | 2.35e-09 | pass |
| sampleSelection ML | SE regime_0:rho | 0.159136 | 0.159136 | 1.75e-09 | 1.10e-08 | pass |
| sampleSelection ML | SE regime_1:(Intercept) | 0.499392 | 0.499388 | 3.45e-06 | 6.91e-06 | pass |
| sampleSelection ML | SE regime_1:xs | 0.319743 | 0.319742 | 1.57e-06 | 4.92e-06 | pass |
| sampleSelection ML | SE regime_1:sigma | 0.0722844 | 0.0722844 | -1.43e-08 | 1.98e-07 | pass |
| sampleSelection ML | SE regime_1:rho |  0.2337 | 0.233699 | 1.69e-06 | 7.22e-06 | pass |
| sampleSelection ML | ATT | 0.966894 | 0.966894 | -2.71e-08 | 2.71e-08 | pass |
| sampleSelection ML | ATU | 1.34249 |  1.3425 | -5.32e-06 | 3.96e-06 | pass |
| sampleSelection ML | ATE | 1.20203 | 1.20203 | -3.34e-06 | 2.78e-06 | pass |
| sampleSelection ML | TH | -0.375596 | -0.375601 | 5.30e-06 | 5.30e-06 | pass |
| sampleSelection ML | BH1 | 0.105941 | 0.105936 | 5.29e-06 | 5.29e-06 | pass |
| sampleSelection ML | BH0 | 0.481537 | 0.481537 | -3.40e-09 | 3.40e-09 | pass |
| sampleSelection ML | EY1_S1 (largest unit difference) | 0.243568 | 0.243568 | 1.20e-07 | 1.20e-07 | pass |
| sampleSelection ML | EY1_S0 (largest unit difference) | 0.301326 | 0.301332 | -5.83e-06 | 5.83e-06 | pass |
| sampleSelection ML | EY0_S1 (largest unit difference) | -1.00014 | -1.00014 | -4.00e-09 | 4.00e-09 | pass |
| sampleSelection ML | EY0_S0 (largest unit difference) | 0.158649 | 0.158649 | 4.78e-10 | 4.78e-10 | pass |
| sampleSelection ML (default iterations) | log-likelihood | -1936.43 | -1936.43 | 2.73e-11 | 2.73e-11 | pass |
| sampleSelection ML (default iterations) | selection:(Intercept) | -0.352828 | -0.352828 | -2.60e-09 | 2.60e-09 | pass |
| sampleSelection ML (default iterations) | selection:xs | 0.835381 | 0.835381 | -1.94e-08 | 1.94e-08 | pass |
| sampleSelection ML (default iterations) | regime_0:(Intercept) | -0.554476 | -0.554476 | -1.47e-09 | 1.47e-09 | pass |
| sampleSelection ML (default iterations) | regime_0:xs | 0.81764 | 0.81764 | -1.81e-09 | 1.81e-09 | pass |
| sampleSelection ML (default iterations) | regime_0:sigma | 0.591869 | 0.591869 | -1.55e-10 | 1.55e-10 | pass |
| sampleSelection ML (default iterations) | regime_0:rho | 0.155683 | 0.155683 | -3.37e-09 | 3.37e-09 | pass |
| sampleSelection ML (default iterations) | regime_1:(Intercept) | 0.645712 | 0.645715 | -3.34e-06 | 3.34e-06 | pass |
| sampleSelection ML (default iterations) | regime_1:xs | 0.352021 | 0.352019 | 1.79e-06 | 1.79e-06 | pass |
| sampleSelection ML (default iterations) | regime_1:sigma | 1.97257 | 1.97257 | 1.76e-07 | 8.92e-08 | pass |
| sampleSelection ML (default iterations) | regime_1:rho | -0.015411 | -0.0154126 | 1.59e-06 | 1.59e-06 | pass |
| sampleSelection ML (default iterations) | SE selection:(Intercept) | 0.0423995 | 0.0423995 | -4.79e-11 | 1.13e-09 | pass |
| sampleSelection ML (default iterations) | SE selection:xs | 0.0756005 | 0.0756005 | -1.66e-10 | 2.20e-09 | pass |
| sampleSelection ML (default iterations) | SE regime_0:(Intercept) | 0.0633864 | 0.0633864 | 3.22e-10 | 5.08e-09 | pass |
| sampleSelection ML (default iterations) | SE regime_0:xs | 0.060482 | 0.060482 | -3.66e-10 | 6.05e-09 | pass |
| sampleSelection ML (default iterations) | SE regime_0:sigma | 0.0185334 | 0.0185334 | -4.35e-11 | 2.35e-09 | pass |
| sampleSelection ML (default iterations) | SE regime_0:rho | 0.159136 | 0.159136 | 1.75e-09 | 1.10e-08 | pass |
| sampleSelection ML (default iterations) | SE regime_1:(Intercept) | 0.499392 | 0.499388 | 3.45e-06 | 6.91e-06 | pass |
| sampleSelection ML (default iterations) | SE regime_1:xs | 0.319743 | 0.319742 | 1.57e-06 | 4.92e-06 | pass |
| sampleSelection ML (default iterations) | SE regime_1:sigma | 0.0722844 | 0.0722844 | -1.43e-08 | 1.98e-07 | pass |
| sampleSelection ML (default iterations) | SE regime_1:rho |  0.2337 | 0.233699 | 1.69e-06 | 7.22e-06 | pass |
| sampleSelection ML (default iterations) | ATT | 0.966894 | 0.966894 | -2.71e-08 | 2.71e-08 | pass |
| sampleSelection ML (default iterations) | ATU | 1.34249 |  1.3425 | -5.32e-06 | 3.96e-06 | pass |
| sampleSelection ML (default iterations) | ATE | 1.20203 | 1.20203 | -3.34e-06 | 2.78e-06 | pass |
| sampleSelection ML (default iterations) | TH | -0.375596 | -0.375601 | 5.30e-06 | 5.30e-06 | pass |
| sampleSelection ML (default iterations) | BH1 | 0.105941 | 0.105936 | 5.29e-06 | 5.29e-06 | pass |
| sampleSelection ML (default iterations) | BH0 | 0.481537 | 0.481537 | -3.40e-09 | 3.40e-09 | pass |
| sampleSelection ML (default iterations) | EY1_S1 (largest unit difference) | 0.243568 | 0.243568 | 1.20e-07 | 1.20e-07 | pass |
| sampleSelection ML (default iterations) | EY1_S0 (largest unit difference) | 0.301326 | 0.301332 | -5.83e-06 | 5.83e-06 | pass |
| sampleSelection ML (default iterations) | EY0_S1 (largest unit difference) | -1.00014 | -1.00014 | -4.00e-09 | 4.00e-09 | pass |
| sampleSelection ML (default iterations) | EY0_S0 (largest unit difference) | 0.158649 | 0.158649 | 4.78e-10 | 4.78e-10 | pass |
| sampleSelection two-step | selection:(Intercept) | -0.352416 | -0.352416 | -4.75e-14 | 4.75e-14 | pass |
| sampleSelection two-step | selection:xs | 0.831153 | 0.831153 | 1.06e-13 | 1.06e-13 | pass |
| sampleSelection two-step | regime_0:(Intercept) | 0.41851 | 0.41851 | -3.13e-13 | 3.13e-13 | pass |
| sampleSelection two-step | regime_0:xs | 1.51424 | 1.51424 | -1.29e-13 | 1.29e-13 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | 1.67954 | 1.67954 | -4.59e-13 | 4.59e-13 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 4.89204 | 4.89204 | -8.37e-13 | 8.37e-13 | pass |
| sampleSelection two-step | regime_1:xs | -1.92669 | -1.92669 | 2.23e-13 | 2.23e-13 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | -4.05654 | -4.05654 | 9.38e-13 | 9.38e-13 | pass |
| sampleSelection two-step | regime_0:sigma | 1.33377 |  1.0371 | 2.97e-01 |  | documented |
| sampleSelection two-step | regime_1:sigma | 3.82515 |  3.3068 | 5.18e-01 |  | documented |
| sampleSelection two-step | regime_0:rho | 1.25925 |    0.99 | 2.69e-01 |  | documented |
| sampleSelection two-step | regime_1:rho | -1.06049 |   -0.99 | -7.05e-02 |  | documented |

### D6d: ?selection Tobit-5 example (seed 0 added, N = 500)

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -894.385 | -894.385 | 0.00e+00 | 0.00e+00 | pass |
| sampleSelection ML | selection:(Intercept) | -0.0632718 | -0.0632718 | -6.74e-10 | 6.74e-10 | pass |
| sampleSelection ML | selection:xs | 1.01226 | 1.01226 | 1.35e-09 | 1.33e-09 | pass |
| sampleSelection ML | regime_0:(Intercept) | 0.0295631 | 0.0295631 | -3.00e-09 | 3.00e-09 | pass |
| sampleSelection ML | regime_0:xo1 | 0.822349 | 0.822349 | -1.43e-10 | 1.43e-10 | pass |
| sampleSelection ML | regime_0:sigma | 0.934385 | 0.934385 | -1.86e-09 | 1.86e-09 | pass |
| sampleSelection ML | regime_0:rho | 0.904121 | 0.904121 | -1.40e-09 | 1.40e-09 | pass |
| sampleSelection ML | regime_1:(Intercept) | 0.230913 | 0.230913 | 9.79e-11 | 9.79e-11 | pass |
| sampleSelection ML | regime_1:xo2 | 0.778774 | 0.778774 | 2.34e-12 | 2.34e-12 | pass |
| sampleSelection ML | regime_1:sigma | 0.906112 | 0.906112 | -1.05e-11 | 1.05e-11 | pass |
| sampleSelection ML | regime_1:rho |  0.1118 |  0.1118 | -2.07e-10 | 2.07e-10 | pass |
| sampleSelection ML | SE selection:(Intercept) | 0.100755 | 0.100755 | 2.24e-10 | 2.22e-09 | pass |
| sampleSelection ML | SE selection:xs | 0.164053 | 0.164053 | 6.20e-10 | 3.78e-09 | pass |
| sampleSelection ML | SE regime_0:(Intercept) | 0.156201 | 0.156201 | 1.81e-09 | 1.16e-08 | pass |
| sampleSelection ML | SE regime_0:xo1 | 0.146741 | 0.146741 | 2.03e-10 | 1.38e-09 | pass |
| sampleSelection ML | SE regime_0:sigma | 0.0948861 | 0.0948861 | 9.74e-10 | 1.03e-08 | pass |
| sampleSelection ML | SE regime_0:rho | 0.0478657 | 0.0478657 | 1.40e-09 | 2.92e-08 | pass |
| sampleSelection ML | SE regime_1:(Intercept) | 0.200613 | 0.200613 | -2.20e-10 | 1.09e-09 | pass |
| sampleSelection ML | SE regime_1:xo2 | 0.171657 | 0.171657 | -2.74e-14 | 1.60e-13 | pass |
| sampleSelection ML | SE regime_1:sigma | 0.0399223 | 0.0399223 | -3.13e-11 | 7.84e-10 | pass |
| sampleSelection ML | SE regime_1:rho | 0.377993 | 0.377993 | -5.17e-10 | 1.37e-09 | pass |
| sampleSelection ML | ATT | -0.183645 | -0.183645 | 4.63e-09 | 4.63e-09 | pass |
| sampleSelection ML | ATU | 0.919408 | 0.919408 | 2.12e-10 | 2.12e-10 | pass |
| sampleSelection ML | ATE | 0.18377 | 0.18377 | 3.17e-09 | 3.17e-09 | pass |
| sampleSelection ML | TH | -1.10305 | -1.10305 | 4.42e-09 | 4.01e-09 | pass |
| sampleSelection ML | BH1 | 0.205472 | 0.205472 | -3.02e-10 | 3.02e-10 | pass |
| sampleSelection ML | BH0 | 1.30852 | 1.30852 | -4.72e-09 | 3.61e-09 | pass |
| sampleSelection ML | EY1_S1 (largest unit difference) |  0.3456 |  0.3456 | -1.61e-11 | 1.61e-11 | pass |
| sampleSelection ML | EY1_S0 (largest unit difference) | 0.662079 | 0.662079 | 3.26e-10 | 3.26e-10 | pass |
| sampleSelection ML | EY0_S1 (largest unit difference) | 0.98385 | 0.98385 | -5.18e-09 | 5.18e-09 | pass |
| sampleSelection ML | EY0_S0 (largest unit difference) | -0.889713 | -0.889713 | 9.20e-10 | 9.20e-10 | pass |
| sampleSelection two-step | selection:(Intercept) | -0.0748153 | -0.0748153 | -1.21e-15 | 1.21e-15 | pass |
| sampleSelection two-step | selection:xs | 1.04221 | 1.04221 | 5.33e-15 | 5.33e-15 | pass |
| sampleSelection two-step | regime_0:(Intercept) | -0.0131795 | -0.0131795 | -4.07e-15 | 4.07e-15 | pass |
| sampleSelection two-step | regime_0:xo1 | 0.786261 | 0.786261 | -1.11e-16 | 1.11e-16 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | 0.789685 | 0.789685 | -4.33e-15 | 4.33e-15 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 0.239552 | 0.239552 | 8.33e-17 | 8.33e-17 | pass |
| sampleSelection two-step | regime_1:xo2 | 0.779176 | 0.779176 | 0.00e+00 | 0.00e+00 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | 0.084577 | 0.084577 | -5.55e-17 | 5.55e-17 | pass |
| sampleSelection two-step | regime_0:sigma | 0.900099 | 0.828364 | 7.17e-02 |  | documented |
| sampleSelection two-step | regime_1:sigma | 0.905268 | 0.908359 | -3.09e-03 |  | documented |
| sampleSelection two-step | regime_0:rho | 0.877331 | 0.953307 | -7.60e-02 |  | documented |
| sampleSelection two-step | regime_1:rho | 0.0934276 | 0.0931097 | 3.18e-04 |  | documented |

### D7a: endoSwitch ImpactData, its documented example (CA ~ Age + Perception; Output ~ Age)

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -536.479 | -536.479 | 4.55e-13 | 4.55e-13 | pass |
| sampleSelection ML | selection:(Intercept) | -0.243907 | -0.243907 | 1.29e-08 | 1.29e-08 | pass |
| sampleSelection ML | selection:Age | -0.00735319 | -0.00735319 | -7.16e-11 | 7.16e-11 | pass |
| sampleSelection ML | selection:Perception | 2.15008 | 2.15008 | -2.58e-08 | 1.20e-08 | pass |
| sampleSelection ML | regime_0:(Intercept) | 1.63224 | 1.63224 | 3.67e-08 | 2.25e-08 | pass |
| sampleSelection ML | regime_0:Age | 0.000760239 | 0.000760239 | -7.79e-11 | 7.79e-11 | pass |
| sampleSelection ML | regime_0:sigma | 0.462083 | 0.462083 | 1.84e-08 | 1.84e-08 | pass |
| sampleSelection ML | regime_0:rho | 0.164473 | 0.164473 | 9.28e-08 | 9.28e-08 | pass |
| sampleSelection ML | regime_1:(Intercept) | 2.63143 | 2.63143 | -8.90e-09 | 3.38e-09 | pass |
| sampleSelection ML | regime_1:Age | 0.0058076 | 0.0058076 | 2.99e-11 | 2.99e-11 | pass |
| sampleSelection ML | regime_1:sigma | 0.70108 | 0.70108 | 9.17e-09 | 9.17e-09 | pass |
| sampleSelection ML | regime_1:rho | -0.117539 | -0.117539 | 1.80e-08 | 1.80e-08 | pass |
| sampleSelection ML | SE selection:(Intercept) | 0.306391 | 0.306391 | -2.17e-10 | 7.08e-10 | pass |
| sampleSelection ML | SE selection:Age | 0.00652142 | 0.00652142 | -7.76e-12 | 1.19e-09 | pass |
| sampleSelection ML | SE selection:Perception | 0.177842 | 0.177842 | -8.80e-10 | 4.95e-09 | pass |
| sampleSelection ML | SE regime_0:(Intercept) | 0.150671 | 0.150671 | 6.27e-09 | 4.16e-08 | pass |
| sampleSelection ML | SE regime_0:Age | 0.00293669 | 0.00293669 | 1.06e-10 | 3.60e-08 | pass |
| sampleSelection ML | SE regime_0:sigma | 0.0250564 | 0.0250564 | 3.58e-09 | 1.43e-07 | pass |
| sampleSelection ML | SE regime_0:rho | 0.188528 | 0.188528 | 3.54e-09 | 1.88e-08 | pass |
| sampleSelection ML | SE regime_1:(Intercept) | 0.196627 | 0.196627 | 2.98e-09 | 1.52e-08 | pass |
| sampleSelection ML | SE regime_1:Age | 0.00401954 | 0.00401954 | 5.41e-11 | 1.35e-08 | pass |
| sampleSelection ML | SE regime_1:sigma | 0.0331409 | 0.0331409 | 1.06e-09 | 3.20e-08 | pass |
| sampleSelection ML | SE regime_1:rho | 0.135119 | 0.135119 | 5.16e-09 | 3.82e-08 | pass |
| sampleSelection ML | ATT | 1.16035 | 1.16035 | -5.61e-08 | 4.84e-08 | pass |
| sampleSelection ML | ATU | 1.31947 | 1.31947 | -2.11e-08 | 1.60e-08 | pass |
| sampleSelection ML | ATE | 1.23172 | 1.23172 | -4.07e-08 | 3.30e-08 | pass |
| sampleSelection ML | TH | -0.159125 | -0.159125 | -3.50e-08 | 3.50e-08 | pass |
| sampleSelection ML | BH1 | -0.083234 | -0.083234 | 1.12e-08 | 1.12e-08 | pass |
| sampleSelection ML | BH0 | 0.0758906 | 0.0758906 | 4.62e-08 | 4.62e-08 | pass |
| sampleSelection ML | EY1_S1 (largest unit difference) | 3.02396 | 3.02396 | 1.08e-08 | 3.56e-09 | pass |
| sampleSelection ML | EY1_S0 (largest unit difference) |   2.931 |   2.931 | -3.42e-08 | 1.17e-08 | pass |
| sampleSelection ML | EY0_S1 (largest unit difference) | 1.80847 | 1.80847 | 9.55e-08 | 5.28e-08 | pass |
| sampleSelection ML | EY0_S0 (largest unit difference) | 1.48441 | 1.48441 | -6.29e-08 | 4.24e-08 | pass |
| sampleSelection two-step | selection:(Intercept) | -0.249119 | -0.249119 | 6.65e-13 | 6.65e-13 | pass |
| sampleSelection two-step | selection:Age | -0.00723386 | -0.00723386 | -1.48e-14 | 1.48e-14 | pass |
| sampleSelection two-step | selection:Perception | 2.14887 | 2.14887 | 4.78e-12 | 4.78e-12 | pass |
| sampleSelection two-step | regime_0:(Intercept) | 1.63553 | 1.63553 | -1.09e-13 | 1.09e-13 | pass |
| sampleSelection two-step | regime_0:Age | 0.000743025 | 0.000743025 | 1.82e-16 | 1.82e-16 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | 0.0805175 | 0.0805175 | -2.14e-13 | 2.14e-13 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 2.63054 | 2.63054 | -7.90e-14 | 7.90e-14 | pass |
| sampleSelection two-step | regime_1:Age | 0.00580432 | 0.00580432 | -2.47e-16 | 2.47e-16 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | -0.0800769 | -0.0800769 | 7.63e-14 | 7.63e-14 | pass |
| sampleSelection two-step | regime_0:sigma | 0.462382 | 0.464419 | -2.04e-03 |  | documented |
| sampleSelection two-step | regime_1:sigma | 0.701046 | 0.704681 | -3.64e-03 |  | documented |
| sampleSelection two-step | regime_0:rho | 0.174136 | 0.173373 | 7.64e-04 |  | documented |
| sampleSelection two-step | regime_1:rho | -0.114225 | -0.113636 | -5.89e-04 |  | documented |
| endoSwitch FIML | log-likelihood | -536.479 | -536.479 | 3.41e-13 | 3.41e-13 | pass |
| endoSwitch FIML | selection:(Intercept) | -0.243907 | -0.243907 | -8.34e-09 | 8.34e-09 | pass |
| endoSwitch FIML | selection:Age | -0.00735319 | -0.00735319 | 1.78e-10 | 1.78e-10 | pass |
| endoSwitch FIML | selection:Perception | 2.15008 | 2.15008 | -5.80e-09 | 2.70e-09 | pass |
| endoSwitch FIML | regime_0:(Intercept) | 1.63224 | 1.63224 | -1.86e-08 | 1.14e-08 | pass |
| endoSwitch FIML | regime_0:Age | 0.000760239 | 0.00076024 | -4.38e-10 | 4.38e-10 | pass |
| endoSwitch FIML | regime_0:sigma | 0.462083 | 0.462083 | -6.70e-09 | 6.70e-09 | pass |
| endoSwitch FIML | regime_0:rho | 0.164473 | 0.164473 | -1.31e-07 | 1.31e-07 | pass |
| endoSwitch FIML | regime_1:(Intercept) | 2.63143 | 2.63143 | 4.88e-08 | 1.85e-08 | pass |
| endoSwitch FIML | regime_1:Age | 0.0058076 | 0.0058076 | -1.10e-09 | 1.10e-09 | pass |
| endoSwitch FIML | regime_1:sigma | 0.70108 | 0.70108 | 9.08e-10 | 9.08e-10 | pass |
| endoSwitch FIML | regime_1:rho | -0.117539 | -0.117539 | 1.04e-08 | 1.04e-08 | pass |
| endoSwitch FIML | SE selection:(Intercept) | 0.306391 | 0.304292 | 2.10e-03 | 6.90e-03 | pass |
| endoSwitch FIML | SE selection:Age | 0.00652142 | 0.00647466 | 4.68e-05 | 7.22e-03 | pass |
| endoSwitch FIML | SE selection:Perception | 0.177842 | 0.177868 | -2.57e-05 | 1.44e-04 | pass |
| endoSwitch FIML | SE regime_0:(Intercept) | 0.150671 | 0.150535 | 1.36e-04 | 9.03e-04 | pass |
| endoSwitch FIML | SE regime_0:Age | 0.00293669 | 0.00293395 | 2.74e-06 | 9.32e-04 | pass |
| endoSwitch FIML | SE regime_0:sigma | 0.0250564 | 0.0250529 | 3.49e-06 | 1.39e-04 | pass |
| endoSwitch FIML | SE regime_0:rho | 0.188528 | 0.18854 | -1.19e-05 | 6.33e-05 | pass |
| endoSwitch FIML | SE regime_1:(Intercept) | 0.196627 | 0.196516 | 1.12e-04 | 5.68e-04 | pass |
| endoSwitch FIML | SE regime_1:Age | 0.00401954 | 0.00401608 | 3.45e-06 | 8.60e-04 | pass |
| endoSwitch FIML | SE regime_1:sigma | 0.0331409 | 0.0331382 | 2.67e-06 | 8.06e-05 | pass |
| endoSwitch FIML | SE regime_1:rho | 0.135119 | 0.135077 | 4.12e-05 | 3.05e-04 | pass |
| endoSwitch FIML | ATT | 1.16035 |  1.1603 | 4.57e-05 | 3.93e-05 | pass |
| endoSwitch FIML | ATU | 1.31947 |  1.3195 | -2.97e-05 | 2.25e-05 | pass |
| endoSwitch FIML | TH | -0.159125 | -0.1591 | -2.47e-05 | 2.47e-05 | pass |
| endoSwitch FIML | BH1 | -0.083234 | -0.0832 | -3.40e-05 | 3.40e-05 | pass |
| endoSwitch FIML | BH0 | 0.0758906 |  0.0759 | -9.36e-06 | 9.36e-06 | pass |
| endoSwitch FIML | EY1_S1 (largest unit difference) |  3.0921 |  3.0921 | -3.97e-08 | 1.28e-08 | pass |
| endoSwitch FIML | EY1_S1 formula at their estimates (largest unit difference) | 2.81443 | 2.81443 | 0.00e+00 | 0.00e+00 | pass |
| endoSwitch FIML | EY0_S1 (largest unit difference) | 1.79889 | 1.79889 | -1.40e-07 | 7.77e-08 | pass |
| endoSwitch FIML | EY0_S1 formula at their estimates (largest unit difference) | 1.78219 | 1.78219 | -2.22e-16 | 1.25e-16 | pass |
| endoSwitch FIML | EY1_S0 (largest unit difference) | 3.16967 | 3.16967 | -4.97e-08 | 1.57e-08 | pass |
| endoSwitch FIML | EY1_S0 formula at their estimates (largest unit difference) | 2.95212 | 2.95212 | -4.44e-16 | 1.50e-16 | pass |
| endoSwitch FIML | EY0_S0 (largest unit difference) | 1.48939 | 1.48939 | 1.02e-07 | 6.86e-08 | pass |
| endoSwitch FIML | EY0_S0 formula at their estimates (largest unit difference) | 1.48939 | 1.48939 | 2.22e-16 | 1.49e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | log-likelihood | -536.479 | -536.479 | 0.00e+00 | 0.00e+00 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:(Intercept) | -0.243907 | -0.243907 | 3.39e-09 | 3.39e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:Age | -0.00735319 | -0.00735319 | -2.86e-11 | 2.86e-11 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:Perception | 2.15008 | 2.15008 | 1.85e-09 | 8.63e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:(Intercept) | 1.63224 | 1.63224 | 1.27e-09 | 7.78e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:Age | 0.000760239 | 0.000760239 | -4.20e-11 | 4.20e-11 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:sigma | 0.462083 | 0.462083 | 1.98e-10 | 1.98e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:rho | 0.164473 | 0.164473 | 1.53e-09 | 1.53e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:(Intercept) | 2.63143 | 2.63143 | -4.79e-10 | 1.82e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:Age | 0.0058076 | 0.0058076 | 5.20e-11 | 5.20e-11 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:sigma | 0.70108 | 0.70108 | -4.12e-11 | 4.12e-11 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:rho | -0.117539 | -0.117539 | 1.32e-09 | 1.32e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:(Intercept) | 0.306391 | 0.306214 | 1.77e-04 | 5.80e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:Age | 0.00652142 | 0.0065181 | 3.32e-06 | 5.09e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:Perception | 0.177842 | 0.177527 | 3.15e-04 | 1.77e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:(Intercept) | 0.150671 | 0.15133 | -6.59e-04 | 4.36e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:Age | 0.00293669 | 0.00294319 | -6.50e-06 | 2.21e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:sigma | 0.0250564 | 0.0250599 | -3.51e-06 | 1.40e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:rho | 0.188528 | 0.189334 | -8.07e-04 | 4.26e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:(Intercept) | 0.196627 | 0.196848 | -2.21e-04 | 1.12e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:Age | 0.00401954 | 0.00402365 | -4.11e-06 | 1.02e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:sigma | 0.0331409 | 0.0331419 | -9.89e-07 | 2.99e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:rho | 0.135119 | 0.135293 | -1.74e-04 | 1.29e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | ATT | 1.16035 |  1.1603 | 4.57e-05 | 3.93e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | ATU | 1.31947 |  1.3195 | -2.97e-05 | 2.25e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | TH | -0.159125 | -0.1591 | -2.47e-05 | 2.47e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | BH1 | -0.083234 | -0.0832 | -3.40e-05 | 3.40e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | BH0 | 0.0758906 |  0.0759 | -9.36e-06 | 9.36e-06 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 (largest unit difference) |  2.9813 |  2.9813 | 5.05e-09 | 1.69e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 formula at their estimates (largest unit difference) | 2.90655 | 2.90655 | 4.44e-16 | 1.53e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 (largest unit difference) | 1.70893 | 1.70893 | -2.10e-09 | 1.23e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 formula at their estimates (largest unit difference) | 1.68103 | 1.68103 | 2.22e-16 | 1.32e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 (largest unit difference) | 3.16967 | 3.16967 | 3.82e-09 | 1.21e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 formula at their estimates (largest unit difference) |  2.9923 |  2.9923 | -4.44e-16 | 1.48e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 (largest unit difference) | 1.54264 | 1.54264 | -3.17e-09 | 2.06e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 formula at their estimates (largest unit difference) | 1.66417 | 1.66417 | 2.22e-16 | 1.33e-16 | pass |
| endoSwitch two-stage | selection:(Intercept) | -0.249119 | -0.249119 | 7.74e-08 | 7.74e-08 | pass |
| endoSwitch two-stage | selection:Age | -0.00723386 | -0.00723386 | -1.74e-09 | 1.74e-09 | pass |
| endoSwitch two-stage | selection:Perception | 2.14887 | 2.14887 | 1.35e-08 | 1.35e-08 | pass |
| endoSwitch two-stage | regime_0:(Intercept) | 1.63553 | 1.63553 | 3.17e-09 | 3.17e-09 | pass |
| endoSwitch two-stage | regime_0:Age | 0.000743025 | 0.000743025 | -6.87e-11 | 6.87e-11 | pass |
| endoSwitch two-stage | theta0 = sigma0 rho0 (minus their MillsRatioAdt0) | 0.0805175 | 0.0805175 | 6.81e-11 | 6.81e-11 | pass |
| endoSwitch two-stage | regime_1:(Intercept) | 2.63054 | 2.63054 | -2.63e-09 | 2.63e-09 | pass |
| endoSwitch two-stage | regime_1:Age | 0.00580432 | 0.00580432 | 5.13e-11 | 5.13e-11 | pass |
| endoSwitch two-stage | theta1 = sigma1 rho1 (their MillsRatioAdt1) | -0.0800769 | -0.0800769 | 3.95e-10 | 3.95e-10 | pass |
| endoSwitch two-stage | regime_0:sigma | 0.462382 | 0.458173 | 4.21e-03 |  | documented |
| endoSwitch two-stage | regime_0:rho | 0.174136 | 0.175736 | -1.60e-03 |  | documented |
| endoSwitch two-stage | regime_1:sigma | 0.701046 | 0.699018 | 2.03e-03 |  | documented |
| endoSwitch two-stage | regime_1:rho | -0.114225 | -0.114556 | 3.31e-04 |  | documented |

### D7b: endoSwitch ImpactData, larger specification chosen for this benchmark

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML | log-likelihood | -417.991 | -417.991 | 5.68e-13 | 5.68e-13 | pass |
| sampleSelection ML | selection:(Intercept) | -2.43515 | -2.43515 | 2.68e-08 | 1.10e-08 | pass |
| sampleSelection ML | selection:Age | -0.0181691 | -0.0181691 | -1.56e-10 | 1.56e-10 | pass |
| sampleSelection ML | selection:Education | 0.200964 | 0.200964 | -4.77e-09 | 4.77e-09 | pass |
| sampleSelection ML | selection:Land_holding | -0.010174 | -0.010174 | 1.85e-10 | 1.85e-10 | pass |
| sampleSelection ML | selection:Access_to_credit | 2.97996 | 2.97996 | -7.58e-09 | 2.54e-09 | pass |
| sampleSelection ML | selection:Perception |  2.2057 |  2.2057 | -2.83e-08 | 1.28e-08 | pass |
| sampleSelection ML | selection:Number_of_extension_contacts | -0.0156927 | -0.0156927 | 1.93e-09 | 1.93e-09 | pass |
| sampleSelection ML | regime_0:(Intercept) | 1.57695 | 1.57695 | -9.45e-09 | 5.99e-09 | pass |
| sampleSelection ML | regime_0:Age | 0.000318044 | 0.000318044 | 3.25e-10 | 3.25e-10 | pass |
| sampleSelection ML | regime_0:Education | 0.0148055 | 0.0148055 | -2.56e-09 | 2.56e-09 | pass |
| sampleSelection ML | regime_0:Land_holding | -0.00379255 | -0.00379255 | 2.62e-10 | 2.62e-10 | pass |
| sampleSelection ML | regime_0:Access_to_credit | 0.126184 | 0.126184 | -1.08e-07 | 1.08e-07 | pass |
| sampleSelection ML | regime_0:sigma | 0.460441 | 0.460441 | 2.65e-09 | 2.65e-09 | pass |
| sampleSelection ML | regime_0:rho | 0.291698 | 0.291698 | -2.05e-07 | 2.05e-07 | pass |
| sampleSelection ML | regime_1:(Intercept) |  2.6967 |  2.6967 | 1.04e-09 | 3.84e-10 | pass |
| sampleSelection ML | regime_1:Age | 0.00653484 | 0.00653484 | 1.03e-11 | 1.03e-11 | pass |
| sampleSelection ML | regime_1:Education | -0.0146487 | -0.0146487 | 9.28e-11 | 9.28e-11 | pass |
| sampleSelection ML | regime_1:Land_holding | -0.00833686 | -0.00833686 | -2.45e-12 | 2.45e-12 | pass |
| sampleSelection ML | regime_1:Access_to_credit | 0.0549918 | 0.0549918 | -2.00e-09 | 2.00e-09 | pass |
| sampleSelection ML | regime_1:sigma | 0.696384 | 0.696384 | 2.77e-11 | 2.77e-11 | pass |
| sampleSelection ML | regime_1:rho | -0.280199 | -0.280199 | 1.36e-09 | 1.36e-09 | pass |
| sampleSelection ML | SE selection:(Intercept) | 0.590396 | 0.590396 | -2.98e-09 | 5.05e-09 | pass |
| sampleSelection ML | SE selection:Age | 0.0102719 | 0.0102719 | 8.88e-11 | 8.64e-09 | pass |
| sampleSelection ML | SE selection:Education | 0.0505727 | 0.0505727 | 2.61e-10 | 5.17e-09 | pass |
| sampleSelection ML | SE selection:Land_holding | 0.011684 | 0.011684 | -5.17e-11 | 4.42e-09 | pass |
| sampleSelection ML | SE selection:Access_to_credit | 0.289171 | 0.289171 | -4.62e-11 | 1.60e-10 | pass |
| sampleSelection ML | SE selection:Perception | 0.332994 | 0.332994 | 2.43e-09 | 7.30e-09 | pass |
| sampleSelection ML | SE selection:Number_of_extension_contacts | 0.0517446 | 0.0517446 | 2.36e-10 | 4.56e-09 | pass |
| sampleSelection ML | SE regime_0:(Intercept) | 0.155806 | 0.155806 | 2.02e-09 | 1.29e-08 | pass |
| sampleSelection ML | SE regime_0:Age | 0.00296081 | 0.00296081 | 4.58e-11 | 1.55e-08 | pass |
| sampleSelection ML | SE regime_0:Education | 0.0139286 | 0.0139286 | 3.16e-10 | 2.27e-08 | pass |
| sampleSelection ML | SE regime_0:Land_holding | 0.00489287 | 0.00489287 | 6.19e-11 | 1.27e-08 | pass |
| sampleSelection ML | SE regime_0:Access_to_credit | 0.155469 | 0.155469 | 2.65e-08 | 1.70e-07 | pass |
| sampleSelection ML | SE regime_0:sigma | 0.0245139 | 0.0245139 | 2.35e-11 | 9.60e-10 | pass |
| sampleSelection ML | SE regime_0:rho | 0.200387 | 0.200387 | 6.99e-08 | 3.49e-07 | pass |
| sampleSelection ML | SE regime_1:(Intercept) | 0.353201 | 0.353201 | 1.17e-09 | 3.31e-09 | pass |
| sampleSelection ML | SE regime_1:Age | 0.00402883 | 0.00402883 | 5.67e-13 | 1.41e-10 | pass |
| sampleSelection ML | SE regime_1:Education | 0.0187845 | 0.0187845 | -1.14e-11 | 6.05e-10 | pass |
| sampleSelection ML | SE regime_1:Land_holding | 0.0046654 | 0.0046654 | 9.90e-14 | 2.12e-11 | pass |
| sampleSelection ML | SE regime_1:Access_to_credit | 0.265446 | 0.265446 | 1.58e-09 | 5.96e-09 | pass |
| sampleSelection ML | SE regime_1:sigma | 0.0335806 | 0.0335806 | 1.67e-11 | 4.97e-10 | pass |
| sampleSelection ML | SE regime_1:rho | 0.249352 | 0.249352 | -2.01e-11 | 8.06e-11 | pass |
| sampleSelection ML | ATT | 1.05752 | 1.05752 | 1.27e-07 | 1.20e-07 | pass |
| sampleSelection ML | ATU | 1.28623 | 1.28623 | 1.13e-10 | 8.77e-11 | pass |
| sampleSelection ML | ATE | 1.16027 | 1.16027 | 7.05e-08 | 6.08e-08 | pass |
| sampleSelection ML | TH | -0.228704 | -0.228704 | 1.27e-07 | 1.27e-07 | pass |
| sampleSelection ML | BH1 | -0.0501454 | -0.0501454 | -1.33e-09 | 1.33e-09 | pass |
| sampleSelection ML | BH0 | 0.178558 | 0.178558 | -1.28e-07 | 1.28e-07 | pass |
| sampleSelection ML | EY1_S1 (largest unit difference) | 2.18995 | 2.18995 | 1.10e-08 | 5.04e-09 | pass |
| sampleSelection ML | EY1_S0 (largest unit difference) | 3.71282 | 3.71282 | -1.77e-08 | 4.77e-09 | pass |
| sampleSelection ML | EY0_S1 (largest unit difference) | 2.13523 | 2.13523 | -3.79e-07 | 1.77e-07 | pass |
| sampleSelection ML | EY0_S0 (largest unit difference) | 1.21137 | 1.21137 | 3.01e-07 | 2.49e-07 | pass |
| sampleSelection two-step | selection:(Intercept) | -2.34024 | -2.34024 | -1.42e-11 | 1.42e-11 | pass |
| sampleSelection two-step | selection:Age | -0.018496 | -0.018496 | -5.18e-15 | 5.18e-15 | pass |
| sampleSelection two-step | selection:Education | 0.188049 | 0.188049 | 5.71e-13 | 5.71e-13 | pass |
| sampleSelection two-step | selection:Land_holding | -0.00957248 | -0.00957248 | -1.04e-14 | 1.04e-14 | pass |
| sampleSelection two-step | selection:Access_to_credit | 2.94889 | 2.94889 | 1.15e-11 | 1.15e-11 | pass |
| sampleSelection two-step | selection:Perception | 2.17597 | 2.17597 | 1.36e-11 | 1.36e-11 | pass |
| sampleSelection two-step | selection:Number_of_extension_contacts | -0.0111117 | -0.0111117 | 1.05e-13 | 1.05e-13 | pass |
| sampleSelection two-step | regime_0:(Intercept) | 1.58896 | 1.58896 | -2.92e-13 | 2.92e-13 | pass |
| sampleSelection two-step | regime_0:Age | -6.01842e-05 | -6.01842e-05 | 5.80e-15 | 5.80e-15 | pass |
| sampleSelection two-step | regime_0:Education | 0.017807 | 0.017807 | -4.50e-14 | 4.50e-14 | pass |
| sampleSelection two-step | regime_0:Land_holding | -0.00414911 | -0.00414911 | 3.44e-15 | 3.44e-15 | pass |
| sampleSelection two-step | regime_0:Access_to_credit | 0.249967 | 0.249967 | -6.37e-13 | 6.37e-13 | pass |
| sampleSelection two-step | theta0 = sigma0 rho0 (their IMR1 with the sign mapped) | 0.237776 | 0.237776 | -8.32e-13 | 8.32e-13 | pass |
| sampleSelection two-step | regime_1:(Intercept) | 2.72785 | 2.72785 | -1.16e-12 | 1.16e-12 | pass |
| sampleSelection two-step | regime_1:Age | 0.0065823 | 0.0065823 | -4.05e-15 | 4.05e-15 | pass |
| sampleSelection two-step | regime_1:Education | -0.0153198 | -0.0153198 | 3.94e-14 | 3.94e-14 | pass |
| sampleSelection two-step | regime_1:Land_holding | -0.00826777 | -0.00826777 | -3.25e-15 | 3.25e-15 | pass |
| sampleSelection two-step | regime_1:Access_to_credit | 0.0289203 | 0.0289203 | 9.14e-13 | 9.14e-13 | pass |
| sampleSelection two-step | theta1 = sigma1 rho1 (their IMR2) | -0.222991 | -0.222991 | 1.12e-12 | 1.12e-12 | pass |
| sampleSelection two-step | regime_0:sigma | 0.465248 | 0.464191 | 1.06e-03 |  | documented |
| sampleSelection two-step | regime_1:sigma | 0.697436 | 0.701963 | -4.53e-03 |  | documented |
| sampleSelection two-step | regime_0:rho | 0.511074 | 0.512238 | -1.16e-03 |  | documented |
| sampleSelection two-step | regime_1:rho | -0.319729 | -0.317668 | -2.06e-03 |  | documented |
| endoSwitch FIML | log-likelihood | -417.991 | -417.991 | 3.65e-10 | 3.65e-10 | pass |
| endoSwitch FIML | selection:(Intercept) | -2.43515 | -2.43515 | -2.80e-06 | 1.15e-06 | pass |
| endoSwitch FIML | selection:Age | -0.0181691 | -0.0181691 | -1.85e-08 | 1.85e-08 | pass |
| endoSwitch FIML | selection:Education | 0.200964 | 0.200964 | 2.29e-07 | 2.29e-07 | pass |
| endoSwitch FIML | selection:Land_holding | -0.010174 | -0.010174 | 5.96e-09 | 5.96e-09 | pass |
| endoSwitch FIML | selection:Access_to_credit | 2.97996 | 2.97995 | 3.71e-06 | 1.24e-06 | pass |
| endoSwitch FIML | selection:Perception |  2.2057 | 2.20569 | 3.45e-06 | 1.57e-06 | pass |
| endoSwitch FIML | selection:Number_of_extension_contacts | -0.0156927 | -0.0156925 | -1.95e-07 | 1.95e-07 | pass |
| endoSwitch FIML | regime_0:(Intercept) | 1.57695 | 1.57695 | -4.20e-07 | 2.66e-07 | pass |
| endoSwitch FIML | regime_0:Age | 0.000318044 | 0.000318036 | 7.94e-09 | 7.94e-09 | pass |
| endoSwitch FIML | regime_0:Education | 0.0148055 | 0.0148055 | -3.50e-08 | 3.50e-08 | pass |
| endoSwitch FIML | regime_0:Land_holding | -0.00379255 | -0.00379255 | 1.72e-09 | 1.72e-09 | pass |
| endoSwitch FIML | regime_0:Access_to_credit | 0.126184 | 0.126184 | -5.95e-07 | 5.95e-07 | pass |
| endoSwitch FIML | regime_0:sigma | 0.460441 | 0.460441 | 1.47e-07 | 1.47e-07 | pass |
| endoSwitch FIML | regime_0:rho | 0.291698 | 0.291699 | -1.33e-06 | 1.33e-06 | pass |
| endoSwitch FIML | regime_1:(Intercept) |  2.6967 |  2.6967 | 1.07e-06 | 3.98e-07 | pass |
| endoSwitch FIML | regime_1:Age | 0.00653484 | 0.00653484 | 5.42e-09 | 5.42e-09 | pass |
| endoSwitch FIML | regime_1:Education | -0.0146487 | -0.0146488 | 5.70e-08 | 5.70e-08 | pass |
| endoSwitch FIML | regime_1:Land_holding | -0.00833686 | -0.00833686 | 4.89e-09 | 4.89e-09 | pass |
| endoSwitch FIML | regime_1:Access_to_credit | 0.0549918 | 0.054994 | -2.19e-06 | 2.19e-06 | pass |
| endoSwitch FIML | regime_1:sigma | 0.696384 | 0.696384 | -3.63e-08 | 3.63e-08 | pass |
| endoSwitch FIML | regime_1:rho | -0.280199 | -0.280201 | 2.27e-06 | 2.27e-06 | pass |
| endoSwitch FIML | SE selection:(Intercept) | 0.590396 | 0.588451 | 1.94e-03 | 3.30e-03 | pass |
| endoSwitch FIML | SE selection:Age | 0.0102719 | 0.0102999 | -2.80e-05 | 2.72e-03 | pass |
| endoSwitch FIML | SE selection:Education | 0.0505727 | 0.0504888 | 8.39e-05 | 1.66e-03 | pass |
| endoSwitch FIML | SE selection:Land_holding | 0.011684 | 0.0116869 | -2.90e-06 | 2.48e-04 | pass |
| endoSwitch FIML | SE selection:Access_to_credit | 0.289171 | 0.288646 | 5.25e-04 | 1.82e-03 | pass |
| endoSwitch FIML | SE selection:Perception | 0.332994 | 0.331666 | 1.33e-03 | 4.00e-03 | pass |
| endoSwitch FIML | SE selection:Number_of_extension_contacts | 0.0517446 | 0.0517446 | 1.51e-08 | 2.92e-07 | pass |
| endoSwitch FIML | SE regime_0:(Intercept) | 0.155806 | 0.155727 | 7.87e-05 | 5.05e-04 | pass |
| endoSwitch FIML | SE regime_0:Age | 0.00296081 | 0.00295962 | 1.19e-06 | 4.02e-04 | pass |
| endoSwitch FIML | SE regime_0:Education | 0.0139286 | 0.0139291 | -5.41e-07 | 3.88e-05 | pass |
| endoSwitch FIML | SE regime_0:Land_holding | 0.00489287 | 0.00489257 | 3.08e-07 | 6.29e-05 | pass |
| endoSwitch FIML | SE regime_0:Access_to_credit | 0.155469 | 0.155251 | 2.18e-04 | 1.40e-03 | pass |
| endoSwitch FIML | SE regime_0:sigma | 0.0245139 | 0.0245085 | 5.39e-06 | 2.20e-04 | pass |
| endoSwitch FIML | SE regime_0:rho | 0.200387 | 0.199686 | 7.01e-04 | 3.51e-03 | pass |
| endoSwitch FIML | SE regime_1:(Intercept) | 0.353201 | 0.351869 | 1.33e-03 | 3.78e-03 | pass |
| endoSwitch FIML | SE regime_1:Age | 0.00402883 | 0.00403153 | -2.70e-06 | 6.70e-04 | pass |
| endoSwitch FIML | SE regime_1:Education | 0.0187845 | 0.0187762 | 8.33e-06 | 4.43e-04 | pass |
| endoSwitch FIML | SE regime_1:Land_holding | 0.0046654 | 0.00466519 | 2.10e-07 | 4.50e-05 | pass |
| endoSwitch FIML | SE regime_1:Access_to_credit | 0.265446 | 0.264204 | 1.24e-03 | 4.70e-03 | pass |
| endoSwitch FIML | SE regime_1:sigma | 0.0335806 | 0.0335764 | 4.17e-06 | 1.24e-04 | pass |
| endoSwitch FIML | SE regime_1:rho | 0.249352 | 0.248226 | 1.13e-03 | 4.53e-03 | pass |
| endoSwitch FIML | ATT | 1.05752 |  1.0575 | 2.31e-05 | 2.18e-05 | pass |
| endoSwitch FIML | ATU | 1.28623 |  1.2862 | 2.66e-05 | 2.07e-05 | pass |
| endoSwitch FIML | TH | -0.228704 | -0.2287 | -3.50e-06 | 3.50e-06 | pass |
| endoSwitch FIML | BH1 | -0.0501454 | -0.0501 | -4.54e-05 | 4.54e-05 | pass |
| endoSwitch FIML | BH0 | 0.178558 |  0.1786 | -4.19e-05 | 4.19e-05 | pass |
| endoSwitch FIML | EY1_S1 (largest unit difference) |  2.4036 | 2.40359 | 4.78e-06 | 1.99e-06 | pass |
| endoSwitch FIML | EY1_S1 formula at their estimates (largest unit difference) |  2.9231 |  2.9231 | 8.88e-16 | 3.04e-16 | pass |
| endoSwitch FIML | EY0_S1 (largest unit difference) | 1.52746 | 1.52746 | -1.28e-06 | 8.39e-07 | pass |
| endoSwitch FIML | EY0_S1 formula at their estimates (largest unit difference) | 1.81611 | 1.81611 | 2.22e-16 | 1.22e-16 | pass |
| endoSwitch FIML | EY1_S0 (largest unit difference) | 3.50098 | 3.50098 | -5.40e-06 | 1.54e-06 | pass |
| endoSwitch FIML | EY1_S0 formula at their estimates (largest unit difference) | 3.50098 | 3.50098 | 2.71e-14 | 7.74e-15 | pass |
| endoSwitch FIML | EY0_S0 (largest unit difference) | 1.30281 | 1.30281 | 4.21e-07 | 3.23e-07 | pass |
| endoSwitch FIML | EY0_S0 formula at their estimates (largest unit difference) | 1.30281 | 1.30281 | -1.87e-14 | 1.43e-14 | pass |
| endoSwitch FIML (reltol 1e-14) | log-likelihood | -417.991 | -417.991 | 0.00e+00 | 0.00e+00 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:(Intercept) | -2.43515 | -2.43515 | -3.82e-09 | 1.57e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:Age | -0.0181691 | -0.0181691 | 3.44e-10 | 3.44e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:Education | 0.200964 | 0.200964 | 2.16e-09 | 2.16e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:Land_holding | -0.010174 | -0.010174 | -2.17e-10 | 2.17e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:Access_to_credit | 2.97996 | 2.97996 | -1.02e-08 | 3.43e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:Perception |  2.2057 |  2.2057 | -1.20e-08 | 5.43e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | selection:Number_of_extension_contacts | -0.0156927 | -0.0156927 | -3.37e-09 | 3.37e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:(Intercept) | 1.57695 | 1.57695 | 1.91e-09 | 1.21e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:Age | 0.000318044 | 0.000318044 | 3.56e-11 | 3.56e-11 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:Education | 0.0148055 | 0.0148055 | -1.18e-09 | 1.18e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:Land_holding | -0.00379255 | -0.00379255 | -1.56e-11 | 1.56e-11 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:Access_to_credit | 0.126184 | 0.126184 | -2.95e-08 | 2.95e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:sigma | 0.460441 | 0.460441 | 3.34e-09 | 3.34e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_0:rho | 0.291698 | 0.291698 | -4.40e-08 | 4.40e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:(Intercept) |  2.6967 |  2.6967 | -1.13e-08 | 4.20e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:Age | 0.00653484 | 0.00653484 | 1.14e-12 | 1.14e-12 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:Education | -0.0146487 | -0.0146487 | -6.68e-10 | 6.68e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:Land_holding | -0.00833686 | -0.00833686 | -1.97e-10 | 1.97e-10 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:Access_to_credit | 0.0549918 | 0.0549918 | 1.91e-08 | 1.91e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:sigma | 0.696384 | 0.696384 | 1.12e-09 | 1.12e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | regime_1:rho | -0.280199 | -0.280199 | -7.58e-09 | 7.58e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:(Intercept) | 0.590396 | 0.591585 | -1.19e-03 | 2.01e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:Age | 0.0102719 | 0.0103499 | -7.80e-05 | 7.54e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:Education | 0.0505727 | 0.0505544 | 1.83e-05 | 3.62e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:Land_holding | 0.011684 | 0.0116864 | -2.39e-06 | 2.04e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:Access_to_credit | 0.289171 | 0.289526 | -3.55e-04 | 1.23e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE selection:Perception | 0.332994 | 0.336678 | -3.68e-03 | 1.09e-02 | FAIL |
| endoSwitch FIML (reltol 1e-14) | SE selection:Number_of_extension_contacts | 0.0517446 | 0.0518285 | -8.39e-05 | 1.62e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:(Intercept) | 0.155806 | 0.156275 | -4.69e-04 | 3.00e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:Age | 0.00296081 | 0.00296949 | -8.68e-06 | 2.92e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:Education | 0.0139286 | 0.0139301 | -1.49e-06 | 1.07e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:Land_holding | 0.00489287 | 0.00489423 | -1.36e-06 | 2.77e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:Access_to_credit | 0.155469 | 0.156284 | -8.15e-04 | 5.21e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:sigma | 0.0245139 | 0.0245251 | -1.13e-05 | 4.59e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_0:rho | 0.200387 | 0.201347 | -9.60e-04 | 4.77e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:(Intercept) | 0.353201 | 0.352325 | 8.76e-04 | 2.49e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:Age | 0.00402883 | 0.00403106 | -2.24e-06 | 5.55e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:Education | 0.0187845 | 0.0187735 | 1.10e-05 | 5.86e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:Land_holding | 0.0046654 | 0.00466577 | -3.74e-07 | 8.02e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:Access_to_credit | 0.265446 | 0.265471 | -2.53e-05 | 9.53e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:sigma | 0.0335806 | 0.0335761 | 4.50e-06 | 1.34e-04 | pass |
| endoSwitch FIML (reltol 1e-14) | SE regime_1:rho | 0.249352 | 0.249696 | -3.44e-04 | 1.38e-03 | pass |
| endoSwitch FIML (reltol 1e-14) | ATT | 1.05752 |  1.0575 | 2.31e-05 | 2.18e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | ATU | 1.28623 |  1.2862 | 2.66e-05 | 2.07e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | TH | -0.228704 | -0.2287 | -3.50e-06 | 3.50e-06 | pass |
| endoSwitch FIML (reltol 1e-14) | BH1 | -0.0501454 | -0.0501 | -4.54e-05 | 4.54e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | BH0 | 0.178558 |  0.1786 | -4.19e-05 | 4.19e-05 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 (largest unit difference) |  2.4036 |  2.4036 | -2.69e-08 | 1.12e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S1 formula at their estimates (largest unit difference) | 2.63527 | 2.63527 | 8.88e-16 | 3.37e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 (largest unit difference) | 1.52746 | 1.52746 | -4.64e-08 | 3.04e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S1 formula at their estimates (largest unit difference) | 1.81063 | 1.81063 | -4.44e-16 | 2.45e-16 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 (largest unit difference) | 2.39335 | 2.39335 | -2.38e-08 | 9.94e-09 | pass |
| endoSwitch FIML (reltol 1e-14) | EY1_S0 formula at their estimates (largest unit difference) | 3.50098 | 3.50098 | -1.24e-14 | 3.55e-15 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 (largest unit difference) | 1.30281 | 1.30281 | 3.67e-08 | 2.82e-08 | pass |
| endoSwitch FIML (reltol 1e-14) | EY0_S0 formula at their estimates (largest unit difference) | 1.30281 | 1.30281 | 8.88e-15 | 6.82e-15 | pass |
| endoSwitch two-stage | selection:(Intercept) | -2.34024 | -2.34025 | 3.72e-06 | 3.72e-06 | FAIL |
| endoSwitch two-stage | selection:Age | -0.018496 | -0.0184959 | -1.14e-07 | 1.14e-07 | pass |
| endoSwitch two-stage | selection:Education | 0.188049 | 0.188049 | 2.72e-07 | 2.72e-07 | pass |
| endoSwitch two-stage | selection:Land_holding | -0.00957248 | -0.00957234 | -1.48e-07 | 1.48e-07 | pass |
| endoSwitch two-stage | selection:Access_to_credit | 2.94889 | 2.94888 | 3.71e-06 | 3.71e-06 | FAIL |
| endoSwitch two-stage | selection:Perception | 2.17597 | 2.17596 | 6.17e-06 | 6.17e-06 | FAIL |
| endoSwitch two-stage | selection:Number_of_extension_contacts | -0.0111117 | -0.0111112 | -4.80e-07 | 4.80e-07 | pass |
| endoSwitch two-stage | regime_0:(Intercept) | 1.58896 | 1.58896 | 2.16e-07 | 2.16e-07 | pass |
| endoSwitch two-stage | regime_0:Age | -6.01842e-05 | -6.01815e-05 | -2.63e-09 | 2.63e-09 | pass |
| endoSwitch two-stage | regime_0:Education | 0.017807 | 0.017807 | -3.31e-08 | 3.31e-08 | pass |
| endoSwitch two-stage | regime_0:Land_holding | -0.00414911 | -0.00414911 | -2.99e-09 | 2.99e-09 | pass |
| endoSwitch two-stage | regime_0:Access_to_credit | 0.249967 | 0.249968 | -1.02e-06 | 1.02e-06 | FAIL |
| endoSwitch two-stage | theta0 = sigma0 rho0 (minus their MillsRatioAdt0) | 0.237776 | 0.237777 | -9.87e-07 | 9.87e-07 | pass |
| endoSwitch two-stage | regime_1:(Intercept) | 2.72785 | 2.72785 | -1.03e-06 | 1.03e-06 | FAIL |
| endoSwitch two-stage | regime_1:Age | 0.0065823 | 0.0065823 | 1.92e-09 | 1.92e-09 | pass |
| endoSwitch two-stage | regime_1:Education | -0.0153198 | -0.0153198 | 1.80e-08 | 1.80e-08 | pass |
| endoSwitch two-stage | regime_1:Land_holding | -0.00826777 | -0.00826778 | 6.57e-09 | 6.57e-09 | pass |
| endoSwitch two-stage | regime_1:Access_to_credit | 0.0289203 | 0.0289196 | 6.99e-07 | 6.99e-07 | pass |
| endoSwitch two-stage | theta1 = sigma1 rho1 (their MillsRatioAdt1) | -0.222991 | -0.222991 | 3.71e-07 | 3.71e-07 | pass |
| endoSwitch two-stage | regime_0:sigma | 0.465248 | 0.458568 | 6.68e-03 |  | documented |
| endoSwitch two-stage | regime_0:rho | 0.511074 | 0.518521 | -7.45e-03 |  | documented |
| endoSwitch two-stage | regime_1:sigma | 0.697436 | 0.693405 | 4.03e-03 |  | documented |
| endoSwitch two-stage | regime_1:rho | -0.319729 | -0.321589 | 1.86e-03 |  | documented |

### D8: base design, N = 2000, integer weights 1-3 and 100 clusters

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML on replicated rows (+ sandwich package) | log-likelihood | -7495.47 | -7495.47 | 2.18e-11 | 2.18e-11 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | selection:(Intercept) | 0.511013 | 0.511013 | 5.30e-09 | 5.30e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | selection:x1 | 0.291896 | 0.291896 | -4.14e-09 | 4.14e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | selection:z1 | -0.438322 | -0.438322 | -1.40e-08 | 1.40e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_0:(Intercept) | 0.821753 | 0.821753 | -6.01e-09 | 6.01e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_0:x1 | 0.49117 | 0.49117 | -1.68e-09 | 1.68e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_0:x2 | 0.147557 | 0.147557 | 2.47e-11 | 2.47e-11 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_0:sigma | 0.947257 | 0.947257 | -7.53e-10 | 7.53e-10 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_0:rho | 0.191291 | 0.191291 | -6.04e-09 | 6.04e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_1:(Intercept) | 1.54296 | 1.54296 | 1.84e-07 | 1.19e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_1:x1 | 0.786091 | 0.786091 | -4.34e-08 | 4.34e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_1:x2 | 0.410955 | 0.410955 | 3.60e-10 | 3.60e-10 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_1:sigma | 0.982031 | 0.982031 | -7.15e-08 | 7.15e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_1:rho | 0.538498 | 0.538499 | -3.61e-07 | 3.61e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | selection:(Intercept) | 0.511013 | 0.511013 | 5.30e-09 | 5.30e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | selection:x1 | 0.291896 | 0.291896 | -4.14e-09 | 4.14e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | selection:z1 | -0.438322 | -0.438322 | -1.40e-08 | 1.40e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_0:(Intercept) | 0.821753 | 0.821753 | -6.01e-09 | 6.01e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_0:x1 | 0.49117 | 0.49117 | -1.68e-09 | 1.68e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_0:x2 | 0.147557 | 0.147557 | 2.47e-11 | 2.47e-11 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_0:sigma | 0.947257 | 0.947257 | -7.53e-10 | 7.53e-10 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_0:rho | 0.191291 | 0.191291 | -6.04e-09 | 6.04e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_1:(Intercept) | 1.54296 | 1.54296 | 1.84e-07 | 1.19e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_1:x1 | 0.786091 | 0.786091 | -4.34e-08 | 4.34e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_1:x2 | 0.410955 | 0.410955 | 3.60e-10 | 3.60e-10 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_1:sigma | 0.982031 | 0.982031 | -7.15e-08 | 7.15e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | regime_1:rho | 0.538498 | 0.538499 | -3.61e-07 | 3.61e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) selection:(Intercept) | 0.0221404 | 0.0221404 | -1.32e-11 | 5.96e-10 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) selection:x1 | 0.0221492 | 0.0221492 | 4.65e-10 | 2.10e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) selection:z1 | 0.0226111 | 0.0226111 | 7.95e-10 | 3.52e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) regime_0:(Intercept) | 0.106529 | 0.106529 | -3.36e-09 | 3.16e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) regime_0:x1 | 0.0331757 | 0.0331757 | -5.40e-10 | 1.63e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) regime_0:x2 | 0.0262906 | 0.0262906 | -2.59e-12 | 9.85e-11 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) regime_0:sigma | 0.0222223 | 0.0222223 | -4.71e-10 | 2.12e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) regime_0:rho | 0.103439 | 0.103439 | -3.24e-09 | 3.14e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) regime_1:(Intercept) | 0.0383369 | 0.0383368 | 2.81e-08 | 7.34e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) regime_1:x1 | 0.0201358 | 0.0201358 | 2.46e-09 | 1.22e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) regime_1:x2 | 0.0173677 | 0.0173677 | 6.82e-10 | 3.93e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) regime_1:sigma | 0.0214753 | 0.0214753 | 3.06e-09 | 1.42e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (Hessian) regime_1:rho | 0.0592823 | 0.0592822 | 7.92e-08 | 1.34e-06 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) selection:(Intercept) | 0.0333615 | 0.0333615 | -4.51e-11 | 1.35e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) selection:x1 | 0.0337285 | 0.0337285 | 4.75e-10 | 1.41e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) selection:z1 | 0.0328215 | 0.0328215 | 6.91e-10 | 2.11e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) regime_0:(Intercept) | 0.164037 | 0.164037 | -5.55e-09 | 3.38e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) regime_0:x1 | 0.0503605 | 0.0503605 | -8.48e-10 | 1.68e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) regime_0:x2 | 0.0416797 | 0.0416797 | -1.16e-11 | 2.77e-10 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) regime_0:sigma | 0.0321377 | 0.0321377 | -7.07e-10 | 2.20e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) regime_0:rho | 0.155481 | 0.155481 | -5.39e-09 | 3.46e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) regime_1:(Intercept) | 0.0550985 | 0.0550984 | 6.25e-08 | 1.13e-06 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) regime_1:x1 | 0.0303176 | 0.0303176 | 4.76e-09 | 1.57e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) regime_1:x2 | 0.0258678 | 0.0258678 | 5.13e-11 | 1.98e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) regime_1:sigma | 0.0319688 | 0.0319688 | 1.77e-08 | 5.53e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (sandwich) regime_1:rho | 0.0826463 | 0.0826462 | 1.61e-07 | 1.95e-06 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) selection:(Intercept) | 0.0346698 | 0.0346698 | -3.18e-10 | 9.18e-09 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) selection:x1 | 0.0333037 | 0.0333037 | 7.40e-10 | 2.22e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) selection:z1 | 0.0330308 | 0.0330308 | 2.39e-09 | 7.23e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) regime_0:(Intercept) | 0.176253 | 0.176253 | -5.03e-09 | 2.85e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) regime_0:x1 | 0.0558187 | 0.0558187 | -7.53e-10 | 1.35e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) regime_0:x2 | 0.0420528 | 0.0420528 | -1.60e-11 | 3.80e-10 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) regime_0:sigma | 0.0328597 | 0.0328597 | -9.21e-10 | 2.80e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) regime_0:rho | 0.164604 | 0.164604 | -4.95e-09 | 3.01e-08 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) regime_1:(Intercept) | 0.0569264 | 0.0569264 | 6.79e-08 | 1.19e-06 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) regime_1:x1 | 0.027584 | 0.027584 | 5.42e-09 | 1.97e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) regime_1:x2 | 0.0222999 | 0.0222999 | 1.20e-11 | 5.37e-10 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) regime_1:sigma | 0.0331725 | 0.0331725 | 2.00e-08 | 6.02e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | SE (cluster) regime_1:rho | 0.0879854 | 0.0879852 | 1.73e-07 | 1.97e-06 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | ATT (weighted) | 0.931281 | 0.931281 | -5.92e-10 | 5.92e-10 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | ATU (weighted) | 0.301212 | 0.301211 | 5.79e-07 | 5.79e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | ATE (weighted) | 0.72585 | 0.725849 | 1.89e-07 | 1.89e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | TH (weighted) | 0.630069 | 0.63007 | -5.80e-07 | 5.80e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | BH1 (weighted) | 1.09842 | 1.09842 | -5.89e-07 | 5.36e-07 | pass |
| sampleSelection ML on replicated rows (+ sandwich package) | BH0 (weighted) | 0.468346 | 0.468346 | -9.45e-09 | 9.45e-09 | pass |
| endoSwitch FIML, weighted | log-likelihood | -7495.47 | -7495.47 | 0.00e+00 | 0.00e+00 | pass |
| endoSwitch FIML, weighted | selection:(Intercept) | 0.511013 | 0.511013 | 2.07e-10 | 2.07e-10 | pass |
| endoSwitch FIML, weighted | selection:x1 | 0.291896 | 0.291896 | 2.32e-10 | 2.32e-10 | pass |
| endoSwitch FIML, weighted | selection:z1 | -0.438322 | -0.438322 | 3.93e-10 | 3.93e-10 | pass |
| endoSwitch FIML, weighted | regime_0:(Intercept) | 0.821753 | 0.821753 | 1.30e-08 | 1.30e-08 | pass |
| endoSwitch FIML, weighted | regime_0:x1 | 0.49117 | 0.49117 | 7.70e-10 | 7.70e-10 | pass |
| endoSwitch FIML, weighted | regime_0:x2 | 0.147557 | 0.147557 | -4.18e-10 | 4.18e-10 | pass |
| endoSwitch FIML, weighted | regime_0:sigma | 0.947257 | 0.947257 | -1.87e-09 | 1.87e-09 | pass |
| endoSwitch FIML, weighted | regime_0:rho | 0.191291 | 0.191291 | 1.03e-08 | 1.03e-08 | pass |
| endoSwitch FIML, weighted | regime_1:(Intercept) | 1.54296 | 1.54296 | 1.29e-09 | 8.38e-10 | pass |
| endoSwitch FIML, weighted | regime_1:x1 | 0.786091 | 0.786091 | 3.07e-10 | 3.07e-10 | pass |
| endoSwitch FIML, weighted | regime_1:x2 | 0.410955 | 0.410955 | 4.56e-10 | 4.56e-10 | pass |
| endoSwitch FIML, weighted | regime_1:sigma | 0.982031 | 0.982031 | 7.16e-10 | 7.16e-10 | pass |
| endoSwitch FIML, weighted | regime_1:rho | 0.538498 | 0.538498 | -4.04e-09 | 4.04e-09 | pass |
| endoSwitch FIML, weighted | SE (Hessian) selection:(Intercept) | 0.0221404 | 0.0221358 | 4.64e-06 | 2.10e-04 | pass |
| endoSwitch FIML, weighted | SE (Hessian) selection:x1 | 0.0221492 | 0.0221502 | -1.01e-06 | 4.55e-05 | pass |
| endoSwitch FIML, weighted | SE (Hessian) selection:z1 | 0.0226111 | 0.0226618 | -5.06e-05 | 2.24e-03 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_0:(Intercept) | 0.106529 | 0.110323 | -3.79e-03 | 3.44e-02 | FAIL |
| endoSwitch FIML, weighted | SE (Hessian) regime_0:x1 | 0.0331757 | 0.0336765 | -5.01e-04 | 1.49e-02 | FAIL |
| endoSwitch FIML, weighted | SE (Hessian) regime_0:x2 | 0.0262906 | 0.0262927 | -2.07e-06 | 7.89e-05 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_0:sigma | 0.0222223 | 0.0225179 | -2.96e-04 | 1.31e-02 | FAIL |
| endoSwitch FIML, weighted | SE (Hessian) regime_0:rho | 0.103439 | 0.107046 | -3.61e-03 | 3.37e-02 | FAIL |
| endoSwitch FIML, weighted | SE (Hessian) regime_1:(Intercept) | 0.0383369 | 0.0383681 | -3.12e-05 | 8.13e-04 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_1:x1 | 0.0201358 | 0.0201393 | -3.49e-06 | 1.73e-04 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_1:x2 | 0.0173677 | 0.0173673 | 3.59e-07 | 2.06e-05 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_1:sigma | 0.0214753 | 0.0214832 | -7.90e-06 | 3.68e-04 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_1:rho | 0.0592823 | 0.0593163 | -3.40e-05 | 5.73e-04 | pass |
| endoSwitch FIML, weighted | ATT (ours weighted vs theirs) | 0.931281 |  0.9284 | 2.88e-03 |  | documented |
| endoSwitch FIML, weighted | ATU (ours weighted vs theirs) | 0.301212 |  0.2958 | 5.41e-03 |  | documented |
| endoSwitch FIML, weighted | ATT (our unweighted formula at their estimates) | 0.928384 |  0.9284 | -1.62e-05 | 1.62e-05 | pass |
| endoSwitch FIML, weighted | ATU (our unweighted formula at their estimates) | 0.295777 |  0.2958 | -2.33e-05 | 2.33e-05 | pass |

### D8b: base design, N = 2000, continuous weights U(0.5, 2)

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| endoSwitch FIML, weighted | log-likelihood | -4724.98 | -4724.98 | 9.09e-13 | 9.09e-13 | pass |
| endoSwitch FIML, weighted | selection:(Intercept) | 0.468663 | 0.468663 | 2.38e-09 | 2.38e-09 | pass |
| endoSwitch FIML, weighted | selection:x1 | 0.280016 | 0.280016 | 5.00e-11 | 5.00e-11 | pass |
| endoSwitch FIML, weighted | selection:z1 | -0.471992 | -0.471992 | -2.73e-09 | 2.73e-09 | pass |
| endoSwitch FIML, weighted | regime_0:(Intercept) | 0.813297 | 0.813297 | -3.60e-08 | 3.60e-08 | pass |
| endoSwitch FIML, weighted | regime_0:x1 | 0.450764 | 0.450764 | -5.47e-09 | 5.47e-09 | pass |
| endoSwitch FIML, weighted | regime_0:x2 | 0.104655 | 0.104655 | -5.30e-09 | 5.30e-09 | pass |
| endoSwitch FIML, weighted | regime_0:sigma | 0.941851 | 0.941851 | -2.89e-08 | 2.89e-08 | pass |
| endoSwitch FIML, weighted | regime_0:rho | 0.301688 | 0.301688 | -2.52e-08 | 2.52e-08 | pass |
| endoSwitch FIML, weighted | regime_1:(Intercept) | 1.55139 | 1.55139 | 1.99e-08 | 1.29e-08 | pass |
| endoSwitch FIML, weighted | regime_1:x1 | 0.741154 | 0.741154 | -5.55e-09 | 5.55e-09 | pass |
| endoSwitch FIML, weighted | regime_1:x2 | 0.38519 | 0.38519 | 5.59e-09 | 5.59e-09 | pass |
| endoSwitch FIML, weighted | regime_1:sigma | 0.987676 | 0.987676 | -1.18e-08 | 1.18e-08 | pass |
| endoSwitch FIML, weighted | regime_1:rho | 0.524395 | 0.524395 | -2.26e-08 | 2.26e-08 | pass |
| endoSwitch FIML, weighted | SE (Hessian) selection:(Intercept) | 0.0278158 | 0.02783 | -1.42e-05 | 5.10e-04 | pass |
| endoSwitch FIML, weighted | SE (Hessian) selection:x1 | 0.0271364 | 0.0271277 | 8.78e-06 | 3.24e-04 | pass |
| endoSwitch FIML, weighted | SE (Hessian) selection:z1 | 0.0290581 | 0.0290873 | -2.92e-05 | 1.00e-03 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_0:(Intercept) | 0.0988983 | 0.100769 | -1.87e-03 | 1.86e-02 | FAIL |
| endoSwitch FIML, weighted | SE (Hessian) regime_0:x1 | 0.034599 | 0.0348243 | -2.25e-04 | 6.47e-03 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_0:x2 | 0.0324326 | 0.0324389 | -6.23e-06 | 1.92e-04 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_0:sigma | 0.0288549 | 0.0290796 | -2.25e-04 | 7.72e-03 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_0:rho | 0.0940319 | 0.0957435 | -1.71e-03 | 1.79e-02 | FAIL |
| endoSwitch FIML, weighted | SE (Hessian) regime_1:(Intercept) | 0.0503724 | 0.0504477 | -7.54e-05 | 1.49e-03 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_1:x1 | 0.025701 | 0.025737 | -3.60e-05 | 1.40e-03 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_1:x2 | 0.0232146 | 0.0232179 | -3.26e-06 | 1.40e-04 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_1:sigma | 0.0273734 | 0.0274164 | -4.30e-05 | 1.57e-03 | pass |
| endoSwitch FIML, weighted | SE (Hessian) regime_1:rho | 0.0759182 | 0.0761301 | -2.12e-04 | 2.78e-03 | pass |

### D9: clustered data, N = 2000 in 100 clusters (cluster share 0.5 in x1 and z1, 0.3 in the errors)

| Benchmark | Quantity | SwitchEconometrics | Benchmark value | Difference | Criterion | Status |
| --- | --- | --- | --- | --- | --- | --- |
| sampleSelection ML + sandwich package | log-likelihood | -3883.92 | -3883.92 | 0.00e+00 | 0.00e+00 | pass |
| sampleSelection ML + sandwich package | selection:(Intercept) | 0.484565 | 0.484565 | 7.83e-13 | 7.83e-13 | pass |
| sampleSelection ML + sandwich package | selection:x1 | 0.268508 | 0.268508 | -4.95e-13 | 4.95e-13 | pass |
| sampleSelection ML + sandwich package | selection:z1 | -0.397478 | -0.397478 | -6.17e-12 | 6.17e-12 | pass |
| sampleSelection ML + sandwich package | regime_0:(Intercept) | 0.948236 | 0.948236 | -5.14e-12 | 5.14e-12 | pass |
| sampleSelection ML + sandwich package | regime_0:x1 | 0.427323 | 0.427323 | -9.87e-13 | 9.87e-13 | pass |
| sampleSelection ML + sandwich package | regime_0:x2 | 0.233003 | 0.233003 | 1.06e-14 | 1.06e-14 | pass |
| sampleSelection ML + sandwich package | regime_0:sigma | 1.02041 | 1.02041 | -9.68e-13 | 9.49e-13 | pass |
| sampleSelection ML + sandwich package | regime_0:rho | 0.300763 | 0.300763 | -4.35e-12 | 4.35e-12 | pass |
| sampleSelection ML + sandwich package | regime_1:(Intercept) | 1.39636 | 1.39636 | 4.91e-11 | 3.51e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:x1 | 0.764816 | 0.764816 | -1.17e-11 | 1.17e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:x2 | 0.37852 | 0.37852 | -9.27e-15 | 9.27e-15 | pass |
| sampleSelection ML + sandwich package | regime_1:sigma | 1.05726 | 1.05726 | -2.83e-11 | 2.68e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:rho | 0.685603 | 0.685603 | -7.86e-11 | 7.86e-11 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) selection:(Intercept) | 0.0305453 | 0.0305453 | -8.94e-15 | 2.93e-13 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) selection:x1 | 0.0297678 | 0.0297678 | 1.50e-13 | 5.03e-12 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) selection:z1 | 0.0322728 | 0.0322728 | 1.06e-12 | 3.29e-11 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) regime_0:(Intercept) | 0.191634 | 0.191634 | -2.83e-12 | 1.48e-11 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) regime_0:x1 | 0.0485285 | 0.0485285 | -3.65e-13 | 7.51e-12 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) regime_0:x2 | 0.0391705 | 0.0391705 | 6.11e-16 | 1.55e-14 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) regime_0:sigma | 0.0447011 | 0.0447011 | -8.59e-13 | 1.92e-11 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) regime_0:rho | 0.162802 | 0.162802 | -1.98e-12 | 1.22e-11 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) regime_1:(Intercept) | 0.0529975 | 0.0529975 | 1.31e-11 | 2.48e-10 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) regime_1:x1 | 0.0296962 | 0.0296962 | 1.02e-12 | 3.44e-11 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) regime_1:x2 | 0.0251018 | 0.0251018 | 2.37e-13 | 9.43e-12 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) regime_1:sigma | 0.0361944 | 0.0361944 | 5.02e-12 | 1.39e-10 | pass |
| sampleSelection ML + sandwich package | SE (Hessian) regime_1:rho | 0.0638728 | 0.0638728 | 3.05e-11 | 4.78e-10 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) selection:(Intercept) | 0.0307101 | 0.0307101 | -3.72e-14 | 1.21e-12 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) selection:x1 | 0.0304112 | 0.0304112 | 1.35e-13 | 4.45e-12 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) selection:z1 | 0.0320514 | 0.0320514 | 9.12e-13 | 2.84e-11 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) regime_0:(Intercept) | 0.193807 | 0.193807 | -2.96e-12 | 1.53e-11 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) regime_0:x1 | 0.0495402 | 0.0495402 | -3.85e-13 | 7.77e-12 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) regime_0:x2 | 0.0380922 | 0.0380922 | -1.10e-15 | 2.90e-14 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) regime_0:sigma | 0.0439792 | 0.0439792 | -8.81e-13 | 2.00e-11 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) regime_0:rho | 0.165075 | 0.165075 | -2.11e-12 | 1.28e-11 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) regime_1:(Intercept) | 0.0538188 | 0.0538188 | 1.96e-11 | 3.65e-10 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) regime_1:x1 | 0.030081 | 0.030081 | 1.70e-12 | 5.67e-11 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) regime_1:x2 | 0.0244063 | 0.0244063 | 4.62e-14 | 1.89e-12 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) regime_1:sigma | 0.0354378 | 0.0354378 | 1.00e-11 | 2.83e-10 | pass |
| sampleSelection ML + sandwich package | SE (sandwich) regime_1:rho | 0.062113 | 0.062113 | 4.05e-11 | 6.52e-10 | pass |
| sampleSelection ML + sandwich package | SE (OPG) selection:(Intercept) | 0.0304533 | 0.0304533 | 1.61e-14 | 5.30e-13 | pass |
| sampleSelection ML + sandwich package | SE (OPG) selection:x1 | 0.029274 | 0.029274 | 1.87e-13 | 6.38e-12 | pass |
| sampleSelection ML + sandwich package | SE (OPG) selection:z1 | 0.0327795 | 0.0327795 | 1.05e-12 | 3.21e-11 | pass |
| sampleSelection ML + sandwich package | SE (OPG) regime_0:(Intercept) | 0.190866 | 0.190866 | -2.68e-12 | 1.41e-11 | pass |
| sampleSelection ML + sandwich package | SE (OPG) regime_0:x1 | 0.0476705 | 0.0476705 | -3.42e-13 | 7.18e-12 | pass |
| sampleSelection ML + sandwich package | SE (OPG) regime_0:x2 | 0.0407383 | 0.0407383 | 2.84e-15 | 6.99e-14 | pass |
| sampleSelection ML + sandwich package | SE (OPG) regime_0:sigma | 0.0456439 | 0.0456439 | -8.36e-13 | 1.83e-11 | pass |
| sampleSelection ML + sandwich package | SE (OPG) regime_0:rho | 0.161907 | 0.161907 | -1.83e-12 | 1.13e-11 | pass |
| sampleSelection ML + sandwich package | SE (OPG) regime_1:(Intercept) | 0.052506 | 0.052506 | 6.39e-12 | 1.22e-10 | pass |
| sampleSelection ML + sandwich package | SE (OPG) regime_1:x1 | 0.0294512 | 0.0294512 | 3.89e-13 | 1.32e-11 | pass |
| sampleSelection ML + sandwich package | SE (OPG) regime_1:x2 | 0.025849 | 0.025849 | 4.38e-13 | 1.70e-11 | pass |
| sampleSelection ML + sandwich package | SE (OPG) regime_1:sigma | 0.0372553 | 0.0372553 | -2.17e-13 | 5.83e-12 | pass |
| sampleSelection ML + sandwich package | SE (OPG) regime_1:rho | 0.0661504 | 0.0661504 | 2.02e-11 | 3.05e-10 | pass |
| sampleSelection ML + sandwich package | SE (cluster) selection:(Intercept) | 0.0621488 | 0.0621488 | -3.13e-14 | 5.03e-13 | pass |
| sampleSelection ML + sandwich package | SE (cluster) selection:x1 | 0.0517358 | 0.0517358 | 2.05e-13 | 3.97e-12 | pass |
| sampleSelection ML + sandwich package | SE (cluster) selection:z1 | 0.0429743 | 0.0429743 | 1.30e-12 | 3.02e-11 | pass |
| sampleSelection ML + sandwich package | SE (cluster) regime_0:(Intercept) | 0.253008 | 0.253008 | -3.47e-12 | 1.37e-11 | pass |
| sampleSelection ML + sandwich package | SE (cluster) regime_0:x1 | 0.0760304 | 0.0760304 | -5.03e-13 | 6.62e-12 | pass |
| sampleSelection ML + sandwich package | SE (cluster) regime_0:x2 | 0.0345852 | 0.0345852 | -9.92e-16 | 2.86e-14 | pass |
| sampleSelection ML + sandwich package | SE (cluster) regime_0:sigma | 0.0514383 | 0.0514383 | -1.04e-12 | 2.03e-11 | pass |
| sampleSelection ML + sandwich package | SE (cluster) regime_0:rho | 0.200609 | 0.200609 | -2.57e-12 | 1.28e-11 | pass |
| sampleSelection ML + sandwich package | SE (cluster) regime_1:(Intercept) | 0.0923142 | 0.0923142 | 2.43e-11 | 2.64e-10 | pass |
| sampleSelection ML + sandwich package | SE (cluster) regime_1:x1 | 0.0622395 | 0.0622395 | 2.81e-12 | 4.52e-11 | pass |
| sampleSelection ML + sandwich package | SE (cluster) regime_1:x2 | 0.02396 | 0.02396 | 2.03e-14 | 8.46e-13 | pass |
| sampleSelection ML + sandwich package | SE (cluster) regime_1:sigma | 0.0550999 | 0.0550999 | 1.47e-11 | 2.67e-10 | pass |
| sampleSelection ML + sandwich package | SE (cluster) regime_1:rho | 0.0850731 | 0.0850731 | 5.78e-11 | 6.79e-10 | pass |
| sampleSelection ML + sandwich package | selection:(Intercept) (fit with sandwich) | 0.484565 | 0.484565 | 7.83e-13 | 7.83e-13 | pass |
| sampleSelection ML + sandwich package | selection:x1 (fit with sandwich) | 0.268508 | 0.268508 | -4.95e-13 | 4.95e-13 | pass |
| sampleSelection ML + sandwich package | selection:z1 (fit with sandwich) | -0.397478 | -0.397478 | -6.17e-12 | 6.17e-12 | pass |
| sampleSelection ML + sandwich package | regime_0:(Intercept) (fit with sandwich) | 0.948236 | 0.948236 | -5.14e-12 | 5.14e-12 | pass |
| sampleSelection ML + sandwich package | regime_0:x1 (fit with sandwich) | 0.427323 | 0.427323 | -9.87e-13 | 9.87e-13 | pass |
| sampleSelection ML + sandwich package | regime_0:x2 (fit with sandwich) | 0.233003 | 0.233003 | 1.06e-14 | 1.06e-14 | pass |
| sampleSelection ML + sandwich package | regime_0:sigma (fit with sandwich) | 1.02041 | 1.02041 | -9.68e-13 | 9.49e-13 | pass |
| sampleSelection ML + sandwich package | regime_0:rho (fit with sandwich) | 0.300763 | 0.300763 | -4.35e-12 | 4.35e-12 | pass |
| sampleSelection ML + sandwich package | regime_1:(Intercept) (fit with sandwich) | 1.39636 | 1.39636 | 4.91e-11 | 3.51e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:x1 (fit with sandwich) | 0.764816 | 0.764816 | -1.17e-11 | 1.17e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:x2 (fit with sandwich) | 0.37852 | 0.37852 | -9.27e-15 | 9.27e-15 | pass |
| sampleSelection ML + sandwich package | regime_1:sigma (fit with sandwich) | 1.05726 | 1.05726 | -2.83e-11 | 2.68e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:rho (fit with sandwich) | 0.685603 | 0.685603 | -7.86e-11 | 7.86e-11 | pass |
| sampleSelection ML + sandwich package | selection:(Intercept) (fit with opg) | 0.484565 | 0.484565 | 7.83e-13 | 7.83e-13 | pass |
| sampleSelection ML + sandwich package | selection:x1 (fit with opg) | 0.268508 | 0.268508 | -4.95e-13 | 4.95e-13 | pass |
| sampleSelection ML + sandwich package | selection:z1 (fit with opg) | -0.397478 | -0.397478 | -6.17e-12 | 6.17e-12 | pass |
| sampleSelection ML + sandwich package | regime_0:(Intercept) (fit with opg) | 0.948236 | 0.948236 | -5.14e-12 | 5.14e-12 | pass |
| sampleSelection ML + sandwich package | regime_0:x1 (fit with opg) | 0.427323 | 0.427323 | -9.87e-13 | 9.87e-13 | pass |
| sampleSelection ML + sandwich package | regime_0:x2 (fit with opg) | 0.233003 | 0.233003 | 1.06e-14 | 1.06e-14 | pass |
| sampleSelection ML + sandwich package | regime_0:sigma (fit with opg) | 1.02041 | 1.02041 | -9.68e-13 | 9.49e-13 | pass |
| sampleSelection ML + sandwich package | regime_0:rho (fit with opg) | 0.300763 | 0.300763 | -4.35e-12 | 4.35e-12 | pass |
| sampleSelection ML + sandwich package | regime_1:(Intercept) (fit with opg) | 1.39636 | 1.39636 | 4.91e-11 | 3.51e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:x1 (fit with opg) | 0.764816 | 0.764816 | -1.17e-11 | 1.17e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:x2 (fit with opg) | 0.37852 | 0.37852 | -9.27e-15 | 9.27e-15 | pass |
| sampleSelection ML + sandwich package | regime_1:sigma (fit with opg) | 1.05726 | 1.05726 | -2.83e-11 | 2.68e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:rho (fit with opg) | 0.685603 | 0.685603 | -7.86e-11 | 7.86e-11 | pass |
| sampleSelection ML + sandwich package | selection:(Intercept) (fit with cluster) | 0.484565 | 0.484565 | 7.83e-13 | 7.83e-13 | pass |
| sampleSelection ML + sandwich package | selection:x1 (fit with cluster) | 0.268508 | 0.268508 | -4.95e-13 | 4.95e-13 | pass |
| sampleSelection ML + sandwich package | selection:z1 (fit with cluster) | -0.397478 | -0.397478 | -6.17e-12 | 6.17e-12 | pass |
| sampleSelection ML + sandwich package | regime_0:(Intercept) (fit with cluster) | 0.948236 | 0.948236 | -5.14e-12 | 5.14e-12 | pass |
| sampleSelection ML + sandwich package | regime_0:x1 (fit with cluster) | 0.427323 | 0.427323 | -9.87e-13 | 9.87e-13 | pass |
| sampleSelection ML + sandwich package | regime_0:x2 (fit with cluster) | 0.233003 | 0.233003 | 1.06e-14 | 1.06e-14 | pass |
| sampleSelection ML + sandwich package | regime_0:sigma (fit with cluster) | 1.02041 | 1.02041 | -9.68e-13 | 9.49e-13 | pass |
| sampleSelection ML + sandwich package | regime_0:rho (fit with cluster) | 0.300763 | 0.300763 | -4.35e-12 | 4.35e-12 | pass |
| sampleSelection ML + sandwich package | regime_1:(Intercept) (fit with cluster) | 1.39636 | 1.39636 | 4.91e-11 | 3.51e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:x1 (fit with cluster) | 0.764816 | 0.764816 | -1.17e-11 | 1.17e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:x2 (fit with cluster) | 0.37852 | 0.37852 | -9.27e-15 | 9.27e-15 | pass |
| sampleSelection ML + sandwich package | regime_1:sigma (fit with cluster) | 1.05726 | 1.05726 | -2.83e-11 | 2.68e-11 | pass |
| sampleSelection ML + sandwich package | regime_1:rho (fit with cluster) | 0.685603 | 0.685603 | -7.86e-11 | 7.86e-11 | pass |
