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
	  label="Last bse to last pst";
	  point=1+&add;
	  result=lab_test_1;
      output;
	  label="Min bse to min pst";
	  point=4+&add;
	  result=min&out;
      output;
	  label="Max bse to max pst";
	  point=7+&add;
	  result=max&out;
      output;
	 end;
	run;
%mend process;
%process(Base, bse, 0);
%process(PostBse, pst, 1.1);

data BasePost;
 set bse pst;
run;

data bse_pst;
 set BasePost;
 if trt=1 then point=point+0.5;
run;

/* Annoraw is the annotate data for the display of out of normal limit data
 * In real use, if lab_test_1>9 or .<lab_test_1<5.5 need to be replaced with 
 * if lab_test_1>ULN or .<lab_test_1<LLN
 */

data annoraw;
 set bse_pst;
 length function $8;
 retain function color text size xsys ysys when;
 if result>9 or .<result<5.5;
 if result>9 then TE_High=1;
 else TE_High=0;
 if result<5.5 then TE_low=1;
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

proc sort data=annoraw;
 by label category  trt;

/*
data abnorcnt;
 set annoraw;
 by label category  trt;
 retain TE_h TE_L 0;
 if first.id then do;
  TE_h=TE_high;
  TE_l=TE_Low;
 end;
 else do;
  TE_h=TE_high+TE_h;
  TE_l=TE_low+TE_l;
 end;
 if last.id then do;
  if TE_h>0 then TE_h=1;
  if TE_l>0 then TE_l=1;
  output;
 end;
run; 
  */

data abnrmfrq;
 set annoraw;
 by label category  trt;
 retain CNT_H CNT_L 0;
 keep category label cnt_h cnt_l result TE_Low TE_High trt;
 if first.trt then do;
   cnt_h=0;
   cnt_l=0;
 end;
  cnt_h=cnt_h+TE_high;
  cnt_L=cnt_l+TE_low;
 if last.trt;
run;

ods output CrossTabFreqs=rawfrq;
ods listing close;
proc freq data=bse_pst;
  tables label*category*trt;
run;

data rawfrq;
 set rawfrq;
 keep label category trt n_subj;
 n_subj=frequency;
 if _type_='111';
run; 

proc sort data=rawfrq;
 by label category trt;
data frqs;
 merge rawfrq abnrmfrq;
 by label category  trt;
  TE_H_pct=round(cnt_h/n_subj*100, .1);
 TE_l_pct=round(cnt_l/n_subj*100, .1);
  if cnt_h <=0 then do;
   cnt_h=0;
   te_h_pct=0;
 end;
 if cnt_l<=0 then do;
   cnt_l=0;
   te_l_pct=0;
 end; 
 TEHigh=compress(cnt_h||'('||TE_h_pct||')'); 
 TELow=compress(cnt_l||'('||TE_L_pct||')');
run;


* Compute subgroup size, mean, and standard deviation ;
 proc sort data=bse_pst;
  by label category  trt;

 proc means data=bse_pst noprint;
    by label category point trt;
    var result;
    output out=stats n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
 run;

proc sort data=stats;
 by label category trt;

data allstats;
 merge stats frqs;
 by label category trt;
run;

  * Create block variables used to produce table ;
 data blocks;
    length  block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 block11  $40.;
    keep block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 block11 trt treatment n_subj tehigh telow  point category label treatment;
    set allstats;
		if trt=0 then Treatment=' A';
	if trt=1 then Treatment=' B';
       blck2 = n_subj;
       blck3 = mean;
       blck4 = std;
	   blck5 = min;
	   blck6=q1;
	   blck7=median;
	   blck8=max;
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
	block10=tehigh;
	block11=telow;
 run;
data label;
   Treatment=' A';
  point=0;
  length  block0 block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 block11 $40.;
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
   block10= left('TE High n(%)');
   block11= left('TE Low n(%)');
run;
proc sort data=bse_pst;
 by category label point trt;

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

ods listing;

proc sort data=CenTend1;
   by point treatment;

/******************************************************************************
 * Change boxplot
 *****************************************************************************/

proc sort data=BasePost;
  by id label ;
data change;
 set BasePost;
 by id label ;
 retain bse;
 if first.label then bse=result;
 if last.label then output;
 keep trt id label bse point result;
run; 


data change;
 set change;
 change=result-bse;
 if trt=1 then point=point+1;
 keep trt bse id label point change;
run;


proc sort data=change;
  by id label;

* Compute subgroup size, mean, and standard deviation ;
 proc sort data=change;
  by  label point trt;

 proc means data=change;* noprint;
    by label point trt;
    var change;
    output out=chgstats n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
 run;

proc sort data=chgstats;
 by label  trt;


proc sort data=change;
 by label;
run; 

ods trace on;
ods trace off;
ods listing close;
ods output Tests3=pval;
ods listing;
proc mixed data=change;
  by label;
  class trt;
  model change=bse trt;
  lsmeans trt;
run;

data trtpval;
 set pval;
 trt=1;
run; 
proc sort data=trtpval;
  where effect='trt';
 by label trt;

proc sort data=chgstats;
 by label trt;

data summary;
 merge chgstats trtpval(keep=effect label trt ProbF Fvalue);
 by label  trt;
run; 


  * Create block variables used to produce table ;
 data chgblocks;
    length  block1 block2 block3 block4 block5 block6 block7 block8 block9 Block10 $40.;
    keep  block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 trt point label treatment;
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
 run;

data label;
   Treatment=' A';
  point=0;
  length   block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 $40.;
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
 by  label point trt;

 data CenTend2;
    merge change chgblocks;
    by label point trt;
	*_phase_=Compress(label||'_'||category);
	_phase_=label;
 run;

 data centend2;
  set label centend2;
 run;

