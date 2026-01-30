*****************HELLOOOOOO*********************************
*This Do File is to pre process the data from Movii



*****FIRST STEP**********************************************

*****Let's load Maestra DNP dataset
	*To load the raw data we define the next cd and import this CSV
		cd ""

		clear all
		import delimited using "subsidios_2021_10_28_proc2"
	
 *To load the intermediate data or pre process, define the next cd and use the next dataset
	cd ""
	
	clear all 
	use "subsidios_trx_movii"


*****SECOND STEP****************************

********************Lets understand and structure the data - MOVII********************

	*1. Describe the dataset 
		describe
		codebook
		
	*2. destring the documento variable so we can do the merge with database Maestra DNP
		destring documento, replace  
			*Destring didnt work because of no nummeric characters
				*Lets identify what observations have no nummeric characters
				list documento if missing(real(documento))
				*Now that we identified 3 obsrvations with no nummeric characters lets replace them
				replace documento="1014247121" if documento=="A1014247121"
				replace documento="52998139" if documento=="A52998139"
				drop if documento==""
		*Now lets try to destring the documento variable 
		destring documento, replace  
		*rename the documento variable so we can merge it with Maestra DNP
		rename documento id_no
		label variable id_no "id number of individuals"
		
		format id_no %24.0f
	
	*3. Find how many unique individuals do we have in this dataset
		codebook party_id
		codebook id_no
			*We found 944.985 unique values with party_id and 938.730 unique values with variable documento. 
			*The difference is due to people who has the same documento particularly those with PEP, I believe
	
	*4. Let's work our semana variable
		codebook semana
		tab semana
			*we are going to give date format to our variable in a new variable called week
			*since some observations come with time we are going to have to do a substring first
			gen week = substr(semana,1,10)
			
			gen week_trx = date(week,"YMD")
			format week_trx %td
			label variable week_trx "week reported with transactions"
			
				*let's order week_trx next to variable semana
				order week_trx, after(semana)
			
				*since we dont need the temporal week variable we can drop it
				drop week
				
				*98.177 missing values of observations that seem to have only the date when individuals received monetary aid
		
	*5. Let's work our valor_subsidio variable 
		hist valor_subsidio if tipo_subsidio=="INGRESO SOLIDARIO"
		label variable valor_subsidio "financial aid amount"
		
	*6. Let's work our fecha_cargue_subsidio
		codebook fecha_cargue_subsidio
			*We are oing to create a new variable with date format
			gen week_sub = substr(fecha_cargue_subsidio,1,10)
		
			gen week_mmoney_deposited = date(week_sub, "YMD")
			format week_mmoney_deposited %td
			label variable week_mmoney_deposited "week when mmoney was deposited"
			
				*lets order our variable next to fecha_cargue_subsidio
				order week_mmoney_deposited, after(fecha_cargue_subsidio)
			
				*since we dont need the temporal variable week_sub we can drop it
				drop week_sub
	
	*7. Lets sort the database by id_no and week_trx
		sort id_no week_trx
		
	*8. Lets work with the variable tarjeta_1
		tab tarjeta_1
			*I am going to encode the values of this variable
			encode tarjeta_1, gen(tdd_active)
			label variable tdd_active "status debit card. 1=active 2=noactive"
			order tdd_active, after(tarjeta_1)
			
	*9. Let's work our variable tipo_subsidio
		tab tipo_subsidio
		encode tipo_subsidio, gen(source_fa)
		codebook source_fa
		label variable source_fa "source of the financial aid received"
		order source_fa, after(tipo_subsidio)
			*now we dont need tipo_subsidio
			drop tipo_subsidio
	
	*10. Let's work our variable nacionalidad
		tab nacionalidad
		encode nacionalidad, gen(nationality)
		codebook nationality
		label variable nationality "individuals nationality"
		order nationality, after(nacionalidad)
			*now we dont need nacionalidad variable
			drop nacionalidad
	
	*11. Let's work the generacion variable
		tab generacion
			*I am going to create a new variable with more age ranges
			gen age_range = edad
			recode age_range min/19=1 20/24=2 25/29=3 30/34=4 35/39=5 40/44=6 45/49=7 50/54=8 55/59=9 60/max=10
			label define age_range 1 "19 or less" 2 "20-24" 3 "25-29" 4 "30-34" 5 "35-39" 6 "40-44" 7 "45-49" 8 "50-54" 9 "55-59" 10 "60 or older"
			label values age_range age_range
			codebook age_range
		
		order age_range, after(generacion)
		label variable age_range "users' age range"
			*now we dont need generacion variable
			drop generacion
		
	*12. Let's work the gender variable
		tab gender
		encode gender, gen(gender_e)
		codebook gender_e
		label variable gender_e "gender encoded. 1=FEM 2=MAS"
		order gender_e, after(gender)
			*now we dont need gender
			drop gender
		
	*13. Lets work with created_on variable 
		gen _created_on = date(created_on, "YMD hms")
		format _created_on %td
		label variable _created_on "date of user creation in platform"
		order _created_on, after(created_on)
			*now we dont need created_on
			drop created_on
		
	*14. Let's work our tipo_usuario variable
		encode tipo_usuario, gen(user_type)
		codebook user_type
		label variable user_type "1=before 04/2020 2=after04/2020 3=normal user"
		order user_type, after(tipo_usuario)
			*now we dont need tipo_usuario variable
			drop tipo_usuario
		
	*15. Lets do collapse experiments for transactions variables
		*Monthly
		preserve
			gen month=mofd(week_trx)
				format month %tm
			collapse (mean) pago_convenio, by (id_no month source_fa)
			hist pago_convenio
		restore
		
		*Quarter
		preserve
			gen quarter=qofd(week_trx)
				format quarter %tm
			collapse (mean) pago_convenio, by (id_no quarter source_fa)
			hist pago_convenio
		restore
		
		*half year
		preserve
		gen half=hofd(week_trx)
			format half %th
		collapse (mean) pago_convenio aportes cashout transferencias mercado_ara compra_tarjeta_plastico recarga_celular giro_movii cash_out_tarjeta p2p, by(id_no half source_fa)
		restore
		
	*16. Let's create a three month variable from the creation of the account
		gen created_3m = mofd(_created_on)+3
			format created_3m %tm
			label variable created_3m "3 months after account creation"
			order created_3m, after(_created_on)
	
	*17. Let's create a six month variable from the creation of the account
		gen created_6m = mofd(_created_on)+6
			format created_6m %tm
			label variable created_6m "6 months after account creation"
			order created_6m, after(created_3m)
	
	*18. Let's create a 12 month variable from the creation of the account
		gen created_12m = mofd(_created_on)+12
			format created_12m %tm
			label variable created_12m "12 months after account creation"
			order created_12m, after(created_6m)
	
	*19. Let's create a 24 month variable from the creation of the account
		gen created_24m = mofd(_created_on)+24
			format created_24m %tm
			label variable created_24m "24 months after account creation"
			order created_24m, after(created_12m)
	
	
	*Now our database is ready to merge!!!
	 
		
	save subsidios_trx_movii, replace
	
		

				
				
				
				
				
				
				
				
				
				
				
				
				
				