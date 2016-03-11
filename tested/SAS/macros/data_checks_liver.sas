/********************************************************************/
/* checks whether the four lab tests used by the liver lab analysis */
/* are present in LB                                                */
/* sets LIVER_LBTESTCD macro variable to 1 if at least one of each  */
/* kind of lab test code exists                                     */
/********************************************************************/
%macro liver_lbtestcd;

	/* look up whether the values exist using chk_val */
	%chk_val(work,lb,lbtestcd,&alt.,&ast.,&alp.,&bili.);

	%global liver_lbtestcd liver_alt liver_ast liver_bili liver_alp;

	%do i = 1 %to 4;
		%let lbtest = %scan(alp alt ast bili,&i.);

		data _null_;
			set rpt_chk_val end=eof;
			where chk = 'VAL'
			  and ds  = 'LB'
			  and var = 'LBTESTCD'
			  and val in (&&&l_&lbtest.)
			  and condition = 'PRESENT';
			retain present_ind 0;
			if ind = 1 then present_ind = 1;
			if eof then call symputx("liver_&lbtest.",present_ind);
		run;

	%end;

	%if &liver_alt. and &liver_ast. and &liver_bili. and &liver_alp. %then %do;
		%let liver_lbtestcd = 1;
		%let err_liver_lbtest = ;
	%end;
	%else %do;
		%let liver_lbtestcd = 0;

		/* create the error message */
		data rpt_liver_lbtest_list;
			length testdesc $100; 
			%if not &liver_alp. %then %do; testdesc = 'Alkaline Phosphatase (ALP)'; output; %end;
			%if not &liver_alt. %then %do; testdesc = 'Alanine Aminotransferase (ALT)'; output; %end;
			%if not &liver_ast. %then %do; testdesc = 'Aspartate Aminotransferase (AST)'; output; %end;
			%if not &liver_bili. %then %do; testdesc = 'Total Bilirubin (TB)'; output; %end;
		run;

		proc sql noprint;
			select testdesc, count(1) into : rpt_liver_lbtest_list separated by ', ', : rpt_liver_lbtest_count
			from rpt_liver_lbtest_list;
		quit;

		data _null_;
			length string $1000;
			string = "&rpt_liver_lbtest_list.";
			if &rpt_liver_lbtest_count. = 1 then do; 
				string = 'Lab test '||strip(string)||' is missing.';
			end;
			else if &rpt_liver_lbtest_count. = 2 then do;
				string = 'Lab tests '||tranwrd(strip(string),', ',' and ')||' are missing.';
			end;
			else do;
				index = length(strip(string)) - index(left(reverse(string)),',')+1;
				string = 'Lab tests '|| substr(strip(string),1,index)||' and'||substr(strip(string),index+1)||
                         ' are missing.';
			end;
			call symputx('err_liver_lbtest',string,'g');
		run;

	%end;

%mend liver_lbtestcd;


