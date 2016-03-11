/* find the number of disposition events per arm that do not have a study day */
/* either due to missing DSSTDY or missing or invalid DSSTDTC or RFSTDTC when DSSTDY is missing */
%macro disposition_err_dt(ds);

	%if not %sysfunc(exist(arm)) %then %do;
		proc sql noprint;
			create table arm as
			select distinct arm
			from &ds.;
		quit;

		data arm;
			set arm end=eof;
			n_arm = _n_;
			if eof then call symputx('num_arms',put(_n_,8. -l),'g');
		run;
	%end;

	/* get arm number along with DM/DS */
	data ds_err_&ds.;
		set &ds.(keep=arm usubjid dsdecod dsstdtc dsdy where=(missing(dsdy)));

		format dsstdt e8601da.; 
		dsstdt = input(dsstdtc,?? e8601da.);
		drop dsstdtc;

		if missing(dsstdt) then order = 99;
		else order = 1;

		/* add arm number */
		if _n_ = 1 then do;
			declare hash h(dataset:'arm');
			h.definekey('arm');
			h.definedata('n_arm');
			h.definedone();
		end;

		length n_arm 8.;
		call missing(n_arm);
		rc = h.find();
		drop rc;

		rename n_arm=arm_num;
		drop dsdy;
	run;

	proc sort data=ds_err_&ds. out=ds_err_&ds.(drop=order);
		by arm usubjid order dsstdt;
	run;

	proc sort data=ds_err_&ds. out=ds_err_&ds._nodup(keep=usubjid arm_num dsdecod) nodupkey dupout=ds_err_&ds._dup;
		by usubjid dsdecod;
	run; 

	/* get the name of each arm number */
	data _null_;
		set arm end=eof;
		call symputx('arm_'||put(n_arm,8. -L),arm);
		if eof then call symputx('arm_count',n_arm);
	run;

	proc sql noprint;
		create table ds_rpt_&ds.(drop=null) as
		select propcase(a.dsdecod) as dsdecod label='Standardized Disposition Term', 
		       %do i = 1 %to &num_arms.;
	              (case when arm_&i. is missing then 0 else arm_&i. end) as arm_&i.
	               label = "&&&arm_&i. Subject Count",
			   %end;
			   0 as null
		from (select (case when count(1) = 0 then '.' else dsdecod end) as dsdecod
		      from (select distinct dsdecod from ds_err_&ds._nodup)) a
		left join (select dsdecod, 
	               %do i = 1 %to &num_arms.; 
	                 sum(case when arm_num = &i. then 1 else 0 end) as arm_&i., 
	               %end;
	               0 as null
		           from ds_err_&ds._nodup
		           group by dsdecod) b
		on a.dsdecod = b.dsdecod
		order by arm_1 desc;
	quit;

	/* drop arm number from err dataset */
	data ds_err_&ds.;
		set ds_err_&ds.(drop=arm_num);
		/*by arm usubjid;
		if not first.arm then arm = '';
		if not first.usubjid then usubjid = '';*/
	run;

	proc datasets library=work nolist nodetails; delete ds_rpt_&ds._:; quit;

	%chk_var(ds=ds,var=dsstdy);

	%if not %sysfunc(exist(ds_rpt_stdy_text)) %then %do;
		data ds_rpt_stdy_text;
			length text $500;
			select ("&ds_dsstdy.");
				when ('1') text = 'Study day (DSSTDY) was present in the disposition domain dataset (DS). '||
                                  'The following table shows counts of subjects whose disposition events '||
                                  'had missing study days.';
				when ('0') text = 'Study day (DSSTDY) was not present in the disposition domain dataset (DS). '||
                                  'The following table shows counts of subjects whose disposition events '||
                                  'had missing or invalid disposition event start date '||
	                              'or who had a missing or invalid reference start date/time.';
				otherwise  text = 'An error was encountered while trying to access DS';
			end;
		run;
	%end;

%mend disposition_err_dt;



