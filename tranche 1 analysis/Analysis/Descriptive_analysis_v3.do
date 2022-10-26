


*******************************************************************************************************************************************
************************************************** DESCRIPTIVE TABLE  OUTPUTS *************************************************************
*******************************************************************************************************************************************
*******************************************************************************************************************************************

// Auckland NotAuckland 



//
// local set Auckland
// foreach var in Fam_WB SWB_LS SWB_LWW WHO5 {
// 	foreach Qrter of numlist 1/6 {
//		
// 		foreach grp in `groups_of_int' {
// 			if ("`var'" == "WHO5" & inlist(`Qrter', 1, 4,5,6)) | ("`var'" == "Fam_WB" & inlist(`Qrter', 1)) {
//		    
// 			}
// 			else {
// 				di "`var',  `grp', Q`Qrter'"
// 				mean `var' if `grp' == 1 & QRTR == "Q`Qrter'" `set_restrictions'
// 			}	
// 		}
//
// 	}
// }
// Auckland NotAuckland


clear all
pause on

do "I:\MAA2021-55\Exploratory_analyis/_0_Init.do"

local dt = "${S_DATE}"
local date_today =  subinstr("`dt'"," ", "_",.)
di "`date_today'"

foreach set in All_NZ Auckland NotAuckland {
	if "`set'" == "All_NZ" {
		local set_restrictions " "	
	}
	if "`set'" == "Auckland" {
		local set_restrictions "& Auckland == 1"	
	}
	if "`set'" == "NotAuckland" {
		local set_restrictions "& Auckland == 0"	
	}
	di "`set_restrictions'"
	
use "I:\MAA2021-55\Data exploration\Intermediate_data\\Table_dataset.dta", clear

svyset snz_uid [pweight=sqfinalwgt], vce(jackknife) jkrweight(sqfinalwgt_*)



***** example code to describe the methodology used below in the loops
* ereturn list command below provides all of the stored estimates following the svy: mean command. we only need row 8 and 9, the estimated population and the number of observations that contributed to this estimate.
* 'mat S = r(table)' and 'mat list S' shows the other estimates that are captured, we care about 1-6, i.e., mean std_error t_stat p_val CI_lower CI_upper
* we also run a separate command to get the standard deviation ('estat sd'), and grab that using 'r(sd)'
* ultimate, we put all of these values into a vector that correspond to the specific group, and then combine them into a single matrix for a given wellbeing indicator and quarter, we then turn these into actual variables and combine all of the data.

// svy: mean LS if father_DC == 1 & QRTR == "Q1"
// ereturn list
// mat S = r(table)
// mat list S
// estat sd
// mat R = r(sd)
// mat list R

//
// encode MH_cats, gen(MH_cats_encoded)
// svy: proportion MH_cats_encoded if father_DC == 1 & QRTR == "Q1"
// ereturn list
// mat S = r(table)
// mat list S
local WB_inds "LS_3cats FamWB_3cats LFS_cats GenHealth_cats Safety_cats discrim_cats EnghInc_cats MH_cats TrustPol_cats TrustParl_cats TrustHlth_cats TrustMed_cats TrustPpl_cats Lonely_cats"
local WB_inds_enc "LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc TrustPpl_cats_enc TrustPol_cats_enc TrustMed_cats_enc TrustParl_cats_enc TrustHlth_cats_enc Lonely_cats_enc"

// local groups_of_int "Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus High_dis_18_to_39 High_dis_40_to_64 High_dis_65Plus VHigh_dis_18_to_39 VHigh_dis_40_to_64 VHigh_dis_65Plus Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_dis_18_to_39 Any_dis_40_to_64 Any_dis_65Plus Any_dis_18to64 Not_Maori_or_Pac_18to64 Maori_18to64 Pacific_18to64"
// local first_grp_of_int "Any_NZer"

local groups_of_int "Any_NZer Male_65Plus Female_65Plus Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus Any_dis_65Plus"

local first_grp_of_int "Any_NZer"
local count_of_groups = 7


// 


// Fam_WB SWB_LS SWB_LWW
foreach var in Fam_WB SWB_LS SWB_LWW WHO5 {
	foreach Qrter of numlist 1/6 {
		local i = 1
		matrix mean_`var'_grps_Q`Qrter' = J(9,`count_of_groups',.)
		
		foreach grp in `groups_of_int' {
			if ("`var'" == "WHO5" & inlist(`Qrter', 1, 4,5,6)) | ("`var'" == "Fam_WB" & inlist(`Qrter', 1)) {
		    
			}
			else {
				
				qui svy: mean `var' if `grp' == 1 & QRTR == "Q`Qrter'" `set_restrictions'
								
				mat mean_`var'_grps_Q`Qrter'[8,`i'] = e(N_pop)
				mat mean_`var'_grps_Q`Qrter'[9,`i'] = e(N)
				foreach row of numlist 1/6 {
					mat mean_`var'_grps_Q`Qrter'[`row',`i'] = r(table)[`row',1]
				}

				qui svy: mean `var' if `grp' == 1 & QRTR == "Q`Qrter'"  `set_restrictions'
				
				qui estat sd
				mat mean_`var'_grps_Q`Qrter'[7,`i'] = r(sd)
				
				local i = `i' + 1
			}	
		}
		matrix rownames mean_`var'_grps_Q`Qrter' = mean std_error t_stat p_val CI_lower CI_upper std_dev est_pop obs
		matrix colnames mean_`var'_grps_Q`Qrter' = `groups_of_int'
		di "Q`Qrter' completed"
		mat list mean_`var'_grps_Q`Qrter'
	}
}
// Fam_WB SWB_LS SWB_LWW
foreach var in Fam_WB SWB_LS SWB_LWW WHO5 {
	foreach Qrter of numlist 1/6 { 
	    if ("`var'" == "WHO5" & inlist(`Qrter', 1, 4,5,6)) | ("`var'" == "Fam_WB" & inlist(`Qrter', 1))  {
		    
		}
		else {
		preserve
		svmat double mean_`var'_grps_Q`Qrter', name (tempvar)
		gen statistic = ""
		replace statistic = "mean" if _n == 1
		replace statistic = "standard error" if _n == 2
		replace statistic = "t statistic" if _n == 3
		replace statistic = "p value" if _n == 4
		replace statistic = "Lower CI estimate" if _n == 5
		replace statistic = "Upper CI estimate" if _n == 6
		replace statistic = "standard deviation" if _n == 7
		replace statistic = "estimated pop size" if _n == 8
		replace statistic = "observations" if _n == 9
		keep tempvar* statistic
		gen wave = `Qrter'
		gen wellbeing_measure = "`var'"
		local i = 1
		foreach grp in `groups_of_int' {
			
			rename tempvar`i' `grp'
			local i = `i' +1
		}
		drop if statistic == ""
		save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_mean_`var'_`Qrter'_`set'.dta", replace
		restore
		}
	}
}


	preserve
use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_mean_Fam_WB_2_`set'.dta", clear
foreach var in Fam_WB SWB_LS SWB_LWW WHO5 {
	foreach Qrter of numlist 1/6 {  
			if ("`var'" == "Fam_WB" & inlist(`Qrter', 1,2)) | ("`var'" == "WHO5" & inlist(`Qrter', 1,4,5,6))  {
				
			} 
			else {
				append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_mean_`var'_`Qrter'_`set'.dta"
				
			}
		
			di "`var'"
	}
}

save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_mean_all_variables_`set'.dta", replace	

restore


//
// preserve
// use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_Fam_WB_1.dta", clear
// foreach Qrter of numlist 2/4 {  
// 	append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_Fam_WB_`Qrter'.dta"
// }
//
// foreach var in SWB_LS SWB_LWW {
// 	foreach Qrter of numlist 1/4 {  
// 		append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_`var'_`Qrter'.dta"
// 	}
// }
// save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_all_variables.dta", replace	
// restore

//
//
// svy: proportion Lonely_cats_enc if father_DC == 1 & QRTR == "Q1" & Lonely_cats_enc ~=.
// local cols = e(k_eexp)
// mat abc = r(table)[1..6,1..`cols']
//
// svmat double abc, name (tempvar)
// levelsof Lonely_cats_enc, local(categories)	
// local i = 1
// foreach category in `categories' {
// 	rename tempvar`i' v`category'
// 	local i = `i' + 1
// }

// 
// 
// 
// prop_`var'_`grp'_Q`Qrter'


pause on
foreach var in `WB_inds_enc' {
	foreach Qrter of numlist 1/6 {
		foreach grp in `groups_of_int' {

			qui svy: proportion `var' if `grp' == 1 & QRTR == "Q`Qrter'"   `set_restrictions'

// 			local cols = e(k_eexp)
// 			mat temp_mat = r(table)[1..6,1..`cols']
// 			svmat double temp_mat , name (tempvar)
// 			local categories_of_vars = e(varlist) 
// 			di "`categories_of_vars'"
// 			local i = 1
// 			foreach column in `categories_of_vars' {
// 				di "`column'"
// 					local first_char = substr("`column'", 1,1)
// 					rename tempvar`i' value_cat`first_char'
// 					local i = `i' + 1
// 			}
						
// 			qui svy: proportion `var' if `grp' == 1 & QRTR == "Q`Qrter'" & age_18_to_64 == 1 & `var' ~=.
			local cols = e(k_eexp)
			local categories_of_vars = e(varlist) 
			mat temp_mat = r(table)[1..6,1..`cols']
			local varname = substr("`var'",1,length("`var'") - 4)
			
			preserve
				svmat double temp_mat , name (tempvar)
				local i = 1
				foreach column in `categories_of_vars' {
					local first_char = substr("`column'", 1,1)
					rename tempvar`i' value_cat`first_char'
					local i = `i' + 1
				}
				gen group = "`grp'"
				gen wave = `Qrter'
				gen wellbeing_measure = "`varname'"

				gen statistic = ""
				replace statistic = "proportion" if _n == 1
				replace statistic = "standard error" if _n == 2
				replace statistic = "t statistic" if _n == 3
				replace statistic = "p value" if _n == 4
				replace statistic = "Lower CI estimate" if _n == 5
				replace statistic = "Upper CI estimate" if _n == 6
				
				keep value_cat* group wave wellbeing_measure statistic
				keep if statistic ~= ""
				reshape long value_, i(statistic group wellbeing_measure wave) j(category) string
				save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_p_`varname'_Q`Qrter'_`grp'_`set'.dta", replace 
			restore
		}
		di "Q`Qrter' completed"
	}
}
preserve


use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_p_EnghInc_cats_Q3_`first_grp_of_int'_`set'.dta", clear

foreach var in `WB_inds_enc' {
	local varname = substr("`var'",1,length("`var'") - 4)
	foreach Qrter of numlist 1/6 {
		foreach grp in `groups_of_int' {
			if "`varname'" == "EnghInc_cats" & "`Qrter'" == "3" & "`grp'" == "`first_grp_of_int'"  {
				
			} 
			else {
				append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_p_`varname'_Q`Qrter'_`grp'_`set'.dta"
				
			}
			
		}
	}	
}
replace  category = substr(category,4,1)
destring category, replace
save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_proportions_data_`set'.dta", replace 



restore


***************************************************************************************************************************************
********************************************* POPULATION ESTIMATES AND OBSERVATION COUNTS *********************************************
***************************************************************************************************************************************

foreach var in `WB_inds_enc' {
	foreach Qrter of numlist 1/6 {
		foreach grp in `groups_of_int' {

			preserve
			collapse (count) Est_pop=snz_uid [pweight=sqfinalwgt] if `grp' == 1 & QRTR == "Q`Qrter'"  `set_restrictions', by(`var')
			local varname = substr("`var'",1,length("`var'") - 4)
			decode `var', gen(var_categories)
			gen group = "`grp'"
			gen wave = `Qrter'
			gen wellbeing_measure = "`varname'"
			rename `var' encoded_cats
			save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_Cnt_`var'_Q`Qrter'_`grp'_`set'.dta", replace 
			restore
			
		}
		di "Q`Qrter' completed"
	}
}


foreach var in `WB_inds_enc' {
	foreach Qrter of numlist 1/6 {
		foreach grp in `groups_of_int' {
			preserve
			collapse (count) Observations=snz_uid  if `grp' == 1 & QRTR == "Q`Qrter'"  `set_restrictions', by(`var')
			local varname = substr("`var'",1,length("`var'") - 4)
			decode `var', gen(var_categories)
			gen group = "`grp'"
			gen wave = `Qrter'
			gen wellbeing_measure = "`varname'"
			rename `var' encoded_cats
			save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_Obs_`var'_Q`Qrter'_`grp'_`set'.dta", replace 
			restore
			
		}
		di "Q`Qrter' completed"
	}
}