/************************************************************/
/* create a table of the counts of missing or 0 test scores */
/* for lab tests used in the liver lab analysis             */
/************************************************************/
%macro liver_lbstresn_missing;

	data lbm_val;
		length lbtest $8;
		lbtest = 'ALT'; output;
		lbtest = 'AST'; output;
		lbtest = 'ALP'; output;
		lbtest = 'TB'; output;
	run;

	proc sql noprint;
		create table lb_rpt_lb(drop=null) as
		select (case 
					when lbtestcd in (&l_alt.) then 'ALT'
		        	when lbtestcd in (&l_ast.) then 'AST'
		        	when lbtestcd in (&l_alp.) then 'ALP'
		        	when lbtestcd in (&l_bili.) then 'TB'
					else ''
				end) as lbtest,
				lbstresn, 
                %if &lb_lbstat. %then lbstat,; %else '' as lbstat length=20,;
                %if &lb_lbreasnd. %then lbreasnd,; %else  '' as lbreasnd length=20,;
				0 as null
		from demographics a,
		     lb b
		where a.usubjid = b.usubjid
		and upcase(lbtestcd) in (&l_alt.,&l_ast.,&l_alp.,&l_bili.)
		;
	quit; 

	proc sql noprint;
		/* get counts of missing or 0 lab test results for each lab test */
		create table lb_rpt_lbstresn_miss0_count as
		select a.lbtest, 
		       /*'MISSING OR 0' as lbstresn,*/ 
               (case when b.missing >= 0 then b.missing else 0 end) as missing,
               (case when b.missing >= 0 and b.count > 0 then 100*b.missing/b.count
                     else . end) as pct
		from lbm_val a
		left join (select lbtest, 
                          sum(case when lbstresn in (.,0) then 1 else 0 end) as missing,
                          count(1) as count
				   from lb_rpt_lb
				   group by lbtest
                   ) b
		on a.lbtest = b.lbtest;
	quit;

	proc sql noprint;
		/* get the completion status and reason not done for missing/0 lab test results */
		create table lb_rpt_lbstresn_miss0_reasn as
		select lbtest, lbstat, lbreasnd, count(1) as count
		from lb_rpt_lb
		where lbstresn in (.,0)
		group by lbtest, lbstat, lbreasnd
		order by lbtest, count desc;
	quit;

	proc sort data=lbm_val; by lbtest; run;

	data lb_rpt_lbstresn_miss0_reasn;
		merge lbm_val(in=a)
              lb_rpt_lbstresn_miss0_reasn(in=b);
		by lbtest;
		if a;

		if a and b then do;
			if not anylower(lbstat) then lbstat = upcase(substr(lbstat,1,1))||lowcase(substr(lbstat,2));
			if not anylower(lbreasnd) then lbreasnd = upcase(substr(lbreasnd,1,1))||lowcase(substr(lbreasnd,2));

			if missing(lbstat) then lbstat = 'Missing';
			if missing(lbreasnd) then lbreasnd = 'Missing';

			length stat_reasn $109;
			stat_reasn =trim(lbstat)||'/'||trim(lbreasnd);

			if first.lbtest then order = 0;
			order + 1;

			/* pick out top three */
			if order in (1,2,3);
		end;

		keep lbtest stat_reasn count;
	run;

	proc transpose data=lb_rpt_lbstresn_miss0_reasn out=lb_rpt_lbstresn_miss0_reasn_x prefix=top;
		by lbtest; 
		var stat_reasn count;
	run;

	/* find max number of reasons or 3 if max is greater than 3 */
	proc sql noprint;
		select min(3,max(count)) into: max_reasn_count
		from (select lbtest, sum(case when count is not missing then 1 else 0 end) as count
		      from lb_rpt_lbstresn_miss0_reasn
			  group by lbtest);
	quit;

	/* combine top min(3,max_reasn_count) statuses/reasons with counts */
	data lb_rpt_lbstresn_miss0;
		merge lb_rpt_lbstresn_miss0_count(in=a)
		      lb_rpt_lbstresn_miss0_reasn_x(where=(_name_='stat_reasn') 
                                            rename=(%do i = 1 %to &max_reasn_count.; top&i.=sr&i. %end;) in=b)
		      lb_rpt_lbstresn_miss0_reasn_x(where=(_name_='count') 
                                            rename=(%do i = 1 %to &max_reasn_count.; top&i.=cnt&i. %end;) in=c)
			  ;
		by lbtest;
		length top3 $500;
		top3 = %do i = 1 %to &max_reasn_count.;
		       		ifc(cnt&i. ne ., trim(sr&i.)||' ('||trim(put(100*cnt&i./missing,8. -l))||'%)','')||' '||
					%if &i. < &max_reasn_count. %then %do; '~!'|| %end;
               %end;
			   ''
               ;
		if &max_reasn_count. = 0 then top3 = 'N/A';
		top3 = tranwrd(top3,'~!','0a'x);
		keep lbtest missing pct top3;
		if a;
	run;

	/*proc datasets library=work nolist nodetails; delete lbm_val lb_rpt_lb lb_rpt_lbstresn_miss0_:; quit;*/

%mend liver_lbstresn_missing;


