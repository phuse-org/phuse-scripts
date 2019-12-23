%* modification 2019-12-23 - update path as data has been moved;

filename source url "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/adsl.xpt";
libname source xport ;

options mprint;

proc format;
   value $destats
     'NC'       = 'n[a]'
     'MEANC'    = 'Mean'
     'STDC'     = 'SD'
     'MEDIANC'  = 'Median'
     'Q1Q3C'    = 'Q1, Q3'
	 'MINMAXC'  = 'Min, Max'
	 'MISSINGC' = 'Missing';

   invalue destatso
     'NC'       = 0
     'MEANC'    = 1
     'STDC'     = 2
     'MEDIANC'  = 3
     'Q1Q3C'    = 4
     'MINMAXC'  = 5
     'MISSINGC' = 6;

    value $sexfmt
	  'N' = 'n[a]'
	  'F' = 'F'
	  'M' = 'M';

	invalue sexfmto
	  'N' = 1
	  'F' = 2
	  'M' = 3;
    
	value $agegrfmt
	  'N'     = 'n[a]'
      '<65'   = '<65'
	  '65-80' = '65-80'
	  '>80'   = '>80';

	invalue agegrfmt
	  'N'     = 1
      '<65'   = 2
	  '65-80' = 3
	  '>80'   = 4;

	value $racefmt
	  'N' = 'n[a]'
	  'WHITE' = 'White'
	  'BLACK OR AFRICAN AMERICAN' = 'Black or African American'
	  'AMERICAN INDIAN OR ALASKA NATIVE' = 'American Indian or Alaska Native';

	invalue racefmto
	  'N' = 1
	  'WHITE' = 2
	  'BLACK OR AFRICAN AMERICAN' = 3
	  'AMERICAN INDIAN OR ALASKA NATIVE' = 4;

	value $ethfmt
	  'N' = 'n[a]'
	  'NOT HISPANIC OR LATINO' = 'Not Hispanic or Latino'
	  'HISPANIC OR LATINO' = 'Hispanic or Latino';

	invalue ethfmto
	  'N' = 1
	  'NOT HISPANIC OR LATINO' = 2
	  'HISPANIC OR LATINO' = 3;
run;

%global trtn trt;
%let trtn = trt01an;
%let trt = trt01a;

data work.adsl;
   set source.adsl;

   where ittfl = 'Y';
run;

proc sort data=adsl out=treatments(keep=&trtn &trt) nodupkey;
   by &trtn;
run;

data treatments;
   set treatments;
   by &trtn;
   
   __dummytrt + 1;
run;

proc sort data=adsl;
   by &trtn;
run;

data adsl_work;
   merge adsl treatments;
   by &trtn;
run;

%global trtnum;

proc sql noprint;
   select strip(put(count(__dummytrt), best.)) into: trtnum
   from treatments;
quit;

%global trt1 trt2 trt3;

%macro bigns;
  proc sql noprint;
    %do i=1 %to &trtnum;
       select count(usubjid) into: trt&i from adsl_work where __dummytrt = &i;
	   select &trt into: trtname&i from adsl_work where __dummytrt = &i;
	%end;
  quit;
%mend bigns;

%bigns;

%macro prcnt(num=,denom=,pctd=pctd,pctfmt=4.0);                               
  do;                                                                           
    length &pctd $9;                                                            
	if &num = 0 and &denom = 0 then &pctd='';
	else do;
	  if &num = 0 then &pctd = '';
      else &pctd = '(' || compress(put(100*&num/&denom,&pctfmt)) || '%)';
	end;
	&pctd = right(&pctd); 
  END;                                                                          
%mend;