preserve
use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_Cnt_EnghInc_cats_enc_Q3_`first_grp_of_int'_`set'.dta", clear
// append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_EnghInc_cats_enc_Q1_Prtnr_Mther_DC.dta"
foreach var in `WB_inds_enc' {
	foreach Qrter of numlist 1/6 {
		foreach grp in `groups_of_int' {
			if "`var'" == "EnghInc_cats_enc" & "`Qrter'" == "3" & "`grp'" == "`first_grp_of_int'" {
				
			} 
			else {
				append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_Cnt_`var'_Q`Qrter'_`grp'_`set'.dta"
				
			}
		
		}
	}
}	
foreach var in `WB_inds_enc' {
	foreach Qrter of numlist 1/6 {
		foreach grp in `groups_of_int' {

				mmerge encoded_cats group wave wellbeing_measure using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_Obs_`var'_Q`Qrter'_`grp'_`set'.dta", unm(both) update
		
		}
	}
}	
save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_Obs_and_pop_est_`set'.dta", replace 


restore	
}




pause on
local WB_inds "LS_3cats FamWB_3cats LFS_cats GenHealth_cats Safety_cats discrim_cats EnghInc_cats MH_cats TrustPol_cats TrustParl_cats TrustHlth_cats TrustMed_cats TrustPpl_cats Lonely_cats"
local WB_inds_enc "LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc TrustPpl_cats_enc TrustPol_cats_enc TrustMed_cats_enc TrustParl_cats_enc TrustHlth_cats_enc Lonely_cats_enc"
local groups_of_int "Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus High_dis_18_to_39 High_dis_40_to_64 High_dis_65Plus VHigh_dis_18_to_39 VHigh_dis_40_to_64 VHigh_dis_65Plus Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_dis_18_to_39 Any_dis_40_to_64 Any_dis_65Plus Any_dis_18to64 Not_Maori_or_Pac_18to64 Maori_18to64 Pacific_18to64"

// 
local first_grp_of_int "Any_NZer"
local count_of_groups = 27
foreach set in All_NZ Auckland NotAuckland {
	
	
	use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_mean_all_variables_`set'.dta", clear
		gen region = "`set'"
		foreach var in `groups_of_int' {
			rename `var' value_`var'
		}
		drop if statistic == ""
		
		reshape long value_ ,i(statistic wave wellbeing_measure ) j(group) string
		replace statistic = "std_err"  if statistic == "standard error"
		replace statistic = "t_stat" if statistic ==  "t statistic"
		replace statistic = "p_val" if statistic ==  "p value"
		replace statistic = "lower_CI_est" if statistic ==  "Lower CI estimate"
		replace statistic = "upper_CI_est" if statistic ==  "Upper CI estimate"
		replace statistic = "std_dev" if statistic ==  "standard deviation"
		replace statistic = "est_pop" if statistic ==  "estimated pop size"
		replace statistic = "obs" if statistic ==  "observations"
		reshape wide value_ ,i(group wave wellbeing_measure) j(statistic) string
		sort group wellbeing_measure wave
		order group wellbeing_measure  wave
		rename value_est_pop Est_pop
		rename value_obs Observations
		save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_HLFS_mean_reshaped_`set'.dta", replace
		 
	
		use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_proportions_data_`set'.dta", clear
		
		gen region = "`set'"
		replace statistic = "std_err"  if statistic == "standard error"
		replace statistic = "t_stat" if statistic ==  "t statistic"
		replace statistic = "p_val" if statistic ==  "p value"
		replace statistic = "lower_CI_est" if statistic ==  "Lower CI estimate"
		replace statistic = "upper_CI_est" if statistic ==  "Upper CI estimate"
		replace statistic = "std_dev" if statistic ==  "standard deviation"