/*********************************************************/
/* find counts of subjects and lab tests missing LLN/ULN */
/*********************************************************/
%macro liver_lbstnrhilo_missing;

	data lbm_val;
		length lbtest $8;
		lbtest = 'ALT'; output;
		lbtest = 'AST'; output;
		lbtest = 'ALP'; output;
		lbtest = 'TB'; output;
	run;

	/* get lab tests where ULN or LLN is missing */
	data lb_rpt_limit_miss_list;
		set lb(keep=usubjid lbtestcd lbdtc lbstresn lbstresu lbstnrlo lbstnrhi);
		where upcase(lbtestcd) in (&l_alt.,&l_ast.,&l_alp.,&l_bili.) 
		      and lbstresn is not missing
		      and (lbstnrlo is missing or lbstnrhi is missing);

		length lbtest $3;
		if lbtestcd in (&l_alt.) then lbtest = 'ALT';
		else if lbtestcd in (&l_ast.) then lbtest = 'AST';
		else if lbtestcd in (&l_alp.) then lbtest = 'ALP';
		else if lbtestcd in (&l_bili.) then lbtest = 'TB';
		drop lbtestcd;

		length lbstres $25;
		lbstres = trim(put(lbstresn,8.1 -l))||' '||lbstresu;
		drop lbstresn lbstresu;
		rename lbstres=lbstresn;

		format lbdt e8601da.;
		lbdt = input(lbdtc,?? e8601da.);
		drop lbdtc;

		/* look up arm from demographics */
		if _n_ = 1 then do;
			declare hash h(dataset:'demographics(keep=usubjid arm)');
			h.definekey('usubjid');
			h.definedata('arm');
			h.definedone();
		end;

		%if &dm_actarm. %then %do; length arm $&dm_actarm_len.; %end;
		%else %do; length arm $&dm_arm_len.; %end;
		call missing(arm);
		rc = h.find();
		drop rc;
	run;

	/* reorder variables */
	data lb_rpt_limit_miss_list;
		retain arm usubjid lbtest lbdt lbstresn lbstnrlo lbstnrhi;
		set lb_rpt_limit_miss_list;
	run; 

	
	/*********************************/
	/* MISSING UPPER LIMIT OF NORMAL */
	/*********************************/

	/* get all lab tests where ULN is missing and the lab test result itself is not */
	proc sql noprint;
		create table lb_rpt_uln_miss_list as
		select arm, usubjid, lbtest, lbdt, lbstresn
		from lb_rpt_limit_miss_list
		where lbstnrhi is missing;

		create table lb_rpt_uln_miss as
		select (case when a.arm is missing then b.arm else a.arm end) as arm, 
               (case when a.lbtest is missing then b.lbtest else a.lbtest end) as lbtest, 
               hi_miss_subj_count, 
               hi_miss_test_count
		from (select arm, lbtest, count(1) as hi_miss_subj_count
		      from (select distinct arm, usubjid, lbtest
                    from lb_rpt_uln_miss_list)
		      group by arm, lbtest) a
		full join (select arm, lbtest, count(1) as hi_miss_test_count
		           from lb_rpt_uln_miss_list
                   group by arm, lbtest) b
		on a.arm = b.arm
		and a.lbtest = b.lbtest;

		/* make dataset to join with */
		create table lbm_val_cp as
		select arm, lbtest
		from treatment_arms a,
		     lbm_val b
		order by arm, lbtest;

		select count(1) into: uln_nobs from lb_rpt_uln_miss_list;
	quit; 

    proc sort data = lb_rpt_uln_miss_list;
		  by arm lbtest;
	run;


	%if &uln_nobs. > 100 %then %do;
	    
		data lb_rpt_uln_miss_list;
			retain arm usubjid;
			set lb_rpt_uln_miss_list(rename=(arm=arm_t)) end=eof;
			by arm_t;
			
			length arm $250;
			arm = arm_t;

			if first.arm_t then n = 0;
			n+1;
			if n <= floor(100/&num.) then output;
			if eof then do;
				arm = 'There were '||trim(put(&uln_nobs.,comma. -l))||' lab tests missing ULN';
				usubjid = 'List truncated at 100';
				lbtest = '.';
				lbdt = .;
				lbstresn = '.';
				output;
			end;

			drop arm_t n;
		run;
	%end;

	/* merge the subject and test counts onto arm/lab tests */
	data lb_rpt_uln_miss;
		retain arm lbtest hi_miss_subj_count hi_miss_test_count;
		merge lbm_val_cp
			  lb_rpt_uln_miss;
		by arm lbtest;

		/* set missing values to 0 */
		array num{*} _numeric_;
		do i = 1 to dim(num);
			if num(i) = . then num(i) = 0;
		end;
		drop i;
	run;

	proc sort data = lb_rpt_uln_miss_list;
	  by arm usubjid lbtest;
	run;


	/* format the lists of tests for output */
	data lb_rpt_uln_miss_list;
		retain arm usubjid blank1 blank2 lbtest lbdt lbstresn;
		set lb_rpt_uln_miss_list;
		by arm usubjid lbtest;
		if not first.arm then arm = '';
		if not first.usubjid then usubjid = '';
		if not first.lbtest then lbtest = '';
		call missing(blank1,blank2);
	run;

	proc sort data = lb_rpt_uln_miss;
	  by arm lbtest;
	run;

	data lb_rpt_uln_miss;
		set lb_rpt_uln_miss;
		by arm lbtest;
		if not first.arm then arm = '';
		if not first.lbtest then lbtest = '';
	run;


	/*************************************/
	/* MISSING LOWER LIMIT OF NORMAL ALP */
	/*************************************/
	
	/* get all lab tests where ULN or LLN is missing and the lab test result itself is not */
	proc sql noprint;
		create table lb_rpt_lln_alp_miss_list as
		select arm, usubjid, lbdt, lbstresn
		from lb_rpt_limit_miss_list
		where lbtest = 'ALP'
		and lbstnrlo is missing;

		create table lb_rpt_lln_alp_miss as
		select (case when a.arm is missing then b.arm else a.arm end) as arm, 
               lo_miss_subj_count, 
               lo_miss_test_count
		from (select arm, count(1) as lo_miss_subj_count
		      from (select distinct arm, usubjid
                    from lb_rpt_lln_alp_miss_list)
		      group by arm) a
		full join (select arm, count(1) as lo_miss_test_count
		           from lb_rpt_lln_alp_miss_list
                   group by arm) b
		on a.arm = b.arm; 

		select count(1) into: lln_nobs from lb_rpt_lln_alp_miss_list;
	quit;

	%if &lln_nobs. > 100 %then %do;
		data lb_rpt_lln_alp_miss_list;
			retain arm usubjid;
			set lb_rpt_lln_alp_miss_list(rename=(arm=arm_t)) end=eof;
			by arm_t;
			
			length arm $250;
			arm = arm_t;

			if first.arm_t then n = 0;
			n+1;
			if n <= floor(100/&num.) then output;
			if eof then do;
				arm = 'There were '||trim(put(&lln_nobs.,comma. -l))||' lab tests missing LLN';
				usubjid = 'List truncated at 100';
				lbdt = .;
				lbstresn = '.';
				output;
			end;

			drop arm_t n;
		run;
	%end;

	/* merge the subject and test counts onto the arm names */
	data lb_rpt_lln_alp_miss;
		retain arm lo_miss_subj_count lo_miss_test_count;
		merge treatment_arms
			  lb_rpt_lln_alp_miss;
		by arm;

		/* set missing values to 0 */
		array num{*} _numeric_;
		do i = 1 to dim(num);
			if num(i) = . then num(i) = 0;
		end;
		drop i;

		keep arm lo_miss_subj_count lo_miss_test_count;
	run;

   proc sort data  = lb_rpt_lln_alp_miss_list;
     by arm usubjid;
   run;

	/* format the lists of tests for output */
	data lb_rpt_lln_alp_miss_list;
		retain arm usubjid blank1 blank2 lbdt lbstresn;
		set lb_rpt_lln_alp_miss_list;
		by arm usubjid;
		if not first.arm then arm = '';
		if not first.usubjid then usubjid = '';
		call missing(blank1,blank2);
	run;

