-- cat newwide.sql  | sqlite3
-- sqlite3 -init newwide.sql
.mode csv
-- FIXME - error check dos2unix command has reformat csv files
.import bcmlirads/LiverMRIAnonymizationKey.csv  datekey
.import bcmlirads/newLiverMRIAnonymizationKeyCases.csv newdatekey 
.import bcmlirads/controlsALLanon.csv                  controldatekey 
-- .import bcmlirads/newdatakeyanon.csv                 imaging 
.import bcmlirads/controlsdatakeyanon.csv              imaging 
.import bcmlirads/DemographicsCases.csv                democase
.import bcmlirads/DemographicsControls.csv             democontrol
.import bcmlirads/benignlesions.csv                    benigndata

-- .import LiverMRIProjectData/dataqa.csv  qadata
-- select HCCDate from datekey;
.headers on
create table demographics  as
select da.SlicerID,da.RaceEthnicity,da.BMI,da.Age,da.Sex,da.Diabetes,da.CirrhosisCause
from democase da
union
select do.SlicerID,do.RaceEthnicity,do.BMI,do.Age,do.Sex,do.Diabetes,do.CirrhosisCause
from democontrol do;

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
CASE WHEN (im.seriesDescription like "t1_vibe_fs%Pre"   or im.seriesDescription like '3D_Thr_Pre'  or im.seriesDescription = 'Ax LAVA BH' or im.seriesDescription = 'Ax LAVA MULTIPHASE +C'  )  THEN 'Pre'
     WHEN (im.seriesDescription like "t1_vibe_fs%Art%"  or im.seriesDescription like '3D_Thr_Art'  or im.seriesDescription like '%Ph1%Ax LAVA%'  )  THEN 'Art'
     WHEN (im.seriesDescription like "t1_vibe_fs%30%"   or im.seriesDescription like '3D_Thr_Ven'  or im.seriesDescription like '%Ph2%Ax LAVA%'  )  THEN 'Ven'
     WHEN (im.seriesDescription like "t1_vibe_fs%60%"   or im.seriesDescription like '3D_Thr_Del%' or im.seriesDescription like '%Ph3%Ax LAVA%'  )  THEN 'Del'
     WHEN (im.seriesDescription like "t1_vibe_fs%Post%" or im.seriesDescription like '3D_Thr_Port' or im.seriesDescription like '%Ax LAVA%DELAY%' )  THEN 'Pst'
     ELSE NULL END AS ImageType,
       im.SeriesModality,im.seriesanonuid,im.niftifile 
from datekey dk join imaging im on  dk.slicerID = im.PatientNumber ;

insert into hccimaging  
select 'control' as Status,
        NULL as HCCDate,
       substr(im.StudyDate, 1, 4) || '-' || substr(im.StudyDate, 5,2) || '-' || substr(im.StudyDate, 7,2) as  StudyDate,
       im.StudyNumber,im.PatientNumber,im.SeriesDescription,
CASE WHEN im.seriesDescription like "%vibe%" THEN 'vibe'
     WHEN im.seriesDescription like "%Thr%"  THEN 'thrive'
     WHEN im.seriesDescription like "%lava%" THEN 'lava'
     ELSE NULL END AS Vendor,
CASE WHEN (im.seriesDescription like "t1_vibe_fs%Pre"   or im.seriesDescription like '3D_Thr_Pre'  or im.seriesDescription = 'Ax LAVA BH'  or im.seriesDescription = 'Ax LAVA MULTIPHASE +C'    )  THEN 'Pre'
     WHEN (im.seriesDescription like "t1_vibe_fs%Art%"  or im.seriesDescription like '3D_Thr_Art'  or im.seriesDescription like '%Ph1%Ax LAVA%'  )  THEN 'Art'
     WHEN (im.seriesDescription like "t1_vibe_fs%30%"   or im.seriesDescription like '3D_Thr_Ven'  or im.seriesDescription like '%Ph2%Ax LAVA%'  )  THEN 'Ven'
     WHEN (im.seriesDescription like "t1_vibe_fs%60%"   or im.seriesDescription like '3D_Thr_Del%' or im.seriesDescription like '%Ph3%Ax LAVA%'  )  THEN 'Del'
     WHEN (im.seriesDescription like "t1_vibe_fs%Post%" or im.seriesDescription like '3D_Thr_Port' or im.seriesDescription like '%Ax LAVA%DELAY%' )  THEN 'Pst'
     ELSE NULL END AS ImageType,
       im.SeriesModality,im.seriesanonuid,im.niftifile 
