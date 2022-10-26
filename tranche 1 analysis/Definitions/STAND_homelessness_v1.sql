/****** Script for SelectTopNRows command from SSMS  ******/
--PURPOSE: flag homeless for week of 202 June 30 to 2020 July 6
--DATE: 1/3/2022
--Author: C Wright


--VERSION: 1.0
--CHANGES:
--

--based on population at 2020 June 30
--n = NOT RELEASED
--category 1 homeless : n = NOT RELEASED
--window for homelessness June 30 to July 6 - 1 week

--NOTE: if the indciator is built for an earlier date then there will be greater capture, eg ACM and PRIMHD SCR could be included

--NOTE: The indicator is unlikely to include homelessness realting to inadequcy and sharing
--Although it is possible to augment it to include both of these where data is avaiable


--SOURCES: 
--1. Y address table and occupant address type
--2. Y HNZ applicant address type - homeless or inadequate prior to social housing entry
--3. X ACM address type - out of date - if updated could be used but only for Auckland region
--4. Y MSD emergency housing - link to partner and child - not sure I have coded this correctly
--5. X PRIHMD accomodation secondary consumer record - out of date - SCR codes in adhoc schema
--6. ? hospital discharge - homeless or inadequate - low count - maybe widen date window
--7. N NNPAC - mental health purchase unit for housing provision during treamtenet - don't seem to be any reported volumes
--8. X PRIMHD ICD10 diagnoses - homeless or inadequate - low count - out of date
--9. X Interrai - small counts - about housing quality only

--OPTIONS to improve method:
--expand date window to more than a week - capture more people with some kind of homelessness for parrt of the period
--get PRIMHD SCR data updated - capture MHA clients that are homeless
--get ACM data updated - capture ACM homeless clients
--write code to indentify families living with another family in the same dwelling, where for example the house is overcrowded

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--NOTE: this indicator is built mainly off the address type classification table
--this maps [snz_idi_address_register_uid] to address type
select * from [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_OCCDWELTYPE] as b
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

--METHOD
--A. create resident population as at 2020 30 June
	  select * 
	  into #pop
	  from [IDI_Clean_20211020].[data].[snz_res_pop] where year([srp_ref_date])=2020 


drop table #pop_2020

