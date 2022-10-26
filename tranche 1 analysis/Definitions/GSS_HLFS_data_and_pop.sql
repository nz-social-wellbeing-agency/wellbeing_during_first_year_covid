/**************************************************************************************************


Author: Shaan Badenhorst
Date: April 2022

Datasets used:
-GSS
-HLFS
-Personal details table

Key output tables:
- [IDI_Sandpit].[DL-MAA2021-49].[WBR_GSS_2018_tables] identifies pre-covid-19 baseline wellbeing by providing data for descriptive statistics (phase one)
- [IDI_Sandpit].[DL-MAA2021-49].[] 
*/


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- GSS data collection and comparison population identification -------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_2016_2018_HH_table]
SELECT	a.[snz_uid]
		,[gss_hq_collection_code]
		,[snz_gss_hhld_uid]
		,[snz_gss_uid]
		,[snz_sex_gender_code]
		,[snz_birth_date_proxy]

		,case when [gss_hq_fam_parentrole_ind] = 'Y' and [gss_hq_fam_withpartner_ind] = 'Y' and [snz_sex_gender_code] = 2 and [gss_hq_fam_num_depchild_nbr] >= 1 then 1 else 0 end as partnered_mother_depchild
		,case when [gss_hq_fam_parentrole_ind] = 'Y' and [gss_hq_fam_withpartner_ind] = 'Y' and [snz_sex_gender_code] = 1 and [gss_hq_fam_num_depchild_nbr] >= 1 then 1 else 0 end as partnered_father_depchild
		,case when [gss_hq_fam_parentrole_ind] = 'Y' and [gss_hq_fam_withpartner_ind] = 'N' and [snz_sex_gender_code] = 2 and [gss_hq_fam_num_depchild_nbr] >= 1 then 1 else 0 end as solo_mother_depchild
		,case when [gss_hq_fam_parentrole_ind] = 'Y' and [gss_hq_fam_withpartner_ind] = 'N' and [snz_sex_gender_code] = 1 and [gss_hq_fam_num_depchild_nbr] >= 1 then 1 else 0 end as solo_father_depchild
		,case when [gss_hq_fam_parentrole_ind] = 'Y'  and [snz_sex_gender_code] = 1 and [gss_hq_fam_num_depchild_nbr] <= 0 then 1 else 0 end as other_father
		,case when [gss_hq_fam_parentrole_ind] = 'Y'  and [snz_sex_gender_code] = 2 and [gss_hq_fam_num_depchild_nbr] <= 0 then 1 else 0  end as other_mother
		,[gss_hq_age_dep_childyg_dev]
INTO [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_2016_2018_HH_table]
FROM [IDI_Clean_202203].[gss_clean].[gss_household] as a left join [IDI_Clean_202203].[data].[personal_detail] as b on a.snz_uid = b.snz_uid where [gss_hq_collection_code] = 'GSS2018' or [gss_hq_collection_code] = 'GSS2016' order by [snz_gss_hhld_uid]

