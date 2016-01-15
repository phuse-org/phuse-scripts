
 options ps=60 ls=80 nodate;
 goptions ftext=none htext=1 cell;
 

 title1 'Boxchart with Summary Statistics - Laboratory Analysis';
 title2 'Change from Base - Lab Test 1';
 

 data one;
     do study = 1 to 4 ;
	   input n mean std;
	   dur=round(mean*10);
	   sdydur=compress('Study_'||study||'('||dur||'wks)');
       label lab_test_1='Measure (unit)'; 
       do i = 1 to n;
		   do trt=0 to 1;
		       id=i+study*1000+trt*100;
		       do visid=1 to 10;
	            lab_test_1 = mean + std*rannor(234111);
			    output;
			   end;
		   end;
	   end;
    end;
    drop i n mean std;
 cards;
 60 7.3 .55
 73 7.1 .65
 59 4.5 .55
 83 7.0 .50
 ;
run; 

ods trace on;
ods listing close;
ods output OneWayFreqs=studylst;
proc freq data=one;
  tables sdydur;
run; 

ods trace off;

data sdynmb;
 set studylst End=eof;
 retain N_sdy 0;
 keep sdyid sdyname;
 N_sdy+1;
 sdyid=_n_;
 sdyname=sdydur;
 output;
 if EOF then do;
 sdyid=n_sdy+1;
 sdyname='Pooled';
 output;
 end;
run; 

ods listing;

data inte;
 set one;
 sdyname=sdydur;
 output;
 sdyname='Pooled';
 output;
run;

proc sort data=inte;
 by sdyname;

 proc sort data=sdynmb;
 by sdyname;

  data inte1;
   merge inte (in=a) sdynmb(in=b keep=sdyname sdyid);
   by sdyname;
   if a and b;
  run;

proc sort data=inte1;
 by sdyname id trt visid;

data new;
 set inte1;
 by sdyname id trt visid;
 retain BSE;
 if first.id then do;
    if visid>2 then BSE=0;
	else BSE=1;
 end;
 if BSE=0 then delete;
 drop BSE;
run;


data Base PostBSE;
 set new;
 by sdyname id trt visid;
 if visid<=2 then output Base;
 else if visid>2 then output PostBSE;
run;


 /************************************************************************************
  * Reorder the box in the plot -Treatment side by side
  ************************************************************************************/

%macro process(in, out);
	proc sort data=&in;
	  by sdyname id visid;
	run;

	data &out;
	 set &in;
	 by sdyname id visid;
	 length label $ 40.;
	 length category $15;
	 keep visid id trt category label result sdyname sdyid study dur; *posit_inc;
	 retain Min&out Max&out;
	 if first.id then do;
	   Min&out=lab_test_1;
	   Max&out=lab_test_1; 
	 end;
	 else do;
	  if Min&out>lab_test_1 then Min&out=lab_test_1;
	  if Max&out<lab_test_1 then Max&out=lab_test_1;
	 end;
	 if last.id then do;
	  category="&out";
	  label="last BSE to last PST";
	  *posit_inc=1; /*position the different category Min2Min, Max2Max, last2last*/
	  result=lab_test_1;
      output;
	  *posit_inc=2;
	  label="Min BSE to Min PST";
	  result=Min&out;
      output;
	  *posit_inc=3;
	  label="Max BSE to Max PST";
	  result=Max&out;
      output;
	 end;
	run;
%mend process;
%process(Base, BSE);
%process(PostBSE, PST);

data BasePost;
 set BSE PST;
run;

data BSE_PST;
 set BasePost;
 /*point is the variable that define the location of the box on x axis */
 point=sdyid*3;
 if category='PST' then point=point+1.6;
 *point=sdyid+(posit_inc-1)*6; /*adjust the number added to position the boxes of different label */
 if trt=1 then point=point+0.7;
run;

data annoraw;
 set BSE_PST;
 length function $8;
 retain function color text size xsys ysys when;
 if result>9 or .<result<3.5;
 if result>9 then TE_High=1;
 else TE_High=0;
 if result<3.5 then TE_low=1;
 else TE_low=0;
  When='A'; /*'A' indcates the symbol will be draw after the plot procedure
             'A' means the annote symbol is in the front of the plot
             'B' indcates the symbol will be draw before the plot procedure
             'B' means the annote sumbol is at the back of the plot
            */              
 xsys='2'; /* xsys= specifies a value that represents a coordinate system. 
              '2' means the Coordinate System Unit = data values */
 ysys='2';
 color = "red "; 
 function = "symbol "; * create a symbol; 
 text = "dot "; * (a filled circle); 
 size = 0.5;
 x=point;
 y=result;
