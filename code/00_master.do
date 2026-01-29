/*******************************************************************************
	MASTER DO-FILE: Financial Inclusion Analysis

	Title: Promoting Financial Inclusion: Do Unconditional E-Money Transfers Work?
	Author: Oscar Andrés Garnica Toro
	Date: January 2024

	This master script runs the complete analysis pipeline for evaluating
	Colombia's Ingreso Solidario cash transfer program impact on financial
	inclusion using Regression Discontinuity Design.

	IMPORTANT: This script is configured to run with SYNTHETIC DATA for
	demonstration purposes. Results will NOT match the thesis findings.

	Research Design:
	- Sharp & Fuzzy Regression Discontinuity Design
	- SISBEN poverty score cutoff: 0.038
	- Panel data: 24 months (April 2020 - March 2022)
	- Outcomes: Account balance, transactions, service usage

*******************************************************************************/

clear all
set more off
set maxvar 10000
set matsize 10000
version 16

/*==============================================================================
	SECTION 0: SETUP AND CONFIGURATION
==============================================================================*/

display as text _n(2) "{hline 78}"
display as result "  FINANCIAL INCLUSION RDD ANALYSIS - MASTER SCRIPT"
display as text "{hline 78}" _n

* Set random seed for reproducibility
set seed 20230915

* Close any open log files
capture log close

/*------------------------------------------------------------------------------
	0.1 Global Path Setup
------------------------------------------------------------------------------*/

* Define root directory (modify this to match your system)
global root "/Users/oscarandresgarnicatoro/Documents/financial-inclusion-colombia"

* Verify root directory exists
capture confirm file "${root}"
if _rc != 0 {
	display as error _n "ERROR: Root directory not found!"
	display as error "Please set the global 'root' to your repository location"
	display as error "Current setting: ${root}"
	exit 601
}

* Define subdirectories
global code "${root}/code"
global data "${root}/data"
global synthetic "${data}/synthetic"
global output "${root}/output"
global figures "${output}/figures"
global tables "${output}/tables"
global logs "${root}/logs"

* Create output directories if they don't exist
capture mkdir "${output}"
capture mkdir "${figures}"
capture mkdir "${figures}/01_descriptive"
capture mkdir "${figures}/02_rdd_analysis"
capture mkdir "${figures}/03_robustness"
capture mkdir "${tables}"
capture mkdir "${tables}/01_summary_statistics"
capture mkdir "${tables}/02_main_results"
capture mkdir "${tables}/03_robustness"
capture mkdir "${logs}"

* Start log file
local datetime = string(Clock("`c(current_date)' `c(current_time)'", "DMYhms"))
local logname "master_analysis_`datetime'"
log using "${logs}/`logname'.smcl", replace text

display as text _n "Repository Structure:"
display as text "  Root:      ${root}"
display as text "  Code:      ${code}"
display as text "  Data:      ${data}"
display as text "  Output:    ${output}"
display as text "  Logs:      ${logs}" _n

/*------------------------------------------------------------------------------
	0.2 Install Required Packages
------------------------------------------------------------------------------*/

display as text "{hline 78}"
display as result "Checking required Stata packages..."
display as text "{hline 78}" _n

* List of required packages
local packages "rdrobust rddensity rdlocrand lpdensity estout distinct winsor2"

foreach pkg of local packages {
	capture which `pkg'
	if _rc != 0 {
		display as text "Installing `pkg'..."
		ssc install `pkg', replace
	}
	else {
		display as text "✓ `pkg' already installed"
	}
}

display as result _n "All required packages installed!" _n

/*------------------------------------------------------------------------------
	0.3 Configuration Parameters
------------------------------------------------------------------------------*/

* RDD parameters
global cutoff = 0.038			// SISBEN eligibility cutoff
global kernel "triangular"		// Kernel function
global poly_order = 1			// Polynomial order (linear)
global bandwidth_method "mserd"	// MSE-optimal bandwidth selection

* Sample restrictions
global min_age = 18				// Minimum age
global max_age = 75				// Maximum age

* Analysis options
global run_cleaning = 1			// Run data cleaning (0/1)
global run_descriptive = 1		// Run descriptive analysis (0/1)
global run_rdd = 1				// Run RDD analysis (0/1)
global run_robustness = 1		// Run robustness checks (0/1)

