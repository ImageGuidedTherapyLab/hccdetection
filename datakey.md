
## Data Key 
  * Phase ID from  [SQL Query](https://github.com/ImageGuidedTherapyLab/hccdetection/blob/master/wide.sql#L9) of series description
  *  \*__Pre__\*: pre-contrast      
  *  \*__Art__\*: arterial phase    
  *  \*__Ven__\*: venous phase      
  *  \*__Del__\*: delayed phase     
  *  \*__Pst__\*: post-contrast     
  *  \*__fixed__\*: The arterial image at time point 0 is used as the fixed image for longitudinal registration 
  *  \*.raw.nii.gz        : raw data
  *  \*.normalize.nii.gz  : z-score
  *  \*.256.nii.gz        : z-score and resample to 256x256 
  *  \*.longregcc.nii.gz  : z-score, resample to 256x256 , register to arterial image at time point 0
  *  \*.regcc.nii.gz      : z-score, resample to 256x256 , register within study to Arterial
  *  \*/label.nii.gz       : densenet3d segmentation of the liver
