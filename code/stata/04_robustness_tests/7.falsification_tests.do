/*
Date: 15/04/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: RD design falsification tests                                          
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

*1.Load DNP data 
use "$master_data/2.movii_dnp_merged.dta", clear

	*1.i. Let's normalize the running variable
	codebook ratio_transform
	replace ratio_transform = 0.038 - ratio_transform
	
	
*2. Let's run some falsification tests
	
	*2.i. cut-off
	
		*2.i.1. histogram of SIBEN score movii users vs IS receivers 
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			
			twoway (histogram ratio_transform if ratio_transform>-.1, start(-.1) bin(500) color(red%60)) ///        
		   (histogram ratio_transform if ratio_transform>-.1 & is_pers==1, start(-.1) bin(500) color(green%60)), ///   
		   legend(order(1 "Movii users" 2 "IS receivers" )) name("hist_movii_is", replace) xtitle("sisben proxy score")
		   graph export "$graphs_rdd_v2/9.falsification/1_hist_movii_is.png", replace
		restore
		
		*2.i.2. histogram of SISBEN score movii users vs IS NO receivers 
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			
			twoway (histogram ratio_transform if ratio_transform>-.1, start(-.1) bin(500) color(red%60)) ///        
		   (histogram ratio_transform if ratio_transform>-.1 & is_pers==0, start(-.1) bin(500) color(green%60)), ///   
		   legend(order(1 "Movii users" 2 "IS no receivers" )) name("hist_movii_no_is", replace) xtitle("sisben proxy score")
		   graph export "$graphs_rdd_v2/9.falsification/2_hist_movii_no_is.png", replace
		restore
		
		*2.i.3. Let's plot the probability of receiving IS against ratio_transform
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			
			global y is_pers
			global x ratio_transform
			global c 0
			su $x
			global x_min = r(min)
			global x_max = r(max)
			
			rdplot $y $x , genvars hide ci(95) c($c)
			
			*default rdplot
			twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("rdplot_default", replace) xtitle("sisben proxy score") ytitle("IS recipient") legend(off)
			graph export "$graphs_rdd_v2/7.cutoff/2_rdplot_is_ratio_default.png", replace
			
			rdrobust $y $x , c($c)	
		restore
		
		*2.i.4. see it for observations with ratio_transform greater than -0.1
			preserve
				*keep if ind_grupo_sisben_4=="C"
				bys documento: egen min_month = min(mes)
				keep if min_month == mes
				keep if ratio_transform>-0.1
				
				global y is_pers
				global x ratio_transform
				global c 0
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x if $x >-0.1, genvars hide ci(95) c($c)
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
	(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
	(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
	xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("rdplot_default", replace) xtitle("sisben proxy score") ytitle("IS recipient") legend(off)
				graph export "$graphs_rdd_v2/7.cutoff/2_rdplot_is_ratio_default_lower01.png", replace

				rdrobust $y $x if $x >-0.1, c($c)
			restore
		
	*2.ii. scatter SISBEN score against predetermined variables
	
		*2.ii.1. Age
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			keep if ratio_transform>-0.1
			
			global y age
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_age", replace) xtitle("sisben proxy score") ytitle("age") legend(off)
			graph export "$graphs_rdd_v2/9.falsification/3_rdplot_sisben_age.png", replace

			rdrobust $y $x if $x >-0.1
		restore

		*2.ii.1. sex
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			keep if ratio_transform>-0.1
			
			gen sex = 0
			replace sex = 1 if gender == "F"
			
			global y sex
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_sex", replace) xtitle("sisben proxy score") ytitle("sex") legend(off)
			graph export "$graphs_rdd_v2/9.falsification/4_rdplot_sisben_sex.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore
		
		*2.ii.1. Bogota
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			keep if ratio_transform>-0.1
			
			gen bogota = 0
			replace bogota = 1 if cod_mpio == 11001
			
			global y bogota
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_bogota", replace) xtitle("sisben proxy score") ytitle("Bogota probability") legend(off)
			graph export "$graphs_rdd_v2/9.falsification/5_rdplot_sisben_bogota.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore
		
		*2.ii.1. Medellin
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			keep if ratio_transform>-0.1
			
			gen medellin = 0
			replace medellin = 1 if cod_mpio == 5001
			
			global y medellin
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_medellin", replace) xtitle("sisben proxy score") ytitle("Medellin probability") legend(off)
			graph export "$graphs_rdd_v2/9.falsification/8_rdplot_sisben_medellin.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore
		
		
		*2.ii.1. cab_municipal
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			keep if ratio_transform>-0.1
			
			gen cab_municipal = 0
			replace cab_municipal = 1 if cod_clase == 1
			
			global y cab_municipal
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_cabmunicipal", replace) xtitle("sisben proxy score") ytitle("Cabecera municipal probability") legend(off)
			graph export "$graphs_rdd_v2/9.falsification/6_rdplot_sisben_cabmunicipal.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore
		
		*2.ii.1. rural
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			keep if ratio_transform>-0.1
			
			gen rural = 0
			replace rural = 1 if cod_clase == 3
			
			global y rural
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_rural", replace) xtitle("sisben proxy score") ytitle("Rural probability") legend(off)
			graph export "$graphs_rdd_v2/9.falsification/7_rdplot_sisben_rural.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore

	