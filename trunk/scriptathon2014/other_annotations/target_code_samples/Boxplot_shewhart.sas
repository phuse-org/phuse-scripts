 options ps=60 ls=80 nodate;
 goptions ftext=none htext=1 cell;
 

 title1 'Boxchart with Summary Statistics - Laboratory Analysis';
 title2 'Change from Base - Lab Test 1';
 

 data one;
     do visit = 1 to 10 ;
       input n mean std;
	   label lab_test_1='Measure (unit)'; 
       do i = 1 to n;
		   do trt=0 to 1;
		       id=i+(trt+1)*1000;
	          lab_test_1 = mean + std*rannor(234111);
	          output;
		   end;
	   end;
    end;
    drop i n mean std;
 cards;
 60 7.3 .55
 73 7.1 .65
 59 6.7 .45
 83 7.0 .50
 70 7.6 .70
 92 7.3 .55
 73 6.7 .55
 89 7.1 .45
 
 ;
run; 

proc sort data=one;
 by id trt visit;

data new;
 set one;
 by id trt visit;
 retain bse;
 if first.id then do;
    if visit>2 then bse=0;
	else bse=1;
 end;
 if bse=0 then delete;
 drop bse;
run;


data Base PostBse;
 set new;
 if visit<=2 then output Base;
 else if visit>2 then output PostBse;
run;

 /****************************************************************
  * Baseline side by side and postbaseline side by side
  ****************************************************************/
%macro process(in, out, add);
	proc sort data=&in;
	  by id visit;
	run;

	data &out;
	 set &in;
	 by id visit;
	 length label $ 40.;
	 length category $15;
	 keep visit id trt category label point result;
	 retain min&out max&out;
	 if first.id then do;
	   min&out=lab_test_1;
	   max&out=lab_test_1; 
	 end;
	 else do;
	  if min&out>lab_test_1 then min&out=lab_test_1;
	  if max&out<lab_test_1 then max&out=lab_test_1;
	 end;
	 if last.id then do;
	  category="&out";
	  label="Last baseline to last postbaseline";
	  point=1+&add;
	  result=lab_test_1;
      output;
	  label="Min baseline to min postbaseline";
	  point=4+&add;
	  result=min&out;
      output;
	  label="Max baseline to max postbaseline";
	  point=7+&add;
	  result=max&out;
      output;
	 end;
	run;
%mend process;
%process(Base, bse, 0);
%process(PostBse, pst, 0.4);

data bse_pst;
 set bse pst;
 if trt=1 then point=point+1;
run;

proc sort data=bse_pst;
  by id label category;
data change;
 set bse_pst;
 by id label category;
 retain bse;
 if first.label then bse=result;
 if last.label then output;
run; 

data change;
 set change;
 change=result-bse;
run;
 
proc freq data=change;
 tables label;
run;

proc sort data=change;
 by label;
run; 

ods trace on;
ods trace off;
ods listing close;
ods output Tests3=pval;
proc mixed data=change;
  by label;
  class trt;
  model change=bse trt;
run;

* Compute subgroup size, mean, and standard deviation ;
 proc sort data=bse_pst;
  by category label point trt;

 proc means data=bse_pst noprint;
    by category label point trt;
    var result;
    output out=stats n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
 run;

data trtpval;
 set pval;
 trt=1;
 length category $ 15;
 category='pst';
run; 
proc sort data=trtpval;
  where effect='trt';
 by label category trt;
proc sort data=stats;
 by label category trt;

data summary;
 merge stats trtpval(keep=category effect label trt ProbF Fvalue);
 by label category trt;
run; 