%macro descrstats(indata=, outdata=, varn=, dec=, name=, ord=);
   proc sort data=&indata out=__indata;
      by __dummytrt;
   run;

   proc means data=__indata noprint;
      by __dummytrt;
	  var &varn;
	  output out=__meansres n=n mean=mean stddev=std min=min max=max q1=q1 q3=q3 median=median;
   run;

   data __meansres;
      set __meansres;
      nc = put(n,6.0);
      meanc = put(mean,6.%eval(&dec+1));
	  medianc = put(median,6.%eval(&dec+1));
	  stdc = put(std,6.%eval(&dec+1));
	  q1q3c = trim(put(q1,6.%eval(&dec+1)))||', '||trim(put(q3,6.%eval(&dec+1)));
	  minmaxc = trim(put(min,6.%eval(&dec+0)))||', '||put(max,6.%eval(&dec+0));
   run;

   proc transpose data=__meansres out=__trout prefix=col;
      id __dummytrt;
      var nc meanc stdc minmaxc q1q3c medianc; 
   run;

   data __descrres;
      length col1-col&trtnum $50;
      set __trout;
	  length name col0 $200;
	  
	  col0 = put(upcase(_NAME_), $destats.);
	  ord = input(upcase(_NAME_), destatso.);
	  name = &name;
	  mainord = &ord;

      keep name col0 ord col1-col&trtnum mainord;
   run;

   data &outdata;
      set __descrres;
   run;
%mend descrstats;

%descrstats(indata=adsl_work, 
            outdata=ageres,
            varn=age,
            dec=0,
            name="Age (years)",
            ord=2);

%descrstats(indata=adsl_work, 
            outdata=weightres,
            varn=weightbl,
            dec=0,
            name="Weight (kg)",
            ord=5);

%macro freqstats(indata=, outdata=, var=, varfmt=, ordfmt=, name=, ord=);
  proc freq data = &indata noprint;
    tables &var*__dummytrt / out = __frout (drop = percent);
  run;

  proc sql noprint;
    %do i=1 %to &trtnum;
       select count(usubjid) into: denom&i from &indata where ^missing(&var) and __dummytrt = &i;
	%end;
  quit;

  proc sort data = __frout;
    by &var;
  run;

  proc transpose data = __frout out = __trout_fr (drop = _LABEL_ _NAME_ ) prefix=n;
    var count;
    id __dummytrt;
    by &var;
  run;

  data denom;
     &var = "N";
     %do i=1 %to &trtnum;
	     n&i = &&denom&i;
	 %end;
  run;

  data &outdata;
    set __trout_fr denom;
    length name col0 $200 col1-col&trtnum $50;

	%do i=1 %to &trtnum;
      if n&i = . then n&i = 0;
	  %prcnt(num=n&i,denom=&&denom&i,pctd=pct&i,pctfmt=5.1);
      col&i = put(n&i,6.0-R) || pct1;
	%end;

	name = &name;
	col0 = put(&var, $&varfmt..);
	mainord = &ord;
	ord = input(&var, &ordfmt..);
  run;

%mend freqstats;

%freqstats(indata=adsl_work,
           outdata=sexres,
           var=sex,
           varfmt=sexfmt,
		   ordfmt=sexfmto,
           name="Sex n(%)",
           ord=1);

%freqstats(indata=adsl_work,
           outdata=agegrres,
           var=agegr1,
           varfmt=agegrfmt,
		   ordfmt=agegrfmto,
           name="Age categories n(%)",
           ord=3);

%freqstats(indata=adsl_work,
           outdata=raceres,
           var=race,
           varfmt=racefmt,
		   ordfmt=racefmto,
           name="Race n(%)",
           ord=4);

%freqstats(indata=adsl_work,
           outdata=ethnicres,
           var=ethnic,
           varfmt=ethfmt,
		   ordfmt=ethfmto,
           name="Ethnicity n(%)",
           ord=5);

data report;
   set ageres weightres sexres agegrres raceres ethnicres;
run;

options nodate nobyline nonumber nocenter
        formchar='|_---|+|---+=|-/\<>*' charcode;

/*proc printto print="&list\&prog..lst" new;
run;
title;
footnote;*/

title5 "&under";

footnote1 "&under";
footnote2 "n[a] - number of subject with non-missing data, used as denominator";

proc report data=report ls=150 ps=45 split="@"  headline headskip nocenter 
nowd missing spacing=2;
  column mainord name ord col0 col1 col2 col3;
  
  define mainord / order order=internal noprint;
  define ord  / order order=internal noprint;
  define name / display " " width=62 spacing=0 flow order;
  define col0 / display " " width=30 ;
  define col1 / display "&trtname1@      (N=%qcmpres(&trt1))" width=20;
  define col2 / display "trtname1@      (N=%qcmpres(&trt2))" width=20;
  define col3 / display "trtname1@     (N=%qcmpres(&trt3))" width=20;

  break after mainord / skip;
run;

/*proc printto;
run;*/
