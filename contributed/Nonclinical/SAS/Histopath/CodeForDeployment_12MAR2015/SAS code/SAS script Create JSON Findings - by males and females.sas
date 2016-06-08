
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/*!!!!!!!!   SET THE FOLLOWING LIBNAME TO YOUR SEND STUDY DATA     !!!!!!!!*/
libname send 'd:\send\data\sas data';
/*!!!!!!!!   SET THE FOLLOWING to the file path where you have     !!!!!!!!*/
/*!!!!!!!!   .html file(s) and javascript and css subolders        !!!!!!!!*/
%let jsonFilePath=D:\SEND\FDAProjectFiles\codefordeployment_12Mar2015\;
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/*************************************************************************
**************************************************************************
      SAS script Create JSON Findings - by males and females
      Create one .json file per unique study id

Author: Henrietta Cummings, SAS Institute, winter 2015
************************************************************************** 
**************************************************************************/

%global trendPercent domain ;

/************************************************************************************/
/*-- percent that if count of findings by sex and arm percentage of overall subjects
      examined is greater than, the background color of the cell will be set to blue
      and the cell will contain a hyperlink to a drill down report                --*/
/************************************************************************************/
%let trendPercent=.2;




%macro createAlljson(domain,domainname,jsonwrite,lastloop);

/*options mprint;*/
%macro retrieveDMdomain();
/**************************************************************************************/
/*-- get unique study identifiers, subject identifiers, sex, arm (dosage level),
        microscopic findings: day, &domain.stresc (result or findings as collected),
        modifiers (&domain.resmod) and severity (&domain.sev) 
     need armcd (2 chars) for naming and retrieving hyperlink tables later --*/ 
/**************************************************************************************/ 
proc sql;
	/*- Standardize the ARM value - Strip sex from ARM value if included
	      and translate Vehicle to Control if Vehicle is included -*/
create table WORK.DM&domain.1st as
select distinct dm.studyid, dm.usubjid, dm.sex,  dm.armcd, &domain..&domain.dy, &domain.seq, 
	  &domain..usubjid as &domain.usubjid, &domain..&domain.spec, &domain..&domain.stresc,
	  	/*-- MI and TF have RESCAT column, MA does not --*/
/* 	  case when "&domain." = "MA" then ' '    ?this was not successful?
	       else  &domain..&domain.rescat end as &domain.rescat,*/
      '' as &domain.RESCAT length=14, 
	  &domain..&domain.orres, &domain..&domain.sev,dm.arm as arm_orig,
	  case when upcase(arm) contains 'HIGH' then 'High'
		   when upcase(arm) contains 'LOW' then 'Low'
		   when upcase(arm) contains 'MEDIUM' then 'Medium'
		   when upcase(arm) contains 'VEHICLE' then 'Control' 
		   when upcase(arm) contains 'CONTROL' then 'Control'
		   else arm end as arm
	from SEND.DM, SEND.&domain.
	where dm.studyid=&domain..studyid and dm.usubjid=&domain..usubjid;
quit;
	/*-- update RESCAT for MI or TF --*/
%if "&domain." = "MI" OR "&domain." = "TF" %then %do;
proc sql;
update WORK.DM&domain.1st a
set &domain.rescat = (select &domain.rescat from SEND.&domain. b
                      where a.studyid=b.studyid and a.usubjid=b.usubjid
					    and a.&domain.dy=b.&domain.dy and a.&domain.spec=b.&domain.spec
						and a.&domain.stresc=b.&domain.stresc and a.&domain.orres=b.&domain.orres);
quit;
%end;
%mend;
%retrieveDMdomain();

	/*--	INCLUDE RESMOD from Supplemental    --*/
proc sql;
create table WORK.supp&domain.resmod as
select * from SEND.SUPP&domain.
where trim(upcase(qnam))="&domain.RESMOD" and trim(upcase(idvar))="&domain.SEQ";
 
create table WORK.DM&domain. as
select a.*, b.qval as &domain.resmod
from WORK.DM&domain.1st a left join WORK.SUPP&domain.resmod b
on a.studyid=b.studyid and a.usubjid=b.usubjid and left(put(a.&domain.seq,4.))=b.idvarval;
quit;
    /*-- include study title --*/
proc sql;
create table WORK.DM&domain.Title as
select distinct a.*, b.tsval as studyTitle
from WORK.DM&domain. a left join SEND.TS b
  on a.studyid=b.studyid and upcase(b.tsparm)='STUDY TITLE';

