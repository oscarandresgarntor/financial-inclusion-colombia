*****************HELLOOOOOO*********************************
*This Do File is to pre process the data from Ingreso Solidario, shared by DNP


*****FIRST STEP**********************************************

*****Let's define the globals
*DNP raw data path
	global raw_data_dnp ""

*MOVii raw data path
	global raw ""
	
*MOVII temp data path
	global temp_data ""

*****SECOND STEP****************************

********************Lets understand and structure the data - Maestra DNP********************

	*1.Let's load the raw data we import the next dataset
	import delimited using "$raw\Maestra DNP - Informacion_usuarios_movii v3.csv", clear 

	*2. It worked! Now lets Format id_no from number to string
	tostring id_no, g(_id_no) format("%16.0f")
	drop id_no
	rename _id_no id_no
	label variable id_no "identification number"
	
	
	*3. We are going to use describe funtion to know how many variables we have their storage type
	describe
		*We have 23 variables. Saved as string, byte and long
	
	*4. I see that the variable id_type has CC and cedula de ciudadania. Lets change that and use only cc
	replace id_type="CC" if id_type=="CEDULA DE CIUDADANIA"
	tab id_type
	
	*5. First question: Why tab ID shows 1.048.310 when the dataset has 1.048.575?
	*br if id_type==""
		*We have 265 observations with missing values in id_type
			*By looking at the data I see that all documents are PEP, but only one that is a CC. Lets replace it
			replace id_type="CC" if id_no=="1003517398"
			*br if id_no==1003517398
			
			replace id_type="PEP" if id_type==""
			encode id_type, g(_id_type)
			drop id_type
			rename _id_type id_type
			tab id_type
			*DONE :)))
			
	*6. Lets see how many missing values we have in each variable 
	mdesc
		*We have:
			*93.956 missing values in SISBEN 4 
			*3.167 missing values in SISBEN 3
	
	
	*7. dob and fec_nacimiento are the same variables?
	describe dob fec_nacimiento
	*br dob fec_nacimiento
	*br dob fec_nacimiento if substr(dob,1,10)!=fec_nacimiento 
		*I found that 37.680 obs have different dob 
		
		*This two observations had a different format in their fec_nacimiento
			replace fec_nacimiento="04/06/1892" if fec_nacimiento=="1892-06-04"
			replace fec_nacimiento="05/02/1898" if fec_nacimiento=="1898-02-05"
		
	*8. Lets format fec_nacimiento so we can work with it
	gen birthday = date(fec_nacimiento, "DMY")
	format birthday %td 
	label variable birthday "person's birthday"
	order birthday, after(fec_nacimiento)
	drop fec_nacimiento
	drop dob
	
	*9. Calculate the age for each individual by 31 august 2022
	gen age = round((td(31aug2022)-birthday)/365.25)
	label variable age "person's age"
	order age, after(birthday)
	
	*10. Create age ranges 
	gen r_age=age
	recode r_age min/19=1 20/24=2 25/29=3 30/34=4 35/39=5 40/44=6 45/49=7 50/54=8 55/59=9 60/max=10
	label define r_age 1 "19 or less" 2 "20-24" 3 "25-29" 4 "30-34" 5 "35-39" 6 "40-44" 7 "45-49" 8 "50-54" 9 "55-59" 10 "60 or older"
	label values r_age r_age
	label variable r_age "age range"
	order r_age, after(age)
		
	*11. Lets transform variable hogar_maestra
	summarize hogar_maestra
	desc hogar_maestra
	*br hogar_maestra
	format hogar_maestra %48s
	
	
	*12. origen
	describe origen
	tab origen
		*954.619 come from SISBEN 4
		*93.956 come from SISBEN 3
		
	*13. cod_mpio
	describe cod_mpio
	tab cod_mpio
	codebook cod_mpio
		*We have data from 1.096 municipalities 
		
	*14. cod_clase
	describe cod_clase
	tab cod_clase
	label variable cod_clase "1=cab_municipal 2=cen_poblado 3=rural"
	
	*15. grupo_sisben_4
	describe ind_grupo_sisben_4
	tab ind_grupo_sisben_4
		*954.619 obs with Sisben 4
	
	*16. nivel_sisben_4
	describe ind_nivel_sisben_4
	tab ind_nivel_sisben_4
	
	*17. Puntaje sisben 3
	desc puntaje_sisben_3_trunc
	encode puntaje_sisben_3_trunc, gen(_puntaje_sisben_3_trunc)
	summarize _puntaje_sisben_3_trunc
		*1.045.408 obs with puntaje 3 sisben
		*3.167 obs without puntaje 3 sisben but with sisben 4
		
	*18. Hogares e individuos con IS
	tab is_hog is_per
		*382.093 indivudals receive IS 
		*143.732 individuals in households that receive IS
		*525.825 total households that receive IS
				
	*19. We have 1.048.575 observations. Let's see if we have duplicates
	duplicates report 
	*br id_no
		*So yeap, we have plenty of duplicates. See duplicates only by id_no
		duplicates report id_no
		*See duplicates by more variables 
		duplicates report id_no hogar_maestra cod_clase ind_grupo_sisben_4 ind_nivel_sisben_4 puntaje_sisben_3_trunc is_hog is_pers
		duplicates list, sepby(id_no)
		*Generate a tag for duplicates
		duplicates tag id_no, gen(dup_id)
		*br if dup_id>=1 & id_type=="CC"
			*We have 1.283 observations with duplicates 
		
		*Drop duplicates 
		duplicates drop id_no, force
		duplicates report id_no 
			*Dropped 5.353 observations with id_no duplicates 
	
	*20. Replace the missing values for all the state financial aid programs
	replace fea_hog=0 if fea_hog==.
	replace fea_pers=0 if fea_pers==.
	replace cm_benef_hog=0 if cm_benef_hog==.
	replace cm_benef_pers=0 if cm_benef_pers==.
	replace jea_hog=0 if jea_hog==.
	replace jea_pers=0 if jea_pers==.
	replace iva_hog=0 if iva_hog==.
	replace iva_pers=0 if iva_pers==.
	
	*21. Graph the discontinuity on IS assignment for group C 
	tab ind_nivel_sisben_4 is_hog if ind_grupo_sisben_4=="C"
	
	encode ind_nivel_sisben_4, gen(_ind_nivel_sisben_4)
	tab _ind_nivel_sisben_4
	
	*histogram _ind_nivel_sisben_4 if ind_grupo_sisben_4=="C" & is_per==1
	
	tab is_per _ind_nivel_sisben_4 if ind_grupo_sisben_4=="C"
	graph twoway scatter is_per _ind_nivel_sisben_4 if ind_grupo_sisben_4=="C"
	twoway dot is_per _ind_nivel_sisben_4 if ind_grupo_sisben_4=="C"
	
	graph twoway line is_per _ind_nivel_sisben_4 if ind_grupo_sisben_4=="C"
	
	preserve
	keep if ind_grupo_sisben_4=="C"
	tab is_per, gen(is_per)
	collapse (sum) is_per1 is_per2, by(_ind_nivel_sisben_4)
	graph twoway line is_per2 _ind_nivel_sisben_4
	graph twoway line is_per2 is_per1 _ind_nivel_sisben_4, xlabel(#20)
	
	restore
	
		save "$temp_data\Maestra_dnp.dta", replace	
		
		use "$temp_data\Maestra_dnp.dta", clear
		
