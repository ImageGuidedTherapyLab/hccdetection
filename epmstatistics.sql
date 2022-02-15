-- cat epmstats/*/lstat.csv > epmstats/lstat.csv
-- cat epmstatistics.sql  | sqlite3
-- sqlite3 -init epmstatistics.sql
.mode csv
.import epmstats/lstat.csv  tmplstat
.import bcmlirads/wideanon.csv datakey
-- cleanup
create table lstat  as
select substr(ts.InstanceUID,1,7) ptid,ts.InstanceUID,dk.Status, cast(dk.diagnosticinterval as float) diagnosticinterval,ts.SegmentationID,ts.FeatureID,ts.LabelID,ts.Mean,ts.StdD,ts.Max,ts.Min,cast(ts.Count as int) Count,ts.`Vol.mm.3`,ts.ExtentX,ts.ExtentY,ts.ExtentZ 
from tmplstat ts join datakey dk on ts.InstanceUID = dk.UID
 where cast(Count as int) >0 ;

create table patientlist  as
select substr(dk.UID,1,7) ptid,dk.UID,dk.status from datakey dk where dk.diagnosticinterval = '0.0' or dk.daysincebaseline = '0.0'; 
      
create table patientlistneg  as
select substr(dk.UID,1,7) ptid,dk.UID,dk.status,cast(dk.diagnosticinterval as float) diagnosticinterval  from datakey dk where cast(dk.diagnosticinterval as float) > 0.0;

create table patientlistprior  as
select pn.ptid,pn.UID,pn.status,min (pn.diagnosticinterval) diagnosticinterval from patientlistneg  pn  group by pn.ptid ;

create table patientlistunion as
select * from patientlist   union
select ptid,UID,status from patientlistprior;


create table cnrhelper  as
select ls.ptid,ls.InstanceUID,ls.Status, ls.diagnosticinterval,ls.SegmentationID,ls.FeatureID,
       max(CASE WHEN ls.labelID = 3 or ls.labelID = 4 or ls.labelID = 5 THEN ls.mean END)  as tumormean,
       max(CASE WHEN ls.labelID = 6 THEN ls.mean END)  as livermean,
       max(CASE WHEN ls.labelID = 6 THEN ls.stdd END)  as liverstd
from lstat ls 
GROUP BY    ls.InstanceUID,ls.FeatureID;

create table cnrdata  as
select  ch.*, (ch.tumormean-ch.livermean)/ch.liverstd as cnr 
from cnrhelper ch;

.headers on
select avg(CASE WHEN cd.FeatureID = 'epm'  THEN cd.cnr END)  as epmcnr,
       avg(CASE WHEN cd.FeatureID = 'art'  THEN cd.cnr END)  as artcnr,
       avg(CASE WHEN cd.FeatureID = 'ven'  THEN cd.cnr END)  as vencnr
from cnrdata cd
where cd.cnr is not NULL;
select avg(CASE WHEN cd.FeatureID = 'epm'  THEN cd.cnr END)  as epmcnrPreDx,
       avg(CASE WHEN cd.FeatureID = 'art'  THEN cd.cnr END)  as artcnrPreDx,
       avg(CASE WHEN cd.FeatureID = 'ven'  THEN cd.cnr END)  as vencnrPreDx
from cnrdata cd
where cd.cnr is not NULL and cd.diagnosticinterval > 0;
select avg(CASE WHEN cd.FeatureID = 'epm'  THEN cd.cnr END)  as epmcnrDx,
       avg(CASE WHEN cd.FeatureID = 'art'  THEN cd.cnr END)  as artcnrDx,
       avg(CASE WHEN cd.FeatureID = 'ven'  THEN cd.cnr END)  as vencnrDx
from cnrdata cd
where cd.cnr is not NULL and cd.diagnosticinterval = 0;


.output epmstats/widejoin.csv  
select pl.UID,pl.Status,ls.*
from patientlistunion pl  left join lstat ls on pl.UID = ls.InstanceUID ;
.quit


