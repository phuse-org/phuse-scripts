%**********************************************************************;
* Project           : Standard Macro
*
* Program name      : Supp2Par_v1.sas
*
* Author            : Dirk Van Krunckelsven (DVK, M164821), Merck Serono                         
* E-mail            : dirk.van.krunckelsven@merckgroup.com OR dirk.vk@gmail.com 
*
* Date created      : 2012-11-08
*
* Purpose           : Macro that merges the Supplemental Qualifiers (SUPPQUAL or SUPP--)  
*                      onto the parent domain for well-formed SDTM datasets.                          
*                     Refer to Supp2Par_v1.pdf for a complete description.    
*
* Revision History  :
*
* Date        Author    Ref  Revision 
* 2013-03-12  DVK       1    Modified header: removed all pre-release comments, 
*                             removed full detailed description, added reference 
*                             to PDF
***********************************************************************;
%macro SUPP2PAR_v1(
  inlib=work,                 /* Name of Input library for Parent and Supplemental Datasets */
  parent=,                    /* Name of Parent Input Dataset */
  supp=,                      /* Name of Supplemental Input Dataset */
  outlib=work,                /* Name of Destination/Output library for Merged dataset */
  outname=%str(&parent.FULL), /* Name of Merged Output Dataset */
  clean=Y,                    /* Whether or not (Y/N) to clean work environment at end */
  dev=N,                      /* Whether or not (Y/N) to show all messages in the log */
  Info=1,                     /* Level of information to provide in the log: 
                                 1 (all), 2 (start and summary), 3 (only summary) */
  RC=RC_S2P                   /* Name of Return Code Macro variable */
);

%* Globalizing the RC macrovariable and setting a local RC_WAR macrovariable
    Latter increments the Warnings (negative RCs) that do not end the processing
    Former picks up the terminating RCs, only when no more termination is possible 
    (at the end almost) RC_WAR is put into the RC and reporting is done of the global RC;
%global &RC;
%let &RC = 99999;
%local RC_WAR ;
%let RC_WAR = 0;

%* Info not in (1 2 3) -> reverts to default;
%if %upcase(%trim(&Info)) ne 1 AND %upcase(%trim(&Info)) ne 2 AND %upcase(%trim(&Info)) ne 3 %then %let Info = 1;

%* First info in log for Info = 1 OR 2 - obviously nonotes at this stage disables this regardless of Info;
%if %upcase(%trim(&Info)) = 1 OR %upcase(%trim(&Info)) = 2 %then %do;
data _null_;
    put "NO" "TE- " " ";
    put "NO" "TE- " "*****************************";
    put "NO" "TE- Started Processing for ";
    put "NO" "TE-  PARENT = %upcase(&inlib..&PARENT.)";
	  put "NO" "TE-  SUPP   = %upcase(&inlib..&SUPP.)";
    put "NO" "TE- " "*****************************";
run;
%end;

%************************************************************************;
%* Turning off LOG Clutter unless specifically marked as development run ;
%* Assuring we know the original settings and can recall them later      ;
%if %upcase(%quote(&DEV)) ne Y %then %do;
%let save_opts=%sysfunc(getoption(SYMBOLGEN))
   %sysfunc(getoption(MACROGEN)) %sysfunc(getoption(MPRINT))
   %sysfunc(getoption(MLOGIC)) %sysfunc(getoption(NOTES))
   %sysfunc(getoption(SOURCE)) %sysfunc(getoption(SOURCE2)) ;
options noSYMBOLGEN noMACROGEN noMPRINT noMLOGIC noNOTES noSOURCE noSOURCE2 ;
%end;
%************************************************************************;

%****************************;
%* Macrovariables used       ;
%let WA = WARN;
%let RN = ING;
%let ER = ERR;
%let R = OR;
*% Early termination macrovar flag, troublelist macrovariable (that needs to exist for where clause below);
%local S2P_Early S2P_ParCopy S2P_TROUBLELIST;
%let S2P_Early = 0;
%let S2P_ParCopy = 0;
%let S2P_TROUBLELIST = '';
%****************************;

%* To make sure that in all cases there is a dataset for the cleaning at the end;
%* This avoids log clutter;
data S2P_; run;

%***********************************************************************;
%* Testing Input parameters                                          ***;
%***********************************************************************;
%* Empty INLIB is caught seperately for functioning of libref;
%* INLIB: Valid libarary defined, if not terminate;
%if &INLIB ne %then %do;
%if %sysfunc(libref(&INLIB.)) ne 0 %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &ER.&R.-;
    %put &ER.&R.: *******************************************************;
    %put &ER.&R.: * LIBRARY %upcase(&INLIB) AS SPECIFIED IN PARAMETER INLIB ;
    %put &ER.&R.: * DOES NOT EXIST, TERMINATED MACRO ;
    %put &ER.&R.: *******************************************************;
  %end;
    %let S2P_Early=1;
    %let &RC=1 ;
    %goto S2P_TERMIN;
  %end;
%end;
%else %if &INLIB eq %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &ER.&R.-;
    %put &ER.&R.: *******************************************************;
    %put &ER.&R.: * LIBRARY %upcase(&INLIB) AS SPECIFIED IN PARAMETER INLIB ;
    %put &ER.&R.: * DOES NOT EXIST, TERMINATED MACRO ;
    %put &ER.&R.: *******************************************************;
  %end;
    %let S2P_Early=1;
    %let &RC=1 ;
    %goto S2P_TERMIN;
%end;

%* OUTLIB: Valid libarary defined, if not use WORK and issue log note;
%if &OUTLIB ne %then %do;
%if %sysfunc(libref(&OUTLIB.)) ne 0 %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &WA.&RN.-;
    %put &WA.&RN.- *******************************************************;
    %put &WA.&RN.- * LIBRARY %upcase(&OUTLIB) AS SPECIFIED IN PARAMETER OUTLIB ;
    %put &WA.&RN.- * DOES NOT EXIST, DEFAULTING TO WORK ;
    %put &WA.&RN.- *******************************************************;
  %end;
    %let RC_WAR=%sysfunc(sum(&RC_WAR,-1)) ;
    %let OUTLIB = WORK;
