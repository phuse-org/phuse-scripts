/*----------------------------------------------------------------------------;
Target 32: Subjects who Discontinue 

Annotations 

Dataset: ADSL
 Variables: USUBJID, TRTAN, DSREASCD, DSTERM, ITTFL
 Record Selection: WHERE ITTFL=�Y� 

Subject ID = USUBJID.
 Reason for Discontinuation = DSREASCD.
 Textual Reason = DSTERM
 Sort by STUDYID and USUBJID.
**---------------------------------------------------------------------------*/

%let _dd=adsl;
options mlogic mprint;


**----------------------------------------------------------------------------;
** phuse scripathon standard access code;
**----------------------------------------------------------------------------;
*filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adsl.xpt" ;

%* modification 2019-12-23 - update path as data has been moved, still not working as variables are not in ADSL;

filename source url "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/&_dd..xpt";
libname source xport ;


**----------------------------------------------------------------------------;
** test print;
**----------------------------------------------------------------------------;
proc contents data=source.&_dd;
run;

data work.adsl ;
set source.adsl ;
keep usubjid ;
run ;
proc print data=work.adsl ;
title1 "A test of accessing datasets from the PhUSE Code Repository" ;
run ;


%macro stdrep;





**----------------------------------------------------------------------------;
** input patient population;
**----------------------------------------------------------------------------;
%let _it = Y /*Y=Randomized*/ /*blank=Enrolled*/;
%if "%upcase(&_it)"="Y"
   %then %let _pp = Randomized;
   %else %let _pp = Enrolled;


**----------------------------------------------------------------------------;
** input user specified titles;
**----------------------------------------------------------------------------;
%let _tt1 = %str(Listing 7.1  &_pp Subjects who Discontinue due to Physician Decision,);
%let _tt2 = %str(Withdrawal by Subject, Withdrawal by Parent/Guardian, or Other);
%let _tt3 = %str(Study: London 2014 Script-athon);


**----------------------------------------------------------------------------;
** select and sort data for reporting;
**----------------------------------------------------------------------------;
proc sql;
   create table _rp as
   select USUBJID
         ,TRTAN
         ,DSREASCD
         ,DSTERM
         ,ITTFL
   from source.&_dd
   %if "%upcase(&_it)"="Y" %then %do; where ITTFL='Y'; %end;
   ;
run;
quit;


**----------------------------------------------------------------------------;
** report;
**----------------------------------------------------------------------------;
options missing=''  formchar='|____|+|___+=|_/\<>*';

proc report data=_rp nowd headline headskip missing split='?' spacing=2 list;
  
   column TRTAN USUBJID DSREASCD DSTERM;   
   by TRTAN;

   define TRTAN   /order order=internal noprint;
   define USUBJID /display width=15 'Subject?ID';
   define DSREASCD/display width=30 'Reason for?Discontinuation';
   define DSTERM  /display width=30 'Textual Reason';
 
   compute before TRTAN;
      put 'Treatment: #TRTAN#';
	  put line;
   endcomp;
run; 

%endmac:

%mend stdrep;

**----------------------------------------------------------------------------;
**;
**----------------------------------------------------------------------------;
%stdrep;
