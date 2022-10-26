****** CODE TO CLEAN DATA AND PRODUCE DESCRIPTIVE STATISTICS FOR COVID-19 VACCINATION PROJECT
**** Author: Shaan Badenhorst
**** Reviewer: Luke Scullion


// Intended use: Read in output from Data Assembly Tool and undertake manipulations of the data as necessary to turn it into a format suitable for descriptive statistics and/or advanced analysis.

// Notes:
* Search this before outputting...
* 
***Delete

// History (reverse order): 
// 2021-10-XX Draft QA'd (LS)
// 2021-10-13 First draft started (SB)
clear all
pause on

// Outputs
* Descriptive statistic tables dataset.
* Datasets for use by SWa and other agencies for further analysis (imported into SQL).

*****************************************************************************
*****************************************************************************
 ** UPDATE REFERENCES WITH EACH NEW CIR DATA LOAD **
// CIR_NHI and CIR_activity table references
global CIR_deets "[vacc_202203_moh_cir_nhi_20220405]"
global CIR_activity_table "[moh_cir_vaccination_activity_20220405]"

// DAT table reference
global tidy_DAT_table "[tmp_202203_vacc_rectangular_20220405]"

// Latest date of vaccination activity and today's date macros
global date_of_interest "29/03/2022"
global new_CIR_data_date "20220329"
global date_today "20220407"
*****************************************************************************
*****************************************************************************


** THE REMAINDER OF THE CODE ONLY REQUIRES UPDATING WHEN THE NUMBER OF DOSES IN THE CIR DATA CHANGES, OR WHEN OTHER VARIABLES ARE ADDED/REMOVED.

global MData "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\Metadata\"
global Outputs "I:\MAA2021-49\SWA_development\Main\Staging\Outputs\Descriptives\"

//run "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\mmerge.ado"
//
do "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\Phase_2/_0_Init.do"



// Prepare metadata files for merging later
*do "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\Phase_2\_1_Metadata_and_additional_data_v2.do"


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
 
** Load CIR activity data to try Shari's recommended method of counting doses.
odbc load, bigint clear exec("select * from [IDI_Adhoc].[clean_read_MOH_CIR].$CIR_activity_table") $IDISP_CONN

sort snz_uid
keep if snz_uid <= NOT RELEASED

// save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\moh_cir_vaccination_activity_20220125.dta", replace
keep if snz_spine_uid ~=.
duplicates drop snz_uid dose_nbr activity_date, force

duplicates drop snz_uid activity_date, force

keep snz_uid activity_date

sort snz_uid activity_date
bysort snz_uid: gen activity_num = _n
foreach act_num of numlist 1/6 {
    gen actvity_`act_num'_date = ""
}
	
foreach act_num of numlist 1/6 {
    replace actvity_`act_num'_date = activity_date if activity_num == `act_num'
}

// dates
collapse (firstnm) actvity_1_date actvity_2_date actvity_3_date actvity_4_date actvity_5_date actvity_6_date, by(snz_uid) fast
foreach num in 29032022 22032022 15032022 08032022 01032022 22022022 15022022 08022022 01022022 25012022 18012022 11012022 04012022 28122021 21122021 14122021 07122021 30112021 23112021 16112021 09112021 02112021 26102021 19102021 12102021 05102021 28092021 21092021 14092021 07092021 31082021 24082021 17082021 10082021 03082021 27072021 20072021 13072021 06072021 29062021 22062021 15062021 08062021 01062021 25052021 18052021 11052021 04052021 27042021 20042021 13042021 06042021 30032021 23032021 16032021 09032021 02032021 23022021 16022021 09022021 {
	gen vacc_stat_as_of_`num' = 0
}

reshape long vacc_stat_as_of, i(snz_uid) j(Date_ref) string
replace Date_ref = substr(Date_ref,-8,. )

gen ref_date_fmt2 = date(Date_ref, "DMY")
format ref_date_fmt2 %dD_m_Y

foreach act_num of numlist 1/6 { 
gen act_date_fmt2_`act_num' = date(actvity_`act_num'_date, "YMD")
format act_date_fmt2_`act_num' %dD_m_Y
}

sort snz_uid  ref_date_fmt2 
gen dose_count = 0
order snz_uid ref_date_fmt2  dose_count

foreach act_num of numlist 1/6 {  
replace dose_count = 1 if act_date_fmt2_`act_num' <= ref_date_fmt2 & ref_date_fmt2 - act_date_fmt2_`act_num'  <=6 
}
//
// collapse (max) dose_count, by(snz_uid ref_date_fmt2)
bysort snz_uid (ref_date_fmt2): gen dose_count_tot_ = sum(dose_count)
order snz_uid ref_date_fmt2 dose_count Date_ref dose_count_tot_

