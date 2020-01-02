******************************************;
* Program name: P_ADPC.sas               *;
*                                        *;
* Description:  Plot of PK Conc          *;
*               (Target 11)              *;
*                                        *;
* Author:       John Salter              *;
*               12OCT2014                *;
******************************************;

%* modification 2019-12-23 - update path as data has been moved;

filename source url "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/adpc.xpt";
libname source xport ;

* Bring in specified data;
data conc;
 set source.adpc (keep=usubjid trta aperiodc atpt parcat3l aval adtm saffn pkfn paexcfln pclloq parcat1);
 t=input(compress(atpt,' HOURSPOSTDOSE'),best.);
 concen=aval;
 order=input(compress(parcat1,' DRUGANALPlasma'),best.);
 label t='Time'
       concen='Concentration (ug/mL)';
 * Apply LLOQ;
 if pclloq ne . then concen=pclloq;
run;

proc sort data=conc;
*  by order trta usubjid t;
  by usubjid t;
run;



* END DATA MANIPULATION *;
ods graphics on /width=24cm height=12cm noborder ; 
ods listing image_dpi=300 style=listing; 

proc template;
define statgraph pkplot;
  begingraph;
   layout lattice / columns=2 columnweights=(.50 .50);
   /* LINEAR PLOT  */
   layout OVERLAY / walldisplay=none border=false 
     	           halign=center;
     entry halign=center "Linear view" /  location=outside valign=top;      
     seriesplot x=t y=concen/group=usubjid lineattrs=(color=black pattern=1);
   endlayout;
   /* LOG-LINEAR PLOT */
   layout OVERLAY / walldisplay=none border=false 
     	           halign=center
     yaxisopts=(type=log logopts=(base=10 minorticks=TRUE) label=(' ')   );
     entry halign=center "Semilogarithmic view" /  location=outside valign=top;      
     seriesplot x=t y=concen/group=usubjid lineattrs=(color=black pattern=1);
   endlayout;
  endlayout;
endgraph;
end;
run;	

%macro plot(trta=);

%do i=1 %to 3;

title1 "Overlaid PK Concentration Plots";
title2 "Analyte: &I; Treatment=&TRTA";
proc sgrender data=conc template=PKPlot;
  where order=&I and trta="&TRTA";
run; 

%end;

%mend;
%plot(trta=A);
%plot(trta=C);

ods graphics off;
