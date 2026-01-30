/*
Date: 20/04/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: Let's declare dataset a pnel dataset 
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
	global export_data "$data/10.export_data"


*1. Load the data 
use "$master_data/2.movii_dnp_merged.dta", clear

*2. Set the data as panel data
destring documento, replace 
tsset documento mes

	*2.i. Since the panel is unbalanced let's fill it
	tsfill
	
	*2.ii. Let's replace the missiing values
		*string variables
		foreach x in primer_nombre apellido hogar_maestra origen ind_grupo_sisben_4 ind_nivel_sisben_4 puntaje_sisben_3_trunc party_id tipo_documento fecha_cargue_subsidio tipo_subsidio gender {
			bys documento: replace `x' = `x'[_n-1] if `x'==""
		}
		
		*numeric variables with the same value than previous observation
		foreach x in cod_mpio birthday age r_age cod_clase is_hog is_pers fea_hog fea_pers cm_benef_hog cm_benef_pers jea_hog jea_pers iva_hog iva_pers _puntaje_sisben_3_trunc dup_id _ind_nivel_sisben_4 id_type ratio_transform fecha_nacimiento created_on tipo_usuario saldo_cierre_mes {
			bys documento: replace `x' = `x'[_n-1] if `x'==.
		}
			//Note: I assign the value of the previous month to the balance 
			//because we assume that the gap months tehy did not run any 
			//financial trx therefore their balance is intact
		
		*numeric variables with value zero for gap months
		foreach x in valor_subsidio cashout numero_total_chout valor_total_chout valor_promedio_chout cashin numero_total_chin valor_total_chin valor_promedio_chin transferencias numero_total_trf valor_total_trf valor_promedio_trf compra_tarjeta numero_total_comt valor_total_comt valor_promedio_comt compra_virtual numero_total_comv valor_total_comv valor_promedio_comv {
			bys documento: replace `x' = 0 if `x'==.
		}
	
		*let's use the blc_data variable to identify the gap months
		bys documento: replace blc_data = 2 if blc_data==.
		label define gap 0 "Master_trx" 1 "Balances dataset" 2 "gap_month"
		label values blc_data gap
		
*3. Let's save the data 
save "$master_data/3.panel_data.dta", replace 



/*
Task1: Isolate the deposits made by the people from those made by the financial 
aid program

*/


*1. Let's load the new panel data 
use "$master_data/3.panel_data.dta", clear 

*2. Let's count the number of commas per obsevation 
gen ncommas = length(tipo_subsidio) - length(subinstr(tipo_subsidio, ",", "",.))
order ncommas, after(tipo_subsidio)

*3. Now we can estimate the number of deposits coming from the financial aid programs per month 
gen nci_subs = 0 
label variable nci_subs "number of cashin coming from financial aid programs"
order nci_subs, after(ncommas)

replace nci_subs = ncommas + 1 if ncommas>0
replace nci_subs = 1 if tipo_subsidio!="NO APLICA" & ncommas==0
/* This the situationt with the number of deposits received from financial aid programs
            Tabulation: Freq.  Value
                    6,836,082  0
                    2,186,640  1
                      191,488  2
                       11,082  3
                          223  4
                           36  5
                           15  6
                            1  7
*/

*4.Now we can isolate the number of deposits made by people from those received from the financial aid
	
	*4.i. the number of deposits made by people
	gen n_tot_chin_pers = 0
	replace n_tot_chin_pers = numero_total_chin - nci_subs if valor_subsidio>0
	label variable n_tot_chin_pers "people total deposits/cashins"
	
	*4.ii. the deposits amount cashin by people
	gen v_tot_chin_pers = valor_total_chin - valor_subsidio
	label variable v_tot_chin_pers "people total amount deposits/cashins"
	
	*4.iii. flag for people that did cashins 
	gen cashin_pers = 0
	replace cashin_pers = 1 if n_tot_chin_pers>0
	label variable cashin_pers "1=user did cashin 0=otherwise"
	order cashin_pers, before(n_tot_chin_pers)
	
	drop ncommas nci_subs
	
*6. Let's normalize the running variable
	codebook ratio_transform
	replace ratio_transform = 0.038 - ratio_transform
	
*7.Let's identify those that received IS at any point in time 
g is_subsidy = 0
replace is_subsidy = 1 if strmatch(tipo_subsidio, "*INGRESO SOLIDARIO*")
order is_subsidy, after(tipo_subsidio)

bys documento: egen is_receiver = max(is_subsidy)
order is_receiver, after(is_subsidy)

*8.Save the progess in the data 
save "$master_data/3b.panel_data.dta", replace
		**DONE***


		
		
		

		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		






















































 


		