/*
Description: Test2
*/
filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adsl.xpt" ;
libname source xport ;

data work.adsl ;
  set source.adsl ;
  keep usubjid ;
run ;

proc print data=work.adsl ;
  title1 "A test of accessing datasets from the PhUSE Code Repository" ;
  run ;
  