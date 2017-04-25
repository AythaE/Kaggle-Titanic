# GenderFareModel.R
# Reference: http://trevorstephens.com/kaggle-titanic-tutorial/r-part-2-the-gender-class-model/


# Import datasets
train <- read.csv('../data/train.csv')
test <- read.csv('../data/test.csv')

# Check sex division on the train dataset
summary(train$Sex)

# Check sex vs survived as separate groups
prop.table(table(train$Sex, train$Survived),1)

# Age distribution
summary(train$Age)

# Create a Child attribute 1 to all passenger younger than 18 years
train$Child <- 0
train$Child[train$Age < 18] <- 1

# Survival proportion against Child and Sex attributes
aggregate(Survived ~ Child + Sex, data=train, FUN=function(x) {sum(x)/length(x)})

# Sampling Fare attribute into 4 values
train$FareDiscrete <- '30+'
train$FareDiscrete[train$Fare < 30 & train$Fare >= 20] <- '20-30'
train$FareDiscrete[train$Fare < 20 & train$Fare >= 10] <- '10-20'
train$FareDiscrete[train$Fare < 10] <- '<10'

# Survival proportion against FareDiscrete, Pclass and Sex attributes. 
# As you could see the majority of females in Pclas 3 that paid more than 20
# perish
aggregate(Survived ~ FareDiscrete + Pclass + Sex, data=train, FUN=function(x) {sum(x)/length(x)})


aggregate(Survived ~ FareDiscrete + Pclass + Child+ Sex, data=train, FUN=function(x) {sum(x)/length(x)})

# Asume all females survived except females in Pclass 3 that paid more than 20
# and all males who died
test$Survived <- 0
test$Survived[test$Sex == 'female'] <- 1
test$Survived[test$Sex == 'female' & test$Pclass == 3 & test$Fare >= 20] <- 0


# Prepare prediction to submit
submit <- data.frame(PassengerID = test$PassengerId, Survived = test$Survived)

# Save prediction
write.csv(submit, file = "../predictions/genderFare.csv", row.names = FALSE)

train$SurvivedP <- 0
train$SurvivedP[train$Sex == 'female'] <- 1
train$SurvivedP[train$Sex == 'female' & train$Pclass == 3 & train$Fare >= 20] <- 0
trainResults <- data.frame(Real = train$Survived, Predicho = train$SurvivedP)

correct <- 0
for(i in 1:nrow(trainResults)){
  if(trainResults$Real[i] == trainResults$Predicho[i]){
    print(i)
    correct <- correct + 1
  }
  
}
tasaError <- correct/nrow(trainResults)
print(paste("La tasa de error sobre el conjunto de train es: ", tasaError))

