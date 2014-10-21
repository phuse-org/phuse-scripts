***********************************************************************;
* Project           : Sample Drug, Sample Indication,Study1
*
* Program name      : table7_2b.sas
*
* Author            : ddabhi
*
* Date created      : 20141012
*
* Purpose           : Subject Disposition table.
*
* Revision History  :
*
* Date        Author      Ref    Revision (Date in YYYYMMDD format) 
*
***********************************************************************;

** Reading ADSL data ;
filename source url "http://phuse-scripts.googlecode.com/svn/trunk/lang/R/report/test/data/adsl.xpt";
libname source xport ;

data adsl(keep = usubjid trt01an trt01a dcreascd ittfl);
	set source.adsl;
	where ittfl = "Y";
run;

** Create total ;
data adsl1;
	set adsl;
	output;
	trt01an = 999;
	trt01a = "Total";
	output;
run;

** Header N Count ;
proc sql noprint;
	create table tot as select trt01an, count(distinct usubjid) as tot from adsl1 group by trt01an order by trt01an;
	select count(distinct trt01an) into :ntrt from adsl1;
	select count(distinct usubjid) into :trt1-:trt%cmpres(&ntrt) from adsl1 group by trt01an order by trt01an;
	select distinct trt01a into :trtlbl1-:trtlbl%cmpres(&ntrt) from adsl1 group by trt01a order by trt01a;
quit;

data dummy;
	length col1 $50;
	col1 = "Completed the study"; 					ord = 1; output;
	col1 = "Discontinued"; 							ord = 2; output;
	col1 = " "; 									ord = 3; output;
	col1 = "  Death"; 								ord = 4; output;
	col1 = "  Adverse Event"; 						ord = 5; output;
	col1 = "  Lack of Efficacy"; 					ord = 6; output;
	col1 = "  Lost to Follow-up"; 					ord = 7; output;
	col1 = "  Non-compliance with Study Drug"; 		ord = 8; output;
	col1 = "  Pregnancy"; 							ord = 9; output;
	col1 = "  Protocal Violation"; 					ord = 10; output;
	col1 = "  Physician Decision"; 					ord = 11; output;
	col1 = "  Withdrawl by Subject"; 				ord = 12; output;
	col1 = "  Withdrawl by Parent/Guardian"; 		ord = 13; output;
	col1 = "  Recovery"; 							ord = 14; output;
	col1 = "  Technical Problems"; 					ord = 15; output;
	col1 = "  Other"; 								ord = 16; output;
run;

* Parameters:							;
* OUTDATA - output dataset name         ;
* WHERE - for subset the input dataset  ;
%macro disp(outdata=, where=, var=);
	proc sql;
		create table &outdata as 
			select count(distinct usubjid) as cnt, (calculated cnt*100)/tot as per, &var as col1, a.trt01an, trt01a length=50 
				from adsl1 as a, tot as b
					where &where and a.trt01an = b.trt01an
						group by a.trt01an, trt01a, tot, col1;
	quit;
%mend disp;
%disp(outdata=comp, where=%str(upcase(dcreascd) = "COMPLETED"), var=%str("Completed the study"))
%disp(outdata=disc, where=%str(upcase(dcreascd) ^= "COMPLETED"), var=%str("Discontinued"))
%disp(outdata=all, where=%str(upcase(dcreascd) ^= "COMPLETED"), var=%str(dcreascd))

data disp;
	set comp disc all(in = a);
	by trt01an trt01a;
	if a then col1 = "  " || trim(left(col1));

	nper = put(cnt, 3.) || "(" || put(per, 5.1) || ")";
run;


proc transpose data = disp out = disp_t;
	by 
run;