quit;

/**************************************************************************************/
/*-- get counts by study identifiers, subject identifiers, sex, arm (dosage level),
        domain findings: &domain.stresc (result or findings as collected), modifiers
            and severity --*/
/**************************************************************************************/
proc sql;
create table WORK.&domain.findings as
select studyid, &domain.spec, &domain.orres, &domain.stresc, &domain.rescat,
  &domain.resmod, &domain.sev, sex, arm, count(*) as countByARM
from WORK.DM&domain.Title
group by studyid, &domain.spec, &domain.orres, &domain.stresc, &domain.rescat,
         &domain.resmod, &domain.sev, sex, arm;
quit;

/**************************************************************************************/
/*--        get total counts of examined subjects by study id, sex and arm          --*/
/**************************************************************************************/
proc sql;
create table WORK.&domain.TotalSubjects as
select studyid, sex, 
  case when upcase(arm) contains 'HIGH' then 'High'
	   when upcase(arm) contains 'LOW' then 'Low'
	   when upcase(arm) contains 'MEDIUM' then 'Medium'
	   when upcase(arm) contains 'VEHICLE' then 'Control' 
	   when upcase(arm) contains 'CONTROL' then 'Control'
	   else arm end as arm,
  count(*) as totalExamined
from SEND.DM
group by studyid, sex, calculated arm;
quit;

/***************************************************************************/
/*--   join findings with total number of subjects by sex and arm        --*/
/***************************************************************************/
proc sql;
create table WORK.&domain.findingsCounts as
select distinct a.*, b.TotalExamined
from WORK.&domain.findings a, WORK.&domain.TotalSubjects b
where a.studyid=b.studyid and a.sex=b.sex and a.arm=b.arm;
quit;

/***************************************************************************/
/*--           Set the percent of cell count to total subjects           --*/
/*-- create column for arm with spaces and hyphen removed                --*/
/***************************************************************************/
proc sql;
create table WORK.&domain.findingsPercent as
select *, countByARM/totalExamined as countPercent 
from WORK.&domain.findingsCounts;
quit;


   /**********************************************************************/
   /* combine all Sex - ARM counts, total examined and percent of total  */
   /*        into one row per spec, stresc, resmod and severity      --*/
   /**********************************************************************/
   /**********************************************************************/

/* ensure sorted as expected */

proc sort data=WORK.&domain.findingsPercent;
by studyid &domain.spec &domain.orres &domain.stresc &domain.resmod &domain.sev sex arm;
run;


    /*-- transpose to get M and F counts in same row --*/
proc transpose data=WORK.&domain.findingsPercent out=WORK.&domain.counts1 prefix=count;
  by studyid &domain.spec &domain.orres &domain.stresc &domain.resmod &domain.sev;
  id sex arm ;
  var countByARM;
run;
	/*-- TRANSLATE NULL VALUES TO 0 --*/
proc sql;
create table WORK.&domain.counts as
select studyid, &domain.spec, &domain.orres, &domain.stresc, &domain.resmod, &domain.sev,
       case when countFControl is null then 0
	        else countFControl end as countFControl,
       case when countMControl is null then 0
	        else countMControl end as countMControl,
       case when countFlow is null then 0
	        else countFlow end as countFlow,
       case when countMlow is null then 0
	        else countMlow end as countMlow,
       case when countFmedium is null then 0
	        else countFmedium end as countFmedium,
       case when countMmedium is null then 0
	        else countMmedium end as countMmedium,
       case when countFhigh is null then 0
	        else countFhigh end as countFhigh,
       case when countMhigh is null then 0
	        else countMhigh end as countMhigh
from WORK.&domain.counts1;
quit;

    /*-- transpose to get M and F total examined in same row --*/
proc transpose data=WORK.&domain.findingsPercent out=WORK.&domain.totals1 prefix=totalEX;
  by studyid &domain.spec &domain.orres &domain.stresc &domain.resmod &domain.sev;
  id sex arm;
  var totalExamined;
run;
	/*-- TRANSLATE NULL VALUES TO 0 --*/
