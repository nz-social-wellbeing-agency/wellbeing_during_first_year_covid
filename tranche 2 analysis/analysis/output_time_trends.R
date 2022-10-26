#####################################################################################################
#' Description: Output summarised results
#'
#' Input: Tidied table
#'
#' Output: Excel summary files
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
#' 2022-07-06 SA functionise
#' 2022-07-05 SA begun
#####################################################################################################

## parameters -------------------------------------------------------------------------------------

# locations
ABSOLUTE_PATH_TO_TOOL <- "/nas/DataLab/MAA/MAA2021-55/wellbeing report - tranche 2/Tools/Dataset Assembly Tool"
ABSOLUTE_PATH_TO_ANALYSIS <- "/nas/DataLab/MAA/MAA2021-55/wellbeing report - tranche 2/Analysis"
SANDPIT = "[IDI_Sandpit]"
USERCODE = "[IDI_UserCode]"
OUR_SCHEMA = "[DL-MAA2021-55]"

# inputs
FULL_DATESSET_CSV = "stable_dataset.csv"
# outputs
LOCKDOWN_PATTERNS = "../Output/patterns exiting lockdown v2.csv"
WINTER_PAYMENT_PATTERNS = "../Output/patterns about winter energy payment v2.csv"
SEPARATE_LOCKDOWN_PATTERNS = "../Output/patterns for separate lockdowns v2.csv"

# controls
VERBOSE = "details" # {"all", "details", "heading", "none"}

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

full_dataset = read.csv(FULL_DATESSET_CSV)

## convert wellbeing measures to indicators -------------------------------------------------------

full_dataset = full_dataset %>%
  mutate(
    life_feel = ifelse(PWB_qFeelAboutLifeScale >= 7, 1, 0),
    life_worth = ifelse(PWB_qThingsWorthwhileScale >= 7, 1, 0),
    good_health = ifelse(PWB_qHealthExcellentPoor %in% c("Excellent", "Very good"), 1, 0),
    trust_ppl = ifelse(PWB_qTrustMostPeopleScale >= 7, 1, 0),
    trust_pol = ifelse(PWB_qTrustPol >= 7, 1, 0),
    trust_parl = ifelse(PWB_qTrustParl >= 7, 1, 0),
    trust_health = ifelse(PWB_qTrustHlth >= 7, 1, 0),
    trust_med = ifelse(PWB_qTrustMed >= 7, 1, 0),
    not_discriminated = ifelse(PWB_qDiscriminated == 0, 1, 0),
    not_lonely = ifelse(PWB_qTimeLonely == 'None of the time', 1, 0),
    enough_income = ifelse(MHS_qEnoughIncome %in% c("Enough money", "More than enough money"), 1, 0),
    family_well = ifelse(PWB_qFamWellbeing >= 7, 1, 0),
    no_damp_or_mould = ifelse(hcq_qdampormould == "No problem", 1, 0),
    warm_home = ifelse(hcq_qkeepingwarm == "No problem", 1, 0)
  )

## summarising function ---------------------------------------------------------------------------

time_series_summary = function(df, category = NA, window, group, label){
  
  df = df %>% filter(!!sym(window) == 1)
  
  if(is.na(category)){
    df = df %>% mutate(category = "all", value = "1")
  } else {
    df = df %>% mutate(category = category, value = as.character(!!sym(category)))
  }
  
  output = df %>%
    group_by(category, value, !!!syms(group)) %>%
    summarise(num = n(),
              life_feel = mean(life_feel, na.rm = TRUE),
              life_worth = mean(life_worth, na.rm = TRUE),
              good_health = mean(good_health, na.rm = TRUE),
              trust_ppl = mean(trust_ppl, na.rm = TRUE),
              trust_pol = mean(trust_pol, na.rm = TRUE),
              trust_parl = mean(trust_parl, na.rm = TRUE),
              trust_health = mean(trust_health, na.rm = TRUE),
              trust_med = mean(trust_med, na.rm = TRUE),
              not_discriminated = mean(not_discriminated, na.rm = TRUE),
              not_lonely = mean(not_lonely, na.rm = TRUE),
              enough_income = mean(enough_income, na.rm = TRUE),
              family_well = mean(family_well, na.rm = TRUE),
              no_damp_or_mould = mean(no_damp_or_mould, na.rm = TRUE),
              warm_home = mean(warm_home, na.rm = TRUE),
              .groups = 'drop') %>%
    mutate(label = label)
  
  return(output)
}

cols_to_summarise = c(
  "EthEuropean",
  "EthMaori",
  "EthPacific",
  "EthAsian",
  "EthMELAA",
  "EthOther",
  "dvsex",
  "partnered_father_depchild",
  "partnered_mother_depchild",
  "solo_father_depchild",
  "solo_mother_depchild",
  "other_father",
  "other_mother",
  "no_income",
  "low_income",
  "any_benefit_receipt",
  "auckland",
  "earned_employ",
  "earned_self_emp"
)

