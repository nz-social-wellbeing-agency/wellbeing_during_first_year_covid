/**************************************************************************************************
Title: Assemble research dataset for tranche 2 wellbeing report

Inputs & Dependencies:
- "combine_all_HLFS_wellbeing_supplements.sql" --> [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables]
- "youngest_dependent_children.sql" --> [IDI_Sandpit].[DL-MAA2021-55].[defn_youngest_dependent_child]
- "annual_income_bnt.sql" --> [IDI_Sandpit].[DL-MAA2021-55].[defn_all_income]
- "main_benefits_by_type_and_partner_status.sql" --> [IDI_Sandpit].[DL-MAA2021-55].[defn_main_benefit_by_type]
- [IDI_Clean_202203].[data].[personal_detail]

Outputs:
- [IDI_Sandpit].[DL-MAA2021-55].[wbr_panel_assembled]

Notes:
1) Validated that waves and interview dates are consistent.
	The date for each wave is approximately one month after the last interview date.
2) There appears to be a small number of records (<20) where the same snz_uid appears more than once
	within a single wave. We will need to filter these individuals out of later analysis.
	This is likely caused by overlaps in benefit spells (e.g. two benefit types recorded at once).
3) We allowed for benefit type to vary over time. However, few respondents change benefit type
	between waves (<50). Hence this will not be worth focusing on.
4) Validation against tranche 1, comparing counts by quarter and parental status:
	- Near perfect consistency with tranche 1 Sandpit table
	- Near perfect consistency with "Table_dataset" file from tranche 1
 
History (reverse order):
2022-07-01 SA v1
**************************************************************************************************/

/* remove table before recreating */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-55].[wbr_panel_assembled];
GO

/* income data preparation - average over two years */
WITH INCOME_PREP AS (

SELECT [snz_uid]
	,[start_date]
	,[end_date]
	,ISNULL([inc_tax_yr_sum_WAS_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_WHP_tot_amt], 0) AS inc_employ
	,ISNULL([inc_tax_yr_sum_BEN_tot_amt], 0) AS inc_benefit
	,ISNULL([inc_tax_yr_sum_C00_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_C01_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_C02_tot_amt], 0) AS inc_company
	,ISNULL([inc_tax_yr_sum_P00_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_P01_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_P02_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_S00_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_S01_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_S02_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_S03_tot_amt], 0) AS inc_self_emp
	,ISNULL([inc_tax_yr_sum_ACC_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_PEN_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_PPL_tot_amt], 0)
		+ ISNULL([inc_tax_yr_sum_STU_tot_amt], 0) AS inc_other
	,[inc_tax_yr_sum_all_srces_tot_amt] AS inc_taxible
	,ISNULL([bet_pmt_tier2], 0)
		+ ISNULL([bet_pmt_tier3], 0)
		+ ISNULL([wff_pmt_neg_adj], 0) AS inc_non_taxible
	,ISNULL([inc_tax_yr_inc_bnt], 0) AS inc_grand_total
FROM [IDI_Sandpit].[DL-MAA2021-55].[defn_all_income]
WHERE YEAR([start_date]) IN (2020, 2021)

),
INCOME_AVERAGE AS (

SELECT snz_uid
	,SUM(inc_employ) / 2 AS inc_employ
	,SUM(inc_benefit) / 2 AS inc_benefit
	,SUM(inc_company) / 2 AS inc_company
	,SUM(inc_self_emp) / 2 AS inc_self_emp
	,SUM(inc_other) / 2 AS inc_other
	,SUM(inc_taxible) / 2 AS inc_taxible
	,SUM(inc_non_taxible) / 2 AS inc_non_taxible
	,SUM(inc_grand_total) / 2 AS inc_grand_total
FROM INCOME_PREP
GROUP BY snz_uid

)
/* assemble data together */
SELECT a.[snz_uid]
	/* suvery panel */
	,[snz_hlfs_uid]
	,[snz_hlfs_hhld_uid]
	,[wave]
	,[interview_date]
	,[DVHHType]
	,[DVHHTen]
	,[DVRegCouncil]
	,[DVFam_WithPartner]
	,[dvsex]
	,[DVFam_ParentRole]
	,a.[DVFam_NumDepChild]
	,[DVFam_NumIndepChild]
	,[EthEuropean]
	,[EthMaori]
	,[EthPacific]
	,[EthAsian]
	,[EthMELAA]
	,[EthOther]
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
	,[PWB_qSafeNightHood]
	,[DVWHO5_Raw]
	,[DVWHO5]
	,[PWB_qFamWellbeing]
	,[hcq_qdampormould]
	,[hcq_qkeepingwarm] 
	,[sqfinalwgt]
	/* youngest child */
	,c.[child_birth_date_proxy]
	,c.[child_birth_year]
	,c.[child_birth_month]
	/* average income */
	,i.inc_employ
	,i.inc_benefit
	,i.inc_company
	,i.inc_self_emp
	,i.inc_other
	,i.inc_taxible
	,i.inc_non_taxible
	,i.inc_grand_total
	/* benefit status */
	,COALESCE(b1.[level4], b2.[level4], b3.[level4], b4.[level4]) AS benefit_receipt
	/* parental status */
	,IIF(DVFam_WithPartner = 1 AND DVFam_ParentRole = 1 AND [dvsex] = 1 AND DVFam_NumDepChild >= 1, 1, 0) AS partnered_father_depchild
	,IIF(DVFam_WithPartner = 1 AND DVFam_ParentRole = 1 AND [dvsex] = 2 AND DVFam_NumDepChild >= 1, 1, 0) AS partnered_mother_depchild
	,IIF(DVFam_WithPartner = 0 AND DVFam_ParentRole = 1 AND [dvsex] = 1 AND DVFam_NumDepChild >= 1, 1, 0) AS solo_father_depchild
	,IIF(DVFam_WithPartner = 0 AND DVFam_ParentRole = 1 AND [dvsex] = 2 AND DVFam_NumDepChild >= 1, 1, 0) AS solo_mother_depchild
	,IIF(DVFam_ParentRole = 1 AND [dvsex] = 1 AND DVFam_NumDepChild <= 0, 1, 0) AS other_father
	,IIF(DVFam_ParentRole = 1 AND [dvsex] = 2 AND DVFam_NumDepChild <= 0, 1, 0) AS other_mother
	/* personal details */
	,p.[snz_birth_year_nbr]
