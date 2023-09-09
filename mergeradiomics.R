
# source('mergeradiomics.R')
options(width=160)
datFull3 <- read.csv('radiomicsout3.csv')
datFull4 <- read.csv('radiomicsout4.csv')
datFull5 <- read.csv('radiomicsout5.csv')
datFull6 <- read.csv('radiomicsout6.csv')

datFull <- rbind( datFull3 , datFull4 , datFull5 , datFull6 )
datFullsubset <- datFull[!is.na(datFull$diagnostics_Mask.original_VoxelNum),]
datFullsubset = cbind(datFullsubset, status = ifelse(datFullsubset$Label < 6  ,'case','control'))

nrow(datFull       )
nrow(datFullsubset )
write.csv(datFullsubset ,'radiomicsout.csv'       )