proc sql;
create table WORK.&domain.totals as
select studyid, &domain.spec, &domain.orres, &domain.stresc, &domain.resmod, &domain.sev,
       case when totalEXFControl is null then 
	           (select totalExamined from WORK.&domain.TotalSubjects 
			   where arm='Control' and sex='F')
	        else totalEXFControl end as totalEXFControl,
       case when totalEXMControl is null then 
	           (select totalExamined from WORK.&domain.TotalSubjects 
			   where arm='Control' and sex='M')
	        else totalEXMControl end as totalEXMControl,
       case when totalEXFlow is null then 
	           (select totalExamined from WORK.&domain.TotalSubjects 
			   where arm='Low' and sex='F')
	        else totalEXFlow end as totalEXFlow,
       case when totalEXMlow is null then 
	           (select totalExamined from WORK.&domain.TotalSubjects 
			   where arm='Low' and sex='M')
	        else totalEXMlow end as totalEXMlow,
       case when totalEXFmedium is null then 
	           (select totalExamined from WORK.&domain.TotalSubjects 
			   where arm='Medium' and sex='F')
	        else totalEXFmedium end as totalEXFmedium,
       case when totalEXMmedium is null then 
	           (select totalExamined from WORK.&domain.TotalSubjects 
			   where arm='Medium' and sex='M')
	        else totalEXMmedium end as totalEXMmedium,
       case when totalEXFhigh is null then 
	           (select totalExamined from WORK.&domain.TotalSubjects 
			   where arm='High' and sex='F')
	        else totalEXFhigh end as totalEXFhigh,
       case when totalEXMhigh is null then 
	           (select totalExamined from WORK.&domain.TotalSubjects 
			   where arm='High' and sex='M')
	        else totalEXMhigh end as totalEXMhigh
from WORK.&domain.totals1;
quit;

    /*-- transpose to get M and F count percents in same row --*/
proc transpose data=WORK.&domain.findingsPercent out=WORK.&domain.percents1 prefix=pct;
  by studyid &domain.spec &domain.orres &domain.stresc &domain.resmod &domain.sev;
  id sex arm;
  var countPercent;
run;
	/*-- TRANSLATE NULL VALUES TO 0 --*/
proc sql;
create table WORK.&domain.percents as
select studyid, &domain.spec, &domain.orres, &domain.stresc, &domain.resmod, &domain.sev,
       case when pctFControl is null then 0
	        else pctFControl end as pctFControl,
       case when pctMControl is null then 0
	        else pctMControl end as pctMControl,
       case when pctFlow is null then 0
	        else pctFlow end as pctFlow,
       case when pctMlow is null then 0
	        else pctMlow end as pctMlow,
       case when pctFmedium is null then 0
	        else pctFmedium end as pctFmedium,
       case when pctMmedium is null then 0
	        else pctMmedium end as pctMmedium,
       case when pctFhigh is null then 0
	        else pctFhigh end as pctFhigh,
       case when pctMhigh is null then 0
	        else pctMhigh end as pctMhigh
from WORK.&domain.percents1;
quit;


data WORK.&domain.countTotalPct_all;
    merge  WORK.&domain.counts WORK.&domain.totals WORK.&domain.percents;
    by studyid &domain.spec &domain.orres &domain.stresc &domain.resmod &domain.sev;
run;
proc sql;
create table WORK.&domain.countTotalPct as
select * from WORK.&domain.countTotalPct_all
WHERE upcase(&domain.stresc) ^= 'NORMAL' ;     /*-- using the standardized results column --*/
quit;

/*-- CREATE LOOKUP TABLE FOR HTML FILE NAMES FOR COUNT TOTAL PCT ROWS --*/
/*--   only creating HTML files for those where results are NOT NORMAL    --*/
data WORK.&domain.lookuphtml1st(keep=studyid &domain.spec &domain.orres &domain.stresc &domain.resmod &domain.sev
                                     mctrlhtml fctrlhtml mlowhtml flowhtml mmedhtml fmedhtml mhighhtml fhighhtml);
set WORK.&domain.countTotalPct;
if _n_ = 1 then uniqueno=1;
else uniqueno = uniqueno + 1;
mctrlhtml = "&domain.MCTRL" || trim(studyid)|| trim(left(put(uniqueno,8.))); 
fctrlhtml = "&domain.FCTRL" || trim(studyid)|| trim(left(put(uniqueno,8.))); 
mlowhtml = "&domain.MLOW" || trim(studyid)|| trim(left(put(uniqueno,8.))); 
flowhtml = "&domain.FLOW" || trim(studyid)|| trim(left(put(uniqueno,8.))); 
mmedhtml = "&domain.MMED" || trim(studyid)|| trim(left(put(uniqueno,8.))); 
fmedhtml = "&domain.FMED" || trim(studyid)|| trim(left(put(uniqueno,8.))); 
mhighhtml = "&domain.MHIGH" || trim(studyid)|| trim(left(put(uniqueno,8.))); 
fhighhtml = "&domain.FHIGH" || trim(studyid)|| trim(left(put(uniqueno,8.))); 

