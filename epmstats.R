#Confusion matrices: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L688
#For “plotting” the tables you can use the xtable package to automatically TeX format them as they print https://www.rdocumentation.org/packages/xtable/versions/1.8-4/topics/xtable
 
#ROC plots: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L751
#PR plot: https://github.com/EGates1/RadPath/blob/master/Code/GradePreds.R#L761
library(caret)
options(width=135)

graphics.off()

# Rscript epmstats.R
# source('epmstats.R')
fname <- "epmstats/widejoin.csv" 
rawdataset <- read.csv(fname, na.strings=c(".", "NA", "", "?"), strip.white=TRUE, encoding="UTF-8")
myrawsubset  <- subset(rawdataset ,                                               LabelID > 2 )

qadatafiles=paste0("bcmdata/",myrawsubset$UID,"/reviewsolution.txt")
qadatainfo <- rep(NA,length(qadatafiles))
for (iii in 1:length(qadatafiles))
{
 if(file.exists(qadatafiles[iii]))
 {
  qadatainfo[iii]<- paste(readLines(qadatafiles[iii]), collapse=" ")
 }
}
mydatasetwithqa = cbind(myrawsubset , QA=qadatainfo)
mydataset <- subset(mydatasetwithqa , QA=='Usable' )
write.csv(mydataset ,"hassan.csv", row.names = FALSE)

# summary stats
print( 'unique patients' )
uniqueptid = unique(mydataset$ptid) 
print( uniqueptid )

# kfold data
folds <- createFolds(uniqueptid , 5)
is_train <- lapply(folds, function(ind, n) !(1:n %in% ind), n = length(uniqueptid ))

# subset data
epmdata      <- subset(mydataset ,                                               FeatureID == 'epm')
epmdataDx    <- subset(mydataset , Status == 'case' &  diagnosticinterval ==0.0 & FeatureID == 'epm')
epmdataPreDx <- subset(mydataset , Status == 'case' &  diagnosticinterval >0.0  & FeatureID == 'epm')
epmdataCase  <- subset(mydataset , Status == 'case' & FeatureID == 'epm')
epmdataCntrl <- subset(mydataset , Status == 'control' & FeatureID == 'epm')
epmdataPreDxCntrl <- subset(mydataset , LabelID != 5  &  ((Status == 'control') |(Status == 'case' & diagnosticinterval >0.0) ) & FeatureID == 'epm')
epmdataDxCntrl    <- subset(mydataset , LabelID != 3  &  ((Status == 'case'     & diagnosticinterval == 0.0) |  (Status == 'control'))  & FeatureID == 'epm')
epmdataBackground <- subset(mydataset ,  LabelID == 6  & FeatureID == 'epm')
epmdataBackgroundCase    <- subset(mydataset , Status == 'case'    & LabelID == 6  & FeatureID == 'epm')
epmdataBackgroundControl <- subset(mydataset , Status == 'control' & LabelID == 6  & FeatureID == 'epm')
mean(epmdataBackgroundCase$Mean)
mean(epmdataBackgroundControl$Mean)
epmdataLR3Background <- subset(mydataset ,  (LabelID == 3 |LabelID == 6)  & FeatureID == 'epm')
epmdataLR4Background <- subset(mydataset ,  (LabelID == 4 |LabelID == 6)  & FeatureID == 'epm')
epmdataLR5Background <- subset(mydataset ,  (LabelID == 5 |LabelID == 6)  & FeatureID == 'epm')
resBackground <- wilcox.test(Mean ~ Status , data = epmdataBackground    , exact = FALSE)
LR3Background <- wilcox.test(Mean ~ LabelID, data = epmdataLR3Background , exact = FALSE)
LR4Background <- wilcox.test(Mean ~ LabelID, data = epmdataLR4Background , exact = FALSE)
LR5Background <- wilcox.test(Mean ~ LabelID, data = epmdataLR5Background , exact = FALSE)
aggregate(epmdata$Mean, list(epmdata$LabelID), FUN=mean)
print( 'Background EPM' )
cat( mean(epmdataBackgroundCase$Mean),sd(epmdataBackgroundCase$Mean), '\n')
cat( mean(epmdataBackgroundControl$Mean),sd(epmdataBackgroundControl$Mean), '\n')
print(resBackground )
print(LR3Background )
print(LR4Background )
print(LR5Background )

