# Goal: Wrangle all the data
# Andie Creel / Started May 18th

rm(list = ls())
library(ipumsr)
library(dplyr)
library(stringr)

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
# -----------------------------------------------------------------------------

# Dropping replicate weights, only working with one year
myWorking <- myData %>%
  select(-starts_with("RWT")) %>% # dropping replicate weights
  filter(YEAR == 2021) %>% # starting only with 2021 only 
  mutate(ACTIVITY = str_pad(ACTIVITY, width = 6, pad = "0", side = "left")) 

# lower case 
names(myWorking) <- tolower(names(myWorking))

# selecting variables
myWorking <- myWorking %>%
  select(year, statefip, county, date,
         age, sex, race, hispan, asian, marst, citizen, educyrs, 
         earnweek, hourwage, 
         activity, where, duration, interact)
  
# -----------------------------------------------------------------------------
# Indicating if an activity is one of my four of interest. 
# -----------------------------------------------------------------------------

# merging in four activities of interest 
myWorking <- left_join(myWorking, myCodes, by = c("activity" = "act_code")) %>%
  select(-different_from_berry, -not_sure_on_coding)
  
# Replace NA values with 0s in the specified columns
columns_to_change <- c("indoor_leisure", "outdoor_rec", "travel_outdoor_rec", "travel_indoor_leisure", "my_code")
myWorking[, columns_to_change][is.na(myWorking[, columns_to_change])] <- 0
  
  

  



