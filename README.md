# Sports-Analytics-Hackathon
Sports Analytics Hackathon 
Australia tour of India 2019 will commence from 24th February 2019. There will be 2 T-20 matches and 5 ODI matches.
As a part of this Hackathon we will consider only 5 ODIs which will be played by Australia and India.
ODIs will commence on 2nd March,2019 and will be held on different cities in India.

# 1. Data Collection
Data has been collected from the following links:            
-> https://cricsheet.org/
-> http://stats.espncricinfo.com/ci/engine/stats/index.html

Input File : odi_summary_v1.csv -> Train Dataset
             ODI_summary_test.csv -> Test Data set

Data from cricksheet has been collected in XAML format and converted into .csv format by using Python.
Data for upcoming 5 matches were created manually to test the models.

 Three Datasheets has been prepared:
  1.ODI summary - consists of all the international One day Cricket Matches played since 2006 for Men and Women.
  2.Batting summary - consists of batting records for each player
  3.Bowling summary - consists of bowling stats per bowlers

# 2. Problem Statement 1 and 2:
##   1. Winner of the Series : Who will Win ODI series ? India or Australia!
##   2. Series Output : What will be the winning margin? White wash or 60-40 or something else!

## 2.1 Data Set Preparation and Cleaning
   For the first two problem statements ODI summary data sheet was used. 
   Since this data includes all the matches from International One Day cricket, we filtered the data set for India and Australia Men's 
   matches.
   There data from from 2006 to 2018. In which India won 20 times whereas Australia won 25 times.
   There were few data quality issues which were taken care:
   
                1. Few Match City fields were blank.Based on the corresponding Venues ,computed those blank Match Cities.
                2. There similar venue names - "Vidarbha Cricket Association Stadium, Jamtha" and "Vidarbha Cricket Association Ground".
                Hence converted them into one - "Vidarbha Cricket Association Ground"
                3. There were 10 records with blank winner column. Those were imputed as 'draw'.
                4.There were few fields with Blank values which were replaced with NA.                        
                5.Some redundant fields were removed - Man of the Match- as it is being decided after match result.Gender - since we are considering Mens' ODI only,Oversplayed - as it is supposed to be 50 by ODI rule.Match Type - as it is always ODI for our analysis.
                6. Data set had records per innings for each match. We converted the data into records per match. Now each reords will contain match reord for both the innings along common matrcies like Match.City,Venue,Date,Winner,Team1,Team2,Winner,Toss Winner,Toss Decision.

## 2.2 Exploratory Data Analysis
   i.Univariate EDA was performed to analyze different independent variables.Few insights from the categorical data are as follows.
   1. Analysis shows that Australia got highest number of wins at ODI match when played at Sydney whereas India got highest number of    wins at ODI match when played at Nagpur
   2. Both the countries got their highest winning when they decided to bat first in the Toss Decision.
   3. Australia has higher tendency to win the match when it wins the Toss compared to India.
   4. Playing at Home ground or Away does not have much effect on the Winning.
   5. Australia has highest winnings when it has batted in the first innings.
   6. Australia has low winning count when it batted on second innings. But compared to first innings,India has got better winning count when it batted on second innings.
   7. India has highest winning against Australia at Vidarbha Cricket Association ground and Australia has highest winning against India at Sydney Cricket ground.

  ii.After analysing categorical variables , we performed analysis on numeric variables. 
There were two data row with  NA values were found while doing summary on the data set. They were removed.

 iii.Two new metrices were derived from total runs per innings and total balls played per innings - First_innings_RunRate_perball and Second_innings_RunRate_perball

  iv.Few insights from the analysis on continuos data as follows:
  1. Australia overall has highest average Runs in First innings against India, though it has lowest runs as well.
  2. India has lowest average of number sixers in first innings, though it has a highest number of sixer against Australia.
  3. India has highest as lowest numbers of 4's against Australia in a match.
  4. Australia has highest average wickets on first innings against India.
  5. First Innings Average Runrate is slight high for Australia against india.
  6. India  has highest sixers in second innings against Australia.
  7. Australia lost highest agerage number of Wickets on second innings against India.

## 2.3 Modeling Approach
  1. Factorized target variable.We have considered value 1 when India is Winner and 0 when Australia s winner.
  2. Created dummy variables from factor variables having 2 or more number of levels.
  3. Splitted data set into train and test(for model validation).
  4. Built logistic Regression model using glm() and stepAIC().
  5. Final Logistic model gave Second_innings_Total.Runs as only predictor variable.
  6. Calculated cut off probability as 0.3770707.
  7. Confusion matrix gave Balanced Accuracy as 0.6364
  8. maximum KS  stat value = 0.2727273
  9. Using Time series we forecasted few items:
   --First_innings_Total.Runs
   --First_innings_Total.6s
   --First_innings_Total.4s
   --First_innings_Total.Wickets
   --First_innings_Total.Balls
   --Second_innings_Total.Runs
   --Second_innings_Total.6s
   --Second_innings_Total.4s
   --Second_innings_Total.Wickets
   --Second_innings_Total.Balls
  10. Used Auto arima model to forecast the above items for the upcoming 5 day ODIs
  11. Model validation was performed computing MAPE values.
  12. After forecasting these values we fed this data into final test data set created for 5 days upcoming ODI.
  13. Ran prediction model created using Logistic regression on the updated test data to get predicted probabilities.
  14. Used cut off 0.3770707 to predict the winners for the upcoming series.
   
# 3. Final Results for Problem 1 and 2
###    India will win the ODI series.
###    India vs Australia score will be 5-0. It will be white wash.!
  


