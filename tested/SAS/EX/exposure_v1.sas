/****************************************************************************/
/*         PROGRAM NAME: Exposure Analysis Panel                            */
/*                                                                          */
/*          DESCRIPTION: Does an analysis of the exposure events for        */
/*                        subjects in the study                             */
/*                                                                          */
/*      EVALUATION TYPE: Safety                                             */
/*                                                                          */
/*               AUTHOR: Andreas Anastassopoulos                            */
/*                          (andreas.anastassapoulos@us.ibm.com)            */
/*                                                                          */
/*                 DATE: March 16, 2010                                     */
/*                                                                          */
/*  EXTERNAL FILES USED: Exposure_Template.xls -- Excel template            */
/*                       data_checks_exposure.sas -- EX data checks         */
/*                       exposure_exdosfrq.csv -- dose frequency codes      */
/*                       data_checks.sas -- Generic variable checks         */
/*                       sl_gs_output.sas -- Script Launcher settings output*/
/*                       err_output.sas -- Error output when missing vars   */
/*                                                                          */
/*  PARAMETERS REQUIRED: saspath -- location of external panel SAS programs */
/*                       utilpath -- location of external util SAS programs */
/*                       dosfrqpath -- location of the EXDOSFRQ code list   */
/*                       ndabla -- NDA or BLA number                        */
/*                       studyid -- study number                            */
/*                                                                          */
/*                       studypath -- location of the drug study datasets   */
/*                       outpath -- location of the output                  */
/*                       outfile -- filename of the output                  */
/*                       templatepath -- location of the Excel template     */
/*                       template -- filename of the template               */
/*                                                                          */
/*   VARIABLES REQUIRED: DM -- ACTARM or ARM                                */
/*                             RFSTDTC                                      */
/*                             USUBJID                                      */
/*                       EX -- USUBJID                                      */
/*                             EXENDTC or EXSTDTC                           */
/*                                                                          */
/* OTHER VARIABLES USED: DM -- ARMCD                                        */
/* IF AVAILABLE          EX -- EXTRT                                        */
/*                             EXDOSE                                       */
/*                             EXDOSU                                       */
/*                             EXDOSFRQ                                     */
/*                             EXDOSFRM                                     */
/*                             EXADJ                                        */
/*                                                                          */
/*            MADE WITH: SAS 9.2                                            */
/*                                                                          */
/*                NOTES:                                                    */
/*                                                                          */
/****************************************************************************/

/* REVISIONS */
/*
** 8/10 changes includes adding the study day and the reason to dose changes  ***;
** 8/11 changes include making cummulative dose graph as percent of total doses instead of number **;
** 8/16 changes the cummulative dose to make it a continuous graph ***;
** 8/18 changes the SCHEDULED vs ACTUAL  **;
** 8/24 changes the verbiage of the ARM in dose graph ***;

2011-02-29  DK  Added exposure dose frequency lookup
                Changed template and output method

2011-03-05  DK  Added grouping & subsetting output

2011-03-27  DK  Added run location handling

2011-04-26  DK  Fixed planned arm in planned arm vs actual arm when ACTARM is present

2011-05-08  DK  Error/no subjects in DM handling

2011-06-09  DK  Fixed a bug where the hash table in the EX_DM merge would fail to initialize
                because the first observation was not a match by adding a count of matches
*/

/* the minoperator option allows the use of the in operator by the macro language */
options minoperator;
options missing='';	

/* determine the run location by looking for the SL-set run_location macro variable */
%sysfunc(ifc(not %symexist(run_location),%nrstr(%let run_location = local;),));
%put RUN LOCATION: &run_location.;

