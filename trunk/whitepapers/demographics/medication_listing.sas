/****************************************************************************/
/*         PROGRAM NAME: Target36.sas                                       */
/*                                                                          */
/*          DESCRIPTION: Listing of medications                             */
/*                                                                          */
/*               AUTHOR: Adrienne M Bonwick                                 */
/*                                                                          */
/*                 DATE: 12th October 2014 (PhUSE scriptathon)              */
/*                                                                          */
/*  EXTERNAL FILES USED: ADCM.xpt                                           */
/*                                                                          */
/****************************************************************************/


filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adcm.xpt" ;
libname source xport ;

%let POPN=SAFFL;
%let POPNLABEL=Safety;

options orientation=landscape pagesize=41 linesize=119 nodate nonumber;

proc sort out=work.adcm/*(keep=STUDYID USUBJID TRTA TRTAN SAFFL CMCLAS CMDECOD CMDOSE CMDOSU CMINDC CMSTDTC CMENDTC ADURN AENRF &POPN)*/
   data=source.ADCM ;
by TRTA STUDYID USUBJID CMSTDTC CMENDTC CMDECOD;
WHERE &POPN='Y' ;
run ;

Data ADCM2;
  set ADCM;
  length StartStop $25 Doseunit $50;
  Period ='Study Period';
  if CMSTDTC='' then CMSTDTC='NK';
  if CMENDTC='' then CMENDTC='NK';
  StartStop=compbl(CMSTDTC||'/'||CMENDTC);
  If cmunit ne . then   DoseUnit = compbl(CMDOSE || '('|| cmunit || ')');
    else DoseUnit = compbl(CMDOSE);
  *** duration=AENDT-ASTDT;
  if AENRF='Ongoing' then Ongoing='Y'; 
    else Ongoing='N';
run;


ods listing close;
ods rtf file="Target36.rtf" style=styles.journal;
options nobyline;
Proc Report data=ADCM2 headline ;
by TRTA;
Columns TRTA USUBJID CMTRT cmdecod cmclas DoseUnit CMINDC StartStop ADURN Ongoing;
define TRTA / noprint;
define USUBJID / width=11 flow;
define CMTRT / width=10  flow;
define cmdecod / width=10 flow; 
define cmclas  / width=10 flow;
define DoseUnit / width=6 "Dose (unit)" flow; 
define CMINDC  / width=10 flow;
define StartStop / width=10 "Start Date / Stop Date" flow; 
define ADURN  / width=6 "Dur (Days)" flow;
define Ongoing / width=7 flow;
title JUSTIFY=L "&POPNLABEL Population";
title2 JUSTIFY=L "Study Period";
title3 JUSTIFY=L "Treatment: #byval1";
run;quit;
ods rtf close;
ods listing;


/*Dataset: ADCM
 Variables: STUDYID, USUBJID, TRTA, TRTAN, SAFFL, CMCLAS, CMDECOD, CMDOSE, CMDOSU, CMINDC, CMSTDTC, CMENDTC, ADURN, AENRF, SAFFL
 Record Selection: 

Subject ID = USUBJID
 Medication ATC term(s) = CMCLAS
 Generic Name = CMDECOD
 Dose (unit) = CMDOSE (CMDOSU)
 Primary Indication for Use = CMINDC
 Start Date/Stop Date = CMSTDTC/CMENDTC
 Dur. (days) = ADURN
 Cont. (Y/N) = display 'Y' if AENRF='Ongoing'; else display 'N'
 Sort by STUDYID, USUBJID, CMSTDTC, CMENDTC, CMDECOD. 
*/