%end;
%end;
%else %if &OUTLIB eq %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &WA.&RN.-;
    %put &WA.&RN.- *******************************************************;
    %put &WA.&RN.- * LIBRARY %upcase(&OUTLIB) AS SPECIFIED IN PARAMETER OUTLIB ;
    %put &WA.&RN.- * DOES NOT EXIST, DEFAULTING TO WORK ;
    %put &WA.&RN.- *******************************************************;
  %end;
    %let RC_WAR=%sysfunc(sum(&RC_WAR,-1)) ;
    %let OUTLIB = WORK;
%end;
%* PARENT: Dataset exists, if not terminate;
%if %sysfunc(exist(%upcase(&INLIB..&PARENT.))) ne 1 %then %do;
%if %upcase(%trim(&Info)) = 1 %then %do;
  %put &ER.&R.-;
  %put &ER.&R.: *******************************************************;
  %put &ER.&R.: * DATASET %upcase(&INLIB..&PARENT) AS SPECIFIED IN PARAMETER PARENT ;
  %put &ER.&R.: * DOES NOT EXIST, TERMINATED MACRO ;
  %put &ER.&R.: *******************************************************;
%end;
  %let &RC=2 ;
  %let S2P_Early=1;
  %goto S2P_TERMIN;
%end;
%* PARENT: Dataset should not be empty, if not terminate;
%local S2P_dsid_PAR S2P_NOBS_PAR S2P_rc_PAR;
%let S2P_dsid_PAR = %sysfunc(open(&inlib..&parent,i));
%if &S2P_dsid_PAR le 0 %then %put &WA.&RN.: %sysfunc(sysrc()) -- %sysfunc(SysMsg());
%let S2P_NObs_PAR = %sysfunc(attrn(&S2P_dsid_PAR,NOBS));
%let S2P_rc_PAR = %sysfunc(close(&S2P_dsid_PAR));
%if &S2P_NObs_PAR = 0 %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &ER.&R.-;
    %put &ER.&R.: *******************************************************;
    %put &ER.&R.: * DATASET %upcase(&INLIB..&PARENT) AS SPECIFIED IN PARAMETER PARENT ;
    %put &ER.&R.: * IS EMPTY, TERMINATED MACRO ;
    %put &ER.&R.: *******************************************************;
  %end;
  %let &RC=3 ;
  %let S2P_Early=1;
  %goto S2P_TERMIN;
%end;
%* SUPP: Dataset exists, if not continue to simple copy;
%if %sysfunc(exist(%upcase(&INLIB..&SUPP.))) ne 1 %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &WA.&RN.-;
    %put &WA.&RN.- *******************************************************;
    %put &WA.&RN.- * DATASET %upcase(&INLIB..&SUPP) AS SPECIFIED IN PARAMETER SUPP ;
    %put &WA.&RN.- *  DOES NOT EXIST, THE MACRO CONTINUES BUT THE CREATED  ;
    %put &WA.&RN.- *  OUTPUT DATASET IS A SIMPLE COPY OF THE %upcase(&PARENT) DATASET,    ; 
    %put &WA.&RN.- *  THERE IS NO REMERGE OF SUPPLEMENTAL INFORMATION ;
    %put &WA.&RN.- *******************************************************;
  %end;
  %let RC_WAR=%sysfunc(sum(&RC_WAR,-2)) ;
  %let S2P_ParCopy=1;
  %goto S2P_COPY;
%end;
%* SUPP: Dataset should not be empty, if not continue to simple copy;
%local S2P_dsid_SUP S2P_NOBS_SUP S2P_rc_SUP;
%let S2P_dsid_SUP = %sysfunc(open(&inlib..&supp,i));
%if &S2P_dsid_SUP le 0 %then %put &WA.&RN.: %sysfunc(sysrc()) -- %sysfunc(SysMsg());
%let S2P_NObs_SUP = %sysfunc(attrn(&S2P_dsid_SUP,NOBS));
%let S2P_rc_SUP = %sysfunc(close(&S2P_dsid_SUP));
%if &S2P_NObs_SUP = 0 %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &WA.&RN.-;
    %put &WA.&RN.- *******************************************************;
    %put &WA.&RN.- * DATASET %upcase(&INLIB..&SUPP) AS SPECIFIED IN PARAMETER SUPP ;
    %put &WA.&RN.- * IS EMPTY, THE MACRO CONTINUES BUT THE CREATED  ;
    %put &WA.&RN.- *  OUTPUT DATASET IS A SIMPLE COPY OF THE %upcase(&PARENT) DATASET,    ; 
    %put &WA.&RN.- *  THERE IS NO REMERGE OF SUPPLEMENTAL INFORMATION ;
    %put &WA.&RN.- *******************************************************;
  %end;
  %let RC_WAR=%sysfunc(sum(&RC_WAR,-4)) ;
  %let S2P_ParCopy=1;
  %goto S2P_COPY;
%end;
%* OUTNAME: Valid dataset name, if not use default: &PARENT.FULL;
data _null_;
if length(trim(left("&OUTNAME"))) gt 32 OR
     prxmatch('/\W/',trim(left("&OUTNAME"))) OR
	  ( not(prxmatch('/^[[:alpha:]]/',trim(left("&OUTNAME")))) 
        AND not(prxmatch('/^_/',trim(left("&OUTNAME"))))       ) then do;
	  call symput("RC_WAR",put(sum(&RC_WAR,-8),best.));
%if %upcase(%trim(&Info)) = 1 %then %do;
      put "&WA.&RN.-";
      put "&WA.&RN.- *******************************************************";
      put "&WA.&RN.- DATASET NAME %upcase(&OUTNAME) AS SPECIFIED IN PARAMETER OUTNAME";
      put "&WA.&RN.- HAS ILLEGAL NAMING, DEFAULTING TO [PARENT]FULL: %upcase(&PARENT.FULL)";
	  if length(trim(left("&OUTNAME"))) gt 32 then do;
      put "&WA.&RN.- - NAME IS MORE THAN 32 CHARACTERS LONG";
	  end;
	  if prxmatch('/\W/',trim(left("&OUTNAME"))) OR
	     ( not(prxmatch('/^[[:alpha:]]/',trim(left("&OUTNAME")))) 
           AND not(prxmatch('/^_/',trim(left("&OUTNAME"))))       ) then do;
      put "&WA.&RN.- - NAME STARTS WITH A NO. AND/OR CONTAINS SPECIAL CHARS/BLANKS";
	  end;
      put "&WA.&RN.- *******************************************************";
