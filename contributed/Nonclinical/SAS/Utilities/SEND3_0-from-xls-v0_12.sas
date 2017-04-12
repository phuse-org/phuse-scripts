/*******************************************************************************/
/*  SEND3.0-from-xls-v0.10.sas                                                 */
/*                                                                             */
/*  A tool to create SAS XPT files for SEND 3.0 from an Excel file             */
/*  using the base SAS system.                                                 */
/*                                                                             */
/* Why I created this script: SAS JMP can import *.xls files and export *.xpt, */
/* but it truncates the columns longer than about 10 to 15 characters  (I'm not*/
/* sure of its exact behaviour.) but this was clearly not acceptable. My script*/  
/* Also automates the removal of temporary rows and columns; so the *.xls files*/
/* don't need to be manually revised in the final stages of production, but    */
/* retain the useful temporary information in case additional modifications are*/
/* needed later.                                                               */
/*                                                                             */
/* Disclaimer:                                                                 */
/*   This is the first SAS script I have written in 15 years and wasn't very   */
/*   proficient back then.  I learned just enough SAS to create this script;   */
/*   so there are bound to be better ways or more reliable ways of writting    */
/*   this.  Use at your own risk, but hopefully you find it at least as        */
/*   helpful to you as it was to me in preparing my first few SEND dataset that*/
/*   were accepted by the FDA.  This study didn't includ the following domains;*/
/*   so, you will need to create code for them if you need these: SC,          */
/*   VS                                                                        */
/*                                                                             */
/* Script's expectations:                                                      */
/* - Developed using SAS 8.02 TS Level 02M0 running on Windows 5.1.2600        */
/* - The tabs in the *.xls file should be labeled with the 2 letter domain     */
/*   name in upper case letters. (any additional tabs will be ignored.)        */
/* - The first row in each worksheet should have the variable lables in upper  */
/*   case letters.  I'm not sure what happens if you have more than one        */
/*   column with the same lable.  I'm also not sure what happens if lables     */
/*   would be the same if case were ignored (e.g. StudyID and STUDYID). I      */
/*   suggest avoid creating duplicates and near duplicates.                    */
/* - If the DOMAIN column is blank in any row, this script assumes the row to  */
/*   be junk and the row is deleted.                                           */
/* - If the DOMAIN column contains 'char', 'Char', or other permutations of    */
/*   capitolization, this script assumes the row to be junk and the row is     */
/*   deleted.  I use this feature to include insert in row 2 of each worksheet */
/*   values to indicate if the column should be numeric or char.  For numeric  */
/*   columns I supply a number (e.g. 9999) in this row and for character       */
/*   columns I supply char.  This is helpful when creating the dataset and     */
/*   also enables SAS to guess the type correctly for columns that have no     */
/*   values in the first several rows.                                         */
/* - For columns that SEND specifies should be character but that contain what */
/*   Excel thinks are numbers, it is important to change the cell format to be */
/*   text by either preceeding the numbers with an appostrophy or by changing  */
/*   the cell's format. There appears to be a bug in Excel 2007 that prevents  */
/*   (at timest) SAS from reading the cell format specified.  From my          */
/*   experience it appears to be readable by SAS if Excel 2007's error checking*/
/*   option can identify that the cell contains text even though it looks like */
/*   a number or if the cell contains a formula that returns text.  Use the    */
/*   "Data Tools" feature called "Text to Columns" to overcome this bug.       */
/* - Colors are ignored by the script, so I started to indicate with colors    */
/*   which columns (and values in TS) are required and which are expected.     */
/*                                                                             */
/* How to use this script:                                                     */
/* - Install SAS 8 on your windows PC.                                         */
/* - Do a search and replace to change the value assigned to DATAFILE= to      */
/*   match the file name you will use and save the resulting file.             */
/* - Do another search and replace to change the XPORT file name.              */
/* - Double-click on the icon for this file to open it in SAS.                 */
/* - Within SAS, click on the icon of a person running, labeled "submit" to    */
/*   run the script.                                                           */
/*                                                                             */
/*******************************************************************************/
/* Feb 2, 2011   W. houser   Created initial version for sharing, v0.2         */
/* Feb 8, 2011   W. houser   Added RELREC and VS--although VS is not in SEND30A*/
/*                           for use with DN03117. changed name to v0.3        */
/* Feb 9, 2011   W. houser   Added lable statements. Added instructions to get */
/*                           proper data types.  Changed name to v0.4          */
/* Feb 23, 2011  W. Houser   Added domains DD, FW, and SUPPEX, corrected       */
/*                           spelling of variable PCEVLINT                     */
/* Jun 28, 2011  W. Houser   Started adjusting script for the final SEND 3.0   */
/* Apr 10, 2012  W. Houser   Corrected issues identified by OpenCDISC validator*/
/*                           Added Dataset lables                              */
/*                           Additional work would be needed to get variable   */
/*                           lengths to match the expected lengths.            */
/* Aug  7-9,2012  W. Houser  Corrected DM's variable descriptors for USUBJID   */
/*                           and SUBJID.  They had been swapped.               */
/*                           Corrected variable description for AGEU, BGORRES, */
/*                           CLGRPID, CLSCAT, EX.POOLID, LB.POOLID, LBORRES,   */
/*                           LBLAT, MADY, MIORRES, OMDTC, PPRFTDTC, PCNAM.     */
/*                           Added statements to set variable lengths based on */
/*                           Opencdisc warnings.                               */
/* Dec 12, 2012   W. Houser  Moved the "SET MyData" statements to be after the */
/*                           LABEL statements.  This way the LABLE statements  */
/*                           Determine the variable order. changed name to v0.9*/
/* Jan 15, 2013   W. Houser  Added TF changed to v0.10                         */
/* Aug  8, 2016   W. Houser  Atted PM changed to v0.11                         */
/* Aug 23, 2016   W. Houser  Set size of TS.DOMAIN to be 2 characters.         */
/* Nov  2, 2016   W. Houser  Added SUPPMA changed to v0.12                     */
/* Feb 17, 2017   W. Houser  Added SUPPMI and the "change" macro to set the    */
/*                           variable lengths to the size of the data          */
/*                           Corrected order of DM variables to match SENDIG   */
/* Mar 14, 2017   W. Houser  Added SC domain                                   */
/*******************************************************************************/

%macro change(dsn);                                         
/* copied this macro from http://support.sas.com/kb/35/230.html */                                                            
data _null_;                                                
  set &dsn;                                                 
  array qqq(*) _character_;                                 
  call symput('siz',put(dim(qqq),5.-L));                    
  stop;                                                     
run;                                                        
                                                            
data _null_;                                                
  set &dsn end=done;                                        
  array qqq(&siz) _character_;                              
  array www(&siz.);                                         
  if _n_=1 then do i= 1 to dim(www);                        
    www(i)=0;                                               
  end;                                                      
  do i = 1 to &siz.;                                        
    www(i)=max(www(i),length(qqq(i)));                      
  end;                                                      
  retain _all_;                                             
  if done then do;                                          
    do i = 1 to &siz.;                                      
      length vvv $50;                                       
      vvv=catx(' ','length',vname(qqq(i)),'$',www(i),';');  
      fff=catx(' ','format ',vname(qqq(i))||' '||           
          compress('$'||put(www(i),3.)||'.;'),' ');         
      call symput('lll'||put(i,3.-L),vvv) ;                 
      call symput('fff'||put(i,3.-L),fff) ;                 
    end;                                                    
  end;                                                      
