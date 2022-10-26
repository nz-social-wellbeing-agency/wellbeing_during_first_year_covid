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

DROP TABLE #tmp_gss
SELECT	a.[snz_uid]
		,[gss_hq_collection_code]
		,a.[snz_gss_hhld_uid]
		,a.[snz_gss_uid]
		--,[snz_sex_gender_code]
		--,[snz_birth_date_proxy]
		--,[snz_ethnicity_grp1_nbr]
		--,[snz_ethnicity_grp2_nbr]
		--,[snz_ethnicity_grp3_nbr]
		--,[snz_ethnicity_grp4_nbr]
		--,[snz_ethnicity_grp5_nbr]
		--,[snz_ethnicity_grp6_nbr]
		,case when [gss_hq_fam_parentrole_ind] = 'Y' and [gss_hq_fam_withpartner_ind] = 'Y' and [gss_pq_dvsex_code] = 2 and [gss_hq_fam_num_depchild_nbr] >= 1 then 1 else 0 end as partnered_mother_depchild
		,case when [gss_hq_fam_parentrole_ind] = 'Y' and [gss_hq_fam_withpartner_ind] = 'Y' and [gss_pq_dvsex_code] = 1 and [gss_hq_fam_num_depchild_nbr] >= 1 then 1 else 0 end as partnered_father_depchild
		,case when [gss_hq_fam_parentrole_ind] = 'Y' and [gss_hq_fam_withpartner_ind] = 'N' and [gss_pq_dvsex_code] = 2 and [gss_hq_fam_num_depchild_nbr] >= 1 then 1 else 0 end as solo_mother_depchild
		,case when [gss_hq_fam_parentrole_ind] = 'Y' and [gss_hq_fam_withpartner_ind] = 'N' and [gss_pq_dvsex_code] = 1 and [gss_hq_fam_num_depchild_nbr] >= 1 then 1 else 0 end as solo_father_depchild
		,case when [gss_hq_fam_parentrole_ind] = 'Y'  and [gss_pq_dvsex_code] = 1 and [gss_hq_fam_num_depchild_nbr] <= 0 then 1 else 0 end as other_father
		,case when [gss_hq_fam_parentrole_ind] = 'Y'  and [gss_pq_dvsex_code] = 2 and [gss_hq_fam_num_depchild_nbr] <= 0 then 1 else 0  end as other_mother
		,[gss_hq_age_dep_childyg_dev]
INTO #tmp_gss
FROM [IDI_Clean_202203].[gss_clean].[gss_household] as a left join [IDI_Clean_202203].[gss_clean].[gss_person] as b on a.snz_uid = b.snz_uid where [gss_hq_collection_code] = 'GSS2018' or [gss_hq_collection_code] = 'GSS2016' order by [snz_gss_hhld_uid]


