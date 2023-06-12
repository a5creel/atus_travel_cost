# Goal: Wrangle all the data
# Andie Creel / Started May 18th

rm(list = ls())
library(ipumsr)
library(dplyr)
library(tidyr)
library(stringr)
library(vroom)
library(devtools)
# install_github("leighseverson/countyweather")
library(countyweather)


# -----------------------------------------------------------------------------
# Creating a file path for a .Renviron file to for NOAA api key 
# -----------------------------------------------------------------------------
# file_path <- file.path("~", ".Renviron")
# file.create(file_path)
# file.edit(file_path)
options("noaakey" = Sys.getenv("noaakey"))

# -----------------------------------------------------------------------------
# Load data downloaded from IPUMS (code provided by IPUMS) and activity codes
# atus_00002 only has 2017 - 2022
# -----------------------------------------------------------------------------
ddi <- read_ipums_ddi("raw_data/atus_00002.xml") #reads in code book
myData <- read_ipums_micro(ddi) # reads in data 

myCodes <- vroom("clean_data/my_codes.csv") %>%
  filter(my_code == 1) %>% #should be included
  mutate(act_code = as.character(act_code))

# -----------------------------------------------------------------------------
# Initial cleaning: drop replicate weights, filtering on my activity codes 
# Creating individual demographics file
# -----------------------------------------------------------------------------

# Dropping replicate weights, only working with one year
myWorking_temp <- myData %>%
  select(-starts_with("RWT")) %>% # dropping replicate weights
  filter(YEAR == 2021) %>% # starting only with 2021 only 
  mutate(ACTIVITY = str_pad(ACTIVITY, width = 6, pad = "0", side = "left")) 

# lower case 
names(myWorking_temp) <- tolower(names(myWorking_temp))
  
# Creating individual demographics file (to be merged in later)
myDemographics <- myWorking_temp %>%
  select(year, statefip, county, caseid, 
         age, sex, race, hispan, asian, marst, citizen, educyrs, 
         earnweek, hourwage) %>%
  mutate(caseid = format(caseid, scientific = FALSE)) %>%
  distinct()

vroom_write(myDemographics, "clean_data/my_demographics.csv", delim = ",")

# selecting variables for travel cost 
myWorking_tc <- myWorking_temp %>%
  select(year, date, caseid, 
         activity, where, duration, interact)

rm(myWorking_temp)

# -----------------------------------------------------------------------------
# Indicating if an activity is indoor rec or outdoor rec
# -----------------------------------------------------------------------------

# merging in four activities of interest 
myWorking <- left_join(myWorking_tc, myCodes, by = c("activity" = "act_code")) %>%
  select(-different_from_berry, -not_sure_on_coding)
  
# Replace NA values with 0s in the specified columns
columns_to_change <- c("indoor_leisure", "outdoor_rec", "travel_outdoor_rec", "travel_indoor_leisure", "my_code")
myWorking[, columns_to_change][is.na(myWorking[, columns_to_change])] <- 0

# -----------------------------------------------------------------------------
# Indicating if outdoor rec is at home or other 
# 0109: Outdoors--not at home
# -----------------------------------------------------------------------------

myWorking <- myWorking %>%
  mutate(outdoor_away_temp = if_else(where == 109, 1, 0)) %>%
  mutate(outdoor_away = outdoor_rec * outdoor_away_temp) %>%

  mutate(outdoor_other_temp = if_else(where != 109, 1, 0)) %>%
  mutate(outdoor_not_away = outdoor_rec * outdoor_other_temp) %>%
  select(-outdoor_other_temp, -outdoor_away_temp)

(sum(myWorking$outdoor_rec) == sum(myWorking$outdoor_not_away) + sum(myWorking$outdoor_away))

# -----------------------------------------------------------------------------
# Indicating if indoor leisure is at a home (yours or another) or other 
# 0101: Respondents's home or yard
# 0103: Someone else's home
# -----------------------------------------------------------------------------

myWorking <- myWorking %>%
  mutate(indoor_home_temp = if_else(where == 101 | where == 103, 1, 0)) %>%
  mutate(indoor_home = indoor_leisure * indoor_home_temp) %>%
  
  mutate(indoor_other_temp = if_else(where != 101 & where != 103, 1, 0)) %>%
  mutate(indoor_not_home = indoor_leisure * indoor_other_temp) %>%
  select(-indoor_other_temp, -indoor_home_temp)

(sum(myWorking$indoor_leisure) == sum(myWorking$indoor_home) + sum(myWorking$indoor_not_home))

