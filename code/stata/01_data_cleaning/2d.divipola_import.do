/*
Date: 25/02/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: import the DIVIPOLA dataset                                           
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
	
*1.import dataset
import excel "$raw/DIVIPOLA_Municipios.xlsx", firstrow case(lower)

rename cod_municipio cod_depto
rename c cod_mpio

duplicates drop cod_mpio, force

destring cod_mpio, replace
tostring cod_mpio, replace 

*2.save as dta
save "$import_data/divipola.dta", replace 