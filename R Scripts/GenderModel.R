# GenderModel.R
# Reference: http://trevorstephens.com/kaggle-titanic-tutorial/r-part-2-the-gender-class-model/


# Import datasets
train <- read.csv('../data/train.csv')
test <- read.csv('../data/test.csv')

# Check sex division on the train dataset
summary(train$Sex)

# Check sex vs survived as separate groups
prop.table(table(train$Sex, train$Survived),1)

# Asume all females survived and all males died
test$Survived <- 0
test$Survived[test$Sex == 'female'] <- 1



# Prepare prediction to submit
submit <- data.frame(PassengerID = test$PassengerId, Survived = test$Survived)

# Save prediction
write.csv(submit, file = "../predictions/gender.csv", row.names = FALSE)

train$SurvivedP <- 0
train$SurvivedP[train$Sex == 'female'] <- 1


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
