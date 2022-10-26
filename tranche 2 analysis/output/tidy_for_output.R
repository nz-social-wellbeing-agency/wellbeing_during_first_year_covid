#
# processing script
#

setwd("/nas/DataLab/MAA/MAA2021-55/wellbeing report - tranche 2/Output/prepared for output")
source("../../Tools/Dataset Assembly Tool/utility_functions.R")
source("../../Tools/Dataset Assembly Tool/summary_confidential.R")


## cross_tabs.csv ---------------------------------------------------------------------------------
df = read.csv("../csv output for prep and submission/cross_tabs.csv", stringsAsFactors = FALSE)

not_wanted_columns = c("DVHHType", "DVWHO5_Raw", "DVUnderUtilise", "DVJobTenC", "lockdown3A", "lockdown4A")
not_wanted_values = c("00_to_09", "Caring For Sick Or Infirm", "Student", "Young Parent Payment", "Youth", "Not specified", "777", "88", "99")

df = df %>%
  select(col01, val01, col02, val02, count) %>%
  filter(! col01 %in% not_wanted_columns,
         ! col02 %in% not_wanted_columns) %>%
  filter(! val01 %in% not_wanted_values,
         ! val02 %in% not_wanted_values) %>%
  filter(is.na(col02) | !is.na(val02)) %>%
  filter(!is.na(val01)) %>%
  mutate(
    val01 = ifelse(col01 == "benefit_receipt" & val01 == "Invalids", "Sickness", val01),
    val02 = ifelse(col02 == "benefit_receipt" & val02 == "Invalids", "Sickness", val02),
    val01 = ifelse(col01 == "Dep17" & val01 %in% as.character(10:100), "10+", val01),
    val02 = ifelse(col02 == "Dep17" & val02 %in% as.character(10:100), "10+", val02),
    val01 = ifelse(col01 == "DVFam_NumDepChild" & val01 %in% as.character(4:100), "4+", val01),
    val02 = ifelse(col02 == "DVFam_NumDepChild" & val02 %in% as.character(4:100), "4+", val02),
    val01 = ifelse(col01 == "DVFam_NumIndepChild" & val01 %in% as.character(3:100), "3+", val01),
    val02 = ifelse(col02 == "DVFam_NumIndepChild" & val02 %in% as.character(3:100), "3+", val02),
    val01 = ifelse(col01 == "DVQual" & val01 == "NA", "none", val01),
    val02 = ifelse(col02 == "DVQual" & val02 == "NA", "none", val02),
    val01 = ifelse(col01 == "DVQual" & is.na(val01), "none", val01),
    val02 = ifelse(col02 == "DVQual" & is.na(val02), "none", val02)
  )

df = df %>%
  group_by(col01, val01, col02, val02) %>%
  summarise(count = sum(count), .groups = 'drop') %>%
  confidentialise_results()

write.csv(df, "cross_tabs_ready.csv", row.names = FALSE)

## cross_waves_tabs.csv ---------------------------------------------------------------------------------
df = read.csv("../csv output for prep and submission/cross_waves_tabs.csv", stringsAsFactors = FALSE)

not_wanted_columns = c("DVHHType", "DVWHO5_Raw", "DVUnderUtilise", "DVJobTenC", "lockdown3A", "lockdown4A")
not_wanted_values = c("00_to_09", "Caring For Sick Or Infirm", "Student", "Young Parent Payment", "Youth", "Not specified", "777", "88", "99")

df = df %>%
  mutate(col01 = substr(col01, 1, nchar(col01) - 3),
         col02 = substr(col02, 1, nchar(col02) - 3))


df = df %>%
  select(col01, val01, col02, val02, count) %>%
  filter(! col01 %in% not_wanted_columns,
         ! col02 %in% not_wanted_columns) %>%
  filter(! val01 %in% not_wanted_values,
         ! val02 %in% not_wanted_values) %>%
  filter(is.na(col02) | !is.na(val02)) %>%
  filter(!is.na(val01)) %>%
  mutate(
    val01 = ifelse(col01 == "benefit_receipt" & val01 == "Invalids", "Sickness", val01),
    val02 = ifelse(col02 == "benefit_receipt" & val02 == "Invalids", "Sickness", val02),
    val01 = ifelse(col01 == "Dep17" & val01 %in% as.character(10:100), "10+", val01),
    val02 = ifelse(col02 == "Dep17" & val02 %in% as.character(10:100), "10+", val02),
    val01 = ifelse(col01 == "DVFam_NumDepChild" & val01 %in% as.character(4:100), "4+", val01),
    val02 = ifelse(col02 == "DVFam_NumDepChild" & val02 %in% as.character(4:100), "4+", val02),
    val01 = ifelse(col01 == "DVFam_NumIndepChild" & val01 %in% as.character(3:100), "3+", val01),
    val02 = ifelse(col02 == "DVFam_NumIndepChild" & val02 %in% as.character(3:100), "3+", val02),
    val01 = ifelse(col01 == "DVQual" & val01 == "NA", "none", val01),
    val02 = ifelse(col02 == "DVQual" & val02 == "NA", "none", val02),
    val01 = ifelse(col01 == "DVQual" & is.na(val01), "none", val01),
    val02 = ifelse(col02 == "DVQual" & is.na(val02), "none", val02)
  )

