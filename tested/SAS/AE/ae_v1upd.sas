/****************************************************************************/
/*         PROGRAM NAME: AE Severity Panel                                  */
/*                                                                          */
/*          DESCRIPTION: Find subject counts per arm for each adverse event	*/
/*                       Find event counts per arm and severity level for   */
/*                        each adverse event	                            */
/*                       Find top adverse events by relative risk &         */
/*                        odds ratio between each pair of arms              */
/*                       Creates three output files:                        */
/*                        Adverse events counts analysis                    */
/*                        Odds ratio analysis	                            */
/*                        Relative risk analysis                            */
/*                                                                          */
/*      EVALUATION TYPE: Safety                                             */
/*                                                                          */
/*               AUTHOR: David Kretch (david.kretch@us.ibm.com)	            */
/*                       Andreas Anastassopoulos                            */
/*                          (andreas.anastassapoulos@us.ibm.com)            */
/*                                                                          */
/*                 DATE: February 7, 2011                                   */
/*                                                                          */
/*  EXTERNAL FILES USED: ae_setup.sas -- Merges AE, DM, and EX              */
/*                       ae_aggregate.sas -- Finds the subject/event counts */
/*                       ae_output.sas -- Creates the Excel XML output      */
/*                       ae_rror.sas -- Relative risk/odds ratio analysis   */
/*                       xml_output.sas -- XML formatting macros            */
/*                       data_checks.sas -- Generic variable checks         */
/*                       sl_gs_output.sas -- Script Launcher settings output*/
/*                       err_output.sas -- Error output when missing vars   */
/*                       AE_OR_Template.xls -- Odds ratio Excel template    */
/*                       AE_RR_Template.xls -- Relative risk Excel template */
/*                                                                          */
/*  PARAMETERS REQUIRED: saspath -- location of panel external SAS programs */
/*                       utilpath -- location of util external SAS programs */
/*                       aeout1 -- filename of data table output            */
/*                       aeout2 -- filename of OR output                    */
/*                       aeout3 -- filename of RR output                    */
/*                                                                          */
/*                       study_lag -- window in days after last exposure    */
/*                                    where AEs should be kept in analysis  */
/*                       cc -- continuity correction value                  */
/*                                                                          */
/*           LOCAL-ONLY: studypath -- location of the drug study datasets   */
/*                       templatepath -- location of the Excel templates    */
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
/*       WHEN AVAILABLE        AESER                                        */
/*                             AESEV                                        */
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
/*            REVISIONS: ---                                                */
/*                                                                          */
/****************************************************************************/

/* REVISION HISTORY */
/*
2011-05-08  DK  Added handling for errors in case DM has no subjects

2011-06-08  DK  Added arguments on calling the error summary macro in the case of one arm
                to avoid setting the error status
*/

/* the minoperator option allows the use of the in operator by the macro language */
options minoperator mlogic symbolgen;
options missing='';	

/* determine the run location by looking for the SL-set run_location macro variable */
%sysfunc(ifc(not %symexist(run_location),%nrstr(%let run_location = local;),));
%put RUN LOCATION: &run_location.;

