
*Form ADaM
Specify Test.
Specify Treatment Variable.

Flag for Minimal Baseline Value per Subject per Test.
Flag for Maximum Post Baseline Value per Subject per Test.
ULN and LLN ensure ANRLO and ANLHI are unique per Test.

*Concern: White Paper currently wants both the SI and Conventional Unit Displayed
Option to only show SI or show both SI and CN (Need Multiple Rows per Test)
;

data test;
USUBJID = "1"; TRT = "PL"; Base = 10; Post = 30; ULN = 55; LLN =15; output;
USUBJID = "2"; TRT = "PL"; Base = 30; Post = 20; ULN = 55; LLN =15; output;
USUBJID = "3"; TRT = "PL"; Base = 40; Post = 30; ULN = 55; LLN =15; output;
USUBJID = "4"; TRT = "T1"; Base = 60; Post = 50; ULN = 55; LLN =15; output;
USUBJID = "5"; TRT = "T1"; Base = 30; Post = 22; ULN = 55; LLN =15; output;
USUBJID = "6"; TRT = "T1"; Base = 22; Post = 12; ULN = 55; LLN =15; output;
USUBJID = "7"; TRT = "T2"; Base = 39; Post = 38; ULN = 55; LLN =15; output;
USUBJID = "8"; TRT = "T2"; Base = 49; Post = 44; ULN = 55; LLN =15; output;
USUBJID = "9"; TRT = "T2"; Base = 12; Post = 60; ULN = 55; LLN =15; output;
run;


libname adam "\\quintiles.net\enterprise\Apps\sasdata\StatOpB\CSV\9_GB_PhUSE\phuse-scripts\data\adam\cdisc-split\";

DATA ADLBC; SET ADAM.ADLBC;
	WHERE PARAMCD = "SODIUM";
RUN;
DATA START; SET ADLBC;
	*ONLY SUBSET LAST POST BASELINE OBSERVATION;
	WHERE AENTMTFL = "Y" AND AVISITN NE 99;
	KEEP USUBJID TRTAN TRTA PARAMCD PARAM AVAL BASE A1LO A1HI;
RUN;

PROC FREQ DATA = START NOPRINT;
	TABLES PARAMCD * A1LO / OUT = LOW;
	TABLES PARAMCD * A1HI / OUT = HIGH;
RUN;

PROC SORT DATA = LOW; BY PARAMCD DESCENDING COUNT; RUN;
DATA LOW; SET LOW;
BY PARAMCD DESCENDING COUNT; 
IF FIRST.PARAMCD;
CALL SYMPUTX("LLN", A1LO);
RUN;

PROC SORT DATA = HIGH; BY PARAMCD DESCENDING COUNT; RUN;
DATA HIGH; SET HIGH;
BY PARAMCD DESCENDING COUNT; 
IF FIRST.PARAMCD;
CALL SYMPUTX("ULN", A1HI);
RUN;

%PUT &LLN;
%PUT &ULN;


*Goal for now is to just do a Single Unit SI or CV as a start;

proc template;
define statgraph sgdesign;
dynamic _BASE _POST _TRT;
begingraph / designwidth=951 designheight=689 dataskin=none 
			DataSymbols = (PLUS circlefilled trianglefilled) 
			DataColors=(CXFFA53D CXF7DF54 CXEF6B48 CX61A6E7 CXCB79C8 CX85CE79 CX967CD0 CXDD6475 CX9DAA2D CX6C69D9 CX2EA64A CXC17D35);
   entrytitle halign=center 'Figure 11.1 Scatterplot';
   entryfootnote halign=left 'LLN ULN ....';

   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
   layout overlay / wallcolor=CXFFFFFF 
						xaxisopts=( griddisplay=on /*linearopts=( viewmin=0.0 viewmax=65.0)*/ label=('Min. Baseline')) 
						yaxisopts=( griddisplay=on /*linearopts=( viewmin=0.0 viewmax=65.0)*/ label=('Min. Post Baseline'));

         scatterplot x=_BASE y=_POST / group=_TRT name='scatter';* markerattrs=(symbol=PLUS  weight=bold);

		*This will draw 45 Degree Refeence Line;
		drawline x1=0 y1=0 x2=100 y2=100 /
                  x1space=wallpercent y1space=wallpercent
                  x2space=wallpercent y2space=wallpercent
                  lineattrs=GraphReference ;

         discretelegend 'scatter' / title="Treatment" opaque=false border=false halign=right valign=center displayclipped=true across=1 order=rowmajor location=outside;

         referenceline y=&ULN / name='href'  yaxis=Y curvelabel='ULN' curvelabelposition=min lineattrs=(color=CX0000FF pattern=SHORTDASH );
		 referenceline y=&LLN / name='href2' yaxis=Y curvelabel='LLN' curvelabelposition=min lineattrs=(color=CXFF0000 pattern=SHORTDASH );
         referenceline x=&LLN / name='vref'  xaxis=X curvelabel='LLN' curvelabelposition=min lineattrs=(color=CXFF0000 pattern=SHORTDASH );
         referenceline x=&ULN / name='vref2' xaxis=X curvelabel='ULN' curvelabelposition=min lineattrs=(color=CX0000FF pattern=SHORTDASH );

		 
      endlayout;
   endlayout;
endgraph;
end;

run;

proc sgrender data=WORK.START template=sgdesign;
dynamic _BASE="BASE" _POST="AVAL" _TRT="TRTA";
run;

