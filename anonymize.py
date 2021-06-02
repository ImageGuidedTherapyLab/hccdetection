from __main__ import slicer
import os
from datetime import datetime
import uuid
import csv
import random

# -------------------------------------------
# Remove this block to generate different
# UUIDs everytime you run this code.
# This block should be right below the uuid
# import.
rd = random.Random()
rd.seed(0)
uuid.uuid4 = lambda: uuid.UUID(int=rd.getrandbits(128))
# -------------------------------------------



def days_between(d1, d2):
    d1 = datetime.strptime(d1, "%Y%m%d")
    d2 = datetime.strptime(d2, "%Y%m%d")
    return abs((d2 - d1).days)


tags = {}
tags['seriesInstanceUID'] = "0020,000E"
tags['seriesDescription'] = "0008,103E"
tags['seriesModality'] = "0008,0060"
tags['studyInstanceUID'] = "0020,000D"
tags['studyDescription'] = "0008,1030"
tags['studyDate'] = "0008,0020"
tags['studyTime'] = "0008,0030"
tags['patientID'] = "0010,0020"
tags['patientName'] = "0010,0010"
tags['patientSex'] = "0010,0040"
tags['patientBirthDate'] = "0010,0030"


db = slicer.dicomDatabase
print(db.databaseFilename)

patientDict = {}
studyDict = {}
fileDict = {}

with open('datakey.csv', 'w') as csvfile:
  csvwrite = csv.writer(csvfile, delimiter='\t', quotechar='|', quoting=csv.QUOTE_MINIMAL)
  fileHeader =  ['PatientID','Study','StudyDate','Series','dcmfile','HCCDate','DiagnosticInterval','StudyNumber','PatientNumber','SeriesDescription','SeriesModality','seriesanonuid','niftifile']
  csvwrite.writerow(fileHeader )

  for patientnumber in db.patients():
    studyList = []
    # TODO - is the idstudy chronological ? 
    for idstudy,study in enumerate(db.studiesForPatient(patientnumber)):
      for series in db.seriesForStudy(study):
        serieslist = [myfile for myfile in db.filesForSeries(series)]
        seriesDescription = slicer.dicomDatabase.fileValue(serieslist[0],tags['seriesDescription'])
        patientID = slicer.dicomDatabase.fileValue(serieslist[0],tags['patientID'])
        seriesModality= slicer.dicomDatabase.fileValue(serieslist[0],tags['seriesModality'])
        studyDate= slicer.dicomDatabase.fileValue(serieslist[0],tags['studyDate'])
        diagnosistimedifference = days_between('20000101',studyDate )
        seriesanonuid = uuid.uuid4()
        patientDict[patientnumber] = {'mrn':patientID }
        studyDict [study]  = studyDate
        niftifile = 'BCM%04d%03d/%s.nii.gz' % (int(patientnumber) ,idstudy,seriesanonuid )
        fileDict[seriesanonuid] = {'PatientID':patientID,'Study':study,'StudyDate':studyDate,'Series':series,'dcmfile':serieslist[0],'HCCDate':'FIXME','DiagnosticInterval':'FIXME','StudyNumber':idstudy,'PatientNumber':patientnumber ,'SeriesDescription':seriesDescription.encode('utf-8'),'SeriesModality':seriesModality,'seriesanonuid':seriesanonuid, 'niftifile':niftifile   }
        print  fileDict[seriesanonuid]
        csvwrite.writerow( [ fileDict[seriesanonuid][headerID] for headerID in fileHeader] )
      studyList.append((study,studyDate,idstudy )) 
    if( len(studyList) > 0 ):
      patientDict[patientnumber]['studyList'] = studyList

import re
triphasicCT = re.compile('.*lava.*|.*thr.*|.*vibe.*', re.IGNORECASE)
# print triphasicCT.match('t1_vibe_fs_tra_bh_ Pre')
# print triphasicCT.match('t1_vibe_fs_tra_bh_Arterial')
# print triphasicCT.match('t1_vibe_fs_tra_bh_30 sect')
# print triphasicCT.match('t1_vibe_fs_tra_bh_60 sect')
# print triphasicCT.match('3D_Thr_Pre')
# print triphasicCT.match('3D_Thr_Art')
# print triphasicCT.match('3D_Thr_Port')
# print triphasicCT.match('Ph1/Ax LAVA Multiphase BH Asset')
# print triphasicCT.match('Ph2/Ax LAVA Multiphase BH Asset')
# print triphasicCT.match('Ph3/Ax LAVA Multiphase BH Asset')
# print triphasicCT.match('Ax LAVA BH  DELAY')
# print triphasicCT.match('WATER: AX LAVA-FLEX MULTIPHASE +C ACR')

#for key,value in fileDict.items():
#  if ( value['SeriesModality'] == 'MR'):
#    node=slicer.util.loadVolume(value['dcmfile'],returnNode=True);
#    print(node)
#    # TODO - note full path output directory
#    outputdir = '/rsrch3/ip/dtfuentes/github/hccdetection/tmpconvert/BCM%04d%03d/' % (int(value['PatientNumber']) ,value['StudyNumber'])
#    print( outputdir )
#    os.system('mkdir -p %s ' % outputdir  )
#    if(node[1] != None):
#      slicer.util.saveNode(node[1], '%s/%s.nii.gz' % (outputdir,value['seriesanonuid'] )  )
#      slicer.mrmlScene.RemoveNode(node[1])
for key,value in fileDict.items():
  if ( value['SeriesModality'] == 'MR'):
    #   write only triphasic scans
    if( triphasicCT.match(value['SeriesDescription'])):
      outputdir = '/rsrch3/ip/dtfuentes/github/hccdetection/tmpconvert/BCM%04d%03d/' % (int(value['PatientNumber']) ,value['StudyNumber'])
      conversionCMD = '/opt/apps/dcm2niix/MRIcroGL/Resources/dcm2niix -o %s -f %s -z y %s'  % (outputdir,value['seriesanonuid'], '/'.join(value['dcmfile'].split('/')[0:-1]) )
      print(conversionCMD )
      print( outputdir )
      os.system('mkdir -p %s ' % outputdir  )
      os.system( conversionCMD )
exit()
