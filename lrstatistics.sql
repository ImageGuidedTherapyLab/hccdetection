-- cat qastats/*/lstat.csv > qastats/lstat.csv
-- cat lrstatistics.sql  | sqlite3
.mode csv
.import qastats/lstat.csv  lstat
-- select HCCDate from datekey;
.headers on

create table widelstat  as
select lt.InstanceUID,lt.LabelID,
            max(CASE WHEN lt.SegmentationID='lrtrain.nii.gz' and FeatureID = 'lirads.nii.gz'   THEN lt.Mean ELSE NULL END)  label,
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
select * from widelstat;
.quit
