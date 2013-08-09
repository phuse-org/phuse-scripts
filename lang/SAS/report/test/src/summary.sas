libname phuse xport
"http://phusescripts.googlecode.com/svn/trunk/lang/R/report/test/data/adsl.xpt" ;

data work.adsl ;
  set phuse.adsl ;
  run ;
  
proc means data=work.adsl ;
  var age ;
  run ;
