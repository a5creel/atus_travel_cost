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
library(stargazer)

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
  filter(race != "other") %>% # can't have NAs 
  group_by(caseid) %>%
  mutate(choice_yes = sum(number_activities)) %>% 
  filter(choice_yes != 0) %>%# cant have no choice
  ungroup() %>%
  mutate(variable = as.factor(variable)) %>%
  filter(earnweek != 99999.99) %>% #dropping people who we don't have weekly earnings for
  filter(!is.na(tmmx)) %>% # dropping people we don't have weather for
  mutate(race = as.factor(race)) 

# relevel so everything is compared to at home leisure  
# myLogit_df$variable <- relevel(myLogit_df$variable, ref = "leisure_home")

#turning into mlogit object
myLogit_formatted <- dfidx(myLogit_df, idx = list(NA, "variable"))

# -----------------------------------------------------------------------------
# running regression
# -----------------------------------------------------------------------------

# using travel time that's grouped by race 
reg1.a<- mlogit(choice ~ travel_time_total_race | earnweek + tmmx, # formula
               myLogit_formatted, #mlogit data object
               reflevel = "leisure_home", #reference level 
               alt.subset = c("leisure_home", "leisure_away", "rec_home", "rec_away")) # choices available

# using travel time that's grouped by state 
reg1.b<- mlogit(choice ~ travel_time_avg_state | earnweek + tmmx, # formula
                myLogit_formatted, #mlogit data object
                reflevel = "leisure_home", #reference level 
                alt.subset = c("leisure_home", "leisure_away", "rec_home", "rec_away")) # choices available

# totally robust to which one we use
stargazer(reg1.a, reg1.b, type = "text")
  

# probabilities of actual choice 
head(fitted(reg1.a, type = "outcome"), 5)

# probabilities of alternatives 
head(fitted(reg1.a, type = "probabilities"), 5)

# average fitted probabilities for every alternative equals 
#   the market shares of the alternatives in the sample
apply(fitted(reg1.a, type = "probabilities"), 2, mean)

# predict
predict(reg1.a)

# -----------------------------------------------------------------------------
# 10% increase in temperature 
# -----------------------------------------------------------------------------

# 10% increase in temperature 
myCounter <- myLogit_formatted %>%
  mutate(tmmx = tmmx * 1.1)

# old probabilities 
Oprob <- fitted(reg1.a, type = "probabilities")

#new probabilities 
Nprob <- predict(reg1.a, newdata = myCounter)

# old and new market shares (leads to big increase in recreation)
rbind(old = apply(Oprob, 2, mean), new = apply(Nprob, 2, mean))

# illustration of IIA assumption 
head(Nprob[, "leisure_away"] / Nprob[, "rec_away"]) 
head(Oprob[, "leisure_away"] / Oprob[, "rec_away"])

#NOTE: these don't equal one another because temperate affects each activity differently 
#   we didn't change the cost of one activity (if we'd done that, we'd expect the 
#   ratio of probabilities to state same for other activites bc of IIA)


# -----------------------------------------------------------------------------
# way too many race variables rn. 
# -----------------------------------------------------------------------------

#NOTE: I had to change the reference level bc it wouldn't fit otherwise
reg2 <- mlogit(choice ~ travel_time_avg_race | race, # formula
               myLogit_formatted, #mlogit data object
               reflevel = "leisure_away", #reference level
               alt.subset = c("leisure_home", "leisure_away", "rec_home", "rec_away")) # choices available

summary(reg2)



# -----------------------------------------------------------------------------
# Checking fitness
# -----------------------------------------------------------------------------

test_1 <- reg1.a$fitted.values
test_2 <- reg1.a$residuals[,1]

mean(test_1)

with(reg1.a, {
  plot(test_1, test_2, main = "Fitted vs Residuals")
  qqnorm(test_2)
})