%mend liver_lbstnrhilo_missing;


/******************************************************************/
/* find counts of the number of each kind of liver lab test in LB */
/* for each subject in DM                                         */
/******************************************************************/
%macro liver_lbtest_count(dm=,lb=);

	proc sql noprint;
		create table lb_cnt_&lb. as
		select a.usubjid, 
	           (case when alt >= 0 then alt else 0 end) as alt, 
	           (case when ast >= 0 then ast else 0 end) as ast, 
	           (case when bili >= 0 then bili else 0 end) as bili, 
	           (case when alp >= 0 then alp else 0 end) as alp
		from (select distinct usubjid from &dm.) a
		left join (select usubjid,
	                      sum(case when lbtest = 'Alanine Aminotransferase' then 1 else 0 end) as alt,
		                  sum(case when lbtest = 'Aspartate Aminotransferase' then 1 else 0 end) as ast,
			              sum(case when lbtest = 'Total Bilirubin' then 1 else 0 end) as bili,
			              sum(case when lbtest = 'Alkaline Phosphatase' then 1 else 0 end) as alp
		           from &lb.
		           group by usubjid
				  )	b
		on a.usubjid = b.usubjid;
	quit;

%mend liver_lbtest_count;


/****************************************************************************************/
/* find lab tests with abnormal results for subjects with missing baseline lab tests    */
/* corresponding to the missing baseline lab tests                                      */
/* find counts per arm of the number of subjects missing one or more baseline lab tests */
/****************************************************************************************/
%macro liver_missing_bl;

	/* find subjects with missing baseline lab tests */
	%liver_lbtest_count(dm=demographics,lb=baseline_labs);

	proc sql noprint;
		select count(1) into: arm_count
		from treatment_arms;
	quit;

	data lb_all_labs;
		set %do i = 1 %to &arm_count.; all_labs_arm&i. %end;;
	run;

	proc sql noprint;
		/* get all subjects who had a missing baseline lab but had post-baseline lab tests */
		create table lb_missing_bl_subj as
		select *
		from lb_cnt_baseline_labs
		where not (alp & alt & ast & bili)
		and usubjid in (select distinct usubjid from max_labs_all);

		/* get all lab visits & results for subjects with missing baseline lab tests */
		create table lb_err_sv as
		select *
		from lb_all_labs
		where usubjid in (select usubjid from lb_missing_bl_subj)
		and lbblfl ne 'Y';

		drop table lb_all_labs;
	quit;

	/* keep only visits where there was an abnormal result */
	data lb_err_sv_abnormal;
		retain usubjid arm;
		set lb_err_sv;
		if (%do i = 1 %to 3; %let lbtestcd = %scan(AST ALT ALP,&i.); 
            &lbtestcd.x2 or &lbtestcd.x3 or &lbtestcd.x5 or &lbtestcd.x10 or &lbtestcd.x20 or
			%end;
			BILIx1_5 or BILIx2 or BILIx3);
	run;

	proc sort data=lb_err_sv_abnormal; by usubjid vnum; run;

	/* tranpose to give one row per subject, visit, and lab test result */
	proc transpose data=lb_err_sv_abnormal(keep=usubjid vnum astx: altx: alpx: /*alp_gehi*/ bilix:)
                   out=lb_err_svl(rename=(_name_=varname col1=value));
		by usubjid vnum;
	run;

	/* keep only lab test results which were abnormal */
	data lb_err_svl;
		set lb_err_svl;
		if index(varname,'x') then lbtestcd = substr(varname,1,index(varname,'x')-1);
		if lbtestcd = '' then lbtestcd = substr(varname,1,index(varname,'_')-1);
		if compress(varname,,'dk') ne '' 
			then x = input(translate(compress(varname,'_','dk'),'.','_'),8.);
		if value then output;
	run;

	proc sort data=lb_err_svl; by usubjid vnum lbtestcd x; run;

	/* keep only the highest lab test result per lab test */
	data lb_err_svl_abnormal;
		set lb_err_svl;
		by usubjid vnum lbtestcd;
		if last.lbtestcd;
	run;

	/* get actual lab results and merge with the abnormal tests */
	data lb_err_res;
		set %do i = 1 %to 4;
				%let lbtestcd = %scan(AST ALT ALP BILI,&i.);
				lb_err_sv_abnormal(keep=usubjid arm vnum 
                                        &lbtestcd. &lbtestcd._res &lbtestcd._lo &lbtestcd._hi &lbtestcd._unit
										&lbtestcd._date
                                   rename=(&lbtestcd.=lbtestcd &lbtestcd._res=res &lbtestcd._lo=lo &lbtestcd._hi=hi
                                           &lbtestcd._unit=unit &lbtestcd._date=datec))
			%end;
			;
		format date e8601da.;
		date = input(datec,?? e8601da.);
		where lbtestcd ne '';
		drop datec;
	run;

	proc sort data=lb_err_res; by usubjid vnum lbtestcd; run;

	data lb_err_svl_abnormal;
		retain usubjid arm;
		merge lb_err_svl_abnormal(in=a) lb_err_res(in=b);
		by usubjid vnum lbtestcd;
		if a;
	run;

	proc sort data=lb_err_svl_abnormal; by usubjid lbtestcd vnum; run;

	/* find which baseline lab tests are missing and keep only abnormal results for those tests */
	data lb_err_subj_miss_bl;
		set lb_missing_bl_subj; 
		length lbtestcd $4;	
		if alp = 0 then do; lbtestcd = 'ALP'; output; end;
		if alt = 0 then do; lbtestcd = 'ALT'; output; end;
		if ast = 0 then do; lbtestcd = 'AST'; output; end;
		if bili = 0 then do; lbtestcd = 'BILI'; output; end;
		keep usubjid lbtestcd;
	run;

	/* create list of subjects with missing baseline lab test results */
	/* AND abnormal subsequent lab test results */
	proc sql noprint;
		create table lb_rpt_subj_miss_bl_list as
		select a.arm, a.usubjid, a.lbtestcd, a.date, 
		       (case when a.x ne . then trim(ifc(x - floor(x) ne 0,put(a.x,8.1 -L),put(a.x,8. -L)))||'x' else '1x' end) as x_uln,
			   res, unit, hi
		from lb_err_svl_abnormal a, lb_err_subj_miss_bl b
		where a.usubjid = b.usubjid
		and a.lbtestcd = b.lbtestcd
		order by arm, usubjid, lbtestcd, date;
	quit;

	/* make suitable for output */
	data lb_rpt_subj_miss_bl_list;
		set lb_rpt_subj_miss_bl_list;
		by arm usubjid lbtestcd;
		if not first.usubjid then usubjid = '';
		if not first.arm then arm = '';
		if not first.lbtestcd then lbtestcd = '';
	run;

	data lb_rpt_subj_miss_bl_list;
		retain arm usubjid blank1 blank2 blank3 lbtestcd date result result_vs_uln;
		set lb_rpt_subj_miss_bl_list(rename=(date=daten));

		length date $10;
		date = put(daten,e8601da.);
		drop daten;

		blank1 = '';
		blank2 = ''; 
		blank3 = '';
		if lbtestcd = 'BILI' then lbtestcd = 'TB';
		length result $25 result_vs_uln $25;
		result = trim(left(ifn(res-floor(res) ne 0,put(res,8.1),put(res,8.))))||' '||unit;
		result_vs_uln = trim(x_uln)||' ULN ('||trim(left(ifn(res-floor(hi) ne 0,put(hi,8.1),put(hi,8.))))||')';
		keep arm usubjid blank1 blank2 blank3 lbtestcd date result result_vs_uln;
	run;

	/* find counts of the number of subjects with missing baseline lab tests */
	proc sql noprint;
		create table lb_rpt_subj_miss_bl as
		select a.arm, 
               (case when miss_bl_total_count is missing then 0 else miss_bl_total_count end) as miss_bl_total_count, 
		       %do i = 1 %to 4;	
			   %let lbtest = %scan(alp alt ast bili,&i.);
                  (case when miss_bl_&lbtest._count is missing then 0 else miss_bl_&lbtest._count end) as miss_bl_&lbtest._count, 
			   %end;
			   total_count
		from (select arm, count(1) as total_count
		      from (select distinct usubjid, arm from max_labs_all)
			  group by arm)	a
		left join (select arm, 
		                  sum(case when not (alp & alt & ast & bili) then 1 else 0 end) as miss_bl_total_count,
					      %do i = 1 %to 4;
					         %let lbtest = %scan(alp alt ast bili,&i.);
                             sum(case when not &lbtest. then 1 else 0 end) as miss_bl_&lbtest._count, 
					      %end;
						  0 as null
			       from lb_missing_bl_subj a,
				        demographics b
				   where a.usubjid = b.usubjid
			       group by arm) b
		on a.arm = b.arm
		;
	quit;

	/* make suitable for output */
	data lb_rpt_subj_miss_bl;
		set lb_rpt_subj_miss_bl;
		%do i = 1 %to 5;
		%let lbtest = %scan(total alp alt ast bili,&i.);
			miss_bl_&lbtest._pct = 100*miss_bl_&lbtest._count/total_count;
			length miss_bl_&lbtest. $25;
			miss_bl_&lbtest. = trim(put(miss_bl_&lbtest._count,8. -L))||' '||'0a'x||
                                    '('||trim(put(miss_bl_&lbtest._pct,4.1 -l))||')';
			keep miss_bl_&lbtest.;
		%end;
		keep arm;
	run;

	/*proc datasets library=work nolist nodetails; delete lb_err: lb_missing_bl_subj; quit;*/

