/*********************************************************************************************/
/*********************************************************************************************/
/*--      STEP 2 - SAS code for writing Findings Report and Trial Summary to HTML5         --*/
/*********************************************************************************************/
/*   RUN SAS Script Create JSON Findings, (SAS Script Create JSON Findings also on local
                                  machines for generating the study's JSON file locally
         THEN RUN this STEP 2 - SAS code - Write reports to HTML5                            */
/*********************************************************************************************/
/*  Author: Henrietta Cummings, SAS Institute, winter 2015                                   */
/*********************************************************************************************/
/*********************************************************************************************/
 
%global htmlfilepath trendPercent domain writeHrefJS thisHTML thisCount;
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/*!!!!!!!!   SET THE FOLLOWING LIBNAME TO YOUR SEND STUDY DATA     !!!!!!!!*/
libname send 'd:\send\data\sas data';
/*!!!!!!!!   SET THE FOLLOWING to the file path where you have     !!!!!!!!*/
/*!!!!!!!!   .html file(s) and javascript and css subolders        !!!!!!!!*/
     /***************************************/
     /* PATH to write  HTML file of reports */
     /***************************************/
%let htmlFilePath=D:\SEND\FDAProjectFiles\codefordeployment_12Mar2015\;
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
    /*-- trendPercent is configurable, reset below if needed --*/
%let trendPercent=.2;
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

/*************************************************************************************/
/*--  CREATE TABLEs OF UNIQUE STUDYID VALUES for the createStudyRpt macro loop     --*/
/*-- if more than one study in SEND table DM, this will generate an html file      --*/
/*-- with Microscopic Findings, Macroscopic Findings and Trial Summary reports     --*/
/*-- for each unique studyid                                                       --*/          
/*************************************************************************************/
proc sql;
create table WORK.MIuniqueStudyId as
select distinct studyid, &trendpercent as trendPercent,
       "MI" as domain, "Microscopic Findings" as domainName
from SEND.DM;
create table WORK.MAuniqueStudyId as
select distinct studyid, &trendpercent as trendPercent,
       "MA" as domain, "Macroscopic Findings" as domainName
from SEND.DM;
quit;

options spool;
*options mprint;
%macro odspreHTML();
<link rel='stylesheet' href='css/jquery-ui.css'>
<link rel='stylesheet' type='text/css' href='css/main.css' /> 
<script src='javascript/jquery-1.11.2.min.js'></script>
<script src='javascript/jquery-ui.js'></script>
<script src='javascript/FDAscripts.js'></script>
<script src='javascript/FDAdrillUsubj.js'></script> 
<script src='javascript/FDAdrilldown.js'></script>
<script src='javascript/colResizable-1.5.min.js'></script>
<script src='javascript/FileSaver.js'></script>
<script src='javascript/jquery.wordexport.js'></script>
<script src='javascript/jquery.base64.js'></script>
<script src='javascript/tableexport.js'></script>
<style>div.stdyttl {margin-left: 2em; font-size:medium; font-weight:bold}</style>
<style>span.exprpt {margin-right: 2em; font-size:medium;}</style>
<div id='reportTabs' class='tabbedpanels'> <ul> <li><a href='#MIrptdiv'>Microscopic Findings</a></li>
<li><a href='#MArptdiv'>Macroscopic Findings</a></li> 
<li><a href='#sumrptdiv'>Trial Summary</a></li> </ul>
%mend;


/*
%macro odspostHTML();
%mend;
<script>$function() {$('%#quote(&domain.)tableID').colresizable({liveDrag:true}); }</script>
 POSTHTML removed for now from style body from body /
    POSTHTML="&odspostHTML"
*/
proc template;
define style myfdatmpl;
parent=styles.HTMLBlue;
style body from body /
    PREHTML="%odspreHTML";
end;
run;

ODS TRACE ON;

ODS EXCLUDE SQL_Results;

/* following options probably need to be removed or adjusted */
options label nodate pageno=1 pagesize=60 linesize=72;

*options MPRINT;

%macro createStudyRpt(i);

   /*-- Scan through &&domain.listStudyId to get StudyId value --*/
%let thisStudyId=%scan(&listStudyId,&i);


ODS HTML5 body="&thisStudyId.ReportsBody.html" style=myfdatmpl
path="&htmlfilepath." (url=NONE)
options(outline="false")
;

/*--- following removed from ODS HTML5 statement
frame="FDAreportsFrame.html" 
contents="FDAreportsContents.html" 
*/ 


*ods document name DATA.FDAreportsDoc;

/***************************************************************************************/
/***************************************************************************************/
/*--   MACRO TO  CREATE FINDINGS REPORT HTML FILE for each DOMAIN and each STUDYID   --*/
/***************************************************************************************/
%macro createRpt(domain);

