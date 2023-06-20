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

myTC <- myTC_og %>%
  filter(year == 2021) %>% 
  mutate(date = as.Date(as.character(date), format = "%Y%m%d")) %>%
  mutate()

myWeath <- myWeath_og %>%
  mutate(county = as.numeric(county))

# -----------------------------------------------------------------------------
# Merge
# -----------------------------------------------------------------------------

myWorking <- left_join(myTC, myWeath, by = c("county", "date"))

# row_na_percentage <- sum(is.na(myWorking$tmmn)) / nrow(myWorking) * 100 # 50% of people dont report county and just say state 

# -----------------------------------------------------------------------------
# Write
# -----------------------------------------------------------------------------

vroom_write(myWorking, "clean_data/4.weather_tc_2021.csv")













