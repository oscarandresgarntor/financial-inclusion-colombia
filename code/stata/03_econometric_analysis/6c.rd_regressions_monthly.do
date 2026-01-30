/*
Date: 12/04/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: Rd regressions (sharp and fuzzy) with amonthly coefficient approach                                          
*/

clear all
set more off


*Globals
*In my laptop:
	global data ""
	global raw "$data/7.raw_data"
	global raw_data_dnp "$raw\dnp"
	global temp_data "$data\8.temp_data"
	global raw_movii_saldos "$raw/saldos_no_trx"
	global raw_movii_trx "$raw/trx"
	global import_movii "$data\5.import_data\movii"
	global import_movii_trx "$import_movii/trx"
	global import_movii_balance "$import_movii/balances"
	global master_data "$data/6.master_data"
	global tables "$data/9.tables"
	global graphs "$data/4.graphs"
	global graphs_trx "$graphs/3.trx_stats"
	global graphs_rdd "$graphs/4.rdd"
	global graphs_rdd_v2 "$graphs/5.rdd_v2"
	global logs "$data/11.logs"
	global graphs_rdd_fpanel_v3 "$graphs/6.rdd_fullpanel_v3"

*declare log
log using "$logs/2.rdd_range01_coff0.smcl", replace

*1.Load DNP data 
use "$master_data/2.movii_dnp_merged.dta", clear

	*1.i. Let's normalize the running variable
	codebook ratio_transform
	replace ratio_transform = 0.038 - ratio_transform
	
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		
		twoway (histogram ratio_transform if ratio_transform>-.1, start(-.1) bin(500) color(red%60)) ///        
       (histogram ratio_transform if ratio_transform>-.1 & is_pers==1, start(-.1) bin(500) color(green%60)), ///   
       legend(order(1 "Movii users" 2 "IS users" )) name("hist_movii_is", replace) xtitle("sisben proxy score")
	   graph export "$graphs_rdd_v2/7.cutoff/1_hist_movii_is.png", replace
	restore
	
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		keep if ratio_transform>-0.1
		
		global y is_pers
		global x ratio_transform
		global c 0
		su $x
		global x_min = r(min)
		global x_max = r(max)
		
		rdplot $y $x if $x >-0.1, genvars hide ci(95)
		*default rdplot
		twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("rdplot_default", replace) xtitle("sisben proxy score") ytitle("IS recipient") legend(off)
		graph export "$graphs_rdd_v2/7.cutoff/2_rdplot_is_ratio_default_lower01.png", replace

		rdrobust $y $x if $x >-0.1
	restore


	
global c 0
global range_rt -0.1
	
	

