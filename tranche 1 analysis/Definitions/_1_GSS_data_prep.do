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
odbc load, bigint clear exec("select * from  [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_disability_indicator]") $IDISP_CONN

duplicates drop snz_uid date, force 
save "I:\MAA2021-55\Data exploration\Intermediate_data\\GSS_disability_ind.dta", replace
 
**Load GSS exploratory analysis table
odbc load, bigint clear exec("select * from  [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_2016_2018_tables_202203]") $IDISP_CONN
mmerge snz_uid using "I:\MAA2021-55\Data exploration\Intermediate_data\\GSS_disability_ind.dta", unm(master)

drop if gss_pq_collection_code   == "GSS2014"
gen edate_interview_date = date(gss_pq_PQinterview_date, "YMD")

*indicators to create categories for and output: life satisfaction, family wellbeing, enough income, trust (5 indicators), material hardship, loneliness
destring gss_pq_feel_life_code gss_pq_enough_inc_code gss_pq_fam_wellbeing_code gss_pq_safe_night_hood_code gss_pq_discriminated_code labour_force_status gss_pq_health_excel_poor_code, replace

** Life satisfaction
gen LS_3cats = "NA"
replace LS_3cats = "Low" if gss_pq_feel_life_code <= 6
replace LS_3cats = "7 or 8" if inlist(gss_pq_feel_life_code, 7,8) 
replace LS_3cats = "9 or 10" if inlist(gss_pq_feel_life_code, 9,10) 

** Family wellbeing
gen FamWB_3cats = "NA"
replace FamWB_3cats = "Low" if gss_pq_fam_wellbeing_code <= 6
replace FamWB_3cats = "7 or 8" if inlist(gss_pq_fam_wellbeing_code, 7,8) 
replace FamWB_3cats = "9 or 10" if inlist(gss_pq_fam_wellbeing_code, 9,10) 

** Safety in neighbourhood walking at night
gen Safety_cats = "NA"
replace Safety_cats = "Safe or very safe" if gss_pq_safe_night_hood_code == 11 | gss_pq_safe_night_hood_code == 12
replace Safety_cats = "Neither safe nor unsafe" if gss_pq_safe_night_hood_code == 13
replace Safety_cats = "Unsafe" if gss_pq_safe_night_hood_code == 14
replace Safety_cats = "Very unsafe" if gss_pq_safe_night_hood_code == 15

** Discriminated against indicator
gen discrim_cats = "NA"
replace discrim_cats = "Discriminated against" if gss_pq_discriminated_code == 1
replace discrim_cats = "Not discriminated against" if gss_pq_discriminated_code== 2

** Labour force
gen LFS_cats = "NA"
replace LFS_cats = "Employed" if labour_force_status == 1
replace LFS_cats = "Unemployed" if labour_force_status == 2
replace LFS_cats = "Not in the labour force" if labour_force_status == 3
 
** General health
gen GenHealth_cats = "NA"
replace GenHealth_cats = "Excellent or very good" if gss_pq_health_excel_poor_code == 11 | gss_pq_health_excel_poor_code == 12
replace GenHealth_cats = "Good" if gss_pq_health_excel_poor_code == 13
replace GenHealth_cats = "Fair" if gss_pq_health_excel_poor_code == 14
replace GenHealth_cats = "Poor" if gss_pq_health_excel_poor_code == 15 

** Enough income categories
gen EnghInc_cats = "NA"
replace EnghInc_cats = "Not enough or only just enough" if gss_pq_enough_inc_code == 11 | gss_pq_enough_inc_code == 12
// replace EnghInc_cats = "Only just enough" if MHS_qEnoughIncome == 12
replace EnghInc_cats = "Enough" if gss_pq_enough_inc_code == 13
replace EnghInc_cats = "More than enough" if gss_pq_enough_inc_code == 14

destring gss_pq_material_wellbeing_code gss_pq_trust_most_code gss_pq_trust_police_code gss_pq_trust_education_code gss_pq_trust_media_code gss_pq_trust_courts_code gss_pq_trust_parliament_code gss_pq_trust_health_code, replace

** Material hardship
gen MH_cats = "NA"
replace MH_cats = "Not in material hardship" if (gss_pq_material_wellbeing_code >= 10 & gss_pq_material_wellbeing_code <= 20)
replace MH_cats = "Material hardship" if (gss_pq_material_wellbeing_code > 5 & gss_pq_material_wellbeing_code <= 9)
replace MH_cats = "Severe material hardship" if (gss_pq_material_wellbeing_code <= 5)

