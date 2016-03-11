/****************************************************************************/
/*         PROGRAM NAME: Disposition Analysis Panel                         */
/*                                                                          */
/*          DESCRIPTION: Find subject counts per arm for each disposition   */
/*                        event appearing in the study, for all subjects    */
/*                        and for exposed subjects                          */
/*                       Create charts of the time to disposition event	for */
/*                        all subjects and for exposed subjects             */
/*                       Creates an Excel spreadsheet as output             */
/*                                                                          */
/*      EVALUATION TYPE:                                                    */
/*                                                                          */
/*               AUTHOR: Andreas Anastassopoulos                            */
/*                          (andreas.anastassapoulos@us.ibm.com)            */
/*                                                                          */
/*                 DATE: December 9, 2009                                   */
/*                                                                          */
/*  EXTERNAL FILES USED: Disposition_Template.xls -- Excel template         */
/*                       data_checks.sas -- Generic variable checks         */
/*                       data_checks_disposition.sas -- DS data checks      */
/*                       sl_gs_output.sas -- Script Launcher settings output*/
/*                       err_output.sas -- Error output when missing vars   */
/*                                                                          */
/*  PARAMETERS REQUIRED: saspath -- location of external panel SAS programs */
/*                       utilpath -- location of external util SAS programs */
/*                       ndabla -- NDA or BLA number                        */
/*                       studyid -- study number                            */
/*                                                                          */
/*           LOCAL ONLY: studypath -- location of the drug study datasets   */
/*                       outpath -- location of the output                  */
/*                       outfile -- filename of the output                  */
/*                       templatepath -- location of the Excel template     */
/*                       template -- filename of the template               */
/*                                                                          */
/*   VARIABLES REQUIRED: DM -- ACTARM or ARM                                */
/*                             USUBJID                                      */
/*                             RFSTDTC if no DSSTDY                         */
/*                       DS -- DSDECOD                                      */
/*                             DSSTDY or DSSTDTC                            */
/*                             USUBJID                                      */
/*                       EX -- USUBJID                                      */
/*                                                                          */
/* OTHER VARIABLES USED: DM -- ARMCD                                        */
/* IF AVAILABLE          DS -- DSCAT                                        */
/*                             DSSCAT                                       */
/*                             DSSEQ                                        */
/*                                                                          */
/*            MADE WITH: SAS 9.2                                            */
/*                                                                          */
/*                NOTES:                                                    */
/*                                                                          */
/****************************************************************************/

/* REVISIONS */
/*
2011-02-17 DK  Changed to subject count from event count
               Added check for DSSCAT variable
               Moved output to separate macro
               Updated template to uniform panel style

2011-02-24 DK  Moved every section into separate macros
               Collapsed time to event code into one macro for both all and exposed
               Added checks for all variables

2011-03-05 DK  Added grouping & subsetting output
               Added handling for missing study day/date variables
               Number of DSDECOD terms now stored in separate macro variables for all vs ex

2011-03-27 DK  Added run location handling

2011-04-24 DK  Fixed an error in determining the number of randomized subjects
               when DSCAT and DSSCAT are missing; now determined by looking at DM_DS/DM_DS_EX

2011-05-08 DK  Error/no subjects in DM handling

2011-05-10 DK  Fixed substr to extract dates, order of sort variables, arm name length, 
               by_ds2_one datastep where statement to prevent using missing values in a do loop

2011-05-18 DK  Changed sort in %ds_by_arm to by dsdy instead of dsstdtc/dsstdy

2011-05-23 DK  Added exceptions in the data step that keeps one dsdecod per usubjid/dscat/dsscat
               when dsdecod is Informed Consent Obtained or Randomized
               Made missing categories/subcategories Missing

2015-06-13 DC  Enhanced to filter data and graph by dscat and dsscat
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
		%let panel_title = Disposition;
		%let panel_desc = ;

		/* NDA/BLA number */
		/* study number */
		%global ndabla studyid catc subc catdis subcatdis;
		%let ndabla = ;
		%let studyid = ;

		%let catc=dscat; 
		%let subc=dsscat; 

		%let catdis='DISPOSITION EVENT'; /* Example: 'DISPOSITION EVENT' */ 
		%let subcatdis='END OF TREATMENT'; /* Example: 'END OF TREATMENT' */

		/* location of the study being examined */
		%let studypath =F:\Internal Use\FDA JumpStart Scripts\Data\SDTM ;

		libname inlib "&studypath."; 

		/* retrieve datasets */
		data dm; set inlib.dm; run; 
		data ds; set inlib.ds; run; 
		data ex; set inlib.ex; run; 

		/* location of external SAS programs */
		%global saspath utilpath;
		%let saspath =F:\Internal Use\FDA JumpStart Scripts\Programs\Ad Hoc ;
		%let utilpath = F:\Internal Use\FDA JumpStart Scripts\Programs\Maclib;

		/* location and filename of the disposition panel template */
		%let templatepath =F:\Internal Use\FDA JumpStart Scripts\Data\External\Templates ;
		%let template = Disposition_Template.xls;

		/* location and filename of the output */
		%let outpath =F:\Internal Use\FDA JumpStart Scripts\Output\Dev ;
		%let outfile = Disposition.xls;

		%global dispout errout;
		%let dispout = &outpath.\&outfile.;	
		%let errout = &outpath.\Disposition Error Summary.xls;

		options noxwait xsync;

		/* copy the template to the output file */
		x "%str(copy %"&templatepath.\&template.%" %"&dispout.%")";	

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
	%end;

