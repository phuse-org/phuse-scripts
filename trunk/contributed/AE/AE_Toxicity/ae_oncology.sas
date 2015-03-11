/****************************************************************************/
/*                                                                          */
/*         PROGRAM NAME: AE Toxicity Panel                      */
/*                                                                          */
/*          DESCRIPTION: Find subject counts per arm for each adverse event	*/
/*                        broken down by toxicity grade                     */
/*                       Compare the AEs between two arms and find          */
/*                        risk difference, relative risk, odds ratio,       */
/*                        95% confidence intervals, and p-value             */
/*                                                                          */
/*      EVALUATION TYPE: Safety                                             */
/*                                                                          */
/*               AUTHOR: David Kretch (david.kretch@us.ibm.com)	            */
/*                                                                          */
/*                 DATE: February 7, 2011                                   */
/*                                                                          */
/*  EXTERNAL FILES USED: ae_setup.sas -- Merges AE, DM, and EX              */
/*                       ae_oncology_aggregate.sas -- Does the analysis     */
/*                       ae_oncology_output.sas -- Creates the output       */
/*                       xml_output.sas -- XML formatting macros            */
/*                       data_checks.sas -- Generic variable checks         */
/*                       sl_gs_output.sas -- Script Launcher settings output*/
/*                       err_output.sas -- Error output when missing vars   */
/*                       mdhier_x_y.sas7bdat -- MedDRA hierarchy ver. X.Y   */
/*                                                                          */
/*  PARAMETERS REQUIRED: meddrapath -- location of MedDRA hierachy datasets */
/*                       saspath -- location of the external SAS programs   */
/*                       utilpath -- location of the external SAS programs  */
/*                                                                          */
/*                       study_lag -- window in days after last exposure    */
/*                                    where AEs should be kept in analysis  */
/*                                                                          */
/*                       toxgr_min -- minimum valid toxicity grade          */
/*                       toxgr_max -- maximum valid toxicity grade          */
/*                       toxgr_grp5_sw -- group toxgrade 5 with 3&4         */
/*                                                                          */
/*                       ver -- MedDRA version                              */
/*                       exp -- comparison treatment arm number             */
/*                       ctl -- comparison control arm number               */
/*                       cmptrm -- MedDRA levels to compare                 */
/*                       cmpgr -- toxicity grades to compare                */
/*                       cmpsort -- variable to sort formatted output by    */
/*                       cc -- continuity correction value                  */
/*                                                                          */
/*           LOCAL ONLY: studypath -- location of the drug study datasets   */
/*                       outpath -- location of the output                  */
/*                                                                          */
/*   VARIABLES REQUIRED: AE -- AEBODSYS                                     */
/*                             AEDECOD                                      */
/*                             USUBJID                                      */
/*                       DM -- ACTARM or ARM                                */
/*                             USUBJID                                      */
/*                       EX -- USUBJID                                      */
/*                                                                          */
/*       VARIABLES USED: AE -- AESTDTC                                      */
/*       WHEN AVAILABLE        AETOXGR                                      */
/*                       DM -- RFSTDTC                                      */
/*                             RFENDTC                                      */
/*                             ARMCD                                        */
/*                       EX -- EXSTDTC                                      */
/*                             EXENDTC                                      */
/*                                                                          */
/*            MADE WITH: SAS 9.2                                            */
/*                                                                          */
/*                NOTES:                                                    */
/*                                                                          */
/****************************************************************************/

