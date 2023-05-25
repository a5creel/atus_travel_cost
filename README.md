# atus_travel_cost
This is for my first (and maybe multiple) dissertation chapter. Of interest: substitution between indoor and outdoor rec under different climate scenarios 


## Data Wrangle 

Step One: Used 01.activity_codes_cleaning.R to get a csv activity codes that indicates is a code is outdoor recreation or indoor leisure. I cleaned the files from the provided code book in R then went through each activity through hand and indicated if an activity was indoor or rec by hand. 

- included all activities in Berry et al except the activities associated with security. Also included snow, water, and concrete activities (roller blading) that they had excluded presumably bc they were interested in Lyme disease 
- there are some indoor leisure activities under "sports, exercise and recreation" that should be included (aerobics, dancing, gym, etc)