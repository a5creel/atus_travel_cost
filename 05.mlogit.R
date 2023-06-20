# Goal: Get the mlogit to fit 
# Andie Creel / Started June 20th, 2023
# Helpful link: https://cran.r-project.org/web/packages/mlogit/index.html

rm(list = ls())
options(scipen = 999)
library(dplyr)
library(tidyr)
library(stringr)
library(vroom)
library(mlogit)

# -----------------------------------------------------------------------------
# Read in data
# -----------------------------------------------------------------------------

myWorking <- vroom("clean_data/4.weather_tc_2021.csv")

# -----------------------------------------------------------------------------
# Data cleaning 
# https://cran.r-project.org/web/packages/mlogit/vignettes/c2.formula.data.html
# -----------------------------------------------------------------------------
myLogit_df <- myWorking %>%
  mutate(choice = if_else(number_activities > 0, 1, 0)) %>% # demand is 0/1 (extensive, not intensive)
  # filter(variable != "no_leisure") %>% 
  filter(my_race != "other") %>% # can't have NAs 
  group_by(caseid) %>%
  mutate(choice_yes = sum(number_activities)) %>% 
  filter(choice_yes != 0) %>%# cant have no choice
  ungroup() %>%
  mutate(variable = as.factor(variable)) %>%
  filter(earnweek != 99999.99) %>% #dropping people who we don't have weekly earnings for
  filter(!is.na(tmmx)) %>% # dropping people we don't have weather for
  mutate(my_race = as.factor(my_race)) 

# relevel so everything is compared to at home leisure  
# myLogit_df$variable <- relevel(myLogit_df$variable, ref = "leisure_home")

#turning into mlogit object
myLogit_formatted <- dfidx(myLogit_df, idx = list(NA, "variable"))

# -----------------------------------------------------------------------------
# running regression
# -----------------------------------------------------------------------------
reg1 <- mlogit(choice ~ travel_time | earnweek + tmmx, # formula
               myLogit_formatted, #mlogit data object
               reflevel = "leisure_home", #reference level 
               alt.subset = c("leisure_home", "leisure_away", "rec_home", "rec_away")) # choices available

summary(reg1)



reg2 <- mlogit(choice ~ travel_time | my_race , # formula
               myLogit_formatted, #mlogit data object
               reflevel = "leisure_home", #reference level 
               alt.subset = c("leisure_home", "leisure_away", "rec_home", "rec_away")) # choices available

summary(reg1)

apply(fitted(reg1, type = "probabilities"), 2, mean)


# -----------------------------------------------------------------------------
# Checking fitness
# -----------------------------------------------------------------------------

test_1 <- reg1$fitted.values
test_2 <- reg1$residuals[,1]

mean(test_1)

with(ml.MC1, {
  plot(test_1, test_2, main = "Fitted vs Residuals")
  qqnorm(test_2)
})