# -----------------------------------------------------------------------------
# How many activites per day do people do?
# -----------------------------------------------------------------------------
# myNum_activites <- myWorking %>%
#   group_by(caseid, date) %>%
#   mutate(num_rec = sum(outdoor_rec)) %>%
#   mutate(num_rec_away = sum(outdoor_away)) %>%
#   mutate(num_rec_not_away = sum(outdoor_not_away)) %>%
#   
#   mutate(num_leisure = sum(indoor_leisure)) %>%
#   mutate(num_leisure_home = sum(indoor_home)) %>%
#   mutate(num_leisure_not_home = sum(indoor_not_home)) %>%
#   
#   select(caseid, date, 
#          num_rec, num_rec_away, num_rec_not_away,  
#          num_leisure, num_leisure_home, num_leisure_not_home) %>%
#   distinct()
# 
# 
# test_1 <- myNum_activites %>%
#   filter(num_rec != 0)
# 
# test_2 <- myNum_activites %>%
#   filter(num_leisure != 0)
# 
# mean(test_1$num_rec) # 1.19
# mean(test_2$num_leisure) # 2
# 

# -----------------------------------------------------------------------------
# Group by date and individual, construct: 
#   - travel time for outdoor recreation 
#   - travel time for indoor leisure 
#   - conditioning variable for obs who EITHER 
#       - recreated AND traveled OR
#       - leisure AND travel 
#   - average travel time
# -----------------------------------------------------------------------------


# YOU ARE HERE. YOU HAVEN'T FIXED THIS FOR THE FOUR ACTIVITIES NOW. YOU NEED TO FIX TRAVEL TIME FOR THAT. 
# ALSO STILL NEED TO GET NO LEISURE AT ALL. 

# 
# myWorking_grouped <- myWorking %>%
#   mutate(travel_rec_long = duration * travel_outdoor_rec) %>%
#   mutate(travel_leisure_long = duration * travel_indoor_leisure) %>%
#   group_by(caseid, date) %>%
#  
#   # outdoor rec
#   mutate(num_rec = sum(outdoor_rec)) %>%
#   mutate(num_rec_away = sum(outdoor_away)) %>%
#   mutate(num_rec_not_away = sum(outdoor_not_away)) %>%
#   
#   # indoor leisure
#   mutate(num_leisure = sum(indoor_leisure)) %>%
#   mutate(num_leisure_home = sum(indoor_home)) %>%
#   mutate(num_leisure_not_home = sum(indoor_not_home)) %>%
#   
#   mutate(travel_time_rec = sum(travel_rec_long)) %>%
#   mutate(travel_time_leisure = sum(travel_leisure_long)) %>%
#   
#   select(caseid, date, num_rec, num_leisure, travel_time_rec, travel_time_leisure) %>%
#   distinct() %>%
#   
#   #only keep ppl who say they did activity AND traveled for that activity
#   mutate(travel_AND_rec = num_rec*travel_time_rec) %>% # will be zero if they didn't do both
#   mutate(travel_AND_rec = ifelse(travel_AND_rec != 0, 1, travel_AND_rec)) %>% # change to a 0/1 value
#   
#   mutate(travel_AND_leisure = num_leisure * travel_time_leisure) %>%
#   mutate(travel_AND_leisure = ifelse(travel_AND_leisure != 0, 1, travel_AND_leisure)) %>%
#   
#   mutate(travel_AND_activity = travel_AND_rec + travel_AND_leisure) %>%
#   mutate(travel_AND_activity = ifelse(travel_AND_activity != 0, 1, travel_AND_activity)) %>%
#   filter(travel_AND_activity != 0) %>% 
#   
#   #get average travel for activity
#   mutate(avgtravel_rec = travel_time_rec/num_rec) %>%
#   mutate(avgtravel_leisure = travel_time_leisure/num_leisure)
# 
# 
# sum(myWorking_grouped$travel_AND_rec) #487 obs for ppl who recreated and traveled
# sum(myWorking_grouped$travel_AND_leisure)# 2431 for leisure 
# 
# 
# #swing long (this has an obs for every person for rec and leisure)
# myFinal <- myWorking_grouped %>%
#   select(-starts_with("travel")) %>%
#   pivot_longer(cols = -c(caseid, date), 
#                names_to = c(".value", "choice"), 
#                names_sep = "_") 

# -----------------------------------------------------------------------------
# Save files
# -----------------------------------------------------------------------------

# relevant case IDs
myCaseIDS <- myFinal %>%
  ungroup() %>%
  select(caseid) %>%
  distinct()

vroom_write(myCaseIDS, "clean_data/my_case_ids.csv", delim = "," )

vroom_write(myFinal, "clean_data/my_activity_travel_long.csv", delim = ",")

