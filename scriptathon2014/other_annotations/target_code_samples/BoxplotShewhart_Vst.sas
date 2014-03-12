
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

proc sort data=new out=nodupnew;
 by trt wks id;
run;
ods output CrossTabFreqs=freq;
ods trace off;
ods listing close;
 proc freq data=nodupnew;
   tables trt*wks;
 run;
ods listing; 

/*ttpoint define the location of the box for each visit */
data frq;
 set freq;
 if _type_='11';
 keep wks trt ttpoint N_Subj;
 ttpoint=1+wks+trt*0.5;
 N_subj=frequency;
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
 proc sort data=new;
  by wks trt;

 proc means data=new noprint;
    by wks trt;
    var lab_test_1;
    output out=stats n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
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
 if lab_test_1>9 then TE_High=1;
 else TE_High=0;
 if lab_test_1<5.5 then TE_low=1;
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
 x=ttpoint;
 y=lab_test_1;
run; 

proc sort data=annoraw;
 by wks trt id;

data abnorcnt;
 set annoraw;
 by wks trt id;
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

data abnrmfrq;
 set abnorcnt;
 by wks trt id;
 retain CNT_H CNT_L 0;
 keep wks trt cnt_h cnt_l lab_test_1 TE_L TE_H;
 if first.trt then do;
   cnt_h=0;
   cnt_l=0;
 end;
  cnt_h=cnt_h+TE_h;
  cnt_L=cnt_l+TE_l;
 if last.trt;
run;

data stats1;
 merge stats abnrmfrq frq;
 by wks trt;
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

 
  * Create block variables used to produce table ;
 data blockraw;
    length  block1 block2 block3 block4 block5 block6 block7 block8 block9 $40.;
    keep block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 block11 trt wks treatment n_subj tehigh telow TTpoint ;
    set stats1;
	by wks trt;
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
	block10=tehigh;
	block11=telow;
run;

data labelraw;
  Treatment=' A';
  ttpoint=0;
  length  block1 block2 block3 block4 block5 block6 block7 block8 block9 block10 block11  $40.;
       block2 = left('N   ');
       block3 = left('Mean  ');
       block4 = left('Std    ');	   
       block5 = left('Min    ');
       block6 = left('Q1     ');
	   block7 = left('Median   ');
	   block8 = left('Q3     ');
	   block9 = left('Max    ');
       block1 = left('Treatment ');
	   block10= left('High n(%)');
	   block11= left('Low n(%)');
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

 /* visit wise boxplot data */ 
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
 cate=compress('Weeks='||wks);
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
 ttpoint=_n_-trt*0.1;
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

/**************************************************generate the boxplot *****************************************************
 ods listing;
 options orientation=landscape;
 ods pdf;
 Title justify=center h=1.5 'Box Plot - xxx Measures Over Time (Weeks Since Randomized)';

 Footnote1 JUSTIFY= LEFT h=1 'Box plot type=schematic, the box shows median,interqutile range (IQR, edge of the bar), min and max'
  ' within 1.5 IQR below 25% and above 75% (ends of the whisker).Values outside the 1.5 IQR below 25% and';
 Footnote2 JUSTIFY= LEFT h=1 'above 75% are shown as outliers. Means plotted as different symbols by treatments. Red dots indicate'
  ' out of normal reference range measures. xxxx reference range is used.';
 
 symbol1 v=circle h=.75 c=orange;
 symbol2 v=star h=.75 c=blue;
 axis1 value=none label=none order=(0.5 to 8.8 by 1) offset=(0,0) major=none;
 axis2 label=(j=c h=1  "xxx Measures (Unit)") minor=(n=4);
 proc shewhart graphics data=plot_visit;
    boxchart lab_test_1*ttpoint (block11 block10 block9 block8 block7 block6 block5 block4 block3 block2 block1 )=Treatment /
         anno=annoraw
 					blocklabtype  = 1.3
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
ods pdf;
Title justify=center h=1.5 'Box Plot - xxx Change from Baseline Over Time (Weeks Since Randomized)';
 Footnote1 JUSTIFY= LEFT h=1 'wks=visit weeks; end=last postbaseline measure; Box plot type=schematic; The box shows median,interqutile range (IQR, edge'
  ' of the bar), min and max within';
 Footnote2 JUSTIFY= LEFT h=1 ' 1.5 IQR below 25% and above 75% (ends of the whisker). Values outside the 1.5 IQR below 25% and above 75% are shown as outliers.'
  ' Means plotted as different';
 Footnote3 justify=left h=1 'symbols by treatments. P value is for the treatment comparison from ANCOVA'
  ' model Change=Baseline+Treatment';
 
 symbol1 v=circle h=.75 c=orange;
 symbol2 v=star h=.75 c=blue;
 axis1 value=none label=none order=(0 to 16.5 by 1) offset=(0,0) major=none;
 axis2 label=(j=c h=1  "xxx Change from Baseline (Unit)") minor=(n=4);
 proc shewhart graphics data=plot_chg_vst;
    boxchart change*ttpoint (block10 block9 block8 block7 block6 block5 block4 block3 block2 block1 )=Treatment /
                    BLOCKLABTYPE=1.2
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
					vREF= 0
                    hoffset       = 5
                    nolimits
				    readphase = all
				    phaseref
				    phaselegend
                    notches;
    run;


ODS pdf close;
 goptions reset=all;

 */