run; 


* Compute subgroup size, mean, and standard deviation ;
 proc sort data=BSE_PST;
  by sdyname category label point trt;

 proc means data=BSE_PST noprint;
    by sdyname category label point trt;
    var result;
    output out=stats n=n mean=mean std=std median=median Min=Min Max=Max q1=q1 q3=q3;
 run;

proc sort data=stats;
 by sdyname label category trt;

  * Create block variables used to produce table ;
 data blocks;
    length  block0 block1 block2 block3 block4 block5 block6 block7 block8 block9  $40.;
    keep block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 trt point sdyname category label treatment;
    set stats;
		if trt=0 then Treatment=' A';
	if trt=1 then Treatment=' B';
       blck2 = n;
       blck3 = mean;
       blck4 = std;
	   blck5 = Min;
	   blck6=q1;
	   blck7=median;
	   blck8=Max;
	   blck9=q3;
    block2 = strip(put(blck2,10.0));
    block3 = strip(put(blck3,10.2));
    block4 = strip(put(blck4,10.2));
	block5 = strip(put(blck5,10.2));
    block6 = strip(put(blck6,10.2));
    block7 = strip(put(blck7,10.2));
	block8 = strip(put(blck8,10.2));
    block9 = strip(put(blck9,10.2));
    block2 = left(block2);
    block3 = left(block3);
    block4 = left(block4);
	block5 = left(block5);
    block6 = left(block6);
    block7 = left(block7);
	block8 = left(block8);
    block9 = left(block9);
	block1= treatment;
	block0=category;
 run;
data label;
   Treatment=' A';
  point=0;
  length  label block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 $40.;
    label="last BSE to last PST";
   block2 = 'N        ';
   block3 = 'Mean     ';
   block4 = 'Std      ';	   
   block5 = 'Min      ';
   block6 = 'Q1       ';
   block7 = 'Median   ';
   block8 = 'Q3       ';
   block9 = 'Max      ';
   block0 = 'Period  ';
   block1 = 'Treatment'; 
   output;
       label="Min BSE to Min PST";
   block2 = 'N        ';
   block3 = 'Mean     ';
   block4 = 'Std      ';	   
   block5 = 'Min      ';
   block6 = 'Q1       ';
   block7 = 'Median   ';
   block8 = 'Q3       ';
   block9 = 'Max      ';
   block0 = 'Period  ';
   block1 = 'Treatment'; 
   output;
       label="Max BSE to Max PST";
   block2 = 'N        ';
   block3 = 'Mean     ';
   block4 = 'Std      ';	   
   block5 = 'Min      ';
   block6 = 'Q1       ';
   block7 = 'Median   ';
   block8 = 'Q3       ';
   block9 = 'Max      ';
   block0 = 'Period  ';
   block1 = 'Treatment'; 
   output;
run;

proc sort data=blocks;
 by sdyname category label point trt;

/****************************************
 * Phase specified as study             *
 ****************************************/


 *************************************************
 * Find out the color code from color information
 * from Word
 *************************************************;
data _Null_;
     *information from Word colors;
	 red=215;
	 green=225;
	 blue=245;
	 *convert to HEX;
	 hexred=put(red,hex2.);
	 hexgreen=put(green,hex2.);
	 hexblue=put(blue,hex2.);
	 *Create as a SAS RGB color;
	 sasrgb="CX"||hexred||hexgreen||hexblue;
	 *Write the new color code value to the Log;
	 put sasrgb;
run;

 data CenTend1;
    merge BSE_PST blocks;
	length _Phase_ $ 20. cblock0 $8. cbox0 $10.;
    by sdyname category label point trt;
	*_phase_=Compress(sdyname||'_'||category);
	_phase_=compress(sdyname);
	/*define color variable for the blocks and for the boxfill */
	if block0='BSE' then do; 
         cblock0='white';
		   cbox0='white';
    end;
	if block0='PST' then do;
         cblock0='CXD7E1F5';
		 cbox0='CXD7E1F5';
	end;
	cblock='White';
 run;

 data centend1;
  set label centend1;
 run;
proc sort data=CenTend1;
   by label point treatment;
run;


%let last =last BSE to last PST;
%let Min = Min BSE to Min PST;
%let Max = Max BSE to Max PST;


%macro metaboxplot(label, lbl);
 proc sort data=annoraw out=anno&lbl;
   where label="&label";
   by label point trt;

