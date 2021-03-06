library(rpart);
library(rattle);
library(rpart.plot);
library(reshape2);
library(kernlab);

train = read.csv("train.csv");
test = read.csv("test.csv");

## Add new feature Title
test$Survived <- NA
comb <- rbind(train, test)
split1 = colsplit(string=as.character(comb$Name), pattern=", ", names=c("Part1","Part2"))
split2 = colsplit(string=as.character(split1$Part2), pattern="\\.", names=c("Part1","Part2"))
comb$Title <- split2$Part1

comb$Title[comb$Title %in% c('Mlle')] <- 'Miss'
comb$Title[comb$Title %in% c('Mme','Ms')] <- 'Mrs'
comb$Title[comb$Title %in% c('Capt', 'Col', 'Don', 'Major')] <- 'Sir'
comb$Title[comb$Title %in% c('Dona', 'Lady', 'the Countess', 'Jonkheer')] <- 'Lady'

## Add new feature FamSize = SibSp+Parch+1
comb$FamSize <- comb$SibSp + comb$Parch + 1

## Add new feature AgeCat
comb$AgeCat[comb$Age <= 10.00] <-"child"
comb$AgeCat[comb$Age > 10.00 & comb$Age <=20.00] <-"teen"
comb$AgeCat[comb$Age > 20.00 & comb$Age <= 35.00] <-"young"
comb$AgeCat[comb$Age > 35.00 & comb$Age <= 50.00] <-"adult"
comb$AgeCat[comb$Age > 50.00 & comb$Age <= 60.00] <-"elder"
comb$AgeCat[comb$Age > 60.00] <-"old"

## Add new feature AgeCatSex
comb$AgeCatSex <- paste(comb$AgeCat, comb$Sex, sep="_")

## Add new feature FamilyID
split1 <- colsplit(string=as.character(comb$Name), pattern=",.", names=c("Part1","Part2"))
comb$Surname <- split1$Part1
comb$FamilyID <- paste(as.character(comb$FamSize), comb$Surname, sep="")
comb$FamilyID[comb$FamSize <= 1] <- 'Single'

id_list <- data.frame(table(comb$FamilyID))
id_list <- id_list[id_list$Freq <= 1,]
comb$FamilyID[comb$FamilyID %in% id_list$Var1] <- 'Single'
comb$FamilyID <- factor(comb$FamilyID)

# Split back
train <- comb[1:891,]
test <- comb[892:1309,]

# Build the tree with new features
#fit <- rpart(Survived ~ FareCatPclass + AgeCatSex + Pclass + Sex + Age + SibSp + Parch + Fare + Embarked + Title + FamSize + FamilyID, data=train, method="class")
fit <- rpart(Survived ~ AgeCatSex + FamilyID, data=train, method="class")
fancyRpartPlot(fit)
printcp(fit)

Prediction <- predict(fit, test, type = "class");
result <- data.frame(PassengerId = test$PassengerId, Survived = as.numeric(levels(Prediction))[Prediction]);
write.csv(result, file = "featureselection.csv", row.names = FALSE);

########## Logistic regression ##########

#model = glm(Survived ~ Age:Sex + Pclass:Sex + Title + Embarked + FamSize, family = binomial(logit), data = train)
model = glm(Survived ~ FamilyID, family = binomial(logit), data = train)
summary(model)

p <- predict(model, test, type="response")
result <- data.frame(PassengerId = test$PassengerId, Survived = p);

write.csv(result, file = "H:/Data Mining/kaggle/logistic.csv", row.names = FALSE);