SELECT [link_set_key]
      ,a.[snz_uid]
      ,[snz_sex_gender_code]
      ,[snz_sex_gender_source_code]
      ,[snz_birth_year_nbr]
      ,[snz_birth_month_nbr]
      ,[snz_birth_date_proxy]
      ,[snz_birth_date_source_code]
      ,[snz_ethnicity_grp1_nbr]
      ,[snz_ethnicity_grp2_nbr]
      ,[snz_ethnicity_grp3_nbr]
      ,[snz_ethnicity_grp4_nbr]
      ,[snz_ethnicity_grp5_nbr]
      ,[snz_ethnicity_grp6_nbr]
      ,[snz_ethnicity_source_code]
      ,[snz_deceased_year_nbr]
      ,[snz_deceased_month_nbr]
      ,[snz_deceased_date_source_code]
      ,[snz_parent1_uid]
      ,[snz_parent2_uid]
      ,[snz_person_ind]
      ,[snz_spine_ind]
	  ,b.[srp_ref_date]
	  into #pop_2020
  FROM [IDI_Clean_20211020].[data].[personal_detail] as a , #pop as b
  where a.snz_uid=b.snz_uid
      

	  --find address in address table
	  drop table #add_2020

	  SELECT a.[snz_uid]
      ,[ant_notification_date]
      ,[ant_replacement_date]
      ,[snz_idi_address_register_uid]
      ,[ant_post_code]
      ,[ant_region_code]
      ,[ant_ta_code]
      ,[ant_meshblock_code]
      ,[ant_supporting_address_source_codes]
      ,[ant_address_source_code]
	  into #add_2020
  FROM [IDI_Clean_20211020].[data].[address_notification] as a,#pop_2020 as b
  where [ant_notification_date]<=datefromparts(2021,1,1) and [ant_replacement_date]>=datefromparts(2020,1,1) and a.snz_uid=b.snz_uid



  drop table #add_2020a

	  SELECT a.*
      ,[snz_idi_address_register_uid]
      ,[ant_region_code]
      ,[ant_ta_code]
      ,[ant_meshblock_code]
	  into #add_2020a
  FROM #pop_2020  as a left join #add_2020 as b
  on a.snz_uid=b.snz_uid


  --create address type table ie motel, campground, residential institution, hospital etc
  drop table #add_type

  SELECT distinct
      [cen_dwl_record_type_code]
      ,[cen_dwl_type_code]
      --,[cen_dwl_type_code_impt_ind]
      ,[snz_idi_address_register_uid]
	  into #add_type
  FROM [IDI_Clean_20211020].[cen_clean].[census_dwelling_2018]


  select  * from [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_OCCDWELTYPE]

  select * from #add_type

  drop table #add_type_2

  select distinct a.*,b.[descriptor_text]
  into #add_type_2
  from #add_type as a left join [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_OCCDWELTYPE] as b
  on a.cen_dwl_type_code=b.cat_code
  
  drop table #add_2020b

  select a.*,b.[descriptor_text],b.cen_dwl_record_type_code,b.cen_dwl_type_code
  into #add_2020b
  from #add_2020a as a left join #add_type_2 as b
   on a.snz_idi_address_register_uid=b.snz_idi_address_register_uid


   select distinct snz_uid from #add_2020b
   where [descriptor_text] in ('Roofless or Rough Sleeper','Motor Camp/Camping Ground','Night Shelter','Improvised Dwelling or Shelter',
   'Mobile Dwelling Not in a Motor Camp','Boarding House','Homeless','Dwelling in a Motor Camp','Marae Complex','Hotel, Motel or Guest Accommodation')


--create MSD emergency housing (people put up in motels by MSD) - motels are classified as homelessness
--find primary applicant for EH then add partner and children
--NB apears mostly sole parents and single people


--4. msd emergency housing
  
  drop table #msd_eh

  --primary applicant
  select distinct a.snz_uid,a.[msd_tte_app_date],b.payment_reason_lvl1,b.payment_reason_lvl2
  into #msd_eh
  FROM (select * from [IDI_Clean_20211020].[msd_clean].[msd_third_tier_expenditure] where [msd_tte_pmt_rsn_type_code] in ('855')
  and [msd_tte_app_date]>=datefromparts(2020,1,1) and [msd_tte_app_date]<=datefromparts(2020,2,1)
  ) as a left join [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_pay_reason] as b
  on a.msd_tte_pmt_rsn_type_code=b.payrsn_code

  --and [msd_tte_app_date]>=datefromparts(2021,3,1)

  --partner
	  drop table #msd_eh_part

	  SELECT distinct a.[snz_uid]
      ,[partner_snz_uid]
	  ,[msd_tte_app_date]
	  into #msd_eh_part
  FROM [IDI_Clean_20211020].[msd_clean].[msd_partner] as a , #msd_eh as b
  where a.snz_uid=b.snz_uid and [msd_ptnr_ptnr_from_date]<=[msd_tte_app_date] and [msd_ptnr_ptnr_to_date]>=[msd_tte_app_date]

  --children
  drop table #msd_eh_child
    SELECT distinct a.[snz_uid]
      ,[child_snz_uid]
	  ,[msd_tte_app_date]
	  into #msd_eh_child
  FROM [IDI_Clean_20211020].[msd_clean].[msd_child] as a , #msd_eh as b
  where a.snz_uid=b.snz_uid and [msd_chld_child_from_date]<=[msd_tte_app_date] and [msd_chld_child_to_date]>=[msd_tte_app_date]

  --unique ist of EH users
  select distinct snz_uid,1 as eh
  into #eh
  from (
  select partner_snz_uid as  snz_uid from #msd_eh_part
  UNION ALL
  select child_snz_uid as snz_uid from #msd_eh_child
  UNION ALL
  select distinct snz_uid from #msd_eh
) as a