/*
  * Create block variables used to produce table ;
 data blocks;
    length  block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 Block10 $40.;
    keep block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 trt point category label treatment;
    set summary;
		if trt=0 then Treatment=' A';
	if trt=1 then Treatment=' B';
       blck2 = n;
       blck3 = mean;
       blck4 = std;
	   blck5 = min;
	   blck6=q1;
	   blck7=median;
	   blck8=max;
	   blck9=q3;
       blck10=ProbF; 
    block2 = strip(put(blck2,10.0));
    block3 = strip(put(blck3,10.2));
    block4 = strip(put(blck4,10.2));
	block5 = strip(put(blck5,10.2));
    block6 = strip(put(blck6,10.2));
    block7 = strip(put(blck7,10.2));
	block8 = strip(put(blck8,10.2));
    block9 = strip(put(blck9,10.2));
    block10 = strip(put(blck10,5.3));
    block2 = left(block2);
    block3 = left(block3);
    block4 = left(block4);
	block5 = left(block5);
    block6 = left(block6);
    block7 = left(block7);
	block8 = left(block8);
    block9 = left(block9);
	block10 = left(block10);
	block1= treatment;
	block0=category;
    if _n_ = 1 then do;
       block2 = left('N                               ')||trim(block2);
       block3 = left('Mean                        ')||trim(block3);
       block4 = left('Std                           ')||trim(block4);	   
       block5 = left('Min                           ')||trim(block5);
       block6 = left('Q1                            ')||trim(block6);
	   block7 = left('Median                      ')||trim(block7);
	   block8 = left('Q3                            ')||trim(block8);
	   block9 = left('Max                          ')||trim(block9);
	  block10 = left('P Value                      ');
       block1 = left('Treatment                   ') ||trim(block1);
	   block0 =left('Period                       ')||trim(category);
       end;
	run;

proc sort data=blocks;
 by category label point trt;

 data CenTend1;
    merge bse_pst blocks;
    by category label point trt;
	*_phase_=Compress(label||'_'||category);
	_phase_=label;
 run;
    */


 * Create block variables used to produce table ;
 data blocks;
    length  block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 Block10 $40.;
    keep block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 trt point category label treatment;
    set summary;
		if trt=0 then Treatment=' A';
	if trt=1 then Treatment=' B';
       blck2 = n;
       blck3 = mean;
       blck4 = std;
	   blck5 = min;
	   blck6=q1;
	   blck7=median;
	   blck8=max;
	   blck9=q3;
       blck10=ProbF; 
    block2 = strip(put(blck2,10.0));
    block3 = strip(put(blck3,10.2));
    block4 = strip(put(blck4,10.2));
	block5 = strip(put(blck5,10.2));
    block6 = strip(put(blck6,10.2));
    block7 = strip(put(blck7,10.2));
	block8 = strip(put(blck8,10.2));
    block9 = strip(put(blck9,10.2));
    block10 = strip(put(blck10,5.3));
    block2 = left(block2);
    block3 = left(block3);
    block4 = left(block4);
	block5 = left(block5);
    block6 = left(block6);
    block7 = left(block7);
	block8 = left(block8);
    block9 = left(block9);
	block10 = left(block10);
	block1= treatment;
	block0=category;
run; 

data label;
  Treatment=' A';
  point=0;
  length  block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 $40.;
   block0='Period';
   block1 = 'Treatment'; 
   block2 = 'N        ';
   block3 = 'Mean     ';
   block4 = 'Std      ';	   
   block5 = 'Min      ';
   block6 = 'Q1       ';
   block7 = 'Median   ';
   block8 = 'Q3       ';
   block9 = 'Max      ';
   block10= 'P value  ';
run;

proc sort data=blocks;
 by category label point trt;

 data CenTend1;
    merge bse_pst blocks;
    by category label point trt;
	*_phase_=Compress(label||'_'||category);
	_phase_=label;
 run;

 data centend1;
  set label centend1;
 run;

proc sort data=CenTend1;
   by point treatment;

ods listing;
OPTIONS ORIENTATION=LANDSCAPE; 
 goption ftext=centl hsize=12in vsize=10in;
