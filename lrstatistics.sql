-- cat qastats/*/lstat.csv > qastats/lstat.csv
-- cat lrstatistics.sql  | sqlite3
.mode csv
.import qastats/lstat.csv  lstat
-- select HCCDate from datekey;
.headers on

select lt.InstanceUID,lt.LabelID,
            max(CASE WHEN lt.SegmentationID='lrtrain-3.nii.gz' and FeatureID = 'lirads.nii.gz'   THEN lt.Mean ELSE NULL END)  label3,
            max(CASE WHEN lt.SegmentationID='lrtrain-3.nii.gz' and FeatureID = 'lirads-3.nii.gz' THEN lt.Mean ELSE NULL END)  predict3,
            max(CASE WHEN lt.SegmentationID='lrtrain-3.nii.gz' and FeatureID = 'lrtrain.nii.gz'  THEN lt.Mean ELSE NULL END)  truth3,
            max(CASE WHEN lt.SegmentationID='lrtrain-4.nii.gz' and FeatureID = 'lirads.nii.gz'   THEN lt.Mean ELSE NULL END)  label4,
            max(CASE WHEN lt.SegmentationID='lrtrain-4.nii.gz' and FeatureID = 'lirads-4.nii.gz' THEN lt.Mean ELSE NULL END)  predict4,
            max(CASE WHEN lt.SegmentationID='lrtrain-4.nii.gz' and FeatureID = 'lrtrain.nii.gz'  THEN lt.Mean ELSE NULL END)  truth4,
            max(CASE WHEN lt.SegmentationID='lrtrain-5.nii.gz' and FeatureID = 'lirads.nii.gz'   THEN lt.Mean ELSE NULL END)  label5,
            max(CASE WHEN lt.SegmentationID='lrtrain-5.nii.gz' and FeatureID = 'lirads-5.nii.gz' THEN lt.Mean ELSE NULL END)  predict5,
            max(CASE WHEN lt.SegmentationID='lrtrain-5.nii.gz' and FeatureID = 'lrtrain.nii.gz'  THEN lt.Mean ELSE NULL END)  truth5,
            lt.Count
from lstat lt
where lt.LabelID !=0
GROUP BY   lt.InstanceUID, lt.LabelID
ORDER BY   lt.InstanceUID  ASC, cast(lt.LabelID as int) ASC;


create table hccimaging  as
select dk.Status,
       CASE WHEN dk.HCCDate = ""  THEN NULL
       ELSE replace(dk.HCCDate, rtrim(dk.HCCDate, replace(dk.HCCDate, '/', '')), '')  || '-' || printf('%02d', cast(substr(dk.HCCDate, 0, instr(dk.HCCDate,'/')) as int)) || '-' || printf('%02d', cast(substr(substr(dk.HCCDate, instr(dk.HCCDate,'/')+1), 0, instr(substr(dk.HCCDate, instr(dk.HCCDate,'/')+1),'/')) as int) ) END  as HCCDate,
       substr(im.StudyDate, 1, 4) || '-' || substr(im.StudyDate, 5,2) || '-' || substr(im.StudyDate, 7,2) as  StudyDate,
       im.StudyNumber,im.PatientNumber,im.SeriesDescription,
CASE WHEN im.seriesDescription like "%vibe%" THEN 'vibe'
     WHEN im.seriesDescription like "%Thr%"  THEN 'thrive'
     WHEN im.seriesDescription like "%lava%" THEN 'lava'
     ELSE NULL END AS Vendor,
CASE WHEN (im.seriesDescription like "t1_vibe_fs%Pre"   or im.seriesDescription like '3D_Thr_Pre'  or im.seriesDescription = 'Ax LAVA BH'     )  THEN 'Pre'
     WHEN (im.seriesDescription like "t1_vibe_fs%Art%"  or im.seriesDescription like '3D_Thr_Art'  or im.seriesDescription like '%Ph1%Ax LAVA%'  )  THEN 'Art'
     WHEN (im.seriesDescription like "t1_vibe_fs%30%"   or im.seriesDescription like '3D_Thr_Ven'  or im.seriesDescription like '%Ph2%Ax LAVA%'  )  THEN 'Ven'
     WHEN (im.seriesDescription like "t1_vibe_fs%60%"   or im.seriesDescription like '3D_Thr_Del%' or im.seriesDescription like '%Ph3%Ax LAVA%'  )  THEN 'Del'
     WHEN (im.seriesDescription like "t1_vibe_fs%Post%" or im.seriesDescription like '3D_Thr_Port' or im.seriesDescription like '%Ax LAVA%DELAY%')  THEN 'Pst'
     ELSE NULL END AS ImageType,
       im.SeriesModality,im.seriesanonuid,im.niftifile 
from datekey dk join imaging im on  dk.slicerID = im.PatientNumber ;

-- select * from hccimaging where seriesdescription == 'Ax LAVA BH' ;
-- select count(Status) from datekey   where Status == 'case';
-- select count(status) from hccimaging where Status == 'case' group by patientnumber, studynumber;
-- FIXME - missing - select * from hccimaging   where patientnumber = 9;
-- FIXME - missing - select * from hccimaging   where patientnumber = 12;

-- julianday(replace(dk.HCCDate, rtrim(dk.HCCDate, replace(dk.HCCDate, '/', '')), '')  || '-' || printf('%02d', cast(substr(dk.HCCDate, 0, instr(dk.HCCDate,'/')) as int)) || '-' || printf('%02d', cast(substr(substr(dk.HCCDate, instr(dk.HCCDate,'/')+1), 0, instr(substr(dk.HCCDate, instr(dk.HCCDate,'/')+1),'/')) as int) )) - julianday(substr(im.StudyDate, 1, 4) || '-' || substr(im.StudyDate, 5,2) || '-' || substr(im.StudyDate, 7,2)) diagnosticinterval,
create table widestudy  as
SELECT   printf('BCM%04d%03d', cast(PatientNumber as int) , cast(StudyNumber as int) ) UID, Vendor, Status, StudyDate,
            CASE WHEN (HCCDate is not NULL  )  THEN julianday(HCCDate) - julianday(StudyDate)
            ELSE "inf" END AS diagnosticinterval,
            max(CASE WHEN ImageType = 'Pre' THEN seriesanonuid ELSE NULL END)  Pre,
            max(CASE WHEN ImageType = 'Art' THEN seriesanonuid ELSE NULL END)  Art,
            max(CASE WHEN ImageType = 'Ven' THEN seriesanonuid ELSE NULL END)  Ven,
            max(CASE WHEN ImageType = 'Del' THEN seriesanonuid ELSE NULL END)  Del,
            max(CASE WHEN ImageType = 'Pst' THEN seriesanonuid ELSE NULL END)  Post,
            PatientNumber, cast(StudyNumber as int) studynumber 
FROM        hccimaging
where       ImageType is not null 
GROUP BY    PatientNumber, StudyNumber
ORDER BY    cast(PatientNumber as int) ASC, cast(StudyNumber as int) ASC;
-- select HCCDate, StudyDate from hccimaging;
-- select diagnosticinterval from widestudy  ;

-- HACK
UPDATE widestudy  
SET Pre = '4bf41e10-1c62-2f82-d081-3d923aca43f2'
WHERE UID = 'BCM0015002';

-- update min
create table hccstudy  as 
select PatientNumber, StudyNumber  HCCStudyNumber  from hccimaging where HCCDate == StudyDate group by Patientnumber;
create table minwidestudy  as 
select PatientNumber, min(StudyNumber) MinStudyNumber from widestudy group by Patientnumber;
-- use hcc date if not then the min study
create table fixedstudy  as 
select w2.PatientNumber, ifnull(w3.HCCStudyNumber,w2.MinStudyNumber) FixedNumber 
from minwidestudy w2 
left join hccstudy     w3 on  w2.PatientNumber = w3.PatientNumber;
-- HACK
UPDATE fixedstudy  
SET FixedNumber = 0 
WHERE PatientNumber  = 24;
-- select * from fixedstudy;

-- joing with hcc date if not then the min study
create table baselineart  as 
select w1.PatientNumber, w1.Art, w1.StudyDate, w2.FixedNumber
from widestudy w1 
join fixedstudy w2 on  w1.PatientNumber = w2.PatientNumber and w1.StudyNumber = w2.FixedNumber;
-- select * from baselineart  ;

-- error check missing data
select count(UID),count(Status),count(diagnosticinterval),count(Pre) ,count(Art) ,count(Ven),count(Del),count(Post)  from widestudy;
UPDATE widestudy SET Post = Del WHERE Post is Null;
select count(UID),count(Status),count(diagnosticinterval),count(Pre) ,count(Art) ,count(Ven),count(Del),count(Post)  from widestudy;

-- output wide format
create table widejoinqa  as 
select w1.*,w3.FixedNumber,julianday(w1.StudyDate)-julianday(w3.StudyDate) daysincebaseline,printf('BCM%04d%03d/%s', cast(w1.PatientNumber as int), cast(w3.FixedNumber as int),w3.Art) Fixed,qa.Status QA
from widestudy    w1
join baselineart  w3 on w1.PatientNumber = w3.PatientNumber 
left join qadata       qa on w1.UID = qa.StudyUID;

.output LiverMRIProjectData/wideanon.csv 
select UID,Vendor,Status,diagnosticinterval,Pre,Art,Ven,Del,Post,PatientNumber,studynumber,FixedNumber,daysincebaseline,Fixed,QA from  widejoinqa  where Pre is not null; 
-- select   printf('BCM%04d%03d', cast(PatientNumber as int) , cast(StudyNumber as int) ) UID,  PatientNumber, StudyNumber from imaging GROUP BY    PatientNumber, StudyNumber;
.quit