--descriptions for pay reasons
  SELECT TOP (1000) [payrsn_code]
      ,[payment_reason_lvl1]
      ,[payment_reason_lvl2]
  FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_pay_reason]
  order by [payrsn_code]



   --add emergency housing flag
   drop table #add_2020c
   select a.*,b.eh
  into #add_2020c
  from #add_2020b as a left join #eh as b
   on a.snz_uid=b.snz_uid


   --add social housing applicants hosuing status at application
   --keep homeless, inadequate and unsuitable
   --NB could include other categories for this group
   --NB applicanats have address UIDS on their applications -  have opted for straight coding of homeless or inadequate but these could also be coded to
   --application address as well, maybe this would give more detail around address type

   --HNZ housing at application
  drop table #hnz

  SELECT b.[snz_uid]
      ,[hnz_na_date_of_application_date]
      --,[snz_application_uid]
      --,[snz_legacy_application_uid]
      ,a.[snz_msd_application_uid]
      --,[snz_msd_uid]
      --,[legacy_snz_msd_uid]
      --,[hnz_na_analy_score_afford_text]
      --,[hnz_na_analy_score_adeq_text]
      --,[hnz_na_analy_score_suitably_text]
      --,[hnz_na_analy_score_sustain_text]
      --,[hnz_na_analy_score_access_text]
      --,[hnz_na_analysis_total_score_text]
      ,[hnz_na_main_reason_app_text]
      --,[hnz_na_hshd_size_nbr]
      --,[hnz_na_stated_location_pref_text]
      --,[hnz_na_bedroom_required_cnt_nbr]
      --,[hnz_na_no_particular_pref_text]
      --,[hnz_na_hshd_type_text]
      ,[snz_idi_address_register_uid]
      --,[hnz_na_region_code]
      --,[hnz_na_ta_code]
      --,[hnz_na_meshblock_code]
      --,[hnz_na_meshblock_imputed_ind]
  into #hnz
  FROM [IDI_Clean_20211020].[hnz_clean].[new_applications] as a,[IDI_Clean_20211020].[hnz_clean].[new_applications_household] as b
  where a.snz_msd_application_uid=b.snz_msd_application_uid and cast([hnz_na_date_of_application_date] as date)  >=datefromparts(2020,6,30) and 
  cast ([hnz_na_date_of_application_date] as date)  <=datefromparts(2020,7,6) and
  [hnz_na_main_reason_app_text] in ('HOMELESSNESS','CURRENT ACCOMMODATION IS INADEQUATE OR UNSUITABLE','INADEQUATE',
  'UNSUITABLE')


  drop table #hnz_homeless
  drop table #hnz_inadequate

  select distinct snz_uid,1 as homeless
  into #hnz_homeless
  from #hnz
  where [hnz_na_main_reason_app_text] in ('HOMELESSNESS')

  
  select distinct snz_uid,1 as inadequate
  into #hnz_inadequate
  from #hnz
  where [hnz_na_main_reason_app_text] in ('CURRENT ACCOMMODATION IS INADEQUATE OR UNSUITABLE','INADEQUATE',
  'UNSUITABLE')



   --add homelessness and inadequacy
   drop table #add_2020d
   select a.*,b.inadequate ,c.homeless
  into #add_2020d
  from #add_2020c as a 
  left join #hnz_inadequate as b on a.snz_uid=b.snz_uid
  left join #hnz_homeless as c on a.snz_uid=c.snz_uid


  --final homelessness address table 2020 June 30 
  select * from #add_2020d


  --create count sumary by type of homelessness

  select * from (
   select case when homeless=1 then 'Homeless' when eh=1 then 'Hotel, Motel or Guest Accommodation' else [descriptor_text] end as description ,case when inadequate=1 then 'Inadequate' else 'Adequate' end as quality,count(*) as rows
   from #add_2020d
   group by case when homeless=1 then 'Homeless'  when eh=1 then 'Hotel, Motel or Guest Accommodation' else [descriptor_text] end,case when inadequate=1 then 'Inadequate' else 'Adequate' end
   ) as a
   where quality='Inadequate' or description in ('Roofless or Rough Sleeper','Motor Camp/Camping Ground','Night Shelter','Improvised Dwelling or Shelter',
   'Mobile Dwelling Not in a Motor Camp','Boarding House','Homeless','Dwelling in a Motor Camp','Marae Complex','Hotel, Motel or Guest Accommodation')

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--additional options for out of date or low count data sources

  --ACM homelessness - not up to date - only auckland -low counts

  SELECT [snz_uid]
      ,[snz_acm_uid]
      ,[snz_unique_nbr]
      ,[acm_has_housing_status_code]
      ,[acm_has_pays_rent_to_code]
      ,[acm_has_bedrooms_nbr]
      ,[acm_has_weekly_rental_amt]
      ,[acm_has_accom_supp_ind]
      ,[acm_has_spec_needs_aware_ind]
      ,[acm_has_budget_advice_aware_ind]
      ,[acm_has_food_parcel_prev_ind]
      ,[acm_has_entered_date]
      ,[acm_has_HNZ_app_ind]
  FROM [IDI_Clean_20211020].[acm_clean].[acm_housing]
  where 
  [acm_has_entered_date]>=datefromparts(2015,6,30) and [acm_has_entered_date]<=datefromparts(2015,7,6) and   
  [acm_has_housing_status_code] in (
--'OWNS HOME',
'COUCH SURFING',
'CAR',
--'FLATTING',
--'REST HOME',
'CARAVAN',
'HOMELESS',
--'NULL',
'NIGHT SHELTER',
'LIVE WITH RELATIVES',
--'BOARDING',
--'RENTS HOME',
'EMERGENCY ACCOMMODATION',
'GARAGE',
'ROUGH SLEEPING'
)

  SELECT TOP (1000) [snz_uid]
      ,[snz_acm_uid]
      ,[snz_unique_nbr]
      ,[member_snz_uid]
      ,[member_snz_acm_uid]
      ,[acm_hhm_relationship_code]
      ,[acm_snz_sex_code]
      ,[acm_hhm_birth_month_nbr]
      ,[acm_hhm_birth_year_nbr]
      ,[acm_hhm_entered_date]
      ,[acm_hhm_child_perm_care_ind]
      ,[acm_hhm_child_part_care_ind]
  FROM [IDI_Clean_20211020].[acm_clean].[acm_household]




  SELECT       distinct [acm_has_housing_status_code]

  FROM [IDI_Clean_20211020].[acm_clean].[acm_housing]

  where [acm_has_housing_status_code] in (
--'OWNS HOME',
'COUCH SURFING',
'CAR',
--'FLATTING',
--'REST HOME',
'CARAVAN',
'HOMELESS',
--'NULL',
'NIGHT SHELTER',
'LIVE WITH RELATIVES',
--'BOARDING',
--'RENTS HOME',
'EMERGENCY ACCOMMODATION',
'GARAGE',
'ROUGH SLEEPING'
)