%macro params;

	/* program parameters if the program is run locally */
	%if %upcase(&run_location.) = LOCAL %then %do;

		data macrovar; set sashelp.vmacro(keep=scope name where=(scope='GLOBAL' & name ne 'RUN_LOCATION')); run;
		data _null_; set macrovar; call execute('%symdel '||trim(left(name))||';');	run;
		proc datasets kill; quit; 

		%global panel_title panel_desc;
		%let panel_title = Exposure;
		%let panel_desc = ;

		/* NDA/BLA number */
		/* study number */
		%global ndabla studyid;
		%let ndabla = ;
		%let studyid = ;

		/* location of the study being examined */
		%let studypath = ;

		libname path "&studypath.";

		/* retrieve datasets */
		data dm; set path.dm; run;
		data ex; set path.ex; run;

		/* location of external SAS programs */
		%global saspath utilpath;
		%let saspath = ;
		%let utilpath = ;

		/* read in the list of dose frequencies from the CSV file */
		%global dosfrqpath;
		%let dosfrqpath = ; 

		/* location and filename of the exposure panel template */
		%let templatepath = ;
		%let template = Exposure_Template.xls;

		/* location and filename of the output */
		%let outpath = ;
		%let outfile = Exposure.xls;

		%global expout errout;
		%let expout = &outpath.\&outfile.; 	
		%let errout = &outpath.\Exposure Error Summary.xls;

		options noxwait xsync;

		/* copy the template to the output file */
		x "%str(copy %"&templatepath.\&template.%" %"&expout.%")";

		/* dummy grouping, subsetting, and dataset information datasets */
		data sl_datasets;
			datatype = ''; name = ''; partition_variable = ''; default = '';
			delete;
		run;
		data sl_group;
			group_name = ''; domain = ''; partition = ''; var_name = ''; var_value = ''; dsvg_grp_name = ''; 
			delete;
		run;
		data sl_subset;
			name = ''; domain = ''; partition = ''; var_name = ''; var_value = ''; inner_operator = ''; outer_operator = '';
			delete;
		run;

	%end;

	/* program parameters if the program is run through Script Launcher */
	%else %do;

		%global dosfrqpath;
		%let dosfrqpath = &saspath.;

		/* map the user-defined Script Launcher panel option values onto panel macro variables */
		data _null_; 
		run;

	%end;

%mend params;

%params;


%include "&saspath.\data_checks_exposure.sas";
%include "&utilpath.\data_checks.sas";
%include "&utilpath.\sl_gs_output.sas";
%include "&utilpath.\err_output.sas";


/***************************************/
/* REQUIRED & OPTIONAL VARIABLE CHECKS */
/***************************************/
%macro ex_prelim_check;

	/* check whether there are subjects in DM */
	%chk_dm_subj_gt0;

	/* required */
	%chk_var(ds=dm,var=rfstdtc); 
	%chk_var(ds=dm,var=usubjid); 
	%chk_var(ds=ex,var=usubjid);  

	data rpt_chk_var_req; set rpt_chk_var; run;

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

	%chk_var(ds=ex,var=exendtc); 
	%chk_var(ds=ex,var=exstdtc); 

	%let ex_exdt = %sysfunc(ifc(&ex_exendtc. or &ex_exstdtc.,1,0));

	proc sql noprint;
		insert into rpt_chk_var_req
		set chk = 'VAR',
		    ds = 'EX',
			var = 'EXSTDTC or EXENDTC',
			condition = 'EXISTS',
			ind = &ex_exdt.;
	quit;

	%global all_req_var;
	proc sql noprint;
		select (case when count = 0 then 1 else 0 end) into: all_req_var
		from (select count(1) as count 
              from rpt_chk_var_req 
              where ind ne 1);
	quit; 

	/* optional */
	%chk_var(ds=dm,var=actarm);
	%chk_var(ds=dm,var=armcd);
	%chk_var(ds=ex,var=exdosfrm);
	%chk_var(ds=ex,var=exdosfrq);
	%chk_var(ds=ex,var=extrt);
	%chk_var(ds=ex,var=exdose);
	%chk_var(ds=ex,var=exdosu);
	%chk_var(ds=ex,var=exadj);

%mend ex_prelim_check;


