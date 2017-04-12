/*******************************************************************************/
/*  SEND3.0-to-xls-v0.3.sas                                                    */
/*                                                                             */
/*  A tool to read SAS XPT files and create an  *.xml for excel to load.       */
/*                                                                             */
/*  The way I have used it is this:                                            */
/*   *  I already had created a directory named “c:\sas-play” which is where   */
/*      the output will be placed.                                             */
/*   *  I double click on the xpt files and they open in SAS 9.2.              */
/*   *  Then I drag the script file into the SAS 9.2 window to open it.        */
/*   *  I click the icon of a running person to “submit” the script for        */
/*      execution.                                                             */
/*   *  A window appears asking if I want to open or save the *.xml.           */
/*   *  If I choose "open", the dataset opens in Excel.                        */
/*                                                                             */
/*                                                                             */
/*                                                                             */
/*******************************************************************************/
/* Jun 27,2011   W. houser   Created initial version that creates single-tab   */
/*               files and is limited by the max row number of pre-Excel 2007  */
/*               Designed to work on SAS 8.                                    */
/* July 11,2011  W. Houser   Started creating version on SAS 9 to overcome the */
/*               stated limitations of the earlier version.                    */
/* July 20,2011  W. Houser   For large studies, separate files for ecah dataset*/
/*               is necessary.  Switched to creating a single file for each one*/
/*******************************************************************************/
/* To determine availble styples: */
/* ods listing;
proc template; list styles; run; quit;
*/
/* sansPrinter - ok but titles are a little too big */
/* Printer  - is good 
/* Normal is really better
*/

ods listing close;

%MACRO XML(domain);
	%if %sysfunc(exist(&domain)) %then %do;
		ods tagsets.ExcelXP style=Styles.Normal file="c:\SAS-play\&domain..xml";
		ods tagsets.ExcelXP options(Sheet_Name="&domain");
		proc print data=work.&domain;
		run;
	%end;

	%if %sysfunc(exist(supp&domain)) %then %do;
		ods tagsets.ExcelXP style=Styles.Normal file="c:\SAS-play\supp&domain..xml";
		ods tagsets.ExcelXP options(Sheet_Name="supp&domain");
		proc print data=work.supp&domain;
		run;
	%end;
%MEND;

%XML(DM)
%XML(CO)
/*
%XML(SE)
%XML(EX)
%XML(DS)
%XML(BW)
%XML(BG)
%XML(CL)
%XML(DD)
%XML(FW)
%XML(LB)
%XML(MA)
%XML(MI)
%XML(OM)
%XML(PM)
%XML(PC)
%XML(PP)
%XML(SC)
%XML(TF)
%XML(VS)
%XML(EG)
%XML(TE)
%XML(TA)
%XML(TX)
%XML(TS)
%XML(POOLDEF)
%XML(RELREQ)
*/
ods tagsets.ExcelXP close;
