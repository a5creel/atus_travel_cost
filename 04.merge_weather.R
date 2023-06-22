# Goal: Merge in weather data 
# Andie Creel / Started: June 20, 2023

rm(list = ls())
options(scipen = 999)
library(ipumsr)
library(dplyr)
library(tidyr)
library(stringr)
library(vroom)
library(mlogit)
library(conflicted)
library(lubridate)

#Setting package::function priority with conflicted package
conflict_prefer("filter", "dplyr")
conflict_prefer("select", "dplyr")

# -----------------------------------------------------------------------------
# Read in data, clean up 
# -----------------------------------------------------------------------------

myTC_og <- vroom("clean_data/3.travel_times_all.csv")
myWeath_og <- vroom("/Users/a5creel/Dropbox (YSE)/PhD Work/Andie's Prospectus/gridMETr/myOutput/2021_county_all.csv")
myInc_codes_og <- vroom("raw_data/income_codes.csv") %>%
  rename(code = Value) %>%
  rename(bin = Label)

myTC <- myTC_og %>%
  filter(year == 2021) %>% 
  mutate(date = as.Date(as.character(date), format = "%Y%m%d")) %>%
  mutate()

myWeath <- myWeath_og %>%
  mutate(county = as.numeric(county))

# -----------------------------------------------------------------------------
# deal with income
# -----------------------------------------------------------------------------
myInc <- myInc_codes_og %>%
  
  # lower bound of binned income 
  mutate(fam_inc_low = str_extract(bin, "\\$([0-9,]+)")) %>%
  mutate(fam_inc_low = as.numeric(gsub("[$,]", "", fam_inc_low))) %>%
  mutate(fam_inc_low = if_else(code == 1, 0, fam_inc_low)) %>% 
  
  # upper bound of binned income 
  mutate(fam_inc_high = str_extract(bin, "\\$[0-9,]+$")) %>%
  mutate(fam_inc_high = as.numeric(gsub("[$,]", "", fam_inc_high))) %>%
  
  # midpoint bound of binned income 
  mutate(fam_inc_mid = 1/2*(fam_inc_low+ fam_inc_high)) %>% 
  select(-bin)

# -----------------------------------------------------------------------------
# Merge
# -----------------------------------------------------------------------------

myWorking <- left_join(myTC, myWeath, by = c("county", "date")) %>%
  left_join(myInc, by = c("famincome" = "code"))

# row_na_percentage <- sum(is.na(myWorking$tmmn)) / nrow(myWorking) * 100 # 50% of people dont report county and just say state 

# row_na_percentage <- sum(is.na(myWorking$fam_inc_low)) / nrow(myWorking) * 100 # 100% of people report their family income
# row_na_percentage <- sum(myWorking$earnweek != 99999.99) / nrow(myWorking) * 100 # 50% of people report their weekly earnings

# -----------------------------------------------------------------------------
# Write
# -----------------------------------------------------------------------------

vroom_write(myWorking, "clean_data/4.weather_tc_2021.csv")












