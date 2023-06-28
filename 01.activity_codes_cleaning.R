# Goal: Extract activity codes from code book to be hand cleaned
# Andie Creel / Started May 18th

rm(list = ls())
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


# EATING AND DRINK --------
myEat <- read_excel("raw_data/activity_codes/activity_codes.xls", 
                       sheet = "ACT_ALL") %>%
  mutate(act_code = substr(Code, 1,7)) %>%
  mutate(descrip = substr(Code, 8, 999)) %>%
  select(-1) %>%
  filter(str_starts(act_code, "11"))

vroom_write(myEat, "raw_data/activity_codes/raw/EAT.csv", delim = ",") # save  

# -----------------------------------------------------------------------------
# merge into one file, write to clean_data
# -----------------------------------------------------------------------------

myLeisure_1 <- read_excel("raw_data/activity_codes/hand_edited/SOCIAL_copy.xls")
myLeisure_2 <- read_excel("raw_data/activity_codes/hand_edited/EAT_copy.xls")

myRec <- read_excel("raw_data/activity_codes/hand_edited/SPORTS_copy.xls")

myTravel <- read_excel("raw_data/activity_codes/hand_edited/TRAVEL_copy.xls")

myCodes <- bind_rows(myLeisure_1, myLeisure_2, myRec, myTravel) #binding togethter
myCodes[is.na(myCodes)] <- 0 #replacing NA with 0

# dropping the codes that aren't outdoor rec, indoor leisure, or travel for one of the two
myCodes <- myCodes %>%
  mutate(my_code = indoor_leisure + outdoor_rec + travel_outdoor_rec + travel_indoor_leisure) %>%
  filter(my_code !=0) 

vroom_write(myCodes, "clean_data/1.my_codes.csv", delim = ",") # writing to clean data folder 

# -----------------------------------------------------------------------------
# raw ATUS data 
# -----------------------------------------------------------------------------

#reads in code book
ddi_1 <- read_ipums_ddi(paste0("raw_data/atus_00004.xml")) 
ddi_2 <- read_ipums_ddi(paste0("raw_data/atus_00005.xml")) 

# reads in data
myData_1 <- read_ipums_micro(ddi_1)
myData_2 <- read_ipums_micro(ddi_2) 

# write

vroom_write(myData_1, "clean_data/1.atus_2013-2021.csv")
vroom_write(myData_2, "clean_data/1.atus_2003-2012.csv")
  