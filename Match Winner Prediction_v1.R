###########################################################################################################################
#-----------------------Cricket Hackathon--------------------------------------------------------------------##         
###########################################################################################################################
#-----------------------Program Flow-------------------------------------------------------------------------------------##
#Business Understanding
#Data Understanding
#Data Preparation & EDA
#Model Building 
#Model Evaluation
###########################################################################################################################
#
#----------------------- Business Understanding--------------------------------------------------------------------------##
# Problem Statement 1 and 2:
##   1. Winner of the Series : Who will Win ODI series ? India or Australia!
##   2. Series Output : What will be the winning margin? White wash or 60-40!
##########################################################################################################################
#------------------------------------------------------------------------------------------------------------------------#
# SET UP WORK DIRECTORY
#-------------------------------------------------------------------------------------------------------------------------#
#setwd("H:/PG Diploma IN Data Science IIITB/Cricket Challenge/Data Preparation/DataSet")
#-------------------------------------------------------------------------------------------------------------------------#
# INSTALL PACKAGES AND LOAD REQUIRED LIBRARIES
#-------------------------------------------------------------------------------------------------------------------------# 

library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)
library(lubridate)
library(cowplot)
library(GGally)
library(MASS)
library(car)
library(e1071)
library(caret)
library(caTools)
library(ROCR)
library(lubridate)
library(dplyr)
library(ggplot2)
library(tidyr)
library(forecast)
library(tseries)
require(graphics)

#-------------------------------------------------------------------------------------------------------------------------#
#**********************DATA SOURCING**************************************************************************************#
#-------------------------------------------------------------------------------------------------------------------------#
#Input dataset
odi_summary <- read.csv("odi_summary_v1.csv",stringsAsFactors = F)

#Test data set for final prediction
odi_summary_test <- read.csv("ODI_summary_test.csv",stringsAsFactors = F)
#------------------------------------------------------------------------------------------------------------------------#
# *********************DATA UNDERSTANDING AND PREPARATION****************************************************************#
#------------------------------------------------------------------------------------------------------------------------#

str(odi_summary) #3005 obs. of  20 variables

length(unique(odi_summary$fid)) # 1522 unique

#We will format Date fields

odi_summary$Date <- as.Date(odi_summary$Date,"%d-%m-%y")

# We will predict Aus-India ODI matches for Male palyers 
# Hence we will first filter out our data set 

odi_summary_IND_AUS <- odi_summary %>% subset(Match.Type == 'ODI' & Gender == 'male' & (Team1 == 'India' | Team1 == "Australia") & (Team2 == 'India' | Team2 == "Australia"))

#There are few match city which are blank. Let compute them basedon match ground location
odi_summary_IND_AUS$Match.City[odi_summary_IND_AUS$Venue.Ground == "Sydney Cricket Ground"] <- 'Sydney'
odi_summary_IND_AUS$Match.City[odi_summary_IND_AUS$Venue.Ground == "Melbourne Cricket Ground"] <- 'Melbourne'
odi_summary_IND_AUS$Match.City[odi_summary_IND_AUS$Venue.Ground == "Adelaide Oval"] <- 'Adelaide'

#Let us  check unique citys
unique(odi_summary_IND_AUS$Match.City)

#There are total 22 cities where these matches were played.
#based on winning team in the match ad the city they played we will segregate the match as away or home.
#From the dataset, we observed that there are 2 cities, kula lumpur and centurion which are not home to either team.
#So will keep them away always

India.City <- c("Bangalore",
                "Vadodara" ,     
                "Ranchi",        
                "Hyderabad",
                "Kochi",         
                "Pune",          
                "Guwahati",      
                "Chandigarh",   
                "Visakhapatnam", 
                "Mumbai",
                "Delhi",
                "Nagpur", 
                "Jaipur",        
                "Ahmedabad")

Australia.City <- c("Adelaide",      
                    "Brisbane",      
                    "Melbourne",     
                    "Canberra",      
                    "Sydney",       
                    "Perth")

Other.City <- c("Kuala Lumpur", 
                "Centurion")

odi_summary_IND_AUS$Winners.Ground <- ifelse((odi_summary_IND_AUS$Winner=="India" & odi_summary_IND_AUS$Match.City %in% India.City),'Home',
                                             ifelse(odi_summary_IND_AUS$Winner=="Australia" & odi_summary_IND_AUS$Match.City %in% Australia.City,'Home','Away'))
#Let us check all venue grounds
levels(as.factor(odi_summary_IND_AUS$Venue.Ground))
#There are two  grounds with similar name : "Vidarbha Cricket Association Stadium, Jamtha" and "Vidarbha Cricket Association Ground"
#Let us correct them to Vidarbha Cricket Association Ground

odi_summary_IND_AUS$Venue.Ground[odi_summary_IND_AUS$Venue.Ground == "Vidarbha Cricket Association Stadium, Jamtha"] <- "Vidarbha Cricket Association Ground"


#There are few blank for Winner col .Hence mathches remain undecided or draw in those cases
sum(odi_summary_IND_AUS$Winner=='')

#Hence there are 10 records withblank winner column. Let us impute them as 'draw'
odi_summary_IND_AUS$Winner[odi_summary_IND_AUS$Winner==''] <- 'Draw'


#Replace all following  blanks with NA
odi_summary_IND_AUS$Venue.Ground[which(odi_summary_IND_AUS$Venue.Ground=='')] <- NA
odi_summary_IND_AUS$MoM[which(odi_summary_IND_AUS$MoM =='')] <- NA
odi_summary_IND_AUS$Toss.Decision[which(odi_summary_IND_AUS$Toss.Decision =='')] <- NA
odi_summary_IND_AUS$Toss.Winner[which(odi_summary_IND_AUS$Toss.Winner =='')] <- NA
odi_summary_IND_AUS$Innings[which(odi_summary_IND_AUS$Innings == '')] <- NA
odi_summary_IND_AUS$Batting.Team [which(odi_summary_IND_AUS$Batting.Team == '')] <- NA

#There are few redundant columns - Match.type, Gender,Overs.played=50 for all
#We will filter them out
odi_summary_IND_AUS <- odi_summary_IND_AUS[,!colnames(odi_summary_IND_AUS)  %in% c('Match.Type','Gender','Overs.Played','MoM')]

#Converting all the character variable into factor


str(odi_summary_IND_AUS)
#Lets factorise  all the character variables
all_char <- c('Match.City','Venue.Ground','Team1', 'Team2','Winner','Toss.Decision','Toss.Winner','Innings','Batting.Team','Winners.Ground')

odi_summary_IND_AUS[,all_char] <- lapply(odi_summary_IND_AUS[,all_char], as.factor)
#Let us look at the summary
summary(odi_summary_IND_AUS)

#Data now consist of records per innings for each match. We will convert the data into records per match 
odi_summary_IND_AUS_1st_inn <- subset(odi_summary_IND_AUS,odi_summary_IND_AUS$Innings == '1st innings')
odi_summary_IND_AUS_2nd_inn <- subset(odi_summary_IND_AUS,odi_summary_IND_AUS$Innings == '2nd innings')

colnames(odi_summary_IND_AUS_1st_inn)
first_inn <- colnames(odi_summary_IND_AUS_1st_inn)
first_inn_pre <- 'First_innings_'

first_inn_pre_colnames<-lapply(first_inn,function(x) str_glue({first_inn_pre},x))

first_inn_pre_colnames <- unlist(first_inn_pre_colnames,use.names = T)

colnames(odi_summary_IND_AUS_1st_inn) <- c(first_inn_pre_colnames)

##

second_inn <- colnames(odi_summary_IND_AUS_2nd_inn)
second_inn_pre <- 'Second_innings_'

