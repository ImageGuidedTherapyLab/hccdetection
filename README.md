
Export slicer DB as nifti 
==============
vglrun /opt/apps/slicer/Slicer-4.10.2-linux-amd64/Slicer --no-main-window --python-script ./anonymize.py


Matlab example 
==============

https://www.mathworks.com/help/images/segment-3d-brain-tumor-using-deep-learning.html


# Usage

## convert dicome to nifti and anonymize data

make art truth

make anon


## preprocess - intensity normalize  

make scaled

## preprocess - resize - Data set with a valid size for 3-D U-Net is multiple of 8

make resize

## preprocess - python code is used to setup the kfold fold  
## preprocess - each fold is configured with a json file to be read by matlab

python setupmodel.py --databaseid=hccmri --initialize
python setupmodel.py --databaseid=hccmri --setuptestset

## train models

matlab livermodel.m

## apply NN to test set

make mask

## evaluate accuracy

make overlap

# detection 

make -f methodist.makefile -j 4 rawmethodist resizemth

# matlab code structure

ImageSegmentationBaseClass.m  - ABC defining the interface
ImageSegmentationDeepMedic.m  - derived class for deep medic architecture
ImageSegmentationDensenet2D.m - derived class for Densenet2D architecture
ImageSegmentationDensenet3D.m - derived class for Densenet3D architecture
ImageSegmentationUnet2D.m     - derived class for Unet2D     architecture
ImageSegmentationUnet3D.m     - derived class for Unet3D     architecture


hccmriunet3d.m - derived class using the 3d unet to segment hcc on mri
hccmriunet2d.m - derived class using the 2d unet to segment hcc on mri
