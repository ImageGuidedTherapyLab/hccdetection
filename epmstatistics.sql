-- cat epmstats/*/lstat.csv > epmstats/lstat.csv
-- cat epmstatistics.sql  | sqlite3
-- sqlite3 -init epmstatistics.sql
.mode csv
.import epmstats/lstat.csv  tmplstat
.import bcmlirads/wideanon.csv datakey
-- cleanup
create table lstat  as
select substr(ts.InstanceUID,1,7) ptid,ts.InstanceUID,dk.Status, dk.diagnosticinterval,ts.SegmentationID,ts.FeatureID,ts.LabelID,ts.Mean,ts.StdD,ts.Max,ts.Min,cast(ts.Count as int) Count,ts.`Vol.mm.3`,ts.ExtentX,ts.ExtentY,ts.ExtentZ 
from tmplstat ts join datakey dk on ts.InstanceUID = dk.UID
 where cast(Count as int) >0 ;



-- select HCCDate from datekey;
.headers on
.output epmstats/widejoin.csv  
select * from lstat where LabelID > 0;
.quit

