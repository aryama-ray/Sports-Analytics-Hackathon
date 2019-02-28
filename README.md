# Sports-Analytics-Hackathon
Sports Analytics Hackathon 
Australia tour of India 2019 will commence from 24th February 2019. There will be 2 T-20 matches and 5 ODI matches.
As a part of this Hackathon we will consider only 5 ODIs which will be played by Australia and India.
ODIs will commence on 2nd March,2019 and will be held on different cities in India.

# Data Collection
Data has been collected from the following links:            
-> https://cricsheet.org/
-> http://stats.espncricinfo.com/ci/engine/stats/index.html

Data from cricksheet has been collected in XAML format and converted into .csv format by using Python.
Data for upcoming 5 matches were created manually to test the models.

 Three Datasheets has been prepared:
  1.ODI summary - consists of all the international One day Cricket Matches played since 2006 for Men and Women.
  2.Batting summary - consists of batting records for each player
  3.Bowling summary - consists of bowling stats per bowlers

# Problem Statement 1 and 2:
##   1. Winner of the Series : Who will Win ODI series ? India or Australia!
##   2. Series Output : What will be the winning margin? White wash or 60-40 or something else!

## Data Set Preparation and Cleaning
   For the first two problem statements ODI summary data sheet was used. 
   Since this data includes all the matches from International One Day cricket, we filtered the data set for India and Australia Men's 
   matches.
   There were few data quality issues which were taken care:
   
                1. Few Match City fields were blank.Based on the corresponding Venues ,computed those blank Match Cities.
                2. There similar venue names - "Vidarbha Cricket Association Stadium, Jamtha" and "Vidarbha Cricket Association Ground".
                Hence converted them into one - "Vidarbha Cricket Association Ground"
                3. There were 10 records with blank winner column. Those were imputed as 'draw'.
                4.There were few fields with Blank values which were replaced with NA.                        
                5.Some redundant fields were removed - Man of the Match- as it is being decided after match result.Gender - since we are considering Mens' ODI only,Oversplayed - as it is supposed to be 50 by ODI rule.Match Type - as it is always ODI for our analysis.
                6. Data set had records per innings for each match. We converted the data into records per match. Now each reords will contain match reord for both the innings along common matrcies like Match.City,Venue,Date,Winner,Team1,Team2,Winner,Toss Winner,Toss Decision.








