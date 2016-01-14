/*soh********************************************************************************************
   CODE NAME         : target26.sas
   DESCRIPTION       : Reference SAS program for target 4
   SOFTWARE/VERSION# : SAS V9
   INPUT             : http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/advs.xpt
--------------------------------------------------------------------------------------------------
   Author:    Prathamesh Athavale / Rucha Landge

**eoh**********************************************************************************************/

filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adae.xpt" ;
filename an_sour url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adsl.xpt" ;

 libname source xport ;
 libname an_sour xport ;

 **** SAE data***;

 data work.adae ;
   set source.adae ;
   keep usubjid trtan aedecod aeser aocc02fl aocc04fl saffl;
   where (aocc02fl='Y' or aocc04fl='Y') and (aeser='Y') and (saffl='Y');
 run ;

proc sort data = adae;
  by usubjid;
run;

***** SUBJECT INFO DATA*****;

  data work.adsl ;
   set an_sour.adsl ;
   keep usubjid trt01an;
   where trt01an ne .;
 run ;

proc sort data = adsl nodupkey;
  by usubjid trt01an;
run;

proc sort data = adae;
  by usubjid;
run;

data adae_sl;
  merge adsl(in = a) adae(in = b);
  by usubjid;
  if a and b;
run;

****DENOMINATOR CALCULATION*****;

proc freq data = adsl noprint;
  table trt01an / out = sum_1(keep = trt01an count);
run;

data _null_;
  set sum_1 end = eof;
  call symput('trtcn'||compress(put(trt01an,8.0)), compress(put(count,8.0)));
  call symput('trtnum'||compress(put(_n_,8.0)), compress(put(trt01an,8.0)));
  if eof then  call symput('numtrt', compress(put(_n_,8.0)));
run;

proc sort data = adae_sl out = adae_sl2 nodupkey;
  by usubjid aedecod;
run;

proc sort data = adae_sl out = adae_dummy(keep = aedecod) nodupkey;
  by aedecod;
  where aocc02fl='Y';
run;

proc sort data = adae_sl2;
  by aedecod;
run;

data adae_sl3;
  merge adae_sl2(in = a) adae_dummy(in = b);
  by aedecod;
  if a and b;
run;

proc freq data = adae_sl3 noprint;
  table aedecod*trtan/out = sum_2(keep = aedecod trtan count);
run;

%macro dummy();
data dummy_2;
  set adae_dummy;
  by aedecod;
  %do i = 1 %to &numtrt;
    if first.aedecod then trtan = &&trtnum&i; output;
  %end;
run;
%mend;

%dummy;

data adae_sl4;
  merge dummy_2(in = a) sum_2(in = b);
  by aedecod trtan;
run;

proc sort data = adae_sl4;
  by trtan;
run;

data adae_sl5;
  merge adae_sl4(in = a) sum_1(rename = (trt01an = trtan count = bign));
  by trtan;
  if a;
run;

data adae_sl6;
  set adae_sl5;
  by trtan aedecod;
  do j = 0 to 1;
  	if first.aedecod then resp = j; 
    if resp = 1 and count ne . then count_final = count;
    else if resp = 1 and count eq . then count_final = 0;
    else if resp = 0 and count ne . then count_final = bign - count;
    else if resp = 0 and count eq . then count_final = bign;output;
  end;
run;

proc sort data = adae_sl6;
  by aedecod;
run;

ods trace on;

ods output FishersExact = fish1;
proc freq data = adae_sl6 ;
  table trtan*resp/out = sum_final sparse fisher;
  weight count_final;
  by aedecod;
  exact fisher;
run;

data fish2(keep = aedecod cvalue1);
  set fish1;
  where name1 = 'XP2_FISH';
run;

data sum_final;
  set sum_final;
  where resp = 1;
  cp = compress(put(count,8.0))||'('||compress(put(count,8.1))||')';
  if trtan = 81 then ord = 1;
  else ord = 2;
run;

proc sort data = sum_final;
  by aedecod ord;
run;

data sum_final;
  set sum_final;
  retain count_max;
  if ord = 1 then count_max = count;
run;

proc sort data = sum_final;
  by aedecod count_max;
run;

proc transpose data = sum_final out = sum_final2 prefix = trt;
  by aedecod count_max;
  id trtan;
  var cp;
run;

data sum_final2;
  merge sum_final2 fish2;
  by aedecod;
run;

proc sort data = sum_final2;
  by descending count_max aedecod;
run;

proc sort data = adae_sl out = adae_sl_sub(keep = usubjid) nodupkey;
  by usubjid;
  where aocc02fl='Y';
run;

***At least one SAE;

data adae_sl_sub2;
  merge adsl(in = a) adae_sl_sub(in = b);
  by usubjid;
  if a;
  if a and b then flg = 1;
  else flg = 0;
run;

***Fisher Test;

ods output FishersExact = fish_sub;
proc freq data = adae_sl_sub2(rename = (trt01an = trtan)) ;
  table trtan*flg/out = sum_final_sub sparse fisher;
  exact fisher;
run;

data fish_sub2(keep = cvalue1);
  set fish_sub;
  where name1 = 'XP2_FISH';
run;

data sum_final_sub;
  length aedecod $100;
  set sum_final_sub;
  where flg = 1;
  cp = compress(put(count,8.0))||'('||compress(put(count,8.1))||')';
  aedecod = 'Number of subjects reporting serious adverse events';
run;

proc sort data = sum_final_sub;
  by aedecod;
run;

proc transpose data = sum_final_sub out = sum_final_sub2 prefix = trt;
  by aedecod;
  id trtan;
  var cp;
run;

data sum_final_sub2;
  merge sum_final_sub2 fish_sub2;
run;

data final_report;
  set sum_final_sub2 sum_final2;
run;

proc report data = final_report headline headskip nowd split = "#";
  column aedecod trt0 trt54 trt81 cvalue1;
  define aedecod /"Preferred Term" width = 40 flow;
  define trt0 /"Placebo#N=&trtcn0" width = 30 flow;
  define trt54/"Treatment 1#N=&trtcn54" width = 30 flow;
  define trt81/"Treatment 2#N=&trtcn81" width = 30 flow;
  define cvalue1/"p-value*b" width = 30 flow;

  compute before _page_;
    line @1 "Table 7.5 Summary of Serious Adverse Events";
	line @1 "Safety Population";
    line @1 "-";
  endcomp;

    compute after _page_;
    line @1 "-";
    line @1 "Denominator for each % is treatment column N";
	line @1 "*b = p-values are from Fisher's Exact Test";
  endcomp;
  run;

**END OF CODE;