//		
//		
// 		replace statistic = "t statistic" if statistic == "t_stat"
// 		replace statistic = "standard error" if statistic == "std_err"
// 		replace statistic = "p value"if statistic == "p_val"
// 		replace statistic = "Lower CI estimate" if statistic == "lower_CI_est"
// 		replace statistic = "Upper CI estimate" if statistic == "upper_CI_est"
		
		reshape wide value_ ,i(group wellbeing_measure wave category) j(statistic) string
		mmerge category group wellbeing_measure wave using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_Obs_and_pop_est_`set'.dta", unm(master) umatch(encoded_cats group  wellbeing_measure wave) update
		sort group wellbeing_measure var_categories wave
		order group wellbeing_measure var_categories wave
		drop category _merge
		append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_HLFS_mean_reshaped_`set'.dta"
		save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_HLFS_desc_tables_data_`set'.dta", replace

}



use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_HLFS_desc_tables_data_All_NZ.dta", clear
append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_HLFS_desc_tables_data_Auckland.dta"
append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\V3_`date_today'_HLFS_desc_tables_data_NotAuckland.dta"
//append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS_desc_tables_data.dta"
// append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS2018_desc_tables_data.dta"
// append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS2016_desc_tables_data.dta"
sort region group wellbeing_measure var_categories wave
gen survey = "GSS 2016" if wave == 1
replace survey = "GSS 2018" if wave == 2
replace survey = "HLFS WB supplement wave 1" if wave == 3
replace survey = "HLFS WB supplement wave 2" if wave == 4
replace survey = "HLFS WB supplement wave 3" if wave == 5
replace survey = "HLFS WB supplement wave 4" if wave == 6
order region group wellbeing_measure var_categories wave survey Est_pop value_mean value_proportion value_std_err value_lower_CI_est value_upper_CI_est value_p_val   value_t_stat value_std_dev Observations  