run;                                                        
                                                            
data &dsn.;                                                
  %do i = 1 %to &siz.;                                      
    &&lll&i                                                 
    &&fff&i                                                 
  %end;                                                     
  set &dsn;                                                 
run;                                                        
                                                            
%mend;                                                      
                                                            
/* DM **********************************************/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="DM$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		ARMCD    $ 20
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		SUBJID
		RFSTDTC
		RFENDTC
		SITEID
		BRTHDTC
		AGE
		AGETXT
		AGEU
		SEX
		SPECIES
		STRAIN
		SBSTRAIN
		ARMCD
		ARM
		SETCD
		);
	IF Lowcase(DOMAIN) eq 'char' THEN DELETE;
	IF DOMAIN eq '' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\dm.xpt';
DATA sasxpt.dm (label='DEMOGRAPHICS'); 
	LABEL 
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		SUBJID	= 'Subject Identifier for the Study'
		RFSTDTC	= 'Subject Reference Start Date/Time'
		RFENDTC	= 'Subject Reference End Date/Time'
		SITEID	= 'Study Site Identifier'
		BRTHDTC	= 'Date/Time of Birth'
		AGE	= 'Age'
		AGETXT	= 'Age Range'
		AGEU	= 'Age Unit'
		SEX	= 'Sex'
		SPECIES	= 'Species'
		STRAIN	= 'Strain/Substrain'
		SBSTRAIN	= 'Strain/Substrain Details'
		ARMCD	= 'Planned Arm Code'
		ARM	= 'Description of Planned Arm'
		SETCD	= 'Set Code'
	   ;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* CO **********************************************/
/* Changed order of variables (RDOMAIN, IDVAR, IDVARVAL, COREF) and added CODY to match final SEND 3.0 */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="CO$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		IDVAR    $ 8
	;
	SET read (keep =
		STUDYID
		DOMAIN
		RDOMAIN
		USUBJID
		COSEQ
		IDVAR
		IDVARVAL
		COREF
		COVAL
		COVAL1
		COVAL2
		COVAL3
		COVAL4
		COVAL5
		COVAL6
		COVAL7
		COVAL8
		COVAL9
		COEVAL
		CODTC
		CODY);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\co.xpt';
DATA sasxpt.CO (label='COMMENTS'); 
	LABEL 
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		RDOMAIN	= 'Related Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		COSEQ	= 'Sequence Number'
		IDVAR	= 'Identifying Variable'
		IDVARVAL	= 'Identifying Variable Value'
		COREF	= 'Comment Reference'
		COVAL	= 'Comment'
		COVAL1	= 'Comment'
		COVAL2	= 'Comment'
		COVAL3	= 'Comment'
		COVAL4	= 'Comment'
		COVAL5	= 'Comment'
		COVAL6	= 'Comment'
		COVAL7	= 'Comment'
		COVAL8	= 'Comment'
		COVAL9	= 'Comment'
		COEVAL	= 'Evaluator'
		CODTC	= 'Date/Time of Comment'
		CODY    = 'Study Day of Comment'
	   ;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* SE **********************************************/