%mend params;
%params;

/* data checks and data check output */
%include "&saspath.\data_checks_disposition.sas";
%include "&utilpath.\data_checks.sas"; 
%include "&utilpath.\sl_gs_output.sas";
%include "&utilpath.\err_output.sas";


/*****************************************************/
/* PRELIMINARY REQUIRED AND OPTIONAL VARIABLE CHECKS */
/*****************************************************/
%macro ds_prelim_check;

	/* check whether there are subjects in DM */
	%chk_dm_subj_gt0;

	/* required variables */
	%chk_var(ds=dm,var=usubjid);
	%chk_var(ds=ds,var=dsdecod);
	%chk_var(ds=ds,var=usubjid);
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

	/* study day of disposition event OR (start date of disposition event AND subject reference start date) */
	%chk_var(ds=ds,var=dsstdtc); 
	%chk_var(ds=ds,var=dsstdy);	
	%chk_var(ds=dm,var=rfstdtc); 

	proc sql noprint;
		insert into rpt_chk_var_req
		set chk = 'VAR',
		    ds = 'DM/DS',
			var = 'DSSTDY or (DSSTDTC and RFSTDTC)',
			condition = 'EXISTS',
			ind = %sysfunc(ifc(&ds_dsstdy. or (&ds_dsstdtc. and &dm_rfstdtc.),1,0));
	quit;  	

	/* set a flag indicating whether all required variables are present */
	%global all_req_var;
	proc sql noprint;
		select (case when count = 0 then 1 else 0 end) into: all_req_var
		from (select count(1) as count 
              from rpt_chk_var_req 
              where ind ne 1);
	quit; 

	/* optional variables */
	%chk_var(ds=dm,var=armcd);
	%chk_var(ds=ds,var=dscat); 
	%chk_var(ds=ds,var=dsscat);
	%chk_var(ds=ds,var=dsseq);

	/* if study day exists or date variables exist to compute study day, time to event can be done */
	%global ds_tte;
	%if &ds_dsstdy. or (&dm_rfstdtc. and &ds_dsstdtc.) %then %let ds_tte = 1;
	%else %let ds_tte = 0;

%mend ds_prelim_check;


