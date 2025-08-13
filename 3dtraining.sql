
-- cat 3dtraining.sql  | sqlite3
-- sqlite3 -init 3dtraining.sql
.mode csv
.import bcmlirads/wideanon.csv datakey
create table patientlist  as
select substr(dk.UID,1,7) ptid,dk.UID,dk.status from datakey dk where dk.diagnosticinterval = '0.0' or dk.daysincebaseline = '0.0'; 

create table patientlistneg  as
select substr(dk.UID,1,7) ptid,dk.UID,dk.status,cast(dk.diagnosticinterval as float) diagnosticinterval  from datakey dk where cast(dk.diagnosticinterval as float) > 0.0;

create table patientlistprior  as
select pn.ptid ptid ,pn.UID UID,pn.status status,min (pn.diagnosticinterval) diagnosticinterval from patientlistneg  pn  group by pn.ptid ;

create table patientlistunion as
select * from patientlist where status = 'control'  union
select ptid,UID,status from patientlistprior;

.headers on
.output 3dtrainingdx.csv
select *, 'bcmdata/'||UID||'/EPM.nii' image, 'bcmdata/'||UID||'/Art.liver.nii.gz' label , 'bcmlirads/'||UID||'fixed.train.nii.gz' train from  patientlist;
.output 3dtrainingpredx.csv
select *, 'bcmdata/'||UID||'/EPM.nii' image, 'bcmdata/'||UID||'/Art.liver.nii.gz' label , 'bcmlirads/'||UID||'fixed.train.nii.gz' train from  patientlistunion ;
.output stdout