%end;
  call symput("OUTNAME",%upcase("&parent.FULL"));
end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

%****************************************************************************;
%* Seeing whether required variables exist on the datsets &PARENT and &SUPP  ;

%* &PARENT REQUIRES at least STUDYID DOMAIN USUBJID ;

%local S2P_dsidA S2P_NvarA S2P_colexistcntA S2P_rcA;
%local S2P_foundUSUBJID S2P_foundDOMAIN S2P_foundSTUDYID;
%let S2P_dsidA = %sysfunc(open(&inlib..&parent,i));
%if &S2P_dsidA le 0 %then %put &WA.&RN.: %sysfunc(sysrc()) -- %sysfunc(SysMsg());

%let S2P_NVarA = %sysfunc(attrn(&S2P_dsidA,NVARS));

%let N1 = USUBJID;
%let N2 = DOMAIN;
%let N3 = STUDYID;

%do iA = 1 %to 3;

%let S2P_found&&N&iA = 0;
    %do S2P_colexistcntA = 1 %to &S2P_NvarA ;
		  %local vn&S2P_colexistcntA;
      %let vn&S2P_colexistcntA = %sysfunc(varname(&S2P_dsidA,&S2P_colexistcntA));
      %if %upcase("&&vn&S2P_colexistcntA") = %upcase("&&N&iA") %then %do;
	      %let S2P_found&&N&iA = 1;
		   %goto ColdStopA;
      %end;
	  %ColdStopA:
	%end;

%end;

%let S2P_rcA = %sysfunc(close(&S2P_dsidA));

%if not ( &S2P_foundUSUBJID AND &S2P_foundDOMAIN AND &S2P_foundSTUDYID ) %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &ER.&R.-;
    %put &ER.&R.: *******************************************************;
    %put &ER.&R.: * DATASET %upcase(&INLIB..&PARENT) LACKS REQUIRED VARIABLE(S):  ;
    %do iA = 1 %to 3;
      %if "&&&&s2P_found&&N&iA" ne "1" %then %do;
    %put &ER.&R.: *  - &&N&iA  ;
      %end;
    %end;
    %put &ER.&R.: * TERMINATED MACRO ;
    %put &ER.&R.: *******************************************************;
  %end;
  %let S2P_Early=1;
  %let &RC = 5;
  %goto S2P_TERMIN;
%end;

%* &SUPP REQUIRES at least STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QVAL and QLABEL;

%local S2P_dsidB S2P_NvarB S2P_colexistcntB S2P_rcB;
%local S2P_foundUSUBJID S2P_foundDOMAIN S2P_foundSTUDYID;
%let S2P_dsidB = %sysfunc(open(&inlib..&supp,i));
%if &S2P_dsidB le 0 %then %put &WA.&RN.: %sysfunc(sysrc()) -- %sysfunc(SysMsg());

%let S2P_NVarB = %sysfunc(attrn(&S2P_dsidB,NVARS));

%let N1 = USUBJID;
%let N2 = RDOMAIN;
%let N3 = STUDYID;
%let N4 = IDVAR;
%let N5 = IDVARVAL;
%let N6 = QNAM;
%let N7 = QVAL;
%let N8 = QLABEL;

%do iB = 1 %to 8;

%let S2P_found&&N&iB = 0;
    %do S2P_colexistcntB = 1 %to &S2P_NvarB ;
		  %local vn&S2P_colexistcntB;
      %let vn&S2P_colexistcntB = %sysfunc(varname(&S2P_dsidA,&S2P_colexistcntB));
      %if %upcase("&&vn&S2P_colexistcntB") = %upcase("&&N&iB") %then %do;
	      %let S2P_found&&N&iB = 1;
		   %goto ColdStopB;
      %end;
	  %ColdStopB:
	%end;

%end;

%let S2P_rcB = %sysfunc(close(&S2P_dsidB));

%if not ( &S2P_foundUSUBJID AND &S2P_foundRDOMAIN AND &S2P_foundSTUDYID AND &S2P_foundIDVAR
           AND &S2P_foundIDVARVAL AND &S2P_foundQNAM AND &S2P_foundQVAL AND &S2P_foundQLABEL) %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &ER.&R.-;
    %put &ER.&R.: *******************************************************;
    %put &ER.&R.: * DATASET %upcase(&INLIB..&SUPP) LACKS REQUIRED VARIABLE(S):  ;
    %do iB = 1 %to 8;
      %if "&&&&s2P_found&&N&iB" ne "1" %then %do;
    %put &ER.&R.: *  - &&N&iB  ;
      %end;
    %end;
    %put &ER.&R.: * TERMINATED MACRO ;
    %put &ER.&R.: *******************************************************;
  %end;
  %let S2P_Early=1;
  %let &RC = 6;
  %goto S2P_TERMIN;
%end;

%* End: Seeing whether required variables exist on the datsets &PARENT and &SUPP ;
 ********************************************************************************;

%* SUPP must have RDOMAIN = &PARENT, if that selection is empty then output is simple copy of input parent;
data S2P_RDOMCHECK;
  set &inlib..&supp (where = (RDOMAIN = "%upcase(&parent)"));
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