--private hospital
--private hospital discharge - no events!

	SELECT a.[snz_uid]
	,'PRI' as source
      ,cast([moh_pri_evt_start_date] as date) as date
	  ,[moh_pri_diag_sub_sys_code] as code_sys_1
	  ,[moh_pri_diag_diag_type_code] as code_sys_2
      ,[moh_pri_diag_clinic_code] as code
      --,[moh_pri_diag_op_ac_date]
	  	  ,0 as value
  FROM (select * from [IDI_Clean_20210720].[moh_clean].[priv_fund_hosp_discharges_event]) as a,[IDI_Clean_20210720].[moh_clean].[priv_fund_hosp_discharges_diag] as b
  where a.[moh_pri_evt_event_id_nbr]=b.[moh_pri_diag_event_id_nbr] and [moh_pri_diag_sub_sys_code]=[moh_pri_diag_clinic_sys_code]
  and substring([moh_pri_diag_clinic_code] ,1,4) in ('Z590','Z591')



--public hospital - homelessness low counts



SELECT b.[snz_uid]
	  ,'PUB' as source
--TOP (1000) [moh_dia_event_id_nbr]
--      ,[moh_dia_clinical_sys_code]
--      ,[moh_dia_submitted_system_code]
--      ,[moh_dia_diagnosis_type_code]
--      ,[moh_dia_diag_sequence_code]
	  ,case when [moh_dia_diagnosis_type_code] in ('E','O') and [moh_dia_op_date] is not null then [moh_dia_op_date]
	  else [moh_evt_evst_date] end as date
	  ,[moh_dia_submitted_system_code] as code_sys_1
	  ,[moh_dia_diagnosis_type_code] as code_sys_2
      ,[moh_dia_clinical_code] as code
	  ,1 as value
      --,[moh_dia_op_date]
      --,[moh_dia_op_flag_ind]
      --,[moh_dia_condition_onset_code]
      --,[snz_moh_uid]
      --,[moh_evt_event_id_nbr]
  FROM [IDI_Clean_20211020].[moh_clean].[pub_fund_hosp_discharges_diag] as a , [IDI_Clean_20211020].[moh_clean].[pub_fund_hosp_discharges_event] as b
  where [moh_dia_clinical_sys_code] = [moh_dia_submitted_system_code] and [moh_evt_event_id_nbr]=[moh_dia_event_id_nbr] and substring([moh_dia_clinical_code],1,4) in ('Z590','Z591')
  and [moh_evt_evst_date]<=datefromparts(2020,7,1) and [moh_evt_evst_date]>=datefromparts(2020,7,1)

