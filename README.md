# RUM travel cost model using ATUS data
This is for my first (and maybe multiple) dissertation chapter. Of interest: substitution between indoor and outdoor rec under different climate scenarios 

Note: I edited my .Renviron file and added a key from NOAA. 

### Step One: Get activities coded
Used 01.activity_codes_cleaning.R to get CSVs of activity codes that indicates if a code is outdoor recreation or indoor leisure. I cleaned the files from the provided code book in R then went through each activity by hand and indicated if an activity was indoor leisure or outdoor recreation. CSVs in raw_data/activity_codes/raw/ are output from R script. Excel files in raw_data/activity_codes/hand_edited/ are where I did the coding. Final cleaned data set is "clean_data/my_codes.csv"

Outdoor rec: 

- included most things under 130000 "Sports, Exercise, and Recreation"
- included all activities in Berry et al except the activities associated with security
- Also included snow, water, and concrete activities (ex roller blading) that they had excluded presumably bc they were interested in Lyme disease 

Indoor leisure: 

- included everything under 120000 "Socializing, Relaxing, and Leisure"
- included everything under 110000 "Eating and Drinking"
- there are some indoor leisure activities under "sports, exercise and recreation" that are included (aerobics, dancing, gym, etc)
- included 181205 "Travel as a form of entertainment (2005+)"

Travel: 

- indoor leisure: everything under travel coded with 120 or 110 except travel as a form of entertainment
- Outdoor rec: everything under travel coded with 130


## Step Two: Get quantity demand for each of my activities and travel time for some

In 02.number_of_activities.R: I get the quantity demanded for each of all 5 activities by every individual in that years ATUS data set. Activities are: leisure at home, leisure away from home,  rec at home, rec away from home, no leisure or outdoor recreation.  

I calculate travel time for if people leisure/recreate at home (zero) and if they choose do away from home leisure/recreation. There are more travel time times to calculate in step 3.

More detailed description: 

- write a demographic file "clean_data/my_demographics.csv" that can be merged back in later 
- use "my_codes.csv" to indicate which activities are mine of interest
- I **assume** that not indicating that at activity is "at home" is equivalent to indicating activity is "away from home". 
- Indicate if an activity is:
    - indoor leisure at home
    - indoor leisure not at home
    - outdoor rec at home (not away from home)
    - outdoor rec not at from home (away from home)
- calculate total number of each of these activities done by a person on one day
- I **assume** that:
    - If indoor leisure is at home, then the travel time was 0
    - If outdoor leisure is at home, then travel time was 0 
    - If indoor leisure is NOT at home, then the travel time was the sum of all travel for leisure divided by # of away from home leisure activities 
    - If outdoor recreation is NOT at home, then the travel time was the sum of all travel for recreation divided by the # of away from home recreation activities 
- write long data set "clean_data/my_activity_travel_long.csv" with number of choices for recreation and leisure by an individual on their interview data and the average travel time for that activity
- All individuals are included in this file (inclusion of "no leisure" makes this a full set of people)


## Step Three: Get travel time for remaining activites 
Get travel time for when someone doesn't demand any away from home recreation or leisure and for when people don't leisure/recreate at all. 

For 0 demand for away form home leisure/recreation, I get the average travel time to that away from home activity for that person's racial group (EJ literature to support grouping around race) and use that as the cost for no trips. I include observations where the observed demand is greater than zero to calculate average travel time. NOTE: some of these observations have zero travel time (because some people say the recreated away from home but don't include travel time to recreation. Ex. they stopped at the park while running errands.)

**Should I adjust the travel time for away from home activity with zero travel time?**

**a lot of missing income!!**

## Step Four

how to use mlogit: https://chat.openai.com/share/2e6aec1d-3a2b-4a37-b0fd-9c2b381a6319


# COME BACK 

- missing income
- zero travel cost for away from home activities 
- how to group for no trips (race?? State??) Need to do both. 
