/*
Date: 13/03/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: Preliminary rd regressions using the merged data                                           
*/

clear all
set more off

*In Uniandes Cluster
	global data ""
	global raw "$data/7.raw_data"
	global raw_data_dnp "$raw\dnp"
	global temp_data "$data\8.temp_data"
	global raw_movii_saldos "$raw/saldos_no_trx"
	global raw_movii_trx "$raw/trx"
	global import_data "$data/5.import_data"
	global import_movii "$data\5.import_data\movii"
	global import_movii_trx "$import_movii/trx"
	global import_movii_balance "$import_movii/balances"
	global master_data "$data/6.master_data"
	global tables "$data/9.tables"
	global graphs "$data/4.graphs"
	global graphs_trx "$graphs/3.trx_stats"
	global graphs_rdd "$graphs/4.rdd"
	

*1.Load DNP data 
use "$master_data/2.movii_dnp_merged.dta", clear

global c 0.038
global range_rt 0.1

*2.Let's run the regressions!!!

	*2.1 balance
		foreach w in 4 7 13 19 25{
		*all sample
		local t = `w'-1
		
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_pers)
				sum saldo_cierre_mes, d 
				keep if saldo_cierre_mes<=r(p90)
				
				
				global y saldo_cierre_mes
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x , genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Balance first `t' months", color(gs0)) name("bal_`t'm", replace) xtitle("sisben proxy score") ytitle("Balance") legend(off)
				graph export "$graphs_rdd/1.balance/1.all_sample/`t'm.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/1.balance/1.all_sample/`t'm.txt", replace
			restore
		
		*group C
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_pers)
				keep if saldo_cierre_mes<=100000
				
				global y saldo_cierre_mes
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Balance first `t' months - group C", color(gs0)) name("bal_m`t'", replace) xtitle("sisben proxy score") ytitle("Balance") legend(off)
				graph export "$graphs_rdd/1.balance/2.group_c/`t'm.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/1.balance/2.group_c/`t'm.txt", replace
			restore
		}
			
		
	*2.2 online purchases
		foreach w in 4 7 13 19 25{
		*all sample
		local t = `w'-1
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) numero_total_comv, by(documento ratio_transform is_pers)
				sum numero_total_comv, d
				keep if numero_total_comv<r(p99)
				
				global y numero_total_comv
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Online purchases first `t' months", color(gs0)) name("number_op_m`t'", replace) xtitle("sisben proxy score") ytitle("Average number of online purchases") legend(off)
				graph export "$graphs_rdd/2.online_purch/1.all_sample/`t'm_number.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/2.online_purch/1.all_sample/`t'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) valor_total_comv, by(documento ratio_transform is_pers)
				sum valor_total_comv, d
				keep if valor_total_comv<r(p99)
				
				global y valor_total_comv
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Online purchases first `t' months", color(gs0)) name("amount_op_m`t'", replace) xtitle("sisben proxy score") ytitle("Average amount of online purchases") legend(off)
				graph export "$graphs_rdd/2.online_purch/1.all_sample/`t'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/2.online_purch/1.all_sample/`t'm_amount.txt", replace
			restore
		
		*group C
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) numero_total_comv, by(documento ratio_transform is_pers)
				sum numero_total_comv, d
				keep if numero_total_comv<r(p99)
				
				global y numero_total_comv
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Online purchases first `t' months - group C", color(gs0)) name("number_op_m`t'_gC", replace) xtitle("sisben proxy score") ytitle("Average number of online purchases") legend(off)
				graph export "$graphs_rdd/2.online_purch/2.group_c/`t'm_number.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/2.online_purch/2.group_c/`t'm_number.txt", replace
			restore
			
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) valor_total_comv, by(documento ratio_transform is_pers)
				sum valor_total_comv, d
				keep if valor_total_comv<r(p99)
				
				global y valor_total_comv
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Online purchases first `t' months - group C", color(gs0)) name("amount_op_m`t'_gC", replace) xtitle("sisben proxy score") ytitle("Average amount of online purchases") legend(off)
				graph export "$graphs_rdd/2.online_purch/2.group_c/`t'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/2.online_purch/2.group_c/`t'm_amount.txt", replace
			restore
		}

		
	*2.3 in-person purchases
		foreach w in 4 7 13 19 25{
		*all sample
		local t = `w'-1
		quietly
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) numero_total_comt, by(documento ratio_transform is_pers)
				sum numero_total_comt, d
				keep if numero_total_comt<r(p99)
				
				global y numero_total_comt
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("In-person purchases first `t' months", color(gs0)) name("number_inp_m`t'", replace) xtitle("sisben proxy score") ytitle("Average number of in-person purchases") legend(off)
				graph export "$graphs_rdd/3.in-person_purch/1.all_sample/`t'm_number.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/3.in-person_purch/1.all_sample/`t'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) valor_total_comt, by(documento ratio_transform is_pers)
				sum valor_total_comt, d
				keep if valor_total_comt<r(p99)
				
				global y valor_total_comt
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("In-person purchases first `t' months", color(gs0)) name("amount_inp_m`t'", replace) xtitle("sisben proxy score") ytitle("Average amount of in-person purchases") legend(off) 
				graph export "$graphs_rdd/3.in-person_purch/1.all_sample/`t'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/3.in-person_purch/1.all_sample/`t'm_amount.txt", replace
			restore
		
		*group C
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) numero_total_comt, by(documento ratio_transform is_pers)
				sum numero_total_comt, d
				keep if numero_total_comt<r(p99)
				
				global y numero_total_comt
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("In-person purchases first `t' months - group C", color(gs0)) name("number_inp_m`t'_gC", replace) xtitle("sisben proxy score") ytitle("Average number of in-person purchases") legend(off)
				graph export "$graphs_rdd/3.in-person_purch/2.group_c/`t'm_number.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/3.in-person_purch/2.group_c/`t'm_number.txt", replace
			restore
			
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) valor_total_comt, by(documento ratio_transform is_pers)
				sum valor_total_comt, d
				keep if valor_total_comt<r(p99)
				
				global y valor_total_comt
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("In-person purchases first `t' months - group C", color(gs0)) name("amount_inp_m`t'_gC", replace) xtitle("sisben proxy score") ytitle("Average amount of in-person purchases") legend(off)
				graph export "$graphs_rdd/3.in-person_purch/2.group_c/`t'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/3.in-person_purch/2.group_c/`t'm_amount.txt", replace
			restore
		}

	*2.4 Transfers
		foreach w in 4 7 13 19 25{
		*all sample
		local t = `w'-1
		quietly
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) numero_total_trf, by(documento ratio_transform is_pers)
				sum numero_total_trf, d
				keep if numero_total_trf<r(p99)
				
				global y numero_total_trf
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Transers first `t' months", color(gs0)) name("number_trf_m`t'", replace) xtitle("sisben proxy score") ytitle("Average number of transfers") legend(off)
				graph export "$graphs_rdd/4.transfer/1.all_sample/`t'm_number.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/4.transfer/1.all_sample/`t'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) valor_total_trf, by(documento ratio_transform is_pers)
				sum valor_total_trf, d
				keep if valor_total_trf<r(p99)
				
				global y valor_total_trf
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Transers first `t' months", color(gs0)) name("amount_trf_m`t'", replace) xtitle("sisben proxy score") ytitle("Average amount of transfers") legend(off) 
				graph export "$graphs_rdd/4.transfer/1.all_sample/`t'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/4.transfer/1.all_sample/`t'm_amount.txt", replace
			restore
		
		*group C
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) numero_total_trf, by(documento ratio_transform is_pers)
				sum numero_total_trf, d
				keep if numero_total_trf<r(p99)
				
				global y numero_total_trf
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Transers first `t' months - group C", color(gs0)) name("number_trf_m`t'_gC", replace) xtitle("sisben proxy score") ytitle("Average number of transfers") legend(off)
				graph export "$graphs_rdd/4.transfer/2.group_c/`t'm_number.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/4.transfer/2.group_c/`t'm_number.txt", replace
			restore
			
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) valor_total_trf, by(documento ratio_transform is_pers)
				sum valor_total_trf, d
				keep if valor_total_trf<r(p99)
				
				global y valor_total_trf
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Transers first `t' months - group C", color(gs0)) name("amount_trf_m`t'_gC", replace) xtitle("sisben proxy score") ytitle("Average amount of transfers") legend(off) 
				graph export "$graphs_rdd/4.transfer/2.group_c/`t'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/4.transfer/2.group_c/`t'm_amount.txt", replace
			restore
		}
	
	*2.5 Cash-in
		foreach w in 4 7 13 19 25{
		*all sample
		local t = `w'-1
		quietly
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) numero_total_chin, by(documento ratio_transform is_pers)
				sum numero_total_chin, d
				keep if numero_total_chin<r(p99)
				
				global y numero_total_chin
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-in first `t' months", color(gs0)) name("number_ci_m`t'", replace) xtitle("sisben proxy score") ytitle("Average number of cash-in") legend(off) 
				graph export "$graphs_rdd/5.cash-in/1.all_sample/`t'm_number.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/5.cash-in/1.all_sample/`t'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) valor_total_chin, by(documento ratio_transform is_pers)
				sum valor_total_chin, d
				keep if valor_total_chin<r(p99)
				
				global y valor_total_chin
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-in first `t' months", color(gs0)) name("amount_ci_m`t'", replace) xtitle("sisben proxy score") ytitle("Average amount of cash-in") legend(off) 
				graph export "$graphs_rdd/5.cash-in/1.all_sample/`t'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/5.cash-in/1.all_sample/`t'm_amount.txt", replace
			restore
		
		*group C
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) numero_total_chin, by(documento ratio_transform is_pers)
				sum numero_total_chin, d
				keep if numero_total_chin<r(p99)
				
				global y numero_total_chin
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-in first `t' months - group C", color(gs0)) name("number_ci_m`t'_gC", replace) xtitle("sisben proxy score") ytitle("Average number of cash-in") legend(off) 
				graph export "$graphs_rdd/5.cash-in/2.group_c/`t'm_number.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/5.cash-in/2.group_c/`t'm_number.txt", replace
			restore
			
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) valor_total_chin, by(documento ratio_transform is_pers)
				sum valor_total_chin, d
				keep if valor_total_chin<r(p99)
				
				global y valor_total_chin
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-in first `t' months - group C", color(gs0)) name("amount_ci_m`t'_gC", replace) xtitle("sisben proxy score") ytitle("Average amount of cash-in") legend(off) 
				graph export "$graphs_rdd/5.cash-in/2.group_c/`t'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/5.cash-in/2.group_c/`t'm_amount.txt", replace
			restore
		}
	
	*2.6 Cash-out
		foreach w in 4 7 13 19 25{
		*all sample
		local t = `w'-1
		quietly
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) numero_total_chout, by(documento ratio_transform is_pers)
				sum numero_total_chout, d
				keep if numero_total_chout<r(p99)
				
				global y numero_total_chout
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-out first `t' months", color(gs0)) name("number_co_m`t'", replace) xtitle("sisben proxy score") ytitle("Average number of cash-out") legend(off) 
				graph export "$graphs_rdd/6.cash-out/1.all_sample/`t'm_number.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/6.cash-out/1.all_sample/`t'm_number.txt", replace
			restore
			
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				keep if ratio_transform<$range_rt
				collapse (mean) valor_total_chout, by(documento ratio_transform is_pers)
				sum valor_total_chout, d
				keep if valor_total_chout<r(p99)
				
				global y valor_total_chout
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-out first `t' months", color(gs0)) name("amount_co_m`t'", replace) xtitle("sisben proxy score") ytitle("Average amount of cash-out") legend(off)  
				graph export "$graphs_rdd/6.cash-out/1.all_sample/`t'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/6.cash-out/1.all_sample/`t'm_amount.txt", replace
			restore
		
		*group C
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) numero_total_chout, by(documento ratio_transform is_pers)
				sum numero_total_chout, d
				keep if numero_total_chout<r(p99)
				
				global y numero_total_chout
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-out first `t' months - group C", color(gs0)) name("number_co_m`t'_gC", replace) xtitle("sisben proxy score") ytitle("Average number of cash-out") legend(off) 
				graph export "$graphs_rdd/6.cash-out/2.group_c/`t'm_number.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/6.cash-out/2.group_c/`t'm_number.txt", replace
			restore
			
			preserve
				keep if ind_grupo_sisben_4=="C"
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n <`w'
				collapse (mean) valor_total_chout, by(documento ratio_transform is_pers)
				sum valor_total_chout, d
				keep if valor_total_chout<r(p99)
				
				global y valor_total_chout
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x, genvars hide ci(95) c($c)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Cash-out first `t' months - group C", color(gs0)) name("amount_co_m`t'_gC", replace) xtitle("sisben proxy score") ytitle("Average amount of cash-out") legend(off)  
				graph export "$graphs_rdd/6.cash-out/2.group_c/`t'm_amount.png", replace
				
				rdrobust $y $x , c($c)
				outreg2 using "$tables/1.rdd_outputs/6.cash-out/2.group_c/`t'm_amount.txt", replace
			restore
		}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	