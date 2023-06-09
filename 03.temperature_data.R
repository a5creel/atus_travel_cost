# Goal: pull temperature data for fips and dates needed 
# Andie Creel / Started June 9th

library(dplyr)
library(vroom)
library(countyweather)

# -----------------------------------------------------------------------------
# Get temperature data
# -----------------------------------------------------------------------------
andrew_precip <- daily_fips(fips = c("12086", "02001"), date_min = "1992-08-01", 
                            date_max = "1992-08-31", var = "prcp")

andrew_precip$daily_data$result

#NEXT STEPS: run a loop through all firms and days i need