keep snz_uid ref_date_fmt2 dose_count_tot_

gsort snz_uid -ref_date_fmt2
bysort snz_uid: gen wk_ago = _n-1

drop ref_date_fmt2 
reshape wide dose_count_tot_, i(snz_uid) j(wk_ago)

save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\\CIR_activity_table_doses_count_timeseries_pt1.dta", replace

odbc load, bigint clear exec("select * from [IDI_Adhoc].[clean_read_MOH_CIR].$CIR_activity_table") $IDISP_CONN

sort snz_uid
keep if snz_uid > XXXXXXX & snz_uid <= XXXXXXX

// save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\moh_cir_vaccination_activity_20220125.dta", replace
keep if snz_spine_uid ~=.
duplicates drop snz_uid dose_nbr activity_date, force

duplicates drop snz_uid activity_date, force


keep snz_uid activity_date

sort snz_uid activity_date
bysort snz_uid: gen activity_num = _n
foreach act_num of numlist 1/6 {
    gen actvity_`act_num'_date = ""
}	
foreach act_num of numlist 1/6 {
    replace actvity_`act_num'_date = activity_date if activity_num == `act_num'
}
collapse (firstnm) actvity_1_date actvity_2_date actvity_3_date actvity_4_date actvity_5_date actvity_6_date, by(snz_uid) fast
foreach num in 29032022 22032022 15032022 08032022 01032022 22022022 15022022 08022022 01022022 25012022 18012022 11012022 04012022 28122021 21122021 14122021 07122021 30112021 23112021 16112021 09112021 02112021 26102021 19102021 12102021 05102021 28092021 21092021 14092021 07092021 31082021 24082021 17082021 10082021 03082021 27072021 20072021 13072021 06072021 29062021 22062021 15062021 08062021 01062021 25052021 18052021 11052021 04052021 27042021 20042021 13042021 06042021 30032021 23032021 16032021 09032021 02032021 23022021 16022021 09022021  {
	gen vacc_stat_as_of_`num' = 0
}

reshape long vacc_stat_as_of, i(snz_uid) j(Date_ref) string
replace Date_ref = substr(Date_ref,-8,. )

gen ref_date_fmt2 = date(Date_ref, "DMY")
format ref_date_fmt2 %dD_m_Y

foreach act_num of numlist 1/6 { 
gen act_date_fmt2_`act_num' = date(actvity_`act_num'_date, "YMD")
format act_date_fmt2_`act_num' %dD_m_Y
}

sort snz_uid  ref_date_fmt2 
gen dose_count = 0
order snz_uid ref_date_fmt2  dose_count

foreach act_num of numlist 1/6 {  
replace dose_count = 1 if act_date_fmt2_`act_num' <= ref_date_fmt2 & ref_date_fmt2 - act_date_fmt2_`act_num'  <=6 
}
//
// collapse (max) dose_count, by(snz_uid ref_date_fmt2)
bysort snz_uid (ref_date_fmt2): gen dose_count_tot_ = sum(dose_count)
order snz_uid ref_date_fmt2 dose_count Date_ref dose_count_tot_

keep snz_uid ref_date_fmt2 dose_count_tot_

gsort snz_uid -ref_date_fmt2
bysort snz_uid: gen wk_ago = _n-1

drop ref_date_fmt2 
reshape wide dose_count_tot_, i(snz_uid) j(wk_ago)

save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\\CIR_activity_table_doses_count_timeseries_pt2.dta", replace


odbc load, bigint clear exec("select * from [IDI_Adhoc].[clean_read_MOH_CIR].$CIR_activity_table") $IDISP_CONN

sort snz_uid
keep if snz_uid >  NOT RELEASED

// save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\moh_cir_vaccination_activity_20220125.dta", replace
keep if snz_spine_uid ~=.
duplicates drop snz_uid dose_nbr activity_date, force

duplicates drop snz_uid activity_date, force

keep snz_uid activity_date

