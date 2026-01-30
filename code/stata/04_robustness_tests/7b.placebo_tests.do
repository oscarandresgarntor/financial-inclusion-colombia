/*
Date: 3/06/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: Let's run placebo tests for the outcomes of interest using 
different cutoff values
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
	global graphs_rdd_v2 "$graphs/5.rdd_v2"
	global logs "$data/11.logs"
	global graphs_rdd_fpanel_v3 "$graphs/6.rdd_fullpanel_v3"
	global graphs_rdd_panel_may20_v4 "$graphs/7.rdd_panel_may20_v4"

	
	
**************************************************
/*PLACEBO TEST


*/			
**************************************************

*1.BALANCE
*First Placebo for those ABOVE the cutoff that received the treatment
************************Let's do balance by semester - above the cutoff
use "$master_data/3b.panel_data.dta", clear 

keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

keep if is_receiver==1

*create semester variable
sort documento mes
bys documento:  gen obs_n = _n

    gen s1 = 0
	replace s1=1 if obs_n<7
	
	gen s2 = 0
	replace s2=1 if obs_n>=7 & obs_n<13
	
	gen s3 = 0
	replace s3=1 if obs_n>=13 & obs_n<19
	
	gen s4 = 0
	replace s4=1 if obs_n>=19 & obs_n<25
	
	gen s5 = 0
	replace s5=1 if obs_n>=25 & obs_n<31
	
	gen semester=0
	replace semester =1 if s1==1
	replace semester =2 if s2==1
	replace semester =3 if s3==1
	replace semester =4 if s4==1
	replace semester =5 if s5==1
	

keep documento is_hog is_pers ratio_transform mes s1 s2 s3 s4 s5 valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
global c 0.03
global range_rt -0.1		
		
		
matrix coeff_sharp=J(5,3,.)
matrix coeff_fuzzy=J(5,3,.)
	*5.1 balance
		forvalues w=1/5 {

			*Sharp RD
			preserve
				keep if s`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_receiver s`w')
				sum saldo_cierre_mes, d 
				keep if saldo_cierre_mes<=r(p99)
				
				
				global y saldo_cierre_mes
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				
				rdplot $y $x , genvars hide ci(95) p(1)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 1" )) title("Sharp RD - Balance semester `w'", color(gs0)) name("bal_`w's_sharp", replace) xtitle("SISBEN score") ytitle("Balance - unit in COP") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/1.balance/1.placebo_above/`w's_sharp.png", replace
				
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x
				outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/1.sharp/1.placebo_above/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
		}
	
	matrix colnames coeff_sharp = s coeff se 
	matrix list coeff_sharp

	matrix colnames coeff_fuzzy	= s coeff se 
	matrix list coeff_fuzzy	
		
		
			*5.2. Let's plot the sharp rdd coefficients in a graph 
			svmat coeff_sharp
			rename coeff_sharp1 s 
			rename coeff_sharp2 coeff 
			rename coeff_sharp3 se 
			
			g ls = coeff + se*(invnormal(0.975))
			g li = coeff - se*(invnormal(0.975))
			
			tw	(rcap ls li s,lc(black)msize(zero) lw(medium)) (sc coeff s,m(O) mfc(white) mlc(black) lw(medium)) (line coeff s), name("sharp_coeff_s", replace) xtitle("Semester") ytitle("ITT coefficient - unit in COP") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/1.balance/1.placebo_above/sharp_semester.png", replace
			
			
*BALANCE	
*Second Placebo for those BELOW the cutoff that did not received the treatment
************************Let's do balance by semester - above the cutoff
use "$master_data/3b.panel_data.dta", clear 

keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

keep if is_receiver==0

*create semester variable
sort documento mes
bys documento:  gen obs_n = _n

    gen s1 = 0
	replace s1=1 if obs_n<7
	
	gen s2 = 0
	replace s2=1 if obs_n>=7 & obs_n<13
	
	gen s3 = 0
	replace s3=1 if obs_n>=13 & obs_n<19
	
	gen s4 = 0
	replace s4=1 if obs_n>=19 & obs_n<25
	
	gen s5 = 0
	replace s5=1 if obs_n>=25 & obs_n<31
	
	gen semester=0
	replace semester =1 if s1==1
	replace semester =2 if s2==1
	replace semester =3 if s3==1
	replace semester =4 if s4==1
	replace semester =5 if s5==1
	