DROP TABLE [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_2016_2018_tables_202203]
SELECT a.[snz_uid]
		,[gss_pq_dvsex_code]
		,a.[gss_pq_dvage_code] as age
		,[gss_pq_collection_code]
		--,datediff(year,[snz_birth_date_proxy],[gss_pq_PQinterview_date])  as age 
		,[gss_pq_birth_month_nbr]
      ,[gss_pq_birth_year_nbr]
      ,[gss_pq_ethnic_grp1_snz_ind]
      ,[gss_pq_ethnic_grp2_snz_ind]
      ,[gss_pq_ethnic_grp3_snz_ind]
      ,[gss_pq_ethnic_grp4_snz_ind]
      ,[gss_pq_ethnic_grp5_snz_ind]
      ,[gss_pq_ethnic_grp6_snz_ind]
	  ,partnered_mother_depchild
	  ,partnered_father_depchild 
	  ,solo_mother_depchild
	  ,solo_father_depchild
	  ,other_father
	  ,other_mother
      ,a.[snz_gss_hhld_uid]
      ,a.[snz_gss_uid]
	   ,[gss_pq_region12_dev]
	   ,[gss_pq_Reg_council_code]
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
	  ,[gss_pq_discriminated_code]
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
	  ,[gss_pq_person_FinalWgt_nbr]
      ,[gss_pq_person_FinalWgt1_nbr]
      ,[gss_pq_person_FinalWgt2_nbr]
      ,[gss_pq_person_FinalWgt3_nbr]
      ,[gss_pq_person_FinalWgt4_nbr]
      ,[gss_pq_person_FinalWgt5_nbr]
      ,[gss_pq_person_FinalWgt6_nbr]
      ,[gss_pq_person_FinalWgt7_nbr]
      ,[gss_pq_person_FinalWgt8_nbr]
      ,[gss_pq_person_FinalWgt9_nbr]
      ,[gss_pq_person_FinalWgt10_nbr]
      ,[gss_pq_person_FinalWgt11_nbr]
      ,[gss_pq_person_FinalWgt12_nbr]
      ,[gss_pq_person_FinalWgt13_nbr]
      ,[gss_pq_person_FinalWgt14_nbr]
      ,[gss_pq_person_FinalWgt15_nbr]
      ,[gss_pq_person_FinalWgt16_nbr]
      ,[gss_pq_person_FinalWgt17_nbr]
      ,[gss_pq_person_FinalWgt18_nbr]
      ,[gss_pq_person_FinalWgt19_nbr]
      ,[gss_pq_person_FinalWgt20_nbr]
      ,[gss_pq_person_FinalWgt21_nbr]
      ,[gss_pq_person_FinalWgt22_nbr]
      ,[gss_pq_person_FinalWgt23_nbr]
      ,[gss_pq_person_FinalWgt24_nbr]
      ,[gss_pq_person_FinalWgt25_nbr]
      ,[gss_pq_person_FinalWgt26_nbr]
      ,[gss_pq_person_FinalWgt27_nbr]
      ,[gss_pq_person_FinalWgt28_nbr]
      ,[gss_pq_person_FinalWgt29_nbr]
      ,[gss_pq_person_FinalWgt30_nbr]
      ,[gss_pq_person_FinalWgt31_nbr]
      ,[gss_pq_person_FinalWgt32_nbr]
      ,[gss_pq_person_FinalWgt33_nbr]
      ,[gss_pq_person_FinalWgt34_nbr]
      ,[gss_pq_person_FinalWgt35_nbr]
      ,[gss_pq_person_FinalWgt36_nbr]
      ,[gss_pq_person_FinalWgt37_nbr]
      ,[gss_pq_person_FinalWgt38_nbr]
      ,[gss_pq_person_FinalWgt39_nbr]
      ,[gss_pq_person_FinalWgt40_nbr]
      ,[gss_pq_person_FinalWgt41_nbr]
      ,[gss_pq_person_FinalWgt42_nbr]
      ,[gss_pq_person_FinalWgt43_nbr]
      ,[gss_pq_person_FinalWgt44_nbr]
      ,[gss_pq_person_FinalWgt45_nbr]
      ,[gss_pq_person_FinalWgt46_nbr]
      ,[gss_pq_person_FinalWgt47_nbr]
      ,[gss_pq_person_FinalWgt48_nbr]
      ,[gss_pq_person_FinalWgt49_nbr]
      ,[gss_pq_person_FinalWgt50_nbr]
      ,[gss_pq_person_FinalWgt51_nbr]
      ,[gss_pq_person_FinalWgt52_nbr]
      ,[gss_pq_person_FinalWgt53_nbr]
      ,[gss_pq_person_FinalWgt54_nbr]
      ,[gss_pq_person_FinalWgt55_nbr]
      ,[gss_pq_person_FinalWgt56_nbr]
      ,[gss_pq_person_FinalWgt57_nbr]
      ,[gss_pq_person_FinalWgt58_nbr]
      ,[gss_pq_person_FinalWgt59_nbr]
      ,[gss_pq_person_FinalWgt60_nbr]
      ,[gss_pq_person_FinalWgt61_nbr]
      ,[gss_pq_person_FinalWgt62_nbr]
      ,[gss_pq_person_FinalWgt63_nbr]
      ,[gss_pq_person_FinalWgt64_nbr]
      ,[gss_pq_person_FinalWgt65_nbr]
      ,[gss_pq_person_FinalWgt66_nbr]
      ,[gss_pq_person_FinalWgt67_nbr]
      ,[gss_pq_person_FinalWgt68_nbr]
      ,[gss_pq_person_FinalWgt69_nbr]
      ,[gss_pq_person_FinalWgt70_nbr]
      ,[gss_pq_person_FinalWgt71_nbr]
      ,[gss_pq_person_FinalWgt72_nbr]
      ,[gss_pq_person_FinalWgt73_nbr]
      ,[gss_pq_person_FinalWgt74_nbr]
      ,[gss_pq_person_FinalWgt75_nbr]
      ,[gss_pq_person_FinalWgt76_nbr]
      ,[gss_pq_person_FinalWgt77_nbr]
      ,[gss_pq_person_FinalWgt78_nbr]
      ,[gss_pq_person_FinalWgt79_nbr]
      ,[gss_pq_person_FinalWgt80_nbr]
      ,[gss_pq_person_FinalWgt81_nbr]
      ,[gss_pq_person_FinalWgt82_nbr]
      ,[gss_pq_person_FinalWgt83_nbr]
      ,[gss_pq_person_FinalWgt84_nbr]
      ,[gss_pq_person_FinalWgt85_nbr]
      ,[gss_pq_person_FinalWgt86_nbr]
      ,[gss_pq_person_FinalWgt87_nbr]
      ,[gss_pq_person_FinalWgt88_nbr]
      ,[gss_pq_person_FinalWgt89_nbr]
      ,[gss_pq_person_FinalWgt90_nbr]
      ,[gss_pq_person_FinalWgt91_nbr]
      ,[gss_pq_person_FinalWgt92_nbr]
      ,[gss_pq_person_FinalWgt93_nbr]
      ,[gss_pq_person_FinalWgt94_nbr]
      ,[gss_pq_person_FinalWgt95_nbr]
      ,[gss_pq_person_FinalWgt96_nbr]
      ,[gss_pq_person_FinalWgt97_nbr]
      ,[gss_pq_person_FinalWgt98_nbr]
      ,[gss_pq_person_FinalWgt99_nbr]
      ,[gss_pq_person_FinalWgt100_nbr]
    INTO [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_2016_2018_tables_202203]
	FROM [IDI_Clean_202203].[gss_clean].[gss_person] as a left join #tmp_gss as b on a.snz_uid = b.snz_uid where [gss_hq_collection_code] = 'GSS2018' or [gss_hq_collection_code] = 'GSS2016'



	--drop table [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_FV_ind]
	--select	a.snz_uid
	--		,[event_date]
	--		,[nia_links_role_type_text]
	--INTO [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_FV_ind]
	--FROM [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_2016_2018_tables] as a left join [IDI_UserCode].[DL-MAA2021-55].[WBR_family_violence] as b on a.snz_uid = b.snz_uid 

	--select top (1000) * from [IDI_Sandpit].[DL-MAA2021-55].[WBR_GSS_FV_ind] order by [event_date] desc

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- HLFS data collection and population of study identification --------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--drop table #sec_conc_DOB
-- select a.snz_uid, [snz_hlfs_uid]
--		,[snz_birth_date_proxy] 
--		,[snz_ethnicity_grp1_nbr]
--		,[snz_ethnicity_grp2_nbr]
--		,[snz_ethnicity_grp3_nbr]
--		,[snz_ethnicity_grp4_nbr]
--		,[snz_ethnicity_grp5_nbr]
--		,[snz_ethnicity_grp6_nbr] 
--into #sec_conc_DOB from  [IDI_Clean_202203].[security].[concordance] as a left join [IDI_Clean_202203].[data].[personal_detail] as b on a.snz_uid = b.snz_uid where [snz_hlfs_uid] is not null

