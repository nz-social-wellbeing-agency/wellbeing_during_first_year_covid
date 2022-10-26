#####################################################################################################
#' Description: Output t-test results
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
#' 2022-08-05 SA begun
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
# outputs
OUTPUT_FILE = "../Output/t_test_collection.csv"

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
  # binary indicators
  mutate(
    good_health = ifelse(PWB_qHealthExcellentPoor %in% c("Excellent", "Very good"), 1, 0),
    not_lonely = ifelse(PWB_qTimeLonely == 'None of the time', 1, 0),
    enough_income = ifelse(MHS_qEnoughIncome %in% c("Enough money", "More than enough money"), 1, 0),
    no_damp_or_mould = ifelse(hcq_qdampormould == "No problem", 1, 0),
    warm_home = ifelse(hcq_qkeepingwarm == "No problem", 1, 0)
  ) %>%
  # time period indicators
  mutate(
    # winter energy payment - 1 week
    wep_1week = case_when(
      '2020-09-25' <= interview_date & interview_date <= '2020-10-01' ~ "before",
      '2020-10-02' <= interview_date & interview_date <= '2020-10-08' ~ "after"
    ),
    # winter energy payment - 2 weeks
    wep_2week = case_when(
      '2020-09-18' <= interview_date & interview_date <= '2020-10-01' ~ "before",
      '2020-10-02' <= interview_date & interview_date <= '2020-10-15' ~ "after"
    ),
    # exit lockdown - 1 week
    lock_1week = case_when(
      '2020-05-07' <= interview_date & interview_date <= '2020-05-13' ~ "before",
      '2020-08-24' <= interview_date & interview_date <= '2020-08-30' & auckland == 1 ~ "before",
      '2020-05-14' <= interview_date & interview_date <= '2020-05-20' ~ "after",
      '2020-09-01' <= interview_date & interview_date <= '2020-09-06' & auckland == 1 ~ "after"
    ),
    # exit lockdown - 2 weeks
    lock_2week = case_when(
      '2020-04-30' <= interview_date & interview_date <= '2020-05-13' ~ "before",
      '2020-08-17' <= interview_date & interview_date <= '2020-08-30' & auckland == 1 ~ "before",
      '2020-05-14' <= interview_date & interview_date <= '2020-05-27' ~ "after",
      '2020-09-01' <= interview_date & interview_date <= '2020-09-13' & auckland == 1 ~ "after"
    )
  ) %>%
  # additional groups
  mutate(
    everyone = 1,
    all_female = ifelse(dvsex == "female", 1, 0),
    all_male = ifelse(dvsex == "male", 1, 0),
    all_mother = ifelse(dvsex == "female" & DVFam_ParentRole == 1, 1, 0),
    all_father = ifelse(dvsex == "male" & DVFam_ParentRole == 1, 1, 0),
    is_employed = ifelse(DVLFS == "employed", 1, 0),
    age_over_65 = ifelse(age >= 65, 1, 0)
  )

## sets of variables for iterating over -----------------------------------------------------------

dependent_vars = c(
  "good_health",
  "not_lonely",
  "enough_income",
  "no_damp_or_mould",
  "warm_home",
  "PWB_qFeelAboutLifeScale",
  "PWB_qThingsWorthwhileScale",
  "PWB_qTrustMostPeopleScale",
  "PWB_qTrustPol",
  "PWB_qTrustParl",
  "PWB_qTrustHlth",
  "PWB_qTrustMed",
  "PWB_qDiscriminated",
  "PWB_qFamWellbeing"
)

group_vars = c(
  "everyone",
  "all_female",
  "all_male",
  "all_mother",
  "all_father",
  "is_employed",
  "DVFam_ParentRole",
  "partnered_father_depchild",
  "partnered_mother_depchild",
  "solo_father_depchild",
  "solo_mother_depchild",
  "low_income",
  "any_benefit_receipt",
  "auckland",
  "EthEuropean",
  "EthMaori",
  "EthPacific",
  "EthAsian",
  "age_over_65"
)

filter_vars = c(
  "wep_1week",
  "wep_2week",
  "lock_1week",
  "lock_2week"
)

## iterate over all models ------------------------------------------------------------------------

calculate = function(.x){
  fv = unlist(.x)[1]
  gv = unlist(.x)[2]
  dv = unlist(.x)[3]
  
  # print(paste(fv,gv,dv))
  
  before_df = full_dataset %>%
    filter(!!sym(fv) == "before",
           !!sym(gv) == 1,
           !is.na(!!sym(dv))) %>%
    select(!!sym(dv))
  
  after_df = full_dataset %>%
    filter(!!sym(fv) == "after",
           !!sym(gv) == 1,
           !is.na(!!sym(dv))) %>%
    select(!!sym(dv))
  
  test_output = t.test(
    before_df, after_df,
    # default settings:
    alternative = "two.sided", mu = 0, paired = FALSE, var.equal = FALSE, conf.level = 0.95
  )
  
  output_df = data.frame(
    period = fv,
    group = gv,
    variable = dv,
    t = test_output$statistic,
    df = test_output$parameter,
    p_value = test_output$p.value,
    conf_LB = test_output$conf.int[1],
    conf_UB = test_output$conf.int[2],
    before_mean = test_output$estimate[1],
    after_mean = test_output$estimate[2],
    before_num_obs = nrow(before_df),
    after_num_obs = nrow(after_df)
  )
  
  return(output_df)
}

combinations = purrr::cross3(filter_vars, group_vars, dependent_vars)

output_list = purrr::map(.x = combinations, .f = calculate)

output_df = bind_rows(output_list)

## output -----------------------------------------------------------------------------------------

write.csv(output_df, OUTPUT_FILE)
  
## conclude ---------------------------------------------------------------------------------------

run_time_inform_user("grand completion", context = "heading", print_level = VERBOSE)
