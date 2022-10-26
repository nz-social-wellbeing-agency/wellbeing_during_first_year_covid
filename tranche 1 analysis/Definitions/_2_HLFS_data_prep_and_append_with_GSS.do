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
 
	global IDI_CONN conn("Driver={SQL Server}; Trusted_Connection=YES; Server=PRTPRDSQL36.stats.govt.nz,1433;Database=$IDI_DB")
 	global IDISP_CONN conn("Driver={SQL Server}; Trusted_Connection=YES; Server=PRTPRDSQL36.stats.govt.nz,1433;Database=$IDI_SP")
	global IDIAH_CONN conn("Driver={SQL Server}; Trusted_Connection=YES; Server=PRTPRDSQL36.stats.govt.nz,1433;Database=$IDI_Adhoc")

 ******************************************
 * Stata functionality with ODBC
 ******************************************
 
**Load and save disability indicator file
odbc load, bigint clear exec("select * from  [IDI_Sandpit].[DL-MAA2021-55].[WBR_HLFS_disability_indicator]") $IDISP_CONN

duplicates drop snz_uid date, force 
save "I:\MAA2021-55\Data exploration\Intermediate_data\\HLFS_disability_ind.dta", replace

**Load HLFS exploratory analysis table
odbc load, bigint clear exec("select * from  [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables_202203]") $IDISP_CONN
mmerge snz_uid using "I:\MAA2021-55\Data exploration\Intermediate_data\\HLFS_disability_ind.dta", unm(master)

** Validating that the use of the sample weights are producing what has been publicly reported by Stats, e.g., 6.4% of 18+ people reported having not enough income, and 23% reported only just having enough income.
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

gen TrustPol = PWB_qTrustPol
gen TrustMed = PWB_qTrustMed
gen TrustParl = PWB_qTrustParl
gen TrustHlth = PWB_qTrustHlth