** Trust
gen TrustPpl = gss_pq_trust_most_code
gen TrustPol = gss_pq_trust_police_code
gen TrustMed = gss_pq_trust_media_code
gen TrustParl = gss_pq_trust_parliament_code
gen TrustHlth = gss_pq_trust_health_code

foreach var in TrustPpl TrustPol TrustMed TrustParl TrustHlth {
	gen `var'_cats = "NA"
	replace `var'_cats = "0 to 4" if `var' <= 4
	replace `var'_cats = "5 to 7" if `var' >= 5 & `var' <= 7
// 	replace `var'_cats = "7 or 8" if `var' >= 7 & `var' <= 8
	replace `var'_cats = "8 to 10" if `var' >= 8 & `var' <= 10
}

** Loneliness
destring gss_pq_time_lonely_code, replace 
gen Lonely_cats = "NA"
replace Lonely_cats = "None of the time" if gss_pq_time_lonely_code == 11
replace Lonely_cats = "A little of the time" if gss_pq_time_lonely_code == 12
replace Lonely_cats = "Some of the time" if gss_pq_time_lonely_code == 13
replace Lonely_cats = "Most of the time" if gss_pq_time_lonely_code == 14
replace Lonely_cats = "All of the time" if gss_pq_time_lonely_code == 15

** Align the naming of these numerical variables with the HLFS dataset
destring gss_pq_life_worthwhile_code gss_pq_health_dvwho5_code, replace
gen Fam_WB = gss_pq_fam_wellbeing_code if gss_pq_fam_wellbeing_code <= 10
gen SWB_LS = gss_pq_feel_life_code if gss_pq_feel_life_code <= 10
gen SWB_LWW = gss_pq_life_worthwhile_code if gss_pq_life_worthwhile_code<= 10
gen WHO5 = gss_pq_health_dvwho5_code if gss_pq_health_dvwho5_code<= 100





****** CODE TO CREATE QUARTERLY/MONTHLY INDICATORS IF YOU WANTED MORE SENSITIVITY DURING THE YEAR
// gen pers_interview_dte = date(gss_pq_PQinterview_date, "YMD")
// format pers_interview_dte %td
// gen edate_interview_date = date(gss_pq_PQinterview_date, "YMD")
// sort pers_interview_dte
//
// gen survey_week = .
// gen survey_week_date = .
// gen interview_month = month(pers_interview_dte)
// gen interview_yr = year(pers_interview_dte)
// egen interview_mm_yyyy_date_tmp = concat(interview_month interview_yr), punct(/)
// gen interview_MY_date = date(interview_mm_yyyy_date_tmp, "MY")
// format interview_MY_date %td
// gen YQ = qofd(interview_MY_date)
// format YQ %tq
//
// gen str_YQ = string(YQ, "%tq")
//
// gen QRTR = ""
// replace QRTR = "2018q1 and 2018q2" if str_YQ == "2018q1" | str_YQ == "2018q2"
// replace QRTR = "2018q3" if str_YQ == "2018q3"
// replace QRTR = "2018q4" if str_YQ == "2018q4"
// replace QRTR = "2019q1 and 2019q2" if str_YQ == "2019q1" | str_YQ == "2019q2"

destring gss_pq_dvsex_code gss_pq_Reg_council_code age, replace 
gen age_18_to_64 = (age >= 18 & age <= 64)


gen adult_female = (age >= 18 & gss_pq_dvsex_code == 2)
gen adult_male = (age >= 18 & gss_pq_dvsex_code == 1)
gen Auckland = (gss_pq_Reg_council_code == 2)


//
// gen Not_Maori_or_Pacific_eth = (snz_ethnicity_grp2_nbr == 0 & snz_ethnicity_grp3_nbr == 0)
// gen Maori_eth = snz_ethnicity_grp2_nbr
// gen Pacific_eth = snz_ethnicity_grp3_nbr
// gen Maori_or_Pacific_eth = (Maori_eth == 1 | Pacific_eth == 1)
// gen All_ethnicities = 1


rename partnered_mother_depchild Prtnr_Mther_DC
rename partnered_father_depchild Prtnr_Fther_DC
rename solo_mother_depchild Solo_Mther_DC
rename solo_father_depchild Solo_Fther_DC