second_inn_pre_colnames<-lapply(second_inn,function(x) str_glue({second_inn_pre},x))

second_inn_pre_colnames <- unlist(second_inn_pre_colnames,use.names = T)

colnames(odi_summary_IND_AUS_2nd_inn) <- c(second_inn_pre_colnames)



#now we will column bind both table

odi_summary_IND_AUS_all_inn <- merge(odi_summary_IND_AUS_1st_inn,odi_summary_IND_AUS_2nd_inn,by.x='First_innings_fid',by.y='Second_innings_fid',all = T)
colnames(odi_summary_IND_AUS_all_inn)

#There are few redundaant columns.We will remove them
redundant_col <- c("First_innings_Innings","Second_innings_Match.City","Second_innings_Venue.Ground","Second_innings_Date",          
"Second_innings_Team1","Second_innings_Team2","Second_innings_Winner","Second_innings_Toss.Decision","Second_innings_Toss.Winner","Second_innings_Innings",
"Second_innings_Winners.Ground")

odi_summary_IND_AUS_all_inn <- odi_summary_IND_AUS_all_inn[,!colnames(odi_summary_IND_AUS_all_inn) %in% redundant_col ]

#Few colnames are misleading,hence we will change them.
common_col <- c("fid","Match.City","Venue.Ground","Date", "Team1","Team2",         
                "Winner","Toss.Decision","Toss.Winner")


colnames(odi_summary_IND_AUS_all_inn) <- c(common_col,"First_innings_Batting.Team",   
                                           "First_innings_Total.Runs",    
                                           "First_innings_Total.6s", 
                                           "First_innings_Total.4s",      
                                           "First_innings_Total.Wickets", 
                                           "First_innings_Total.Balls",
                                           "Winners.Ground",
                                           "Second_innings_Batting.Team",
                                           "Second_innings_Total.Runs",
                                           "Second_innings_Total.6s",
                                           "Second_innings_Total.4s",
                                           "Second_innings_Total.Wickets",
                                           "Second_innings_Total.Balls")

length(odi_summary_IND_AUS_all_inn$fid)
#total 49 matches were played

max(year(odi_summary_IND_AUS_all_inn$Date)) #We have data till 2018
min(year(odi_summary_IND_AUS_all_inn$Date)) #Wehave data from 2006

sum(odi_summary_IND_AUS_all_inn$Winner=="India") # 20 times India won
sum(odi_summary_IND_AUS_all_inn$Winner=="Australia") #25 times Australia won


# Exploratory Data Analysis ########################################################################################

str(odi_summary_IND_AUS_all_inn)

# Barchart for categorical variables.
cat_bar<- theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5), 
                legend.position = 'right')


plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(Match.City,fill=as.factor(Winner)))+geom_bar(position='dodge')+labs(title = 'Match.City wise Analysis', y = "Match Count", x = "Match City")+cat_bar,
          ggplot(odi_summary_IND_AUS_all_inn, aes(Toss.Decision,fill=as.factor(Winner)))+geom_bar(position='dodge')+labs(title = 'Toss.Decision wise Analysis', y = "Match Count", x = "Toss.Decision")+cat_bar)

# Analysis shows that Australia got highest number of wins at ODI match when played at Sydney
# whereas India got highest number of wins at ODI match when played at Nagpur
# Both the countries got their highest winning when they decided to bat first in the Toss Decision.

plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(Toss.Winner,fill=as.factor(Winner)))+geom_bar(position='dodge')+labs(title = 'Toss Winner wise Analysis', y = "Match Count", x = "Toss Winner")+cat_bar,
          ggplot(odi_summary_IND_AUS_all_inn, aes(First_innings_Batting.Team,fill=as.factor(Winner)))+geom_bar(position='dodge')+labs(title = 'First_innings_Batting.Team wise Analysis', y = "Match Count", x = "First_innings_Batting.Team")+cat_bar,
          ggplot(odi_summary_IND_AUS_all_inn, aes(Winners.Ground,fill=as.factor(Winner)))+geom_bar(position='dodge')+labs(title = "Winner ground wise Analysis", y = "Match Count", x = "Winners Ground")+cat_bar)      


#Australia has higher tendency to win the match when it wins the Toss compared to India.
#Playing at Home ground or Away does not have much effect on the Winning
#Australia has highest winnings when it has batted in the first innings.

plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(Venue.Ground,fill=as.factor(Winner)))+geom_bar(position='dodge')+labs(title = 'Venue.Ground wise Analysis', y = "Match Count", x = "Venue.Ground")+cat_bar,
          ggplot(odi_summary_IND_AUS_all_inn, aes(Second_innings_Batting.Team,fill=as.factor(Winner)))+geom_bar(position='dodge')+labs(title = 'Second_innings_Batting.Team wise Analysis', y = "Match Count", x = "Second_innings_Batting.Team")+cat_bar)

#Australia has low winning count when it batted on second innings.But compared to first innings,India has got better winning count when it batted on second innings.
#India has highest winning against Australia at Vidarbha Cricket Association ground and Australia has highest winning against India at Sydney Cricket ground.

summary(odi_summary_IND_AUS_all_inn)
#There are 2 NA values for 2nd Innings data , probably the match didn't end due to some circumstances.
#Let us check those records
odi_summary_IND_AUS_all_inn[is.na(odi_summary_IND_AUS_all_inn$Second_innings_Total.Runs),]


#Now both these records having NA in Second_innings_Total.Runs fields are Draw matches.Hence we will remove these 2 records
odi_summary_IND_AUS_all_inn <- na.omit(odi_summary_IND_AUS_all_inn)

#We have total runs per inning and total balls played per innings.Let us calculate run rate per ball playedper innings 
#First Innings
odi_summary_IND_AUS_all_inn <- odi_summary_IND_AUS_all_inn %>% mutate(First_innings_RunRate_perball = First_innings_Total.Runs/First_innings_Total.Balls)
#Second Innings
odi_summary_IND_AUS_all_inn <- odi_summary_IND_AUS_all_inn %>% mutate(Second_innings_RunRate_perball = Second_innings_Total.Runs/Second_innings_Total.Balls)

#Let us visualize and analyse for continuous variables

num_box <- theme(axis.line=element_blank(),axis.title=element_blank(), 
                 axis.ticks=element_blank(), axis.text=element_blank())

plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(First_innings_Total.Runs,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=First_innings_Total.Runs))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)
#Australia overall has highest average Runs in First innings against India, though it has lowest runs as well
plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(First_innings_Total.6s,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=First_innings_Total.6s))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)
#India has lowest average of number sixers in first innings, though it has a highest number of sixer against Australia. 
plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(First_innings_Total.4s,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=First_innings_Total.4s))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)
#India has highest as lowest numbers of 4's against Australia in a match.
plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(First_innings_Total.Wickets,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=First_innings_Total.Wickets))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)
#Australia has highest average wickets on first innings against India
plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(First_innings_Total.Balls,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=First_innings_Total.Balls))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)

plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(First_innings_RunRate_perball,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=First_innings_RunRate_perball))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)
#First Innings Average Runrate is slight high for Australia against india.
plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(Second_innings_Total.Runs,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=Second_innings_Total.Runs))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)

plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(Second_innings_Total.6s,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=Second_innings_Total.6s))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)
#India has highest sixers in second innings against Australia.

plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(Second_innings_Total.4s,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=Second_innings_Total.4s))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)

plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(Second_innings_Total.Wickets,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=Second_innings_Total.Wickets))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)
#Australia lost highest agerage number of Wickets on second innings against India.

plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(Second_innings_Total.Balls,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=Second_innings_Total.Balls))+ geom_boxplot(width=0.1), 
          align = "h",ncol = 1)

plot_grid(ggplot(odi_summary_IND_AUS_all_inn, aes(Second_innings_RunRate_perball,fill=as.factor(Winner)))+ geom_bar(),
          ggplot(odi_summary_IND_AUS_all_inn, aes(x=Winner,y=Second_innings_RunRate_perball))+ geom_boxplot(width=0.1)+num_box, 
          align = "h",ncol = 1)

#Analysis per match date
ggplot(odi_summary_IND_AUS_all_inn,aes(x=factor(Winner),fill='green')) + geom_bar() + facet_wrap(~Date) + labs(x="Match Winner", y="Number of Match", title = "India Australia Match Outcome")


##
### Correlation between numeric variables
str(odi_summary_IND_AUS_all_inn)

corr_odi_data <- cor(odi_summary_IND_AUS_all_inn[,c("First_innings_Total.Runs","First_innings_Total.6s","First_innings_Total.4s",
                                                    "First_innings_Total.Wickets","First_innings_Total.Balls","Second_innings_Total.Runs",
                                                    "Second_innings_Total.6s","Second_innings_Total.4s","Second_innings_Total.Wickets",
                                                    "Second_innings_Total.Balls","First_innings_RunRate_perball","Second_innings_RunRate_perball")])
summary(odi_summary_IND_AUS_all_inn)


# We convert target variable - Attrition from char to factorwith levels 0/1 
odi_summary_IND_AUS_all_inn$Winner <- ifelse(odi_summary_IND_AUS_all_inn$Winner =="India",1,0)

# We will create dummy variables from factor variables having 2 or more number of levels
str(odi_summary_IND_AUS_all_inn)

odi_summary_IND_AUS_all_inn <- odi_summary_IND_AUS_all_inn[,-1]
#Since MOM is decided after match result, we assume theat MOM will not affect match result
#Also, in our case team1 and team2 will always be India and Australia. Hence we will remove them
odi_summary_IND_AUS_all_inn_fact <- odi_summary_IND_AUS_all_inn[,colnames(odi_summary_IND_AUS_all_inn) %in% c("Venue.Ground","Toss.Decision","Toss.Winner","First_innings_Batting.Team","Winners.Ground","Second_innings_Batting.Team")]


dummy_var <- data.frame(sapply(odi_summary_IND_AUS_all_inn_fact, 
                               function(x) data.frame(model.matrix(~x-1,data =odi_summary_IND_AUS_all_inn_fact))[,-1]))

# combining dummy_var with rest of the numerical variables

odi_summary_IND_AUS_all_inn_allvar <- cbind(odi_summary_IND_AUS_all_inn[,c("Winner","Date","First_innings_Total.Runs",    
                                                                           "First_innings_Total.6s", 
                                                                           "First_innings_Total.4s",      
                                                                           "First_innings_Total.Wickets", 
                                                                           "First_innings_Total.Balls",
                                                                           "Second_innings_Total.Runs",
                                                                           "Second_innings_Total.6s",
                                                                           "Second_innings_Total.4s",
                                                                           "Second_innings_Total.Wickets",
                                                                           "Second_innings_Total.Balls",
                                                                           "First_innings_RunRate_perball",
                                                                           "Second_innings_RunRate_perball")],dummy_var)

sapply(odi_summary_IND_AUS_all_inn_allvar[,-2],function(x) sum(x))

#Hence some colums with zero values are present in the dataframe.Let us remove them

odi_summary_IND_AUS_all_inn_allvar <- odi_summary_IND_AUS_all_inn_allvar[,which(colSums(odi_summary_IND_AUS_all_inn_allvar[,-2])!=0)]

##-----------------End of Data Preparation-----------------------------------------------------------------------------------##
#----------------------------------------------------------------------------------------------------------------------------##
# PREPARE TRAINING AND TEST DATA
#----------------------------------------------------------------------------------------------------------------------------##
# We split the data between train_data and test_data
set.seed(100)

indices_attrn = sample.split(odi_summary_IND_AUS_all_inn_allvar , SplitRatio = 0.7)

train_data = odi_summary_IND_AUS_all_inn_allvar[indices_attrn,]

test_data = odi_summary_IND_AUS_all_inn_allvar[!(indices_attrn),]

#----------------------------------------------------------------------------------------------------------------------------##
# BUILD LOGISTIC REGRESSION MODEL
#----------------------------------------------------------------------------------------------------------------------------##
# Base model for logistic regression

model_1_odi = glm(Winner~.,data = train_data,family = 'binomial')
summary(model_1_odi)


model_2_odi = stepAIC(model_1_odi,direction = 'both')
summary(model_2_odi)

vif(model_2_odi)

#Removed Venue.Ground.xSardar.Patel.Stadium..Motera 
model_3_odi = glm(Winner ~ Date + First_innings_Total.6s + Second_innings_Total.Runs + 
                    Second_innings_Total.6s + Venue.Ground.xMA.Chidambaram.Stadium..Chepauk + 
                    Venue.Ground.xPunjab.Cricket.Association.Stadium..Mohali + 
                    Venue.Ground.xReliance.Stadium +  
                    Venue.Ground.xVidarbha.Cricket.Association.Ground,data = train_data,family = 'binomial')

summary(model_3_odi)
vif(model_3_odi)

#Venue.Ground.xPunjab.Cricket.Association.Stadium..Mohali has high  p value >>0.05

model_4_odi = glm(Winner ~ Date + First_innings_Total.6s + Second_innings_Total.Runs + 
                    Second_innings_Total.6s + Venue.Ground.xMA.Chidambaram.Stadium..Chepauk + 
                    Venue.Ground.xReliance.Stadium +  
                    Venue.Ground.xVidarbha.Cricket.Association.Ground,data = train_data,family = 'binomial')

summary(model_4_odi)
vif(model_4_odi)

#Venue.Ground.xMA.Chidambaram.Stadium..Chepauk has p val >> 0.05

model_5_odi = glm(Winner ~ Date + First_innings_Total.6s + Second_innings_Total.Runs + 
                    Second_innings_Total.6s + 
                    Venue.Ground.xReliance.Stadium +  
                    Venue.Ground.xVidarbha.Cricket.Association.Ground,data = train_data,family = 'binomial')

summary(model_5_odi)
vif(model_5_odi)
#removing VVenue.Ground.xReliance.Stadium  asit has pval>>0.05

model_6_odi = glm(Winner ~  Date + First_innings_Total.6s + Second_innings_Total.Runs + 
                    Second_innings_Total.6s + 
                    Venue.Ground.xVidarbha.Cricket.Association.Ground,data = train_data,family = 'binomial')

summary(model_6_odi)
vif(model_6_odi)


#removing Venue.Ground.xVidarbha.Cricket.Association.Ground

model_7_odi = glm(Winner ~ Date + First_innings_Total.6s + Second_innings_Total.Runs + 
                    Second_innings_Total.6s,
                    data = train_data,family = 'binomial')

summary(model_7_odi)
vif(model_7_odi)

#Removing Date as it has high  p value

model_8_odi = glm(Winner ~ First_innings_Total.6s + Second_innings_Total.Runs + 
                    Second_innings_Total.6s,data = train_data,family = 'binomial')


summary(model_8_odi)
vif(model_8_odi)

model_9_odi = glm(Winner ~ Second_innings_Total.Runs + 
                    Second_innings_Total.6s,data = train_data,family = 'binomial')


summary(model_9_odi)
vif(model_9_odi)

model_10_odi = glm(Winner ~ Second_innings_Total.Runs, 
                    data = train_data,family = 'binomial')