DROP TABLE [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_2016_2018_tables]
SELECT a.[snz_uid]
		,[snz_sex_gender_code]
		,[gss_pq_collection_code]
		,datediff(year,[snz_birth_date_proxy],[gss_pq_PQinterview_date])  as age 
	  ,partnered_mother_depchild
	  ,partnered_father_depchild 
	  ,solo_mother_depchild
	  ,solo_father_depchild
	  ,other_father
	  ,other_mother
      ,a.[snz_gss_hhld_uid]
      ,a.[snz_gss_uid]
      ,[gss_pq_dveligible]
      ,[gss_pq_HQinterview_date]
      ,[gss_pq_PQinterview_date]
	  ,[gss_pq_arrive_NZ_yr]
      ,[gss_pq_arrive_nz_mnth_code]
	  ,[gss_pq_inc_total_code]
	  ,[gss_pq_lfs_dev] as labour_force_status
	  ,[gss_pq_fam_type_code]
      ,[gss_pq_HH_tenure_code]
      ,[gss_pq_HH_comp_code]
      ,[gss_pq_HH_crowd_code]
      ,[gss_pq_HH_inc_detailed_code]
      ,[gss_pq_HH_inc_higher_code]
      ,[gss_pq_pers_inc_amt_code]
      ,[gss_pq_feel_life_code]
      ,[gss_pq_life_worthwhile_code]
      ,[gss_pq_health_excel_poor_code]
	  ,[gss_pq_trust_most_code]
      ,[gss_pq_trust_police_code]
      ,[gss_pq_trust_education_code]
      ,[gss_pq_trust_media_code]
      ,[gss_pq_trust_courts_code]
      ,[gss_pq_trust_parliament_code]
      ,[gss_pq_trust_health_code]
	  ,[gss_pq_enough_inc_code]
      ,[gss_pq_material_wellbeing_code]
      ,[gss_pq_house_condition_code]
      ,[gss_pq_house_mold_code]
      ,[gss_pq_house_cold_code]
	  ,[gss_pq_safe_night_home_code]
      ,[gss_pq_safe_night_hood_code]
      ,[gss_pq_safe_night_pub_trans_code]
	  ,[gss_pq_health_dvwho5_code]
	  ,[gss_pq_time_lonely_code]
      ,[gss_pq_resp_partner_HH_ind]
      ,[gss_pq_people_house_nbr]
      ,[gss_pq_resp_partner_anywhr_ind]
      ,[gss_pq_resp_live_parent_ind]
      ,[gss_pq_resp_live_child_ind]
      ,[gss_pq_resp_live_brosis_ind]
      ,[gss_pq_resp_live_otherfam_ind]
      ,[gss_pq_resp_live_nonfam_ind]
	  ,[gss_pq_cdm_house_breath_code]
      ,[gss_pq_cdm_house_damp_code]
      ,[gss_pq_cdm_house_mould_code]
      ,[gss_pq_cdm_house_mouldsize_code]
      ,[gss_pq_fam_wellbeing_code]
      ,[gss_pq_fam_size_code]
      ,[gss_pq_fam_groups_child_code]
      ,[gss_pq_fam_groups_gpar_code]
      ,[gss_pq_fam_groups_dist_code]
      ,[gss_pq_fam_groups_oth_code]
      ,[gss_pq_fam_groups_dontknow_code]
      ,[gss_pq_fam_groups_refuse_code]
      ,[gss_pq_fam_rel_or_friend_code]
      ,[gss_pq_fam_most_relorfriend_code]
    INTO [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_2016_2018_tables]
	FROM [IDI_Clean_202203].[gss_clean].[gss_person] as a left join [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_2016_2018_HH_table] as b on a.snz_uid = b.snz_uid where [gss_hq_collection_code] = 'GSS2018' or [gss_hq_collection_code] = 'GSS2016'


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- HLFS data collection and population of study identification --------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
drop table #sec_conc_DOB
 select a.snz_uid, [snz_hlfs_uid], [snz_birth_date_proxy] into #sec_conc_DOB from  [IDI_Clean_202203].[security].[concordance] as a left join [IDI_Clean_202203].[data].[personal_detail] as b on a.snz_uid = b.snz_uid where [snz_hlfs_uid] is not null

