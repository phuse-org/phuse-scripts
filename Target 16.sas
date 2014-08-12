filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/advsmax.xpt" ;
libname source xport ;
data work.advsmax ;
	set source.advsmax;
   run;

data advsmax2;
   set advsmax(where=((PARAMCD="DIABP") and (ATPTN=815) and (ANL01FL="Y") and (ADY > 1) and (SAFFL="Y")));
   keep USUBJID TRTPN PARAM PARAMCD AVAL ANL01FL BNRIND ANRIND SHIFT1 CRIT1FL
	      ANRLO ANRHI 
			BASE AVAL
			Ref
         ;
	if not nmiss(base, aval) then Ref = Base;
	label BASE = "Max. Baseline"
	      AVAL = "Max. Post baseline"
			;
	run ;


*--------------------------------------------------------------------------------
Produce the baseline shift frequency table
*--------------------------------------------------------------------------------;

proc sort data = advsmax2;
   by TRTPN;
	run;

proc freq data = advsmax2 noprint;
   by TRTPN;
   table BNRIND * ANRIND / missing out = TableA;
	table BNRIND / missing out = BNRIND;
	table ANRIND / missing out = ARIND;
	table TRTPN / missing out = TRTPN;
	run;

data TableA;
   set TableA;
	by TRTPN;
	length ValueFmt $100;
	ValueFmt = trim(left(put(count, comma8.))) !! " (" !! trim(left(put(percent, 10.1))) !! ")";
	run;

* MERGE ON GROUP NS AND ADD TO THE GROUP LABEL;

data TableA;
   merge TableA
	      TRTPN(rename = (Count = GroupN Percent = GroupPercent));
	by TRTPN;
	length GroupFmt $100;
   GroupFmt = trim(left(TRTPN)) !! " (N = " !! trim(left(put(GroupN, comma10.))) !! ")";
	run;

proc transpose data = TableA out = TableAt prefix = ValueFmt;
   by GroupFmt BNRIND;
	var ValueFmt;
	id ANRIND;
	run;

*--------------------------------------------------------------------------------
Produce the treatment emergent high table
*--------------------------------------------------------------------------------;

data advsmax3; 
   set advsmax2;

	if (CRIT1FL ne "");
	*n = (CRIT1FL="Y");
   n = mod(_n_,17) = 1;
   run;
	
proc summary data = advsmax3 nway;
   class TRTPN;
	var n;
	output out = EmergentHigh n=Nx sum = n mean = percent;
	run;

data FishersExact;
   Name1 = "XP2_FISH";
	nValue1 = .;
	run;
proc freq data = advsmax3;* noprint;
   ods output FishersExact=FishersExact;
   table TRTPN * n / exact;
	run;

data PValue;
   set FishersExact;
	if Name1 = "XP2_FISH";
	*length FishersP $12;
	rename Nvalue1=FishersP;
	format NValue1 pvalue.;
	run;

data EmergentHigh;
   merge EmergentHigh
         PValue;
	format percent 6.1;
	if n(percent) then percent = 100 * percent;
	run;



	
*--------------------------------------------------------------------------------
Set up the ODS Template
*--------------------------------------------------------------------------------;
	
options orientation=landscape; 
ods pdf file = "Target16.pdf" style = journal fontscale = 70;

ods layout start width = 9in height = 7.5in;

*--------------------------------------------------------------------------------
Produce the graph
*--------------------------------------------------------------------------------;

%LET MAJOR = 10;   * MAJOR TIC UNITS;

proc summary data = advsmax2 nway;
   var ANRLO ANRHI BASE AVAL ;
	output out = ADVSMAXSum mean =   min(AVAL) = MinValue max(AVAL) = MaxValue;
	run;
	    
* MANUALLY IDENTIFY Y AXIS MIN AND MAX TO APPLY TO BOTH PLOT AND PLOT2;
* (OTHWERISE DEFAULT SELECTION MAY DIFFER BETWEEN PLOT AND PLOT2);
data _null_;
   set ADVSMAXSum;
	call symput("ANRLO",trim(left(ANRLO)));
	call symput("ANRHI",trim(left(ANRHI)));
	margin = (maxvalue - minvalue) / 100;  * ADD MARGINS 1% OF RANGE;
	YAxisMin =  &MAJOR * (floor((minvalue - margin) / &MAJOR));
	YAxisMax =  &MAJOR * ( ceil((maxvalue + margin) / &MAJOR));
	call symput("MINVALUE", YAxisMin);
	call symput("MAXVALUE", YAxisMax);
	put _all_;
	run;


