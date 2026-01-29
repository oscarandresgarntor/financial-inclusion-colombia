# Data Documentation

## Important Notice: Synthetic Data Usage

⚠️ **This repository contains SYNTHETIC DATA ONLY**

### Why Synthetic Data?

The original research analyzed **confidential administrative data** that cannot be publicly shared due to:

1. **Non-Disclosure Agreements (NDAs)**:
   - MOVii (digital wallet provider): Transaction-level financial data
   - DNP (National Planning Department): Personal eligibility records

2. **Privacy Regulations**:
   - Contains personally identifiable information (PII)
   - Financial transaction data protected under Colombian data privacy laws
   - SISBEN scores and demographic information are sensitive

3. **Institutional Agreements**:
   - Data use restricted to authorized research purposes
   - Cannot be redistributed or made publicly available

### What's in This Repository

#### Synthetic Data (`data/synthetic/`)

**Purpose**: Demonstrate code functionality and analysis pipeline

**Contents**:
- `sample_eligibility_data.dta`: 10,000 synthetic SISBEN eligibility records
- `sample_transaction_data.dta`: 10,000 synthetic transaction observations

**Generated using**: `code/python/scripts/generate_synthetic_data.py`

**Characteristics**:
- Same variable structure as real data
- Realistic distributions (approximate)
- **Fabricated values** - not real observations
- Preserves privacy completely

#### Data Dictionaries (`data/dictionaries/`)

**Contents**:
- `dnp_variables.xlsx`: Variable definitions from DNP eligibility data
- `movii_variables.xlsx`: Variable definitions from MOVii transaction data

**Purpose**: Document real data structure without exposing actual values

### Actual Research Data (Not Included)

#### DNP Eligibility Data

**Source**: Departamento Nacional de Planeación (DNP)
- **Observations**: 1,048,575
- **Variables**: ~50 variables
- **Size**: ~500MB
- **Time period**: April 2020 (cross-sectional)

**Key variables**:
- SISBEN III poverty scores
- Demographics (age, gender, education)
- Household characteristics
- Geographic identifiers
- Program eligibility status

**Access**: Restricted to authorized researchers through DNP data request process

#### MOVii Transaction Data

**Source**: MOVii S.A.S. (digital wallet provider)
- **Users**: 944,985 unique individuals
- **Observations**: ~23 million transaction-month observations
- **Variables**: ~80 transaction and account variables
- **Size**: ~67GB
- **Time period**: April 2020 - March 2022 (24 months)

**Key variables**:
- Account balances
- Transaction counts by type
- Transaction amounts
- Service usage patterns
- User activity indicators

**Access**: Restricted to authorized researchers through MOVii data partnership

### Synthetic vs. Real Data Comparison

| Aspect | Real Data | Synthetic Data |
|--------|-----------|----------------|
| **Observations** | 1,048,575 (DNP) + 944,985 users (MOVii) | 10,000 each |
| **Size** | ~67GB total | ~2MB |
| **Time span** | 24 months | Same structure |
| **Variables** | 130+ variables | Same variables |
| **Values** | Actual administrative records | Randomly generated |
| **Results** | Published thesis findings | For demonstration only |
| **Privacy** | Highly confidential | Fully public-safe |

### Important Disclaimers

1. **Results Shown in Output**:
   - Tables and figures in `output/` are based on **actual data**
   - These results appear in the published thesis
   - **Cannot be replicated** using synthetic data

2. **Code Demonstration**:
   - All code runs successfully with synthetic data
   - Demonstrates methodology and techniques
   - Output values will be **completely different** from thesis

3. **Reproducibility**:
   - Analysis pipeline is fully reproducible
   - Synthetic data allows testing of code
   - True replication requires access to real data

### Obtaining Real Data

#### For Academic Researchers

**DNP Data**:
1. Submit data request to DNP Research Division
2. Provide research protocol and IRB approval
3. Sign data use agreement
4. Access granted for specific research purposes

**MOVii Data**:
1. Establish research partnership with MOVii
2. Negotiate data sharing agreement
3. Sign NDA and data protection protocols
4. Access typically granted for institutional research

**Contact**:
- DNP: [Link to data request process]
- MOVii: Institutional partnerships only

#### For Replication

Researchers interested in replicating this analysis should:

1. Contact thesis author: [your-email@domain.com]
2. Provide IRB approval and research protocol
3. Negotiate data access agreements independently
4. Use code from this repository with actual data

### Data Quality Assurance

#### Real Data Validation (Performed)