ODS PDF FILE='C:\Documents and Settings\VA04942\My Documents\my_work\GPS\Lab_community\test1.PDF';

   Title justify=center h=1.5 'Laborary Analysis - Box Plot of Last/Min/Max Baseline vs. Last/Min/Max Postbaseline Measure ';

   Footnote1 JUSTIFY= LEFT h=1 'Abbreviation: bse=baseline pst=postbaseline; Box plot type=schematic;  The box shows median,'
  'interqutile range (IQR, edge of the bar), min and max within 1.5 IQR below 25% and above 75%';
   Footnote2 JUSTIFY= LEFT h=1 '(ends of the whisker).Values outside the 1.5 IQR below 25% and ' 
  'above 75% are shown as outliers. Means plotted as different symbols by treatments.';
   FOOTNOTE3 Justify=left h=1 'P values are from the ANCOVA model Change=Baseline+Treatment.';
 
 symbol1 v=circle h=.75 c=green;
 symbol2 v=triangle h=.75 c=red;
 axis1  value=(height=0.1 color=white) label=( h=0.1 c=white "Baseline vs. Postbaseline by Treatment") major=none minor=none;
 axis2  label=(j=c h=1  "xxx Measure (Unit)") minor=(n=4);
 proc shewhart graphics data=CenTend1;
    boxchart result*point(block10 block9 block8 block7 block6 block5 block4 block3 block2 block1 block0 )=Treatment /
                    blocklabtype  = 1.5
                    blockpos      = 3
					blockrep
				    stddevs
                    boxwidthscale = 0
					boxwidth=2
                    boxstyle      = schematic
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					height=1.5
				    vREFLABELS='Lower Limit' 'Upper Limit'
					vREF= 5.5 9
                    hoffset       = 5
                    nolimits
				    readphase = all
				    phaseref
					PHASELABTYPE=5
				    phaselegend
                    notches;
    run;
 ods pdf close;

 /************************************************************************************
  * Reorder the box in the plot -Treatment side by side
  ************************************************************************************/

%macro process(in, out, add);
	proc sort data=&in;
	  by id visit;
	run;

	data &out;
	 set &in;
	 by id visit;
	 length label $ 40.;
	 length category $15;
	 keep visit id trt category label point result;
	 retain min&out max&out;
	 if first.id then do;
	   min&out=lab_test_1;
	   max&out=lab_test_1; 
	 end;
	 else do;
	  if min&out>lab_test_1 then min&out=lab_test_1;
	  if max&out<lab_test_1 then max&out=lab_test_1;
	 end;
	 if last.id then do;
	  category="&out";
	  label="Last baseline to last postbaseline";
	  point=1+&add;
	  result=lab_test_1;
      output;
	  label="Min baseline to min postbaseline";
	  point=4+&add;
	  result=min&out;
      output;
	  label="Max baseline to max postbaseline";
	  point=7+&add;
	  result=max&out;
      output;
	 end;
	run;
%mend process;
%process(Base, bse, 0);
%process(PostBse, pst, 1.1);

data bse_pst;
 set bse pst;
 if trt=1 then point=point+0.4;
run;

proc sort data=bse_pst;
  by id label category;
data change;
 set bse_pst;
 by id label category;
 retain bse;
 if first.label then bse=result;
 if last.label then output;
run; 

data change;
 set change;
 change=result-bse;
run;
 /*
proc freq data=change;
 tables label;
run;
 */
proc sort data=change;
 by label;
run; 

ods trace on;
ods trace off;
ods listing close;
ods output Tests3=pval;
proc mixed data=change;
  by label;
  class trt;
  model change=bse trt;
run;

* Compute subgroup size, mean, and standard deviation ;
 proc sort data=bse_pst;
  by category label point trt;

 proc means data=bse_pst noprint;
    by category label point trt;
    var result;
    output out=stats n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
 run;

data trtpval;
 set pval;
 trt=1;
 length category $ 15;
 category='pst';
run; 
proc sort data=trtpval;
  where effect='trt';
 by label category trt;
proc sort data=stats;
 by label category trt;

data summary;
 merge stats trtpval(keep=category effect label trt ProbF Fvalue);
 by label category trt;