from controldatekey dk join imaging im on  dk.slicerID = im.PatientNumber ;

insert into hccimaging  
select 'case' as Status,
       CASE WHEN dk.HCCDate = ""  THEN NULL
       ELSE replace(dk.HCCDate, rtrim(dk.HCCDate, replace(dk.HCCDate, '/', '')), '')  || '-' || printf('%02d', cast(substr(dk.HCCDate, 0, instr(dk.HCCDate,'/')) as int)) || '-' || printf('%02d', cast(substr(substr(dk.HCCDate, instr(dk.HCCDate,'/')+1), 0, instr(substr(dk.HCCDate, instr(dk.HCCDate,'/')+1),'/')) as int) ) END  as HCCDate,
       substr(im.StudyDate, 1, 4) || '-' || substr(im.StudyDate, 5,2) || '-' || substr(im.StudyDate, 7,2) as  StudyDate,
       im.StudyNumber,im.PatientNumber,im.SeriesDescription,
CASE WHEN im.seriesDescription like "%vibe%" THEN 'vibe'
     WHEN im.seriesDescription like "%Thr%"  THEN 'thrive'
     WHEN im.seriesDescription like "%lava%" THEN 'lava'
     ELSE NULL END AS Vendor,
CASE WHEN (im.seriesDescription like "t1_vibe_fs%Pre"   or im.seriesDescription like '3D_Thr_Pre'  or im.seriesDescription = 'Ax LAVA BH'   or im.seriesDescription = 'Ax LAVA MULTIPHASE +C'   )  THEN 'Pre'
     WHEN (im.seriesDescription like "t1_vibe_fs%Art%"  or im.seriesDescription like '3D_Thr_Art'  or im.seriesDescription like '%Ph1%Ax LAVA%'  )  THEN 'Art'
     WHEN (im.seriesDescription like "t1_vibe_fs%30%"   or im.seriesDescription like '3D_Thr_Ven'  or im.seriesDescription like '%Ph2%Ax LAVA%'  )  THEN 'Ven'
     WHEN (im.seriesDescription like "t1_vibe_fs%60%"   or im.seriesDescription like '3D_Thr_Del%' or im.seriesDescription like '%Ph3%Ax LAVA%'  )  THEN 'Del'
     WHEN (im.seriesDescription like "t1_vibe_fs%Post%" or im.seriesDescription like '3D_Thr_Port' or im.seriesDescription like '%Ax LAVA%DELAY%' )  THEN 'Pst'
     ELSE NULL END AS ImageType,
       im.SeriesModality,im.seriesanonuid,im.niftifile 
from newdatekey dk join imaging im on  dk.slicerID = im.PatientNumber ;

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
-- UPDATE widestudy  
-- SET Pre = '4bf41e10-1c62-2f82-d081-3d923aca43f2'
-- WHERE UID = 'BCM0015002';

