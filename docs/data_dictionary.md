# Data Dictionary

This document provides comprehensive documentation of all variables used in the financial inclusion analysis.

## Data Sources

### 1. DNP (Departamento Nacional de Planeación) - Eligibility Data

**Source**: National Planning Department administrative records
**Coverage**: 1,048,575 observations
**Time period**: April 2020
**Purpose**: Program eligibility determination based on SISBEN scores

### 2. MOVii - Transaction Data

**Source**: MOVii digital wallet administrative records
**Coverage**: 944,985 unique users
**Time period**: April 2020 - March 2022 (24 months)
**Purpose**: Financial behavior tracking via transaction-level data

## Variable Categories

## I. Identification Variables

### User Identifiers

| Variable | Type | Description | Source |
|----------|------|-------------|--------|
| `user_id` | String | Unique anonymous user identifier | MOVii |
| `documento` | String | National ID number (anonymized) | DNP |
| `cod_municipio` | Numeric | Municipality code (DANE standard) | DNP |
| `cod_departamento` | Numeric | Department code (DANE standard) | DNP |

**Note**: All personal identifiers encrypted/anonymized for privacy.

### Time Variables

| Variable | Type | Description | Range |
|----------|------|-------------|-------|
| `month` | Numeric | Calendar month | 1-12 |
| `year` | Numeric | Calendar year | 2020-2022 |
| `period` | Numeric | Period since program start | 1-24 |
| `date` | Date | Transaction date | Apr2020-Mar2022 |

## II. Treatment Variables

### Running Variable & Eligibility

| Variable | Type | Description | Values | Notes |
|----------|------|-------------|--------|-------|
| `puntaje_sisben` | Numeric | SISBEN III poverty score | 0-100 | Continuous score |
| `puntaje_centrado` | Numeric | Centered SISBEN score | - | `puntaje_sisben - 0.038` |
| `elegible` | Binary | Eligible for Ingreso Solidario | 0/1 | 1 if `puntaje_sisben < 0.038` |
| `tratado` | Binary | Actually received transfers | 0/1 | Fuzzy RDD treatment indicator |

**Key values**:
- **Cutoff**: 0.038
- **Bandwidth**: Varies by outcome (typically ±0.01 to ±0.03)

### Program Participation

| Variable | Type | Description | Values |
|----------|------|-------------|--------|
| `is_beneficiario` | Binary | Ingreso Solidario beneficiary | 0/1 |
| `monto_transferencia` | Numeric | Monthly transfer amount (COP) | 0-160,000 |
| `meses_recibido` | Numeric | Months with transfer received | 0-24 |
| `fecha_primer_giro` | Date | Date of first transfer | - |

## III. Outcome Variables

### Account Balance

| Variable | Type | Description | Unit | Transformation |
|----------|------|-------------|------|----------------|
| `saldo` | Numeric | End-of-month wallet balance | COP | - |
| `saldo_ihs` | Numeric | IHS-transformed balance | - | `asinh(saldo)` |
| `saldo_promedio` | Numeric | Average daily balance | COP | - |
| `saldo_max` | Numeric | Maximum balance in month | COP | - |

### Transaction Counts

| Variable | Type | Description | Unit |
|----------|------|-------------|------|
| `trx_total` | Numeric | Total transactions per month | Count |
| `trx_envios` | Numeric | Person-to-person transfers sent | Count |
| `trx_recibidos` | Numeric | Transfers received | Count |
| `trx_retiros` | Numeric | Cash withdrawals | Count |
| `trx_depositos` | Numeric | Cash-in deposits | Count |
| `trx_compras` | Numeric | Merchant purchases | Count |
| `trx_pagos` | Numeric | Bill payments | Count |
| `trx_recargas` | Numeric | Mobile airtime top-ups | Count |

### Transaction Amounts

| Variable | Type | Description | Unit |
|----------|------|-------------|------|
| `monto_envios` | Numeric | Total amount sent (transfers) | COP |
| `monto_retiros` | Numeric | Total withdrawn | COP |
| `monto_depositos` | Numeric | Total deposited | COP |
| `monto_compras` | Numeric | Total purchases | COP |
| `monto_total` | Numeric | Sum of all transaction amounts | COP |

