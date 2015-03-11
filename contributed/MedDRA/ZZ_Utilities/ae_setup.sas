/*******************************************/
/* ADVERSE EVENT PANEL SETUP               */
/* 	                                       */
/* 1. validate subjects and adverse events */
/* 2. merge AE, DM, and EX 	               */
/* 3. look up MedDRA terms and DMEs        */
/*******************************************/

/* REVISION HISTORY */
/*
2011-05-08  DK  Added handling for errors in case DM has no subjects

2011-05-31  DK  Modified the SQL that creates macro variables for 
                the number of AEs in the safety pop in the rpt_setup macro
                to handle the case of 0 AEs (previously would return a 0)

2011-06-18  DK  Changed the date validation to compare start and end separately
				in order to handle dates with missing days better

2011-06-19  DK  Added a check for long character strings in arm names
                and broke up those separated by slashes with an additional space
*/

/* sets up datasets for aggregation */
/* finds safety population and adverse events during study */
%macro setup(mdhier=N,dme=N);

	/* if data validation switch doesn't exist, set it to on */
	%if not %symexist(vld_sw) %then %let vld_sw = 1;

	/* if there is no study lag defined, set it to 30 days */
	%if not %symexist(study_lag) %then %let study_lag = 30;


	/**************************/
	/* preliminary datachecks */
	/**************************/

	%log_msg(DATA CHECKS);

	/* check that there are subjects in DM */
	%chk_dm_subj_gt0;


	/* required variables */
	%chk_var(ds=ae,var=aebodsys);
	%chk_var(ds=ae,var=aedecod);
	%chk_var(ds=ae,var=usubjid);

	%chk_var(ds=dm,var=usubjid);

	%chk_var(ds=ex,var=usubjid);

	data rpt_chk_var_req;
		set rpt_chk_var;
	run;

	/* actual arm or planned arm */
	%chk_var(ds=dm,var=actarm);
	%chk_var(ds=dm,var=arm);

	/* insert a row into RPT_CHK_VAR_REQ indicating whether actual arm OR arm exists */
	proc sql noprint;
		insert into rpt_chk_var_req
		set chk = 'VAR',
		    ds = 'DM',
			var = 'ACTARM or ARM',
			condition = 'EXISTS',
			ind = %sysfunc(ifc(&dm_actarm. or &dm_arm.,1,0));
	quit; 

	/* store which arm variable to use */
	%global arm_var;
	%if &dm_actarm. %then %let arm_var = ACTARM;
	%else %if &dm_arm. %then %let arm_var = ARM;
	%else %let arm_var = ;

	/* set a flag indicating whether all required variables are present */
	%global setup_req_var;
	%if &ae_aebodsys.
	    and &ae_aedecod.
		and &ae_usubjid.
        and (&dm_actarm. or &dm_arm.)
        and &dm_usubjid. 
        and &ex_usubjid. %then %let setup_req_var = 1;
	%else %let setup_req_var = 0;

	%if not &dm_subj_gt0. or not &setup_req_var. %then %goto setup_exit;

	/* optional variables */
	%chk_var(ds=ae,var=aestdtc);
	%chk_var(ds=ae,var=aeser); 
	%chk_var(ds=ae,var=aesev);
	%chk_var(ds=ae,var=aetoxgr);
	%chk_var(ds=dm,var=rfstdtc); 
	%chk_var(ds=dm,var=rfendtc);
	%chk_var(ds=dm,var=armcd);
	%chk_var(ds=ex,var=exstdtc);
	%chk_var(ds=ex,var=exendtc);

	%let ex_exdtc = /*&ex_exstdtc.*/ %sysfunc(ifc(&ex_exstdtc. and &ex_exendtc.,1,0));
	%let dm_rfdtc = %sysfunc(ifc(&dm_rfstdtc. and &dm_rfendtc.,1,0));

	/* if no dates are available, turn off the AE validation */
	%if not (&ae_aestdtc. and (&ex_exdtc. or &dm_rfdtc.)) %then %do;
		%let vld_sw = 0;
		%put;
		%put WARNING: AE data validation has been turned off because required variables are missing;
		%put;
	%end;


	/***********************************/
	/* subjects from demographics (DM) */
	/***********************************/

	%log_msg(%str(DEMOGRAPHICS DOMAIN (DM)));

	data all_dm;
		set dm(keep=usubjid &arm_var. 
		            %if &dm_armcd. %then armcd;
                    %if &vld_sw. and &dm_rfdtc. %then rfstdtc rfendtc;
               );

		/* set the arm variable (either actual arm or planned arm) to ARM */
		arm = &arm_var.;

		/* exclude screen failures and unassigned subjects */
		%if &dm_armcd. %then %do;
			if upcase(armcd) in ('SCRNFAIL' 'NOTASSGN') then delete;
		%end;

		/* convert the subject reference character date fields to numeric */
		%if &vld_sw. and &dm_rfdtc. %then %do;
			length rfstdt 8. rfendt 8.;
			format rfstdt e8601da. rfendt e8601da.;
			label rfstdt='Subject Reference Start Date' rfendt='Subject Reference End Date';
			call missing(rfstdt,rfendt);

			rfstdt_len = length(trim(rfstdtc));
			if rfstdt_len >= 10 then rfstdt = input(substr(rfstdtc,1,10),?? e8601da.);
			else if rfstdt_len >= 7 then rfstdt = input(substr(rfstdtc,1,7)||'-01',?? e8601da.);

			rfendt_len = length(trim(rfendtc));
			if rfendt_len >= 10 then rfendt = input(substr(rfendtc,1,10),?? e8601da.);
			else if rfendt_len >= 7 then rfendt = input(substr(rfendtc,1,7)||'-01',?? e8601da.);

		%end;
	run;

	proc sort data=all_dm; by usubjid; run;


	/****************************************/
	/* safety population from exposure (EX) */
	/****************************************/

	%log_msg(%str(EXPOSURE DOMAIN (EX)));

	proc sql noprint;
		create table all_ex(drop=null) as
		select usubjid,
		       %if &vld_sw. /*and &ex_exdtc.*/ %then %do; 
			      /* find the min and max treatment dates in EX */
			      /* in order to use max(exstdtc,exendtc) as treatment end date, */
			      /* comment out line 175 and ex_exdtc condition on line 163 and uncomment lines 173-174 */
			      %if &ex_exstdtc. %then %do;
                     min(input(substr(exstdtc,1,10),? e8601da.)) as exstdt format=e8601da. 
                                                                           label='Treatment Start Date',
			         10 as exstdt_len,
			      %end;
			      %if &ex_exstdtc. and &ex_exendtc. %then %do;
                     max(max(input(substr(exstdtc,1,10),? e8601da.)),
                         max(input(substr(exendtc,1,10),? e8601da.)))
