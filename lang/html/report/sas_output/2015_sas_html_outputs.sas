
%LET outdir = /by-sasp/patdb/projects/bsp_test/000000/stat/test_sas92_katja/results;

data grocery;
   input Sector $ Manager $ Department $ Sales @@;
   datalines;
se 1 np1 50    se 1 p1 100   se 1 np2 120   se 1 p2 80
se 2 np1 40    se 2 p1 300   se 2 np2 220   se 2 p2 70
nw 3 np1 60    nw 3 p1 600   nw 3 np2 420   nw 3 p2 30
nw 4 np1 45    nw 4 p1 250   nw 4 np2 230   nw 4 p2 73
nw 9 np1 45    nw 9 p1 205   nw 9 np2 420   nw 9 p2 76
sw 5 np1 53    sw 5 p1 130   sw 5 np2 120   sw 5 p2 50
sw 6 np1 40    sw 6 p1 350   sw 6 np2 225   sw 6 p2 80
ne 7 np1 90    ne 7 p1 190   ne 7 np2 420   ne 7 p2 86
ne 8 np1 200   ne 8 p1 300   ne 8 np2 420   ne 8 p2 125
;

proc format;
   value $sctrfmt 'se' = 'Southeast'
                  'ne' = 'Northeast'
                  'nw' = 'Northwest'
                  'sw' = 'Southwest';

   value $mgrfmt '1' = 'Smith'   '2' = 'Jones'
                 '3' = 'Reveiz'  '4' = 'Brown'
                 '5' = 'Taylor'  '6' = 'Adams'
                 '7' = 'Alomar'  '8' = 'Andrews'
                 '9' = 'Pelfrey';

   value $deptfmt 'np1' = 'Paper'
                  'np2' = 'Canned'
                  'p1'  = 'Meat/Dairy'
                  'p2'  = 'Produce';
run;

options NODATE NONUMBER;
TITLE FOOTNOTE;


ODS HTML FILE="&outdir/example1.html" STYLE=Barrettsblue;
proc report data=grocery nowd;
   column manager department sales;
   rbreak after / dol summarize;
   where sector='se';
   format manager $mgrfmt. department $deptfmt.
          sales dollar11.2;
   title 'Sales for the Southeast Sector';
   title2 "for &sysdate";
run;
ODS HTML CLOSE;


ODS HTML FILE="&outdir/example2.html" STYLE=Barrettsblue;
proc report data=grocery nowd headline headskip;
   column manager department sales
          sales=salesmin
          sales=salesmax;
   define manager / order
                    order=formatted
                    format=$mgrfmt.
                    'Manager';
   define department    / order
                    order=internal
                    format=$deptfmt.
                    'Department';

   define sales / analysis sum format=dollar7.2 'Sales';
   define salesmin / analysis min noprint;
   define salesmax / analysis max noprint;
   compute after;
      line @7 'Departmental sales ranged from'
           salesmin dollar7.2  +1 'to' +1 salesmax dollar7.2
           '.';
   endcomp;
   where sector='se';
   title 'Sales for the Southeast Sector';
   title2 "for &sysdate";
run;
ODS HTML CLOSE;


ODS HTML FILE="&outdir/example3.html" STYLE=Barrettsblue;
proc report data=grocery nowd headline headskip
            ls=66 ps=18;
    column sector manager (Sum Min Max Range Mean Std),sales;
   define manager / group format=$mgrfmt. id;
   define sector / group format=$sctrfmt.;
   define sales / format=dollar11.2 ;
   title 'Sales Statistics for All Sectors';
run;
ODS HTML CLOSE;

ODS HTML FILE="&outdir/example4.html" STYLE=Barrettsblue;
proc report data=grocery nowd headline;
   title;
   column ('Individual Store Sales as a Percent of All Sales'
            sector manager sales,(sum pctsum) comment);
   define manager / group
                    format=$mgrfmt.;
   define sector / group
                   format=$sctrfmt.;
   define sales / format=dollar11.2
                  '';
   define sum / format=dollar9.2
                'Total Sales';
   define pctsum / 'Percent of Sales' format=percent6. width=8;
   define comment / computed width=20 '' flow;
   compute comment / char length=40;
      if sales.pctsum gt .15 and _break_ = ' '
      then comment='Sales substantially above expectations.';
      else comment=' ';
   endcomp;
   rbreak after / ol summarize;
run;
ODS HTML CLOSE;


ODS HTML FILE="&outdir/example5.html" STYLE=Barrettsblue;
proc report data=grocery nowd headline
            formchar(2)='~'
            panels=99 pspace=6
            ls=64 ps=18;
   column manager department sales;
   define manager / order
                    order=formatted
                    format=$mgrfmt.;
   define department / order
                 order=internal
                 format=$deptfmt.;
   define sales / format=dollar7.2;
   break after manager / skip;
   where sector='nw' or sector='sw';
   title 'Sales for the Western Sectors';
run;
ODS HTML CLOSE;