keep documento is_hog is_pers ratio_transform mes s1 s2 s3 s4 s5 valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
global c -0.03
global range_rt -0.1		
		
		
matrix coeff_sharp=J(5,3,.)
matrix coeff_fuzzy=J(5,3,.)
	*5.1 balance
		forvalues w=1/5 {

			*Sharp RD
			preserve
				keep if s`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_receiver s`w')
				sum saldo_cierre_mes, d 
				keep if saldo_cierre_mes<=r(p99)
				
				
				global y saldo_cierre_mes
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				
				rdplot $y $x , genvars hide ci(95) p(1)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 1" )) title("Sharp RD - Balance semester `w'", color(gs0)) name("bal_`w's_sharp", replace) xtitle("SISBEN score") ytitle("Balance - unit in COP") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/1.balance/2.placebo_below/`w's_sharp.png", replace
				
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x
				outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/1.sharp/2.placebo_below/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
		}
	
	matrix colnames coeff_sharp = s coeff se 
	matrix list coeff_sharp

	matrix colnames coeff_fuzzy	= s coeff se 
	matrix list coeff_fuzzy	
		
		
			*5.2. Let's plot the sharp rdd coefficients in a graph 
			svmat coeff_sharp
			rename coeff_sharp1 s 
			rename coeff_sharp2 coeff 
			rename coeff_sharp3 se 
			
			g ls = coeff + se*(invnormal(0.975))
			g li = coeff - se*(invnormal(0.975))
			
			tw	(rcap ls li s,lc(black)msize(zero) lw(medium)) (sc coeff s,m(O) mfc(white) mlc(black) lw(medium)) (line coeff s), name("sharp_coeff_s", replace) xtitle("Semester") ytitle("ITT coefficient - unit in COP") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/1.balance/2.placebo_below/sharp_semester.png", replace
			
			
			
			
			
*TRANSFERS	
*Placebo ABOVE the cutoff for the treated individuals		
************************Let's do transfers by semester
use "$master_data/3b.panel_data.dta", clear 

keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

keep if is_receiver==1

*create semester variable
sort documento mes
bys documento:  gen obs_n = _n

    gen s1 = 0
	replace s1=1 if obs_n<7
	
	gen s2 = 0
	replace s2=1 if obs_n>=7 & obs_n<13
	
	gen s3 = 0
	replace s3=1 if obs_n>=13 & obs_n<19
	
	gen s4 = 0
	replace s4=1 if obs_n>=19 & obs_n<25
	
	gen s5 = 0
	replace s5=1 if obs_n>=25 & obs_n<31
	
	gen semester=0
	replace semester =1 if s1==1
	replace semester =2 if s2==1
	replace semester =3 if s3==1
	replace semester =4 if s4==1
	replace semester =5 if s5==1
	

keep documento is_hog is_pers ratio_transform mes s1 s2 s3 s4 s5 valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
global c 0
global range_rt -0.1		
		
		
matrix coeff_sharp=J(5,3,.)
matrix coeff_fuzzy=J(5,3,.)
	*5.1 transfers
		forvalues w=1/5 {

			*Sharp RD
			preserve
				keep if s`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) transferencias, by(documento ratio_transform is_receiver s`w')
				sum transferencias, d 
				
				
				global y transferencias
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				
				rdplot $y $x , genvars hide ci(95) p(1)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 1" )) title("Sharp RD - Transfers semester `w'", color(gs0)) name("tran_`w's_sharp", replace) xtitle("SISBEN score") ytitle("Transfer") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/4.transfer/1.placebo_above/`w's_sharp.png", replace
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x
				outreg2 using "$tables/6.rdd_panel_may20_v4/4.transfer/1.sharp/1.placebo_above/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
		}
	
	matrix colnames coeff_sharp = s coeff se 
	matrix list coeff_sharp

	matrix colnames coeff_fuzzy	= s coeff se 
	matrix list coeff_fuzzy	
		
		
			*5.2. Let's plot the sharp rdd coefficients in a graph 
			svmat coeff_sharp
			rename coeff_sharp1 s 
			rename coeff_sharp2 coeff 
			rename coeff_sharp3 se 
			
			g ls = coeff + se*(invnormal(0.975))
			g li = coeff - se*(invnormal(0.975))
			
			tw	(rcap ls li s,lc(black)msize(zero) lw(medium)) (sc coeff s,m(O) mfc(white) mlc(black) lw(medium)) (line coeff s), name("sharp_coeff_s_transf", replace) xtitle("Semester") ytitle("ITT coefficient") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/4.transfer/1.placebo_above/sharp_semester.png", replace
			