%local S2P_dsid_FSUP S2P_NOBS_FSUP S2P_rc_FSUP;
%let S2P_dsid_FSUP = %sysfunc(open(S2P_RDOMCHECK,i));
%if &S2P_dsid_FSUP le 0 %then %put &WA.&RN.: %sysfunc(sysrc()) -- %sysfunc(SysMsg());
%let S2P_NObs_FSUP = %sysfunc(attrn(&S2P_dsid_FSUP,NLOBS));
%let S2P_rc_FSUP = %sysfunc(close(&S2P_dsid_FSUP));
%if &S2P_NObs_FSUP = 0 %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &WA.&RN.-;
    %put &WA.&RN.- *******************************************************;
    %put &WA.&RN.- * DATASET %upcase(&INLIB..&SUPP) AS SPECIFIED IN PARAMETER SUPP ;
    %put &WA.&RN.- * IS EMPTY after selecting for RDOMAIN = %upcase(&parent);
    %put &WA.&RN.- * THE MACRO CONTINUES BUT THE CREATED OUTPUT DATASET ; 
    %put &WA.&RN.- * IS A SIMPLE COPY OF THE %upcase(&PARENT) DATASET;
    %put &WA.&RN.- *******************************************************;
  %end;
  %let RC_WAR=%sysfunc(sum(&RC_WAR,-32)) ;
  %let S2P_ParCopy=1;
  %goto S2P_COPY;
%end;

%* END: Testing Input parameters and data                            ***;
%* More can be performed lateron                                     ***;
%***********************************************************************;

%* Contents dataset for the parent domain;
proc contents data=&inlib..&parent out=S2P_contents_&parent noprint;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;

%**************************************;
%* Checks on the supplemental dataset *;

%* Checking whether Supplemental dataset has records where either USUBJID and/or RDOMAIN and/or QNAM is empty;
%* If so, ignore the record and issue notification(s) in the log with an output dataset to contain the ignored records;
%* The processing does continue however;
data &supp._IGNOR S2P_&supp._Accept;
  set &inlib..&supp. (where = (strip(RDOMAIN) = '' or strip(USUBJID) = '' or strip(QNAM) = '') in = a) 
      &inlib..&supp. (where = (not(strip(RDOMAIN) = '' or strip(USUBJID) = '' or strip(QNAM) = '')) in = b) ;
  if a then output &supp._IGNOR;
  else if b then output S2P_&supp._Accept;
run;
%if &syserr > 4 %then %do ;
   %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
   %let &rc=500;
   %goto S2P_TERMIN ;
%end ;
%local S2P_dsid_IGNOR S2P_NOBS_IGNOR S2P_rc_IGNOR;
%let S2P_dsid_IGNOR = %sysfunc(open(WORK.&SUPP._IGNOR,i));
%if &S2P_dsid_IGNOR le 0 %then %put &WA.&RN.: %sysfunc(sysrc()) -- %sysfunc(SysMsg());
%let S2P_NObs_IGNOR = %sysfunc(attrn(&S2P_dsid_IGNOR,NOBS));
%let S2P_rc_IGNOR = %sysfunc(close(&S2P_dsid_IGNOR));
%if &S2P_NObs_IGNOR ne 0 %then %do;
  %let RC_WAR=%sysfunc(sum(&RC_WAR,-512)) ;
    %put &WA.&RN.- *******************************************************;
    %put &WA.&RN.- * DATASET %upcase(&INLIB..&SUPP) AS SPECIFIED IN PARAMETER SUPP ;
    %put &WA.&RN.- * HAS &S2P_NObs_IGNOR. RECORD(S) WITH EMPTY VALUES FOR ;
    %put &WA.&RN.- * STUDYID, USUBJID, RDOMAIN OR QNAM ;
    %put &WA.&RN.- * THE MACRO CONTINUES BUT THESE RECORD(S) ARE IGNORED ;
    %put &WA.&RN.- * REFER TO THE DATASET %upcase(WORK.&SUPP)_IGNOR TO IDENTIFY THESE RECORDS ;
    %put &WA.&RN.- *******************************************************;
%end;
%* Checking whether Supplemental dataset is unique on USUBJID RDOMAIN IDVAR IDVARVAL QNAM;
%* If not, the macro warns and terminates;
proc sort data = S2P_&supp._Accept 
  dupout = WORK.&SUPP._DUPP nodupkey out=_null_;
  by USUBJID RDOMAIN IDVAR IDVARVAL QNAM;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;
%local S2P_dsid_SUPPDUP S2P_NOBS_SUPPDUP S2P_rc_SUPPDUP;
%let S2P_dsid_SUPPDUP = %sysfunc(open(WORK.&SUPP._DUPP,i));
%if &S2P_dsid_SUPPDUP le 0 %then %put &WA.&RN.: %sysfunc(sysrc()) -- %sysfunc(SysMsg());
%let S2P_NObs_SUPPDUP = %sysfunc(attrn(&S2P_dsid_SUPPDUP,NOBS));
%let S2P_rc_SUPPDUP = %sysfunc(close(&S2P_dsid_SUPPDUP));
%if &S2P_NObs_SUPPDUP ne 0 %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &ER.&R.-;
    %put &ER.&R.: *******************************************************;
    %put &ER.&R.: * DATASET %upcase(&INLIB..&SUPP) AS SPECIFIED IN PARAMETER SUPP ;
    %put &ER.&R.: *   HAS &S2P_NObs_SUPPDUP. DUPLICATE RECORD(S) ;
    %put &ER.&R.: *   ON THE KEYS USUBJID RDOMAIN IDVAR IDVARVAL QNAM ;
    %put &ER.&R.: * IT IS IMPOSSIBLE TO DETERMINE WHICH RECORD TO MERGE ;
	  %put &ER.&R.: * THE MACRO WILL TERMINATE ;
    %put &ER.&R.: *******************************************************;
    %put &ER.&R.: * Duplicate Records listed here (limited to 15 duplicates) ;
    %put &ER.&R.: *  Simple list of key values mentioned above ;
    %put &ER.&R.: *  All duplicate records are stored in WORK.%upcase(&supp)._DUPP;
	data _null_;
	  set WORK.&SUPP._DUPP (obs=15) end=eof;
      put "&ER.&R.: * " USUBJID RDOMAIN IDVAR IDVARVAL QNAM;
	  if eof then  put "&ER.&R.: *******************************************************";
	run;
  %end;
  %let &RC=10;
  %let S2P_Early=1;
  %goto S2P_TERMIN;