* NOTE: DEPENDENT ON NUMBER OF TREATMENTS;

ods region x = .5in y = .5in height = 4.5in width = 4.5in;

goptions colors=(blue,red,green);
symbol1 interpol = none value = triangle c=green;
symbol2 value = circle c=red;
symbol3 value = x c=blue;
symbol4 value = none interpol = RL value = none line = 21 CI = black;
legend1 position = bottom;
proc gplot data = advsmax2;
   title "Scatter Plot-Max. Post-baseline vs Max. Baseline for Lab Test 1 (mmol/L)";
   plot AVAL * base = TRTPN/ 
	   vref = &ANRLO, &ANRHI lvref = 21 cvref = (blue red) vaxis = &MINVALUE to &MAXVALUE by &MAJOR
      href = &ANRLO, &ANRHI lhref = 21 chref = (blue red) 
      ;
	plot2  Ref * base / overlay noaxis vaxis = &MINVALUE to &MAXVALUE by &MAJOR ;
	legend ;

   run; 


* FOR EACH COLUMN WITH VALUES, CREAT PROC REPORT CODE FOR COLUMSN STMT AND DEFINE STATMENTS;
proc format;
   picture percpar 
	   low-high = "009.9)"
		(prefix = "(");
	run;

* BASELINE SHIFT TABLE;
	
ods region x = 5in y = .5in height = 3.5in;
options missing = "";
proc report data = TableA split="#" style(header)={borderstyle=solid}; * style(report)={fontsize=9pt} style(column)={fontsize=9pt} ;  
	columns GroupFmt BNRIND ("Max Post Basline Result (shift from baseline)" (ANRIND,("N (%)" (count percent))));
	*columns GroupFmt BNRIND ("Max Post Basline Result (shift from baseline)" (ANRIND,("N (%)" (ValueFmt))));
	define GroupFmt / "Treatment" group style(column)={just=center cellwidth=1in verticalalign=bottom};
   define BNRIND / "Max. Baseline Result" group  style(column)={just=center cellwidth=1in verticalalign=bottom};
	compute after GroupFmt;
      line " ";
		endcomp;
	define ANRIND / across ;
	define count / " " analysis sum right format = 4. style(column)={just=right cellwidth=.4in borderrightstyle=hidden}; * sum noprint  right;
	define percent / " " analysis sum left format = percpar6. style(column)={just=left cellwidth=.4in borderleftstyle=hidden}; *analysis sum noprint  left;
	run;
   quit;

* EMERGENT HIGH TABLE;

ods region x = 5in y = 4in height = 2.5in;
proc report data = EmergentHigh split="#" style(report)={borderleftstyle=solid} style(header)={textalign=left};*style(report)={fontsize=9pt} style(column)={fontsize=9pt} ; 
	columns TRTPN  ("Treatment Emergent High" (Nx n percent FishersP));
   define TRTPN / display style(column)={cellwidth = .7in};
	define Nx / display style(column)={cellwidth = .7in textalign=left};
	define n / display style(column)={cellwidth = .7in textalign=left};
	define percent / "%" display style(column)={cellwidth = .7in textalign=left};
	define FishersP / display style(column)={cellwidth = .7in textalign=left};
	run;


ods region x = .5in y = 6in height = 1.5in;
ods text="Scatter Plot: Includes subjects with both a baseline and a post-baseline measure.  Reference limits apply to most of the participants are used in the plot";
ods text="N=number of subjects with at least one post-baseline measure; Nx=number of subjects with maximum baseline either normal or low and have at least one post-baseline measure.";
ods text="Summary tables used the reference limits set 1 (Male, Age 18-65, LLNx &ANRLO mmol/L ULNx &ANRHI mmol/L) set 2 (Female, Age 18-65, LLN=&ANRLO mmol/L ULN=&ANRHI mmol/L).";

ods layout end;


ods pdf close;