/*****************/
/* preprocessing */
/*****************/
%macro ex_setup;

	%put *******************************************;
	%put * EXPOSURE ANALYSIS DATASET PREPROCESSING *;	
	%put *******************************************;

	/* valid EXDOSFRQ values implying a specified number of doses per hour/day/week */
	/* taken from SDTM Terminology 10.06.2010 */
	data exdosfrq;
		infile "&dosfrqpath.\exposure_exdosfrq.csv" dsd delimiter=',' truncover;
		length exdosfrq $20 description $50 frequency $10 unit $1;
		input exdosfrq $ description $ frequency $ unit $;

		index = index(frequency,'/');
		if not index then exdosfrqn = input(frequency,8.);
		else exdosfrqn = input(substr(frequency,1,index-1),8.) / input(substr(frequency,index+1),8.);
	run;

	/* store dosing frequency codes in a macro variable */
	/* for use in the panel data checks */
	%global vld_exdosfrq;
	proc sql noprint;
		select "'"||trim(exdosfrq)||"'" into: vld_exdosfrq separated by ' '
		from exdosfrq;
	quit;

	/* used ACTARM if it is available */
	%if &dm_actarm. %then %do;
		proc datasets library=work;
			modify dm;
			rename %if &dm_arm. %then arm=plannedarm;
			       actarm=arm;
		quit;
	%end;

	** SORT THE DATASETS AND KEEP THE NEEDED VARIABLES ****;
	data dm;
		set dm;

		%if &dm_armcd. %then %do;
			if upcase(ARMCD) in("SCRNFAIL","NOTASSGN") then delete;
		%end;

		/* put arm into propcase */
		arm_display = arm;
		if arm_display ne '' and not anylower(arm_display) then do;
			length arm_word $50;
			i = 1;
			arm_word = scan(arm_display,i);
			do while (arm_word ne '');
				if length(arm_word) > 3 and not anydigit(compress(arm_word)) 
						then substr(arm_display,index(arm_display,compress(arm_word)),length(compress(arm_word))) = 
							propcase(compress(arm_word));
				if compress(arm_word) in ('MG' 'KG') 
					then substr(arm_display,index(arm_display,compress(arm_word)),length(compress(arm_word))) = 
						lowcase(arm_word);
				if compress(arm_word) = ('ML') 
					then substr(arm_display,index(arm_display,compress(arm_word)),length(compress(arm_word))) = 'mL';
				i = i + 1;
				arm_word = scan(arm_display,i);
			end;
		end;
		arm = arm_display;
		drop arm_display arm_word i;
	run;

	proc sort data = dm(keep = USUBJID RFSTDTC arm %if &dm_actarm. and &dm_arm. %then plannedarm;);
	  by USUBJID;
	run;

	data ex;
		set ex;
		format exendt e8601da.;
		format exstdt e8601da.;
		call missing(exendt,exstdt);

		/* if EXENDTC/EXSTDTC exist, convert them to SAS date format */
		/* put missing values at the end at the next sort using the sort order variable */
		%if &ex_exendtc. %then %do;
			if exendtc ne '' then do;
				exendt = input(exendtc,e8601da.);
				exendt_sort = 1;
			end;
			else do;
				exendt = .;
				exendt_sort = 2;
			end;
		%end;

		%if &ex_exstdtc. %then %do;
			if exstdtc ne '' then do;
				exstdt = input(exstdtc,e8601da.);
				exstdt_sort = 1;
			end;
			else do;
				exstdt = .;
				exstdt_sort = 2;
			end;
		%end;

		%if &ex_extrt. %then %do;
			extrt = propcase(extrt);
		%end;

		/* if EXDOSFRQ isn't in the EX dataset, create it and initialize it as missing */
		%if not &ex_exdosfrq. %then %do;
			length exdosfrq $1;
			call missing(exdosfrq);
		%end;

		/* if EXDOSFRM isn't in the EX dataset, create it and initialize it as missing */
		%if not &ex_exdosfrm. %then %do;
			length exdosfrm $1;
			call missing(exdosfrm);
		%end;

	run;


	%if &ex_exendtc. %then %do;
		proc sort data = ex;
		  by USUBJID exendt_sort exendt;
		run;
	%end;
	%else %if &ex_exstdtc. %then %do;
		proc sort data = ex;
		  by USUBJID exstdt_sort exstdt;
		run;
	%end;


	** MERGE THE EXPOSURE AND PATIENT DATASETS AND DETERMINE STUDY DAYS AND NUMBER OF DOSES ****;

	data ex_dm;
		merge ex(in=a) dm(in=b);
		format studydate treatdate enddate date9.;
		by USUBJID;
		if a and b;

		treatdate = exstdt;
		studydate = input(substr(RFSTDTC,1,10), yymmdd10.); 
		enddate = exendt;


		/* CALCULATE THE STUDY DAY OF THE EXPOSURE EVENT */
		if enddate = . then do;
		  if treatdate >= studydate then studydays = (treatdate - studydate)+1;
		    else studydays = (treatdate - studydate);
		end;
		else do;
		if enddate >= studydate then studydays = (enddate - studydate)+1;
		  else studydays = (enddate - studydate);
		end;
		*if studydays > 0;


		/* CALCULATE THE PERIOD IN DAYS DURING WHICH THE SUBJECT WAS TAKING DOSES OF THE DRUG */
		studydays0 = lag(studydays);
		if first.usubjid then dose_days = studydays;
		else dose_days = studydays - studydays0;
		if not missing(dose_days) and dose_days <= 0 then dose_days = 1;

		/* set up a count of matching observations so the hash table lookup is initialized on the first match */
		retain match;
		if a and b then match = sum(match,1);

		/* LOOK UP THE FREQUENCY OF DOSES PER INTERVAL FROM THE REFERENCE TABLE */
		if match = 1 then do;
			declare hash h(dataset:'exdosfrq');
			h.definekey('exdosfrq');
			h.definedata('exdosfrqn','unit');
			h.definedone();
		end;

		length exdosfrqn 8. unit $1;
		label exdosfrqn='Dosing Frequency Per Interval' unit='Dosing Frequency Unit';
		call missing(exdosfrqn,unit);
		rc = h.find();
		drop rc;

		/* if no dose frequency was found, assume one dose per study day */
		if exdosfrqn = . then do;
			exdosfrqn = 1;
			unit = 'd';
		end;

		/* special case to deal with injections */
		/* only one injection per exposure event */
		if index(upcase(exdosfrm),'INJECTION') then do;
			exdosfrqn = 1;
			unit = 'o';
		end;

		select (unit);
			when ('h') dose_days_fu = dose_days * 24;
			when ('d') dose_days_fu = dose_days;
			when ('w') dose_days_fu = dose_days / 7;
			when ('m') dose_days_fu = dose_days / 30.4375;
			when ('o') dose_days_fu = 1;
			otherwise;
		end;

		doses = dose_days_fu * exdosfrqn;

	run;