-- Grab parents (male and female) with dependent aged children in the family nucleus
 drop table #may21_WB_supp
 select *, convert(DATETIME, sqd_fsqinterviewdate,103) as interview_dte  into #may21_WB_supp from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202105]
 drop table #feb21_WB_supp 
 select *, convert(DATETIME, sqd_fsqinterviewdate,103) as interview_dte  into #feb21_WB_supp from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202102] 
 drop table #nov20_WB_supp 
 select *, convert(DATETIME, sqd_fsqinterviewdate,103) as interview_dte  into #nov20_WB_supp from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202011]

 drop table #tmp_HLFS
 select * into  #tmp_HLFS from (
 select [snz_hlfs_uid],	DVHHType,DVHHTen,DVRegCouncil, DVFam_WithPartner, [dvsex] ,DVFam_ParentRole, DVFam_NumDepChild,DVFam_NumIndepChild , 
		EthEuropean, EthMaori, EthPacific, EthAsian, EthMELAA, EthOther, 1 as may21, null as feb21, null as nov20, null as aug20,  interview_dte as interview_date
			,Dep17					-- Material hardship score based on the Dep17 index
			,DVLFS					-- Labour force status
			,DVUnderUtilise			-- Underutilisation
			,NumJobs				-- Total number of businesses, paid jobs, and unpaid jobs in family businesses
			,DVJobTenC				-- Job tenure categories
			,DVHQual				-- Highest qualification
			,DVStudy				-- Study status (ie formal, informal etc)
			,PWB_qFeelAboutLifeScale	-- Overall life satisfaction
			,PWB_qThingsWorthwhileScale	-- Life worthwhile
			,PWB_qHealthExcellentPoor	-- Self-rated general health status
			--,pwb_qhappyyest			-- How happy yesterday
			,PWB_qTrustMostPeopleScale	-- Generalised trust - how much respondent trusts most people in NZ
			,PWB_qTrustPol			-- Trust in the police
			,PWB_qTrustParl			-- Trust in parliament
			,PWB_qTrustHlth			-- Trust in the health system
			,PWB_qTrustMed			-- Trust in the media
			,PWB_qDiscriminated		-- In the last 12 months has th respondent been discriminated against
			,PWB_qTimeLonely		-- How often felt lonely in the last 4 weeks
			,MHS_qEnoughIncome		-- How well does respondent's (and partner's) income meet everyday needs
			--,DVHHTen				-- Household tenure
			--,datediff(year,[snz_birth_date_proxy],interview_date) as age,
			,case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as partnered_father_depchild,
			case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as partnered_mother_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as solo_father_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as solo_mother_depchild,
			case when DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 end as other_father,
			case when DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 end as other_mother
			--case when DVFam_ParentRole = 0 and [dvsex] = 1 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 end as adult_male,
			--case when DVFam_ParentRole = 0 and [dvsex] = 2 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 end as adult_female
			from #may21_WB_supp
 union all 
 select [snz_hlfs_uid], DVHHType,DVHHTen,DVRegCouncil, DVFam_WithPartner, [dvsex],DVFam_ParentRole, DVFam_NumDepChild,DVFam_NumIndepChild, 
		EthEuropean, EthMaori, EthPacific, EthAsian, EthMELAA, EthOther, null as may21, 1 as feb21, null as nov20, null as aug20,  interview_dte  as interview_date
			,Dep17					-- Material hardship score based on the Dep17 index
			,DVLFS					-- Labour force status
			,DVUnderUtilise			-- Underutilisation
			,NumJobs				-- Total number of businesses, paid jobs, and unpaid jobs in family businesses
			,DVJobTenC				-- Job tenure categories
			,DVHQual				-- Highest qualification
			,DVStudy				-- Study status (ie formal, informal etc)
			,PWB_qFeelAboutLifeScale	-- Overall life satisfaction
			,PWB_qThingsWorthwhileScale	-- Life worthwhile
			,PWB_qHealthExcellentPoor	-- Self-rated general health status
			--,pwb_qhappyyest			-- How happy yesterday
			,PWB_qTrustMostPeopleScale	-- Generalised trust - how much respondent trusts most people in NZ
			,PWB_qTrustPol			-- Trust in the police
			,PWB_qTrustParl			-- Trust in parliament
			,PWB_qTrustHlth			-- Trust in the health system
			,PWB_qTrustMed			-- Trust in the media
			,PWB_qDiscriminated		-- In the last 12 months has th respondent been discriminated against
			,PWB_qTimeLonely		-- How often felt lonely in the last 4 weeks
			,MHS_qEnoughIncome		-- How well does respondent's (and partner's) income meet everyday needs
			--,DVHHTen				-- Household tenure
			,case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as partnered_father_depchild,
			case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as partnered_mother_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as solo_father_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as solo_mother_depchild,
			case when DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 end as other_father,
			case when DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 end as other_mother
			from #feb21_WB_supp
 union all 
 select [snz_hlfs_uid],	DVHHType,DVHHTen,DVRegCouncil, DVFam_WithPartner, [dvsex],DVFam_ParentRole, DVFam_NumDepChild,DVFam_NumIndepChild, 
		EthEuropean, EthMaori, EthPacific, EthAsian, EthMELAA, EthOther, null as may21, null as feb21,1 as nov20, null as aug20,	 interview_dte  as interview_date
			,Dep17					-- Material hardship score based on the Dep17 index
			,DVLFS					-- Labour force status
			,DVUnderUtilise			-- Underutilisation
			,NumJobs				-- Total number of businesses, paid jobs, and unpaid jobs in family businesses
			,DVJobTenC				-- Job tenure categories
			,DVHQual				-- Highest qualification
			,DVStudy				-- Study status (ie formal, informal etc)
			,PWB_qFeelAboutLifeScale	-- Overall life satisfaction
			,PWB_qThingsWorthwhileScale	-- Life worthwhile
			,PWB_qHealthExcellentPoor	-- Self-rated general health status
			--,pwb_qhappyyest			-- How happy yesterday
			,PWB_qTrustMostPeopleScale	-- Generalised trust - how much respondent trusts most people in NZ
			,PWB_qTrustPol			-- Trust in the police
			,PWB_qTrustParl			-- Trust in parliament
			,PWB_qTrustHlth			-- Trust in the health system
			,PWB_qTrustMed			-- Trust in the media
			,PWB_qDiscriminated		-- In the last 12 months has th respondent been discriminated against
			,PWB_qTimeLonely		-- How often felt lonely in the last 4 weeks
			,MHS_qEnoughIncome		-- How well does respondent's (and partner's) income meet everyday needs
			--,DVHHTen				-- Household tenure
			,case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as partnered_father_depchild,
			case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as partnered_mother_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as solo_father_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as solo_mother_depchild,
			case when DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 end as other_father,
			case when DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 end as other_mother
			from #nov20_WB_supp
 union all 
 select [snz_hlfs_uid],	DVHHType,DVHHTen,DVRegCouncil, DVFam_WithPartner, [dvsex],DVFam_ParentRole, DVFam_NumDepChild,DVFam_NumIndepChild, 
		EthEuropean, EthMaori, EthPacific, EthAsian, EthMELAA, EthOther, null as may21, null as feb21, null as nov20,1 as aug20,	datefromparts(year(sqd_fsqinterviewdate),month(sqd_fsqinterviewdate),day(sqd_fsqinterviewdate) )  as interview_date
			,Dep17					-- Material hardship score based on the Dep17 index
			,DVLFS					-- Labour force status
			,DVUnderUtilise			-- Underutilisation
			,NumJobs				-- Total number of businesses, paid jobs, and unpaid jobs in family businesses
			,DVJobTenC				-- Job tenure categories
			,DVHQual				-- Highest qualification
			,DVStudy				-- Study status (ie formal, informal etc)
			,PWB_qFeelAboutLifeScale	-- Overall life satisfaction
			,PWB_qThingsWorthwhileScale	-- Life worthwhile
			,PWB_qHealthExcellentPoor	-- Self-rated general health status
			,PWB_qTrustMostPeopleScale	-- Generalised trust - how much respondent trusts most people in NZ
			,PWB_qTrustPol			-- Trust in the police
			,PWB_qTrustParl			-- Trust in parliament
			,PWB_qTrustHlth			-- Trust in the health system
			,PWB_qTrustMed			-- Trust in the media
			,PWB_qDiscriminated		-- In the last 12 months has th respondent been discriminated against
			,PWB_qTimeLonely		-- How often felt lonely in the last 4 weeks
			,MHS_qEnoughIncome		-- How well does respondent's (and partner's) income meet everyday needs
			--,DVHHTen				-- Household tenure
			,case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as partnered_father_depchild,
			case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as partnered_mother_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as solo_father_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as solo_mother_depchild,
			case when DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 end as other_father,
			case when DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 end as other_mother
			from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202008]
 ) as a 
 
 
  drop table  [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables]
  select a.[snz_hlfs_uid]
		,[snz_birth_date_proxy]
		,datediff(year,[snz_birth_date_proxy],[interview_date])  as age 
      ,[DVHHType]
      ,[DVHHTen]
      ,[DVRegCouncil]
      ,[DVFam_WithPartner]
      ,[dvsex]
      ,[DVFam_ParentRole]
      ,[DVFam_NumDepChild]
      ,[DVFam_NumIndepChild]
      ,[EthEuropean]
      ,[EthMaori]
      ,[EthPacific]
      ,[EthAsian]
      ,[EthMELAA]
      ,[EthOther]
      ,[may21]
      ,[feb21]
      ,[nov20]
      ,[aug20]
      ,[interview_date]
      ,[Dep17]
      ,[DVLFS]
      ,[DVUnderUtilise]
      ,[NumJobs]
      ,[DVJobTenC]
      ,[DVHQual]
      ,[DVStudy]
      ,[PWB_qFeelAboutLifeScale]
      ,[PWB_qThingsWorthwhileScale]
      ,[PWB_qHealthExcellentPoor]
      ,[PWB_qTrustMostPeopleScale]
      ,[PWB_qTrustPol]
      ,[PWB_qTrustParl]
      ,[PWB_qTrustHlth]
      ,[PWB_qTrustMed]
      ,[PWB_qDiscriminated]
      ,[PWB_qTimeLonely]
      ,[MHS_qEnoughIncome]
      ,[partnered_father_depchild]
      ,[partnered_mother_depchild]
      ,[solo_father_depchild]
      ,[solo_mother_depchild]
      ,[other_father]
      ,[other_mother]
	  into [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables]
  FROM #tmp_HLFS as a left join  #sec_conc_DOB as b on a.[snz_hlfs_uid] = b.[snz_hlfs_uid] 
 










 select top (100) [snz_hlfs_uid], count(*) as cnt from [IDI_Sandpit].[DL-MAA2021-49].[WBR_Wellbeing_supp_tables]  group by [snz_hlfs_uid] order by cnt desc