/**********************************************/
/* DISPOSITION ANALYSIS DATASET PREPROCESSING */
/**********************************************/
%macro ds_setup;

	%put **********************************************;
	%put * DISPOSITION ANALYSIS DATASET PREPROCESSING *;	
	%put **********************************************;

	/* used ACTARM if it is available */
	%if &dm_actarm. %then %do;
		proc datasets library=work;
			modify dm;
			rename %if &dm_arm. %then arm=plannedarm;
			       actarm=arm;
		quit;
	%end;

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
						then substr(arm_display,index(arm_display,compress(arm_word)),length(compress(arm_word))) = propcase(compress(arm_word));
				if compress(arm_word) in ('MG' 'KG') 
					then substr(arm_display,index(arm_display,compress(arm_word)),length(compress(arm_word))) = lowcase(arm_word);
				if compress(arm_word) = ('ML') 
					then substr(arm_display,index(arm_display,compress(arm_word)),length(compress(arm_word))) = 'mL';
				i = i + 1;
				arm_word = scan(arm_display,i);
			end;
		end;
		arm = arm_display;
		drop arm_display arm_word i;
	run;

	data ds ;
		set ds;
		if not anylower(dsdecod) then dsdecod = propcase(dsdecod);

		%if &ds_dscat. %then %do;
			if missing(dscat) then dscat = 'Missing';
			if not anylower(dscat) then dscat = propcase(dscat);
		%end;
		%else %do;
			dscat = 'Missing';
		%end;

		%if &ds_dsscat. %then %do;
			if missing(dsscat) then dsscat = 'Missing';
			if not anylower(dsscat) then dsscat = propcase(dsscat);
		%end;
		%else %do;
			dsscat = 'Missing';
		%end;
	run;

	*data ex;
	*	set ex;
	*run;

	* Obtain demographics and people for each of the disposition terms; 
	proc sort data = dm;
	  by usubjid;
	run;

	proc sort data = ds;
	  by usubjid;
	run;

	proc sort data = ex nodupkey;
	  by usubjid;
	run;

	data dm_ds;
		merge dm (in=b) ds (in=a);
		by usubjid;
		if  a and b;
	run;


	data dm_ds;   
		set dm_ds;

		%if &ds_dsstdy. %then %do;
			dsdy = dsstdy;
		%end;

		%else %if &dm_rfstdtc. and &ds_dsstdtc. %then %do;    
			dss_year  = substr(left(dsstdtc),1,4);
			dss_month = substr(left(dsstdtc),6,2);
			dss_day   = substr(left(dsstdtc),9,2);
			dss_date  = mdy( dss_month, dss_day, dss_year);

			rfs_year  = substr(left(rfstdtc),1,4); 
			rfs_month = substr(left(rfstdtc),6,2);
			rfs_day   = substr(left(rfstdtc),9,2);
			rfs_date  = mdy( rfs_month, rfs_day, rfs_year);

			if dss_date >= rfs_date then do;
				dsdy = (dss_date - rfs_date + 1);
			end;
			else do;
				dsdy = (dss_date - rfs_date);
			end;
		%end; 

		%else %do;
			length dsdy 8. dsstdy 8. rfstdtc $1 dsstdtc $1;
			call missing(dsdy,dsstdy,rfstdtc,dsstdtc);
		%end;
	run;

	** MERGE ON THE EX FILE TO SUBSET	**;

	data dm_ds_ex;
	  merge dm_ds(in=d) ex(in=e keep=usubjid);
	  by usubjid;
	  if d and e;
	run;
	  
%mend ds_setup;