/* put together disposition analysis panel data check summaries for */
/* disposition events that were not included in the analysis        */
/* due to missing data                                              */
%macro disposition_stdy;

	%disposition_err_dt(dm_ds);
	%disposition_err_dt(dm_ds_ex);

	/* put together list of subjects/disposition events that weren't used */
	data ds_rpt_stdy;
		retain arm usubjid ex dsstdt dsdecod;
		merge ds_err_dm_ds(in=a rename=(dsstdt=dsstdtn)) 
              ds_err_dm_ds_ex(in=b rename=(dsstdt=dsstdtn));
		by arm usubjid;
		if b then ex = 'Y';
		else ex = 'N';
		if not first.arm then arm = '';
		if not first.usubjid then do;
			usubjid = '';
			ex = '';
		end;

		if dsstdtn ne . then dsstdt = put(dsstdtn,e8601da.);
		else dsstdt = '.';
		drop dsstdtn;
	run;

	/* truncate the list at 500 */
	data ds_rpt_stdy;
		set ds_rpt_stdy;

		dsid = open('ds_rpt_stdy');
		nobs = attrn(dsid,'nobs');
		rc = close(dsid);

		if _n_ = 501 then do;
			arm = trim(put(nobs,8. -l))||' events';
			usubjid = 'Truncated at 500';
			ex = '';
			dsstdt = .;
			dsdecod = '.';
		end;
		else if _n_ > 501 then delete;

		drop dsid nobs rc;
	run;

	/* put together summary of counts */
	data ds_rpt_stdy_summary;
		set ds_rpt_dm_ds(in=a) ds_rpt_dm_ds_ex(in=b);
		length exposure $16;
		if a then exposure = 'All Subjects';
		if b then exposure = 'Exposed Subjects';
	run;

	data ds_rpt_stdy_summary;
		retain exposure dsdecod;
		set ds_rpt_stdy_summary;
		by exposure;
		if not first.exposure then exposure = '';
	run;

	proc datasets library=work nolist nodetails; delete ds_err: ds_rpt_dm_ds:; quit;

%mend disposition_stdy;



/* find whether there are any subjects not in both DM and DS */
/* if there are, set the macro variable DM_DS_USUBJID accordingly */
%macro disposition_dm_ds_usubjid;

	%chk_cmp(lib=work,ds1=dm,var1=usubjid,ds2=ds,var2=usubjid);

	/*data _null_;
		dsid = open('rpt_cmp_dm_ds');
		if dsid then do;
			nobs = attrn(dsid,'nobs');
			rc = close(dsid);
		end; 
		if nobs = . then do;
			if rc = 0 then nobs = 0;
			else nobs = -1;
		end;
		call symputx('dm_ds_usubjid',nobs,'g');
	run;*/

	%global dm_ds_usubjid;

	proc sql noprint;
		select count(1) into: dm_ds_usubjid
		from rpt_cmp_dm_ds
		where in = 'dm';
	quit;

	data ds_rpt_dm_ds_usubjid;
		text = 'There are '||compress(ifc(&dm_ds_usubjid.=0,'no',&dm_ds_usubjid.))||' '||
               'subjects in the demographics domain (DM) '||
               'that had no disposition events in the disposition domain (DS).';
	run;

%mend disposition_dm_ds_usubjid;



/* run all disposition checks */
%macro disposition_check;

	%disposition_stdy;

	%disposition_dm_ds_usubjid;

%mend disposition_check;



/* output for data checks */
%macro disposition_check_out; 

	*options noxwait xsync;

	*x "%str(copy %"&templatepath.\disposition_data_check_summary_template.xls%" %"&outpath.\disposition_data_check_summary.xls%")";

	%if not %symexist(run_location) %then %let run_location = LOCAL;

	/* local runs use the Microsoft Jet database-based Excel LIBNAME engine */
	%if %upcase(&run_location.) = LOCAL %then %do;
		*libname xls excel "&dispout." ver=2003; *Output function changed due to SAS 9.3(64bit) and Excel 2010(32bit) incompatability;
		libname xls pcfiles path="&dispout."; 
	%end;
	/* Script Launcher runs use the PCFILES LIBNAME Engine */
	%else %do; 
		libname xls pcfiles path="&dispout."; 
	%end;

	proc sql noprint;
		drop table xls.subjmiss,
                   xls.text, 
	               xls.summary,
				   xls.list,
				   xls.arminfo,
				   xls.dcinfo
                   ;
	quit; 

	data xls.subjmiss;
		set ds_rpt_dm_ds_usubjid;
	run;

	data xls.text;
		set ds_rpt_stdy_text;
	run;

	data xls.summary;
		set ds_rpt_stdy_summary;
	run;

	data xls.list;
		set ds_rpt_stdy;
	run;

	data xls.arminfo;
		set arm;
	run;

	/* data check summary info for removing blank rows in the template */
	proc sql noprint; 
		select count(1) into: summary
		from ds_rpt_stdy_summary;

		select count(1) into: list
		from ds_rpt_stdy;
	quit;

	data xls.dcinfo; 
		data = 'summary'; val = &summary.; output;
		data = 'list'; val = &list.; output;
	run;

	libname xls clear;

%mend disposition_check_out;