%mend liver_missing_bl;


/****************************************************************/
/* find counts of subjects without any (non-baseline) lab tests */
/* list subjects without non-baseline lab tests                 */
/****************************************************************/
%macro liver_missing_pbl;

	%liver_lbtest_count(dm=demographics,lb=max_labs_all); 

	proc sql noprint;
		create table lb_rpt_subj_miss_pbl_list as
		select b.arm, a.usubjid
		from lb_cnt_max_labs_all a,
	         demographics b
		where a.usubjid	= b.usubjid
		and alp = 0 & alt = 0 & ast = 0 & bili = 0
		and a.usubjid in (select distinct usubjid 
		                from baseline_labs)
		order by arm;
	quit;

	proc sql noprint;
		create table lb_rpt_subj_miss_pbl as
		select a.arm, 
               (case when miss_pbl_count is missing then 0 else miss_pbl_count end) as miss_pbl_count, 
               (case when miss_pbl_count is missing then 0 else 100*miss_pbl_count/total_count end) as miss_pbl_pct
		from (select distinct arm from demographics) a
		left join (select b.arm, 
                   sum(case when (alp = 0 & alt = 0 & ast = 0 & bili = 0) then 1 else 0 end) as miss_pbl_count, 
                   count(1) as total_count
			       from (select *
                         from lb_cnt_max_labs_all) a,
	                     demographics b
			       where a.usubjid	= b.usubjid
			       and a.usubjid in (select distinct usubjid
                                     from baseline_labs)
			       group by arm
			       ) b
		on a.arm = b.arm;

		select count(1) into: nobs from lb_rpt_subj_miss_pbl_list;
	quit;

	%if &nobs. > 100 %then %do;
		%truncate(count=lb_rpt_subj_miss_pbl,list=lb_rpt_subj_miss_pbl_list);
	%end;

	/* format for output */
	data lb_rpt_subj_miss_pbl_list;
		set lb_rpt_subj_miss_pbl_list;
		by arm;
		if not first.arm then arm = '';
	run;

