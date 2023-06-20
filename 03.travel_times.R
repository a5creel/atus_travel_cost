# Get the rest of the travel times calculated for each activity 
# Started on June 15th, 2023

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
# Read in files
# -----------------------------------------------------------------------------

myTC_og <- vroom("clean_data/2.num_activities_ALL.csv") %>%
  mutate(year = as.numeric(substr(as.character(date), 1,4)))
  

myDems_og <- vroom("clean_data/2.demographics_ALL.csv")

# -----------------------------------------------------------------------------
# Get race/ethnicity variable 
# These 10 race/ethnicity variables cover all but .1%
# -----------------------------------------------------------------------------

# Race variables:
# 0100: White only
# 0110: Black only
# 0120:American Indian, Alaskan Native
# 0131: Asian only
# 0132: Hawaiian Pacific Islander only

# 0200: White-Black
# 0201: White-American Indian
# 0202: White-Asian

# Hispanic variables:
# 100: not Hispanic
# I construct: 
#   white Hispanic
#   black Hispanic

myDem_race <- myDems_og %>%
  mutate(my_race = NA) %>%
  mutate(my_race = if_else(race == 100 & hispan == 100 , "white_noH", my_race)) %>%
  mutate(my_race = if_else(race == 100 & hispan != 100 , "hispanic_white", my_race)) %>%
  mutate(my_race = if_else(race == 110 & hispan == 100 , "black", my_race)) %>%
  mutate(my_race = if_else(race == 110 & hispan != 100 , "hispanic_black", my_race)) %>%
  mutate(my_race = if_else(race == 120, "native", my_race)) %>%
  mutate(my_race = if_else(race == 131, "asian", my_race)) %>%
  mutate(my_race = if_else(race == 132, "islander", my_race)) %>%
  mutate(my_race = if_else(race == 200, "white-black", my_race)) %>%
  mutate(my_race = if_else(race == 201, "white-native", my_race)) %>%
  mutate(my_race = if_else(race == 202, "white-asian", my_race)) %>%
  mutate(my_race = if_else(is.na(my_race), "other", my_race)) %>%
  select(caseid, year, my_race, county, hourwage, earnweek, famincome)
  

# -----------------------------------------------------------------------------
# calculate average travel time for each race for:
#   away from home leisure 
#   away form home rec

# I'll use this calculated time for no trips 
# -----------------------------------------------------------------------------

# data set of recreation trips with positive demand and travel time
myAvgTrvl_rec <- left_join(myTC_og, myDem_race, by = c("caseid", "year")) %>%
  filter(variable == "rec_away") %>%
  filter(number_activities != 0) %>%
  group_by(my_race, year) %>%
  mutate(avg_trvl_time_rec = mean(travel_time)) %>%
  select(year, my_race, avg_trvl_time_rec) %>%
  distinct()

# data set of leisure with positive demand and travel time
myAvgTrvl_leisure <- left_join(myTC_og, myDem_race, by = c("caseid", "year")) %>%
  filter(variable == "leisure_away") %>%
  filter(number_activities != 0) %>%
  group_by(my_race, year) %>%
  mutate(avg_trvl_time_leisure = mean(travel_time)) %>%
  select(year, my_race, avg_trvl_time_leisure) %>%
  distinct()


myRaceCounts <- myDem_race %>%
  group_by(year) %>%
  count(my_race, name = "race_count")

myAvg_trvl_time <- left_join(myRaceCounts, myAvgTrvl_leisure, by = c("my_race", "year")) %>%
  left_join(myAvgTrvl_rec, by = c("my_race", "year"))

rm(myRaceCounts, myAvgTrvl_leisure, myAvgTrvl_rec)

# -----------------------------------------------------------------------------
# Add race and avg travel time for no trip. 
# -----------------------------------------------------------------------------

# merge in race and avg travel time
myWorking_merge <- left_join(myTC_og, myDem_race, by = c("caseid", "year")) %>%
  left_join(myAvg_trvl_time, by = c("my_race", "year"))


# if someone has no trip for an activity, make travel_time be equal 
# to the average travel time for that activity for that individual's racial group
myWorking_trvl_time <- myWorking_merge %>%
  mutate(travel_time = if_else(variable == "leisure_away" & number_activities == 0, 
                               avg_trvl_time_leisure, travel_time)) %>%
  mutate(travel_time = if_else(variable == "rec_away" & number_activities == 0, 
                               avg_trvl_time_rec, travel_time)) %>%
  select(-race_count, -starts_with("avg"))

# -----------------------------------------------------------------------------
# calculate travel cost as 1/3 the wage rate (PER MIN) using weekly earnings 
# assuming at 35 hour work week 
# -----------------------------------------------------------------------------

myWorking_trvl_cost <- myWorking_trvl_time %>%
  mutate(opportunity_cost = earnweek/35/60/3) %>% # 35 hr work week, 60 mins per hour, 1/3 rate
  mutate(travel_cost = travel_time*opportunity_cost)

#clean up 
rm(myWorking_merge, myWorking_trvl_time)

# ~22k out of 45k ovs dont have their weekly earning included 
# test <- myWorking_trvl_cost %>%
#   filter(earnweek == 99999.99)

vroom_write(myWorking_trvl_cost, "clean_data/3.travel_times_all.csv")