drop table #HLFS_pop_indicators
select	distinct	a.[snz_hlfs_uid], 
			b.snz_uid,
			DVFam_WithPartner, 
			[dvsex], 
			DVFam_ParentRole, 
			DVFam_NumDepChild,
			DVFam_NumIndepChild,
			aug20,
			nov20,
			feb21,
			may21,
			interview_date
into #HLFS_pop_indicators
from #combined_HLFS_wellbeing_data as a left join [IDI_Clean_202203].[hlfs_clean].[data] as b on a.[snz_hlfs_uid]=b.[snz_hlfs_uid] 

Select top(1000) * from #HLFS_pop_indicators

 drop table #HLFS_pop_indicators_pers_details
 select		a.[snz_hlfs_uid], 
			a.snz_uid,
			max([dvsex]) as Sex 
			,max(case when aug20 = 1 then interview_date end) as interview_date_aug20
			,max(case when aug20 = 1 then DVFam_WithPartner end) as DVFam_WithPartner_aug20
			,max(case when aug20 = 1 then DVFam_ParentRole end) as DVFam_ParentRole_aug20
			,max(case when aug20 = 1 then DVFam_NumDepChild end) as DVFam_NumDepChild_aug20
			,max(case when aug20 = 1 then DVFam_NumIndepChild end) as DVFam_NumIndepChild_aug20
			,max(case when aug20 = 1 then datediff(year,[snz_birth_date_proxy],interview_date) end) as age_aug20 
			,max(case when aug20 = 1 and DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 else null end) as partnered_father_depchild_aug20 
			,max(case when aug20 = 1 and DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 else null end) as partnered_mother_depchild_aug20 
			,max(case when aug20 = 1 and DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 else null end) as solo_father_depchild_aug20 
			,max(case when aug20 = 1 and DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 else null end) as solo_mother_depchild_aug20 
			,max(case when aug20 = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 else null end) as other_father_aug20 
			,max(case when aug20 = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 else null end) as other_mother_aug20 
			,max(case when aug20 = 1 and DVFam_ParentRole = 0 and [dvsex] = 1 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 else null end) as adult_male_aug20 
			,max(case when aug20 = 1 and DVFam_ParentRole = 0 and [dvsex] = 2 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 else null end) as adult_female_aug20 

			,max(case when nov20 = 1 then interview_date end) as interview_date_nov20
			,max(case when nov20 = 1 then DVFam_WithPartner end) as DVFam_WithPartner_nov20
			,max(case when nov20 = 1 then DVFam_ParentRole end) as DVFam_ParentRole_nov20
			,max(case when nov20 = 1 then DVFam_NumDepChild end) as DVFam_NumDepChild_nov20
			,max(case when nov20 = 1 then DVFam_NumIndepChild end) as DVFam_NumIndepChild_nov20
			,max(case when nov20 = 1 then datediff(year,[snz_birth_date_proxy],interview_date) end) as age_nov20 
			,max(case when nov20 = 1 and DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 else null end) as partnered_father_depchild_nov20 
			,max(case when nov20 = 1 and DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 else null end) as partnered_mother_depchild_nov20 
			,max(case when nov20 = 1 and DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 else null end) as solo_father_depchild_nov20 
			,max(case when nov20 = 1 and DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 else null end) as solo_mother_depchild_nov20 
			,max(case when nov20 = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 else null end) as other_father_nov20 
			,max(case when nov20 = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 else null end) as other_mother_nov20 
			,max(case when nov20 = 1 and DVFam_ParentRole = 0 and [dvsex] = 1 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 else null end) as adult_male_nov20 
			,max(case when nov20 = 1 and DVFam_ParentRole = 0 and [dvsex] = 2 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 else null end) as adult_female_nov20 

			,max(case when feb21 = 1 then interview_date end) as interview_date_feb21
			,max(case when feb21 = 1 then DVFam_WithPartner end) as DVFam_WithPartner_feb21
			,max(case when feb21 = 1 then DVFam_ParentRole end) as DVFam_ParentRole_feb21
			,max(case when feb21 = 1 then DVFam_NumDepChild end) as DVFam_NumDepChild_feb21
			,max(case when feb21 = 1 then DVFam_NumIndepChild end) as DVFam_NumIndepChild_feb21
			,max(case when feb21 = 1 then datediff(year,[snz_birth_date_proxy],interview_date) end) as age_feb21 
			,max(case when feb21 = 1 and DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 else null end) as partnered_father_depchild_feb21 
			,max(case when feb21 = 1 and DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 else null end) as partnered_mother_depchild_feb21 
			,max(case when feb21 = 1 and DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 else null end) as solo_father_depchild_feb21 
			,max(case when feb21 = 1 and DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 else null end) as solo_mother_depchild_feb21 
			,max(case when feb21 = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 else null end) as other_father_feb21 
			,max(case when feb21 = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 else null end) as other_mother_feb21 
			,max(case when feb21 = 1 and DVFam_ParentRole = 0 and [dvsex] = 1 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 else null end) as adult_male_feb21 
			,max(case when feb21 = 1 and DVFam_ParentRole = 0 and [dvsex] = 2 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 else null end) as adult_female_feb21 

			,max(case when may21 = 1 then interview_date end) as interview_date_may21
			,max(case when may21 = 1 then DVFam_WithPartner end) as DVFam_WithPartner_may21
			,max(case when may21 = 1 then DVFam_ParentRole end) as DVFam_ParentRole_may21
			,max(case when may21 = 1 then DVFam_NumDepChild end) as DVFam_NumDepChild_may21
			,max(case when may21 = 1 then DVFam_NumIndepChild end) as DVFam_NumIndepChild_may21
			,max(case when may21 = 1 then datediff(year,[snz_birth_date_proxy],interview_date) end) as age_may21 
			,max(case when may21 = 1 and DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 else null end) as partnered_father_depchild_may21 
			,max(case when may21 = 1 and DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 else null end) as partnered_mother_depchild_may21 
			,max(case when may21 = 1 and DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 else null end) as solo_father_depchild_may21 
			,max(case when may21 = 1 and DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 else null end) as solo_mother_depchild_may21 
			,max(case when may21 = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 else null end) as other_father_may21 
			,max(case when may21 = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 else null end) as other_mother_may21 
			,max(case when may21 = 1 and DVFam_ParentRole = 0 and [dvsex] = 1 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 else null end) as adult_male_may21 
			,max(case when may21 = 1 and DVFam_ParentRole = 0 and [dvsex] = 2 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 else null end) as adult_female_may21 

			--DVFam_WithPartner, 
			--DVFam_ParentRole, 
			--DVFam_NumDepChild,
			--DVFam_NumIndepChild,
			--aug20,
			--nov20,
			--feb21,
			--may21,
			--datediff(year,[snz_birth_date_proxy],interview_date) as age,
			--case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as partnered_father_depchild,
			--case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as partnered_mother_depchild,
			--case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as solo_father_depchild,
			--case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as solo_mother_depchild,
			--case when DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 end as other_father,
			--case when DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 end as other_mother,
			--case when DVFam_ParentRole = 0 and [dvsex] = 1 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 end as adult_male,
			--case when DVFam_ParentRole = 0 and [dvsex] = 2 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 end as adult_female
	into [IDI_Sandpit].[DL-MAA2021-49].[WBR_HLFS_wellbeing_pop_202203]
	from #HLFS_pop_indicators as a left join [IDI_Clean_202203].[data].[personal_detail] as b on a.snz_uid=b.snz_uid group by a.snz_uid, a.[snz_hlfs_uid]
	CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-49].[WBR_HLFS_wellbeing_pop_202203] (snz_uid);
	   	 
	select top (1000) * [IDI_Sandpit].[DL-MAA2021-49].[WBR_HLFS_wellbeing_pop_202203]



