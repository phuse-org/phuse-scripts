/* a test comment */

 options ps=60 ls=80 nodate;
 goptions ftext=none htext=1 cell;
 

 title1 'Boxchart with Summary Statistics - Laboratory Analysis';
 title2 'Change from Baseline - Lab Test 1';
 

 data one;
     do wks = 0 to 7;
       input n mean std;
	   label lab_test_1='Measure (unit)'; 
       do trt=0 to 1;
	    multi=wks+3*trt*round(wks/3);
        do i = 1 to n-multi;
		      id=i+(trt+1)*1000;
	          lab_test_1 = mean + std*rannor(234111);
	          output;
		end;
	   end;
    end;
    drop i n mean std;
 cards;
 80 7.3 .55
 80 7.1 .65
 80 6.7 .45
 80 7.0 .50
 80 7.6 .70
 80 7.3 .55
 80 6.7 .55
 ;
run;

proc sort data=one;
  by id wks;
data new;
 set one;
 by id wks;
 retain bse;
 if first.id then do;
   if wks=0 then bse=lab_test_1;
   else bse=.;
 end;
 if bse=. then delete;
run; 

ods output CrossTabFreqs=freq;
ods trace off;
ods listing close;
 proc freq data=new;
   tables trt*wks;
 run;
ods listing; 
data frq;
 set freq;
 if _type_='11';
 keep wks trt ttpoint;
 ttpoint=1+wks+trt/3;
run;

proc sort data=frq;
  by wks trt;
proc sort data=new;
  by wks trt;
run; 

data two;
 merge new frq;
 by wks trt;
run;

  * Compute subgroup size, mean, and standard deviation ;
 proc sort data=two;
  by wks trt;

 proc means data=two noprint;
    by wks trt;
    var lab_test_1;
    output out=stats n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
 run;
 
  * Create block variables used to produce table ;
 data blockraw;
    length  block1 block2 block3 block4 block5 block6 block7 block8 block9 $40.;
    keep block1 block2 block3 block4 block5 block6 block7 block8 block9 trt wks treatment;
    set stats;
	by wks trt;
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
run;
data labelraw;
  Treatment=' A';
  ttpoint=0;
  length  block1 block2 block3 block4 block5 block6 block7 block8 block9  $40.;
       block2 = left('N   ');
       block3 = left('Mean  ');
       block4 = left('Std    ');	   
       block5 = left('Min    ');
       block6 = left('Q1     ');
	   block7 = left('Median   ');
	   block8 = left('Q3     ');
	   block9 = left('Max    ');
       block1 = left('Treatment ');
run;

/* Annoraw is the annotate data for the display of out of normal limit data
 * In real use, if lab_test_1>9 or .<lab_test_1<5.5 need to be replaced with 
 * if lab_test_1>ULN or .<lab_test_1<LLN
 */
data annoraw;
 set two;
 length function $8;
 retain function color text size xsys ysys when;
 if lab_test_1>9 or .<lab_test_1<5.5;
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
 x=ttpoint;
 y=lab_test_1;
run; 

 data vwiseplot;
    merge two blockraw;
    by wks trt;
 run; 

 data vwiseplot;
   set vwiseplot;
    by wks;
	if wks=0 then _Phase_='Baseline';
	else _phase_=compress('Weeks='||wks);
 run;

 proc sort data=vwiseplot;
   by ttpoint Treatment;
 run;


 data plot_visit;
  set labelraw vwiseplot;
 run;
 
/************************************************************************
 * Box plot for change
 ************************************************************************/
data new;
 set one;
 by id wks;
 retain bse;
 length cate $10;
 cate=compress('Wks='||wks);
 if first.id then do;
   if wks=0 then bse=lab_test_1;
   else bse=.;
 end;
 if bse=. then delete;
 else output;
 if last.id then do;
   cate='_Endpoint';
   output;
 end;  
run; 

data chg;
 set new;
 if wks>0;
 change=lab_test_1-bse;
run; 

ods output CrossTabFreqs=chgfreq;
ods trace off;
ods listing close;
 proc freq data=chg;
   tables trt*cate;
 run;
ods listing; 

proc sort data=chgfreq;
 where _type_='11';
  by cate trt;
run; 

data chgfrq;
 set chgfreq;
 by cate trt;
 keep cate trt ttpoint;
 ttpoint=_n_-trt*0.3;
run;

proc sort data=chgfrq;
  by cate trt;
proc sort data=chg;
  by cate trt;
run; 

data chgdata;
 merge chg chgfrq;
 by cate trt;
run;

 * Compute subgroup size, mean, and standard deviation ;
 proc means data=chgdata noprint;
    by cate trt ttpoint;
    var change;
    output out=chgstats n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
 run;


 ods listing close;
 ods output Tests3=pval;
 proc mixed data=chgdata;
   where cate='_Endpoint';
   class trt;
   model change=trt bse;
 run;
 
 
data trtpval;
 set pval;
 trt=1;
  length cate $10;
  where effect='trt';
 cate='_Endpoint';
 keep cate effect trt ProbF Fvalue;
run; 

proc sort data=trtpval;
  by cate trt;

