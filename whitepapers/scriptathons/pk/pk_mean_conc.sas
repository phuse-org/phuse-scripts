*------------------------------------------------------------------------------*;
*                                                                              *;
* Program Name    :  Target13.sas                                              *;
* Program Type    :  Figure                                                    *;
* Author          :  Adrienne M Bonwick                                        *;
* Date            :  17 March 2014                                             *;
*------------------------------------------------------------------------------*;
* Purpose: SAS program to produce the PhUSE target 13.                         *;
*------------------------------------------------------------------------------*;
* Input : http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/       *;
*                data/adsl.xpt                                                 *;
*                                                                              *;
* Output:  Generated output plot AB_check.rtf                                  *;
*------------------------------------------------------------------------------*;
* Operating system: Windows/Citrix                                             *;
*                   SAS 9.3                                                    *;
*------------------------------------------------------------------------------*;
* Modification Log                                                             *;
*   Programmers Name:                                                          *;
*   Date:                                                                      *;
*   Description:                                                               *;
********************************************************************************;

filename source clear;
libname source clear;
%* modification 2019-12-23 - update path as data has been moved;

filename source url "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/adpc.xpt";
libname source xport ;

data work.orig_adpc ;
set source.adpc;
run;

%let syscc=0;
options mprint;

%macro target13(PCTESTCD=, Meantype=A, SD=Y);
%if %upcase("&PCTESTCD") = " " %then
  %put %str(E)RROR: Need to specify a variable to test;;
%if %upcase("&meantype") ne "G" and %upcase("&meantype") ne "A" %then
  %put %str(E)RROR: Need to specify either Geometric or Arithmetic option;;
%if %upcase("&SD") ne "UPPER" and %upcase("&SD") ne "BOTH" and %upcase("&SD") ne "N"  %then
  %put %str(E)RROR: Need to specify Upper, Both or No Bars;;


data work.adpc ;
set source.adpc(keep=ANLPRNT TRTAN ANLPRNT PCSPEC PCTESTL TRTA DOSREFID PCTESTCD
                     PCORRESU PCORRES USUBJID  PCORRESN EPLTM);

  where PCTESTCD="&PCTESTCD";
  PCTPT=input(EPLTM,best10.);
  ORDERBY=compress( ANLPRNT||PCSPEC||PCTESTL||TRTAN); 	
  BYVAL6=compbl(propcase(pctestcd)||' Conc '||' ('||PCORRESU||')'); 
run ;

proc sort data=ADPC;
 by TRTAN TRTA PCTPT;
run;

%if &meantype=A %then %do;

  proc univariate data=ADPC noprint;
     by TRTAN TRTA PCTPT;
     var PCORRESN;
	 output out=PCMEANS mean=PCmean STD=PCSD ;
  run;

  data MeanData;
    set PCMEANS;
	if PCMEAN=0 then do;
	   PCMEAN=.;
	   PCSD=.;
	end;
  run;
%end;

%if &meantype=G %then %do;

  data LOGPC;
    set ADPC;
	if PCORRESN ne . then LOGORRES=log(PCORRESN);
  run;

  proc univariate data=LOGPC noprint;
     by TRTAN TRTA PCTPT;
     var PCORRESN;
	 output out=LogMEANS mean=Logmean STD=logSD ;
  run;

  data MeanData;
    set LogMEANS;
    PCMEAN=EXP(LogMEANS);
    PCSD=EXP(logSD);
  run;
