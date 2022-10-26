###################################################################################################
#' Description: Tidy assembled data
#'
#' Input: Rectangular table produced by run_assembly
#'
#' Output: Tidied table
#' 
#' Author: Simon Anastasiadis
#' 
#' Dependencies: dbplyr_helper_functions.R, utility_functions.R, table_consistency_checks.R,
#' overview_dataset.R, summary_confidential.R
#' 
#' Notes: 
#' 
#' Issues:
#' 
#' History (reverse order):
#' 2022-07-05 SA v1
#' 2022-07-01 SA begun
###################################################################################################

## reference dates --------------------------------------------------------------------------------
#'
#' Families Package:
#'   increase 1 July 2018
#'   increase 1 July 2020
#' Accomodation Supplement
#'   increase 1 April 2018
#' Familiy Tax Credit
#'   increase 1 July 2018
#' Winter Energy Payment
#'   increase 1 July 2018
#'   doubled for winter 2020: 1 May - 30 September
#' Benefit rates
#'   increase 1 July 2021
#'   increase 1 April 2022
#' Student supprt
#'   increase 1 April
#' 
#' COVID response
#'   borders closed 19 March 2020
#'   National lockdown starts (level 4) 26 March 2020
#'   National lockdown ends (level 2) 13 May 2020
#'   Auckland lockdown starts (level 3) 12 August 2020
#'   Auckland lockdown ends (level 2) 30 August 2020
#'   Auckland lockdown starts (level 3) 15 February 2021
#'   Auckland lockdown ends (level 2) 17 February 2021
#'   Auckland lockdown starts (level 3) 28 February 2021
#'   Auckland lockdown ends (level 2) 6 March 2021
#'   National lockdown starts (level 4) 18 August 2021
#'   

## parameters -------------------------------------------------------------------------------------

# locations
ABSOLUTE_PATH_TO_TOOL <- "/nas/DataLab/MAA/MAA2021-55/wellbeing report - tranche 2/Tools/Dataset Assembly Tool"
ABSOLUTE_PATH_TO_ANALYSIS <- "/nas/DataLab/MAA/MAA2021-55/wellbeing report - tranche 2/Analysis"
SANDPIT = "[IDI_Sandpit]"
USERCODE = "[IDI_UserCode]"
OUR_SCHEMA = "[DL-MAA2021-55]"

# inputs
ASSEMBLED_TABLE = "[wbr_panel_assembled]"
# outputs
FULL_DATESSET_CSV = "./tidied_dataset.csv"
CROSSTABS_CSV = "../Output/cross_tabs.csv"

# controls
VERBOSE = "details" # {"all", "details", "heading", "none"}
MAKE_REPORTS = TRUE

## setup ------------------------------------------------------------------------------------------

setwd(ABSOLUTE_PATH_TO_TOOL)
source("utility_functions.R")
source("dbplyr_helper_functions.R")
source("table_consistency_checks.R")
source("overview_dataset.R")
source("summary_confidential.R")
setwd(ABSOLUTE_PATH_TO_ANALYSIS)

## access dataset ---------------------------------------------------------------------------------

run_time_inform_user("GRAND START", context = "heading", print_level = VERBOSE)

db_con = create_database_connection(database = "IDI_Sandpit")

working_table = create_access_point(db_con, SANDPIT, OUR_SCHEMA, ASSEMBLED_TABLE)
working_table = working_table %>% collect()

## error checking ---------------------------------------------------------------------------------

run_time_inform_user("error checks begun", context = "heading", print_level = VERBOSE)

# at least 1000 rows
assert_size(working_table, ">", 1000)

run_time_inform_user("error checks complete", context = "details", print_level = VERBOSE)

## check dataset variables ------------------------------------------------------------------------

run_time_inform_user("summary report on input data", context = "heading", print_level = VERBOSE)
if(MAKE_REPORTS){
  explore_report(working_table, id_column = "snz_uid", target = "wave", output_file = "raw_table_report")
}

## filter to complete panel -----------------------------------------------------------------------

