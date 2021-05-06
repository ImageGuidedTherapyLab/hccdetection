#Confusion matrices: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L688
#For “plotting” the tables you can use the xtable package to automatically TeX format them as they print https://www.rdocumentation.org/packages/xtable/versions/1.8-4/topics/xtable
 
#ROC plots: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L751
#PR plot: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L761

graphics.off()

# source('lrstats.R')
fname <- "qastats/wide.csv" 
mydataset <- read.csv(fname, na.strings=c(".", "NA", "", "?"), strip.white=TRUE, encoding="UTF-8")

# summary stats
print( 'unique patients' )
print( unique(mydataset$ptid) )
print( 'lesion summary' )
print( table(mydataset$truth))

# subset data
newdata <- subset(mydataset , truth != 4 )
table(newdata$truth)

# The `pROC' package implements various AUC functions.
# Calculate the Area Under the Curve (AUC).
myroc3a     = pROC::roc( response = ifelse(mydataset$truth == 3,1,0), predictor = mydataset$predict3  , curve=T   )
myroc5a     = pROC::roc( response = ifelse(mydataset$truth == 5,1,0), predictor = mydataset$predict5  , curve=T   )
myroc5b     = pROC::roc( response = ifelse(mydataset$truth == 5,1,0), predictor = mydataset$countlr5  / mydataset$compsize, curve=T   )
myrocepm3   = pROC::roc( response = ifelse(mydataset$truth == 3,1,0), predictor = mydataset$EPM  , curve=T   )
myrocepm5   = pROC::roc( response = ifelse(mydataset$truth == 5,1,0), predictor = mydataset$EPM  , curve=T   )
myrocepmsub = pROC::roc( response = newdata$truth , predictor = newdata$EPM  , curve=T   )
myrocsuba   = pROC::roc( response = newdata$truth , predictor = newdata$predict3 , curve=T   )
myrocsubb   = pROC::roc( response = newdata$truth , predictor = newdata$predict5 , curve=T   )

cbind(mydataset$InstanceUID,mydataset$LabelID, mydataset$countlr5, mydataset$compsize, mydataset$countlr5  / mydataset$compsize,mydataset$truth,ifelse(mydataset$truth == 5,1,0))
# Calculate the AUC Confidence Interval.

pROC::ci.auc( ifelse(mydataset$truth == 5,1,0), mydataset$predict5  )
pROC::ci.auc( ifelse(mydataset$truth == 5,1,0), mydataset$countlr5  / mydataset$compsize)


png('myroc3a.png');     plot(myroc3a    ,main=sprintf("ROC curve NN LR3/LR4&LR5 \nAUC=%0.3f", myroc3a$auc)); dev.off()
png('myroc5a.png');     plot(myroc5a    ,main=sprintf("ROC curve NN LR5/LR3&LR4 \nAUC=%0.3f", myroc5a$auc)); dev.off()
png('myroc5b.png');     plot(myroc5b    ,main=sprintf("ROC curve bLR5/not-LR5   \nAUC=%0.3f", myroc5b$auc)); dev.off()
png('myrocepm5.png');   plot(myrocepm5  ,main=sprintf("ROC curve EPM LR5/LR3&LR4\nAUC=%0.3f", myrocepm5$auc)); dev.off()
png('myrocepm3.png');   plot(myrocepm3  ,main=sprintf("ROC curve EPM LR3/LR4&LR5\nAUC=%0.3f", myrocepm3$auc)); dev.off()
png('myrocepmsub.png'); plot(myrocepmsub,main=sprintf("ROC curve EPM LR3/LR5    \nAUC=%0.3f", myrocepmsub$auc)); dev.off()
png('myrocsuba.png');   plot(myrocsuba  ,main=sprintf("ROC curve NN  LR3/LR5    \nAUC=%0.3f", myrocsuba$auc)); dev.off()
png('myrocsubb.png');   plot(myrocsubb  ,main=sprintf("ROC curve NN  LR3/LR5    \nAUC=%0.3f", myrocsubb$auc)); dev.off()