/*				     max(input(substr(exendtc,1,10),? e8601da.))*/
                        as exendt format=e8601da. label='Treatment End Date', 
			         10 as exendt_len,
			      %end;
				  %else %if &ex_exstdtc. %then %do;	
                     max(input(substr(exstdtc,1,10),? e8601da.)) as exendt format=e8601da. 
                                                                           label='Treatment End Date',
			         10 as exendt_len,
				  %end;
			   %end;
			   . as null
		from ex
		group by usubjid
		order by usubjid;
	quit;

	/**********************************************************/
	/* all subjects in the safety population assigned to arms */
	/**********************************************************/

	%log_msg(%str(SUBJECTS IN SAFETY POPULATION (DM & EX)));

	data all_dm_ex(keep=arm usubjid %if &vld_sw. %then trtstdt trtstdt_len trtendt trtendt_len;)
	     err_dm_ex;
		merge all_dm(in=a)
              all_ex(in=b);
		by usubjid;

		length err_type $10;

		/* if the subject is in both DM and EX, then output */
		if a and b then output = 1;
		else if a then do;;
			output = 0; 
			err_type = 'ex';
		end;
		else delete;

		%if &vld_sw. %then %do;
			if output then do;
				format trtstdt e8601da. trtendt e8601da.;
				label trtstdt='Subject Treatment Start Date' trtendt='Subject Treatment End Date';
				call missing(trtstdt,trtendt);

				/* use the treatment start and end dates from EX if available */
				%if &ex_exdtc. %then %do;
					if not missing(exstdt) and not missing(exendt) then do;
						trtstdt = exstdt;
						trtstdt_len = exstdt_len;
						trtendt = exendt;
						trtendt_len = exendt_len;
					end;
				%end;
				/* otherwise use the subject reference start and end dates from DM */
				%if &dm_rfdtc. %then %do;
					if not missing(rfstdt) and not missing(rfendt) and missing(trtstdt) and missing(trtendt) then do;
						trtstdt = rfstdt;
						trtstdt_len = rfstdt_len;
						trtendt = rfendt;
						trtendt_len = rfendt_len;
					end;
				%end;
				
				/* if the subject does not have valid start and end dates, then do not output */
				if missing(trtstdt) or missing(trtendt) then do;
					output = 0;
					err_type = 'dt';
				end;
			end;
		%end;

		if output then output all_dm_ex;
		else output err_dm_ex;
	run; 

	/* get counts of subjects per arm */
	proc sql noprint;
		create table all_arm as
		select arm, count(distinct usubjid) as count
		from all_dm_ex
		group by arm
		order by arm;

		/* get maximum arm name length */
		%global max_arm_nm_len;
		select max(length(arm)) into: max_arm_nm_len
		from all_arm;
	quit;

	data all_arm;
		set all_arm end=eof;

		arm_num = _n_;

		retain total;
		total = sum(total,count);

		call symputx('arm_'||put(_n_,8. -L),put(count,8. -L),'g');

		if eof then do;	
			call symputx('arm_count',put(_n_,8. -L),'g');
			call symputx('arm_total',put(total,8. -L),'g');
		end; 
	run; 

	/* assign arm numbers */
	data all_dm_ex;
		set all_dm_ex;

		if _n_ = 1 then do;
			declare hash h(dataset:'all_arm');
			h.definekey('arm');
			h.definedata('arm_num');
			h.definedone();
		end;

		length arm_num 8.;
		label arm_num='Arm Number';
		call missing(arm_num);
		rc = h.find();
		drop rc;
	run;

	/**************************************/
	/* import adverse events (AE) dataset */
	/**************************************/

	%log_msg(%str(ADVERSE EVENTS DOMAIN (AE)));

	data all_ae;
		retain usubjid aebodsys aedecod aeseq aestdtc;
		set ae(keep=usubjid aebodsys aedecod aeseq
		            %if &ae_aeser. %then aeser;
					%if &ae_aesev. %then aesev;
					%if &ae_aetoxgr. %then aetoxgr;
                    %if &vld_sw. %then aestdtc;
					aeendtc
               );

		/* change adverse event descriptions variables to proper noun case */
		if not anylower(aebodsys) then aebodsys = propcase(aebodsys);
		if not anylower(aedecod) then aedecod = propcase(aedecod);

		/* validate AETOXGR */
		%if &ae_aetoxgr. %then %do;
			%if %symexist(toxgr_min) and %symexist(toxgr_max) %then %do;
				/* convert from character to numeric if necessary */
				%if &ae_aetoxgr_type. = C %then %do;
					if not notdigit(aetoxgr) then aetoxgr_num = input(aetoxgr,8.);
				%end;
				%else %do;
					aetoxgr_num = aetoxgr;
				%end;

				if not (&toxgr_min. <= aetoxgr_num <= &toxgr_max.) then aetoxgr_num = .;
				drop aetoxgr;
				rename aetoxgr_num = aetoxgr;
			%end;
		%end;
		%else %do;
			call missing(aetoxgr);
		%end;

		/* convert the character start date/time of the AE to numeric */
		%if &vld_sw. %then %do;
			format aestdt e8601da.;
			label aestdt='Adverse Event Start Date';
			call missing(aestdt);

			aestdt_len = length(trim(aestdtc));

			if aestdt_len >= 10 then aestdt = input(substr(aestdtc,1,10),?? e8601da.);
			else if aestdt_len >= 7 
				then aestdt = mdy(input(substr(aestdtc,6,2),2.),1,input(substr(aestdtc,1,4),4.));
		%end;
	run;

	proc sort data=all_ae; by usubjid aebodsys aedecod aeseq; run;


	/******************************************************/
	/* find all adverse events whose subject              */
	/* is assigned to an arm and in the safety population */
	/******************************************************/
	
	%log_msg(%str(ADVERSE EVENTS FOR SUBJECTS IN SAFETY POPULATION (AE, DM, & EX)));

	data all_ae_dm_ex;
		merge all_dm_ex(in=a)
              all_ae(in=b)
		      ;
		by usubjid;
		if a and b;
	run;

	/* keep only those adverse events that took place during the study analysis period */
	/* keep counts of adverse events included and excluded in a reporting dataset */
	data ds_base(drop=err: %if &vld_sw. %then aestdt aestdt_len trtstdt: trtendt:;)
	     err_base(drop=total);
		set all_ae_dm_ex end=eof;

		total = 'Total'; /* for aggregating over all adverse events */

		length err 8 err_type $10 err_desc $50;
		call missing(err,err_type,err_desc);

		/* do data validation if data validation switch is on */
		%if &vld_sw. = 1 %then %do;

			if missing(aestdt) then do;
				output = 0;	
				err_type = 'dt';
				err = 1; err_desc = '1. Date missing or incomplete';
			end;
			else do; 
				/* compare the AE start date to the treatment start date */
				stdt_len = min(aestdt_len,trtstdt_len);

				if (10 <= stdt_len and not (aestdt >= trtstdt))
				or (7 <= stdt_len < 10 and not (mdy(month(aestdt),1,year(aestdt)) 
                                                >= mdy(month(trtstdt),1,year(trtstdt))))
				then do;
					output = 0;
					err_type = 'dt';
					err = 2; err_desc = '2. Date before study analysis period';
				end;
				
				/* compare the AE start date to the treatment end date */
				endt_len = min(aestdt_len,trtstdt_len);

				if (10 <= endt_len and not (intnx('day',trtendt,&study_lag.) >= aestdt))
				or (7 <= endt_len < 10 and not (intnx('month',mdy(month(trtendt),1,year(trtendt)),floor(&study_lag./30))
                                                >= mdy(month(aestdt),1,year(aestdt))))
				then do;
					output = 0;
					err_type = 'dt';
					err = 3; err_desc = '3. Date after study analysis period';
				end;

				if output ne 0 then output = 1;
			end;

			/* flag records with missing AEBODSYS or AEDECOD descriptions */
			if aebodsys = '' or aedecod = '' then do;
				output = 0;
				err_type = 'desc';
				err = 4; err_desc = '4. Description missing';
			end;
		%end;
		%else %do;
			output = 1;
		%end;

		if output then output ds_base;
		else output err_base;
	run;

	proc sort data=ds_base; by aebodsys aedecod; run; 


	/****************************************/
	/* MEDDRA AND DESIGNATED MEDICAL EVENTS */
	/****************************************/

	%if &mdhier. = Y %then %do;

		%log_msg(LOOK UP MEDDRA TERMS);

		/* merge by-subject/preferred term adverse events with */
		/* the appropriate version of the MedDRA hierarchy */
		data ds_base_meddra(drop=aebodsys aedecod)
		     err_base_meddra;
			set ds_base(drop=output);

			aebodsys = upcase(aebodsys);
			aedecod = upcase(aedecod);

			if _n_ = 1 then do;
				declare hash h(dataset:"meddra.mdhier_%sysfunc(translate(&ver.,'_','.'))");
				h.definekey('aebodsys','aedecod');
				h.definedata('soc_name','hlgt_name','hlt_name','pt_name');
				h.definedone();
			end;

			length soc_name $100 hlgt_name $100 hlt_name $100 pt_name $100;
			label soc_name='System Organ Class'
                  hlgt_name='High-Level Group Term'
                  hlt_name='High-Level Term'
                  pt_name='Preferred Term';
			call missing(soc_name,hlgt_name,hlt_name,pt_name);

			rc = h.find();
			if rc = 0 then output = 1;
			else output = 0;
			drop rc;

			/* add designated medical event flag */
			%if &dme. = Y %then %do;

				if _n_ = 1 then do;
					declare hash i(dataset:'dme.dme(rename=(llt_name=pt_name))');
					i.definekey('pt_name');
					i.definedata('dme');
					i.definedone();
				end;

				length dme $1;
				label dme='Designated Medical Event';
				call missing(dme);

				rc = i.find();
				drop rc;
			%end;

			if output then output ds_base_meddra;
			else output err_base_meddra;
		run;


		/* MedDRA matching report */
		/* get the counts of each term without a matching MedDRA description and number of subjects affected */
		proc sql noprint;
			/* store count and proportion of adverse events that were matched with MedDRA terms */
			create table rpt_meddra as
			select "MedDRA hierarchy version &ver." as meddra_ver, 
				   meddra_cnt,
			       err_cnt,
				   100*meddra_cnt/(meddra_cnt+err_cnt) as meddra_pct
			from (select count(1) as meddra_cnt from ds_base_meddra),
                 (select count(1) as err_cnt from err_base_meddra);	

			%global meddra_pct meddra;
			select meddra_pct
	               into : meddra_pct
			from rpt_meddra;

			create table rpt_meddra_term as
			select (case when a.aebodsys is missing then b.aebodsys else a.aebodsys end) as aebodsys
			        label='Body System or Organ Class',
	               (case when a.aedecod is missing then b.aedecod else a.aedecod end) as aedecod
			        label='Dictionary-Derived Term',
	               subj_count, event_count
			from (select aebodsys, aedecod, count(distinct usubjid) as subj_count label='No Matching MedDRA Description Subject Count'
			      from err_base_meddra
				  group by aebodsys, aedecod) a,
				 (select aebodsys, aedecod, count(1) as event_count label='No Matching MedDRA Description Event Count'
				  from err_base_meddra
				  group by aebodsys, aedecod) b
			where a.aebodsys = b.aebodsys
			and a.aedecod = b.aedecod;
		quit;

		data rpt_meddra_term;
			set rpt_meddra_term;
			aebodsys = propcase(aebodsys);
			aedecod = propcase(aedecod);
		run;

	%end;

	/* write out arms into macro variables in propcase form */
	data all_arm;
		set all_arm end=eof;

		/* put words into propcase, leave acronyms and abbreviations as-is */
		arm_display = arm;
		if arm_display ne '' and not anylower(arm_display) then do;
			length arm_word $50;
			i = 1;
			arm_word = scan(arm_display,i);
			do while (arm_word ne '');
				if length(arm_word) > 3 and not anydigit(compress(arm_word)) 
						then substr(arm_display,index(arm_display,compress(arm_word)),length(compress(arm_word))) = propcase(compress(arm_word));
				if compress(arm_word) in ('UP') 
					then substr(arm_display,index(arm_display,compress(arm_word)),length(compress(arm_word))) = propcase(arm_word);
				if compress(arm_word) in ('MG' 'KG') 
					then substr(arm_display,index(arm_display,compress(arm_word)),length(compress(arm_word))) = lowcase(arm_word);
				if compress(arm_word) = ('ML') 
					then substr(arm_display,index(arm_display,compress(arm_word)),length(compress(arm_word))) = 'mL';
				i = i + 1;
				arm_word = scan(arm_display,i);
			end;
		end;

		/* if the arm name has long character strings broken only by slashes, add spaces */
		if index(arm_display,'/') then do;
			i = 1;
			arm_word = scan(arm_display,i,' ');
			do while (arm_word ne '');
				if length(arm_word) > 40 and index(arm_word,'/') then longword = 1;
				i = i + 1; 
				arm_word = scan(arm_display,i,' ');
			end;
			if longword = 1 then arm_display = tranwrd(arm_display,'/','/ ');
		end;

		call symputx('arm_name_'||put(_n_,8. -L),arm_display,'g');

		drop arm_word i;
	run; 		
	
	/* create setup reporting datasets */
	%rpt_setup;

	%setup_exit: %global setup_success;
                 %if not &dm_subj_gt0. or not &setup_req_var. %then %do;
				 	%if not &dm_subj_gt0. %then %put ERROR: There are no subjects in DM;
	                %if not &setup_req_var. %then %put ERROR: Some variables required for AE setup are missing;
                    %let setup_success = 0;
	             %end;
				 %else %let setup_success = 1;

