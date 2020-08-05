from __main__ import slicer
import os
from datetime import datetime
import uuid
import csv


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
        niftifile = 'BCM%04d%02d/%s.nii.gz' % (int(patientnumber) ,idstudy,seriesanonuid )
        fileDict[seriesanonuid] = {'PatientID':patientID,'Study':study,'StudyDate':studyDate,'Series':series,'dcmfile':serieslist[0],'HCCDate':'FIXME','DiagnosticInterval':'FIXME','StudyNumber':idstudy,'PatientNumber':patientnumber ,'SeriesDescription':seriesDescription,'SeriesModality':seriesModality,'seriesanonuid':seriesanonuid, 'niftifile':niftifile   }
        print  fileDict[seriesanonuid]
        csvwrite.writerow( [ fileDict[seriesanonuid][headerID] for headerID in fileHeader] )
      studyList.append((study,studyDate,idstudy )) 
    if( len(studyList) > 0 ):
      patientDict[patientnumber]['studyList'] = studyList


for key,value in fileDict.items():
  if ( value['SeriesModality'] == 'MR'):
    node=slicer.util.loadVolume(value['dcmfile'],returnNode=True);
    # TODO - note full path output directory
    outputdir = '/rsrch2/ip/dtfuentes/github/hccdetection/tmpconvert/BCM%04d%03d/' % (int(value['PatientNumber']) ,value['StudyNumber'])
    print( outputdir )
    os.system('mkdir -p %s ' % outputdir  )
    slicer.util.saveNode(node[1], '%s/%s.nii.gz' % (outputdir,value['seriesanonuid'] )  )
exit()