retain uniqueno;
run;

/***************************************************************************/
/* join to get all unique subject id values where count percentage
      is greater than the macro variable trendpercent setting              */
/***************************************************************************/
proc sql;
create table WORK.&domain.JoinforUsubj as
select distinct a.usubjid, b.studyid, a.&domain.dy, b.&domain.spec, b.&domain.orres, 
  b.&domain.stresc, b.&domain.resmod, b.&domain.rescat, b.&domain.sev, 
  b.sex, b.arm 
from WORK.DM&domain. a, WORK.&domain.findingsPercent b
where a.studyid=b.studyid and a.&domain.spec=b.&domain.spec and a.&domain.orres=b.&domain.orres 
    and a.&domain.stresc=b.&domain.stresc and a.&domain.resmod=b.&domain.resmod
    and a.&domain.rescat=b.&domain.rescat and a.&domain.sev=b.&domain.sev 
    and a.sex=b.sex and a.arm=b.arm 
    and b.countPercent > &trendPercent;
quit;

/**************************************************************************/
/*--            Set Planned vs Unplanned days                           --*/
/*-- if record exists in disposition with planned study day (VISITDY)   --*/
/*--   equal to the domain's DY value (MIDY, MADY), then 'P'            --*/
/*-- if disposition study day equal domain's DY value and disposition   --*/
/*--   VISITDY is null, then 'U' unplanned                              --*/
/*-- if no disposition record exists for the domain's DY and unique     --*/
/*--   subject id and MI record exists for the day, then 'US'           --*/
/**************************************************************************/
proc sql;
create table WORK.ds as
select distinct studyid, usubjid, visitdy, dsstdy
from SEND.DS
where usubjid is not null 
order by studyid, usubjid, dsstdy;
quit; 
proc sql;
create table WORK.&domain.JoinforUsubjDay1 as
select distinct a.studyid, a.usubjid, a.&domain.dy as day,
       case when ds.visitdy=a.&domain.dy then 'P '
	        when ds.visitdy is null then 'U ' 
			when ds.dsstdy is null and ds.visitdy is null then 'US'  /* no disposition record */
            else '' end as dayStatus
from WORK.&domain.JoinforUsubj a left join WORK.ds
on a.studyid=ds.studyid and a.usubjid=ds.usubjid 
  and a.&domain.dy=ds.dsstdy 
order by studyid, usubjid;
 
     /*********************************************************/
     /*--     GET ALL DAY/DAYSTATUS INTO THE SAME ROW       --*/
     /*********************************************************/
proc sort data=WORK.&domain.JoinforUsubjDay1;
by studyid usubjid day ; 
run;
proc transpose data=WORK.&domain.JoinforUsubjDay1 out=WORK.&domain.forUsubjtbl prefix=day;
by studyid usubjid;
id day;
var daystatus;
run;
proc sql;
/*-- update to US where no disposition existed for the domain day --*/
update WORK.&domain.JoinforUsubjDay1
set dayStatus = 'US'
where dayStatus is null;
quit;

proc sql;
create table WORK.&domain.JoinforUsubjDay(drop=_name_) as
select distinct a.*, b.&domain.spec, b.&domain.orres, b.&domain.stresc,
       b.&domain.resmod, b.&domain.sev, b.&domain.rescat, b.sex, b.arm
from WORK.&domain.forUsubjtbl a, WORK.&domain.JoinForUsubj b
where a.studyid=b.studyid and a.usubjid=b.usubjid; 
quit;

proc sql;
create table WORK.&domain.JoinforUsubjTBL as
select distinct a.*, 
	   case when a.sex='M' and upcase(a.arm)='CONTROL' then mctrlhtml
	        when a.sex='F' and upcase(a.arm)='CONTROL' then fctrlhtml
            when a.sex='M' and upcase(a.arm)='LOW' then mlowhtml
	        when a.sex='F' and upcase(a.arm)='LOW' then flowhtml 
            when a.sex='M' and upcase(a.arm)='MEDIUM' then mmedhtml
	        when a.sex='F' and upcase(a.arm)='MEDIUM' then fmedhtml 
            when a.sex='M' and upcase(a.arm)='HIGH' then mhighhtml
	        when a.sex='F' and upcase(a.arm)='HIGH' then fhighhtml 
			else ' ' end as htmlfilename
