
* Looking at ceasing of Winter Energy Payment
clear
import delimited "I:\MAA2021-55\wellbeing report - tranche 2\Analysis\aw_localreg_wep_2022-07-29.csv"

destring pwb_qfeelaboutlifescale, force replace
destring pwb_qfamwellbeing, force replace
encode mhs_qenoughincome, generate(enufinc_just)
recode enufinc_just (1 2 5=1) (4=0) (3=.)
encode mhs_qenoughincome, generate(enufinc_enuf)
recode enufinc_enuf (1 2=1) (4 5=0) (3=.)
gen wep_benefit=wep*any_benefit_receipt
gen high_lifesat = (pwb_qfeelaboutlifescale>=7)
gen high_famwb = (pwb_qfamwellbeing>=7)

* Local regression - all
regress enufinc_just wep##any_benefit_receipt c.relative_date##any_benefit_receipt i.day_of_week [pweight = sqfinalwgt] if relative_date>=-14 & relative_date<=13
regress enufinc_enuf wep##any_benefit_receipt c.relative_date##any_benefit_receipt i.day_of_week [pweight = sqfinalwgt] if relative_date>=-14 & relative_date<=13
regress pwb_qfeelaboutlifescale wep##any_benefit_receipt c.relative_date##any_benefit_receipt i.day_of_week [pweight = sqfinalwgt] if relative_date>=-14 & relative_date<=13
regress pwb_qfamwellbeing wep##any_benefit_receipt c.relative_date i.day_of_week [pweight = sqfinalwgt] if relative_date>=-14 & relative_date<=13

* Local regression - Under 65 only
regress enufinc_just wep##any_benefit_receipt c.relative_date##any_benefit_receipt i.day_of_week [pweight = sqfinalwgt] if over_65==0 & relative_date>=-14 & relative_date<=13
regress enufinc_enuf wep##any_benefit_receipt c.relative_date##any_benefit_receipt i.day_of_week [pweight = sqfinalwgt] if over_65==0 & relative_date>=-14 & relative_date<=13
regress pwb_qfeelaboutlifescale wep##any_benefit_receipt c.relative_date##any_benefit_receipt i.day_of_week [pweight = sqfinalwgt] if over_65==0 & relative_date>=-14 & relative_date<=13
regress pwb_qfamwellbeing wep##any_benefit_receipt c.relative_date i.day_of_week [pweight = sqfinalwgt] if over_65==0 & relative_date>=-14 & relative_date<=13

* Local regression - Comparing over/under 65
regress enufinc_just wep##over_65 c.relative_date##over_65 i.day_of_week [pweight = sqfinalwgt] if relative_date>=-14 & relative_date<=13
regress enufinc_enuf wep##over_65 c.relative_date##over_65 i.day_of_week [pweight = sqfinalwgt] if relative_date>=-14 & relative_date<=13
regress pwb_qfeelaboutlifescale wep##over_65 c.relative_date##over_65 i.day_of_week [pweight = sqfinalwgt] if relative_date>=-14 & relative_date<=13


* Looking at end of lockdown
clear
import delimited "I:\MAA2021-55\wellbeing report - tranche 2\Analysis\aw_localreg_lockdown_2022-07-29.csv"

destring pwb_qfeelaboutlifescale pwb_qfamwellbeing, replace force
gen high_lifesat = (pwb_qfeelaboutlifescale>=7)
gen high_famwb = (pwb_qfamwellbeing>=7)

* Checking if okay to combine lockdowns
regress pwb_qfeelaboutlifescale lockdown##auck_lockdown i.day_of_week [pweight = sqfinalwgt] if auckland==1 & over_65==0 & reldate_combined>=-7 & reldate_combined<=14
* Interaction between lockdown and auck_lockdown not significant, implying auckland people had a similar reaction to the second lockdown as the first, and okay to combine.

* Overall
regress pwb_qfeelaboutlifescale lockdown i.day_of_week [pweight = sqfinalwgt] if over_65==0 & reldate_combined>=-7 & reldate_combined<=14

* By age
regress pwb_qfeelaboutlifescale lockdown##over_65 i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14

