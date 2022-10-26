#
# processing script
#

setwd("/nas/DataLab/MAA/MAA2021-55/wellbeing report - tranche 2/Output/revised outputs")
source("../../Tools/Dataset Assembly Tool/utility_functions.R")
source("../../Tools/Dataset Assembly Tool/summary_confidential.R")

## patterns over time -----------------------------------------------------------------------------

df_ext = read.csv("./patterns exiting lockdown v2.csv", stringsAsFactors = FALSE)

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

df_ext = df_ext %>% mutate(!!! mutate_list)

mutate_formula = glue::glue("{focus_cols} + lag({focus_cols}) + lead({focus_cols})")
mutate_list = as.list(rlang::parse_exprs(mutate_formula))
names(mutate_list) = focus_cols

df_ext = df_ext %>%
  group_by(label, category, during) %>%
  arrange(days_since_lockdown_lifted) %>%
  mutate(num = num + lag(num) + lead(num)) %>%
  mutate(!!! mutate_list)

mutate_formula = glue::glue("randomly_round_vector({focus_cols})")
mutate_list = as.list(rlang::parse_exprs(mutate_formula))
names(mutate_list) = glue::glue("conf_{focus_cols}")

df_ext = df_ext %>% mutate(conf_num = randomly_round_vector(num)) %>% mutate(!!! mutate_list)

mutate_formula = glue::glue("ifelse({focus_cols} < 6 | is.na({focus_cols}), NA, conf_{focus_cols})")
mutate_list = as.list(rlang::parse_exprs(mutate_formula))
names(mutate_list) = glue::glue("conf_{focus_cols}")

df_ext = df_ext %>% mutate(conf_num = ifelse(num < 6 | is.na(num), NA, conf_num)) %>% mutate(!!! mutate_list)


write.csv(df_ext, "patterns exiting lockdown v2_ready.csv", row.names = FALSE)
