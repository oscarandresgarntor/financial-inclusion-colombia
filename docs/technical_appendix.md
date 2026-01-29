# Technical Appendix: Econometric Specifications

## Contents

1. [Regression Equations](#regression-equations)
2. [Estimation Procedures](#estimation-procedures)
3. [Inference Methods](#inference-methods)
4. [Software Specifications](#software-specifications)
5. [Computational Details](#computational-details)

---

## Regression Equations

### 1. Sharp RDD: Basic Specification

**Intent-to-Treat (ITT) effect**:

$$Y_i = \alpha + \tau \cdot D_i + \beta_1 (S_i - c) + \beta_2 D_i (S_i - c) + \varepsilon_i$$

Where:
- $Y_i$: Outcome for individual $i$
- $D_i = \mathbb{1}[S_i < c]$: Treatment indicator (1 if SISBEN score below cutoff)
- $S_i$: SISBEN poverty score (running variable)
- $c = 0.038$: Eligibility cutoff
- $(S_i - c)$: Centered running variable
- $\tau$: **ITT treatment effect**
- $\varepsilon_i$: Error term

**Stata implementation**:
```stata
* Basic RDD regression
reg outcome i.elegible##c.sisben_centrado if abs(sisben_centrado) <= h, ///
    robust cluster(user_id)
```

### 2. Sharp RDD: Polynomial Specifications

**Linear (p=1)** - Preferred:
$$Y_i = \alpha + \tau D_i + \beta_1 (S_i - c) + \beta_2 D_i (S_i - c) + \varepsilon_i$$

**Quadratic (p=2)** - Robustness:
$$Y_i = \alpha + \tau D_i + \sum_{j=1}^{2} [\beta_j (S_i - c)^j + \gamma_j D_i (S_i - c)^j] + \varepsilon_i$$

**Cubic (p=3)** - Additional robustness:
$$Y_i = \alpha + \tau D_i + \sum_{j=1}^{3} [\beta_j (S_i - c)^j + \gamma_j D_i (S_i - c)^j] + \varepsilon_i$$

**Stata implementation**:
```stata
* Generate polynomial terms
gen sisben_sq = sisben_centrado^2
gen sisben_cu = sisben_centrado^3

* Quadratic specification
reg outcome i.elegible##(c.sisben_centrado c.sisben_sq) if abs(sisben_centrado) <= h, ///
    robust cluster(user_id)
```

### 3. Sharp RDD with rdrobust

**Optimal bandwidth and bias correction**:

Using Calonico, Cattaneo, Titiunik (2014) methodology:

$$\hat{\tau}_{RD} = \hat{Y}^+(c) - \hat{Y}^-(c)$$

Where:
- $\hat{Y}^+(c)$: Extrapolated outcome at cutoff from right
- $\hat{Y}^-(c)$: Extrapolated outcome at cutoff from left

**Stata implementation**:
```stata
rdrobust outcome sisben_score, ///
    c(0.038) ///                      // Cutoff
    kernel(triangular) ///            // Kernel function
    p(1) ///                          // Polynomial order
    bwselect(mserd) ///               // MSE-optimal bandwidth
    vce(cluster user_id) ///          // Clustered SE
    all                               // Display all output
```

### 4. Fuzzy RDD: Two-Stage Specification

**First stage** (effect of eligibility on treatment receipt):

$$T_i = \pi_0 + \pi_1 D_i + \theta_1 (S_i - c) + \theta_2 D_i (S_i - c) + u_i$$

Where:
- $T_i$: Actual treatment receipt (1 if received transfers, 0 otherwise)
- $\pi_1$: **First-stage effect** (compliance rate)

**Second stage** (effect of treatment on outcome):

$$Y_i = \gamma + \delta \hat{T}_i + \beta_1 (S_i - c) + \beta_2 D_i (S_i - c) + \nu_i$$

Where:
- $\hat{T}_i$: Predicted treatment from first stage
- $\delta$: **LATE treatment effect** (for compliers)

**Relationship**: $\delta = \tau / \pi_1$ (ITT / first-stage)

**Stata implementation**:
```stata
* Manual 2SLS
ivregress 2sls outcome (tratado = elegible) sisben_centrado ///
    i.elegible#c.sisben_centrado if abs(sisben_centrado) <= h, ///
    robust cluster(user_id) first

* Using rdrobust
rdrobust outcome sisben_score, ///
    c(0.038) ///
    fuzzy(tratado) ///                // Fuzzy treatment variable
    kernel(triangular) ///
    p(1) ///
    bwselect(mserd) ///
    vce(cluster user_id) ///
    all
```

### 5. Panel RDD: Month-by-Month Specification

**Separate RDD for each time period $t$**:

$$Y_{it} = \alpha_t + \tau_t D_i + \beta_{1t} (S_i - c) + \beta_{2t} D_i (S_i - c) + \varepsilon_{it}$$

Yields dynamic treatment effects: $\{\tau_1, \tau_2, ..., \tau_{24}\}$

**Stata implementation**:
```stata
* Loop over months
forvalues t = 1/24 {
    rdrobust outcome sisben_score if period == `t', ///
        c(0.038) kernel(tri) p(1) vce(cluster user_id)

    * Store coefficient
    matrix tau[`t',1] = e(tau_cl)
    matrix se[`t',1] = e(se_tau_cl)
}
```

### 6. Panel Fixed Effects Model

**Two-way fixed effects with RDD**:

$$Y_{it} = \alpha_i + \lambda_t + \tau (D_i \times POST_t) + \beta_1 (S_i - c) + \beta_2 D_i (S_i - c) + X_{it}'\Gamma + \varepsilon_{it}$$

Where:
- $\alpha_i$: Individual fixed effects
- $\lambda_t$: Time fixed effects
- $POST_t$: Post-treatment indicator
- $X_{it}$: Time-varying controls

**Stata implementation**:
```stata
* Generate treatment × post interaction
gen treat_post = elegible * post

* Panel FE regression
xtreg outcome treat_post sisben_centrado i.elegible#c.sisben_centrado ///
    i.month if abs(sisben_centrado) <= h, ///
    fe vce(cluster user_id)
```

### 7. Heterogeneity Analysis

**Effect heterogeneity by subgroup $G$**:

$$Y_i = \alpha + \tau_1 D_i + \tau_2 (D_i \times G_i) + \beta_1 (S_i - c) + \beta_2 D_i (S_i - c) + \gamma G_i + \varepsilon_i$$

Where:
- $\tau_1$: Treatment effect for reference group
- $\tau_2$: Differential effect for group $G$
- Total effect for group $G$: $\tau_1 + \tau_2$

**Subgroups examined**:
- Gender (male vs. female)
- Age (young vs. old)
- Urban vs. rural
- Region
- Pre-treatment account activity

**Stata implementation**:
```stata
rdrobust outcome sisben_score if genero == 1, c(0.038) // Males
rdrobust outcome sisben_score if genero == 2, c(0.038) // Females

* Test difference
suest male_model female_model
test [male_model]tau_cl = [female_model]tau_cl
```

---

## Estimation Procedures

### Bandwidth Selection

**MSE-optimal bandwidth** (Calonico et al., 2014):

$$h_{MSE} = \arg\min_{h} E[(\hat{\tau}(h) - \tau)^2]$$

Minimizes:
- **Squared bias**: $[E(\hat{\tau}(h)) - \tau]^2$
- **Variance**: $Var(\hat{\tau}(h))$

**Coverage-error-optimal bandwidth** (CER):

Minimizes coverage error of confidence interval:

$$h_{CER} = \arg\min_{h} |Coverage(\hat{\tau}(h)) - 0.95|$$

**Stata implementation**:
```stata
* MSE-optimal (default)
rdbwselect outcome sisben_score, c(0.038) kernel(tri) p(1) bwselect(mserd)

* CER-optimal
rdbwselect outcome sisben_score, c(0.038) kernel(tri) p(1) bwselect(cerrd)

* Store bandwidth
local h = e(h_mserd)
```

### Kernel Functions

**Triangular kernel** (preferred):

$$K(u) = \begin{cases}
(1 - |u|) & \text{if } |u| \leq 1 \\
0 & \text{otherwise}
\end{cases}$$

Where $u = (S_i - c) / h$

**Epanechnikov kernel**:

$$K(u) = \begin{cases}
0.75(1 - u^2) & \text{if } |u| \leq 1 \\
0 & \text{otherwise}
\end{cases}$$

**Uniform kernel**:

$$K(u) = \begin{cases}
0.5 & \text{if } |u| \leq 1 \\
0 & \text{otherwise}
\end{cases}$$

**Stata implementation**:
```stata
* Triangular (default)
rdrobust outcome sisben_score, c(0.038) kernel(triangular)

* Epanechnikov
rdrobust outcome sisben_score, c(0.038) kernel(epanechnikov)

* Uniform
rdrobust outcome sisben_score, c(0.038) kernel(uniform)
```

### Bias Correction

**Robust bias-corrected estimator** (Calonico et al., 2014):

$$\hat{\tau}_{bc} = \hat{\tau} - \hat{Bias}(\hat{\tau})$$

Uses higher-order polynomial to estimate bias term.

**Implementation**: Automatically applied in `rdrobust` with `all` option.

---

## Inference Methods

### Standard Errors

**Heteroskedasticity-robust**:

$$\hat{V}_{HC}(\hat{\tau}) = (X'X)^{-1} X' \hat{\Omega} X (X'X)^{-1}$$

Where $\hat{\Omega} = diag(\hat{\varepsilon}_i^2)$

**Cluster-robust** (at user level):

$$\hat{V}_{CL}(\hat{\tau}) = (X'X)^{-1} \left(\sum_{g=1}^{G} X_g' \hat{\varepsilon}_g \hat{\varepsilon}_g' X_g\right) (X'X)^{-1}$$

Where $g$ indexes clusters (users).

**Stata implementation**:
```stata
* Heteroskedasticity-robust
rdrobust outcome sisben_score, c(0.038) vce(hc2)

* Cluster-robust (preferred)
rdrobust outcome sisben_score, c(0.038) vce(cluster user_id)
```

### Confidence Intervals

**Conventional CI** (may undercover):

$$\hat{\tau} \pm 1.96 \times SE(\hat{\tau})$$

**Robust bias-corrected CI** (preferred):

$$\hat{\tau}_{bc} \pm 1.96 \times SE_{rb}(\hat{\tau})$$

Uses robust standard error accounting for bias correction.

**Implementation**: `rdrobust` reports both conventional and robust CI.

### Hypothesis Testing

**Null hypothesis**: $H_0: \tau = 0$ (no treatment effect)

**Test statistic**:

$$t = \frac{\hat{\tau}_{bc}}{SE_{rb}(\hat{\tau})}$$

**P-value**: $p = 2\Phi(-|t|)$ where $\Phi$ is standard normal CDF

**Critical values**:
- 10% level: |t| > 1.645
- 5% level: |t| > 1.96
- 1% level: |t| > 2.576

### Multiple Testing Correction

When testing multiple outcomes, adjust for family-wise error rate:

**Bonferroni correction**:

$$\alpha_{adjusted} = \frac{\alpha}{m}$$

Where $m$ is number of outcomes tested.

**False Discovery Rate (FDR)**:

Benjamini-Hochberg procedure for controlling FDR at level $q$.

**Stata implementation**:
```stata
* Store p-values from multiple tests
matrix pvals = (0.01, 0.03, 0.08, 0.15, ...)

* Bonferroni
matrix bonf = pvals * scalar(m)

* FDR (requires user-written command)
multtest, pvals(pvals) method(bh) alpha(0.05)
```

---

## Software Specifications

### Stata Version

**Required**: Stata 16 or higher (MP, SE, or IC)

**Packages**:

```stata
* Install required packages
ssc install rdrobust, replace
ssc install rddensity, replace
ssc install rdlocrand, replace
ssc install lpdensity, replace
ssc install estout, replace
ssc install winsor2, replace
ssc install distinct, replace
```

**Package versions used**:
- `rdrobust` version 1.0 (September 2021)
- `rddensity` version 2.2 (March 2020)
- `estout` version 3.25 (January 2020)

### Python Version

**Required**: Python 3.8 or higher

**Key packages**:
```
pandas==1.3.5
numpy==1.21.6
matplotlib==3.5.3
geopandas==0.9.0
jupyterlab==3.2.9
```

Install via:
```bash
pip install -r requirements.txt
```

### R (Optional)

For additional robustness checks:

```r
install.packages("rdrobust")
install.packages("rddensity")
install.packages("rdlocrand")
```

---

## Computational Details

### Memory Requirements

**Stata**:
- Minimum: 4GB RAM
- Recommended: 8GB+ RAM for full dataset
- Synthetic data: 1GB sufficient

**Set memory**:
```stata
set maxvar 10000
set matsize 10000
set niceness 5
```

### Parallel Processing

**Stata MP**: Utilize multiple cores for faster computation

```stata
set processors 4  // Use 4 cores
```

**Python**: Use multiprocessing for Monte Carlo simulations

```python
from multiprocessing import Pool
pool = Pool(processes=4)
```

### Numerical Precision

**Tolerances**:
- Convergence tolerance: 1e-6
- Optimization tolerance: 1e-8

**Stata settings**:
```stata
set type double  // Use double precision
set seed 42      // Set random seed for reproducibility
```

### Optimization

**rdrobust** uses:
- Interior-point algorithms for bandwidth optimization
- Numerical derivatives via finite differences
- Gradient descent for bias estimation

**Convergence criteria**:
- Maximum iterations: 100
- Tolerance: 1e-6

### Reproducibility

**Random seed setting**:

```stata
set seed 20230915  // Fixed seed for all analyses
```

**Version control**:
- All code in Git repository
- Package versions documented
- Data version stamps

### Performance Notes

**Full analysis runtime** (actual data):
- Data cleaning: ~2 hours
- Descriptive statistics: ~30 minutes
- RDD analysis: ~3 hours
- Robustness tests: ~4 hours
- **Total**: ~10 hours on 16GB RAM, 4-core machine

**Synthetic data runtime**:
- All analyses: ~15 minutes (much smaller dataset)

### Error Handling

**Common issues**:

1. **Insufficient observations in bandwidth**:
   - Solution: Increase bandwidth or check data
   ```stata
   rdrobust outcome sisben_score, c(0.038) bwselect(mserd) all
   if e(N_h_l) < 50 | e(N_h_r) < 50 {
       display "Warning: Small sample in bandwidth"
   }
   ```

2. **Non-convergence**:
   - Solution: Simplify polynomial order or kernel
   ```stata
   rdrobust outcome sisben_score, c(0.038) p(1) // Use linear instead of quadratic
   ```

3. **Perfect collinearity**:
   - Solution: Check for redundant variables
   ```stata
   _rmcoll varlist, forcedrop
   ```

### Output Management

**Store results**:

```stata
* Store estimates
estimates store model_1

* Export to table
esttab model_1 using "output/tables/results.tex", ///
    replace label booktabs ///
    se star(* 0.10 ** 0.05 *** 0.01)

* Export to Excel
putexcel set "output/tables/results.xlsx", replace
putexcel A1 = "Treatment Effect"
putexcel B1 = (_b[RD_Estimate])
```

### Diagnostic Checks

**Post-estimation**:

```stata
* Check bandwidth
display "Optimal bandwidth: " e(h_mserd)

* Check sample size
display "Observations in bandwidth: " e(N_h_l) + e(N_h_r)

* Check first-stage (fuzzy RDD)
display "First-stage F-stat: " e(first_stage_F)
```

---

## References

**Econometric Theory**:

- Calonico, S., Cattaneo, M. D., & Titiunik, R. (2014). Robust nonparametric confidence intervals for regression-discontinuity designs. *Econometrica*, 82(6), 2295-2326.

- Cattaneo, M. D., Jansson, M., & Ma, X. (2020). Simple local polynomial density estimators. *Journal of the American Statistical Association*, 115(531), 1449-1455.

- Imbens, G. W., & Lemieux, T. (2008). Regression discontinuity designs: A guide to practice. *Journal of Econometrics*, 142(2), 615-635.

- Lee, D. S., & Lemieux, T. (2010). Regression discontinuity designs in economics. *Journal of Economic Literature*, 48(2), 281-355.

**Software Documentation**:

- Calonico, S., Cattaneo, M. D., Farrell, M. H., & Titiunik, R. (2019). Regression discontinuity designs using covariates. *Review of Economics and Statistics*, 101(3), 442-451.

- Cattaneo, M. D., Idrobo, N., & Titiunik, R. (2020). *A Practical Introduction to Regression Discontinuity Designs: Foundations*. Cambridge University Press.

**Stata Command References**:

- `help rdrobust`
- `help rddensity`
- `help rdplot`
- `help rdbwselect`

---

## Contact

For technical questions about implementation:
- **Author**: Oscar Andrés Garnica Toro
- **Email**: [your-email@domain.com]
- **GitHub Issues**: [Repository URL]/issues