from WORK.&domain.JoinforUsubjDay a left join WORK.&domain.lookuphtml1st b
  on a.studyid=b.studyid and a.&domain.spec=b.&domain.spec and a.&domain.orres=b.&domain.orres 
    and a.&domain.stresc=b.&domain.stresc and a.&domain.resmod=b.&domain.resmod
    and a.&domain.sev=b.&domain.sev 

WHERE a.&domain.stresc ^= 'NORMAL'
;
quit;


/**************************************************************/
/*       SET HTMLFILENAME for 1st drill down reports          */
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/* htmlfilename identifies the object(s) for the drill down in the JSON file */
/**************************************************************/
/**********************************************************************/
/*-- naming convention for html files: 
       values of &domain || sex || arm || studyid || a number beginning with 1 and incremented 
         for each new html file created 
       ex: MHIGHCT12341 where 'M' is the value of sex,
           'HIGH' is the value of arm,
           'CT1234' is the studyid and 1 is the unique sequential number;
           FCT12342 where 'F' is the value of sex,
           'CT1234' is the studyid and 2 is the unique sequential number;
**************************************************************************/
	/*-- ensure sorted as expected --*/
proc sort data=WORK.&domain.JoinforUsubjTBL;
by studyid &domain.spec &domain.orres &domain.stresc &domain.resmod &domain.rescat 
   &domain.sev sex arm usubjid ;
run;

        /************************************************/
        /*-- create the table/dataset containing rows 
              with html file names for report 1 drill down 1
                 and for report 1 drill down 2        --*/ 
        /************************************************/
data WORK.&domain.FindingsUsubjDay(drop=uniqueno domainVal);

set WORK.&domain.JoinforUsubjTBL;

by studyid &domain.spec &domain.orres &domain.stresc &domain.resmod
   &domain.rescat &domain.sev sex arm usubjid ;    

if last.studyid OR last.&domain.spec OR last.&domain.orres OR last.&domain.stresc OR last.&domain.resmod
   OR last.&domain.sev OR last.sex OR last.arm OR last.usubjid then do;       

  if _n_ = 1 OR uniqueno = . then uniqueno = 1;   /* for creating html2name*/

  if sex = 'F' then sexVal = 'Female';
  else 
    if sex = 'M' then sexVal = 'Male';

  domainVal = symget("domain");
  select (domainval);
     when ('MI') findingsTitle='Microscopic Findings';
     when ('MA') findingsTitle='Macroscopic Findings';
     when ('TF') findingstitle='Tumor Findings';
	 otherwise findingstitle='Findings';
  end;

  html2name=compress(studyid,'- ') || "_" || "&domain." || compress(sex) || compress(usubjid,'- ');

  groupTitle = trim(ARM) || ' Dose';

  output;    /* WRITE ROW for USUBJID and findings DAY */

  	/*-- increment for next group --*/
  uniqueno=uniqueno+1;
end;


retain uniqueno;

run;

proc sort data=WORK.&domain.FindingsUsubjDay;
by studyid &domain.spec &domain.orres &domain.stresc &domain.resmod
   &domain.rescat &domain.sev sex arm usubjid  ; 
run;

     /**********************************************************/
     /*--       unique values to create html files for       --*/
     /*-- INPUT TABLE ONLY INCLUDES ROWS THAT ARE NOT NORMAL --*/
     /**********************************************************/
proc sql;
create table WORK.&domain.drill1studyid as
select distinct studyid from WORK.&domain.FindingsUsubjDay;
quit;


    /****************************************************************/
    /*-- Enumerate drill1rpts list and put list into macro variable  --*/
    /****************************************************************/
proc sql noprint;
select count(*) into:numDrill1st from WORK.&domain.drill1studyid;
select studyid into:listDrill1st separated by ' ' from WORK.&domain.drill1studyid;
select count(distinct &domain.dy) into:uniqueDays from WORK.DM&domain.;
select name into:DaysName separated by ' ' from dictionary.columns
where upcase(libname)='WORK' and upcase(memname)="&domain.FINDINGSUSUBJDAY"
  and upcase(name) like 'DAY%';
select name into:dayCols separated by ', ' from dictionary.columns
where upcase(libname)='WORK' and upcase(memname)="&domain.FINDINGSUSUBJDAY"
  and upcase(name) like 'DAY%';
quit;


