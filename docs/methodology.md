# Methodology: Regression Discontinuity Design Implementation

## Overview

This document provides technical details on the econometric methodology used to evaluate the impact of Colombia's Ingreso Solidario program on financial inclusion outcomes.

## Research Design: Regression Discontinuity

### Program Background

The **Ingreso Solidario** program was launched in April 2020 as Colombia's emergency response to COVID-19. It provided unconditional cash transfers to vulnerable households not covered by other social programs.

**Key features**:
- Monthly transfers of ~160,000 COP ($40-50 USD at 2020 rates)
- Delivered through MOVii digital wallets (e-money accounts)
- Eligibility determined by SISBEN poverty score
- Created natural experiment for studying financial technology adoption

### Identification Strategy

#### Running Variable: SISBEN Score

The **SISBEN III** (Sistema de Identificación de Potenciales Beneficiarios de Programas Sociales) is Colombia's poverty targeting system:

- Composite score from 0-100 scale
- Based on household demographics, assets, housing, education
- Collected through census-style household surveys
- Used for multiple social program eligibility determinations

#### Treatment Assignment Rule

**Cutoff**: SISBEN score = 0.038

- Households with SISBEN score < 0.038: **Eligible** for Ingreso Solidario
- Households with SISBEN score ≥ 0.038: **Not eligible**

This sharp discontinuity in eligibility creates the identification strategy.

#### Key Assumptions

**RDD Validity Requirements**:

1. **Continuity of potential outcomes**: In absence of treatment, outcomes should be continuous at cutoff
2. **No manipulation**: Households cannot precisely manipulate their SISBEN score around cutoff
3. **Local randomization**: Households just below/above cutoff are comparable (as-if randomized)

**Tested through**:
- Density tests (McCrary, 2008; Cattaneo et al., 2018)
- Covariate balance checks
- Falsification tests on predetermined variables

## Econometric Specifications

### Sharp RDD: Intent-to-Treat (ITT)

Estimates the effect of program **eligibility** on outcomes.

**Basic specification**:

```
Y_i = α + τ·D_i + f(SISBEN_i - c) + β·D_i·f(SISBEN_i - c) + ε_i
```

Where:
- `Y_i`: Outcome for individual i (balance, transactions, etc.)
- `D_i`: Treatment indicator (1 if SISBEN_i < 0.038, 0 otherwise)
- `SISBEN_i`: Running variable (poverty score)
- `c`: Cutoff (0.038)
- `f(·)`: Polynomial function of centered running variable
- `τ`: **Treatment effect parameter** (ITT)

**Implementation details**:
- Local linear regression (polynomial order = 1)
- Triangular kernel weighting
- Optimal bandwidth selection using MSE-optimal procedure (Calonico et al., 2014)
- Robust bias-corrected confidence intervals
- Clustering at individual level for panel data

**Stata code**:
```stata
rdrobust outcome sisben_score, c(0.038) kernel(triangular) p(1) ///
    vce(cluster user_id) all
```

### Fuzzy RDD: Local Average Treatment Effect (LATE)

Accounts for imperfect compliance in treatment assignment.

**Why fuzzy?**
- Not all eligible households received transfers (non-compliance)
- Some ineligible households received transfers (inclusion errors)
- Treatment assignment ≠ actual treatment receipt

**First stage**: Effect of eligibility on treatment receipt

```
T_i = π_0 + π_1·D_i + g(SISBEN_i - c) + θ·D_i·g(SISBEN_i - c) + u_i
```

Where `T_i` = 1 if actually received transfers, 0 otherwise

**Second stage**: IV regression of outcome on treatment

```
Y_i = γ + δ·T̂_i + f(SISBEN_i - c) + β·D_i·f(SISBEN_i - c) + ν_i
```

Where:
- `T̂_i`: Predicted treatment from first stage
- `δ`: **Treatment effect parameter** (LATE)

**Interpretation**: Effect of actually receiving transfers for compliers (those induced to receive by eligibility)

**Stata code**:
```stata
rdrobust outcome sisben_score, c(0.038) kernel(triangular) p(1) ///
    fuzzy(treatment_received) vce(cluster user_id) all
```

### Panel Data Specification

