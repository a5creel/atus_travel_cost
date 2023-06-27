# #USE THE RMARKDOWN WRITE_UP INSTEAD.
# 
# 
# # Goal: Get the mlogit to fit 
# # Andie Creel / Started June 20th, 2023
# # Helpful link: https://cran.r-project.org/web/packages/mlogit/index.html
# 
# rm(list = ls())
# options(scipen = 999)
# library(dplyr)
# library(tidyr)
# library(stringr)
# library(vroom)
# library(mlogit)
# library(stargazer)
# library(lubridate)
# 
# # -----------------------------------------------------------------------------
# # read in R memory built in R_data_objs
# # -----------------------------------------------------------------------------
# 
# load("05.RUM_data_objs.RData")
# 
# # -----------------------------------------------------------------------------
# # running regression
# # -----------------------------------------------------------------------------
# 
# # using travel time that's grouped by race 
# reg1.a<- mlogit(choice ~ travel_time_total_race | fam_inc_mid + tmmx, # formula
#                myRUM_idx, #mlogit data object
#                reflevel = "leisure_home", #reference level 
#                alt.subset = c("leisure_home", "leisure_away", "rec_home", "rec_away")
#                ) # choices available (dropped no leisure)
# 
# # using travel time that's grouped by state 
# reg1.b<- mlogit(choice ~ travel_time_avg_state | fam_inc_mid + tmmx, # formula
#                 myRUM_idx, #mlogit data object
#                 reflevel = "leisure_home", #reference level 
#                 alt.subset = c("leisure_home", "leisure_away", "rec_home", "rec_away")) # choices available
# 
# # totally robust to which one we use
# stargazer(reg1.a, reg1.b, type = "text")
#   
# test <- fitted(reg1.a)
# 
# # probabilities of actual choice 
# head(fitted(reg1.a, type = "outcome"), 5)
# 
# # probabilities of alternatives 
# head(fitted(reg1.a, type = "probabilities"), 5)
# 
# # average fitted probabilities for every alternative equals 
# #   the market shares of the alternatives in the sample
# apply(fitted(reg1.a, type = "probabilities"), 2, mean)
# 
# # predict
# predict(reg1.a)
# 
# # -----------------------------------------------------------------------------
# # 10% increase in temperature 
# # -----------------------------------------------------------------------------
# 
# # 10% increase in temperature 
# myCounter <- myRUM_idx %>%
#   mutate(tmmx = tmmx * 1.1)
# 
# # old probabilities 
# Oprob <- fitted(reg1.a, type = "probabilities")
# 
# #new probabilities 
# Nprob <- predict(reg1.a, newdata = myCounter)
# 
# # old and new market shares (leads to big increase in recreation)
# rbind(old = apply(Oprob, 2, mean), new = apply(Nprob, 2, mean))
# 
# # illustration of IIA assumption 
# head(Nprob[, "leisure_away"] / Nprob[, "rec_away"]) 
# head(Oprob[, "leisure_away"] / Oprob[, "rec_away"])
# 
# #NOTE: these don't equal one another because temperate affects each activity differently 
# #   we didn't change the cost of one activity (if we'd done that, we'd expect the 
# #   ratio of probabilities to state same for other activites bc of IIA)
# 
# 
# # -----------------------------------------------------------------------------
# # way too many race variables rn. 
# # -----------------------------------------------------------------------------
# 
# # #NOTE: I had to change the reference level bc it wouldn't fit otherwise
# # reg2 <- mlogit(choice ~ travel_time_avg_race | race, # formula
# #                myRUM_idx, #mlogit data object
# #                reflevel = "leisure_away", #reference level
# #                alt.subset = c("leisure_home", "leisure_away", "rec_home", "rec_away")) # choices available
# # 
# # 
# # summary(reg2)
# 
# 
# # -----------------------------------------------------------------------------
# # Checking fitness
# # -----------------------------------------------------------------------------
# 
# test_1 <- reg1.a$fitted.values
# test_2 <- reg1.a$residuals[,1]
# 
# mean(test_1)
# 
# with(reg1.a, {
#   plot(test_1, test_2, main = "Fitted vs Residuals")
#   qqnorm(test_2)
# })
# 
# # -----------------------------------------------------------------------------
# # run by season 
# # -----------------------------------------------------------------------------
# 
# myQuarterReg <- function(i){
# 
#   myWorking_temp <- myRUM_idx %>%
#     filter(quarter == i) 
#   
#   reg <- mlogit(choice ~ travel_time_total_state | fam_inc_mid + tmmx, # formula
#                          myWorking_temp, #mlogit data object
#                          reflevel = "leisure_home", #reference level 
#                          alt.subset = c("leisure_home", "leisure_away", "rec_home", "rec_away")) # choices available (dropped no leisure)
#   
# }
# 
# 
# quarterRegs <- lapply(1:4, myQuarterReg)
# 
# 
# stargazer(quarterRegs[[1]], quarterRegs[[2]], quarterRegs[[3]], quarterRegs[[4]],
#           type = "text")
# 
# 
