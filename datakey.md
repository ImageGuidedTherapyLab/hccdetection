
## Data Key 
  * Phase ID from  [SQL Query](https://github.com/ImageGuidedTherapyLab/hccdetection/blob/master/wide.sql#L9) of series description
  *  \*__BCM%04d%03d__\*: patient number, study number
  *  \*__Case%d%HCC__\*: patient number, diagnostic image
  *  \*__Case%d%Pre__\*: patient number, pre-diagnostic image
  *  \*__Control%d__\*: patient number, control study
  *  \*__Pre__\*: pre-contrast      
  *  \*__Art__\*: arterial phase    
  *  \*__Ven__\*: venous phase      
  *  \*__Del__\*: delayed phase     
  *  \*__Pst__\*: post-contrast     
  *  \*__fixed__\*: The arterial image at diagnosis data (cases) or time point 0 (controls) is used as the fixed image for longitudinal registration 
  *  \*.raw.nii.gz        : raw data
  *  \*.normalize.nii.gz  : z-score
  *  \*.256.nii.gz        : z-score and resample to 256x256 
  *  \*.longregcc.nii.gz  : bias corrected, resample to original resolution of arterial image at diagnosis date (cases) or  time point 0 (controls)
  *  \*.liver.nii.gz      : densenet3d segmentation of the liver