Exploits 24-month longitudinal structure (April 2020 - March 2022).

**Month-by-month RDD**:

```
Y_it = α_t + τ_t·D_i + f_t(SISBEN_i - c) + β_t·D_i·f_t(SISBEN_i - c) + ε_it
```

Run separately for each month `t`, yielding dynamic treatment effects `{τ_1, τ_2, ..., τ_24}`

**Panel fixed effects model**:

```
Y_it = α_i + λ_t + τ·(D_i × POST_t) + f(SISBEN_i - c) + X_it'Γ + ε_it
```

Where:
- `α_i`: Individual fixed effects
- `λ_t`: Time fixed effects
- `POST_t`: Indicator for post-treatment period
- `X_it`: Time-varying controls

**Advantages**:
- Controls for time-invariant unobservables
- Examines heterogeneity in effects over time
- Tests persistence of impacts

## Bandwidth Selection

### MSE-Optimal Bandwidth

Following Calonico, Cattaneo, and Titiunik (2014), we use data-driven bandwidth selection:

**Objective**: Minimize Mean Squared Error of RDD estimator

```
h_opt = argmin MSE(τ̂(h))
```

Balances:
- **Bias** (decreases with smaller bandwidth → more local)
- **Variance** (increases with smaller bandwidth → fewer observations)

**Implementation**:
- `rdbwselect` command in Stata
- Separate bandwidths for sharp and fuzzy RDD
- Bandwidth varies by outcome variable

### Sensitivity Analysis

Test robustness to bandwidth choice:
- 0.5 × h_opt (more local, smaller sample)
- 1.5 × h_opt (less local, larger sample)
- Fixed bandwidths: 0.01, 0.02, 0.03, 0.04

Results should be stable across reasonable bandwidth range.

## Outcome Variables

### Primary Outcomes

**Financial inclusion indicators**:

1. **Account Balance** (`saldo`): End-of-month balance in MOVii wallet (COP)
   - Measures savings/liquidity retention

2. **Total Transactions** (`trx_total`): Monthly count of all transactions
   - Measures active account usage

3. **Transfer Usage** (`trx_envios`): Monthly count of person-to-person transfers
   - Measures financial intermediation behavior

4. **Cash-Out Transactions** (`trx_retiros`): Monthly withdrawals to cash
   - Baseline behavior (converting digital to physical money)

5. **Purchase Transactions** (`trx_compras`): Monthly purchases at merchants
   - Advanced digital payment adoption

6. **Cash-In Transactions** (`trx_depositos`): Monthly deposits to wallet
   - Proactive account funding beyond transfers

### Secondary Outcomes

- Transaction amounts (in addition to counts)
- Service diversification indices
- Account dormancy indicators
- Geographic transaction patterns

### Outcome Transformations

Given skewed distributions:
- **Inverse hyperbolic sine (IHS)**: `asinh(x) = log(x + sqrt(x² + 1))`
  - Handles zeros
  - Approximates log for large values
  - Interpretable as percentage changes

## Sample Restrictions

### Inclusion Criteria

1. **MOVii account holders**: Have digital wallet (944,985 users)
2. **DNP eligibility data**: Matched to SISBEN records (1,048,575 obs)
3. **Complete SISBEN score**: Non-missing running variable
4. **Valid transaction data**: At least one month of observed transactions

### Bandwidth-Based Sample

RDD uses **local** sample around cutoff:
- Include observations within h_opt of cutoff
- Typical bandwidth: ±0.01 to ±0.03 around c = 0.038
- Effective sample: ~50,000-150,000 observations (varies by outcome/bandwidth)

### Data Quality Filters

- Exclude outliers >99th percentile in transaction amounts (winsorizing)
- Exclude users with data quality flags from MOVii
- Exclude observations with imputed SISBEN scores

## Robustness Checks

### 1. Falsification Tests

**Test**: RDD on predetermined covariates (should find null effects)

Variables tested:
- Age
- Gender
- Municipality
- Household size
- Educational level

If significant effects found → suggests sorting/manipulation at cutoff

### 2. Placebo Tests

**Test**: RDD at artificial cutoffs away from true threshold