## responses against time - exiting lockdown ------------------------------------------------------
#
# Lockdown 1 (all NZ)
# pre = 2020-05-07 to 2020-05-12
# post = 2020-05-13 to 2020-08-11
#
# Lockdown 2 (Auckland)
# pre = 2020-08-12 to 2020-08-30
# post = 2020-08-31 to 2021-02-14
#

# days since lockdown lifted
full_dataset = full_dataset %>%
  mutate(interview_date = as.Date(interview_date)) %>%
  mutate(
    days_since_lockdown_lifted = case_when(
      '2020-05-07' <= interview_date & interview_date <= '2020-05-12' ~ interview_date - as.Date('2020-05-13'),
      '2020-05-13' <= interview_date & interview_date <= '2020-08-11' ~ interview_date - as.Date('2020-05-12'),
      '2020-08-12' <= interview_date & interview_date <= '2020-08-30' & auckland == 1 ~ interview_date - as.Date('2020-08-31'),
      '2020-08-31' <= interview_date & interview_date <= '2021-02-14' & auckland == 1 ~ interview_date - as.Date('2020-08-30'),
      '2021-02-28' <= interview_date & interview_date <= '2021-03-06' & auckland == 1 ~ interview_date - as.Date('2021-03-07'),
      '2021-03-07' <= interview_date & interview_date <= '2021-03-30' & auckland == 1 ~ interview_date - as.Date('2021-03-06'),
    ),
    days_watching_auckland_lockdown = case_when(
      '2020-08-12' <= interview_date & interview_date <= '2020-08-30' & auckland == 1 ~ interview_date - as.Date('2020-08-31'),
      '2020-08-31' <= interview_date & interview_date <= '2021-02-14' & auckland == 1 ~ as.Date('2020-08-30') - interview_date
    )
  ) %>%
  mutate(all_records = 1)

output = time_series_summary(full_dataset, category = NA, "all_records", "days_since_lockdown_lifted", "combined_lockdown")

for(cc in cols_to_summarise){
  
  output = bind_rows(
    output,
    time_series_summary(full_dataset, category = cc, "all_records", "days_since_lockdown_lifted", "combined_lockdown")
  )
  
}


output %>%
  filter(!is.na(days_since_lockdown_lifted),
         days_since_lockdown_lifted <= 90,
         value != "0",
         value != "no") %>%
  write.csv(LOCKDOWN_PATTERNS)

## responses against time - winter energy payment -------------------------------------------------
#
# 1 May - 30 September
#

full_dataset = full_dataset %>%
  mutate(interview_date = as.Date(interview_date)) %>%
  mutate(during_winter_hardship = ifelse('2020-05-01' <= interview_date & interview_date <= '2020-09-30', 1, 0)) %>%
  mutate(all_records = 1)

output = time_series_summary(full_dataset, category = NA, "all_records", c("during_winter_hardship", "interview_date"), "winter_hardship")

for(cc in cols_to_summarise){

  output = bind_rows(
    output, 
    time_series_summary(full_dataset, category = cc, "all_records", c("during_winter_hardship", "interview_date"), "winter_hardship")
  )
  
}

output %>%
  filter(value != "0",
         value != "no") %>%
  write.csv(WINTER_PAYMENT_PATTERNS)

## responses against time - exiting lockdown - separate lockdowns ---------------------------------
#
# Lockdown 1 (all NZ)
# pre = 2020-05-07 to 2020-05-12
# post = 2020-05-13 to 2020-08-11
#
# Lockdown 2 (Auckland)
# pre = 2020-08-12 to 2020-08-30
# post = 2020-08-31 to 2021-02-14
#

full_dataset = full_dataset %>%
  mutate(interview_date = as.Date(interview_date)) %>%
  mutate(
    during_lockdown1 = lockdown1,
    during_window1 = ifelse('2020-05-07' <= interview_date & interview_date <= '2020-08-10', 1, 0),
    during_lockdown2 = ifelse('2020-08-12' <= interview_date & interview_date <= '2020-08-30', 1, 0),
    during_window2 = ifelse('2020-07-29' <= interview_date & interview_date <= '2020-11-28', 1, 0)
  )

output = bind_rows(
  time_series_summary(full_dataset, NA, "during_window1", c("auckland", "during_lockdown1", "interview_date"), "national"),
  time_series_summary(full_dataset, NA, "during_window2", c("auckland", "during_lockdown2", "interview_date"), "auckland")
)

output %>%
  filter(value != "0",
         value != "no") %>%
  write.csv(SEPARATE_LOCKDOWN_PATTERNS)

## conclude ---------------------------------------------------------------------------------------

run_time_inform_user("grand completion", context = "heading", print_level = VERBOSE)
