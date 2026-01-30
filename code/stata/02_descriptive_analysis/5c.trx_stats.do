/*
Date: 05/03/2023                                  
Name: Oscar Andres Garnica Toro                   
Description: Transactions stats for the merged dataset of Movii
and DNP                                           
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
	

*1.Load DNP data 
use "$master_data/2.movii_dnp_merged.dta", clear

*2.get descriptive stats of the transactions
	
	*2.1. subsidy amount
	preserve
		collapse (mean) valor_subsidio, by(documento tipo_usuario)
		sum valor_subsidio if tipo_usuario!=3, d
		kdensity valor_subsidio if tipo_usuario!=3, name("kernel_subsidy", replace)
		graph export "$graphs_trx/1.subsidy/1_kden_subsidy_amount.png", replace
		hist valor_subsidio if tipo_usuario!=3, name("hist_subsidy", replace)
		graph export "$graphs_trx/1.subsidy/2_hist_subsidy_amount.png", replace
	restore
		
		*subsidy amount by Ingreso solidario users vs the rest
		preserve
			collapse (mean) valor_subsidio, by(mes is_pers)
			
			reshape wide valor_subsidio, i(mes) j(is_pers)
			
			graph twoway line valor_subsidio0 valor_subsidio1 mes, name("subsidy_amount_is", replace) ytitle("average subsidy amount") xtitle("") xlabel(#20, angle(90)) legend(order(1 "no IS" 2 "IS"))
			
			graph export "$graphs_trx/1.subsidy/3_month_subsidy_amount_is.png", replace
		restore 
		
		*subsidy amount by user type
		preserve
			collapse (mean) valor_subsidio, by(mes tipo_usuario)
			
			reshape wide valor_subsidio, i(mes) j(tipo_usuario)
			
			graph twoway line valor_subsidio1 valor_subsidio2 valor_subsidio3 mes, name("subsidy_amount_ut", replace) ytitle("average subsidy amount") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/1.subsidy/4_month_subsidy_amount_ut.png", replace
		restore 
	
	*2.2. cash-out
		*number of cash-out by user type
		preserve
			collapse (mean) numero_total_chout, by(mes tipo_usuario)
			
			reshape wide numero_total_chout, i(mes) j(tipo_usuario)
			
			graph twoway line numero_total_chout1 numero_total_chout2 numero_total_chout3 mes, name("monthly_cashout_ut", replace) ytitle("average number of cash-out") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/2.cashout/1_number_cashout_usertype.png", replace
		restore 
		
		*cash-out amount by user type
		preserve
			collapse (mean) valor_total_chout, by(mes tipo_usuario)
			
			reshape wide valor_total_chout, i(mes) j(tipo_usuario)
			
			graph twoway line valor_total_chout1 valor_total_chout2 valor_total_chout3 mes, name("amount_cashout_ut", replace) ytitle("average total amount cash-out") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/2.cashout/2_amount_cashout_usertype.png", replace
		restore
	
		*number of cashout by Ingreso solidario users vs the rest
		preserve
			collapse (mean) numero_total_chout, by(mes is_pers)
			
			reshape wide numero_total_chout, i(mes) j(is_pers)
			
			graph twoway line numero_total_chout0 numero_total_chout1 mes, name("monthly_cashout_is", replace) ytitle("average number of cash-out") xtitle("") xlabel(#20, angle(90)) legend(order(1 "no IS" 2 "IS"))
			
			graph export "$graphs_trx/2.cashout/3_number_cashout_IS.png", replace
		restore 
		
		*total amount cashout by Ingreso solidario users vs the rest
		preserve
			collapse (mean) valor_total_chout, by(mes is_pers)
			
			reshape wide valor_total_chout, i(mes) j(is_pers)
			
			graph twoway line valor_total_chout0 valor_total_chout1 mes, name("amount_cashout_is", replace) ytitle("average total amount cash-out") xtitle("") xlabel(#20, angle(90)) legend(order(1 "no IS" 2 "IS"))
			
			graph export "$graphs_trx/2.cashout/4_total_amount_cashout_IS.png", replace
		restore 
		
		
	*2.3. cash-in
		*number of cash-in by user type
		preserve
			collapse (mean) numero_total_chin, by(mes tipo_usuario)
			
			reshape wide numero_total_chin, i(mes) j(tipo_usuario)
			
			graph twoway line numero_total_chin1 numero_total_chin2 numero_total_chin3 mes, name("monthly_cashin_ut", replace) ytitle("average number of cash-in") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/3.cashin/1_number_cashin_usertype.png", replace
		restore 
		
		*total amount cash-in by user type
		preserve
			collapse (mean) valor_total_chin, by(mes tipo_usuario)
			
			reshape wide valor_total_chin, i(mes) j(tipo_usuario)
			
			graph twoway line valor_total_chin1 valor_total_chin2 valor_total_chin3 mes, name("amount_cashin_ut", replace) ytitle("average total amount cash-in") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/3.cashin/2_amount_cashin_usertype.png", replace
		restore 
		
		*number of cash-in by Ingreso solidario users vs the rest
		preserve
			collapse (mean) numero_total_chin, by(mes is_pers)
			
			reshape wide numero_total_chin, i(mes) j(is_pers)
			
			graph twoway line numero_total_chin0 numero_total_chin1 mes, name("monthly_cashin_is", replace) ytitle("average number of cash-in") xtitle("") xlabel(#20, angle(90)) legend(order(1 "No IS" 2 "IS"))
			
			graph export "$graphs_trx/3.cashin/3_number_cashin_is.png", replace
		restore 
		
		*total amount cash-in by Ingreso solidario users vs the rest
		preserve
			collapse (mean) valor_total_chin, by(mes is_pers)
			
			reshape wide valor_total_chin, i(mes) j(is_pers)
			
			graph twoway line valor_total_chin0 valor_total_chin1 mes, name("amount_cashin_is", replace) ytitle("average total amount cash-in") xtitle("") xlabel(#20, angle(90)) legend(order(1 "No IS" 2 "IS"))
			
			graph export "$graphs_trx/3.cashin/4_amount_cashin_is.png", replace
		restore 
		
		
	
	*2.4. Transfers
		*number of transfers by user type
		preserve
			collapse (mean) numero_total_trf, by(mes tipo_usuario)
			
			reshape wide numero_total_trf, i(mes) j(tipo_usuario)
			
			graph twoway line numero_total_trf1 numero_total_trf2 numero_total_trf3 mes, name("number_transfers_ut", replace) ytitle("average number of tranfers") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/4.transfers/1_number_transfers_usertype.png", replace
		restore 
		
		*total amount transfers by user type
		preserve
			collapse (mean) valor_total_trf, by(mes tipo_usuario)
			
			reshape wide valor_total_trf, i(mes) j(tipo_usuario)
			
			graph twoway line valor_total_trf1 valor_total_trf2 valor_total_trf3 mes, name("amount_transfers_ut", replace) ytitle("average amount of tranfers") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/4.transfers/2_amount_transfers_usertype.png", replace
		restore 
		
		*number of transfers by Ingreso solidario users vs the rest
		preserve
			collapse (mean) numero_total_trf, by(mes is_pers)
			
			reshape wide numero_total_trf, i(mes) j(is_pers)
			
			graph twoway line numero_total_trf0 numero_total_trf1 mes, name("number_transfers_is", replace) ytitle("average number of transfers") xtitle("") xlabel(#20, angle(90)) legend(order(1 "No IS" 2 "IS"))
			
			graph export "$graphs_trx/4.transfers/3_number_transfers_is.png", replace
		restore 
		
		*total amount transfers by Ingreso solidario users vs the rest
		preserve
			collapse (mean) valor_total_trf, by(mes is_pers)
			
			reshape wide valor_total_trf, i(mes) j(is_pers)
			
			graph twoway line valor_total_trf0 valor_total_trf1 mes, name("amount_transfers_is", replace) ytitle("average total amount transfers") xtitle("") xlabel(#20, angle(90)) legend(order(1 "No IS" 2 "IS"))
			
			graph export "$graphs_trx/4.transfers/4_amount_transfers_is.png", replace
		restore 
		
		
		
	*2.5. Debit card purchases
		*number of debit card purchases by user type
		preserve
			collapse (mean) numero_total_comt, by(mes tipo_usuario)
			
			reshape wide numero_total_comt, i(mes) j(tipo_usuario)
			
			graph twoway line numero_total_comt1 numero_total_comt2 numero_total_comt3 mes, name("number_debitcard_purchases_ut", replace) ytitle("average number of debitcard purchases") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/5.dc_purchases/1_number_dcpurchases_usertype.png", replace
		restore 
		
		*total amount debit card purchases by user type
		preserve
			collapse (mean) valor_total_comt, by(mes tipo_usuario)
			
			reshape wide valor_total_comt, i(mes) j(tipo_usuario)
			
			graph twoway line valor_total_comt1 valor_total_comt2 valor_total_comt3 mes, name("amount_debitcard_purchases_ut", replace) ytitle("average amount of debitcard purchases") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/5.dc_purchases/2_amount_dcpurchases_usertype.png", replace
		restore 
		
		*number of debit card purchases by Ingreso solidario users vs the rest
		preserve
			collapse (mean) numero_total_comt, by(mes is_pers)
			
			reshape wide numero_total_comt, i(mes) j(is_pers)
			
			graph twoway line numero_total_comt0 numero_total_comt1 mes, name("number_debitcard_purchases_is", replace) ytitle("average number of debitcard purchases") xtitle("") xlabel(#20, angle(90)) legend(order(1 "No IS" 2 "IS"))
			
			graph export "$graphs_trx/5.dc_purchases/3_number_dcpurchases_is.png", replace
		restore 
		
		*total amount debit card purchases by Ingreso solidario users vs the rest
		preserve
			collapse (mean) valor_total_comt, by(mes is_pers)
			
			reshape wide valor_total_comt, i(mes) j(is_pers)
			
			graph twoway line valor_total_comt0 valor_total_comt1 mes, name("amount_debitcard_purchases_is", replace) ytitle("average total amount debitcard purchases") xtitle("") xlabel(#20, angle(90)) legend(order(1 "No IS" 2 "IS"))
			
			graph export "$graphs_trx/5.dc_purchases/4_amount_dcpurchases_is.png", replace
		restore 
		
		
	*2.6. online purchases
		*number of online purchases by user type
		preserve
			collapse (mean) numero_total_comv, by(mes tipo_usuario)
			
			reshape wide numero_total_comv, i(mes) j(tipo_usuario)
			
			graph twoway line numero_total_comv1 numero_total_comv2 numero_total_comv3 mes, name("number_onlinepurchase_ut", replace) ytitle("average number of online purchase") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/6.online_purchases/1_number_onlinepurchase_usertype.png", replace
		restore 
		
		*total amount online purchases by user type
		preserve
			collapse (mean) valor_total_comv, by(mes tipo_usuario)
			
			reshape wide valor_total_comv, i(mes) j(tipo_usuario)
			
			graph twoway line valor_total_comv1 valor_total_comv2 valor_total_comv3 mes, name("amount_onlinepurchase_ut", replace) ytitle("average amount of online purchase") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/6.online_purchases/2_amount_onlinepurchase_usertype.png", replace
		restore 
		
		*number of online purchases by Ingreso solidario users vs the rest
		preserve
			collapse (mean) numero_total_comv, by(mes is_pers)
			
			reshape wide numero_total_comv, i(mes) j(is_pers)
			
			graph twoway line numero_total_comv0 numero_total_comv1 mes, name("number_onlinepurchase_is", replace) ytitle("average number of online purchase") xtitle("") xlabel(#20, angle(90)) legend(order(1 "No IS" 2 "IS"))
			
			graph export "$graphs_trx/6.online_purchases/3_number_onlinepurchase_is.png", replace
		restore 
		
		*total amount online purchases by Ingreso solidario users vs the rest
		preserve
			collapse (mean) valor_total_comv, by(mes is_pers)
			
			reshape wide valor_total_comv, i(mes) j(is_pers)
			
			graph twoway line valor_total_comv0 valor_total_comv1 mes, name("amount_onlinepurchase_is", replace) ytitle("average total amount online purchase") xtitle("") xlabel(#20, angle(90)) legend(order(1 "No IS" 2 "IS"))
			
			graph export "$graphs_trx/6.online_purchases/4_amount_onlinepurchase_is.png", replace
		restore 


	*2.7. balances
		*average balance at the end of the month by user type
		preserve
			collapse (mean) saldo_cierre_mes, by(mes tipo_usuario)
			
			reshape wide saldo_cierre_mes, i(mes) j(tipo_usuario)
			
			graph twoway line saldo_cierre_mes1 saldo_cierre_mes2 saldo_cierre_mes3 mes, name("average_balance_ut", replace) ytitle("average balance at the end of the month") xtitle("") xlabel(#20, angle(90)) legend(order(1 "users before 04/2020" 2 "users after 04/2020" 3 "no aid users"))
			
			graph export "$graphs_trx/7.balance/1_balance_usertype.png", replace
		restore 
		
		*average balance at the end of the month by Ingreso solidario users vs the rest
		preserve
			collapse (mean) saldo_cierre_mes, by(mes is_pers)
			
			reshape wide saldo_cierre_mes, i(mes) j(is_pers)
			
			graph twoway line saldo_cierre_mes0 saldo_cierre_mes1 mes, name("average_balance_is", replace) ytitle("average balance at the end of the month") xtitle("") xlabel(#20, angle(90)) legend(order(1 "No IS" 2 "IS"))
			
			graph export "$graphs_trx/7.balance/2_balance_is.png", replace
		restore 


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	