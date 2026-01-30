*****************HELLOOOOOO*********************************
*This Do File is to analyse the data merged of Ingreso Solidario and Movii


*****FIRST STEP****************************	
****Load the dataset
		
	*0.To load the intermediate merged data
		cd ""
		
		clear all
		use "4.dnp_movii_preprocessed_db"
		
*****SECOND STEP****************************	
****Let's analyse the dataset

		*1. Collapse and check duplicates 
		preserve
			collapse (sum) valor_subsidio pago_convenio servicio_publico aportes cashout transferencias mercado_ara compra_tarjeta_plastico recarga_celular giro_movii cash_out_tarjeta pago_tarjeta_otros pago_tarjeta_mercado p2p cashin desembolso_presti pago_presti contenido_digital pagos_pse apuesta_deportiva otros_pagos total_tx saldo_inicio_semana, by(id_no primer_nombre apellido id_type hogar_maestra origen ind_grupo_sisben_4 r_age cod_mpio birthday age cod_clase is_hog is_pers fea_hog fea_pers cm_benef_hog cm_benef_pers jea_hog jea_pers iva_hog iva_pers _puntaje_sisben_3_trunc _ind_nivel_sisben_4 nationality gender_e _created_on created_3m created_6m created_12m created_24m user_type _merge treated_is_else treated_is_only treated_not_is control)
		
			duplicates report
			duplicates report id_no
		restore
			*YES!! No duplicates anymoooore!
	
		*2. Let's run an RD with the sum of total_tx 
		preserve
			collapse (mean) total_tx, by(id_no is_pers _ind_nivel_sisben_4)
			rdrobust total_tx _ind_nivel_sisben_4, c(17)
		restore
		
		*3. Let's check the number of individuals per day
		preserve
			collapse (sum) treated_is_else treated_is_only treated_not_is control, by(_created_on)
			graph twoway line treated_is_else _created_on, xlabel(#20, angle(vertical)) name(line1, replace)
			graph twoway line treated_is_only _created_on, xlabel(#20, angle(vertical)) name(line2, replace)
			graph twoway line treated_not_is _created_on, xlabel(#20, angle(vertical)) name(line3, replace)
			graph twoway line control _created_on, xlabel(#20, angle(vertical)) name(line4, replace)
		restore
		
		*4. Let's check the number of individuals per month
		gen month_created=mofd(_created_on)
		format month_created %tm
		order month_created, after(_created_on)
		
		preserve
			collapse (sum) treated_is_else treated_is_only treated_not_is control, by(month_created)
			graph twoway line treated_is_else month_created, xlabel(#20, angle(vertical)) name(line1, replace)
			graph twoway line treated_is_only month_created, xlabel(#20, angle(vertical)) name(line2, replace)
			graph twoway line treated_not_is month_created, xlabel(#20, angle(vertical)) name(line3, replace)
			graph twoway line control month_created, xlabel(#20, angle(vertical)) name(line4, replace)
		restore
		
		*5. Let's check Alcaldia financial aid distribution over sisbenIV		
			preserve
				keep if source_fa==1
				collapse (mean) total_tx saldo_inicio_semana, by(id_no ind_grupo_sisben_4 _puntaje_sisben_3_trunc _ind_nivel_sisben_4 ) 
				rddensity _ind_nivel_sisben_4, c(17) plot
			restore
			
		*6. Let's check IS financial aid distribution over sisbenIV	
			preserve
				keep if source_fa==4
				collapse (mean) total_tx saldo_inicio_semana, by(id_no ind_grupo_sisben_4 _puntaje_sisben_3_trunc _ind_nivel_sisben_4 ) 
				rddensity _ind_nivel_sisben_4, c(17) plot
			restore
		
		*7. Let's check the total dataset distribution over sisbenIV	
			preserve
				collapse (mean) total_tx saldo_inicio_semana, by(id_no ind_grupo_sisben_4 _puntaje_sisben_3_trunc _ind_nivel_sisben_4 ) 
				rddensity _ind_nivel_sisben_4, c(17) plot
			restore
			
	*11. Let's keep only the treated and control individuals
		keep if treated==1 | control==1
		
	*12. Descriptive statistics
		*A. number of treated and control users by SISBENIV categories
		preserve 
			collapse (sum) treated control, by(_ind_nivel_sisben_4)
			graph twoway line treated control _ind_nivel_sisben_4, xlabel(#20, valuelabel)
		restore
		
		*B. average users' age by _ind_nivel_sisben_4 in group C
		preserve
			keep if ind_grupo_sisben_4=="C"
			collapse (mean) age, by(_ind_nivel_sisben_4)
			graph bar age, over(_ind_nivel_sisben_4) name(edad_c)
		restore
		
		*C. number of women and men users per _ind_nivel_sisben_4
		preserve 
			keep if ind_grupo_sisben_4=="C"
			tab gender_e, gen(gender_e)
			collapse (mean) gender_e1 gender_e2, by(_ind_nivel_sisben_4)
			graph bar gender_e1 gender_e2, over(_ind_nivel_sisben_4)
		restore
		
		*D. average age by treated and control groups 
		sum age if treated_is_only==1 | treated_is_else==1
		sum age if (treated_is_only==1 | treated_is_else==1) & ind_grupo_sisben_4=="C"
		
		sum age if treated_not_is==1 | control==1
		sum age if (treated_not_is==1 | control==1) & ind_grupo_sisben_4=="C"
			*Here, they are not very different
			*those treated by IS are 43years in average vs those not treated
			*by IS are 40-41years in average
			
			***ttest of age average
			gen treatment_status=0
			replace treatment_status=1 if treated_is_only==1 | treated_is_else==1
			label define treatment_status 1 "IS_treated" 0 "IS_not_treated"
			label values treatment_status treatment_status
			
				ttest age, by(treatment_status)
				
				ttest age if ind_grupo_sisben_4=="C", by(treatment_status)
		
				*Here, I compare those that received only IS vs those that received nothing
					sum age if treated_is_only==1
					sum age if treated_is_only==1 & ind_grupo_sisben_4=="C"
		
					sum age if control==1
					sum age if control==1 & ind_grupo_sisben_4=="C"
						*The difference is 10-11 years of difference. They are very different
		
		*E. summarize women users per treated and control groups
		preserve 
			tab gender_e, gen(gender_e)
			sum gender_e1 if treated_is_only==1 | treated_is_else==1
			sum gender_e1 if treated_not_is==1 | control==1
		restore
		
			*same statistics but only for group C
					preserve 
						tab gender_e if ind_grupo_sisben_4=="C", gen(gender_e)
						sum gender_e1 if treated_is_only==1 | treated_is_else==1
						sum gender_e1 if treated_not_is==1 | control==1
					restore
		
			***ttest of gender share
				preserve 
					tab gender_e, gen(gender_e)
					ttest gender_e1, by(treatment_status)
				restore
				
				preserve 
					keep if ind_grupo_sisben_4=="C"
					tab gender_e, gen(gender_e)
					ttest gender_e1, by(treatment_status)
				restore
		
		*F. urban and rural users percentage among treated and control groups
		preserve 
			tab cod_clase, gen(cod_clase)
			sum cod_clase1 if treated_is_only==1 | treated_is_else==1
			sum cod_clase1 if treated_not_is==1 | control==1
			sum cod_clase2 if treated_is_only==1 | treated_is_else==1
			sum cod_clase2 if treated_not_is==1 | control==1
			sum cod_clase3 if treated_is_only==1 | treated_is_else==1
			sum cod_clase3 if treated_not_is==1 | control==1
		restore
			
			*same but only for group C
				preserve 
					keep if ind_grupo_sisben_4=="C"
					tab cod_clase, gen(cod_clase)
					sum cod_clase1 if treated_is_only==1 | treated_is_else==1
					sum cod_clase1 if treated_not_is==1 | control==1
					sum cod_clase2 if treated_is_only==1 | treated_is_else==1
					sum cod_clase2 if treated_not_is==1 | control==1
					sum cod_clase3 if treated_is_only==1 | treated_is_else==1
					sum cod_clase3 if treated_not_is==1 | control==1
				restore
		
			***ttest of urban and rural area
				preserve 
					tab cod_clase, gen(cod_clase)
					ttest cod_clase1, by(treatment_status)
				restore
				
				preserve 
					keep if ind_grupo_sisben_4=="C"
					tab cod_clase, gen(cod_clase)
					ttest cod_clase1, by(treatment_status)
				restore
		
				preserve 
					tab cod_clase, gen(cod_clase)
					ttest cod_clase3, by(treatment_status)
				restore
				
				preserve 
					keep if ind_grupo_sisben_4=="C"
					tab cod_clase, gen(cod_clase)
					ttest cod_clase3, by(treatment_status)
				restore
		
		
		*G. users nationality among treated and control groups
		preserve 
			tab nationality, gen(nationality)
			sum nationality3 if treated_is_only==1 | treated_is_else==1
			sum nationality3 if treated_not_is==1 | control==1
		restore
		
			*same but only for group C
			preserve 
				keep if ind_grupo_sisben_4=="C"
				tab nationality, gen(nationality)
				sum nationality3 if treated_is_only==1 | treated_is_else==1
				sum nationality3 if treated_not_is==1 | control==1
			restore
			
			***ttest of nationality
				preserve 
					tab nationality, gen(nationality)
					ttest nationality3, by(treatment_status)
				restore
				
				preserve 
					keep if ind_grupo_sisben_4=="C"
					tab nationality, gen(nationality)
					ttest nationality3, by(treatment_status)
				restore
		
		
		*H. control users created after 31mar2020
		tab _ind_nivel_sisben_4 control if _created_on > date("31mar2020","DMY")
		
		*I. rdplot of average weekly total transactions by _ind_nivel_sisben_4
		preserve 
			collapse (mean) total_tx, by(id_no _ind_nivel_sisben_4)
			rdplot total_tx _ind_nivel_sisben_4, c(17)
		restore
		
		*J. rdplot of average cash out amount per _ind_nivel_sisben_4
		preserve
			keep if ind_grupo_sisben_4=="C"
			rdplot cashout _ind_nivel_sisben_4, c(17) 
		restore
		
		*K. rdplot of sum of total trx by _ind_nivel_sisben_4
		preserve
			keep if _merge==3
			rdplot total_tx _ind_nivel_sisben_4, c(17)
		restore
		
		
		tab _ind_nivel_sisben_4 is_pers if ind_grupo_sisben_4=="C"
		tab r_age is_pers 
		tab gender_e is_pers
		tab cod_clase is_pers
		tab _ind_nivel_sisben_4, missing
		
	
	*. Let's collapse the number of transactions by sisben group C level
		preserve
			keep if _merge==3 & ind_grupo_sisben_4=="C"
			collapse (sum) total_tx, by(_ind_nivel_sisben_4)
			graph twoway line total_tx _ind_nivel_sisben_4, xlabel(#10, valuelabel)
		restore
	
	*. Let's collapse the average trx amount by sisben group C level
		preserve
			keep if _merge==3 & ind_grupo_sisben_4=="C"
			egen ave_tx_amount = rowmean(pago_convenio aportes transferencias mercado_ara compra_tarjeta_plastico recarga_celular) //I am using SIX types of transactions to experiment
			collapse (mean) ave_tx_amount, by(_ind_nivel_sisben_4)
			graph twoway line ave_tx_amount _ind_nivel_sisben_4, xlabel(#10, valuelabel)
		restore 
		
	*. Let's run a RD regression 
		preserve
			keep if _merge==3 & ind_grupo_sisben_4=="C"
			collapse (sum) total_tx, by(id_no is_pers _ind_nivel_sisben_4)
			hist _ind_nivel_sisben_4, bin(50) 
			rddensity _ind_nivel_sisben_4, c(17) //it seems there is manipulation at the cutoff or at least there is no continuity at it
			rdplot total_tx _ind_nivel_sisben_4, c(17)
			rdrobust total_tx _ind_nivel_sisben_4, c(17)
		restore 
		
	keep if _merge==3 & ind_grupo_sisben_4=="C"
	collapse (sum) total_tx, by(id_no is_pers _ind_nivel_sisben_4)
	hist _ind_nivel_sisben_4, bin(50) 
	rddensity _ind_nivel_sisben_4, c(17) plot
	rdplot total_tx _ind_nivel_sisben_4, c(17)
	
	
	*Lets check the time window
	tab semana
		*We have info from people receiving IS since april 2020 until october 2021 -> we can get a broader time window with MOVII's help
	
	*Save the merged db
	cd ""
	save dnp_movii_db, replace
	
	
	graph twoway scatter total_tx _ind_nivel_sisben_4 if ind_grupo_sisben_4=="C"
	
	*People in levels of C with and without IS that matched both datasets 
	tab ind_nivel_sisben_4 is_pers if ind_grupo_sisben_4=="C" & _merge==3