/**************************************************************************************/
/*   LEFT JOIN TO GET htmlfilename FOR HYPERLINK IN DATA _NULL_ create reports        */
/**************************************************************************************/
proc sql;
create table WORK.&domain.countTotalPctTbl as
select distinct a.*, b.mctrlhtml, b.fctrlhtml, b.mlowhtml,
       b.flowhtml, b.mmedhtml, b.fmedhtml, b.mhighhtml, b.fhighhtml
from WORK.&domain.countTotalPct a left join WORK.&domain.lookuphtml1st b
  on a.studyid=b.studyid and a.&domain.spec=b.&domain.spec and a.&domain.orres=b.&domain.orres 
     and a.&domain.sev=b.&domain.sev
     and a.&domain.stresc=b.&domain.stresc and a.&domain.resmod=b.&domain.resmod  ;
quit;

/*-- Sort by order that is needed for creating the reports --*/
proc sort data=WORK.&domain.countTotalPctTbl;
by studyid &domain.spec &domain.orres &domain.stresc &domain.resmod &domain.sev;
run;

proc sql noprint;
select count(distinct &domain.dy) into:uniqueDays from WORK.DM&domain.;
quit;

   /*-- get trendpercent, domainName and domain values --*/
data _null_;
  set WORK.&domain.uniqueStudyId;
  /*-- these have same values for each studyid --*/
  if _n_ = 1 then do;
    call symput("trendpercent",trendpercent);
    call symput("domainName",domainName);
    call symput("domain",domain);
  end;
run;

ods noproctitle;
ods proclabel "&domainName. &thisStudyid. Findings Consolidated View" ;

/* suppress system title at top of report */
title;
 
/*-- include the select list for exporting the table --*/
/*-- begin with a <div> with the ID included in reportTabs for this report --*/
%macro odstextHTML();
<div id='%quote(&domain.)rptdiv' style='display:none'>
<div id='%quote(&domain.)expdiv' class='l header' style='font-size:normal;'> Study ID: &thisStudyID.
 <span class='c header' style='font-size:normal;margin-left:10em;'> &domainName. Findings </span>
 <span class='r header' style='margin-left:72em;' > Export Report: </span> <br /> 
<form id='%quote(&domain.)expForm' name='expForm' class='r header' >
<select id='%quote(&domain.expMenu)' name='expMenu'>
<option></option><option value='ExportExcel'>Export to Excel</option>
<option value='ExportCSV'>Export to CSV</option> 
<option value='ExportWord'>Export to Word</option>
</select></form></div> 
<iframe id='myframe' style='display:none'></iframe>

%mend;
 
ODS TEXT =  "%odstextHTML()"   ;

/* </script>
<option value='ExportXML'>Export to XML</option>
<option value='ExportXPT'>Export to XPT</option>
*/

/*-- Using ODS Report Writing Interface in data _null_
        to output rows as appropriate for the FDA Findings Reports  --*/

data _null_ ;
 
set WORK.&domain.countTotalPctTbl end=eof;

by &domain.spec &domain.orres /*&domain.stresc*/ &domain.resmod &domain.sev;

