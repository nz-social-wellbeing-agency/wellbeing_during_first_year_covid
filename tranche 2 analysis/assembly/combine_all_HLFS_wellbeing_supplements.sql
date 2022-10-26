/**************************************************************************************************
Panel of HLFS wellbeing supplements
Simon Anastasiadis
2022-06-29

Project: wellbeing report - tranche 2
Purpose: dataset assembly and preparation

-- Origin --
Project: wellbeing report - tranche 1
File: GSS_HLFS_data_and_pop.sql
Author: Shaan Badenhorst
Date: April 2022

-- Inputs --
[IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202008]
[IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202011]
[IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202102] 
[IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202105]
[IDI_Clean_202203].[security].[concordance]

-- Outputs --
[IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables]

-- Notes --
1) During 2020 and 2021, there were four waves of the HLFS that included a wellbeing supplement.
	While there were some changes between the waves, many questions are consistent across waves.
	This code gathers together a panel dataset of those columns that are (1) consistent across
	waves, and (2) of interest for our analysis. A full list of columns that are consistent can
	be found in "align HLFS wellbeing supplements.xlsx"
2) This dataset is the only panel dataset with wellbeing measures, that we are aware of in the IDI.
	It was collected during the COVID pandemic and hence is affected by this. These effects will
	include both national level effects (e.g. lockdowns) and individual effects (such as changes
	in response rates by deprivation due to the move to phone interviews).
3) At construction, we have not filtered to only those who answered all four waves. The HLFS uses
	a rolling panel, with people in the survey for several consecutive waves. Consequently, some
	respondents were not given the chance to answer certain waves because they were starting, or
	had finished, their consecutive waves.
4) We have built this as our best attempt to reconstruct the input dataset from tranche 1 of the
	wellbeing report analysis. However, lacking well documented code, we have had to make some
	assumptions during our process. We will test these assumptions prior to using the data.

**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables];
GO

WITH
/********************
first wave, August 2020
********************/
wave1_august2020 AS (
	SELECT [snz_hlfs_uid]
		,[snz_hlfs_hhld_uid]
		,DVHHType
		,DVHHTen
		,DVRegCouncil
		,DVFam_WithPartner
		,[dvsex]
		,DVFam_ParentRole
		,DVFam_NumDepChild
		,DVFam_NumIndepChild
		,EthEuropean
		,EthMaori
		,EthPacific
		,EthAsian
		,EthMELAA
		,EthOther
		,'aug20' AS wave
		,datefromparts(year(sqd_fsqinterviewdate),month(sqd_fsqinterviewdate),day(sqd_fsqinterviewdate) )  AS interview_date
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
		,[hcq_qdampormould]
		,[hcq_qkeepingwarm] 
		,[sqfinalwgt]
	FROM [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202008]
),
/********************
second wave, November 2020
********************/
wave2_november2020 AS (
	SELECT [snz_hlfs_uid]
		,[snz_hlfs_hhld_uid]
		,DVHHType
		,DVHHTen
		,DVRegCouncil
		,DVFam_WithPartner
		,[dvsex]
		,DVFam_ParentRole
		,DVFam_NumDepChild
		,DVFam_NumIndepChild
		,EthEuropean
		,EthMaori
		,EthPacific
		,EthAsian
		,EthMELAA
		,EthOther
		,'nov20' AS wave
		,CONVERT(DATETIME, sqd_fsqinterviewdate,103) AS interview_date
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
		,NULL AS PWB_qSafeNightHood		
		,NULL AS [DVWHO5_Raw]		-- Raw mental wellbeing score based on WHO-5 wellbeing index
		,NULL AS [DVWHO5]
		,PWB_qFamWellbeing
		,[hcq_qdampormould]
		,[hcq_qkeepingwarm] 
		,[sqfinalwgt]
	FROM [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202011]
),
/********************
third wave, February 2021
********************/
wave3_february2021 AS (
	SELECT [snz_hlfs_uid]
		,[snz_hlfs_hhld_uid]
		,DVHHType
		,DVHHTen
		,DVRegCouncil
		,DVFam_WithPartner
		,[dvsex]
		,DVFam_ParentRole
		,DVFam_NumDepChild
		,DVFam_NumIndepChild
		,EthEuropean
		,EthMaori
		,EthPacific
		,EthAsian
		,EthMELAA
		,EthOther
		,'feb21' AS wave
		,CONVERT(DATETIME, sqd_fsqinterviewdate,103) AS interview_date
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
		,NULL AS PWB_qSafeNightHood		
		,NULL AS [DVWHO5_Raw]		-- Raw mental wellbeing score based on WHO-5 wellbeing index
		,NULL AS [DVWHO5]
		,PWB_qFamWellbeing
		,[hcq_qdampormould]
		,[hcq_qkeepingwarm] 
		,[sqfinalwgt]
	FROM [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202102] 
),
/********************
fourth wave, May 2021
********************/
wave4_may2021 AS (
	SELECT [snz_hlfs_uid]
		,[snz_hlfs_hhld_uid]
		,DVHHType
		,DVHHTen
		,DVRegCouncil
		,DVFam_WithPartner
		,[dvsex] 
		,DVFam_ParentRole
		,DVFam_NumDepChild
		,DVFam_NumIndepChild 
		,EthEuropean
		,EthMaori
		,EthPacific
		,EthAsian
		,EthMELAA
		,EthOther
		,'may21' AS wave
		,CONVERT(DATETIME, sqd_fsqinterviewdate,103) AS interview_date
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
		,NULL AS PWB_qSafeNightHood		
		,NULL AS [DVWHO5_Raw]		-- Raw mental wellbeing score based on WHO-5 wellbeing index
		,NULL AS [DVWHO5]
		,PWB_qFamWellbeing
		,[hcq_qdampormould]
		,[hcq_qkeepingwarm] 
		,[sqfinalwgt]
	FROM [IDI_Adhoc].[clean_read_HLFS].[hlfs_wellbeing_202105]
)
SELECT c.snz_uid, k.*
INTO [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables]
FROM (
	SELECT *
	FROM wave1_august2020

	UNION ALL

	SELECT *
	FROM wave2_november2020

	UNION ALL

	SELECT *
	FROM wave3_february2021

	UNION ALL

	SELECT *
	FROM wave4_may2021
) AS k
LEFT JOIN [IDI_Clean_202203].[security].[concordance] AS c
ON k.snz_hlfs_uid = c.snz_hlfs_uid
GO

/* compress & index */
CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables] ([snz_uid])

ALTER TABLE [IDI_Sandpit].[DL-MAA2021-55].[WBR_Wellbeing_supp_tables] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
