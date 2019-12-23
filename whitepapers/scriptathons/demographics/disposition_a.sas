/*************************************************/
/* PROGRAM NAME : discontinuation_typeA.sas */
/* Ann Croft 12-Oct-2014 */

%* modification 2019-12-23 - update path as data has been moved;

filename source url "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/adsl.xpt";
libname source xport ;

*** Get data ***;
data adsl;
  set source.adsl;
  where trt01p ne '';
  if trt01pn=0 then trt01pn=3;
  else if trt01pn=54 then trt01pn=1;
  else if trt01pn=81 then trt01pn=2;
run;

*** Get table counts ***;
proc freq data=adsl noprint;
  table studyid * trt01pn * trt01p * disconfl / out=topline (drop=percent);
run;

proc freq data=adsl noprint;
  table studyid * trt01pn * trt01p * DCREASCD / out=midline1 (drop=percent);
  table studyid * DCREASCD   / out=sortord1 (drop=percent);
  where DSRAEFL='Y' or DTHFL='Y';
run;

proc freq data=adsl noprint;
  table studyid * trt01pn * trt01p * DCREASCD / out=midline2 (drop=percent);
  table studyid * DCREASCD   / out=sortord2 (drop=percent);
  where DCdecod='LACK OF EFFICACY';
run;

proc freq data=adsl noprint;
  table studyid * trt01pn * trt01p * DCREASCD / out=midline3 (drop=percent);
  table studyid * DCREASCD / out=sortord3 (drop=percent);
  where DCdecod^='LACK OF EFFICACY' and DSRAEFL^='Y' and DTHFL^='Y';
  where also disconfl='Y';
run;

data all;
  set topline (in=a) midline1 (in=b) midline2 (in=c) midline3 (in=d);
  by studyid trt01pn trt01p;
  if      a then do; ord1=1; ord2=1; end;
  else if b then do; ord1=2; ord2=1; end;
  else if c then do; ord1=3; ord2=2; end;
  else if d then do; ord1=4; ord2=3; end;
run;
data alls;
  set sortord1 (in=b) sortord2 (in=c) sortord3 (in=d);
  by studyid ;
  if      b then do; ord1=2; ord2=1; end;
  else if c then do; ord1=3; ord2=2; end;
  else if d then do; ord1=4; ord2=3; end;
run;

*** Get sort order within table ***;
proc sort data=alls; by ord1 ord2 descending count; run;
data alls2;
  set alls;
  by ord1 ord2 descending count;
  retain ord3 .;
  if first.ord2 then ord3=1;
  else ord3=ord3+1;
run;

*** Get population counts ***;
proc freq data=adsl noprint;
  table studyid * trt01pn * trt01p / out=pop (drop=percent rename=(count=tot));
run;

*** Create output cells with percentage ***;
data allp;
  length dcreascd $200;
  merge all pop;
  by studyid trt01pn trt01p;
  if count ne . then do;
    countc=put(count, 4.)||' ('||put(round(count/tot, 0.1), 5.1)||')';
  end; 
  if ord1=1 then do;
    if disconfl='Y' then DCREASCD='Discontinued'; 
    else DCREASCD='Completed the Study';
  end;
run;

*** Get data ready for output table ***;
proc sort data=allp; by studyid ord1 ord2 dcreascd trt01pn; run;
proc transpose data=allp out=allpt prefix=trt;
  var countc;
  by studyid ord1 ord2 dcreascd;
  id trt01pn;
run;

*** Macro call to determine what treatment groups there are ***;
%global maxc maxt;
data _null_;
  length popc $100;
  set pop end=eof;
  by studyid trt01pn trt01p;
  retain popc '';
  if _n_=1 then popc=strip(put(trt01pn, best.));
  else if _n_>1 then popc=strip(popc)||', '||strip(put(trt01pn, best.));
  call symput('trt'||strip(put(trt01pn, best.))||'c', strip(trt01p)) /*Character Treatment name */;
  call symput('trt'||strip(put(trt01pn, best.))||'n', strip(trt01p)) /* Numberic treatment count*/;
  if eof then do; 
    call symput('maxc', strip(popc));
    call symput('maxt', strip(put(_n_, best.)));
  end;
run;
%put &maxc;
%put &maxt;
*** ***;

*** # is to be used a placeholder for a space for table as rtf does not hold it ***;

%macro zero;
  %do i=1 %to &maxt;
    if trt&i.='' then trt&i.='###0';
    else trt&i.=tranwrd(trt&i., ' ', '#');
  %end;
%mend zero;

*** Set missing cells to zero ***;
data allpt2;
  set allpt;
  %zero;
run;

*** Merge sort order on to table for descending table counts ***;
data allpt3 (keep=studyid dcreascd ord1 ord2 ord3 trt:);
  merge allpt2 alls2;
  by studyid ord1 ord2;
  if ord1=1 and upcase(DCREASCD)='DISCONTINUED' then ord3=2;
  else if ord1=1 then ord3=1;
run;

proc sort data=allpt3;
  by studyid ord1 ord2 ord3;
run;

ods rtf;
%macro disconta;

data final;
  length col1 $200;
  set allpt3;
  *** Work out how many lines per dispostion is needed (space dependant) ***;
  *** Work out how many lines per page can be filled and hence find how many pages required ***;
  pagex=1;
  if ord1=1 then col1=strip(dcreascd);
  else if ord1=3 then col1='####'||strip(dcreascd);
run;

options 
title1 j=l "Table X: Dispostion Table";
title2 j=l "##";
title3 j=l "Subject Disposition";
footnote1 j=l "Abbreviations: N=total number of subjects in population.";
footnote2 j=l "###############n=number of subjects in the specified category";
footnote3 j=l "###############%=Percentage of patients with N as denomiator"; 
footnote4 j=l "##";
footnote5 j=l "##";
footnote6 j=l "Program Location: blah lah blah";

proc report data=final headline split='@' style = {cellpadding =0pt} nowd spacing=0
     style(report)={just=left outputwidth = 25 cm}
     style(lines)=[protectspecialchars=off just=left]
     style(column)= {pretext = "^R'\s2 '"
                     posttext = "   "
                     asis=yes};
     column pagex ord1 ord2  ord3 col1
                  %do i=1 %to &maxt; ("&&trt&i.c @(N=&&trt&i.n)" trt&i) %end; ;
     define pagex    / noprint order order=internal;
     define ord1     / noprint order order=internal;
     define ord2     / noprint order order=internal;
     define ord3     / noprint order order=internal;
     define col1     / "Subject Disposition"  style(column)=[cellwidth= 9.5 cm just=left];
     %do i=1 %to &maxt;
       define trt&i. / "  n   %"  style(column)=[cellwidth= 4.5 cm just=left];
     %end;
     
     compute before ord2 / style(lines)={font_size=9pt font_face="Courier New" font_weight=bold};
       length text $150.; 
       num=150;
       if      ord2=1 then text='##Death or Adverse Event';
       else if ord2=2 then text='##Lack of Efficacy-Related Reasons';
       else if ord2=3 then text='##Other Reasons';
     endcomp;
run;
%mend disconta;
%disconta;
ods rtf close;