if _n_ = 1 then do;
    /************************/
	/*-- INITIALIZE SUMS --*/
    /************************/
  controlMSum=0; controlFsum=0; lowDoseMsum=0; lowDoseFsum=0; 
  midDoseMsum=0; midDoseFsum=0; highDoseMsum=0; highDoseFsum=0;
    /*************************************/
    /*-- ODS OUT OBJECT INITIALIZATION --*/
    /*************************************/
  declare odsout tbl(id: "&domain.tableID");

  /* COMMENTING TITLE - it is now in the active tab
  tbl.title(data: "&domainname." || " Findings for Study ID: "  || studyid, 
            style_attr: 'just=left fontsize=19pt fontweight=bold') ;
  */
  tbl.table_start(label: "&domainname." || " Findings for Study ID: " || studyid);

  /************************************************************************/
  /*                         WRITE HEADER ROW                            */
  /************************************************************************/
  tbl.head_start();
   tbl.row_start();
	 tbl.format_cell(data: "Body Tissue", style_attr: "just=C backgroundcolor=lightgray color=black");
     tbl.format_cell(data: "Findings", style_attr: "just=C 
                     backgroundcolor=lightgray color=black");
     tbl.format_cell(data: "Modifiers", style_attr: "just=C 
                     backgroundcolor=lightgray color=black");

/**** highlight right border between Severity and control Males  ****/
     tbl.format_cell(data: "Severity", style_attr: "just=C borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid backgroundcolor=lightgray color=black");
     tbl.format_cell(data: "1: Control #1 Males",
                     style_attr: "just=C backgroundcolor=lightgray color=black");
     tbl.format_cell(data: "3: Low Dose Males",
                     style_attr: "just=C backgroundcolor=lightgray color=black");
     tbl.format_cell(data: "4: Mid Dose Males",
                     style_attr: "just=C backgroundcolor=lightgray color=black");
     tbl.format_cell(data: "5: High Dose Males",
                     style_attr: "just=C backgroundcolor=lightgray color=black borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");

/**** highlight right border between high dose males and control females ****/

     tbl.format_cell(data: "1: Control #1 Females",
                     style_attr: "just=C backgroundcolor=lightgray color=black");
     tbl.format_cell(data: "3: Low Dose Females",
                     style_attr: "just=C backgroundcolor=lightgray color=black");
     tbl.format_cell(data: "4: Mid Dose Females",
                     style_attr: "just=C backgroundcolor=lightgray color=black");
     tbl.format_cell(data: "5: High Dose Females",
                     style_attr: "just=C backgroundcolor=lightgray color=black borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");
 
   tbl.row_end();
  tbl.head_start();

end;    /*-- _n_ = 1 --*/
   
  
if first.&domain.spec then do;

    /*******************************************************************/
    /* Write BODY TISSUE value */
    /*******************************************************************/
    tbl.row_start();
	   tbl.format_cell(data: &domain.spec, style_attr: "color=blue fontweight=bold");
	tbl.row_end();
    /*--   WRITE ROW WITH TISSUE Examined with OTHER VALUES BLANK    --*/
    /*******************************************************************/
    tbl.row_start();
           /*-- blank value for &domain.spec - Tissue --*/
       tbl.format_cell(data: " ", style_attr: "backgroundcolor=lightblue");
           /*-- blank value for &domain.stresc - Findings --*/
       tbl.format_cell(data: " ", style_attr: "backgroundcolor=lightblue");
            /*-- blank value for Modifiers in total line */
       tbl.format_cell(data: " ", style_attr: "backgroundcolor=lightblue");
            /*-- #Examined in the Severity column --*/
       tbl.format_cell(data: "#Examined",
                       style_attr: "just=C backgroundcolor=lightblue borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");       
       tbl.format_cell(data: totalEXMcontrol,
                       style_attr: "just=C backgroundcolor=lightblue");       
       tbl.format_cell(data: totalEXMlow,
                       style_attr: "just=C backgroundcolor=lightblue");       
       tbl.format_cell(data: totalEXMmedium,
                       style_attr: "just=C backgroundcolor=lightblue");       
       tbl.format_cell(data: totalEXMhigh,
                       style_attr: "just=C backgroundcolor=lightblue borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");       
       tbl.format_cell(data: totalEXFControl,
                       style_attr: "just=C backgroundcolor=lightblue");       
       tbl.format_cell(data: totalEXFlow,
                       style_attr: "just=C backgroundcolor=lightblue");       
       tbl.format_cell(data: totalEXFmedium,
                       style_attr: "just=C backgroundcolor=lightblue");       
       tbl.format_cell(data: totalEXfhigh,
                       style_attr: "just=C backgroundcolor=lightblue borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");
    tbl.row_end();
  
end;      /*-- first.&domain.spec --*/

/*******************************************************************/
/*--          WRITE ROW FOR MALE and FEMALE COUNTS               --*/
/*******************************************************************/

tbl.row_start();
        /*-- blank value for &domain.spec - Tissue --*/
   tbl.format_cell(data: " "); 

   tbl.format_cell(data: &domain.orres, style_attr: "just=C");
   tbl.format_cell(data: &domain.resmod, style_attr: "just=C");
   tbl.format_cell(data: &domain.sev, style_attr: "just=C borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");

   thisDomain="&domain.";
   if pctMControl > &trendPercent. then   
	 tbl.format_cell(data: "<a href='javascript:processFindings(" || '"findings", "' || 
           trim(Mctrlhtml) || '", "' || trim(studyid) || '", "' || "&domain." || '", ' || 
           &uniqueDays. || ");'>" || countMControl || '</a>' ,
           style_attr: "just=C backgroundcolor=dodgerblue color=blue");    
  else
     tbl.format_cell(data: countMControl);

   if pctMlow > &trendPercent. then 
     tbl.format_cell(data: "<a href='javascript:processFindings(" || '"findings", "' || 
            trim(Mlowhtml) || '", "' ||
                     trim(studyid) || '", "' || "&domain." || '", ' || &uniqueDays. || ");'>"  
                     || countMlow || '</a>' ,  
                     style_attr: "just=C backgroundcolor=dodgerblue color=blue");
   else
     tbl.format_cell(data: countMlow);
   if pctMmedium > &trendPercent. then       
     tbl.format_cell(data: "<a href='javascript:processFindings(" || '"findings", "' || 
            trim(Mmedhtml) || '", "' ||
                     trim(studyid) || '", "' || "&domain." || '", ' || &uniqueDays. || ");'>"  
                     || countMmedium || '</a>' , 
                     style_attr: "just=C backgroundcolor=dodgerblue color=blue");
   else
     tbl.format_cell(data: countMmedium);
   if pctMhigh > &trendPercent. then 
     /*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
     /** need to get the following syntax correct so there can be one set of javascript code for the functions **/
 	 /*tbl.format_cell(data: '<a href="JavaScript: onClick=openTrend(' || trim(Mhighhtml) || ".html," ||
                                trim(Mhighhtml) || ');">' || countMhigh || '</a>' ,*/
     /*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/    
	 tbl.format_cell(data: "<a href='javascript:processFindings(" || '"findings", "' || 
           trim(Mhighhtml) || '", "' ||
                     trim(studyid) || '", "' || "&domain." || '", ' || &uniqueDays. || ");'>"  
                     || countMhigh || '</a>' ,
                    style_attr: "just=C backgroundcolor=dodgerblue color=blue borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid"  );   
   else
     tbl.format_cell(data: countMhigh, style_attr: " borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");
   if pctFControl > &trendPercent. then       
     tbl.format_cell(data: "<a href='javascript:processFindings(" || '"findings", "' || 
            trim(Fctrlhtml) || '", "' ||
                     trim(studyid) || '", "' || "&domain." || '", ' || &uniqueDays. || ");'>"  
                     || countFcontrol || '</a>' ,
                     style_attr: "just=C backgroundcolor=dodgerblue");        
   else
     tbl.format_cell(data: countFControl);
   if pctFlow > &trendPercent. then                
     tbl.format_cell(data: "<a href='javascript:processFindings(" || '"findings", "' || 
           trim(Flowhtml) || '", "' ||
                     trim(studyid) || '", "' || "&domain." || '", ' || &uniqueDays. || ");'>"  
                     || countFlow || '</a>' , 
                     style_attr: "just=C backgroundcolor=dodgerblue color=blue");
   else
     tbl.format_cell(data: countFlow);
   if pctFmedium > &trendPercent. then 
     tbl.format_cell(data: "<a href='javascript:processFindings(" || '"findings", "' || 
            trim(Fmedhtml) || '", "' ||
                     trim(studyid) || '", "' || "&domain." || '", ' || &uniqueDays. || ");'>"  
                     || countFmedium || '</a>' ,  
                     style_attr: "just=C backgroundcolor=dodgerblue color=blue");
   else
     tbl.format_cell(data: countFmedium);
   if pctFhigh > &trendPercent. then 
     tbl.format_cell(data: "<a href='javascript:processFindings(" || '"findings", "' || 
            trim(Fhighhtml) || '", "' ||
                     trim(studyid) || '", "' || "&domain." || '", ' || &uniqueDays. || ");'>"  
                     ||  countFhigh || '</a>' ,
                     style_attr: "just=C 
                     backgroundcolor=dodgerblue color=blue borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");
   else
     tbl.format_cell(data: countFhigh, style_attr: " borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");
tbl.row_end();


/**************************************************************************/
/*-- ADD VALUES to TOTAL/SUM for SPECIMEN MATERIAL TYPE / FINDINGS      --*/
/**************************************************************************/
controlMsum=countMControl + controlMsum; 
controlFsum=countFControl + controlFsum; 
lowDoseMsum=countMLow + lowDoseMsum; 
lowDoseFsum=countFLow + lowDoseFsum; 
midDoseMsum=countMMedium + midDoseMsum; 
midDoseFsum=countFMedium + lowDoseFsum;
highDoseMsum=countMHigh + highDoseMsum; 
highDoseFsum=countFHigh + highDoseFsum; 


if last.&domain.spec OR last.&domain.orres OR last.&domain.sev then do;
 
  /************************************************************/
  /*-- WRITE TOTAL LINE FOR PREVIOUS BODY SYSTEM / FINDINGS --*/
  /************************************************************/
  tbl.row_start();
            /*-- blank value for Tissue in total line */
       tbl.format_cell(data: " ",  /* need to set formatting for size */
                       style_attr: "backgroundcolor=lightgray");
            /*-- Findings --*/
       tbl.format_cell(data: &domain.orres,
                         style_attr: "just=C backgroundcolor=lightgray");
            /*-- blank value for Modifiers in total line */
       tbl.format_cell(data: &domain.resmod,
                         style_attr: "backgroundcolor=lightgray");
            /*-- Total in the Severity column --*/
       tbl.format_cell(data: "Total", style_attr: "just=C 
                       fontweight=bold backgroundcolor=lightgray color=blue borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");       
       tbl.format_cell(data: controlMSum, style_attr: "just=C 
                       backgroundcolor=lightgray color=blue");       
       tbl.format_cell(data: lowDoseMSum, style_attr: "just=C 
                       backgroundcolor=lightgray color=blue");        
       tbl.format_cell(data: midDoseMSum, style_attr: "just=C 
                       backgroundcolor=lightgray color=blue");        
       tbl.format_cell(data: highDoseMSum, style_attr: "just=C 
                       backgroundcolor=lightgray color=blue borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");       
       tbl.format_cell(data: controlFSum, style_attr: "just=C 
                       backgroundcolor=lightgray color=blue");       
       tbl.format_cell(data: lowDoseFSum, style_attr: "just=C 
                       backgroundcolor=lightgray color=blue");        
       tbl.format_cell(data: midDoseFSum, style_attr: "just=C 
                       backgroundcolor=lightgray color=blue");        
       tbl.format_cell(data: highDoseFSum, style_attr: "just=C 
                       backgroundcolor=lightgray color=blue borderrightwidth=1pt
	                 borderrightcolor=black borderrightstyle=solid");  
    tbl.row_end();
 
      /*-- Reset total variable values --*/
    controlMSum=0; controlFsum=0; lowDoseMsum=0; lowDoseFsum=0; 
    midDoseMsum=0; midDoseFsum=0; highDoseMsum=0; highDoseFsum=0;   

end;     /*-- last.&domain.dy OR last.&domain.spec OR last.&domain.orres OR last.&domain.sev --*/

if eof then do;
  tbl.table_end();
end;

/**************************************************************************/
/*-- RETAIN ONGOING TOTALS/SUMS FOR SPECIMEN MATERIAL TYPE AND FINDINGS --*/
/**************************************************************************/
retain controlMsum controlFsum lowDoseMsum lowDoseFsum midDoseMsum
       midDoseFsum highDoseMsum highDoseFsum     ;

WHERE studyid = "&thisStudyid.";

run;

/*-- close the &domain.rptdiv <div> --*/
ODS TEXT = "</div>";

%mend createRpt;

%createRpt(domain=MI);
%createRpt(domain=MA);


/********************************************************************************/
/******************************************************************************** 
         ***-- TRIAL SUMMARY REPORT --***
Create data for building Trial Summary report from SEND data
*********************************************************************************/
/********************************************************************************/

        /*-- COLUMNS/DATA required -- 
Study ID, Study Title, Study Type, Investigational Therapy or Treatment,
Treatment Vehicle, Route of Administration, Doses, Dosing Duration,
Time to Interim Sacrifice, Time to Terminal Sacrifice, Study Start Date
Study End Date, Experimental Start Date, Experimental End Date,,
Sponsor's Group Label, Number/Sex/Group, Species, Strain/Substrain
      -------------------------------*/

/*********************************************************/
/*-- GET COUNTS for EACH SEX & GROUP from DEMOGRAPHICS --*/
/**********************************************************/ 
proc sql;
create table WORK.TSdmCounts as
select studyid, sex, setcd, count(*) as groupCount
from SEND.DM
group by studyid, sex, setcd;
quit;
proc sql;
create table WORK.TSgroupCounts as
select studyid, sex, setcd, groupCount,
       case when sex='F' then 'Female'
            when sex='M' then 'Male'
            else 'Unknown' end as sexText,
       trim(left(put(groupCount,8.))) || '/' || trim(calculated sexText) || '/Group' || setcd as groupCountTxt
from WORK.TSdmCounts
order by studyid, setcd, sex;
quit;

/*********************************************************/
/*--           GET UNIQUE DOSES IN STUDY               --*/
/*-- from TRIAL SETS (TX) Domain by studyid and setcd  --*/
/*********************************************************/ 
proc sort data=SEND.TX out=sortedTX;
by studyid setcd;
run;

data WORK.TStxCombined(keep=studyid setcd groupLabel groupCode doses);
set sortedTX;
BY STUDYID SETCD;
length studyid $7 setcd $2 groupLabel $15 groupCode $15 doses $15 thisDose $15 thisDoseUnit $15
       thisGroupLbl $15 thisGroupCd $15;
select(trim(upcase(txparmcd)));
  when ('TRTDOS') thisDose=txval;
  when ('TRTDOSU') thisDoseUnit=txval;
  when ('GRPLBL') thisGroupLbl=txval;
  when ('SPGRPCD') thisGroupCd=txval;
  otherwise;
end;

if last.studyid OR last.setcd then do;
  groupLabel=thisGroupLbl; groupCode=thisGroupCd;
  doses=trim(thisDose) || ' ' || trim(thisDoseUnit);
  OUTPUT;
end;
retain thisDose thisDoseUnit thisGroupLbl thisGroupCd;
run; 

/***********************************************************/
/*--    JOIN GROUP COUNTS with GROUP LABEL and DOSES     --*/
/***********************************************************/
proc sql;
create table WORK.TSgroupLblDoses as
select a.studyid label='Study ID', a.setcd, 
       a.groupCountTxt label='Number/Sex/Group', 
       b.groupLabel label="Sponsor's Group Label", 
       b.doses label='Doses'
from WORK.TSgroupCounts a, WORK.TStxCombined b
where a.studyid=b.studyid and a.setcd=b.setcd;
quit;


/*********************************************************/
/*--     GET TRIAL SUMMARY VALUES for STUDY            --*/
/*********************************************************/
data WORK.tsCombined(keep=studyid studyTitle studyType treatment 
                     trtVehicle route intsac trmsac dosduration
                     ststdtc stendtc expstdtc expendtc
                     species strain);

label studyid='Study ID' studyTitle='Study Title' studyType='Study Type'
      treatment='Investigational Therapy or Treatment'
      trtVehicle='Treatment Vehicle' route='Route of Administration'
      intsac='Time to Interim Sacrifice' trmsac='Time to Terminal Sacrifice'
      ststdtc='Study Start Date' stendtc='Study End Date'
      expstdtc='Experimental Start Date'
      expendtc='Experimental End Date' dosduration='Dose Duration'
      species='Species' strain='Strain/Substrain';

set SEND.TS;
by studyid;

select (upcase(tsparmcd));
  when ('STITLE') thisstudyTitle=tsval;
  when ('SSTYP') thisstudytype=tsval;
  when ('TRT') thistreatment=tsval;
  when ('TRTV') thistrtVehicle=tsval;
  when ('ROUTE') thisroute=tsval;
  when ('INTSAC') thisintsac=tsval;
  when ('TRMSAC') thistrmsac=tsval;
  when ('STSTDTC') thisststdtc=tsval;
  when ('STENDTC') thisstendtc=tsval;
  when ('EXPSTDTC') thisexpstdtc=tsval;
  when ('EXPENDTC') thisexpendtc=tsval;
  when ('DOSDUR') thisdosduration=tsval;
  when ('SPECIES') thisspecies=tsval;
  when ('STRAIN') thisstrain=tsval;
  otherwise;
end;

if last.studyid then do;
   studyTitle=thisStudyTitle; studyType=thisStudytype; treatment=thisTreatment;
   trtVehicle=thistrtVehicle; route=thisRoute; intsac=thisintsac; trmsac=thistrmsac;
   ststdtc=thisststdtc; stendtc=thisststdtc; expstdtc=thisexpstdtc; expendtc=thisexpendtc; 
   dosduration=thisdosduration; species=thisspecies; strain=thisstrain;
   output;
end;

retain thisStudyTitle thisStudyType thisTreatment thistrtVehicle thisRoute thisintsac
       thistrmsac thisststdtc thisstendtc thisexpstdtc thisexpendtc thisdosduration 
       thisspecies thisstrain;

run;

/***********************************************************************/
/*--    JOIN GROUP LABEL, DOSES and GROUP COUNTS with TS values      --*/
/***********************************************************************/
proc sql;
create table WORK.TSjoinTSTX as
select a.*, b.*
from WORK.tsCombined a, WORK.TSgroupLblDoses b
where a.studyid=b.studyid
order by a.studyid, b.setcd;
quit;

    /*****************************************************/
    /*-- transpose to get Doses and Counts in same row --*/
    /*****************************************************/

proc sort data=WORK.TSjointstx;
by studyid studyTitle studyType treatment trtVehicle route intsac trmsac ststdtc stendtc 
   expstdtc expendtc dosduration species strain;
run;
proc sql;
create table tsuniquedose as
select distinct studyid, studytitle, studytype, treatment, trtvehicle, route, intsac, trmsac,
       ststdtc, stendtc, expstdtc, expendtc, dosduration, species, strain, doses
from WORK.TSjoinTSTX;
quit;
proc transpose data=tsuniquedose out=WORK.TSTXdose prefix=DOSE;
  by studyid studyTitle studyType treatment trtVehicle route intsac trmsac ststdtc stendtc 
     expstdtc expendtc dosduration species strain;
  var Doses ;
run;
proc sql;
create table tsuniquegrplbl as
select distinct studyid, studytitle, studytype, treatment, trtvehicle, route, intsac, trmsac,
       ststdtc, stendtc, expstdtc, expendtc, dosduration, species, strain, grouplabel
from WORK.TSjoinTSTX;
quit;
proc transpose data=tsuniquegrplbl out=WORK.TSTXgrpLbl prefix=GRPLBL;
  by studyid studyTitle studyType treatment trtVehicle route intsac trmsac ststdtc stendtc 
     expstdtc expendtc dosduration species strain;
  var grouplabel ;
run;
proc sql;
create table tsuniquegrpcount as
select distinct studyid, studytitle, studytype, treatment, trtvehicle, route, intsac, trmsac,
       ststdtc, stendtc, expstdtc, expendtc, dosduration, species, strain, groupcounttxt
from WORK.TSjoinTSTX;
quit;
proc transpose data=WORK.TSjoinTSTX out=WORK.TSTXgrpCount prefix=GRPCOUNT;
  by studyid studyTitle studyType treatment trtVehicle route intsac trmsac ststdtc stendtc 
     expstdtc expendtc dosduration species strain;
  var groupCounttxt ;
run;

data WORK.TStxall;
merge WORK.TStxdose(drop=_name_) WORK.TStxgrplbl(drop=_name_) WORK.TStxgrpcount(drop=_name_);
  by studyid studyTitle studyType treatment trtVehicle route intsac trmsac ststdtc stendtc 
     expstdtc expendtc dosduration species strain;
run;


/***************************************************************/
/* make number of Doses and group Label/Counts configurable by
   determining how many for each and using macro variable in a  
   DO loop that writes the rows for both                       */ 
/***************************************************************/

%global numDoses numGrpLbl numGrpCount;

proc sql noprint;
       /*-- DOSES --*/
select count(*) into:numDoses from DICTIONARY.COLUMNS
where upcase(libname)='WORK' and upcase(memname)='TSTXALL' and upcase(name) like 'DOSE%';
       /*-- GROUP LABELS --*/
select count(*) into:numGrpLbl from DICTIONARY.COLUMNS
where upcase(libname)='WORK' and upcase(memname)='TSTXALL' and upcase(name) like 'GRPLBL%';
       /*-- GROUP COUNTS --*/
select count(*) into:numGrpCount from DICTIONARY.COLUMNS
where upcase(libname)='WORK' and upcase(memname)='TSTXALL' and upcase(name) like 'GRPCOUNT%';
quit;


           /******************************************/
           /*  BEGIN CREATING THE HTML (ODS) OUTPUT  */
           /******************************************/

/* Trial Summary Report */
%macro createTrialSummary();

ods noproctitle;
ods proclabel "Trial Summary";

/*-- include the select list for exporting the table --*/
/*-- begin with the report division ID needed for the tab --*/
%macro odstextHTML();
<div id='sumrptdiv'>
<br /><br /><div id='sumexpdiv' align='left' class='c header'> Study ID: &thisStudyID. 
  <span style='margin-left:60em;'> Export Report:</span> <b /> 
<form id='sumexpform' name='expForm'><select id='sumexpmenu' name='expMenu' style='margin-left:70em;'>
<option></option><option value='ExportExcel'>Export to Excel</option>
<option value='ExportCSV'>Export to CSV</option> 
<option value='ExportWord'>Export to Word</option>
</select></form> </div>
<script src='javascript/FDAscripts.js'> </script>
<iframe id='myframe' style='display:none'></iframe>
<script>$(window).load(function() { var ourtable = $('#sumrptdiv').find('table')[0];
  $(ourtable).attr('id','#sumtableID')});</script>
%mend;
/* removed for now from odstextHTML 
<option value='ExportXML'>Export to XML</option>
<option value='ExportXPT'>Export to XPT</option>
*/
 
ODS TEXT =  "%odstextHTML()"   ;

data _null_;

set WORK.TStxall end=eof;
by studyid;

if _N_ = 1 then do;
  declare odsout tbl();
/*   COMMENTING TITLE - IT IS NOW IN THE TAB
tbl.title(data: 'Study ID: '  || studyid, 
      style_attr: "just=L fontweight=bold just=left fontsize=12pt" );
*/
tbl.table_start(label: 'Study ID: ' || studyid || '  Trial Summary');
  tbl.row_start();
    tbl.format_cell(data: "Trial Summary ", style_attr: "just=left fontweight=bold fontsize=11pt backgroundcolor=silver",
    column_span: 2);
  tbl.row_end();
  tbl.row_start();
    tbl.format_cell(data: " ");
  tbl.row_end();

tbl.row_start();
  tbl.format_cell(data: 'Study Title', style_attr: 'just=L backgroundcolor=silver');
  tbl.format_cell(data: studyTitle, style_attr: "just=left");
tbl.row_end();

tbl.row_start();
  tbl.format_cell(data: 'Study Type', style_attr: 'just=L backgroundcolor=silver');
  tbl.format_cell(data: studyType, style_attr: "just=left");
tbl.row_end();

tbl.row_start();
  tbl.format_cell(data: 'Investigational Therapy or Treatment', style_attr: 'just=L backgroundcolor=silver');
  tbl.format_cell(data: Treatment, style_attr: "just=left");
tbl.row_end();

tbl.row_start();
  tbl.format_cell(data: 'Treatment Vehicle', style_attr: 'just=L backgroundcolor=silver');
  tbl.format_cell(data: trtVehicle, style_attr: "just=left");
tbl.row_end();

tbl.row_start();
  tbl.format_cell(data: 'Route of Administration', style_attr: 'just=L backgroundcolor=silver');
  tbl.format_cell(data: route, style_attr: "just=left");
tbl.row_end();

end;  /*-- _n_ = 1 --*/

%do x = 1 %to &numDoses.;
  tbl.row_start();
    if &x = 1 then
	  tbl.format_cell(data: 'Doses', style_attr: 'just=L backgroundcolor=silver');
	else 
	  tbl.format_cell(data: ' ', style_attr: 'backgroundcolor=silver');
	tbl.format_cell(data: Dose&x, style_attr: "just=left");
  tbl.row_end();
%end; /* do x to number of Doses */

	tbl.row_start();
	  tbl.format_cell(data: 'Dose Duration', style_attr: 'just=L backgroundcolor=silver');
	  tbl.format_cell(data: dosDuration, style_attr: "just=left");
	tbl.row_end();

	tbl.row_start();
	  tbl.format_cell(data: 'Time to Interim Sacrifice', style_attr: 'just=L backgroundcolor=silver');
	  tbl.format_cell(data: intsac, style_attr: 'just=L');
	tbl.row_end();

	tbl.row_start();
	  tbl.format_cell(data: 'Time to Terminal Sacrifice', style_attr: 'just=L backgroundcolor=silver');
	  tbl.format_cell(data: trmsac, style_attr: 'just=L');
	tbl.row_end();

	tbl.row_start();
	  tbl.format_cell(data: 'Study Start Date', style_attr: 'just=L backgroundcolor=silver');
	  tbl.format_cell(data: ststdtc, style_attr: 'just=L');
	tbl.row_end();

	tbl.row_start();
	  tbl.format_cell(data: 'Study End Date', style_attr: 'just=L backgroundcolor=silver');
	  tbl.format_cell(data: stendtc, style_attr: 'just=L');
	tbl.row_end();

	tbl.row_start();
	  tbl.format_cell(data: 'Experimental Start Date', style_attr: 'just=L backgroundcolor=silver');
	  tbl.format_cell(data: expstdtc, style_attr: 'just=L');
	tbl.row_end();

	tbl.row_start();
	  tbl.format_cell(data: 'Experimental End Date', style_attr: 'just=L backgroundcolor=silver');
	  tbl.format_cell(data: expendtc, style_attr: 'just=L');
	tbl.row_end();

%do x = 1 %to &numGrpLbl.;
		  tbl.row_start();
		    if &x = 1 then
		      tbl.format_cell(data: 'Sponsor"s Group Label', style_attr: 'just=L backgroundcolor=silver');
		    else 
		      tbl.format_cell(data: ' ', style_attr:'backgroundcolor=silver');
		    tbl.format_cell(data: GrpLbl&x, style_attr: 'just=L');
		  tbl.row_end();
%end;

%do x = 1 %to &numGrpCount.;
	  tbl.row_start();
	    if &x = 1 then
	      tbl.format_cell(data: 'Number/Sex/Group', style_attr: 'just=L backgroundcolor=silver');
	    else 
	      tbl.format_cell(data: ' ', style_attr: 'just=L backgroundcolor=silver');
	    tbl.format_cell(data: GrpCount&x, style_attr: 'just=L');
	  tbl.row_end();
%end;
 
	tbl.row_start();
	  tbl.format_cell(data: 'Species', style_attr: 'just=L backgroundcolor=silver');
	  tbl.format_cell(data: species, style_attr: 'just=L');
	tbl.row_end();

	tbl.row_start();
	  tbl.format_cell(data: 'Strain/Substrain', style_attr: 'just=L backgroundcolor=silver');
	  tbl.format_cell(data: strain, style_attr: 'just=L');
	tbl.row_end();
 
if eof then do;
  tbl.table_end();
end;

run;
%mend;

%createTrialSummary();


/*-- close the division for ID=reportTabs and for Trial Summary report --*/
ODS TEXT = "</div></div> ";


/************************************************************************************
3) Labs/Body Weights/Food Consumption

a.	Compare treatment vs controls
b.	Needs to be able to exlude data points
c.	Needs to be able to club custom groups as control
d.	Tabular with bar-graphs, whisker plots, forrest plots.
*************************************************************************************/

ODS TRACE OFF;

ods document close;
ods _all_ close;

%mend createStudyRpt;

   /****************************************************************/
    /*-- Enumerate STUDYID list and put list into macro variable  --*/
    /****************************************************************/
proc sql noprint;
select count(*) into:numStudyId from WORK.MIuniqueStudyId;
select studyId into:listStudyId separated by ' ' from WORK.MIuniqueStudyId;
quit;
 

  /*********************************************************/
  /*-- Macro for looping through studyId report creation --*/
  /*********************************************************/
%macro loopIMI();
  %do j=1 %to &numStudyId.;
    %createStudyRpt(i=&j);
  %end;
%mend;

%loopIMI();