# where we have more than one record for a person-wave pair - need to drop these records
dupes_by_uid_and_wave = working_table %>%
  group_by(snz_uid, wave) %>%
  summarise(num = n(), .groups = "drop") %>%
  filter(num != 1) %>%
  select(snz_uid) %>%
  distinct()

# where we have more than one record for a person-wave pair - need to drop these records
dupes_by_hhld_and_wave = working_table %>%
  group_by(snz_hlfs_hhld_uid, wave) %>%
  summarise(num = n(), .groups = "drop") %>%
  filter(num != 1) %>%
  select(snz_hlfs_hhld_uid) %>%
  distinct()

working_table = working_table %>%
  anti_join(dupes_by_uid_and_wave, by = "snz_uid") %>%
  anti_join(dupes_by_hhld_and_wave, by = "snz_hlfs_hhld_uid")

## recode responses code to text ------------------------------------------------------------------

working_table = working_table %>%
  mutate(
    DVHHType = case_when(
      DVHHType == 1 ~ 'Couple only',
      DVHHType == 2 ~ 'Couple only and other(s)',
      DVHHType == 3 ~ 'Couple with one dependent child',
      DVHHType == 4 ~ 'Couple with two dependent children',
      DVHHType == 5 ~ 'Couple with three or more dependent children',
      DVHHType == 6 ~ 'Couple with dependent and adult children',
      DVHHType == 7 ~ 'Couple with adult child(ren) only',
      DVHHType == 8 ~ 'Couple with dependent child(ren) and other(s)',
      DVHHType == 9 ~ 'Couple with adult child(ren) only and other(s)',
      DVHHType == 10 ~ 'One parent with dependent child(ren) only',
      DVHHType == 11 ~ 'One parent with dependent and adult children',
      DVHHType == 12 ~ 'One parent with adult child(ren) only',
      DVHHType == 13 ~ 'One parent with dependent child(ren) and other(s)',
      DVHHType == 14 ~ 'One parent with adult child(ren) only and other(s)',
      DVHHType == 15 ~ 'One-person household',
      DVHHType == 16 ~ 'Other household',
      TRUE ~ 'Household composition unidentifiable'
    ),
    DVHHTen = case_when(
      DVHHTen == 1 ~ 'Dwelling owned',
      DVHHTen == 2 ~ 'Dwelling not owned',
      DVHHTen == 3 ~ 'Dwelling owned',
      TRUE ~ 'Not specified'
    ),
    DVRegCouncil = case_when(
      DVRegCouncil == 01 ~ 'Northland',
      DVRegCouncil == 02 ~ 'Auckland',
      DVRegCouncil == 03 ~ 'Waikato',
      DVRegCouncil == 04 ~ 'Bay of Plenty',
      DVRegCouncil == 05 ~ 'Gisborne',
      DVRegCouncil == 06 ~ 'Hawkes Bay',
      DVRegCouncil == 07 ~ 'Taranaki',
      DVRegCouncil == 08 ~ 'Manawatu-Wanganui',
      DVRegCouncil == 09 ~ 'Wellington',
      DVRegCouncil == 12 ~ 'West Coast',
      DVRegCouncil == 13 ~ 'Canterbury',
      DVRegCouncil == 14 ~ 'Otago',
      DVRegCouncil == 15 ~ 'Southland',
      DVRegCouncil == 16 ~ 'Tasman',
      DVRegCouncil == 17 ~ 'Nelson',
      DVRegCouncil == 18 ~ 'Marlborough'
    ),
    DVFam_WithPartner = ifelse(DVFam_WithPartner == 1, 1, 0),
    DVFam_ParentRole = ifelse(DVFam_ParentRole == 1, 1, 0),
    dvsex = case_when(
      dvsex == 1 ~ 'male',
      dvsex == 2 ~ 'female',
      TRUE ~ 'unknown'
    ),
    DVFam_NumDepChild = ifelse(is.na(DVFam_NumDepChild), 0, DVFam_NumDepChild),
    DVLFS = case_when(
      DVLFS == 1 ~ 'employed',
      DVLFS == 2 ~ 'unemployed',
      DVLFS == 3 ~ 'not in labour force',
      TRUE ~ 'unknown'
    ),
    NumJobs = case_when(
      NumJobs == 1 ~ 'single job',
      NumJobs >= 2 ~ 'multi job',
      is.na(NumJobs) ~ 'no job'
    ),
    DVJobTenC = case_when(
      DVJobTenC == 01 ~ 'Less than 1 month',
      DVJobTenC == 02 ~ '1 month to less than 6 months',
      DVJobTenC == 03 ~ '6 months to less than 1 year',
      DVJobTenC == 04 ~ '1 year to less than 3 years',
      DVJobTenC == 05 ~ '3 years to less than 5 years',
      DVJobTenC == 06 ~ '5 years to less than 10 years',
      DVJobTenC == 07 ~ '10 years or more',
      TRUE ~ 'NA'
    ),
    DVHQual = case_when(
      DVHQual %in% c(1, 2, 3) ~ 'postgrad',
      DVHQual %in% c(4) ~ 'bachelors',
      DVHQual %in% c(5, 6, 7, 8, 9, 10, 11, 12) ~ 'post-school',
      DVHQual %in% c(13, 14, 15, 16, 17, 18, 19, 20, 21) ~ 'college',
      DVHQual %in% c(22) ~ 'none',
      TRUE ~ 'NA'
    ),
    DVStudy = case_when(
      DVStudy %in% c(1, 2, 3) ~ 1,
      DVStudy %in% c(4) ~ 0
    ),
    PWB_qFeelAboutLifeScale = ifelse(PWB_qFeelAboutLifeScale %in% 0:10, PWB_qFeelAboutLifeScale, NA),
    PWB_qThingsWorthwhileScale = ifelse(PWB_qThingsWorthwhileScale %in% 0:10, PWB_qThingsWorthwhileScale, NA),
    PWB_qTrustMostPeopleScale = ifelse(PWB_qTrustMostPeopleScale %in% 0:10, PWB_qTrustMostPeopleScale, NA),
    PWB_qTrustPol = ifelse(PWB_qTrustPol %in% 0:10, PWB_qTrustPol, NA),
    PWB_qTrustParl = ifelse(PWB_qTrustParl %in% 0:10, PWB_qTrustParl, NA),
    PWB_qTrustHlth = ifelse(PWB_qTrustHlth %in% 0:10, PWB_qTrustHlth, NA),
    PWB_qTrustMed = ifelse(PWB_qTrustMed %in% 0:10, PWB_qTrustMed, NA),
    PWB_qFamWellbeing = ifelse(PWB_qFamWellbeing %in% 0:10, PWB_qFamWellbeing, NA),
    PWB_qHealthExcellentPoor = case_when(
      PWB_qHealthExcellentPoor == 11 ~ 'Excellent',
      PWB_qHealthExcellentPoor == 12 ~ 'Very good',
      PWB_qHealthExcellentPoor == 13 ~ 'Good',
      PWB_qHealthExcellentPoor == 14 ~ 'Fair',
      PWB_qHealthExcellentPoor == 15 ~ 'Poor',
      TRUE ~ 'NA'
    ),
    PWB_qDiscriminated = ifelse(PWB_qDiscriminated == 1, 1, 0),
    PWB_qTimeLonely = case_when(
      PWB_qTimeLonely == 11 ~ 'None of the time',
      PWB_qTimeLonely == 12 ~ 'A little of the time',
      PWB_qTimeLonely == 13 ~ 'Some of the time',
      PWB_qTimeLonely == 14 ~ 'Most of the time',
      PWB_qTimeLonely == 15 ~ 'All of the time',
      TRUE ~ 'NA'
    ),
    MHS_qEnoughIncome = case_when(
      MHS_qEnoughIncome == 11 ~ 'Not enough money',
      MHS_qEnoughIncome == 12 ~ 'Only just enough money',
      MHS_qEnoughIncome == 13 ~ 'Enough money',
      MHS_qEnoughIncome == 14 ~ 'More than enough money',
      TRUE ~ 'NA'
    ),
    hcq_qdampormould = case_when(
      hcq_qdampormould == 11 ~ "No problem",
      hcq_qdampormould == 12 ~ "Minor problem",
      hcq_qdampormould == 13 ~ "Major problem"
    ),
    hcq_qkeepingwarm = case_when(
      hcq_qkeepingwarm == 11 ~ "No problem",
      hcq_qkeepingwarm == 12 ~ "Minor problem",
      hcq_qkeepingwarm == 13 ~ "Major problem"
    ),
    inc_employ = ifelse(is.na(inc_employ), 0, inc_employ),
    inc_benefit = ifelse(is.na(inc_benefit), 0, inc_benefit),
    inc_company = ifelse(is.na(inc_company), 0, inc_company),
    inc_self_emp = ifelse(is.na(inc_self_emp), 0, inc_self_emp),
    inc_other = ifelse(is.na(inc_other), 0, inc_other),
    inc_non_taxible = ifelse(is.na(inc_non_taxible), 0, inc_non_taxible),
    inc_grand_total = ifelse(is.na(inc_grand_total), 0, inc_grand_total)
  )
    