gen mother_DC = (Solo_Mther_DC == 1 | Prtnr_Mther_DC == 1 & inrange(age, 18,64))
gen father_DC = (Solo_Fther_DC == 1 | Prtnr_Fther_DC == 1 & inrange(age, 18,64))
gen Not_Solo_Parent_DC = (Prtnr_Mther_DC == 1 | Prtnr_Fther_DC == 1 & inrange(age, 18,64))
gen Solo_Parent_DC = (Solo_Mther_DC == 1 | Solo_Fther_DC == 1 & inrange(age, 18,64))

gen Any_NZer = (inrange(age, 18,64))
gen Any_NZer_18_to_39 = (inrange(age, 18,39))
gen Any_NZer_40_to_64 = (inrange(age, 40,64))
gen Any_NZer_65Plus = (inrange(age, 65,130))

replace Prtnr_Mther_DC = 0  if ~inrange(age, 18,64)
replace Prtnr_Fther_DC = 0   if ~inrange(age, 18,64)
replace Solo_Mther_DC = 0   if ~inrange(age, 18,64)
replace Solo_Fther_DC = 0   if ~inrange(age, 18,64)


gen High_dis_18_to_39 = (dv_disability == 1 & inrange(age, 18,39))
gen High_dis_40_to_64 = (dv_disability == 1 & inrange(age, 40,64))
gen High_dis_65Plus = (dv_disability == 1 & inrange(age, 65,130))

gen VHigh_dis_18_to_39 = (dv_disability == 2 & inrange(age, 18,39))
gen VHigh_dis_40_to_64 = (dv_disability == 2 & inrange(age, 40,64))
gen VHigh_dis_65Plus = (dv_disability == 2 & inrange(age, 65,130))

recode age 0/11=1 12/19=2 20/34=3 35/49=4 50/64=5 65/130=6 , generate(MOH_age_grp)
capture label define agegroup 1 "0 to 11" 2 "12 to 19" 3 "20 to 34" 4 "35 to 49" 5 "50 to 64" 6 "65+" 
label values MOH_age_grp agegroup

destring gss_pq_life_worthwhile_code gss_pq_feel_life_code gss_pq_fam_wellbeing_code gss_pq_health_dvwho5_code, replace


gen Survey = gss_pq_collection_code


*** align weighting variables to make running the descriptive tables code easier.
rename gss_pq_person_FinalWgt_nbr sqfinalwgt

