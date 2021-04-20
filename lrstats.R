fname <- "qastats/wide.csv" 

mydataset <- read.csv(fname, na.strings=c(".", "NA", "", "?"), strip.white=TRUE, encoding="UTF-8")

# The `pROC' package implements various AUC functions.

# Calculate the Area Under the Curve (AUC).

myroc = pROC::roc( mydataset$truth, mydataset$predict5  , curve=T   )

# Calculate the AUC Confidence Interval.

pROC::ci.auc( mydataset$truth, mydataset$predict5  )

plot(myroc)