epmdataThresholdDx    <- subset(mydataset, ((Status == 'case' & LabelID < 6& diagnosticinterval ==0.0 ) | (Status == 'control')) & FeatureID == 'epm')
epmdataThresholdPreDx <- subset(mydataset, ((Status == 'case' & LabelID < 6& diagnosticinterval > 0.0 ) | (Status == 'control')) & FeatureID == 'epm')

# subset data
artdata      <- subset(mydataset ,                                               FeatureID == 'art')
artdataDx    <- subset(mydataset , Status == 'case' & diagnosticinterval ==0.0 & FeatureID == 'art')
artdataPreDx <- subset(mydataset , Status == 'case' & diagnosticinterval >0.0  & FeatureID == 'art')
artdataCase  <- subset(mydataset , Status == 'case' & FeatureID == 'art')
artdataCntrl <- subset(mydataset , Status == 'control' & FeatureID == 'art')
artdataPreDxCntrl <- subset(mydataset ,  ((Status == 'control') |(Status == 'case' & diagnosticinterval >0.0) ) & FeatureID == 'art')
artdataDxCntrl    <- subset(mydataset ,  ((Status == 'case' & diagnosticinterval == 0.0) |  (Status == 'control'))  & FeatureID == 'art')

# subset data
vendata      <- subset(mydataset ,                                               FeatureID == 'ven')
vendataDx    <- subset(mydataset , Status == 'case' & diagnosticinterval ==0.0 & FeatureID == 'ven')
vendataPreDx <- subset(mydataset , Status == 'case' & diagnosticinterval >0.0  & FeatureID == 'ven')
vendataCase  <- subset(mydataset , Status == 'case' & FeatureID == 'ven')
vendataCntrl <- subset(mydataset , Status == 'control' & FeatureID == 'ven')
vendataPreDxCntrl <- subset(mydataset ,  ((Status == 'control') |(Status == 'case' & diagnosticinterval >0.0) ) & FeatureID == 'ven')
vendataDxCntrl    <- subset(mydataset ,  ((Status == 'case' & diagnosticinterval == 0.0) |  (Status == 'control'))  & FeatureID == 'ven')

print( 'DX summary' )
print( length(unique(epmdataDx$ptid)) )
print( 'Dx lesion summary' )
print( table(epmdataDx$LabelID))
print( 'DX summary' )
dxtmp = subset(epmdataDxCntrl , Status == 'case')
print( length(unique(dxtmp$ptid)) )
print( 'Dx lesion summary' )
print( table(dxtmp$LabelID))

print( 'pre Dx summary' )
print( length(unique(epmdataPreDx$ptid)))
print( 'pre Dx lesion summary' )
print( table(epmdataPreDx$LabelID))
print( 'pre Dx summary' )
predxtmp = subset(epmdataPreDxCntrl , Status == 'case')
print( length(unique(predxtmp $ptid)))
print( 'pre Dx lesion summary' )
print( table(predxtmp $LabelID))

print( 'control summary' )
print( length(unique(epmdataCntrl$ptid)))
print( 'pre Dx Cntrl summary' )
print( length(unique(epmdataPreDxCntrl$ptid)))


print( 'Dx control summary' )
print( length(unique(epmdataDxCntrl$ptid)))

# Boxplot of EPM 
print( 'median EPM ' )
print(aggregate(epmdataPreDxCntrl$Mean, list(epmdataPreDxCntrl$LabelID), FUN=median))
print(aggregate(epmdataDxCntrl$Mean, list(epmdataDxCntrl$LabelID), FUN=median))
png('epmboxpredxcntrl.png'); boxplot(Mean~Status+LabelID,data=epmdataPreDxCntrl, main="Pre Dx vs Control", xlab="LI-RADS", ylab="EPM RMSD", names=c("LR3","","LR4","","Case","Cntl"), ylim = c(0, 1.5)) ; text(5.5, .5, 'background');dev.off()
png('epmboxdxcntrl.png');boxplot(Mean~Status+LabelID,data=epmdataDxCntrl, main="Dx vs Control", xlab="LI-RADS", ylab="EPM RMSD", names=c("LR4","","LR5","","Case","Cntl"), ylim = c(0, 1.5)) ; text(5.5, .5, 'background');dev.off()
png('epmboxcasecontrola.png');boxplot(Mean~LabelID,data=epmdata, main="Case vs Control", xlab="LI-RADS", ylab="EPM RMSD", names=c("LR3","LR4","LR5","Control")) ; dev.off()
png('epmboxcasecontrolb.png');boxplot(Mean~Status+LabelID,data=epmdata, main="Case vs Control", xlab="Status", ylab="EPM RMSD", names=c("LR3","","LR4","","LR5","","Case","Cntl")) ; text(7.5, .5, 'background'); dev.off()