**Transformations**:
- `_ihs`: Inverse hyperbolic sine transformation
- `_log`: Natural logarithm (for amounts >0)
- `_per_trx`: Average amount per transaction

### Activity Indicators

| Variable | Type | Description | Values |
|----------|------|-------------|--------|
| `cuenta_activa` | Binary | Any transaction in month | 0/1 |
| `cuenta_dormida` | Binary | No transactions for 3+ months | 0/1 |
| `usuario_nuevo` | Binary | First month of activity | 0/1 |
| `diversificacion` | Numeric | Number of transaction types used | 0-8 |

### Service Usage Patterns

| Variable | Type | Description | Calculation |
|----------|------|-------------|-------------|
| `ratio_retiros` | Numeric | Share of cash-out transactions | `trx_retiros / trx_total` |
| `ratio_compras` | Numeric | Share of purchase transactions | `trx_compras / trx_total` |
| `ratio_envios` | Numeric | Share of transfer transactions | `trx_envios / trx_total` |
| `indice_inclusion` | Numeric | Financial inclusion index | Composite score (0-100) |

## IV. Demographic Variables

### Individual Characteristics

| Variable | Type | Description | Values | Source |
|----------|------|-------------|--------|--------|
| `edad` | Numeric | Age in years | 18-100 | DNP |
| `genero` | Categorical | Gender | 1=Male, 2=Female | DNP |
| `estado_civil` | Categorical | Marital status | 1-5 | DNP |
| `nivel_educativo` | Categorical | Education level | 1-6 | DNP |
| `ocupacion` | Categorical | Occupation type | 1-10 | DNP |

**Education levels**:
1. No education
2. Primary incomplete
3. Primary complete
4. Secondary incomplete
5. Secondary complete
6. Higher education

### Household Characteristics

| Variable | Type | Description | Values | Source |
|----------|------|-------------|--------|--------|
| `tam_hogar` | Numeric | Household size | 1-15+ | DNP |
| `num_menores` | Numeric | Children under 18 | 0-10+ | DNP |
| `jefe_hogar` | Binary | Household head | 0/1 | DNP |
| `tipo_vivienda` | Categorical | Housing type | 1-5 | DNP |
| `estrato` | Numeric | Socioeconomic stratum | 1-6 | DNP |

**Stratum levels**:
1. Lowest income
2. Low income
3. Lower-middle income
4. Middle income
5. Upper-middle income
6. High income

### Geographic Variables

| Variable | Type | Description | Values |
|----------|------|-------------|--------|
| `departamento` | String | Department name | 32 departments |
| `municipio` | String | Municipality name | 1,100+ municipalities |
| `zona` | Categorical | Urban/rural | 1=Urban, 2=Rural |
| `region` | Categorical | Geographic region | 1=Andina, 2=Caribe, etc. |

**Regions**:
1. Andina (Andean)
2. Caribe (Caribbean)
3. Pacífico (Pacific)
4. Orinoquía (Orinoco)
5. Amazonía (Amazon)
6. Insular (Islands)

## V. Constructed Variables

### RDD-Specific Variables

| Variable | Type | Description | Calculation |
|----------|------|-------------|-------------|
| `dentro_bandwidth` | Binary | Within optimal bandwidth | Based on `rdbwselect` |
| `peso_kernel` | Numeric | Triangular kernel weight | Distance-based weight |
| `polynomial_1` | Numeric | Linear term | `puntaje_centrado` |
| `polynomial_2` | Numeric | Quadratic term | `puntaje_centrado²` |
| `interaccion_trat` | Numeric | Treatment × polynomial | `elegible × polynomial` |

### Time-Varying Indicators

| Variable | Type | Description | Values |
|----------|------|-------------|--------|
| `pre_programa` | Binary | Pre-treatment period | 1 if period < 1 |
| `durante_programa` | Binary | During active transfers | 1 if period 1-12 |
| `post_programa` | Binary | After program ended | 1 if period > 12 |
| `semestre` | Numeric | Semester number | 1-4 |

### Panel Structure Variables

