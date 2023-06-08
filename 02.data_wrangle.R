# Goal: Wrangle all the data
# Andie Creel / Started May 18th

rm(list = ls())
library(ipumsr)
library(dplyr)
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
# Indicating if an activity is one of my four of interest. 
# -----------------------------------------------------------------------------

# merging in four activities of interest 
myWorking <- left_join(myWorking_tc, myCodes, by = c("activity" = "act_code")) %>%
  select(-different_from_berry, -not_sure_on_coding)
  
# Replace NA values with 0s in the specified columns
# columns_to_change <- c("indoor_leisure", "outdoor_rec", "travel_outdoor_rec", "travel_indoor_leisure", "my_code")
# myWorking[, columns_to_change][is.na(myWorking[, columns_to_change])] <- 0


# -----------------------------------------------------------------------------
# How many ourdoor rec activites per day do people do?
# -----------------------------------------------------------------------------
myNum_activites <- myWorking %>%
  group_by(caseid, date) %>%
  mutate(num_rec = sum(outdoor_rec, na.rm = T)) %>%
  mutate(num_leisure = sum(indoor_leisure, na.rm = T)) %>%
  select(caseid, date, num_rec, num_leisure) %>%
  distinct()


test_1 <- myNum_activites %>%
  filter(num_rec != 0)

test_2 <- myNum_activites %>%
  filter(num_leisure != 0)

mean(test_1$num_rec) # 1.22
mean(test_2$num_leisure) # 5.14

# -----------------------------------------------------------------------------
# Get temperature data
# -----------------------------------------------------------------------------
andrew_precip <- daily_fips(fips = c("12086", "02001"), date_min = "1992-08-01", 
                            date_max = "1992-08-31", var = "prcp")

andrew_precip$daily_data$result

#NEXT STEPS: run a loop through all firms and days i need

# -----------------------------------------------------------------------------
# Group by date and individual, construct: 
#   - travel time for outdoor recreation 
#   - travel time for indoor leisure 
# -----------------------------------------------------------------------------

#how to use mlogit
#https://chat.openai.com/share/2e6aec1d-3a2b-4a37-b0fd-9c2b381a6319

myWorking_grouped <- myWorking %>%
  mutate(travel_rec_long = duration * travel_outdoor_rec) %>%
  mutate(travel_leisure_long = duration * travel_indoor_leisure) %>%
  group_by(caseid, date) %>%
  mutate(travel_time_rec = sum(travel_rec_long)) %>%
  mutate(travel_time_leisure = sum(travel_leisure_long)) %>%
  select(caseid, date, travel_time_rec, travel_time_leisure) %>%
  distinct()






