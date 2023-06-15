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