run; 
 
  * Create block variables used to produce table ;
 data blocks;
    length  block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 Block10 $40.;
    keep block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 trt point category label treatment;
    set summary;
		if trt=0 then Treatment=' A';
	if trt=1 then Treatment=' B';
       blck2 = n;
       blck3 = mean;
       blck4 = std;
	   blck5 = min;
	   blck6=q1;
	   blck7=median;
	   blck8=max;
	   blck9=q3;
       blck10=ProbF; 
    block2 = strip(put(blck2,10.0));
    block3 = strip(put(blck3,10.2));
    block4 = strip(put(blck4,10.2));
	block5 = strip(put(blck5,10.2));
    block6 = strip(put(blck6,10.2));
    block7 = strip(put(blck7,10.2));
	block8 = strip(put(blck8,10.2));
    block9 = strip(put(blck9,10.2));
    block10 = strip(put(blck10,5.3));
    block2 = left(block2);
    block3 = left(block3);
    block4 = left(block4);
	block5 = left(block5);
    block6 = left(block6);
    block7 = left(block7);
	block8 = left(block8);
    block9 = left(block9);
	block10 = left(block10);
	block1= treatment;
	block0=category;
 run;
data label;
   Treatment=' A';
  point=0;
  length  block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 $40.;
   block2 = 'N        ';
   block3 = 'Mean     ';
   block4 = 'Std      ';	   
   block5 = 'Min      ';
   block6 = 'Q1       ';
   block7 = 'Median   ';
   block8 = 'Q3       ';
   block9 = 'Max      ';
   block10= 'P Value  ';
   block0 = 'Period  ';
   block1 = 'Treatment'; 
run;

proc sort data=blocks;
 by category label point trt;

 data CenTend2;
    merge bse_pst blocks;
    by category label point trt;
	*_phase_=Compress(label||'_'||category);
	_phase_=label;
 run;

 data centend2;
  set label centend2;
 run;

ods listing;

proc sort data=CenTend2;
   by point treatment;

goption ftext=centl hsize=10in vsize=10in;
/* Specify style and graphics options */

OPTIONS ORIENTATION=LANDSCAPE; 
ODS PDF FILE='C:\Documents and Settings\VA04942\My Documents\my_work\GPS\Lab_community\test2.PDF';

   Title justify=center h=1.5 'Laborary Analysis - Box Plot of Last/Min/Max Baseline vs. Last/Min/Max Postbaseline Measure ';

   Footnote1 JUSTIFY= LEFT h=1 'Abbreviation: bse=baseline pst=postbaseline; Box plot type=schematic, the box shows median,'
  'interqutile range (IQR, edge of the bar), min and max within 1.5 IQR below 25% and';
   Footnote2 JUSTIFY= LEFT h=1 'above 75%(ends of the whisker). Values outside the 1.5 IQR below 25% and ' 
  'above 75% are shown as outliers. Means plotted as different symbols by treatments.';
   FOOTNOTE3 Justify=left h=1 'P values are from the ANCOVA model Change=Baseline+Treatment.';

 symbol1 v=circle h=.75 c=green;
 symbol2 v=triangle h=.75 c=red;
 axis1  value=(height=0.1 color=white) label=( h=0.1 c=white "Baseline vs. Postbaseline by Treatment") major=none minor=none;
 axis2  label=(j=c h=1  "xxx Measure (Unit)") minor=(n=4);
 proc shewhart graphics data=CenTend2;
    boxchart result*point(block10 block9 block8 block7 block6 block5 block4 block3 block2 block1 block0 )=Treatment /
                    blocklabtype  = 1.5
                    blockpos      = 3
					blockrep
				    stddevs
                    boxwidthscale = 0
					boxwidth=2
                    boxstyle      = schematic
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					height=1.5
				    vREFLABELS='Lower Limit' 'Upper Limit'
					vREF= 5.5 9
                    hoffset       = 5
                    nolimits
				    readphase = all
					PHASELABTYPE=5
				    phaseref
				    phaselegend
                    notches;
    run;
 ods pdf close;
 goptions reset=all;


/***********************change plot ********************************************/
data change_1;
 set change;
 if trt=1 then point=point+0.6;
run;

proc means data=Change_1 noprint;
    by label point trt;
    var change;
    output out=chgstats n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
 run;

data trtpval;
 set pval;
 trt=1;
 length category $ 15;
run; 
proc sort data=trtpval;
  where effect='trt';
 by label trt;
proc sort data=chgstats;
 by label trt;

data chgsummary;
 merge chgstats trtpval(keep=effect label trt ProbF Fvalue);
 by label trt;