* Sole mothers
regress enufinc_just lockdown##solo_mother_depchild i.day_of_week [pweight = sqfinalwgt] if over_65==0 & reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfeelaboutlifescale lockdown##solo_mother_depchild i.day_of_week [pweight = sqfinalwgt] if over_65==0 & reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##solo_mother_depchild i.day_of_week [pweight = sqfinalwgt] if over_65==0 & reldate_combined>=-7 & reldate_combined<=14

* Sole mothers compared to partnered mothers
regress enufinc_just lockdown##solo_mother_depchild i.day_of_week [pweight = sqfinalwgt] if over_65==0 & (solo_mother_depchild==1 | partnered_mother_depchild==1) & reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfeelaboutlifescale lockdown##solo_mother_depchild i.day_of_week [pweight = sqfinalwgt] if over_65==0 & (solo_mother_depchild==1 | partnered_mother_depchild==1) & reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##solo_mother_depchild i.day_of_week [pweight = sqfinalwgt] if over_65==0 & (solo_mother_depchild==1 | partnered_mother_depchild==1) & reldate_combined>=-7 & reldate_combined<=14

* People on benefit
regress enufinc_just lockdown##any_benefit_receipt i.day_of_week reldate_combined [pweight = sqfinalwgt] if over_65==0 & reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfeelaboutlifescale lockdown##any_benefit_receipt i.day_of_week [pweight = sqfinalwgt] if over_65==0 & reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##any_benefit_receipt i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14

* Maori people
regress pwb_qfeelaboutlifescale lockdown##ethmaori i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##ethmaori i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14
regress high_lifesat lockdown##ethmaori i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14
regress high_famwb lockdown##ethmaori i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14

* Pacific people
regress pwb_qfeelaboutlifescale lockdown##ethpacific i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##ethpacific i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14
regress high_lifesat lockdown##ethpacific i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14
regress high_famwb lockdown##ethpacific i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14

* People in Auckland
regress pwb_qfeelaboutlifescale lockdown##auckland i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##auckland i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14



* Looking at the start of lockdown - diff in diff
recode reldate_auck_start (-14 / -1 = 0) (0 / 13 = 1) (else = .), generate(lockdown_period)

* Overall
regress pwb_qfeelaboutlifescale lockdown_period##auckland i.day_of_week [pweight = sqfinalwgt] if reldate_auck_start>=-14 & reldate_auck_start<=13
regress pwb_qfamwellbeing lockdown_period##auckland i.day_of_week [pweight = sqfinalwgt] if reldate_auck_start>=-14 & reldate_auck_start<=13
regress enufinc_enuf lockdown_period##auckland i.day_of_week [pweight = sqfinalwgt] if reldate_auck_start>=-14 & reldate_auck_start<=13


* By age
regress pwb_qfeelaboutlifescale lockdown##over_65 i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14

* Sole mothers
regress pwb_qfeelaboutlifescale lockdown##solo_mother_depchild i.day_of_week [pweight = sqfinalwgt] if over_65==0 & reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##solo_mother_depchild i.day_of_week [pweight = sqfinalwgt] if over_65==0 & reldate_combined>=-7 & reldate_combined<=14
* Sole mothers compared to partnered mothers
regress pwb_qfeelaboutlifescale lockdown##solo_mother_depchild i.day_of_week [pweight = sqfinalwgt] if over_65==0 & (solo_mother_depchild==1 | partnered_mother_depchild==1) & reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##solo_mother_depchild i.day_of_week [pweight = sqfinalwgt] if over_65==0 & (solo_mother_depchild==1 | partnered_mother_depchild==1) & reldate_combined>=-7 & reldate_combined<=14

* People on benefit
regress pwb_qfeelaboutlifescale lockdown##any_benefit_receipt i.day_of_week [pweight = sqfinalwgt] if over_65==0 & reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##any_benefit_receipt i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14

* Maori people
regress pwb_qfeelaboutlifescale lockdown##ethmaori i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##ethmaori i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14

* Pacific people
regress pwb_qfeelaboutlifescale lockdown##ethpacific i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##ethpacific i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14

* People in Auckland
regress pwb_qfeelaboutlifescale lockdown##auckland i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14
regress pwb_qfamwellbeing lockdown##auckland i.day_of_week [pweight = sqfinalwgt] if reldate_combined>=-7 & reldate_combined<=14

