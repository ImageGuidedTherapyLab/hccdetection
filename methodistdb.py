import sqlite3
conn = sqlite3.connect('/rsrch3/maroach/ctkDICOM.sql')
#conn = sqlite3.connect('methodistdb/ctkDICOM.sql')
 
print("Opened database successfully")

# create in memory data for scratch storage
conn.execute('''
attach database ':memory:' as tmp;
''')
conn.execute('''
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
     replace(di.Filename, "X:/Cancer Physics and Engineering Lab/Milli Roach/LIRADS EPM/Methodist QIAC Uploads 2022/",'') flagtmpptid
     from series im  
     join images   di on di.SeriesInstanceUID= im.SeriesInstanceUID
where im.seriesDescription not like '%SUB%'
GROUP BY    im.SeriesInstanceUID;
-- select * from tmp.flagdata where ImageType is not NULL;
-- select StudyInstanceUID,seriesDescription,Vendor,ImageType from tmp.flagdata where ImageType is not NULL;
''')
print("Table created successfully")

conn.execute('''
create table tmp.widestudy  as
select fg.StudyInstanceUID StudyInstanceUID,max(fg.Vendor) Vendor,
            max(CASE WHEN ImageType = 'Dyn' THEN fg.SeriesInstanceUID       ELSE NULL END)  Dyn,
            max(CASE WHEN ImageType = 'Pst' THEN fg.SeriesInstanceUID       ELSE NULL END)  Pst
from tmp.flagdata  fg
where fg.ImageType is not null 
GROUP BY    fg.StudyInstanceUID;
''')
cursor = conn.execute('''
-- error check
select count(ws.StudyInstanceUID),count(ws.Dyn),count(ws.Pst)  from tmp.widestudy  ws;
''')
for row in cursor:
   print(row)
conn.execute('''
create table tmp.wideformat  as
select ws.*,dn.seriesDate DynDate ,dn.seriesDescription DynDescription , pt.seriesDate PstDate, pt.seriesDescription PstDescription,
--replace(di.Filename, "/Radonc/Cancer Physics and Engineering Lab/Milli Roach/LIRADS EPM/Methodist QIAC Uploads 2022/",'') tmpptid,
replace(di.Filename, "X:/Cancer Physics and Engineering Lab/Milli Roach/LIRADS EPM/Methodist QIAC Uploads 2022/",'') tmpptid,
rtrim(di.Filename, replace(di.Filename, '/', '')) DynFilename,
rtrim(pi.Filename, replace(pi.Filename, '/', '')) PstFilename
from tmp.widestudy ws 
join images        di on di.SeriesInstanceUID= ws.Dyn
join images        pi on pi.SeriesInstanceUID= ws.Pst
join tmp.flagdata  dn on dn.SeriesInstanceUID= ws.Dyn
join tmp.flagdata  pt on pt.SeriesInstanceUID= ws.Pst 
GROUP BY    ws.StudyInstanceUID;
''')
cursor = conn.execute('''
-- wide format
-- sqlite3 -init methodistdb.sql methodistdb/ctkDICOM.sql
-- sqlite3 -init methodistdb.sql /rsrch3/maroach/ctkDICOM.sql
-- cat methodistdb.sql  | sqlite3 methodistdb/ctkDICOM.sql
-- cat methodistdb.sql  | sqlite3 /rsrch3/maroach/ctkDICOM.sql
select rtrim(substr(tmpptid,1,instr(tmpptid, "/")),'/') ptid, StudyInstanceUID,Vendor,Dyn,Pst,DynDate,PstDate,DynDescription,PstDescription,DynFilename,PstFilename from tmp.wideformat;
''')
numberPt=set()
for row in cursor:
   print(row[0].split('_'),row)
   if(len(row[0].split('_'))>1):
     numberPt.add(row[0].split('_')[3])
   else:
     numberPt.add(row[0])
cursor = conn.execute('''
select rtrim(substr(flagtmpptid,1,instr(flagtmpptid, "/")),'/') ptid,SeriesDescription,Vendor,ImageType from tmp.flagdata;
''')
#for row in cursor:
#   print(row)
conn.close()