Placebo cutoffs:
- c = 0.028 (0.01 below true cutoff)
- c = 0.048 (0.01 above true cutoff)
- c = 0.018, 0.058 (further away)

Should find null effects at placebo cutoffs.

### 3. Density Tests

**McCrary (2008) test**: Smooth density of running variable at cutoff

**Procedure**:
1. Estimate density to left and right of cutoff
2. Test for discontinuous jump
3. Rejection → evidence of manipulation

**Implementation**: `rddensity` command (Cattaneo et al., 2018)

### 4. Functional Form

Test sensitivity to polynomial order:
- Linear (p=1) - **preferred, less bias**
- Quadratic (p=2)
- Cubic (p=3)

Higher-order polynomials can introduce bias (Gelman & Imbens, 2019).

### 5. Kernel Choice

Compare different weighting kernels:
- Triangular (default)
- Uniform
- Epanechnikov

Results generally robust to kernel choice.

## Standard Errors

### Clustering

**Level**: Individual user (`user_id`)

**Rationale**:
- Panel data: multiple observations per user
- Errors likely correlated within user over time
- Conservative approach to inference

### Robust Bias Correction

Using Calonico et al. (2014) robust bias-corrected confidence intervals:
- Corrects for bias from polynomial approximation
- Provides valid inference in finite samples

## Software Implementation

### Stata Packages

**Required**:
```stata
ssc install rdrobust
ssc install rddensity
ssc install rdlocrand
ssc install lpdensity
ssc install estout
```

**Versions used**:
- Stata 16.1
- rdrobust 1.0
- rddensity 2.2

### Key Commands

**Sharp RDD**:
```stata
rdrobust outcome running_var, c(0.038) kernel(tri) p(1) ///
    vce(cluster id) all bwselect(mserd)
```

**Fuzzy RDD**:
```stata
rdrobust outcome running_var, c(0.038) kernel(tri) p(1) ///
    fuzzy(treatment) vce(cluster id) all bwselect(mserd)
```

**Density test**:
```stata
rddensity running_var, c(0.038) plot
```

**Bandwidth selection**:
```stata
rdbwselect outcome running_var, c(0.038) kernel(tri) p(1) ///
    bwselect(mserd) all
```

## Interpretation Guide

### Effect Sizes

**ITT effects** (Sharp RDD):
- Intention-to-treat: Effect of being eligible
- Policy-relevant: What program achieves with imperfect compliance
- Lower bound on treatment effect

**LATE effects** (Fuzzy RDD):
- Effect of actually receiving treatment
- For compliers only (not whole population)
- Larger magnitude than ITT (scales up by compliance rate)

### Statistical Significance

- **Conventional inference**: Robust bias-corrected p-values
- **Cluster-robust SE**: Account for within-user correlation
- **Multiple testing**: Consider family-wise error rate when testing many outcomes

### Economic Significance

Compare effect magnitudes to:
- Pre-treatment means
- Transfer amounts (~160,000 COP/month)
- Typical transaction sizes
- Policy costs and benefits

## References

**RDD Methodology**:
- Calonico, S., Cattaneo, M. D., & Titiunik, R. (2014). Robust nonparametric confidence intervals for regression-discontinuity designs. *Econometrica*, 82(6), 2295-2326.
- Cattaneo, M. D., Jansson, M., & Ma, X. (2018). Manipulation testing based on density discontinuity. *The Stata Journal*, 18(1), 234-261.
- Gelman, A., & Imbens, G. (2019). Why high-order polynomials should not be used in regression discontinuity designs. *Journal of Business & Economic Statistics*, 37(3), 447-456.
- McCrary, J. (2008). Manipulation of the running variable in the regression discontinuity design. *Journal of Econometrics*, 142(2), 698-714.

**Financial Inclusion Context**:
- Bachas, P., Gertler, P., Higgins, S., & Seira, E. (2021). How debit cards enable the poor to save more. *Journal of Finance*, 76(4), 1913-1957.
- Jack, W., & Suri, T. (2014). Risk sharing and transactions costs: Evidence from Kenya's mobile money revolution. *American Economic Review*, 104(1), 183-223.

**Colombia SISBEN System**:
- DNP - Departamento Nacional de Planeación. (2011). *SISBEN III Methodology*.