/**********************/
/* DISPOSITION BY ARM */
/**********************/
%macro ds_by_arm(infile,outfile);

	%put ******************************************;
	%put * DISPOSITION EVENTS BY ARM for &infile. *;	
	%put ******************************************;

	** Revised logic part of the program starts here ****;
	**IF THE VARIABLES ARE MISSING THEY WILL BE SET TO MISSING ***;

	proc sort data=&infile. out=&infile._sort;
		by usubjid dscat dsscat %if &ds_dsstdtc. %then dsstdtc; %else %if &ds_dsstdy. %then dsstdy;;
	run;

	/* keep only the last disposition event per category and subcategory */
	/* keep death if there are multiple disposition events on a single day */
	data &infile._sort;
		set &infile._sort;
		if upcase(dsdecod) = 'DEATH' then order = 100;
		else order = 1;
	run;

	proc sort data=&infile._sort out=&infile._sort;
		by usubjid  
           dscat 
           dsscat 
           dsdy
		   order
           %if &ds_dsseq. %then dsseq;
           dsdecod;
	run;

	/* pick out the last disposition event per subject in each category and subcategory */
	/* category/subcategory/subject level */
	data &infile._cscsl;
		set &infile._sort;
		by usubjid dscat dsscat;

		if upcase(dscat) ne 'PROTOCOL MILESTONE' 
		and not (upcase(dsdecod) =: 'INFORMED CONSENT OBTAINED')
        and not (upcase(dsdecod) =: 'RANDOMIZED')
		then do;
			if last.dsscat;
		end;
	run;

	proc sql noprint;
		create table by_cat as
		select dscat, dsscat, dsdecod, arm, count(distinct usubjid)	as num_by_cat
		from &infile._cscsl
		group by dscat, dsscat, dsdecod, arm;
	quit;

	/*proc summary data = dm_ds_a nway;
	  class dscat dsscat dsdecod arm;
	  output out = by_cat(drop=_type_ rename=(_freq_=num_by_cat));
	run;*/


	* Create the denominator total out of the randomized ;
	* Total Randomized Patients ;


	* Total Randomized Patients by Treatment ;
	proc sql noprint;
		create table ran_arm as
		select arm, count(distinct usubjid) as total_count
		from &infile.
		where upcase(dsdecod) like 'RANDOM%'
		group by arm;
	quit; 

	data ran_arm;
		set ran_arm;
		arm_n + 1;
	run;

	** CHECK TO SEE IF THERE ARE ANY RANDOMIZED, IF NOT CALCULATE ARM N **;
	%global num_random;
	proc sql noprint;
	  select count(*) into: num_random
	  from ran_arm;
	quit;

	%if &num_random. = 0 %then %do;

		proc sql noprint;
			create table ran_arm as
			select arm, count(distinct usubjid) as total_count
			from dm_ds
			group by arm;
		quit;

		data ran_arm;
			set ran_arm;
			arm_n + 1;
		run;

		proc sql noprint;
			select count(1) into: num_random
			from ran_arm;
		quit;

	%end;

	** COMBINE BREAKDOWN WITH NUMBER BY ARM ***;

	proc sql;
	  create table by_cat_arm
	  as select b.*, r.*
	  from by_cat b, ran_arm r
	  where b.arm = r.arm
	  order by dscat, dsscat, dsdecod, arm
	  ;
	quit;

	** NOW MAKE ONE OBS FOR EACH STANDARD TERM ***;

	data by_dsdecode (drop=total_count num_by_cat arm I arm_n);
		  set by_cat_arm;
		  by dscat dsscat dsdecod;
		  retain n_arm1 - n_arm%eval(&num_random.) n1 - n%eval(&num_random.) p_arm1 - p_arm%eval(&num_random.) name1 - name%eval(&num_random.);
		  format name1 - name%eval(&num_random.) $100.;
		  array ns{*} n_arm1 - n_arm%eval(&num_random.);
		  array nds{*} n1 - n%eval(&num_random.);
		  array percs{*} p_arm1 - p_arm%eval(&num_random.);
		  array names{*} $ name1 - name%eval(&num_random.);

		ns{arm_n} = total_count;
		nds{arm_n} = num_by_cat;
		percs{arm_n} = 100*num_by_cat/total_count;
		names{arm_n} = arm;

		dscat = propcase(dscat);
		dsdecod = propcase(dsdecod);
		if index(dscat,'Mile') then sorter = 1;
		  else sorter = 2;

		if last.dsdecod then do;
		  tot_perc = sum(of p_arm:);
		  output;
		  do I = 1 to &num_random.;
		     nds{I} = 0;
		     percs{I} = 0;
		  end;
		end;
	run;

	proc sort data =  by_dsdecode;
	  by sorter dscat dsscat decending tot_perc;
	run;

	data by_dsdecode;
		  set by_dsdecode;
		  by sorter dscat dsscat;
		if not first.dscat then dscat = '';
		if not first.dsscat then dsscat = '';
	run;

	** NOW I NEED TO GET THE VARIABLES INTO THE CORRECT ORDER FOR EXPORTING ***;

	%macro order;

		%do I = 1 %to &num_random.;

		data order&I;
			format order $8.;
			order = "n_arm&I.";
			output;
			order = "n&I.";
			output;
			order = "p_arm&I.";
			output;
			order = "name&I.";
			output;
		run;

		%end;

	%mend order;

	%order;

	data order;
	 set order:;
	run;

	proc sql noprint;
	  select order into: order separated by ','
	  from order;
	quit;

	proc sql;
	  create table &OUTFILE.
	  as select dscat, dsscat, dsdecod, &order
	  from by_dsdecode
	;
	quit;


	PROC STDIZE DATA=&OUTFILE. REPONLY MISSING=0 OUT=&OUTFILE.;
	VAR _numeric_;
	RUN;
	  
	/* clean up */
	proc datasets library = work;
	  delete order:;
	run;
	quit;

%mend ds_by_arm;


/************************************/
/* TIME TO DISPOSITION EVENT BY ARM */
/************************************/
%macro time_to_event(ds);

	%put **************************************;
	%put * TIME TO DISPOSITION EVENT for &ds. *;	
	%put **************************************;

	/* disposition event study day or date variables to calculate it must be available */
	%if &ds_tte. %then %do;

		/* set the time-to-event failure note to empty */
		%if not %symexist(tte_fail_note) %then %do;
			%global tte_fail_note;
			%let tte_fail_note = ;
		%end;

		** THE FOLLOWING CREATES THE LITTLE GRAPHS ***;

		** DEDUPE DATA **;
		proc sort data = &ds. nodupkey dupout = &ds._dupes;
		  by usubjid dsdecod dsdy;
		run;