# NN plot update
epmdataDxCntrlLesion = cbind(epmdataDxCntrl, lesionID = ifelse(epmdataDxCntrl$LabelID < 6  ,45,6))
epmdataPreDxCntrlLesion = cbind(epmdataPreDxCntrl, lesionID = ifelse(epmdataPreDxCntrl$LabelID < 6  ,34,6))
print( 'median EPM NN' )
print(aggregate(epmdataPreDxCntrlLesion$Mean, list(epmdataPreDxCntrlLesion$lesionID), FUN=median))
print(aggregate(epmdataDxCntrlLesion$Mean, list(epmdataDxCntrlLesion$lesionID), FUN=median))
png('epmboxdxcntrllesion.png'); boxplot(Mean~Status+lesionID,data=epmdataDxCntrlLesion, main="Dx vs Control", xlab="", ylab="EPM RMSD", names=c("Case","Cntl","lesion",""), ylim = c(0, 1.5)) ; text(1.5, .5, 'background');dev.off()
png('epmboxpredxcntrllesion.png'); boxplot(Mean~Status+lesionID,data=epmdataPreDxCntrlLesion, main="Pre Dx vs Control", xlab="", ylab="EPM RMSD", names=c("Case","Cntl","lesion",""),  ylim = c(0, 1.5)) ; text(1.5, .5, 'background');dev.off()

# Boxplot of ART 
png('artboxpredxcntrl.png'); boxplot(Mean~LabelID,data=artdataPreDxCntrl, main="Pre Dx vs Control", xlab="LI-RADS", ylab="ART") ; dev.off()
png('artboxdxcntrl.png');boxplot(Mean~LabelID,data=artdataDxCntrl, main="Dx vs Control", xlab="LI-RADS", ylab="ART") ; dev.off()
png('artboxcasecontrola.png');boxplot(Mean~LabelID,data=artdata, main="Case vs Control", xlab="LI-RADS", ylab="ART", names=c("LR3","LR4","LR5","Control")) ; dev.off()
png('artboxcasecontrolb.png');boxplot(Mean~Status+LabelID,data=artdata, main="Case vs Control", xlab="Status", ylab="ART") ; dev.off()

# Boxplot of VEN 
png('venboxpredxcntrl.png'); boxplot(Mean~LabelID,data=vendataPreDxCntrl, main="Pre Dx vs Control", xlab="LI-RADS", ylab="VEN") ; dev.off()
png('venboxdxcntrl.png');boxplot(Mean~LabelID,data=vendataDxCntrl, main="Dx vs Control", xlab="LI-RADS", ylab="VEN") ; dev.off()
png('venboxcasecontrola.png');boxplot(Mean~LabelID,data=vendata, main="Case vs Control", xlab="LI-RADS", ylab="VEN", names=c("LR3","LR4","LR5","Control")) ; dev.off()
png('venboxcasecontrolb.png');boxplot(Mean~Status+LabelID,data=vendata, main="Case vs Control", xlab="Status", ylab="VEN") ; dev.off()

res <- wilcox.test(Mean ~ Status, data = epmdata, exact = FALSE)

# The `pROC' package implements various AUC functions.
# Calculate the Area Under the Curve (AUC).
myrocepm3   = pROC::roc( response = ifelse(epmdataCase$LabelID == 3,1,0), predictor = epmdataCase$Mean  , curve=T   )
myrocepm5   = pROC::roc( response = ifelse(epmdataCase$LabelID == 5,1,0), predictor = epmdataCase$Mean  , curve=T   )
png('myrocepm5.png');   plot(myrocepm5  ,main=sprintf("ROC curve EPM LR5/LR3&LR4\nAUC=%0.3f", myrocepm5$auc)); dev.off()
png('myrocepm3.png');   plot(myrocepm3  ,main=sprintf("ROC curve EPM LR3/LR4&LR5\nAUC=%0.3f", myrocepm3$auc)); dev.off()

