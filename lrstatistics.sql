-- cat qastats/*/lstat.csv > qastats/lstat.csv
-- cat lrstatistics.sql  | sqlite3
-- sqlite3 -init lrstatistics.sql
.mode csv
.import qastats/lstat.csv  tmplstat
-- cleanup
create table lstat  as
select InstanceUID,SegmentationID,FeatureID,LabelID,Mean,StdD,Max,Min,cast(Count as int) Count,`Vol.mm.3`,ExtentX,ExtentY,ExtentZ from tmplstat where cast(Count as int) >0 ;

-- select HCCDate from datekey;
.headers on

create table volumestats  as
select lt.InstanceUID,1  LabelID,
            max(CASE WHEN lt.SegmentationID='lrtrain-1.nii.gz' and FeatureID = 'lirads.nii.gz' and lt.LabelID=3 THEN lt.Count ELSE NULL END) countlr3,
            max(CASE WHEN lt.SegmentationID='lrtrain-1.nii.gz' and FeatureID = 'lirads.nii.gz' and lt.LabelID=4 THEN lt.Count ELSE NULL END) countlr4,
            max(CASE WHEN lt.SegmentationID='lrtrain-1.nii.gz' and FeatureID = 'lirads.nii.gz' and lt.LabelID=5 THEN lt.Count ELSE NULL END) countlr5,
            max(CASE WHEN lt.SegmentationID='lrtrain.nii.gz' and FeatureID= 'lrtrain.nii.gz' and lt.LabelID=1 THEN lt.Count ELSE NULL END) compsize 
from lstat lt
GROUP BY   lt.InstanceUID
UNION
select lt.InstanceUID,2  LabelID,
            max(CASE WHEN lt.SegmentationID='lrtrain-2.nii.gz' and FeatureID = 'lirads.nii.gz' and lt.LabelID=3 THEN lt.Count ELSE NULL END) countlr3,
            max(CASE WHEN lt.SegmentationID='lrtrain-2.nii.gz' and FeatureID = 'lirads.nii.gz' and lt.LabelID=4 THEN lt.Count ELSE NULL END) countlr4,
            max(CASE WHEN lt.SegmentationID='lrtrain-2.nii.gz' and FeatureID = 'lirads.nii.gz' and lt.LabelID=5 THEN lt.Count ELSE NULL END) countlr5,
            max(CASE WHEN lt.SegmentationID='lrtrain.nii.gz' and FeatureID= 'lrtrain.nii.gz' and lt.LabelID=2 THEN lt.Count ELSE NULL END) compsize 
from lstat lt
GROUP BY   lt.InstanceUID
UNION
select lt.InstanceUID,3  LabelID,
            max(CASE WHEN lt.SegmentationID='lrtrain-3.nii.gz' and FeatureID = 'lirads.nii.gz' and lt.LabelID=3 THEN lt.Count ELSE NULL END) countlr3,
            max(CASE WHEN lt.SegmentationID='lrtrain-3.nii.gz' and FeatureID = 'lirads.nii.gz' and lt.LabelID=4 THEN lt.Count ELSE NULL END) countlr4,
            max(CASE WHEN lt.SegmentationID='lrtrain-3.nii.gz' and FeatureID = 'lirads.nii.gz' and lt.LabelID=5 THEN lt.Count ELSE NULL END) countlr5,
            max(CASE WHEN lt.SegmentationID='lrtrain.nii.gz' and FeatureID= 'lrtrain.nii.gz' and lt.LabelID=3 THEN lt.Count ELSE NULL END) compsize 
from lstat lt
GROUP BY   lt.InstanceUID
ORDER BY   lt.InstanceUID  ASC;


create table widelstat  as
select lt.InstanceUID,cast(lt.LabelID as int) LabelID,
            max(CASE WHEN lt.SegmentationID='lrtrain.nii.gz' and FeatureID = 'EPM_3.nii.gz' THEN lt.Mean ELSE NULL END)  EPM,
            max(CASE WHEN lt.SegmentationID='lrtrain.nii.gz' and FeatureID = 'lirads-3.nii.gz' THEN lt.Mean ELSE NULL END)  predict3,
            max(CASE WHEN lt.SegmentationID='lrtrain.nii.gz' and FeatureID = 'lirads-4.nii.gz' THEN lt.Mean ELSE NULL END)  predict4,
            max(CASE WHEN lt.SegmentationID='lrtrain.nii.gz' and FeatureID = 'lirads-5.nii.gz' THEN lt.Mean ELSE NULL END)  predict5,
            max(CASE WHEN lt.SegmentationID='lrtrain.nii.gz' and FeatureID = 'lrtrain.nii.gz'  THEN lt.Mean ELSE NULL END)  truth,
            lt.Count
from lstat lt
where lt.LabelID !=0
GROUP BY   lt.InstanceUID, lt.LabelID
ORDER BY   lt.InstanceUID  ASC, cast(lt.LabelID as int) ASC;


.output qastats/wide.csv  
select substr(ws.InstanceUID,1,7)  ptid, ws.*, vs.* from volumestats vs join  widelstat ws  on vs.InstanceUID = ws.InstanceUID and vs.LabelID = ws.LabelID  where vs.compsize > 20;
.quit
