import med_seg_metrics as ms
import os
uidlist = os.listdir('Processed')

for myuid in uidlist:
   try:
      ms.HausdorffDistance('Processed/%d/scaled/256/densenet3d/run_a/label.nii.gz' % int(myuid),'Processed/%d/scaled/256/densenet3d/run_a/liver.nii.gz' % int(myuid),'95')
   except ValueError:
      print(myuid, 'is not an int')
   except RuntimeError:
      print(myuid, 'fail...')



