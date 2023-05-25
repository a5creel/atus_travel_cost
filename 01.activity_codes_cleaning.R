# Goal: Get cleaned dataset of activities that our indoor and outdoor 
# Andie Creel / Started May 18th

library(ipumsr)
library(dplyr)
library(stringr)
library(readxl)
library(vroom)


# -----------------------------------------------------------------------------
# Read in activity codes from speadsheet to manipulate into two columns
# -----------------------------------------------------------------------------

# SOCIAL --------
# Get six digit code separate 
mySocial <- read_excel("raw_data/activity_codes/activity_codes.xls", 
                       sheet = "ACT_SOCIAL") %>%
  mutate(act_code = substr(Code, 1,7)) %>%
  mutate(descrip = substr(Code, 8, 999)) %>%
  select(-1) 

vroom_write(mySocial, "raw_data/activity_codes/raw/SOCIAL.csv", delim = ",") # save 

# SPORTS --------
# Get six digit code separate 
mySports <- read_excel("raw_data/activity_codes/activity_codes.xls", 
                       sheet = "ACT_SPORTS") %>%
  mutate(act_code = substr(Code, 1,7)) %>%
  mutate(descrip = substr(Code, 8, 999)) %>%
  select(-1) 

vroom_write(mySports, "raw_data/activity_codes/raw/SPORTS.csv", delim = ",") # save 
  
# TRAVEL --------
# Get six digit code separate 
myTravel <- read_excel("raw_data/activity_codes/activity_codes.xls", 
                       sheet = "ACT_TRAVEL") %>%
  mutate(act_code = substr(Code, 1,7)) %>%
  mutate(descrip = substr(Code, 8, 999)) %>%
  select(-1) 

vroom_write(myTravel, "raw_data/activity_codes/raw/TRAVEL.csv", delim = ",") # save  

  
  