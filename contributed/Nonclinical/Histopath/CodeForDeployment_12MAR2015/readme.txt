*The following two SAS programs are in this deployment. 

STEP 1 - SAS script Create JSON Findings - by males and females
STEP 2 - STEP 2 - SAS code - Write Findings_TrialSummary to HTML5

*The SEND SAS library is assigned in both programs.

Modify the send libname path in each program to the file path where your study data resides.

libname SEND 'd:\send\data\sas data';   /*-- contains SEND test data tables / STUDY DATA --*/
                                             

SAS script Create JSON Findings - by males and females
This script must be run for each study before STEP 2 SAS code program is run.
It generates work tables and the .json file needed by step 2 for building the html file for the study.
It contains a macro variable %let statement following the send libname.
You need to modify the path in the %let statement to the file path where you will write the html file.

/*!!!!!!!!   SET THE FOLLOWING to the file path where you have     !!!!!!!!*/
/*!!!!!!!!   .html file(s) and javascript and css subolders        !!!!!!!!*/
%let jsonFilePath=D:\SEND\FDAProjectFiles\codefordeployment_12Mar2015\;

The subfolders css and javascript should be placed in the same folder.

This SAS script and the css and javascript subfolders can be provided to users to place in a folder
on their local machine. The folder can be named anything, but the css and javascript subfolders should
not be renamed. 

When you email an html file(s) generated with step 1 and 2 above, the users can run the SAS script
to generate their local .json file for the study(s).

STEP 2 - SAS code - Write Findings_TrialSummary to HTML5
This SAS program will be run one time after running step 1 above to generate the .html file for the study(s).
It contains a macro variable %let statement that sets the file path for ODS to write the .html file.
/*!!!!!!!!   SET THE FOLLOWING to the file path where you have     !!!!!!!!*/
/*!!!!!!!!   .html file(s) and javascript and css subolders        !!!!!!!!*/
     /***************************************/
     /* PATH to write  HTML file of reports */
     /***************************************/
%let htmlFilePath=D:\SEND\FDAProjectFiles\codefordeployment_12Mar2015\;

The step 2 SAS program also contains a %let statement for the trend percent so you can modify if needed.
The current setting is .2
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
    /*-- trendPercent is configurable, reset below if needed --*/
%let trendPercent=.2;


To open the reports after SAS script(s) have been run:
Open the html file named the studyid + ReportBody.html in the folder for htmlFilePath / jsonFilePath. 
This will display the reports for the particular study in tabs.

The word export uses the jquery.wordexport plugin for Firefox and other non-IE browsers. For IE, the <div> id
for the report is used to create a range and select the report, then the ActiveXObject Word.Application is
used to paste the report into word. This may take a bit between the word doc opening and the report displaying.
There is a check to see if the browser supports the execcommand Copy for the range object. 
A message displays to let the user know that if the report does not copy they can right click on the
highlighted report in the web page and paste it into the open word doc, then save the doc with the name
and to their specific location.

css subfolder contains jquery, custom and plugin styles;
javascript subfolder contains jquery, custom and plugin .js files; tableexport and colresizable plugins
are included - these were not successful in the development environment, but are included in case they
can be successful in later development.

FDAscripts.js, FDAdrilldown.js and FDAdrillusubj.js contain custom code written specifically for the 
web page reports.

HTML5 is the html used and SAS ODS report writing interface generates the report html. There is custom 
html5/jquery code included in PREHTML and ODS Text to complete the requirements.