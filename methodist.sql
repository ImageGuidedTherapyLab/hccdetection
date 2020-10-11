-- select * from series im where im.seriesDescription like "%lava%";
-- select * from series im where im.seriesDescription like "%vibe%";
-- select im.seriesTime,im.seriesDescription from series im where im.seriesDescription like "%vibe%";
.headers on
attach database ':memory:' as tmp;
create table tmp.flagdata  as
select im.StudyInstanceUID,im.SeriesInstanceUID,im.seriesDescription,
CASE WHEN im.seriesDescription like "%vibe%" THEN 'vibe'
     WHEN im.seriesDescription like "%Thr%"  THEN 'thrive'
     WHEN im.seriesDescription like "%lava%" THEN 'lava'
     ELSE NULL END AS Vendor,
CASE WHEN (im.seriesDescription like 'DYN%VIBE' or im.seriesDescription like 'VIBE%DYN%'   or im.seriesDescription like '3D_Thr_Pre'  or im.seriesDescription like '%dynam%PRE%POST%' or im.seriesDescription like '%PRE%POST%dynam%'  or im.seriesDescription like 'Ax%LAVA%PRE%POST'     )  THEN 'Dyn'
     WHEN (im.seriesDescription like 'AX%VIBE%10 MIN%%' or im.seriesDescription like 'AX%VIBE%DELAY%' or im.seriesDescription like '3D_Thr_Port' or im.seriesDescription like '%Ax%LAVA%DELAY%')  THEN 'Pst'
     ELSE NULL END AS ImageType from series im 
where im.seriesDescription not like '%SUB%';
-- select * from tmp.flagdata where ImageType is not NULL;

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

-- wide format
-- cat methodist.sql  | sqlite3 BerettaLab/ctkDICOM.sql
.mode csv
.output BerettaLab/wideformat.csv 
select ws.*,dn.seriesDescription DynDescription , pt.seriesDescription PstDescription,di.Filename DynFilename,pi.Filename PstFilename
from tmp.widestudy ws 
join images        di on di.SeriesInstanceUID= ws.Dyn
join images        pi on pi.SeriesInstanceUID= ws.Pst
join tmp.flagdata  dn on dn.SeriesInstanceUID= ws.Dyn
join tmp.flagdata  pt on pt.SeriesInstanceUID= ws.Pst 
GROUP BY    ws.StudyInstanceUID;

.quit
