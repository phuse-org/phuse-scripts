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

  

PROC SGPANEL < option(s)>;
PANELBY variable(s)< /option(s)>;
BAND X= variable | Y= variable
UPPER= numeric-value | numeric-variable LOWER= numeric-value | numeric-variable
</option(s)>;
COLAXIS <option(s)>;
DENSITY response-variable </option(s)>;
DOT category-variable </option(s)>;
HBAR category-variable </option(s)>;
HBOX response-variable </option(s)>;
HISTOGRAM response-variable </option(s)>;
HLINE category-variable </option(s)>;
KEYLEGEND <"name(s)"> </option(s)>;
LOESS X= numeric-variable Y= numeric-variable </option(s)>;
NEEDLE X= variable Y= numeric-variable </option(s)>;
PBSPLINE X= numeric-variable Y= numeric-variable </option(s)>;
REFLINE value(s) </option(s)>;
REG X= numeric-variable Y= numeric-variable </option(s)>;
ROWAXIS <option(s)>;
SCATTER X= variable Y= variable </option(s)>;
SERIES X= variable Y= variable </option(s)>;
STEP X= variable Y= variable </option(s)>;
VBAR category-variable </option(s)>;
VBOX response-variable </option(s)>;
VECTOR X= numeric-variable Y= numeric-variable </option(s)>;
VLINE category-variable </option(s)>;


  title1 "Summary of Common Treatment-Emergent Adverse Events";
proc sgpanel data=work.count;
  panelby trtan;
  rowaxis label="PT";
  vbar adaedoc / response=numjid stat=mean
                 transparency=0.3;
  
 run; 