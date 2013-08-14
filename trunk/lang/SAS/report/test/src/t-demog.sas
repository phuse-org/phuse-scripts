*--------------------------------------------------------------------*;
*  Project: PhUSE Codeathon 2014
*
*  Program name: t-demog.sas
*  Developer/Programmer: artieocollins@gmail.com
*  Date: 14Aug2013
*
*  Purpose: Demography
*
*  Platform:    
*  SAS Version: 
*
*  Modifications: 
*
*--------------------------------------------------------------------*;

**** Formats ****;

proc format;
 
  value sex
        1     =  'Male'
        2     =  'Female'
         ;

  value age
        1     =  '  18-19'
        2     =  '  20-29'
        3     =  '  30-39'
        4     =  '  40-49'
        5     =  '  50-59'
        6     =  '  >=60 '
        ;

  value race
        1     =  'Black'
        2     =  'White'
        3     =  'Asian'
        4     =  'Hispanic'
        5     =  'Other'
        ;

run;

**** Bring in data ****;

filename mcsldata url "http://phuse-scripts.googlecode.com/svn/trunk/lang/R/report/test/data/mcsl.csv" ;

data mcsl ;   
  infile mcsldata delimiter="," firstobs=2 missover ;  
  length studyid $20 usubjid $20 trt01a $20 ageu $10 race $25 sex $1 saffl $1 efffl $1 dcdecod $50 dcreascd $50 ;
  length trt01an age racen bmibl heightbl weightbl 8 ;   input studyid $ usubjid $ trt01a $ trt01an age ageu $ race $ racen 
         sex $ saffl $ efffl $ bmibl heightbl weightbl dcdecod $ dcreascd $ ;  
  if sex='M' then sexn=1;
    else if sex='F' then sexn=2;
run;

/*
proc freq;
  tables trt01an*age trt01an*sex / missing list;
endsas;
*/

**** Categorize age ****;

data age1(keep=trt01an usubjid age agecat);
  set mcsl;
  if 18 <= age <=19 then agecat=1;
    else if 20 <= age <=29 then agecat=2;
    else if 30 <= age <=39 then agecat=3;
    else if 40 <= age <=49 then agecat=4;
    else if 50 <= age <=59 then agecat=5;
    else if age>=60 then agecat=6;
    else delete;
run;

proc sql;
  create table agenums as
  select 1 as cat, agecat as subcat, trt01an, agecat, count(distinct usubjid) as num from age1
  group by cat, subcat, trt01an, agecat;

  create table agetots as
  select 1 as cat, agecat as subcat, agecat, count(distinct usubjid) as num from age1
  group by cat, agecat;
quit;

data agecat;
  set agenums agetots(in=x);
  if x then trt01an='99';
  text='  '||put(agecat, age.);
run;

proc sort data=agecat;
  by cat subcat descending agecat;
run;

proc transpose data=agecat prefix=trt out=age(drop=agecat);
  var num;
  by cat subcat descending agecat text;
  id trt01an;
run;

**** gender ****;

proc sql;
  create table sexg as
  select 2 as cat, sexn as subcat, trt01an, sexn, count(distinct usubjid) as num from mcsl
  where sex^=' '
  group by cat, subcat, trt01an, sexn;

  create table sext as
  select 2 as cat, sexn as subcat,  sexn, count(distinct usubjid) as num from mcsl
  where sexn^=.
  group by cat, subcat, sexn;
quit;

data sexcat;
  set sexg sext(in=x);
  if x then trt01an='99';
  text='  '||put(sexn,sex.);
run;

proc sort data=sexcat;
  by cat subcat descending sexn;
run;

proc transpose data=sexcat prefix=trt out=sex(drop=sexn);
  var num;
  by cat subcat descending sexn text;
  id trt01an;
run;

**** Race ****;

**** Bring the data together *****;
data final;
  set age sex;
  by cat subcat;
  array col (4) $;
  col1=put(trt0, 3.);
  col2=put(trt54, 3.);
  col3=put(trt81, 3.);
  col4=put(trt99, 3.);
  output;
  if first.cat then do;
    do i=1 to dim(col);
      col(i)='';  
    end;
    subcat=0;
    if cat=1 then text='Age';
      else if cat=2 then text='Gender';
    output;
  end;
run;

proc sort data=final;
  by cat subcat;
run;

**** Generate report ****;

proc report data=final nowd headline headskip split='*' missing;
  column cat subcat text col1 col2 col3 col4;

  define cat     / order order=internal noprint " ";
  define subcat  / order order=internal noprint " ";
  define text    / display width=30 left flow " ";
  define col1    / display width=12 left "Group 1";
  define col2    / display width=12 left "Group 2";
  define col3    / display width=12 left "Group 3";
  define col4    / display width=12 left "Total";

  break after cat/skip;

  title1 "Demography";
  footnote1 "NOTE: Numbers in parentheses are percentages                            ";

run;