summary(model_10_odi)
#Hence Second_innings_Total.Runs is  only the predictor variable.
#----------------------------------------------------------------------------------------------------------------------------##
# MODEL TESTING AND VALIDATION
#----------------------------------------------------------------------------------------------------------------------------##

#Prediction of Employee attrition on test data set
#odi_summary_IND_AUS_all_inn_allvar
odi_summary_IND_AUS_prediction <- predict(model_10_odi, type = "response", newdata = test_data[,-1])

#Summary of prediction:
summary(odi_summary_IND_AUS_prediction)


#We merge predicted value to test_data set
test_data$Predicted_probality <- odi_summary_IND_AUS_prediction


#We need to find  out optimal cutoff points. Following function  will calculate  the optimal cutoff.
Actual_odi_summary_IND_AUS <- factor(ifelse(test_data$Winner==1,"India","Australia"))
Find_cut_off_optimal <- function(cutoff_value) 
{
  predicted_odi_summary_IND_AUS <- factor(ifelse(odi_summary_IND_AUS_prediction >= cutoff_value, "India", "Australia"))
  odi_summary_IND_AUS_confusion_matrix <- confusionMatrix(predicted_odi_summary_IND_AUS, Actual_odi_summary_IND_AUS, positive = "India")
  
  odi_summary_IND_AUS_sensitivity <- odi_summary_IND_AUS_confusion_matrix$byClass[1]
  odi_summary_IND_AUS_specificity <- odi_summary_IND_AUS_confusion_matrix$byClass[2]
  odi_summary_IND_AUS_accuracy <- odi_summary_IND_AUS_confusion_matrix$overall[1]
  
  odi_summary_IND_AUS_output <- t(as.matrix(c(odi_summary_IND_AUS_sensitivity, odi_summary_IND_AUS_specificity, odi_summary_IND_AUS_accuracy))) 
  colnames(odi_summary_IND_AUS_output) <- c("sensitivity", "specificity", "accuracy")
  return(odi_summary_IND_AUS_output)
}


#Now  we will run this  function for a  sequence of  cutoff to  plot sigmoid  curve.
##Not working!!
seq_initiation = seq(.01,.80,length=100)
out_dataset = matrix(0,100,3)

for(index_num in 1:100)
{
  out_dataset[index_num,] = Find_cut_off_optimal(seq_initiation[index_num])
} 

plot(seq_initiation, out_dataset[,1],xlab="Cutoff",ylab="Value",cex.lab=1.5,cex.axis=1.5,ylim=c(0,1),type="l",lwd=2,axes=FALSE,col=2)
axis(1,seq(0,1,length=5),seq(0,1,length=5),cex.lab=1.5)
axis(2,seq(0,1,length=5),seq(0,1,length=5),cex.lab=1.5)
lines(seq_initiation,out_dataset[,2],col="darkgreen",lwd=2)
lines(seq_initiation,out_dataset[,3],col=4,lwd=2)
box()
legend(-0.1,.001,col=c(2,"yellow",4,"darkred"),lwd=c(2,2,2,2),c("Sensitivity","Specificity","Accuracy"))

#cutoff_prob_value <- seq_initiation[which(abs(out_dataset[,1]-out_dataset[,2]) < 0.09)][1]
cutoff_prob_value <- seq_initiation[which(abs(out_dataset[,1]-out_dataset[,2]) < 0.8)][1]
cutoff_prob_value #0.3770707

#So we choose cut off as 0.3770707 in the model
odi_summary_IND_AUS_final_prediction <- factor(ifelse(odi_summary_IND_AUS_prediction >=0.3770707, "India", "Australia"))
#Now  we need to check conf
test_data_confusionmatrix <- confusionMatrix(odi_summary_IND_AUS_final_prediction, Actual_odi_summary_IND_AUS, positive = "India")
#Sensitivity : 1.0000          
#Specificity : 0.2727         
#Pos Pred Value : 0.2727          
#Neg Pred Value :  1.0000          
#Prevalence : 0.2143          
#Detection Rate : 0.2143          
#Detection Prevalence : 0.7857          
#Balanced Accuracy : 0.6364

##---Calculation of KS  statistics  for the test dataset --------------------------------------------------------------------##

odi_summary_IND_AUS_prediction <- ifelse(odi_summary_IND_AUS_final_prediction=="India",1,0)
Actual_odi_IND_AUS <- ifelse(Actual_odi_summary_IND_AUS=="India",1,0)

#We run prediction on emp_test_data_attrition_prediction and Actual_emp_attrition
pred_odi_IND_AUS_test <- prediction(odi_summary_IND_AUS_prediction, Actual_odi_IND_AUS)

#Performance of the model
odi_IND_AUS_performance_measures_test<- performance(pred_odi_IND_AUS_test, "tpr", "fpr")

ks_table_odi_IND_AUS_test <- attr(odi_IND_AUS_performance_measures_test, "y.values")[[1]] - 
  (attr(odi_IND_AUS_performance_measures_test, "x.values")[[1]])

# Here we check the maximum KS  stat value
max(ks_table_odi_IND_AUS_test) #KS Stat - > 0.2727273


test_data$Predicted_Winner <- odi_summary_IND_AUS_final_prediction
#   
#------------------------------------------------------------------------------------------------------------------------------------------
write.csv(odi_summary_IND_AUS_all_inn,"odi_summary_IND_AUS_all_inn.csv")
############################################################################################################################################

#Let us analysis using Time series:

#Using Auto arima model we will forecast the following:
#First_innings_Total.Runs
#First_innings_Total.6s
#First_innings_Total.4s
#First_innings_Total.Wickets
#First_innings_Total.Balls

#Second_innings_Total.Runs
#Second_innings_Total.6s
#Second_innings_Total.4s
#Second_innings_Total.Wickets
#Second_innings_Total.Balls


#Let us analysis using Time series

#a.We will take subset of odi_summary_IND_AUS_all_inn to forecast First_innings_Total.Runs
odi_summary_IND_AUS_firstinn_tot.run <- odi_summary_IND_AUS_all_inn[,c('Date', 'First_innings_Total.Runs')]
odi_summary_IND_AUS_firstinn_tot.run <- arrange(odi_summary_IND_AUS_firstinn_tot.run,Date)

#We will split last 3 data for accuracy test from the base data set
odi_summary_IND_AUS_firstinn_tot.run_in <- odi_summary_IND_AUS_firstinn_tot.run[1:42,]
odi_summary_IND_AUS_firstinn_tot.run_valid <- odi_summary_IND_AUS_firstinn_tot.run[43:45,]

# Create time series for odi_summary_IND_AUS_firstinn_tot.run

timeseries_odi_summary_IND_AUS_firstinn_tot.run <- ts(odi_summary_IND_AUS_firstinn_tot.run_in$First_innings_Total.Runs)

#plot the time series
plot(timeseries_odi_summary_IND_AUS_firstinn_tot.run)

#We will compute auto arima

odi_summary_IND_AUS_firstinn_tot.run_arima <- auto.arima(timeseries_odi_summary_IND_AUS_firstinn_tot.run)

tsdiag(odi_summary_IND_AUS_firstinn_tot.run_arima)
plot(odi_summary_IND_AUS_firstinn_tot.run_arima$x)
lines(fitted(odi_summary_IND_AUS_firstinn_tot.run_arima), col="blue")

#We will compute residual series to test white noise
odi_summary_IND_AUS_firstinn_tot.run_residual <- timeseries_odi_summary_IND_AUS_firstinn_tot.run -fitted(odi_summary_IND_AUS_firstinn_tot.run_arima)

