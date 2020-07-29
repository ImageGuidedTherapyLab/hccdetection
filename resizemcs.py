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
parser.add_option( "--datatype",
                  action="store", dest="datatype", default='float',
                  help="datatype output", metavar="FILE")
parser.add_option( "--interpolation",
                  action="store", dest="interpolation", default='linear',
                  help="resampling option", metavar="INT")
(options, args) = parser.parse_args()

if (options.imagefile != None and options.output != None ):
  interplationdict = {'linear':1,'nearest':0}
  # Data set with a valid size for 3-D U-Net (multiple of 8)
  pyimg = nib.load(options.imagefile)
  cropoutput = options.output
  resample256output = options.output.replace('crop','256')
  resample512output = options.output.replace('crop','512')
  print(cropoutput,resample256output, resample512output )
  print(pyimg.shape )
  cropind = map(lambda x : x/8 * 8, pyimg.shape )
  cropcmd = 'c3d -verbose -mcs %s  -info -foreach -region 0x0x0vox %dx%dx%dvox -info -type %s -endfor -omc %s  ' % (options.imagefile, cropind[0],cropind[1],cropind[2],options.datatype,cropoutput )
  print( cropcmd )
  os.system( cropcmd )

  resample256cmd = 'c3d -verbose -mcs %s  -info -foreach -interpolation %d -resample 256x256x%d -type %s -info -endfor -omc %s ' % (cropoutput,interplationdict[options.interpolation], cropind[2], options.datatype, resample256output )
  print(resample256cmd )
  os.system(resample256cmd)

  resample512cmd = 'c3d -verbose -mcs %s  -info -foreach -interpolation %d -resample 512x512x%d -type %s -info -endfor -omc %s ' % (cropoutput,interplationdict[options.interpolation], cropind[2], options.datatype, resample512output )
  print(resample512cmd )
  os.system(resample512cmd)
