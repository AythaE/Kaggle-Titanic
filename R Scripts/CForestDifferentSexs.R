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

# Combine 'Mme' and 'Mlle' into 'Mlle'
full$Title[full$Title %in% c('Mme', 'Mlle')] <- 'Mlle'

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
full$FamilyID[full$FamilySize <= 2] <- 'Small'

# Check the family ID
table(full$FamilyID)

famIDs <- data.frame(table(full$FamilyID))

famIDs <- famIDs[famIDs$Freq <= 2,]

# Overwrite non sense famIDs
full$FamilyID[full$FamilyID %in% famIDs$Var1] <- 'Small'
# Turn FamilyID into factor
full$FamilyID <- factor(full$FamilyID)


############################# IMPUTATION ############################# 


# Check age distribution
summary(full$Age)

# Predict age using an Anova Decission Tree
library(rpart)
Agefit <- rpart(Age ~ Pclass + Sex + SibSp + Parch + Fare + Embarked + Title + FamilySize,
                data=full[!is.na(full$Age),], 
                method="anova")

AgePrediction <- full$Age
AgePrediction[is.na(full$Age)] <- predict(Agefit, full[is.na(full$Age),])

# Plot age distributions
op <- par(mfrow=c(1,2))

hist(full$Age, freq=F, main='Age: Original Data', 
     col='darkgreen', ylim=c(0,0.04))
hist(AgePrediction, freq=F, main='Age: Predicted Data', 
     col='lightgreen', ylim=c(0,0.04))

## At end of plotting, reset to previous settings:
par(op)

full$Age[is.na(full$Age)] <- predict(Agefit, full[is.na(full$Age),])



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


############################# PREDICTION ############################# 


library(party)

# Split the data
train <- full[1:891,]
test <- full[892:1309,]

# Divide the train and test in different datasets for males and females
trainMale <- train[train$Sex == 'male',]
trainFemale <- train[train$Sex == 'female',]
testMale <- test[test$Sex == 'male',]
testFemale <- test[test$Sex == 'female',]

# Set a random seed to reproducible prediction
set.seed(415)

# Create a Conditional inference forest predictor for males
fitMale <- cforest(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare +
                 Embarked + Title + FamilySize + FamilyID,
               data = trainMale, 
               controls=cforest_unbiased(ntree=2000, mtry=3))

# Create a Conditional inference forest predictor for females
fitFemale <- cforest(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare +
                     Embarked + Title + FamilySize + FamilyID,
                   data = trainFemale, 
                   controls=cforest_unbiased(ntree=2000, mtry=3))

# Use the models to predict over the test dataset
PredictionMale <- predict(fitMale, testMale, OOB=TRUE, type = "response")
PredictionFemale <- predict(fitFemale, testFemale, OOB=TRUE, type = "response")


############################# PREPARE SUBMITION ############################# 


# Prepare prediction to submit
submitMale <- data.frame(PassengerId = testMale$PassengerId, Survived = PredictionMale)
submitFemale <- data.frame(PassengerId = testFemale$PassengerId, Survived = PredictionFemale)

submit <- rbind(submitMale, submitFemale)

# Save prediction
write.csv(submit, file = "../predictions/CForestDifferentSexs.csv", row.names = FALSE)



PredictionTrainMale <- predict(fitMale, trainMale, OOB=TRUE, type = "response")
PredictionTrainFemale <- predict(fitFemale, trainFemale, OOB=TRUE, type = "response")
trainResultsMale <- data.frame(Real = trainMale$Survived, Predicho = PredictionTrainMale)
trainResultsFemale <- data.frame(Real = trainFemale$Survived, Predicho = PredictionTrainFemale)

trainResults <- rbind(trainResultsMale, trainResultsFemale)
correct <- 0
for(i in 1:nrow(trainResults)){
  if(trainResults$Real[i] == trainResults$Predicho[i]){
    print(i)
    correct <- correct + 1
  }
  
}
tasaError <- correct/nrow(trainResults)
print(paste("La tasa de error sobre el conjunto de train es: ", tasaError))
