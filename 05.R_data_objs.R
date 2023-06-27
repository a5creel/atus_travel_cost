# Goal: save a rdata space so I'm loading the same thing every time
# Andie Creel / Started June 27th, 2023

rm(list = ls())
options(scipen = 999)
library(dplyr)
library(tidyr)
library(stringr)
library(vroom)
library(mlogit)
library(lubridate)

# -----------------------------------------------------------------------------
# Read in data
# -----------------------------------------------------------------------------

myWorking_og <- vroom("clean_data/4.weather_tc_ALL.csv") 

# -----------------------------------------------------------------------------
# Data cleaning 
# https://cran.r-project.org/web/packages/mlogit/vignettes/c2.formula.data.html
# -----------------------------------------------------------------------------
myRUM_df <- myWorking_og %>%
  mutate(choice = if_else(number_activities > 0, 1, 0)) %>% # demand is 0/1 (extensive, not intensive)
  mutate(race = as.factor(race))  %>%
  mutate(variable = as.factor(variable)) %>%
  
  # can't have NAs 
  filter(race != "other") %>% 
  
  # dropping people we don't have weather for
  filter(!is.na(tmmx)) %>% 
  
  # drop no leisure
  filter(variable != "no_leisure") %>%
  group_by(caseid) %>%
  mutate(temp = sum(choice)) %>%
  filter(temp != 0) %>%
  select(-temp) %>%
  ungroup() %>%

  # drop no income 
  filter(!is.na(fam_inc_mid))

#turning into mlogit object
myRUM_idx <- dfidx(myRUM_df, idx = list(NA, "variable")) 


rm(myWorking_og)
# -----------------------------------------------------------------------------
# save r data
# -----------------------------------------------------------------------------

save(list = ls(), file = "05.RUM_data_objs.RData")








