/**************************************************************************************************
Title: Youngest dependent child
Author: Simon Anastasiadis 

Inputs & Dependencies:
- [IDI_Clean].[data].[personal_detail]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-55].[defn_youngest_dependent_child]

Description:
Year and month of birth for youngest dependent child born in NZ.

Intended purpose:
Counting the number of dependent children that a person has at any point in time.

Notes:
1) There is no control for whether a person lives with (their) children or is
   involved in their care. Only considers parents by birth so legal guardians
   can not be identified this way.
2) Only considers children born in NZ, as application is NZ-based parental entitlements.
3) Uses all dates up to a given point in time.
3) Requires child is still alive at given point in time.

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2021-55]
  Given date = '2021-06-30'

History (reverse order):
2022-06-30 SA v1
**************************************************************************************************/

/* Clear before creation */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-55].[defn_youngest_dependent_child];
GO

WITH both_parent_input AS (

	SELECT [snz_parent1_uid]
		,[snz_parent2_uid]
		,[snz_birth_date_proxy] AS child_birth_date_proxy
		,[snz_birth_year_nbr] AS child_birth_year
		,[snz_birth_month_nbr] AS child_birth_month
		,[snz_deceased_year_nbr] AS child_deceased_year
		,[snz_deceased_month_nbr] AS child_deceased_month
	FROM [IDI_Clean_202203].[data].[personal_detail]
	WHERE [snz_uid] IS NOT NULL
	AND [snz_birth_year_nbr] IS NOT NULL
	AND [snz_birth_month_nbr] IS NOT NULL
	and [snz_birth_year_nbr] <> 9999
	AND DATEFROMPARTS([snz_birth_year_nbr], [snz_birth_month_nbr], 15) <= '2021-06-30' --born before given date
	AND (
		[snz_deceased_year_nbr] IS NULL
		OR DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 15) >= '2021-06-30' --still alive at given date
	)

)
SELECT *
INTO [IDI_Sandpit].[DL-MAA2021-55].[defn_youngest_dependent_child]
FROM (
	/* parent 1 */
	SELECT [snz_parent1_uid] AS [snz_uid]
		,child_birth_date_proxy
		,child_birth_year
		,child_birth_month
		,child_deceased_year
		,child_deceased_month
	FROM both_parent_input
	WHERE [snz_parent1_uid] IS NOT NULL

	UNION ALL

	/* parent 2 */
	SELECT [snz_parent2_uid] AS [snz_uid]
		,child_birth_date_proxy
		,child_birth_year
		,child_birth_month
		,child_deceased_year
		,child_deceased_month
	FROM both_parent_input
	WHERE [snz_parent2_uid] IS NOT NULL
	AND [snz_parent1_uid] <> [snz_parent2_uid] -- parents are different
) k
GO


/* drop all children other than the one with the latest birth date */
WITH order_by_birth AS (
	SELECT *
		,ROW_NUMBER() OVER (PARTITION BY snz_uid ORDER BY child_birth_date_proxy DESC) AS rn
	FROM [IDI_Sandpit].[DL-MAA2021-55].[defn_youngest_dependent_child]
)
DELETE FROM order_by_birth
WHERE rn <> 1

/* compress & index */
CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-55].[defn_youngest_dependent_child] ([snz_uid])

ALTER TABLE [IDI_Sandpit].[DL-MAA2021-55].[defn_youngest_dependent_child] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