/* Changed order of variables (moved SEUPDES) to match final SEND 3.0 */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="SE$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		SESEQ
		ETCD
		ELEMENT
		SESTDTC
		SEENDTC
		SEUPDES
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\se.xpt';
DATA sasxpt.se (label='SUBJECT ELEMENTS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		SESEQ	= 'Sequence Number'
		ETCD	= 'Element Code'
		ELEMENT	= 'Description of Element'
		SESTDTC	= 'Start Date/Time of Element'
		SEENDTC	= 'End Date/Time of Element'
		SEUPDES	= 'Description of Unplanned Element'
	;
	SET MyData;
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* EX **********************************************/
/* To match final SEND 3.0: */
/* Moved EXMETHOD; removed EXCONC, EXCONCU; changed label of EXMETHOD */
/* EXLOT changed from Perm to Exp; No change in this code as a result */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="EX$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		POOLID
		EXSEQ
		EXTRT
		EXDOSE
		EXDOSTXT
		EXDOSU
		EXDOSFRM
		EXDOSFRQ
		EXROUTE
		EXLOT
		EXLOC
		EXMETHOD
		EXTRTV
		EXVAMT
		EXVAMTU
		EXADJ
		EXSTDTC
		EXENDTC
		EXSTDY
		EXENDY
		EXDUR
		EXTPT
		EXTPTNUM
		EXELTM
		EXTPTREF
		EXRFTDTC
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\ex.xpt';
DATA sasxpt.ex (label='EXPOSURE'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		POOLID	= 'Pool Identifier'
		EXSEQ	= 'Sequence Number'
		EXTRT	= 'Name of Actual Treatment'
		EXDOSE	= 'Dose per Administration'
		EXDOSTXT	= 'Dose Description'
		EXDOSU	= 'Dose Units'
		EXDOSFRM	= 'Dose Form'
		EXDOSFRQ	= 'Dosing Frequency Per Interval'
		EXROUTE	= 'Route of Administration'
		EXLOT	= 'Lot Number'
		EXLOC	= 'Location of Dose Administration'
		EXMETHOD	= 'Method of Administration'
		EXTRTV	= 'Treatment Vehicle'
		EXVAMT	= 'Amount Administered'
		EXVAMTU	= 'Amount Administered Units'
		EXADJ	= 'Reason for Dose Adjustment'
		EXSTDTC	= 'Start Date/Time of Treatment'
		EXENDTC	= 'End Date/Time of Treatment'
		EXSTDY	= 'Study Day of Start of Treatment'
		EXENDY	= 'Study Day of End of Treatment'
		EXDUR	= 'Duration of Treatment'
		EXTPT	= 'Planned Time Point Name'
		EXTPTNUM	= 'Planned Time Point Number'
		EXELTM	= 'Planned Elapsed Time from Time Point Ref'
		EXTPTREF	= 'Time Point Reference'
		EXRFTDTC	= 'Date/Time of Reference Time Point'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* DS **********************************************/
/* To match final SEND 3.0: */
/* Moved VISITDY; renamed DSDTC-->DSSTDTC ; added DSSTDY  */
/* VISITDY changed from Perm to Exp */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="DS$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		DSSEQ
		DSTERM
		DSDECOD
		VISITDY
		DSSTDTC
		DSSTDY
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\ds.xpt';
DATA sasxpt.ds (label='DISPOSITION'); 
	LABEL
		STUDYID	='Study Identifier'
		DOMAIN 	='Domain Abbreviation'
		USUBJID	='Unique Subject Identifier'
		DSSEQ	='Sequence Number'
		DSTERM	='Reported Term for the Disposition Event'
		DSDECOD	='Standardized Disposition Term'
		VISITDY	='Planned Study Day of Disposition'
		DSSTDTC	='Date/Time of Disposition'
		DSSTDY  ='Study Day of Disposition'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* BW **********************************************/
/* To match final SEND 3.0: */
/* relabeled BWORRES, BWORRESU, BWSTRESC, BWSTRESN, BWSTRESU, BWREASND, BWREASEX, VISITDY  */
/* VISITDY changed from Perm to Exp */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="BW$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		BWTESTCD $  8
		BWTEST   $ 40
		BWBLFL   $  1
		BWFAST   $  1
		BWEXCLFL $  1
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		BWSEQ
		BWTESTCD
		BWTEST
		BWORRES
		BWORRESU
		BWSTRESC
		BWSTRESN
		BWSTRESU
		BWSTAT
		BWREASND
		BWBLFL
		BWFAST
		BWEXCLFL
		BWREASEX
		VISITDY
		BWDTC
		BWDY
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\bw.xpt';
DATA sasxpt.bw (label='BODY WEIGHT'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		BWSEQ	= 'Sequence Number'
		BWTESTCD	= 'Test Short Name'
		BWTEST	= 'Test Name'
		BWORRES	= 'Result or Findings as Collected'
		BWORRESU	= 'Unit of the Original Result'
		BWSTRESC	= 'Standardized Result in Character Format'
		BWSTRESN	= 'Standardized Result in Numeric Format'
		BWSTRESU	= 'Unit of the Standardized Result'
		BWSTAT	= 'Examination Status'
		BWREASND	= 'Reason Not Done'
		BWBLFL	= 'Baseline Flag'
		BWFAST	= 'Fasting Status'
		BWEXCLFL	= 'Exclusion Flag'
		BWREASEX	= 'Reason for Exclusion'
		VISITDY	= 'Planned Study Day of Collection'
		BWDTC	= 'Date/Time Animal Weighed'
		BWDY	= 'Study Day Animal Weighed'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* BG **********************************************/
/* To match final SEND 3.0: */
/* added BGDY, BGENDY but left them blank since they are Perm  */
/* relabeled  --ORRES, --ORRESU, --STRESC, --STRESN, --STRESU, --REASND, --REASEX, --BGELTM, --BGTPTREF, --BGRFTDTC  */
/* no variables changed importance */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="BG$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		BGTESTCD $  8
		BGTEST   $ 40
		BGEXCLFL $  1
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		BGSEQ
		BGTESTCD
		BGTEST
		BGORRES
		BGORRESU
		BGSTRESC
		BGSTRESN
		BGSTRESU
		BGSTAT
		BGREASND
		BGEXCLFL
		BGREASEX
		BGDTC
		BGENDTC
		BGDY
		BGENDY
		BGELTM
		BGTPTREF
		BGRFTDTC
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\bg.xpt';
DATA sasxpt.bg (label='BODY WEIGHT GAIN'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		BGSEQ	= 'Sequence Number'
		BGTESTCD	= 'Test Short Name'
		BGTEST	= 'Test Name'
		BGORRES	= 'Result or Findings as Collected'
		BGORRESU	= 'Unit of the Original Result'
		BGSTRESC	= 'Standardized Result in Character Format'
		BGSTRESN	= 'Standardized Result in Numeric Format'
		BGSTRESU	= 'Unit of the Standardized Result'
		BGSTAT	= 'Examination Status'
		BGREASND	= 'Reason Not Done'
		BGEXCLFL	= 'Exclusion Flag'
		BGREASEX	= 'Reason for Exclusion'
		BGDTC	= 'Date/Time Animal Weighed'
		BGENDTC	= 'End Date/Time Animal Weighed'
		BGDY    = 'Study Day Animal Weighed'
		BGENDY  = 'Study Day of End of Weight Interval'
		BGELTM	= 'Planned Elapsed Time from Time Point Ref'
		BGTPTREF	= 'Time Point Reference'
		BGRFTDTC	= 'Date/Time of Reference Time Point'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* CL **********************************************/
/* To match final SEND 3.0: */
/* added VISITDY (Exp)                          */
/* added CLBODSYS, CLTPTREF, CLRFTDTC (Perm)  */
/* deleted CLDTHREL */
/* moved CLEVAL     */
/* relabeled  --ORRES, --STRESC, --REASND, --REASEX  */
/* no variables changed importance */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="CL$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		CLTESTCD $  8
		CLTEST   $ 40
		CLEXCLFL $  1
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		POOLID
		CLSEQ
		CLGRPID
		CLSPID
		CLTESTCD
		CLTEST
		CLCAT
		CLSCAT
		CLBODSYS
		CLORRES
		CLSTRESC
		CLRESCAT
		CLSTAT
		CLREASND
		CLLOC
		CLEVAL
		CLSEV
		CLEXCLFL
		CLREASEX
		VISITDY
		CLDTC
		CLDY
		CLTPT
		CLTPTNUM
		CLELTM
		CLTPTREF
		CLRFTDTC
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\cl.xpt';
DATA sasxpt.cl (label='CLINICAL OBSERVATIONS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		POOLID	= 'Pool Identifier'
		CLSEQ	= 'Sequence Number'
		CLGRPID	= 'Group Identifier'
		CLSPID	= 'Mass Identifier'
		CLTESTCD	= 'Test Short Name'
		CLTEST	= 'Test Name'
		CLCAT	= 'Category for Clinical Observations'
		CLSCAT	= 'Subcategory for Clinical Observations'
		CLBODSYS ='Body System or Organ Class'
		CLORRES	= 'Result or Findings as Collected'
		CLSTRESC	= 'Standardized Result in Character Format'
		CLRESCAT	= 'Result Category'
		CLSTAT	= 'Examination Status'
		CLREASND	= 'Reason Not Done'
		CLLOC	= 'Location of a Finding'
		CLEVAL	= 'Evaluator'
		CLSEV	= 'Severity'
		CLEXCLFL	= 'Exclusion Flag'
		CLREASEX	= 'Reason for Exclusion'
		VISITDY = 'Planned Study Day of Collection'
		CLDTC	= 'Start Date/Time of Observation'
		CLDY	= 'Study Day of Observation'
		CLTPT	= 'Planned Time Point Name'
		CLTPTNUM	= 'Planned Time Point Number'
		CLELTM	= 'Planned Elapsed Time from Time Point Ref'
		CLTPTREF ='Time Point Reference'
		CLRFTDTC ='Date/Time of Reference Time Point'
	;
	SET MyData;
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* DD **********************************************/
/* To match final SEND 3.0: 
   added DDDY (Perm)
   no variables changed importance */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="DD$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		DDSEQ
		DDTESTCD
		DDTEST
		DDORRES
		DDSTRESC
		DDRESCAT
		DDEVAL
		DDDTC
		DDDY
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\dd.xpt';
DATA sasxpt.dd (label='DEATH DIAGNOSIS'); 
	LABEL 
		STUDYID = 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		DDSEQ	= 'Sequence Number'
		DDTESTCD= 'Death Diagnosis Short Name'
		DDTEST	= 'Death Diagnosis Name'
		DDORRES	= 'Result or Findings as Collected'
		DDSTRESC= 'Standardized Result in Character Format'
		DDRESCAT= 'Result Category'
		DDEVAL	= 'Evaluator'
		DDDTC	= 'Date/time of Diagnosis'
		DDDY	= 'Study Day of Diagnosis'
	   ;
	SET MyData;
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* FW **********************************************/
/* To match final SEND 3.0: 
	Added FWDY, FWENDY
	Priority changed for FWEXCLFL, FWREASEX from Exp to Perm 
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="FW$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		FWTESTCD $  8
		FWTEST   $ 40
		FWEXCLFL $  1
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		POOLID
		FWSEQ
		FWGRPID
		FWTESTCD
		FWTEST
		FWORRES
		FWORRESU
		FWSTRESC
		FWSTRESN
		FWSTRESU
		FWSTAT
		FWREASND
		FWEXCLFL
		FWREASEX
		FWDTC
		FWENDTC
		FWDY
		FWENDY
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\fw.xpt';
DATA sasxpt.fw (label='FOOD AND WATER CONSUMPTION'); 
	LABEL 
		STUDYID = 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		POOLID	= 'Pool Identifier'
		FWSEQ	= 'Sequence Number'
		FWGRPID	= 'Group Identifier'
		FWTESTCD	= 'Food /Water Consumption Short Name'
		FWTEST	= 'Food /Water Consumption Name'
		FWORRES	= 'Result or Findings as Collected'
		FWORRESU	= 'Unit of the Original Result'
		FWSTRESC	= 'Standardized Result in Character Format'
		FWSTRESN	= 'Standardized Result in Numeric Format'
		FWSTRESU	= 'Unit of the Standardized Result'
		FWSTAT	= 'Completion Status'
		FWREASND	= 'Reason Not Done'
		FWEXCLFL	= 'Exclusion Flag'
		FWREASEX	= 'Reason for Exclusion'
		FWDTC	= 'Date/Time of Observation'
		FWENDTC	= 'End Date/Time of Observation'
		FWDY	= 'Study Day of Observation'
		FWENDY	= 'Study Day of End of Observation'
	   ;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* LB **********************************************/
/* To match final SEND 3.0: 
	deleted LBSPCLOC
	added LBSPCUFL, LBLAT, LBDIR, LBPORTOT, LBENDY (Perm)
	moved LBEXCLFL, LBREASEX
	relabeled  POOLID, --GRPID, --REFID, --ORRES, --ORRESU, --STRESC, --STRESN, --STRESU, --STNRC, --REASND, --ANTREG, --LOC, --REASEX   
	Priority changed for VISITDY from Perm to Exp
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="LB$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		LBTESTCD $  8
		LBTEST   $ 40
		LBBLFL   $  1
		LBFAST   $  1
		LBEXCLFL $  1
		LBSPCUFL $  1
		LBDRVFL  $  1
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		POOLID
		LBSEQ
		LBGRPID
		LBREFID
		LBSPID
		LBTESTCD
		LBTEST
		LBCAT
		LBSCAT
		LBORRES
		LBORRESU
		LBORNRLO
		LBORNRHI
		LBSTRESC
		LBSTRESN
		LBSTRESU
		LBSTNRLO
		LBSTNRHI
		LBSTNRC
		LBNRIND
		LBSTAT
		LBREASND
		LBNAM
		LBSPEC
		LBANTREG
		LBSPCCND
		LBSPCUFL		
		LBLOC
		LBLAT
		LBDIR
		LBPORTOT
		LBMETHOD
		LBBLFL
		LBFAST
		LBDRVFL
		LBTOX
		LBTOXGR
		LBEXCLFL
		LBREASEX
		VISITDY
		LBDTC
		LBENDTC
		LBDY
		LBENDY
		LBTPT
		LBTPTNUM
		LBELTM
		LBTPTREF
		LBRFTDTC
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\lb.xpt';
DATA sasxpt.lb (label='LABORATORY TEST RESULTS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		POOLID	= 'Pool Identifier'
		LBSEQ	= 'Sequence Number'
		LBGRPID	= 'Group Identifier'
		LBREFID	= 'Specimen Identifier'
		LBSPID	= 'Sponsor-Defined Identifier'
		LBTESTCD	= 'Lab Test or Examination Short Name'
		LBTEST	= 'Lab Test or Examination Name'
		LBCAT	= 'Category for Lab Test'
		LBSCAT	= 'Subcategory for Lab Test'
		LBORRES	= 'Result or Findings as Collected'
		LBORRESU	= 'Unit of the Original Result'
		LBORNRLO	= 'Reference Range Lower Limit-Orig Unit'
		LBORNRHI	= 'Reference Range Upper Limit-Orig Unit'
		LBSTRESC	= 'Standardized Result in Character Format'
		LBSTRESN	= 'Standardized Result in Numeric Format'
		LBSTRESU	= 'Unit of the Standardized Result'
		LBSTNRLO	= 'Reference Range Lower Limit-Std Unit'
		LBSTNRHI	= 'Reference Range Upper Limit-Std Unit'
		LBSTNRC	= 'Reference Range for Char Rslt-Std Unit'
		LBNRIND	= 'Reference Range Indicator'
		LBSTAT	= 'Completion Status'
		LBREASND	= 'Reason Not Done'
		LBNAM	= 'Vendor Name'
		LBSPEC	= 'Specimen Type'
		LBANTREG	= 'Anatomical Region of Specimen'
		LBSPCCND	= 'Specimen Condition'
		LBSPCUFL	= 'Specimen Usability for the Test'
		LBLOC	= 'Specimen Collection Location'
		LBLAT	= 'Specimen Laterality within Subject'
		LBDIR	= 'Specimen Directionality within Subject'
		LBPORTOT	= 'Portion or Totality'
		LBMETHOD	= 'Method of Test or Examination'
		LBBLFL	= 'Baseline Flag'
		LBFAST	= 'Fasting Status'
		LBDRVFL	= 'Derived Flag'
		LBTOX	= 'Toxicity'
		LBTOXGR	= 'Standard Toxicity Grade'
		LBEXCLFL	= 'Exclusion Flag'
		LBREASEX	= 'Reason for Exclusion'
		VISITDY	= 'Planned Study Day of Collection'
		LBDTC	= 'Date/Time of Specimen Collection'
		LBENDTC	= 'End Date/Time of Specimen Collection'
		LBDY	= 'Study Day of Specimen Collection'
		LBENDY	= 'Study Day of End of Specimen Collection'
		LBTPT	= 'Planned Time Point Name'
		LBTPTNUM	= 'Planned Time Point Number'
		LBELTM	= 'Planned Elapsed Time from Time Point Ref'
		LBTPTREF	= 'Time Point Reference'
		LBRFTDTC	= 'Date/Time of Reference Time Point'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* MA **********************************************/
/* To match final SEND 3.0: 
	deleted MASPCLOC, MALOC
	added MABODSYS, MASPCUFL, MALAT, MADIR, MAPORTOT (Perm)
	no variables moved
	relabeled  DOMAIN, --GRPID, --REFID, --TESTCD, --TEST, --ORRES, --STRESC, --ANTREG
	Priority changed for no other variables
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="MA$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		MATESTCD $  8
		MATEST   $ 40
		MASPCUFL   $  1
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		MASEQ
		MAGRPID
		MAREFID
		MASPID
		MATESTCD
		MATEST
		MABODSYS
		MAORRES
		MASTRESC
		MASTAT
		MAREASND
		MANAM
		MASPEC
		MAANTREG
		MASPCCND
		MASPCUFL
		MALAT
		MADIR
		MAPORTOT
		MAEVAL
		MASEV
		MADTHREL
		MADTC
		MADY
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\ma.xpt';
DATA sasxpt.ma (label='MACROSCOPIC FINDINGS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		MASEQ	= 'Sequence Number'
		MAGRPID	= 'Group Identifier'
		MAREFID	= 'Specimen Reference Identifier'
		MASPID	= 'Mass Identifier'
		MATESTCD	= 'Macroscopic Examination Short Name'
		MATEST	= 'Macroscopic Examination Name'
		MABODSYS	= 'Body System or Organ Class'
		MAORRES	= 'Result or Findings as Collected'
		MASTRESC	= 'Standardized Result in Character Format'
		MASTAT	= 'Examination Status'
		MAREASND	= 'Reason Not Done'
		MANAM	= 'Laboratory Name'
		MASPEC	= 'Specimen Material Type'
		MAANTREG	= 'Anatomical Region of Specimen'
		MASPCCND	= 'Specimen Condition'
		MASPCUFL	= 'Specimen Usability for the Test'
		MALAT	= 'Specimen Laterality within Subject'
		MADIR	= 'Specimen Directionality within Subject'
		MAPORTOT	= 'Portion or Totality'
		MAEVAL	= 'Evaluator'
		MASEV	= 'Severity'
		MADTHREL	= 'Relationship to Death'
		MADTC	= 'Date/Time of Collection'
		MADY	= 'Study Day of Specimen Collection'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* MI **********************************************/
/* To match final SEND 3.0: 
	added --BODSYS, --MILAT, --DIR (Perm)
	added --MISPCUFL (Exp)
	deleted MISPCLOC
	no variables moved
	relabeled  --GRPID, --REFID, --SPID, --ORRES, --REASND
	Priority changed for no other variables
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="MI$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		MITESTCD $  8
		MITEST   $ 40
		MISPCUFL $  1
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		MISEQ
		MIGRPID
		MIREFID
		MISPID
		MITESTCD
		MITEST
		MIBODSYS
		MIORRES
		MISTRESC
		MIRESCAT
		MISTAT
		MIREASND
		MINAM
		MISPEC
		MIANTREG
		MISPCCND
		MISPCUFL
		MIMETHOD
		MILAT
		MIDIR
		MIEVAL
		MISEV
		MIDTHREL
		MIDTC
		MIDY
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\mi.xpt';
DATA sasxpt.mi (label='MICROSCOPIC FINDINGS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		MISEQ	= 'Sequence Number'
		MIGRPID	= 'Group Identifier'
		MIREFID	= 'Specimen Reference Identifier'
		MISPID	= 'Mass Identifier'
		MITESTCD	= 'Microscopic Examination Short Name'
		MITEST	= 'Microscopic Examination Name'
		MIBODSYS	= 'Body System or Organ Class'
		MIORRES	= 'Result or Findings as Collected'
		MISTRESC	= 'Standardized Result in Character Format'
		MIRESCAT	= 'Result Category'
		MISTAT	= 'Completion Status'
		MIREASND	= 'Reason Not Done'
		MINAM	= 'Laboratory Name'
		MISPEC	= 'Specimen Material Type'
		MIANTREG	= 'Anatomical Region of Specimen'
		MISPCCND	= 'Specimen Condition'
		MISPCUFL	= 'Specimen Usability for the Test'
		MIMETHOD	= 'Method of Test or Examination'
		MILAT	= 'Specimen Laterality within Subject'
		MIDIR	= 'Specimen Directionality within Subject'
		MIEVAL	= 'Evaluator'
		MISEV	= 'Severity'
		MIDTHREL	= 'Relationship to Death'
		MIDTC	= 'Date/Time of Specimen Collection'
		MIDY	= 'Study Day of Specimen Collection'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* OM **********************************************/
/* To match final SEND 3.0: 
	added --SPCCND, --SPCUFL, --LAT, --DIR, --PORTOT (Perm)
	deleted OMSPCLOC
	moved OMSPEC, OMANTREG
	relabeled  --ORRES, --ORRESU, --STRESC, --STRESN, --STRESU, --ANTREG
	Priority changed for no other variables
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="OM$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		OMTESTCD $  8
		OMTEST   $ 40
		OMSPCUFL $  1
		OMEXCLFL $  1
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		OMSEQ
		OMTESTCD
		OMTEST
		OMORRES
		OMORRESU
		OMSTRESC
		OMSTRESN
		OMSTRESU
		OMSTAT
		OMREASND
		OMSPEC
		OMANTREG
		OMSPCCND
		OMSPCUFL
		OMLAT
		OMDIR
		OMPORTOT
		OMEXCLFL
		OMREASEX
		OMDTC
		OMDY
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\om.xpt';
DATA sasxpt.om (label='ORGAN MEASUREMENTS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		OMSEQ	= 'Sequence Number'
		OMTESTCD	= 'Test Short Name'
		OMTEST	= 'Test Name'
		OMORRES	= 'Result or Findings as Collected'
		OMORRESU	= 'Unit of the Original Result'
		OMSTRESC	= 'Standardized Result in Character Format'
		OMSTRESN	= 'Standardized Result in Numeric Format'
		OMSTRESU	= 'Unit of the Standardized Result'
		OMSTAT	= 'Finding Status'
		OMREASND	= 'Reason Not Done'
		OMSPEC	= 'Specimen Material Type'
		OMANTREG	= 'Anatomical Region of Specimen'
		OMSPCCND	= 'Specimen Condition'
		OMSPCUFL	= 'Specimen Usability for the Test'
		OMLAT	= 'Specimen Laterality within Subject'
		OMDIR	= 'Specimen Directionality within Subject'
		OMPORTOT	= 'Portion or Totality'
		OMEXCLFL	= 'Exclusion Flag'
		OMREASEX	= 'Reason for Exclusion'
		OMDTC	= 'Date/Time Organ Weighed'
		OMDY	= 'Study Day of Weighing'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* PM **********************************************/
/* added to the script Aug 5, 2016
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="PM$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		PMTESTCD $  8
		PMTEST   $ 40
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		PMSEQ
		PMGRPID
		PMSPID
		PMTESTCD
		PMTEST
		PMORRES
		PMORRESU
		PMSTRESC
		PMSTRESN
		PMSTRESU
		PMSTAT
		PMREASND
		PMLOC
		PMEVAL
		VISITDY
		PMDTC
		PMDY
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\pm.xpt';
DATA sasxpt.pm (label='PALPABLE MASSES'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		PMSEQ	= 'Sequence Number'
		PMGRPID	= 'Group Identifier'
		PMSPID	= 'Mass Identifier'
		PMTESTCD	= 'Test Short Name'
		PMTEST	= 'Test Name'
		PMORRES	= 'Result or Findings as Collected'
		PMORRESU = 'Unit of the Original Result'
		PMSTRESC = 'Standardized Result in Character Format'
		PMSTRESN = 'Standardized Result in Numeric Format'
		PMSTRESU = 'Unit of the Standardized Result'
		PMSTAT	= 'Examination Status'
		PMREASND	= 'Reason Not Done'
		PMLOC	= 'Location of a Finding'
		PMEVAL	= 'Evaluator'
		VISITDY	= 'Planned Study Day of Collection'
		PMDTC	= 'Start Date/Time of Observation'
		PMDY	= 'Study Day of Observation'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* PC **********************************************/
/* To match final SEND 3.0: 
	moved PCEXCLFL, PCREASEX
	relabeled  STUDYID, DOMAIN, USUBJID, POOLID, PCGRPID, PCSPID, --ORRES, --ORRESU, --STRESU, --REASND, --PCREASEX, PCDY	                        
	Priority changed for PCBLFL, VISITDY (Perm --> Exp)
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="PC$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		PCTESTCD $  8
		PCTEST   $ 40
		PCBLFL   $  1
		PCFAST   $  1
		PCEXCLFL $  1
		PCDRVFL  $  1
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		POOLID
		PCSEQ
		PCGRPID
		PCREFID
		PCSPID
		PCTESTCD
		PCTEST
		PCCAT
		PCSCAT
		PCORRES
		PCORRESU
		PCSTRESC
		PCSTRESN
		PCSTRESU
		PCSTAT
		PCREASND
		PCNAM
		PCSPEC
		PCSPCCND
		PCMETHOD
		PCBLFL
		PCFAST
		PCDRVFL
		PCLLOQ
		PCEXCLFL
		PCREASEX
		VISITDY
		PCDTC
		PCENDTC
		PCDY
		PCENDY
		PCTPT
		PCTPTNUM
		PCELTM
		PCTPTREF
		PCRFTDTC
		PCEVLINT
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\pc.xpt';
DATA sasxpt.pc (label='PHARMACOKINETICS CONCENTRATIONS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		POOLID	= 'Pool Identifier'
		PCSEQ	= 'Sequence Number'
		PCGRPID	= 'Group Identifier'
		PCREFID	= 'Sample Identifier'
		PCSPID	= 'Sponsor Identifier'
		PCTESTCD	= 'Test Short Name'
		PCTEST	= 'Test Name'
		PCCAT	= 'Test Category'
		PCSCAT	= 'Test Subcategory'
		PCORRES	= 'Result or Findings as Collected'
		PCORRESU	= 'Unit of the Original Result'
		PCSTRESC	= 'Standardized Result in Character Format'
		PCSTRESN	= 'Standardized Result in Numeric Format'
		PCSTRESU	= 'Unit of the Standardized Result'
		PCSTAT	= 'Completion Status'
		PCREASND	= 'Reason Not Done'
		PCNAM	= 'Vendor Name'
		PCSPEC	= 'Specimen Material Type'
		PCSPCCND	= 'Specimen Condition'
		PCMETHOD	= 'Method of Test or Examination'
		PCBLFL	= 'Baseline Flag'
		PCFAST	= 'Fasting Status'
		PCDRVFL	= 'Derived Flag'
		PCLLOQ	= 'Lower Limit of Quantitation'
		PCEXCLFL	= 'Exclusion Flag'
		PCREASEX	= 'Reason for Exclusion'
		VISITDY	= 'Visit Day'
		PCDTC	= 'Date/Time of Specimen Collection'
		PCENDTC	= 'End Date/Time of Specimen Collection'
		PCDY	= 'Study Day of Specimen Collection '
		PCENDY	= 'Study Day of End of Specimen Collection'
		PCTPT	= 'Planned Time Point Name'
		PCTPTNUM	= 'Planned Time Point Number'
		PCELTM	= 'Planned Elapsed Time from Time Point Ref'
		PCTPTREF	= 'Time Point Reference'
		PCRFTDTC   	= 'Date/Time of Reference Point'
		PCEVLINT	= 'Evaluation Interval'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* PP **********************************************/
/* To match final SEND 3.0: 
    new VISITDY (Exp)
    new PPSTINT, PPENINT (Perm)
	Priority changed for no other variables
	no variables moved
	relabeled  STUDYID, DOMAIN, USUBJID, POOLID, PPGRPID, --ORRES, --ORRESU, --STRESC, --STRESN, --STRESU, --REASND, PPRFTDTC	                        
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="PP$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		PPTESTCD $  8
		PPTEST   $ 40
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		POOLID
		PPSEQ
		PPGRPID
		PPTESTCD
		PPTEST
		PPCAT
		PPSCAT
		PPORRES
		PPORRESU
		PPSTRESC
		PPSTRESN
		PPSTRESU
		PPSTAT
		PPREASND
		PPSPEC
		VISITDY
		PPTPTREF
		PPRFTDTC
		PPSTINT
		PPENINT
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\pp.xpt';
DATA sasxpt.pp (label='PHARMACOKINETICS PARAMETERS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		POOLID	= 'Pool Identifier'
		PPSEQ	= 'Sequence Number'
		PPGRPID	= 'Group Identifier'
		PPTESTCD	= 'Parameter Short Name'
		PPTEST	= 'Parameter Name'
		PPCAT	= 'Parameter Category'
		PPSCAT	= 'Parameter Subcategory'
		PPORRES	= 'Result or Findings as Collected'
		PPORRESU	= 'Unit of the Original Result'
		PPSTRESC	= 'Standardized Result in Character Format'
		PPSTRESN	= 'Standardized Result in Numeric Format'
		PPSTRESU	= 'Unit of the Standardized Result'
		PPSTAT	= 'Completion Status'
		PPREASND	= 'Reason Not Done'
		PPSPEC	= 'Specimen Material Type'
		VISITDY	= 'Planned Study Day of Collection'
		PPTPTREF	= 'Time Point Reference'
		PPRFTDTC	= 'Date/Time of Reference Point'
		PPSTINT	= 'Start of Evaluation Interval'
		PPENINT	= 'End of Evaluation Interval'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* SC **********************************************/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="SC$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		SCSEQ
		SCGRPID
		SCTESTCD
		SCTEST
		SCORRES
		SCORRESU
		SCSTRESC
		SCSTRESN
		SCSTRESU
		SCDTC
		SCDY
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\sc.xpt';
DATA sasxpt.sc (label='SUBJECT CHARACTERISTICS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		SCSEQ	= 'Sequence Number'
		SCGRPID	= 'Group Identifier'
		SCTESTCD	= 'Subject Characteristic Short Name'
		SCTEST	= 'Subject Characteristic'
		SCORRES	= 'Result or Findings as Collected'
		SCORRESU	= 'Unit of the Original Result'
		SCSTRESC	= 'Standardized Result in Character Format'
		SCSTRESN	= 'Standardized Result in Numeric Format'
		SCSTRESU	= 'Unit of the Standardized Result'
		SCDTC	= 'Date/Time of Collection'
		SCDY	= 'Study Day of Collection'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* TF **********************************************/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="TF$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		TFTESTCD $  8
		TFTEST   $ 40
	;
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		TFSEQ
		TFGRPID
		TFREFID
		TFSPID
		TFTESTCD
		TFTEST
		TFORRES
		TFSTRESC
		TFRESCAT
		TFSTAT
		TFREASND
		TFNAM
		TFSPEC
		TFANTREG
		TFSPCCND
		TFMETHOD
		TFLAT
		TFDIR
		TFEVAL
		TFDTHREL
		TFDTC
		TFDY
		TFDETECT
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\tf.xpt';
DATA sasxpt.tf (label='TUMOR FINDINGS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		TFSEQ	= 'Sequence Number'
		TFGRPID	= 'Group Identifier'
		TFREFID	= 'Specimen Identifier'
		TFSPID	= 'Mass Number'
		TFTESTCD	= 'Tumor Examination Short Name'
		TFTEST	= 'Tumor Examination'
		TFBODSYS	= 'Body System or Organ Class'
		TFORRES	= 'Result or Findings as Collected'
		TFSTRESC	= 'Standardized Result in Character Format'
		TFRESCAT	= 'Tumor Malignancy Status'
		TFSTAT	= 'Completion Status'
		TFREASND	= 'Reason Not Done'
		TFNAM	= 'Laboratory Name'
		TFSPEC	= 'Specimen Material Type'
		TFANTREG	= 'Anatomical Region of Specimen'
		TFSPCCND	= 'Specimen Condition'
		TFMETHOD	= 'Method of Test or Examination'
		TFLAT	= 'Specimen Laterality within Subject'
		TFDIR	= 'Specimen Directionality within Subject'
		TFEVAL	= 'Evaluator'
		TFDTHREL	= 'Relationship to Death'
		TFDTC	= 'Date/Time of Collection'
		TFDY	= 'Study Day of Collection'
		TFDETECT	= 'Time in Days to Detection of Tumor'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;

/* VS **********************************************/
/* This is a new domain in SEND 3.0, but I made these adjustments to match the final version
	corrected spelling of VSSEQ
	moved VSCSTATE, VSEXCLFL, VSREASEX
    new VSENDY (Perm)

	relabeled  STUDYID, DOMAIN, USUBJID, POOLID, PPGRPID, --ORRES, --ORRESU, --STRESC, --STRESN, --STRESU, --REASND, PPRFTDTC	                        
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="VS$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		VSSEQ
		VSGRPID
		VSSPID
		VSTESTCD
		VSTEST
/*		VSCAT  removed to avoid error from ppsDefine's validation*/
		VSSCAT
		VSPOS
		VSORRES
		VSORRESU
		VSSTRESC
		VSSTRESN
		VSSTRESU
		VSSTAT
		VSREASND
		VSLOC
		VSCSTATE
		VSBLFL
		VSDRVFL
		VSEXCLFL
		VSREASEX
		VISITDY
		VSDTC
		VSENDTC
		VSDY
		VSENDY
		VSTPT
		VSTPTNUM
		VSELTM
		VSTPTREF
		VSRFTDTC
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\vs.xpt';
DATA sasxpt.vs (label='VITAL SIGNS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		VSSEQ	= 'Sequence Number'
		VSGRPID	= 'Group Identifier'
		VSSPID	= 'Sponsor-Defined Identifier'
		VSTESTCD	= 'Vital Signs Test Short Name'
		VSTEST	= 'Vital Signs Test Name'
/*		VSCAT	= 'Category for Vital Signs'  removed to avoid error from ppsDefine's validation*/
		VSSCAT	= 'Subcategory for Vital Signs'
		VSPOS	= 'Vital Signs Position of Subject'
		VSORRES	= 'Result or Findings as Collected'
		VSORRESU	= 'Unit of the Original Result'
		VSSTRESC	= 'Standardized Result in Character Format'
		VSSTRESN	= 'Standardized Result in Numeric Format'
		VSSTRESU	= 'Unit of the Standardized Result'
		VSSTAT	= 'Completion Status'
		VSREASND	= 'Reason Not Done'
		VSLOC	= 'Location of Vital Signs Measurement'
		VSCSTATE	= 'Consciousness State'
		VSBLFL	= 'Baseline Flag'
		VSDRVFL	= 'Derived Flag'
		VSEXCLFL	= 'Exclusion Flag'
		VSREASEX	= 'Reason for Exclusion'
		VISITDY	= 'Planned Study Day of Collection'
		VSDTC	= 'Date/Time of Measurement'
		VSENDTC	= 'End Date/Time of Measurement'
		VSDY	= 'Study Day of Vital Signs'
		VSENDY	= 'Study Day of End of Measurement'
		VSTPT	= 'Planned Time Point Name'
		VSTPTNUM	= 'Planned Time Point Number'
		VSELTM	= 'Planned Elapsed Time from Time Point Ref'
		VSTPTREF	= 'Time Point Reference'
		VSRFTDTC	= 'Date/Time of Time Point Reference'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* EG **********************************************/
/* This is a new domain in SEND 3.0 */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="EG$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		DOMAIN
		USUBJID
		EGSEQ
		EGGRPID
		EGREFID
		EGSPID
		EGTESTCD
		EGTEST
/*		EGCAT removed to avoid error from ppsDefine's validation*/
		EGPOS
		EGORRES
		EGORRESU
		EGSTRESC
		EGSTRESN
		EGSTRESU
		EGSTAT
		EGREASND
		EGXFN
		EGNAM
		EGLEAD
		EGMETHOD
		EGCSTATE
		EGBLFL
		EGDRVFL
		EGEVAL
		EGEXCLFL
		EGREASEX
		VISITDY
		EGDTC
		EGENDTC
		EGDY
		EGENDY
		EGTPT
		EGTPTNUM
		EGELTM
		EGTPTREF
		EGRFTDTC
		EGEVLINT
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\eg.xpt';
DATA sasxpt.eg (label='ECG TEST RESULTS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		EGSEQ	= 'Sequence Number'
		EGGRPID	= 'Group Identifier'
		EGREFID = 'ECG Reference Identifier'
		EGSPID	= 'Sponsor-Defined Identifier'
		EGTESTCD	= 'ECG Test or Examination Short Name'
		EGTEST	= 'ECG Test or Examination Name'
/*		EGCAT	= 'Category for ECG' removed to avoid error from ppsDefine's validation */
		EGPOS	= 'ECG Position of Subject'
		EGORRES	= 'Result or Findings as Collected'
		EGORRESU	= 'Unit of the Original Result'
		EGSTRESC	= 'Standardized Result in Character Format'
		EGSTRESN	= 'Standardized Result in Numeric Format'
		EGSTRESU	= 'Unit of the Standardized Result'
		EGSTAT	= 'Completion Status'
		EGREASND	= 'Reason Not Done'
		EGXFN	= 'ECG External File Name'
		EGNAM	= 'Vendor Name'
		EGLEAD	= 'Location Used for Measurement'
		EGMETHOD	= 'Method of ECG Test'
		EGCSTATE	= 'Consciousness State'
		EGBLFL	= 'Baseline Flag'
		EGDRVFL	= 'Derived Flag'
		EGEVAL	= 'Evaluator'
		EGEXCLFL	= 'Exclusion Flag'
		EGREASEX	= 'Reason for Exclusion'
		VISITDY	= 'Planned Study Day of Collection'
		EGDTC	= 'Date/Time of ECG'
		EGENDTC	= 'End Date/Time of ECG Collection'
		EGDY	= 'Study Day of ECG Collection'
		EGENDY	= 'Study Day of End of ECG Collection'
		EGTPT	= 'Planned Time Point Name'
		EGTPTNUM	= 'Planned Time Point Number'
		EGELTM	= 'Planned Elapsed Time from Time Point Ref'
		EGTPTREF	= 'Time Point Reference'
		EGRFTDTC	= 'Date/Time of Reference Time Point'
		EGEVLINT	= 'Evaluation Interval'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* TE **********************************************/
/* To match final SEND 3.0, no changes were needed */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="TE$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		DOMAIN
		ETCD
		ELEMENT
		TESTRL
		TEENRL
		TEDUR
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\te.xpt';
DATA sasxpt.te (label='TRIAL ELEMENTS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		ETCD	= 'Element Code'
		ELEMENT	= 'Description of Element'
		TESTRL	= 'Rule for Start of Element'
		TEENRL	= 'Rule for End of Element'
		TEDUR	= 'Planned Duration of Element'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* TA **********************************************/
/* To match final SEND 3.0: 
    no new variables
    no deleted variables
    Priority changed for EPOCH (Perm --> Exp)
	no variables moved
	relabeled  no variables
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="TA$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	LENGTH
		ARMCD    $ 20
	;
	SET read (keep =
		STUDYID
		DOMAIN
		ARMCD
		ARM
		TAETORD
		ETCD
		ELEMENT
		TABRANCH
		TATRANS
		EPOCH
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\ta.xpt';
DATA sasxpt.ta (label='TRIAL ARMS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		ARMCD	= 'Planned Arm Code'
		ARM	= 'Description of Planned Arm'
		TAETORD	= 'Order of Element within Arm'
		ETCD	= 'Element Code'
		ELEMENT	= 'Description of Element'
		TABRANCH	= 'Branch'
		TATRANS	= 'Transition Rule'
		EPOCH	= 'Trial Epoch'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* TX **********************************************/
/* To match final SEND 3.0: 
    no new variables
    no deleted variables
    no priority changes
	no variables moved
	relabeled no variables
	should now include TXPARMCD values TRTDOS, TRTDOSU
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="TX$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		DOMAIN
		SETCD
		SET
		TXSEQ
		TXPARMCD
		TXPARM
		TXVAL
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\tx.xpt';
DATA sasxpt.tx (label='TRIAL SETS'); 
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		SETCD	= 'Set Code'
		SET	= 'Set Description'
		TXSEQ	= 'Sequence Number'
		TXPARMCD	= 'Trial Set Parameter Short Name'
		TXPARM	= 'Trial Set Parameter'
		TXVAL	= 'Trial Set Parameter Value'
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* TS **********************************************/
/* To match final SEND 3.0: 
    no new variables
    no deleted variables
    no priority changes
	no variables moved
	relabeled no variables
	some TSPARMCD changed. This list includes all the "Should Include" TSPARMCDs that changed plus a couple of the others:
		DESIGN -> SDESIGN
		DURDOS -> DOSDUR
		SENDVER -> SNDIGVER
		TITLE -> STITLE
		SPONSOR -> SSPONSOR
		STTYP -> SSTYP
		TESTARTL -> TRT
		TFNAM -> TSTFNAM
		PLANSUB -> SPLANSUB
		QARPT -> deleted
		LENGTH -> deleted
	some TSPARMCD values are new to being "Should Include":
		AGE
		AGETXT
		AGEU
		SNDCTVER
		SPLRNAM
		SPREFID
		STSTDTC
		TSTFLOC
		TRMSAC
		TRTCAS
		TRTV
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="TS$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		DOMAIN
		TSSEQ
		TSGRPID
		TSPARMCD
		TSPARM
		TSVAL
		);
	IF Lowcase(DOMAIN)='char' THEN DELETE;
	IF DOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\ts.xpt';
DATA sasxpt.ts (label='TRIAL SUMMARY'); 
	
	LABEL
		STUDYID	= 'Study Identifier'
		DOMAIN	= 'Domain Abbreviation'
		TSSEQ	= 'Sequence Number'
		TSGRPID	= 'Group Identifier'
		TSPARMCD	= 'Trial Summary Parameter Short Name'
		TSPARM	= 'Trial Summary Parameter'
		TSVAL	= 'Parameter Value'
	;
	LENGTH
		DOMAIN    $ 2
	;
	SET MyData; 
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* SUPPEX **********************************************/
/* To match final SEND 3.0, no changes were needed */
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="SUPPEX$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		RDOMAIN
		USUBJID
		POOLID
		IDVAR
		IDVARVAL
		QNAM
		QLABEL
		QVAL
		QORIG
		QEVAL
		);
	IF Lowcase(RDOMAIN)='char' THEN DELETE;
	IF RDOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\suppex.xpt';
DATA sasxpt.suppex (label='SUPPLEMENTAL QUALIFIERS FOR EX'); 
	LABEL 
		STUDYID = 'Study Identifier'
		RDOMAIN = 'Related Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		POOLID	= 'Pool Identifier'
		IDVAR	= 'Identifying Variable'
		IDVARVAL= 'Identifying Variable Value'
		QNAM	= 'Qualifier Variable Name'
		QLABEL	= 'Qualifier Variable Label'
		QVAL	= 'Data Value'
		QORIG	= 'Origin'
		QEVAL	= 'Evaluator'
	   ;
	SET MyData;
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* SUPPMA **********************************************/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="SUPPMA$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		RDOMAIN
		USUBJID
		POOLID
		IDVAR
		IDVARVAL
		QNAM
		QLABEL
		QVAL
		QORIG
		QEVAL
		);
	IF Lowcase(RDOMAIN)='char' THEN DELETE;
	IF RDOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\suppma.xpt';
DATA sasxpt.suppma (label='SUPPLEMENTAL QUALIFIERS FOR MA'); 
	LABEL 
		STUDYID = 'Study Identifier'
		RDOMAIN = 'Related Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		POOLID	= 'Pool Identifier'
		IDVAR	= 'Identifying Variable'
		IDVARVAL= 'Identifying Variable Value'
		QNAM	= 'Qualifier Variable Name'
		QLABEL	= 'Qualifier Variable Label'
		QVAL	= 'Data Value'
		QORIG	= 'Origin'
		QEVAL	= 'Evaluator'
	   ;
	SET MyData;
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* SUPPMI **********************************************/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="SUPPMI$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		RDOMAIN
		USUBJID
		POOLID
		IDVAR
		IDVARVAL
		QNAM
		QLABEL
		QVAL
		QORIG
		QEVAL
		);
	IF Lowcase(RDOMAIN)='char' THEN DELETE;
	IF RDOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\suppmi.xpt';
DATA sasxpt.suppmi (label='SUPPLEMENTAL QUALIFIERS FOR MI'); 
	LABEL 
		STUDYID = 'Study Identifier'
		RDOMAIN = 'Related Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		POOLID	= 'Pool Identifier'
		IDVAR	= 'Identifying Variable'
		IDVARVAL= 'Identifying Variable Value'
		QNAM	= 'Qualifier Variable Name'
		QLABEL	= 'Qualifier Variable Label'
		QVAL	= 'Data Value'
		QORIG	= 'Origin'
		QEVAL	= 'Evaluator'
	   ;
	SET MyData;
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* RELREC **********************************************/
/* To match final SEND 3.0: 
    no new variables
    no deleted variables
    Priority changed for POOLID (Exp --> Perm)
	no variables moved
	relabeled  no variables
*/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="RELREC$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		RDOMAIN
		USUBJID
		POOLID
		IDVAR
		IDVARVAL
		RELTYPE
		RELID
		);
	IF Lowcase(RDOMAIN)='char' THEN DELETE;
	IF RDOMAIN='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\relrec.xpt';
DATA sasxpt.relrec (label='RELATED RECORDS'); 
	LABEL 
		STUDYID = 'Study Identifier'
		RDOMAIN = 'Related Domain Abbreviation'
		USUBJID	= 'Unique Subject Identifier'
		POOLID	= 'Pool Identifier'
		IDVAR	= 'Identifying Variable'
		IDVARVAL= 'Identifying Variable Value'
		RELTYPE	= 'Relationship Type'
		RELID	= 'Relationship Identifier'
	   ;
	SET MyData;
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
/* POOLDEF **********************************************/
PROC IMPORT OUT=WORK.read
		DATAFILE="C:\SAS-play\Study.xls"
		DBMS=EXCEL2000 REPLACE;
		RANGE="POOLDEF$"; /*to select the sheet*/
RUN;
DATA MyData; /*Remove the row that identifies the datatype, and keep only SEND defined columns*/
	SET read (keep =
		STUDYID
		POOLID
		USUBJID
		);
	IF Lowcase(POOLID)='char' THEN DELETE;
	IF POOLID='' THEN DELETE;
%change(MyData)
/* export as *.xpt file*/
LIBNAME sasxpt XPORT 'c:\sas-play\pooldef.xpt';
DATA sasxpt.pooldef (label='POOLED DEFINITION'); 
	LABEL 
		STUDYID = 'Study Identifier'
		POOLID	= 'Pool Identifier'
		USUBJID	= 'Unique Subject Identifier'
	   ;
	SET MyData;
RUN;
PROC DATASETS;
	DELETE MyData;
RUN;
