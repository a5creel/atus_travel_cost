# Goal: Merge hand cleaned activity codes into one workable files 
# Andie Creel / Started May 18th

rm(list = ls())
library(ipumsr)
library(dplyr)
library(stringr)
library(readxl)
library(vroom)

# -----------------------------------------------------------------------------
# Read in handed coded activity codes
# -----------------------------------------------------------------------------

myLeisure_1 <- read_excel("raw_data/activity_codes/hand_edited/SOCIAL_copy.xls")
myLeisure_2 <- read_excel("raw_data/activity_codes/hand_edited/EAT_copy.xls")

myRec <- read_excel("raw_data/activity_codes/hand_edited/SPORTS_copy.xls")

myTravel <- read_excel("raw_data/activity_codes/hand_edited/TRAVEL_copy.xls")


# -----------------------------------------------------------------------------
# merge
# -----------------------------------------------------------------------------
myCodes <- bind_rows(myLeisure_1, myLeisure_2, myRec, myTravel) #binding togethter
myCodes[is.na(myCodes)] <- 0 #replacing NA with 0

# dropping the codes that aren't outdoor rec, indoor leisure, or travel for one of the two
myCodes <- myCodes %>%
  mutate(my_code = indoor_leisure + outdoor_rec + travel_outdoor_rec + travel_indoor_leisure) %>%
  filter(my_code !=0) 

vroom_write(myCodes, "clean_data/my_codes.csv", delim = ",") # writing to clean data folder 



