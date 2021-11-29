#Confusion matrices: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L688
#For “plotting” the tables you can use the xtable package to automatically TeX format them as they print https://www.rdocumentation.org/packages/xtable/versions/1.8-4/topics/xtable
 
#ROC plots: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L751
#PR plot: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L761

graphics.off()

# source('epmstats.R')
fname <- "epmstats/widejoin.csv" 
mydataset <- read.csv(fname, na.strings=c(".", "NA", "", "?"), strip.white=TRUE, encoding="UTF-8")

# summary stats
print( 'unique patients' )
print( unique(mydataset$ptid) )

# subset data
epmdataDx    <- subset(mydataset , Status == 'case' & diagnosticinterval ==0.0 & FeatureID == 'epm')
epmdataPreDx <- subset(mydataset , Status == 'case' & diagnosticinterval >0.0 & FeatureID == 'epm')
epmdataCase  <- subset(mydataset , Status == 'case' & FeatureID == 'epm')
epmdataCntrl <- subset(mydataset , Status == 'control' & FeatureID == 'epm')
epmdataPreDxCntrl <- subset(mydataset ,  ((Status == 'control') |(Status == 'case' & diagnosticinterval >0.0) ) & FeatureID == 'epm')
epmdataDxCntrl    <- subset(mydataset ,  ((Status == 'case' & diagnosticinterval == 0.0) |  (Status == 'control'))  & FeatureID == 'epm')

print( 'DX summary' )
print( length(unique(epmdataDx$ptid)) )
print( 'Dx lesion summary' )
print( table(epmdataDx$LabelID))
print( 'pre Dx summary' )
print( length(unique(epmdataPreDx$ptid)))
print( 'pre Dx lesion summary' )
print( table(epmdataPreDx$LabelID))
print( 'control summary' )
print( length(unique(epmdataCntrl$ptid)))
print( 'pre Dx Cntrl summary' )
print( length(unique(epmdataPreDxCntrl$ptid)))
print( 'Dx control summary' )
print( length(unique(epmdataDxCntrl$ptid)))

# The `pROC' package implements various AUC functions.
# Calculate the Area Under the Curve (AUC).
myrocepm3   = pROC::roc( response = ifelse(epmdataCase$LabelID == 3,1,0), predictor = epmdataCase$Mean  , curve=T   )
myrocepm5   = pROC::roc( response = ifelse(epmdataCase$LabelID == 5,1,0), predictor = epmdataCase$Mean  , curve=T   )

png('myrocepm5.png');   plot(myrocepm5  ,main=sprintf("ROC curve EPM LR5/LR3&LR4\nAUC=%0.3f", myrocepm5$auc)); dev.off()
png('myrocepm3.png');   plot(myrocepm3  ,main=sprintf("ROC curve EPM LR3/LR4&LR5\nAUC=%0.3f", myrocepm3$auc)); dev.off()

## 
## cbind(mydataset$InstanceUID,mydataset$LabelID, mydataset$countlr5, mydataset$compsize, mydataset$countlr5  / mydataset$compsize,mydataset$truth,ifelse(mydataset$truth == 5,1,0))
## # Calculate the AUC Confidence Interval.
## #pROC::ci.auc( ifelse(mydataset$truth == 5,1,0), mydataset$predict5  )
## #pROC::ci.auc( ifelse(mydataset$truth == 5,1,0), mydataset$countlr5  / mydataset$compsize)
## 
## pROC::roc.test(myroc3a   , myrocepm3   , method='bootstrap'   )
## pROC::roc.test(myroc5a   , myrocepm5   , method='bootstrap'   )
## pROC::roc.test(myrocsuba , myrocepmsub , method='bootstrap'   )
## 
## 
## png('myroc3a.png');     plot(myroc3a    ,main=sprintf("ROC curve NN LR3/LR4&LR5 \nAUC=%0.3f", myroc3a$auc)); dev.off()
## png('myroc5a.png');     plot(myroc5a    ,main=sprintf("ROC curve NN LR5/LR3&LR4 \nAUC=%0.3f", myroc5a$auc)); dev.off()
## #png('myroc5b.png');     plot(myroc5b    ,main=sprintf("ROC curve bLR5/not-LR5   \nAUC=%0.3f", myroc5b$auc)); dev.off()
## png('myrocepmsub.png'); plot(myrocepmsub,main=sprintf("ROC curve EPM LR3/LR5    \nAUC=%0.3f", myrocepmsub$auc)); dev.off()
## png('myrocsuba.png');   plot(myrocsuba  ,main=sprintf("ROC curve NN  LR3/LR5    \nAUC=%0.3f", myrocsuba$auc)); dev.off()
## #png('myrocsubb.png');   plot(myrocsubb  ,main=sprintf("ROC curve NN  LR3/LR5    \nAUC=%0.3f", myrocsubb$auc)); dev.off()
