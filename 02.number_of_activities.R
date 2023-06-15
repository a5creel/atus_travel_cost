# Goal: Get the quantity demanded for each of 5 activities and some of the 
#       travel times 
# Andie Creel / Started May 18th

rm(list = ls())
library(ipumsr)
library(dplyr)
library(tidyr)
library(stringr)
library(vroom)
library(devtools)

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
  mutate(outdoor_home = outdoor_rec * outdoor_other_temp) %>%
  select(-outdoor_other_temp, -outdoor_away_temp)

(sum(myWorking$outdoor_rec) == sum(myWorking$outdoor_home) + sum(myWorking$outdoor_away))

# -----------------------------------------------------------------------------
# Indicating if indoor leisure is at a home (yours or another) or other 
# 0101: Respondents's home or yard
# 0103: Someone else's home
# -----------------------------------------------------------------------------

myWorking <- myWorking %>%
  mutate(indoor_home_temp = if_else(where == 101 | where == 103, 1, 0)) %>%
  mutate(indoor_home = indoor_leisure * indoor_home_temp) %>%
  
  mutate(indoor_other_temp = if_else(where != 101 & where != 103, 1, 0)) %>%
  mutate(indoor_away = indoor_leisure * indoor_other_temp) %>%
  select(-indoor_other_temp, -indoor_home_temp)

(sum(myWorking$indoor_leisure) == sum(myWorking$indoor_home) + sum(myWorking$indoor_away))

# -----------------------------------------------------------------------------
# How many activities per day do people do?
# -----------------------------------------------------------------------------
myWorking_num <- myWorking %>%
  group_by(caseid, date) %>%
  mutate(num_rec = sum(outdoor_rec)) %>%
  mutate(num_rec_away = sum(outdoor_away)) %>%
  mutate(num_rec_home = sum(outdoor_home)) %>%

  mutate(num_leisure = sum(indoor_leisure)) %>%
  mutate(num_leisure_home = sum(indoor_home)) %>%
  mutate(num_leisure_away = sum(indoor_away)) %>%

  select(caseid, date,
         # num_rec, num_leisure, 
         num_rec_away, num_rec_home,
         num_leisure_home, num_leisure_away) %>%
  distinct()

# -----------------------------------------------------------------------------
# Assuming activities at home require zero travel cost
# -----------------------------------------------------------------------------

myWorking_num_trvl1 <- myWorking_num %>%
  mutate(trvl_rec_home = 0) %>%
  mutate(trvl_leisure_home = 0)

# -----------------------------------------------------------------------------
# Group by date and individual, construct: 
#   - Assumption that activities at home require zero travel cost
#   - Number of activities per day people do
#   - Travel time for away from home outdoor recreation 
#   - Travel time for away from home indoor leisure 
# -----------------------------------------------------------------------------

myWorking_grouped <- myWorking %>%
  mutate(travel_rec_long = duration * travel_outdoor_rec) %>%
  mutate(travel_leisure_long = duration * travel_indoor_leisure) %>%
  group_by(caseid, date) %>%
  
  # outdoor rec numbers 
  mutate(num_rec = sum(outdoor_rec)) %>%
  mutate(num_rec_away = sum(outdoor_away)) %>%
  mutate(num_rec_home = sum(outdoor_home)) %>%

  # indoor leisure numbers 
  mutate(num_leisure = sum(indoor_leisure)) %>%
  mutate(num_leisure_home = sum(indoor_home)) %>%
  mutate(num_leisure_away = sum(indoor_away)) %>%
  
  # travel for activities at home
  mutate(trvl_rec_home = 0) %>%
  mutate(trvl_leisure_home = 0) %>%
  
  # no leisure 
  mutate(temp_no_leisure = num_leisure_home + num_rec_home + num_leisure_away + num_rec_away) %>%
  mutate(no_leisure.num = if_else(temp_no_leisure == 0, 1, 0)) %>%
  mutate(no_leisure.trvl = NA) %>%
  
  # getting travel time for away from home activities 
  mutate(total_time_rec = sum(travel_rec_long)) %>%
  mutate(total_time_leisure = sum(travel_leisure_long)) %>%

  select(caseid, date, num_rec, num_leisure, 
         num_rec_away, num_rec_home, 
         num_leisure_away, num_leisure_home,
         total_time_rec, total_time_leisure,
         trvl_rec_home, trvl_leisure_home, 
         no_leisure.num, no_leisure.trvl) %>%
  distinct() %>%
  
  #get average travel for activity
  mutate(trvl_rec_away = total_time_rec/num_rec_away) %>%
  mutate(trvl_leisure_away = total_time_leisure/num_leisure_away) %>%
  select(caseid, date, 
         num_leisure_home, num_rec_home, num_leisure_away, num_rec_away,
         trvl_leisure_home, trvl_rec_home, trvl_leisure_away, trvl_rec_away, 
         no_leisure.num, no_leisure.trvl) %>%
  
  #renaming for pivot
  rename(leisure_home.num = num_leisure_home,
         rec_home.num = num_rec_home,
         leisure_away.num = num_leisure_away,
         rec_away.num = num_rec_away,
         leisure_home.trvl = trvl_leisure_home,
         rec_home.trvl = trvl_rec_home,
         leisure_away.trvl = trvl_leisure_away,
         rec_away.trvl = trvl_rec_away)

myFinal <- myWorking_grouped %>% 
  pivot_longer(cols = -c(caseid, date),
               names_to = c("variable", ".value"),
               names_pattern = "(.*)\\.(.*)")%>% 
  rename(number_activities = num, travel_time = trvl)


# -----------------------------------------------------------------------------
# Save files
# -----------------------------------------------------------------------------

vroom_write(myFinal, "clean_data/my_activity_travel_long.csv", delim = ",")