/******************************************************************
  Treatment emergent table and boxplot
  *****************************************************************/
  data base post;
   set one;
   if wks=0 then output base;
   else output post;
  run;

  %macro TE_data(in, phase, out);
    proc sort data=&in;
	 by id wks;

	data &out;
	 set &in;
	 by id wks;
	 keep id trt &phase.min &phase.max &phase.lst; 
	 retain &phase.min &phase.max;
	 if first.id then do;
	  &phase.min=lab_test_1;
      &phase.max=lab_test_1;
     end;
	 else do;
	  if &phase.min>lab_test_1 then &phase.min=lab_test_1;
	  if &phase.max<lab_test_1 then &phase.max=lab_test_1;
	 end;
	 if last.id then do;
	  &phase.lst=lab_test_1;
	  output;
	 end;
	Run;
  %mend TE_data;
  %TE_data(base, bse, bse);
  %TE_data(post, pst, pst);

data final;
  merge bse(in=a) pst(in=b);
  by id;
  if a and b;
  if bsemin>5.5 then do;
     if pstmin<=5.5 then TE_low=1;
	 else  TE_low=0;
  end;
  if bsemax<9 then do;
     if pstmax>=9 then TE_high=1;
	 ELse TE_high=0;
  end;
  if 5.5<bselst<9 then do;
     if pstlst>=9 or pstlst<=5.5 then TE_abn=1;
	 else TE_abn=0;
  end;
run; 

ods trace on;
ods trace off;
ods output CrossTabFreqs=TE_Frq;
ods output FishersExact=TE_Exact;
proc freq data=final;
 tables TRT*TE_low TE_high*trt TE_abn*trt/Exact;
run;

data TE_frq1;
 set TE_Frq;
 if _type_='11';
 keep table trt TE_low TE_high TE_abn Frequency;
run; 

proc sort data=TE_frq1;
 by table trt;
run;

data TE_frq2;
 set TE_frq1;
 by table trt;
 retain BN SN;
 keep table BN SN PCT TRT TE_low TE_high TE_abn Frequency;
 if first.trt then do;
  BN=frequency;
  SN=Max(TE_low, TE_high, TE_abn)*frequency;
 end;
 else do;
  BN=BN+frequency;
  SN=SN+Max(TE_low, TE_high, TE_abn)*frequency;
 end;
 if last.trt then do;
  PCT=round(SN/BN*100, 0.1);
  output;
 end;
run;

data TE_exact;
 set TE_exact;
 trt=1;
run;

proc sort data=TE_exact;
  where name1='XP2_FISH';
  by table trt;
run;

data frqtable;
 merge te_frq2 te_exact;
 length category $ 40.;
 by table trt;
 	if trt=0 then Treatment=' A';
	if trt=1 then Treatment=' B';
 *if index(table, 'TE_abn')>0 then category='Treatment Emergent Abnormal';
  if index(table, 'TE_abn')>0 then delete;
 if index(table, 'TE_high')>0 then category='Treatment Emergent High';
 if index(table, 'TE_low')>0 then category='Treatment Emergent Low';
 pval=round(nvalue1, .0001);
 keep category treatment BN SN PCT pval;
