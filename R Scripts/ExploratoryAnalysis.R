# ExploratoryAnalysis.R

# Import datasets
train <- read.csv('../data/train.csv', stringsAsFactors = F)
test <- read.csv('../data/test.csv')

str(train)

# Check survivors 
prop.table(table(train$Survived))

# Check sex division on the train dataset
summary(train$Sex)

# Check sex vs survived as separate groups
prop.table(table(train$Sex, train$Survived),1)

# Check age distribution
summary(train$Age)

# Create a Child attribute 1 to all passenger younger than 18 years
train$Child <- 0
train$Child[train$Age < 18] <- 1

# Survival proportion against Child and Sex attributes
aggregate(Survived ~ Child + Sex, data=train, FUN=function(x) {sum(x)/length(x)})

require(ggplot2)
require(reshape2)

ggplot(data = train, aes(x=Age, colour=as.factor(Survived))) +
  geom_freqpoly(binwidth = 2) +
  facet_wrap(~Sex) +
  ggtitle("Supervivientes por edad y sexo") +
  labs(colour="Survived")


# Check Pclass distribution
summary(as.factor(train$Pclass))

# Survival proportion against Pclass
prop.table(table(train$Pclass, train$Survived),1)


require(plyr)
train.bypclass <- ddply(train, c("Pclass"), function(x) {count(x$Survived)})
colnames(train.bypclass) <- c("Pclass", "Survived", "Count")
train.bypclass.twocol <- dcast(train.bypclass, Pclass ~ Survived)
train.bypclass.twocol$Total <- train.bypclass.twocol$`0` + train.bypclass.twocol$`1`
train.bypclass.twocol$`0` <- train.bypclass.twocol$`0` / train.bypclass.twocol$Total * 100
train.bypclass.twocol$`1` <- train.bypclass.twocol$`1` / train.bypclass.twocol$Total * 100
train.bypclass.twocol$Total <- NULL

train.bypclass.perc <- melt(train.bypclass.twocol, id.vars = c('Pclass'), variable.name = 'Survived', value.name = 'Perc')
ggplot(data = train.bypclass.perc, aes(x = Pclass, y = Perc, fill = Survived)) +
  geom_bar(stat = "identity") +
  ggtitle("Porcentaje de supervivencia por clase")



# Check Fare distribution
summary(train$Fare)

# Sampling Fare attribute into 4 values
train$FareDiscrete <- '30+'
train$FareDiscrete[train$Fare < 30 & train$Fare >= 20] <- '20-30'
train$FareDiscrete[train$Fare < 20 & train$Fare >= 10] <- '10-20'
train$FareDiscrete[train$Fare < 10] <- '<10'

# Survival proportion against Fare
prop.table(table(train$FareDiscrete, train$Survived),1)


# Survival proportion against FareDiscrete, Pclass and Sex attributes. 
# As you could see the majority of females in Pclas 3 that paid more than 20
# perish
aggregate(Survived ~ FareDiscrete + Pclass + Sex, data=train, FUN=function(x) {sum(x)/length(x)})


# Survival proportion against FareDiscrete, Pclass, Child and Sex attributes. 
# As you could see the majority of children males in Pclas 1 and 2 survived, the same for
# the Pclass 3 children males that paid between 10-20 
aggregate(Survived ~ FareDiscrete + Pclass + Child+ Sex, data=train, FUN=function(x) {sum(x)/length(x)})


summary(train$Cabin)
str(train)

summary(train$Embarked)


table(train$Embarked, train$Pclass)


train.byembarked <- ddply(train, c("Embarked"), function(x) {count(x$Pclass)})
colnames(train.byembarked) <- c("Embarked", "Pclass", "Count")
train.byembarked.twocol <- dcast(train.byembarked, Embarked ~ Pclass)
train.byembarked.twocol$Total <- train.byembarked.twocol$`1` + train.byembarked.twocol$`2` + train.byembarked.twocol$`3`
train.byembarked.twocol$`1` <- train.byembarked.twocol$`1` / train.byembarked.twocol$Total * 100
train.byembarked.twocol$`2` <- train.byembarked.twocol$`2` / train.byembarked.twocol$Total * 100
train.byembarked.twocol$`3` <- train.byembarked.twocol$`3` / train.byembarked.twocol$Total * 100

# Delete the firs row (Missing values)
train.byembarked.twocol = train.byembarked.twocol[-1,]
train.byembarked.twocol$Total <- NULL

train.byembarked.perc <- melt(train.byembarked.twocol, id.vars = c('Embarked'), variable.name = 'Pclass', value.name = 'Perc')
ggplot(data = train.byembarked.perc, aes(x = Embarked, y = Perc, fill = Pclass)) +
  geom_bar(stat = "identity") +
  ggtitle("Porcentaje de Pclass por puerto de embarque")
