filename source url "http://phuse-scripts.googlecode.com/svn/trunk/lang/R/report/test/data/adsl.xpt";
libname source xport ;

data work.adsl ;
  set source.adsl ;
run ;

 filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adae.xpt" ;
 libname source xport ;

 data work.adae ;
   set source.adae ;
   keep USUBJID TRTAN AEDECOD TRTEMFL AOCCPFL SAFFL;
 run ;

   proc sort data=work.adae;
   by aedecod;
run;

   data adae1;
   set adae;
   where TRTEMFL="Y" and AOCCPFL='Y' and saffl="Y";
   run;


   proc sql;
   	create table countae as
	select distinct count(usubjid) as numAE, aedecod, trtan
	from adae1
	group by trtan, aedecod;

    create table nsubj as
	select distinct count(distinct usubjid) as numusubjid, TRT01AN
	from adsl
	group by TRT01AN;
	quit;

data count;
merge countae(in=_countae)  nsubj(in=_nsubj rename=(trt01an=trtan));
by trtan;
if not _nsubj then do;
abort cancel;
end;
label AEpercent="AEs (%)";
if not missing(numAE) and not missing(numusubjid) then do;
AEpercent= numAE/numusubjid;
end;
else do;
AEpercent= .;
end;
run;

proc sort data=count;
by aedecod;
run;

data tcount;
merge
count
count(where=(trtan_1=0) rename=(AEpercent=AEpercent_1 trtan=trtan_1))
;
by aedecod;

if missing(AEpercent) then do;
AEpercent=0;
end;

if missing(AEpercent_1) then do;
AEpercent_1=0;
end;

RelRisk= AEpercent - AEpercent_1;
aeseqno+1;
run;

proc sql;
create table maxpercen2 as 
select distinct -max(AEpercent) as minusmaxAEpercent, aedecod
from tcount
group by aedecod
order by minusmaxAEpercent;
quit;

data maxpercen2;
set maxpercen2;
dispseqno+1;
run;

proc sort data=maxpercen2;
by aedecod;
run;

data tcount2;
merge tcount maxpercen2;
by aedecod;
run;

proc sql;
create table AEgrid as 
select * from (select distinct trtan from tcount2),
(select distinct aedecod, dispseqno from tcount2)
order by aedecod, trtan;
quit;

data tcount3;
merge tcount2 AEgrid;
by aedecod trtan;
if missing(AEpercent) then do;
AEpercent=0;
end;
run;

proc sort data=tcount3;
by dispseqno;
run;


title1 "Common Treatment-Emergent Adverse Events";
proc sgplot data=tcount3;
label trtan="Treatment";
label aeseqno="AE ordered in descending order";
where dispseqno<=20;
  scatter x=AEpercent y=dispseqno / group=trtan; 
  xaxis grid;
  yaxis grid values=(1 to 20 by 1) valueshint;
 run; 

