###################################################################################################
#' Description: Ensure certain measures are stable across waves
#'
#' Input: Tidy table produced by tidy_variables.R
#'
#' Output: Stable tables
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
#' 2022-07-05 SA begun
###################################################################################################

## parameters -------------------------------------------------------------------------------------

# locations
ABSOLUTE_PATH_TO_TOOL <- "/nas/DataLab/MAA/MAA2021-55/wellbeing report - tranche 2/Tools/Dataset Assembly Tool"
ABSOLUTE_PATH_TO_ANALYSIS <- "/nas/DataLab/MAA/MAA2021-55/wellbeing report - tranche 2/Analysis"
SANDPIT = "[IDI_Sandpit]"
USERCODE = "[IDI_UserCode]"
OUR_SCHEMA = "[DL-MAA2021-55]"

# inputs
FULL_DATESSET_CSV = "./tidied_dataset.csv"
# outputs
CROSS_WAVE_TABS_CSV = "../Output/cross_waves_tabs.csv"
STABLISED_DATASET_CSV = "./stable_dataset.csv"

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

working_table = read.csv(FULL_DATESSET_CSV)

## enforce stability across waves -----------------------------------------------------------------

cols_to_keep_max = c(
  "any_benefit_receipt",
  "DVFam_ParentRole",
  "DVFam_WithPartner",
  "EthEuropean",
  "EthAsian",
  "EthMaori",
  "EthPacific",
  "EthMELAA",
  "EthOther",
  "other_father",
  "other_mother",
  "partnered_father_depchild",
  "partnered_mother_depchild",
  "solo_father_depchild",
  "solo_mother_depchild"
)

mutate_formula = glue::glue("max({cols_to_keep_max})")
mutate_list = as.list(rlang::parse_exprs(mutate_formula))
names(mutate_list) = cols_to_keep_max

working_table = working_table %>%
  group_by(snz_uid) %>%
  # max of indicators
  mutate(!!! mutate_list) %>%
  mutate(
    dvsex = first(dvsex),
    DVHQual = first(DVHQual),
    DVHHTen = first(DVHHTen)
  )

## cross-wave interactions ------------------------------------------------------------------------

cols_of_interest = c(
  "DVHHTen",
  "DVFam_NumDepChild",
  "DVFam_NumIndepChild",
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
  "PWB_qFamWellbeing",
  "hcq_qdampormould",
  "hcq_qkeepingwarm"
)

cross_tab_summary = function(df, cols, suffix1, suffix2){
  cols1 = paste0(cols, suffix1)
  cols2 = paste0(cols, suffix2)
  
  full_cross_tabs = summarise_and_label_over_lists(
    df = df,
    group_by_list = cross_product_column_names(cols1, cols2, drop.dupes.across = FALSE),
    summarise_list = list("snz_uid"),
    make_distinct = FALSE, make_count = TRUE, make_sum = FALSE
  )
  
  return(full_cross_tabs)
}

w1 = working_table %>% filter(wave == 'aug20')
w2 = working_table %>% filter(wave == 'nov20')
w3 = working_table %>% filter(wave == 'feb21')
w4 = working_table %>% filter(wave == 'may21')

w1w2 = inner_join(w1, w2, by = "snz_uid", suffix = c("_w1","_w2")) %>% ungroup()
w2w3 = inner_join(w2, w3, by = "snz_uid", suffix = c("_w2","_w3")) %>% ungroup()
w3w4 = inner_join(w3, w4, by = "snz_uid", suffix = c("_w3","_w4")) %>% ungroup()

if(MAKE_REPORTS){
  run_time_inform_user("cross_tab w1w2", context = "heading", print_level = VERBOSE)
  ct_w1w2 = cross_tab_summary(w1w2, cols_of_interest, "_w1", "_w2")

  run_time_inform_user("cross_tab w2w3", context = "heading", print_level = VERBOSE)
  ct_w2w3 = cross_tab_summary(w2w3, cols_of_interest, "_w2", "_w3")

  run_time_inform_user("cross_tab w3w4", context = "heading", print_level = VERBOSE)
  ct_w3w4 = cross_tab_summary(w3w4, cols_of_interest, "_w3", "_w4")

  run_time_inform_user("writing cross tabs to file", context = "heading", print_level = VERBOSE)
  bind_rows(ct_w1w2, ct_w2w3, ct_w3w4) %>% write.csv(CROSS_WAVE_TABS_CSV)
}


## write for output -------------------------------------------------------------------------------

run_time_inform_user("writing to csv", context = "heading", print_level = VERBOSE)
write.csv(working_table, STABLISED_DATASET_CSV, row.names = FALSE)

## conclude ---------------------------------------------------------------------------------------

run_time_inform_user("grand completion", context = "heading", print_level = VERBOSE)