%end;

   proc template;
   define statgraph temp_pksum;
   DYNAMIC _XMAX _YMAX _XLABEL _YLABEL _SD TICKS VIEW GSTAT _LEGENDSIZE;
   MVAR SCALE1 SCALE2 TRTLBL ;
   begingraph / designwidth=2500px designheight=1400px;
   layout lattice / columns=2 rows=2 ROWWEIGHTS= (.9 .1) ;
   cell;
   cellheader;
   entry "Linear view" / textattrs=(size=9pt) ;
   endcellheader;
   *layout for linear scale;
   layout overlay /XAXISOPTS =( LABEL=_XLABEL LABELATTRS=GRAPHVALUETEXT(SIZE=10pt) 
                                tickvalueattrs=(size=9) Linearopts=( viewmin=0 viewmax=_XMAX tickvaluelist=ticks tickvaluefitpolicy=NONE)) 
                   YAXISOPTS =(LABEL=_YLABEL LABELATTRS=GRAPHVALUETEXT(SIZE=10pt) tickvalueattrs=(size=9) Linearopts=( viewmin=0 viewmax = _YMAX ));

   if (_SD = 'BOTH'  )

        scatterplot x=PCTPT y=PCMEAN / yerrorlower=eval(PCMEAN - PCSD) 
              yerrorupper=eval(PCMEAN + PCSD) group=TRTAN MARKERATTRS=(color=black ) 
              yerrorupper=eval(PCMEAN + PCSD) group=TRTAN MARKERATTRS=(color=black ) name="s2" ;
   seriesplot x=PCTPT y=PCMEAN /group=TRTAN LINEATTRS=(color=black) name="s1";

				   
   endif;

   if (_SD = 'UPPER'  )
         scatterplot x=PCTPT y=PCMEAN /  yerrorlower=eval(PCMEAN) 
                             yerrorupper=eval(PCMEAN + PCSD) 
                             group=TRTAN MARKERATTRS=(color=black ) 
                             MARKERATTRS=(color=black ) name="s2" ;
         seriesplot x=PCTPT y=PCMEAN /group=TRTAN LINEATTRS=(color=black) name="s1";
		 
   endif;
   if ( _SD = 'N' )
          scatterplot x=PCTPT y=PCMEAN / group=TRTAN MARKERATTRS=(color=black ) name="s2" ;
          seriesplot x=PCTPT y=PCMEAN /group=TRTAN LINEATTRS=(color=black) name="s1";
   endif;
   endlayout;
   endcell;
   cell;
   cellheader;
   entry "Semilogarithmic view" / textattrs=(size=9pt) ;
   endcellheader;
   *layout for semi logarithmic scale;
   layout overlay / YAXISOPTS =( LABEL=_YLABEL tickvalueattrs=(size=9) 
                      LABELATTRS=GRAPHVALUETEXT(SIZE=10pt) 
                      TYPE=LOG LOGOPTS=( BASE=10 viewmax = _YMAX )) 
                    XAXISOPTS =( LABEL=_XLABEL tickvalueattrs=(size=9) 
                      LABELATTRS=GRAPHVALUETEXT(SIZE=10pt) 
                      Linearopts=( viewmin=0 viewmax=_XMAX tickvaluelist=TICKS 
                      tickvaluefitpolicy=NONE)) ;
      scatterplot x=PCTPT y=PCMEAN / group=TRTAN MARKERATTRS=(color=black ) name="s2" ;
      seriesplot x=PCTPT y=PCMEAN /group=TRTAN LINEATTRS=(color=black) name="s1";
   *endif;
   endlayout;
   endcell;
   sidebar / align=bottom;
   *discretelegend; MERGEDLEGEND "s1" "s2"/ /*MERGE=true*/  border=false valueattrs=(size=_LEGENDSIZE);
   endsidebar;
   endlayout;
   endgraph;
   end;
   run;

ods graphics on / width=22.87cm noborder height=12cm ;
ods tagsets.RTF nogtitle nogfootnote FILE = "target13.rtf" ;
ods listing close;

title J=L "SPONSOR/PROTOCOL/PRODUCT INFO" j=R "page x of y";
title3 "Figure 14.2-x.x Arithmetic/Geometric Mean concentration-time plot per [analyte] (overlaying) and analyte separately";
title4 "Analysis set: PK analysis set";
footnote j=l "PATH DATA/PROGRAM/OUTPUT";

   proc sgrender data=Meandata template="temp_pksum";
   dynamic _sd="&SD" 
           _XLABEL="Time (h)" 
           SCALE="LINEAR" 
           _YLABEL="Arithmetic mean (SD) Anal2 Conc (ng/mL )" 
           _XMAX=100  
           _LEGENDSIZE="11pt" 
           TICKS= "0 4 8 12 24 36 48 72 96" ;
   **by byval1 byval2 byval3 byval4 byval5 page;
   run;quit;

   title;
   footnote;

ods graphics off;   
ods tagsets.RTF  close;  
ods listing;
%mend;

%TARGET13(pctestcd=ANAL1, MEANTYPE=A, SD=BOTH);
*%TARGET13(pctestcd=ANAL1, MEANTYPE=G);
/*



*/

%put syscc=&syscc.;

