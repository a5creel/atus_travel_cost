# Get the rest of the travel times calculated for each activity 
# Started on June 15th, 2023

rm(list = ls())
library(ipumsr)
library(dplyr)
library(tidyr)
library(stringr)
library(vroom)

# -----------------------------------------------------------------------------
# Read in files
# -----------------------------------------------------------------------------

myWorking <- vroom("clean_data/my_activity_travel_long.csv")

myDems_og <- vroom("clean_data/my_demographics.csv")

myDems <- myDems_og %>%
  select(year, caseid, county, race, hispan, asian, hourwage)

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
  select(caseid, my_race)
  

# -----------------------------------------------------------------------------
# calculate average travel time for each race for:
#   away from home leisure 
#   away form home rec

# I'll use this calculated time for no trips 
# -----------------------------------------------------------------------------

# data set of recreation trips with positive demand and travel time
myAvgTrvl_rec <- left_join(myWorking, myDem_race, by = "caseid") %>%
  filter(variable == "rec_away") %>%
  filter(number_activities != 0) %>%
  # filter(travel_time != 0) %>%
  group_by(my_race) %>%
  mutate(avg_trvl_time_rec = mean(travel_time)) %>%
  select(my_race, avg_trvl_time_rec) %>%
  distinct()

# data set of leisure with positive demand and travel time
myAvgTrvl_leisure <- left_join(myWorking, myDem_race, by = "caseid") %>%
  filter(variable == "leisure_away") %>%
  filter(number_activities != 0) %>%
  # filter(travel_time != 0) %>%
  group_by(my_race) %>%
  mutate(avg_trvl_time_leisure = mean(travel_time)) %>%
  select(my_race, avg_trvl_time_leisure) %>%
  distinct()


myRaceCounts <- myDem_race %>%
  count(my_race, name = "race_count")

myAvg_trvl_time <- left_join(myRaceCounts, myAvgTrvl_leisure, by = "my_race") %>%
  left_join(myAvgTrvl_rec, by = "my_race")

rm(myRaceCounts, myAvgTrvl_leisure, myAvgTrvl_rec)