# evaluate optimal threshold for case/control
uniquecasecntlptidDx = unique(epmdataThresholdDx$ptid) 
epmdataThresholdDx$response = ifelse(epmdataThresholdDx$LabelID == 6,0,1)

uniquecasecntlptidPreDx = unique(epmdataThresholdPreDx$ptid) 
epmdataThresholdPreDx$response = ifelse(epmdataThresholdPreDx$LabelID == 6,0,1)

set.seed(2) 
# kfold data PreDx
nFolds = 5
casecntlfoldsPreDx <- createFolds(uniquecasecntlptidPreDx , nFolds )
casecntlSubgroupsPreDx = 1:length(uniquecasecntlptidPreDx )
casecntlSubgroupsPreDx[casecntlfoldsPreDx$Fold1] =  "Fold 1"
casecntlSubgroupsPreDx[casecntlfoldsPreDx$Fold2] =  "Fold 2"
casecntlSubgroupsPreDx[casecntlfoldsPreDx$Fold3] =  "Fold 3"
casecntlSubgroupsPreDx[casecntlfoldsPreDx$Fold4] =  "Fold 4"
casecntlSubgroupsPreDx[casecntlfoldsPreDx$Fold5] =  "Fold 5"
dataframeuidmapPreDx  = data.frame(ptid=uniquecasecntlptidPreDx,casecntlSubgroupsPreDx)
epmdataCaseCntlPreDx = merge(x = epmdataThresholdPreDx, y = dataframeuidmapPreDx  , by = "ptid", all.x = TRUE)
write.csv(epmdataCaseCntlPreDx ,"logisticpre.csv", row.names = FALSE)

# nfold statistics
length(casecntlfoldsPreDx$Fold1)
length(casecntlfoldsPreDx$Fold1)/ length(uniquecasecntlptidPreDx )
nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 1' & Status == 'case'   ))
nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 1' & Status == 'control'))
length(casecntlfoldsPreDx$Fold2)
length(casecntlfoldsPreDx$Fold2)/ length(uniquecasecntlptidPreDx )
nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 2' & Status == 'case'   ))
nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 2' & Status == 'control'))
length(casecntlfoldsPreDx$Fold3)
length(casecntlfoldsPreDx$Fold3)/ length(uniquecasecntlptidPreDx )
nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 3' & Status == 'case'   ))
nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 3' & Status == 'control'))
length(casecntlfoldsPreDx$Fold4)
length(casecntlfoldsPreDx$Fold4)/ length(uniquecasecntlptidPreDx )
nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 4' & Status == 'case'   ))
nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 4' & Status == 'control'))
length(casecntlfoldsPreDx$Fold5)
length(casecntlfoldsPreDx$Fold5)/ length(uniquecasecntlptidPreDx )
nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 5' & Status == 'case'   ))
nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 5' & Status == 'control'))

# avg percentage in each fold
(length(casecntlfoldsPreDx$Fold1)/ length(uniquecasecntlptidPreDx ) + length(casecntlfoldsPreDx$Fold2)/ length(uniquecasecntlptidPreDx ) + length(casecntlfoldsPreDx$Fold3)/ length(uniquecasecntlptidPreDx ) + length(casecntlfoldsPreDx$Fold4)/ length(uniquecasecntlptidPreDx ) + length(casecntlfoldsPreDx$Fold5)/ length(uniquecasecntlptidPreDx ))/5.

# avg case in each fold
( nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 1' & Status == 'case'   )) + nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 2' & Status == 'case'   )) + nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 3' & Status == 'case'   )) + nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 4' & Status == 'case'   )) + nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 5' & Status == 'case'   ))   ) /5.
# avg control in each fold
( nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 1' & Status == 'control'   )) + nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 2' & Status == 'control'   )) + nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 3' & Status == 'control'   )) + nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 4' & Status == 'control'   )) + nrow(subset(epmdataCaseCntlPreDx,casecntlSubgroupsPreDx=='Fold 5' & Status == 'control'   ))   ) /5.

