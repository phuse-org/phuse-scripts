/***
  NB: Specify LRECL = 32767 in FILENAME statement to override default of 256, which leads to problems
    http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000308090.htm
      (see LRECL restriction on page above)
    http://support.sas.com/documentation/cdl/en/hostwin/63285/HTML/default/viewer.htm#chfnoptfmain.htm
      (Win  - default LRECL is 256 for FILENAME)
    http://support.sas.com/documentation/cdl/en/hostunx/61879/HTML/default/viewer.htm#chfnoptfmain.htm
      (UNIX - default LRECL is 256 for FILENAME)

  Otherwise, imported data seem fine:

    6248 rows created in WORK.LB from
    C:\CSS\phuse-scripts\data\Tabulations\SDTM - Statin Test Data v0\lb.csv.
    NOTE: WORK.LB data set was successfully created.o
***/

FILENAME PHUSECSV URL 
         "https://github.com/phuse-org/phuse-scripts/raw/master/data/Tabulations/SDTM%20-%20Statin%20Test%20Data%20v0/lb.csv"
         LRECL = 32767;

PROC IMPORT OUT= WORK.lb
            DATAFILE= PHUSECSV
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2;
RUN;