display as text "Analysis Configuration:"
display as text "  SISBEN cutoff:     ${cutoff}"
display as text "  Kernel function:   ${kernel}"
display as text "  Polynomial order:  ${poly_order}"
display as text "  Bandwidth method:  ${bandwidth_method}" _n

/*==============================================================================
	SECTION 1: DATA CLEANING AND PREPARATION
==============================================================================*/

if $run_cleaning == 1 {

	display as text _n(2) "{hline 78}"
	display as result "SECTION 1: DATA CLEANING AND PREPARATION"
	display as text "{hline 78}" _n

	/*--------------------------------------------------------------------------
		1.1 Check Synthetic Data Availability
	--------------------------------------------------------------------------*/

	display as text "Checking for synthetic data files..." _n

	* Check if synthetic data exists
	capture confirm file "${synthetic}/sample_eligibility_data.dta"
	if _rc != 0 {
		display as error _n "ERROR: Synthetic data not found!"
		display as text _n "Please run the Python script to generate synthetic data:"
		display as text "  python code/python/scripts/generate_synthetic_data.py" _n
		display as text "Then re-run this master script."
		log close
		exit 601
	}

	display as result "✓ Synthetic data files found" _n

	/*--------------------------------------------------------------------------
		1.2 Load and Prepare Eligibility Data (DNP)
	--------------------------------------------------------------------------*/

	display as text "Loading DNP eligibility data..." _n

	use "${synthetic}/sample_eligibility_data.dta", clear

	* Variable labels
	label variable user_id "User ID"
	label variable puntaje_sisben "SISBEN III score"
	label variable puntaje_centrado "SISBEN score centered at cutoff"
	label variable elegible "Eligible for Ingreso Solidario (SISBEN < 0.038)"
	label variable tratado "Actually received transfers"
	label variable edad "Age (years)"
	label variable genero "Gender (1=Male, 2=Female)"
	label variable estrato "Socioeconomic stratum"
	label variable tam_hogar "Household size"
	label variable num_menores "Number of children"
	label variable zona "Zone (1=Urban, 2=Rural)"
	label variable nivel_educativo "Education level"
	label variable cod_departamento "Department code"
	label variable cod_municipio "Municipality code"

	* Value labels
	label define genero_lbl 1 "Male" 2 "Female"
	label values genero genero_lbl

	label define zona_lbl 1 "Urban" 2 "Rural"
	label values zona zona_lbl

	* Sample restrictions
	keep if edad >= $min_age & edad <= $max_age
	keep if !missing(puntaje_sisben)

	* Save cleaned eligibility data
	tempfile eligibility_clean
	save `eligibility_clean', replace

	local n_users = _N
	display as result "✓ DNP data loaded: `n_users' observations" _n

	/*--------------------------------------------------------------------------
		1.3 Load and Prepare Transaction Data (MOVii)
	--------------------------------------------------------------------------*/

	display as text "Loading MOVii transaction panel data..." _n

	use "${synthetic}/sample_transaction_panel.dta", clear

	* Variable labels
	label variable user_id "User ID"
	label variable period "Period (months since April 2020)"
	label variable year "Year"
	label variable month_num "Month"
	label variable saldo "Account balance (COP)"
	label variable trx_total "Total transactions"
	label variable trx_envios "Person-to-person transfers sent"
	label variable trx_recibidos "Transfers received"
	label variable trx_retiros "Cash withdrawals"
	label variable trx_depositos "Deposits"
	label variable trx_compras "Purchases"
	label variable monto_total "Total transaction amount"
	label variable monto_envios "Amount sent (transfers)"
	label variable monto_retiros "Amount withdrawn"
	label variable monto_compras "Amount spent (purchases)"
	label variable monto_depositos "Amount deposited"
	label variable cuenta_activa "Account active (any transaction)"
	label variable diversificacion "Service diversification index"

	* Merge with eligibility data
	merge m:1 user_id using `eligibility_clean', keep(match) nogen

	* Generate additional variables
	gen saldo_ihs = asinh(saldo)
	label variable saldo_ihs "Account balance (IHS transformation)"

	gen ratio_retiros = trx_retiros / trx_total if trx_total > 0
	label variable ratio_retiros "Share of cash-out transactions"

	gen ratio_compras = trx_compras / trx_total if trx_total > 0
	label variable ratio_compras "Share of purchase transactions"

	* Time indicators
	gen post_programa = (period > 12)
	label variable post_programa "Post-program period (>12 months)"

	gen durante_programa = (period <= 12)
	label variable durante_programa "During active transfers (≤12 months)"

	* Save full panel
	save "${data}/synthetic/analysis_panel.dta", replace

	local n_obs = _N
	local n_users = r(N)
	display as result "✓ Panel data prepared: `n_obs' observations" _n

	/*--------------------------------------------------------------------------
		1.4 Create Cross-Sectional Sample (Month 6)
	--------------------------------------------------------------------------*/

	display as text "Creating cross-sectional sample (month 6)..." _n

	use "${data}/synthetic/analysis_panel.dta", clear
	keep if period == 6

	save "${data}/synthetic/analysis_crosssection.dta", replace

	local n_obs = _N
	display as result "✓ Cross-section created: `n_obs' observations" _n

	display as result _n "Data cleaning complete!" _n
}