sort snz_uid activity_date
bysort snz_uid: gen activity_num = _n
foreach act_num of numlist 1/6 {
    gen actvity_`act_num'_date = ""
}	
foreach act_num of numlist 1/6 {
    replace actvity_`act_num'_date = activity_date if activity_num == `act_num'
}
collapse (firstnm) actvity_1_date actvity_2_date actvity_3_date actvity_4_date actvity_5_date actvity_6_date, by(snz_uid) fast
foreach num in 29032022 22032022 15032022 08032022 01032022 22022022 15022022 08022022 01022022 25012022 18012022 11012022 04012022 28122021 21122021 14122021 07122021 30112021 23112021 16112021 09112021 02112021 26102021 19102021 12102021 05102021 28092021 21092021 14092021 07092021 31082021 24082021 17082021 10082021 03082021 27072021 20072021 13072021 06072021 29062021 22062021 15062021 08062021 01062021 25052021 18052021 11052021 04052021 27042021 20042021 13042021 06042021 30032021 23032021 16032021 09032021 02032021 23022021 16022021 09022021  {
	gen vacc_stat_as_of_`num' = 0
}

reshape long vacc_stat_as_of, i(snz_uid) j(Date_ref) string
replace Date_ref = substr(Date_ref,-8,. )

gen ref_date_fmt2 = date(Date_ref, "DMY")
format ref_date_fmt2 %dD_m_Y

foreach act_num of numlist 1/6 { 
gen act_date_fmt2_`act_num' = date(actvity_`act_num'_date, "YMD")
format act_date_fmt2_`act_num' %dD_m_Y
}

sort snz_uid  ref_date_fmt2 
gen dose_count = 0
order snz_uid ref_date_fmt2  dose_count

foreach act_num of numlist 1/6 {  
replace dose_count = 1 if act_date_fmt2_`act_num' <= ref_date_fmt2 & ref_date_fmt2 - act_date_fmt2_`act_num'  <=6 
}
//
// collapse (max) dose_count, by(snz_uid ref_date_fmt2)
bysort snz_uid (ref_date_fmt2): gen dose_count_tot_ = sum(dose_count)
order snz_uid ref_date_fmt2 dose_count Date_ref dose_count_tot_

keep snz_uid ref_date_fmt2 dose_count_tot_

gsort snz_uid -ref_date_fmt2
bysort snz_uid: gen wk_ago = _n-1

drop ref_date_fmt2 
reshape wide dose_count_tot_, i(snz_uid) j(wk_ago)

save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\\CIR_activity_table_doses_count_timeseries_pt3.dta", replace




use "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\\CIR_activity_table_doses_count_timeseries_pt1.dta", clear

mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\\CIR_activity_table_doses_count_timeseries_pt2.dta", unm(both) 

mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\\CIR_activity_table_doses_count_timeseries_pt3.dta", unm(both) 

save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\\CIR_activity_table_doses_count_timeseries_combined.dta", replace

//export delimited using "I:\MAA2021-49\Cross-agency collaboration\Dataset creation\upload csv to sql\CIR_${new_CIR_data_date}_doses_cnts_over_time_${date_today}.csv",replace 






// Load the CIR details table to merge on personal details where missing in the IDI (age, sex, ethnicity, meshblock) 
odbc load, bigint clear exec("select * from [IDI_Sandpit].[DL-MAA2021-49].$CIR_deets") $IDISP_CONN
duplicates drop snz_uid, force
foreach var in snz_moh_uid MB2018_code dob_year dob_month gender_code ethnic_code_1 ethnic_code_2 ethnic_code_3 priority_ethnic_code  {
	rename `var' CIR_`var'
}
sort snz_uid
save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\CIR_dets_202203.dta", replace 

// DHB of service
odbc load, bigint clear exec("select snz_uid, dhb_of_service from [IDI_Sandpit].[DL-MAA2021-49].vacc_clean_moh_cir_vaccination_activity_20220405_202203") $IDISP_CONN
duplicates drop snz_uid, force
rename dhb_of_service CIR_DHB_of_service
sort snz_uid
save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\CIR_DHB_data_202203.dta", replace 
 
// Load DAT table from Sandpit
odbc load, bigint clear exec("select * from [IDI_Sandpit].[DL-MAA2021-49].$tidy_DAT_table") $IDISP_CONN

// Merge on CIR details table
mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\CIR_dets_202203.dta", unm(master)
mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\CIR_DHB_data_202203.dta", unm(master)
// mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\Industry_3char.dta", unm(master)
mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\T1Bens_202203.dta", unm(master)
mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\T2Bens_202203.dta", unm(master)
mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\enrolment_data_202203.dta", unm(master)
// mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\Craig_ethnicity.dta", unm(master)