%end;

%* Checking whether the same QNAM occurs with different labels ;
%* The QNAM that occurs more than once is writen out to log ;
%* List of troublesome QNAMs is written into a macrovariable to retrieve lateron if necessary ;
%local S2P_NONUNIQ_QNAM;
proc freq data = S2P_&supp._Accept noprint;
table QNAM*QLABEL/list out = S2P_SUPPFREQ_&parent (drop = count percent);
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;
data S2P_SUPPFREQ_&parent;
  set S2P_SUPPFREQ_&parent;
  QNAM = upcase(QNAM);
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;
proc sort data = S2P_SUPPFREQ_&parent;
  by QNAM;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;
data _null_;
  set S2P_SUPPFREQ_&parent;
  by QNAM;
  if not(first.QNAM) and last.QNAM then do;
    call symput("S2P_TROUBLELIST","&S2P_TROUBLELIST. " !! "'" !! trim(left(QNAM))!! "'");
	call symput("S2P_NONUNIQ_QNAM","1");
  end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;
%if %upcase(%trim(&Info)) = 1 %then %do;
data _null_;
  set S2P_SUPPFREQ_&parent 
  (where = (QNAM in (&S2P_TROUBLELIST)) )
  end = lastrec;
  by QNAM;
  if _N_ = 1 then do;
    put "&ER.&R.- **************************************************************************" ;
    put "&ER.&R.- The same QNAM occurs with different labels (QLABEL) in the %upcase(&supp) dataset. " ;
  end;
  if first.QNAM then do;
    put "&ER.&R.-  * QNAM = " QNAM ;
  end;
    put "&ER.&R.-   - QLABEL = " QLABEL;
  if lastrec then do;
    put "&ER.&R.- -------------------------------------------------------------------------- " ;
    put "&ER.&R.- IMPOSSIBLE TO FURTHER PROCESS " ;
    put "&ER.&R.- **************************************************************************" ;
  end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;
%end;
%if &S2P_NONUNIQ_QNAM = 1 %then %do;
  %let S2P_Early=1;
  %let &RC = 7;
  %goto S2P_TERMIN;
%end;

%*END: Checks on the supplemental dataset *;
%******************************************;

%**********************************************************************;
%*Creating a version of supplemental dataset in the WORK library      *;
%*And ensuring that IDVAR is not empty, but substituted by USUBJID    *;
%local S2P_IDVARE S2P_IDVARNE USUBLEN;

* Determining Length of USUBJID (assuming it is always a text variable);
* So that it can be assigned as such on IDVARVAL (in order to avoid truncation, 
   because empty IDVARVAL which will be replaced by USUBJID is likely to not 
   have the apropriate length);
* 2011-11-16: Addition: Possibly IDVAR has length smaller than length('USUBJID') 
                in that case adapt, if not leave as is;
proc contents noprint data = S2P_&supp._Accept out = S2P_ATT_USUB (where = (NAME = 'USUBJID' OR NAME = 'IDVAR'));
quit;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;

data _null_;
  set S2P_ATT_USUB (keep = LENGTH NAME);
  if NAME = 'USUBJID' then call symput("USUBLEN","$"!!trim(left(put(LENGTH,best.)))!!".");
  else if NAME = 'IDVAR' then do;
  if LENGTH ge length('USUBJID') then call symput("IDVARLEN","$"!!trim(left(put(LENGTH,best.)))!!".");
	else call symput("IDVARLEN","$"!!trim(left(put(length('USUBJID'),best.)))!!".");
  end;
run;
* End 2011-11-16 addition;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

data S2P_&SUPP.;
  length IDVARVAL &USUBLEN IDVAR &IDVARLEN;
  set S2P_&supp._Accept;
  if IDVAR = '' and IDVARVAL = '' then do;
    IDVAR = 'USUBJID';
	IDVARVAL = USUBJID;
	call symput("S2P_IDVARE","1");
  end;
  else if IDVAR = '' AND IDVARVAL ne '' then do;
	call symput("S2P_IDVARNE","1");
  end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

%***********************************;
*% Check for QNAM allready on parent;
%* Determining which ones already occur on Parent first;
proc sort data=s2P_contents_&parent out= S2P_QNAM_PAR(keep=NAME);
  by NAME;
quit;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;
proc sort nodupkey data = S2P_&supp._Accept out = S2P_QNAM_SUP (keep = QNAM);
by QNAM;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;

%* Adding check on Legal Variable Name in QNAM;
%let CHK = 0;
data _null_;
  set S2P_QNAM_SUP (where = (strip(QNAM) ne ''));
  if not(nvalid(strip(QNAM))) OR length(strip(QNAM)) gt 8 then do;
      NAM = strip(QNAM);
      put "&WA.&RN.- *******************************************************";
      put "&WA.&RN.- QNAM VARIABLE (" NAM ") IN SUPPLEMENTAL DATA (%upcase(&SUPP.))";
      if not(nvalid(strip(QNAM))) then put "&WA.&RN.- HAS ILEGAL NAMING, PROC TRANSPOSE WILL CORRECT THIS";
	  if length(strip(QNAM)) gt 8 then put "&WA.&RN.- HAS LENGTH GREATER THAN 8, SAS ALLOWS BUT XPT V5 DOES NOT";
      put "&WA.&RN.- CDISC COMPLIANCE REQUIRES A CORRECTION";
      put "&WA.&RN.- *******************************************************";
	  call symput ( "CHK", "1" );
  end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

%if %eval(&CHK ) = 1 %then %do;
   %let RC_WAR=%sysfunc(sum(&RC_WAR,-256)) ;
%end;

data S2P_QNAM_CHECK;
  merge S2P_QNAM_PAR (in=par) 
        S2P_QNAM_SUP (in = sup rename = (QNAM = NAME));
  by NAME;
  if par and sup;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

%* Renaming the QNAMs already taken to ..._2 and informing in the log;
%* If there is a case of QNAMs allready existing on the parent;

