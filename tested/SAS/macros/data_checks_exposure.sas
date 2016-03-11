/* find how many exposure events have missing frequencies */
%macro exposure_exdosfrq_missing;

	proc sql noprint;
		create table ex_exdosfrq_missing as
		select arm, 
		       propcase(exdosfrm) as exdosfrm,
               sum(case when exdosfrq not in (&vld_exdosfrq.) then 1 else 0 end) as exdosfrq_miss,
               count(1) as total
		from ex_dm
		group by arm, exdosfrm;
	quit;

	data ex_exdosfrq_missing;
		retain arm exdosfrm blank1 blank2 blank3 exdosfrq_miss exdosfrq_miss_pct;
		set ex_exdosfrq_missing;
		by arm;
		if not first.arm then arm = '';
		exdosfrq_miss_pct = 100*exdosfrq_miss/total;
		blank1 = .; blank2 = .; blank3 = .;
		drop total;
	run;

%mend exposure_exdosfrq_missing;


/* find exposure events that were excluded from analysis A */
/* due to missing study days for all of a subject's exposure events */
%macro exposure_err_a(ds);

	proc sql noprint;
		create table ex_err_a as
		select arm, usubjid
		from (select arm, usubjid, max(studydays) as studydays
              from &ds.
              group by arm, usubjid
             )
		where studydays is missing
		order by arm, usubjid;

		%global ex_err_a;
		select put(count(1),8. -L) into: ex_err_a
		from ex_err_a;
	quit; 

	proc sql noprint;
		create table ex_err_a_summary as
		select a.arm, (case when b.count is missing then 0 else b.count end) as count,
		       (case when b.count is missing then 0 else b.count/a.total end) as pct
		from (select arm, count(1) as total 
              from dm 
              group by arm) a
		left join (select arm, count(1) as count
		           from ex_err_a
				   group by arm) b
		on a.arm = b.arm;
	quit;

	data ex_err_a;
		set ex_err_a;
		by arm usubjid;
		if not first.arm then arm = '';
	run;

%mend exposure_err_a;


/* find exposure events that were excluded from analysis B */
/* due to missing dose numbers */
%macro exposure_err_b(ds);

	proc sql noprint;
		create table ex_err_b as
		select arm, usubjid
		from &ds.
		where doses is missing
		order by arm, usubjid;

		%global ex_err_b;
		select put(count(1),8. -L) into: ex_err_b
		from ex_err_b;
	quit; 

	proc sql noprint;
		create table ex_err_b_summary as
		select a.arm,  
               (case when subject_count is missing then 0 else subject_count end) as subject_count, 
               (case when subject_count is missing then 0 else subject_count/arm_tot end) as subject_pct, 
               (case when event_count is missing then 0 else event_count end) as event_count, 
               (case when event_count is missing then 0 else event_count/ex_tot end) as event_pct
		from (select a.arm, arm_tot, ex_tot
              from (select arm, count(1) as arm_tot
                    from dm
                    group by arm) a, 
                   (select arm, count(1) as ex_tot
                    from ex_dm
                    group by arm) b
			  where a.arm = b.arm
              ) a
		left join (select a.arm, subject_count, event_count
		           from (select arm, count(distinct usubjid) as subject_count
                         from ex_err_b
						 group by arm) a,
                        (select arm, count(1) as event_count
                         from ex_err_b
						 group by arm) b
				   where a.arm = b.arm) b
		on a.arm = b.arm;
	quit;

%mend exposure_err_b; 



/* run Exposure data checks */
%macro exposure_check;

	%exposure_exdosfrq_missing;


	%exposure_err_a(ex_dm);


	%exposure_err_b(ex_dm);

%mend exposure_check;



/* output for data checks */
%macro exposure_check_out; 

	*options noxwait xsync;

	*x "%str(copy %"&templatepath.\disposition_data_check_summary_template.xls%" %"&outpath.\disposition_data_check_summary.xls%")";

	%if not %symexist(run_location) %then %let run_location = LOCAL;

	/* local runs use the Microsoft Jet database-based Excel LIBNAME engine */
	%if %upcase(&run_location.) = LOCAL %then %do;
		*libname xls excel "&expout." ver=2003;*Output function changed due to SAS 9.3(64bit) and Excel 2010(32bit) incompatability;
		libname xls pcfiles path="&expout."; 
	%end;
	/* Script Launcher runs use the PCFILES LIBNAME Engine */
	%else %do;
		libname xls pcfiles path="&expout."; 
	%end;

	proc sql noprint;
		drop table xls.checka,
                   xls.checkb,
				   xls.missdosfrq, 
				   xls.pva_err,
				   xls.dc_err,
				   xls.dcinfo
                   ;
	quit; 

	data xls.checka;
		set ex_err_a_summary;
	run; 

	data xls.checkb;
		set ex_err_b_summary;
	run;

	data xls.missdosfrq;
		set ex_exdosfrq_missing;
	run;

	%if not (&dm_arm. and &ex_extrt. and &ex_exdose. and &ex_exdosu.) %then %do;	
		data xls.pva_err;
			set final_exposureD_err;
		run;
	%end;

	%if not (&ex_extrt. and &ex_exdose. and &ex_exdosu.) %then %do;	
		data xls.dc_err;
			set final_exposureE_err;
		run;
	%end;

	/* data check info for removing blank rows between sections */
	data xls.dcinfo;
		data = 'arm_count'; val = &num_arms.; output;
	run;

	libname xls clear;

%mend exposure_check_out;