/*Start of 6/13 enhancement*/

		%if &subcatdis~= %then %do;

		** NUMBER OF EACH BY ARM DSDECOD ***;

		proc summary data = &ds. nway;
		  class arm dsdecod;
		  where upcase(&subc.)=&subcatdis and upcase(&catc.)=&catdis;
		  output out = by_dsdecod(drop=_type_ rename=(_freq_=tot_dsdecod));
		run;

		** NUMBER OF EACH BY ARM BY DAY ***;

		proc summary data = &ds. nway;
		  class arm dsdecod dsdy;
		  where upcase(&subc.)=&subcatdis and upcase(&catc.)=&catdis;
		  output out = by_dsdecod_day(drop=_type_ rename=(_freq_=by_dsdecod));
		run;
		
		%end;

		%if &subcatdis= and &catdis~= %then %do;

		** NUMBER OF EACH BY ARM DSDECOD ***;

		proc summary data = &ds. nway;
		  class arm dsdecod;
		  where upcase(&catc.)=&catdis;
		  output out = by_dsdecod(drop=_type_ rename=(_freq_=tot_dsdecod));
		run;

		** NUMBER OF EACH BY ARM BY DAY ***;

		proc summary data = &ds. nway;
		  class arm dsdecod dsdy;
		  where upcase(&catc.)=&catdis;
		  output out = by_dsdecod_day(drop=_type_ rename=(_freq_=by_dsdecod));
		run;
		
		%end;

		%if &subcatdis= and &catdis= %then %do;

		** NUMBER OF EACH BY ARM DSDECOD ***;

		proc summary data = &ds. nway;
		  class arm dsdecod;
		  output out = by_dsdecod(drop=_type_ rename=(_freq_=tot_dsdecod));
		run;

		** NUMBER OF EACH BY ARM BY DAY ***;

		proc summary data = &ds. nway;
		  class arm dsdecod dsdy;
		  output out = by_dsdecod_day(drop=_type_ rename=(_freq_=by_dsdecod));
		run;
		
		%end;