# https://www.statology.org/how-to-report-logistic-regression-results/#:~:text=We%20can%20use%20the%20following,%5D%20and%20%5Bresponse%20variable%5D.
# We can use the following general format to report the results of a logistic regression model:
# Logistic regression was used to analyze the relationship between [predictor variable 1], [predictor variable 2], … [predictor variable n] and [response variable].
# It was found that, holding all other predictor variables constant, the odds of [response variable] occurring [increased or decreased] by [some percent] (95% CI [Lower Limit, Upper Limit]) for a one -unit increase in [predictor variable 1].

# In a multivariable logistic regression model, adjusting for BMI, age, sex, and diabetes status, the association between EPM and HCC status is significant (OR=8.08e3;  95% CI: 1.41e2-4.61e5).
myinput  <- c("BMI", "Age", "Sex", "Diabetes",   "Mean")
myglm <- glm(response~ ., data=epmdataCaseCntlPreDx[c(myinput, "response")], family=binomial(link="logit"))
print(summary(myglm))
exp(myglm$coefficients['Mean'])
exp(myglm$coefficients['Mean']- 1.96* 2.063876)
exp(myglm$coefficients['Mean']+ 1.96* 2.063876)

library(cutpointr)
dfget_opt_ind <- function(roc_curve, oc, direction) {
    stopifnot(is.numeric(oc) | is.na(oc))
    sapply(oc, function(x) {
        if (direction == ">=") {
            opt_ind <- max(which(roc_curve$x.sorted >= x))
        } else if (direction == "<=") {
            opt_ind <- max(which(roc_curve$x.sorted <= x))
        }
        return(opt_ind)
    })
}

cpPreDx <- cutpointr(epmdataCaseCntlPreDx , Mean, response , subgroup = casecntlSubgroupsPreDx,method = maximize_metric, metric = sum_sens_spec)
print(summary(cpPreDx))
png('ROCcpPreDx.png'); plot_roc(cpPreDx);dev.off()

PreDx_summary <- vector("list", nFolds )
for (iii in 1:nFolds ) {
  oi <- dfget_opt_ind(cpPreDx$roc_curve[[iii]], oc = unlist(cpPreDx$optimal_cutpoint[iii]), direction = cpPreDx$direction[iii])
  PreDx_summary[[iii]]$confusion_matrix <- data.frame( cutpoint = unlist(cpPreDx$optimal_cutpoint[iii]), cpPreDx$roc_curve[[iii]][oi, c("tp", "fn", "fp", "tn")])
}

foldlengthPreDx = sapply(cpPreDx$data,nrow)
aggregateaccuracyPreDx = sum(cpPreDx$acc * foldlengthPreDx) / sum(foldlengthPreDx)

aggregatesensitivityPreDx = (
    PreDx_summary[[1]]$confusion_matrix$tp +
    PreDx_summary[[2]]$confusion_matrix$tp +
    PreDx_summary[[3]]$confusion_matrix$tp +
    PreDx_summary[[4]]$confusion_matrix$tp +
    PreDx_summary[[5]]$confusion_matrix$tp ) / (
    PreDx_summary[[1]]$confusion_matrix$tp + PreDx_summary[[1]]$confusion_matrix$fn +
    PreDx_summary[[2]]$confusion_matrix$tp + PreDx_summary[[2]]$confusion_matrix$fn +
    PreDx_summary[[3]]$confusion_matrix$tp + PreDx_summary[[3]]$confusion_matrix$fn +
    PreDx_summary[[4]]$confusion_matrix$tp + PreDx_summary[[4]]$confusion_matrix$fn +
    PreDx_summary[[5]]$confusion_matrix$tp + PreDx_summary[[5]]$confusion_matrix$fn 
                            ) 

aggregatespecificityPreDx = (
    PreDx_summary[[1]]$confusion_matrix$tn +
    PreDx_summary[[2]]$confusion_matrix$tn +
    PreDx_summary[[3]]$confusion_matrix$tn +
    PreDx_summary[[4]]$confusion_matrix$tn +
    PreDx_summary[[5]]$confusion_matrix$tn ) / (
    PreDx_summary[[1]]$confusion_matrix$tn + PreDx_summary[[1]]$confusion_matrix$fp +
    PreDx_summary[[2]]$confusion_matrix$tn + PreDx_summary[[2]]$confusion_matrix$fp +
    PreDx_summary[[3]]$confusion_matrix$tn + PreDx_summary[[3]]$confusion_matrix$fp +
    PreDx_summary[[4]]$confusion_matrix$tn + PreDx_summary[[4]]$confusion_matrix$fp +
    PreDx_summary[[5]]$confusion_matrix$tn + PreDx_summary[[5]]$confusion_matrix$fp 
                            ) 

