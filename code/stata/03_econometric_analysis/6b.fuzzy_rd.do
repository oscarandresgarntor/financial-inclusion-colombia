/*
Date: 21/03/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: Fuzzy rd regressions                                          
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
	global logs "$data/11.logs"

*declare log
log using "$logs/1.fuzzyrd_range01_coff0038.smcl", replace
	
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

				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/1.balance/1.all_sample/`t'm.txt", replace
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

				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/1.balance/2.group_c/`t'm.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/2.online_purch/1.all_sample/`t'm_number.txt", replace
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
				
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/2.online_purch/1.all_sample/`t'm_amount.txt", replace
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
				
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/2.online_purch/2.group_c/`t'm_number.txt", replace
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
				
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/2.online_purch/2.group_c/`t'm_amount.txt", replace
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
				
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/3.in-person_purch/1.all_sample/`t'm_number.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/3.in-person_purch/1.all_sample/`t'm_amount.txt", replace
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
				
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/3.in-person_purch/2.group_c/`t'm_number.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/3.in-person_purch/2.group_c/`t'm_amount.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/4.transfer/1.all_sample/`t'm_number.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/4.transfer/1.all_sample/`t'm_amount.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/4.transfer/2.group_c/`t'm_number.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/4.transfer/2.group_c/`t'm_amount.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/5.cash-in/1.all_sample/`t'm_number.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/5.cash-in/1.all_sample/`t'm_amount.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/5.cash-in/2.group_c/`t'm_number.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/5.cash-in/2.group_c/`t'm_amount.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/6.cash-out/1.all_sample/`t'm_number.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/6.cash-out/1.all_sample/`t'm_amount.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/6.cash-out/2.group_c/`t'm_number.txt", replace
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
				
				rdrobust $y $x , c($c) fuzzy(is_pers)
				outreg2 using "$tables/2.fuzzy_rd/6.cash-out/2.group_c/`t'm_amount.txt", replace
			restore
		}
		
	log close
	
translate "$logs/1.fuzzyrd_range01_coff0038.smcl" "$logs/1.fuzzyrd_range01_coff0038.pdf"
		
	