*TRANSFERS	
*Placebo BELOW the cutoff for the not-treated individuals		
************************Let's do transfers by semester
use "$master_data/3b.panel_data.dta", clear 

keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

keep if is_receiver==0

*create semester variable
sort documento mes
bys documento:  gen obs_n = _n

    gen s1 = 0
	replace s1=1 if obs_n<7
	
	gen s2 = 0
	replace s2=1 if obs_n>=7 & obs_n<13
	
	gen s3 = 0
	replace s3=1 if obs_n>=13 & obs_n<19
	
	gen s4 = 0
	replace s4=1 if obs_n>=19 & obs_n<25
	
	gen s5 = 0
	replace s5=1 if obs_n>=25 & obs_n<31
	
	gen semester=0
	replace semester =1 if s1==1
	replace semester =2 if s2==1
	replace semester =3 if s3==1
	replace semester =4 if s4==1
	replace semester =5 if s5==1
	

keep documento is_hog is_pers ratio_transform mes s1 s2 s3 s4 s5 valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
global c 0
global range_rt -0.1		
		
		
matrix coeff_sharp=J(5,3,.)
matrix coeff_fuzzy=J(5,3,.)
	*5.1 transfers
		forvalues w=1/5 {

			*Sharp RD
			preserve
				keep if s`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) transferencias, by(documento ratio_transform is_receiver s`w')
				sum transferencias, d 
				
				
				global y transferencias
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				
				rdplot $y $x , genvars hide ci(95) p(1)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 1" )) title("Sharp RD - Transfers semester `w'", color(gs0)) name("tran_`w's_sharp", replace) xtitle("SISBEN score") ytitle("Transfer") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/4.transfer/2.placebo_below/`w's_sharp.png", replace
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x
				outreg2 using "$tables/6.rdd_panel_may20_v4/4.transfer/1.sharp/2.placebo_below/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
		}
	
	matrix colnames coeff_sharp = s coeff se 
	matrix list coeff_sharp

	matrix colnames coeff_fuzzy	= s coeff se 
	matrix list coeff_fuzzy	
		
		
			*5.2. Let's plot the sharp rdd coefficients in a graph 
			svmat coeff_sharp
			rename coeff_sharp1 s 
			rename coeff_sharp2 coeff 
			rename coeff_sharp3 se 
			
			g ls = coeff + se*(invnormal(0.975))
			g li = coeff - se*(invnormal(0.975))
			
			tw	(rcap ls li s,lc(black)msize(zero) lw(medium)) (sc coeff s,m(O) mfc(white) mlc(black) lw(medium)) (line coeff s), name("sharp_coeff_s_transf", replace) xtitle("Semester") ytitle("ITT coefficient") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/4.transfer/2.placebo_below/sharp_semester.png", replace

			
*CASH-OUT
*Placebo ABOVE the cutoff for treated individuals 			
************************Let's do cash-out by semester
use "$master_data/3b.panel_data.dta", clear 

keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

keep if is_receiver==1

*create semester variable
sort documento mes
bys documento:  gen obs_n = _n

    gen s1 = 0
	replace s1=1 if obs_n<7
	
	gen s2 = 0
	replace s2=1 if obs_n>=7 & obs_n<13
	
	gen s3 = 0
	replace s3=1 if obs_n>=13 & obs_n<19
	
	gen s4 = 0
	replace s4=1 if obs_n>=19 & obs_n<25
	
	gen s5 = 0
	replace s5=1 if obs_n>=25 & obs_n<31
	
	gen semester=0
	replace semester =1 if s1==1
	replace semester =2 if s2==1
	replace semester =3 if s3==1
	replace semester =4 if s4==1
	replace semester =5 if s5==1
	

