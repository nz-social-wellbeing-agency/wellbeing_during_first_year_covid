/**************************************************************************************************
Title: Homelessness indicator
Date: 8/03/2022
Author: Verity Warn, based on Craig's Wright code

Inputs & Dependencies:
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_OCCDWELTYPE]
- [IDI_Clean_20211020].[msd_clean].[msd_third_tier_expenditure]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_pay_reason]
- [IDI_Clean_20211020].[msd_clean].[msd_partner]
- [IDI_Clean_20211020].[msd_clean].[msd_child]
- [IDI_Clean_20211020].[hnz_clean].[new_applications]
- [IDI_Clean_20211020].[hnz_clean].[new_applications_household]

Outputs:
- [IDI_Sandpit].[DL-MAA2021-60].[homelessness_ind]

Description:
- Create a list of all snz_uids who, based on this definition, are homeless
- This definition uses MSD emergency housing and HNZ social housing applications in order to identify homelessness/severly inadequate housing

Intended purpose:
- To identify characteristics & service interactions of those who are homeless

Issues:
- 

Parameters & Present values:
  Current refresh = 20211020
  Prefix = defn_
  Project schema = [DL-MAA2021-60]
  Study year: 2019


History (reverse order):

**************************************************************************************************/

/* 

Plan:

1. Identify homelessness through emergency housing
2. Identify homelessness through social housing applications
3. Union all snz_uid (distinct) = homeless-at-some-pt-in-2019 population 

*/


/***** Emergency housing (MSD) users in 2019 *****/

	/* 1. Identify all primary applicants */
	DROP TABLE IF EXISTS #primary_eh
	SELECT snz_uid
		,msd_tte_app_date
	INTO #primary_eh
	FROM (
		SELECT * 
		FROM [IDI_Clean_20211020].[msd_clean].[msd_third_tier_expenditure] 
		WHERE [msd_tte_pmt_rsn_type_code] in ('855') -- emergency housing  
		AND [msd_tte_app_date] >= datefromparts(2019,1,1) 
		AND [msd_tte_app_date] <= datefromparts(2019,12,31)
		) AS a
	LEFT JOIN 
	[IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_pay_reason] AS b
	ON a.msd_tte_pmt_rsn_type_code = b.payrsn_code


	/* 2. Identify partners of primary applications */
	DROP TABLE IF EXISTS #partner_eh
	SELECT a.snz_uid
		,[partner_snz_uid]
		,[msd_tte_app_date]
	INTO #partner_eh
	FROM #primary_eh AS a
	INNER JOIN 
	[IDI_Clean_20211020].[msd_clean].[msd_partner] AS b
	ON a.snz_uid =b.snz_uid 
	WHERE [msd_ptnr_ptnr_from_date]<=[msd_tte_app_date] 
	AND [msd_ptnr_ptnr_to_date]>=[msd_tte_app_date]


	/* 3. Identify children of primary applicants */
	DROP TABLE IF EXISTS #children_eh
	SELECT distinct a.[snz_uid]
		,[child_snz_uid]
		,[msd_tte_app_date]
	INTO #children_eh
	FROM #primary_eh AS a
	INNER JOIN
	[IDI_Clean_20211020].[msd_clean].[msd_child] as b
	ON a.snz_uid=b.snz_uid
	WHERE [msd_chld_child_from_date]<=[msd_tte_app_date] 
	AND [msd_chld_child_to_date]>=[msd_tte_app_date]


	/* 4. Union distinct primary, partner and children emergency housing users */
	DROP TABLE IF EXISTS #EH_homeless
	SELECT snz_uid
		,count(*) as num_eh -- this count is just for interest, not need for definition
	INTO #EH_homeless
	FROM (
		SELECT snz_uid FROM #primary_eh
		UNION ALL
		SELECT partner_snz_uid AS snz_uid FROM #partner_eh
		UNION ALL
		SELECT child_snz_uid AS snz_uid FROM #children_eh		
		) AS a
	GROUP BY snz_uid

	--select num_eh, count(*) from #eh_homeless group by num_eh order by num_eh ASC -- frequency of use


/***** Homelessness from social housing applications *****/

	DROP TABLE IF EXISTS #SH_homeless
	SELECT b.[snz_uid]
		--,[hnz_na_date_of_application_date]
		--,a.[snz_msd_application_uid]
		--,[hnz_na_main_reason_app_text]
		--,[snz_idi_address_register_uid]
	INTO #SH_homeless
	FROM [IDI_Clean_20211020].[hnz_clean].[new_applications] as a, [IDI_Clean_20211020].[hnz_clean].[new_applications_household] as b
	WHERE a.snz_msd_application_uid=b.snz_msd_application_uid 
		AND cast([hnz_na_date_of_application_date] as date) >= datefromparts(2019,1,1) 
		AND cast([hnz_na_date_of_application_date] as date) <= datefromparts(2019,12,31) 
		AND [hnz_na_main_reason_app_text] in ('HOMELESSNESS','CURRENT ACCOMMODATION IS INADEQUATE OR UNSUITABLE','INADEQUATE','UNSUITABLE')

	
/***** Join all homeless groups together, find distinct population *****/

	DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-60].[homelessness_ind]
	SELECT DISTINCT snz_uid 
	INTO [IDI_Sandpit].[DL-MAA2021-60].[homelessness_ind]
	FROM (
		--SELECT snz_uid FROM #census_homeless
		--UNION ALL
		SELECT snz_uid FROM #EH_homeless
		UNION ALL
		SELECT snz_uid FROM #SH_homeless		
		) AS a
	GROUP BY snz_uid

	-- xx,xxx 
	-- xx,xxx as at 25.3.22 ???

	DROP TABLE IF EXISTS #EH_homeless
	DROP TABLE IF EXISTS #SH_homeless
