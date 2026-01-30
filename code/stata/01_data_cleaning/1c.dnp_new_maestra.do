*****************HELLOOOOOO*********************************
*This Do File is to merge the Maestra DNP datasets. The firs version did not have 
*the assignment variable in a continuos format- So, here we merge it to have it
*and also have the rest of the demographic data coming from the Maestra DNP dataset

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

*****SECOND STEP**********************************************

***Let's load the first version of the Maestra DNP
use "$temp_data\Maestra_dnp.dta", clear

*****THIRD STEP**********************************************

***Let's the merge begin!
merge 1:1 id_no using "$temp_data\5.dnp_assignment_var_cleaning.dta"
keep if _merge==3

hist ratio_transform


save "$temp_data\6.new_maestra_dnp.dta", replace 