--NNPAC no events!
  SELECT TOP (1000) [snz_uid]
      ,[snz_moh_uid]
      ,[snz_moh_evt_uid]
      ,[moh_nnp_accident_flag_code]
      ,[moh_nnp_attendence_code]
      ,[moh_nnp_event_type_code]
      ,[moh_nnp_event_end_type_code]
      ,[moh_nnp_hlth_prov_type_code]
      ,[moh_nnp_service_type_code]
      ,[moh_nnp_triage_level_code]
      ,[moh_nnp_agency_code]
      ,[moh_nnp_birth_month_nbr]
      ,[moh_nnp_birth_year_nbr]
      ,[moh_nnp_service_datetime]
      ,[moh_nnp_1st_contact_datetime]
      ,[moh_nnp_departure_datetime]
      ,[moh_nnp_event_end_datetime]
      ,[moh_nnp_presentation_datetime]
      ,[moh_nnp_end_date_submitted_ind]
      ,[moh_nnp_service_date]
      ,[moh_nnp_domicile_code]
      ,[moh_nnp_dhb_of_domicile_code]
      ,[moh_nnp_purchase_unit_code]
      ,[moh_nnp_facility_code]
      ,[moh_nnp_sex_snz_code]
      ,[moh_nnp_hlth_spc_code]
      ,[moh_nnp_idf_dhb_code]
      ,[moh_nnp_idf_dhb_source_code]
      ,[moh_nnp_location_code]
      ,[moh_nnp_purchaser_code]
      ,[moh_nnp_sent_dom_code]
      ,[moh_nnp_sent_dom_rating_code]
      ,[moh_nnp_volume_amt]
      ,[moh_nnp_unit_of_measure_key]
      ,[moh_nnp_eth_priority_grp_code]
      ,[moh_nnp_ethnic_snz_code]
      ,[moh_nnp_ethnic_grp1_snz_ind]
      ,[moh_nnp_ethnic_grp2_snz_ind]
      ,[moh_nnp_ethnic_grp3_snz_ind]
      ,[moh_nnp_ethnic_grp4_snz_ind]
      ,[moh_nnp_ethnic_grp5_snz_ind]
      ,[moh_nnp_ethnic_grp6_snz_ind]
  FROM [IDI_Clean_20211020].[moh_clean].[nnpac]

  --where [moh_nnp_service_date]>=datefromparts(2020,6,30) and [moh_nnp_service_date]<=datefromparts(2020,7,6) and
  where 
  --year([moh_nnp_service_date])=2020 and
  [moh_nnp_purchase_unit_code] in ('MHAD15D','MHAD15C','MHAD15')

  


  --interrai - low counts mostly around housing quality

  SELECT TOP (1000) [iCode]
      ,[IDI Variable Name]
      ,[9_1]
      ,[9_3]
      ,[Acceptable Values]
      ,[iCode_type]
      ,[Question]
      ,[Question_CA]
      ,[Question_HC]
      ,[Question_LTCF]
  FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_interrai_question_lookup]
  where [Question] like '%home%'

  SELECT TOP (1000) [iCode]
      ,[IDI Variable Name]
      ,[Answer_Code]
      ,[Answer]
  FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_interrai_answer_lookup]
  where [IDI Variable Name] like '%disrepair%' or [IDI Variable Name] like '%squalid%' or [IDI Variable Name] like '%cool%'
  or [IDI Variable Name] like '%safety%'

  where moh_irai_home_disrepair_ind=1 or 
  moh_irai_squalid_home_ind=1 or 
  moh_irai_inadeq_heat_cool_ind=1 or 
  moh_irai_lack_prsnl_safety_ind=1 ;

  /****** Script for SelectTopNRows command from SSMS  ******/
