%let miss = MISSING;

/****************************************************/
/* checks whether variable VAR exists in dataset DS */
/* and sets macro variable DS_VAR as follows        */
/* DS_VAR = 1  if VAR exists                        */
/* DS_VAR = 0  if VAR does not exist                */
/* also inserts a record into RPT_CHK_VAR           */
/*                                                  */
/* sets DS_VAR_TYPE to variable type                */
/* and DS_VAR_LEN to variable length                */
/****************************************************/
%macro chk_var(lib=work,ds=,var=);

	%global &ds._&var.;

	data chk_var_&ds._&var.;
		length chk $12 ds $32 var $36 type $1 len 8. condition $200 ind 8.;
		chk = 'VAR';
		ds = upcase("&ds.");
		var = upcase("&var.");
		condition = 'EXISTS';

		dsid = open("&lib..&ds.");
		if dsid then do;
			ind = ifn(varnum(dsid,upcase("&var."))>0,1,0);
			if ind then do;
				type = vartype(dsid,varnum(dsid,upcase("&var.")));
				len = varlen(dsid,varnum(dsid,upcase("&var.")));
			end;
			else do;
				type = '';
				len = -1;
			end;
			rc = close(dsid);
			drop rc;
		end;
		else do; 
			/*ind = -1;*/
			ind = 0;
			type = ''; 
			len = -1;
		end;

		drop dsid;

		call symputx("&ds._&var.",ind,'g');	
		call symputx("&ds._&var._type",type,'g');
		call symputx("&ds._&var._len",len,'g');
	run;

	data rpt_chk_var;
		merge %if %sysfunc(exist(rpt_chk_var)) %then rpt_chk_var; chk_var_&ds._&var.;
		by ds var;
	run;

	proc datasets library=work nolist nodetails; delete chk_var_&ds._&var.; quit;

%mend chk_var;


/*****************************************************/
/* check whether DM has any subjects                 */
/* sets the macro variable DM_SUBJ_GT0 as follows    */
/* DM_SUBJ_GT0 = 1 if there are more than 0 subjects */
/* DM_SUBJ_GT0 = 0 if there are 0 subjects           */
/*****************************************************/
%macro chk_dm_subj_gt0;

	data _null_;
		dsid = open('dm');
		if dsid then do;
			nobs = attrn(dsid,'nobs');
			nvars = attrn(dsid,'nvars');
		end;
		call symputx('dm_subj_gt0',ifc(nobs>0 and nvars>0,'1','0'),'g');
		rc = close(dsid);
	run;

%mend chk_dm_subj_gt0;


/****************************************************************************/
/* checks whether dataset DS has values VAL1-VAL15 in variable VAR          */
/* and sets macro variable DS_VAR_VAL as follows:                           */
/* DS_VAR_VAL = 1 if VAL is present                                         */
/* DS_VAR_VAL = 0 if VAL is not present                                     */
/* DS_VAR_VAL = -1 if DS does not exist or VAR does not exist               */
/*                                                                          */
/* the macro will also insert a record into RPT_CHK_VAL for each value      */
/* with the appropriate indicator depending upon the presence or absence of */
/* the value in variable VAR                                                */
/*                                                                          */
/* argument CS makes the macro use case sensitive variable values           */
/* argument COUNT makes the macro find counts instead of indicators         */
/*                                                                          */
/* tbd: macro variable DS_VAR_MISSING, 	                                    */
/*      macro will fail if DS_VAR_VAL is too long                           */
/****************************************************************************/
%macro chk_val(lib,ds,var,
               val1, val2, val3, val4, val5,
               val6, val7, val8, val9, val10, 
               val11,val12,val13,val14,val15,
               val16,val17,val18,val19,val20,
               val21,val22,val23,val24,val25,
               cs=F,count=F);

	%if not %symexist(miss) %then %let miss = MISSING;

	%let cs = %upcase(&cs.); %let count = %upcase(&count.);

	/* find the number of values to look up */
	%let i = 1;
	%do %while (%symexist(val&i.));
		%if (&&&val&i. = ) %then %goto max_arg;
		%let i = %eval(&i. + 1);
	%end;
	%max_arg: %let max_arg = %eval(&i. - 1);

	%if %symexist(vals) %then %symdel vals;

	/* get the data type and length of VAR */
	%let dsid = %sysfunc(open(&lib..&ds.));
	%if &dsid. > 0 %then %do;
		%let varnum = %sysfunc(varnum(&dsid.,&var.));
		%if &varnum. > 0 %then %do;
			%let type = %sysfunc(vartype(&dsid.,&varnum.));
			%let len = %sysfunc(varlen(&dsid.,&varnum.));
		%end;
		%let rc = %sysfunc(close(&dsid.));
	%end;

	/* if the macro was able to determine the length and type of the variable */
	/* then set a success code. otherwise, set a failure code and go to the end */
	%if %symexist(type) and %symexist(len) %then %let success = 1;
	%else %do; 
		%let success = 0;
		%let type = C;
		%let len = 200;
 	%end;

 	/* look for missing keyword and replace with missing */
	%do i = 1 %to &max_arg.;
		%if %upcase(&&&val&i.) = &miss. %then %let val&i. = %sysfunc(ifc(&type.=C,,.));
	%end;

	/* create the list of values to look up */
	data _null_;
		vals = %do i = 1 %to &max_arg.; 
                ifc("&type." = 'C',"%str(%')&&&val&i.%str(%')","&&&val&i.")||
                ifc("&i." ne "&max_arg.",',','')|| 
               %end;
               '';
		if "&cs." ne 'T' then vals=upcase(vals);

		call symputx('vals',vals);
	run;

	/* create a dummy dataset for joining */
	data dual; call missing(dummy); run;

	/* a list of all values sought */
	/* counts of those appearing in the dataset will be joined to these */
	/* those not appearing in the dataset will get an appropriate indicator */
	data chk_val_&ds._&var._val;
		length &var. %sysfunc(ifc(&type.=C,$,))&len.;
		%do i = 1 %to &max_arg.;
			&var. = ifc("&cs." ne 'T',upcase("&&&val&i."),"&&&val&i.");	output;
		%end;
	run;

	proc sql noprint;
		create table chk_val_&ds._&var. as
		select "VAL" length=12 as chk,
               upcase("&ds.") length=32 as ds,
			   upcase("&var.") length=36 as var,
               %sysfunc(ifc(&type.=C,a.&var.,put(a.&var.,8.7 -L))) length=200 as val, 
			   %if &count. ne T	%then %do;
				   "PRESENT" length=200 as condition,
	               (case 
                       when count > 0 then 1
					   when count = -1 then -1
                       else 0 
                    end) as ind
			   %end;
			   %else %do;
				   "COUNT" length=200 as condition,
	               (case when count is not missing then count else 0 end) as ind
			   %end;
		from chk_val_&ds._&var._val	a

		/* if the variable exists, find the counts of the requested values */
		%if &success. %then %do;
			left join (select &var., count(1) as count
					   from &lib..&ds.
					   where %sysfunc(ifc(&type.=C and &cs. ne T,upcase(&var.),&var.)) in (&vals.)
					   group by &var.) b
	        on a.&var. = b.&var.
		%end;

		/* else set all indicators to -1 */
		%else %do;
			left join (select -1 as count
			           from dual) b
			on 1=1
		%end;
		;
	quit;

	/* set missing values to 'MISSING' */
	data chk_val_&ds._&var.;
		set chk_val_&ds._&var.;
		if "&type." = 'C' and val = ''
		or "&type." = 'N' and val in ('','.')
		then val = 'MISSING';
	run;

	proc sort data=chk_val_&ds._&var.; by ds var val condition; run;

	data rpt_chk_val;
		merge %if %sysfunc(exist(rpt_chk_val)) %then rpt_chk_val; chk_val_&ds._&var.(in=a);
		by ds var val condition;
		if a then call symputx(compress(ds)||'_'||compress(var)||'_'||
                               compress(translate(trim(val),'_',' '),'_','ak')||
					           ifc("&count."='T','_cnt',''),ind,'g');
	run;

	proc datasets library=work nolist nodetails; delete chk_val_&ds._&var.: dual; quit;

	/* if dataset DS or variable VAR do not exist, then print an error */
	%if not &success. %then %do;
		%put ERROR: Dataset &ds. or variable &var. does not exist;
	%end;

