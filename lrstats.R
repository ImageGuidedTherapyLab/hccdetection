#Confusion matrices: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L688
#For “plotting” the tables you can use the xtable package to automatically TeX format them as they print https://www.rdocumentation.org/packages/xtable/versions/1.8-4/topics/xtable
 
#ROC plots: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L751
#PR plot: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L761

graphics.off()

# source('lrstats.R')
fname <- "qastats/wide.csv" 
mydataset <- read.csv(fname, na.strings=c(".", "NA", "", "?"), strip.white=TRUE, encoding="UTF-8")

# The `pROC' package implements various AUC functions.

# Calculate the Area Under the Curve (AUC).


myroc3a = pROC::roc( response = ifelse(mydataset$truth == 3,1,0), predictor = mydataset$predict3  , curve=T   )
myroc4a = pROC::roc( response = ifelse(mydataset$truth == 4,1,0), predictor = mydataset$predict4  , curve=T   )
myroc5a = pROC::roc( response = ifelse(mydataset$truth == 5,1,0), predictor = mydataset$predict5  , curve=T   )
myroc5b = pROC::roc( response = ifelse(mydataset$truth == 5,1,0), predictor = mydataset$countlr5  / mydataset$compsize, curve=T   )

cbind(mydataset$InstanceUID,mydataset$LabelID, mydataset$countlr5, mydataset$compsize, mydataset$countlr5  / mydataset$compsize,mydataset$truth,ifelse(mydataset$truth == 5,1,0))
# Calculate the AUC Confidence Interval.

pROC::ci.auc( ifelse(mydataset$truth == 5,1,0), mydataset$predict5  )
pROC::ci.auc( ifelse(mydataset$truth == 5,1,0), mydataset$countlr5  / mydataset$compsize)

plot(myroc3a);x11() 
plot(myroc5b)