run;


 Title justify=center h=1.5 ' Box Plot - xxx Measures Over Time (Weeks Since Randomized)/Treatment Emergent Change ';

 Footnote1 JUSTIFY= LEFT h=1 ' Box plot type=schematic, the box shows median,interqutile range (IQR, edge of the bar), min and max'
  ' within 1.5 IQR below 25% and above 75% (ends of the whisker).Values outside the 1.5 IQR below 25% and above 75% are shown as outliers.'
  ' Means plotted as different symbols by treatments. Red dots indicate out of normal reference range measures. xxxx reference range is used.';
 Footnote2 Justify=left h=1 ' N=# of subjects with all baseline measures fulfill (TE high:<ULN, TE low:>LLN) n=# of subjects in the N and'
  ' with any post-baseline measures fulfill (TE high:>=ULN, TE low:<=LLN)  %=n/N*100 ULN=Upper limit normal  LLN=Lower limit normal'; 
 options orientation=portrait;
 ods pdf;
 
 /* Start the Layout */ 
ODS Layout start width = 8in height = 10in; 
 /* Start first region */ 

 ods region x=0 pct    height=60 pct 
            y=0 pct    width =90 pct; 
title;
 footnote;

 symbol1 v=circle h=.75 c=orange;
 symbol2 v=star h=.75 c=blue;
 axis1 value=none label=none order=(0.5 to 8.8 by 1) offset=(0,0) major=none;
 axis2 label=(j=c h=1  "xxx Measures (Unit)") minor=(n=4);
 proc shewhart graphics data=plot_visit;
    boxchart lab_test_1*ttpoint (block11 block10 block9 block8 block7 block6 block5 block4 block3 block2 block1 )=Treatment /
         anno=annoraw
 					blocklabtype  = 1.3
                    blockpos      = 3
					blockrep
				    stddevs
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
				    phaseref
					PHASELABTYPE=5
				    phaselegend
                    notches
                    nolegend;
  run;
/* Start second region */ 

ods region x=0 pct height=40 pct 
           y=65 pct width =90 pct; 


proc report data=frqtable nofs headline headskip;

column category treatment,(BN SN PCT) pval;
define category / group width=20;
define treatment / across width=8 'Treatment';
define BN / display format=5.0 'N' width=6;
define SN / display format=5.0 'n' width=6;
define PCT/display format=5.2 '%' width=6;
define pval/max format=5.4 'Exact P-value';
run;
ODS layout end; 

Title justify=center h=1.5 'Box Plot - xxx Change from Baseline Over Time (Weeks Since Randomized)';
 Footnote1 JUSTIFY= LEFT h=1 'wks=visit weeks; end=last postbaseline measure; Box plot type=schematic; The box shows median,interqutile range (IQR, edge'
  ' of the bar), min and max within';
 Footnote2 JUSTIFY= LEFT h=1 ' 1.5 IQR below 25% and above 75% (ends of the whisker). Values outside the 1.5 IQR below 25% and above 75% are shown as outliers.'
  ' Means plotted as different';
 Footnote3 justify=left h=1 'symbols by treatments. P value is for the treatment comparison from ANCOVA'
  ' model Change=Baseline+Treatment';
 
 symbol1 v=circle h=.75 c=orange;
 symbol2 v=star h=.75 c=blue;
 axis1 value=none label=none order=(0 to 16.5 by 1) offset=(0,0) major=none;
 axis2 label=(j=c h=1  "xxx Change from Baseline (Unit)") minor=(n=4);
 proc shewhart graphics data=plot_chg_vst;
    boxchart change*ttpoint (block10 block9 block8 block7 block6 block5 block4 block3 block2 block1 )=Treatment /
                    BLOCKLABTYPE=1.0
                    blockpos      = 3
					blockrep
				    stddevs
					boxwidth=2 
                    boxstyle      = schematic
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					height=1.5
				    /*vREFLABELS='Lower Limit' 'Upper Limit'*/
					vREF= 0
                    hoffset       = 5
                    nolimits
		            readphase = all
                    phaseref
				    phaselegend
                    notches
                    nolegend;
    run;