%mend liver_missing_pbl;


/*************************************************/
/* find counts of subjects without any lab tests */
/* list subjects without lab tests               */
/*************************************************/
%macro liver_missing_all;

	proc sql noprint;
		create table lb_rpt_subj_miss_all_list as
		select arm, usubjid
		from demographics
		where usubjid not in (select distinct usubjid
		                      from baseline_labs)
		and usubjid not in (select distinct usubjid
		                    from max_labs_all)
		order by arm, usubjid;

		create table lb_rpt_subj_miss_all as
		select a.arm,
               (case when miss_count is missing then 0 else miss_count end) as miss_all_count, 
               (case when miss_count is missing then 0 else 100*miss_count/total_count end) as miss_all_pct
		from (select arm, count(1) as total_count
              from demographics
              group by arm) a
		left join (select arm, count(1) as miss_count
			       from lb_rpt_subj_miss_all_list
                   group by arm) b
		on a.arm = b.arm;

		select count(1) into: nobs from lb_rpt_subj_miss_all_list;
	quit; 

	%if &nobs. > 100 %then %do;
		%truncate(count=lb_rpt_subj_miss_all,list=lb_rpt_subj_miss_all_list);
	%end;

	/* format for output */
	data lb_rpt_subj_miss_all_list;
		set lb_rpt_subj_miss_all_list;
		by arm;
		if not first.arm then arm = '';
	run;

