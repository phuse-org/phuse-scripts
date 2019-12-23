%* modification 2019-12-23 - update path as data has been moved;

filename source url "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/adpp.xpt";
libname source xport;

/*
from table shell:

Sheet: PPTS
Compound: ANLPRNT
Matrix: PPSPECL
Analyte: PPCATL
Actual Treatment: TRTAN
Period Day: PPSDY
Stat Order: s_order
PARAM: _PARAM=compbl(put(PPTESTCD ,$pk.)||' ('||strip(PPORRESU)||')')
*/

proc format;
   value TRTAN 1 = "Period 1 Treatment"
               2 = "Period 2 Treatment"
               3 = "Period 3 Treatment";

   value statg 1 = "n"
               2 = "Mean (SD)"
               3 = "CV% mean"
               4 = "Geo-mean"
               5 = "CV% geo-mean"
               6 = "Median"
               7 = "[Min; Max]        ";

   value $ pk "AUCINFO" = "AUC"
              "AUCTAU"  = "AUCtau"
              "AUCLAST" = "AUC(0-tlast)"
              "CMAX"    = "Cmax"
              "CMAXD"   = "Cmax/Dose"
              "MRTLAST" = "MRT"
              "TLAST"   = "tlast"
              "TMAX"    = "tmax"
              "CLRFO"   = "CL/F"
              "VZFO"    = "VzF"
              "LAMZ"    = "lambdaZ"
              "LAMZHL"  = "t1/2"
              "CLAST"   = "Clast";
run;

data adpp;
  set source.adpp;
  where PKFN=1 and ANL01FN ne 1 and paramcd in ('AUCINFO' 'AUCLAST' 'CMAX' 'TMAX' 'MRTLAST' 'LAMZHL') and PPSTRESN ne . and compress(PPCATL)='ANAL2';
  _PARAM = compbl(put(PPTESTCD,$pk.)||' ('||strip(PPORRESU)||')');
  AVAL_log = log(AVAL);
run;

proc sort data=adpp;
  by ANLPRNT PPSPECL PPCATL TRTAN PPSDY _PARAM;
run;

proc univariate data=adpp noprint;
  by ANLPRNT PPSPECL PPCATL TRTAN PPSDY _PARAM;
  var AVAL AVAL_log;
  output out=adpp_sum
         n=n1 n2 mean=mn1 mn2 std=std1 std2 cv=cv1 cv2 median=med1 med2 min=min1 min2 max=max1 max2;
run;

data adpp_sum_t; * adpp_sum transposed;
  set adpp_sum;
  length value $ 30.;
  by ANLPRNT PPSPECL PPCATL;
  s_order = 1; * n;
  value = put(n1, 2.);
  output;
  s_order = 2; * mean (sd);
  select;
    when(index(_PARAM,'AUC')>0)  value = put(mn1,6.) ||' ('||put(std1,5.) ||')';
    when(index(_PARAM,'Cmax')>0) value = put(mn1,5.) ||' ('||put(std1,4.) ||')';
    when(index(_PARAM,'MRT')>0)  value = put(mn1,4.1)||' ('||put(std1,4.2)||')';
    when(index(_PARAM,'t1/2')>0) value = put(mn1,4.2)||' ('||put(std1,4.2)||')';
	otherwise value = ' ';
  end;
  output;
  s_order = 3; * CV% mean;
  if index(_PARAM,'tmax')=0 then value = put(cv1,4.1);
  else value = ' ';
  output;
  s_order = 4; * geo-mean;
  select;
    when(index(_PARAM,'AUC')>0)  value = put(exp(mn2),6.);
    when(index(_PARAM,'Cmax')>0) value = put(exp(mn2),5.);
    when(index(_PARAM,'MRT')>0)  value = put(exp(mn2),4.1);
    when(index(_PARAM,'t1/2')>0) value = put(exp(mn2),4.2);
	otherwise value = ' ';
  end;
  output;
  s_order = 5; * CV% geo-mean;
  if index(_PARAM,'tmax')=0 then value = put(sqrt(exp(std2**2)-1)*100,4.1);
  else value = ' ';
  output;
  s_order = 6; * median;
  select;
    when(index(_PARAM,'AUC')>0)  value = put(med1,6.);
    when(index(_PARAM,'Cmax')>0) value = put(med1,5.);
    when(index(_PARAM,'MRT')>0)  value = put(med1,4.1);
    when(index(_PARAM,'t1/2')>0) value = put(med1,4.2);
    when(index(_PARAM,'tmax')>0) value = put(med1,4.2);
	otherwise;
  end;
  output;
  s_order = 7; /* [min; max] */;
  select;
    when(index(_PARAM,'AUC')>0)  value = '['||put(min1,6.) ||';'||put(max1,6.) ||']';
    when(index(_PARAM,'Cmax')>0) value = '['||put(min1,4.) ||';'||put(max1,5.) ||']';
    when(index(_PARAM,'MRT')>0)  value = '['||put(min1,4.2)||';'||put(max1,4.1)||']';
    when(index(_PARAM,'t1/2')>0) value = '['||put(min1,4.2)||';'||put(max1,4.1)||']';
    when(index(_PARAM,'tmax')>0) value = '['||put(min1,4.2)||';'||put(max1,4.2)||']';
	otherwise;
  end;
  output;