%mend ex_setup;


/*****************************************/
/* 1. ANALYSIS A: NUMBER OF DAYS ON DRUG */
/*****************************************/
%macro ex_1;

	%put *****************************************;
	%put * 1. ANALYSIS A: NUMBER OF DAYS ON DRUG *;	
	%put *****************************************;

	** GET THE LAST OBS BY ID ***;

	data ex_dm2;
		set ex_dm;
		by usubjid;
		/* get last nonmissing exposure event */
		where studydays ne .;
		if last.usubjid then output ex_dm2;
	run;

	** NUMBER OF PEOPLE EACH DAY ***;
	proc summary data = ex_dm2;
	  class studydays arm;
	  output out = num_days;
	run;

	** KEEP THE RIGHT OBS ***;

	proc sort data = num_days (where=(_type_ in (1,3)));
	  by arm studydays;
	run;

	** FIGURE OUT THE NUMBER OF TREATMENTS **;

	proc sort data = num_days nodupkey out = num_treatments;
	  by arm;
	run;

	** MAKE THE NUMBER OF TREATMENTS A MACRO **;
	%global num_treatments;
	proc sql noprint;
	  select count(*) into: num_treatments
	  from num_treatments;
	quit;

	** SET UP A LOOK TO DO ALL OF THE TREATMENTS ***;
	%do d = 1 %to &num_treatments;

		data treatment;
		  set num_treatments;
		if _N_ = &D;
		run;

		proc sql noprint;
		  select arm into: treatment
		  from treatment;
		quit;


		** MAX DAYS **;
		proc sql noprint;
		  select max(studydays) into: max_days
		  from num_days
		  where arm = "&treatment.";
		quit;

		** CREATE A DATASET CONTAINING ALL POSSIBLE DAYS ***;
		data all_days(drop=I);
		  do I = 1 to &max_days;
		    arm = "&treatment.";
		    studydays = I;
			output;
		  end;
		run;

		** MERE ALL POSSIBLE DAYS ONTO THE DATASET **;
		data num_days&D;
		  merge num_days all_days;
		  by arm studydays;
		  if arm = "&treatment.";
		  if missing(_freq_) then _freq_ = 0;
		run;

		data _null_;
		treatment2 = compress("&treatment.",'.');
		call symput('treatment2',treatment2);
		run;


		** FIGURE OUT THE NUMBER REMAINING AT EACH DAY OF THE STUDY **;
		data num_days&D(keep = studydays ARM_&D);
			  set num_days&D;
			  retain total_study left_in_study;

			if _type_ = 1 then do;
			  total_study = _freq_;
			  left_in_study = _freq_;
			  studydays = 0;
			end;
			else left_in_study = sum(left_in_study, - _freq_);
			ARM_&D. = left_in_study / total_study;
			label arm_&D = "&treatment2."
			      studydays = 'Day of Study';
			studydays = studydays+1;
		run;

		/* sort for the merge to follow */
		proc sort data=num_days&D;
			by studydays;
		run;

	%end;


	** MERGE THE DATA BACK TOGETHER TO MAKE ONE SET **;

	data final_ExposureA;
		merge
		%do S = 1 %to &num_treatments;
		  num_days&S.
		%end;
		;
		by studydays;

		if studydays < 1 then delete;

		array num{*} _numeric_;
		do i = 1 to dim(num);
			if num(i) = . then num(i) = 0;
		end;
		drop i;
	run;