/* REVISIONS */
/*
2011-03-26  DK  Script Launcher parameter mapping
                handling for MedDRA version 'N/A'
2011-05-08  DK  Added handling for errors in case DM has no subjects

2011-06-02  DK  Merged the counts from part 3 onto the cartesian product of arm number and AE term number
                to avoid issues from arms with no AEs
                Added check for MedDRA matching percentage < 80
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
		%let panel_title = AE Toxicity;
		%let panel_desc = ;

		%global saspath utilpath; 
		%let saspath = ;
		%let utilpath = ;

		%global oncaeout errout;
		%let outpath = ;
		%let oncaeout = &outpath.\AE Toxicity Analysis.xls;
		%let errout = &outpath.\AE Toxicity Error Summary.xls;

		%let studypath = ;

		libname inlib "&studypath."; 

		/* retrieve the required datasets */
		data ae; set inlib.ae; run;
		data dm; set inlib.dm; run;
		data ex; set inlib.ex; run;

		/* NDA/BLA and study number */
		%global ndabla studyid;
		%let ndabla = ;
		%let studyid = ;

		/* MedDRA hierachy */
		%let meddrapath = ;

		libname meddra "&meddrapath.";

		/* MedDRA version */
		%global ver meddra meddra_pct;
		%let ver = ;
		%if %upcase(%substr(&ver.,1,1)) = N %then %do;
			%let meddra = N;
			%let meddra_pct = 0;
		%end;
		%else %let meddra = Y;

		/* study lag in days; determines window in days following the end of a study */
		/* in which AEs should be included in the analysis */
		%global study_lag;
		%let study_lag = 30;

		/*****************************/
		/* TOXICITY GRADE PARAMETERS */
		/*****************************/

		/* toxicity grade 5 grouping switch to group 5 with 3 and 4 in the oncology panel */
		%global toxgr_grp5_sw;
		%let toxgr_grp5_sw = 1;

		/*************************/
		/* COMPARISON PARAMETERS */
		/*************************/

		/* experiment and control */
		/* defined by arm number from all_arm */
		%global exp ctl;
		%let exp = 1;
		%let ctl = 2; 

		/* comparison terms */
		%global cmptrm;
		%let cmptrm = soc_name,pt_name;

		/* grades to use in comparison in the two-term analysis */
		/* valid values: all, 5, 34, 345 */
		%global cmpgr;
		%let cmpgr = all;

		/* sort variable */
		%global cmpsort;
		%let cmpsort = rr;

		/* continuity correction method */
		/* arm adds the reciprocal of the opposite arm */
		/* otherwise any number is added as a constant */
		%global cc;
		%let cc = .5; 

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

		/* MedDRA hierachy */
		libname meddra "&meddrapath."; 

		/* map the user-defined Script Launcher panel option values onto panel macro variables */
		data _null_;

			/* MedDRA version */
			meddraver = "&meddraver.";
			meddra = ifc(upcase(substr("&meddraver.",1,1)) = 'N','N','Y'); 
			call symputx('ver',meddraver,'g'); 
			call symputx('meddra',meddra,'g'); 
			if meddra = 'N' then call symputx('meddra_pct','0','g');

			/* study lag */
			length study_lag $15;
			study_lag = trim(left("&study_lag."));
			call symputx('study_lag',study_lag,'g');

			/* toxicity grade grouping */
			select ("&tox_grade.");
				when ('All Grades, Grades 3 and 4, Grade 5') toxgr_grp5_sw = 0;	
				when ('All Grades, Grades 3 and above') toxgr_grp5_sw = 1;
				otherwise toxgr_grp5_sw = 0;
			end;
			call symputx('toxgr_grp5_sw',toxgr_grp5_sw,'g');

			/* comparison terms */
			meddracomp = lowcase(left(trim("&meddracomp."))); 
			cmptrm_1 = trim(scan(meddracomp,1,'/'))||'_name';
			cmptrm_2 = trim(scan(meddracomp,2,'/'))||'_name';
			cmptrm = trim(cmptrm_1)||','||trim(cmptrm_2);
			call symputx('cmptrm',cmptrm,'g');

			/* toxicity grades to use in the two-term comparison */
			length cmpgr $15;
			select ("&compmet.");
				when ('All Grades') cmpgr = 'all'; 
				when ('Grades 3 and 4') cmpgr = '34';
				when ('Grades 3, 4, and 5') cmpgr = '345';
				when ('Grade 5') cmpgr = '5'; 
				otherwise cmpgr = 'all'; 
			end;
			call symputx('cmpgr',cmpgr,'g');

			/* sort-by variable for the two-term analysis formatted tab */
			length cmpsort $15;
			select ("&sortby");	
				when ('Risk Difference') cmpsort = 'rd';
				when ('Relative Risk') cmpsort = 'rr';
				when ('Odds Ratio') cmpsort = 'ort';
				when ('P-Value') cmpsort = 'p_value';
				otherwise cmpsort = 'rd';
			end;
			call symputx('cmpsort',cmpsort,'g');

			/* continuity correction */
			length cc $15;
			select (upcase(compress("&cont_corr.")));
				when ('1') cc = '1';
				when ('0.5','1/2') cc = '0.5';
				when ('1/OTHERARMCOUNT') cc = 'arm';
				when ('NONE','0') cc = '0';
				otherwise cc = '0';
			end;
			call symputx('cc',cc,'g');
		run;

	%end;

