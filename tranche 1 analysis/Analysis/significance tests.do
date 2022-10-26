
eststo clear

use "I:\MAA2021-55\wellbeing report - tranche 1\Data exploration\Intermediate_data\\Table_dataset.dta", clear

// Set up survey structure

svyset snz_uid [pweight=sqfinalwgt], vce(jackknife) jkrweight(sqfinalwgt_*)

// The waves we care about are:
* Q2: 2018 GSS
* Q3: Jun 2020 HLFS
* Q6: Mar 2021 HLFS

gen covid = .
replace covid = 0 if QRTR == "Q2"
replace covid = 1 if QRTR == "Q3"

gen q1_q4 = .
replace q1_q4 = 0 if QRTR == "Q3"
replace q1_q4 = 1 if QRTR == "Q6"

// Set up binary variables

gen ls_low=0
replace ls_low=. if LS_3cats=="NA"
replace ls_low=1 if LS_3cats=="Low"
gen fam_low=0
replace fam_low=. if FamWB_3cats=="NA"
replace fam_low=1 if FamWB_3cats=="Low"
gen inc=0
replace inc=. if EnghInc_cats=="NA"
replace inc=1 if EnghInc_cats=="Not enough or only just enough"
gen health=0
replace health=. if GenHealth_cats=="NA"
replace health=1 if GenHealth_cats=="Excellent or very good"
gen lonely=0
replace lonely=. if Lonely_cats=="NA"
replace lonely=1 if Lonely_cats=="None of the time"
gen discrim=0
replace discrim=. if discrim_cats=="NA"
replace discrim=1 if discrim_cats=="Discriminated against"
gen t_ppl=0
replace t_ppl=. if TrustPpl_cats=="NA"
replace t_ppl=1 if TrustPpl_cats=="0 to 4"
gen t_parl=0
replace t_parl=. if TrustParl_cats=="NA"
replace t_parl=1 if TrustParl_cats=="0 to 4"
gen t_pol=0
replace t_pol=. if TrustPol_cats=="NA"
replace t_pol=1 if TrustPol_cats=="0 to 4"
gen t_med=0
replace t_med=. if TrustMed_cats=="NA"
replace t_med=1 if TrustMed_cats=="0 to 4"
gen t_hlth=0
replace t_hlth=. if TrustHlth_cats=="NA"
replace t_hlth=1 if TrustHlth_cats=="0 to 4"
gen safety=0
replace safety=. if Safety_cats=="NA"
replace safety=1 if Safety_cats=="Safe or very safe"

// Set up short names of variables

gen smum=Solo_Mther_DC
gen sdad=Solo_Fther_DC
gen pmum=Prtnr_Mther_DC
gen pdad=Prtnr_Fther_DC
gen female=adult_female
gen male=adult_male
gen dis_18=Any_dis_18_to_39
gen dis_40=Any_dis_40_to_64
gen dis_65=Any_dis_65Plus
gen all=Any_NZer
gen all_18=Any_NZer_18_to_39
gen all_40=Any_NZer_40_to_64
gen all_65=Any_NZer_65Plus
gen maori=Maori_18to64
gen pacif=Pacific_18to64
gen other=Not_Maori_or_Pac_18to64


// Run tests of significance
* These are formatted as regressions because that's the easiest way to format outputs

foreach pop in smum pmum female sdad pdad male ///
dis_18 all_18 dis_40 all_40 dis_65 all_65 maori pacif other all {
	foreach period in covid q1_q4 {
		foreach var in SWB_LS SWB_LWW Fam_WB WHO5 ///
		ls_low fam_low inc health lonely discrim ///
		t_ppl t_parl t_pol t_med t_hlth safety {
			qui eststo `var'`period': svy: regress `var' `period' if `pop'==1
		}
	}
	di "`pop'"
	qui estout *, cells(p(fmt(3)))
	estout r(coefs, transpose)
}

* Same thing for Auckland only

foreach pop in smum pmum female sdad pdad male ///
dis_18 all_18 dis_40 all_40 dis_65 all_65 maori pacif other all {
	foreach period in covid q1_q4 {
		foreach var in SWB_LS SWB_LWW Fam_WB WHO5 safety ///
		ls_low fam_low inc health lonely discrim ///
		t_ppl t_parl t_pol t_med t_hlth safety {
			qui eststo `var'`period': svy: regress `var' `period' ///
			if `pop'==1 & Auckland==1
		}
	}
	di "Auckland `pop'"
	qui estout *, cells(p(fmt(3)))
	estout r(coefs, transpose)
}