save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\WBR_disability_parents_desc_tables_data_`date_today'.dta", replace








**************************************************************************************************************************************************************************
**************************************************************************************************************************************************************************
**************************************************************************************************************************************************************************

// specifies directory for the output file (excel file) and suppresses small counts as per microdata output guide.
export excel using "I:\MAA2021-55\Outputs\\Descriptive_tables_data_raw_`date_today'.xlsx", firstrow(variables)  sheet(HLFS_GSS_desc_data) replace 

*** identify rows where the metric of interest is the mean (==1 when its a row based on a mean estimate, ==0 when its the proportion)
gen mean_row = (value_mean ~=. )

*** Loops through all of the mean estimate related values and the count itself
foreach col in value_std_err value_t_stat value_upper_CI_est value_mean value_lower_CI_est value_p_val value_std_dev Observations {
	*** replaces all values associated with the mean estimates + the count itself to missing if the raw-unweighted-count is < 20 - where disability data is used.
	replace `col' = . if mean_row == 1 & Observations < 20 & (inlist(group, "VHigh_dis_18_to_39", "VHigh_dis_40_to_64", "VHigh_dis_65Plus", "Any_dis_18_to_39", "Any_dis_18to64") | inlist(group,"Any_dis_40_to_64", "Any_dis_65Plus", "High_dis_18_to_39", "High_dis_40_to_64", "High_dis_65Plus"))

	*** replaces all values associated with the mean estimates + the count itself to missing if the raw-unweighted-count is < 5 - where disability data IS NOT used.
	replace `col' = . if mean_row == 1 & Observations < 20 & ~inlist(group, "VHigh_dis_18_to_39", "VHigh_dis_40_to_64", "VHigh_dis_65Plus", "Any_dis_18_to_39", "Any_dis_18to64") & ~inlist(group,"Any_dis_40_to_64", "Any_dis_65Plus", "High_dis_18_to_39", "High_dis_40_to_64", "High_dis_65Plus")
	
			*** replaces the counts for the rows where the proportion has been estimated, to be consistent with the above rules. 
	if "`col'" == "Observations" {
			replace `col' = . if mean_row == 0 & Observations < 20 & (inlist(group, "VHigh_dis_18_to_39", "VHigh_dis_40_to_64", "VHigh_dis_65Plus", "Any_dis_18_to_39", "Any_dis_18to64") | inlist(group,"Any_dis_40_to_64", "Any_dis_65Plus", "High_dis_18_to_39", "High_dis_40_to_64", "High_dis_65Plus"))
			replace `col' = . if mean_row == 0 & Observations < 20 & ~inlist(group, "VHigh_dis_18_to_39", "VHigh_dis_40_to_64", "VHigh_dis_65Plus", "Any_dis_18_to_39", "Any_dis_18to64") & ~inlist(group,"Any_dis_40_to_64", "Any_dis_65Plus", "High_dis_18_to_39", "High_dis_40_to_64", "High_dis_65Plus")
	}
}

*** Loops through all of the proportion estimate related values and the population estimate itself
foreach col in value_std_err value_proportion value_upper_CI_est value_t_stat value_lower_CI_est value_p_val Est_pop {
	replace `col' = . if mean_row == 0 & Est_pop < 1000 
}

foreach col in value_upper_CI_est  value_lower_CI_est  value_proportion  {
	replace `col' = round(`col', 0.001) 
}	

grr  Observations, seed(16000) base(3) replace
replace Est_pop = round(Est_pop, 1000) if wave <= 2 //GSS data
replace Est_pop = round(Est_pop, 100) if wave >= 3 //HLFS data



drop mean_row

export excel using "I:\MAA2021-55\Outputs\\Descriptive_tables_data_clean_`date_today'.xlsx", firstrow(variables)  sheet(HLFS_desc_data) replace 

**************************************************************************************************************************************************************************
**************************************************************************************************************************************************************************
**************************************************************************************************************************************************************************








