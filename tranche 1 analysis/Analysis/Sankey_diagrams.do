
*******************************************************************************************************************************************
******************************************************* SANKEY DIAGRAM OUTPUTS *************************************************************
*******************************************************************************************************************************************
*******************************************************************************************************************************************


use "I:\MAA2021-55\Data exploration\Intermediate_data\\Table_dataset.dta", clear

keep if inlist(QRTR, "Q3", "Q4", "Q5", "Q6")




pause on
local WB_inds "LS_3cats FamWB_3cats LFS_cats GenHealth_cats Safety_cats discrim_cats EnghInc_cats MH_cats TrustPol_cats TrustParl_cats TrustHlth_cats TrustMed_cats TrustPpl_cats Lonely_cats"
local WB_inds_enc "LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc TrustPpl_cats_enc TrustPol_cats_enc TrustMed_cats_enc TrustParl_cats_enc TrustHlth_cats_enc Lonely_cats_enc"
local groups_of_int "Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus High_dis_18_to_39 High_dis_40_to_64 High_dis_65Plus VHigh_dis_18_to_39 VHigh_dis_40_to_64 VHigh_dis_65Plus Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_dis_18_to_39 Any_dis_40_to_64 Any_dis_65Plus Any_dis_18to64 Not_Maori_or_Pac_18to64 Maori_18to64 Pacific_18to64"

// 
local first_grp_of_int "Any_NZer"

***** requires reshaping the data to wide so will keep only the relevant variables.
keep 	`WB_inds' ///
		sqfinalwgt Auckland QRTR respondent snz_uid ///
		`groups_of_int'
		


***** reshapes teh data and attached the relevant quarter/wave to the end of the variable name, i.e., LSQ1, LSQ2, etc
reshape wide 	`WB_inds' `groups_of_int' sqfinalwgt Auckland respondent  , i(snz_uid) j(QRTR) string



******* Tester collapse code.....
// pause on
// foreach group in Solo_Mther_DC  {
// 		foreach quarter in 1 {
// 				foreach indicator in Lonely_cats {
// 					preserve
// 						local next_q = `quarter' + 1
// 						collapse (count) Count=snz_hlfs_uid  [pw=((sqfinalwgtQ`quarter'+sqfinalwgtQ`next_q')/2)] if age_18_to_64==1 &  `group'Q`quarter' == 1 & respondentQ`quarter' == 1 & respondentQ`next_q' == 1 , by(`indicator'Q`quarter' `indicator'Q`next_q') fast
// 						pause
// 					restore	
// 				}	
// 		}
// }
// end

