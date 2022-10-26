****** CODE TO IMPORT METADATA AND DEFINITIONS FOR THE WELLBEING REPORT PROJECT, THIS SCRIPT ALSO DOWNLOADS ADDITIONAL DATA NOT PROCESSED BY THE DATA ASSEMBLY TOOL.
**** Author: Shaan Badenhorst
**** Reviewer: 

**** Notes: The latter half of this script needs to be rerun with each refresh of the IDI.

// History (reverse order): 
// 2022-05-XX Draft QA'd (  )
// 2022-04-27 First draft started (SB)

// Outputs
* Stata .dta files to merge the classifications.

clear all
pause on

do "I:\MAA2021-55\Exploratory_analyis/_0_Init.do"

************************************************************ 
************************************************************ 
************************************************************
*** NEEDS TO BE UPDATED WITH EACH NEW REFRESH OF THE IDI ***
************************************************************
************************************************************
************************************************************

// Globals created for ODBC functionality
	global IDI_DB idi_clean_202203
	global IDI_SP idi_sandpit
	global IDI_Adhoc idi_adhoc

 ******************************************
 * ODBC parameters 
 * (shouldn't need to be changed)
 ******************************************
 
	global IDI_CONN conn(NOT RELEASED)
 	global IDISP_CONN conn(NOT RELEASED)
	global IDIAH_CONN conn(NOT RELEASED)

 ******************************************
 * Stata functionality with ODBC
 ******************************************

odbc load, bigint clear exec("select * from  [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables]") $IDISP_CONN

** Validating that the use of the sample weights are producing what has been publicly reported by Stats
// collapse (count) snz_hlfs_uid [pw=sqfinalwgt] if age>=18 & aug20 == 1, by(MHS_qEnoughIncome)
// Looks good using the finalweights in that way for collapses.

** General HLFS based indicators
gen unemployed = (DVLFS == 2)
replace unemployed = . if DVLFS == 77 // None were status unidentified

gen Not_in_LabourForce = (DVLFS == 3)
replace Not_in_LabourForce = . if DVLFS == 77 // None were status unidentified

*PWB_qHealthExcellentPoor PWB_qTrustMostPeopleScale Dep17 DVLFS MHS_qEnoughIncome
* DVUnderUtilise not available in GSS...
gen good_or_better_health = (PWB_qHealthExcellentPoor <= 13)
replace good_or_better_health = . if PWB_qHealthExcellentPoor >= 88
gen vgood_or_better_health = (PWB_qHealthExcellentPoor <= 12)
replace vgood_or_better_health = . if PWB_qHealthExcellentPoor >= 88

** Trust
gen high_or_vhigh_trust_ppl = (inlist(PWB_qTrustMostPeopleScale, 7,8,9,10))
gen vhigh_trust_ppl = (inlist(PWB_qTrustMostPeopleScale, 9,10))

gen high_or_vhigh_trust_pol = (inlist(PWB_qTrustPol, 7,8,9,10))
gen vhigh_trust_pol = (inlist(PWB_qTrustPol, 9,10))

gen high_or_vhigh_trust_par = (inlist(PWB_qTrustParl, 7,8,9,10))
gen vhigh_trust_par = (inlist(PWB_qTrustParl, 9,10))

gen high_or_vhigh_trust_med = (inlist(PWB_qTrustMed, 7,8,9,10))
gen vhigh_trust_med = (inlist(PWB_qTrustMed, 9,10))

gen high_or_vhigh_trust_hlth = (inlist(PWB_qTrustHlth, 7,8,9,10))
gen vhigh_trust_hlth = (inlist(PWB_qTrustHlth, 9,10))

** Not enough income indicators, only just enough or better AND enough income or better.
gen only_just_enough_income_plus = (inlist(MHS_qEnoughIncome, 12,13,14))
gen enough_income_plus = (inlist(MHS_qEnoughIncome, 13,14))

** SWA: life satisfaction, family wellbeing and life worthwhile
destring PWB_qFeelAboutLifeScale, replace
replace PWB_qFeelAboutLifeScale = . if PWB_qFeelAboutLifeScale >= 80
gen high_LS = (PWB_qFeelAboutLifeScale >= 7)

destring PWB_qThingsWorthwhileScale, replace
replace PWB_qThingsWorthwhileScale = . if PWB_qThingsWorthwhileScale >= 80
gen high_Life_Worthwhile = (PWB_qThingsWorthwhileScale >= 7)

**Lonely most or all of the time binary indicator
gen lonely_most_or_all = (inlist(PWB_qTimeLonely, 14,15))

** Discriminated against indicator
gen discriminated = (PWB_qDiscriminated == 1)

** Feeling unsafe or very unsafe in neighbourhood walking after dark most
destring PWB_qSafeNightHood, replace
gen Unsafe_VUnsafe_ind = (inlist(PWB_qSafeNightHood, 14,15))

** MSD definition of material harship and severe material hardship based on MWI and DEP17
*DEP17, 9+ = SMH, 7-8 is also material hardship but not severe
*MWI, 0-5 is SMH, 6-9 is also material hardship but not severe
gen material_hrdship = (Dep17 >= 7 & Dep17 ~= 77)
gen sevre_material_hrdship = (Dep17 >= 9 & Dep17 ~= 77)

*indicators to create categories for and output: life satisfaction, family wellbeing, enough income, trust (5 indicators), material hardship, loneliness

** Life satisfaction
gen LS_3cats = "NA"
replace LS_3cats = "Low" if PWB_qFeelAboutLifeScale <= 6
replace LS_3cats = "7 or 8" if inlist(PWB_qFeelAboutLifeScale, 7,8) 
replace LS_3cats = "9 or 10" if inlist(PWB_qFeelAboutLifeScale, 9,10) 

** Family wellbeing
gen FamWB_3cats = "NA"
replace FamWB_3cats = "Low" if PWB_qFamWellbeing <= 6
replace FamWB_3cats = "7 or 8" if inlist(PWB_qFamWellbeing, 7,8) 
replace FamWB_3cats = "9 or 10" if inlist(PWB_qFamWellbeing, 9,10) 

** Labour force
gen LFS_cats = "NA"
replace LFS_cats = "Employed" if DVLFS == 1
replace LFS_cats = "Unemployed" if DVLFS == 2
replace LFS_cats = "Not in the labour force" if DVLFS == 3

** General health
gen GenHealth_cats = "NA"
replace GenHealth_cats = "Excellent or very good" if PWB_qHealthExcellentPoor == 11 | PWB_qHealthExcellentPoor == 12
replace GenHealth_cats = "Good" if PWB_qHealthExcellentPoor == 13
replace GenHealth_cats = "Fair" if PWB_qHealthExcellentPoor == 14
replace GenHealth_cats = "Poor" if PWB_qHealthExcellentPoor == 15

** Safety in neighbourhood walking at night
gen Safety_cats = "NA"
replace Safety_cats = "Safe or very safe" if PWB_qSafeNightHood == 11 | PWB_qSafeNightHood == 12
replace Safety_cats = "Neither safe nor unsafe" if PWB_qSafeNightHood == 13
replace Safety_cats = "Unsafe" if PWB_qSafeNightHood == 14
replace Safety_cats = "Very unsafe" if PWB_qSafeNightHood == 15

** Discriminated against indicator
gen discrim_cats = "NA"
replace discrim_cats = "Discriminated against" if PWB_qDiscriminated == 1
replace discrim_cats = "Not discriminated against" if PWB_qDiscriminated == 2

** Enough income
gen EnghInc_cats = "NA"
replace EnghInc_cats = "Not enough or only just enough" if MHS_qEnoughIncome == 11 | MHS_qEnoughIncome == 12
// replace EnghInc_cats = "Only just enough" if MHS_qEnoughIncome == 12
replace EnghInc_cats = "Enough" if MHS_qEnoughIncome == 13
replace EnghInc_cats = "More than enough" if MHS_qEnoughIncome == 14

** Material hardship 
gen MH_cats = "NA"
replace MH_cats = "Not in material hardship" if (Dep17 <=6)
replace MH_cats = "Material hardship" if (Dep17 >= 7 & Dep17 <= 8)
replace MH_cats = "Severe material hardship" if (Dep17 >= 9 & Dep17 <= 77)

** Trust
gen TrustPpl = PWB_qTrustMostPeopleScale

foreach var in PWB_qTrustPol PWB_qTrustParl PWB_qTrustHlth PWB_qTrustMed TrustPpl {
	gen `var'_cats = "NA"
	replace `var'_cats = "0 to 4" if `var' <= 4
	replace `var'_cats = "5 to 7" if `var' >= 5 & `var' <= 7
// 	replace `var'_cats = "7 or 8" if `var' >= 7 & `var' <= 8
	replace `var'_cats = "8 to 10" if `var' >= 8 & `var' <= 10
}

** loneliness
gen Lonely_cats = "NA"
replace Lonely_cats = "None of the time" if PWB_qTimeLonely == 11
replace Lonely_cats = "A little of the time" if PWB_qTimeLonely == 12
replace Lonely_cats = "Some of the time" if PWB_qTimeLonely == 13
replace Lonely_cats = "Most of the time" if PWB_qTimeLonely == 14
replace Lonely_cats = "All of the time" if PWB_qTimeLonely == 15

gen QRTR = ""
replace QRTR = "Q1" if aug20 == 1
replace QRTR = "Q2" if nov20 == 1
replace QRTR = "Q3" if feb21 == 1
replace QRTR = "Q4" if may21 == 1

gen respondent = (nov20 == 1 | aug20 == 1 | may21 == 1 | feb21 == 1)


bysort snz_hlfs_uid: egen max_age = max(age)

gen age_18_to_64 = (max_age >= 18 & max_age <= 64)

gen LS = PWB_qFeelAboutLifeScale

gen Auckland = (DVRegCouncil == 2)


gen Not_Maori_or_Pacific_eth = (snz_ethnicity_grp2_nbr == 0 & snz_ethnicity_grp3_nbr == 0)
gen Maori_eth = snz_ethnicity_grp2_nbr
gen Pacific_eth = snz_ethnicity_grp3_nbr
gen Maori_or_Pacific_eth = (Maori_eth == 1 | Pacific_eth == 1)
gen All_ethnicities = 1


******* Creation/renaming of cohorts of interest
destring dvsex, replace
gen adult_female = (age >= 18 & dvsex == 2)
gen adult_male = (age >= 18 & dvsex == 1)
rename partnered_mother_depchild Prtnr_Mther_DC
rename partnered_father_depchild Prtnr_Fther_DC
rename solo_mother_depchild Solo_Mther_DC
rename solo_father_depchild Solo_Fther_DC
gen mother_DC = (Solo_Mther_DC == 1 | Prtnr_Mther_DC == 1)
gen father_DC = (Solo_Fther_DC == 1 | Prtnr_Fther_DC == 1)
gen Not_Solo_Parent_DC = (Prtnr_Mther_DC == 1 | Prtnr_Fther_DC == 1)
gen Solo_Parent_DC = (Solo_Mther_DC == 1 | Solo_Fther_DC == 1)
gen Any_NZer = 1
gen Any_NZer_18_to_39 = (Any_NZer == 1 & inrange(max_age, 18,39))
gen Any_NZer_40_to_64 = (Any_NZer == 1 & inrange(max_age, 40,64))
gen Any_NZer_65Plus = (Any_NZer == 1 & inrange(max_age, 65,130))




save "I:\MAA2021-55\Data exploration\Intermediate_data\\Table_dataset.dta", replace



*******************************************************************************************************************************************
******************************************************* SANKEY DIAGRAM OUTPUTS *************************************************************
*******************************************************************************************************************************************
*******************************************************************************************************************************************


use "I:\MAA2021-55\Data exploration\Intermediate_data\\Table_dataset.dta", clear

***** requires reshaping the data to wide so will keep only the relevant variables.
keep LS LS_cats LS_3cats FamWB_cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats sqfinalwgt DVRegCouncil Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male snz_hlfs_uid snz_ethnicity_grp1_nbr snz_ethnicity_grp2_nbr snz_ethnicity_grp3_nbr snz_ethnicity_grp4_nbr snz_ethnicity_grp5_nbr snz_ethnicity_grp6_nbr QRTR age_18_to_64 respondent Auckland mother_DC father_DC  Not_Solo_Parent_DC Solo_Parent_DC Any_NZer 


***** reshapes teh data and attached the relevant quarter/wave to the end of the variable name, i.e., LSQ1, LSQ2, etc
reshape wide LS LS_cats LS_3cats FamWB_cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats sqfinalwgt DVRegCouncil Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male respondent Auckland mother_DC father_DC  Not_Solo_Parent_DC Solo_Parent_DC Any_NZer , i(snz_hlfs_uid snz_ethnicity_grp1_nbr snz_ethnicity_grp2_nbr snz_ethnicity_grp3_nbr snz_ethnicity_grp4_nbr snz_ethnicity_grp5_nbr snz_ethnicity_grp6_nbr age_18_to_64) j(QRTR) string


gen Not_Maori_or_Pacific_eth = (snz_ethnicity_grp2_nbr == 0 & snz_ethnicity_grp3_nbr == 0)
gen Maori_eth = snz_ethnicity_grp2_nbr
gen Pacific_eth = snz_ethnicity_grp3_nbr
gen Maori_or_Pacific_eth = (Maori_eth == 1 | Pacific_eth == 1)
gen All_ethnicities = 1


****** not essential, but made looking across quarters in the dataset a bit easier when spot checking that the code is doing what i wanted it to.
order All_ethnicities AucklandQ1 AucklandQ2 AucklandQ3 AucklandQ4 DVRegCouncilQ1 DVRegCouncilQ2 DVRegCouncilQ3 DVRegCouncilQ4 EnghInc_catsQ1 EnghInc_catsQ2 EnghInc_catsQ3 EnghInc_catsQ4 FamWB_3catsQ1 FamWB_3catsQ2 FamWB_3catsQ3 FamWB_3catsQ4 FamWB_catsQ1 FamWB_catsQ2 FamWB_catsQ3 FamWB_catsQ4 LSQ1 LSQ2 LSQ3 LSQ4 LS_3catsQ1 LS_3catsQ2 LS_3catsQ3 LS_3catsQ4 LS_catsQ1 LS_catsQ2 LS_catsQ3 LS_catsQ4 Lonely_catsQ1 Lonely_catsQ2 Lonely_catsQ3 Lonely_catsQ4 MH_catsQ1 MH_catsQ2 MH_catsQ3 MH_catsQ4 Maori_eth Not_Maori_or_Pacific_eth PWB_qTrustHlth_catsQ1 PWB_qTrustHlth_catsQ2 PWB_qTrustHlth_catsQ3 PWB_qTrustHlth_catsQ4 PWB_qTrustMed_catsQ1 PWB_qTrustMed_catsQ2 PWB_qTrustMed_catsQ3 PWB_qTrustMed_catsQ4 PWB_qTrustParl_catsQ1 PWB_qTrustParl_catsQ2 PWB_qTrustParl_catsQ3 PWB_qTrustParl_catsQ4 PWB_qTrustPol_catsQ1 PWB_qTrustPol_catsQ2 PWB_qTrustPol_catsQ3 PWB_qTrustPol_catsQ4 Pacific_eth Prtnr_Fther_DCQ1 Prtnr_Fther_DCQ2 Prtnr_Fther_DCQ3 Prtnr_Fther_DCQ4 Prtnr_Mther_DCQ1 Prtnr_Mther_DCQ2 Prtnr_Mther_DCQ3 Prtnr_Mther_DCQ4 Solo_Fther_DCQ1 Solo_Fther_DCQ2 Solo_Fther_DCQ3 Solo_Fther_DCQ4 Solo_Mther_DCQ1 Solo_Mther_DCQ2 Solo_Mther_DCQ3 Solo_Mther_DCQ4 TrustPpl_catsQ1 TrustPpl_catsQ2 TrustPpl_catsQ3 TrustPpl_catsQ4 adult_femaleQ1 adult_femaleQ2 adult_femaleQ3 adult_femaleQ4 adult_maleQ1 adult_maleQ2 adult_maleQ3 adult_maleQ4 age_18_to_64 father_DCQ1 father_DCQ2 father_DCQ3 father_DCQ4 mother_DCQ1 mother_DCQ2 mother_DCQ3 mother_DCQ4 respondentQ1 respondentQ2 respondentQ3 respondentQ4 snz_ethnicity_grp1_nbr snz_ethnicity_grp2_nbr snz_ethnicity_grp3_nbr snz_ethnicity_grp4_nbr snz_ethnicity_grp5_nbr snz_ethnicity_grp6_nbr Maori_or_Pacific_eth snz_hlfs_uid sqfinalwgtQ1 sqfinalwgtQ2 sqfinalwgtQ3 sqfinalwgtQ4


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


// Prtnr_Fther_DC Prtnr_Mther_DC 
// Solo_Fther_DC Solo_Mther_DC 
// adult_female adult_male 
// Mother_DC Father_DC 
// Not_Solo_Parent_DC Solo_Parent_DC Any_NZer


***** produce sankey diagram datasets for people living in Auckland only, broken down by variables that are looped through below.... e.g., group, quarters, and wellbeing indicators
foreach group in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer {
		foreach quarter of numlist 1/3 {
				foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
					preserve 
						local next_q = `quarter' + 1
						collapse (count) Count=snz_hlfs_uid  [pw=((sqfinalwgtQ`quarter'+sqfinalwgtQ`next_q')/2)] if age_18_to_64==1 &  `group'Q`quarter' == 1 & respondentQ`quarter' == 1 & respondentQ`next_q' == 1 & AucklandQ`quarter' == 1, by(`indicator'Q`quarter' `indicator'Q`next_q') fast
						gen Qrt_start = `quarter'
						gen Qrt_end = `next_q'
						gen Group = "`group'"
						gen Region = "Auckland"
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
						qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q`quarter'_to_Q`next_q'_Auckland.dta", replace
					
					restore
				}	
		}
		****** does the same quarter to quarter breakdown but for quarter 1 to 4 (long-term transition)
		foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats Safety_cats discrim_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
					preserve 
						collapse (count) Count=snz_hlfs_uid  [pw=((sqfinalwgtQ1+sqfinalwgtQ4)/2)] if age_18_to_64==1 &  `group'Q1 == 1 & respondentQ1 == 1 & respondentQ4 == 1 & AucklandQ1 == 1, by(`indicator'Q1 `indicator'Q4) fast
						gen Qrt_start = 1
						gen Qrt_end = 4
						gen Group = "`group'"
						gen Region = "Auckland"
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
						qui save "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\`indicator'_`group'_Q1_to_Q4_Auckland.dta", replace
					restore
		}
		preserve
		use "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\LS_3cats_`group'_Q1_to_Q2_Auckland.dta", clear
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




