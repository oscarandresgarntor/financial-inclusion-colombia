****************************************************
*Date: 06/02/2023                                  *
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

*1.Let's load the data
use "$import_movii_trx/historial_trx_consolidated.dta", clear 

*2.Let's append with the balances data
append using "$import_movii_balance/historial_balances_consolidated.dta", generate(blc_data)

*3.Let's drop duplicates coming from the same balances dataset 
duplicates drop documento mes blc_data, force
duplicates tag documento mes, g(dup_tag)
drop if dup_tag > 0 & blc_data == 1
drop dup_tag

sort documento mes party_id

*4.Let's drop the missings in documento
drop if documento ==""
drop if documento == "0"
drop if documento== "00000000"

*5.Lets replace the missing values
foreach x of varlist cashout numero_total_chout valor_total_chout valor_promedio_chout cashin numero_total_chin valor_total_chin valor_promedio_chin transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes {
	
	replace `x' = 0 if `x' ==.
	
}

/*
foreach x of varlist party_id tipo_documento documento mes valor_subsidio fecha_cargue_subsidio tipo_subsidio gender fecha_nacimiento created_on tipo_usuario cashout numero_total_chout valor_total_chout valor_promedio_chout cashin numero_total_chin valor_total_chin valor_promedio_chin transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv saldo_cierre_mes tarjeta_1 tarjeta_2 {
	
	codebook `x' 
	
}

we have 3.777.808 unique values for documento
and 3.791.842 unique values for party_id
*/

*6.Adjust tipo_documento variable
replace tipo_documento = "CC" if tipo_documento=="CEDULA DE CIUDADANIA"
replace tipo_documento = "CE" if tipo_documento=="CEDULA DE EXTRANJERIA"
replace tipo_documento = "PA" if tipo_documento=="PAS"
replace tipo_documento = "PA" if documento=="A20691400"
replace tipo_documento = "CC" if tipo_documento==""

*7.Lets set date format to date variables 
generate month =date(mes,"YMD",2022)
order month, after(mes)
format month %td

drop mes 
g mes=mofd(month)
format mes %tm
order mes, before(month)
drop month

g dob=date(fecha_nacimiento, "YMD", 2022)
order dob, after(fecha_nacimiento)
format dob %td
drop fecha_nacimiento
rename dob fecha_nacimiento

g creation=date(created_on, "YMD", 2022)
order creation, after(created_on)
format creation %td
drop created_on
rename creation created_on

*8.Let's give labels to each variables
label variable party_id "Movii user identifier"
label variable tipo_documento "type of ID"
label variable documento "ID number"
label variable mes "Cutoff Month"
label variable valor_subsidio "Subsidy amount"
label variable fecha_cargue_subsidio "Date of subsidy received"
label variable tipo_subsidio "Type of subsidy"
label variable gender "user gender"
label variable fecha_nacimiento "date of birth"
label variable created_on "User creation date"
label variable tipo_usuario ///
"1=user created before 04/20 with subsidy 2=user created after 04/20 with subsidy 3=user with no subsidy"
label variable cashout "1=user did cashout 0=otherwise"
label variable numero_total_chout "total number of cashout"
label variable valor_total_chout "cashout total amount"
label variable valor_promedio_chout "cashout average amount"
label variable cashin "1=user did cashin 0=otherwise"
label variable numero_total_chin "total number of cashin"
label variable valor_total_chin "cashin total amount"
label variable valor_promedio_chin "cashin average amount"
label variable transferencias "1=user did transfer 0=otherwise"
label variable numero_total_trf "total number of transfers"
label variable valor_total_trf "transfer total amount"
label variable valor_promedio_trf "transfer average amount"
label variable compra_tarjeta "1=user did Debit Card purchase 0=otherwise"
label variable numero_total_comt "total number of debit card purchases"
label variable valor_total_comt "debit card purchases total amount"
label variable valor_promedio_comt "debit card purchases average amount"
label variable compra_virtual "1=user did online purchases 0=otherwise"
label variable numero_total_comv "total number of online purchases"
label variable valor_total_comv "online purchases total amount"
label variable valor_promedio_comv "online purchases average amount"
label variable saldo_cierre_mes "user account balance at the end of the month"
drop tarjeta_1 
drop tarjeta_2 

*9.Save the dataset
save "$master_data/1.movii_dataset.dta", replace

