#Dickey-Fuller test 
adf.test(odi_summary_IND_AUS_firstinn_tot.run_residual,alternative = "stationary")
#Result: -2.9375, Lag order = 3, p-value = 0.2041
#Since p-value > 0.05 ,null hypothesis is failed to be rejected.That implies the residual series is not stationary.

#KPSS test  
kpss.test(odi_summary_IND_AUS_firstinn_tot.run_residual)
#Result: KPSS Level =  0.065831, Truncation lag parameter = 1, p-value = 0.1
#

#--------------Model evaluation with AUTO ARIMA --------------------------------------------------------------------------#

odi_summary_IND_AUS_firstinn_tot.pred <- predict(odi_summary_IND_AUS_firstinn_tot.run_arima,n.ahead = 8)

#MAPE value fr the forecasting
odi_summary_IND_AUS_firstinn_tot.run_arima_MAPE <-accuracy(odi_summary_IND_AUS_firstinn_tot.pred$pred, odi_summary_IND_AUS_firstinn_tot.run_valid[,2])[5]
#6.466537

#-------------------

#b.We will take subset of odi_summary_IND_AUS_all_inn to forecast First_innings_Total.6s
odi_summary_IND_AUS_firstinn_tot6s <- odi_summary_IND_AUS_all_inn[,c('Date', 'First_innings_Total.6s')]
odi_summary_IND_AUS_firstinn_tot6s <- arrange(odi_summary_IND_AUS_firstinn_tot6s,Date)

#We will split last 3 data for accuracy test from the base data set
odi_summary_IND_AUS_firstinn_tot6s_in <- odi_summary_IND_AUS_firstinn_tot6s[1:42,]
odi_summary_IND_AUS_firstinn_tot6s_valid <- odi_summary_IND_AUS_firstinn_tot6s[43:45,]

# Create time series for odi_summary_IND_AUS_firstinn_tot6s.run

timeseries_odi_summary_IND_AUS_firstinn_tot6s <- ts(odi_summary_IND_AUS_firstinn_tot6s_in$First_innings_Total.6s)

#plot the time series
plot(timeseries_odi_summary_IND_AUS_firstinn_tot6s)

#We will compute auto arima

odi_summary_IND_AUS_firstinn_tot6s_arima <- auto.arima(timeseries_odi_summary_IND_AUS_firstinn_tot6s)

tsdiag(odi_summary_IND_AUS_firstinn_tot6s_arima)
plot(odi_summary_IND_AUS_firstinn_tot6s_arima$x)
lines(fitted(odi_summary_IND_AUS_firstinn_tot6s_arima), col="blue")

#We will compute residual series to test white noise
odi_summary_IND_AUS_firstinn_tot6s_residual <- timeseries_odi_summary_IND_AUS_firstinn_tot6s -fitted(odi_summary_IND_AUS_firstinn_tot6s_arima)

#Dickey-Fuller test 
adf.test(odi_summary_IND_AUS_firstinn_tot6s_residual,alternative = "stationary")
#Result: -3.2258, Lag order = 3, p-value = 0.09638
#Since p-value > 0.05 ,null hypothesis is failed to be rejected.That implies the residual series is not stationary.

#KPSS test  
kpss.test(odi_summary_IND_AUS_firstinn_tot6s_residual)
#Result: KPSS Level =  0.050393, Truncation lag parameter = 1, p-value = 0.1
#

#--------------Model evaluation with AUTO ARIMA --------------------------------------------------------------------------#

odi_summary_IND_AUS_firstinn_tot6s.pred <- predict(odi_summary_IND_AUS_firstinn_tot6s_arima,n.ahead = 8)

#MAPE value fr the forecasting
odi_summary_IND_AUS_firstinn_tot6s.run_arima_MAPE <-accuracy(odi_summary_IND_AUS_firstinn_tot6s.pred$pred, odi_summary_IND_AUS_firstinn_tot6s_valid[1:2,2])[5]
#66.85441

############################################################################################3

#c.We will take subset of odi_summary_IND_AUS_all_inn to forecast First_innings_Total.4s
odi_summary_IND_AUS_firstinn_tot4s <- odi_summary_IND_AUS_all_inn[,c('Date', 'First_innings_Total.4s')]
odi_summary_IND_AUS_firstinn_tot4s <- arrange(odi_summary_IND_AUS_firstinn_tot4s,Date)

#We will split last 3 data for accuracy test from the base data set
odi_summary_IND_AUS_firstinn_tot4s_in <- odi_summary_IND_AUS_firstinn_tot4s[1:42,]
odi_summary_IND_AUS_firstinn_tot4s_valid <- odi_summary_IND_AUS_firstinn_tot4s[43:45,]

# Create time series for First_innings_Total.4s.run

timeseries_odi_summary_IND_AUS_firstinn_tot4s <- ts(odi_summary_IND_AUS_firstinn_tot4s_in$First_innings_Total.4s)

#plot the time series
plot(timeseries_odi_summary_IND_AUS_firstinn_tot4s)

#We will compute auto arima

odi_summary_IND_AUS_firstinn_tot4s_arima <- auto.arima(timeseries_odi_summary_IND_AUS_firstinn_tot4s)

tsdiag(odi_summary_IND_AUS_firstinn_tot4s_arima)
plot(odi_summary_IND_AUS_firstinn_tot4s_arima$x)
lines(fitted(odi_summary_IND_AUS_firstinn_tot4s_arima), col="blue")

#We will compute residual series to test white noise
odi_summary_IND_AUS_firstinn_tot4s_residual <- timeseries_odi_summary_IND_AUS_firstinn_tot4s -fitted(odi_summary_IND_AUS_firstinn_tot4s_arima)

#Dickey-Fuller test 
adf.test(odi_summary_IND_AUS_firstinn_tot4s_residual,alternative = "stationary")
#Result: -2.5324, Lag order = 3, p-value = 0.3638
#Since p-value > 0.05 ,null hypothesis is failed to be rejected.That implies the residual series is not stationary.

#KPSS test  
kpss.test(odi_summary_IND_AUS_firstinn_tot4s_residual)
#Result: KPSS Level =  0.23606, Truncation lag parameter = 1, p-value = 0.1
#

#--------------Model evaluation with AUTO ARIMA --------------------------------------------------------------------------#

odi_summary_IND_AUS_firstinn_tot4s.pred <- predict(odi_summary_IND_AUS_firstinn_tot4s_arima,n.ahead = 8)

#MAPE value fr the forecasting
odi_summary_IND_AUS_firstinn_tot4s.run_arima_MAPE <-accuracy(odi_summary_IND_AUS_firstinn_tot4s.pred$pred, odi_summary_IND_AUS_firstinn_tot4s_valid[,2])[5]
#20.04326

#################################################################################################################################################


#d.We will take subset of odi_summary_IND_AUS_all_inn to forecast First_innings_Total.Wickets
odi_summary_IND_AUS_firstinn_Total.Wickets <- odi_summary_IND_AUS_all_inn[,c('Date', 'First_innings_Total.Wickets')]
odi_summary_IND_AUS_firstinn_Total.Wickets <- arrange(odi_summary_IND_AUS_firstinn_Total.Wickets,Date)

#We will split last 3 data for accuracy test from the base data set
odi_summary_IND_AUS_firstinn_Total.Wickets_in <- odi_summary_IND_AUS_firstinn_Total.Wickets[1:42,]
odi_summary_IND_AUS_firstinn_Total.Wickets_valid <- odi_summary_IND_AUS_firstinn_Total.Wickets[43:45,]

# Create time series for First_innings_Total.Wickets

timeseries_odi_summary_IND_AUS_firstinn_Total.Wickets <- ts(odi_summary_IND_AUS_firstinn_Total.Wickets_in$First_innings_Total.Wickets)