df = df %>%
  group_by(col01, val01, col02, val02) %>%
  summarise(count = sum(count), .groups = 'drop') %>%
  confidentialise_results()

write.csv(df, "cross_waves_tabs_ready.csv", row.names = FALSE)

## patterns over time -----------------------------------------------------------------------------
df_sep = read.csv("../csv output for prep and submission/patterns for separate lockdowns.csv", stringsAsFactors = FALSE)
df_wtr = read.csv("../csv output for prep and submission/patterns about winter energy payment.csv", stringsAsFactors = FALSE)
df_ext = read.csv("../csv output for prep and submission/patterns exiting lockdown.csv", stringsAsFactors = FALSE)

df_sep = df_sep %>%
  mutate(during = coalesce(during_lockdown1, during_lockdown2),
         category = ifelse(value == 1, category, paste(category,"=",value))) %>%
  mutate(label = paste(label, ifelse(auckland == 1, "in_auckland", "out_auckland"))) %>%
  select(label, category, during, interview_date,	num,
         life_feel, life_worth, good_health, trust_ppl, trust_pol, trust_parl, trust_health, trust_med,
         not_discriminated, not_lonely, enough_income, family_well)

df_wtr = df_wtr %>%
  rename(during = during_winter_hardship) %>%
  mutate(category = ifelse(value == 1, category, paste(category,"=",value))) %>%
  select(label, category, during, interview_date,	num,
         life_feel, life_worth, good_health, trust_ppl, trust_pol, trust_parl, trust_health, trust_med,
         not_discriminated, not_lonely, enough_income, family_well)

df_ext = df_ext %>%
  mutate(during = ifelse(days_since_lockdown_lifted < 0, 1, 0),
         category = ifelse(value == 1, category, paste(category,"=",value))) %>%
  select(label, category, during, days_since_lockdown_lifted,	num,
         life_feel, life_worth, good_health, trust_ppl, trust_pol, trust_parl, trust_health, trust_med,
         not_discriminated, not_lonely, enough_income, family_well)

focus_cols = c(
  "life_feel",
  "life_worth", 
  "good_health", 
  "trust_ppl", 
  "trust_pol", 
  "trust_parl", 
  "trust_health", 
  "trust_med",
  "not_discriminated", 
  "not_lonely", 
  "enough_income", 
  "family_well"
)

mutate_formula = glue::glue("round(num * {focus_cols}, 0)")
mutate_list = as.list(rlang::parse_exprs(mutate_formula))
names(mutate_list) = focus_cols

df_sep = df_sep %>% mutate(!!! mutate_list)
df_wtr = df_wtr %>% mutate(!!! mutate_list)
df_ext = df_ext %>% mutate(!!! mutate_list)

mutate_formula = glue::glue("{focus_cols} + lag({focus_cols}) + lead({focus_cols})")
mutate_list = as.list(rlang::parse_exprs(mutate_formula))
names(mutate_list) = focus_cols

df_sep = df_sep %>%
  group_by(label, category, during) %>%
  arrange(interview_date) %>%
  mutate(num = num + lag(num) + lead(num)) %>%
  mutate(!!! mutate_list)

df_wtr = df_wtr %>%
  group_by(label, category, during) %>%
  arrange(interview_date) %>%
  mutate(num = num + lag(num) + lead(num)) %>%
  mutate(!!! mutate_list)

df_ext = df_ext %>%
  group_by(label, category, during) %>%
  arrange(days_since_lockdown_lifted) %>%
  mutate(num = num + lag(num) + lead(num)) %>%
  mutate(!!! mutate_list)

mutate_formula = glue::glue("randomly_round_vector({focus_cols})")
mutate_list = as.list(rlang::parse_exprs(mutate_formula))
names(mutate_list) = glue::glue("conf_{focus_cols}")

df_sep = df_sep %>% mutate(conf_num = randomly_round_vector(num)) %>% mutate(!!! mutate_list)
df_wtr = df_wtr %>% mutate(conf_num = randomly_round_vector(num)) %>% mutate(!!! mutate_list)
df_ext = df_ext %>% mutate(conf_num = randomly_round_vector(num)) %>% mutate(!!! mutate_list)

write.csv(df_sep, "patterns for separate lockdowns_ready.csv", row.names = FALSE)
write.csv(df_wtr, "patterns about winter energy payment_ready.csv", row.names = FALSE)
write.csv(df_ext, "patterns exiting lockdown_ready.csv", row.names = FALSE)
