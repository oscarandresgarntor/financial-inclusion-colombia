/*
Date: 25/02/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: merge users data with divipola codes to identify users location in Colombia                                           
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
	global export_data "$data/10.export_data"
	
*1.Load users data 
use "$master_data/2.movii_dnp_merged.dta", clear

bys documento: egen min_month = min(mes)
		keep if min_month == mes
		destring documento, replace
		collapse (count) total_users = documento, by(cod_mpio)
		
		tostring cod_mpio, replace 
	
*2.merge with divipola 
merge 1:1 cod_mpio using "$import_data/divipola.dta", keep (1 3) nogen

*3.collapse at department level
collapse (sum) total_users, by(cod_depto departamento cod_mpio municipio latitud longitud)

gen unit=1

save "$temp_data/7.departamento_users.dta", replace 

outsheet using "$export_data/1.departamento_users.csv", comma replace


	/*
	Let's export the dataset without BOGOTA
	*/
	
	*1.Load users data
	use "$master_data/2.movii_dnp_merged.dta", clear

	bys documento: egen min_month = min(mes)
			keep if min_month == mes
			destring documento, replace
			collapse (count) total_users = documento, by(cod_mpio)
			
			tostring cod_mpio, replace 
		
	*2.merge with divipola 
	merge 1:1 cod_mpio using "$import_data/divipola.dta", keep (1 3) nogen

	*3.collapse at department level
	collapse (sum) total_users, by(cod_depto departamento cod_mpio municipio latitud longitud)

	gen unit=1
	
	drop if departamento=="BOGOTÁ, D.C."

	outsheet using "$export_data/1b.depto_users_sinbogota.csv", comma replace








