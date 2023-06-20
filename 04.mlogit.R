# Goal: Get the mlogit to fit 
# Andie Creel / Started June 20th, 2023

rm(list = ls())
options(scipen = 999)
library(dplyr)
library(tidyr)
library(stringr)
library(vroom)
library(mlogit)


# -----------------------------------------------------------------------------
# test for logit 
# https://cran.r-project.org/web/packages/mlogit/vignettes/c2.formula.data.html
# -----------------------------------------------------------------------------
myLogitTest <- myWorking_trvl_cost %>%
  mutate(choice = if_else(number_activities > 0, 1, 0)) %>%
  filter(variable != "no_leisure") %>%
  filter(my_race != "other") %>% # can't have NAs 
  group_by(caseid) %>%
  mutate(choice_yes = sum(number_activities)) %>% # cant have no choice 
  filter(choice_yes != 0) %>%
  ungroup() %>%
  mutate(variable = as.factor(variable)) %>%
  filter(earnweek != 99999.99)

# relevel 
myLogitTest$variable <- relevel(myLogitTest$variable, ref = "leisure_home")

myTest <- dfidx(myLogitTest, idx = list(NA, "variable"))
ml.MC1 <- mlogit(choice ~ travel_time |earnweek, myTest)
summary(ml.MC1)