SELECT [snz_uid]
      ,[moh_irai_assessment_date]
      ,[moh_irai_assessment_type_text]
      ,[moh_irai_home_disrepair_ind]
      ,[moh_irai_squalid_home_ind]
      ,[moh_irai_inadeq_heat_cool_ind]
      ,[moh_irai_lack_prsnl_safety_ind]

  FROM [IDI_Clean_20211020].[moh_clean].[interrai]
  where (moh_irai_home_disrepair_ind='1' or 
  moh_irai_squalid_home_ind='1' or 
  moh_irai_inadeq_heat_cool_ind='1' or 
  moh_irai_lack_prsnl_safety_ind='1') and [moh_irai_assessment_date]>=datefromparts(2020,6,30)
  and [moh_irai_assessment_date]<=datefromparts(2020,7,6)


  --PRIMHD SCR - secondary consumer record - accomadation classifications
  --code 3 = homeless, temporary, unihabtable, sharing


  SELECT distinct [snz_moh_uid]
      ,[accommodation_code]
      --,[organisation_id]
      --,[referral_id]
      --,[team_code]
      --,[collection_code]
      --,[supplementary_consumer_rec_id]
      --,[unique_scr_id]
      --,[master_hcu_domicile_code]
      --,[master_hcu_dom_org_id]
      --,[ethnicgp]
      --,[dom_code_nhi]
      --,[priority_ethnic_code]
      --,[gender_nhi]
      --,[education_status_code]
      --,[employment_status_code]
      --,[wellness_plan_code]
      --,[dhb_dom_nhi]
  FROM [IDI_Adhoc].[clean_read_MOH_PRIMHD].[moh_primhd_scr]
  where year([collection_code])=2016 and [accommodation_code]=3
  and [collection_code]>=datefromparts(2016,6,30)
  and [collection_code]<=datefromparts(2016,7,6)