#plot the time series
plot(timeseries_odi_summary_IND_AUS_firstinn_Total.Wickets)

#We will compute auto arima

odi_summary_IND_AUS_firstinn_Total.Wickets_arima <- auto.arima(timeseries_odi_summary_IND_AUS_firstinn_Total.Wickets)

tsdiag(odi_summary_IND_AUS_firstinn_Total.Wickets_arima)
plot(odi_summary_IND_AUS_firstinn_Total.Wickets_arima$x)
lines(fitted(odi_summary_IND_AUS_firstinn_Total.Wickets_arima), col="blue")

#We will compute residual series to test white noise
odi_summary_IND_AUS_firstinn_Total.Wickets_residual <- timeseries_odi_summary_IND_AUS_firstinn_Total.Wickets -fitted(odi_summary_IND_AUS_firstinn_Total.Wickets_arima)

#Dickey-Fuller test 
adf.test(odi_summary_IND_AUS_firstinn_Total.Wickets_residual,alternative = "stationary")
#Result: -2.9131, Lag order = 3, p-value = 0.2137
#Since p-value > 0.05 ,null hypothesis is failed to be rejected.That implies the residual series is not stationary.

#KPSS test  
kpss.test(odi_summary_IND_AUS_firstinn_Total.Wickets_residual)
#Result: KPSS Level =  = 0.38853, Truncation lag parameter = 1, p-value = 0.0821
#

#--------------Model evaluation with AUTO ARIMA --------------------------------------------------------------------------#

odi_summary_IND_AUS_firstinn_Total.Wickets.pred <- predict(odi_summary_IND_AUS_firstinn_Total.Wickets_arima,n.ahead = 8)

#MAPE value fr the forecasting
odi_summary_IND_AUS_firstinn_Total.Wickets.run_arima_MAPE <-accuracy(odi_summary_IND_AUS_firstinn_Total.Wickets.pred$pred, odi_summary_IND_AUS_firstinn_Total.Wickets_valid[,2])[5]
#27.48754

###############################################################################################################################################################


#e.We will take subset of odi_summary_IND_AUS_all_inn to forecast First_innings_Total.Balls
odi_summary_IND_AUS_firstinn_Total.Balls <- odi_summary_IND_AUS_all_inn[,c('Date', 'First_innings_Total.Balls')]
odi_summary_IND_AUS_firstinn_Total.Balls <- arrange(odi_summary_IND_AUS_firstinn_Total.Balls,Date)

#We will split last 3 data for accuracy test from the base data set
odi_summary_IND_AUS_firstinn_Total.Balls_in <- odi_summary_IND_AUS_firstinn_Total.Balls[1:42,]
odi_summary_IND_AUS_firstinn_Total.Balls_valid <- odi_summary_IND_AUS_firstinn_Total.Balls[43:45,]

# Create time series for First_innings_Total.4s.run

timeseries_odi_summary_IND_AUS_firstinn_Total.Balls <- ts(odi_summary_IND_AUS_firstinn_Total.Balls_in$First_innings_Total.Balls)

#plot the time series
plot(timeseries_odi_summary_IND_AUS_firstinn_Total.Balls)

#We will compute auto arima

odi_summary_IND_AUS_firstinn_Total.Balls_arima <- auto.arima(timeseries_odi_summary_IND_AUS_firstinn_Total.Balls)

tsdiag(odi_summary_IND_AUS_firstinn_Total.Balls_arima)
plot(odi_summary_IND_AUS_firstinn_Total.Balls_arima$x)
lines(fitted(odi_summary_IND_AUS_firstinn_Total.Balls_arima), col="blue")

#We will compute residual series to test white noise
odi_summary_IND_AUS_firstinn_Total.Balls_residual <- timeseries_odi_summary_IND_AUS_firstinn_Total.Balls -fitted(odi_summary_IND_AUS_firstinn_Total.Balls_arima)

#Dickey-Fuller test 
adf.test(odi_summary_IND_AUS_firstinn_Total.Balls_residual,alternative = "stationary")
#Result: -3.2944, Lag order = 3, p-value = 0.08612
#Since p-value > 0.05 ,null hypothesis is failed to be rejected.That implies the residual series is not stationary.

#KPSS test  
kpss.test(odi_summary_IND_AUS_firstinn_Total.Balls_residual)
#Result: KPSS Level =  0.10384, Truncation lag parameter = 1, p-value = 0.1
#

#--------------Model evaluation with AUTO ARIMA --------------------------------------------------------------------------#

odi_summary_IND_AUS_firstinn_Total.Balls.pred <- predict(odi_summary_IND_AUS_firstinn_Total.Balls_arima,n.ahead = 8)

#MAPE value fr the forecasting
odi_summary_IND_AUS_firstinn_Total.Balls.run_arima_MAPE <-accuracy(odi_summary_IND_AUS_firstinn_Total.Balls.pred$pred, odi_summary_IND_AUS_firstinn_Total.Balls_valid[,2])[5]
#1.142199

###################################################################################################################################################################################

#f.We will take subset of odi_summary_IND_AUS_all_inn to forecast Second_innings_Total.Runs
odi_summary_IND_AUS_secondinn_Total.Runs <- odi_summary_IND_AUS_all_inn[,c('Date', 'Second_innings_Total.Runs')]
odi_summary_IND_AUS_secondinn_Total.Runs <- arrange(odi_summary_IND_AUS_secondinn_Total.Runs,Date)

#We will split last 3 data for accuracy test from the base data set
odi_summary_IND_AUS_secondinn_Total.Runs_in <- odi_summary_IND_AUS_secondinn_Total.Runs[1:42,]
odi_summary_IND_AUS_secondinn_Total.Runs_valid <- odi_summary_IND_AUS_secondinn_Total.Runs[43:45,]

# Create time series for Second_innings_Total.Runs

timeseries_odi_summary_IND_AUS_secondinn_Total.Runs <- ts(odi_summary_IND_AUS_secondinn_Total.Runs_in$Second_innings_Total.Runs)

#plot the time series
plot(timeseries_odi_summary_IND_AUS_secondinn_Total.Runs)

#We will compute auto arima

odi_summary_IND_AUS_secondinn_Total.Runs_arima <- auto.arima(timeseries_odi_summary_IND_AUS_secondinn_Total.Runs)

tsdiag(odi_summary_IND_AUS_secondinn_Total.Runs_arima)
plot(odi_summary_IND_AUS_secondinn_Total.Runs_arima$x)
lines(fitted(odi_summary_IND_AUS_secondinn_Total.Runs_arima), col="blue")

#We will compute residual series to test white noise
odi_summary_IND_AUS_secondinn_Total.Runs_residual <- timeseries_odi_summary_IND_AUS_secondinn_Total.Runs -fitted(odi_summary_IND_AUS_secondinn_Total.Runs_arima)

#Dickey-Fuller test 
adf.test(odi_summary_IND_AUS_secondinn_Total.Runs_residual,alternative = "stationary")
#Result: -3.1777, Lag order = 3, p-value = 0.1094
#Since p-value > 0.05 ,null hypothesis is failed to be rejected.That implies the residual series is not stationary.

#KPSS test  
kpss.test(odi_summary_IND_AUS_secondinn_Total.Runs_residual)
#Result: KPSS Level =  0.4415, Truncation lag parameter = 1, p-value = 0.05927
#

#--------------Model evaluation with AUTO ARIMA --------------------------------------------------------------------------#

odi_summary_IND_AUS_secondinn_Total.Runs.pred <- predict(odi_summary_IND_AUS_secondinn_Total.Runs_arima,n.ahead = 8)

