# Goal: pull temperature data for fips and dates needed 
# Andie Creel / Started June 9th

library(dplyr)
library(vroom)
library(countyweather)
library(parallel)
library(purrr)

options(scipen = 999)
options("noaakey" = Sys.getenv("noaakey"))

# -----------------------------------------------------------------------------
# get list of cbgs 
# -----------------------------------------------------------------------------
myTC <- vroom("clean_data/my_activity_travel_long.csv") 
myDems <- vroom("clean_data/my_demographics.csv")

myWeather <- left_join(myTC, myDems, by = "caseid") %>%
  select(county, date) %>%
  distinct() 

myWeather$date <- as.Date(as.character(myWeather$date), format = "%Y%m%d")

# -----------------------------------------------------------------------------
# Get temperature data
# -----------------------------------------------------------------------------

#NEXT STEPS: run a loop through all firms and days i need

result_list <- mclapply(1:5, function(i) {
  tryCatch(
    daily_fips(fips = myWeather$county[i],
               date_min = myWeather$date[i], 
               date_max = myWeather$date[i], 
               var = "all"),
    error = function(e) {
      NA  # Return NA if an error occurs
    }
  )
}, mc.cores = 4)



# 
# filtered_list <- discard(result_list, ~ na.omit(.x))
# 
# 
# test<-result_list[!sapply(result_list, is.na)]
# 
# combined_df <- bind_rows(result_list[!sapply(result_list$daily_data$result, is.na)]$daily_data$result)
# 
# 
# combined_df <- result_list %>%
#   map_df(~ if (is.data.frame(.x)) .x else NA) %>%
#   filter(!is.na(.[[1]]))