************************************************************************************************************************************************************************************************************************************************

 ******************************************
 ************** DATA CLEANING *************
 ******************************************

// Tidy up age variable based on todays date.

di "$date_of_interest"
gen date_of_interest =  "$date_of_interest"
gen date_of_interest2 = date(date_of_interest, "DMY")
format date_of_interest2 %dD_m_Y

rename snz_birth_year_nbr  Birth_year
rename snz_birth_month_nbr Birth_month

// Identify observations to replace birth and sex details for using CIR data.....
gen flag_DOB = (Birth_year <= 1908 | Birth_year ==.) 
replace Birth_year = CIR_dob_year if flag_DOB ==1
replace Birth_month = CIR_dob_month if flag_DOB ==1

tab Sex
gen flag_Sex = (Sex == .)
tab flag_Sex
replace CIR_gender_code = "1" if CIR_gender_code == "M"
replace CIR_gender_code = "2" if CIR_gender_code == "F"
replace CIR_gender_code = "3" if CIR_gender_code == "O"
destring CIR_gender_code, replace
replace Sex = CIR_gender_code if flag_Sex == 1
tab Sex


mmerge Meshblock using "${MData}MB2021_to_MB2018.dta", unm(master) umatch(mb2021)

rename Meshblock MB2021
rename mb2018 Meshblock

gen flag_MB = (Meshblock == .)
// replace CIR_MB2018_code = "." if CIR_MB2018_code =="NULL"
destring CIR_MB2018_code, replace
replace Meshblock=CIR_MB2018_code if flag_MB ==1



// Create age variables

gen dob = mdy(Birth_month, 15, Birth_year)
format dob %dD_m_Y

gen age = (date_of_interest2 - dob )/365.25
gen floor_age = floor(age)

foreach week of numlist 1/23 {
	gen tmp_date_wk_`week' = date_of_interest2 - (7*`week')

	format tmp_date_wk_`week' %dD_m_Y
		
	gen age_`week'_wk_ago = floor((tmp_date_wk_`week' - dob )/365.25)
}
// Check that age variable going back in time works and makes sense....
gen flag1 = ( floor_age == 12 & age_5_wk_ago == 11)
tab flag1
gen flag2 = ( floor_age == 12 & age_7_wk_ago == 11)
tab flag2

*** Drop 11 year olds - as at 5 weeks prior to current data - and younger to speed this up.
// drop if floor_age <= 11
gen dead = (year_of_death ~=.)
drop if dead == 1




recode floor_age 0/11=1 12/19=2 20/34=3 35/49=4 50/64=5 65/130=6 , generate(MOH_age_grp)
capture label define agegroup 1 "0 to 11" 2 "12 to 19" 3 "20 to 34" 4 "35 to 49" 5 "50 to 64" 6 "65+" 
label values MOH_age_grp agegroup

recode floor_age 0/4=1 5/9=2 10/14=3 15/19=4 20/29=5 30/39=6 40/49=7 50/64=8 65/130=9, generate(agegrp9)
capture label define agegroup2 1 "0 to 4" 2 "5 to 9" 3 "10 to 14" 4 "15 to 19" 5 "20 to 29" 6 "30 to 39" 7 "40 to 49" 8 "50 to 64" 9 "65+"
label values agegrp9 agegroup2

recode floor_age 0/4=1 5/9=2 10/14=3 15/19=4 20/29=5 30/39=6 40/49=7 50/64=8 65/79=9 80/94=10 95/130=11 , generate(agegrp11)
capture label define agegroup3 1 "0 to 4" 2 "5 to 9" 3 "10 to 14" 4 "15 to 19" 5 "20 to 29" 6 "30 to 39" 7 "40 to 49" 8 "50 to 64" 9 "65 to 79" 10 "80 to 94" 11 "95+"
label values agegrp11 agegroup3

recode floor_age 0/4=1 5/9=2 10/14=3 15/19=4 20/24=5 25/29=6 30/34=7 35/39=8 40/44=9 45/49=10 50/54=11 55/59=12 60/64=13 65/69=14 70/74=15 75/130=16, generate(age_5yr_bands)
capture label define agegroup4 1 "0 to 4" 2 "5 to 9" 3 "10 to 14" 4 "15 to 19" 5 "20 to 24" 6 "25 to 29" 7 "30 to 34" 8 "35 to 39" 9 "40 to 44" 10 "45 to 49" 11 "50 to 54" 12 "55 to 59" 13 "60 to 64" 14 "65 to 69" 15 "70 to 74" 16 "75+"
label values age_5yr_bands agegroup4

