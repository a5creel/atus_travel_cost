# RUM travel cost model using ATUS data
This is for my first (and maybe multiple) dissertation chapter. Of interest: substitution between indoor and outdoor rec under different climate scenarios 


## Data Wrangle 

Note: I edited my .Renviron file and added a key from NOAA. 

### Step One
Used 01.activity_codes_cleaning.R to get CSVs of activity codes that indicates if a code is outdoor recreation or indoor leisure. I cleaned the files from the provided code book in R then went through each activity by hand and indicated if an activity was indoor leisure or outdoor recreation. CSVs in raw_data/activity_codes/raw/ are output from R script. Excel files in raw_data/activity_codes/hand_edited/ are where I did the coding. Final cleaned dataset is "clean_data/my_codes.csv"

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


## Step Two

- write a demographic file "clean_data/my_demographics.csv" that can be merged back in later 
- use "my_codes.csv" to indicate which activities are mine of interest
- Indicate if an activity is:
    - indoor leisure at home
    - indoor leisre not at home
    - outdoor rec away from home
    - outdoor rec not away from home
- if someone does outdoor recreation on a day, they do ~1.19 activities (away from home)
- if someone does indoor leisure on a day, they do ~2 activities (away from home)
- I NEED TO REDO THIS STEP AND THE FOLLOWING, conditioning on ppl doing an activity AND traveling for that activity
- calculate average travel for the activity
- write "clean_data/my_case_ids.csv" which is relevant caseids after the conditioning 
- write long data set "clean_data/my_activity_travel_long.csv" with number of choices for recreation and leisure by an individual on their interview data and the average travel cost for that activity

**I need to get people who do no rec or leisure at all**


Next steps:

- get data for no trips set up

how to use mlogit: https://chat.openai.com/share/2e6aec1d-3a2b-4a37-b0fd-9c2b381a6319