| Variable | Type | Description | Notes |
|----------|------|-------------|-------|
| `panel_balanceado` | Binary | Appears in all 24 months | Panel balance check |
| `obs_por_usuario` | Numeric | Observations per user | 1-24 |
| `first_obs` | Binary | First observation for user | Panel structure |
| `last_obs` | Binary | Last observation for user | Panel structure |

## VI. Quality Control Variables

### Data Flags

| Variable | Type | Description | Action |
|----------|------|-------------|--------|
| `flag_outlier` | Binary | Outlier detection flag | Winsorize at 99th percentile |
| `flag_missing` | Binary | Missing key variables | Exclude from analysis |
| `flag_imputado` | Binary | SISBEN score imputed | Exclude from main analysis |
| `flag_duplicado` | Binary | Duplicate record | Keep first occurrence |

## VII. Sample Restrictions

### Inclusion Criteria Variables

| Variable | Type | Description | Values |
|----------|------|-------------|--------|
| `sample_main` | Binary | Main analysis sample | 0/1 |
| `sample_rdd` | Binary | RDD sample (within bandwidth) | 0/1 |
| `sample_panel` | Binary | Balanced panel sample | 0/1 |

**Main sample criteria**:
- Have MOVii account
- Matched to DNP data
- Non-missing SISBEN score
- Pass quality controls
- Within RDD bandwidth (for RDD analysis)

## Variable Naming Conventions

### Prefixes
- `ind_`: Indicator/dummy variable (0/1)
- `num_`: Count variable
- `monto_`: Amount in COP
- `ratio_`: Ratio/proportion (0-1)
- `log_`: Natural logarithm
- `ihs_`: Inverse hyperbolic sine transformation

### Suffixes
- `_t`: Time t value
- `_tm1`: Lagged one period (t-1)
- `_diff`: First difference
- `_cum`: Cumulative sum
- `_avg`: Average/mean
- `_sd`: Standard deviation

## Data Transformations

### Inverse Hyperbolic Sine (IHS)

**Formula**: `asinh(x) = log(x + sqrt(x² + 1))`

**Used for**: Variables with zeros and/or negative values

**Interpretation**: Approximately percentage change for large values

**Stata code**:
```stata
gen var_ihs = asinh(var)
```

### Logarithm

**Formula**: `log(x)` (natural log)

**Used for**: Strictly positive skewed variables

**Stata code**:
```stata
gen var_log = log(var) if var > 0
```

### Winsorization

**Procedure**: Replace extreme values at 1st/99th percentile

**Used for**: Reducing influence of outliers

**Stata code**:
```stata
winsor2 var, replace cuts(1 99)
```

## Missing Data Codes

| Code | Meaning | Action |
|------|---------|--------|
| `.` | Missing (Stata default) | Exclude from analysis |
| `.a` | Not applicable | Category-specific treatment |
| `.b` | Not available in data | Exclude |
| `.c` | Confidential/suppressed | Exclude |

## Units of Measurement

### Monetary
- **COP**: Colombian Pesos
- **USD**: US Dollars (for reference, ~3,500-4,000 COP/USD in 2020-2022)

### Time
- **Months**: Calendar months
- **Days**: Calendar days
- **Period**: Months since April 2020 (program start)

### Counts
- **Transactions**: Number of separate transactions
- **Users**: Number of unique individuals

## Data Quality Notes

### Known Issues

1. **SISBEN score precision**: Some scores rounded to 2 decimals
2. **Transaction dates**: Few observations have timestamp issues (<0.1%)
3. **Municipality codes**: Some rural areas have merged codes
4. **Missing demographics**: ~2% missing education/occupation

### Imputation

**Not performed** - missing observations excluded rather than imputed to maintain data quality for causal inference.

### Synthetic Data Disclaimer

Variables in `data/synthetic/` have:
- Same structure and naming
- Realistic distributions
- **Fabricated values** (not real data)
- For code demonstration only
- **Results will not match thesis**

## References

**SISBEN Documentation**:
- DNP. (2011). *Metodología SISBEN III*. Bogotá: Departamento Nacional de Planeación.

**Variable Standards**:
- DANE. (2020). *Códigos de División Político-Administrativa*. Colombia.

**MOVii Data**:
- Internal MOVii administrative database documentation (confidential)