cat("PreDx cutpoints = ",cpPreDx$optimal_cutpoint,"\n")
print(sprintf("PreDx acc = %f sensitivity = %f specifitity = %f",aggregateaccuracyPreDx, aggregatesensitivityPreDx , aggregatespecificityPreDx))

cpPreDxinsample <- cutpointr(epmdataCaseCntlPreDx , Mean, response , method = maximize_metric, metric = sum_sens_spec)
print(summary(cpPreDxinsample))
# get CI for auc
getpreaucci   = pROC::roc( response = epmdataCaseCntlPreDx$response, predictor = epmdataCaseCntlPreDx$Mean, curve=T , ci=TRUE  )
print(getpreaucci )

png('ROCcpPreDxinsample.png'); plot_roc(cpPreDxinsample);dev.off()

# kfold data Dx

casecntlfoldsDx <- createFolds(uniquecasecntlptidDx , nFolds )
casecntlSubgroupsDx = 1:length(uniquecasecntlptidDx )
casecntlSubgroupsDx[casecntlfoldsDx$Fold1] = "Fold 1"
casecntlSubgroupsDx[casecntlfoldsDx$Fold2] = "Fold 2"
casecntlSubgroupsDx[casecntlfoldsDx$Fold3] = "Fold 3"
casecntlSubgroupsDx[casecntlfoldsDx$Fold4] = "Fold 4"
casecntlSubgroupsDx[casecntlfoldsDx$Fold5] = "Fold 5"
dataframeuidmapDx  = data.frame(ptid=uniquecasecntlptidDx,casecntlSubgroupsDx)
epmdataCaseCntlDx = merge(x = epmdataThresholdDx, y = dataframeuidmapDx  , by = "ptid", all.x = TRUE)

# avg percentage in each fold
(length(casecntlfoldsDx$Fold1)/ length(uniquecasecntlptidDx ) + length(casecntlfoldsDx$Fold2)/ length(uniquecasecntlptidDx ) + length(casecntlfoldsDx$Fold3)/ length(uniquecasecntlptidDx ) + length(casecntlfoldsDx$Fold4)/ length(uniquecasecntlptidDx ) + length(casecntlfoldsDx$Fold5)/ length(uniquecasecntlptidDx ))/5.

# avg case in each fold
( nrow(subset(epmdataCaseCntlDx,casecntlSubgroupsDx=='Fold 1' & Status == 'case'   )) + nrow(subset(epmdataCaseCntlDx,casecntlSubgroupsDx=='Fold 2' & Status == 'case'   )) + nrow(subset(epmdataCaseCntlDx,casecntlSubgroupsDx=='Fold 3' & Status == 'case'   )) + nrow(subset(epmdataCaseCntlDx,casecntlSubgroupsDx=='Fold 4' & Status == 'case'   )) + nrow(subset(epmdataCaseCntlDx,casecntlSubgroupsDx=='Fold 5' & Status == 'case'   ))   ) /5.
# avg control in each fold
( nrow(subset(epmdataCaseCntlDx,casecntlSubgroupsDx=='Fold 1' & Status == 'control'   )) + nrow(subset(epmdataCaseCntlDx,casecntlSubgroupsDx=='Fold 2' & Status == 'control'   )) + nrow(subset(epmdataCaseCntlDx,casecntlSubgroupsDx=='Fold 3' & Status == 'control'   )) + nrow(subset(epmdataCaseCntlDx,casecntlSubgroupsDx=='Fold 4' & Status == 'control'   )) + nrow(subset(epmdataCaseCntlDx,casecntlSubgroupsDx=='Fold 5' & Status == 'control'   ))   ) /5.