%mend ex_1;


/****************************************/
/* 2. ANALYSIS B: DISTRIBUTION OF DOSES */
/****************************************/
%macro ex_2;

	%put ****************************************;
	%put * 2. ANALYSIS B: DISTRIBUTION OF DOSES *;	
	%put ****************************************;

	** NOW DO THE DOSE BUCKET ANALYSIS ***;

	** SUMMARIZE BY ID TO GET THE CUMMULATIVE NUMBER OF DOSES ****;
	proc summary data = ex_dm nway;
	  class usubjid;
	  id arm;
	  var doses;
	  output out = by_usubjid(drop = _type_ _freq_) sum=;
	run;


	** NOW GET THE MAX DOSES FOR EACH ARM **;

	proc sort data = by_usubjid;
	  by arm decending doses;
	run;

	data max_doses;
	  set by_usubjid;
	  by arm;
	if first.arm;
	max_doses = doses;
	drop usubjid doses;
	run;




	** MERGE ON ***;

	proc sql;
	  create table by_usubjid2
	  as select b.*, m.*
	  from by_usubjid b, max_doses m
	  where b.arm = m.arm and 
	  b.doses > 0
	  ;
	quit;

	** DETERMINE THE PECENTS FOR EACH PERSON ***;

	data by_usubjid2;
	  set by_usubjid2;

	percent = round(doses/max_doses,.01);
	run;

	** NUMBER WITH EACH AMOUNT OF DOSE percents ***;

	proc summary data = by_usubjid2 nway;
	  class arm percent;
	  output out = by_doses(drop=_type_ rename=_freq_=subjects);
	run;

	** NOW GO AND MAKE SURE ALL PERCENTS FROM 0 to 100 ARE IN THE DATASET FOR EACH ARM ***;

	data by_doses2(rename=(subjects2=subjects percent2=percent));
		  set by_doses;
		  by arm;
		percent0 = lag(percent);
		if first.arm then do;
		if percent > 0 then do;
		  do J = 0 to percent-.01 by .01;
		    percent2 = J;
			subjects2 = 0;
			output;
		  end;
		 percent2 =percent;
		 subjects2 = subjects;
		 output;
		end;
		else do;
		 percent2 = percent;
		 subjects2 = subjects;
		 output;
		end;
		end;
		else do;
		 if round((percent - percent0),.01) = .01 then do;
		   percent2 = percent;
		   subjects2 = subjects;
		   output;
		 end;
		 else do;
		  do I = percent0 to percent-.01 by .01;
		    percent2 = I;
			subjects2 = 0;
			output;
		  end;
		  percent2 = percent;
		  subjects2 = subjects;
		  output;
		 end;
		end;
		drop I j percent0 percent subjects;
	run;

	proc summary data = by_doses2 nway;
	  class arm percent;
	  var subjects;
	  output out = by_doses2(drop=_type_ _freq_) sum=;
	run;




	** NUMBER BY EACH ARM ***;
	proc summary data = by_usubjid2 nway;
	  class arm;
	  output out = by_treatment(drop = _type_ rename=(_freq_=num_treatment));
	run;

	data by_treatment;
	  set by_treatment;
	arm_n = _n_;
	run;

	** MERGE TO GET THE NUMBERATOR AND DENOMINATOR ON SAME DATASET ***;

	data by_doses_percs;
	  merge by_doses2 by_treatment;
	  by arm;
	  n_percent = subjects / num_treatment;
	run;


	** GET CUMMULATIVE PERCENT ***;
	data by_doses_percs;
		  set by_doses_percs;
		  by arm;
		  retain cum_percent;

		if first.arm then cum_percent = 1;
		cum_percent = sum(cum_percent, - n_percent);
	run;


	** LOOP TO FIGURE OUT NUMBER OF PERCENTS BY ARM ***;
	%do n = 1 %to &num_treatments;

		data treatment;
		  set num_treatments;
		if _N_ = &N;
		run;


		proc sql noprint;
		  select arm into: treatment
		  from treatment;
		quit;

		data _null_;
		  set max_doses;
		if arm = "&treatment.";
		call symput('MD',max_doses);
		run;

		data _null_;
		treatment2 = trim(compress("&treatment.",'.'))||' (Max Doses = '||compress("&MD.")||')';
		call symput('treatment2',treatment2);
		run;

		%put &treatment2.;

		data by_doses_percs&N.;
		  set by_doses_percs;

		if arm = "&treatment.";
		cum_percent&N. = cum_percent;
		percent= round(percent,.01);
		label cum_percent&N = "&treatment2.";
		arm&N = arm;

		keep percent cum_percent&N. ;
		run;

	%end;


	** MERGE BACK ALL THE DATASETS ***;

	data final_ExposureB;
		merge
		%do S = 1 %to &num_treatments;
		  by_doses_percs&S.
		%end;
		;
		by percent;
	run;

