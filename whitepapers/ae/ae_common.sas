filename source url "http://phuse-scripts.googlecode.com/svn/trunk/lang/R/report/test/data/adsl.xpt"
libname source xport ;
data work.adsl ;
  set source.adsl ;
run ;


 filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adae.xpt" ;
 libname source xport ;
 data work.adae ;
   set source.adae ;
   keep USUBJID TRTAN AEDECOD TRTEMFL AOCCPFL SAFFL;
 run ;
 proc print data=work.adae ;
   title1 "A test of accessing datasets from the PhUSE Code Repository" ;
   run ;

   proc sort data=work.adae;
   by aedecod;

   data adae1;
   set adae;
   where AOCCPFL='Y' ;
   run;


   proc sql;
   	create table count as
	select count(usubjid) as numsub, aedecod, trtan, aedecod, trtemfl, aoccpfl, saffl
	from adae1
	group by trtan;
	quit;

  

  title1 "Summary of Common Treatment-Emergent Adverse Events";
proc sgpanel data=work.count;
  panelby trtan;
  rowaxis label="PT";
  vbar adaedoc / response=numjid stat=mean
                 transparency=0.3;
  
 run; 