/*==============================================================================
	SECTION 2: DESCRIPTIVE ANALYSIS
==============================================================================*/

if $run_descriptive == 1 {

	display as text _n(2) "{hline 78}"
	display as result "SECTION 2: DESCRIPTIVE ANALYSIS"
	display as text "{hline 78}" _n

	use "${data}/synthetic/analysis_crosssection.dta", clear

	/*--------------------------------------------------------------------------
		2.1 Summary Statistics
	--------------------------------------------------------------------------*/

	display as text "Generating summary statistics..." _n

	* Overall summary statistics
	eststo clear
	estpost summarize puntaje_sisben edad genero estrato tam_hogar ///
		saldo trx_total trx_compras cuenta_activa
	esttab using "${tables}/01_summary_statistics/summary_overall.tex", ///
		cells("mean(fmt(2)) sd(fmt(2)) min max count") ///
		noobs nonumber nomtitle replace booktabs ///
		title("Summary Statistics - Full Sample")

	* By treatment status
	eststo clear
	eststo: quietly estpost summarize saldo trx_total trx_compras if tratado == 0
	eststo: quietly estpost summarize saldo trx_total trx_compras if tratado == 1
	esttab using "${tables}/01_summary_statistics/summary_by_treatment.tex", ///
		cells("mean(fmt(0)) sd(fmt(0))") ///
		mtitle("Control" "Treated") replace booktabs ///
		title("Summary Statistics by Treatment Status")

	display as result "✓ Summary statistics saved" _n

	/*--------------------------------------------------------------------------
		2.2 Visualizations
	--------------------------------------------------------------------------*/

	display as text "Creating descriptive visualizations..." _n

	* Histogram of SISBEN scores
	histogram puntaje_sisben, frequency ///
		xline($cutoff, lcolor(red) lpattern(dash)) ///
		title("Distribution of SISBEN Scores") ///
		subtitle("Cutoff at 0.038") ///
		xtitle("SISBEN Score") ytitle("Frequency") ///
		note("Synthetic data - for demonstration only")
	graph export "${figures}/01_descriptive/sisben_distribution.png", replace

	* Balance by eligibility
	graph box saldo, over(elegible) ///
		title("Account Balance by Eligibility") ///
		ytitle("Balance (COP)") ///
		note("Synthetic data - for demonstration only")
	graph export "${figures}/01_descriptive/balance_by_eligibility.png", replace

	display as result "✓ Descriptive figures saved" _n
}

/*==============================================================================
	SECTION 3: REGRESSION DISCONTINUITY ANALYSIS
==============================================================================*/