/*******************************************************************/
/*-- MACRO TO  CREATE FINDINGS REPORT HTML FILE for each STUDYID --*/
/*******************************************************************/
 
%macro createDrill1st(i);
   /*-- Scan through &listDrill1st to get the current StudyID value --*/
%let studyid=%scan(&listDrill1st,&i);
%let findingsTitle=&domainName. Findings;
%let jsonfile1=&jsonfilepath.&studyid._DRILLDOWN.json;

/*********************************************************************/
/*    WRITE to the JSON file from WORK.&domain.FindingsUsubjDay      */
/*      for the current STUDYID for the FIRST DRILL DOWN LINKS       */
/*********************************************************************/

proc sql;
create table WORK.findingsDrillDown as
select htmlfilename, findingsTitle, &domain.orres as findings, groupTitle label='Group:', 
       sexval label='Sex:', &domain.spec as TissueName label='Tissue Name:', 
       usubjid label='Unique Subject ID', &domain.sev as Severity label='Severity',
       trim(html2name) as html2name, &domain.rescat as rescat label='Results Category', &daycols.
from WORK.&domain.FindingsUsubjDay 
where studyid="&studyid." 
order by htmlfilename, usubjid;
quit;

/*-- WRITE ALL DRILL-DOWN DATA TO THE SAME .JSON FILE FOR EACH UNIQUE STUDYID --*/
data _null_;
file "&jsonfile1." &jsonWrite.;

length tempVal $100 dayXNm $40 dayNm $40 ;
set WORK.findingsDrillDown end=eof;

by htmlfilename;

/*-- if first set of data already written, start with a comma --*/
if _n_ = 1 then 
  if "&jsonWrite." = "MOD" then 
    put ', ' ;
  else
    put '{ ' ;

if first.htmlfilename then do;  
  tempVal = '"' || strip(htmlfilename) || '": [ {' ;
  put tempVal ;
end;
else put ' { ';
tempVal = '"htmlfilename": "' || strip(htmlfilename) || '",' ; 
put tempVal;
put '"findingstitle": "' findingsTitle'",';
put '"findings": "' findings '",' ;
put '"grouptitle": "' groupTitle '",' ;
put '"sexval": "' sexval '",' ;
put '"tissuename": "' tissuename '",' ;
tempVal = '"usubjid": "' || strip(usubjid) ||   '",' ;
put tempVal;
tempVal = '"html2ndname": "' || strip(html2name) ||   '",' ;
put tempVal;
put '"severity": "' severity '",' ;
put '"rescat": "' rescat '",' ;
/***********************************************************/
/*     DAY columns are dynamic, write these in a loop      */
/* daysName was set with sql into: from dictionary.columns */
/***********************************************************/
%do x = 1 %to &uniqueDays;
  %let dayName=%scan(&daysName,&x);
  dayNm = '"day' || strip(left(put(&x.,8.))) || '":'; 
  tempVal = '"' || strip("&dayName") || '"';
  put dayNm  tempVal ',';
  %if &x < &uniqueDays %then %do;
    dayXnm = '"day' || strip(left(put(&x.,8.))) || 'val":';
	put dayXnm '"' &dayname '",';
  %end;
  %else %do;
    dayXnm = '"day' || strip(left(put(&x.,8.))) || 'val":';
	put dayXnm '"' &dayname '"';
  %end;
%end;

if eof=1 then put '} ]  ' ;
else do;
  if last.htmlfilename then
    put '} ] ,' ;
  else put '},' ;
end;

run;


%mend;

  /*********************************************************/
  /*-- Macro for looping through studyId report creation --*/
  /*********************************************************/
%macro loop1st;
  %do j=1 %to &numDrill1st;
    %createDrill1st(i=&j);
  %end;
%mend;

%loop1st;


/***********************************************************************/
/*-- RETRIEVE TX (Trial Sets) VALUES FOR SECOND DRILL DOWN REPORT - 
       UNIQUE SUBJECT IDENTIFIER DETAILS for USUBJID values that are 
       in the first drill down report                                  */
/***********************************************************************/
proc sql;
create table WORK.dm&domain._setcd as
select distinct a.studyid, a.armcd, tx.setcd, a.sex, a.arm
from WORK.DM&domain. a left join SEND.TX
  on a.studyid=tx.studyid and upcase(tx.txparmcd)='ARMCD' and a.armcd=tx.txval;
quit;

/*-- above can result in more than one setcd value per unique subject
  		keep the first                                                --*/