%local S2P_dsid_QNAMC S2P_NOBS_QNAMC S2P_rc_QNAMC;
%let S2P_dsid_QNAMC = %sysfunc(open(S2P_QNAM_CHECK,i));
%if &S2P_dsid_QNAMC le 0 %then %put &WA.&RN.: %sysfunc(sysrc()) -- %sysfunc(SysMsg());
%let S2P_NObs_QNAMC = %sysfunc(attrn(&S2P_dsid_QNAMC,NOBS));
%let S2P_rc_QNAMC = %sysfunc(close(&S2P_dsid_QNAMC));
%if &S2P_NObs_QNAMC ne 0 %then %do;

data _null_;
  set S2P_QNAM_CHECK end = eof;
  if _N_=1 then call execute('data S2P_&SUPP.;length QNAM $10.; set S2P_&SUPP.; ');
  %* By definition, max. length of QNAM = 8, therefore adapted QNAM has 10;
  call execute('if QNAM = "' !! strip(NAME) !! '" then QNAM = "' !! strip(NAME) !! '_2" ;');
  call symput('QNAM'!!strip(put(_N_,best.)),NAME);
  if eof then do; 
    call symput('QNAMNUM',put(_N_,best.));
    call execute('run;');
  end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &WA.&RN.-;
    %put &WA.&RN.- *******************************************************;
    %put &WA.&RN.- * PARENT DATASET %upcase(&PARENT) HAS VARIABLE(S) NAMED IDENTICAL ;
    %put &WA.&RN.- * TO A VALUE OF QNAM IN THE SUPPLEMENTAL DATASET %upcase(&SUPP.) ;
    %put &WA.&RN.- * THE REMERGED VARIABLES WILL RECEIVE THE SUFFIX '_2':  ;
      %do i = 1 %to &QNAMNUM;
    %put &WA.&RN.- *    %trim(&&QNAM&i) -> %trim(&&QNAM&i)_2;
      %end;
    %put &WA.&RN.- *******************************************************;
  %end;
  %let RC_WAR=%sysfunc(sum(&RC_WAR,-64)) ;
%end;

*% End: Check for QNAM allready on parent;
%****************************************;

%if "&S2P_IDVARE" = "1" %then %do;
	%*put &WA&RN- Empty IDVAR and IDVARVAL have been substituted with USUBJID;
  %let RC_WAR=%sysfunc(sum(&RC_WAR,-16)) ;
%end;

%if "&S2P_IDVARNE" = "1" %then %do;
  %*put &WA&RN: IDVAR empty while IDVARVAL not empty - Not processing further;
  %let S2P_Early=1;
  %let &RC = 8;
  %goto S2P_TERMIN;
%end;

%*END: Creating a version of supplemental dataset in the WORK library *;
%**********************************************************************;

%***************************************************************************;
%* CORE PROCESSING FOR THE REQUIREMENT: MERGE SUPP ONTO PARENT BEGINS HERE *;
%***************************************************************************;

%* To determine the values for IDVAR in the Supplemental, 
   which will be variable(s) needed for the merge;
%* Also the supplementals will be treated in subsets according to 
   the IDVAR value unless only one IDVAR value encountered;
proc freq data = S2P_&SUPP. ( where = (RDOMAIN = "%upcase(&parent)") ) noprint;
  table idvar /out=S2P_ids_&parent;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;

%* Putting these into macrovariable IDn, and the max. number into IDMAX;
data _null_;
  set S2P_ids_&parent end=eof;
  call symput('ID'!!trim(left(put(_N_,best.))),trim(left(IDVAR)));
  if eof then do;
    call symput('IDMAX',put(_N_,best.));
  end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

%* Determining for each IDVAR (in macrovar. IDn) what 
   the TYPE and FORMAT needed (i.e. as on the parent domain) is;
%* Checking whether the IDVAR values are indeed variables on the parent domain;
%local NOID;
%let NOID= 0;
data _null_;
retain
  %do i = 1 %to &IDMAX;
  CATCH_&&ID&i
  %end;
  ;
  set S2P_contents_&parent end = eof;
  %do i = 1 %to &IDMAX;
  if trim(left(NAME)) = "&&ID&i" then do;
    CATCH_&&ID&i = 1;
    if type = 1 then do;
	  call symput("IDTYP&i","N");
	end;
	else if type = 2 then do;
	  call symput("IDTYP&i","C");
	end;
  end;
  %end;
  if eof then do;
  %do i = 1 %to &IDMAX;
    if CATCH_&&ID&i ne 1 then do;
      call symput("IDDROP&i","&&ID&i");
	    call symput("NOID",trim(left(input(1,best.))));  
	  end;
    else call symput("IDDROP&i","");
  %end;
  end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

%* If there are IDS not present on the PARENT, then we end it here;
%if &NOID %then %do;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &ER.&R.-;
    %put &ER.&R.- *******************************************************;
    %put &ER.&R.- * NOT RE-MERGING: SOME IDVARS DEFINED IN THE ;
    %put &ER.&R.- *  SUPPLEMENTAL (%upcase(&SUPP.)) DATASET ;
    %put &ER.&R.- *  ARE NOT PRESENT ON THE PARENT (%upcase(&PARENT));
      %do i = 1 %to &IDMAX;
        %if "%trim(&&IDDROP&i)" ne "" %then %put &ER.&R.- *    %trim(&&IDDROP&i);
    %end; 
    %put &ER.&R.- * THE MACRO TERMINATES ;
    %put &ER.&R.- *******************************************************;
  %end;
  %let &RC=9 ;
  %let S2P_Early=1;
  %goto S2P_TERMIN;
%end;

%do i = 1 %to &IDMAX;

%local IDCLN&i;
%if "&&ID&i" ne "USUBJID"  %then %let IDCLN&i = &&ID&i;
%else %let IDCLN&i = ;

%* Adapting the supplemental so that the IDVAR is actually turned into a variable 
   identical as on the parent domain (same type, format as determined in previous step);
%* IDVAR is not formatted, in SAS the merge ensures that the 1st dataset mentioned 
     (here: Parent) will dictate the format of the resulting dataset;