/*End of 6/13 Enhancement*/

		** NOW GET THE MAX DAY IN THE STUDY ***;

		proc sql noprint;
		  select max(dsdy) into: max_day
		  from by_dsdecod_day;
		quit;
		 
		** NOW RUN THROUGH AND DO THE CUMMULATIVE NUMBER OF EACH EVENT AND ALL THE NUMBER OF DAYS ***;

		data by_dsdecod_day1 (keep = arm dsdecod dsdy1 cum_dsdecod);
			  set by_dsdecod_day;
			  by arm dsdecod;
			  retain cum_dsdecod;

			dsdy0 = lag(dsdy);
			if first.dsdecod then do;
			  if dsdy < 0 then do;
			    dsdy1 = dsdy;
			    cum_dsdecod = by_dsdecod;
			    output;
			  end;
			  else do;
			  do J = 0 to dsdy;
			    dsdy1 = J;
				if dsdy1 = dsdy then cum_dsdecod = by_dsdecod;
				  else cum_dsdecod = 0;
				output;
			  end;
			  end;
			end;
			else do;
			  days_between = abs(dsdy0-dsdy);
			  if days_between = 1 then do;
			    dsdy1 = dsdy;
			    cum_dsdecod = cum_dsdecod+by_dsdecod;
				output;
			  end;
			  else do;
			    do I = 1 to days_between;
				  dsdy1 = dsdy0+I;
				  if dsdy1 = dsdy then 	cum_dsdecod = cum_dsdecod+by_dsdecod;
				  output;
				end;
			  end;
			end;
		run;

		** MERGE TOTAL ON TOGETHER AND CALCULATE CUMMULATIVE PERCENT ***;

		data by_ds;
		  merge by_dsdecod_day1 by_dsdecod ;
		  by arm dsdecod;

		cum_percent = cum_dsdecod/tot_dsdecod;
		run;


		** NOW FIGURE OUT THE NUMBER OF ARMS AND THE NUMBER OF DSDECODS AND NUMBER OF DAYS FOR DSDECOD **;

		proc sql;
		  create table arm 
		  as select distinct arm
		  from by_dsdecod
		  ;
		quit;

		** THIS GETS A NUMERIC FOR EACH ARM ***;
		data arm;
			  set arm;
			n_arm = _n_;
		run;


		%global num_arms;
		proc sql noprint;
		  select count(*) into: num_arms
		  from arm;
		quit;


		** NOW I FIGURE OUT HOW MANY EACH DSDECOD OCCURED TO GET UP TO 12 INTERESTING ONES ***;
		** THIS PUTS THEM IN ORDER ***;
		proc sql;
		  create table dsd_num
		  as select dsdecod, sum(tot_dsdecod) as num_events
		  from by_dsdecod
		  group by dsdecod
		  order by num_events descending;
		quit;

		/* determine the macro variable to use for the number of DSDECOD terms */
		%if not %sysfunc(index(&ds.,ex)) %then %let rlimit = num_dsd;
		%else %let rlimit = num_dsde;

		data dsd_num (keep = dsdecod order);
			  set dsd_num end=eof;
			order = _n_;
			twelve = 12;
			if eof then do;
				call symputx("&rlimit.",put(min(_n_,12),8. -l),'g');
			end;
		run;


		** NOW I NEED TO GET ALL THE ARMS LINED UP CORRECTLY for EACH DSDECOD**;

		** MERGE FILES TOGETHER **;

		proc sql;
		  create table by_ds2
		  as select b.*, a.*, d.*
		  from by_ds b, arm a, dsd_num d
		  where b.dsdecod = d.dsdecod  and
		        b.arm = a.arm
		  order by d.order, b.dsdy1
		;
		quit;

		data by_ds2_one(keep = dsdecod order dsdy1 c_perc1-c_perc%eval(&num_arms.));
			  set by_ds2 end=eof;
			  by order dsdy1;
			  retain c_perc1-c_perc%eval(&num_arms.);
			  array c_percs{*} c_perc1-c_perc%eval(&num_arms.);

			where dsdy1 ne .;
			 
			if first.order then do;
			  do I = 1 to %eval(&num_arms.);
			    c_percs{I} = 0;
			  end;
			end;

			c_percs{n_arm} = cum_percent;
			if last.dsdy1 then output; 

			if last.order then do;
			  if dsdy1 < &max_day. then do;
			    do J = dsdy1+1 to %eval(&max_day.);
				  dsdy1 = J;
				  output;
				end;
			  end;
			end;
		run;

		** GET UNIQUE ARM DSDECODE OBS TO BE USED IN LABELS ***;

		proc sort data = by_ds2 out = for_labels(keep = order dsdecod tot_dsdecod n_arm) nodupkey;
		  by order n_arm;
		run;



		* Break up the file by DSDECOD Term and Export ; 
		** I WANT TO CREATE A LABEL FOR EACH THAT HAS THE NUMBER OF OBS IN IT ***;
		%global lable1 lable2 lable3 lable4 lable5 lable6 lable7 lable8;

		%do a=1 %to &&&rlimit.;

			** THIS WILL HAVE THE NUMBER OF OBS FOR EACH ARM IN THE DSDECOD WE ARE WORKING ON ***;

			data for_labels1(keep=tot_dsdecod n_arm);
			  set for_labels;
			if order = &a.;
			run;

			** CREATE A LABEL FOR THE DSDECOD **;
			data _null_;
			  set for_labels;
			  format dsdtext $100.;
			  if order = &a.;
			dsdtext = "Cumulative Chart for Disposition Event = "||trim(compress(dsdecod,';'));
			call symput('dsd_label',dsdtext);
			run;

			** THIS WILL HAVE THE LABEL TEXT FOR EACH ***;
			data for_labels1;
			  format text $200.;
			  merge for_labels1 arm;
			  by n_arm;
			  if tot_dsdecod = . then tot_dsdecod =0;
			  text = "label c_perc"||compress(_N_)||' = "'||trim(compress(arm,,'c'))||' Events = '||compress(tot_dsdecod)||'"';
			run;

			** CREATE A MACRO FOR EACH ***;

			%do L = 1 %to &num_arms.;

				data _null_;
				 set for_labels1;
				 if _N_ = &L;
				 call symput("lable&L.",trim(text));
				run;

			%end;


			** NOW SUBSET THE DATA AND USE THE LABELS ***;

			data dsdecod&a.%sysfunc(ifc(%sysfunc(index(&ds.,ex)),e,)) (drop = order);
				length dsdecod $ 200;
				set by_ds2_one;
				if order = &a.;

				dsdecod = "&dsd_label.";

				%do L2 = 1 %to &num_arms.;
					&&lable&L2.;
				%end;
			run;

		%end;

	%end;
	%else %do;

		%put;
		%put WARNING: Study day or date variables not available;
		%put;

		%if not %symexist(tte_fail_note) %then %do;
			%global tte_fail_note;
			%let tte_fail_note = Time to event analysis could not be performed because 
                                 study day and date variables used to compute study day were not available;
			%let tte_fail_note = %sysfunc(compbl(&tte_fail_note.));
		%end;

	%end;