INTO [IDI_Sandpit].[DL-MAA2021-55].[wbr_panel_assembled]
FROM [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables] AS a
LEFT JOIN [IDI_Sandpit].[DL-MAA2021-55].[defn_youngest_dependent_child] AS c
ON a.snz_uid = c.snz_uid
LEFT JOIN INCOME_AVERAGE AS i
ON a.snz_uid = i.snz_uid

LEFT JOIN [IDI_Sandpit].[DL-MAA2021-55].[defn_main_benefit_by_type] AS b1
ON a.snz_uid = b1.snz_uid
AND a.wave = 'aug20'
AND [interview_date] BETWEEN b1.[start_date] AND b1.[end_date]

LEFT JOIN [IDI_Sandpit].[DL-MAA2021-55].[defn_main_benefit_by_type] AS b2
ON a.snz_uid = b2.snz_uid
AND a.wave = 'nov20'
AND [interview_date] BETWEEN b2.[start_date] AND b2.[end_date]

LEFT JOIN [IDI_Sandpit].[DL-MAA2021-55].[defn_main_benefit_by_type] AS b3
ON a.snz_uid = b3.snz_uid
AND a.wave = 'feb21'
AND [interview_date] BETWEEN b3.[start_date] AND b3.[end_date]

LEFT JOIN [IDI_Sandpit].[DL-MAA2021-55].[defn_main_benefit_by_type] AS b4
ON a.snz_uid = b4.snz_uid
AND a.wave = 'may21'
AND [interview_date] BETWEEN b4.[start_date] AND b4.[end_date]

LEFT JOIN [IDI_Clean_202203].[data].[personal_detail] AS p
ON a.snz_uid = p.snz_uid
GO

/* index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-55].[wbr_panel_assembled] (snz_uid, wave);
GO
/* compress */
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-55].[wbr_panel_assembled] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO
