# Goal: pull temperature data for fips and dates needed 
# Andie Creel / Started June 9th
rm(list = ls())
library(dplyr)
library(vroom)
# library(devtools)
# install_github("leighseverson/countyweather")

library(countyweather)
library(parallel)
# library(purrr)

options(scipen = 999)
options("noaakey" = Sys.getenv("noaakey")) #reading in noaa key from .Renviron file in home directory 
Sys.getenv("OBJC_DISABLE_INITIALIZE_FORK_SAFETY") # edited in .Renviron file (for parallel stuff)

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

# length <- nrow(myWeather)
length <- 10


# Perform parallel processing using mclapply()
result_list <- mclapply(1:length, function(i) {

    result <- daily_fips(fips = myWeather$county[i],
                         date_min = myWeather$date[i], 
                         date_max = myWeather$date[i], 
                         var = "all")
    temp_df <- as.data.frame(result$daily_data$result) %>%
      mutate(fips = myWeather$county[i])# Return the result if successful
        
}, mc.cores = 4)


bad <- sapply(result_list, inherits, what = "try-error")
result_list_good <- result_list[!bad]
final_weather_df <- bind_rows(result_list_good)