keep documento is_hog is_pers ratio_transform mes s1 s2 s3 s4 s5 valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
global c 0
global range_rt -0.1		
		
		
matrix coeff_sharp=J(5,3,.)
matrix coeff_fuzzy=J(5,3,.)
	*5.1 cashout
		forvalues w=1/5 {

			*Sharp RD
			preserve
				keep if s`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) cashout, by(documento ratio_transform is_receiver s`w')
				sum cashout, d 
				*keep if cashout<=r(p90)
				
				
				global y cashout
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				
				rdplot $y $x , genvars hide ci(95) p(1)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 1" )) title("Sharp RD - Cash-out semester `w'", color(gs0)) name("co_`w's_sharp", replace) xtitle("SISBEN score") ytitle("Cash-out") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/6.cash-out/1.placebo_above/`w's_sharp.png", replace
				
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x
				outreg2 using "$tables/6.rdd_panel_may20_v4/6.cash-out/1.sharp/1.placebo_above/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
		}
	
	matrix colnames coeff_sharp = s coeff se 
	matrix list coeff_sharp

	matrix colnames coeff_fuzzy	= s coeff se 
	matrix list coeff_fuzzy	
		
		
			*5.2. Let's plot the sharp rdd coefficients in a graph 
			svmat coeff_sharp
			rename coeff_sharp1 s 
			rename coeff_sharp2 coeff 
			rename coeff_sharp3 se 
			
			g ls = coeff + se*(invnormal(0.975))
			g li = coeff - se*(invnormal(0.975))
			
			tw	(rcap ls li s,lc(black)msize(zero) lw(medium)) (sc coeff s,m(O) mfc(white) mlc(black) lw(medium)) (line coeff s), name("sharp_coeff_s_cashout", replace) xtitle("Semester") ytitle("ITT coefficient") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/6.cash-out/1.placebo_above/sharp_semester.png", replace
			

			
*CASH-OUT
*Placebo BELOW the cutoff for not-treated individuals 			
************************Let's do cash-out by semester
use "$master_data/3b.panel_data.dta", clear 

keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

keep if is_receiver==0

*create semester variable
sort documento mes
bys documento:  gen obs_n = _n

    gen s1 = 0
	replace s1=1 if obs_n<7
	
	gen s2 = 0
	replace s2=1 if obs_n>=7 & obs_n<13
	
	gen s3 = 0
	replace s3=1 if obs_n>=13 & obs_n<19
	
	gen s4 = 0
	replace s4=1 if obs_n>=19 & obs_n<25
	
	gen s5 = 0
	replace s5=1 if obs_n>=25 & obs_n<31
	
	gen semester=0
	replace semester =1 if s1==1
	replace semester =2 if s2==1
	replace semester =3 if s3==1
	replace semester =4 if s4==1
	replace semester =5 if s5==1
	

keep documento is_hog is_pers ratio_transform mes s1 s2 s3 s4 s5 valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
global c 0
global range_rt -0.1		
		
		
matrix coeff_sharp=J(5,3,.)
matrix coeff_fuzzy=J(5,3,.)
	*5.1 cashout
		forvalues w=1/5 {

			*Sharp RD
			preserve
				keep if s`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) cashout, by(documento ratio_transform is_receiver s`w')
				sum cashout, d 
				*keep if cashout<=r(p90)
				
				
				global y cashout
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				
				rdplot $y $x , genvars hide ci(95) p(1)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 1" )) title("Sharp RD - Cash-out semester `w'", color(gs0)) name("co_`w's_sharp", replace) xtitle("SISBEN score") ytitle("Cash-out") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/6.cash-out/2.placebo_below/`w's_sharp.png", replace
				
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x
				outreg2 using "$tables/6.rdd_panel_may20_v4/6.cash-out/1.sharp/2.placebo_below/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
		}
	
	matrix colnames coeff_sharp = s coeff se 
	matrix list coeff_sharp

	matrix colnames coeff_fuzzy	= s coeff se 
	matrix list coeff_fuzzy	
		
		
			*5.2. Let's plot the sharp rdd coefficients in a graph 
			svmat coeff_sharp
			rename coeff_sharp1 s 
			rename coeff_sharp2 coeff 
			rename coeff_sharp3 se 
			
			g ls = coeff + se*(invnormal(0.975))
			g li = coeff - se*(invnormal(0.975))
			
			tw	(rcap ls li s,lc(black)msize(zero) lw(medium)) (sc coeff s,m(O) mfc(white) mlc(black) lw(medium)) (line coeff s), name("sharp_coeff_s_cashout", replace) xtitle("Semester") ytitle("ITT coefficient") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/6.cash-out/2.placebo_below/sharp_semester.png", replace
			