// Convert to strings for ease of outputting later...
decode MOH_age_grp , generate(MOH_age_cats)
decode agegrp9 , generate(age_grps)
decode agegrp11 , generate(age_grps_v2)
decode age_5yr_bands , generate(age_5yr_grps)

// decode dec_neet_since_Jan2020 , generate(deciles_pct_time_NEET_Jan20)
 
// Generate one variable for highest qualification 
 gen highest_qualification = "Missing"
 replace highest_qualification = "No qualification" if Qual_lvl_0 == 1
 replace highest_qualification = "Level 1 to 3 qualification" if Qual_lvl_1 == 1 | Qual_lvl_2 == 1 | Qual_lvl_3 == 1
 replace highest_qualification = "Level 4 to 6 qualification" if Qual_lvl_4_to_6 == 1
 replace highest_qualification = "Level 7+" if Qual_lvl_7_plus == 1

// Generate a single enrolment indicator
capture drop  Enrolled_student
 gen Enrolled_student = 1 if prim_sec == 1 | tec_it == 1 | tertiary== 1
 replace Enrolled_student =  0 if Enrolled_student == .

//  rename targeted_training enrolled_targ_training
 rename tertiary enrolled_tertiary
 rename tec_it enrolled_tec_it_training
 rename prim_sec enrolled_prim_secondary 

 // Remedy indicators coded to things other than 1 or 0.
replace enrolled_tec_it_training = 1 if enrolled_tec_it_training == 3
replace enrolled_tertiary = 1 if enrolled_tertiary == 4
// drop enrolled_targ_training

// Replace missings with 0s

foreach var in OT_placement Tax_year_total_income emergency_housing corrections_experience ///
				T2Ben_40 T2Ben_44 T2Ben_64 T2Ben_65 T2Ben_340 T2Ben_344 T2Ben_425 T2Ben_450 T2Ben_460 T2Ben_471 T2Ben_472 T2Ben_473 T2Ben_474 T2Ben_500 T2Ben_833 T2Ben_835 T2Ben_836 T2Ben_838 T2Ben_Any_indicator ///
				T1Ben_20 T1Ben_30 T1Ben_180 T1Ben_181 T1Ben_313 T1Ben_320 T1Ben_365 T1Ben_370 T1Ben_603 T1Ben_607 T1Ben_611 T1Ben_675  T1Ben_Any_indicator ///
				full_or_restricted_license GP_contacts ///
				enrolled_prim_secondary  enrolled_tec_it_training enrolled_tertiary ///
				offender_2020 offender_2021 victimisation_2020 victimisation_2021 ///
				PHO_enrolment chips	Current_HNZ_tenant_Dec21 Craig_sole_parent_ind moh_disability_funded serious_mental_health residential_type_ind dv_washing dv_comt dv_walking dv_remembering dv_seeing dv_hearing dv_disability  ASD_Indicator_1 ID_Indicator {
		 replace `var' = 0 if `var' == .
		
}



 

// Recode income into categories
 replace Tax_year_total_income = round(Tax_year_total_income, 1)
 replace Tax_year_total_income = . if Tax_year_total_income >= 99999999
 recode Tax_year_total_income -9999999/-1=1 0/0=2 1/15000=3 15001/30000=4 30001/60000=5 60001/90000=6 90001/120000=7 120001/180000=8 180001/99999999=9 , generate(tax_inc_cats)
 capture label define incgroup2 1 "Loss" 2 "Zero income" 3 "$1-$15,000" 4 "$15,001-$30,000" 5 "$30,001-$60,000" 6 "$60,001-$90,000" 7 "$90,001-$120,000" 8 "$120,001-$180,000" 9 "$180,000+"
 label values tax_inc_cats incgroup2
 
decode tax_inc_cats , generate(tax_inc_A2020toM2021_cats)	
 
 
// Generate police interaction indicator for 2020 and 2021 combined 
 gen Police_int_2020or2021 = 0
 replace Police_int_2020or2021 = 1 if offender_2020 == 1 | offender_2021 == 1 | victimisation_2020 == 1 | victimisation_2021 == 1
  
 // Combine police interation years
