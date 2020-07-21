import nibabel as nib
import os

# setup command line parser to control execution
from optparse import OptionParser
parser = OptionParser()
parser.add_option( "--imagefile",
                  action="store", dest="imagefile", default=None,
                  help="FILE containing image info", metavar="FILE")
parser.add_option( "--output",
                  action="store", dest="output", default=None,
                  help="FILE output", metavar="FILE")
(options, args) = parser.parse_args()

if (options.imagefile != None and options.output != None ):
  # Data set with a valid size for 3-D U-Net (multiple of 8)
  pyimg = nib.load(options.imagefile)
  print(pyimg.shape )
  cropind = map(lambda x : x/8 * 8, pyimg.shape )
  rescalecmd = 'c3d -verbose %s  -region 0x0x0vox %dx%dx%dvox -type float -o %s ' % (options.imagefile, cropind[0],cropind[1],cropind[2],options.output )
  os.system( rescalecmd )
  verifyrescalecmd = 'c3d %s -info  ' % (options.output )
  print(verifyrescalecmd )
  os.system( verifyrescalecmd  )
