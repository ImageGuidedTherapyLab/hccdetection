.mode csv
.import LiverMRIProjectData/datakeyANON.csv  imaging
.headers on
.output LiverMRIProjectData/wideanon.csv 
SELECT   printf('BCM%04d%03d', cast(PatientNumber as int) , cast(StudyNumber as int) ) UID,
            max(CASE WHEN SeriesDescription like "t1_vibe_fs%Pre"   THEN seriesanonuid ELSE NULL END)  Pre,
            max(CASE WHEN SeriesDescription like "t1_vibe_fs%Art%"  THEN seriesanonuid ELSE NULL END)  Art,
            max(CASE WHEN SeriesDescription like "t1_vibe_fs%30%"   THEN seriesanonuid ELSE NULL END)  Ven,
            max(CASE WHEN SeriesDescription like "t1_vibe_fs%60%"   THEN seriesanonuid ELSE NULL END)  Del,
            max(CASE WHEN SeriesDescription like "t1_vibe_fs%Post%" THEN seriesanonuid ELSE NULL END)  Post 
FROM        imaging
where       SeriesDescription like "t1_vibe_fs%"
GROUP BY    PatientNumber, StudyNumber
ORDER BY    cast(PatientNumber as int) ASC, cast(StudyNumber as int) ASC;

-- select   printf('BCM%04d%03d', cast(PatientNumber as int) , cast(StudyNumber as int) ) UID,  PatientNumber, StudyNumber from imaging GROUP BY    PatientNumber, StudyNumber;
.quit
