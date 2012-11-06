** perform analysis on age **;
libname ds_in "C:\Documents and Settings\C035271\Desktop\FDA_Phuse WG5\Draft Examples\ADaM";

options orientation=portrait;
ods rtf file='C:\Documents and Settings\C035271\Desktop\FDA_Phuse WG5\Draft Examples\age_analysis.rtf';
  proc tabulate data=ds_in.adsl;
  	  class trt01p;
  	  var   age;
  	  table (age='Age (Days)'*(n mean std mode min q1 median q3 max)),
  	        (trt01p='Treatment Group' all='Total')
  	        / misstext='0' printmiss;
  	  title 'Summary of Age';

  proc tabulate data=ds_in.adsl;
  	  class trt01p lastdisp;
  	  var   age;
  	  table (lastdisp='Disposition'*(age='Age (Days)'*(n mean std mode min q1 median q3 max))),
  	        (trt01p='Treatment Group' all='Total')
  	        / misstext='0' printmiss;
  	  title 'Summary of Age by Last Disposition';
  run;
ods rtf close;
