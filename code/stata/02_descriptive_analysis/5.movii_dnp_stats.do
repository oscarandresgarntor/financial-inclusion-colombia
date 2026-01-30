****************************************************
*Date: 12/02/2023                                  *
*Name: Oscar Andres Garnica Toro                   *
*Description: Stats for the merged dataset of Movii*
*and DNP                                           *
****************************************************

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
	global export_data "$data/10.export_data"

*1.Load DNP data 
use "$master_data/2.movii_dnp_merged.dta", clear
		*since it's strange having people with less than 15 years old
		*and more than 110 so I am going to drop this observations
		drop if age<15
		drop if age>110

	save "$master_data/2.movii_dnp_merged.dta", replace 
		
*2. Descriptive Stats
use "$master_data/2.movii_dnp_merged.dta", clear

	*2.i. Created on timeline
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		codebook created_on
	restore
	
	*2.ii. Gender
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		codebook gender
	restore

	*2.iii. Age
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		codebook age
	restore
	
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		tab r_age
		tab2xl r_age using "$tables/r_age.xlsx", row(1) col(1) replace 
	restore
	
	*2.iv. type of location
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		codebook cod_clase 
		tab cod_clase
	restore
	
	*2.v. municipalities
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		codebook cod_mpio 
	restore

*3.identify cutoff point
	*3.i. Let's see how the score distributes among Movii Users
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		codebook ratio_transform
		hist ratio_transform if ratio_transform<.1, bin(500) name("hist_score", replace)
		kdensity ratio_transform if ratio_transform<.1, name("kdensity_ratio", replace)
	restore
	
	*3.ii. Let's see how the score distributes among IS users
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		codebook ratio_transform if is_pers==1
		hist ratio_transform if ratio_transform<.1 & is_pers==1, bin(500) name("hist_score_is", replace)
		kdensity ratio_transform if ratio_transform<.1 & is_pers==1, name("kdensity_ratio_is", replace)
	restore
	
	*3.iii. Let's plot the distributions of movii and IS users together
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		
		twoway (histogram ratio_transform if ratio_transform<.1, start(0) bin(500) color(red%60)) ///        
       (histogram ratio_transform if ratio_transform<.1 & is_pers==1, start(0) bin(500) color(green%60)), ///   
       legend(order(1 "Movii users" 2 "IS users" )) name("hist_movii_is", replace) xtitle("sisben proxy score")
	   graph export "$graphs_rdd/7.cutoff/1_hist_movii_is.png", replace
	restore
	
	*3.iv. Let's plot the probability of receiving IS against ratio_transform
		preserve
			*keep if ind_grupo_sisben_4=="C"
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			
			global y is_pers
			global x ratio_transform
			global c 0.038
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
			graph export "$graphs_rdd/7.cutoff/2_rdplot_is_ratio_default.png", replace
			
			rdrobust $y $x , c($c)	
		restore
		
			*see it for observations with ratio_transform lower than 0.1
			preserve
				*keep if ind_grupo_sisben_4=="C"
				bys documento: egen min_month = min(mes)
				keep if min_month == mes
				keep if ratio_transform<0.1
				
				global y is_pers
				global x ratio_transform
				global c 0.038
				su $x
				global x_min = r(min)
				global x_max = r(max)
				
				rdplot $y $x if $x <0.1, genvars hide ci(95) c($c)
				*default rdplot
				twoway (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small)  mcolor(gs10)) ///
	(function `e(eq_l)', range($x_min $c) lcolor(black) sort lwidth(medthin) lpattern(solid)) ///
	(function `e(eq_r)', range($c $x_max) lcolor(black) sort lwidth(medthin) lpattern(solid)), ///
	xline($c, lcolor(black) lwidth(medthin)) xscale(r($x_min $x_max))  /// 
	legend(cols(2) order(1 "Sample average within bin" 2 "Polynomial fit of order 4" )) title("Regression function fit", color(gs0)) name("rdplot_default", replace) xtitle("sisben proxy score") ytitle("IS recipient") legend(off)
				graph export "$graphs_rdd/7.cutoff/2_rdplot_is_ratio_default_lower01.png", replace

				rdrobust $y $x if $x <0.1, c($c)
			restore

/*		IMPORTANT TO CENTER CUT-OFF TO ZERO	
*4.Let's normalize to zero the cut-off point 
	gen sisben_score = 0.038 - ratio_transform
	preserve
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		tabstat sisben_score, stats(mean median sd min max n)
	restore
	order sisben_score, after(ratio_transform)
	label variable sisben_score "sisben score center to the cutoff"
*/	

*5. Descriptive stats of predetermined covariates
 
		*5.i. sisben score
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			tabstat ratio_transform, stats(mean median sd min max n)
		restore

		*5.ii. individual eligible for treatment
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			gen treatment = 0
			replace treatment = 1 if ratio_transform<=0.038
			tabstat treatment, stats(mean median sd min max n)
				//64.43% of individuals are eligible for treatment
		restore
		
		*individuals actually treated
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			tabstat is_pers, stats(mean median sd min max n)
				//45.16% are actually treated
		restore
		
		*share of women in the sample
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			gen fem = 0
			replace fem = 1 if gender == "F"
			tabstat fem, stats(mean median sd min max n)
				//64.10% are women
		restore
		
		*age 
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			tabstat age, stats(mean median sd min max n)
		restore
		
		*rurality
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			gen rurality = 0
			replace rurality = 1 if cod_clase==3
			tabstat rurality, stats(mean median sd min max n)
		restore
		
		*Bogota
		preserve
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			gen bogota = 0
			replace bogota = 1 if cod_mpio==11001
			tabstat bogota, stats(mean median sd min max n)
		restore

*6.Descriptive stats of potential outcomes
		*6.i.Balance	
		matrix A = J(2,5,.)	
		local col=1
		foreach w in 3 6 12 18 24{
				preserve
					keep if created_on>date("30sep2019", "DMY")
					sort documento mes
					bys documento:  gen obs_n = _n
					keep if obs_n <=`w'
					collapse (mean) saldo_cierre_mes, by(documento ratio_transform is_pers)
					sum saldo_cierre_mes
					matrix A[1,`col']=round(r(mean),.01)
					matrix A[2,`col']=round(r(sd),.01)
					
					local col=`col'+1
				restore
		}
		matrix colnames A = 3m 6m 12m 18m 24m
		matrix rownames A = mean sd
		
		mat2txt , matrix(A) saving("$tables/3.outcomes_stats/1.balance/stats.txt")
		
		*6.ii.online purchase	
		matrix B = J(4,5,.)	
		local col=1
		foreach w in 3 6 12 18 24{
				preserve
					keep if created_on>date("30sep2019", "DMY")
					sort documento mes
					bys documento:  gen obs_n = _n
					keep if obs_n <=`w'
					collapse (mean) numero_total_comv valor_total_comv, by(documento ratio_transform is_pers)
					
					sum numero_total_comv
					matrix B[1,`col']=round(r(mean),.01)
					matrix B[2,`col']=round(r(sd),.01)
					
					sum valor_total_comv
					matrix B[3,`col']=round(r(mean),.01)
					matrix B[4,`col']=round(r(sd),.01)
					
					local col=`col'+1
				restore
		}
		matrix colnames B = 3m 6m 12m 18m 24m
		matrix rownames B = mean sd mean sd 
		
		mat2txt , matrix(B) saving("$tables/3.outcomes_stats/2.online_purch/stats.txt") replace
		
		*6.iii.in-person purchase	
		matrix C = J(4,5,.)	
		local col=1
		foreach w in 3 6 12 18 24{
				preserve
					keep if created_on>date("30sep2019", "DMY")
					sort documento mes
					bys documento:  gen obs_n = _n
					keep if obs_n <=`w'
					collapse (mean) numero_total_comt valor_total_comt, by(documento ratio_transform is_pers)
					
					sum numero_total_comt
					matrix C[1,`col']=round(r(mean),.01)
					matrix C[2,`col']=round(r(sd),.01)
					
					sum valor_total_comt
					matrix C[3,`col']=round(r(mean),.01)
					matrix C[4,`col']=round(r(sd),.01)
					
					local col=`col'+1
				restore
		}
		matrix colnames C = 3m 6m 12m 18m 24m
		matrix rownames C = mean sd mean sd 
		
		mat2txt , matrix(C) saving("$tables/3.outcomes_stats/3.in-person_purch/stats.txt") replace
		
		*6.iv.Transfer	
		matrix D = J(4,5,.)	
		local col=1
		foreach w in 3 6 12 18 24{
				preserve
					keep if created_on>date("30sep2019", "DMY")
					sort documento mes
					bys documento:  gen obs_n = _n
					keep if obs_n <=`w'
					collapse (mean) numero_total_trf valor_total_trf, by(documento ratio_transform is_pers)
					
					sum numero_total_trf
					matrix D[1,`col']=round(r(mean),.01)
					matrix D[2,`col']=round(r(sd),.01)
					
					sum valor_total_trf
					matrix D[3,`col']=round(r(mean),.01)
					matrix D[4,`col']=round(r(sd),.01)
					
					local col=`col'+1
				restore
		}
		matrix colnames D = 3m 6m 12m 18m 24m
		matrix rownames D = mean sd mean sd 
		
		mat2txt , matrix(D) saving("$tables/3.outcomes_stats/4.transfer/stats.txt") replace
		
		*6.v.Cash-in	
		matrix E = J(4,5,.)	
		local col=1
		foreach w in 3 6 12 18 24{
				preserve
					keep if created_on>date("30sep2019", "DMY")
					sort documento mes
					bys documento:  gen obs_n = _n
					keep if obs_n <=`w'
					collapse (mean) numero_total_chin valor_total_chin, by(documento ratio_transform is_pers)
					
					sum numero_total_chin
					matrix E[1,`col']=round(r(mean),.01)
					matrix E[2,`col']=round(r(sd),.01)
					
					sum valor_total_chin
					matrix E[3,`col']=round(r(mean),.01)
					matrix E[4,`col']=round(r(sd),.01)
					
					local col=`col'+1
				restore
		}
		matrix colnames E = 3m 6m 12m 18m 24m
		matrix rownames E = mean sd mean sd 
		
		mat2txt , matrix(E) saving("$tables/3.outcomes_stats/5.cash-in/stats.txt") replace
	
		*6.v.Cash-out	
		matrix F = J(4,5,.)	
		local col=1
		foreach w in 3 6 12 18 24{
				preserve
					keep if created_on>date("30sep2019", "DMY")
					sort documento mes
					bys documento:  gen obs_n = _n
					keep if obs_n <=`w'
					collapse (mean) numero_total_chout valor_total_chout, by(documento ratio_transform is_pers)
					
					sum numero_total_chout
					matrix F[1,`col']=round(r(mean),.01)
					matrix F[2,`col']=round(r(sd),.01)
					
					sum valor_total_chout
					matrix F[3,`col']=round(r(mean),.01)
					matrix F[4,`col']=round(r(sd),.01)
					
					local col=`col'+1
				restore
		}
		matrix colnames F = 3m 6m 12m 18m 24m
		matrix rownames F = mean sd mean sd 
		
		mat2txt , matrix(F) saving("$tables/3.outcomes_stats/6.cash-out/stats.txt") replace
		
*7. Let's estimate an rddensity using values 0.038, 0.04, 0.05 and 0.055 as cutoff
	*c=0.038
	preserve
		local c 0.038
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		rddensity ratio_transform, c(`c') plot  
		graph export "$graphs_rdd/8.rddensity/038_cutoff.png", replace
	restore
		*group C
		preserve
			local c 0.038
			keep if ind_grupo_sisben_4=="C"
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			rddensity ratio_transform, c(`c') plot  
			graph export "$graphs_rdd/8.rddensity/038_cutoff_gc.png", replace
		restore
	
	*c=0.04
 	preserve
		local c 0.04
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		rddensity ratio_transform, c(`c') plot  
		graph export "$graphs_rdd/8.rddensity/04_cutoff.png", replace
	restore
		*group C
		preserve
			local c 0.04
			keep if ind_grupo_sisben_4=="C"
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			rddensity ratio_transform, c(`c') plot  
			graph export "$graphs_rdd/8.rddensity/04_cutoff_gc.png", replace
		restore
		
	*c=0.05
 	preserve
		local c 0.05
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		rddensity ratio_transform, c(`c') plot  
		graph export "$graphs_rdd/8.rddensity/05_cutoff.png", replace
	restore
		*group C
		preserve
			local c 0.05
			keep if ind_grupo_sisben_4=="C"
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			rddensity ratio_transform, c(`c') plot  
			graph export "$graphs_rdd/8.rddensity/05_cutoff_gc.png", replace
		restore
		
		*c=0.055
 	preserve
		local c 0.055
		bys documento: egen min_month = min(mes)
		keep if min_month == mes
		rddensity ratio_transform, c(`c') plot  
		graph export "$graphs_rdd/8.rddensity/055_cutoff.png", replace
	restore
		*group C
		preserve
			local c 0.055
			keep if ind_grupo_sisben_4=="C"
			bys documento: egen min_month = min(mes)
			keep if min_month == mes
			rddensity ratio_transform, c(`c') plot  
			graph export "$graphs_rdd/8.rddensity/055_cutoff_gc.png", replace
		restore

*8. People marked by DNP as IS but do not receive any subsidy in our data 
preserve 
	keep if is_pers==1 & tipo_usuario==3
	bys documento: egen min_month = min(mes)
	keep if min_month == mes
	keep documento
	outsheet using "$export_data/3.is_marked_butnoreceiver.csv", comma replace
restore














