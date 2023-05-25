# Goal: Wrangle all the data
# Andie Creel / Started May 18th

library(ipumsr)
library(dplyr)
library(stringr)

# -----------------------------------------------------------------------------
# Load data downloaded from IPUMS (code provided by IPUMS)
# atus_00002 only has 2017 - 2022
# -----------------------------------------------------------------------------
ddi <- read_ipums_ddi("raw_data/atus_00002.xml") #reads in code book
myData <- read_ipums_micro(ddi) # reads in data 

# -----------------------------------------------------------------------------
# Initial cleaning: drop replicate 
# -----------------------------------------------------------------------------

# Codes I am using 
# 1813.. : Travel Related to Sports, Exercise, and Recreation
# 130000 : Sports, Exercise, and Recreation

myWorking <- myData %>%
  select(-starts_with("RWT")) %>% # dropping replicate weights
  filter(YEAR == 2021) %>% # starting only with 2021 only 
  mutate(ACTIVITY = str_pad(ACTIVITY, width = 6, pad = "0", side = "left")) %>% #getting activity code back to 6 digits 
  filter(str_starts(ACTIVITY, "1813") | str_starts(ACTIVITY, "130")) 
  