-- Indicators from HLFS:
 drop table #tmp_HLFS
 select		[snz_hlfs_uid], 
			snz_uid 
			,Dep17					-- Material hardship score based on the Dep17 index
			,DVLFS					-- Labour force status
			,DVUnderUtilise			-- Underutilisation
			,NumJobs				-- Total number of businesses, paid jobs, and unpaid jobs in family businesses
			,DVJobTenC				-- Job tenure categories
			,DVHQual				-- Highest qualification
			,DVStudy				-- Study status (ie formal, informal etc)
			,PWB_qFeelAboutLifeScale	-- Overall life satisfaction
			,PWB_qThingsWorthwhileScale	-- Life worthwhile
			,PWB_qHealthExcellentPoor	-- Self-rated general health status
			,pwb_qhappyyest			-- How happy yesterday
			,DVWHO5					-- Weighted mental wellbeing score based on WHO-5 wellbeing index
			,PWB_qTrustMostPeopleScale	-- Generalised trust - how much respondent trusts most people in NZ
			,PWB_qTrustPol			-- Trust in the police
			,PWB_qTrustParl			-- Trust in parliament
			,PWB_qTrustHlth			-- Trust in the health system
			,PWB_qTrustMed			-- Trust in the media
			,PWB_qSafeNightHood		-- How safe or unsafe feel when walking alone in neighbourhood after dark
			,PWB_qDiscriminated		-- In the last 12 months has th respondent been discriminated against
			,PWB_qTimeLonely		-- How often felt lonely in the last 4 weeks
			,MHS_qEnoughIncome		-- How well does respondent's (and partner's) income meet everyday needs
			,DVHHTen				-- Household tenure
