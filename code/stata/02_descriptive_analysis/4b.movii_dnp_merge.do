****************************************************
*Date: 12/02/2023                                  *
*Name: Oscar Andres Garnica Toro                   *
*Description: This code merges DNP and Movii data  *
****************************************************

clear all
set more off

*In Uniandes Cluster
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
	
*1.Load DNP data 
use "$temp_data\6.new_maestra_dnp.dta", clear 

rename id_no documento
drop _merge

*2.merge with Movii data 
merge 1:m documento using "$master_data/1.movii_dataset.dta", keep(1 3) nogen

*3.fix the type of user variable
bys documento: egen type_user=min(tipo_usuario)
order type_user, after(tipo_usuario)
replace tipo_usuario=type_user if tipo_usuario!=type_user
drop type_user

*4.Save the dataset
save "$master_data/2.movii_dnp_merged.dta", replace