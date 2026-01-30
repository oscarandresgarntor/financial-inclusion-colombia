****************************************************
*Date: 01/27/2023                                  *
*Name: Oscar Andres Garnica Toro                   *
*Description: This code imports and merges         *
*the Movii transactions to a dta format            *
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

*1.Let's import movii transactions
foreach y in "historial1000" "historial2000" "historial3000" "historial4000" "historial5000" "historial6000" "historial7000" "historial8000" {
    import delimited "$raw_movii_trx/`y'.csv", case(lower) clear 

	save "$import_movii_trx/`y'.dta", replace
}


*2.Let's append all the transactions in one dataset

	*I am going to adjust all documento variables in each dataset to string format
	use "$import_movii_trx/historial6000.dta", clear 
	tostring documento, gen(s_documento) format("%16.0f")
	drop documento
	rename s_documento documento
	save "$import_movii_trx/historial6000.dta", replace 

	use "$import_movii_trx/historial7000.dta", clear 
	tostring documento, gen(s_documento) format("%16.0f")
	drop documento
	rename s_documento documento
	save "$import_movii_trx/historial7000.dta", replace 
	
	use "$import_movii_trx/historial8000.dta", clear 
	tostring documento, gen(s_documento) format("%16.0f")
	drop documento
	rename s_documento documento
	save "$import_movii_trx/historial8000.dta", replace 

*now we are ready to do the append 
use "$import_movii_trx/historial1000.dta", clear 
	
foreach y in "historial2000" "historial3000" "historial4000" "historial5000" "historial6000" "historial7000" "historial8000" {
    append using "$import_movii_trx/`y'.dta"
}

save "$import_movii_trx/historial_trx_consolidated.dta", replace




















