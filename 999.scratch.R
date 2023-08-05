# Goal: keep track of things i'm not ready to delete
# Andie Creel / Started: June 20, 2023


# -----------------------------------------------------------------------------
# stuff for camp resources 
# -----------------------------------------------------------------------------
myWork_og <- vroom("clean_data/1.atus_2013-2021.csv") 

#getting photo 
myWork <- myWork_og %>% 
  select(-starts_with("RWT")) %>% 
  select(DATE, CASEID, ACTIVITY, WHERE, DURATION, START, STOP) %>% 
  head(100)

# getting number of outdoor leisrue actvities we have coded 
numLes <- vroom("clean_data/1.my_codes.csv")
sum(numLes$outdoor_rec)





# -----------------------------------------------------------------------------
# Creating a file path for a .Renviron file to for NOAA api key 
# -----------------------------------------------------------------------------
# file_path <- file.path("~", ".Renviron")
# file.create(file_path)
# file.edit(file_path)
# options("noaakey" = Sys.getenv("noaakey"))

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# Set the number of cores to be used
num_cores <- detectCores()

# Perform parallel processing using mclapply()
result_list <- mclapply(1:length, function(i) {
  tryCatch(
    {
      # Capture and ignore the warning messages
      withCallingHandlers(
        {
          result <- daily_fips(fips = myWeather$county[i],
                               date_min = myWeather$date[i], 
                               date_max = myWeather$date[i], 
                               var = "all")
          result$daily_data$result # Return the result if successful
        },
        warning = function(w) {
          # Ignore the warning
          invokeRestart("muffleWarning")
        }
      )
    },
    error = function(e) {
      # Handle errors here
      NA  # Return NA if an error occurs
    }
  )
}, mc.cores = num_cores)

i<-5





# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# original way i was doing temp stuff using countyweather package
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
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


# -----------------------------------------------------------------------------
# How many activites per day do people do?
# -----------------------------------------------------------------------------
# myNum_activites <- myWorking %>%
#   group_by(caseid, date) %>%
#   mutate(num_rec = sum(outdoor_rec)) %>%
#   mutate(num_rec_away = sum(outdoor_away)) %>%
#   mutate(num_rec_not_away = sum(outdoor_not_away)) %>%
#   
#   mutate(num_leisure = sum(indoor_leisure)) %>%
#   mutate(num_leisure_home = sum(indoor_home)) %>%
#   mutate(num_leisure_not_home = sum(indoor_not_home)) %>%
#   
#   select(caseid, date, 
#          num_rec, num_rec_away, num_rec_not_away,  
#          num_leisure, num_leisure_home, num_leisure_not_home) %>%
#   distinct()
# 
# 
# test_1 <- myNum_activites %>%
#   filter(num_rec != 0)
# 
# test_2 <- myNum_activites %>%
#   filter(num_leisure != 0)
# 
# mean(test_1$num_rec) # 1.19
# mean(test_2$num_leisure) # 2


# # Goal: Read in weather data from gridmetR project (provided by Jude)
# # Andie Creel / Started June 9th
# 
# rm(list = ls())
# library(arrow)
# library(dplyr)
# library(purrr)
# install_github("leighseverson/countyweather")
# library(countyweather)
# 
# # -----------------------------------------------------------------------------
# # Read in data from other R project
# # -----------------------------------------------------------------------------
# 
# #Define folders (variables) to extract 
# # folder.names <- c("pr","rmin","rmax","srad","tmmx","tmmn", "vs")
# folder.names <- c("pr","rmin","rmax","srad","tmmx","tmmn") #FOR NOW ONLY BC VS MISSING
# 
# 
# #Define set of years (ATUS years are 2003 onward)
# # filter.years <- seq.int(2003,2022,1)
# 
# # Do it for one year
# results_list <- vector("list", length = length(folder.names))
# 
# for (i in 1:length(folder.names)) {
#  
#   # read in parquet file from where it's stored (may need to adjust this path if moved)
#   temp <- read_parquet(paste0("/Users/a5creel/Dropbox (YSE)/PhD Work/Andie's Prospectus/gridMETr/cache/", 
#                                          folder.names[i], 
#                                          "/",
#                                          folder.names[i],
#                                          "_2022.parquet"))
#   
#   # cleaning
#   temp <- as.data.frame(temp) %>%
#     rename(!!folder.names[i] := value) %>%
#     select(-var)
#   
#   # store
#   results_list[[i]] <- temp
#   
# }
# 
# # Extract the common columns that you don't want to duplicate
# common_columns <- c("county", "date")
# 
# # Combine the unique columns of the data frames
# final_df <- results_list %>%
#   purrr::map(select, -one_of(common_columns)) %>%
#   bind_cols()
# 
# # Add the common columns to the combined data frame
# final_df <- bind_cols(select(results_list[[1]], one_of(common_columns)), final_df)
# 
# 
# 

# 

