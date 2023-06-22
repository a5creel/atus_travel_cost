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

###############################################################################
# Turn this into a function so I can run it over the years
###############################################################################

cleanYears <-function(extract, file_names){
  
  # -----------------------------------------------------------------------------
  # Load data downloaded from IPUMS (code provided by IPUMS) and activity codes
  # atus_00003 only has 2017 - 2022
  # -----------------------------------------------------------------------------
  ddi <- read_ipums_ddi(paste0("raw_data/atus_", extract, ".xml")) #reads in code book
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
    mutate(ACTIVITY = str_pad(ACTIVITY, width = 6, pad = "0", side = "left")) 
  
  # lower case 
  names(myWorking_temp) <- tolower(names(myWorking_temp))
    
  # Creating individual demographics file (to be merged in later)
  myDemographics <- myWorking_temp %>%
    select(year, statefip, county, caseid, 
           age, sex, race, hispan, marst, citizen, educyrs, 
           earnweek, hourwage, famincome) %>%
    mutate(caseid = format(caseid, scientific = FALSE)) %>%
    distinct()
  
  vroom_write(myDemographics, paste0("clean_data/2.demographics_", file_names, ".csv"), delim = ",")
  
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
  # Group by date and individual, construct number and travel
  # -----------------------------------------------------------------------------
  
  # Number of activities per day people do  
  myWorking_grouped_num <- myWorking %>%
    group_by(caseid, date) %>%
    
    # outdoor rec numbers 
    mutate(num_rec = sum(outdoor_rec)) %>%
    mutate(num_rec_away = sum(outdoor_away)) %>%
    mutate(num_rec_home = sum(outdoor_home)) %>%
  
    # indoor leisure numbers 
    mutate(num_leisure = sum(indoor_leisure)) %>%
    mutate(num_leisure_home = sum(indoor_home)) %>%
    mutate(num_leisure_away = sum(indoor_away)) %>%
   
   # no leisure 
    mutate(temp_no_leisure = num_leisure_home + num_rec_home + num_leisure_away + num_rec_away) %>%
    mutate(no_leisure.num = if_else(temp_no_leisure == 0, 1, 0)) %>%
    mutate(no_leisure.trvltot = NA) %>%
    
    ungroup()
    
  # travel time for away from home activities 
  myWorking_grouped_travel <- myWorking_grouped_num %>%
    mutate(travel_rec_long = duration * travel_outdoor_rec) %>%
    mutate(travel_leisure_long = duration * travel_indoor_leisure) %>%
    group_by(caseid, date) %>% 
    
    # travel for activities at home
    mutate(trvl_rec_home = 0) %>%
    mutate(trvl_leisure_home = 0) %>%
    
    # getting travel time for away from home activities 
    mutate(total_time_rec = sum(travel_rec_long)) %>%
    mutate(total_time_leisure = sum(travel_leisure_long)) %>%
  
    select(caseid, date, 
           num_rec_away, num_rec_home, 
           num_leisure_away, num_leisure_home,
           no_leisure.num, no_leisure.trvltot,
           trvl_rec_home, trvl_leisure_home, 
           total_time_rec, total_time_leisure) %>%
    distinct() 

  #get average travel for activity
  myWorking_grouped_travel_2 <- myWorking_grouped_travel %>%
    mutate(avg_time_rec = total_time_rec/num_rec_away) %>%
    mutate(avg_time_leisure = total_time_leisure/num_leisure_away) %>%
    
    #renaming for pivot
    rename(leisure_home.num = num_leisure_home,
           rec_home.num = num_rec_home,
           leisure_away.num = num_leisure_away,
           rec_away.num = num_rec_away,
           
           leisure_home.trvlavg = trvl_leisure_home,
           rec_home.trvlavg = trvl_rec_home,
           leisure_away.trvlavg = avg_time_leisure,
           rec_away.trvlavg = avg_time_rec,
           
           leisure_home.trvltot= trvl_leisure_home,
           rec_home.trvltot = trvl_rec_home,
           leisure_away.trvltot = total_time_leisure,
           rec_away.trvltot = total_time_rec)
  
  myFinal <- myWorking_grouped_travel_2 %>% 
    pivot_longer(cols = -c(caseid, date),
                 names_to = c("variable", ".value"),
                 names_pattern = "(.*)\\.(.*)")%>% 
    rename(number_activities = num, 
           travel_time_avg = trvlavg, 
           travel_time_total = trvltot) %>%
    mutate(travel_time_avg = if_else(variable == "rec_home" | variable == "leisure_home", 0, travel_time_avg))
  
  # -----------------------------------------------------------------------------
  # Save files
  # -----------------------------------------------------------------------------
  
  vroom_write(myFinal, paste0("clean_data/2.num_activities_long_", file_names, ".csv"), delim = ",")

}

###############################################################################
# Run (only need to run once) (NOTE: average and total are correct here. )
###############################################################################

cleanYears("00004", "2013-2021")
cleanYears("00005", "2003-2012")

###############################################################################
# Merge all files into one 
###############################################################################

# Demographics 
myDem1 <- vroom("clean_data/2.demographics_2003-2012.csv")
myDem2 <- vroom("clean_data/2.demographics_2013-2021.csv")

myDem <- bind_rows(myDem1, myDem2)

vroom_write(myDem, "clean_data/2.demographics_ALL.csv")


# number of activities 
myNum1 <- vroom("clean_data/2.num_activities_long_2003-2012.csv")
myNum2 <- vroom("clean_data/2.num_activities_long_2013-2021.csv")

myNum <- bind_rows(myNum1, myNum2)

vroom_write(myNum, "clean_data/2.num_activities_ALL.csv")