gen Victimisation_2020_2021 = (victimisation_2020 == 1 | victimisation_2021 == 1)
gen Offender_2020_2021 = (offender_2020 == 1 | offender_2021 == 1)

 
// Merge on geographic variables using Meshblock.
  mmerge Meshblock using "${MData}Current_geo.dta", unm(master) umatch(mb2018_v1_00) ukeep(sa12018_v1_00 sa22018_v1_00 sa22018_v1_00_name iur2018_v1_00 iur2018_v1_00_name regc2018_v1_00 regc2018_v1_00_name ta2018_v1_00 ta2018_v1_00_name dhb2015_v1_00 dhb2015_v1_00_name sa12018_v1_00_name)
  mmerge sa12018_v1_00 using "${MData}GCH_SA1_conc.dta", unm(master) umatch(sa1_2018) 
  mmerge Meshblock using "${MData}NZDEP.dta", unm(master) umatch(mb2018_code) ukeep(nzdep2018)

rename Māorimedium maorimedium

// Employed spells
// gen pct_neet_since_Jan2020 = NEET/637
// recode pct_neet_since_Jan2020 0/0.24999999=1    0.25/0.49999999=2   0.5/0.74999999999 = 3 0.75/1=4 , generate(dec_neet_since_Jan2020)
// capture label define dec_labels 1 "0 to 25 percent" 2 "25 to 50 percent" 3 "50 to 75 percent" 4 "75 to 100 percent" 
// label values dec_neet_since_Jan2020 dec_labels

// gen pct_emplyd_btwn_Jan20_Mar21 = Employed_spell/456
// recode pct_emplyd_btwn_Jan20_Mar21 0/0.24999999=1    0.25/0.49999999=2   0.5/0.74999999999 = 3 0.75/1=4 , generate(qrtls_emplyd_btwn_Jan20_Mar21)
// capture label define qrt_labels 1 "0 to 25 percent" 2 "25 to 50 percent" 3 "50 to 75 percent" 4 "75 to 100 percent" 
// label values qrtls_emplyd_btwn_Jan20_Mar21 qrt_labels
// tab qrtls_emplyd_btwn_Jan20_Mar21
//
// decode qrtls_emplyd_btwn_Jan20_Mar21 , generate(qrtiles_pct_time_emplyd_Jan20)

	
************************************************************************************************************************************************************************************************************************************************	

     
***********************************************
********* VACCINATION STATUS CREATION *********

/*
gen Dose_1_date = mdy(Dose_1_Month, Dose_1_Day, Dose_1_Year)
gen Dose_2_date = mdy(Dose_2_Month, Dose_2_Day, Dose_2_Year)
gen Dose_3_date = mdy(Dose_3_Month, Dose_3_Day, Dose_3_Year)
gen Dose_4_date = mdy(Dose_4_Month, Dose_4_Day, Dose_4_Year)
gen Dose_5_date = mdy(Dose_5_Month, Dose_5_Day, Dose_5_Year)
format Dose_1_date %dD_m_Y
format Dose_2_date %dD_m_Y
format Dose_3_date %dD_m_Y
format Dose_4_date %dD_m_Y
format Dose_5_date %dD_m_Y


*** V1 of indicator
gen CIR_Ind_v1_0_wk_ago = "No doses observed"
replace CIR_Ind_v1_0_wk_ago = "Two or more doses observed" if Dose_2_date ~= . | Dose_3_date ~= . | Dose_4_date ~= . | Dose_5_date ~= .
replace CIR_Ind_v1_0_wk_ago = "One dose observed"  if (Dose_2_date == . & Dose_3_date == . & Dose_4_date == . & Dose_5_date == .) & Dose_1_date ~=.


foreach week of numlist 1/23 {
		gen CIR_Ind_v1_`week'_wk_ago = CIR_Ind_v1_0_wk_ago
		replace CIR_Ind_v1_`week'_wk_ago = "One dose observed" if Dose_2_date >= (tmp_date_wk_`week' +1) & Dose_1_date ~= . 
		replace CIR_Ind_v1_`week'_wk_ago = "One dose observed" if Dose_3_date >= (tmp_date_wk_`week' +1) & Dose_1_date ~= . & Dose_2_date == . 
		replace CIR_Ind_v1_`week'_wk_ago = "One dose observed" if Dose_4_date >= (tmp_date_wk_`week' +1) & Dose_1_date ~= . & Dose_3_date == . & Dose_2_date == . 
		replace CIR_Ind_v1_`week'_wk_ago = "One dose observed" if Dose_5_date >= (tmp_date_wk_`week' +1) & Dose_1_date ~= . & Dose_4_date == . & Dose_3_date == . & Dose_2_date == . 
		replace CIR_Ind_v1_`week'_wk_ago = "No doses observed" if (Dose_1_date >= (tmp_date_wk_`week' +1) & Dose_1_date ~= .) | (Dose_1_date == . & Dose_2_date >= (tmp_date_wk_`week' +1)) | (Dose_1_date == . & Dose_2_date == . & Dose_3_date >= (tmp_date_wk_`week' +1)) | (Dose_1_date == . & Dose_2_date == . & Dose_3_date == . & Dose_4_date >= (tmp_date_wk_`week' +1)) | (Dose_1_date == . & Dose_2_date == . & Dose_3_date == . & Dose_4_date == . & Dose_5_date >= (tmp_date_wk_`week' +1))
}	 



*/


