** perform analysis on agegroups **;
libname ds_in "C:\Documents and Settings\C035271\Desktop\FDA_Phuse WG5\Draft Examples\ADaM";

options orientation=portrait;
ods rtf file='C:\Documents and Settings\C035271\Desktop\FDA_Phuse WG5\Draft Examples\agegroup_analysis.rtf';
  proc tabulate data=ds_in.adsl;
  	  class trt01p agegr1;
  	  table (agegr1='Age Category' all='Total'),
  	        ((trt01p='Treatment Group' all='Total')*(n='n' colpctn='%'*f=5.1))
  	        / misstext='0' printmiss;
  	  title 'Summary of Age Categories';
  proc tabulate data=ds_in.adsl;
  	  class trt01p agegr1 lastdisp;
  	  table ((lastdisp='Disposition' all='Total')*(agegr1='Age Category' all='Total')),
  	        ((trt01p='Treatment Group' all='Total')*(n='n' colpctn='%'*f=5.1))
  	        / misstext='0' printmiss;
  	  title 'Summary of Age Categories by Last Disposition';
  run;
ods rtf close;