%mend time_to_event;


/***********************/
/* CREATE EXCEL OUTPUT */
/***********************/
%macro ds_out;

	%put ********************************************;
	%put * CREATE DISPOSITION ANALYSIS EXCEL OUTPUT *;	
	%put ********************************************;

	** ADD IN THE DATA INFORMATION ***;
	data lib; 
		length path $500;
		path = "&ndabla.";
		output;
		path = "&studyid.";
		output;
		path = 	compbl(put(date(),e8601da.)||' '||put(time(),timeampm11.));
		output;
		path = "&sl_custom_ds.";
		output;
		path = "&tte_fail_note.";
		output;
		path = ifc(&dm_actarm.,'actual treatment arm (ACTARM)','planned treatment arm (ARM)');
		output;
		%if &subcatdis~= %then %do;
			path = "Subset where &catc. = &catdis. and &subc. = &subcatdis.";
			output;
		%end;
		%if &subcatdis= %then %do;
			path = "Subset where &catc. = &catdis.";
			output;
		%end;
	run;

	%if not %symexist(run_location) %then %let run_location = LOCAL;

	/* local runs use the Microsoft Jet database-based Excel LIBNAME engine */
	%if %upcase(&run_location.) = LOCAL %then %do;
		libname xls excel "&dispout." ver=2003; *Output function changed due to SAS 9.3(64bit) and Excel 2010(32bit) incompatability;
/*		libname xls pcfiles path="&dispout."; */
	%end;
	/* Script Launcher runs use the PCFILES LIBNAME Engine */
	%else %do; 
		libname xls pcfiles path="&dispout."; 
	%end;

	proc sql noprint;
		drop table xls.DispositionANew,
                   xls.DispositionBNew, 
				   %if &ds_tte. %then %do;
				    %do a = 1 %to &num_dsd.;
					 xls.Sheet&a.,
					 xls.Sheet&a.E,
				    %end;
				   %end;
	               xls.Info
                   ;
	quit; 


	data xls.DispositionANew;
		set final_dispositionA;
	run;

	data xls.DispositionBNew;
		set final_dispositionB ;
	run;

	%if &ds_tte. %then %do;

		%do a = 1 %to &num_dsd.;

			data xls.Sheet&a.(dblabel=yes);
				set dsdecod&a.;
			run; 

		%end;

		%do a = 1 %to &num_dsde.;

			data xls.Sheet&a.E(dblabel=yes);
				set dsdecod&a.e;
			run;

		%end;

	%end;

	data xls.Info;
		set lib;
	run;
	
	libname xls clear;

%mend ds_out;


/**********************************/
/* RUN DISPOSITION ANALYSIS PANEL */
/**********************************/
%macro ds;

	%ds_prelim_check;

	%if &dm_subj_gt0. and &all_req_var. %then %do;

		%ds_setup;

		%ds_by_arm(dm_ds,final_dispositionA);

		%ds_by_arm(dm_ds_ex,final_dispositionB);

		%time_to_event(dm_ds);

		%time_to_event(dm_ds_ex); 

		/* do preprocessing of Script Launcher datasets */
		%group_subset_pp;

		%ds_out;

		/* data checks */
		%disposition_check;

		%disposition_check_out;

		/* create grouping & subsetting output */
		%group_subset_xls_out(gs_file=&dispout.);

	%end; 
	%else %do;
		%error_summary(err_file=&errout.,
                       err_nosubj=%sysfunc(ifc(&dm_subj_gt0.,0,1)),
                       err_missvar=%sysfunc(ifc(&all_req_var.,0,1))
                       );
	%end;

%mend ds;


/* run the disposition panel */
%ds;
