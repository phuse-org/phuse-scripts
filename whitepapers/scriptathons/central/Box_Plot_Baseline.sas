filename source "C:\how\Scriptathon\sasdata\advs.xpt";
libname source xport;
data advs;
	keep USUBJID SAFFL PARAMCD TRTPN TRTP AVAL AVISIT AVISITN ATPT;
	set source.advs;
	where SAFFL='Y' and PARAMCD in ('DIABP', 'PULSE') 
		and ATPT='AFTER LYING DOWN FOR 5 MINUTES' and AVISITN=99;
run;
data advs1;
	set advs;
	if PARAMCD = 'DIABP' then PARAMCD_NUM=0;
	else PARAMCD_NUM=1;
run;
/*fitting a linear model with DIABP and PULSE
	I'm not quite sure the ourcome and independent variables are, so I will pick what I 
	think could be interesting y=AVAL x=PARAMCD and focus more on the code*/
proc sgplot data=advs1;
	scatter y=AVAL x=PARAMCD_NUM;
run;
proc reg data=advs1;
	model AVAL=PARAMCD_NUM;
	output out=regout p=fitted_value r=residuals j;
run;
proc sgplot data=regout;
	scatter x=fitted_value y=residuals;
	loess x=fitted_value y=residuals;
	refline 0;
run;
