#####################################################################################################
#' Description: Output regression results
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
#' Notes: Becausse R requires specialised packages for panel logit regression (and these packages
#' are not easily available in the data lab) we output a dataset that can be loaded into Stata
#' for the panel regressions.
#' 
#' Issues:
#' 
#' History (reverse order):
#' 2022-08-29 AW included a different set of regression variables, in regression_variables_aw.csv. Output to continuous_regression_outputs_aw.txt
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
FULL_DATESSET_CSV = "./stable_dataset.csv"
MODEL_CSV = "./regression_variables_aw.csv"
# outputs
OUTPUT_TEXT_FILE = "../Output/continuous_regression_outputs.txt"
REGRESSION_DATASET_CSV = "./regression_dataset_for_stata.csv"

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

full_dataset = read.csv(FULL_DATESSET_CSV, stringsAsFactors = FALSE)

## recode character columns to factors ------------------------------------------------------------

full_dataset = full_dataset %>%
  mutate(
    youngest_child_age = case_when(
      youngest_child_age == 'baby' & family_package_boost == 1 ~ "baby_fm_pkg",
      youngest_child_age == 'baby' & family_package_boost == 0 ~ "baby_no_pkg",
      is.na(youngest_child_age) ~ 'none',
      TRUE ~ youngest_child_age
    )
  ) %>%
  mutate(
    MHS_qEnoughIncome = factor(MHS_qEnoughIncome, levels = c("More than enough money", "Enough money", "Only just enough money", "Not enough money")),
    PWB_qHealthExcellentPoor = factor(PWB_qHealthExcellentPoor, levels = c("Excellent", "Very good", "Good", "Fair", "Poor")),
    DVLFS = factor(DVLFS, levels = c("employed", "unemployed", "not in labour force")),
    NumJobs = factor(NumJobs, levels = c("single job", "multi job", "no job")),
    PWB_qTimeLonely = factor(PWB_qTimeLonely, levels = c("None of the time", "A little of the time", "Some of the time", "Most of the time", "All of the time")),
    youngest_child_age = factor(youngest_child_age, levels = c("none", "baby_fm_pkg", "baby_no_pkg", "todler", "primary", "intermediate", "college")),
    age_cat = factor(age_cat, c("10_to_19", "20_to_29", "30_to_39", "40_to_49", "50_to_59", "60_to_69", "70_to_79", "80_up")),
    hcq_qkeepingwarm = factor(hcq_qkeepingwarm, c("No problem", "Minor problem", "Major problem")),
    hcq_qdampormould = factor(hcq_qdampormould, c("No problem", "Minor problem", "Major problem"))
  ) %>%
  # binary indicators
  mutate(
    good_health = ifelse(PWB_qHealthExcellentPoor %in% c("Excellent", "Very good"), 1, 0),
    not_lonely = ifelse(PWB_qTimeLonely == 'None of the time', 1, 0),
    enough_income = ifelse(MHS_qEnoughIncome %in% c("Enough money", "More than enough money"), 1, 0),
    no_damp_or_mould = ifelse(hcq_qdampormould == "No problem", 1, 0),
    warm_home = ifelse(hcq_qkeepingwarm == "No problem", 1, 0)
  ) %>%
  mutate(
    NumJobsmulti_job = ifelse(NumJobs == "multi job", 1, 0)
  )

## model designs ----------------------------------------------------------------------------------

model_vars = read.csv(MODEL_CSV, stringsAsFactors = FALSE, check.names = FALSE)
var_labels = colnames(model_vars)[4:ncol(model_vars)]

## iterate over all models ------------------------------------------------------------------------

sink(OUTPUT_TEXT_FILE)