-- update min
create table hccstudy  as 
select PatientNumber, StudyNumber  HCCStudyNumber  from hccimaging where HCCDate == StudyDate group by Patientnumber;
create table minmaxdatewidestudy  as 
select PatientNumber, min(StudyDate) MinStudyDate, max(StudyDate) MaxStudyDate from widestudy group by Patientnumber;
create table minwidestudy  as 
select ws.PatientNumber, ws.StudyNumber MinStudyNumber from widestudy ws join  minmaxdatewidestudy ms on ws.PatientNumber=ms.PatientNumber and ms.MinStudyDate=ws.StudyDate;
-- use hcc date if not then the min study
create table fixedstudy  as 
select w2.PatientNumber, ifnull(w3.HCCStudyNumber,w2.MinStudyNumber) FixedNumber 
from minwidestudy w2 
left join hccstudy     w3 on  w2.PatientNumber = w3.PatientNumber;
-- HACK
UPDATE fixedstudy  
SET FixedNumber = 0 
WHERE PatientNumber  = 24;
UPDATE fixedstudy  
SET FixedNumber = 1 
WHERE PatientNumber  = 149;
UPDATE fixedstudy  
SET FixedNumber = 10 
WHERE PatientNumber  = 26;
UPDATE fixedstudy  
SET FixedNumber = 2 
WHERE PatientNumber  = 129;
UPDATE fixedstudy  
SET FixedNumber = 1 
WHERE PatientNumber  = 124;
UPDATE fixedstudy  
SET FixedNumber = 2 
WHERE PatientNumber  = 125;
UPDATE fixedstudy  
SET FixedNumber = 4 
WHERE PatientNumber  = 144;
UPDATE fixedstudy  
SET FixedNumber = 1 
WHERE PatientNumber  = 108;
UPDATE fixedstudy  
SET FixedNumber = 3 
WHERE PatientNumber  = 163;
UPDATE fixedstudy  
SET FixedNumber = 1 
WHERE PatientNumber  = 159;
UPDATE fixedstudy  
SET FixedNumber = 2 
WHERE PatientNumber  = 153;
UPDATE fixedstudy  
SET FixedNumber = 4
WHERE PatientNumber  = 151;
UPDATE fixedstudy  
SET FixedNumber = 2
WHERE PatientNumber  = 148;
UPDATE fixedstudy  
SET FixedNumber = 1
WHERE PatientNumber  = 138;
UPDATE fixedstudy  
SET FixedNumber = 1
WHERE PatientNumber  = 131;
UPDATE fixedstudy  
SET FixedNumber = 3
WHERE PatientNumber  = 129;
UPDATE fixedstudy  
SET FixedNumber = 1
WHERE PatientNumber  = 109;
UPDATE fixedstudy  
SET FixedNumber = 2
WHERE PatientNumber  = 107;
UPDATE fixedstudy  
SET FixedNumber = 1
WHERE PatientNumber  = 104;
UPDATE fixedstudy  
SET FixedNumber = 1
WHERE PatientNumber  =  94;
UPDATE fixedstudy  
SET FixedNumber = 2
WHERE PatientNumber  =  86;
UPDATE fixedstudy  
SET FixedNumber = 1
WHERE PatientNumber  =  85;
UPDATE fixedstudy  
SET FixedNumber = 2
WHERE PatientNumber  =   3;
-- select * from fixedstudy;

-- join with hcc date
create table baselineart  as 
select w1.PatientNumber, w1.Art, w1.StudyDate, w2.FixedNumber,w3.MaxStudyDate
from widestudy w1 
join fixedstudy w2 on  w1.PatientNumber = w2.PatientNumber and w1.StudyNumber = w2.FixedNumber 
join minmaxdatewidestudy  w3 on  w1.PatientNumber = w3.PatientNumber ;
-- select * from baselineart  ;

-- output wide format
create table widejoinqa  as 
select w1.*,w3.FixedNumber,julianday(w1.StudyDate)-julianday(w3.StudyDate) daysincebaseline,julianday(w3.MaxStudyDate)-julianday(w1.StudyDate) daysuntilmax,printf('BCM%04d%03d/%s', cast(w1.PatientNumber as int), cast(w3.FixedNumber as int),w3.Art) Fixed
from widestudy    w1
join baselineart  w3 on w1.PatientNumber = w3.PatientNumber
where w1.Pre is not null and w1.Art is not null and w1.Ven is not null and w1.Del is not null and w1.Post is not null
order by cast(w1.PatientNumber as int),w1.StudyDate ;
-- left join qadata       qa on w1.UID = qa.StudyUID;

