``````****** CODE TO IMPORT METADATA AND DEFINITIONS FOR COVID-19 VACCINATION PROJECT, THIS SCRIPT ALSO DOWNLOADS ADDITIONAL DATA NOT PROCESSED BY THE DATA ASSEMBLY TOOL.
**** Author: Shaan Badenhorst
**** Reviewer: Luke Scullion

**** Notes: The latter half of this script needs to be rerun with each refresh of the IDI.


// History (reverse order): 
// 2021-10-XX Draft QA'd (  )
// 2021-10-13 First draft started (SB)



// Outputs
* Stata .dta files to merge the classifications.

clear all
pause on

global MData "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\Metadata\"
global Outputs "I:\MAA2021-49\SWA_development\Main\Staging\Outputs\Descriptives\"

//run "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\mmerge.ado"
//
do "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\Phase_2/_0_Init.do"

import excel "${MData}benefit_codes_adhoc.xlsx", firstrow clear
keep if ValidTo >= mdy(01, 01, 2021)
drop if level4 == "NULL"
bysort serv: gen keep = 1 if _n == 1
keep if keep == 1
replace level4 = "Job Seeker related" if  serv == "675"
replace level4 = "Caring For Sick Or Infirm / Invalids" if  serv == "370"
bysort serv: gen count = _N 
save "${MData}benefit_codes_adhoc.dta", replace

import excel "${MData}COB_COC_Codes.xlsx", firstrow clear
save "${MData}COB_COC_Codes.dta", replace

import delimited "${MData}Rel_codes.csv",  clear
save "${MData}Rel_codes.dta", replace

import delimited "${MData}SA2.csv",  clear
save "${MData}SA2.dta", replace

import delimited "${MData}Eth_codes.csv",  clear
save "${MData}Eth_codes.dta", replace

import delimited "${MData}Inc_codes.csv",  clear
save "${MData}Inc_codes.dta", replace

import delimited "${MData}Qual_codes.csv",  clear
save "${MData}Qual_codes.dta", replace

import excel "${MData}School_directory.xlsx", firstrow clear
save "${MData}School_directory.dta", replace

import excel "${MData}Provider_region_metadata.xlsx", firstrow clear
save "${MData}Provider_region_metadata.dta", replace

import excel "${MData}Provider_metadata.xlsx", firstrow clear
save "${MData}Provider_metadata.dta", replace


import excel "${MData}MB2013_MB2018.xlsx", firstrow  clear
tostring *, replace
save "${MData}MB2013_MB2018.dta", replace

use "${MData}Provider_region_metadata.dta", clear
mmerge Meshblock2013 using "${MData}MB2013_MB2018.dta", unm(master) umatch(MB2013_code)
duplicates drop ProviderCode, force
drop _merge
destring *, replace
save "${MData}Provider_region_metadata.dta", replace

import delimited "${MData}Current_geo.csv",  clear
keep mb2018_v1_00 sa12018_v1_00 sa22018_v1_00 sa22018_v1_00_name iur2018_v1_00 iur2018_v1_00_name regc2018_v1_00 regc2018_v1_00_name ta2018_v1_00 ta2018_v1_00_name dhb2015_v1_00 dhb2015_v1_00_name sa12018_v1_00_name
save "${MData}Current_geo.dta", replace

import delimited "${MData}GCH_SA1_conc.csv",  clear
save "${MData}GCH_SA1_conc.dta", replace


import delimited "${MData}NZDEP.csv",  clear
save "${MData}NZDEP.dta", replace

import excel "${MData}Census_Occ.xlsx", firstrow clear
gen var = "Occupation_Cen2018"
tostring code, replace
save "${MData}Census_Occ.dta", replace

import excel "${MData}Country_codes.xlsx", firstrow clear
gen var = "COB_COC"
tostring Code, replace
save "${MData}Country_codes.dta", replace

import excel "${MData}ANZSIC06.xlsx", firstrow clear
replace cat_code = subinstr(cat_code, " ", "",.)
gen var = "Industry"
tostring cat_code, replace
save "${MData}ANZSIC06.dta", replace	