%mend setup;


/* reporting info on data validation and MedDRA matching */
%macro rpt_setup;

	/* DEMOGRAPHICS */
	/* subject validation */

	%log_msg(SUBJECT VALIDATION REPORT);

	data all_dm_ex;
	set all_dm_ex;
	rename arm = &arm_var.;
	run;

	/* get counts of the subjects removed before arriving at the set of subjects */
	/* used in the analysis */
	proc sql;
		create table rpt_dm(drop=order) as

		/* Subjects in demographics (DM) */
		select 1 as order, '1. Subjects in demographics (DM)' as desc,
		       %do i = 1 %to &arm_count.;
			      sum(case 
                      when compress(upcase(&arm_var.)) = compress(upcase("&&&arm_name_&i.")) 
                           then 1 
                           else 0 
                      end) 
				  as arm&i._count,
			   %end;
			   count(1) as total_count
		from dm

		union

		/* Subjects removed - unassigned/screen failure */
		select 2 as order, '2. Subjects removed - unassigned/screen failure' as desc,
               %if &dm_armcd. %then %do;
			       %do i = 1 %to &arm_count.;
				      sum(case 
	                      when compress(upcase(&arm_var.)) = compress(upcase("&&&arm_name_&i.")) 
                               and upcase(armcd) in ('SCRNFAIL','NOTASSGN')
	                           then 1 
	                           else 0 
	                      end) 
                      as arm&i._count,
				   %end;
				   sum(case when upcase(armcd) in ('SCRNFAIL','NOTASSGN')then 1 else 0 end) as total_count
			   %end;
			   %else %do;
			       %do i = 1 %to &arm_count.;
				      0 as arm&i._count,
				   %end;
				   0 as total_count
			   %end;
		from dm

		union

		/* Subjects removed - not in safety population */
		select 3 as order, '3. Subjects removed - not in safety population' as desc,
		       %do i = 1 %to &arm_count.;
			      (case when arm&i._count is missing then 0 else arm&i._count end) as arm&i._count,
			   %end;
			   total_count
		from (select %do i = 1 %to &arm_count.;
			            sum(case 
                            when compress(upcase(&arm_var.)) = compress(upcase("&&&arm_name_&i.")) 
                                 then 1 
                                 else 0 
                            end) 
                        as arm&i._count,
			         %end;
					 count(1) as total_count
              from err_dm_ex
		      where err_type = 'ex')

		union

		/* Subjects removed - no treatment/reference dates */
		select 4 as order, '4. Subjects removed - no treatment/reference dates' as desc,
		       %do i = 1 %to &arm_count.; 
                  (case when arm&i._count is missing then 0 else arm&i._count end) as arm&i._count, 
               %end; 
               total_count
		from (select %do i = 1 %to &arm_count.; 
                        sum(case 
                            when compress(upcase(&arm_var.)) = compress(upcase("&&&arm_name_&i.")) 
                                 then 1 
                                 else 0 
                            end) 
                        as arm&i._count, 
                     %end; 
					 count(1) as total_count
              from err_dm_ex
			  where err_type = 'dt')

		union

		/* Subjects used in analysis */
		select 5 as order, '5. Subjects used in analysis' as desc,
		       %do i = 1 %to &arm_count.;
			      sum(case 
                      when compress(upcase(&arm_var.)) = compress(upcase("&&&arm_name_&i.")) 
                           then 1 
                           else 0 
                      end) 
                  as arm&i._count,
			   %end;
			   count(1) as total_count
		from all_dm_ex;
	quit;

	/* add percentages of the original arm subject counts */
	data rpt_dm;
		retain desc %do i = 1 %to &arm_count.; arm&i._count arm&i._pct %end;;
		set rpt_dm;

		%do i = 1 %to &arm_count.;
			retain dm_arm&i._count;
			if _n_ = 1 then dm_arm&i._count = arm&i._count;
			arm&i._pct = 100*arm&i._count/dm_arm&i._count;
			drop dm_arm&i._count;
		%end;

		retain dm_total_count;
		if _n_ = 1 then dm_total_count = total_count;
		total_pct = 100*total_count/dm_total_count;
		drop dm_total_count;
	run;		

	/* ADVERSE EVENTS */

	%log_msg(ADVERSE EVENT DATA VALIDATION REPORT);

	/* write out number of adverse events in safety population */
	%global naes_sp;
	%let dsid = %sysfunc(open(all_ae_dm_ex));
	%let naes_sp = %sysfunc(attrn(&dsid.,nobs));
	%let rc = %sysfunc(close(&dsid.));

	/* and for each arm */
	%do i = 1 %to &arm_count.; %global naes_sp_&i.; %end;;
	proc sql noprint;
		select %do i = 1 %to &arm_count.; sum(case when arm_num = &i. then 1 else 0 end) as sum_&i., %end;	
               0 as null
          into %do i = 1 %to &arm_count.; : naes_sp_&i., %end; : null
		from all_ae_dm_ex;
	quit;

	/* write out number of validated adverse events in safety population */
	%global naes_spv;
	%let dsid = %sysfunc(open(ds_base));
	%let naes_spv = %sysfunc(attrn(&dsid.,nobs));
	%let rc = %sysfunc(close(&dsid.));

	/* create table of counts of each kind of error (e.g. invalid dates) */
	proc sql noprint;
		create table rpt_err(drop=err null) as
		select err, err_desc, 
               %do i = 1 %to &arm_count.;
			      arm&i._err_count, 100*arm&i._err_count/arm&i._count as arm&i._err_pct,
			   %end;
			   0 as null
		from (select err, err_desc, 
                     %do i = 1 %to &arm_count.; 
                        sum(case when arm_num = &i. then 1 else 0 end) as arm&i._err_count, 
                     %end; 
              0 as null
		      from err_base
			  group by err, err_desc) a,
			 (select %do i = 1 %to &arm_count.; 
                        sum(case when arm_num = &i. then 1 else 0 end) as arm&i._count, 
                     %end;
			         0 as null
			  from all_ae_dm_ex) b;
	quit;

	/* get counts per arm of each term that got thrown out due to invalid data */
	proc sql noprint;
		create table rpt_err_term_x as
		select aebodsys, aedecod, arm_num, count(1) as count
		from err_base
		group by aebodsys, aedecod, arm_num;
	quit;

	proc transpose data=rpt_err_term_x out=rpt_err_term(drop=_name_) prefix=arm;
		by aebodsys aedecod;
		id arm_num;
	run;

	data rpt_err_term;
		retain aebodsys aedecod %do i = 1 %to &arm_count.; arm&i. %end;;
		set rpt_err_term;

		%do i = 1 %to &arm_count.;
			if arm&i. = . then arm&i. = 0;

			label arm&i. = "&&&arm_name_&i. Event Count";
		%end;

		if aebodsys = '' then aebodsys = 'Missing';
		if aedecod = '' then aedecod = 'Missing';
	run;

	proc datasets library=work nolist nodetails; delete rpt_err_term_x; quit;

%mend rpt_setup;


/* print a text message with a box around it to the log */
%macro log_msg(text);

	options nonotes;

	data _null_;
		length = length("&text.");

		length string $100 separator $100;

		do i = 1 to length + 4;
			separator =  trim(left(separator))||"*";
		end;

		string = '* '||trim("&text.")||' *';

		put separator;
		put string;
		put separator;
	run;

	options notes;

%mend log_msg;