foreach var in gss_pq_person_FinalWgt1_nbr gss_pq_person_FinalWgt2_nbr gss_pq_person_FinalWgt3_nbr gss_pq_person_FinalWgt4_nbr gss_pq_person_FinalWgt5_nbr gss_pq_person_FinalWgt6_nbr gss_pq_person_FinalWgt7_nbr gss_pq_person_FinalWgt8_nbr gss_pq_person_FinalWgt9_nbr gss_pq_person_FinalWgt10_nbr gss_pq_person_FinalWgt11_nbr gss_pq_person_FinalWgt12_nbr gss_pq_person_FinalWgt13_nbr gss_pq_person_FinalWgt14_nbr gss_pq_person_FinalWgt15_nbr gss_pq_person_FinalWgt16_nbr gss_pq_person_FinalWgt17_nbr gss_pq_person_FinalWgt18_nbr gss_pq_person_FinalWgt19_nbr gss_pq_person_FinalWgt20_nbr gss_pq_person_FinalWgt21_nbr gss_pq_person_FinalWgt22_nbr gss_pq_person_FinalWgt23_nbr gss_pq_person_FinalWgt24_nbr gss_pq_person_FinalWgt25_nbr gss_pq_person_FinalWgt26_nbr gss_pq_person_FinalWgt27_nbr gss_pq_person_FinalWgt28_nbr gss_pq_person_FinalWgt29_nbr gss_pq_person_FinalWgt30_nbr gss_pq_person_FinalWgt31_nbr gss_pq_person_FinalWgt32_nbr gss_pq_person_FinalWgt33_nbr gss_pq_person_FinalWgt34_nbr gss_pq_person_FinalWgt35_nbr gss_pq_person_FinalWgt36_nbr gss_pq_person_FinalWgt37_nbr gss_pq_person_FinalWgt38_nbr gss_pq_person_FinalWgt39_nbr gss_pq_person_FinalWgt40_nbr gss_pq_person_FinalWgt41_nbr gss_pq_person_FinalWgt42_nbr gss_pq_person_FinalWgt43_nbr gss_pq_person_FinalWgt44_nbr gss_pq_person_FinalWgt45_nbr gss_pq_person_FinalWgt46_nbr gss_pq_person_FinalWgt47_nbr gss_pq_person_FinalWgt48_nbr gss_pq_person_FinalWgt49_nbr gss_pq_person_FinalWgt50_nbr gss_pq_person_FinalWgt51_nbr gss_pq_person_FinalWgt52_nbr gss_pq_person_FinalWgt53_nbr gss_pq_person_FinalWgt54_nbr gss_pq_person_FinalWgt55_nbr gss_pq_person_FinalWgt56_nbr gss_pq_person_FinalWgt57_nbr gss_pq_person_FinalWgt58_nbr gss_pq_person_FinalWgt59_nbr gss_pq_person_FinalWgt60_nbr gss_pq_person_FinalWgt61_nbr gss_pq_person_FinalWgt62_nbr gss_pq_person_FinalWgt63_nbr gss_pq_person_FinalWgt64_nbr gss_pq_person_FinalWgt65_nbr gss_pq_person_FinalWgt66_nbr gss_pq_person_FinalWgt67_nbr gss_pq_person_FinalWgt68_nbr gss_pq_person_FinalWgt69_nbr gss_pq_person_FinalWgt70_nbr gss_pq_person_FinalWgt71_nbr gss_pq_person_FinalWgt72_nbr gss_pq_person_FinalWgt73_nbr gss_pq_person_FinalWgt74_nbr gss_pq_person_FinalWgt75_nbr gss_pq_person_FinalWgt76_nbr gss_pq_person_FinalWgt77_nbr gss_pq_person_FinalWgt78_nbr gss_pq_person_FinalWgt79_nbr gss_pq_person_FinalWgt80_nbr gss_pq_person_FinalWgt81_nbr gss_pq_person_FinalWgt82_nbr gss_pq_person_FinalWgt83_nbr gss_pq_person_FinalWgt84_nbr gss_pq_person_FinalWgt85_nbr gss_pq_person_FinalWgt86_nbr gss_pq_person_FinalWgt87_nbr gss_pq_person_FinalWgt88_nbr gss_pq_person_FinalWgt89_nbr gss_pq_person_FinalWgt90_nbr gss_pq_person_FinalWgt91_nbr gss_pq_person_FinalWgt92_nbr gss_pq_person_FinalWgt93_nbr gss_pq_person_FinalWgt94_nbr gss_pq_person_FinalWgt95_nbr gss_pq_person_FinalWgt96_nbr gss_pq_person_FinalWgt97_nbr gss_pq_person_FinalWgt98_nbr gss_pq_person_FinalWgt99_nbr gss_pq_person_FinalWgt100_nbr { 
	local nmbr = subinstr("`var'", "gss_pq_person_FinalWgt", "",.)
	local nmbr2 = subinstr("`nmbr'", "_nbr", "",.)
	rename `var' sqfinalwgt_`nmbr2'
 
}

gen Not_Maori_or_Pac_18to64 = (gss_pq_ethnic_grp2_snz_ind == 0 & gss_pq_ethnic_grp3_snz_ind == 0 & inrange(age, 18,64))
gen Maori_18to64 = (gss_pq_ethnic_grp2_snz_ind == 1 & inrange(age, 18,64))
gen Pacific_18to64 = (gss_pq_ethnic_grp3_snz_ind == 1 & inrange(age, 18,64))

save "I:\MAA2021-55\Data exploration\Intermediate_data\\GSS_Table_dataset.dta", replace