if $run_rdd == 1 {

	display as text _n(2) "{hline 78}"
	display as result "SECTION 3: REGRESSION DISCONTINUITY ANALYSIS"
	display as text "{hline 78}" _n

	use "${data}/synthetic/analysis_crosssection.dta", clear

	/*--------------------------------------------------------------------------
		3.1 Sharp RDD: Intent-to-Treat Effects
	--------------------------------------------------------------------------*/

	display as text "Running Sharp RDD analysis..." _n

	* Balance outcome
	rdrobust saldo puntaje_sisben, c($cutoff) kernel($kernel) p($poly_order) ///
		bwselect($bandwidth_method) all

	outreg2 using "${tables}/02_main_results/sharp_rdd.tex", ///
		replace tex(frag) dec(0) ctitle("Balance")

	* Save RD plot
	rdplot saldo puntaje_sisben, c($cutoff) ///
		graph_options(title("Sharp RDD: Account Balance") ///
		ytitle("Balance (COP)") xtitle("SISBEN Score") ///
		note("Synthetic data - for demonstration only"))
	graph export "${figures}/02_rdd_analysis/rdplot_balance.png", replace

	* Transactions outcome
	rdrobust trx_total puntaje_sisben, c($cutoff) kernel($kernel) p($poly_order) ///
		bwselect($bandwidth_method) all

	outreg2 using "${tables}/02_main_results/sharp_rdd.tex", ///
		append tex(frag) dec(2) ctitle("Transactions")

	* Purchases outcome
	rdrobust trx_compras puntaje_sisben, c($cutoff) kernel($kernel) p($poly_order) ///
		bwselect($bandwidth_method) all

	outreg2 using "${tables}/02_main_results/sharp_rdd.tex", ///
		append tex(frag) dec(2) ctitle("Purchases")

	display as result "✓ Sharp RDD analysis complete" _n

	/*--------------------------------------------------------------------------
		3.2 Fuzzy RDD: Treatment Effect on Treated
	--------------------------------------------------------------------------*/

	display as text "Running Fuzzy RDD analysis..." _n

	* Balance outcome
	rdrobust saldo puntaje_sisben, c($cutoff) kernel($kernel) p($poly_order) ///
		fuzzy(tratado) bwselect($bandwidth_method) all

	outreg2 using "${tables}/02_main_results/fuzzy_rdd.tex", ///
		replace tex(frag) dec(0) ctitle("Balance")

	* Transactions outcome
	rdrobust trx_total puntaje_sisben, c($cutoff) kernel($kernel) p($poly_order) ///
		fuzzy(tratado) bwselect($bandwidth_method) all

	outreg2 using "${tables}/02_main_results/fuzzy_rdd.tex", ///
		append tex(frag) dec(2) ctitle("Transactions")

	display as result "✓ Fuzzy RDD analysis complete" _n

	/*--------------------------------------------------------------------------
		3.3 Panel RDD: Dynamic Effects
	--------------------------------------------------------------------------*/

	display as text "Running panel RDD analysis..." _n

	use "${data}/synthetic/analysis_panel.dta", clear

	* Month-by-month estimation
	matrix tau = J(24, 3, .)  // Store coefficients, SE, p-values
	matrix colnames tau = "Coefficient" "SE" "P-value"

	forvalues t = 1/24 {
		quietly {
			rdrobust saldo puntaje_sisben if period == `t', ///
				c($cutoff) kernel($kernel) p($poly_order)

			matrix tau[`t',1] = e(tau_cl)
			matrix tau[`t',2] = e(se_tau_rb)
			matrix tau[`t',3] = 2*normal(-abs(e(tau_cl)/e(se_tau_rb)))
		}
		display as text "  Month `t': τ = " %6.0f tau[`t',1] " (SE = " %6.0f tau[`t',2] ")"
	}

	* Export matrix to Excel
	putexcel set "${tables}/02_main_results/dynamic_effects.xlsx", replace
	putexcel A1 = matrix(tau), names

	display as result _n "✓ Panel RDD analysis complete" _n
}

/*==============================================================================
	SECTION 4: ROBUSTNESS CHECKS
==============================================================================*/

if $run_robustness == 1 {

	display as text _n(2) "{hline 78}"
	display as result "SECTION 4: ROBUSTNESS CHECKS"
	display as text "{hline 78}" _n

	use "${data}/synthetic/analysis_crosssection.dta", clear

	/*--------------------------------------------------------------------------
		4.1 Density Test (McCrary Test)
	--------------------------------------------------------------------------*/

	display as text "Running density test..." _n

	rddensity puntaje_sisben, c($cutoff) plot
	graph export "${figures}/03_robustness/density_test.png", replace

	local pval = e(pval_asy)
	display as text "  Density test p-value: " %5.3f `pval'

	if `pval' < 0.05 {
		display as text "  ⚠ Warning: Evidence of sorting at cutoff"
	}
	else {
		display as result "  ✓ No evidence of manipulation"
	}

	display ""

	/*--------------------------------------------------------------------------
		4.2 Falsification Tests (Predetermined Covariates)
	--------------------------------------------------------------------------*/

	display as text "Running falsification tests..." _n

	eststo clear

	* Age (predetermined)
	quietly rdrobust edad puntaje_sisben, c($cutoff) kernel($kernel) p($poly_order)
	eststo edad_rdd
	display as text "  Age: τ = " %6.2f e(tau_cl) " (p = " %5.3f e(pv_rb) ")"

	* Gender (predetermined)
	quietly rdrobust genero puntaje_sisben, c($cutoff) kernel($kernel) p($poly_order)
	eststo genero_rdd
	display as text "  Gender: τ = " %6.2f e(tau_cl) " (p = " %5.3f e(pv_rb) ")"

	* Household size (predetermined)
	quietly rdrobust tam_hogar puntaje_sisben, c($cutoff) kernel($kernel) p($poly_order)
	eststo hogar_rdd
	display as text "  Household size: τ = " %6.2f e(tau_cl) " (p = " %5.3f e(pv_rb) ")"

	* Export table
	esttab edad_rdd genero_rdd hogar_rdd using "${tables}/03_robustness/falsification_tests.tex", ///
		replace booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
		mtitle("Age" "Gender" "HH Size") ///
		title("Falsification Tests: Predetermined Covariates")

	display as result _n "✓ Falsification tests complete" _n

	/*--------------------------------------------------------------------------
		4.3 Placebo Tests (Alternative Cutoffs)
	--------------------------------------------------------------------------*/

	display as text "Running placebo tests..." _n

	* Test at alternative cutoffs
	local placebo_cutoffs "0.028 0.048"

	matrix placebo = J(2, 3, .)
	matrix colnames placebo = "Cutoff" "Coefficient" "P-value"

	local row = 1
	foreach cutoff of local placebo_cutoffs {
		quietly rdrobust saldo puntaje_sisben, c(`cutoff') kernel($kernel) p($poly_order)
		matrix placebo[`row',1] = `cutoff'
		matrix placebo[`row',2] = e(tau_cl)
		matrix placebo[`row',3] = e(pv_rb)

		display as text "  Cutoff `cutoff': τ = " %6.0f e(tau_cl) " (p = " %5.3f e(pv_rb) ")"
		local row = `row' + 1
	}

	* Export
	putexcel set "${tables}/03_robustness/placebo_tests.xlsx", replace
	putexcel A1 = matrix(placebo), names

	display as result _n "✓ Placebo tests complete" _n

	/*--------------------------------------------------------------------------
		4.4 Bandwidth Sensitivity
	--------------------------------------------------------------------------*/

	display as text "Running bandwidth sensitivity analysis..." _n

	* Get optimal bandwidth
	quietly rdbwselect saldo puntaje_sisben, c($cutoff) kernel($kernel) p($poly_order)
	local h_opt = e(h_mserd)

	display as text "  Optimal bandwidth: " %5.3f `h_opt' _n

	* Test multiple bandwidths
	local bandwidths "0.5 1.0 1.5"  // Multiples of optimal

	matrix bw_sens = J(3, 4, .)
	matrix colnames bw_sens = "Multiplier" "Bandwidth" "Coefficient" "P-value"

	local row = 1
	foreach mult of local bandwidths {
		local bw = `h_opt' * `mult'
		quietly rdrobust saldo puntaje_sisben, c($cutoff) kernel($kernel) p($poly_order) h(`bw')

		matrix bw_sens[`row',1] = `mult'
		matrix bw_sens[`row',2] = `bw'
		matrix bw_sens[`row',3] = e(tau_cl)
		matrix bw_sens[`row',4] = e(pv_rb)

		display as text "  BW = " %5.3f `bw' " (`mult' × h_opt): τ = " %6.0f e(tau_cl) " (p = " %5.3f e(pv_rb) ")"
		local row = `row' + 1
	}

	* Export
	putexcel set "${tables}/03_robustness/bandwidth_sensitivity.xlsx", replace
	putexcel A1 = matrix(bw_sens), names

	display as result _n "✓ Bandwidth sensitivity analysis complete" _n
}

/*==============================================================================
	SECTION 5: COMPLETION
==============================================================================*/

display as text _n(2) "{hline 78}"
display as result "ANALYSIS COMPLETE!"
display as text "{hline 78}" _n

display as text "Output files saved to:"
display as text "  Tables:  ${tables}"
display as text "  Figures: ${figures}"
display as text "  Logs:    ${logs}" _n

display as result "⚠️  REMINDER: This analysis used SYNTHETIC DATA"
display as text "   Results shown are for demonstration only and do not match thesis findings"
display as text "   See data/README.md for information about the actual research data" _n

* Close log
log close

display as result _n "Log file saved: ${logs}/`logname'.smcl" _n

/*==============================================================================
	END OF MASTER SCRIPT
==============================================================================*/
