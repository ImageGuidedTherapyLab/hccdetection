
-- select * from series im where im.seriesDescription like "%lava%";
-- select * from series im where im.seriesDescription like "%vibe%";
-- select im.seriesTime,im.seriesDescription from series im where im.seriesDescription like "%vibe%";


.headers on
attach database ':memory:' as tmp;
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
     replace(di.Filename, "/Radonc/Cancer Physics and Engineering Lab/Milli Roach/LIRADS EPM/",'') flagtmpptid
     from series im  
     join images   di on di.SeriesInstanceUID= im.SeriesInstanceUID
where im.seriesDescription not like '%SUB%'
GROUP BY    im.SeriesInstanceUID;
-- select * from tmp.flagdata where ImageType is not NULL;
-- select StudyInstanceUID,seriesDescription,Vendor,ImageType from tmp.flagdata where ImageType is not NULL;

-- select rtrim(substr(flagtmpptid,1,instr(flagtmpptid, "/"))) from tmp.flagdata limit 2;
-- select replace(flagtmpptid, rtrim(substr(flagtmpptid,1,instr(flagtmpptid, "/"))) ,'') from tmp.flagdata limit 2;
-- clean up table to get uid
update tmp.flagdata
set flagtmpptid = replace(flagtmpptid, rtrim(substr(flagtmpptid,1,instr(flagtmpptid, "/"))) ,'') ;

create table tmp.widestudy  as
select fg.StudyInstanceUID StudyInstanceUID,max(fg.Vendor) Vendor,
            max(CASE WHEN ImageType = 'Dyn' THEN fg.SeriesInstanceUID       ELSE NULL END)  Dyn,
            max(CASE WHEN ImageType = 'Pst' THEN fg.SeriesInstanceUID       ELSE NULL END)  Pst
from tmp.flagdata  fg
where fg.ImageType is not null 
GROUP BY    fg.StudyInstanceUID;
-- select * from tmp.widestudy;

-- error check
select count(ws.StudyInstanceUID),count(ws.Dyn),count(ws.Pst)  from tmp.widestudy  ws;

create table tmp.wideformat  as
select ws.*,dn.seriesDate DynDate ,dn.seriesDescription DynDescription , pt.seriesDate PstDate, pt.seriesDescription PstDescription,
replace(di.Filename, "/Radonc/Cancer Physics and Engineering Lab/Milli Roach/LIRADS EPM/",'') tmpptid,
--replace(di.Filename, "X:/Cancer Physics and Engineering Lab/Milli Roach/LIRADS EPM/Methodist QIAC Uploads 2022/",'') tmpptid,
rtrim(di.Filename, replace(di.Filename, '/', '')) DynFilename,
rtrim(pi.Filename, replace(pi.Filename, '/', '')) PstFilename
from tmp.widestudy ws 
join images        di on di.SeriesInstanceUID= ws.Dyn
join images        pi on pi.SeriesInstanceUID= ws.Pst
join tmp.flagdata  dn on dn.SeriesInstanceUID= ws.Dyn
join tmp.flagdata  pt on pt.SeriesInstanceUID= ws.Pst 
GROUP BY    ws.StudyInstanceUID;

-- clean up table to get uid
update tmp.wideformat
set tmpptid = replace(tmpptid, rtrim(substr(tmpptid,1,instr(tmpptid, "/"))) ,'') ;

-- wide format
-- sqlite3 -init methodistss.sql /rsrch9/ip/sasmith6/Documents/SlicerDICOMDatabase/ctkDICOM.sql
-- cat methodistss.sql  | sqlite3 /rsrch9/ip/sasmith6/Documents/SlicerDICOMDatabase/ctkDICOM.sql
.mode csv
.output methodistss/wideformat.csv 
select rtrim(substr(tmpptid,1,instr(tmpptid, "/")),'/') ptid, StudyInstanceUID,Vendor,Dyn,Pst,DynDate,PstDate,DynDescription,PstDescription,DynFilename,PstFilename, substr(DynFilename,1,instr(DynFilename,'SE00')-1) || "raystation"  as raystation , NULL as liverlabel0,  NULL as liverlabel1, NULL as liverlabel2, NULL as liverlabel3, NULL as lesionlabel  from tmp.wideformat;
-- select rtrim(substr(tmpptid,1,instr(tmpptid, "/")),'/') ptid, StudyInstanceUID,Vendor,Dyn,Pst,DynDate,PstDate,DynDescription,PstDescription,DynFilename,PstFilename,rtrim(DynFilename,'/') || '_0' as DynFilename0,rtrim(DynFilename,'/') || '_1' as DynFilename1,rtrim(DynFilename,'/')||'_2' as DynFilename2,rtrim(DynFilename,'/')||'_3' as DynFilename3 ,rtrim(PstFilename,'/')||'_a' as PstFilename_a , NULL as liverlabel0,  NULL as liverlabel1, NULL as liverlabel2, NULL as liverlabel3, NULL as lesionlabel  from tmp.wideformat;

.output methodistss/flagdata.csv 
select rtrim(substr(flagtmpptid,1,instr(flagtmpptid, "/")),'/') ptid,SeriesDescription,Vendor,ImageType from tmp.flagdata;

.output methodistss/ucsfdb.csv 
select im.SeriesDescription,di.Filename from images di join series im on di.SeriesInstanceUID= im.SeriesInstanceUID where di.Filename like "%UCSF%" group by di.seriesinstanceuid;
.output methodistss/sfvadb.csv 
select im.SeriesDescription,di.Filename from images di join series im on di.SeriesInstanceUID= im.SeriesInstanceUID where di.Filename like "%SFVA%" group by di.seriesinstanceuid;
.mode list
.output stdout

-- .quit