into #tmp_HLFS
from  [IDI_Clean_202203].[hlfs_clean].[data]

	
	select partnered_father_depchild, partnered_mother_depchild, solo_father_depchild, solo_mother_depchild, other_father, other_mother, adult_male, adult_female, count(*) as cnt from #HLFS_pop_indicators_pers_details group by partnered_father_depchild, partnered_mother_depchild, solo_father_depchild, solo_mother_depchild, other_father, other_mother, adult_male, adult_female
	
	--drop table #count_freqs
	--select [snz_hlfs_uid], 
	--		snz_uid,
	--		max(DVFam_WithPartner) as DVFam_WithPartner, 
	--		max([dvsex]) as [dvsex], 
	--		max(DVFam_ParentRole) as DVFam_ParentRole, 
	--		max(DVFam_NumDepChild) as DVFam_NumDepChild,
	--		max(DVFam_NumIndepChild) as DVFam_NumIndepChild,
	--		max(aug20) as aug20,
	--		max(nov20) as nov20,
	--		max(feb21) as feb21,
	--		max(may21) as may21,
	--		max(partnered_father_depchild) as partnered_father_depchild, 
	--		max(partnered_mother_depchild) as partnered_mother_depchild, 
	--		max(solo_father_depchild) as solo_father_depchild, 
	--		max(solo_mother_depchild) as solo_mother_depchild, 
	--		max(other_father) as other_father, 
	--		max(other_mother) as other_mother, 
	--		max(adult_male) as adult_male, 
	--		max(adult_female) as adult_female
	--into #count_freqs
	--from #HLFS_pop_indicators_pers_details group by snz_uid, [snz_hlfs_uid]

	--select * from #count_freqs
	-- CHECK HOW MANY PEOPLE TRANSITION INTO DIFFERENT TYPES OF PARENTS, I.E., SOLO, PARTNERED, ETC.
	select partnered_father_depchild, partnered_mother_depchild, solo_father_depchild, solo_mother_depchild, other_father, other_mother, adult_male, adult_female, count(*) as cnt from #count_freqs group by partnered_father_depchild, partnered_mother_depchild, solo_father_depchild, solo_mother_depchild, other_father, other_mother, adult_male, adult_female
	

	select * from #HLFS_pop_indicators where [dob_month] is null or [dob_year] is null

	select * from #HLFS_pop_indicators where partnered_father_depchild is NULL and partnered_mother_depchild  is NULL and  solo_father_depchild  is NULL and  solo_mother_depchild  is NULL and  other_father  is NULL and  other_mother is NULL and  adult_male is NULL and  adult_female is NULL

		
 
 
 into #combined_HLFS_wellbeing_data 