import delimited "${MData}MB2021_to_MB2018.csv",   clear
destring *, replace
save "${MData}MB2021_to_MB2018.dta", replace



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
  // Load the serious mental health data
// odbc load, bigint clear exec("select [snz_uid], [serious_mental_health] from [IDI_Sandpit].[DL-MAA2021-49].[cw_20211020_serious_MH_sml]") $IDISP_CONN
// duplicates drop snz_uid, force
// sort snz_uid
// save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\SMH_indicator.dta", replace
 
 

// // Load the CHIPS address data
// odbc load, bigint clear exec("select [snz_idi_address_register_uid], [chips] from [IDI_Sandpit].[DL-MAA2021-49].[cw_20211020_chips]") $IDISP_CONN
// // duplicates drop snz_uid, force
// save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\CHIPS.dta", replace

Load Craig's ethnicity variables from the personal details table
odbc load, bigint clear exec("select * from [IDI_Sandpit].[DL-MAA2021-49].[cw_202203_ethnic_code_v02_sml_clean]") $IDISP_CONN
duplicates drop snz_uid, force
sort snz_uid
save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\Craig_ethnicity_202203.dta", replace

// Load student variables 
odbc load, bigint clear exec("select * from [IDI_Sandpit].[DL-MAA2021-49].[cw_202203_study_20200701]") $IDISP_CONN
destring *, replace
duplicates drop snz_uid, force
mmerge prim_sec_provider_code using "${MData}School_directory.dta", unm(master) umatch(SchoolNumber) ukeep(SchoolType Māorimedium Decile EducationRegion)
mmerge tec_it_provider_code using "${MData}Provider_region_metadata.dta", unm(master) umatch(ProviderCode) ukeep(ProviderType MB2018_code  ) uname(TEC_IT_)
mmerge tertiary_provider_code using "${MData}Provider_region_metadata.dta", unm(master) umatch(ProviderCode) ukeep(ProviderType MB2018_code ) uname(Tertiary_)
mmerge Tertiary_MB2018_code using "${MData}Current_geo.dta", unm(master) umatch(mb2018_v1_00) ukeep(ta2018_v1_00 ta2018_v1_00_name ) uname(Tertiary_)
mmerge TEC_IT_MB2018_code using "${MData}Current_geo.dta", unm(master) umatch(mb2018_v1_00) ukeep(ta2018_v1_00 ta2018_v1_00_name ) uname(TEC_IT_)
duplicates drop snz_uid, force
sort snz_uid
drop _merge
save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\enrolment_data_202203.dta", replace

//
// // Load the disability data into the dataset
// odbc load, bigint clear exec("select * from [IDI_Sandpit].[DL-MAA2021-49].[cw_20211020_disability_v01_sml]") $IDISP_CONN
// duplicates drop snz_uid, force
// sort snz_uid
// save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\Disability_data.dta", replace

// 
//  // Load the v2 disability indicator
// odbc load, bigint clear exec("select [snz_uid], [dv_disability] from [IDI_Sandpit].[DL-MAA2021-49].[cw_20211020_disability_v02_sml]") $IDISP_CONN
// // duplicates drop snz_uid, force
// save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\Disability_v2.dta", replace