run;

proc sort data=adpp_sum_t;
  by ANLPRNT PPSPECL PPCATL TRTAN PPSDY s_order _PARAM;
run;

TITLE;
FOOTNOTE;

options NOBYLINE;

TITLE1 j=L "Study001";
TITLE2 j=C "Table 14.2-PPTS (Page xxx of xxx)";
TITLE3 j=C "Summary statistics for PK parameters";
TITLE4 j=C "by compound, matrix, analyte and actual treatment";
TITLE5 j=C "Analysis Set: PK analysis set";

FOOTNOTE1 j=L "CV% = coefficient of variation (%) = sd/mean*100";                                            
FOOTNOTE2 j=L "CV% geo-mean = (sqrt(exp(variance for log transformed data)-1))*100";
FOOTNOTE3 j=L "Geo-mean: Geometric mean";
FOOTNOTE4 j=L "Geo-mean and CV% geo-mean not presented when the minimum value for a parameter is zero.";
FOOTNOTE5 j=L "Data: adpp  Program: pps.sas  Output: t.14.2.ppts.txt";
FOOTNOTE6 j=L "Fake Data/ Production Run on 17MAR2014:23:57";

proc report data=adpp_sum_t split="#" nowindows headline formchar(2)="_" headskip spacing=1 
            missing out=CLXCHECKNOBS;
  * Add by variables;
  by ANLPRNT PPSPECL PPCATL;
  * Generate column statement for proc report;
  column ( ANLPRNT PPSPECL PPCATL TRTAN PPSDY s_order _PARAM, value );
  * Generate define statement for all variables;
  define ANLPRNT / " " width=2 left format=$10. noprint group order=data id;
  define PPSPECL / " " width=2 left format=$10. noprint group order=data id;
  define PPCATL  / " " width=2 left format=$15. group noprint id;
  define TRTAN   / "Actual treatment" width=20 left group format=TRTAN. order=data flow;
  define PPSDY   / "Period day" width=8 left group missing;
  define s_order / "Statistic" width=14 left group format=statg. order=internal id;
  define _PARAM  / " " width=15 left across;
  define value   / " " width=19 left group missing flow;
  * If value of macro variable SELECTVAR is not empty, generate a break after statement with it;
  break after PPSDY/skip;
  * Add compute page before statement;
  compute before _page_ / left;
    line +1 "Compound:" +1 ANLPRNT $10. +1 ", Matrix:" +1 PPSPECL $10. +1 ", Analyte:" +1 PPCATL $15.;
    line ' ';
  endcomp;
  * Add compute variables statements (for changing cell styles using criterias);
run;

options BYLINE;