- **DNP data**:
  - Cross-checked SISBEN scores with official databases
  - Validated geographic codes against DANE standards
  - Verified eligibility determinations

- **MOVii data**:
  - Transaction integrity checks
  - Balance reconciliation
  - Outlier detection and treatment
  - Temporal consistency validation

- **Data merge**:
  - 90.2% match rate between DNP and MOVii
  - Unmatched observations analyzed for systematic patterns
  - Merge quality documented in thesis appendix

#### Synthetic Data (Limitations)

- **Not validated** - random generation only
- **No real patterns** - correlations are artificial
- **No causal inference** - results meaningless
- **Demonstration purpose only**

### Variable Documentation

See full variable definitions in:
- [Data Dictionary](../docs/data_dictionary.md)
- `data/dictionaries/dnp_variables.xlsx`
- `data/dictionaries/movii_variables.xlsx`

### File Structure

```
data/
├── README.md                          # This file
│
├── synthetic/                         # Demonstration data (PUBLIC)
│   ├── sample_eligibility_data.dta   # Synthetic DNP data
│   └── sample_transaction_data.dta   # Synthetic MOVii data
│
└── dictionaries/                      # Variable documentation (PUBLIC)
    ├── dnp_variables.xlsx            # DNP variable definitions
    └── movii_variables.xlsx          # MOVii variable definitions
```

**Not included** (confidential):
```
data/
├── real/                              # CONFIDENTIAL - NOT IN REPO
│   ├── dnp_master.dta                # Real eligibility data
│   ├── movii_panel.dta               # Real transaction panel
│   └── merged_analysis.dta           # Merged analysis file
```

### Data Processing Pipeline

**Overview**:
1. **Data cleaning** (`code/stata/01_data_cleaning/`)
   - Import and standardize DNP data
   - Process MOVii transaction records
   - Merge datasets on anonymized IDs

2. **Variable construction** (`code/stata/02_descriptive_analysis/`)
   - Create outcome variables
   - Generate treatment indicators
   - Construct panel structure

3. **Analysis** (`code/stata/03_econometric_analysis/`)
   - RDD estimation
   - Panel regression
   - Robustness checks

See [Master Script](../code/00_master.do) for complete pipeline.

### Synthetic Data Generation

**Script**: `code/python/scripts/generate_synthetic_data.py`

**Methodology**:
```python
import numpy as np
import pandas as pd

np.random.seed(42)  # Reproducibility

# Generate SISBEN scores (normal around cutoff)
sisben = np.random.normal(0.038, 0.015, 10000)

# Generate eligibility
eligible = (sisben < 0.038).astype(int)

# Generate outcomes with artificial treatment effect
balance = 50000 + 10000 * eligible + np.random.normal(0, 20000, 10000)

# Export to Stata format
df.to_stata('data/synthetic/sample_eligibility_data.dta')
```

**Run to regenerate**:
```bash
python code/python/scripts/generate_synthetic_data.py
```

### Ethical Considerations

This research follows strict ethical guidelines:

1. **Data minimization**: Only necessary variables collected
2. **Anonymization**: All personal identifiers removed/encrypted
3. **Secure storage**: Data stored on encrypted, access-controlled servers
4. **Limited access**: Only authorized researchers
5. **No re-identification attempts**: Prohibited by agreements
6. **Public outputs**: Only aggregate statistics published

**IRB Approval**: Universidad de los Andes Ethics Committee (Protocol #XXXX)

### Citing This Data

**For code/methodology**:
```
Garnica, O. A. (2023). "Promoting Financial Inclusion: Do Unconditional
E-Money Transfers Work?" [Code repository]. GitHub.
https://github.com/[username]/financial-inclusion-colombia
```

**For research findings** (actual data):
```
Garnica, O. A. (2023). "Promoting Financial Inclusion: Do Unconditional
E-Money Transfers Work? Evidence from Colombia's Ingreso Solidario Program."
Master's Thesis, Universidad de los Andes.
```

### Support

**Questions about**:
- Synthetic data generation → GitHub Issues
- Code functionality → GitHub Issues
- Real data access → Contact author or data providers
- Research methodology → See thesis or contact author

### Acknowledgments

**Data providers**:
- **MOVii S.A.S.**: For providing transaction data under research partnership
- **DNP** (Departamento Nacional de Planeación): For providing eligibility data

**Data access facilitated by**:
- Universidad de los Andes
- Centro de Estudios sobre Desarrollo Económico (CEDE)

---

**Last updated**: January 2024
**Contact**: [your-email@domain.com]