run; 
 
  * Create block variables used to produce table ;
 data chgblocks;
    length  block1 block2 block3 block4 block5 block6 block7 block8 block9 Block10 $40.;
    keep block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 trt point category label treatment;
    set chgsummary;
	if trt=0 then Treatment=' A';
	if trt=1 then Treatment=' B';
       blck2 = n;
       blck3 = mean;
       blck4 = std;
	   blck5 = min;
	   blck6=q1;
	   blck7=median;
	   blck8=max;
	   blck9=q3;
       blck10=ProbF; 
    block2 = strip(put(blck2,10.0));
    block3 = strip(put(blck3,10.2));
    block4 = strip(put(blck4,10.2));
	block5 = strip(put(blck5,10.2));
    block6 = strip(put(blck6,10.2));
    block7 = strip(put(blck7,10.2));
	block8 = strip(put(blck8,10.2));
    block9 = strip(put(blck9,10.2));
    block10 = strip(put(blck10,5.3));
    block2 = left(block2);
    block3 = left(block3);
    block4 = left(block4);
	block5 = left(block5);
    block6 = left(block6);
    block7 = left(block7);
	block8 = left(block8);
    block9 = left(block9);
	block10 = left(block10);
	block1= treatment;
 run;
data chglabel;
   Treatment=' A';
  point=0;
  length  block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 $40.;
   block2 = 'N        ';
   block3 = 'Mean     ';
   block4 = 'Std      ';	   
   block5 = 'Min      ';
   block6 = 'Q1       ';
   block7 = 'Median   ';
   block8 = 'Q3       ';
   block9 = 'Max      ';
   block10= 'P Value  ';
   block1 = 'Treatment'; 
run;

proc sort data=chgblocks;
 by label point trt;
 
 data CHGCenTend2;
    merge change_1 chgblocks;
    by label point trt;
	*_phase_=Compress(label||'_'||category);
	_phase_=label;
 run;

 data CHGcentend2;
  set chglabel chgcentend2;
 run;

ods listing;

proc sort data=chgCenTend2;
   by point treatment;

goption ftext=centl hsize=10in vsize=10in;
/* Specify style and graphics options */

OPTIONS ORIENTATION=LANDSCAPE; 
ods pdf;
*ODS PDF FILE='C:\Documents and Settings\VA04942\My Documents\my_work\GPS\Lab_community\test2.PDF';

   Title justify=center h=1.5 'Laborary Analysis - Box Plot of Last/Min/Max Baseline vs. Last/Min/Max Postbaseline Measure ';

   Footnote1 JUSTIFY= LEFT h=1 'Abbreviation: bse=baseline pst=postbaseline; Box plot type=schematic, the box shows median,'
  'interqutile range (IQR, edge of the bar), min and max within 1.5 IQR below 25% and';
   Footnote2 JUSTIFY= LEFT h=1 'above 75%(ends of the whisker). Values outside the 1.5 IQR below 25% and ' 
  'above 75% are shown as outliers. Means plotted as different symbols by treatments.';
   FOOTNOTE3 Justify=left h=1 'P values are from the ANCOVA model Change=Baseline+Treatment.';

 symbol1 v=circle h=.75 c=green;
 symbol2 v=triangle h=.75 c=red;
 axis1  value=(height=0.1 color=white) label=( h=0.1 c=white "Baseline vs. Postbaseline by Treatment") major=none minor=none;
 axis2  label=(j=c h=1  "xxx Measure (Unit)") minor=(n=4);
 proc shewhart graphics data=chgCenTend2;
    boxchart change*point(block10 block9 block8 block7 block6 block5 block4 block3 block2 block1)=Treatment /
                    blocklabtype  = 1.5
                    blockpos      = 3
					blockrep
				    stddevs
                    boxwidthscale = 0
					boxwidth=2
                    boxstyle      = schematic
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					height=1.5
				    /*vREFLABELS='Lower Limit' 'Upper Limit'
					vREF= 5.5 9*/
                    hoffset       = 5
                    nolimits
				    readphase = all
					PHASELABTYPE=5
				    phaseref
				    phaselegend
                    notches;
    run;
 ods pdf close;
 goptions reset=all;