*** redundant code - now combined with HLFS descriptive tables code
/*

*******************************************************************************************************************************************
************************************************** DESCRIPTIVE TABLE  OUTPUTS *************************************************************
*******************************************************************************************************************************************
*******************************************************************************************************************************************
// GSS2018
// Auckland NotAuckland 
foreach GSS in  GSS2016 GSS2018 {

foreach set in All_NZ Auckland NotAuckland  {
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
	
use "I:\MAA2021-55\Data exploration\Intermediate_data\\GSS_Table_dataset.dta", clear
keep if gss_pq_collection_code == "`GSS'"

rename gss_pq_person_FinalWgt_nbr GSS_Individual_FinalWeight

svyset snz_uid [pweight=GSS_Individual_FinalWeight], vce(jackknife) jkrweight(gss_pq_person_FinalWgt*)


foreach var in LS_3cats FamWB_3cats LFS_cats GenHealth_cats Safety_cats discrim_cats EnghInc_cats MH_cats TrustPpl_cats TrustPol_cats TrustMed_cats TrustParl_cats TrustHlth_cats Lonely_cats {
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
destring gss_pq_life_worthwhile_code gss_pq_feel_life_code gss_pq_fam_wellbeing_code gss_pq_health_dvwho5_code, replace

gen Fam_WB = gss_pq_fam_wellbeing_code if gss_pq_fam_wellbeing_code <= 10
gen SWB_LS = gss_pq_feel_life_code if gss_pq_feel_life_code <= 10
gen SWB_LWW = gss_pq_life_worthwhile_code if gss_pq_life_worthwhile_code<= 10
gen WHO5 = gss_pq_health_dvwho5_code if gss_pq_health_dvwho5_code<= 100

if "`GSS'" == "GSS2016" {
    local mean_vars "SWB_LS SWB_LWW"
}
else {
    local mean_vars "Fam_WB SWB_LS SWB_LWW WHO5"
}

foreach var in `mean_vars' {
	foreach Qrter of numlist 1/1 {
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

foreach var in `mean_vars' {
	foreach Qrter of numlist 1/1 { 
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
			save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_mean_`var'_`Qrter'_`set'.dta", replace
			restore
		}
	}
}


preserve

use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_mean_SWB_LS_1_`set'.dta", clear
foreach var in `mean_vars' {
	foreach Qrter of numlist 1/1 {  
			if "`var'" == "SWB_LS" & "`Qrter'" == "1" | ("`var'" == "WHO5" & inlist(`Qrter', 2,3,4)) {
				
			} 
			else {
				append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_mean_`var'_`Qrter'_`set'.dta"
				
			}
		
			di "`var'"
	}
}
save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_mean_all_variables_`set'.dta", replace	
restore




//}
//
// preserve
// use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS_mean_Fam_WB_1.dta", clear
// foreach Qrter of numlist 2/4 {  
// 	append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS_mean_Fam_WB_`Qrter'.dta"
// }
//
// foreach var in SWB_LS SWB_LWW {
// 	foreach Qrter of numlist 1/4 {  
// 		append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS_mean_`var'_`Qrter'.dta"
// 	}
// }
// save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS_mean_all_variables.dta", replace	
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
//
//
// foreach set in All_NZ Auckland NotAuckland  {
// 	if "`set'" == "All_NZ" {
// 		local set_restrictions " "	
// 	}
// 	if "`set'" == "Auckland" {
// 		local set_restrictions "& Auckland == 1"	
// 	}
// 	if "`set'" == "NotAuckland" {
// 		local set_restrictions "& Auckland == 0"	
// 	}
// 	di "`set_restrictions'"
//	
// use "I:\MAA2021-55\Data exploration\Intermediate_data\\GSS_Table_dataset.dta", clear
//
// rename gss_pq_person_FinalWgt_nbr GSS_Individual_FinalWeight
//
// svyset snz_uid [pweight=GSS_Individual_FinalWeight], vce(jackknife) jkrweight(gss_pq_person_FinalWgt*)
//
//
// foreach var in LS_3cats FamWB_3cats LFS_cats GenHealth_cats Safety_cats discrim_cats EnghInc_cats MH_cats TrustPpl_cats TrustPol_cats TrustMed_cats TrustParl_cats TrustHlth_cats Lonely_cats {
// 	encode `var', gen(`var'_enc)
// }
//



pause on
foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc TrustPpl_cats_enc TrustPol_cats_enc TrustMed_cats_enc TrustParl_cats_enc TrustHlth_cats_enc Lonely_cats_enc {
	foreach Qrter of numlist 1/1 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
			if "`grp'" == "Any_NZer_65Plus" {
				qui svy: proportion `var' if `grp' == 1 & QRTR == "Q`Qrter'"  `set_restrictions'
			}
			else {
				qui svy: proportion `var' if `grp' == 1 & QRTR == "Q`Qrter'" & age_18_to_64 == 1  `set_restrictions'
			}
//			
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
				save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_p_`varname'_Q`Qrter'_`grp'_`set'.dta", replace 
			restore
		}
		di "Q`Qrter' completed"
	}
}


preserve
use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_p_EnghInc_cats_Q1_Prtnr_Mther_DC_`set'.dta", clear
// foreach Qrter of numlist 1/4 {
// 	foreach grp in Prtnr_Mther_DC Prtnr_Fther_DC Solo_Mther_DC Solo_Fther_DC adult_female adult_male mother_DC father_DC  {
// 		append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS_p_EnghInc_cats_enc_Q`Qrter'_`grp'.dta"
// 	}
// }	
foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc TrustPpl_cats_enc TrustPol_cats_enc TrustMed_cats_enc TrustParl_cats_enc TrustHlth_cats_enc Lonely_cats_enc {
	local varname = substr("`var'",1,length("`var'") - 4)
	foreach Qrter of numlist 1/1 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
			if "`var'" == "EnghInc_cats_enc" & "`Qrter'" == "1" & "`grp'" == "Prtnr_Mther_DC"  {
				
			} 
			else {
				append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_p_`varname'_Q`Qrter'_`grp'_`set'.dta"
				
			}
			
		}
	}	
}
replace  category = substr(category,4,1)
destring category, replace
save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_proportions_data_`set'.dta", replace 
restore





***************************************************************************************************************************************
********************************************* POPULATION ESTIMATES AND OBSERVATION COUNTS *********************************************
***************************************************************************************************************************************



foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc TrustPpl_cats_enc TrustPol_cats_enc TrustMed_cats_enc TrustParl_cats_enc TrustHlth_cats_enc Lonely_cats_enc {
	foreach Qrter of numlist 1/1 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
			preserve
			if "`grp'" == "Any_NZer_65Plus" {
				collapse (count) Est_pop=snz_uid [pweight=GSS_Individual_FinalWeight] if `grp' == 1 & QRTR == "Q`Qrter'"   `set_restrictions', by(`var')
			}
			else {
				collapse (count) Est_pop=snz_uid [pweight=GSS_Individual_FinalWeight] if `grp' == 1 & QRTR == "Q`Qrter'" & age_18_to_64 == 1  `set_restrictions', by(`var')
			}
			
			local varname = substr("`var'",1,length("`var'") - 4)
			decode `var', gen(var_categories)
			gen group = "`grp'"
			gen wave = `Qrter'
			gen wellbeing_measure = "`varname'"
			rename `var' encoded_cats
			save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_Cnt_`var'_Q`Qrter'_`grp'_`set'.dta", replace 
			restore
			
		}
		di "Q`Qrter' completed"
	}
}


foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc TrustPpl_cats_enc TrustPol_cats_enc TrustMed_cats_enc TrustParl_cats_enc TrustHlth_cats_enc Lonely_cats_enc {
	foreach Qrter of numlist 1/1 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
			preserve
			if "`grp'" == "Any_NZer_65Plus" {
				collapse (count) Observations=snz_uid  if `grp' == 1 & QRTR == "Q`Qrter'"  `set_restrictions', by(`var')
			}
			else {
				collapse (count) Observations=snz_uid  if `grp' == 1 & QRTR == "Q`Qrter'" & age_18_to_64 == 1  `set_restrictions', by(`var')
			}
			
			local varname = substr("`var'",1,length("`var'") - 4)
			decode `var', gen(var_categories)
			gen group = "`grp'"
			gen wave = `Qrter'
			gen wellbeing_measure = "`varname'"
			rename `var' encoded_cats
			save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_Obs_`var'_Q`Qrter'_`grp'_`set'.dta", replace 
			restore
			
		}
		di "Q`Qrter' completed"
	}
}

preserve
use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_Cnt_EnghInc_cats_enc_Q1_Prtnr_Mther_DC_`set'.dta", clear
// append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS_Obs_EnghInc_cats_enc_Q1_Prtnr_Mther_DC.dta"
foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc TrustPpl_cats_enc TrustPol_cats_enc TrustMed_cats_enc TrustParl_cats_enc TrustHlth_cats_enc Lonely_cats_enc {
	foreach Qrter of numlist 1/1 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus  {
			if "`var'" == "EnghInc_cats_enc" & "`Qrter'" == "1" & "`grp'" == "Prtnr_Mther_DC" & "`obs'" == "Cnt" {
				
			} 
			else {
				append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_Cnt_`var'_Q`Qrter'_`grp'_`set'.dta"
				
			}
		
		}
	}
}	
foreach var in LS_3cats_enc FamWB_3cats_enc LFS_cats_enc GenHealth_cats_enc Safety_cats_enc discrim_cats_enc EnghInc_cats_enc MH_cats_enc TrustPpl_cats_enc TrustPol_cats_enc TrustMed_cats_enc TrustParl_cats_enc TrustHlth_cats_enc Lonely_cats_enc {
	foreach Qrter of numlist 1/1 {
		foreach grp in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {

				mmerge encoded_cats group wave wellbeing_measure using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_Obs_`var'_Q`Qrter'_`grp'_`set'.dta", unm(both) update
		
		}
	}
}	
save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_Obs_and_pop_est_`set'.dta", replace 

	
restore	
}






foreach set in All_NZ Auckland NotAuckland {
	
	
	use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_mean_all_variables_`set'.dta", clear
		gen region = "`set'"
		replace wave = 0
		foreach var in Prtnr_Fther_DC Prtnr_Mther_DC Solo_Fther_DC Solo_Mther_DC adult_female adult_male mother_DC father_DC Not_Solo_Parent_DC Solo_Parent_DC Any_NZer Any_NZer_18_to_39 Any_NZer_40_to_64 Any_NZer_65Plus {
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
		save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_mean_reshaped_`set'.dta", replace
		
	
		use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_proportions_data_`set'.dta", clear
		gen region = "`set'"
		replace statistic = "std_err"  if statistic == "standard error"
		replace statistic = "t_stat" if statistic ==  "t statistic"
		replace statistic = "p_val" if statistic ==  "p value"
		replace statistic = "lower_CI_est" if statistic ==  "Lower CI estimate"
		replace statistic = "upper_CI_est" if statistic ==  "Upper CI estimate"
		replace statistic = "std_dev" if statistic ==  "standard deviation"


		reshape wide value_ ,i(group wellbeing_measure wave category) j(statistic) string
		mmerge category group wellbeing_measure wave using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_Obs_and_pop_est_`set'.dta", unm(master) umatch(encoded_cats group  wellbeing_measure wave) update
		replace wave = 0
		sort group wellbeing_measure var_categories wave
		order group wellbeing_measure var_categories wave
		drop category _merge
		append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_mean_reshaped_`set'.dta"
		save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_desc_tables_data_`set'.dta", replace

}

use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_desc_tables_data_All_NZ.dta", clear
append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_desc_tables_data_Auckland.dta"
append using "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_desc_tables_data_NotAuckland.dta"

save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\`GSS'_desc_tables_data.dta", replace
}
use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS2018_desc_tables_data.dta", replace
replace wave = 0.5
save "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS2018_desc_tables_data.dta", replace

use "I:\MAA2021-55\Data exploration\Intermediate_data\desc\\GSS2016_desc_tables_data.dta", replace
//
// order region group wellbeing_measure var_categories wave Est_pop value_mean value_proportion value_std_err value_lower_CI_est value_upper_CI_est value_p_val   value_t_stat value_std_dev Observations  
//
// // specifies directory for the output file (excel file) and suppresses small counts as per microdata output guide.
// export excel using "I:\MAA2021-55\Outputs\\Descriptive_tables_data_raw_16_May_2022.xlsx", firstrow(variables)  sheet(GSS_desc_data) replace 
// foreach var in value_lower_CI_est value_p_val value_proportion value_std_err value_t_stat value_upper_CI_est Observations value_mean value_std_dev {
// 	replace `var' = . if Est_pop <= 999
// }
// replace Est_pop = . if Est_pop <= 999
// replace Est_pop = round(Est_pop, 100)
// export excel using "I:\MAA2021-55\Outputs\\Descriptive_tables_data_clean_16_May_2022.xlsx", firstrow(variables)  sheet(GSS_desc_data) replace 
//
//
//





















**** Old code that was creating monthly/quarter timeseries charts of wellbeing measures.

/*
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

destring gss_pq_dvsex_code, replace
gen adult_female = (age >= 18 & gss_pq_dvsex_code == 2)
gen adult_male = (age >= 18 & gss_pq_dvsex_code == 1)

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