# adjust for covariates
# https://www.statology.org/how-to-report-logistic-regression-results/#:~:text=We%20can%20use%20the%20following,%5D%20and%20%5Bresponse%20variable%5D.
# In a multivariable logistic regression model, adjusting for BMI, age, sex, and diabetes status, the association between EPM and HCC status is significant (OR=2.91e5;  95% CI: 2.81e2- 3.02e7).

myglmdx <- glm(response~ ., data=epmdataCaseCntlDx[c(myinput, "response")], family=binomial(link="logit"))
print(summary(myglmdx ))
exp(myglmdx$coefficients['Mean'])
exp(myglmdx$coefficients['Mean']- 1.96* 2.368484)
exp(myglmdx$coefficients['Mean']+ 1.96* 2.368484)


cpDx <- cutpointr(epmdataCaseCntlDx , Mean, response , subgroup = casecntlSubgroupsDx,method = maximize_metric, metric = sum_sens_spec)
print( summary(cpDx))
png('ROCcpDx.png'); plot_roc(cpDx);dev.off()

Dx_summary <- vector("list", nFolds )
for (iii in 1:nFolds ) {
  oi <- dfget_opt_ind(cpDx$roc_curve[[iii]], oc = unlist(cpDx$optimal_cutpoint[iii]), direction = cpDx$direction[iii])
  Dx_summary[[iii]]$confusion_matrix <- data.frame( cutpoint = unlist(cpDx$optimal_cutpoint[iii]), cpDx$roc_curve[[iii]][oi, c("tp", "fn", "fp", "tn")])
}

foldlengthDx = sapply(cpDx$data,nrow)
aggregateaccuracyDx = sum(cpDx$acc * foldlengthDx) / sum(foldlengthDx)

aggregatesensitivityDx = (
    Dx_summary[[1]]$confusion_matrix$tp +
    Dx_summary[[2]]$confusion_matrix$tp +
    Dx_summary[[3]]$confusion_matrix$tp +
    Dx_summary[[4]]$confusion_matrix$tp +
    Dx_summary[[5]]$confusion_matrix$tp ) / (
    Dx_summary[[1]]$confusion_matrix$tp + Dx_summary[[1]]$confusion_matrix$fn +
    Dx_summary[[2]]$confusion_matrix$tp + Dx_summary[[2]]$confusion_matrix$fn +
    Dx_summary[[3]]$confusion_matrix$tp + Dx_summary[[3]]$confusion_matrix$fn +
    Dx_summary[[4]]$confusion_matrix$tp + Dx_summary[[4]]$confusion_matrix$fn +
    Dx_summary[[5]]$confusion_matrix$tp + Dx_summary[[5]]$confusion_matrix$fn 
                            ) 

aggregatespecificityDx = (
    Dx_summary[[1]]$confusion_matrix$tn +
    Dx_summary[[2]]$confusion_matrix$tn +
    Dx_summary[[3]]$confusion_matrix$tn +
    Dx_summary[[4]]$confusion_matrix$tn +
    Dx_summary[[5]]$confusion_matrix$tn ) / (
    Dx_summary[[1]]$confusion_matrix$tn + Dx_summary[[1]]$confusion_matrix$fp +
    Dx_summary[[2]]$confusion_matrix$tn + Dx_summary[[2]]$confusion_matrix$fp +
    Dx_summary[[3]]$confusion_matrix$tn + Dx_summary[[3]]$confusion_matrix$fp +
    Dx_summary[[4]]$confusion_matrix$tn + Dx_summary[[4]]$confusion_matrix$fp +
    Dx_summary[[5]]$confusion_matrix$tn + Dx_summary[[5]]$confusion_matrix$fp 
                            ) 

cat("Dx cutpoints = ",cpDx$optimal_cutpoint,"\n")
print( sprintf("Dx acc = %f sensitivity = %f specifitity = %f",aggregateaccuracyDx, aggregatesensitivityDx , aggregatespecificityDx))

cpDxinsample <- cutpointr(epmdataCaseCntlDx , Mean, response , method = maximize_metric, metric = sum_sens_spec)
print(summary(cpDxinsample ))
# get CI for auc
getaucci   = pROC::roc( response = epmdataCaseCntlDx$response, predictor = epmdataCaseCntlDx$Mean, curve=T , ci=TRUE  )
print(getaucci )
png('ROCcpDxinsample.png'); plot_roc(cpDxinsample );dev.off()