proc sort data=WORK.dm&domain._setcd nodupkeys;
by studyid armcd sex arm;
run;

PROC SQL;
	/*-- Sponsor Defined Group Code --*/
create table WORK.&domain.GetGroupValCD as
select distinct a.studyid, a.armcd, a.setcd, a.sex, a.arm, tx.txval as spgrpcd
from WORK.DM&domain._setcd a left join SEND.TX
  on a.studyid=tx.studyid and a.setcd=tx.setcd
  and upcase(tx.txparmcd) = 'SPGRPCD' ;

	/*-- Sponsor Defined Group Label --*/
create table WORK.&domain.GetGroupValLbl as
select distinct a.studyid, a.setcd, a.sex, a.arm, tx.txval as grplbl
from WORK.DM&domain._setcd a left join SEND.TX
  on a.studyid=tx.studyid and a.setcd=tx.setcd
  and upcase(tx.txparmcd) = 'GRPLBL' ;

	/*-- Control Type --*/
create table WORK.&domain.GetControlType as
select distinct a.studyid, a.setcd, a.sex, a.arm, tx.txval as controlType
from WORK.DM&domain._setcd a left join SEND.TX
  on a.studyid=tx.studyid and a.setcd=tx.setcd
  and upcase(tx.txparmcd) = 'TCNTRL' ;

quit;


/**************************************************************************/
/*-- RETRIEVE ADDITIONAL DM COLUMNS NEEDED FOR SECOND DRILL DOWN REPORT --*/
/**************************************************************************/
proc sql;
create table WORK.&domain.GetDMvalues as
select distinct a.usubjid label='Unique Study Identifier', a.sex label='Sex',
       a.arm, dm.armcd, dm.arm as arm_orig, /*a.setcd,*/ /*&domain.orres, &domain.stresc,*/
       dm.species label='Species', 
       dm.strain label='Strain/Substrain',
       dm.sbstrain label='Strain/Substrain Details', 
       '' as subjrefStrtSrc label='Subject Reference Start Date/Time(Source)',
       dm.rfstdtc label='Subject Reference Start Date/Time',
       '' as subjRefEndSrc label='Subject Reference End Date/Time(Source)',
       dm.rfendtc label='Subject Reference End Date/Time',
       '' as dateOfBirthSrc 'Date of Birth(Source)',
       dm.brthdtc label='Date of Birth', dm.agetxt label='Age Range',
       dm.ageu label='Age Unit', A.STUDYID       
from WORK.&domain.FindingsUsubjDay a, SEND.DM
where a.studyid=dm.studyid and a.usubjid=dm.usubjid ;          
quit;

/*????????????????????????????????????????????????????????????????????*/
/*??????????????????????? NEED Animal's Pathogen Status, Common Name,
      Threat Day and Order of Threat 

'' as threatDay label='Threat Day',
       '' as orderOfThreat label='Order of Threat',
???????????????????????????????????????????????????????????*/
/*????????????????????????????????????????????????????????????????????*/

proc sql;
/***********************************************************************/
/*-- CREATE TABLE/DATASET WITH ALL ROWS FOR USUBJID values that will --*/
/*-- be available for second drill down                              --*/
/***********************************************************************/
create table WORK.&domain.usubjidDetails as
select distinct a.*, b.spgrpcd, c.grplbl, d.controlType, 
  compress(a.studyid,'- ') || "_" || "&domain." || compress(a.sex) || compress(a.usubjid,'- ') 
    as html2name, d.setcd,
  case when "&domain." = 'MI' then 'Microscopic Findings'
       when "&domain." = 'MA' then 'Macroscopic Findings'
       when "&domain." = 'TF' then 'Tumor Findings'
	   else 'Findings' end as findingstitle
from WORK.&domain.GetDMvalues a, WORK.&domain.GetGroupValCD b, WORK.&domain.GetGroupValLbl c, WORK.&domain.GetControlType d
where a.studyid=b.studyid and a.sex=b.sex and a.arm=b.arm
  and a.studyid=c.studyid and a.sex=c.sex and a.arm=c.arm
  and a.studyid=d.studyid and a.sex=d.sex and a.arm=d.arm ;
quit;
/*-- unique .json files to be written - one for each study --*/
proc sql;
create table WORK.&domain.usubjid2nddrill as
select distinct studyid from WORK.&domain.usubjidDetails;
quit;

