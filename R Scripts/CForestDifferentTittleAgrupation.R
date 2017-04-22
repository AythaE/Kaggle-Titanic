# InitialDecissionTree.R
# References: 
# - http://trevorstephens.com/kaggle-titanic-tutorial/r-part-5-random-forests/
# - https://www.kaggle.io/svf/924638/c05c7b2409e224c760cdfb527a8dcfc4/__results__.html


############################# LOAD DATA ############################# 


# Import datasets
train <- read.csv('../data/train.csv', stringsAsFactors = F)
test <- read.csv('../data/test.csv', stringsAsFactors = F)

# Join the 2 dataset into a full one
test$Survived <- NA
full <- rbind(train, test)


############################# FEATURE ENGINEERING ############################# 


# Extract the social title from the Name Attr using a regular exprexion
full$Title <- sapply(full$Name, FUN=function(x) {strsplit(x, split='[,.]')[[1]][2]})

# Clean the initial title space
full$Title <- sub(' ', '', full$Title)

# Check the titles
table(full$Title)


# TODO try the title division use in https://www.kaggle.io/svf/924638/c05c7b2409e224c760cdfb527a8dcfc4/__results__.html#whats-in-a-name

# Reassign mlle, ms, and mme accordingly
full$Title[full$Title %in% c('Ms', 'Mlle')] <- 'Miss'
full$Title[full$Title == 'Mme'] <- 'Mrs'

# Combine the high class titles into 'Sir' for males and 'Lady' for female
full$Title[full$Title %in% c('Capt', 'Don', 'Major', 'Sir')] <- 'Sir'
full$Title[full$Title %in% c('Dona', 'Lady', 'the Countess', 'Jonkheer')] <- 'Lady'

# Set as factor
full$Title <- factor(full$Title)



# Create a family size attribute using the siblings/spouses number, the parents/childrens 
# number and adding one to count him/herself
full$FamilySize <- full$SibSp + full$Parch + 1

library('ggplot2') # visualization
library('ggthemes') # visualization
library('scales') # visualization

# Use ggplot2 to visualize the relationship between family size & survival
ggplot(full[1:891,], aes(x = FamilySize, fill = factor(Survived))) +
  geom_bar(stat='count', position='dodge') +
  scale_x_continuous(breaks=c(1:11)) +
  labs(x = 'Family Size') +
  theme_few()

# Extract the surname to create a FamilyID
full$Surname <- sapply(full$Name, FUN=function(x) {strsplit(x, split='[,.]')[[1]][1]})
full$FamilyID <- paste(full$Surname, as.character(full$FamilySize), sep="_")

# Set the Family ID of the Small fams as small
full$FamilyID[full$FamilySize <= 1] <- 'Small'

# Check the family ID
table(full$FamilyID)

famIDs <- data.frame(table(full$FamilyID))

famIDs <- famIDs[famIDs$Freq <= 1,]

# Overwrite non sense famIDs
full$FamilyID[full$FamilyID %in% famIDs$Var1] <- 'Small'
# Turn FamilyID into factor
full$FamilyID <- factor(full$FamilyID)


############################# IMPUTATION ############################# 


# Check age distribution
summary(full$Age)

# TODO Try Mice
# Make variables factors into factors
factor_vars <- c('PassengerId','Pclass','Sex','Embarked',
                 'Title','FamilyID','FamilySize')

full[factor_vars] <- lapply(full[factor_vars], function(x) as.factor(x))

library(mice)
# Set a random seed
set.seed(129)

# Perform mice imputation, excluding certain less-than-useful variables:
mice_mod <- mice(full[, !names(full) %in% c('PassengerId','Name','Ticket','Cabin','Surname','FamilyID','Survived')], method='rf') 

mice_output <- complete(mice_mod)
# Plot age distributions
par(mfrow=c(1,2))
hist(full$Age, freq=F, main='Age: Original Data', 
     col='darkgreen', ylim=c(0,0.04))
hist(mice_output$Age, freq=F, main='Age: Predicted Data', 
     col='lightgreen', ylim=c(0,0.04))

full$Age <- mice_output$Age



# Get rid of embarked missing values assign it to the most repeated value S
full$Embarked <- factor(full$Embarked)
summary(full$Embarked)
which(full$Embarked == '')
full$Embarked[c(62,830)] = "S"
full$Embarked <- factor(full$Embarked)



# Assign the fare NA to the median value
summary(full$Fare)
which(is.na(full$Fare))
full$Fare[1044] <- median(full$Fare, na.rm=TRUE)


############################# DATA PREPARATION ############################# 


# Turn Sex into a factor to use it in cforest
full$Sex <- factor(full$Sex)

# Rechange Pclass into Int
full$Pclass <- as.integer(full$Pclass)

# Reduce the number of levels of the FamilyID to use it in a RandomForest
full$FamilyID2 <- full$FamilyID
full$FamilyID2 <- as.character(full$FamilyID2)
full$FamilySize <- as.integer(full$FamilySize)
full$FamilyID2[full$FamilySize <= 3] <- 'Small'
full$FamilyID2 <- factor(full$FamilyID2)
summary(full$FamilyID2)
############################# PREDICTION ############################# 


library(party)
library(randomForest)

# Split the data
train <- full[1:891,]
test <- full[892:1309,]

# Set a random seed to reproducible prediction
set.seed(415)
str(test)

fit <- randomForest(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare +
                      Embarked + Title + FamilySize + FamilyID2,
                    data=train, 
                    importance=TRUE, 
                    ntree=2000)
# Plot the most important variables
varImpPlot(fit)

# Create a Conditional inference forest predictor
fit <- cforest(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare +
                 Embarked + Title + FamilySize + FamilyID,
               data = train, 
               controls=cforest_unbiased(ntree=2000, mtry=3))

fit
# Use the model to predict over the test dataset
Prediction <- predict(fit, test, OOB=TRUE, type = "response")


############################# PREPARE SUBMITION ############################# 


# Prepare prediction to submit
submit <- data.frame(PassengerId = test$PassengerId, Survived = Prediction)

# Save prediction
write.csv(submit, file = "../predictions/CForestMiceAgeFamIDLessSmall.csv", row.names = FALSE)
