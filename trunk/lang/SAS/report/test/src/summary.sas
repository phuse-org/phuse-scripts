filename source url "http://phuse-scripts.googlecode.com/svn/trunk/lang/R/report/test/data/adsl.xpt" ;
libname source xport ;

data work.adsl ;
  set source.adsl ;
  run ;
  
proc means data=adsl ;
  var age bmibl heightbl weightbl ;
  title1 "Summary Statistics of Key Continuous Variables" ;
  run ;

proc freq data=adsl ;
  tables dcdecod dcreascd ;
  title1 "Summary Statistics of Key Discrete Variables" ;
  run ;