proc sort data=chgstats;
  by cate trt;

data sumstats;
 merge trtpval chgstats;
 by cate trt;
run;



* Create block variables used to produce table ;
 data blockchg;
    length  block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 $40.;
    keep block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 trt cate treatment;
    set sumstats;
	by cate trt;
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
	block10 = strip(put(blck10, 4.3));
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
Run;

data labelchg;
 Treatment=' A';
 ttpoint=0;
 length   block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 $40.;
   block1 = left('Treatment');
   block2 = left('N');    
   block3 = left('Mean');   
   block4 = left('Std');      
   block5 = left('Min');    
   block6 = left('Q1');    
   block7 = left('Median'); 
   block8 = left('Q3');     
   block9 = left('Max');    
   block10 = left('P value');   
run;


 data vwisechg;
    merge chgdata blockchg;
    by cate trt;
     _phase_=compress(cate);
 run;
 
 data plot_chg_vst;
  set labelchg vwisechg;
 run;

 ods listing;
 options orientation=landscape;
 ods pdf;
 Title justify=center h=1.5 'Box Plot - xxx Measures Over Time (Weeks Since Randomized)';

 Footnote1 JUSTIFY= LEFT h=1 'Box plot type=schematic, the box shows median,interqutile range (IQR, edge of the bar), min and max'
  ' within 1.5 IQR below 25% and above 75% (ends of the whisker).Values outside the 1.5 IQR below 25% and';
 Footnote2 JUSTIFY= LEFT h=1 'above 75% are shown as outliers. Means ploted as different symbols by treatments. Red dots indicate'
  ' out of normal reference range measures. Lilly reference range is used.';
 
 symbol1 v=circle h=.75 c=orange;
 symbol2 v=star h=.75 c=blue;
 axis1 value=none label=none order=(0.5 to 8.8 by 1) offset=(0,0) major=none;
 axis2 label=(j=c h=1  "xxx Measures (Unit)") minor=(n=4);
 proc shewhart graphics data=plot_visit;
    boxchart lab_test_1*ttpoint (block9 block8 block7 block6 block5 block4 block3 block2 block1 )=Treatment /
         anno=annoraw
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
ods listing;
 options orientation=landscape;
 ods pdf;
 Title justify=center h=1.5 'Box Plot - xxx Measures Over Time (Weeks Since Randomized)';

 Footnote1 JUSTIFY= LEFT h=1 'The box shows median,interqutile range (IQR, edge of the bar), min and max.'
                             'Means ploted as different symbols by treatments.';
 Footnote2 JUSTIFY= LEFT h=1 'Red dots indicate out of normal reference range measures. Lilly reference range is used.';
 
 symbol1 v=circle h=.75 c=orange;
 symbol2 v=star h=.75 c=blue;
 axis1 value=none label=none order=(0.5 to 8.8 by 1) offset=(0,0) major=none;
 axis2 label=(j=c h=1  "xxx Measures (Unit)") minor=(n=4);
 proc shewhart graphics data=plot_visit;
    boxchart lab_test_1*ttpoint (block9 block8 block7 block6 block5 block4 block3 block2 block1 )=Treatment /
         anno=annoraw
 					blocklabtype  = 1.5
                    blockpos      = 3
					blockrep
				    stddevs
                    boxwidthscale = 0
					boxwidth=2
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					height=1.5
					/*
				   vREFLABELS='Lower Limit' 'Upper Limit'
					vREF= 5.5 9*/
                    hoffset       = 5
                    nolimits
				    readphase = all
				    phaseref
					PHASELABTYPE=5
				    phaselegend
                    notches;
  run;
  ods pdf close;


Title justify=center h=1.5 'Box Plot - xxx Change from Baseline Over Time (Weeks Since Randomized)';
 Footnote1 JUSTIFY= LEFT h=1 'wks=visit weeks; end=last postbaseline measure; Box plot type=schematic; The box shows median,interqutile range (IQR, edge'
  ' of the bar), min and max within 1.5 IQR below 25% and above 75% (ends of the';
 Footnote2 JUSTIFY= LEFT h=1 'whisker). Values outside the 1.5 IQR below 25% and above 75% are shown as outliers.'
  ' Means ploted as different symbols by treatments. ';
 Footnote3 justify=left h=1 'P value is for the treatment comparison from ANCOVA'
  ' model Change=Baseline+Treatment';
 
 symbol1 v=circle h=.75 c=orange;
 symbol2 v=star h=.75 c=blue;
 axis1 value=none label=none order=(0 to 16.5 by 1) offset=(0,0) major=none;
 axis2 label=(j=c h=1  "xxx Change from Baseline (Unit)") minor=(n=4);
 proc shewhart graphics data=plot_chg_vst;
    boxchart change*ttpoint (block10 block9 block8 block7 block6 block5 block4 block3 block2 block1 )=Treatment /
                    BLOCKLABTYPE=2
                    blockpos      = 3
					blockrep
				    stddevs
					boxwidth=2
                    boxwidthscale = 0
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
				    phaseref
				    phaselegend
                    notches;
    run;
 ods pdf close;
 goptions reset=all;


 
