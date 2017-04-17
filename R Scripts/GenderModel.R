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
