#python hd95driver.py > hd95.csv
import med_seg_metrics as ms
import os
uidlist = os.listdir('Processed')

for myuid in uidlist:
   try:
      cpheadercmd = 'c3d Processed/%d/256/Truth.nii Processed/%d/scaled/256/densenet3d/run_a/liver.nii.gz -copy-transform -o Processed/%d/scaled/256/densenet3d/run_a/liverheader.nii.gz' % (int(myuid),int(myuid),int(myuid))
      #print(cpheadercmd)
      os.system(cpheadercmd)
      myHD = ms.HausdorffDistance('Processed/%d/256/Truth.nii' % int(myuid),'Processed/%d/scaled/256/densenet3d/run_a/liverheader.nii.gz' % int(myuid),'95')
      print(myuid,',',myHD)
   except ValueError:
      print(myuid, 'notAnInt')
   except RuntimeError:
      print(myuid, 'fail')