*******************************************************************************************************************************************
************************************************** DESCRIPTIVE TABLE  OUTPUTS *************************************************************
*******************************************************************************************************************************************
*******************************************************************************************************************************************

// Auckland NotAuckland 

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

svyset snz_hlfs_uid [pweight=sqfinalwgt], vce(jackknife) jkrweight(sqfinalwgt_*)


foreach var in LS_3cats FamWB_3cats LFS_cats GenHealth_cats Safety_cats discrim_cats EnghInc_cats MH_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
	encode `var', gen(`var'_enc)
}



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


gen Fam_WB = PWB_qFamWellbeing if PWB_qFamWellbeing <= 10
gen SWB_LS = PWB_qFeelAboutLifeScale if PWB_qFeelAboutLifeScale <= 10
gen SWB_LWW = PWB_qThingsWorthwhileScale if PWB_qThingsWorthwhileScale<= 10
gen WHO5 = DVWHO5 if DVWHO5<= 100
// Fam_WB SWB_LS SWB_LWW
foreach var in WHO5 {
	foreach Qrter of numlist 1/4 {
		local i = 1
		matrix mean_`var'_grps_Q`Qrter' = J(9,14,.)
		
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
			 if "`var'" == "WHO5" & inlist(`Qrter', 2,3,4) {
		    
			}
			else {
				if "`grp'" == "Any_NZer_65Plus" {
					qui svy: mean `var' if `grp' == 1 & QRTR == "Q`Qrter'"  `set_restrictions'
				}
				else {
					qui svy: mean `var' if `grp' == 1 & QRTR == "Q`Qrter'" & age_18_to_64 == 1  `set_restrictions'
				}
				
				mat mean_`var'_grps_Q`Qrter'[8,`i'] = e(N_pop)
				mat mean_`var'_grps_Q`Qrter'[9,`i'] = e(N)
				foreach row of numlist 1/6 {
					mat mean_`var'_grps_Q`Qrter'[`row',`i'] = r(table)[`row',1]
				}
				if "`grp'" == "Any_NZer_65Plus" {
					qui svy: mean `var' if `grp' == 1 & QRTR == "Q`Qrter'"  `set_restrictions'
				}
				else {
					qui svy: mean `var' if `grp' == 1 & QRTR == "Q`Qrter'" & age_18_to_64 == 1  `set_restrictions'
				}
				qui estat sd
				mat mean_`var'_grps_Q`Qrter'[7,`i'] = r(sd)
				
				local i = `i' + 1
			}	
		}
		matrix rownames mean_`var'_grps_Q`Qrter' = mean std_error t_stat p_val CI_lower CI_upper std_dev est_pop obs
		matrix colnames mean_`var'_grps_Q`Qrter' = Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus
		di "Q`Qrter' completed"
		mat list mean_`var'_grps_Q`Qrter'
	}
}
// Fam_WB SWB_LS SWB_LWW
foreach var in  WHO5 {
	foreach Qrter of numlist 1/4 { 
	    if "`var'" == "WHO5" & inlist(`Qrter', 2,3,4) {
		    
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
			foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
				
				rename tempvar`i' `grp'
				local i = `i' +1
			}
			drop if statistic == ""
			save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_`var'_`Qrter'_`set'.dta", replace
			restore
		}
	}
}
preserve



use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_Fam_WB_1_`set'.dta", clear
foreach var in Fam_WB SWB_LS SWB_LWW WHO5 {
	foreach Qrter of numlist 1/4 {  
			if ("`var'" == "Fam_WB" & "`Qrter'" == "1") | ("`var'" == "WHO5" & inlist(`Qrter', 2,3,4))  {
				
			} 
			else {
				append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_`var'_`Qrter'_`set'.dta"
				
			}
		
			di "`var'"
	}
}

save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_all_variables_`set'.dta", replace	

restore
}
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

local enc_cats LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc PWB_qTrustPol_cats_enc PWB_qTrustParl_cats_enc PWB_qTrustHlth_cats_enc PWB_qTrustMed_cats_enc TrustPpl_cats_enc Lonely_cats_enc

pause on
foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc PWB_qTrustPol_cats_enc PWB_qTrustParl_cats_enc PWB_qTrustHlth_cats_enc PWB_qTrustMed_cats_enc TrustPpl_cats_enc Lonely_cats_enc {
	foreach Qrter of numlist 1/4 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
			
			if "`grp'" == "Any_NZer_65Plus" {
				 qui svy: proportion `var' if `grp' == 1 & QRTR == "Q`Qrter'"  `set_restrictions'
			}
			else {
				 qui svy: proportion `var' if `grp' == 1 & QRTR == "Q`Qrter'" & age_18_to_64 == 1  `set_restrictions'
			}
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
				save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\p_`varname'_Q`Qrter'_`grp'_`set'.dta", replace 
			restore
		}
		di "Q`Qrter' completed"
	}
}
preserve



use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\p_EnghInc_cats_Q1_Prtnr_Mther_DC_`set'.dta", clear
// foreach Qrter of numlist 1/4 {
// 	foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male mother_DC father_DC  {
// 		append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\p_EnghInc_cats_enc_Q`Qrter'_`grp'.dta"
// 	}
// }	
foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc PWB_qTrustPol_cats_enc PWB_qTrustParl_cats_enc PWB_qTrustHlth_cats_enc PWB_qTrustMed_cats_enc TrustPpl_cats_enc Lonely_cats_enc {
	local varname = substr("`var'",1,length("`var'") - 4)
	foreach Qrter of numlist 1/4 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
			if "`var'" == "EnghInc_cats_enc" & "`Qrter'" == "1" & "`grp'" == "Prtnr_Mther_DC"  {
				
			} 
			else {
				append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\p_`varname'_Q`Qrter'_`grp'_`set'.dta"
				
			}
			
		}
	}	
}
replace  category = substr(category,4,1)
destring category, replace
save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\proportions_data_`set'.dta", replace 

restore




***************************************************************************************************************************************
********************************************* POPULATION ESTIMATES AND OBSERVATION COUNTS *********************************************
***************************************************************************************************************************************

// 		local grp 	Prtnr_Fther_DC
// 		local var 	GenHealth_cats_enc
// 		local Qrter 	3
		//& `var' ~=. 

foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc PWB_qTrustPol_cats_enc PWB_qTrustParl_cats_enc PWB_qTrustHlth_cats_enc PWB_qTrustMed_cats_enc TrustPpl_cats_enc Lonely_cats_enc {
	foreach Qrter of numlist 1/4 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {

			preserve
			if "`grp'" == "Any_NZer_65Plus" {
				collapse (count) Est_pop=snz_hlfs_uid [pweight=sqfinalwgt] if `grp' == 1 & QRTR == "Q`Qrter'"  `set_restrictions', by(`var')
			}
			else {
				collapse (count) Est_pop=snz_hlfs_uid [pweight=sqfinalwgt] if `grp' == 1 & QRTR == "Q`Qrter'" & age_18_to_64 == 1  `set_restrictions', by(`var')
			}
			
// 			if "`grp'" == "Prtnr_Fther_DC" & "`var'" == "GenHealth_cats_enc" & "`Qrter'" == "3" { 
// 				pause
// 			}	
			
			local varname = substr("`var'",1,length("`var'") - 4)
			decode `var', gen(var_categories)
			gen group = "`grp'"
			gen wave = `Qrter'
			gen wellbeing_measure = "`varname'"
			rename `var' encoded_cats
			save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Cnt_`var'_Q`Qrter'_`grp'_`set'.dta", replace 
			restore
			
		}
		di "Q`Qrter' completed"
	}
}


foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc PWB_qTrustPol_cats_enc PWB_qTrustParl_cats_enc PWB_qTrustHlth_cats_enc PWB_qTrustMed_cats_enc TrustPpl_cats_enc Lonely_cats_enc {
	foreach Qrter of numlist 1/4 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
			preserve
			if "`grp'" == "Any_NZer_65Plus" {
				collapse (count) Observations=snz_hlfs_uid  if `grp' == 1 & QRTR == "Q`Qrter'"   `set_restrictions', by(`var')
			}
			else {
				collapse (count) Observations=snz_hlfs_uid  if `grp' == 1 & QRTR == "Q`Qrter'" & age_18_to_64 == 1  `set_restrictions', by(`var')
			}
			
			local varname = substr("`var'",1,length("`var'") - 4)
			decode `var', gen(var_categories)
			gen group = "`grp'"
			gen wave = `Qrter'
			gen wellbeing_measure = "`varname'"
			rename `var' encoded_cats
			save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_`var'_Q`Qrter'_`grp'_`set'.dta", replace 
			restore
			
		}
		di "Q`Qrter' completed"
	}
}

preserve
use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Cnt_EnghInc_cats_enc_Q1_Prtnr_Mther_DC_`set'.dta", clear
// append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_EnghInc_cats_enc_Q1_Prtnr_Mther_DC.dta"
foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc PWB_qTrustPol_cats_enc PWB_qTrustParl_cats_enc PWB_qTrustHlth_cats_enc PWB_qTrustMed_cats_enc TrustPpl_cats_enc Lonely_cats_enc {
	foreach Qrter of numlist 1/4 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus  {
			if "`var'" == "EnghInc_cats_enc" & "`Qrter'" == "1" & "`grp'" == "Prtnr_Mther_DC" & "`obs'" == "Cnt" {
				
			} 
			else {
				append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Cnt_`var'_Q`Qrter'_`grp'_`set'.dta"
				
			}
		
		}
	}
}	
foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc PWB_qTrustPol_cats_enc PWB_qTrustParl_cats_enc PWB_qTrustHlth_cats_enc PWB_qTrustMed_cats_enc TrustPpl_cats_enc Lonely_cats_enc {
	foreach Qrter of numlist 1/4 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {

				mmerge encoded_cats group wave wellbeing_measure using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_`var'_Q`Qrter'_`grp'_`set'.dta", unm(both) update
		
		}
	}
}	
save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_and_pop_est_`set'.dta", replace 


restore	
}



value_cat* group wave wellbeing_measure statistic




foreach set in All_NZ Auckland NotAuckland {
	local set All_NZ
	
	use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_all_variables_`set'.dta", clear

		foreach var in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
			rename `var' value_`var'
		}
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
		save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_reshaped_`set'.dta", replace
		
		local set All_NZ
	
		use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\proportions_data_`set'.dta", clear
		
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
		mmerge category group wellbeing_measure wave using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_and_pop_est_`set'.dta", unm(master) umatch(encoded_cats group  wellbeing_measure wave) update
		sort wellbeing_measure group wave category
		
		
		encoded_cats group wave wellbeing_measure using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_`var'_Q`Qrter'_`grp'_`set'.dta", unm(both) update
		
		decode `var', gen(var_categories)
			gen group = "`grp'"
			gen wave = `Qrter'
			gen wellbeing_measure = "`varname'"
			rename `var' encoded_cats
		, i(statistic group wellbeing_measure wave) j(category)	
		
		gen wave = `Qrter'
		gen wellbeing_measure = "`var'"
		local i = 1
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus
	"I:\MAA2021-55\Data exploration\Intermediate_data\desc\\proportions_data_`set'.dta"
	"I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_and_pop_est_`set'.dta"
	

}
	