-- Grab parents (male and female) with dependent aged children in the family nucleus
 drop table #may21_WB_supp
 select *, convert(DATETIME, sqd_fsqinterviewdate,103) as interview_dte  into #may21_WB_supp from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202105]
 drop table #feb21_WB_supp 
 select *, convert(DATETIME, sqd_fsqinterviewdate,103) as interview_dte  into #feb21_WB_supp from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202102] 
 drop table #nov20_WB_supp 
 select *, convert(DATETIME, sqd_fsqinterviewdate,103) as interview_dte  into #nov20_WB_supp from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202011]

 drop table #tmp_HLFS
 select * into  #tmp_HLFS from (
 select [snz_hlfs_uid],	DVHHType,DVHHTen,DVRegCouncil, DVFam_WithPartner,  [dob_month] ,[dob_year], [dvsex] , [dvyrsinnz],DVFam_ParentRole, DVFam_NumDepChild,DVFam_NumIndepChild , 
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
			,null as PWB_qSafeNightHood		
			--,PWB_qSafeNightHood		-- How safe or unsafe feel when walking alone in neighbourhood after dark
			,null as [DVWHO5_Raw]		-- Raw mental wellbeing score based on WHO-5 wellbeing index
			,null as [DVWHO5]
			,PWB_qFamWellbeing
			,[quarter_nbr]

			--,DVHHTen				-- Household tenure
			--,datediff(year,[snz_birth_date_proxy],interview_date) as age,
			,case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as partnered_father_depchild,
			case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as partnered_mother_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as solo_father_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as solo_mother_depchild,
			case when DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 end as other_father,
			case when DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 end as other_mother

			      ,[sqfinalwgt]
      ,[sqfinalwgt_1]
      ,[sqfinalwgt_2]
      ,[sqfinalwgt_3]
      ,[sqfinalwgt_4]
      ,[sqfinalwgt_5]
      ,[sqfinalwgt_6]
      ,[sqfinalwgt_7]
      ,[sqfinalwgt_8]
      ,[sqfinalwgt_9]
      ,[sqfinalwgt_10]
      ,[sqfinalwgt_11]
      ,[sqfinalwgt_12]
      ,[sqfinalwgt_13]
      ,[sqfinalwgt_14]
      ,[sqfinalwgt_15]
      ,[sqfinalwgt_16]
      ,[sqfinalwgt_17]
      ,[sqfinalwgt_18]
      ,[sqfinalwgt_19]
      ,[sqfinalwgt_20]
      ,[sqfinalwgt_21]
      ,[sqfinalwgt_22]
      ,[sqfinalwgt_23]
      ,[sqfinalwgt_24]
      ,[sqfinalwgt_25]
      ,[sqfinalwgt_26]
      ,[sqfinalwgt_27]
      ,[sqfinalwgt_28]
      ,[sqfinalwgt_29]
      ,[sqfinalwgt_30]
      ,[sqfinalwgt_31]
      ,[sqfinalwgt_32]
      ,[sqfinalwgt_33]
      ,[sqfinalwgt_34]
      ,[sqfinalwgt_35]
      ,[sqfinalwgt_36]
      ,[sqfinalwgt_37]
      ,[sqfinalwgt_38]
      ,[sqfinalwgt_39]
      ,[sqfinalwgt_40]
      ,[sqfinalwgt_41]
      ,[sqfinalwgt_42]
      ,[sqfinalwgt_43]
      ,[sqfinalwgt_44]
      ,[sqfinalwgt_45]
      ,[sqfinalwgt_46]
      ,[sqfinalwgt_47]
      ,[sqfinalwgt_48]
      ,[sqfinalwgt_49]
      ,[sqfinalwgt_50]
      ,[sqfinalwgt_51]
      ,[sqfinalwgt_52]
      ,[sqfinalwgt_53]
      ,[sqfinalwgt_54]
      ,[sqfinalwgt_55]
      ,[sqfinalwgt_56]
      ,[sqfinalwgt_57]
      ,[sqfinalwgt_58]
      ,[sqfinalwgt_59]
      ,[sqfinalwgt_60]
      ,[sqfinalwgt_61]
      ,[sqfinalwgt_62]
      ,[sqfinalwgt_63]
      ,[sqfinalwgt_64]
      ,[sqfinalwgt_65]
      ,[sqfinalwgt_66]
      ,[sqfinalwgt_67]
      ,[sqfinalwgt_68]
      ,[sqfinalwgt_69]
      ,[sqfinalwgt_70]
      ,[sqfinalwgt_71]
      ,[sqfinalwgt_72]
      ,[sqfinalwgt_73]
      ,[sqfinalwgt_74]
      ,[sqfinalwgt_75]
      ,[sqfinalwgt_76]
      ,[sqfinalwgt_77]
      ,[sqfinalwgt_78]
      ,[sqfinalwgt_79]
      ,[sqfinalwgt_80]
      ,[sqfinalwgt_81]
      ,[sqfinalwgt_82]
      ,[sqfinalwgt_83]
      ,[sqfinalwgt_84]
      ,[sqfinalwgt_85]
      ,[sqfinalwgt_86]
      ,[sqfinalwgt_87]
      ,[sqfinalwgt_88]
      ,[sqfinalwgt_89]
      ,[sqfinalwgt_90]
      ,[sqfinalwgt_91]
      ,[sqfinalwgt_92]
      ,[sqfinalwgt_93]
      ,[sqfinalwgt_94]
      ,[sqfinalwgt_95]
      ,[sqfinalwgt_96]
      ,[sqfinalwgt_97]
      ,[sqfinalwgt_98]
      ,[sqfinalwgt_99]
      ,[sqfinalwgt_100]

			--case when DVFam_ParentRole = 0 and [dvsex] = 1 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 end as adult_male,
			--case when DVFam_ParentRole = 0 and [dvsex] = 2 and datediff(year,[snz_birth_date_proxy],interview_date) >= 18 then 1 end as adult_female
			from #may21_WB_supp
 union all 
 select [snz_hlfs_uid], DVHHType,DVHHTen,DVRegCouncil, DVFam_WithPartner, [dob_month] ,[dob_year], [dvsex], [dvyrsinnz],DVFam_ParentRole, DVFam_NumDepChild,DVFam_NumIndepChild, 
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
			,null as PWB_qSafeNightHood		
			--,PWB_qSafeNightHood		-- How safe or unsafe feel when walking alone in neighbourhood after dark
			--,DVHHTen				-- Household tenure
			,null as [DVWHO5_Raw]		-- Raw mental wellbeing score based on WHO-5 wellbeing index
			,null as [DVWHO5]
			,PWB_qFamWellbeing
			,[quarter_nbr]
			,case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as partnered_father_depchild,
			case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as partnered_mother_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as solo_father_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as solo_mother_depchild,
			case when DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 end as other_father,
			case when DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 end as other_mother

		,[sqfinalwgt]
      ,[sqfinalwgt_1]
      ,[sqfinalwgt_2]
      ,[sqfinalwgt_3]
      ,[sqfinalwgt_4]
      ,[sqfinalwgt_5]
      ,[sqfinalwgt_6]
      ,[sqfinalwgt_7]
      ,[sqfinalwgt_8]
      ,[sqfinalwgt_9]
      ,[sqfinalwgt_10]
      ,[sqfinalwgt_11]
      ,[sqfinalwgt_12]
      ,[sqfinalwgt_13]
      ,[sqfinalwgt_14]
      ,[sqfinalwgt_15]
      ,[sqfinalwgt_16]
      ,[sqfinalwgt_17]
      ,[sqfinalwgt_18]
      ,[sqfinalwgt_19]
      ,[sqfinalwgt_20]
      ,[sqfinalwgt_21]
      ,[sqfinalwgt_22]
      ,[sqfinalwgt_23]
      ,[sqfinalwgt_24]
      ,[sqfinalwgt_25]
      ,[sqfinalwgt_26]
      ,[sqfinalwgt_27]
      ,[sqfinalwgt_28]
      ,[sqfinalwgt_29]
      ,[sqfinalwgt_30]
      ,[sqfinalwgt_31]
      ,[sqfinalwgt_32]
      ,[sqfinalwgt_33]
      ,[sqfinalwgt_34]
      ,[sqfinalwgt_35]
      ,[sqfinalwgt_36]
      ,[sqfinalwgt_37]
      ,[sqfinalwgt_38]
      ,[sqfinalwgt_39]
      ,[sqfinalwgt_40]
      ,[sqfinalwgt_41]
      ,[sqfinalwgt_42]
      ,[sqfinalwgt_43]
      ,[sqfinalwgt_44]
      ,[sqfinalwgt_45]
      ,[sqfinalwgt_46]
      ,[sqfinalwgt_47]
      ,[sqfinalwgt_48]
      ,[sqfinalwgt_49]
      ,[sqfinalwgt_50]
      ,[sqfinalwgt_51]
      ,[sqfinalwgt_52]
      ,[sqfinalwgt_53]
      ,[sqfinalwgt_54]
      ,[sqfinalwgt_55]
      ,[sqfinalwgt_56]
      ,[sqfinalwgt_57]
      ,[sqfinalwgt_58]
      ,[sqfinalwgt_59]
      ,[sqfinalwgt_60]
      ,[sqfinalwgt_61]
      ,[sqfinalwgt_62]
      ,[sqfinalwgt_63]
      ,[sqfinalwgt_64]
      ,[sqfinalwgt_65]
      ,[sqfinalwgt_66]
      ,[sqfinalwgt_67]
      ,[sqfinalwgt_68]
      ,[sqfinalwgt_69]
      ,[sqfinalwgt_70]
      ,[sqfinalwgt_71]
      ,[sqfinalwgt_72]
      ,[sqfinalwgt_73]
      ,[sqfinalwgt_74]
      ,[sqfinalwgt_75]
      ,[sqfinalwgt_76]
      ,[sqfinalwgt_77]
      ,[sqfinalwgt_78]
      ,[sqfinalwgt_79]
      ,[sqfinalwgt_80]
      ,[sqfinalwgt_81]
      ,[sqfinalwgt_82]
      ,[sqfinalwgt_83]
      ,[sqfinalwgt_84]
      ,[sqfinalwgt_85]
      ,[sqfinalwgt_86]
      ,[sqfinalwgt_87]
      ,[sqfinalwgt_88]
      ,[sqfinalwgt_89]
      ,[sqfinalwgt_90]
      ,[sqfinalwgt_91]
      ,[sqfinalwgt_92]
      ,[sqfinalwgt_93]
      ,[sqfinalwgt_94]
      ,[sqfinalwgt_95]
      ,[sqfinalwgt_96]
      ,[sqfinalwgt_97]
      ,[sqfinalwgt_98]
      ,[sqfinalwgt_99]
      ,[sqfinalwgt_100]

			from #feb21_WB_supp
 union all 
 select [snz_hlfs_uid],	DVHHType,DVHHTen,DVRegCouncil, DVFam_WithPartner, [dob_month] ,[dob_year], [dvsex], [dvyrsinnz], DVFam_ParentRole, DVFam_NumDepChild,DVFam_NumIndepChild, 
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
			,null as PWB_qSafeNightHood		
			--,PWB_qSafeNightHood		-- How safe or unsafe feel when walking alone in neighbourhood after dark
			--,DVHHTen				-- Household tenure
			,null as [DVWHO5_Raw]		-- Raw mental wellbeing score based on WHO-5 wellbeing index
			,null as [DVWHO5]
			,PWB_qFamWellbeing
			,[quarter] as [quarter_nbr]   
			,case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as partnered_father_depchild,
			case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as partnered_mother_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as solo_father_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as solo_mother_depchild,
			case when DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 end as other_father,
			case when DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 end as other_mother

			      ,[sqfinalwgt]
      ,[sqfinalwgt_1]
      ,[sqfinalwgt_2]
      ,[sqfinalwgt_3]
      ,[sqfinalwgt_4]
      ,[sqfinalwgt_5]
      ,[sqfinalwgt_6]
      ,[sqfinalwgt_7]
      ,[sqfinalwgt_8]
      ,[sqfinalwgt_9]
      ,[sqfinalwgt_10]
      ,[sqfinalwgt_11]
      ,[sqfinalwgt_12]
      ,[sqfinalwgt_13]
      ,[sqfinalwgt_14]
      ,[sqfinalwgt_15]
      ,[sqfinalwgt_16]
      ,[sqfinalwgt_17]
      ,[sqfinalwgt_18]
      ,[sqfinalwgt_19]
      ,[sqfinalwgt_20]
      ,[sqfinalwgt_21]
      ,[sqfinalwgt_22]
      ,[sqfinalwgt_23]
      ,[sqfinalwgt_24]
      ,[sqfinalwgt_25]
      ,[sqfinalwgt_26]
      ,[sqfinalwgt_27]
      ,[sqfinalwgt_28]
      ,[sqfinalwgt_29]
      ,[sqfinalwgt_30]
      ,[sqfinalwgt_31]
      ,[sqfinalwgt_32]
      ,[sqfinalwgt_33]
      ,[sqfinalwgt_34]
      ,[sqfinalwgt_35]
      ,[sqfinalwgt_36]
      ,[sqfinalwgt_37]
      ,[sqfinalwgt_38]
      ,[sqfinalwgt_39]
      ,[sqfinalwgt_40]
      ,[sqfinalwgt_41]
      ,[sqfinalwgt_42]
      ,[sqfinalwgt_43]
      ,[sqfinalwgt_44]
      ,[sqfinalwgt_45]
      ,[sqfinalwgt_46]
      ,[sqfinalwgt_47]
      ,[sqfinalwgt_48]
      ,[sqfinalwgt_49]
      ,[sqfinalwgt_50]
      ,[sqfinalwgt_51]
      ,[sqfinalwgt_52]
      ,[sqfinalwgt_53]
      ,[sqfinalwgt_54]
      ,[sqfinalwgt_55]
      ,[sqfinalwgt_56]
      ,[sqfinalwgt_57]
      ,[sqfinalwgt_58]
      ,[sqfinalwgt_59]
      ,[sqfinalwgt_60]
      ,[sqfinalwgt_61]
      ,[sqfinalwgt_62]
      ,[sqfinalwgt_63]
      ,[sqfinalwgt_64]
      ,[sqfinalwgt_65]
      ,[sqfinalwgt_66]
      ,[sqfinalwgt_67]
      ,[sqfinalwgt_68]
      ,[sqfinalwgt_69]
      ,[sqfinalwgt_70]
      ,[sqfinalwgt_71]
      ,[sqfinalwgt_72]
      ,[sqfinalwgt_73]
      ,[sqfinalwgt_74]
      ,[sqfinalwgt_75]
      ,[sqfinalwgt_76]
      ,[sqfinalwgt_77]
      ,[sqfinalwgt_78]
      ,[sqfinalwgt_79]
      ,[sqfinalwgt_80]
      ,[sqfinalwgt_81]
      ,[sqfinalwgt_82]
      ,[sqfinalwgt_83]
      ,[sqfinalwgt_84]
      ,[sqfinalwgt_85]
      ,[sqfinalwgt_86]
      ,[sqfinalwgt_87]
      ,[sqfinalwgt_88]
      ,[sqfinalwgt_89]
      ,[sqfinalwgt_90]
      ,[sqfinalwgt_91]
      ,[sqfinalwgt_92]
      ,[sqfinalwgt_93]
      ,[sqfinalwgt_94]
      ,[sqfinalwgt_95]
      ,[sqfinalwgt_96]
      ,[sqfinalwgt_97]
      ,[sqfinalwgt_98]
      ,[sqfinalwgt_99]
      ,[sqfinalwgt_100]


			from #nov20_WB_supp
 union all 
 select [snz_hlfs_uid],	DVHHType,DVHHTen,DVRegCouncil, DVFam_WithPartner, [dob_month] ,[dob_year], [dvsex], [dvyrsinnz], DVFam_ParentRole, DVFam_NumDepChild,DVFam_NumIndepChild, 
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
			,PWB_qSafeNightHood		-- How safe or unsafe feel when walking alone in neighbourhood after dark
			,[DVWHO5_Raw]			-- Raw mental wellbeing score based on WHO-5 wellbeing index
			,[DVWHO5]				-- Weighted mental wellbeing score based on WHO-5 wellbeing index
			,PWB_qFamWellbeing
			,[quarter] as [quarter_nbr]
			 --,DVHHTen				-- Household tenure
			,case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as partnered_father_depchild,
			case when DVFam_WithPartner = 1 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as partnered_mother_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild >= 1 then 1 end as solo_father_depchild,
			case when DVFam_WithPartner = 0 and DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild >= 1 then 1 end as solo_mother_depchild,
			case when DVFam_ParentRole = 1 and [dvsex] = 1 and DVFam_NumDepChild <= 0 then 1 end as other_father,
			case when DVFam_ParentRole = 1 and [dvsex] = 2 and DVFam_NumDepChild <= 0 then 1 end as other_mother

			      ,[sqfinalwgt]
      ,[sqfinalwgt_1]
      ,[sqfinalwgt_2]
      ,[sqfinalwgt_3]
      ,[sqfinalwgt_4]
      ,[sqfinalwgt_5]
      ,[sqfinalwgt_6]
      ,[sqfinalwgt_7]
      ,[sqfinalwgt_8]
      ,[sqfinalwgt_9]
      ,[sqfinalwgt_10]
      ,[sqfinalwgt_11]
      ,[sqfinalwgt_12]
      ,[sqfinalwgt_13]
      ,[sqfinalwgt_14]
      ,[sqfinalwgt_15]
      ,[sqfinalwgt_16]
      ,[sqfinalwgt_17]
      ,[sqfinalwgt_18]
      ,[sqfinalwgt_19]
      ,[sqfinalwgt_20]
      ,[sqfinalwgt_21]
      ,[sqfinalwgt_22]
      ,[sqfinalwgt_23]
      ,[sqfinalwgt_24]
      ,[sqfinalwgt_25]
      ,[sqfinalwgt_26]
      ,[sqfinalwgt_27]
      ,[sqfinalwgt_28]
      ,[sqfinalwgt_29]
      ,[sqfinalwgt_30]
      ,[sqfinalwgt_31]
      ,[sqfinalwgt_32]
      ,[sqfinalwgt_33]
      ,[sqfinalwgt_34]
      ,[sqfinalwgt_35]
      ,[sqfinalwgt_36]
      ,[sqfinalwgt_37]
      ,[sqfinalwgt_38]
      ,[sqfinalwgt_39]
      ,[sqfinalwgt_40]
      ,[sqfinalwgt_41]
      ,[sqfinalwgt_42]
      ,[sqfinalwgt_43]
      ,[sqfinalwgt_44]
      ,[sqfinalwgt_45]
      ,[sqfinalwgt_46]
      ,[sqfinalwgt_47]
      ,[sqfinalwgt_48]
      ,[sqfinalwgt_49]
      ,[sqfinalwgt_50]
      ,[sqfinalwgt_51]
      ,[sqfinalwgt_52]
      ,[sqfinalwgt_53]
      ,[sqfinalwgt_54]
      ,[sqfinalwgt_55]
      ,[sqfinalwgt_56]
      ,[sqfinalwgt_57]
      ,[sqfinalwgt_58]
      ,[sqfinalwgt_59]
      ,[sqfinalwgt_60]
      ,[sqfinalwgt_61]
      ,[sqfinalwgt_62]
      ,[sqfinalwgt_63]
      ,[sqfinalwgt_64]
      ,[sqfinalwgt_65]
      ,[sqfinalwgt_66]
      ,[sqfinalwgt_67]
      ,[sqfinalwgt_68]
      ,[sqfinalwgt_69]
      ,[sqfinalwgt_70]
      ,[sqfinalwgt_71]
      ,[sqfinalwgt_72]
      ,[sqfinalwgt_73]
      ,[sqfinalwgt_74]
      ,[sqfinalwgt_75]
      ,[sqfinalwgt_76]
      ,[sqfinalwgt_77]
      ,[sqfinalwgt_78]
      ,[sqfinalwgt_79]
      ,[sqfinalwgt_80]
      ,[sqfinalwgt_81]
      ,[sqfinalwgt_82]
      ,[sqfinalwgt_83]
      ,[sqfinalwgt_84]
      ,[sqfinalwgt_85]
      ,[sqfinalwgt_86]
      ,[sqfinalwgt_87]
      ,[sqfinalwgt_88]
      ,[sqfinalwgt_89]
      ,[sqfinalwgt_90]
      ,[sqfinalwgt_91]
      ,[sqfinalwgt_92]
      ,[sqfinalwgt_93]
      ,[sqfinalwgt_94]
      ,[sqfinalwgt_95]
      ,[sqfinalwgt_96]
      ,[sqfinalwgt_97]
      ,[sqfinalwgt_98]
      ,[sqfinalwgt_99]
      ,[sqfinalwgt_100]

			from [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202008]
 ) as a 


 
  drop table  [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables_202203]
  select 	snz_uid,
		a.[snz_hlfs_uid]
		,datediff(year,datefromparts([dob_year], [dob_month], 15),[interview_date])  as age 
		,[quarter_nbr]
      ,[DVHHType]
      ,[DVHHTen]
      ,[DVRegCouncil]
      ,[DVFam_WithPartner]
      ,[dvsex]
	  ,[dvyrsinnz]
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
	  ,PWB_qSafeNightHood		
	  ,[DVWHO5_Raw]			
	  ,[DVWHO5]		
	  ,PWB_qFamWellbeing
      ,[partnered_father_depchild]
      ,[partnered_mother_depchild]
      ,[solo_father_depchild]
      ,[solo_mother_depchild]
      ,[other_father]
      ,[other_mother]
	        ,[sqfinalwgt]
      ,[sqfinalwgt_1]
      ,[sqfinalwgt_2]
      ,[sqfinalwgt_3]
      ,[sqfinalwgt_4]
      ,[sqfinalwgt_5]
      ,[sqfinalwgt_6]
      ,[sqfinalwgt_7]
      ,[sqfinalwgt_8]
      ,[sqfinalwgt_9]
      ,[sqfinalwgt_10]
      ,[sqfinalwgt_11]
      ,[sqfinalwgt_12]
      ,[sqfinalwgt_13]
      ,[sqfinalwgt_14]
      ,[sqfinalwgt_15]
      ,[sqfinalwgt_16]
      ,[sqfinalwgt_17]
      ,[sqfinalwgt_18]
      ,[sqfinalwgt_19]
      ,[sqfinalwgt_20]
      ,[sqfinalwgt_21]
      ,[sqfinalwgt_22]
      ,[sqfinalwgt_23]
      ,[sqfinalwgt_24]
      ,[sqfinalwgt_25]
      ,[sqfinalwgt_26]
      ,[sqfinalwgt_27]
      ,[sqfinalwgt_28]
      ,[sqfinalwgt_29]
      ,[sqfinalwgt_30]
      ,[sqfinalwgt_31]
      ,[sqfinalwgt_32]
      ,[sqfinalwgt_33]
      ,[sqfinalwgt_34]
      ,[sqfinalwgt_35]
      ,[sqfinalwgt_36]
      ,[sqfinalwgt_37]
      ,[sqfinalwgt_38]
      ,[sqfinalwgt_39]
      ,[sqfinalwgt_40]
      ,[sqfinalwgt_41]
      ,[sqfinalwgt_42]
      ,[sqfinalwgt_43]
      ,[sqfinalwgt_44]
      ,[sqfinalwgt_45]
      ,[sqfinalwgt_46]
      ,[sqfinalwgt_47]
      ,[sqfinalwgt_48]
      ,[sqfinalwgt_49]
      ,[sqfinalwgt_50]
      ,[sqfinalwgt_51]
      ,[sqfinalwgt_52]
      ,[sqfinalwgt_53]
      ,[sqfinalwgt_54]
      ,[sqfinalwgt_55]
      ,[sqfinalwgt_56]
      ,[sqfinalwgt_57]
      ,[sqfinalwgt_58]
      ,[sqfinalwgt_59]
      ,[sqfinalwgt_60]
      ,[sqfinalwgt_61]
      ,[sqfinalwgt_62]
      ,[sqfinalwgt_63]
      ,[sqfinalwgt_64]
      ,[sqfinalwgt_65]
      ,[sqfinalwgt_66]
      ,[sqfinalwgt_67]
      ,[sqfinalwgt_68]
      ,[sqfinalwgt_69]
      ,[sqfinalwgt_70]
      ,[sqfinalwgt_71]
      ,[sqfinalwgt_72]
      ,[sqfinalwgt_73]
      ,[sqfinalwgt_74]
      ,[sqfinalwgt_75]
      ,[sqfinalwgt_76]
      ,[sqfinalwgt_77]
      ,[sqfinalwgt_78]
      ,[sqfinalwgt_79]
      ,[sqfinalwgt_80]
      ,[sqfinalwgt_81]
      ,[sqfinalwgt_82]
      ,[sqfinalwgt_83]
      ,[sqfinalwgt_84]
      ,[sqfinalwgt_85]
      ,[sqfinalwgt_86]
      ,[sqfinalwgt_87]
      ,[sqfinalwgt_88]
      ,[sqfinalwgt_89]
      ,[sqfinalwgt_90]
      ,[sqfinalwgt_91]
      ,[sqfinalwgt_92]
      ,[sqfinalwgt_93]
      ,[sqfinalwgt_94]
      ,[sqfinalwgt_95]
      ,[sqfinalwgt_96]
      ,[sqfinalwgt_97]
      ,[sqfinalwgt_98]
      ,[sqfinalwgt_99]
      ,[sqfinalwgt_100]

	  into [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables_202203]
  FROM #tmp_HLFS as a left join  [IDI_Clean_202203].[security].[concordance] as b on a.[snz_hlfs_uid] = b.[snz_hlfs_uid] 
 

 