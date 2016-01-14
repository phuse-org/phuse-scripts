********************************************************************************************
   CODE NAME         : target31.sas
   DESCRIPTION       : Reference SAS program for target 31
   SOFTWARE/VERSION# : SAS V9
   INPUT             : http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adsl.xpt
Dataset: ADSL
Variables: USUBJID, TRTAN, DSREASCD, ITTFL
Record Selection: WHERE ITTFL=Y 

Completed the Study = count patients where DSREASCD='Completed'.
Discontinued = count patients where DSREASCD ne 'Completed'.
Display all discontinuation reasons alphabetically by DSREASCD.
Percentage = 100 * n in cell / N with ADSL.TRTAN value. 
********************************************************************************************;

**-----------------------------------------------------------------------------;
**-----------------------------------------------------------------------------;
filename source url http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adsl.xpt;
libname source xport;

data work.adsl;
  set source.adsl;
run;

**-----------------------------------------------------------------------------;
**-----------------------------------------------------------------------------;
proc sql;
  create table disp as 
	select distinct TRT01P,TRT01PN, count(usubjid) as cnt, 1 as ord,
  case 
    when DCREASCD='Completed'  then DCREASCD 
    else 'Discontinued' end as status
  from adsl
	  where ITTFL='Y'
	  group by TRT01P, calculated status
  union all
	  select distinct TRT01P,TRT01PN, count(usubjid) as cnt, 2 as ord,
	  DCREASCD as status
  from adsl
	  where ITTFL='Y' and DCREASCD^='Completed'
	  group by TRT01P,DCREASCD
  order by TRT01PN,calculated ord, calculated status
;

  create table freq as
	select distinct TRT01PN,count (usubjid) as tot_cnt
  from adsl
  group by TRT01PN
  order by TRT01PN
;
quit;

**-----------------------------------------------------------------------------;
**-----------------------------------------------------------------------------;
data disp_2;
	merge disp freq;
	by TRT01PN;
	treat=  strip(TRT01P) ||" (N="||strip(tot_cnt)||")";
	cnt_prcnt= strip(cnt)||" ("||strip(put(cnt/tot_cnt,percent8.1))||")";
run;

proc sort data= disp_2; by status ord; run;

proc transpose data=disp_2 out=trans_2 prefix=tr;
	by status ord;
	id TRT01PN;
	idlabel treat;
	var cnt_prcnt;
run; 

proc sort data =trans_2; by ord status; run;

**-----------------------------------------------------------------------------;
**-----------------------------------------------------------------------------;
title1 font="Courier New" height=8pt "Subject Disposition";
  
proc report data=trans_2 nowd headline headskip split="\" spacing=2;
  columns  ord status  tr:;
  
  define ord / group  order=data noprint;
  define status/group "Subject Disposition"  order=data;
  define tr: /display;
  
  break after ord/skip;
  
  compute after _page_;
		line @2 "Abbreviations:  N = number of subjects in the population; n=number of subjects specified category";
		line @2 "% = Percentage of subjects with N as denominator";
	endcomp;
quit;
run;