## new variables ----------------------------------------------------------------------------------

working_table = working_table %>%
  mutate(
    family_package_boost = ifelse(child_birth_date_proxy >= '2020-07-01', 1, 0),
    youngest_child_age = case_when(
      2021 - child_birth_year <= 2 ~ 'baby',
      2021 - child_birth_year <= 4 ~ 'todler',
      2021 - child_birth_year <= 10 ~ 'primary',
      2021 - child_birth_year <= 12 ~ 'intermediate',
      2021 - child_birth_year <= 18 ~ 'college',
      TRUE ~ 'NA'
    ),
    no_income = ifelse(inc_grand_total <= 0, 1, 0),
    low_income = ifelse(inc_grand_total <= 23.65 * 40 * 52, 1, 0),
    any_benefit_receipt = ifelse(!is.na(benefit_receipt), 1, 0),
    auckland = ifelse(DVRegCouncil =='Auckland', 1, 0),
    # age at the end of 2021
    age = 2021 - snz_birth_year_nbr,
    age_cat = case_when(
      00 <= age & age < 10 ~ "00_to_09",
      10 <= age & age < 20 ~ "10_to_19",
      20 <= age & age < 30 ~ "20_to_29",
      30 <= age & age < 40 ~ "30_to_39",
      40 <= age & age < 50 ~ "40_to_49",
      50 <= age & age < 60 ~ "50_to_59",
      60 <= age & age < 70 ~ "60_to_69",
      70 <= age & age < 80 ~ "70_to_79",
      80 <= age ~ "80_up",
      TRUE ~ 'NA'
    ),
    # income indicators
    earned_employ = ifelse(inc_employ > 1000, 1, 0),
    earned_benefit = ifelse(inc_benefit > 1000, 1, 0),
    earned_company = ifelse(inc_company > 1000, 1, 0),
    earned_self_emp = ifelse(inc_self_emp > 1000, 1, 0),
    earned_any_income = ifelse(inc_grand_total > 1000, 1, 0)
  ) %>%
  # time windows
  mutate(
    winter_energy_payment = ifelse('2020-05-01' <= interview_date & interview_date <= '2020-09-30', 1, 0),
    lockdown1 = ifelse('2020-03-26' <= interview_date & interview_date <= '2020-05-13', 1, 0),
    lockdown2A = ifelse('2020-08-12' <= interview_date & interview_date <= '2020-08-30' & auckland == 1, 1, 0),
    lockdown3A = ifelse('2021-02-15' <= interview_date & interview_date <= '2021-02-17' & auckland == 1, 1, 0),
    lockdown4A = ifelse('2021-02-28' <= interview_date & interview_date <= '2021-03-06' & auckland == 1, 1, 0),
    lockdown_any = lockdown1 + lockdown2A + lockdown3A + lockdown4A
  )