select top (100) * from #combned_HLFS_list
 
 drop table #combned_HLFS_list
 select * into #combned_HLFS_list from (
	select [snz_hlfs_uid], DVFam_WithPartner, DVSex, may21, null as feb21, null as nov20, null as aug20 from #may21
		union all 
	select [snz_hlfs_uid], DVFam_WithPartner, DVSex, null as may21, feb21, null as nov20, null as aug20 from #feb21
		union all 
	select [snz_hlfs_uid], DVFam_WithPartner, DVSex, null as may21, null as feb21, nov20, null as aug20 from #nov20	
		union all 
	select [snz_hlfs_uid], DVFam_WithPartner, DVSex, null as may21, null as feb21, null as nov20, aug20 from #aug20	
 ) as a


select top (100) * from #combned_HLFS_list


drop table #combned_HLFS_list_mothers_fathers
select distinct [snz_hlfs_uid], max(DVFam_WithPartner) as DVFam_WithPartner, max(DVSex) as DVSex, max(may21) as may21,max(feb21) as feb21, max(nov20) as nov20, max(aug20) as aug20   into #combned_HLFS_list_mothers_fathers from #combned_HLFS_list  group by [snz_hlfs_uid]

select count(*) as cnt, DVFam_WithPartner, DVSex from #combned_HLFS_list_mothers_fathers group by DVFam_WithPartner, DVSex
cnt	DVFam_WithPartner	DVSex


