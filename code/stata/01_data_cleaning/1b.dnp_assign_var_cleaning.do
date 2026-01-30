*****************HELLOOOOOO*********************************
*This Do File is to pre process the new data from Ingreso Solidario with a continuous assignment variable, shared by DNP

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

*****Let's load the data the raw data from DNP
import delimited using "$raw_data_dnp\RTA_Movii_18102022 (ratio)", clear


*****THIRD STEP**********************************************

*****Let's clean the data and organize it

	*1. VAR: tipodeidentificacion
	drop if tipodeidentificacion=="0"
	replace tipodeidentificacion="CC" if tipodeidentificacion=="CEDULA DE CIUDADANIA"
	replace tipodeidentificacion="PA" if tipodeidentificacion=="PAS"
	
	encode tipodeidentificacion, g(id_type)
	drop tipodeidentificacion
	order id_type, before(numeroidentificacion)
	label variable id_type "identification type"
	
	*2. VAR: numeroidentificacion
	tostring numeroidentificacion, g(id_no) format("%16.0f") 
	drop numeroidentificacion
	label variable id_no "identification number"
	
	*3. VAR: origen
	drop if origen=="" //drop this observations because we have no info of them
	encode origen, g(_origen)
	drop origen
	rename _origen origen  
	order origen, after(id_no)
	label variable origen "info system origin"
	
	*4. VAR: cod_mpio
	tostring cod_mpio, g(s_cod_mpio) format("%16.0f") 
	drop cod_mpio
	rename s_cod_mpio cod_mpio
	label variable cod_mpio "municipality code"
	
	*5. VAR: fec_nacimiento
	gen birthday = date(fec_nacimiento, "YMD")
	format birthday %td 
	label variable birthday "person's birthday"
	order birthday, after(fec_nacimiento)
	drop fec_nacimiento
	
	*6. VAR: ratio_transform
	drop if ratio_transform==.
	
	*7. duplicates dropping
	duplicates tag id_no, g(dup_flag)
		//I have 20 individuals duplicated one time.
		//Since I can't know which one is the real one
		//I am going to drop the 40 observations
		drop if dup_flag==1
		drop dup_flag

	*8. Let's keep only the variables we need
	drop origen cod_mpio birthday ind_nivel_sisben_4 ind_grupo_sisben_4 puntaje_sisben_3_trunc is_pers is_hog hogar_maestra
		
save "$temp_data\5.dnp_assignment_var_cleaning.dta", replace 

