%* Additionally to convert the character IDVARVAL in case IDVAR is numeric, 
     a best format is applied;
data S2P_&parent._SUPP&i;
  set S2P_&SUPP. ( where = (IDVAR = "&&ID&i" and RDOMAIN = "%upcase(&parent)" ) );
  %if "&&IDTYP&i" = "N" %then %do;
  &&ID&i = input(trim(left(IDVARVAL)),best.);
  %end;
  %else %if "&&IDTYP&i" = "C" %then %do;
  &&ID&i = IDVARVAL;
  %end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

proc sort 
  data = S2P_&parent._SUPP&i ( where = (IDVAR = "&&ID&i") )
  out = S2P_&parent._SORT_&supp._&i  (drop = IDVARVAL IDVAR) ;
  by STUDYID RDOMAIN USUBJID &&IDCLN&i;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;

%* Transposing the supplemental so that the QNAMs become variables 
    with QVAL as values and QLABELs are applied;
proc transpose data = S2P_&parent._SORT_&supp._&i (rename = (RDOMAIN = DOMAIN)) 
               out  = S2P_&parent._SORT_&supp._&i.T (drop = _NAME_ _LABEL_);
  by STUDYID DOMAIN USUBJID &&IDCLN&i;
  var qval;
  id qnam;
  idlabel qlabel ;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;

%* Sorting the parent domain to ready it for the merge;
proc sort data = &inlib..&parent out = S2P_&parent._SORT_&parent._&i ;
  by STUDYID DOMAIN USUBJID &&IDCLN&i;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;

%* Merging parent and supplemental together;
%* Informing in the log if Supplemental record has no Parent;
data S2P_&parent._STEP_&i S2P_&supp.DROP_&i;
  merge S2P_&parent._SORT_&parent._&i (in = PARENT)
	    S2P_&parent._SORT_&supp._&i.T     (in = SUPP);
	by STUDYID DOMAIN USUBJID &&IDCLN&i;
  if PARENT then output S2P_&parent._STEP_&i;
	else if SUPP and not(PARENT) then output S2P_&supp.DROP_&i;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

%end;
*%Determining whether --SEQ variable exists or not on the PARENT dataset;

%local S2P_dsid S2P_Nvar S2P_found S2P_colexistcnt S2P_rc;
%let S2P_dsid = %sysfunc(open(&inlib..&parent,i));
%if &S2P_dsid le 0 %then %put &WA.&RN.: %sysfunc(sysrc()) -- %sysfunc(SysMsg());
%let S2P_NVar = %sysfunc(attrn(&S2P_dsid,NVARS));
%let S2P_found = 0;
    %do S2P_colexistcnt = 1 %to &S2P_Nvar ;
		  %local vn&S2P_colexistcnt;
      %let vn&S2P_colexistcnt = %sysfunc(varname(&S2P_dsid,&S2P_colexistcnt));
      %if %upcase("&&vn&S2P_colexistcnt") = %upcase("&parent.SEQ") %then %do;
	      %let S2P_found = 1;
		   %goto ColdStop;
      %end;
	  %ColdStop:
	%end;
%let S2P_rc = %sysfunc(close(&S2P_dsid));

%do i = 1 %to &IDMAX;

%* Readying merging the subsets of remerged datasets together: SORT;
%* Or if only one IDVAR value encountered this will resort;
proc sort data = S2P_&parent._STEP_&i ;
%if &S2P_found = 1 %then %do;
by STUDYID DOMAIN USUBJID &parent.SEQ;
%end;
%else %do;
by STUDYID DOMAIN USUBJID;
%end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Procedure Step Error Trapped - Terminating;
         %let &rc=600;
         %goto S2P_TERMIN ;
      %end ;

%end;

%* Merging subsets of remerged datasets together;
%* Or if only one IDVAR it is just set;
%* In the dataset S2P_FINAL_&parent. - which is later set to OUTLIB.OUTNAME;
data S2P_FINAL_&parent.;;
merge
%do i = 1 %to &IDMAX;
S2P_&parent._STEP_&i
%end;
;
%if &S2P_found = 1 %then %do;
by STUDYID DOMAIN USUBJID &parent.SEQ;
%end;
%else %do;
by STUDYID DOMAIN USUBJID;
%end;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

%* Setting DROP datasets together;
data %upcase(&supp._DROP);
set 
%do i = 1 %to &IDMAX;
  S2P_&supp.DROP_&i
%end;
;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Terminating;
         %let &rc=500;
         %goto S2P_TERMIN ;
      %end ;