%mend ex_2;


/********************/
/* BOXPLOT OF DOSES */
/********************/
%macro ex_3;

	%put ***********************************;
	%put * 3. ANALYSIS C: BOXPLOT OF DOSES *;	
	%put ***********************************;

	** NOW DO THE DOSE STATS ***;


	** GET THE DESCRIPTIVE STATS BY ARM ***;

	proc univariate data = by_usubjid (where=(doses >= 0)) noprint;
	  class arm;
	  var doses;
	  output out = final_stats n=n_subjects std=sd_doses mean=mean_doses min=min_doses max=max_doses
	                                                 median=median_doses q1=q1_doses q3=q3_doses mode=mode_doses 
	                                                 p10=p10_doses p90=p90_doses;
	run;

	** DETERMINE THE NUMBER OF ARMS ***;
	%global num_arms;
	proc sql noprint;
	  select count(*) into: num_arms
	  from final_stats;
	quit;


	%do I = 1 %to &num_arms.;

		data _null_;
		  set final_stats;
		  if _N_ = &I;
		  call symput('arm',arm);
		  call symput('arm_2',compress(arm,'.'));
		run;

		** TRANSFORM THE DATA TO VERTICAL **;
		data arm&I.(keep = sort_order arm&I.);
			  set final_stats;
			  format sort_order $20.;
			if arm = "&arm.";
			label arm&I. = "&arm_2.";

			sort_order = '01 Mean';
			arm&I. = mean_doses;
			output;
			sort_order = '02 SD';
			arm&I. = sd_doses;
			output;
			sort_order = '03 Median';
			arm&I. = median_doses;
			output;
			sort_order = '04 P10';
			arm&I. = p10_doses;
			output;
			sort_order = '05 Q1';
			arm&I. = q1_doses;
			output;
			sort_order = '06 Q3';
			arm&I. = q3_doses;
			output;
			sort_order = '07 P90';
			arm&I. = p90_doses;
			output;
			sort_order = '08 Min';
			arm&I. = min_doses;
			output;
			sort_order = '09 Max';
			arm&I. = max_doses;
			output;
			sort_order = '10 Median-P10';
			arm&I. = median_doses-p10_doses;
			output;
			sort_order = '11 Q1';
			arm&I. = q1_doses;
			output;
			sort_order = '12 Median - Q1';
			arm&I. = median_doses-q1_doses;
			output;
			sort_order = '13 Q3 - Median';
			arm&I. = q3_doses-median_doses;
			output;
			sort_order = '14 P90 - Median';
			arm&I. = p90_doses-median_doses;
			output;
			sort_order = '15 Q1 - Min';
			arm&I. = q1_doses-min_doses;
			output;
			sort_order = '16 Max - Q3';
			arm&I. = max_doses-q3_doses;
			output;
			sort_order = '17 N';
			arm&I. = n_subjects;
			output;
			sort_order = '18 Mode';
			arm&I. = mode_doses;
			output;
		run;

		proc sort data = arm&I.;
		  by sort_order;
		run;

	%end;


	data final;
	  merge arm:;
	  by sort_order;
	run;

	data for_macro;
		format a $4.;
		do I = 1 to &num_arms.;
		a = compress("arm"||compress(I));
		output;
		end;
	run;

	proc sql noprint;
	  select a into: arms separated by ','
	  from for_macro;
	quit;

	proc sql;
	  create table final_exposureC
	  as select sort_order, &arms.
	  from 	final;
	quit;

%mend ex_3;


