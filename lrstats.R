#Confusion matrices: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L688
#For “plotting” the tables you can use the xtable package to automatically TeX format them as they print https://www.rdocumentation.org/packages/xtable/versions/1.8-4/topics/xtable
 
#ROC plots: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L751
#PR plot: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L761


fname <- "qastats/wide.csv" 

mydataset <- read.csv(fname, na.strings=c(".", "NA", "", "?"), strip.white=TRUE, encoding="UTF-8")

# The `pROC' package implements various AUC functions.

# Calculate the Area Under the Curve (AUC).

myroc = pROC::roc( mydataset$truth, mydataset$predict5  , curve=T   )

# Calculate the AUC Confidence Interval.

pROC::ci.auc( mydataset$truth, mydataset$predict5  )

plot(myroc)