*2.Let's run the regressions!!!

	*2.1 balance
		forvalues w=1/24{
		
			*Sharp RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_pers)
				sum saldo_cierre_mes, d 
				keep if saldo_cierre_mes<=r(p90)
				
				
				global y saldo_cierre_mes
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x , genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Balance month `w'", color(gs0)) name("bal_`w'm", replace) xtitle("sisben proxy score") ytitle("Balance") legend(off)
				graph export "$graphs_rdd_v2/1.balance/`w'm.png", replace
				
				rdrobust $y $x
				outreg2 using "$tables/4.rdd_v2/1.balance/1.sharp/`w'm.txt", replace
			restore
			
			*Fuzzy RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_pers)
				sum saldo_cierre_mes, d 
				keep if saldo_cierre_mes<=r(p90)
				
				global y saldo_cierre_mes
				global x ratio_transform

				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/1.balance/2.fuzzy/`w'm.txt", replace
			restore
		}
	

	*2.2 online purchases
		forvalues w=1/24{
		
			*Sharp RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) numero_total_comv, by(documento ratio_transform is_pers)
				sum numero_total_comv, d
				keep if numero_total_comv<r(p99)
				
				global y numero_total_comv
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Online purchases month `w'", color(gs0)) name("number_op_m`w'", replace) xtitle("sisben proxy score") ytitle("Average number of online purchases") legend(off)
				graph export "$graphs_rdd_v2/2.online_purch/`w'm_number.png", replace
				
				rdrobust $y $x 
				outreg2 using "$tables/4.rdd_v2/2.online_purch/1.sharp/`w'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) valor_total_comv, by(documento ratio_transform is_pers)
				sum valor_total_comv, d
				keep if valor_total_comv<r(p99)
				
				global y valor_total_comv
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) 
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Online purchases month `w'", color(gs0)) name("amount_op_m`w'", replace) xtitle("sisben proxy score") ytitle("Average amount of online purchases") legend(off)
				graph export "$graphs_rdd_v2/2.online_purch/`w'm_amount.png", replace
				
				rdrobust $y $x 
				outreg2 using "$tables/4.rdd_v2/2.online_purch/1.sharp/`w'm_amount.txt", replace
			restore
			
			*Fuzzy RD 
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) numero_total_comv, by(documento ratio_transform is_pers)
				sum numero_total_comv, d
				keep if numero_total_comv<r(p99)
				
				global y numero_total_comv
				global x ratio_transform
				
				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/2.online_purch/2.fuzzy/`w'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) valor_total_comv, by(documento ratio_transform is_pers)
				sum valor_total_comv, d
				keep if valor_total_comv<r(p99)
				
				global y valor_total_comv
				global x ratio_transform
				
				
				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/2.online_purch/2.fuzzy/`w'm_amount.txt", replace
			restore

		}

		
	*2.3 in-person purchases
		forvalues w=1/24{
		
			*Sharp RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) numero_total_comt, by(documento ratio_transform is_pers)
				sum numero_total_comt, d
				keep if numero_total_comt<r(p99)
				
				global y numero_total_comt
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("In-person purchases month `w'", color(gs0)) name("number_inp_m`w'", replace) xtitle("sisben proxy score") ytitle("Average number of in-person purchases") legend(off)
				graph export "$graphs_rdd_v2/3.in-person_purch/`w'm_number.png", replace
				
				rdrobust $y $x 
				outreg2 using "$tables/4.rdd_v2/3.in-person_purch/1.sharp/`w'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) valor_total_comt, by(documento ratio_transform is_pers)
				sum valor_total_comt, d
				keep if valor_total_comt<r(p99)
				
				global y valor_total_comt
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("In-person purchases month `w'", color(gs0)) name("amount_inp_m`w'", replace) xtitle("sisben proxy score") ytitle("Average amount of in-person purchases") legend(off) 
				graph export "$graphs_rdd_v2/3.in-person_purch/`w'm_amount.png", replace
				
				rdrobust $y $x 
				outreg2 using "$tables/4.rdd_v2/3.in-person_purch/1.sharp/`w'm_amount.txt", replace
			restore
			
			*Fuzzy RD 
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) numero_total_comt, by(documento ratio_transform is_pers)
				sum numero_total_comt, d
				keep if numero_total_comt<r(p99)
				
				global y numero_total_comt
				global x ratio_transform
				
				
				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/3.in-person_purch/2.fuzzy/`w'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) valor_total_comt, by(documento ratio_transform is_pers)
				sum valor_total_comt, d
				keep if valor_total_comt<r(p99)
				
				global y valor_total_comt
				global x ratio_transform
				
				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/3.in-person_purch/2.fuzzy/`w'm_amount.txt", replace
			restore

		}

	*2.4 Transfers
		forvalues w=1/24{
		
			*Sharp RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) numero_total_trf, by(documento ratio_transform is_pers)
				sum numero_total_trf, d
				keep if numero_total_trf<r(p99)
				
				global y numero_total_trf
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Transers month `w'", color(gs0)) name("number_trf_m`w'", replace) xtitle("sisben proxy score") ytitle("Average number of transfers") legend(off)
				graph export "$graphs_rdd_v2/4.transfer/`w'm_number.png", replace
				
				rdrobust $y $x 
				outreg2 using "$tables/4.rdd_v2/4.transfer/1.sharp/`w'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) valor_total_trf, by(documento ratio_transform is_pers)
				sum valor_total_trf, d
				keep if valor_total_trf<r(p99)
				
				global y valor_total_trf
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Transers month `w'", color(gs0)) name("amount_trf_m`w'", replace) xtitle("sisben proxy score") ytitle("Average amount of transfers") legend(off) 
				graph export "$graphs_rdd_v2/4.transfer/`w'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/4.rdd_v2/4.transfer/1.sharp/`w'm_amount.txt", replace
			restore
			
			*Fuzzy RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) numero_total_trf, by(documento ratio_transform is_pers)
				sum numero_total_trf, d
				keep if numero_total_trf<r(p99)
				
				global y numero_total_trf
				global x ratio_transform
				
				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/4.transfer/2.fuzzy/`w'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) valor_total_trf, by(documento ratio_transform is_pers)
				sum valor_total_trf, d
				keep if valor_total_trf<r(p99)
				
				global y valor_total_trf
				global x ratio_transform
				
				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/4.transfer/2.fuzzy/`w'm_amount.txt", replace
			restore
		}
	
	*2.5 Cash-in
		forvalues w=1/24{
		
			*Sharp RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) numero_total_chin, by(documento ratio_transform is_pers)
				sum numero_total_chin, d
				keep if numero_total_chin<r(p99)
				
				global y numero_total_chin
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-in month `w'", color(gs0)) name("number_ci_m`w'", replace) xtitle("sisben proxy score") ytitle("Average number of cash-in") legend(off) 
				graph export "$graphs_rdd_v2/5.cash-in/`w'm_number.png", replace
				
				rdrobust $y $x 
				outreg2 using "$tables/4.rdd_v2/5.cash-in/1.sharp/`w'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) valor_total_chin, by(documento ratio_transform is_pers)
				sum valor_total_chin, d
				keep if valor_total_chin<r(p99)
				
				global y valor_total_chin
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-in month `w'", color(gs0)) name("amount_ci_m`w'", replace) xtitle("sisben proxy score") ytitle("Average amount of cash-in") legend(off) 
				graph export "$graphs_rdd_v2/5.cash-in/`w'm_amount.png", replace
				
				rdrobust $y $x 
				outreg2 using "$tables/4.rdd_v2/5.cash-in/1.sharp/`w'm_amount.txt", replace
			restore
			
			*Fuzzy RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) numero_total_chin, by(documento ratio_transform is_pers)
				sum numero_total_chin, d
				keep if numero_total_chin<r(p99)
				
				global y numero_total_chin
				global x ratio_transform
				
				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/5.cash-in/2.fuzzy/`w'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) valor_total_chin, by(documento ratio_transform is_pers)
				sum valor_total_chin, d
				keep if valor_total_chin<r(p99)
				
				global y valor_total_chin
				global x ratio_transform
				
				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/5.cash-in/2.fuzzy/`w'm_amount.txt", replace
			restore
		}
	
	*2.6 Cash-out
		forvalues w=1/24{
		
			*Sharp RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) numero_total_chout, by(documento ratio_transform is_pers)
				sum numero_total_chout, d
				keep if numero_total_chout<r(p99)
				
				global y numero_total_chout
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-out month `w'", color(gs0)) name("number_co_m`w'", replace) xtitle("sisben proxy score") ytitle("Average number of cash-out") legend(off) 
				graph export "$graphs_rdd_v2/6.cash-out/`w'm_number.png", replace
				
				rdrobust $y $x 
				outreg2 using "$tables/4.rdd_v2/6.cash-out/1.sharp/`w'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) valor_total_chout, by(documento ratio_transform is_pers)
				sum valor_total_chout, d
				keep if valor_total_chout<r(p99)
				
				global y valor_total_chout
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-out month `w'", color(gs0)) name("amount_co_m`w'", replace) xtitle("sisben proxy score") ytitle("Average amount of cash-out") legend(off)  
				graph export "$graphs_rdd_v2/6.cash-out/`w'm_amount.png", replace
				
				rdrobust $y $x 
				outreg2 using "$tables/4.rdd_v2/6.cash-out/1.sharp/`w'm_amount.txt", replace
			restore
			
			*Fuzzy RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) numero_total_chout, by(documento ratio_transform is_pers)
				sum numero_total_chout, d
				keep if numero_total_chout<r(p99)
				
				global y numero_total_chout
				global x ratio_transform
				
				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/6.cash-out/2.fuzzy/`w'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) valor_total_chout, by(documento ratio_transform is_pers)
				sum valor_total_chout, d
				keep if valor_total_chout<r(p99)
				
				global y valor_total_chout
				global x ratio_transform
				
				rdrobust $y $x , fuzzy(is_pers)
				outreg2 using "$tables/4.rdd_v2/6.cash-out/2.fuzzy/`w'm_amount.txt", replace
			restore
		
		}

	log close
	
translate "$logs/2.rdd_range01_coff0.smcl" "$logs/2.rdd_range01_coff0.pdf"