ods listing;

proc sort data=CenTend2;
   by point treatment;


/**************************************************************************
 *
 * Generate Graph Reports
 *
 *
 ***************************************************************************/

 ods listing;
 /* Set the graphics environment */
goptions reset=all cback=white border htitle=10pt htext=9pt ;  

 /* Use the NODISPLAY graphics option when */
 /* creating the original graphs.          */
goptions device=gif nodisplay xpixels=240 ypixels=160;

 /* Write 2 sample graphs to the graph catalog of WORK.Centgr */

 Title1 h=2pt justify=center 'Observed Values';
 symbol1 v=circle h=.75 c=green;
 symbol2 v=triangle h=.75 c=red;
  legend1 label=(h=2pt 'Treatment') value=(h=2pt);
 axis1  value=(height=0.1 color=white) label=( h=0.1 c=white "Baseline vs. Postbaseline by Treatment") major=none minor=none;
 axis2  label=(j=c h=1  "xxx Measure (Unit)") minor=(n=4);
 proc shewhart graphics data=CenTend1 gout = outgr1;
    boxchart result*point(block11 block10 block9 block8 block7 block6 block5 block4 block3 block2 block1 block0 )=Treatment /
	 				anno=annoraw
                    blocklabtype  = 1.5
                    blockpos      = 3
					blockrep
				    stddevs
					boxwidth=2
                    boxstyle      = schematic
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					height=1.5
				    vREFLABELS='Lower Limit' 'Upper Limit'
					/*vREF= 5.5 9*/
                    hoffset       = 5
                    nolimits
				    readphase = all
					PHASELABTYPE=5
				    phaseref
				    phaselegend
                    notches
				    nolegend
					SYMBOLLEGEND=legend1
	;
    run;



 Title1 justify=center h=2pt 'Changes from Baseline';
 symbol1 v=circle h=.75 c=green;
 symbol2 v=triangle h=.75 c=red;
 *  legend1 label=(h=2pt 'Treatment') value=(h=2pt);
 axis1  value=(height=0.1 color=white) label=( h=0.1 c=white "Baseline vs. Postbaseline by Treatment") major=none minor=none;
 axis2  label=(j=c h=1  "xxx Measure (Unit)") minor=(n=4);
 proc shewhart graphics data=CenTend2 gout = outgr1;
    boxchart change*point(block10 block9 block8 block7 block6 block5 block4 block3 block2 block1)=Treatment /
                    blocklabtype  = 1.5
                    blockpos      = 3
					blockrep
				    stddevs
					boxwidth=2
                    boxstyle      = schematic
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					vREF= 0
					height=1.5
                    hoffset       = 5
                    nolimits
					readphase = all
					PHASELABTYPE=5
				    phaseref
				    phaselegend
                    notches
					nolegend
					SYMBOLLEGEND=none
     ;
    run;

					    /*vREFLABELS='Lower Limit' 'Upper Limit'
					vREF= -2.5 1.8*/
quit;

 goptions xpixels=600 ypixels=300; 
 /* Generate the common title and footnote */
 /* with PROC GSLIDE.                      */
 title1    h=5pt 'Laborary Analysis - Box Plot of Last/Min/Max Baseline vs. Last/Min/Max Postbaseline Measure';
 Footnote1  justify=left h=3pt '  bse=baseline; pst=postbaseline; Box plot type=schematic; The box shows median,interqutile range (IQR, edge of'
                               ' the bar), min and max within 1.5 IQR below 25% and above 75% ends of the whisker).Values outside the 1.5';
 Footnote2 JUSTIFY= LEFT h=3pt '  IQR below 25% and above 75% are shown as outliers. Means plotted as different symbols by treatments.'
							   ' Out of normal reference range data is plotted as red dots overlay the boxplot. Reference lines plotted the lowest of';

 Footnote3 justify=left h=3pt  '  the upper limited normal and the highest of the lower limited normal.    '
                               ' P value is for the treatment comparison from the ANCOVA model Change=Baseline+Treatment';
 footnote4 h=.2 '  ';  

proc gslide gout=work.outgr1;
run;
quit;
 
 options orientation=landscape LEFTMARGIN=1.5in RIGHTMARGIN=1 in TOPMARGIN=1in BOTTOMMARGIN=1in; 
 ods pdf;
  goptions reset=all device=gif 
         gsfname=grafout gsfmode=replace
         xpixels=600 ypixels=400 ;

 /* Use the GREPLAY procedure to define a   */
 /* 5-panel template.  The fifth panel      */
 /* contains the common title and footnote. */
proc greplay igout=work.outgr1 tc=tempcat nofs;

  /* Define a custom template called NEWTEMP */
  tdef newtemp des='Five panel template'

        /* Define panel 1 */
        1/llx=2   lly=10
          ulx=2   uly=90
          urx=60  ury=90
          lrx=60  lry=10
          color=white

        /* Define panel 2 */
        2/llx=60   lly=14
          ulx=60   uly=90
          urx=100  ury=90
          lrx=100  lry=14
          color=white

        /* Define panel 5 */
        5/llx=2   lly=0
          ulx=2   uly=100
          urx=100 ury=100
          lrx=100 lry=0
          color=black;

   /* Assign current template */
   template newtemp;

   /* List contents of current template */
   list template;

   /* Replay a total of five graphs using  */
   /* the custom template just created.    */
   treplay 1:Shewhart
           2:Shewhar1
           5:gslide
;
run; 
goption reset=all;
ods pdf close;
quit;


