
-- sqlite3 -init methodisttiming.sql methodistdb/ctkDICOM.sql
-- cat methodisttiming.sql  | sqlite3 methodistdb/ctkDICOM.sql


.headers on
attach database ':memory:' as tmp;
attach database 'methodistdb/ctkDICOMTagCache.sql' as tag;
 
create table tmp.flagdata  as
select im.StudyInstanceUID,im.SeriesInstanceUID,im.seriesDescription,im.SeriesDate,
CASE WHEN im.seriesDescription like "%vibe%" THEN 'vibe'
     WHEN im.seriesDescription like "%Thr%"  THEN 'thrive'
     WHEN im.seriesDescription like "%lava%" THEN 'lava'
     ELSE NULL END AS Vendor,
--dynamic post contrast series:
-- "VIBE DYNAMIC",vibe,Dyn
-- "AX VIBE TWIST PRE-POST DYNAMIC",vibe,Dyn
-- "AX TWIST DYNAMIC PRE-POST",,Dyn
-- "3D Ax LAVA PRE/POST",lava,
-- "WATER: 3D Ax DISCO Dyn Mph 3 BH",,
-- "WATER: 3D Ax DISCO Dyn Mph 3 BH",,
-- "WATER: Ax DISCO Dyn Mph 3 BH",,
-- DYNAMIC,,
-- "Ax Lava Pre/Post Fast",lava,
-- "Ax LAVA Pre/Post",lava,Dyn
-- "Ax LAVA PRE-POST",lava,Dyn
-- "Ax LAVA PRE & POST",lava,Dyn
-- "VIBE DYNAMIC",vibe,Dyn
-- "PRE-POST DYNAMIC",,Dyn
-- "VIBE DYN",vibe,Dyn
-- "Ax LAVA Pre/Post",lava,Dyn
-- "PRE-POST DYNAMIC",,Dyn
-- "VIBE DYN1",vibe,Dyn
-- "Ax LAVA Pre/Post Fast",lava,
-- "PRE-POST DYNAMIC",,Dyn
CASE WHEN (im.seriesDescription like 'DYNAMIC' or im.seriesDescription like 'DYN%VIBE%' or im.seriesDescription like 'VIBE%DYN%'   or im.seriesDescription like '%DISCO%Dyn%'  or im.seriesDescription like '%PRE%POST%'  )  THEN 'Dyn'
-- delayed post contrast series:
-- "AX VIBE DIXON TWIST DELAYED_TTC=3.3s_F",vibe,Pst
-- "AX VIBE DIXON TWIST DELAYED_TTC=3.5s_W",vibe,Pst
-- "AX VIBE DIXON TWIST DELAYED_TTC=3.6s_W",vibe,Pst
-- "Ax LAVA 12Post Delay",lava,Pst
-- "t1_vibe_dixon_tra_p4_bh_10 MIN DELAY_W",vibe,
-- "Ax LAVA DELAY",lava,Pst
-- "3D Ax LAVA POST DELAY",lava,Pst
-- "Cor LAVA Post Delay",lava,
-- "Ax LAVA DELAY",lava,Pst
-- "Ax LAVA Nav DELAY",lava,Pst
-- "AX T1 FS VIBE 10 MIN",vibe,Pst
-- "Ax LAVA Post Delay",lava,Pst
-- "AX VIBE FS 10 MIN DELAYED",vibe,Pst
     WHEN (im.seriesDescription like 'AX%VIBE%10 MIN%' or im.seriesDescription like '%t1_VIBE%DELAY%'or im.seriesDescription like 'AX%VIBE%DELAY%' or im.seriesDescription like '%cor%lava%delay' or im.seriesDescription like '%Ax%LAVA%DELAY%')  THEN 'Pst'
     ELSE NULL END AS ImageType,
     di.SOPInstanceUID,
     replace(di.Filename, "X:/Cancer Physics and Engineering Lab/Milli Roach/LIRADS EPM/Methodist QIAC Uploads 2022/",'') flagtmpptid
     from series im  
     join images   di on di.SeriesInstanceUID= im.SeriesInstanceUID
where im.seriesDescription not like '%SUB%'
GROUP BY    im.SeriesInstanceUID;
-- select StudyInstanceUID,seriesDescription,Vendor,ImageType from tmp.flagdata where ImageType is not NULL;

select min(tg.value), avg(tg.value), max(tg.value)
from tmp.flagdata fl 
join tag.TagCache tg   on fl.SOPInstanceUID= tg.SOPInstanceUID
where tg.tag='0018,0081' and tg.value !='__TAG_NOT_IN_INSTANCE__'  and fl.ImageType is not NULL;

select min(tg.value), avg(tg.value), max(tg.value)
from tmp.flagdata fl 
join tag.TagCache tg   on fl.SOPInstanceUID= tg.SOPInstanceUID
where tg.tag='0018,0080' and tg.value !='__TAG_NOT_IN_INSTANCE__'  and fl.ImageType is not NULL;

-- .quit
