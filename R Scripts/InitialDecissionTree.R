# InitialDecissionTree.R
# Reference: http://trevorstephens.com/kaggle-titanic-tutorial/r-part-3-decision-trees/


# Import datasets
train <- read.csv('../data/train.csv')
test <- read.csv('../data/test.csv')

library(rpart)
# Create a decission tree
fit <- rpart(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked,
             data=train,
             method="class")
# Initial plot
plot(fit)
text(fit)

# Add libraries to better decission tree plot
library(rattle)
library(rpart.plot)
library(RColorBrewer)

fancyRpartPlot(fit)

# Use the decission tree to predict over the test dataset
Prediction <- predict(fit, test, type = "class")

# Prepare prediction to submit
submit <- data.frame(PassengerId = test$PassengerId, Survived = Prediction)

# Save prediction
write.csv(submit, file = "../predictions/myfirstdtree.csv", row.names = FALSE)