## measure of panel by individual -----------------------------------------------------------------

# where does the same individual answer all four waves
all_four_waves_uid = working_table %>%
  group_by(snz_uid) %>%
  summarise(
    w1_uid = sum(ifelse(wave == "aug20", 1, 0)),
    w2_uid = sum(ifelse(wave == "nov20", 1, 0)),
    w3_uid = sum(ifelse(wave == "feb21", 1, 0)),
    w4_uid = sum(ifelse(wave == "may21", 1, 0)),
    .groups = "drop"
  ) %>%
  mutate(num_waves_uid = w1_uid + w2_uid + w3_uid + w4_uid)

# where does the same household answer all four waves
all_four_waves_hhld = working_table %>%
  group_by(snz_hlfs_hhld_uid) %>%
  summarise(
    w1_hhld = sum(ifelse(wave == "aug20", 1, 0)),
    w2_hhld = sum(ifelse(wave == "nov20", 1, 0)),
    w3_hhld = sum(ifelse(wave == "feb21", 1, 0)),
    w4_hhld = sum(ifelse(wave == "may21", 1, 0)),
    .groups = "drop"
  ) %>%
  mutate(num_waves_hhld = w1_hhld + w2_hhld + w3_hhld + w4_hhld)

working_table = working_table %>%
  left_join(all_four_waves_uid, by = "snz_uid") %>%
  left_join(all_four_waves_hhld, by = "snz_hlfs_hhld_uid")

