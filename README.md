# atus_travel_cost
This is for my first (and maybe multiple) dissertation chapter. Of interest: substitution between indoor and outdoor rec under different climate scenarios 


## Data Wrangle 

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

03.___.R indicates what activities are mine of interest 

NEXT STEP: collect travel time, indicate no trips. think about what no trips really are. 

