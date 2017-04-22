# InitialDecissionTree.R
# References: 
# - http://trevorstephens.com/kaggle-titanic-tutorial/r-part-4-feature-engineering/
# - https://www.kaggle.com/mrisdal/titanic/exploring-survival-on-the-titanic/notebook


# Import datasets
train <- read.csv('../data/train.csv', stringsAsFactors = F)
test <- read.csv('../data/test.csv', stringsAsFactors = F)

# Join the 2 dataset into a full one
test$Survived <- NA
full <- rbind(train, test)

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


full$FamilySize <- full$SibSp + full$Parch + 1

library('ggplot2') # visualization
library('ggthemes') # visualization
library('scales') # visualization

# Use ggplot2 to visualize the relationship between family size & survival
ggplot(full[1:891,], aes(x = FamilySize, fill = factor(Survived))) +
  geom_bar(stat='percent', position='dodge') +
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



library(rpart)

# Split the data
train <- full[1:891,]
test <- full[892:1309,]

# Create a decission tree
fit <- rpart(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked + Title + FamilySize + FamilyID,
             data=train, 
             method="class")

# Add libraries to make a decission tree plot
library(rattle)
library(rpart.plot)
library(RColorBrewer)

fancyRpartPlot(fit)


# Use the decission tree to predict over the test dataset
Prediction <- predict(fit, test, type = "class")

# Prepare prediction to submit
submit <- data.frame(PassengerId = test$PassengerId, Survived = Prediction)

# Save prediction
write.csv(submit, file = "../predictions/featureEngineeringTree.csv", row.names = FALSE)