%mend chk_val;


/****************************************************************/
/* determine which values of VAR1 in DS1 are not in VAR2 of DS2 */
/* and vice versa                                               */
/****************************************************************/
%macro chk_cmp(lib=,ds1=,var1=,ds2=,var2=);

	/* put ds1 and ds2 in alphabetical order */
	/*data _null_;
		if upcase("&ds1.") <= upcase("&ds2.") then do;
			ds1 = upcase("&ds1."); ds2 = upcase("&ds2.");
			var1 = upcase("&var1."); var2 = upcase("&var2.");
		end;
		else do;
			ds1 = upcase("&ds2."); ds2 = upcase("&ds1.");
			var1 = upcase("&var2."); var2 = upcase("&var1.");
		end;
		call symputx('ds1',ds1); call symputx('ds2',ds2);
		call symputx('var1',var1); call symputx('var2',var2);
	run; */

	/* determine data types */
	data _null_;
		length type1 $1 type2 $1;

		dsid = open("&lib..&ds1.");
		if dsid then do;
			type1 = vartype(dsid,varnum(dsid,"&var1."));
			rc = close(dsid);
		end;

		dsid = open("&lib..&ds2.");
		if dsid then do;
			type2 = vartype(dsid,varnum(dsid,"&var2."));
			rc = close(dsid);
		end;

		if type1 ne '' and type2 ne '' and type1 = type2 then call symputx('success','1');
		else call symputx('success','0');
	run;

	%if not &success. %then %goto exit;

	proc sql noprint;
		create table chk_cmp_ds1 as
		select distinct &var1., 1 as ds1
		from &lib..&ds1.
		order by &var1.;

		create table chk_cmp_ds2 as
		select distinct &var2., 1 as ds2
		from &lib..&ds2.
		order by &var2.;

		create table rpt_cmp_&ds1._&ds2. as
		select "&ds1." length=32 as ds1,
		       "&ds2." length=32 as ds2,
               (case when ds1 then "&ds1." else "&ds2." end) length=32 as in, 
               (case when ds1 then a.&var1. else b.&var2. end) as var
		from chk_cmp_ds1 a
		full join chk_cmp_ds2 b
		on a.&var1. = b.&var2.
		where not (ds1 and ds2);
	quit;

	proc datasets library=work nolist nodetails; delete chk_cmp_ds1 chk_cmp_ds2; quit;

	%exit: 
	%if not &success. %then %do;
		%put ERROR: One or more of dataset &ds1. or &ds2. or variable &var1. or &var2. does not exist;
		%put ERROR: or &var1. and &var2. are not of the same type;
	%end;

%mend chk_cmp;