%* ACTUAL OUTPUT DATASET WRITTEN HERE (IN CASE OF CORRECTLY PROCESSED - not for copy;
data %upcase(&outlib..&outname);
  set S2P_FINAL_&parent.;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Cannot write output dataset - Terminating;
         %let &rc=599;
         %goto S2P_TERMIN ;
      %end ;

%* Determining whether drops exist and reporting;
%local S2P_dsid_DROPS S2P_NOBS_DROPS S2P_rc_DROPS;
%let S2P_dsid_DROPS = %sysfunc(open(&supp._DROP,i));
%if &S2P_dsid_DROPS le 0 %then %put &WA.&RN.: %sysfunc(sysrc()) -- %sysfunc(SysMsg());
%let S2P_NObs_DROPS = %sysfunc(attrn(&S2P_dsid_DROPS,NOBS));
%let S2P_rc_DROPS = %sysfunc(close(&S2P_dsid_DROPS));
%if &S2P_NObs_DROPS ne 0 %then %do;
  %let RC_WAR=%sysfunc(sum(&RC_WAR,-128)) ;
  %if %upcase(%trim(&Info)) = 1 %then %do;
    %put &WA.&RN.- *******************************************************;
    %put &WA.&RN.- * DATASET %upcase(&INLIB..&SUPP) HAS RECORDS ;
    %put &WA.&RN.- *  THAT DO NOT EXIST ON THE PARENT DOMAIN ;
    %put &WA.&RN.- *  REFER TO THE DATASET IN WORK: %upcase(&SUPP._DROP) ;
    %put &WA.&RN.- *******************************************************;
  %end;
%end;
%else %do;
  %if "%upcase(&clean)" = "Y" %then %do;
  proc datasets lib=work nolist;
    delete &SUPP.DROP;
  quit;
  %end;
%end;

%********************************************************************************;
%* END: CORE PROCESSING FOR THE REQUIREMENT: MERGE SUPP ONTO PARENT BEGINS HERE *;
%********************************************************************************;
%* Copy Termination is here so that options are still reset and cleaning is still performed;
%S2P_COPY: 
%if &S2P_ParCopy %then %do;
data %upcase(&outlib..&outname);
  set &inlib..&parent;
run;
      %if &syserr > 4 %then %do ;
         %put ERROR: &sysmacroname: Data Step Error Trapped - Cannot write output dataset - Terminating;
         %let &rc=599;
         %goto S2P_TERMIN ;
      %end ;
%end;

*% At this stage the 99999 is fine, it would have meant unexpected termination;
%* Complete Termination is here so that options are still reset and cleaning is still performed;
%let &RC = %sysfunc(sum(0,&RC_WAR));
%S2P_TERMIN: 

%* Cleaning work library if requested;
%if %upcase("&clean") = "Y" %then %do;
proc datasets nolist lib=work memtype = data;
  delete S2P_:;
quit;
%end;

data S2P_ReturnCode;
  INFO = &&&RC;
run;

*% The below is a min minor correction because the NOTEs where not delivered;
%local note_opt;
%let note_opt=%sysfunc(getoption(NOTES));
options NOTES ;

data _null_;
  set S2P_ReturnCode;
  INFO2 = INFO * -1;
  if INFO = 0 then do;
    %if %upcase(%trim(&Info)) = 1 OR %upcase(%trim(&Info)) = 2 %then %do;
    put "NO" "TE- " " ";
    put "NO" "TE- " "*****************************";
    put "NO" "TE- Finished Processing Successfully without Remarks";
    put "NO" "TE-  CREATED: %upcase(&outlib..&outname)";
    put "NO" "TE- " "*****************************";
    put "NO" "TE- Nevertheless, do inspect the log...  ";
    %end;
 end;
  else if INFO lt 0 then do;
     put "WARN" "ING- " " ";
   put "WARN" "ING- " "*****************************";
    put "WARN" "ING- Finished Processing Successfully with Remarks: ";
    put "WARN" "ING-  CREATED: %upcase(&outlib..&outname)";
    if INFO2 = '1'b then put "WARN" 'ING- * Outlib does not exist, defaults to WORK';
    if INFO2 = '1.'b then put "WARN" 'ING- * Supplemental dataset does not exist, output will be copy of parent';
    if INFO2 = '1..'b then put "WARN" 'ING- * Supplemental dataset is empty, output will be copy of parent';
    if INFO2 = '1...'b then put "WARN" 'ING- * Improper Outname specified, defaults to [PARENT]FULL: %upcase(&parent)FULL';
    if INFO2 = '1....'b then put "WARN" 'ING- * IDVAR and IDVARVAL were empty substituted by USUBJID'; 
    if INFO2 = '1.....'b then put "WARN" 'ING- * Supplemental empty after selecting for RDOMAIN'; 
    if INFO2 = '1......'b then put "WARN" 'ING- * QNAM value in Supplemental is already a variable on Parent. Suffixed with _2'; 
    if INFO2 = '1.......'b then put "WARN" "ING- * Records on Supplemental do not exist on the Parent domain, refer to: %trim(%upcase(&supp.))_DROP"; 
    if INFO2 = '1........'b then put "WARN" "ING- * QNAM value in Supplemental is not a Valid SAS variable Name"; 
    if INFO2 = '1.........'b then put "WARN" "ING- * Records ignored: empty STUDYID USUBJID RDOMAIN or QNAM, refer to: %trim(%upcase(&supp.))_IGNOR";

    put "WARN" "ING- " "*****************************";
    put "WARN" "ING- " "For CDISC compliance most of these messages must be fixed";
    put "WARN" "ING- " "*****************************";
    put "WARN" "ING- Nevertheless, do inspect the log...  ";
end;
  else if INFO gt 0 then do;
    put "ERR" "OR- " " ";
    put "ERR" "OR- " "*****************************";
    put "ERR" "OR- " "* EARLY TERMINATION DUE TO: *";
          if INFO = 1 then put "ERR" 'OR- * Inlib does not exist';
     else if INFO = 2 then put "ERR" 'OR- * Parent dataset does not exist';
     else if INFO = 3 then put "ERR" 'OR- * Parent dataset is empty';
     else if INFO = 5 then put "ERR" 'OR- * Required variables not present on the Parent dataset';
     else if INFO = 6 then put "ERR" 'OR- * Required variables not present on the Supplemental dataset';
     else if INFO = 7 then put "ERR" 'OR- * Same QNAM has different labels';
     else if INFO = 8 then put "ERR" 'OR- * IDVAR empty while IDVARVAL not empty';
     else if INFO = 9 then put "ERR" 'OR- * IDVAR(s) not present on PARENT domain';
     else if INFO =10 then put "ERR" 'OR- * Supplemental dataset not unique on USUBJID RDOMAIN IDVAR IDVARVAL QNAM';
     else if INFO = 500 then put "ERR" 'OR- * Data Step Error Trapped in macro';
     else if INFO = 599 then put "ERR" 'OR- * Data Step Error Trapped in macro: Cannot write output dataset';
     else if INFO = 600 then put "ERR" 'OR- * Proc Step Error Trapped in macro';
     else if INFO = 99999 then put "ERR" 'OR- * Unexpected Error';
	 else put "ERR" 'OR- * Unknown Reason';
   put "ERR" "OR- " "*****************************";
end;
run;

*% Setting option NOTES back as found WITHIN (!) the macro ;
options &note_opt. ;

proc datasets nolist; 
  delete S2P_Returncode; 
quit;

%*end;

%* Resetting options to original state;
%if %upcase(&DEV) ne Y %then %do;
options &save_opts ;
%end;

%mend SUPP2PAR_v1;
