#!/usr/bin/env python3
"""
Generate Synthetic Data for Financial Inclusion Analysis
========================================================

This script creates synthetic demonstration data that mimics the structure
and approximate distributions of the real MOVii and DNP datasets used in
the thesis analysis.

IMPORTANT: This data is completely fabricated and should ONLY be used for:
- Code demonstration
- Testing analysis pipeline
- Educational purposes

Results from synthetic data will NOT match the actual research findings.

Author: Oscar Andrés Garnica Toro
Date: January 2024
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import os

# Set random seed for reproducibility
np.random.seed(42)

# Configuration
N_USERS = 10000  # Number of synthetic users
N_MONTHS = 24    # Number of months (April 2020 - March 2022)
CUTOFF = 0.038   # SISBEN eligibility cutoff

print("=" * 70)
print("SYNTHETIC DATA GENERATION FOR FINANCIAL INCLUSION ANALYSIS")
print("=" * 70)
print(f"\nGenerating synthetic data for {N_USERS:,} users over {N_MONTHS} months...")
print(f"SISBEN eligibility cutoff: {CUTOFF}")
print("\n⚠️  WARNING: This is synthetic data - results will not match thesis findings!\n")

# ============================================================================
# PART 1: ELIGIBILITY DATA (DNP)
# ============================================================================

print("Generating DNP eligibility data...")

# Generate SISBEN scores (concentrated around cutoff)
# Use truncated normal distribution
sisben_mean = CUTOFF + 0.002  # Slightly above cutoff
sisben_std = 0.015
sisben_scores = np.random.normal(sisben_mean, sisben_std, N_USERS)
sisben_scores = np.clip(sisben_scores, 0, 0.1)  # Truncate to realistic range

# Center SISBEN score around cutoff
sisben_centrado = sisben_scores - CUTOFF

# Determine eligibility (sharp rule)
elegible = (sisben_scores < CUTOFF).astype(int)

# Determine actual treatment (fuzzy - some non-compliance)
# 90% compliance for eligible, 5% spillover for ineligible
compliance_rate = 0.90
spillover_rate = 0.05

tratado = np.zeros(N_USERS, dtype=int)
tratado[elegible == 1] = np.random.binomial(1, compliance_rate, sum(elegible == 1))
tratado[elegible == 0] = np.random.binomial(1, spillover_rate, sum(elegible == 0))

# Generate demographics
edad = np.random.randint(18, 75, N_USERS)
genero = np.random.choice([1, 2], N_USERS, p=[0.35, 0.65])  # 1=Male, 2=Female (more women)
estrato = np.random.choice([1, 2, 3], N_USERS, p=[0.6, 0.3, 0.1])  # Concentrated in low strata
tam_hogar = np.random.poisson(3.5, N_USERS) + 1  # Average 3.5 household size
num_menores = np.random.poisson(1.2, N_USERS)  # Average 1.2 children
zona = np.random.choice([1, 2], N_USERS, p=[0.75, 0.25])  # 1=Urban, 2=Rural
nivel_educativo = np.random.choice([1, 2, 3, 4, 5], N_USERS, p=[0.1, 0.25, 0.3, 0.25, 0.1])

# Geographic distribution (departments - codes for major regions)
departamentos = [5, 8, 11, 13, 19, 25, 47, 50, 52, 54, 63, 66, 68, 73, 76]  # Major departments
cod_departamento = np.random.choice(departamentos, N_USERS,
                                    p=[0.05, 0.08, 0.25, 0.04, 0.05, 0.12, 0.03, 0.04, 0.03, 0.05, 0.04, 0.05, 0.07, 0.05, 0.05])

# Generate municipality codes (simplified)
cod_municipio = cod_departamento * 1000 + np.random.randint(1, 100, N_USERS)

# Create eligibility dataframe
dnp_data = pd.DataFrame({
    'user_id': [f'USER_{i:06d}' for i in range(1, N_USERS + 1)],
    'puntaje_sisben': sisben_scores,
    'puntaje_centrado': sisben_centrado,
    'elegible': elegible,
    'tratado': tratado,
    'edad': edad,
    'genero': genero,
    'estrato': estrato,
    'tam_hogar': tam_hogar,
    'num_menores': num_menores,
    'zona': zona,
    'nivel_educativo': nivel_educativo,
    'cod_departamento': cod_departamento,
    'cod_municipio': cod_municipio,
})

print(f"  ✓ Generated {len(dnp_data):,} synthetic eligibility records")
print(f"  ✓ Eligible users: {elegible.sum():,} ({100*elegible.mean():.1f}%)")
print(f"  ✓ Actually treated: {tratado.sum():,} ({100*tratado.mean():.1f}%)")

# ============================================================================
# PART 2: TRANSACTION DATA (MOVii) - Panel Structure
# ============================================================================

print("\nGenerating MOVii transaction panel data...")

# Create panel structure
panel_data = []

for month in range(1, N_MONTHS + 1):
    # Not all users active in all months
    if month == 1:
        active_users = N_USERS  # All users in first month
    else:
        # Some attrition over time
        active_users = int(N_USERS * (1 - 0.01 * month))  # 1% attrition per month

    # Select active users
    active_indices = np.random.choice(N_USERS, active_users, replace=False)

    for idx in active_indices:
        user_id = f'USER_{idx+1:06d}'
        treated = tratado[idx]
        eligible = dnp_data.loc[idx, 'elegible']

        # Generate outcomes with treatment effect
        # Treatment increases balance, transactions, especially for those receiving transfers

        # Base values (no treatment)
        base_balance = 30000 * np.random.lognormal(0, 1)
        base_trx_total = np.random.poisson(3)

        # Treatment effects (if treated)
        if treated == 1 and month <= 12:  # Active treatment period (first 12 months)
            # ITT effect: +15,000 COP balance, +2 transactions
            treatment_effect_balance = 15000 + np.random.normal(0, 5000)
            treatment_effect_trx = 2 + np.random.poisson(1)
        else:
            treatment_effect_balance = 0
            treatment_effect_trx = 0

        # Final outcomes
        saldo = max(0, base_balance + treatment_effect_balance)
        trx_total = base_trx_total + treatment_effect_trx

        # Decompose transactions
        trx_retiros = int(trx_total * 0.4)  # 40% cash-out
        trx_envios = int(trx_total * 0.25)  # 25% transfers
        trx_compras = int(trx_total * 0.15)  # 15% purchases (treatment increases this)
        trx_depositos = int(trx_total * 0.1)  # 10% deposits
        trx_recibidos = max(0, int(trx_total * 0.1) + (1 if treated else 0))  # Receive transfer if treated

        # Transaction amounts
        monto_total = saldo * 1.5 + np.random.normal(0, 10000)
        monto_envios = trx_envios * 25000 if trx_envios > 0 else 0
        monto_retiros = trx_retiros * 50000 if trx_retiros > 0 else 0
        monto_compras = trx_compras * 35000 if trx_compras > 0 else 0
        monto_depositos = trx_depositos * 40000 if trx_depositos > 0 else 0

        # Activity indicators
        cuenta_activa = 1 if trx_total > 0 else 0

        # Service diversification
        diversificacion = sum([trx_retiros > 0, trx_envios > 0, trx_compras > 0,
                              trx_depositos > 0, trx_recibidos > 0])

        panel_data.append({
            'user_id': user_id,
            'period': month,
            'year': 2020 + (month - 1 + 3) // 12,  # Starts April 2020
            'month_num': (month - 1 + 4) % 12 + 1,  # April = 4
            'saldo': saldo,
            'trx_total': trx_total,
            'trx_envios': trx_envios,
            'trx_recibidos': trx_recibidos,
            'trx_retiros': trx_retiros,
            'trx_depositos': trx_depositos,
            'trx_compras': trx_compras,
            'monto_total': monto_total,
            'monto_envios': monto_envios,
            'monto_retiros': monto_retiros,
            'monto_compras': monto_compras,
            'monto_depositos': monto_depositos,
            'cuenta_activa': cuenta_activa,
            'diversificacion': diversificacion,
        })

movii_panel = pd.DataFrame(panel_data)

print(f"  ✓ Generated {len(movii_panel):,} user-month observations")
print(f"  ✓ Average observations per user: {len(movii_panel)/N_USERS:.1f}")
print(f"  ✓ Panel structure: {N_USERS:,} users × {N_MONTHS} months")

# ============================================================================
# PART 3: CREATE CROSS-SECTIONAL SAMPLE (for simple RDD)
# ============================================================================

print("\nCreating cross-sectional sample (month 6)...")

# Select month 6 data (representative month during treatment)
month6_data = movii_panel[movii_panel['period'] == 6].copy()

# Merge with eligibility data
sample_data = month6_data.merge(dnp_data, on='user_id', how='inner')

print(f"  ✓ Cross-sectional sample: {len(sample_data):,} observations")

# ============================================================================
# PART 4: EXPORT DATA
# ============================================================================

print("\nExporting data files...")

# Create output directory if needed
output_dir = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'data', 'synthetic')
os.makedirs(output_dir, exist_ok=True)

# Export eligibility data
eligibility_path = os.path.join(output_dir, 'sample_eligibility_data.dta')
dnp_data.to_stata(eligibility_path, write_index=False, version=117)
print(f"  ✓ Saved: {eligibility_path}")

# Export transaction panel data
panel_path = os.path.join(output_dir, 'sample_transaction_panel.dta')
movii_panel.to_stata(panel_path, write_index=False, version=117)
print(f"  ✓ Saved: {panel_path}")

# Export cross-sectional sample
crosssection_path = os.path.join(output_dir, 'sample_crosssection.dta')
sample_data.to_stata(crosssection_path, write_index=False, version=117)
print(f"  ✓ Saved: {crosssection_path}")

# Also export as CSV for easier inspection
dnp_data.to_csv(os.path.join(output_dir, 'sample_eligibility_data.csv'), index=False)
movii_panel.to_csv(os.path.join(output_dir, 'sample_transaction_panel.csv'), index=False)
sample_data.to_csv(os.path.join(output_dir, 'sample_crosssection.csv'), index=False)

print("  ✓ Also exported CSV versions for inspection")

# ============================================================================
# PART 5: SUMMARY STATISTICS
# ============================================================================

print("\n" + "=" * 70)
print("SYNTHETIC DATA SUMMARY STATISTICS")
print("=" * 70)

print("\n1. SISBEN Score Distribution:")
print(f"   Mean: {sisben_scores.mean():.4f}")
print(f"   SD: {sisben_scores.std():.4f}")
print(f"   Min: {sisben_scores.min():.4f}")
print(f"   Max: {sisben_scores.max():.4f}")
print(f"   Below cutoff ({CUTOFF}): {elegible.sum():,} ({100*elegible.mean():.1f}%)")

print("\n2. Treatment Assignment:")
print(f"   Eligible: {elegible.sum():,} ({100*elegible.mean():.1f}%)")
print(f"   Treated: {tratado.sum():,} ({100*tratado.mean():.1f}%)")
print(f"   Compliance rate: {100*tratado[elegible==1].mean():.1f}%")
print(f"   Spillover rate: {100*tratado[elegible==0].mean():.1f}%")

print("\n3. Outcomes (Month 6 Cross-Section):")
print(f"   Mean balance: ${sample_data['saldo'].mean():,.0f} COP")
print(f"   Mean transactions: {sample_data['trx_total'].mean():.1f}")
print(f"   Active accounts: {100*sample_data['cuenta_activa'].mean():.1f}%")

print("\n4. Treatment vs Control (Month 6):")
treated_sample = sample_data[sample_data['tratado'] == 1]
control_sample = sample_data[sample_data['tratado'] == 0]

print(f"   Balance - Treated: ${treated_sample['saldo'].mean():,.0f}")
print(f"   Balance - Control: ${control_sample['saldo'].mean():,.0f}")
print(f"   Difference: ${treated_sample['saldo'].mean() - control_sample['saldo'].mean():,.0f}")

print(f"\n   Transactions - Treated: {treated_sample['trx_total'].mean():.2f}")
print(f"   Transactions - Control: {control_sample['trx_total'].mean():.2f}")
print(f"   Difference: {treated_sample['trx_total'].mean() - control_sample['trx_total'].mean():.2f}")

print("\n5. Panel Data:")
print(f"   Total observations: {len(movii_panel):,}")
print(f"   Users: {movii_panel['user_id'].nunique():,}")
print(f"   Time periods: {movii_panel['period'].nunique()}")
print(f"   Avg observations per user: {len(movii_panel)/movii_panel['user_id'].nunique():.1f}")

print("\n" + "=" * 70)
print("✓ SYNTHETIC DATA GENERATION COMPLETE")
print("=" * 70)

print("\n⚠️  REMEMBER: This is synthetic data!")
print("   - Values are randomly generated")
print("   - Results will NOT match thesis findings")
print("   - Use only for code testing and demonstration")
print("\n   See data/README.md for more information\n")
