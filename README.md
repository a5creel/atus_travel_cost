# RUM travel cost model using ATUS data
This is for my first (and maybe multiple) dissertation chapter. 

Of interest: 
  - Substitution between indoor and outdoor rec under different climate scenarios 
  - How does that substitution change during seasons
  - How does it change for people living in an urban heat island 

<!--Note: I edited my .Renviron file and added a key from NOAA, but it ended up not being needed. I used Jude's gridMET code to get county level weather. 
-->
### Step One: Get activities coded
Used 01.activity_codes_cleaning.R to get CSVs of activity codes that indicates if a code is outdoor recreation or indoor leisure. I cleaned the files from the provided code book in R then went through each activity by hand and indicated if an activity was indoor leisure or outdoor recreation. CSVs in raw_data/activity_codes/raw/ are output from R script. Excel files in raw_data/activity_codes/hand_edited/ are where I did the coding. Final cleaned data set is "clean_data/my_codes.csv"

Outdoor rec: 

- included most things under 130000 "Sports, Exercise, and Recreation"
- included all activities in Berry et al except the activities associated with security
- Also included snow, water, and concrete activities (ex roller blading) that they had excluded presumably because they were interested in Lyme disease 

Indoor leisure: 

- included everything under 120000 "Socializing, Relaxing, and Leisure"
- included everything under 110000 "Eating and Drinking"
- there are some indoor leisure activities under "sports, exercise and recreation" that are included (aerobics, dancing, gym, etc)
- included 181205 "Travel as a form of entertainment (2005+)"

Travel: 

- indoor leisure: everything under travel coded with 120 or 110 except travel as a form of entertainment
- Outdoor rec: everything under travel coded with 130


## Step Two: Get quantity demand for each of my activities and travel time for some
Activities are: leisure at home, leisure away from home,  rec at home, rec away from home, no leisure or outdoor recreation.

In 02.number_of_activities.R: I get the quantity demanded for each of all 5 activities by every individual in that years ATUS data set.   

I calculate travel time for if people leisure/recreate at home (travel cost equals 0 minutes) and if they choose do away from home leisure/recreation. I calculate the average travel time for away from home activities (total travel divided by # of activities done in that category) and the total time for away from home activities. There are more travel time times to calculate in step 3.

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
- I calculate average travel time for away from home activities 
- I calculate total travel time for away form home activities 
- write long data set "clean_data/2.num_activities_ALL.csv" with number of choices for recreation and leisure by an individual on their interview date and the average travel time for that activity
- All individuals are included in this file (inclusion of "no leisure" makes this a full set of people)


## Step Three: Get travel time for remaining activites 
Get travel time for when someone doesn't demand any away from home recreation or leisure and for when people don't leisure/recreate at all. 

I do this in two ways for both average travel time and total travel time: 
  - I group by year and race, then get the average travel time and use that for new trips
  - I group by year and stats, "

I include when people do an activity away from home but record 0 travel time. I figured these are trips where someone does leisure or recreation while running errands, so they genuinely don't have travel time. If these are trips with a real travel cost of 0, those should be included in averages. Ex. Stopping  at the park while running errands.

**a lot of missing income!!**

## Step Four
Merges in weather **and family income**. 

This uses Jude Bayham's [gridMET repository](https://github.com/a5creel/gridMETr). The weather county is by date and county. 

I use the income codes and get the lower bound of the bin, the upper bound of the bin, and the midpoint of the binned income. 100% of respondents in 2021 reported this income, whereas only ~50% report their weekly earning. 

**ATTN:** I need to address that this cna only be set identified with income ! 

## Step Five 
how to use mlogit: https://chat.openai.com/share/2e6aec1d-3a2b-4a37-b0fd-9c2b381a6319


# Next Steps:

- create a different race indicator (over identified)
  - investigate just white vs black ? 
- find a dataset for urban heat islands 