#MAPE value fr the forecasting
odi_summary_IND_AUS_secondinn_Total.Runs.run_arima_MAPE <-accuracy(odi_summary_IND_AUS_secondinn_Total.Runs.pred$pred, odi_summary_IND_AUS_secondinn_Total.Runs_valid[,2])[5]
#8.001801


##############################################################################################################################################################

#g.We will take subset of odi_summary_IND_AUS_all_inn to forecast Second_innings_Total.6s
odi_summary_IND_AUS_secondinn_Total6s <- odi_summary_IND_AUS_all_inn[,c('Date', 'Second_innings_Total.6s')]
odi_summary_IND_AUS_secondinn_Total6s <- arrange(odi_summary_IND_AUS_secondinn_Total6s,Date)

#We will split last 3 data for accuracy test from the base data set
odi_summary_IND_AUS_secondinn_Total6s_in <- odi_summary_IND_AUS_secondinn_Total6s[1:42,]
odi_summary_IND_AUS_secondinn_Total6s_valid <- odi_summary_IND_AUS_secondinn_Total6s[43:45,]

# Create time series for Second_innings_Total6s

timeseries_odi_summary_IND_AUS_secondinn_Total6s <- ts(odi_summary_IND_AUS_secondinn_Total6s_in$Second_innings_Total.6s)

#plot the time series
plot(timeseries_odi_summary_IND_AUS_secondinn_Total6s)

#We will compute auto arima

odi_summary_IND_AUS_secondinn_Total6s_arima <- auto.arima(timeseries_odi_summary_IND_AUS_secondinn_Total6s)

tsdiag(odi_summary_IND_AUS_secondinn_Total6s_arima)
plot(odi_summary_IND_AUS_secondinn_Total6s_arima$x)
lines(fitted(odi_summary_IND_AUS_secondinn_Total6s_arima), col="blue")

#We will compute residual series to test white noise
odi_summary_IND_AUS_secondinn_Total6s_residual <- timeseries_odi_summary_IND_AUS_secondinn_Total6s -fitted(odi_summary_IND_AUS_secondinn_Total6s_arima)

#Dickey-Fuller test 
adf.test(odi_summary_IND_AUS_secondinn_Total6s_residual,alternative = "stationary")
#Result: -3.1779, Lag order = 3, p-value = 0.1093
#Since p-value > 0.05 ,null hypothesis is failed to be rejected.That implies the residual series is not stationary.

#KPSS test  
kpss.test(odi_summary_IND_AUS_secondinn_Total6s_residual)
#Result: KPSS Level =  0.047804, Truncation lag parameter = 1, p-value = 0.1
#

#--------------Model evaluation with AUTO ARIMA --------------------------------------------------------------------------#

odi_summary_IND_AUS_secondinn_Total6s.pred <- predict(odi_summary_IND_AUS_secondinn_Total6s_arima,n.ahead = 8)

#MAPE value fr the forecasting
odi_summary_IND_AUS_secondinn_Total6s.run_arima_MAPE <-accuracy(odi_summary_IND_AUS_secondinn_Total6s.pred$pred, odi_summary_IND_AUS_secondinn_Total6s_valid[1:2,2])[5]
#33.51266

####################################################################################################################################################################################

#h.We will take subset of odi_summary_IND_AUS_all_inn to forecast Second_innings_Total.4s
odi_summary_IND_AUS_secondinn_Total4s <- odi_summary_IND_AUS_all_inn[,c('Date', 'Second_innings_Total.4s')]
odi_summary_IND_AUS_secondinn_Total4s <- arrange(odi_summary_IND_AUS_secondinn_Total4s,Date)

#We will split last 3 data for accuracy test from the base data set
odi_summary_IND_AUS_secondinn_Total4s_in <- odi_summary_IND_AUS_secondinn_Total4s[1:42,]
odi_summary_IND_AUS_secondinn_Total4s_valid <- odi_summary_IND_AUS_secondinn_Total4s[43:45,]

# Create time series for Second_innings_Total4s

timeseries_odi_summary_IND_AUS_secondinn_Total4s <- ts(odi_summary_IND_AUS_secondinn_Total4s_in$Second_innings_Total.4s)

#plot the time series
plot(timeseries_odi_summary_IND_AUS_secondinn_Total4s)

#We will compute auto arima

odi_summary_IND_AUS_secondinn_Total4s_arima <- auto.arima(timeseries_odi_summary_IND_AUS_secondinn_Total4s)

tsdiag(odi_summary_IND_AUS_secondinn_Total4s_arima)
plot(odi_summary_IND_AUS_secondinn_Total4s_arima$x)
lines(fitted(odi_summary_IND_AUS_secondinn_Total4s_arima), col="blue")

#We will compute residual series to test white noise
odi_summary_IND_AUS_secondinn_Total4s_residual <- timeseries_odi_summary_IND_AUS_secondinn_Total4s -fitted(odi_summary_IND_AUS_secondinn_Total4s_arima)

#Dickey-Fuller test 
adf.test(odi_summary_IND_AUS_secondinn_Total4s_residual,alternative = "stationary")
#Result: -3.9699, Lag order = 3, p-value = 0.02041
#Since p-value > 0.05 ,null hypothesis is failed to be rejected.That implies the residual series is not stationary.

#KPSS test  
kpss.test(odi_summary_IND_AUS_secondinn_Total4s_residual)
#Result: KPSS Level =  0.13806, Truncation lag parameter = 1, p-value = 0.1
#

#--------------Model evaluation with AUTO ARIMA --------------------------------------------------------------------------#

odi_summary_IND_AUS_secondinn_Total4s.pred <- predict(odi_summary_IND_AUS_secondinn_Total4s_arima,n.ahead = 8)

#MAPE value fr the forecasting
odi_summary_IND_AUS_secondinn_Total4s.run_arima_MAPE <-accuracy(odi_summary_IND_AUS_secondinn_Total4s.pred$pred, odi_summary_IND_AUS_secondinn_Total4s_valid[,2])[5]
#33.9665

####################################################################################################################################################################


#i.We will take subset of odi_summary_IND_AUS_all_inn to forecast Second_innings_Total.Wickets
odi_summary_IND_AUS_secondinn_Total.Wickets <- odi_summary_IND_AUS_all_inn[,c('Date', 'Second_innings_Total.Wickets')]
odi_summary_IND_AUS_secondinn_Total.Wickets <- arrange(odi_summary_IND_AUS_secondinn_Total.Wickets,Date)

#We will split last 3 data for accuracy test from the base data set
odi_summary_IND_AUS_secondinn_Total.Wickets_in <- odi_summary_IND_AUS_secondinn_Total.Wickets[1:42,]
odi_summary_IND_AUS_secondinn_Total.Wickets_valid <- odi_summary_IND_AUS_secondinn_Total.Wickets[43:45,]

# Create time series for Second_innings_Total.Wickets

timeseries_odi_summary_IND_AUS_secondinn_Total.Wickets <- ts(odi_summary_IND_AUS_secondinn_Total.Wickets_in$Second_innings_Total.Wickets)

#plot the time series
plot(timeseries_odi_summary_IND_AUS_secondinn_Total.Wickets)

#We will compute auto arima

odi_summary_IND_AUS_secondinn_Total.Wickets_arima <- auto.arima(timeseries_odi_summary_IND_AUS_secondinn_Total.Wickets)

tsdiag(odi_summary_IND_AUS_secondinn_Total.Wickets_arima)
plot(odi_summary_IND_AUS_secondinn_Total.Wickets_arima$x)
lines(fitted(odi_summary_IND_AUS_secondinn_Total.Wickets_arima), col="blue")