-- error check missing data
-- FIXME - need exception handling
select count(UID),count(Status),count(diagnosticinterval),count(Pre) ,count(Art) ,count(Ven),count(Del),count(Post)  from widejoinqa;
UPDATE widejoinqa SET Post = Del WHERE Post is Null;
select count(UID),count(Status),count(diagnosticinterval),count(Pre) ,count(Art) ,count(Ven),count(Del),count(Post)  from widejoinqa;

create table patientlist  as
select substr(dk.UID,1,7) ptid,dk.UID,dk.status,dk.diagnosticinterval,dk.daysincebaseline   from widejoinqa dk where (dk.diagnosticinterval = 0.0 or dk.diagnosticinterval = 'inf') and  dk.daysincebaseline = 0.0; 

create table patientlistpos  as
select substr(dk.UID,1,7) ptid,dk.UID,dk.status,dk.diagnosticinterval from widejoinqa dk where dk.diagnosticinterval  > 0.0 and dk.diagnosticinterval != 'inf' ;

create table patientlistprior  as
select pn.ptid,pn.UID,pn.status,min (pn.diagnosticinterval) diagnosticinterval from patientlistpos  pn  group by pn.ptid ;

UPDATE patientlistprior  
SET UID = 'BCM0033006'
WHERE ptid  =  'BCM0033';
UPDATE patientlistprior  
SET UID = 'BCM0039008'
WHERE ptid  =  'BCM0039';
UPDATE patientlistprior  
SET UID = 'BCM0044010'
WHERE ptid  =  'BCM0044';
UPDATE patientlistprior  
SET UID = 'BCM0065001'
WHERE ptid  =  'BCM0065';

create table patientlistunion as
select ptid,UID,status from patientlist   union
select ptid,UID,status from patientlistprior;

-- filter missing study
create table filterpatientlistcase as
select count(ptid) numscan,* from patientlistunion where status = 'case' group by ptid;

create table patientlistunionnew as
select ptid,UID,status from patientlistunion where status = 'control' union
select pu.ptid,pu.UID,pu.status from patientlistunion pu join  filterpatientlistcase fp on pu.ptid = fp.ptid where fp.numscan =2 ;

-- error check
select count(ptid), status from patientlistunionnew group by status ;

.output bcmlirads/wideanon.csv 
select wj.UID,wj.Vendor,wj.Status,dm.*,wj.diagnosticinterval,wj.Pre,wj.Art,wj.Ven,wj.Del,wj.Post,wj.PatientNumber,wj.studynumber,wj.FixedNumber,wj.daysincebaseline,wj.Fixed from  widejoinqa wj join demographics dm on wj.PatientNumber = dm.SlicerID;
.output bcmlirads/wideanonPreDx.csv 
select wj.UID,wj.Vendor,wj.Status,wj.diagnosticinterval,wj.Pre,wj.Art,wj.Ven,wj.Del,wj.Post,wj.PatientNumber,wj.studynumber,wj.FixedNumber,wj.daysincebaseline,wj.Fixed from  widejoinqa wj join patientlistunionnew  pn on pn.UID = wj.UID ;
.output bcmlirads/wideanonAll.csv 
select wj.rowid, wj.UID,wj.PatientNumber,wj.StudyNumber,wj.StudyDate,wj.Vendor,wj.Status,wj.diagnosticinterval,wj.Pre,wj.Art,wj.Ven,wj.Del,wj.Post,wj.PatientNumber,wj.studynumber,wj.FixedNumber,wj.daysincebaseline,wj.daysuntilmax,wj.Fixed,bd.*
from  widejoinqa wj 
left join benigndata  bd on wj.PatientNumber=bd.SlicerID
order by cast(wj.PatientNumber as int),wj.StudyDate ;
.mode list
.output stdout
-- cat newwide.sql  | sqlite3
-- select   printf('BCM%04d%03d', cast(PatientNumber as int) , cast(StudyNumber as int) ) UID,  PatientNumber, StudyNumber from imaging GROUP BY    PatientNumber, StudyNumber;
