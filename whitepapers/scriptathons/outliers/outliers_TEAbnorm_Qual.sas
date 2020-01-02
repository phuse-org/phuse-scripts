/********************************************************************************
Hello reviewer, I still need some additional information to complete this figure.
Due to the differences of data on the the shell(target), the number of observations 
are overlaped and the legend is not perfect. I am glad if I could continue to
finish it. My name is Xiaopeng Li and I can be reached at xiaopeng.li@celerion.com
********************************************************************************/

%* modification 2019-12-23 - update path as data has been moved;

filename source url "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/advs.xpt";
libname source xport ;
data work.advs ;
  set source.advs ;

  if SAFFL="Y" and PARAMCD="DIABP" and ATPT="AFTER LYING DOWN FOR 5 MINUTES"
     and (AVISITN ge 0 and AVISITN lt 99) and ANL01FL="Y";
keep USUBJID TRTA ADY AVAL;

run ;

/*proc print;run;*/

proc sort; by TRTA ADY; run;

proc means data=advs mean n lclm uclm noprint;
by TRTA ADY;
var aval;
output out=meanvs mean=mean n=num lclm=lclm uclm=uclm;
run;

/*proc print data=meanvs;run;*/

data mean;
  set meanvs;
  keep trta ady mean;
run;


data num;
  set meanvs;
  keep trta ady num;
run;


data ci;
  set meanvs;
  keep trta ady lclm uclm;

if trta="Xanomeline Low Dose" then ady=ady;
else if trta="Xanomeline High Dose" then ady=ady+0.3;
else if trta="Placebo" then ady=ady+0.6;

run;

proc sort; by trta ady; run;

proc print data=ci;run;

data anno;
  length color function style $8.;
  retain xsys ysys '2' when 'a' ;
  set ci;
  if lclm ne . and uclm ne .;

if trta="Placebo" then do;
  function='move'; xsys='2'; ysys='2'; y=lclm; x=ady; color='blue'; output;
  function='draw'; x=ady; y=lclm; color='blue'; width=2; output;
  function='draw'; x=ady; y=uclm;  color='blue'; width=2; output;
  function='move'; y=lclm; xsys='2'; x=ady; color='blue'; width=2; output;
  function='draw'; xsys='9'; x=+0.5; width=2; output;  function='draw';           
                             x=-1; width=2; output;
  function='move'; y=uclm; xsys='2'; x=ady; color='blue'; width=2; output;
  function='draw'; xsys='9'; x=+0.5; width=2; color='blue'; output;
  function='draw';           x=-1; width=2; color='blue'; output;
end;

else if trta="Xanomeline Low Dose" then do;
  function='move'; xsys='2'; ysys='2'; y=lclm; x=ady; color='green'; output;
  function='draw'; x=ady; y=lclm; color='green'; width=2; output;
  function='draw'; x=ady; y=uclm;  color='green'; width=2; output;
  function='move'; y=lclm; xsys='2'; x=ady; color='green'; width=2; output;
  function='draw'; xsys='9'; x=+0.5; width=2; output;  function='draw';           
                             x=-1; width=2; output;
  function='move'; y=uclm; xsys='2'; x=ady; color='green'; width=2; output;
  function='draw'; xsys='9'; x=+0.5; width=2; color='green'; output;
  function='draw';           x=-1; width=2; color='green'; output;
end;

else if trta="Xanomeline High Dose" then do;
  function='move'; xsys='2'; ysys='2'; y=lclm; x=ady; color='red'; output;
  function='draw'; x=ady; y=lclm; color='red'; width=2; output;
  function='draw'; x=ady; y=uclm;  color='red'; width=2; output;
  function='move'; y=lclm; xsys='2'; x=ady; color='red'; width=2; output;
  function='draw'; xsys='9'; x=+0.5; width=2; output;  function='draw';           
                             x=-1; width=2; output;
  function='move'; y=uclm; xsys='2'; x=ady; color='red'; width=2; output;
  function='draw'; xsys='9'; x=+0.5; width=2; color='red'; output;
  function='draw';           x=-1; width=2; color='red'; output;
end;

run;

/*proc print data=anno;run;*/
data num;
   set num;


data anno2;
  length color function style $8.;
  retain xsys ysys '2' when 'a' ;
  set num;
  if num ne .;
  if trta="Placebo" then do;
   x=ady; y=-170; text=trim(left(num));color='blue';
  end;

  else if trta="Xanomeline High Dose" then do;
   x=ady; y=-180; text=trim(left(num)); color='red';
  end;

  else if trta="Xanomeline Low Dose" then do;
   x=ady; y=-190; text=trim(left(num)); color='green';
  end;

run;

data anno;
   set anno anno2;



data final;
    set mean num;
if trta="Xanomeline Low Dose" then ady=ady;
else if trta="Xanomeline High Dose" then ady=ady+0.3;
else if trta="Placebo" then ady=ady+0.6;



/*data observation;
    set meanvs;
drop a1;
rename a2=a1;

data observation;;
   set observation;
if trta="Xanomeline Low Dose" then y=10;
else if trta="Xanomeline High Dose" then trtn=2;
else if trta="Placebo" then trtn=3;
*/

/*******************************axis and symbol************************/

    symbol1 i=j v=dot color='blue';
    symbol2 i=j v=triangle color='red';
    symbol3 i=j v=star color='green';

axis1 label=(a=90 "Systolic blood pressure")
      order=(-200 to 350 by 50);

axis2 label=("Visit number (visit day)")
      order=(0 to 250 by 50);


/**********************************************************************/

title1 " Target 17";
title2 " ";
title3 "Systolic Blood Pressure Figure by Treatment";
title4 " ";
title5 "created by Xiaopeng Li";


proc gplot data=final;
plot mean*ady=trta /*num*ady=trta*/ / /*overlay*/ haxis=axis2 vaxis=axis1 ANNOTATE=anno;

run;
quit;