#We will compute residual series to test white noise
odi_summary_IND_AUS_secondinn_Total.Wickets_residual <- timeseries_odi_summary_IND_AUS_secondinn_Total.Wickets -fitted(odi_summary_IND_AUS_secondinn_Total.Wickets_arima)

#Dickey-Fuller test 
adf.test(odi_summary_IND_AUS_secondinn_Total.Wickets_residual,alternative = "stationary")
#Result:  -3.0465, Lag order = 3, p-value = 0.1611
#Since p-value > 0.05 ,null hypothesis is failed to be rejected.That implies the residual series is not stationary.

#KPSS test  
kpss.test(odi_summary_IND_AUS_secondinn_Total.Wickets_residual)
#Result: KPSS Level =  0.26896, Truncation lag parameter = 1, p-value = 0.1
#

#--------------Model evaluation with AUTO ARIMA --------------------------------------------------------------------------#

odi_summary_IND_AUS_secondinn_Total.Wickets.pred <- predict(odi_summary_IND_AUS_secondinn_Total.Wickets_arima,n.ahead = 8)

#MAPE value fr the forecasting
odi_summary_IND_AUS_secondinn_Total.Wickets.run_arima_MAPE <-accuracy(odi_summary_IND_AUS_secondinn_Total.Wickets.pred$pred, odi_summary_IND_AUS_secondinn_Total.Wickets_valid[,2])[5]
#84.71056

##########################################################################################################################################################################################


#k.We will take subset of odi_summary_IND_AUS_all_inn to forecast Second_innings_Total.Balls
odi_summary_IND_AUS_secondinn_Total.Balls <- odi_summary_IND_AUS_all_inn[,c('Date', 'Second_innings_Total.Balls')]
odi_summary_IND_AUS_secondinn_Total.Balls <- arrange(odi_summary_IND_AUS_secondinn_Total.Balls,Date)

#We will split last 3 data for accuracy test from the base data set
odi_summary_IND_AUS_secondinn_Total.Balls_in <- odi_summary_IND_AUS_secondinn_Total.Balls[1:42,]
odi_summary_IND_AUS_secondinn_Total.Balls_valid <- odi_summary_IND_AUS_secondinn_Total.Balls[43:45,]

# Create time series for Second_innings_Total.Balls

timeseries_odi_summary_IND_AUS_secondinn_Total.Balls <- ts(odi_summary_IND_AUS_secondinn_Total.Balls_in$Second_innings_Total.Balls)

#plot the time series
plot(timeseries_odi_summary_IND_AUS_secondinn_Total.Balls)

#We will compute auto arima

odi_summary_IND_AUS_secondinn_Total.Balls_arima <- auto.arima(timeseries_odi_summary_IND_AUS_secondinn_Total.Balls)

tsdiag(odi_summary_IND_AUS_secondinn_Total.Balls_arima)
plot(odi_summary_IND_AUS_secondinn_Total.Balls_arima$x)
lines(fitted(odi_summary_IND_AUS_secondinn_Total.Balls_arima), col="blue")

#We will compute residual series to test white noise
odi_summary_IND_AUS_secondinn_Total.Balls_residual <- timeseries_odi_summary_IND_AUS_secondinn_Total.Balls -fitted(odi_summary_IND_AUS_secondinn_Total.Balls_arima)

#Dickey-Fuller test 
adf.test(odi_summary_IND_AUS_secondinn_Total.Balls_residual,alternative = "stationary")
#Result: -3.2258, Lag order = 3, p-value = 0.09638
#Since p-value > 0.05 ,null hypothesis is failed to be rejected.That implies the residual series is not stationary.

#KPSS test  
kpss.test(odi_summary_IND_AUS_secondinn_Total.Balls_residual)
#Result: KPSS Level =  0.050393, Truncation lag parameter = 1, p-value = 0.1
#

#--------------Model evaluation with AUTO ARIMA --------------------------------------------------------------------------#

odi_summary_IND_AUS_secondinn_Total.Balls.pred <- predict(odi_summary_IND_AUS_secondinn_Total.Balls_arima,n.ahead = 8)

#MAPE value fr the forecasting
odi_summary_IND_AUS_secondinn_Total.Balls.run_arima_MAPE <-accuracy(odi_summary_IND_AUS_secondinn_Total.Balls.pred$pred, odi_summary_IND_AUS_secondinn_Total.Balls_valid[,2])[5]
#5.401237

#################################################################################################################################################################################


#odi_summary_IND_AUS_secondinn_Total.Balls.pred$pred
#
#We have forecasted following field for next 5 months.We will add predicted values with test data

odi_summary_test <- cbind(odi_summary_test,
                          odi_summary_IND_AUS_firstinn_tot.pred$pred[4:8],
                          odi_summary_IND_AUS_firstinn_tot6s.pred$pred[4:8],
                          odi_summary_IND_AUS_firstinn_tot4s.pred$pred[4:8],
                          odi_summary_IND_AUS_firstinn_Total.Wickets.pred$pred[4:8],
                          odi_summary_IND_AUS_firstinn_Total.Balls.pred$pred[4:8],
                          odi_summary_IND_AUS_secondinn_Total.Runs.pred$pred[4:8],
                          odi_summary_IND_AUS_secondinn_Total6s.pred$pred[4:8],
                          odi_summary_IND_AUS_secondinn_Total4s.pred$pred[4:8],
                          odi_summary_IND_AUS_secondinn_Total.Wickets.pred$pred[4:8],
                          odi_summary_IND_AUS_secondinn_Total.Balls.pred$pred[4:8])
colnames(test_data)
colnames(odi_summary_test) <- c('Match.City','Venue.Ground','Date','Team1','Team2',"First_innings_Total.Runs",
                                "First_innings_Total.6s","First_innings_Total.4s","First_innings_Total.Wickets",
                                "First_innings_Total.Balls","Second_innings_Total.Runs","Second_innings_Total.6s",                                         
                                "Second_innings_Total.4s","Second_innings_Total.Wickets","Second_innings_Total.Balls")                                    

odi_summary_test$Venue.Ground <- as.factor(odi_summary_test$Venue.Ground)                         

odi_summary_test_dummy_var <- data.frame(sapply(odi_summary_test$Venue.Ground,function(x) data.frame(model.matrix(~x-1,data =odi_summary_test[,c("Venue.Ground")]))))
colnames(odi_summary_test_dummy_var) <- c("Venue.Ground.xRajiv.Gandhi.International.Stadium..Uppal","Venue.Ground.xVidarbha.Cricket.Association.Ground","Venue.Ground.xJSCA.International.Stadium.Complex","Venue.Ground.xPunjab.Cricket.Association.Stadium..Mohali","Venue.Ground.xFeroz.Shah.Kotla")
rownames(odi_summary_test_dummy_var) <- c(1:5)
odi_summary_test <- cbind(odi_summary_test,odi_summary_test_dummy_var)

#Let us remove Venue.Ground,Team1 and Team2 from test data -odi_summary_test
redundant <- c("Venue.Ground","Team1","Team2","Match.City")
odi_summary_test <- odi_summary_test[,!colnames(odi_summary_test) %in% redundant]


#We will now predict on odi_summary_test
odi_summary_test_prediction <- predict(model_10_odi, type = "response", newdata = odi_summary_test)

#Summary of prediction:
summary(odi_summary_test_prediction)


#We merge predicted value to test_data set
odi_summary_test$Predicted_probality <- odi_summary_test_prediction

#Now our calculated cutoff is 0.3770707
odi_summary_test_final_prediction <- factor(ifelse(odi_summary_test_prediction >=0.3770707, "India", "Australia"))

odi_summary_test$Predicted_Winner <- odi_summary_test_final_prediction

#Hence based on our Prediction India will Win in all the 5 matches provided India chooses to bat on second innings.!