%mend liver_missing_all;


/* truncate long lists of subject IDs at max */
/* and equalize the number of subject IDs per arm */
%macro truncate(count=,list=);

	%let max = 100;

	proc sql noprint;
		select name	into: countvar
		from dictionary.columns
		where memname = upcase("&count.")
		and index(name,'count');

		select count(1) into: arm_count
		from &count.;
	quit;

	proc sort data=&count. out=t_&count.; 
		by descending &countvar.;
	run;

	data t_&count.;
		set t_&count.;
		retain n remainder;

		if _n_ = 1 then n = &arm_count.;
		else n = n - 1;

		if _n_ = 1 then do;
			remainder = &max.;
			portion = min(&countvar.,floor(remainder/n)); 
		end;
		
		lag = lag(portion);

		if _n_ ne 1 then do;
			remainder = remainder - lag;
			portion = min(&countvar.,floor(remainder/n)); 
		end;

		keep arm portion;
	run;

	proc sql noprint;
		create table &list._t as
		select a.*, b.portion
		from &list. a,
		     t_&count. b
		where a.arm = b.arm
		order by arm, usubjid;

		select count(1) into: subj_count
		from &list.;
	quit;

	data &list._t;
		set &list._t(rename=(arm=arm_t usubjid=usubjid_t)) end=eof;
		by arm_t;
		if first.arm_t then n = 0;
		n + 1;

		length arm $100 usubjid $100;
		arm = arm_t;
		usubjid = usubjid_t;

		if n <= portion then output;

		if eof and &subj_count. > &max. then do;
			arm = compbl("There were &subj_count. subjects in total.");
			usubjid = 'List truncated at 100 subjects.';
			output;
		end;

		keep arm usubjid;
	run;

	proc datasets library=work nolist nodetails;
		change &list.=&list._full &list._t=&list.;
		delete t_&count.;
	quit;
		
%mend truncate;