//All_NZ
foreach set in All_NZ Auckland NotAuckland  {
	if "`set'" == "All_NZ" {
		local set_restrictions " "	
	}
	if "`set'" == "Auckland" {
		local set_restrictions "& AucklandQ`quarter' == 1"	
	}
	if "`set'" == "NotAuckland" {
		local set_restrictions "& AucklandQ`quarter' == 0"	
	}
	di "`set_restrictions'"

		***** produce sankey diagram datasets for people living in `set', broken down by variables that are looped through below.... e.g., group, quarters, and wellbeing indicators
	foreach group in `groups_of_int' {
				foreach quarter of numlist 3/5 {
						foreach indicator in `WB_inds' {
							preserve 
								local next_q = `quarter' + 1
									if "`set'" == "Auckland" {
										local set_restrictions "& AucklandQ`quarter' == 1"	
									}
									if "`set'" == "NotAuckland" {
										local set_restrictions "& AucklandQ`quarter' == 0"	
									}
								collapse (count) Est_pop=snz_uid  [pw=((sqfinalwgtQ`quarter'+sqfinalwgtQ`next_q')/2)] if  `group'Q`quarter' == 1 & respondentQ`quarter' == 1 & respondentQ`next_q' == 1 `set_restrictions', by(`indicator'Q`quarter' `indicator'Q`next_q') fast
								gen Qrt_start = `quarter'
								gen Qrt_end = `next_q'
								gen Group = "`group'"
								gen Region = "`set'"
								
								// Restructure the data to make it easier for Stats NZ checkers.
								unab vars: _all
								local omit "Qrt_start Qrt_end Group Region Est_pop"
								local reshape_vars `:list vars - omit'
								local i 1
								foreach var in `reshape_vars' {
									local newname = substr("`var'",1,length("`var'")-2 )
									rename `var' `newname'
									gen variable_`i' = "`newname'"
									rename `newname' variable_`i'_categories
									local i = `i' + 1
								}
								unab vars: _all
								local omit "Est_pop"
								local tostring_vars `:list vars - omit'
								qui tostring `tostring_vars', replace
								qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q`quarter'_to_Q`next_q'_`set'.dta", replace
							
							restore
						}	
				}
				****** does the same quarter to quarter breakdown but for quarter 3 to 6 (long-term transition)
				foreach indicator in `WB_inds' {
							preserve 
								collapse (count) Est_pop=snz_uid  [pw=((sqfinalwgtQ3+sqfinalwgtQ6)/2)] if  `group'Q3 == 1 & respondentQ3 == 1 & respondentQ6 == 1 `set_restrictions', by(`indicator'Q3 `indicator'Q6) fast
								gen Qrt_start = 3
								gen Qrt_end = 6
								gen Group = "`group'"
								gen Region = "`set'"
									
								// Restructure the data to make it easier for Stats NZ checkers.
								unab vars: _all
								local omit "Qrt_start Qrt_end Group Region Est_pop"
								local reshape_vars `:list vars - omit'
								local i 1
								foreach var in `reshape_vars' {
									local newname = substr("`var'",1,length("`var'")-2 )
									rename `var' `newname'
									gen variable_`i' = "`newname'"
									rename `newname' variable_`i'_categories
									local i = `i' + 1
								}
								unab vars: _all
								local omit "Est_pop"
								local tostring_vars `:list vars - omit'
								qui tostring `tostring_vars', replace
								qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q3_to_Q6_`set'.dta", replace
							restore
				}
			
			
			
	}
	
	*** combines all the breakdowns for each 'set'
	preserve
	use "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\LS_3cats_Any_NZer_Q3_to_Q4_`set'.dta", clear
	foreach indicator in `WB_inds' {
		foreach group in `groups_of_int' {
			foreach quarter of numlist 3/5 {
				local next_q = `quarter' + 1 
				if "`indicator'" == "LS_3cats" & "`group'" == "Any_NZer" & "`quarter'" == "3" & "`next_q'" == "4"  {
							    
				}
				else {
					append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q`quarter'_to_Q`next_q'_`set'.dta"
							
				}
				if "`quarter'" == "3" {
					append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q`quarter'_to_Q6_`set'.dta"
				}
							
			}
		} 
	}
	save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sankey_`set'.dta", replace
	restore		
}
  
use "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sankey_All_NZ.dta", clear
append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sankey_Auckland.dta"
append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sankey_NotAuckland.dta"

rename variable_1 Wellbeing_Indicator
drop variable_2

export excel using "I:\MAA2021-55\Outputs\\Descriptive_tables_data_raw_26_May_2022.xlsx", firstrow(variables)  sheet(Sankey_diag_data) replace 

replace Est_pop = . if Est_pop < 1000 
replace Est_pop = round(Est_pop, 100) 

export excel using "I:\MAA2021-55\Outputs\\Descriptive_tables_data_clean_26_May_2022.xlsx", firstrow(variables)  sheet(Sankey_diag_data) replace 














/*





				foreach indicator in  FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
					append using  "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q1_to_Q2_Auckland.dta"
				}
				foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
					append using  "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q1_to_Q4_Auckland.dta"
				}
				foreach quarter of numlist 2/3 {
						foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
							local next_q = `quarter' + 1 
							append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q`quarter'_to_Q`next_q'_Auckland.dta"
						}
				}
				qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`group'_Auckland.dta", replace
				restore
		}
		***** combines all of the auckland based sankey diagram data
		preserve
		use "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Prtnr_Fther_DC_Auckland.dta", clear
		foreach group in  Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer {
			append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`group'_Auckland.dta"
		}
		save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sanky_Auckland.dta", replace
		restore




