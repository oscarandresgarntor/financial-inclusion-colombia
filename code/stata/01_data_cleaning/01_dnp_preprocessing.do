/*******************************************************************************
	DNP DATA PREPROCESSING

	Purpose: Clean and prepare DNP (National Planning Department) eligibility
	         data for RDD analysis

	Input: Raw DNP eligibility records with SISBEN scores
	Output: Clean eligibility dataset with treatment assignment

	Author: Oscar Andrés Garnica Toro
	Date: January 2024

	Note: This is a simplified version for demonstration with synthetic data.
	      Original version: 208 lines processing 1,048,575 observations
*******************************************************************************/

clear all
set more off

display as text _n "{hline 78}"
display as result "DNP DATA PREPROCESSING"
display as text "{hline 78}" _n

/*------------------------------------------------------------------------------
	Load Raw Data
------------------------------------------------------------------------------*/

* In actual thesis: import from CSV with 1M+ observations
* With synthetic data: already processed

use "${synthetic}/sample_eligibility_data.dta", clear

display as text "Initial observations: " as result _N

/*------------------------------------------------------------------------------
	Variable Formatting and Cleaning
------------------------------------------------------------------------------*/

* Generate ID variables
* In actual thesis: formatted national ID numbers, anonymized

* Label variables
label variable user_id "User identification"
label variable puntaje_sisben "SISBEN III poverty score (0-100)"
label variable puntaje_centrado "SISBEN score centered at cutoff"
label variable elegible "Eligible for Ingreso Solidario (1=Yes)"
label variable tratado "Received cash transfers (1=Yes)"

* Demographics
label variable edad "Age (years)"
label variable genero "Gender"
label variable estrato "Socioeconomic stratum (1-6)"
label variable tam_hogar "Household size"
label variable num_menores "Number of children under 18"
label variable zona "Geographic zone"
label variable nivel_educativo "Education level"

* Geographic
label variable cod_departamento "Department code (DANE)"
label variable cod_municipio "Municipality code (DANE)"

/*------------------------------------------------------------------------------
	Value Labels
------------------------------------------------------------------------------*/

label define genero_lbl 1 "Male" 2 "Female"
label values genero genero_lbl

label define zona_lbl 1 "Urban" 2 "Rural"
label values zona zona_lbl

label define educ_lbl 1 "No education" 2 "Primary incomplete" ///
	3 "Primary complete" 4 "Secondary incomplete" ///
	5 "Secondary complete" 6 "Higher education"
label values nivel_educativo educ_lbl

/*------------------------------------------------------------------------------
	Treatment Assignment Validation
------------------------------------------------------------------------------*/

* Verify eligibility rule
assert elegible == 1 if puntaje_sisben < ${cutoff}
assert elegible == 0 if puntaje_sisben >= ${cutoff}

display as text _n "Treatment Assignment:"
display as text "  Eligible:        " as result %6.0fc sum(elegible) ///
	as text " (" as result %5.2f 100*sum(elegible)/_N as text "%)"
display as text "  Actually treated:" as result %6.0fc sum(tratado) ///
	as text " (" as result %5.2f 100*sum(tratado)/_N as text "%)"

* Compliance rate
quietly sum tratado if elegible == 1
local compliance = r(mean)
display as text "  Compliance rate: " as result %5.2f 100*`compliance' as text "%"

* Spillover rate
quietly sum tratado if elegible == 0
local spillover = r(mean)
display as text "  Spillover rate:  " as result %5.2f 100*`spillover' as text "%" _n

/*------------------------------------------------------------------------------
	Sample Restrictions
------------------------------------------------------------------------------*/

display as text "Applying sample restrictions..." _n

* Age restrictions
local n_initial = _N
keep if edad >= ${min_age} & edad <= ${max_age}
display as text "  Age restrictions (${min_age}-${max_age}): " ///
	as result _N as text " obs (" as result %5.2f 100*_N/`n_initial' as text "% retained)"

* Drop missing SISBEN scores
local n_before = _N
drop if missing(puntaje_sisben)
display as text "  Non-missing SISBEN:           " ///
	as result _N as text " obs (" as result %5.2f 100*_N/`n_before' as text "% retained)"

/*------------------------------------------------------------------------------
	Generate Additional Variables
------------------------------------------------------------------------------*/

* Age groups
gen edad_grupo = .
replace edad_grupo = 1 if edad < 30
replace edad_grupo = 2 if edad >= 30 & edad < 50
replace edad_grupo = 3 if edad >= 50 & !missing(edad)

label define edad_grupo_lbl 1 "18-29" 2 "30-49" 3 "50+"
label values edad_grupo edad_grupo_lbl
label variable edad_grupo "Age group"

* Distance to cutoff (for heterogeneity analysis)
gen dist_cutoff = abs(puntaje_centrado)
label variable dist_cutoff "Absolute distance to cutoff"

* Sample indicators
gen sample_main = 1
label variable sample_main "Main analysis sample"

/*------------------------------------------------------------------------------
	Summary Statistics
------------------------------------------------------------------------------*/

display as text _n "Final Sample Summary:" _n

display as text "  Observations: " as result %8.0fc _N
display as text "  Variables:    " as result %8.0fc c(k) _n

display as text "SISBEN Score:"
quietly sum puntaje_sisben, detail
display as text "  Mean:   " as result %6.4f r(mean)
display as text "  Median: " as result %6.4f r(p50)
display as text "  SD:     " as result %6.4f r(sd)
display as text "  Range:  " as result %6.4f r(min) " - " %6.4f r(max) _n

display as text "Demographics:"
quietly sum edad
display as text "  Age (mean):         " as result %5.1f r(mean)
tab genero, matcell(freq)
display as text "  Female:             " as result %5.1f 100*freq[2,1]/_N as text "%"
quietly sum tam_hogar
display as text "  Household size:     " as result %5.1f r(mean)

/*------------------------------------------------------------------------------
	Save Cleaned Data
------------------------------------------------------------------------------*/

* In actual thesis: save to temp folder
* For synthetic data: already in place

compress
display as text _n as result "✓ DNP data preprocessing complete!" _n

/*******************************************************************************
	NOTES FROM ACTUAL THESIS VERSION:

	Original file: 1.do_file_dnp_v1.do (208 lines)

	Key processing steps not shown in synthetic version:
	- Import from CSV with special character handling
	- Format national ID numbers (cedulas)
	- Handle 265 missing ID types
	- Clean 37,680 inconsistent birth dates
	- Process 93,956 missing SISBEN 4 scores
	- Handle 3,167 missing SISBEN 3 scores
	- Validate household IDs
	- Cross-check with multiple administrative sources

	The actual data processing was significantly more complex due to
	real-world data quality issues not present in synthetic data.
*******************************************************************************/