ODS pdf close;



 /***************Graphs for PHUSE White Paper 1 *****************************/
 options orientation=landscape;
 ods pdf;

 Title justify=center h=1.5 ' Box Plot - xxx Measures Over Time (Weeks Since Randomized)/Treatment Emergent Change ';

 Footnote1 JUSTIFY= LEFT h=1 ' Box plot type=schematic, the box shows median,interqutile range (IQR, edge of the bar), min and max'
  ' within 1.5 IQR below 25% and above 75% (ends of the whisker).';
 Footnote2 JUSTIFY= LEFT h=1 ' Values outside the 1.5 IQR below 25% and above 75% are shown as outliers.'
  ' Means plotted as different symbols by treatments. Red dots indicate out of normal reference range measures.';
 symbol1 v=circle h=.75 c=orange;
 symbol2 v=star h=.75 c=blue;
 axis1 value=none label=none order=(0.5 to 8.8 by 1) offset=(0,0) major=none;
 axis2 label=(j=c h=1  "xxx Measures (Unit)") minor=(n=4);
 proc shewhart graphics data=plot_visit;
    boxchart lab_test_1*ttpoint ( block9 block8 block7 block6 block5 block4 block3 block2 block1 )=Treatment /
         anno=annoraw
 					blocklabtype  = 1.3
                    blockpos      = 3
					blockrep
				    stddevs
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
				    phaseref
					PHASELABTYPE=5
				    phaselegend
                    notches
                    nolegend;
  run;


 Title justify=center h=1.5 'Box Plot - xxx Change from Baseline Over Time (Weeks Since Randomized)';
 Footnote1 JUSTIFY= LEFT h=1 'Endpoint=last postbaseline measure; Box plot type=schematic; The box shows median,interqutile range (IQR, edge'
  ' of the bar), min and max within 1.5 IQR below';
 Footnote2 JUSTIFY= LEFT h=1 '25% and above 75% (ends of the whisker). Values outside the 1.5 IQR below 25% and above 75% are shown as outliers.'
  ' Means plotted as different symbols by treatments.';
 Footnote3 justify=left h=1 'P value is for the treatment comparison from ANCOVA model Change=Baseline+Treatment';
 
 symbol1 v=circle h=.75 c=orange;
 symbol2 v=star h=.75 c=blue;
 axis1 value=none label=none order=(0 to 16.5 by 1) offset=(0,0) major=none;
 axis2 label=(j=c h=1  "xxx Change from Baseline (Unit)") minor=(n=4);
 proc shewhart graphics data=plot_chg_vst;
    boxchart change*ttpoint (block10 block9 block8 block7 block6 block5 block4 block3 block2 block1 )=Treatment /
                    BLOCKLABTYPE=1.2
                    blockpos      = 3
					blockrep
				    stddevs
					boxwidth=2 
                    boxstyle      = schematic
					haxis=axis1
					vaxis=axis2
					CvREF=Red
					height=1.5
				    /*vREFLABELS='Lower Limit' 'Upper Limit'*/
					vREF= 0
                    hoffset       = 5
                    nolimits
		            readphase = all
                    phaseref
				    phaselegend
                    notches
                    nolegend;
    run;


ODS pdf close;



               





  /***********
ods listing;
 options orientation=landscape;
 ods pdf;
 Title justify=center h=1.5 'Box Plot - xxx Measures Over Time (Weeks Since Randomized)';

 Footnote1 JUSTIFY= LEFT h=1 'The box shows median,interqutile range (IQR, edge of the bar), min and max.'
                             'Means plotted as different symbols by treatments.';
 Footnote2 JUSTIFY= LEFT h=1 'Red dots indicate out of normal reference range measures. xxxx reference range is used.';
 
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


Title justify=center h=1.5 'Box Plot - xxx Change from Baseline Over Time (Weeks Since Randomized)';
 Footnote1 JUSTIFY= LEFT h=1 'wks=visit weeks; end=last postbaseline measure; Box plot type=schematic; The box shows median,interqutile range (IQR, edge'
  ' of the bar), min and max within 1.5 IQR below 25% and above 75% (ends of the';
 Footnote2 JUSTIFY= LEFT h=1 'whisker). Values outside the 1.5 IQR below 25% and above 75% are shown as outliers.'
  ' Means plotted as different symbols by treatments. ';
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
					vREF= 5.5 9
                    hoffset       = 5
                    nolimits
				    readphase = all
				    phaseref
				    phaselegend
                    notches;
    run;
 ods pdf close;
 goptions reset=all;

*/
 