** Tidy up dataset and create collaboration file.
//
// use "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\temp_save2_${new_CIR_data_date}.dta" , clear
// mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\\$CIR_activity_table_doses_count.dta", unm(master)
// replace doses_count = 0 if doses_count == .


mmerge snz_uid using "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\\CIR_activity_table_doses_count_timeseries_combined.dta", unm(master) 
foreach var in dose_count_tot_0 dose_count_tot_1 dose_count_tot_2 dose_count_tot_3 dose_count_tot_4 dose_count_tot_5 dose_count_tot_6 dose_count_tot_7 dose_count_tot_8 dose_count_tot_9 dose_count_tot_10 dose_count_tot_11 dose_count_tot_12 dose_count_tot_13 dose_count_tot_14 dose_count_tot_15 dose_count_tot_16 dose_count_tot_17 dose_count_tot_18 dose_count_tot_19 dose_count_tot_20 dose_count_tot_21 dose_count_tot_22 dose_count_tot_23 dose_count_tot_24 dose_count_tot_25 dose_count_tot_26 dose_count_tot_27 dose_count_tot_28 dose_count_tot_29 dose_count_tot_30 dose_count_tot_31 dose_count_tot_32 dose_count_tot_33 dose_count_tot_34 dose_count_tot_35 dose_count_tot_36 dose_count_tot_37 dose_count_tot_38 dose_count_tot_39 dose_count_tot_40 dose_count_tot_41 dose_count_tot_42 dose_count_tot_43 dose_count_tot_44 dose_count_tot_45 dose_count_tot_46 dose_count_tot_47 dose_count_tot_48 dose_count_tot_49 dose_count_tot_50 dose_count_tot_51 dose_count_tot_52 dose_count_tot_53 dose_count_tot_54 dose_count_tot_55 dose_count_tot_56 dose_count_tot_57 dose_count_tot_58 dose_count_tot_59 {
	replace `var' = 0 if `var' == .
}


replace CIR_DHB_of_service = "AUCKLAND" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Auckland"
replace CIR_DHB_of_service = "BAY OF PLENTY" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Bay of Plenty"
replace CIR_DHB_of_service = "CANTERBURY" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Canterbury"
replace CIR_DHB_of_service = "CAPITAL AND COAST" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Capital and Coast"
replace CIR_DHB_of_service = "COUNTIES MANUKAU" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Counties Manukau"
replace CIR_DHB_of_service = "HAWKE'S BAY" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Hawke's Bay"
replace CIR_DHB_of_service = "HUTT" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Hutt Valley"
replace CIR_DHB_of_service = "LAKES" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Lakes"
replace CIR_DHB_of_service = "MIDCENTRAL" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "MidCentral"
replace CIR_DHB_of_service = "NELSON MARLBOROUGH" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Nelson Marlborough"
replace CIR_DHB_of_service = "NORTHLAND" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Northland"
replace CIR_DHB_of_service = "SOUTH CANTERBURY" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "South Canterbury"
replace CIR_DHB_of_service = "SOUTHERN" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Southern"
replace CIR_DHB_of_service = "TAIRAWHITI" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Tairawhiti"
replace CIR_DHB_of_service = "TARANAKI" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Taranaki"
replace CIR_DHB_of_service = "WAIKATO" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Waikato"
replace CIR_DHB_of_service = "WAIRARAPA" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Wairarapa"
replace CIR_DHB_of_service = "WAITEMATA" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Waitemata"
replace CIR_DHB_of_service = "WEST COAST" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "West Coast"
replace CIR_DHB_of_service = "WHANGANUI" if CIR_DHB_of_service=="" & dhb2015_v1_00_name == "Whanganui"

rename CIR_DHB_of_service DHB





