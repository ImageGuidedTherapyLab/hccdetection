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
       max(CASE WHEN ls.labelID = 3 THEN ls.mean END)  as tumormeanlr3,
       max(CASE WHEN ls.labelID = 4 THEN ls.mean END)  as tumormeanlr4,
       max(CASE WHEN ls.labelID = 5 THEN ls.mean END)  as tumormeanlr5,
       max(CASE WHEN ls.labelID = 6 THEN ls.mean END)  as livermean,
       max(CASE WHEN ls.labelID = 6 THEN ls.stdd END)  as liverstd
from lstat ls 
GROUP BY   ls.InstanceUID,ls.FeatureID;

create table cnrdata  as
select  ch.*, (ch.tumormeanlr3-ch.livermean)/ch.liverstd as cnrlr3 , (ch.tumormeanlr4-ch.livermean)/ch.liverstd as cnrlr4, (ch.tumormeanlr5-ch.livermean)/ch.liverstd as cnrlr5 
from cnrhelper ch;

.headers on
create table cnrdatalr3PreDx  as
select count(CASE WHEN cd.FeatureID = 'epm' THEN cd.cnrlr3 END) as epmcntbPreDxlr3,sum(CASE WHEN cd.FeatureID = 'epm' THEN cd.cnrlr3 END)  as epmsumbPreDxlr3,
       count(CASE WHEN cd.FeatureID = 'art' THEN cd.cnrlr3 END) as artcntbPreDxlr3,sum(CASE WHEN cd.FeatureID = 'art' THEN cd.cnrlr3 END)  as artsumbPreDxlr3,
       count(CASE WHEN cd.FeatureID = 'ven' THEN cd.cnrlr3 END) as vencntbPreDxlr3,sum(CASE WHEN cd.FeatureID = 'ven' THEN cd.cnrlr3 END)  as vensumbPreDxlr3
from cnrdata cd 
where cd.cnrlr3 is not NULL and cd.diagnosticinterval > 0;

create table cnrdatalr4PreDx  as
select count(CASE WHEN cd.FeatureID = 'epm' THEN cd.cnrlr4 END) as epmcntbPreDxlr4,sum(CASE WHEN cd.FeatureID = 'epm' THEN cd.cnrlr4 END)  as epmsumbPreDxlr4,
       count(CASE WHEN cd.FeatureID = 'art' THEN cd.cnrlr4 END) as artcntbPreDxlr4,sum(CASE WHEN cd.FeatureID = 'art' THEN cd.cnrlr4 END)  as artsumbPreDxlr4,
       count(CASE WHEN cd.FeatureID = 'ven' THEN cd.cnrlr4 END) as vencntbPreDxlr4,sum(CASE WHEN cd.FeatureID = 'ven' THEN cd.cnrlr4 END)  as vensumbPreDxlr4
from cnrdata cd 
where cd.cnrlr4 is not NULL and cd.diagnosticinterval > 0;


create table cnrdatalr5Dx  as
select count(CASE WHEN cd.FeatureID = 'epm' THEN cd.cnrlr5 END) as epmcntbDxlr5,sum(CASE WHEN cd.FeatureID = 'epm' THEN cd.cnrlr5 END)  as epmsumbDxlr5,
       count(CASE WHEN cd.FeatureID = 'art' THEN cd.cnrlr5 END) as artcntbDxlr5,sum(CASE WHEN cd.FeatureID = 'art' THEN cd.cnrlr5 END)  as artsumbDxlr5,
       count(CASE WHEN cd.FeatureID = 'ven' THEN cd.cnrlr5 END) as vencntbDxlr5,sum(CASE WHEN cd.FeatureID = 'ven' THEN cd.cnrlr5 END)  as vensumbDxlr5
from cnrdata cd 
where cd.cnrlr5 is not NULL and cd.diagnosticinterval == 0;

create table cnrdatalr4Dx  as
select count(CASE WHEN cd.FeatureID = 'epm' THEN cd.cnrlr4 END) as epmcntbDxlr4,sum(CASE WHEN cd.FeatureID = 'epm' THEN cd.cnrlr4 END)  as epmsumbDxlr4,
       count(CASE WHEN cd.FeatureID = 'art' THEN cd.cnrlr4 END) as artcntbDxlr4,sum(CASE WHEN cd.FeatureID = 'art' THEN cd.cnrlr4 END)  as artsumbDxlr4,
       count(CASE WHEN cd.FeatureID = 'ven' THEN cd.cnrlr4 END) as vencntbDxlr4,sum(CASE WHEN cd.FeatureID = 'ven' THEN cd.cnrlr4 END)  as vensumbDxlr4
from cnrdata cd 
where cd.cnrlr4 is not NULL and cd.diagnosticinterval == 0;



select * from cnrdatalr3PreDx;
select * from cnrdatalr4PreDx;

select (plr3.epmsumbPreDxlr3+ plr4.epmsumbPreDxlr4)/( plr3.epmcntbPreDxlr3+ plr4.epmcntbPreDxlr4)  as epmcnrPreDx,
       (plr3.artsumbPreDxlr3+ plr4.artsumbPreDxlr4)/( plr3.artcntbPreDxlr3+ plr4.artcntbPreDxlr4)  as artcnrPreDx,
       (plr3.vensumbPreDxlr3+ plr4.vensumbPreDxlr4)/( plr3.vencntbPreDxlr3+ plr4.vencntbPreDxlr4)  as vencnrPreDx 
from      cnrdatalr3PreDx plr3 join  cnrdatalr4PreDx plr4;

select (plr5.epmsumbDxlr5+ plr4.epmsumbDxlr4)/( plr5.epmcntbDxlr5+ plr4.epmcntbDxlr4)  as epmcnrDx,
       (plr5.artsumbDxlr5+ plr4.artsumbDxlr4)/( plr5.artcntbDxlr5+ plr4.artcntbDxlr4)  as artcnrDx,
       (plr5.vensumbDxlr5+ plr4.vensumbDxlr4)/( plr5.vencntbDxlr5+ plr4.vencntbDxlr4)  as vencnrDx 
from      cnrdatalr5Dx plr5 join  cnrdatalr4Dx plr4;

.output epmstats/widejoin.csv  
select pl.UID,pl.Status,ls.*
from patientlistunion pl  left join lstat ls on pl.UID = ls.InstanceUID ;
.quit