## check dataset variables ------------------------------------------------------------------------

run_time_inform_user("summary report on refined datasets", context = "heading", print_level = VERBOSE)
if(MAKE_REPORTS){
  explore_report(working_table, id_column = "snz_uid", target = "wave", output_file = "refined_table_report")
}

## write for output -------------------------------------------------------------------------------

run_time_inform_user("writing to csv", context = "heading", print_level = VERBOSE)
write.csv(working_table, FULL_DATESSET_CSV, row.names = FALSE)

## all cross-tabs and output ----------------------------------------------------------------------

run_time_inform_user("producing cross-tabs", context = "heading", print_level = VERBOSE)

cols_to_summarise = c(
  "wave",
  "DVHHType",
  "DVHHTen",
  "DVRegCouncil",
  "DVFam_WithPartner",
  "dvsex",
  "DVFam_ParentRole",
  "DVFam_NumDepChild",
  "DVFam_NumIndepChild",
  "EthEuropean",
  "EthMaori",
  "EthPacific",
  "EthAsian",
  "EthMELAA",
  "EthOther",
  "Dep17",
  "DVLFS",
  "DVUnderUtilise",
  "NumJobs",
  "DVJobTenC",
  "DVHQual",
  "DVStudy",
  "PWB_qFeelAboutLifeScale",
  "PWB_qThingsWorthwhileScale",
  "PWB_qHealthExcellentPoor",
  "PWB_qTrustMostPeopleScale",
  "PWB_qTrustPol",
  "PWB_qTrustParl",
  "PWB_qTrustHlth",
  "PWB_qTrustMed",
  "PWB_qDiscriminated",
  "PWB_qTimeLonely",
  "MHS_qEnoughIncome",
  "PWB_qSafeNightHood",
  "DVWHO5_Raw",
  "DVWHO5",
  "PWB_qFamWellbeing",
  "hcq_qdampormould",
  "hcq_qkeepingwarm",
  "earned_employ",
  "earned_benefit",
  "earned_company",
  "earned_self_emp",
  "earned_any_income",
  "benefit_receipt",
  "partnered_father_depchild",
  "partnered_mother_depchild",
  "solo_father_depchild",
  "solo_mother_depchild",
  "other_father",
  "other_mother",
  "family_package_boost",
  "youngest_child_age",
  "no_income",
  "low_income",
  "any_benefit_receipt",
  "auckland",
  "age_cat",
  "winter_energy_payment",
  "lockdown1",
  "lockdown2A",
  "lockdown3A",
  "lockdown4A",
  "lockdown_any"
)

if(MAKE_REPORTS){

  full_cross_tabs = summarise_and_label_over_lists(
    df = working_table,
    group_by_list = cross_product_column_names(cols_to_summarise, cols_to_summarise, drop.dupes.across = FALSE),
    summarise_list = list("snz_uid"),
    make_distinct = FALSE, make_count = TRUE, make_sum = FALSE
  )
  
  write.csv(full_cross_tabs, CROSSTABS_CSV)
}

## conclude ---------------------------------------------------------------------------------------

# close connection
close_database_connection(db_con)
run_time_inform_user("grand completion", context = "heading", print_level = VERBOSE)