for(ii in 1:nrow(model_vars)){
  this_type = model_vars[ii,1]
  this_panel = model_vars[ii,2]
  this_depend_var = model_vars[ii,3]
  
  these_vars = var_labels[model_vars[ii,4:ncol(model_vars)] == 1]
  these_vars = these_vars[!is.na(these_vars)]
  
  this_formula = paste(this_depend_var, "~", paste(these_vars, collapse = " + "))
  
  if(this_type == "continuous" & this_panel == "fixed"){
    
    model_output = plm::plm(formula(this_formula), data = full_dataset, index = c("snz_uid", "wave"), model = "within")
    print("-----------------------------------")
    print(glue::glue("{this_type} | {this_panel} | {this_depend_var}"))
    print("-----------------------------------")
    print(summary(model_output))
    
  } else if(this_type == "continuous" & this_panel == "random"){
    
    model_output = plm::plm(formula(this_formula), data = full_dataset, index = c("snz_uid", "wave"), model = "random")
    print("-----------------------------------")
    print(glue::glue("{this_type} | {this_panel} | {this_depend_var}"))
    print("-----------------------------------")
    print(summary(model_output))
    
  } else if(this_type == "logit" & this_panel == "fixed"){
    
  } else if(this_type == "logit" & this_panel == "random"){
    
  } else {
    stop("unreachable error")
  }
  
}

sink()

## prep and output dataset for running logit regressions in Stata ---------------------------------
#
# R requires specific packages to run panel logit regression.
# These are either not installed, or not easily used.
# Hence we will output to Stata which is setup for this type of regression.
# One key step is first coding everything to dummy/indicator variables as
# Stata does not appear to convert text variables to dummies for a regression.
#