***** produce sankey diagram datasets for people living in OUTSIDE of Auckland only, broken down by variables that are looped through below.... e.g., group, quarters, and wellbeing indicators
foreach group in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer {
		foreach quarter of numlist 1/3 {
				foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
					preserve 
						local next_q = `quarter' + 1
						collapse (count) Count=snz_hlfs_uid  [pw=((sqfinalwgtQ`quarter'+sqfinalwgtQ`next_q')/2)] if age_18_to_64==1 &  `group'Q`quarter' == 1 & respondentQ`quarter' == 1 & respondentQ`next_q' == 1 & AucklandQ`quarter' == 0, by(`indicator'Q`quarter' `indicator'Q`next_q') fast
						gen Qrt_start = `quarter'
						gen Qrt_end = `next_q'
						gen Group = "`group'"
						gen Region = "Not Auckland"
						gen Ethnicity = "All"
						
						// Restructure the data to make it easier for Stats NZ checkers.
						unab vars: _all
						local omit "Qrt_start Qrt_end Group Region Ethnicity Count"
						local reshape_vars `:list vars - omit'
						local i 1
						foreach var in `reshape_vars' {
							local newname = substr("`var'",1,length("`var'")-2 )
							rename `var' `newname'
							gen variable_`i' = "`newname'"
							rename `newname' variable_`i'_categories
							local i = `i' + 1
						}
						unab vars: _all
						local omit "Count"
						local tostring_vars `:list vars - omit'
						qui tostring `tostring_vars', replace
						qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q`quarter'_to_Q`next_q'_NotAuckland.dta", replace
					
					restore
				}	
		}
		****** does the same quarter to quarter breakdown but for quarter 1 to 4 (long-term transition)
		foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
					preserve 
						collapse (count) Count=snz_hlfs_uid  [pw=((sqfinalwgtQ1+sqfinalwgtQ4)/2)] if age_18_to_64==1 &  `group'Q1 == 1 & respondentQ1 == 1 & respondentQ4 == 1 & AucklandQ1 == 0, by(`indicator'Q1 `indicator'Q4) fast
						gen Qrt_start = 1
						gen Qrt_end = 4
						gen Group = "`group'"
						gen Region = "Not Auckland"
						gen Ethnicity = "All"
						
						// Restructure the data to make it easier for Stats NZ checkers.
						unab vars: _all
						local omit "Qrt_start Qrt_end Group Region Ethnicity Count"
						local reshape_vars `:list vars - omit'
						local i 1
						foreach var in `reshape_vars' {
							local newname = substr("`var'",1,length("`var'")-2 )
							rename `var' `newname'
							gen variable_`i' = "`newname'"
							rename `newname' variable_`i'_categories
							local i = `i' + 1
						}
						unab vars: _all
						local omit "Count"
						local tostring_vars `:list vars - omit'
						qui tostring `tostring_vars', replace
						qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q1_to_Q4_NotAuckland.dta", replace
					restore
		}
		preserve
		use "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\LS_3cats_`group'_Q1_to_Q2_NotAuckland.dta", clear
		foreach indicator in  FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
			append using  "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q1_to_Q2_NotAuckland.dta"
		}
		foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
			append using  "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q1_to_Q4_NotAuckland.dta"
		}
		foreach quarter of numlist 2/3 {
				foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
					local next_q = `quarter' + 1 
					append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q`quarter'_to_Q`next_q'_NotAuckland.dta"
				}
		}
		qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`group'_NotAuckland.dta", replace
		restore
}
***** combines all of the not auckland based sankey diagram data
preserve
use "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Prtnr_Fther_DC_NotAuckland.dta", clear
foreach group in  Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer {
	append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`group'_NotAuckland.dta"
}
save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sanky_NotAuckland.dta", replace
restore





