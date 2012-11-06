libname ds_in "C:\Documents and Settings\C035271\Desktop\FDA_Phuse WG5\Draft Examples\data_in";
libname ds_out "C:\Documents and Settings\C035271\Desktop\FDA_Phuse WG5\Draft Examples\ADaM";

** get data from SDTM.DM and create ADSL variables **;
data adsl;
  length trt01p $6 agegr1 $10;
  set ds_in.dm (keep=studyid usubjid siteid age ageu sex race ethnic country armcd arm);

  ** populate treatment groups **;
  if armcd ne 'SCRNFAIL' then do;
    trt01p=arm;
	if trt01p='Drug A' then trt01pn=1;
	  else trt01pn=2;
  end;

  ** create age categories **;
  if .<age<65 then do;
    agegr1='<65 days';
	agegr1n=1;
  end;
  else do;
    agegr1='>=65 days';
	agegr1n=2;
  end;

  ** create enrolled and randomized population flags **;
  enrlfl=1;
  if armcd ne 'SCRNFAIL' then randfl=1;
run;

** bring in disposition data **;
proc sort data=ds_in.ds (keep=studyid usubjid visitnum dsstdy dsterm dscat dsdecod)
          out=ds;
	by studyid usubjid visitnum dsstdy;
run;


** remove undesired DSCAT and DSTERM values **;
data ds;
  set ds;
  if dscat='PROTOCOL M' then delete;
  if dsterm='Informed c' or dsterm='Randomized' then delete;
run;

** select last record **;
data ds;
  set ds;
    by studyid usubjid visitnum;
  if last.usubjid;
  keep studyid usubjid dsdecod;
run;

** merge disposition with adsl **;
proc sort data=adsl;
  by studyid usubjid;
run;

data adsl;
  length lastdisp $15;
  merge adsl (in=in_adsl) ds;
    by studyid usubjid;
  if in_adsl;
  lastdisp=dsdecod;
run;

** output adam.adsl data set **;
data ds_out.adsl;
  set adsl;
  keep studyid usubjid siteid age ageu agegr1 agegr1n sex race
       ethnic country lastdisp trt01p trt01pn enrlfl randfl;
run;
