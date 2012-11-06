** perform analysis on race **;
libname ds_in "C:\Documents and Settings\C035271\Desktop\FDA_Phuse WG5\Draft Examples\ADaM";

options orientation=portrait;
ods rtf file='C:\Documents and Settings\C035271\Desktop\FDA_Phuse WG5\Draft Examples\race_analysis.rtf';
  proc tabulate data=ds_in.adsl;
  	  class trt01p race;
  	  table (race='Race' all='Total'),
  	        ((trt01p='Treatment Group' all='Total')*(n='n' colpctn='%'*f=5.1))
  	        / misstext='0' printmiss;
  	  title 'Summary of Race';
  proc tabulate data=ds_in.adsl;
  	  class trt01p race lastdisp;
  	  table ((lastdisp='Disposition' all='Total')*(race='Race' all='Total')),
  	        ((trt01p='Treatment Group' all='Total')*(n='n' colpctn='%'*f=5.1))
  	        / misstext='0' printmiss;
  	  title 'Summary of Race by Last Disposition';
  run;
ods rtf close;