proc sort data=CenTend1 out=box&lbl;
  where label="&label";
   by label point treatment;

 options orientation=landscape LEFTMARGIN=1.5in RIGHTMARGIN=1 in TOPMARGIN=1in BOTTOMMARGIN=1in; 
 title1    h=10pt "Laborary Analysis - Box Plot of &label";

 Footnote1 JUSTIFY= LEFT h=0.9 'Box plot type=schematic, the box shows median,interqutile range (IQR, edge of the bar), Min and Max'
  ' within 1.5 IQR below 25% and above 75% (ends of the whisker).';
 Footnote2 Justify=left h=0.9 'Values outside the 1.5 IQR below 25% and above 75% are shown as outliers. Means ploted as different'
  ' symbols by treatments. Red dots indicate out of normal reference range measures.';
 Footnote3 Justify=left h=0.9 'The upper and lower limits use the most conservative ones if they differ by'
  ' gender, age, etc.  xxxx reference range is used. Baseline and postbaseline boxes are framed in different colors.';
 Footnote4 Justify=left h=0.9 'BSE=baseline        PST=post-baseline';


 symbol1 v=circle h=0.8 c=green;
 symbol2 v=star h=0.8 c=purple;
  legend1 label=(h=8pt 'Treatment') value=(h=6pt);
 axis1  value=(height=0.1 color=white) label=( h=0.1 c=white "Baseline vs. Postbaseline by Treatment") major=none Minor=none;
 axis2  label=(j=c h=1  "xxx Measure (Unit)") Minor=(n=4);
 proc shewhart graphics data=box&lbl gout = outgr1;
    boxchart result*point(block9 block8 block7 block6 block5 block4 block3 block2 block1 block0  )=Treatment /
	   	           cBOXfill=(cbox0)
					/*cboxfill=CXD6E3FE*/
					/*blockvar =( block0 block0 block0 block0 block0 block0 block0 block0 block0 block0)*/
	                cblockvar=(cblock0 cblock0 cblock0 cblock0 cblock0 cblock0 cblock0 cblock0 cblock0 cblock0)
	                anno=anno&lbl
                    blocklabtype  = 1.3
                    blockpos      = 3
					blockrep
				    stddevs
                  /*  boxwidthscale = 0 */
					boxwidth=1.5
                    boxstyle      = schematic
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					height=1.5
				    vREFLABELS='Lower Limit' 'Upper Limit'
					/*vREF= 3.5 9*/
                    hoffset       = 5
                    nolimits
				    readphase = all
					PHASELABTYPE=5
				    phaseref
				    phaselegend
                    notches
					SYMBOLLEGEND=legend1
					nolegend
;
    run;

%mend metaboxplot;
ods pdf;
%metaboxplot(&last, Last);
*%metaboxplot(&Min, Min);
*%metaboxplot(&Max, Max);
 ods pdf close;
 goptions reset=all;


/******************************************************************************
 * Change boxplot
 *****************************************************************************/

proc sort data=BasePost;
  by sdyname id label ;
data change;
 set BasePost;
 by sdyname id label ;
 retain BSE;
 if first.label then BSE=result;
 if last.label then output;
 keep sdyname trt id label BSE result sdyid study dur;
run; 


data change;
 set change;
 change=result-BSE;
 /*point is the variable that define the location of the box on x axis */
 point=sdyid*3;
 if trt=1 then point=point+1;
 keep sdyname trt BSE id label point change study sdyid dur;
run;

proc sort data=change;
  by sdyname id label;

* Compute subgroup size, mean, and standard deviation ;
 proc sort data=change;
  by sdyname label point trt;

 proc means data=change;* noprint;
    by sdyname label point trt;
    var change;
    output out=chgstats n=n mean=mean std=std median=median Min=Min Max=Max q1=q1 q3=q3;
 run;

proc sort data=chgstats;
 by sdyname label  trt;


proc sort data=change;
 by sdyname label;
run; 

ods trace on;
ods trace off;
ods listing close;
ods output Tests3=pval;
ods output lsmeans=lsm;
ods output diffs=lsmdif;
proc mixed data=change;
  by sdyname label;
  class trt;
  model change=BSE trt study;
  lsmeans trt/diffs=control('0');
run;

ods listing;

data trtpval;
 set pval;
 trt=1;
run;
data lsm_dif;
 set lsmdif;
 trt=1;
run; 

proc sort data=lsm_dif;
 by sdyname label;
proc sort data=lsm;
 by sdyname label; 
proc sort data=trtpval;
  where effect='trt';
 by sdyname label trt;