%macro params(in_panel_title = AE Severity,
			  in_panel_desc = AE Severity Panel,
			  in_saspath = ,
			  in_utilpath = ,
			  in_outpath = ,
			  in_studypath = ,
			  in_ndabla = ,
			  in_studyid = CDISC,
			  in_templatepath = ,
			  in_studylag = 120,
			  in_cc = 0);

	/* program parameters if the program is run locally */
	%if %upcase(&run_location.) = LOCAL %then %do;

		data macrovar; set sashelp.vmacro(keep=scope name where=(scope='GLOBAL' & name ne 'RUN_LOCATION')); run;
		data _null_; set macrovar; call execute('%symdel '||trim(left(name))||';');	run;
		proc datasets kill; quit;

		%global panel_title panel_desc;
		%let panel_title = AE Severity;
		%let panel_desc = &in_panel_desc;

		%global saspath utilpath; 
		%let saspath = &in_saspath;
		%let utilpath = &in_utilpath;

		%global outpath aeout1 aeout2 aeout3 errout;
		%let outpath = &in_outpath;
		%let aeout1 = &outpath.\AE Severity.xls;	
		%let aeout2 = &outpath.\Adverse Events Odds Ratio Analysis.xls;	
		%let aeout3 = &outpath.\Adverse Events Relative Risk Analysis.xls;
		%let errout = &outpath.\AE Severity Error Summary.xls;

		%let studypath = &in_studypath;

		libname inlib "&studypath."; 

		/* retrieve the required datasets */
		data ae; set inlib.ae; run;
		data dm; set inlib.dm; run;
		data ex; set inlib.ex; run;

		/* NDA/BLA and study number */
		%global ndabla studyid;
		%let ndabla = &in_ndabla;
		%let studyid = &in_studyid;

		/* study lag in days; determines window in days following the end of a study */
		/* in which AEs should be included in the analysis */
		%global study_lag;
		%let study_lag = &in_studylag;

		/*****************************************/
		/* ODDS RATIO / RELATIVE RISK PARAMETERS */
		/*****************************************/
		%global templatepath rr_template or_template;
		%let templatepath = &in_templatepath;
		%let or_template = AE_OR_Template.xls; 	
		%let rr_template = AE_RR_Template.xls;

		/* copy the templates to the output destination */
		options noxwait xsync;

		x "%str(copy %"&templatepath.\&or_template.%" %"&aeout2.%")";
		x "%str(copy %"&templatepath.\&rr_template.%" %"&aeout3.%")";

		/* continuity correction method */
		/* arm adds the reciprocal of the opposite arm */
		/* otherwise any number is added as a constant */
		%global cc;
		%let cc = &in_cc;

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

		/* map the user-defined Script Launcher panel option values onto panel macro variables */
		data _null_; 

			/* study lag */
			length study_lag $15;
			study_lag = trim(left("&study_lag."));
			call symputx('study_lag',study_lag,'g');

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

%include "&utilpath.\ae_setup.sas"; 	
%include "&saspath.\ae_aggregate.sas"; 
%include "&saspath.\ae_output.sas";
%include "&utilpath.\data_checks.sas";
%include "&utilpath.\err_output.sas";
%include "&utilpath.\sl_gs_output.sas";
%include "&utilpath.\xml_output.sas";


/* set the continuity correction & whole number switch/indicator */
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


/********************/
/* RUN ALL ANALYSES */
/********************/
%macro ae;

	%setup;

	%if &setup_success. %then %do;

		/* sort input dataset by the by variables */
		/* keep one record per subject, adverse event, and serious event indicator */ 
		proc sort data=ds_base out=ds_base_bysubjpt nodupkey; 
			by aebodsys aedecod usubjid %if &ae_aeser. %then descending aeser;; 
		run;

		/* keep only one record per subject and adverse event */
		/* AESER remains to indicate whether any of a subject's AEs were serious */
		data ds_base_bysubjpt;
			retain usubjid arm_num aebodsys aedecod;
			set ds_base_bysubjpt;
			by aebodsys aedecod usubjid; 
			if first.usubjid;
		run;

		/* analyses A & B */
		%ab;
		%if &ae_aeser. %then %ab(aeser=y);;

		/* analyses C & D */
		%if &ae_aesev. %then %do;
			%cd;
			%if &ae_aeser. %then %cd(aeser=y);;
		%end;

		%if &ae_aeser. %then %do;
			%chk_val(work,all_ae_dm_ex,aeser,Y);
			%chk_val(work,all_ae_dm_ex,aeser,N);
		%end;

		%out_ae;

		/* relative risk and odds ratio output */
		%if &arm_count. > 1 %then %do;
			%include "&saspath.\ae_rror.sas";
		%end;
		%else %do; 
			%error_summary(err_file=&aeout2.,
			               err_seterr=0,
                           err_desc=%nrstr(The Adverse Events Odds Ratio Analysis could not be run because this study contained only one arm));
			%error_summary(err_file=&aeout3., 
			               err_seterr=0,
                           err_desc=%nrstr(The Adverse Events Relative Risk Analysis could not be run because this study contained only one arm));
		%end;

	%end;
	%else %do;
		%error_summary(err_file=&errout.,
                       err_nosubj=%sysfunc(ifc(&dm_subj_gt0.,0,1)),
                       err_missvar=%sysfunc(ifc(&setup_req_var.,0,1))
                       );
	%end;

%mend ae;

%ae;
