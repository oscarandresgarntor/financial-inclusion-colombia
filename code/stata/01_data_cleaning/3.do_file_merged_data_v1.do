*****************HELLOOOOOO*********************************
*This Do File is to process the data merged of Ingreso Solidario and Movii



*****FIRST STEP****************************		
		
	*To load the intermediate data of DNP, define the next cd and use the next dataset
	cd ""
	
	clear all 
	use "Maestra_dnp"
	
		
*****SECOND STEP****************************		
		
*************Time to MERGE!*************************************

	*1. Let's merge the datasets
		merge 1:m id_no using subsidios_trx_movii
			*We have 1.043.222 - 500.250 = 542.972 matched ids!! thats huge but can be better if we get more data from DNP and MOVII 
		

*****THIRD STEP****************************	
****Process the datasets
		
	*0.To load the intermediate merged data
	cd ""
	
	clear all
	use "3_dnp_movii_db"
		
		
	*1. Let's keep only the merged observations
		keep if _merge==3
			*4,738,355 observations deleted
		
	*2. Let's sort the data by id_no and week_trx
		sort id_no week_trx
	
	*3. Let's create dummy variables that identifies individuals source of financial aid
		tab source_fa, gen(source_fa)
		order source_fa1, after(source_fa)
		order source_fa2, after(source_fa1)
		order source_fa3, after(source_fa2)
		order source_fa4, after(source_fa3)
		order source_fa5, after(source_fa4)
		order source_fa6, after(source_fa5)
		order source_fa7, after(source_fa6)
		order source_fa8, after(source_fa7)
		
	*4. Individuals treated only with IS
		gen is_ind = 1
		replace is_ind=0 if is_hog==1 & is_pers==1 & (source_fa==4 | source_fa==8)
		
		egen is_ind_avg = mean(is_ind), by(id_no)
		gen treated_is_only=0
		replace treated_is_only = 1 if is_ind_avg==0
		label variable treated_is_only "1=treated only with IS"
			drop is_ind is_ind_avg
	
	*5. Individuals treated with IS and others
		gen treated_is_else = 0
		replace treated_is_else = 1 if is_pers == 1 & treated_is_only == 0 
		// here, I identify those with IS and not treated only with IS
		label variable treated_is_else "1=treated but with IS and other FA"
	
	*6. Individuals treated but no with IS
		gen is_ind = 1
		replace is_ind = 0 if is_pers ==1 // here, I exclude those with IS
		replace is_ind = 0 if is_hog ==1 // here, I exclude households with IS
		replace is_ind = 0 if source_fa==4 // here, I exclude those with IS reported as source of FA 
		replace is_ind = 0 if source_fa == 8 /// here, I exclude those with
		// no source of financial aid 
		
		egen is_ind_avg = mean(is_ind), by(id_no)
		gen treated_not_is = 0
		replace treated_not_is = 1 if is_ind_avg > 0
		label variable treated_not_is "1=treated but not with IS"
			drop is_ind is_ind_avg
	
	*7. Individuals with no financial aid (IS, FA, JA, CM, ALCALDIA, ETC)
		gen is_ind=1
		replace is_ind=0 if is_hog==0 & is_pers==0 & fea_hog==0 & fea_pers==0 & cm_benef_hog==0 & cm_benef_pers==0 & jea_hog==0 & jea_pers==0 & iva_hog==0 & iva_pers==0 & source_fa7==1
	
		egen is_ind_avg = mean(is_ind), by(id_no)
			*I use the average to identify individuals that in all weekly observations register no financial aid
		gen control = 0
		replace control=1 if is_ind_avg==0
		label variable control "1=individual did not receive any Financial Aid"
			drop is_ind is_ind_avg
	
	*8. We have duplicates due to different values in observation for the same individual in variables like nationality, date of creation
			egen nationality_2 = max(nationality), by(id_no)
			order nationality_2, after(nationality)
			label values nationality_2 nationality
				*let's drop the nationality var to save space
				drop nationality
				rename nationality_2 nationality
				label variable nationality "individuals nationality"
				
			egen gender_e_2 = max(gender_e), by(id_no)
			order gender_e_2, after(gender_e)
			label values gender_e_2 gender_e
				drop gender_e
				rename gender_e_2 gender_e
				label variable gender_e "gender encoded. 1=FEM 2=MAS"
				
			egen min_created_on=min(_created_on), by(id_no)
			order min_created_on, after(_created_on)
			format min_created_on %td
				drop _created_on
				rename min_created_on _created_on
				label variable _created_on "date of user creation in platform"
				
			egen min_created_3m=min(created_3m), by(id_no)
			order min_created_3m, after(created_3m)
			format min_created_3m %tm
				drop created_3m
				rename min_created_3m created_3m
				label variable created_3m "3 months after account creation"
				
			egen min_created_6m=min(created_6m), by(id_no)
			order min_created_6m, after(created_6m)
			format min_created_6m %tm
				drop created_6m
				rename min_created_6m created_6m
				label variable created_6m "6 months after account creation"
				
			egen min_created_12m=min(created_12m), by(id_no)
			order min_created_12m, after(created_12m)
			format min_created_12m %tm
				drop created_12m
				rename min_created_12m created_12m
				label variable created_12m "12 months after account creation"
				
			egen min_created_24m=min(created_24m), by(id_no)
			order min_created_24m, after(created_24m)
			format min_created_24m %tm
				drop created_24m
				rename min_created_24m created_24m
				label variable created_24m "24 months after account creation"
	
	*9. the user_type is generating id_no duplicates
		egen tag_min = min(user_type), by(id_no)
		egen tag_max = max(user_type), by(id_no)
			
			*var for users that are not either treated and control 
			egen user_type_2=min(user_type), by(id_no)
			order user_type_2, after(user_type)
			label values user_type_2 user_type
			drop user_type
			rename user_type_2 user_type
			label variable user_type "1=before 04/2020 2=after04/2020 3=normal user"
	
	*10. Save the dataset preprocessed
		cd ""
		save 4.dnp_movii_preprocessed_db, replace
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	