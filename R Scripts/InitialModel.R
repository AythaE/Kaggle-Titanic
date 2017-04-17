# InitialModel.R
# Reference: http://trevorstephens.com/kaggle-titanic-tutorial/r-part-1-booting-up/

# Import datasets
train <- read.csv('../data/train.csv', stringsAsFactors = FALSE)
test <- read.csv('../data/test.csv', stringsAsFactors = FALSE)

# Check data
str(train)
str(test)

# Check survivors 
table(train$Survived)
prop.table(table(train$Survived))

# Assume everyone died 
test$Survived <- rep(0, 418)

# Prepare prediction to submit
submit <- data.frame(PassengerID = test$PassengerId, Survived = test$Survived)

# Save prediction
write.csv(submit, file = "../predictions/allperish.csv", row.names = FALSE)
