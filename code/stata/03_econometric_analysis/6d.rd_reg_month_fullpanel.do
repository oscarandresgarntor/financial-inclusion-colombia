/*
Date: 22/04/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: Let's declare dataset a pnel dataset 
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

		
*1. Let's load the new panel data 
use "$master_data/3b.panel_data.dta", clear 

	//So the number of users goes like this:
		//1. 370,090 total users 
			*codebook documento
		//2. 167,139 users flagged as IS elegible 
			*codebook documento if is_pers==1
		//3. 96,598 users that effectively received IS at some any point in time
			*codebook documento if is_receiver==1
		//4. 160,475 users with no financial aid at any point 
			*codebook documento if tipo_usuario==3
		//5. 113,017 users that received financial aid but not from IS
			*codebook documento if is_receiver ==0 & tipo_usuario !=3
		//6. 242 users that received financial aid from IS but they and their 
		//families are flagged as no IS beneficiaries
			*codebook documento if is_hog ==0 & is_pers ==0 & is_receiver ==1
		//7. 49,487 users that actually received financial aid from IS and 
		//created their account between 01mar2020 - 31may2020
			*codebook documento if is_receiver == 1 & created_on >date("01mar2020", "DMY") //
			//& created_on < date("31may2020", "DMY")
		//8.53,043 users with no financial aid that created their account before 31may2020
			*codebook documento if tipo_usuario == 3 & created_on < date("31may2020", "DMY")
		
*2. Let's plot the chances of receiving IS using our new is_receiver
	
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		
		twoway (histogram ratio_transform if ratio_transform>-.1, start(-.1) bin(500) color(red%60)) ///        
       (histogram ratio_transform if ratio_transform>-.1 & is_receiver==1, start(-.1) bin(500) color(green%60)), ///   
       legend(order(1 "Movii users" 2 "IS users" )) name("hist_movii_is", replace) xtitle("sisben proxy score")
	   graph export "$graphs_rdd_fpanel_v3/7.cutoff/1_hist_movii_is.png", replace
	restore
	
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		keep if ratio_transform>-0.1
		
		global y is_receiver
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
		graph export "$graphs_rdd_fpanel_v3/7.cutoff/2_rdplot_is_ratio_default_lower01.png", replace

		rdrobust $y $x if $x >-0.1
	restore

	
*2.Let's structure the data with the variables that we need
keep documento is_hog is_pers ratio_transform mes valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
global c 0
global range_rt -0.1
	
	

*3.Let's run the regressions!!!

	*3.1 balance
		forvalues w=1/24{
		
			*Sharp RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_receiver)
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
				graph export "$graphs_rdd_fpanel_v3/1.balance/`w'm.png", replace
				
				
				rdrobust $y $x
				outreg2 using "$tables/5.rdd_fullpanel_v3/1.balance/1.sharp/`w'm.txt", replace
			restore
			
			*Fuzzy RD
			preserve
				keep if created_on>date("30sep2019", "DMY")
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_receiver)
				sum saldo_cierre_mes, d 
				keep if saldo_cierre_mes<=r(p90)
				
				global y saldo_cierre_mes
				global x ratio_transform

				rdrobust $y $x , fuzzy(is_receiver)
				outreg2 using "$tables/5.rdd_fullpanel_v3/1.balance/2.fuzzy/`w'm.txt", replace
			restore
		}
	

				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
		