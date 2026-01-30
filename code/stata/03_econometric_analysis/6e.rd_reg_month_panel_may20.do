/*
Date: 24/04/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: Let's run the empirical strategy using only the cohort of users 
that created their account between October 2019 and May 2020
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

		
*1. Let's load the new panel data 
use "$master_data/3b.panel_data.dta", clear 

	*1.i. Let's keep only users that created their account between 10/19 - 05/20
	keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

	//So the number of users goes like this:
		//1. 115,025 total users 
			*codebook documento
		//2. 76,808 users flagged as IS elegible 
			*codebook documento if is_pers==1
		//2b. 82,918 users IS eligible if their SISBEN score is above 0
			*codebook documento if ratio_transform >0
		//3. 51,056 users that effectively received IS at any point in time
			*codebook documento if is_receiver==1
		//4. 53,471 users with no financial aid at any point 
			*codebook documento if tipo_usuario==3
		//5. 10,498 users that received financial aid but not from IS
			*codebook documento if is_receiver ==0 & tipo_usuario !=3
		//6. 33 users that received financial aid from IS but they and their 
		//families are flagged as no IS beneficiaries
			*codebook documento if is_hog ==0 & is_pers ==0 & is_receiver ==1
	
*2. Dig deeper on those that do not receive financial aid - 53,471 users
		//1. 0 is the subsidy amount for all users that do not receive any financial aid
			*tab valor_subsidio if tipo_usuario ==3
		//2. 31,625 are the users belonging to a household flagged as IS by DNP
			*codebook documento if tipo_usuario == 3 & is_hog == 1
		//3. 23,259 are the users flagged as IS by DNP
			*codebook documento if tipo_usuario == 3 & is_pers == 1
		//4. 7,769 users belong to a household that belongs to FEA 
			*codebook documento if tipo_usuario == 3 & fea_hog == 1
		//5. 4,781 users belong to FEA 
			*codebook documento if tipo_usuario == 3 & fea_pers == 1
		//6. 1,748 users, either them or their household, are in Colombia Mayor 
			*codebook documento if tipo_usuario == 3 & (cm_benef_hog == 1 | cm_benef_pers == 1)
		//7. 1,951 users, either them or their household, are in JEA
			*codebook documento if tipo_usuario == 3 & (jea_hog  == 1 | jea_pers == 1)
		//8. 2,283 users, either them or their household, are in IVA
			*codebook documento if tipo_usuario == 3 & (iva_hog == 1 | iva_pers == 1)
			
*2. Let's plot the chances of receiving IS using our new is_receiver
	
	*2.i. Let's plot the histogram of ratio transform of Movii users vs IS receivers
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		
		twoway (histogram ratio_transform if ratio_transform>-.1, start(-.1) bin(500) color(red%60)) ///        
       (histogram ratio_transform if ratio_transform>-.1 & is_receiver==1, start(-.1) bin(500) color(green%60)), ///   
       legend(order(1 "Movii users" 2 "IS users" )) name("hist_movii_is", replace) xtitle("sisben proxy score")
	   graph export "$graphs_rdd_panel_may20_v4/7.cutoff/1_hist_movii_is.png", replace
	restore
	
		*2.i.b. Let's plot the histogram of ratio transform of Movii users non treated vs treated
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			
			twoway (histogram ratio_transform if ratio_transform>-.1 & is_receiver==0, start(-.1) bin(500) color(red%60)) ///        
		   (histogram ratio_transform if ratio_transform>-.1 & is_receiver==1, start(-.1) bin(500) color(green%60)), ///   
		   legend(order(1 "Non treated users" 2 "IS users" )) name("hist_is_vs_nontreated", replace) xtitle("sisben proxy score")
		   graph export "$graphs_rdd_panel_may20_v4/7.cutoff/1b_hist_is-tretaed_vs_nontreated.png", replace
		restore
	
	*2.ii. Let's run the rdplot and rdrobust of the probability of receiving IS
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
		
		rdplot $y $x if $x >-0.1, genvars hide ci(95) p(1)
		*default rdplot
		twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("rdplot_default", replace) xtitle("SISBEN score") ytitle("IS treated probability") legend(off) graphregion(color(white)) bgcolor(white)
		graph export "$graphs_rdd_panel_may20_v4/7.cutoff/2_rdplot_is_ratio_default_lower01.png", replace

		rdrobust $y $x if $x >-0.1
	restore
	
	*2.iii. Let's run the RD density under this sample
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		
		rddensity ratio_transform, plot graph_opt(xtitle("SISBEN score") graphregion(color(white)) bgcolor(white) legend(off))
		graph export "$graphs_rdd_panel_may20_v4/8.rddensity/2_rddensity_movii.png", replace
	restore 
	
		*RD density but only with the non-treated
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			
			rddensity ratio_transform if is_pers==0, plot graph_opt(xtitle("SISBEN score") graphregion(color(white)) bgcolor(white))
			*graph export "$graphs_rdd_panel_may20_v4/8.rddensity/2_rddensity_movii.png", replace
		restore 
	
	*2.iv. full sample distribution on ratio_transform
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		
		histogram ratio_transform if ratio_transform>-.1 
	   graph export "$graphs_rdd_panel_may20_v4/8.rddensity/1_hist_movii.png", replace
	restore
	
	
*3.Let's run some falsification tests

		*3.i. histogram of SISBEN score movii users vs IS NO receivers 
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			
			twoway (histogram ratio_transform if ratio_transform>-.1, start(-.1) bin(500) color(red%60)) ///        
		   (histogram ratio_transform if ratio_transform>-.1 & is_pers==0, start(-.1) bin(500) color(green%60)), ///   
		   legend(order(1 "Movii users" 2 "IS no receivers" )) name("hist_movii_no_is", replace) xtitle("sisben proxy score")
		   graph export "$graphs_rdd_panel_may20_v4/9.falsification/2_hist_movii_no_is.png", replace
		restore
		
		*3.ii. Age
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_age", replace) xtitle("sisben proxy score") ytitle("age") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/9.falsification/3_rdplot_sisben_age.png", replace

			rdrobust $y $x if $x >-0.1
		restore
		
		*3.iii. sex
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_sex", replace) xtitle("sisben proxy score") ytitle("sex") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/9.falsification/4_rdplot_sisben_sex.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore
		
		*3.iv. Bogota
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
			graph export "$graphs_rdd_panel_may20_v4/9.falsification/5_rdplot_sisben_bogota.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore
		
		*3.v. rural
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
			graph export "$graphs_rdd_panel_may20_v4/9.falsification/7_rdplot_sisben_rural.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore
		
				*3.v. urban
			preserve
				bys documento: egen min_month = min(mes)
				keep if min_month == mes
				keep if ratio_transform>-0.1
				
				gen urban = 0
				replace urban = 1 if cod_clase == 1
				
				global y urban
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
		legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_urban", replace) xtitle("sisben proxy score") ytitle("urban probability") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/9.falsification/7b_rdplot_sisben_urban.png", replace
				
				rdrobust $y $x if $x >-0.1
			restore
		
		*3.vi. Medellin
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
			graph export "$graphs_rdd_panel_may20_v4/9.falsification/8_rdplot_sisben_medellin.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore
		
		*3.vii. Familias en accion
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			keep if ratio_transform>-0.1
			
			
			global y fea_pers
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_fea", replace) xtitle("sisben proxy score") ytitle("FEA probability") legend(off)
			graph export "$graphs_rdd_panel_may20_v4/9.falsification/9_rdplot_sisben_fea.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore
		
				*3.vii.b. Familias en accion - hogar
				preserve
					bys documento: egen min_month = min(mes)
					keep if min_month == mes
					keep if ratio_transform>-0.1
					
					
					global y fea_hog
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
			legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_fea_hog", replace) xtitle("sisben proxy score") ytitle("FEA_hog probability") legend(off)
					graph export "$graphs_rdd_panel_may20_v4/9.falsification/9b_rdplot_sisben_fea_hog.png", replace
					
					rdrobust $y $x if $x >-0.1
				restore

		*3.viii. Colombia mayor
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			keep if ratio_transform>-0.1
			
			
			global y cm_benef_pers
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_cm", replace) xtitle("sisben proxy score") ytitle("CM probability") legend(off)
			graph export "$graphs_rdd_panel_may20_v4/9.falsification/10_rdplot_sisben_cm.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore
		
			*3.viii.b. Colombia mayor
			preserve
				bys documento: egen min_month = min(mes)
				keep if min_month == mes
				keep if ratio_transform>-0.1
				
				
				global y cm_benef_hog
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
		legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_cm_hog", replace) xtitle("sisben proxy score") ytitle("CM_hog probability") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/9.falsification/10b_rdplot_sisben_cm_hog.png", replace
				
				rdrobust $y $x if $x >-0.1
			restore
			
		*3.ix. Jovenes en accion
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			keep if ratio_transform>-0.1
			
			
			global y jea_pers
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_jea", replace) xtitle("sisben proxy score") ytitle("JEA probability") legend(off)
			graph export "$graphs_rdd_panel_may20_v4/9.falsification/11_rdplot_sisben_jea.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore		
			
			*3.ix.b. Jovenes en accion
			preserve
				bys documento: egen min_month = min(mes)
				keep if min_month == mes
				keep if ratio_transform>-0.1
				
				
				global y jea_hog
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
		legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_jea_hog", replace) xtitle("sisben proxy score") ytitle("JEA_hog probability") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/9.falsification/11b_rdplot_sisben_jea_hog.png", replace
				
				rdrobust $y $x if $x >-0.1
			restore		
			
		*3.x. IVA
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			keep if ratio_transform>-0.1
			
			
			global y iva_pers
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
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_iva", replace) xtitle("sisben proxy score") ytitle("IVA probability") legend(off)
			graph export "$graphs_rdd_panel_may20_v4/9.falsification/12_rdplot_sisben_iva.png", replace
			
			rdrobust $y $x if $x >-0.1
		restore		
			
			*3.x.b. IVA hogar
			preserve
				bys documento: egen min_month = min(mes)
				keep if min_month == mes
				keep if ratio_transform>-0.1
				
				
				global y iva_hog
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
		legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("sisben_iva_hog", replace) xtitle("sisben proxy score") ytitle("IVA_hog probability") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/9.falsification/12b_rdplot_sisben_iva_hog.png", replace
				
				rdrobust $y $x if $x >-0.1
			restore		
			
		*3.xi. Creation dates
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			
			keep documento is_hog is_pers ratio_transform mes is_receiver created_on
			
			gen is_after=0
			replace is_after=1 if is_receiver==1 & created_on>=date("01Apr2020", "DMY")
				*43% of users receive IS and created their account in April first onwards
				sum is_after
				
			gen is_before=0
			replace is_before=1 if is_receiver==1 & created_on<date("01Apr2020", "DMY")
				*1.3% of users receive IS and creted their account before April2020
				sum is_before
				
			gen no_is_after=0
			replace no_is_after=1 if is_receiver==0 & created_on>=date("01Apr2020", "DMY")
				*44% of users no receive IS and created their account after April2020
				sum no_is_after
			
			gen no_is_before = 0 
			replace no_is_before = 1 if is_receiver==0 & created_on<date("01Apr2020", "DMY")
				*11% of users no receive IS and created their accounts before April2020 
				sum no_is_before
		restore	
		
		
		
		*3.xii. compliers, always takers and never takers
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			
			keep documento is_hog is_pers ratio_transform mes is_receiver created_on gender age
			
			gen sex = 0
			replace sex = 1 if gender == "F"
			
			*all 
				codebook documento
				sum sex
				sum age 
			*compliers treated
				codebook documento if is_receiver==1 & ratio_transform>0
				sum sex if is_receiver==1 & ratio_transform>0
				sum age if is_receiver==1 & ratio_transform>0
				
			*never-takers
				codebook documento if is_receiver==0 & ratio_transform>0
				sum sex if is_receiver==0 & ratio_transform>0
				sum age if is_receiver==0 & ratio_transform>0
				
			*always takers
				codebook documento if is_receiver==1 & ratio_transform<0
				sum sex if is_receiver==1 & ratio_transform<0
				sum age if is_receiver==1 & ratio_transform<0
				
			*compliers non-treated
				codebook documento if is_receiver==0 & ratio_transform<0
				sum sex if is_receiver==0 & ratio_transform<0
				sum age if is_receiver==0 & ratio_transform<0
		restore	
			
	
*4.Let's structure the data with the variables that we need
keep documento is_hog is_pers ratio_transform mes valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
global c 0
global range_rt -0.1
	
	

*5.Let's run the regressions!!!

matrix coeff_sharp=J(24,3,.)
matrix coeff_fuzzy=J(24,3,.)
	*5.1 balance
		forvalues w=1/24{

			*Sharp RD
			preserve
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
				
				/*
				rdplot $y $x , genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Balance month `w'", color(gs0)) name("bal_`w'm", replace) xtitle("sisben proxy score") ytitle("Balance") legend(off)
				*graph export "$graphs_rdd_fpanel_v3/1.balance/`w'm.png", replace
				*/
				display `w'
				rdrobust $y $x
				outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/1.sharp/`w'm.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
						
			*Fuzzy RD
			preserve
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==`w'
				keep if ratio_transform>$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_receiver)
				sum saldo_cierre_mes, d 
				keep if saldo_cierre_mes<=r(p90)
				
				global y saldo_cierre_mes
				global x ratio_transform

				rdrobust $y $x, fuzzy(is_receiver)
				outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/2.fuzzy/`w'm.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_fuzzy[`w', 1]=`w'
				matrix coeff_fuzzy[`w', 2]=e(tau_cl)
				matrix coeff_fuzzy[`w', 3]=e(se_tau_cl)
			restore
		}
	
	matrix colnames coeff_sharp = month coeff se 
	matrix lis coeff_sharp

	matrix colnames coeff_fuzzy	= month coeff se 
	matrix list coeff_fuzzy	
	
	*5.2. Let's plot the sharp rdd coefficients in a graph 
	svmat coeff_sharp
	rename coeff_sharp1 month 
	rename coeff_sharp2 coeff 
	rename coeff_sharp3 se 
	
	g ls = coeff + se*(invnormal(0.975))
	g li = coeff - se*(invnormal(0.975))
	
	tw	(rcap ls li month,lc(black)msize(zero) lw(medium)) (sc coeff month,m(O) mfc(white) mlc(black) lw(medium)) (line coeff month), name("sharp_coeff", replace)
	
	*5.3. Let's plot the fuzzy rdd coefficients in a graph 
	svmat coeff_fuzzy
	rename coeff_fuzzy1 month_f
	rename coeff_fuzzy2 coeff_f
	rename coeff_fuzzy3 se_f 
	
	g ls_f = coeff_f + se_f*(invnormal(0.975))
	g li_f = coeff_f - se_f*(invnormal(0.975))
	
	tw	(rcap ls_f li_f month_f,lc(black)msize(zero) lw(medium)) (sc coeff_f month_f,m(O) mfc(white) mlc(black) lw(medium)) (line coeff_f month_f), name("fuzzy_coeff", replace)
	 
	
	*5.4 Let's analyze each month. 
		//it has a coefficiente of 137.1*** for the sharp RD, more than 40 times smaller than the coefficients in previous months
		
				sort documento mes
				bys documento:  gen obs_n = _n
				keep if obs_n ==4
				*28,498 users received the Money Transfer (MT) in the fourth month, out of the 51,056 flagged as IS receivers 
					//codebook documento if valor_subsidio >0 & is_receiver ==1 & obs_n == 4
				*23,107 users received the MT in the third month, out of the 51,056 users flagged as IS receivers
					//codebook documento if valor_subsidio >0 & is_receiver ==1 & obs_n == 3
				*44,640 users received the MT in the second month, out of the 51,056 users flagged as IS receivers
					//codebook documento if valor_subsidio >0 & is_receiver ==1 & obs_n == 2
				*44,560 users received the MT in the first month, out of the 51,056 users flagged as IS receivers
					//codebook documento if valor_subsidio >0 & is_receiver ==1 & obs_n == 1
				
				*44,924 users received the MT in the eigth month, out of the 51,056 users flagged as IS receivers
					//codebook documento if valor_subsidio >0 & is_receiver ==1 & obs_n == 1
					//however, for 90% of the IS receivers the eigth month is december. They probably did not save that much money during that month because of the holidays
					//during that month they received the MT between the 18th and 20th of december, right before christmas.
				
		
	*5.5 Let's run the regressions for people with accounts created until april/20
		keep documento is_hog is_pers ratio_transform mes valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
		global c 0
		global range_rt -0.1
		
		matrix coeff_sharp=J(24,3,.)
		matrix coeff_fuzzy=J(24,3,.)
			*5.1 balance
				forvalues w=1/24{

					*Sharp RD
					preserve
						keep if created_on<=date("30apr2020", "DMY")
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
						
						/*
						rdplot $y $x , genvars hide ci(95)
						
						*default rdplot
						twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
		(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
		(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
		xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
		legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Balance month `w'", color(gs0)) name("bal_`w'm", replace) xtitle("sisben proxy score") ytitle("Balance") legend(off)
						*graph export "$graphs_rdd_fpanel_v3/1.balance/`w'm.png", replace
						*/
						
						rdrobust $y $x
						*outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/1.sharp/`w'm.txt", replace
						display e(tau_cl)
						display e(se_tau_cl)
						matrix coeff_sharp[`w', 1]=`w'
						matrix coeff_sharp[`w', 2]=e(tau_cl)
						matrix coeff_sharp[`w', 3]=e(se_tau_cl)
					restore
								
					*Fuzzy RD
					preserve
						keep if created_on<=date("30apr2020", "DMY")
						sort documento mes
						bys documento:  gen obs_n = _n
						keep if obs_n ==`w'
						keep if ratio_transform>$range_rt
						collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_receiver)
						sum saldo_cierre_mes, d 
						keep if saldo_cierre_mes<=r(p90)
						
						global y saldo_cierre_mes
						global x ratio_transform

						rdrobust $y $x, fuzzy(is_receiver)
						*outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/2.fuzzy/`w'm.txt", replace
						display e(tau_cl)
						display e(se_tau_cl)
						matrix coeff_fuzzy[`w', 1]=`w'
						matrix coeff_fuzzy[`w', 2]=e(tau_cl)
						matrix coeff_fuzzy[`w', 3]=e(se_tau_cl)
					restore
				}
			
			matrix colnames coeff_sharp = month coeff se 
			matrix lis coeff_sharp

			matrix colnames coeff_fuzzy	= month coeff se 
			matrix list coeff_fuzzy	
			
			*5.2. Let's plot the sharp rdd coefficients in a graph 
			svmat coeff_sharp
			rename coeff_sharp1 month 
			rename coeff_sharp2 coeff 
			rename coeff_sharp3 se 
			
			g ls = coeff + se*(invnormal(0.975))
			g li = coeff - se*(invnormal(0.975))
			
			tw	(rcap ls li month,lc(black)msize(zero) lw(medium)) (sc coeff month,m(O) mfc(white) mlc(black) lw(medium)) (line coeff month), name("sharp_coeff_apr", replace)
			
			*5.3. Let's plot the fuzzy rdd coefficients in a graph 
			svmat coeff_fuzzy
			rename coeff_fuzzy1 month_f
			rename coeff_fuzzy2 coeff_f
			rename coeff_fuzzy3 se_f 
			
			g ls_f = coeff_f + se_f*(invnormal(0.975))
			g li_f = coeff_f - se_f*(invnormal(0.975))
			
			tw	(rcap ls_f li_f month_f,lc(black)msize(zero) lw(medium)) (sc coeff_f month_f,m(O) mfc(white) mlc(black) lw(medium)) (line coeff_f month_f), name("fuzzy_coeff_apr", replace)	
		
		
		
	*5.6 Let's run the regressions for people with accounts created until June/20
	use "$master_data/3b.panel_data.dta", clear 
		*152,193 users with accounts created before July first
			//codebook documento if created_on<=date("30jun2020", "DMY")
		keep documento is_hog is_pers ratio_transform mes valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
		global c 0
		global range_rt -0.1
		
		matrix coeff_sharp=J(24,3,.)
		matrix coeff_fuzzy=J(24,3,.)
			*5.1 balance
				forvalues w=1/24{

					*Sharp RD
					preserve
						keep if created_on>date("30sep2019", "DMY") & created_on<=date("30jun2020", "DMY")
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
						
						/*
						rdplot $y $x , genvars hide ci(95)
						
						*default rdplot
						twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
		(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
		(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
		xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
		legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Balance month `w'", color(gs0)) name("bal_`w'm", replace) xtitle("sisben proxy score") ytitle("Balance") legend(off)
						*graph export "$graphs_rdd_fpanel_v3/1.balance/`w'm.png", replace
						*/
						
						rdrobust $y $x
						*outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/1.sharp/`w'm.txt", replace
						display e(tau_cl)
						display e(se_tau_cl)
						matrix coeff_sharp[`w', 1]=`w'
						matrix coeff_sharp[`w', 2]=e(tau_cl)
						matrix coeff_sharp[`w', 3]=e(se_tau_cl)
					restore
								
					*Fuzzy RD
					preserve
						keep if created_on<=date("30jun2020", "DMY")
						sort documento mes
						bys documento:  gen obs_n = _n
						keep if obs_n ==`w'
						keep if ratio_transform>$range_rt
						collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_receiver)
						sum saldo_cierre_mes, d 
						keep if saldo_cierre_mes<=r(p90)
						
						global y saldo_cierre_mes
						global x ratio_transform

						rdrobust $y $x, fuzzy(is_receiver)
						*outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/2.fuzzy/`w'm.txt", replace
						display e(tau_cl)
						display e(se_tau_cl)
						matrix coeff_fuzzy[`w', 1]=`w'
						matrix coeff_fuzzy[`w', 2]=e(tau_cl)
						matrix coeff_fuzzy[`w', 3]=e(se_tau_cl)
					restore
				}
			
			matrix colnames coeff_sharp = month coeff se 
			matrix lis coeff_sharp

			matrix colnames coeff_fuzzy	= month coeff se 
			matrix list coeff_fuzzy	
			
			*5.2. Let's plot the sharp rdd coefficients in a graph 
			svmat coeff_sharp
			rename coeff_sharp1 month 
			rename coeff_sharp2 coeff 
			rename coeff_sharp3 se 
			
			g ls = coeff + se*(invnormal(0.975))
			g li = coeff - se*(invnormal(0.975))
			
			tw	(rcap ls li month,lc(black)msize(zero) lw(medium)) (sc coeff month,m(O) mfc(white) mlc(black) lw(medium)) (line coeff month), name("sharp_coeff_jun", replace)
			
			*5.3. Let's plot the fuzzy rdd coefficients in a graph 
			svmat coeff_fuzzy
			rename coeff_fuzzy1 month_f
			rename coeff_fuzzy2 coeff_f
			rename coeff_fuzzy3 se_f 
			
			g ls_f = coeff_f + se_f*(invnormal(0.975))
			g li_f = coeff_f - se_f*(invnormal(0.975))
			
			tw	(rcap ls_f li_f month_f,lc(black)msize(zero) lw(medium)) (sc coeff_f month_f,m(O) mfc(white) mlc(black) lw(medium)) (line coeff_f month_f), name("fuzzy_coeff_jun", replace)	
		

		
************************Let's do balance by quarter
use "$master_data/3b.panel_data.dta", clear 

keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

*create quarter variable
sort documento mes
bys documento:  gen obs_n = _n

    gen q1 = 0
	replace q1=1 if obs_n<4
	
	gen q2 = 0
	replace q2=1 if obs_n>=4 & obs_n<7
	
	gen q3 = 0
	replace q3=1 if obs_n>=7 & obs_n<10
	
	gen q4 = 0
	replace q4=1 if obs_n>=10 & obs_n<13
	
	gen q5 = 0
	replace q5=1 if obs_n>=13 & obs_n<16
	
	gen q6 = 0
	replace q6=1 if obs_n>=16 & obs_n<19
	
	gen q7 = 0
	replace q7=1 if obs_n>=19 & obs_n<22
	
	gen q8 = 0
	replace q8=1 if obs_n>=22 & obs_n<25


keep documento is_hog is_pers ratio_transform mes q1 q2 q3 q4 q5 q6 q7 q8 valor_subsidio is_receiver created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes cashin_pers n_tot_chin_pers v_tot_chin_pers
	
global c 0
global range_rt -0.1		
		
		
matrix coeff_sharp=J(8,3,.)
matrix coeff_fuzzy=J(8,3,.)
	*5.1 balance
		forvalues w=1/8 {

			*Sharp RD
			preserve
				keep if q`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_receiver q`w')
				sum saldo_cierre_mes, d 
				keep if saldo_cierre_mes<=r(p90)
				
				
				global y saldo_cierre_mes
				global x ratio_transform
				
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				/*
				rdplot $y $x , genvars hide ci(95)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Balance month `w'", color(gs0)) name("bal_`w'm", replace) xtitle("sisben proxy score") ytitle("Balance") legend(off)
				*graph export "$graphs_rdd_fpanel_v3/1.balance/`w'm.png", replace
				*/
				display "q`w'"
				rdrobust $y $x
				*outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/1.sharp/`w'm.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
						
			*Fuzzy RD
			preserve
				keep if q`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_receiver q`w')
				sum saldo_cierre_mes, d 
				keep if saldo_cierre_mes<=r(p90)
				
				global y saldo_cierre_mes
				global x ratio_transform
				
				
				display "q`w'"
				rdrobust $y $x, fuzzy(is_receiver)
				*outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/2.fuzzy/`w'm.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_fuzzy[`w', 1]=`w'
				matrix coeff_fuzzy[`w', 2]=e(tau_cl)
				matrix coeff_fuzzy[`w', 3]=e(se_tau_cl)
			restore
		}
	
	matrix colnames coeff_sharp = q coeff se 
	matrix list coeff_sharp

	matrix colnames coeff_fuzzy	= q coeff se 
	matrix list coeff_fuzzy	
		
		
			*5.2. Let's plot the sharp rdd coefficients in a graph 
			svmat coeff_sharp
			rename coeff_sharp1 q 
			rename coeff_sharp2 coeff 
			rename coeff_sharp3 se 
			
			g ls = coeff + se*(invnormal(0.975))
			g li = coeff - se*(invnormal(0.975))
			
			tw	(rcap ls li q,lc(black)msize(zero) lw(medium)) (sc coeff q,m(O) mfc(white) mlc(black) lw(medium)) (line coeff q), name("sharp_coeff_q", replace)
			
			*5.3. Let's plot the fuzzy rdd coefficients in a graph 
			svmat coeff_fuzzy
			rename coeff_fuzzy1 q_f
			rename coeff_fuzzy2 coeff_f
			rename coeff_fuzzy3 se_f 
			
			g ls_f = coeff_f + se_f*(invnormal(0.975))
			g li_f = coeff_f - se_f*(invnormal(0.975))
			
			tw	(rcap ls_f li_f q_f,lc(black)msize(zero) lw(medium)) (sc coeff_f q_f,m(O) mfc(white) mlc(black) lw(medium)) (line coeff_f q_f), name("fuzzy_coeff_q", replace)	
		

		
************************Let's do balance by semester
use "$master_data/3b.panel_data.dta", clear 

keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

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
				graph export "$graphs_rdd_panel_may20_v4/1.balance/`w's_sharp.png", replace
				
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x
				outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/1.sharp/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
						
			*Fuzzy RD
			preserve
				keep if s`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_receiver s`w')
				sum saldo_cierre_mes, d 
				keep if saldo_cierre_mes<=r(p99)
				
				global y saldo_cierre_mes
				global x ratio_transform
				
				
				rdplot $y $x fuzzy(is_receiver), genvars hide ci(95) p(1)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 1" )) title("Fuzzy RD - Balance semester `w'", color(gs0)) name("bal_`w's_fuzzy", replace) xtitle("SISBEN 4 score") ytitle("Balance - unit in COP") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/1.balance/`w's_fuzzy.png", replace
				
				
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x, fuzzy(is_receiver)
				outreg2 using "$tables/6.rdd_panel_may20_v4/1.balance/2.fuzzy/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_fuzzy[`w', 1]=`w'
				matrix coeff_fuzzy[`w', 2]=e(tau_cl)
				matrix coeff_fuzzy[`w', 3]=e(se_tau_cl)
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
			graph export "$graphs_rdd_panel_may20_v4/1.balance/sharp_semester.png", replace
			
			*5.3. Let's plot the fuzzy rdd coefficients in a graph 
			svmat coeff_fuzzy
			rename coeff_fuzzy1 s_f
			rename coeff_fuzzy2 coeff_f
			rename coeff_fuzzy3 se_f 
			
			g ls_f = coeff_f + se_f*(invnormal(0.975))
			g li_f = coeff_f - se_f*(invnormal(0.975))
			
			tw	(rcap ls_f li_f s_f,lc(black)msize(zero) lw(medium)) (sc coeff_f s_f,m(O) mfc(white) mlc(black) lw(medium)) (line coeff_f s_f), name("fuzzy_coeff_s", replace) xtitle("Semester") ytitle("LATE coefficient - unit in COP") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/1.balance/fuzzy_semester.png", replace
				
				
		*to compare the coefficients to the average end of the month balance I 
		*estimate the average balance with the next code:
			use "$master_data/3b.panel_data.dta", clear 

			keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")
			
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
			
			tab semester, sum(saldo_cierre_mes)
			
			

************************Let's do transfers by semester
use "$master_data/3b.panel_data.dta", clear 

keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

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
				graph export "$graphs_rdd_panel_may20_v4/4.transfer/`w's_sharp.png", replace
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x
				outreg2 using "$tables/6.rdd_panel_may20_v4/4.transfer/1.sharp/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
						
			*Fuzzy RD
			preserve
				keep if s`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) transferencias, by(documento ratio_transform is_receiver s`w')
				sum transferencias, d 
				
				global y transferencias
				global x ratio_transform
				
				rdplot $y $x , fuzzy(is_receiver) genvars hide ci(95) p(1)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 1" )) title("Fuzzy RD - Transfers semester `w'", color(gs0)) name("tran_`w's_fuzzy", replace) xtitle("SISBEN score") ytitle("Transfer") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/4.transfer/`w's_fuzzy.png", replace
				
				
				display "s`w'"
				sum $y if ratio_transform<0
				rdrobust $y $x, fuzzy(is_receiver)
				outreg2 using "$tables/6.rdd_panel_may20_v4/4.transfer/2.fuzzy/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_fuzzy[`w', 1]=`w'
				matrix coeff_fuzzy[`w', 2]=e(tau_cl)
				matrix coeff_fuzzy[`w', 3]=e(se_tau_cl)
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
			graph export "$graphs_rdd_panel_may20_v4/4.transfer/sharp_semester.png", replace
			
			*5.3. Let's plot the fuzzy rdd coefficients in a graph 
			svmat coeff_fuzzy
			rename coeff_fuzzy1 s_f
			rename coeff_fuzzy2 coeff_f
			rename coeff_fuzzy3 se_f 
			
			g ls_f = coeff_f + se_f*(invnormal(0.975))
			g li_f = coeff_f - se_f*(invnormal(0.975))
			
			tw	(rcap ls_f li_f s_f,lc(black)msize(zero) lw(medium)) (sc coeff_f s_f,m(O) mfc(white) mlc(black) lw(medium)) (line coeff_f s_f), name("fuzzy_coeff_s_transf", replace) xtitle("Semester") ytitle("LATE coefficient") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/4.transfer/fuzzy_semester.png", replace
			

			
			
************************Let's do cash-out by semester
use "$master_data/3b.panel_data.dta", clear 

keep if created_on>date("30sep2019", "DMY") & created_on<=date("31may2020", "DMY")

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
				graph export "$graphs_rdd_panel_may20_v4/6.cash-out/`w's_sharp.png", replace
				
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x
				outreg2 using "$tables/6.rdd_panel_may20_v4/6.cash-out/1.sharp/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_sharp[`w', 1]=`w'
				matrix coeff_sharp[`w', 2]=e(tau_cl)
				matrix coeff_sharp[`w', 3]=e(se_tau_cl)
			restore
						
			*Fuzzy RD
			preserve
				keep if s`w' ==1
				keep if ratio_transform>$range_rt
				collapse (mean) cashout, by(documento ratio_transform is_receiver s`w')
				sum cashout, d 
				*keep if cashout<=r(p90)
				
				global y cashout
				global x ratio_transform
				
				
				rdplot $y $x , fuzzy(is_receiver) genvars hide ci(95) p(1)
				
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 1" )) title("Fuzzy RD - Cash-out semester `w'", color(gs0)) name("co_`w's_fuzzy", replace) xtitle("SISBEN score") ytitle("Cash-out") legend(off)
				graph export "$graphs_rdd_panel_may20_v4/6.cash-out/`w's_fuzzy.png", replace
				
				
				display "s`w'"
				sum $y if ratio_transform<0 
				rdrobust $y $x, fuzzy(is_receiver)
				outreg2 using "$tables/6.rdd_panel_may20_v4/6.cash-out/2.fuzzy/`w's.txt", replace
				display e(tau_cl)
				display e(se_tau_cl)
				matrix coeff_fuzzy[`w', 1]=`w'
				matrix coeff_fuzzy[`w', 2]=e(tau_cl)
				matrix coeff_fuzzy[`w', 3]=e(se_tau_cl)
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
			graph export "$graphs_rdd_panel_may20_v4/6.cash-out/sharp_semester.png", replace
			
			*5.3. Let's plot the fuzzy rdd coefficients in a graph 
			svmat coeff_fuzzy
			rename coeff_fuzzy1 s_f
			rename coeff_fuzzy2 coeff_f
			rename coeff_fuzzy3 se_f 
			
			g ls_f = coeff_f + se_f*(invnormal(0.975))
			g li_f = coeff_f - se_f*(invnormal(0.975))
			
			tw	(rcap ls_f li_f s_f,lc(black)msize(zero) lw(medium)) (sc coeff_f s_f,m(O) mfc(white) mlc(black) lw(medium)) (line coeff_f s_f), name("fuzzy_coeff_s_cashout", replace) xtitle("Semester") ytitle("LATE coefficient") legend(off) graphregion(color(white)) bgcolor(white)
			graph export "$graphs_rdd_panel_may20_v4/6.cash-out/fuzzy_semester.png", replace
			
			
			
			
			

			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			