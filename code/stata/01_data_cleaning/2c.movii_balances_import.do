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

*1.Let's import movii balances
foreach y in "000" "001" "002" "003" "004" "005" "006" "007" "008" "009" "010" "011" "012" "2000" "2001" "2002" "2003" "2004" "2005" "3000" "3001" "3002" "3003" "3004" "4000" "4001" "4002" "4003" "5000" "5001" "5002" "5003" "6000" "6001" "6002" "7000" "7001" "7002" "7003" "7004" "7005" "7006" "7007" "8000" "8001" "8002" "8003" "9000" "9001" "10000" "10001" "10002" "10003" "10004" {
    import delimited "$raw_movii_saldos/saldos_`y'.csv", case(lower) clear 

	save "$import_movii_balance/saldos_`y'.dta", replace
}

*2.Let's append all balances in one dataset

	*I am going to adjust all documento variables in each dataset to string format  
		foreach y in "000" "001" "002" "003" "004" "005" "006" "007" "008" "009" "010" "011" "012" "2000" "2001" "2002" "2003" "2004" "2005" "3000" "3001" "3002" "3003" "3004" "4000" "4001" "4002" "4003" "5000" "5001" "5002" "5003" "6000" "6001" "6002" "7000" "7001" "7002" "7003" "7004" "7005" "7006" "7007" "8000" "8001" "8002" "8003" "9000" "9001" "10000" "10001" "10002" "10003" "10004" {
			use "$import_movii_balance/saldos_`y'.dta", clear
			capture confirm string variable documento
			if !_rc {
				display " string documento saldos_`y' "
			}
			else {
				tostring documento, gen(s_documento) format("%16.0f")
				drop documento
				rename s_documento documento
				save "$import_movii_balance/saldos_`y'.dta", replace 
			}	
		}

*now, we are ready to append
use "$import_movii_balance/saldos_000.dta", clear 
	
foreach y in "001" "002" "003" "004" "005" "006" "007" "008" "009" "010" "011" "012" "2000" "2001" "2002" "2003" "2004" "2005" "3000" "3001" "3002" "3003" "3004" "4000" "4001" "4002" "4003" "5000" "5001" "5002" "5003" "6000" "6001" "6002" "7000" "7001" "7002" "7003" "7004" "7005" "7006" "7007" "8000" "8001" "8002" "8003" "9000" "9001" "10000" "10001" "10002" "10003" "10004" {
    append using "$import_movii_balance/saldos_`y'.dta"
}

save "$import_movii_balance/historial_balances_consolidated.dta", replace











