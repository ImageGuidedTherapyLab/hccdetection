import subprocess
from scipy import ndimage
import nibabel as nib
import numpy as np
import os

# raw dicom data is usually short int (2bytes) datatype
# labels are usually uchar (1byte)
IMG_DTYPE = np.int16
SEG_DTYPE = np.uint8

# setup command line parser to control execution
from optparse import OptionParser
parser = OptionParser()
parser.add_option( "--imagefile",
                  action="store", dest="imagefile", default=None,
                  help="FILE containing image info", metavar="FILE")
parser.add_option( "--labelfile",
                  action="store", dest="labelfile", default=None,
                  help="FILE containing image info", metavar="FILE")
parser.add_option( "--output",
                  action="store", dest="output", default=None,
                  help="FILE output", metavar="FILE")
(options, args) = parser.parse_args()


if (options.imagefile != None and options.labelfile != None and options.output != None ):
    # load nifti file
    imagedata = nib.load(options.imagefile)
    numpyimage= imagedata.get_data().astype(IMG_DTYPE )

    # load nifti file
    truthdata = nib.load(options.labelfile )
    numpytruth= truthdata.get_data().astype(SEG_DTYPE)

    # error check
    assert numpyimage.shape == numpytruth.shape

    # bounding box for each label
    if( np.max(numpytruth) ==1 ) :
      (liverboundingbox,)  = ndimage.find_objects(numpytruth)
      tumorboundingbox  = None
    else:
      boundingboxes = ndimage.find_objects(numpytruth)
      liverboundingbox = boundingboxes[0]

    print(imagedata.shape,numpytruth.shape,liverboundingbox  )
    npimagebb = numpyimage[:,:, liverboundingbox[2] ]
    nptruthbb = numpyimage[:,:, liverboundingbox[2] ]

    imagebbcmd = 'c3d -verbose %s -dup %s -info -copy-transform -info -binarize -multiply -info -region 0x0x%dvox %dx%dx%dvox -info -type short -o %s/image.nii  ' % (options.imagefile, options.labelfile, int(liverboundingbox[2].start), imagedata.shape[0],imagedata.shape[1],int(liverboundingbox[2].stop-liverboundingbox[2].start),options.output )
    labelbbcmd = 'c3d -verbose %s -replace 1 0 2 1 -info -region 0x0x%dvox %dx%dx%dvox -info -type uchar -o %s/label.nii  ' % (options.labelfile, int(liverboundingbox[2].start), imagedata.shape[0],imagedata.shape[1],int(liverboundingbox[2].stop-liverboundingbox[2].start),options.output )
    print(imagebbcmd )
    os.system(imagebbcmd )
    print(labelbbcmd )
    os.system(labelbbcmd )
else:
  parser.print_help()
  print (options)
 