/**************************************************/
/* analyze the distribution of visit/visit number */
/**************************************************/
%macro liver_visitnum;

	%if &lb_visitnum. %then %do;
		proc sql noprint;
			create table lb_rpt_lb_uvv as
			select distinct usubjid, visitnum, visit
			from labdata; 
		quit;

		proc sql noprint;
			create table lb_rpt_visitnum as
			select visit, visitnum, count(1) as total
			from lb_rpt_lb_uvv
		    group by visitnum, visit;

			drop table lb_rpt_lb_uvv;
		quit;
	%end;
	%else %do;
		data lb_rpt_visitnum;
			text = 'VISITNUM was not present in LB';
		run;
	%end;

%mend liver_visitnum;


/**********************************/
/* run liver analysis data checks */
/**********************************/
%macro liver_check;

	%put LIVER LABS ANALYSIS DATA CHECKS;

	%liver_lbstresn_missing;
	
	%liver_lbstnrhilo_missing;

	%liver_missing_bl;

	%liver_missing_pbl;

	%liver_missing_all;

	%liver_visitnum;

%mend liver_check;


/*********************************************/
/* output liver check data to Excel template */
/*********************************************/
%macro liver_check_output;

	%if not %symexist(run_location) %then %let run_location = LOCAL;

	/* local runs use the Microsoft Jet database-based Excel LIBNAME engine */
	%if %upcase(&run_location.) = LOCAL %then %do;
		*libname xls excel "&liverout." ver=2003; *Output function changed due to SAS 9.3(64bit) and Excel 2010(32bit) incompatability;
		libname xls pcfiles path="&liverout.";
	%end;
	/* Script Launcher runs use the PCFILES LIBNAME Engine */
	%else %do;
		libname xls pcfiles path="&liverout."; 
	%end;

	proc sql noprint;
		drop table xls.missbl,
				   xls.missbl_list,
                   xls.misspbl,
				   xls.misspbl_list, 
		           xls.missall,
				   xls.missall_list,  
		           xls.missuln,
				   xls.missuln_list, 
		           xls.misslln,
				   xls.misslln_list, 
                   xls.lbstresn_miss0,
				   xls.visitnum,
				   xls.dcinfo
                   ;
	quit;  	

	data xls.missbl;
		set lb_rpt_subj_miss_bl;
	run;

	data xls.missbl_list;
		set lb_rpt_subj_miss_bl_list;
	run; 

	data xls.misspbl;
		set lb_rpt_subj_miss_pbl;
	run;

	data xls.misspbl_list;
		set lb_rpt_subj_miss_pbl_list;
	run;   

	data xls.missall;
		set lb_rpt_subj_miss_all;
	run;

	data xls.missall_list;
		set lb_rpt_subj_miss_all_list;
	run;  

	data xls.missuln;
		set lb_rpt_uln_miss;
	run;

	data xls.missuln_list;
		set lb_rpt_uln_miss_list;
	run;  

	data xls.misslln;
		set lb_rpt_lln_alp_miss;
	run;

	data xls.misslln_list;
		set lb_rpt_lln_alp_miss_list;
	run;  

	data xls.lbstresn_miss0;
		set lb_rpt_lbstresn_miss0;
	run;  

	data xls.visitnum;
		set lb_rpt_visitnum;
	run;

	/* data check info */
	proc sql noprint;
		select count(1) into: arm_count
		from treatment_arms;

		select count(1) into: missbl_list
		from lb_rpt_subj_miss_bl_list;

		select count(1) into: misspbl_list
		from lb_rpt_subj_miss_pbl_list;

		select count(1) into: missall_list
		from lb_rpt_subj_miss_all_list;

		select count(1) into: missuln_list
		from lb_rpt_uln_miss_list;

		select count(1) into: missalplln_list
		from lb_rpt_lln_alp_miss_list;
	quit;

	data xls.dcinfo;
		length data $25;
		data = 'arm_count'; val = %sysfunc(ifc(%symexist(arm_count),&arm_count.,0)); output;
		data = 'missbl_list'; val = %sysfunc(ifc(%symexist(missbl_list),&missbl_list.,0)); output;
		data = 'misspbl_list'; val = %sysfunc(ifc(%symexist(misspbl_list),&misspbl_list.,0)); output; 
		data = 'missall_list'; val = %sysfunc(ifc(%symexist(missall_list),&missall_list.,0)); output;
		data = 'missuln_list'; val = %sysfunc(ifc(%symexist(missuln_list),&missuln_list.,0)); output;
		data = 'missalplln_list'; val = %sysfunc(ifc(%symexist(missalplln_list),&missalplln_list.,0)); output;
		data = 'visitnum'; val = %sysfunc(ifc(%symexist(lb_visitnum),&lb_visitnum.,0)); output;
	run;

	libname xls clear;

%mend liver_check_output;