keep snz_uid ASD_Indicator_1  Birth_month Birth_year  CIR_sequence_group COB_COC Current_HNZ_tenant_Dec21 Decile DHB EducationRegion  Enrolled_student GP_contacts ID_Indicator MOH_age_cats MOH_age_grp Meshblock OT_placement Occupation_Cen2018 Offender_2020_2021 PHO_enrolment Police_int_2020or2021 Qual_lvl_0 Qual_lvl_1 Qual_lvl_2 Qual_lvl_3 Qual_lvl_4_to_6 Qual_lvl_7_plus SchoolType Sex T1Ben_* T2Ben_*   Tax_year_total_income    tertiary_provider_code tec_it_provider_code  Victimisation_2020_2021  address_register_uid age* chips corrections_experience   date_of_interest2   dob dv_comt dv_disability  dv_hearing dv_remembering dv_seeing  dv_walking dv_washing emergency_housing enrolled_prim_secondary enrolled_tec_it_training enrolled_tertiary  floor_age full_or_restricted_license gch hhn highest_qualification iur2018_v1_00 iur2018_v1_00_name   maorimedium  moh_disability_funded  nzdep2018 offender_2020 offender_2021 ors  prim_sec_provider_code   regc2018_v1_00 regc2018_v1_00_name residential_type_ind sa12018_v1_00 sa12018_v1_00_name sa22018_v1_00 sa22018_v1_00_name   snz_ethnicity_grp1_nbr snz_ethnicity_grp2_nbr snz_ethnicity_grp3_nbr snz_ethnicity_grp4_nbr snz_ethnicity_grp5_nbr snz_ethnicity_grp6_nbr  ta2018_v1_00 ta2018_v1_00_name tax_inc_A2020toM2021_cats  tmp_date_wk_* victimisation_2020 victimisation_2021  dose_count_tot_* serious_mental_health

/// serious_mental_health

order snz_uid ASD_Indicator_1  Birth_month Birth_year  CIR_sequence_group COB_COC Current_HNZ_tenant_Dec21 Decile DHB EducationRegion  Enrolled_student GP_contacts ID_Indicator MOH_age_cats MOH_age_grp Meshblock OT_placement Occupation_Cen2018 Offender_2020_2021 PHO_enrolment Police_int_2020or2021 Qual_lvl_0 Qual_lvl_1 Qual_lvl_2 Qual_lvl_3 Qual_lvl_4_to_6 Qual_lvl_7_plus SchoolType Sex T1Ben_* T2Ben_*   Tax_year_total_income    tertiary_provider_code tec_it_provider_code  Victimisation_2020_2021  address_register_uid age* chips corrections_experience   date_of_interest2   dob dv_comt dv_disability  dv_hearing dv_remembering dv_seeing  dv_walking dv_washing emergency_housing enrolled_prim_secondary enrolled_tec_it_training enrolled_tertiary  floor_age full_or_restricted_license gch hhn highest_qualification iur2018_v1_00 iur2018_v1_00_name   maorimedium  moh_disability_funded  nzdep2018 offender_2020 offender_2021 ors  prim_sec_provider_code   regc2018_v1_00 regc2018_v1_00_name residential_type_ind sa12018_v1_00 sa12018_v1_00_name sa22018_v1_00 sa22018_v1_00_name   snz_ethnicity_grp1_nbr snz_ethnicity_grp2_nbr snz_ethnicity_grp3_nbr snz_ethnicity_grp4_nbr snz_ethnicity_grp5_nbr snz_ethnicity_grp6_nbr  ta2018_v1_00 ta2018_v1_00_name tax_inc_A2020toM2021_cats  tmp_date_wk_* victimisation_2020 victimisation_2021  dose_count_tot_* serious_mental_health


save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\temp_save2_${new_CIR_data_date}.dta" , replace






global descriptives_dataset_${new_CIR_data_date} "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\temp_save2_${new_CIR_data_date}.dta"

***********************************************
***********************************************

use "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\temp_save2_${new_CIR_data_date}.dta" , clear



preserve 
keep if _n <= 10
export delimited using "I:\MAA2021-49\Cross-agency collaboration\Dataset creation\upload csv to sql\CIR_${new_CIR_data_date}_collab_dataset_${date_today}_sample.csv", replace 
restore
export delimited using "I:\MAA2021-49\Cross-agency collaboration\Dataset creation\upload csv to sql\CIR_${new_CIR_data_date}_collab_dataset_${date_today}.csv",replace 
//