/****************************************************/
/* CREATE THE PLANNED ARM VS ACTUAL TREATMENT TABLE */
/****************************************************/
%macro ex_4;

	%put ************************************;
	%put * 4. ANALYSIS D: PLANNED VS ACTUAL *;	
	%put ************************************;

	/* EXTRT, EXDOSE, and EXDOSU must exist to run this analysis */
	%if &dm_arm. and &ex_extrt. and &ex_exdose. and &ex_exdosu. %then %do;

		proc sql noprint;
			/* find out how many subjects there were per planned arm */
			create table ex_d_planned as
			select arm, count(distinct usubjid)	as arm_count
			from (select a.usubjid, 
                         %if &dm_actarm. %then plannedarm;
						 %else arm;	as arm
			      from dm a,
				       ex b
				  where a.usubjid = b.usubjid)
			group by arm;

			/* find the number of subjects per treatment and dose */
			create table ex_d_actual as
			select arm, extrt, exdose, exdosu, count(distinct usubjid) as extrt_count
			from (select a.usubjid, 
                         %if &dm_actarm. %then plannedarm;
	                     %else arm; as arm,
                         extrt, exdose, exdosu 
			      from ex a,
				       dm b
		          where a.usubjid = b.usubjid)
			group by arm, extrt, exdose, exdosu;

			/* combined the planned and actual counts */
			create table ex_d_pva as
			select a.arm, arm_count, extrt, exdose, exdosu, extrt_count
			from ex_d_planned a,
			     ex_d_actual b
			where a.arm = b.arm
			order by arm, extrt, exdose, exdosu;
		quit;

		/* format the planned vs. actual table for output */
		data final_exposureD;
			retain arm arm_count actual actual_dose actual_count;
			set ex_d_pva;
			by arm extrt exdose;

			if not first.arm then do;
				arm = '';
				arm_count = .;
			end;

			if not first.extrt then extrt = '';

			extrt = propcase(extrt);

			length actual $100 actual_dose $100; 
			actual = extrt;
			actual_dose = left(ifc(not missing(exdose),compress(exdose),'')||' '||
		                  ifc(not missing(exdosu),exdosu,''));
			actual_count = extrt_count;

			keep arm arm_count actual actual_dose actual_count;
		run;

	%end;
	/* if the variables necessary for this table don't exist, create an error message */
	%else %do;

		data final_exposureD;
			err_msg = '';
		 run;

		/* determine which necessary variables were missing and compose an appropriate error message */
		data final_exposureD_err;
			length missvar $100;
			missvar = compbl(ifc(&ex_extrt. ne 1,'EXTRT','')||' '||
                             ifc(&ex_exdose. ne 1,'EXDOSE','')||' '||
                             ifc(&ex_exdosu. ne 1,'EXDOSU','')
                             );

			if not (&ex_extrt. and &ex_exdose. and &ex_exdosu.) then do;
				select (ifn(&ex_extrt. ne 1,1,0) + ifn(&ex_exdose. ne 1,1,0) + ifn(&ex_exdosu. ne 1,1,0));
					when (1) ;
					when (2) missvar = tranwrd(trim(missvar),' ',' and ');
					otherwise do;
						missvar = tranwrd(trim(missvar),' ',', ');
						lastcomma = length(trim(missvar)) - index(left(reverse(missvar)),',') + 1;
						missvar = substr(missvar,1,lastcomma-1)||', and '||substr(missvar,lastcomma+1);
					end;
				end;
			end;

			call symputx('extrt_missvar',missvar,'g');

			missvar = compbl(missvar);

			err_msg = 'Planned treatment could not be compared to actual treatment because '||
			          ifc(not &dm_arm.,'ARM did not exist in the DM dataset ','')||
					  ifc(not &dm_arm. and not (&ex_extrt. and &ex_exdose. and &ex_exdosu.),'and ','')||
                      ifc(not (&ex_extrt. and &ex_exdose. and &ex_exdosu.),
                          trim(missvar)||' did not exist in the EX dataset','');
			err_msg = strip(err_msg)||'.';
			keep err_msg;
		 run;

	%end;

%mend ex_4;