proc sort data=chgstats;
 by sdyname label trt;

data summary;
 merge chgstats 
       trtpval(keep=sdyname effect label trt ProbF Fvalue)
       lsm_dif(keep=sdyname label trt estimate rename=estimate=lsmdiff)
       lsm (keep=sdyname label trt estimate rename=estimate=lsm);
 by sdyname label  trt;
run; 

  * Create block variables used to produce table ;
 data chgblocks;
    length  block1 block2 block3 block4 block5 block6 block7 block8 block9 Block10 $40.;
    keep  block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 block11 block12 
          block13 trt point label treatment sdyname dur;
    set summary;
		if trt=0 then Treatment=' A';
	if trt=1 then Treatment=' B';
       blck2 = n;
       blck3 = mean;
       blck4 = std;
	   blck5 = Min;
	   blck6=q1;
	   blck7=median;
	   blck8=Max;
	   blck9=q3;
	   blck10=lsm;
	   blck11=lsmdiff;
       blck12=ProbF;
       blck13=dur; 
    block2 = strip(put(blck2,10.0));
    block3 = strip(put(blck3,10.2));
    block4 = strip(put(blck4,10.2));
	block5 = strip(put(blck5,10.2));
    block6 = strip(put(blck6,10.2));
    block7 = strip(put(blck7,10.2));
	block8 = strip(put(blck8,10.2));
    block9 = strip(put(blck9,10.2));
    block10 = strip(put(blck10,10.2));
    block11 = strip(put(blck11,10.2));
    block12 = strip(put(blck12,5.3));
	block13 = strip(put(blck13,5.0));
    block2 = left(block2);
    block3 = left(block3);
    block4 = left(block4);
	block5 = left(block5);
    block6 = left(block6);
    block7 = left(block7);
	block8 = left(block8);
    block9 = left(block9);
	block10 = left(block10);
    block11 = left(block11);
    block12 = left(block12);
	block13 = left(block13);
	block1= treatment;
 run;

data label;
   Treatment=' A';
  point=0;
  length label  block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 $40.;
   label="last BSE to last PST";
   block1 = 'Treatment';
   block2 = 'N        ';
   block3 = 'Mean     ';
   block4 = 'Std      ';	   
   block5 = 'Min      ';
   block6 = 'Q1       ';
   block7 = 'Median   ';
   block8 = 'Q3       ';
   block9 = 'Max      ';
   block10= 'LsMean   ';
   block11= 'LsMean_dif';
   block12= 'P Value  ';
   block13= 'Study Duration(weeks)';
   output;
      label="Min BSE to Min PST";
   block1 = 'Treatment';
   block2 = 'N        ';
   block3 = 'Mean     ';
   block4 = 'Std      ';	   
   block5 = 'Min      ';
   block6 = 'Q1       ';
   block7 = 'Median   ';
   block8 = 'Q3       ';
   block9 = 'Max      ';
   block10= 'LsMean   ';
   block11= 'LsMean_dif';
   block12= 'P Value  ';
   block13= 'Study Duration(weeks)';
   output;
      label="Max BSE to Max PST";
   block1 = 'Treatment';
   block2 = 'N        ';
   block3 = 'Mean     ';
   block4 = 'Std      ';	   
   block5 = 'Min      ';
   block6 = 'Q1       ';
   block7 = 'Median   ';
   block8 = 'Q3       ';
   block9 = 'Max      ';
   block10= 'LsMean   ';
   block11= 'LsMean_dif';
   block12= 'P Value  ';
   block13= 'Study Duration(weeks)';
   output;

run;

proc sort data=chgblocks;
 by sdyname label point trt;

 data CenTend2;
    merge change chgblocks;
    by sdyname label point trt;
	_phase_=compress(sdyname);
 run;

 data centend2;
  set label centend2;
 run;

ods listing;

proc sort data=CenTend2;
   by label point treatment;
goption reset=all;
quit;