foreach var in TrustPol TrustParl TrustHlth TrustMed TrustPpl {
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
replace QRTR = "Q3" if aug20 == 1
replace QRTR = "Q4" if nov20 == 1
replace QRTR = "Q5" if feb21 == 1
replace QRTR = "Q6" if may21 == 1

gen respondent = (nov20 == 1 | aug20 == 1 | may21 == 1 | feb21 == 1)


bysort snz_hlfs_uid: egen max_age = max(age)

gen age_18_to_64 = (max_age >= 18 & max_age <= 64)

gen LS = PWB_qFeelAboutLifeScale

gen Auckland = (DVRegCouncil == 2)


gen Not_Maori_or_Pacific_eth = (EthMaori == 0 & EthPacific == 0)
gen Maori_eth = EthMaori
gen Pacific_eth = EthPacific
gen Maori_or_Pacific_eth = (EthMaori == 1 | EthPacific == 1)
gen All_ethnicities = 1


******* Creation/renaming of cohorts of interest


** note that our cohort of interest is parents aged 18-64, therefore all of the populations below (except for the 65+, or specifically grouped ones) are also 18-64, e.g., Any_NZer comparison group is also restricted to 18-64 to make running the descriptive tables code easier....
destring dvsex, replace
gen adult_female = (inrange(max_age, 18,64) & dvsex == 2)
gen adult_male = (inrange(max_age, 18,64) & dvsex == 1)
rename partnered_mother_depchild Prtnr_Mther_DC
rename partnered_father_depchild Prtnr_Fther_DC
rename solo_mother_depchild Solo_Mther_DC
rename solo_father_depchild Solo_Fther_DC

replace Prtnr_Mther_DC = 0  if ~inrange(max_age, 18,64)
replace Prtnr_Fther_DC = 0   if ~inrange(max_age, 18,64)
replace Solo_Mther_DC = 0   if ~inrange(max_age, 18,64)
replace Solo_Fther_DC = 0   if ~inrange(max_age, 18,64)

gen mother_DC = (Solo_Mther_DC == 1 | Prtnr_Mther_DC == 1 & inrange(max_age, 18,64))
gen father_DC = (Solo_Fther_DC == 1 | Prtnr_Fther_DC == 1 & inrange(max_age, 18,64))
gen Not_Solo_Parent_DC = (Prtnr_Mther_DC == 1 | Prtnr_Fther_DC == 1 & inrange(max_age, 18,64))
gen Solo_Parent_DC = (Solo_Mther_DC == 1 | Solo_Fther_DC == 1 & inrange(max_age, 18,64))

gen Any_NZer = (inrange(max_age, 18,64))
gen Any_NZer_18_to_39 = (inrange(max_age, 18,39))
gen Any_NZer_40_to_64 = (inrange(max_age, 40,64))
gen Any_NZer_65Plus = (inrange(max_age, 65,130))


gen High_dis_18_to_39 = (dv_disability == 1 & inrange(max_age, 18,39))
gen High_dis_40_to_64 = (dv_disability == 1 & inrange(max_age, 40,64))
gen High_dis_65Plus = (dv_disability == 1 & inrange(max_age, 65,130))

gen VHigh_dis_18_to_39 = (dv_disability == 2 & inrange(max_age, 18,39))
gen VHigh_dis_40_to_64 = (dv_disability == 2 & inrange(max_age, 40,64))
gen VHigh_dis_65Plus = (dv_disability == 2 & inrange(max_age, 65,130))

gen Fam_WB = PWB_qFamWellbeing if PWB_qFamWellbeing <= 10
gen SWB_LS = PWB_qFeelAboutLifeScale if PWB_qFeelAboutLifeScale <= 10
gen SWB_LWW = PWB_qThingsWorthwhileScale if PWB_qThingsWorthwhileScale<= 10
gen WHO5 = DVWHO5 if DVWHO5<= 100

gen Not_Maori_or_Pac_18to64 = (EthMaori == 0 & EthPacific == 0 & inrange(max_age, 18,64))
gen Maori_18to64 = (EthMaori == 1 & inrange(max_age, 18,64))
gen Pacific_18to64 = (EthPacific == 1 & inrange(max_age, 18,64))

** combine GSS and HLFS datasets
append using "I:\MAA2021-55\Data exploration\Intermediate_data\\GSS_Table_dataset.dta"
replace QRTR = "Q1" if gss_pq_collection_code == "GSS2016"
replace QRTR = "Q2" if gss_pq_collection_code == "GSS2018"

foreach var in LS_3cats FamWB_3cats LFS_cats GenHealth_cats Safety_cats discrim_cats EnghInc_cats MH_cats TrustPpl_cats TrustPol_cats TrustMed_cats TrustParl_cats TrustHlth_cats Lonely_cats {
	encode `var', gen(`var'_enc)
}
replace Survey = "HLFS" if Survey == ""

gen Any_dis_18_to_39 = (High_dis_18_to_39 == 1 | VHigh_dis_18_to_39 == 1)
gen Any_dis_40_to_64 = (High_dis_40_to_64 == 1 | VHigh_dis_40_to_64 == 1)
gen Any_dis_65Plus = (High_dis_65Plus == 1 | VHigh_dis_65Plus == 1)
gen Any_dis_18to64 = (Any_dis_18_to_39 == 1 | Any_dis_40_to_64 == 1)

replace max_age = age if QRTR == "Q1" | QRTR == "Q2"
replace dvsex =  gss_pq_dvsex_code if dvsex == .

gen ethnicity_1 = (gss_pq_ethnic_grp1_snz_ind == 1 | EthEuropean == 1)
gen ethnicity_2 = (gss_pq_ethnic_grp2_snz_ind == 1 | EthMaori == 1)
gen ethnicity_3 = (gss_pq_ethnic_grp3_snz_ind == 1 | EthPacific == 1)
gen ethnicity_4 = (gss_pq_ethnic_grp4_snz_ind == 1 | EthAsian == 1)
gen ethnicity_5 = (gss_pq_ethnic_grp5_snz_ind == 1 | EthMELAA == 1)
gen ethnicity_6 = (gss_pq_ethnic_grp6_snz_ind == 1 | EthOther == 1)

gen Male_65Plus = (inrange(max_age, 65,130) & dvsex == 1)
gen Female_65Plus = (inrange(max_age, 65,130) & dvsex == 2)

keep 	sqfinalwgt* snz_uid QRTR Auckland max_age ethnicity_* respondent dvsex ///
		LS_3cats* FamWB_3cats* LFS_cats* GenHealth_cats* Safety_cats* discrim_cats* EnghInc_cats* MH_cats* TrustPpl_cats* TrustPol_cats* TrustMed_cats* TrustParl_cats* TrustHlth_cats* Lonely_cats* /// 
		Fam_WB SWB_LS SWB_LWW WHO5 ///
		Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus High_dis_18_to_39 High_dis_40_to_64 High_dis_65Plus VHigh_dis_18_to_39 VHigh_dis_40_to_64 VHigh_dis_65Plus ///
		Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC ///
		Any_dis_18_to_39 Any_dis_40_to_64 Any_dis_65Plus Any_dis_18to64 Not_Maori_or_Pac_18to64 Maori_18to64 Pacific_18to64 ///
		Male_65Plus Female_65Plus
order 	sqfinalwgt* snz_uid QRTR Auckland max_age ethnicity_* respondent dvsex ///
		LS_3cats* FamWB_3cats* LFS_cats* GenHealth_cats* Safety_cats* discrim_cats* EnghInc_cats* MH_cats* TrustPpl_cats* TrustPol_cats* TrustMed_cats* TrustParl_cats* TrustHlth_cats* Lonely_cats* /// 
		Fam_WB SWB_LS SWB_LWW WHO5 ///
		Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus High_dis_18_to_39 High_dis_40_to_64 High_dis_65Plus VHigh_dis_18_to_39 VHigh_dis_40_to_64 VHigh_dis_65Plus ///
		Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC ///
		Any_dis_18_to_39 Any_dis_40_to_64 Any_dis_65Plus Any_dis_18to64 Not_Maori_or_Pac_18to64 Maori_18to64 Pacific_18to64 ///
		Male_65Plus Female_65Plus		




save "I:\MAA2021-55\Data exploration\Intermediate_data\\Table_dataset.dta", replace



