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
  mutate(activity = as.factor(activity)) %>%
  
  # can't have NAs 
  filter(race != "other") %>% 
  
  # dropping people we don't have weather for
  filter(!is.na(tmmx)) %>% 
  
  # drop no leisure
  filter(activity != "no_leisure") %>%
  group_by(caseid) %>%
  mutate(temp = sum(choice)) %>%
  filter(temp != 0) %>%
  select(-temp) %>%
  ungroup() %>%

  # drop no income 
  filter(!is.na(fam_inc_mid))

# -----------------------------------------------------------------------------
# CHANGING NAMES.
# -----------------------------------------------------------------------------
myRUM_df <- myRUM_df %>%
  mutate(activity = if_else(activity == "rec_away", "outdoor_away", activity)) %>%
  mutate(activity = if_else(activity == "rec_home", "outdoor_home", activity)) %>%
  mutate(activity = if_else(activity == "leisure_away", "indoor_away", activity)) %>%
  mutate(activity = if_else(activity == "leisure_home", "indoor_home", activity)) 



# -----------------------------------------------------------------------------
# Adding seasons
# -----------------------------------------------------------------------------
getSeason <- function(input.date){
  numeric.date <- 100*month(input.date)+day(input.date)
  ## input Seasons upper limits in the form MMDD in the "break =" option:
  cuts <- base::cut(numeric.date, breaks = c(0,319,0620,0921,1220,1231)) 
  # rename the resulting groups (could've been done within cut(...levels=) if "Winter" wasn't double
  levels(cuts) <- c("winter","spring","summer","fall","winter")
  return(cuts)
}


myRUM_df <- myRUM_df %>% 
  mutate(season = getSeason(date))

# -----------------------------------------------------------------------------
# turning into mlogit object
# -----------------------------------------------------------------------------

myRUM_idx <- dfidx(myRUM_df, idx = list(NA, "activity")) 

rm(myWorking_og)

# -----------------------------------------------------------------------------
# save r data
# -----------------------------------------------------------------------------

save(list = ls(), file = "05.RUM_data_objs.RData")