%mend params;

%params; 
	
/* data validation switch; determines whether to perform data validation on AEs */
%let vld_sw = 1; 

/* minimum and maximum toxicity grades for oncology panel */
%global toxgr_min toxgr_max;
%let toxgr_min = 1;
%let toxgr_max = 5;

/* include confidence limits for AE rates (risks) 1=on, 0=off */
%let ae_rate_ci_sw = 1;

%include "&utilpath.\ae_setup.sas"; 	
%include "&saspath.\ae_oncology_aggregate.sas";
%include "&saspath.\ae_oncology_output.sas";
%include "&utilpath.\data_checks.sas";
%include "&utilpath.\err_output.sas";
%include "&utilpath.\sl_gs_output.sas";	
%include "&utilpath.\xml_output.sas";

/* set the continuity correction switch */
/* set the cc whole number switch */
data _null_;
	if anyalpha("&cc.") then cc = "&cc.";
	else cc = &cc.;

	if anyalpha(cc) and cc = 'arm' then cc_sw = 2;
	else if not missing(cc) and cc ne 0 then cc_sw = 1;
	else cc_sw = 0;

	if cc_sw = 2 then cc_whole = 0;
	else if (cc - floor(cc) ne 0) then cc_whole = 0;
	else cc_whole = 1;

	call symputx('cc_sw',cc_sw,'g');
	call symputx('cc_whole',cc_whole,'g');
run;


%macro onc;

	%if %upcase(%substr(&ver.,1,1)) = N %then %do;
		%setup;
		%global meddra; %let meddra = N;
	%end;
	%else %setup(mdhier=Y);

	/* determine whether there were enough AEs with matching MedDRA terms */
	%if &meddra_pct. < 80 %then %let meddra = N;

	/* determine the treatment and control arms from user-defined Script Launcher panel options */
	/* if the arms cannot be determined, set it to two arms in the study */
	%if %upcase(&run_location.) ne LOCAL %then %do;
		data _null_;
			set all_arm end=eof; 

			retain exp;
			if upcase(compbl(trim(arm))) =: upcase(compbl(trim("&treat_arm."))) then exp = arm_num;
			retain ctl;
			if upcase(compbl(trim(arm))) =: upcase(compbl(trim("&cont_arm."))) then ctl = arm_num;

			if eof then do;
				if exp = . then exp = 1;
				if ctl = . then ctl = min(2,&arm_count.);

				call symputx('exp',put(exp,8. -l),'g');
				call symputx('ctl',put(ctl,8. -l),'g');
			end;
		run;
	%end;

	%if &setup_success. %then %do;

		/* you cannot group 5 with 3 and 4 if 4 is the upper bound */
		/* ensures that no array bounds will be exceeded */
		%if %symexist(toxgr_max) %then %if &toxgr_max. = 4 %then %let toxgr_grp5_sw = 0;

		/* Toxicity Grade Summary */
		%aggregate(ds_base,pt_1,total);

		/* Preferred Term Analysis by Toxicity Grade */
		%aggregate(ds_base,pt_2,aebodsys,aedecod);	
		%fmt_output(pt_2_output);

		/* Two-Term Analysis*/
		/* if MedDRA matching was successful, use it, otherwise fall back on the provided terms */
		%if &arm_count. > 1 %then %do;
			%if &meddra. = Y %then %do;
				%compare(ds_base_meddra,pt_3,&cmptrm.);
			%end;
			%else %do;
				%let cmptrm = aebodsys,aedecod;
				%compare(ds_base,pt_3,&cmptrm.);
			%end;
			%fmt_output(pt_3_output,sort_sw=yes,sortvar=&cmpsort.,sortgrp_sw=yes);	
		%end;

		%out_onc;

	%end;
	%else %do;
		%error_summary(err_file=&errout.,
                       err_nosubj=%sysfunc(ifc(&dm_subj_gt0.,0,1)),
                       err_missvar=%sysfunc(ifc(&setup_req_var.,0,1))
                       );
	%end;

%mend onc;

%let start = %sysfunc(time());

%onc;

%let end = %sysfunc(time());

%let diff = %sysevalf(&end. - &start.);

%put NOTE: RUNNING TIME: %sysfunc(trim(%sysfunc(putn(&diff.,mmss20))));