full_dataset = full_dataset %>%
  mutate(
    wave_num = case_when(
      wave == 'aug20' ~ 1,
      wave == 'nov20' ~ 2,
      wave == 'feb21' ~ 3,
      wave == 'may21' ~ 4
    )
  ) %>%
  mutate(
    wavenov20 = ifelse(wave == 'nov20', 1, 0),
    wavemay21 = ifelse(wave == 'may21', 1, 0),
    wavefeb21 = ifelse(wave == 'feb21', 1, 0),
    waveaug20 = ifelse(wave == 'aug20', 1, 0),
    MHS_qEnoughIncomeNot_enough_money = ifelse(MHS_qEnoughIncome == 'Not enough money', 1, 0),
    MHS_qEnoughIncomeEnough_money = ifelse(MHS_qEnoughIncome == 'Enough money', 1, 0),
    MHS_qEnoughIncomeOnly_just_enough_money = ifelse(MHS_qEnoughIncome == 'Only just enough money', 1, 0),
    MHS_qEnoughIncomeMore_than_enough_money = ifelse(MHS_qEnoughIncome == 'More than enough money', 1, 0),
    PWB_qHealthExcellentPoorGood = ifelse(PWB_qHealthExcellentPoor == 'Good', 1, 0),
    PWB_qHealthExcellentPoorPoor = ifelse(PWB_qHealthExcellentPoor == 'Poor', 1, 0),
    PWB_qHealthExcellentPoorVery_good = ifelse(PWB_qHealthExcellentPoor == 'Very good', 1, 0),
    PWB_qHealthExcellentPoorFair = ifelse(PWB_qHealthExcellentPoor == 'Fair', 1, 0),
    PWB_qHealthExcellentPoorExcellent = ifelse(PWB_qHealthExcellentPoor == 'Excellent', 1, 0),
    DVLFSnot_in_labour_force = ifelse(DVLFS == 'not in labour force', 1, 0),
    DVLFSemployed = ifelse(DVLFS == 'employed', 1, 0),
    DVLFSunemployed = ifelse(DVLFS == 'unemployed', 1, 0),
    NumJobsno_job = ifelse(NumJobs == 'no job', 1, 0),
    NumJobssingle_job = ifelse(NumJobs == 'single job', 1, 0),
    NumJobsmulti_job = ifelse(NumJobs == 'multi job', 1, 0),
    PWB_qTimeLonelySome_of_the_time = ifelse(PWB_qTimeLonely == 'Some of the time', 1, 0),
    PWB_qTimeLonelyA_little_of_the_time = ifelse(PWB_qTimeLonely == 'A little of the time', 1, 0),
    PWB_qTimeLonelyNone_of_the_time = ifelse(PWB_qTimeLonely == 'None of the time', 1, 0),
    PWB_qTimeLonelyMost_of_the_time = ifelse(PWB_qTimeLonely == 'Most of the time', 1, 0),
    PWB_qTimeLonelyAll_of_the_time = ifelse(PWB_qTimeLonely == 'All of the time', 1, 0),
    hcq_qdampormouldNo_problem = ifelse(hcq_qdampormould == 'No problem', 1, 0),
    hcq_qdampormouldMinor_problem = ifelse(hcq_qdampormould == 'Minor problem', 1, 0),
    hcq_qdampormouldMajor_problem = ifelse(hcq_qdampormould == 'Major problem', 1, 0),
    hcq_qkeepingwarmNo_problem = ifelse(hcq_qkeepingwarm == 'No problem', 1, 0),
    hcq_qkeepingwarmMinor_problem = ifelse(hcq_qkeepingwarm == 'Minor problem', 1, 0),
    hcq_qkeepingwarmMajor_problem = ifelse(hcq_qkeepingwarm == 'Major problem', 1, 0),
    age_cat60_to_69 = ifelse(age_cat == '60_to_69', 1, 0),
    age_cat30_to_39 = ifelse(age_cat == '30_to_39', 1, 0),
    age_cat20_to_29 = ifelse(age_cat == '20_to_29', 1, 0),
    age_cat40_to_49 = ifelse(age_cat == '40_to_49', 1, 0),
    age_cat50_to_59 = ifelse(age_cat == '50_to_59', 1, 0),
    age_cat10_to_19 = ifelse(age_cat == '10_to_19', 1, 0),
    age_cat80_up = ifelse(age_cat == '80_up', 1, 0),
    age_cat70_to_79 = ifelse(age_cat == '70_to_79', 1, 0),
    age_cat00_to_09 = ifelse(age_cat == '00_to_09', 1, 0),
    dvsexfemale = ifelse(dvsex == 'female', 1, 0),
    dvsexmale = ifelse(dvsex == 'male', 1, 0),
    DVRegCouncilCanterbury = ifelse(DVRegCouncil == 'Canterbury', 1, 0),
    DVRegCouncilSouthland = ifelse(DVRegCouncil == 'Southland', 1, 0),
    DVRegCouncilManawatu_Wanganui = ifelse(DVRegCouncil == 'Manawatu-Wanganui', 1, 0),
    DVRegCouncilAuckland = ifelse(DVRegCouncil == 'Auckland', 1, 0),
    DVRegCouncilWellington = ifelse(DVRegCouncil == 'Wellington', 1, 0),
    DVRegCouncilHawkes_Bay = ifelse(DVRegCouncil == 'Hawkes Bay', 1, 0),
    DVRegCouncilWaikato = ifelse(DVRegCouncil == 'Waikato', 1, 0),
    DVRegCouncilNorthland = ifelse(DVRegCouncil == 'Northland', 1, 0),
    DVRegCouncilBay_of_Plenty = ifelse(DVRegCouncil == 'Bay of Plenty', 1, 0),
    DVRegCouncilTaranaki = ifelse(DVRegCouncil == 'Taranaki', 1, 0),
    DVRegCouncilTasman = ifelse(DVRegCouncil == 'Tasman', 1, 0),
    DVRegCouncilOtago = ifelse(DVRegCouncil == 'Otago', 1, 0),
    DVRegCouncilGisborne = ifelse(DVRegCouncil == 'Gisborne', 1, 0),
    DVRegCouncilNelson = ifelse(DVRegCouncil == 'Nelson', 1, 0),
    DVRegCouncilMarlborough = ifelse(DVRegCouncil == 'Marlborough', 1, 0),
    DVRegCouncilWest_Coast = ifelse(DVRegCouncil == 'West Coast', 1, 0),
    youngest_child_agenone = ifelse(youngest_child_age == 'none', 1, 0),
    youngest_child_agecollege = ifelse(youngest_child_age == 'college', 1, 0),
    youngest_child_ageprimary = ifelse(youngest_child_age == 'primary', 1, 0),
    youngest_child_agetodler = ifelse(youngest_child_age == 'todler', 1, 0),
    youngest_child_agebaby_no_pkg = ifelse(youngest_child_age == 'baby_no_pkg', 1, 0),
    youngest_child_ageintermediate = ifelse(youngest_child_age == 'intermediate', 1, 0),
    youngest_child_agebaby_fm_pkg = ifelse(youngest_child_age == 'baby_fm_pkg', 1, 0)
  ) %>%
  filter(
    !is.na(PWB_qTrustMostPeopleScale),
    !is.na(MHS_qEnoughIncome),
    !is.na(PWB_qHealthExcellentPoor),
    !is.na(NumJobs),
    !is.na(PWB_qTimeLonely),
    !is.na(hcq_qdampormould),
    !is.na(hcq_qkeepingwarm),
    !is.na(age_cat),
    PWB_qTrustMostPeopleScale != 'NA',
    MHS_qEnoughIncome != 'NA',
    PWB_qHealthExcellentPoor != 'NA',
    NumJobs != 'NA',
    PWB_qTimeLonely != 'NA',
    hcq_qdampormould != 'NA',
    hcq_qkeepingwarm != 'NA',
    age_cat != 'NA',
    Dep17 != 77
  ) %>%
  mutate(
    any_benefit_receipt_winter_energy_payment = any_benefit_receipt * winter_energy_payment,
    winter_energy_payment_partnered_father_depchild = winter_energy_payment * partnered_father_depchild,
    winter_energy_payment_partnered_mother_depchild = winter_energy_payment * partnered_mother_depchild,
    winter_energy_payment_solo_father_depchild = winter_energy_payment * solo_father_depchild,
    winter_energy_payment_solo_mother_depchild = winter_energy_payment * solo_mother_depchild,
    winter_energy_payment_low_income = winter_energy_payment * low_income,
    # lockdown
    lockdown_any_partnered_father_depchild = lockdown_any * partnered_father_depchild,
    lockdown_any_partnered_mother_depchild = lockdown_any * partnered_mother_depchild,
    lockdown_any_solo_father_depchild = lockdown_any * solo_father_depchild,
    lockdown_any_solo_mother_depchild = lockdown_any * solo_mother_depchild,
    # lockdown_any_youngest_child_age = lockdown_any * youngest_child_age,
    lockdown_any_youngest_child_agebaby_fm_pkg = lockdown_any * youngest_child_agebaby_fm_pkg,
    lockdown_any_youngest_child_agebaby_no_pkg = lockdown_any * youngest_child_agebaby_no_pkg,
    lockdown_any_youngest_child_agetodler = lockdown_any * youngest_child_agetodler,
    lockdown_any_youngest_child_ageprimary = lockdown_any * youngest_child_ageprimary,
    lockdown_any_youngest_child_ageintermediate = lockdown_any * youngest_child_ageintermediate,
    lockdown_any_youngest_child_agecollege  = lockdown_any * youngest_child_agecollege,
    # benefit receipt
    any_benefit_receipt_partnered_father_depchild = any_benefit_receipt * partnered_father_depchild,
    any_benefit_receipt_partnered_mother_depchild = any_benefit_receipt * partnered_mother_depchild,
    any_benefit_receipt_solo_father_depchild = any_benefit_receipt * solo_father_depchild,
    any_benefit_receipt_solo_mother_depchild = any_benefit_receipt * solo_mother_depchild
  )
  
write.csv(full_dataset, REGRESSION_DATASET_CSV)

## conclude ---------------------------------------------------------------------------------------

run_time_inform_user("grand completion", context = "heading", print_level = VERBOSE)