// Load the industry table 
// odbc load, bigint clear exec("select * from [IDI_Sandpit].[DL-MAA2021-49].[vacc_INDUSTRY_V2_20211020]") $IDISP_CONN
//
// save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\SQL_Industry.dta", replace
//
// 	drop anzsic06 ir_ems_pbn_nbr ir_ems_enterprise_nbr end_date
// 	duplicates drop snz_uid anzsic06, force
// 	gen Ind_3char_ = 1
//
// 	reshape wide Ind_3char_  , i(snz_uid) j(anzsic06_3char) string
// 	foreach ind in  Ind_3char_A01  Ind_3char_A02  Ind_3char_A03  Ind_3char_A04  Ind_3char_A05  Ind_3char_B06  Ind_3char_B07  Ind_3char_B08  Ind_3char_B09  Ind_3char_B10  Ind_3char_C11  Ind_3char_C12  Ind_3char_C13  Ind_3char_C14  Ind_3char_C15  Ind_3char_C16  Ind_3char_C17  Ind_3char_C18  Ind_3char_C19  Ind_3char_C20  Ind_3char_C21  Ind_3char_C22  Ind_3char_C23  Ind_3char_C24  Ind_3char_C25  Ind_3char_D26  Ind_3char_D27  Ind_3char_D28  Ind_3char_D29  Ind_3char_E30  Ind_3char_E31  Ind_3char_E32  Ind_3char_F33  Ind_3char_F34  Ind_3char_F35  Ind_3char_F36  Ind_3char_F37  Ind_3char_F38  Ind_3char_G39  Ind_3char_G40  Ind_3char_G41  Ind_3char_G42  Ind_3char_G43  Ind_3char_H44  Ind_3char_H45  Ind_3char_I46  Ind_3char_I47  Ind_3char_I48  Ind_3char_I49  Ind_3char_I50  Ind_3char_I51  Ind_3char_I52  Ind_3char_I53  Ind_3char_J54  Ind_3char_J55  Ind_3char_J56  Ind_3char_J57  Ind_3char_J58  Ind_3char_J59  Ind_3char_J60  Ind_3char_K62  Ind_3char_K63  Ind_3char_K64  Ind_3char_L66  Ind_3char_L67  Ind_3char_M69  Ind_3char_M70  Ind_3char_N72  Ind_3char_N73  Ind_3char_O75  Ind_3char_O76  Ind_3char_O77  Ind_3char_P80  Ind_3char_P81  Ind_3char_P82  Ind_3char_Q84  Ind_3char_Q85  Ind_3char_Q86  Ind_3char_Q87  Ind_3char_R89  Ind_3char_R90  Ind_3char_R91  Ind_3char_R92  Ind_3char_S94  Ind_3char_S95  Ind_3char_S96 {
// 		replace `ind' = 0 if `ind' == .
// 	}
// 	pause
// 	save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\Industry_3char.dta", replace

// Load the main benefits table 
odbc load, bigint clear exec("select * from [IDI_Sandpit].[DL-MAA2021-49].[vacc_main_benefit_final_202203]") $IDISP_CONN
destring msd_spel_servf_code, replace
drop if msd_spel_servf_code == .
drop if msd_spel_servf_code == 839
gen T1Ben_ = 1
keep snz_uid msd_spel_servf_code T1Ben_
duplicates drop snz_uid msd_spel_servf_code T1Ben_ , force
reshape wide T1Ben_ , i(snz_uid) j(msd_spel_servf_code) 
gen T1Ben_Any_indicator = 1
foreach ben in T1Ben_20 T1Ben_30 T1Ben_180 T1Ben_181 T1Ben_313 T1Ben_320 T1Ben_365 T1Ben_370 T1Ben_603 T1Ben_607 T1Ben_611 T1Ben_675  {
	replace `ben' = 0 if `ben' == .
}
save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\T1Bens_202203.dta", replace

// Load the second tier benefits table 
odbc load, bigint clear exec("select * from [IDI_Sandpit].[DL-MAA2021-49].[vacc_BENEFIT_RECEIPT_T2_202203]") $IDISP_CONN
keep snz_uid Code value
rename value T2Ben_
reshape wide T2Ben_ , i(snz_uid) j(Code) 
gen T2Ben_Any_indicator = 1
foreach ben in T2Ben_40 T2Ben_44 T2Ben_64 T2Ben_65 T2Ben_340 T2Ben_344 T2Ben_425 T2Ben_450 T2Ben_460 T2Ben_471 T2Ben_472 T2Ben_473 T2Ben_474 T2Ben_500 T2Ben_833 T2Ben_835 T2Ben_836 T2Ben_838 {
	replace `ben' = 0 if `ben' == .
}
save "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\dtas\T2Bens_202203.dta", replace

	