// mmerge encoded_cats group wave wellbeing_measure using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_EnghInc_cats_enc_Q1_Prtnr_Mther_DC.dta", unm(both)
// mmerge encoded_cats group wave wellbeing_measure using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_EnghInc_cats_enc_Q1_adult_male.dta", unm(both)
// mmerge encoded_cats group wave wellbeing_measure using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Obs_`var'_Q`Qrter'_`grp'.dta", unm(both)

/*








use "I:\MAA2021-55\Data exploration\Intermediate_data\\Table_dataset.dta", clear
foreach var in EnghInc_cats_enc MH_cats_enc PWB_qTrustPol_cats_enc PWB_qTrustParl_cats_enc PWB_qTrustHlth_cats_enc PWB_qTrustMed_cats_enc TrustPpl_cats_enc Lonely_cats_enc Safety_cats_enc discrim_cats_enc {
	foreach Qrter of numlist 1/4 {
		foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male mother_DC father_DC  {
			collapse (count) Est_pop=snz_hlfs_uid [pweight=sqfinalwgt] if `grp' == 1 & QRTR == "Q`Qrter'" & age_18_to_64 == 1 & `var' ~=., by(`var')
			save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\Cnt_`var'_Q`Qrter'_`grp'.dta", replace 
			
		}
		di "Q`Qrter' completed"
	}
}





foreach var in Fam_WB SWB_LS SWB_LWW {
	foreach Qrter of numlist 1/4 { 
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
		foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male mother_DC father_DC  {
			
			rename tempvar`i' `grp'
			local i = `i' +1
		}
		save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\mean_`var'_`Qrter'.dta", replace
		
	}
}




mat list mean_est_grps_Q1


di "e(b se ci_l ci_u N_pop N)"
mat R = r(table)
[1...,1...]
mat list R
mat R2 = e()[1...,1...]
mat list R2
local rown: rown R
svmat R, n(col)
keep b se ci_l ci_u N_pop N
drop if b == .
mat list e(b se ci_l ci_u N_pop N)
mat summary_stats = e(b se ci_l ci_u N_pop N)
mat list summary_stats
di e(N)
local N_pop_check = e(N_pop_check)
di "`N_pop_check'"
foreach group in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male mother_DC father_DC {
	foreach mean_var in  {
		foreach wave of numlist 1/4 {
			svy: mean `mean_var' if `group' == 1 & QRTR == `wave'
			mat define summary_stats = e(b se ci_l ci_u N_pop N)
		}
	}
	
}


svy: mean DVWHO5
estimates store test, title(testing)
estout *, cells(b se ci_l ci_u)  stats(N_pop N) style(fixed)
ereturn list
di e(N_pop)
// 

mat define myresults = e(b sd )
matlist myresults

use "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_indicator_data.dta", clear


//
//
//
// br if Region == "Auckland" & variable_1 == "LS_3cats"  & Qrt_start == "1" &  Qrt_end == "2" & (Group == "Prtnr_Fther_DC" | Group == "adult_male")
//
// br if Region == "All" & variable_1 == "Lonely_cats"  & Qrt_start == "1" &  Qrt_end == "2" & (Group == "Prtnr_Fther_DC" | Group == "adult_male") & Ethnicity == "All_ethnicities"

// use "I:\MAA2021-55\Data exploration\Descriptive_data\Sankey_data\\Sanky_data_raw.dta", clear
// gen Count2 = Count
// replace Count2 = . if Count2 < 1000
// replace Count2 = round(Count2, 100)
//
// foreach group in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC {
// 		foreach quarter of numlist 1/3 {
// 				foreach indicator in LS_3cats FamWB_3cats EnghInc_cats MH_cats PWB_qTrustPol_cats PWB_qTrustParl_cats PWB_qTrustHlth_cats PWB_qTrustMed_cats TrustPpl_cats Lonely_cats {
// 					preserve 
// 						local next_q = `quarter' + 1
// 						collapse (count) Count=snz_hlfs_uid  [pw=((sqfinalwgtQ`quarter'+sqfinalwgtQ`next_q')/2)] if age_18_to_64==1 &  `group'Q`quarter' == 1 & respondentQ`quarter' == 1 & respondentQ`next_q' == 1 & AucklandQ`quarter' == 1, by(`indicator'Q`quarter' `indicator'Q`next_q') fast
// 						gen Qrt_start = `quarter'
// 						gen Qrt_end = `next_q'
// 						gen Group = "`group'"
// 						gen Region = "All"
// 						save "I:\MAA2021-55\Data\Analysis\Sanky\`indicator'_`group'_Q`quarter'_to_Q`next_q'_AllRegions.dta", replace
//					
// 					restore
// 				}	
// 		}
// }
//
// collapse (count) snz_hlfs_uid [pw=sqfinalwgt] if age>=18 & aug20 == 1, by(MHS_qEnoughIncome)





gen edate_interview_date = dofc(interview_date)
sort interview_date

gen interview_month = month(edate_interview_date)
gen interview_yr = year(edate_interview_date)

egen interview_mm_yyyy_date_tmp = concat(interview_month interview_yr), punct(/)
gen interview_MY_date = date(interview_mm_yyyy_date_tmp, "MY")
format interview_MY_date %td
gen YQ = qofd(interview_MY_date)
format YQ %tq





// 					sum_vhi_trst_ppl_`grp' = vhigh_trust_ppl ///
// sd_vhi_trst_ppl_`grp' = vhigh_trust_ppl ///
foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male {
	preserve
	keep if age >= 18 & age <= 64
	keep if `grp' == 1
	collapse 		(sum) 	sum_who5_Raw_`grp' = DVWHO5_Raw ///
					sum_who5_`grp' = DVWHO5 ///
					sum_LWW_`grp' = PWB_qThingsWorthwhileScale ///
					sum_LS_`grp' = PWB_qFeelAboutLifeScale ///
					Cnt_unemplyd_`grp' = unemployed ///
					Cnt_Not_in_LF_`grp' = Not_in_LabourForce ///
					Cnt_GPlus_health_`grp' = good_or_better_health ///
					Cnt_VGPlus_health_`grp' = vgood_or_better_health ///
					Cnt_hi_trst_ppl_`grp' =  high_or_vhigh_trust_ppl ///
					Cnt_hi_trst_pol_`grp' =  high_or_vhigh_trust_pol ///
					Cnt_hi_trst_par_`grp' =  high_or_vhigh_trust_par ///
					Cnt_hi_trst_med_`grp' =  high_or_vhigh_trust_med ///
					Cnt_hi_trst_hlth_`grp' =  high_or_vhigh_trust_hlth ///
					Cnt_JstEngh_Inc_`grp' = only_just_enough_income_plus ///
					Cnt_EnghInc_`grp'=enough_income_plus ///
					Cnt_high_LS_`grp'=high_LS ///
					Cnt_high_LWW_`grp'=high_Life_Worthwhile ///
					Cnt_lnelyMostAll_`grp'=lonely_most_or_all ///
					Cnt_discrim_`grp'=discriminated ///
					Cnt_unsfe_vunsfe_`grp' =Unsafe_VUnsafe_ind ///
					Cnt_MH_`grp'=material_hrdship ///
					Cnt_SMH_`grp'=sevre_material_hrdship ///
					(sd) 	sd_who5_Raw_`grp' = DVWHO5_Raw ///
					sd_who5_`grp' = DVWHO5 ///
					sd_LWW_`grp' = PWB_qThingsWorthwhileScale ///
					sd_LS_`grp' = PWB_qFeelAboutLifeScale ///
					(count) Count_`grp'=snz_hlfs_uid, by(YQ)
//	
//
// 		rename PWB_qFeelAboutLifeScale Ind_LS_`grp'
// 		rename good_or_better_health Ind_Gplus_hlth_`grp'
// 		rename vgood_or_better_health Ind_VGplus_hlth_`grp'
// 		rename high_or_vhigh_trust Ind_High_Trst_`grp'
// 		rename vhigh_trust Ind_VHigh_Trst_`grp'
// 		rename unemployed Ind_Unmpld_`grp'
// 		rename only_just_enough_income_plus Ind_JstEnghInc_`grp' 
// 		rename enough_income_plus Ind_EnghInc_`grp' 
// 		rename material_hrdship Ind_MH_`grp'
// 		rename sevre_material_hrdship Ind_SMH_`grp'
// 	rename snz_hlfs_uid Count_`grp'
	save "I:\MAA2021-55\Exploratory_analyis\HLFS_`grp'_QRTLY.dta", replace
	restore
}

use "I:\MAA2021-55\Exploratory_analyis\HLFS_Prtnr_Mther_DC_QRTLY.dta", clear
foreach grp in Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male {
	mmerge YQ using "I:\MAA2021-55\Exploratory_analyis\HLFS_`grp'_QRTLY.dta", unm(both) update
}
drop _merge

// order interview_MY_date  LS_adult_female LS_adult_male LS_partnered_father_depchild LS_partnered_mother_depchild LS_solo_father_depchild LS_solo_mother_depchild Count_adult_female Count_adult_male Count_partnered_father_depchild Count_partnered_mother_depchild Count_solo_father_depchild Count_solo_mother_depchild 
foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male {
	foreach var in 	sum_who5_Raw_ sum_who5_ sum_LWW_ sum_LS_  sd_who5_Raw_ sd_who5_ sd_LWW_ sd_LS_ {
		replace `var'`grp' = . if Count_`grp' <= 5
		replace `var'`grp' = . if `var'`grp' ==0
		
	}
	foreach var in Cnt_unemplyd_ Cnt_Not_in_LF_ Cnt_GPlus_health_ Cnt_VGPlus_health_ Cnt_hi_trst_ppl_ Cnt_hi_trst_pol_ Cnt_hi_trst_par_ Cnt_hi_trst_med_ Cnt_hi_trst_hlth_ Cnt_JstEngh_Inc_ Cnt_EnghInc_ Cnt_high_LS_ Cnt_high_LWW_ Cnt_lnelyMostAll_ Cnt_discrim_ Cnt_unsfe_vunsfe_ Cnt_MH_ Cnt_SMH_ {
		replace `var'`grp' = . if `var'`grp' <= 5
		grr  Count_`grp', seed(16000) base(3) replace
	}
	replace Count_`grp' = . if Count_`grp' <= 5
	grr  Count_`grp', seed(16000) base(3) replace
}

save "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_LS_monthly.dta", replace
gen YQ = qofd(interview_MY_date)
format YQ %tq
collapse (sum) sum_* Count_* , by(YQ)

save "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_collapse_qrtly.dta", replace


use "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_indicator_data.dta", clear
//
// gen YQ = qofd(interview_MY_date)
// format YQ %tq

foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male {
	preserve
	keep if age >= 18 & age <= 64
	keep if `grp' == 1
	collapse 		(sd) 	sd_who5_Raw_`grp' = DVWHO5_Raw ///
					sd_who5_`grp' = DVWHO5 ///
					sd_unemplyd_`grp' = unemployed ///
					sd_Not_in_LF_`grp' = Not_in_LabourForce ///
					sd_GPlus_health_`grp' = good_or_better_health ///
					sd_VGPlus_health_`grp' = vgood_or_better_health ///
					sd_hi_trst_ppl_`grp' =  high_or_vhigh_trust_ppl ///
					sd_vhi_trst_ppl_`grp' = vhigh_trust_ppl ///
					sd_hi_trst_pol_`grp' =  high_or_vhigh_trust_pol ///
					sd_vhi_trst_pol_`grp' = vhigh_trust_pol ///
					sd_hi_trst_par_`grp' =  high_or_vhigh_trust_par ///
					sd_vhi_trst_par_`grp' = vhigh_trust_par ///
					sd_hi_trst_med_`grp' =  high_or_vhigh_trust_med ///
					sd_vhi_trst_med_`grp' = vhigh_trust_med ///
					sd_hi_trst_hlth_`grp' =  high_or_vhigh_trust_hlth ///
					sd_vhi_trst_hlth_`grp' = vhigh_trust_hlth ///
					sd_JstEngh_Inc_`grp' = only_just_enough_income_plus ///
					sd_EnghInc_`grp'=enough_income_plus ///
					sd_high_LS_`grp'=high_LS ///
					sd_high_LWW_`grp'=high_Life_Worthwhile ///
					sd_lnelyMostAll_`grp'=lonely_most_or_all ///
					sd_discrim_`grp'=discriminated ///
					sd_unsfe_vunsfe_`grp' =Unsafe_VUnsafe_ind ///
					sd_MH_`grp'=material_hrdship ///
					sd_SMH_`grp'=sevre_material_hrdship ///
					(count) Count_`grp'=snz_hlfs_uid, by(YQ)
//	
//
// 		rename PWB_qFeelAboutLifeScale Ind_LS_`grp'
// 		rename good_or_better_health Ind_Gplus_hlth_`grp'
// 		rename vgood_or_better_health Ind_VGplus_hlth_`grp'
// 		rename high_or_vhigh_trust Ind_High_Trst_`grp'
// 		rename vhigh_trust Ind_VHigh_Trst_`grp'
// 		rename unemployed Ind_Unmpld_`grp'
// 		rename only_just_enough_income_plus Ind_JstEnghInc_`grp' 
// 		rename enough_income_plus Ind_EnghInc_`grp' 
// 		rename material_hrdship Ind_MH_`grp'
// 		rename sevre_material_hrdship Ind_SMH_`grp'
// 	rename snz_hlfs_uid Count_`grp'
	save "I:\MAA2021-55\Exploratory_analyis\HLFS_`grp'_YQ.dta", replace
	restore
}

use "I:\MAA2021-55\Exploratory_analyis\HLFS_Prtnr_Mther_DC_YQ.dta", clear
foreach grp in Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male {
	mmerge YQ using "I:\MAA2021-55\Exploratory_analyis\HLFS_`grp'_YQ.dta", unm(both) update
}
drop _merge

save "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_YQ_sd.dta", replace

use "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_LS_monthly.dta", clear
append using "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_collapse_qrtly.dta"
mmerge YQ using "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_YQ_sd.dta", unm(both) update


reshape long Ind_LS_ Ind_Gplus_hlth_ Ind_VGplus_hlth_ Ind_High_Trst_ Ind_VHigh_Trst_ Ind_Unmpld_ Ind_JstEnghInc_ Ind_EnghInc_ Ind_MH_ Ind_SMH_ Count_ , i(YQ interview_MY_date) j(Group) string

foreach var in Ind_LS_ Ind_Gplus_hlth_ Ind_VGplus_hlth_ Ind_High_Trst_ Ind_VHigh_Trst_ Ind_Unmpld_ Ind_JstEnghInc_ Ind_EnghInc_ Ind_MH_ Ind_SMH_ Count_ {
	
	local newname = substr("`var'",1,length("`var'")-1 )
	rename `var' `newname'
}

reshape long Ind_, i(YQ interview_MY_date Group Count) j(indicator) string
rename Ind_ value

gen average = value / Count

save "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_LS_monthly_and_qrtly.dta", replace
export delimited using "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_LS_monthly_and_qrtly.csv", replace 

************************************************************************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************************************************************************


**Load GSS exploratory analysis table
odbc load, bigint clear exec("select * from  [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_2016_2018_tables]") $IDISP_CONN

**first interview date: Friday 23 March 2020
// global date_of_interest3 "19/03/2018"
// gen date_of_interest3 =  "$date_of_interest"
// gen date_of_interest4 = date(date_of_interest3, "DMY")
**Start weekly survey indicator from Monday 3 May 2020

destring gss_pq_health_excel_poor_code gss_pq_trust_most_code labour_force_status gss_pq_enough_inc_code gss_pq_material_wellbeing_code, replace
*PWB_qHealthExcellentPoor PWB_qTrustMostPeopleScale Dep17 DVLFS MHS_qEnoughIncome
* DVUnderUtilise not available in GSS...
gen good_or_better_health = (gss_pq_health_excel_poor_code <= 13)
replace good_or_better_health = . if gss_pq_health_excel_poor_code >= 88
gen vgood_or_better_health = (gss_pq_health_excel_poor_code <= 12)
replace vgood_or_better_health = . if gss_pq_health_excel_poor_code >= 88

gen high_or_vhigh_trust = (inlist(gss_pq_trust_most_code, 7,8,9,10))
gen vhigh_trust = (inlist(gss_pq_trust_most_code, 9,10))

gen unemployed = (labour_force_status == 2)
replace unemployed = . if labour_force_status == 77 // None were status unidentified

gen only_just_enough_income_plus = (inlist(gss_pq_enough_inc_code, 12,13,14))
gen enough_income_plus = (inlist(gss_pq_enough_inc_code, 13,14))

** MSD definition of material harship and severe material hardship based on MWI and DEP17
*DEP17, 9+ = SMH, 7-8 is also material hardship but not severe
*MWI, 0-5 is SMH, 6-9 is also material hardship but not severe
gen material_hrdship = (gss_pq_material_wellbeing_code <= 9)
gen sevre_material_hrdship = (gss_pq_material_wellbeing_code <= 5)

gen pers_interview_dte = date(gss_pq_PQinterview_date, "YMD")
format pers_interview_dte %td
gen edate_interview_date = date(gss_pq_PQinterview_date, "YMD")
sort pers_interview_dte

gen survey_week = .
gen survey_week_date = .
gen interview_month = month(pers_interview_dte)
gen interview_yr = year(pers_interview_dte)
egen interview_mm_yyyy_date_tmp = concat(interview_month interview_yr), punct(/)
gen interview_MY_date = date(interview_mm_yyyy_date_tmp, "MY")
format interview_MY_date %td
gen YQ = qofd(interview_MY_date)
format YQ %tq

destring snz_sex_gender_code, replace
gen adult_female = (age >= 18 & snz_sex_gender_code == 2)
gen adult_male = (age >= 18 & snz_sex_gender_code == 1)

destring gss_pq_feel_life_code, replace

replace gss_pq_feel_life_code = . if gss_pq_feel_life_code >= 80

rename partnered_mother_depchild Prtnr_Mther_DC
rename partnered_father_depchild Prtnr_Fther_DC
rename solo_mother_depchild Solo_Mther_DC
rename solo_father_depchild Solo_Fther_DC

foreach coll in GSS2016 GSS2018 {
	foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male {
		preserve
		keep if age >=18 & age <= 64
		keep if `grp' == 1 & gss_pq_collection_code == "`coll'"
		collapse (sum) gss_pq_feel_life_code good_or_better_health vgood_or_better_health high_or_vhigh_trust vhigh_trust unemployed only_just_enough_income_plus enough_income_plus material_hrdship sevre_material_hrdship (count) snz_uid, by(interview_MY_date)
		
		rename gss_pq_feel_life_code Ind_LS_`grp'
		rename good_or_better_health Ind_Gplus_hlth_`grp'
		rename vgood_or_better_health Ind_VGplus_hlth_`grp'
		rename high_or_vhigh_trust Ind_High_Trst_`grp'
		rename vhigh_trust Ind_VHigh_Trst_`grp'
		rename unemployed Ind_Unmpld_`grp'
		rename only_just_enough_income_plus Ind_JstEnghInc_`grp' 
		rename enough_income_plus Ind_EnghInc_`grp' 
		rename material_hrdship Ind_MH_`grp'
		rename sevre_material_hrdship Ind_SMH_`grp'
		rename snz_uid Count_`grp'
		save "I:\MAA2021-55\Exploratory_analyis\GSS_`coll'_`grp'_LS_monthly.dta", replace
		restore
	}
}

foreach coll in GSS2016 GSS2018 {
	use "I:\MAA2021-55\Exploratory_analyis\GSS_`coll'_Prtnr_Mther_DC_LS_monthly.dta", clear
	foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male {
		mmerge interview_MY_date using "I:\MAA2021-55\Exploratory_analyis\GSS_`coll'_`grp'_LS_monthly.dta", unm(both) update
	}
	
	
// 	order interview_MY_date  LS_adult_female LS_adult_male LS_partnered_father_depchild LS_partnered_mother_depchild LS_solo_father_depchild LS_solo_mother_depchild Count_adult_female Count_adult_male Count_partnered_father_depchild Count_partnered_mother_depchild Count_solo_father_depchild Count_solo_mother_depchild 
	save "I:\MAA2021-55\Exploratory_analyis\GSS_`coll'_6grps_LS_monthly.dta", replace
// 	export delimited using "I:\MAA2021-55\Exploratory_analyis\GSS_`coll'_6grps_LS_monthly.csv", replace 
}
use "I:\MAA2021-55\Exploratory_analyis\GSS_GSS2016_6grps_LS_monthly.dta", clear
append using "I:\MAA2021-55\Exploratory_analyis\GSS_GSS2018_6grps_LS_monthly.dta"

foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male {
	foreach var in Ind_LS_ Ind_Gplus_hlth_ Ind_VGplus_hlth_ Ind_High_Trst_ Ind_VHigh_Trst_ Ind_Unmpld_ Ind_MH_ Ind_SMH_ Ind_JstEnghInc_ Ind_EnghInc_ {
		replace `var'`grp' = . if Count_`grp' <= 5
		
	}
	replace Count_`grp' = . if Count_`grp' <= 5
	grr  Count_`grp', seed(16000) base(3) replace
}
drop _merge
save "I:\MAA2021-55\Exploratory_analyis\GSS_6grps_LS_monthly.dta", replace

gen YQ = qofd(interview_MY_date)
format YQ %tq
collapse (sum) Ind_LS_Prtnr_Mther_DC Ind_Gplus_hlth_Prtnr_Mther_DC Ind_VGplus_hlth_Prtnr_Mther_DC Ind_High_Trst_Prtnr_Mther_DC Ind_VHigh_Trst_Prtnr_Mther_DC Ind_Unmpld_Prtnr_Mther_DC Ind_JstEnghInc_Prtnr_Mther_DC Ind_EnghInc_Prtnr_Mther_DC Ind_MH_Prtnr_Mther_DC Ind_SMH_Prtnr_Mther_DC Count_Prtnr_Mther_DC Ind_LS_Prtnr_Fther_DC Ind_Gplus_hlth_Prtnr_Fther_DC Ind_VGplus_hlth_Prtnr_Fther_DC Ind_High_Trst_Prtnr_Fther_DC Ind_VHigh_Trst_Prtnr_Fther_DC Ind_Unmpld_Prtnr_Fther_DC Ind_JstEnghInc_Prtnr_Fther_DC Ind_EnghInc_Prtnr_Fther_DC Ind_MH_Prtnr_Fther_DC Ind_SMH_Prtnr_Fther_DC Count_Prtnr_Fther_DC Ind_LS_Solo_Mther_DC Ind_Gplus_hlth_Solo_Mther_DC Ind_VGplus_hlth_Solo_Mther_DC Ind_High_Trst_Solo_Mther_DC Ind_VHigh_Trst_Solo_Mther_DC Ind_Unmpld_Solo_Mther_DC Ind_JstEnghInc_Solo_Mther_DC Ind_EnghInc_Solo_Mther_DC Ind_MH_Solo_Mther_DC Ind_SMH_Solo_Mther_DC Count_Solo_Mther_DC Ind_LS_Solo_Fther_DC Ind_Gplus_hlth_Solo_Fther_DC Ind_VGplus_hlth_Solo_Fther_DC Ind_High_Trst_Solo_Fther_DC Ind_VHigh_Trst_Solo_Fther_DC Ind_Unmpld_Solo_Fther_DC Ind_JstEnghInc_Solo_Fther_DC Ind_EnghInc_Solo_Fther_DC Ind_MH_Solo_Fther_DC Ind_SMH_Solo_Fther_DC Count_Solo_Fther_DC Ind_LS_adult_female Ind_Gplus_hlth_adult_female Ind_VGplus_hlth_adult_female Ind_High_Trst_adult_female Ind_VHigh_Trst_adult_female Ind_Unmpld_adult_female Ind_JstEnghInc_adult_female Ind_EnghInc_adult_female Ind_MH_adult_female Ind_SMH_adult_female Count_adult_female Ind_LS_adult_male Ind_Gplus_hlth_adult_male Ind_VGplus_hlth_adult_male Ind_High_Trst_adult_male Ind_VHigh_Trst_adult_male Ind_Unmpld_adult_male Ind_JstEnghInc_adult_male Ind_EnghInc_adult_male Ind_MH_adult_male Ind_SMH_adult_male Count_adult_male , by(YQ)

save "I:\MAA2021-55\Exploratory_analyis\GSS_6grps_LS_qrtly.dta", replace
append using "I:\MAA2021-55\Exploratory_analyis\GSS_6grps_LS_monthly.dta"

reshape long Ind_LS_ Ind_Gplus_hlth_ Ind_VGplus_hlth_ Ind_High_Trst_ Ind_VHigh_Trst_ Ind_Unmpld_ Ind_JstEnghInc_ Ind_EnghInc_ Ind_MH_ Ind_SMH_ Count_ , i(YQ interview_MY_date) j(Group) string

foreach var in Ind_LS_ Ind_Gplus_hlth_ Ind_VGplus_hlth_ Ind_High_Trst_ Ind_VHigh_Trst_ Ind_Unmpld_ Ind_JstEnghInc_ Ind_EnghInc_ Ind_MH_ Ind_SMH_ Count_ {
	
	local newname = substr("`var'",1,length("`var'")-1 )
	rename `var' `newname'
}

reshape long Ind_, i(YQ interview_MY_date Group Count) j(indicator) string
rename Ind_ value

gen average = value / Count

save "I:\MAA2021-55\Exploratory_analyis\GSS_6grps_LS_monthly_and_qrtly.dta", replace
export delimited using "I:\MAA2021-55\Exploratory_analyis\GSS_6grps_LS_monthly_and_qrtly.csv", replace 


append using  "I:\MAA2021-55\Exploratory_analyis\HLFS_6grps_LS_monthly_and_qrtly.dta"
export delimited using "I:\MAA2021-55\Exploratory_analyis\GSS_and_HLFS_6grps__monthly_and_qrtly.csv", replace 

foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male {
	gen avg_`grp' = LS_`grp' / Count_`grp'
}
gen perc_diff_AFemale_PM = (avg_adult_female-avg_partnered_mother_depchild)/avg_adult_female
gen perc_diff_AFemale_SM = (avg_adult_female-avg_solo_mother_depchild)/avg_adult_female
gen perc_diff_AMale_PF = (avg_adult_male-avg_partnered_father_depchild)/avg_adult_male
gen perc_diff_AMale_SF = (avg_adult_male-avg_solo_father_depchild)/avg_adult_male
export delimited using "I:\MAA2021-55\Exploratory_analyis\GSS_2016_2018_6grps_LS_monthly_v2.csv", replace 



*** QUARTERLY BREAKDOWNS

foreach coll in GSS2016 GSS2018 {
	foreach grp in partnered_mother_depchild partnered_father_depchild solo_mother_depchild solo_father_depchild adult_female adult_male {
		preserve
		keep if age >=18 & age <= 64
		keep if `grp' == 1 & gss_pq_collection_code == "`coll'"
		collapse (sum) gss_pq_feel_life_code (count) snz_uid, by(YQ)
		rename gss_pq_feel_life_code LS_`grp'
		rename snz_uid Count_`grp'
		save "I:\MAA2021-55\Exploratory_analyis\GSS_`coll'_`grp'_LS_YQ.dta", replace
		restore
	}
}
preserve
foreach coll in GSS2016 GSS2018 {
	use "I:\MAA2021-55\Exploratory_analyis\GSS_`coll'_partnered_mother_depchild_LS_YQ.dta", clear
	foreach grp in partnered_father_depchild solo_mother_depchild solo_father_depchild adult_female adult_male {
		mmerge YQ using "I:\MAA2021-55\Exploratory_analyis\GSS_`coll'_`grp'_LS_YQ.dta", unm(both) update
	}
	
	order YQ  LS_adult_female LS_adult_male LS_partnered_father_depchild LS_partnered_mother_depchild LS_solo_father_depchild LS_solo_mother_depchild Count_adult_female Count_adult_male Count_partnered_father_depchild Count_partnered_mother_depchild Count_solo_father_depchild Count_solo_mother_depchild 
	save "I:\MAA2021-55\Exploratory_analyis\GSS_`coll'_6grps_LS_YQ.dta", replace
	export delimited using "I:\MAA2021-55\Exploratory_analyis\GSS_`coll'_6grps_LS_YQ.csv", replace 
}
use "I:\MAA2021-55\Exploratory_analyis\GSS_GSS2016_6grps_LS_YQ.dta", clear
append using "I:\MAA2021-55\Exploratory_analyis\GSS_GSS2018_6grps_LS_YQ.dta"
foreach grp in partnered_father_depchild solo_mother_depchild solo_father_depchild adult_female adult_male {
	gen avg_`grp' = LS_`grp' / Count_`grp'
}
gen perc_diff_AFemale_PM = (avg_adult_female-avg_partnered_mother_depchild)/avg_adult_female
gen perc_diff_AFemale_SM = (avg_adult_female-avg_solo_mother_depchild)/avg_adult_female
gen perc_diff_AMale_PF = (avg_adult_male-avg_partnered_father_depchild)/avg_adult_male
gen perc_diff_AMale_SF = (avg_adult_male-avg_solo_father_depchild)/avg_adult_male
export delimited using "I:\MAA2021-55\Exploratory_analyis\GSS_2016_2018_6grps_LS_YQ_v2.csv", replace 
restore


//
// foreach week of numlist 1/52 {
// 	gen Mon_this_wk_`week' = date_of_interest4 + (7*(`week'-1))
// 	gen Mon_next_wk_`week' = date_of_interest4 + (7*`week')
// 	replace survey_week = `week' if edate_interview_date >= Mon_this_wk_`week' & edate_interview_date < Mon_next_wk_`week'
// 	replace survey_week_date = Mon_this_wk_`week' if edate_interview_date >= Mon_this_wk_`week' & edate_interview_date < Mon_next_wk_`week'
//	
// 	drop Mon_this_wk_`week' Mon_next_wk_`week'
//	
// }
// format survey_week_date %d
//
// gen wellbeing_wave = .
// replace wellbeing_wave = 1 if aug20 == 1
// replace wellbeing_wave = 2 if nov20 == 1
// replace wellbeing_wave = 3 if feb21 == 1
// replace wellbeing_wave = 4 if may21 == 1

foreach var in partnered_father_depchild partnered_mother_depchild solo_father_depchild solo_mother_depchild other_father other_mother {
	
	replace `var' = 0 if `var' == .
}
rename gss_pq_feel_life_code PWB_qFeelAboutLifeScale
destring PWB_qFeelAboutLifeScale, replace
replace PWB_qFeelAboutLifeScale = . if PWB_qFeelAboutLifeScale >= 80

// preserve
// collapse (mean) PWB_qFeelAboutLifeScale, by(DVRegCouncil survey_week_date partnered_father_depchild partnered_mother_depchild solo_father_depchild solo_mother_depchild) fast
//
// foreach var in partnered_father_depchild partnered_mother_depchild solo_father_depchild solo_mother_depchild {
// 	gen Au_LS_`var' = PWB_qFeelAboutLifeScale if `var' == 1 & DVRegCouncil == 2
// 	gen Ot_LS_`var' = PWB_qFeelAboutLifeScale if `var' == 1 & DVRegCouncil ~= 2
// }
//
// line LS_partnered_father_depchild LS_partnered_mother_depchild LS_solo_father_depchild LS_solo_mother_depchild survey_week_date 
//
// line Au_LS_partnered_mother_depchild Ot_LS_partnered_mother_depchild Au_LS_solo_mother_depchild Ot_LS_solo_mother_depchild survey_week_date 
// restore

collapse (mean) PWB_qFeelAboutLifeScale, by(solo_mother_depchild partnered_mother_depchild partnered_father_depchild  survey_week_date) fast

// foreach var in partnered_father_depchild partnered_mother_depchild solo_father_depchild solo_mother_depchild {
// 	gen Au_LS_`var' = PWB_qFeelAboutLifeScale if `var' == 1 & DVRegCouncil == 2
// 	gen Ot_LS_`var' = PWB_qFeelAboutLifeScale if `var' == 1 & DVRegCouncil ~= 2
// }
gsort survey_week_date
twoway (line PWB_qFeelAboutLifeScale survey_week_date if solo_mother_depchild == 1, lcolor(blue)) (line PWB_qFeelAboutLifeScale survey_week_date if partnered_mother_depchild == 1, lcolor(red)) (line PWB_qFeelAboutLifeScale survey_week_date if  partnered_father_depchild == 1, lcolor(green)) 
pause
restore