***** produce sankey diagram datasets for different ethnicity groups, broken down by variables that are looped through below.... e.g., group, quarters, and wellbeing indicators
foreach ethnicity in Not_Maori_or_Pacific_eth Maori_or_Pacific_eth Maori_eth Pacific_eth All_ethnicities {
	
	foreach group in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer {
			foreach quarter of numlist 1/3 {
					foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
						preserve 
							local next_q = `quarter' + 1
							collapse (count) Count=snz_hlfs_uid  [pw=((sqfinalwgtQ`quarter'+sqfinalwgtQ`next_q')/2)] if age_18_to_64==1 &  `group'Q`quarter' == 1 & respondentQ`quarter' == 1 & respondentQ`next_q' == 1 & `ethnicity' == 1, by(`indicator'Q`quarter' `indicator'Q`next_q') fast
							gen Qrt_start = `quarter'
							gen Qrt_end = `next_q'
							gen Group = "`group'"
							gen Region = "All"
							gen Ethnicity = "`ethnicity'"
							
							// Restructure the data to make it easier for Stats NZ checkers.
							unab vars: _all
							local omit "Qrt_start Qrt_end Group Region Ethnicity Count"
							local reshape_vars `:list vars - omit'
							local i 1
							foreach var in `reshape_vars' {
								local newname = substr("`var'",1,length("`var'")-2 )
								rename `var' `newname'
								gen variable_`i' = "`newname'"
								rename `newname' variable_`i'_categories
								local i = `i' + 1
							}
							unab vars: _all
							local omit "Count"
							local tostring_vars `:list vars - omit'
							qui tostring `tostring_vars', replace
							
							
							qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q`quarter'_to_Q`next_q'_Eth`ethnicity'.dta", replace
						
						restore
					}	
			}
			****** does the same quarter to quarter breakdown but for quarter 1 to 4 (long-term transition)
			foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
						preserve 
							collapse (count) Count=snz_hlfs_uid  [pw=((sqfinalwgtQ1+sqfinalwgtQ4)/2)] if age_18_to_64==1 &  `group'Q1 == 1 & respondentQ1 == 1 & respondentQ4 == 1 & `ethnicity' == 1, by(`indicator'Q1 `indicator'Q4) fast
							gen Qrt_start = 1
							gen Qrt_end = 4
							gen Group = "`group'"
							gen Region = "All"
							gen Ethnicity = "`ethnicity'"
							
							// Restructure the data to make it easier for Stats NZ checkers.
							unab vars: _all
							local omit "Qrt_start Qrt_end Group Region Ethnicity Count"
							local reshape_vars `:list vars - omit'
							local i 1
							foreach var in `reshape_vars' {
								local newname = substr("`var'",1,length("`var'")-2 )
								rename `var' `newname'
								gen variable_`i' = "`newname'"
								rename `newname' variable_`i'_categories
								local i = `i' + 1
							}
							unab vars: _all
							local omit "Count"
							local tostring_vars `:list vars - omit'
							qui tostring `tostring_vars', replace
							qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q1_to_Q4_Eth`ethnicity'.dta", replace
						restore
			}
			preserve
			use "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\LS_3cats_`group'_Q1_to_Q2_Eth`ethnicity'.dta", clear
			foreach indicator in  FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
				append using  "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q1_to_Q2_Eth`ethnicity'.dta"
			}
			foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
				append using  "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q1_to_Q4_Eth`ethnicity'.dta"
			}
			foreach quarter of numlist 2/3 {
					foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
						local next_q = `quarter' + 1 
						append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q`quarter'_to_Q`next_q'_Eth`ethnicity'.dta"
					}
			}
			qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`group'_Eth`ethnicity'.dta", replace
			restore
	}
	***** combines all of the ethnicity based sankey diagram data
	preserve
	use "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Prtnr_Fther_DC_Eth`ethnicity'.dta", clear
	foreach group in  Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer {
		append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`group'_Eth`ethnicity'.dta"
	}
	save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sanky_Eth`ethnicity'.dta", replace
	restore
		
}



***** combines the AUCKLAND, NOT AUCKLAND, and ETHNICITY based breakdowns together
use "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sanky_Auckland.dta", clear
append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sanky_NotAuckland.dta"
foreach ethnicity in Not_Maori_or_Pacific_eth Maori_or_Pacific_eth Maori_eth Pacific_eth All_ethnicities  {
	append using "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sanky_Eth`ethnicity'.dta"
}





***** prepares the data for outputting, i.e., attaches an output date, suppresses appropriately, and rounds according to the output guide.
gen output_date = "${S_DATE}"
order Qrt_start Qrt_end variable_1 variable_2 variable_1_categories variable_2_categories  Group Region Ethnicity Count output_date
save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sankey_data_raw.dta", replace

// specifies directory for the output file (excel file) 
export excel using "I:\MAA2021-55\Outputs\\Sankey_data_raw_12_May_2022.xlsx", firstrow(variables)  sheet(Sankey) replace 
replace Count = . if Count < 1000
replace Count = round(Count, 100)
save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sankey_data_clean.dta", replace
export excel using "I:\MAA2021-55\Outputs\\Sankey_data_clean_12_May_2022.xlsx", firstrow(variables)  sheet(Sankey) replace 