/*******************/
/* CHANGES IN DOSE */
/*******************/
%macro ex_5;

	%put *******************************;
	%put * 5. ANALYSIS E: DOSE CHANGES *;	
	%put *******************************;

	/* EXTRT, EXDOSE, and EXDOSU must exist to run this analysis */
	%if &ex_extrt. and &ex_exdose. and &ex_exdosu. %then %do;

		** LOOK FOR CHANGES IN DOSE ***;

		** OUTPUT IF THERE IS A CHANGE IN TREATMENT OR DOSE FROM ONE RECORD TO THE NEXT ****;
		data ex2;
			set ex_dm;
			format change_date mmddyy10. exadj $50.;
			usubjid0 = lag(usubjid);
			extrt0 = lag(extrt);
			exdose0 = lag(exdose);
			exdosu0 = lag(exdosu);
			if exendtc ne "" then change_date = input(exendtc, yymmdd10.);
			  else change_date = treatdate ;
			if usubjid0 = usubjid;
			if (extrt0 ne extrt) or (exdose0 ne exdose);
			old_dose = left(trim(extrt0)|| ' '||compress(exdose0)||' '||compress(exdosu0));
			new_dose = left(trim(extrt)|| ' '||compress(exdose)||' '||compress(exdosu));
			if exadj = '' then exadj = 'Not Given';
			else exadj = propcase(exadj);
			label old_dose = 'Original Dose'
			      new_dose = 'New Dose'
				  usubjid = 'Subject ID'
				  change_date = 'Change Date'
				  studydays	= 'Day of Study'
				  ;
		run;


		** SEE IF THERE WAS A CHANGE IN COUNT FOR OUTPUT **;

		proc sql noprint;
		  select count(*) into: changes
		  from ex2;
		quit;

		%if %eval(&changes.) = 0 %then %do;

			data final_exposureE;
				usubjid = "No Reported Change in Dose";
			run;

		%end;
		%else %do;

			proc sql;
			  create table final_exposureE
			  as select usubjid, old_dose, new_dose, change_date, studydays, exadj
			  from ex2
			  order by usubjid, change_date;
			;
			quit;

			data final_exposureE;
				set final_exposureE(obs=2500) end=eof;
				by usubjid change_date;
				if not first.usubjid then do;
					usubjid = '';
				end;
				output;
				if _n_ = 2500 and eof then do;
					usubjid = 'Over 2500 changes in dose';
					old_dose = 'List truncated at 2500';
					new_dose = '';
					studydays = .;
					exadj = '';
					output;
				end;
			run;

		%end;

	%end;
	%else %do;

		data final_exposureE;
			usubjid = '';
		 run;

		/* determine which necessary variables were missing and compose an appropriate error message */
		data final_exposureE_err;
			length missvar $100;
			missvar = "&extrt_missvar.";

			err_msg = compbl('Changes in dose could not be determined because '||
                      trim(missvar)||' did not exist in the EX dataset.');
			keep err_msg;
		 run;

	%end;

%mend ex_5;


/***********************/
/* CREATE EXCEL OUTPUT */
/***********************/
%macro ex_out;

	%put *****************************************;
	%put * CREATE EXPOSURE ANALYSIS EXCEL OUTPUT *;	
	%put *****************************************;

	** ADD IN THE DATA INFORMATION ***;
	data lib; 
		length path $100;
		path = "&ndabla.";
		output;
		path = "&studyid.";
		output;
		path = 	compbl(put(date(),e8601da.)||' '||put(time(),timeampm11.));
		output;	
		path = "&sl_custom_ds.";
		output;	
		path = ifc(&dm_actarm.,'actual treatment arm (ACTARM)','planned treatment arm (ARM)');
		output;
		path = ifc(&dm_actarm.,'Arm is actual arm','Arm is planned arm');
		output;
	run;

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
		drop table xls.final_exposureA,
		           xls.final_exposureB2,
				   xls.final_exposureC,
				   xls.pva,
				   xls.dosechanges,
	               xls.Info
                   ;
	quit; 
	
	data xls.final_exposureA(dblabel=yes);
		set final_exposureA;
	run;

	data xls.final_exposureB2(dblabel=yes);
		set final_exposureB;
	run;

	data xls.final_exposureC(dblabel=yes);
		set final_exposureC;
	run;

	data xls.pva(dblabel=yes);
		set final_exposureD;
	run;

	data xls.dosechanges(dblabel=yes);
		set final_exposureE;
	run;

	data xls.info(dblabel=yes);
		set lib;
	run;

	libname xls clear;

%mend ex_out; 


/*******************************/
/* RUN EXPOSURE ANALYSIS PANEL */
/*******************************/
%macro ex;

	/* preliminary data checks to ensure that required variables are present */
	%ex_prelim_check;

	/* only run the analysis if all required variables are present */
	%if &dm_subj_gt0. and &all_req_var. %then %do;

		%ex_setup;

		%ex_1;
		%ex_2;
		%ex_3;
		%ex_4;
		%ex_5;

		%group_subset_pp;

		%ex_out;

		/* run exposure panel data checks & output */
		%exposure_check;

		%exposure_check_out;

		%group_subset_xls_out(gs_file=&expout.);

	%end;
	%else %do;
		%error_summary(err_file=&errout.,
                       err_nosubj=%sysfunc(ifc(&dm_subj_gt0.,0,1)),
                       err_missvar=%sysfunc(ifc(&all_req_var.,0,1))
                       );
	%end;

%mend ex;


/* execute the EX macro to run the analysis */
%ex;