ods listing;
 options orientation=landscape LEFTMARGIN=1.5in RIGHTMARGIN=1 in TOPMARGIN=1in BOTTOMMARGIN=1in; 
 ods pdf;

 title1    h=10pt 'Laborary Analysis - Box Plot of Change from Last/Min/Max Baseline for Last/Min/Max Postbaseline Measure';
 Footnote1  justify=left h=7pt '  BSE=baseline; PST=postbaseline; Box plot type=schematic; The box shows median,interqutile range (IQR, edge of'
                               ' the bar), Min and Max within 1.5 IQR below 25% and above 75% ends of the whisker).Values';
 Footnote2 JUSTIFY= LEFT h=7pt ' outside the 1.5 IQR below 25% and above 75% are shown as outliers. Means ploted as different symbols by treatments.'
							   ' The upper and lower limits use the most conservative ones if they differ by gender, age, etc. ';
 Footnote3 justify=left h=7pt  '  P value is for the treatment comparison from the ANCOVA model Change=Baseline+Treatment+Study';
 footnote4 h=.2 '  ';

 symbol1 v=circle h=0.8 c=green;
 symbol2 v=star h=0.8 c=purple;
   legend1 label=(h=6pt 'Treatment') value=(h=6pt);
 axis1  value=(height=0.1 color=white) label=( h=0.1 c=white "Baseline vs. Postbaseline by Treatment") major=none Minor=none;
 axis2  label=(j=c h=1  "xxx Measure (Unit)") Minor=(n=4);
 proc shewhart graphics data=CenTend2;
  by label;
    boxchart change*point(block12 block11 block10 block9 block8 block7 block6 block5 block4 block3 block2 block1)=Treatment /
	                blocklabtype  = 1.5
                    blockpos      = 3
					blockrep
				    stddevs
					boxwidth=1.5
                    boxstyle      = schematic
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					height=1.5
                    hoffset       = 5
                    nolimits
					vREF= 0
					readphase = all
					PHASELABTYPE=5
				    phaseref
				    phaselegend
                    notches
					nolegend
					SYMBOLLEGEND=legend1
     ;
    run;
 ods pdf close;
 goptions reset=all;
quit;







 /********************
 Phase specified as study&period(BSE or PST)
 *******************
 data CenTend1;
    merge BSE_PST blocks;
	length _Phase_ $ 10.;
    by sdyname category label point trt;
	_phase_=Compress(sdyname||'_'||category);
	if block0='BSE' then do; 
         cblock0='cream';
		 cbox0='cream';
    end;
	if block0='PST' then do;
         cblock0='pink';
		 cbox0='pink';
	end;
	cblock='White';
 run;


 data centend1;
  set label centend1;
 run;

%let last =last BSE to last PST;
%let label = Min BSE to Min PST;
%let last = Max BSE to Max PST;


%macro metaboxplot(label, lbl);
 proc sort data=annoraw out=anno&lbl;
   where label="&label";
   by label point trt;

proc sort data=CenTend1 out=box&lbl;
  where label="&label";
   by label point treatment;

 ods listing;
 options orientation=landscape LEFTMARGIN=1.5in RIGHTMARGIN=1 in TOPMARGIN=1in BOTTOMMARGIN=1in; 
 ods pdf;
 title1    h=10pt "Laborary Analysis - Box Plot of &label";

 Footnote1 JUSTIFY= LEFT h=1 'Box plot type=schematic, the box shows median,interqutile range (IQR, edge of the bar), Min and Max'
  ' within 1.5 IQR below 25% and above 75% (ends of the whisker).';
 Footnote2 Justify=left h=1 'Values outside the 1.5 IQR below 25% and above 75% are shown as outliers. Means ploted as different symbols by treatments.'
  'Red dots indicate out of normal reference range measures.';
 Footnote3 Justify=left h=1 'The upper and lower limits use the most conservative ones if they differ by gender, age, etc.  Lilly reference range is used.'
  ' Baseline and postbaseline boxes are framed in different colors.'; 

 *ods pdf;
 symbol1 v=circle h=0.8 c=green;
 symbol2 v=star h=0.8 c=purple;
  legend1 label=(h=8pt 'Treatment') value=(h=6pt);
 axis1  value=(height=0.1 color=white) label=( h=0.1 c=white "Baseline vs. Postbaseline by Treatment") major=none Minor=none;
 axis2  label=(j=c h=1  "xxx Measure (Unit)") Minor=(n=4);
 proc shewhart graphics data=box&lbl gout = outgr1;
    *by label;
    boxchart result*point(block9 block8 block7 block6 block5 block4 block3 block2 block1 block0  )=Treatment /

	                anno=anno&lbl
                    blocklabtype  = 1.3
                    blockpos      = 3
					blockrep
				    stddevs
					boxwidth=1.5
                    boxstyle      = schematic
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					height=1.5
				    vREFLABELS='Lower Limit' 'Upper Limit'
					vREF= 4.0 9
                    hoffset       = 5
                    nolimits
				    readphase = all
					PHASELABTYPE=5
				    phaseref
				    phaselegend
                    notches
					SYMBOLLEGEND=legend1
					nolegend
;
    run;

%mend metaboxplot; ****/