select top(1000) * from #combned_HLFS_list_mothers_only




SELECT	[snz_hlfs_uid]
		,DVSex



		select [dvhhtype], count(*) as cnt
  FROM [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202105] group by [dvhhtype] 

  select count(*) as cnt
		,DVSex
		from  [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202105] where [dvhhtype] in (3,4,5,6,8, 10,11,13) and DVFam_ParentRole
 = 1 group by DVSex   



 SELECT	a.[snz_hlfs_uid], b.snz_uid from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202105] 

 drop table #may21 
  drop table #feb21 
   drop table #nov20 
    drop table #aug20

 select [snz_hlfs_uid], 1 as may21 into #may21 from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202105]
 select [snz_hlfs_uid], 1 as feb21 into #feb21 from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202102]	
 select [snz_hlfs_uid], 1 as nov20 into #nov20 from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202011]	
 select [snz_hlfs_uid], 1 as aug20 into #aug20 from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202008]
 
 select distinct [snz_hlfs_uid] from #nov20 as a full outer join #aug20 as b on a.[snz_hlfs_uid] = b.[snz_hlfs_uid]
 -- 



 drop table #combned_HLFS_list
 select distinct [snz_hlfs_uid] into #combned_HLFS_list from (
	select * from #may21
		union all 
	select * from #feb21
		union all 
	select * from #nov20	
		union all 
	select * from #aug20	
 ) as a

 select top (100) * from #combned_HLFS_list


 
 drop table #may21 
  drop table #feb21 
   drop table #nov20 
    drop table #aug20

 select [snz_hlfs_uid], DVSex, 1 as may21 into #may21 from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202105] where DVFam_ParentRole = 1 and DVFam_NumDepChild  >= 1
 select [snz_hlfs_uid], DVSex, 1 as feb21 into #feb21 from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202102] where DVFam_ParentRole = 1 and DVFam_NumDepChild  >= 1
 select [snz_hlfs_uid], DVSex, 1 as nov20 into #nov20 from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202011] where DVFam_ParentRole = 1 and DVFam_NumDepChild  >= 1
 select [snz_hlfs_uid], DVSex, 1 as aug20 into #aug20 from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202008] where DVFam_ParentRole = 1 and DVFam_NumDepChild  >= 1
 
 
 drop table #combned_HLFS_list
 select * into #combned_HLFS_list from (
	select [snz_hlfs_uid], DVSex, may21, null as feb21, null as nov20, null as aug20 from #may21
		union all 
	select [snz_hlfs_uid], DVSex, null as may21, feb21, null as nov20, null as aug20 from #feb21
		union all 
	select [snz_hlfs_uid], DVSex, null as may21, null as feb21, nov20, null as aug20 from #nov20	
		union all 
	select [snz_hlfs_uid], DVSex, null as may21, null as feb21, null as nov20, aug20 from #aug20	
 ) as a

 select top(100) * from #combned_HLFS_list

drop table #combned_HLFS_list_mothers_only
select distinct [snz_hlfs_uid], max(DVSex) as DVSex, max(may21) as may21,max(feb21) as feb21, max(nov20) as nov20, max(aug20) as aug20   into #combned_HLFS_list_mothers_only from #combned_HLFS_list where DVSex = 2 group by [snz_hlfs_uid]
 
 select top(1000) * from #combned_HLFS_list_mothers_only
 

 drop table #combned_HLFS_list_mothers
 select distinct [snz_hlfs_uid] into #combned_HLFS_list_mothers from #combned_HLFS_list




 drop table #combned_HLFS_list_snz_uids
 select a.[snz_hlfs_uid], [snz_uid] into #combned_HLFS_list_snz_uids from #combned_HLFS_list as a left join [IDI_Clean_20211020].[security].[concordance] as b on a.[snz_hlfs_uid] = b.[snz_hlfs_uid] where [snz_spine_uid] is not null

 SELECT [gss_pq_collection_code], count(*) as cnt 
  FROM [IDI_Clean_20211020].[gss_clean].[gss_person] group by [gss_pq_collection_code]

  select top (100) * FROM [IDI_Clean_20211020].[gss_clean].[gss_person] 

  select a.snz_uid, [gss_pq_collection_code] into #crossover_chk from #combned_HLFS_list_snz_uids as a left join [IDI_Clean_20211020].[gss_clean].[gss_person]  as b on a.snz_uid=b.snz_uid

  select [gss_pq_collection_code], count(*) as cnt from #crossover_chk group by [gss_pq_collection_code]