/**********************************************************************/
/*-- LINKS on USUBJID values in first drill down report --*/
/**********************************************************************/
/*-- naming convention: values of studyid || _ || domain || sex || usubjid
       to be created; ex: MCT1234CT1234007 where 'M' is the value of sex,
            'CT1234' is the studyid and CT1234007 is the value of usubjid;
                          FCT1234CT1234008 where 'F' is the value of sex,
            'CT1234' is the studyid and CT1234008 is the USUBJID value;
**************************************************************************/
    /****************************************************************/
    /*-- Enumerate drill2rpts list and put list into macro variable  --*/
    /****************************************************************/
proc sql noprint;
select count(*) into:numDrill2nd from WORK.&domain.usubjid2nddrill;
select studyid into:listDrill2nd separated by ' ' from WORK.&domain.usubjid2nddrill;
quit;


/*******************************************************************/
/*-- MACRO TO CREATE USUBJ REPORTs' .json FILE for each STUDYID  --*/
/*******************************************************************/
 
%macro createDrill2nd(i);
   /*-- Scan through &listDrill2nd to get studyid value --*/
%let studyid=%scan(&listDrill2nd,&i);
%let jsonfile1=&jsonfilepath.&studyid._DRILLDOWN.JSON;

/*********************************************************************/
/*    WRITE to the .JSON file from WORK.&domain.usubjDetails         */
/*      for the current STUDYID for the FIRST DRILL DOWN LINKS       */
/*********************************************************************/
proc sql;
create table WORK.usubjDrillDown as
select distinct html2name, usubjid, spgrpcd, grplbl, controltype, species, strain, sbstrain, 
       subjrefstrtsrc, rfstdtc, subjrefendsrc, rfendtc, dateofbirthsrc,
       brthdtc, agetxt, ageu, armcd, arm_orig, /*setcd,*/ studyid, findingstitle 
from WORK.&domain.usubjidDetails 
where studyid="&studyid." 
order by html2name, usubjid;
quit;


data _null_;
/***************************************************************************/
/***       ALWAYS USE MOD to append .json data for 2nd drilldown         ***/
/*** and begin the write to the existing .json file with a comma to
       separate the first object being written from the last object output
       from the previous data _null_ for the 1st drilldown               ***/
/***************************************************************************/
file "&jsonfile1." MOD;
set WORK.usubjDrillDown end=eof;
length tempVal $100;

/*-- start with a comma to separate new object from last object --*/
if _n_ = 1 then 
  put ', ' ;

/*-- Each row has a unique HTLM2NAME --*/
tempVal = '"' || strip(html2name) ||  '": [ {' ;
put tempVal;

tempVal = '"html2name": "' || strip(html2name) ||   '",' ;
put tempVal;
put '"findingstitle": "' findingsTitle'",';
tempVal = '"usubjid": "' || strip(usubjid) ||   '",' ;
put tempVal;
put '"spgrpcd": "' spgrpcd '",' ;
put '"grplbl": "' grplbl '",' ;
put '"controltype": "' controltype '",' ;
put '"species": "' species '",' ;
put '"strain": "' strain '",' ;
put '"sbstrain": "' sbstrain '",' ;
put '"subjrefstrtsrc": "' subjrefstrtsrc '",' ;
put '"rfstdtc": "' rfstdtc '",' ;
put '"subjrefendsrc": "' subjrefendsrc '",' ;
put '"rfendtc": "' rfendtc '",' ;
put '"dateofbirthsrc": "' dateofbirthsrc '",' ;
put '"brthdtc": "' brthdtc '",' ;
put '"agetxt": "' agetxt '",' ;
put '"ageu": "' ageu '",' ;
put '"armcd": "' armcd '",' ;
put '"arm_orig": "' arm_orig '"' ;

if eof=1 then do;
  if &lastLoop. = 0 then
    put '} ]  ' ;
  else
    put '} ]    }' ;    /*-- at the end of writing to .json; include } to close the .json file --*/
end;
else do;
  put '} ] ,' ;   /*-- end the object and include , before next object --*/
end;

run;

%mend;

  /*********************************************************/
  /*-- Macro for looping through studyId report creation --*/
  /*********************************************************/
%macro loop2nd;
  %do j=1 %to &numDrill2nd;
    %createDrill2nd(i=&j);
  %end;
%mend;

%loop2nd; 



%mend createAlljson;


/**************************************/
/*-- Findings domain: MI, MA, or TF --*/
/**************************************/
%createAlljson(MI,Microscopic,,0);
%createAlljson(MA,Macroscopic,MOD,1);

