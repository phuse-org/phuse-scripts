/****************************************************************************/
/*         PROGRAM NAME: Liver Lab Analysis Panel                           */
/*                                                                          */
/*          DESCRIPTION: Find counts of subjects with abnormal lab tests    */
/*                        in multiples of a reference high                  */
/*                        and in combination                                */
/*                        for lab tests ALP, ALT, AST, and TB               */
/*                                                                          */
/*      EVALUATION TYPE:                                                    */
/*                                                                          */
/*               AUTHOR: Shannon Dennis (shannon.dennis@fda.hhs.gov)        */
/*                                                                          */
/*                 DATE: December 29, 2009                                  */
/*                                                                          */
/*  EXTERNAL FILES USED: Liver_Labs_Template.xls -- Excel template          */
/*                       data_checks.sas -- Generic variable checks         */
/*                       data_checks_liver.sas -- DS data checks            */
/*                       sl_gs_output.sas -- Script Launcher settings output*/
/*                                                                          */
/*  PARAMETERS REQUIRED: saspath -- location of external panel SAS programs */
/*                       utilpath -- location of external util SAS programs */
/*                       ndabla -- NDA or BLA number                        */
/*                       studyid -- study number                            */
/*                       liverout -- filename and path of output            */
/*                                                                          */
/*           LOCAL ONLY: studypath -- location of the drug study datasets   */
/*                       outpath -- location of the output                  */
/*                       outfile -- filename of the output                  */
/*                       templatepath -- location of the Excel template     */
/*                       template -- filename of the template               */
/*                                                                          */
/*   VARIABLES REQUIRED: DM -- ACTARM or ARM                                */
/*                             USUBJID                                      */
/*                       LB -- USUBJID                                      */
/*                             LBDTC                                        */
/*                             LBTESTCD                                     */
/*                             LBSTNRHI                                     */
/*                             LBSTRESN                                     */
/*                             LBSTRESU                                     */
/*                             LBSTNRLO                                     */
/*                                                                          */
/* OTHER VARIABLES USED: DM -- ARMCD                                        */
/* IF AVAILABLE                RFSTDTC                                      */
/*                       LB -- LBDY                                         */
/*                             LBBLFL                                       */
/*                             VISITNUM                                     */
/*                                                                          */
/*            MADE WITH: SAS 9.2                                            */
/*                                                                          */
/*                NOTES:                                                    */
/*                                                                          */
/****************************************************************************/

/* REVISIONS */
/*
2011-03-11 DK  Added data checks
               Moved separate parts of the program into separate macros
               Updated template to uniform panel style

2011-03-27 DK  Added run location handling

2011-05-08 DK  Error/no subjects in DM handling

2011-06-02 DK  Modified the missing/0 lab test result data check to handle 
               the case that there are no missing/0 lab test results
               Changed the denominators in the missing baseline lab test data check
               to the number of subjects per arm who had post-baseline lab tests
               Added ALKP to the list of values for ALP

2011-06-03 DK  Made the liver lab test code data check mandatory; if any of the four
               lab tests is missing, the analysis is not done and an error is output

2011-06-09 DK  Fixed a bug where splitting the lab tests into separate datasets 
               was not using the macro variables defining the acceptable lab test codes

2014-05-04 JP  Fixed bug where baseline results were being pulled into any visit. Should
			   be any visit besides baseline.

2015-02-12 DC  Enhanced the panel to include USUBJID for Hy's Law

2015-10-30 DC  Enhanced the panel to include additional information on multiple baseline
               Lab test that conflict in numeric results

2015-12-03 PG  Modified the above enhancement to include all duplicate baseline tests

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
		%let panel_title = Liver Labs;
		%let panel_desc = ;

		%global ndabla studyid;
		%let ndabla = ;
		%let studyid = ;

		%let studypath = ;

		libname folder "&studypath.";

		data dm; set folder.dm; run;
		data lb; set folder.lb; run;

		%global saspath utilpath; 
		%let saspath = ;
		%let utilpath = ;

		%let templatepath = ;
		%let template = Liver_Labs_Template.xls;

		%let outpath = ;
		%let outfile = Liver_Labs.xls;

		%global liverout errout;
		%let liverout = &outpath.\&outfile.; 
		%let errout = &outpath.\Liver Labs Error Summary.xls;

		/* copy template to output file */
		/* added by DK */
		options noxwait xsync;

		x "%str(copy %"&templatepath.\&template.%" %"&liverout.%")"; 

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

		proc printto print="&saspath.\liveroutput.lst"; run; quit;

	%end;

	/* program parameters if the program is run through Script Launcher */
	%else %do;

		/* map the user-defined Script Launcher panel option values onto panel macro variables */
		data _null_; 
		run;

	%end;

%mend params;

%params; 


/* define acceptable lab test codes (LBTESTCD) for the four liver lab tests */
%let alt = alt,sgpt;
%let ast = ast,sgot;
%let alp = alp,alkp;
%let bili = bili,bili_tb,tb,tbl,tbil,tbili,tb_bili,bilitot;

data _null_;
	call symputx('l_alt',"'"||upcase(tranwrd("&alt.",",","','"))||"'");
	call symputx('l_ast',"'"||upcase(tranwrd("&ast.",",","','"))||"'");
	call symputx('l_alp',"'"||upcase(tranwrd("&alp.",",","','"))||"'");
	call symputx('l_bili',"'"||upcase(tranwrd("&bili.",",","','"))||"'");
run;


%include "&saspath.\data_checks_liver.sas";	
%include "&utilpath.\data_checks.sas";
%include "&utilpath.\sl_gs_output.sas";
%include "&utilpath.\err_output.sas";


/* preliminary data checks */
%macro liver_prelim;

	%put LIVER LAB ANALYSIS PRELIMINARY DATA CHECKS;

	/* check whether there are subjects in DM */
	%chk_dm_subj_gt0;

	/* REQUIRED VARIABLES */
	%chk_var(ds=dm,var=usubjid); 

	%chk_var(ds=lb,var=usubjid);
	%chk_var(ds=lb,var=lbtestcd);  
	%chk_var(ds=lb,var=lbstnrhi);
	%chk_var(ds=lb,var=lbstresn);
	%chk_var(ds=lb,var=lbstresu);
	%chk_var(ds=lb,var=lbstnrlo); 

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

	%chk_var(ds=lb,var=lbdy);  

	%chk_var(ds=dm,var=rfstdtc);
	%chk_var(ds=lb,var=lbdtc); 	

	proc sql noprint;
		insert into rpt_chk_var_req
		set chk = 'VAR',
		    ds = 'DM/LB',
			var = 'LBDY or (LBDTC and RFSTDTC)',
			condition = 'EXISTS',
			ind = %sysfunc(ifc(&lb_lbdy. or (&lb_lbdtc. and &dm_rfstdtc.),1,0));
	quit;

	%global all_req_var;
	proc sql noprint;
		select (case when count = 0 then 1 else 0 end) into: all_req_var
		from (select count(1) as count 
              from rpt_chk_var_req 
              where ind ne 1);
	quit;  

	/* check that all four lab tests are present */
	%liver_lbtestcd;

	/* OPTIONAL */
	%chk_var(ds=dm,var=armcd);

	%chk_var(ds=lb,var=lbblfl);	
	%chk_var(ds=lb,var=lbtest);	
	%chk_var(ds=lb,var=visitnum);
	%chk_var(ds=lb,var=lbstat);
	%chk_var(ds=lb,var=lbreasnd);

	%chk_val(work,lb,visitnum,missing);	

%mend liver_prelim;


/****************************/
/* LIVER LAB ANALYSIS SETUP */
/****************************/
%macro liver_setup;

	%put LIVER LAB SETUP;

	/* used ACTARM if it is available */
	%if &dm_actarm. %then %do;
		proc datasets library=work;
			modify dm;
			rename %if &dm_arm. %then arm=plannedarm;
			       actarm=arm;
		quit;
	%end;

	/*Put dataset into Work Library for manipulation*/;	
	data demographics;
		set dm;

		%if &dm_armcd. %then %do;
			if upcase(ARMCD) in("SCRNFAIL","NOTASSGN") then delete;
		%end;

		keep ARM USUBJID RFSTDTC;
		/* added by DK */
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

	/*greate global macro for the number of arms*/
	proc freq data = demographics noprint;
	table arm/out=treatment_arms;
	run;

	data treatment_arms;
	set treatment_arms;
	treatment = _N_;
	run;

	proc summary data = treatment_arms;
	output out = num;
	run;

	data _null_;
	set num;
	call symputx('num', put(_freq_,1. -l),'g');
	run;

	/*bring in all datasets with lb and subset only the 4 liver labs*/
	data labdata;
		set lb;

		%if not &lb_lbtest. %then %do;
			length lbtest $40;
		%end;

		if LBTESTCD in (&l_alp.,&l_alt.,&l_ast.,&l_bili.);
		if LBTESTCD in (&l_alt.) then LBTEST = "Alanine Aminotransferase";
		if LBTESTCD in (&l_ast.) then LBTEST = "Aspartate Aminotransferase";
		if LBTESTCD in (&l_bili.) then LBTEST = "Total Bilirubin";
		if LBTESTCD in (&l_alp.) then LBTEST = "Alkaline Phosphatase";
		if LBSTNRHI = . or LBSTNRHI = 0 then delete;
	run;

	/*macro to drop variables that have all missing values in labdata*/

	%macro find_null_col(inlib, dsn, outlib);
		options nofmterr;
		/*obtain metadata information*/
		ods listing close;
		ods output variables=varlist(keep=member variable);

		proc datasets library=%upcase(&inlib) memtype=data;
		contents data=_all_;
		quit;
		run;

		ods output close;
		ods listing;

		data varlist(keep=member variable rename=(member=name));
			set varlist;
			member=compress(tranwrd(member,%upcase("&inlib.."),''));
		run;

		/*count non-missing values for each column*/
		data _null_;
			set varlist end=t;
			%if &dsn ne %then %do; where compress(name)=%upcase("&dsn"); %end;
			call execute(
			"proc sql; create table ds" || compress(put(_n_,best.))
			|| " as select count(" || compress(variable)
			|| ") as cnt, '" || compress(name) || "' as dataset length=100,'"
			|| compress(variable) || "' as variable length=100 from &inlib.."
			|| compress(name) || " where "
			|| compress(variable) || " is not missing; quit;"
			);
			if t then call symput("cnt",compress(put(_n_,best.)));
		run;

		/*identify columns with all missing values*/
		data rpt;
			set
			%do index=1 %to &cnt; ds&index %end; ;
			where cnt=0;
			;
		run;

		proc sql noprint;
			select count(*) into: nvar from rpt;
		quit;

		/*print list file*/
		title1 "LIST OF COLUMNS WITH MISSING VALUES IN LIBRARY %UPCASE(&INLIB)";
		%if &dsn ne %then %do; title2 "FOR DATASET %UPCASE(&DSN)"; %end;
		%if &nvar = 0 %then %do;
			data rpt;
				msg=" There are no columns with missing values.";
				output;
			run;

			proc print data=rpt noobs;
			run;
		%end;

		%else %do;
			proc print data=rpt noobs;
			var dataset variable;
			run;
		%end;
		/*output datasets*/
		%if (&outlib ne ) and &nvar. > 0 %then %do;

			%if &outlib. ne work %then %do;
				proc datasets nolist memtype=data;
					copy in=&inlib out=&outlib;
					%if &dsn ne %then %do; select &dsn; %end;
				quit;
				run;
			%end;

			data _null_;
				length varlist $1000;
				retain varlist;
				set rpt;
				by dataset;
				if first.dataset then varlist='';
				varlist=left(trim(varlist)) || ' ' || trim(variable);
				if last.dataset then
				call execute(
				"data &outlib.." || compress(dataset) || "(drop=" || trim(varlist)
				|| ");" || "set &outlib.." || compress(dataset)
				|| ";" || "run;"
				);
			run;

		%end;
		title1; title2;
		quit;
		run;

	%mend find_null_col;

	%find_null_col(work, labdata, work);

	proc sort data = labdata out=labdata_sort;
		by usubjid;
	proc sort data= demographics;
		by usubjid;
	run;

	/*merge labdata with demographic data*/
	data labdata;
		merge labdata_sort (in=a) demographics (in=b);
		by usubjid;
		if a and b;	/* added b condition -- DK */
	run;

	/*Code to check if variables exist*/
	data null ;
		dsid=open('labdata');
		check_visitnum = varnum(dsid,'visitnum');
		check_basflag = varnum(dsid,'lbblfl');
		check_lbdy = varnum(dsid,'lbdy');
		call symput ('chk_blfl',put(check_basflag,3.));
		call symput ('chk_vnum',put(check_visitnum,3.));
		call symput ('chk_lbdy',put(check_lbdy,5.));
	run;

	/* if variable is not part of dataset, create the variable*/
	%if &chk_lbdy. = 0 %then %do;

		%put LAB DAY DOES NOT EXIST ... CREATING LAB DAY;

		data labdata;
			set labdata;
			/*create study days*/
			treatdate = input(LBDTC, yymmdd10.);
			studydate = input(RFSTDTC, yymmdd10.); 
			enddate = input(LBDY, 5.);

			if enddate = . then do;
			  if treatdate >= studydate then lbdy = (treatdate - studydate)+1;
			    else lbdy = (treatdate - studydate);
			end;
			else do;
			if enddate >= studydate then lbdy = (enddate - studydate)+1;
			  else lbdy = (enddate - studydate);
			end;
		run;

	%end;


	%if &chk_blfl. = 0 %then %do; /*create baseline flag*/

		%put BASELINE FLAG DOES NOT EXIST ... CREATING BASELINE FLAG;

		data labdata1;
		set labdata;
		if lbdy le 1 then a = lbdy;
		run;

		proc sort data = labdata1;
		by usubjid descending a ;
		run;

		data bl;
		set labdata1;
		by usubjid descending a ;
		if a ne . and first.usubjid then lbblfl = "Y";
		if lbblfl = "Y" then output;
		keep usubjid lbdy lbblfl; 
		run;

		proc sort data = labdata;
		by usubjid lbdy;
		proc sort data = bl;
		by usubjid lbdy;
		run;

		data labdata;
		merge labdata (in=a) bl (in=b);
		by usubjid lbdy;
		run;
	%end;

	%if &chk_vnum. = 0 %then %do; /* create visitnum*/

		%put VISIT NUMBER DOES NOT EXIST ... CREATING VISIT NUMBER;

		proc freq data = labdata noprint;
		table lbdy/out = studydays;
		run;

		data studydays;
		set studydays;
		vnum = _n_;
		drop count percent;
		run;

		proc sort data = labdata;
		by lbdy;
		proc sort data = studydays;
		by lbdy;
		run;

		data labdata;
		merge labdata (in=a) studydays (in=b);
		by lbdy;
		run;
	%end;

	%else %do;

		/*get a list of all the visit number labels*/
		proc freq data = labdata noprint;
		table VISITNUM/out=VISITNUM;
		run; 

		/*create the variable vnum which renumbers the visitnum variable in chronological order	*/
		data VISITNUM;
		set VISITNUM;
		vnum = _N_;
		drop count percent;
		run;

		/*merge vnum onto labdata*/
		proc sort data=labdata;
		by VISITNUM;
		run;

		data labdata;
		merge labdata (in=a) visitnum (in=b);
		by VISITNUM;
		run;

	%end;

	/*create a list of subjects in the lab results dataset*/
	proc freq data = labdata noprint;
	table USUBJID/out=USUBJID;
	run;

	/*create the variable subnum which renumbers the usubjid variable in chronological order*/
	data USUBJID;
	set USUBJID;
	subnum = _N_;
	drop count percent;
	run;

	/*merge subnum onto labdata*/
	proc sort data=labdata;
	by USUBJID;
	run;

	data labdata;
	merge labdata (in=a) USUBJID (in=b);
	by USUBJID;
	run;

	proc sort data = labdata;
	by USUBJID LBTESTCD;
	run;

	/*get max lab values not a baseline*/
	proc means data = labdata NOPRINT;
		by USUBJID LBTESTCD;
		where LBBLFL NE "Y" and LBDY ge 1;
		output out = maximum_labs
		max(LBSTRESN)=LBSTRESN;
	run;

	data max_labs;
		set maximum_labs;
		rename LBSTRESN = maxlab;
		label LBSTRESN = " ";
		keep USUBJID LBTESTCD LBSTRESN;
	run;

	/*get baseline lab values*/
	data baseline_labs;
		set labdata;
		if LBBLFL = "Y";
		rename LBSTRESN = bllab
				LBSTNRHI = blhi;
		label LBSTRESN = " ";
		label LBSTNRHI = " ";
		keep USUBJID ARM RFSTDTC LBTESTCD LBTEST LBSTRESN LBSTNRHI LBDY LBDTC subnum;
	run;

	/* dataset with all max lab values and dates*/
	data max_labs_all;
		set labdata;
		if LBBLFL ne "Y" and LBDY ge 1;
		keep USUBJID ARM RFSTDTC LBTESTCD LBTEST LBSTRESN LBSTNRHI LBDY LBDTC subnum;
	run;

	proc sort data = max_labs_all;
	by usubjid lbtestcd lbstresn;
	run;

	data max_labs_stday;
		merge max_labs_all (in=a) maximum_labs (in=b);
		by usubjid lbtestcd lbstresn;
		if b;
		keep usubjid lbtestcd lbstresn ARM RFSTDTC LBTESTCD LBTEST LBSTRESN LBSTNRHI LBDY LBDTC;
	run;

	proc sort data = max_labs_stday nodupkey;
	by usubjid LBTESTCD LBSTRESN;
	run;

	data labdata_bl_max;
	merge baseline_labs (in=a) max_labs_stday(in=b);
	by USUBJID LBTESTCD;
	rename lbstresn = maxlab;
	if lbstresn = . then delete;
	if bllab = . then delete;
	run;

%mend liver_setup;


/*********************************************/
/*macro to run all analysis through every arm*/
/*********************************************/
%macro liver_arm;

	%put LIVER LAB ANALYSIS FOR EACH ARM;

	%do i = 1 %to &num.;

		%put SEPARATING OUT LABS FOR ARM &i.;

		data treatment_arms;
			set treatment_arms;
			if treatment = &i. then do;
			call symput("arm&i.", input(arm,$100.));
			call symput("dnom&i.", put(count,5.));
			end;
		run;

		/*separate out 4 liver labs into their own dataset*/
		data ASTarm&i. ALTarm&i. BILIarm&i. ALParm&i.;
			set labdata;
			if arm = "&&arm&i." then do;
			if LBTESTCD in (&l_alt.) then output ALTarm&i.;
			if LBTESTCD in (&l_ast.) then output ASTarm&i.;
			if LBTESTCD in (&l_bili.) then output BILIarm&i.;
			if LBTESTCD in (&l_alp.) then output ALParm&i.; 
			end;
		run;

		/*rename variables*/
		%MACRO LABS(lab);
			data &lab.arm&i.;
				set &lab.arm&i.;
				rename LBTESTCD = &lab.
					   LBSTRESN = &lab._RES
					   LBSTRESU = &lab._UNIT
					   LBSTNRLO = &lab._LO
					   LBSTNRHI = &lab._HI
					   LBDTC = &lab._DATE;
				label LBTESTCD = " ";
				label LBSTRESN = " ";
				label LBSTRESU = " ";
				label LBSTNRLO = " ";
				label LBSTNRHI = " ";
				label LBDTC = " ";
				if LBDY ge 1;
			RUN;
		%MEND LABS;

		%LABS (AST);
		%LABS (ALP);
		%LABS (ALT);
		%LABS (BILI);

		/*flag results above upper limit of normal*/
		data ALParm&i.;
			set ALParm&i.;
			if ALP_RES = . then ALP_miss = 1;
			if ALP_RES NE . THEN DO;

				if (ALP_RES GE ALP_HI*2) then ALPx2 = 1;
				if (ALP_RES GE ALP_HI*3) then ALPx3 = 1;
				if (ALP_RES GE ALP_HI*5) then ALPx5 = 1;
				if (ALP_RES GE ALP_HI*10) then ALPx10 = 1;
				if (ALP_RES GE ALP_HI*20) then ALPx20 = 1;
				if ALP_RES LE ALP_HI THEN ALPnorm = 1;
				if ALP_RES GE ALP_HI THEN ALP_GEHI = 1;
				if ALPnorm = 1 and LBBLFL = "Y" then ALP_basenm = 1;
			end;
			keep arm alp alp_date alp_hi alp_lo alp_res alp_unit vnum alp_basenm 
			alpnorm alp_gehi alp_miss alpx2 alpx3 alpx5 alpx10 alpx20 subnum usubjid /*studyid*/ LBBLFL;
		run;

		data ALTarm&i.;
			set ALTarm&i.;
			if ALT_RES NE . THEN DO;

			if (ALT_RES GE ALT_HI*2) then ALTx2 = 1;
			if (ALT_RES GE ALT_HI*3) then ALTx3 = 1;
			if (ALT_RES GE ALT_HI*5) then ALTx5 = 1;
			if (ALT_RES GE ALT_HI*10) then ALTx10 = 1;
			if (ALT_RES GE ALT_HI*20) then ALTx20 = 1;
			if ALT_LO < ALT_RES < ALT_HI THEN ALTnorm = 1;
			if ALTnorm = 1 and LBBLFL = "Y" then ALT_basenm = 1;
			end;
			keep arm alt alt_date alt_hi alt_lo alt_res alt_unit vnum alt_basenm 
			altnorm altx2 altx3 altx5 altx10 altx20 subnum usubjid /*studyid*/ LBBLFL;
		run;

		data ASTarm&i.;
			set ASTarm&i.;
			if AST_RES NE . THEN DO;

			if (AST_RES GE AST_HI*2) then ASTx2 = 1;
			if (AST_RES GE AST_HI*3) then ASTx3 = 1;
			if (AST_RES GE AST_HI*5) then ASTx5 = 1;
			if (AST_RES GE AST_HI*10) then ASTx10 = 1;
			if (AST_RES GE AST_HI*20) then ASTx20 = 1;
			if AST_LO < AST_RES < AST_HI THEN ASTnorm = 1;
			if ASTnorm = 1 and LBBLFL = "Y" then AST_basenm = 1;
			end;
			keep arm ast ast_date ast_hi ast_lo ast_res ast_unit vnum ast_basenm 
			astnorm astx2 astx3 astx5 astx10 astx20 subnum usubjid /*studyid*/ LBBLFL;
		run;

		data BILIarm&i.;
			set BILIarm&i.;
			if BILI_RES NE . THEN DO;
			if (BILI_RES GE BILI_HI*1.5) THEN BILIx1_5 = 1;
			if (BILI_RES GE BILI_HI*2) THEN BILIx2 = 1;
			if (BILI_RES GE BILI_HI*3) then BILIx3 = 1;
			if BILI_LO < BILI_RES < BILI_HI THEN BILInorm = 1;
			if BILInorm = 1 and LBBLFL = "Y" then Bili_basenm = 1;
			end;
			keep arm bili bili_date bili_hi bili_lo bili_res bili_unit vnum bili_basenm 
			bilinorm bilix1_5 bilix2 bilix3 subnum usubjid /*studyid*/ LBBLFL;
		run;

		/*count instances of liver labs abover normal not at baseline*/
		%macro counts (liver, uln);
		
			%put GET COUNTS OF ABNORMALLY HIGH (&uln.) LAB TEST RESULTS FOR &liver.;

			proc freq data = &liver.arm&i. noprint;
			table subnum*&liver.&uln./missing out = sub&liver.arm&i.&uln.;
			where LBBLFL ne "Y" and &liver.&uln. = 1;
			run;

			proc means data = sub&liver.arm&i.&uln. NOPRINT;
			var count;
			output out = &liver.arm&i.&uln. sum=ind_count;
			run; 

			data &liver.arm&i.&uln.;
				retain lab;
				set &liver.arm&i.&uln.;
				rename  _freq_ = subjects;
				label ind_count = " ";
				if _type_ = 0 then lab = "&liver.&uln.";
				percent = (_freq_/ &&dnom&i.)*100;
				drop _type_;
			run;

			proc sql noprint;
			  select count(*) into: num_obs
			  from &liver.arm&i.&uln.;
			quit;

			data &liver.arm&i.&uln.;
				%if &num_obs. = 0 %then %do;
				lab = "&liver.&uln.";
				subjects = 0;
				ind_count = 0;
				percent = 0;
				%end;
				%else set &liver.arm&i.&uln.;;
			run;

		%mend counts;

		%counts (alt, x2);
		%counts (alt, x3);
		%counts (alt, x5);
		%counts (alt, x10);
		%counts (alt, x20);
		%counts (ast, x2);
		%counts (ast, x3);
		%counts (ast, x5);
		%counts (ast, x10);
		%counts (ast, x20);
		%counts (alp, x2);
		%counts (alp, x3);
		%counts (alp, x5);
		%counts (alp, x10);
		%counts (alp, x20);
		%counts (alp, norm);
		%counts (alp, _GEHI);
		%counts (alp, _miss);
		%counts (bili, x1_5);
		%counts (bili, x2);
		%counts (bili, x3);

		%macro table (lab);
			data &lab.dili_arm&i.;
				retain lab ind_count;
				length lab $10.;
				set &lab.arm&i.x2 &lab.arm&i.x3 &lab.arm&i.x5 &lab.arm&i.x10 &lab.arm&i.x20;
				rename subjects = subjects_arm&i.
						ind_count = ind_count_arm&i.
						percent = percent_arm&i.;
				order = _N_;
			run;

			proc sort data = &lab.dili_arm&i.;
			by lab;
			run;

		%mend table;

		%table (alt);
		%table (ast);
		%table (alp);

		data bilidili_arm&i.;
			length lab $10.;
			set biliarm&i.x1_5 biliarm&i.x2 biliarm&i.x3;
			rename subjects = subjects_arm&i.
					ind_count = ind_count_arm&i.
					percent = percent_arm&i.;
			order = _N_;
		run;

		/*merge lab datasets to count instances by visit*/
		DATA all_labs_arm&i.;
			merge astarm&i.(in=a) altarm&i.(in=b) alparm&i.(in=c) biliarm&i.(in=d);
			by USUBJID vnum;
		run;

		data all_labs_arm&i.;
			set all_labs_arm&i.;
			WHERE LBBLFL ^= 'Y';
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx1_5 = 1 & ALPnorm = 1) then dili_1av = 1;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx2 = 1 & ALPnorm = 1) then dili_2av = 1;
			if ((ALTx5 = 1 or ASTx5 = 1)& BILIx3 = 1 & ALPnorm = 1) then dili_3av = 1;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx1_5 = 1 & ALP_GEHI = 1) then dili_4av = 1;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx2 = 1 & ALP_GEHI = 1) then dili_5av = 1;
			if ((ALTx5 = 1 or ASTx5 = 1)& BILIx3 = 1 & ALP_GEHI = 1) then dili_6av = 1;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx1_5 = 1 & ALP_miss = 1) then dili_7av = 1;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx2 = 1 & ALP_miss = 1) then dili_8av = 1;
			if ((ALTx5 = 1 or ASTx5 = 1)& BILIx3 = 1 & ALP_miss = 1) then dili_9av = 1;
		run;

		%macro table2 (lab, j);

			%put TABLE 2 MACRO, &lab.;

			proc freq data = all_labs_arm&i. noprint;
			table subnum*dili_&j.av/missing out = dili_&j.av_arm&i.;
			where dili_&j.av = 1;
			run;

			proc means data = dili_&j.av_arm&i. NOPRINT;
			var count;
			output out = dili_&j.av_arm&i. sum=ind_count;
			run;

			data dili_&j.av_arm&i.;
				retain lab;
				set dili_&j.av_arm&i.;
				rename  _freq_ = subjects;
				label ind_count = " ";
				if _type_ = 0 then lab = "&lab.";
				percent = (_freq_/ &&dnom&i.)*100;
				drop _type_;
			run;

			proc sql noprint;
			  select count(*) into: num_obs
			  from dili_&j.av_arm&i.;
			quit;

			data dili_&j.av_arm&i.;
				%if &num_obs. = 0 %then %do;
				lab = "&lab.";
				subjects = 0;
				ind_count = 0;
				percent = 0;
				%end;
				%else set dili_&j.av_arm&i.;;
			run;

		%mend table2;

		%table2 ((av)ALT or ASTx3 & Bilix1.5 & ALP normal, 1);
		%table2 ((av)ALT or ASTx3 & Bilix2 & ALP normal, 2);
		%table2 ((av)ALT or ASTx5 & Bilix3 & ALP normal, 3);
		%table2 ((av)ALT or ASTx3 & Bilix1.5 & ALP > normal, 4);
		%table2 ((av)ALT or ASTx3 & Bilix2 & ALP > normal, 5);
		%table2 ((av)ALT or ASTx3 & Bilix3 & ALP > normal, 6);
		%table2 ((av)ALT or ASTx3 & Bilix1.5 & ALP missing, 7);
		%table2 ((av)ALT or ASTx3 & Bilix2 & ALP missing, 8);
		%table2 ((av)ALT or ASTx3 & Bilix3 & ALP missing, 9);

		data dili_av_arm&i.;
			retain lab ind_count subjects;
			length lab $50.;
			set dili_1av_arm&i. dili_2av_arm&i. dili_3av_arm&i. dili_4av_arm&i. dili_5av_arm&i. dili_6av_arm&i. 
			dili_7av_arm&i. dili_8av_arm&i. dili_9av_arm&i.;
			rename subjects = subjects_arm&i.
					ind_count = ind_count_arm&i.
					percent = percent_arm&i.;
			order = _N_;
		run;

		proc sort data = dili_av_arm&i.;
		by lab;
		run;

		/*count the number of dili cases that occurred during the study, at any visit*/
		data dili_all_arm&i.;
			merge subaltarm&i.x3 (in=a) subaltarm&i.x5 (in=b) subastarm&i.x3 (in=c) subastarm&i.x5 (in=d) subalparm&i.norm (in=e)
				  subalparm&i._miss (in=f) subalparm&i._gehi (in=g) subbiliarm&i.x1_5 (in=h) subbiliarm&i.x2 (in=i) 
				  subbiliarm&i.x3 (in=j);
			by subnum;
			drop count percent;
		run;

		data dili_all_arm&i.;
			set dili_all_arm&i.;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx1_5 = 1 & ALPnorm = 1) then dili_1ds = 1;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx2 = 1 & ALPnorm = 1) then dili_2ds = 1;
			if ((ALTx5 = 1 or ASTx5 = 1)& BILIx3 = 1 & ALPnorm = 1) then dili_3ds = 1;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx1_5 = 1 & ALP_GEHI = 1) then dili_4ds = 1;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx2 = 1 & ALP_GEHI = 1) then dili_5ds = 1;
			if ((ALTx5 = 1 or ASTx5 = 1)& BILIx3 = 1 & ALP_GEHI = 1) then dili_6ds = 1;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx1_5 = 1 & ALP_miss = 1) then dili_7ds = 1;
			if ((ALTx3 = 1 or ASTx3 = 1)& BILIx2 = 1 & ALP_miss = 1) then dili_8ds = 1;
			if ((ALTx5 = 1 or ASTx5 = 1)& BILIx3 = 1 & ALP_miss = 1) then dili_9ds = 1;
		run;

		%macro table3 (lab, j);

			%put TABLE 3 MACRO, &lab.;

			proc freq data = dili_all_arm&i. noprint;
			table subnum*dili_&j.ds/missing out = dili_&j.ds_arm&i.;
			where dili_&j.ds = 1;
			run;

			proc means data = dili_&j.ds_arm&i. NOPRINT;
			var count;
			output out = dili_&j.ds_arm&i. sum=ind_count;
			run;

			data dili_&j.ds_arm&i.;
				retain lab;
				set dili_&j.ds_arm&i.;
				rename  _freq_ = subjects;
				label ind_count = " ";
				if _type_ = 0 then lab = "&lab.";
				percent = (_freq_/ &&dnom&i.)*100;
				drop _type_;
			run;

			proc sql noprint;
				select count(*) into: num_obs
				from dili_&j.ds_arm&i.;
			quit;

			data dili_&j.ds_arm&i.;
				%if &num_obs. = 0 %then %do;
				lab = "&lab.";
				subjects = 0;
				ind_count = 0;
				percent = 0;
				%end;
				%else set dili_&j.ds_arm&i.;;
			run;

		%mend table3;

		%table3 ((ds)ALT or ASTx3 & Bilix1.5 & ALP normal, 1);
		%table3 ((ds)ALT or ASTx3 & Bilix2 & ALP normal, 2);
		%table3 ((ds)ALT or ASTx5 & Bilix3 & ALP normal, 3);
		%table3 ((ds)ALT or ASTx3 & Bilix1.5 & ALP > normal, 4);
		%table3 ((ds)ALT or ASTx3 & Bilix2 & ALP > normal, 5);
		%table3 ((ds)ALT or ASTx5 & Bilix3 & ALP > normal, 6);
		%table3 ((ds)ALT or ASTx3 & Bilix1.5 & ALP missing, 7);
		%table3 ((ds)ALT or ASTx3 & Bilix2 & ALP missing, 8);
		%table3 ((ds)ALT or ASTx5 & Bilix3 & ALP missing, 9);

		data dili_ds_arm&i.;
			retain lab ind_count subjects;
			length lab $50.;
			set dili_1ds_arm&i. dili_2ds_arm&i. dili_3ds_arm&i. dili_4ds_arm&i. dili_5ds_arm&i. dili_6ds_arm&i. 
			dili_7ds_arm&i. dili_8ds_arm&i. dili_9ds_arm&i.;
			rename subjects = subjects_arm&i.
					ind_count = ind_count_arm&i.
					percent = percent_arm&i.;
			order = _N_;
		run;

		proc sort data = dili_ds_arm&i.;
		by lab;
		run;

		/*count instances of baseline and maximum values above normal*/
		data dili_blmax_arm&i.;
			set labdata_bl_max;
			if arm = "&&arm&i.";
			if (bllab < blHI*2) then bllab_1 = 1;
			if (LBSTNRHI*2 <= bllab < blHI*5) then bllab_2 = 1;
			if (LBSTNRHI*5 <= bllab < blHI*10) then bllab_3 = 1;
			if (LBSTNRHI*10 <= bllab < blHI*20) then bllab_4 = 1;
			if (bllab >= blHI*20) then bllab_5 = 1;
			if (maxlab < LBSTNRHI*2) then maxlab_1 = 1;
			if (LBSTNRHI*2 <= maxlab < LBSTNRHI*5) then maxlab_2 = 1;
			if (LBSTNRHI*5 <= maxlab < LBSTNRHI*10) then maxlab_3 = 1;
			if (LBSTNRHI*10 <= maxlab < LBSTNRHI*20) then maxlab_4 = 1;
			if (maxlab >= LBSTNRHI*20) then maxlab_5 = 1;
		run;

		%macro dili3(test, lab);

			%put DILI MACRO, &test. (&lab.);

			/* moved out from inside the loop below */
			data dili_blmax_arm&i.;
				set dili_blmax_arm&i.;
				%do j = 1 %to 5;
					%do k = 1 %to 5;

						if bllab_&j. = 1 & maxlab_1 = 1 then bl&j._mx1 = 1;
						if bllab_&j. = 1 & maxlab_2 = 1 then bl&j._mx2 = 1;
						if bllab_&j. = 1 & maxlab_3 = 1 then bl&j._mx3 = 1;
						if bllab_&j. = 1 & maxlab_4 = 1 then bl&j._mx4 = 1;
						if bllab_&j. = 1 & maxlab_5 = 1 then bl&j._mx5 = 1;

					%end;
				%end;
			run;

			%do j = 1 %to 5;
				%do k = 1 %to 5;

					%put &test. BASELINE LAB &j. MAX LAB &k.;

					proc freq data = dili_blmax_arm&i. noprint;
					table bl&j._mx&k./out = &lab._arm&i._bl&j._mx&k.;	
					where LBTEST in ("&test.") and bl&j._mx&k. = 1; 
					run;

					data &lab._arm&i._bl&j._mx&k.;
						length lab $10.;
						set &lab._arm&i._bl&j._mx&k.;
						rename count = bl&j._count
							   percent = bl&j._percent;
						percent = (count/&&dnom&i.)*100;
						label count = " ";
						label percent = " ";
						lab = "&lab._mx&k.";
						drop bl&j._mx&k.;
					run;

					proc sql noprint;
					  select count(*) into: num_obs
					  from &lab._arm&i._bl&j._mx&k.;
					quit;

					data &lab._arm&i._bl&j._mx&k.;
						length lab $10.;
						%if &num_obs. = 0 %then %do;
						bl&j._count = 0;
						bl&j._percent = 0;
						lab = "&lab._mx&k.";
						%end;
						%else set &lab._arm&i._bl&j._mx&k.;;
					run;

					data &lab._max_arm&i.;
						set dili_blmax_arm&i.;
						if LBTEST = "&test.";
						st_&lab._maxlab_arm&i. = maxlab/LBSTNRHI;
						rename maxlab = &lab._maxlab_arm&i.
								arm = arm&i.;
						label maxlab = " ";
						label arm = " ";
						keep usubjid maxlab arm st_&lab._maxlab_arm&i.;
					run;

					data &lab._maxstdy_arm&i.;
						retain usubjid arm;
						set max_labs_stday;
						if arm = "&&arm&i." & lbtest = "&test.";
						if lbdy <0 then delete;
						st_&lab._maxlab_arm&i. = lbstresn/LBSTNRHI;
						rename lbstresn = &lab._maxlab_arm&i.
								arm = arm&i.
								lbdy = lbdy_arm&i.;
						label lbstresn = " ";
						label lbdy = " ";
						label arm = " ";
						keep usubjid arm lbstresn lbdy st_&lab._maxlab_arm&i.;
					run;

					proc sort data = &lab._maxstdy_arm&i. nodupkey;
					by usubjid;
					run;

				%end;
			%end;
		%mend dili3;

		%dili3 (Alanine Aminotransferase, ALT);
		%dili3 (Aspartate Aminotransferase, AST);
		%dili3 (Total Bilirubin, BILI);
		%dili3 (Alkaline Phosphatase, ALP);

		%macro dili4(lab);
			%do k = 1 %to 5;
				data &lab._arm&i._blmax&k.;
					retain lab;
					merge &lab._arm&i._bl1_mx&k. &lab._arm&i._bl2_mx&k. &lab._arm&i._bl3_mx&k. &lab._arm&i._bl4_mx&k. &lab._arm&i._bl5_mx&k.;
					by lab;
				run;

			%end;
		%mend dili4;

		%dili4(ALT);
		%dili4(AST);
		%dili4(BILI);
		%dili4(ALP);


		%macro dili5(lab);
			data &lab._arm&i._blmax;
				retain lab;
				merge &lab._arm&i._blmax1 &lab._arm&i._blmax2 &lab._arm&i._blmax3 &lab._arm&i._blmax4 &lab._arm&i._blmax5;
				by lab;
				rename bl1_count = bl1_count_arm&i.
						bl1_percent = bl1_percent_arm&i.
						bl2_count = bl2_count_arm&i.
						bl2_percent = bl2_percent_arm&i.
						bl3_count = bl3_count_arm&i.
						bl3_percent = bl3_percent_arm&i.
						bl4_count = bl4_count_arm&i.
						bl4_percent = bl4_percent_arm&i.
						bl5_count = bl5_count_arm&i.
						bl5_percent = bl5_percent_arm&i.;
			run;

		%mend dili5;

		%dili5(ALT);
		%dili5(AST);
		%dili5(BILI);
		%dili5(ALP);

		/*dataset for ast/alt and tb max values comparison*/

		data ast_bili_max_arm&i.;
			merge ast_max_arm&i. (in=a) bili_max_arm&i. (in=b);
			by usubjid;
			drop usubjid;
		run;

		data alt_bili_max_arm&i.;
			merge alt_max_arm&i. (in=a) bili_max_arm&i. (in=b);
			by usubjid;
			drop usubjid;
		run;

	%end;

%mend liver_arm;


/*******************************************************************/
/* MERGE THE DATA FOR LAB TEST <lab> BACK TOGETHER TO MAKE ONE SET */
/*******************************************************************/
%macro liver_one(lab);

	%put MERGE DATA FOR LAB TEST &lab.;

	data &lab.dili_all;
		  merge
		%macro sets;
			%do S = 1 %to &num.;
			  &lab.dili_arm&S.
			%end;
		%mend sets;
		%sets;
		;
		by lab;
	run;

	proc sort data = &lab.dili_all;
	by order;
	run;

	data &lab.blmax_all;
		  merge
		%macro sets;
			%do S = 1 %to &num.;
			  &lab._arm&S._blmax
			%end;
		%mend sets;
		%sets;
		;
		by lab;
	run;

	data dili_av_all;
		merge
		%macro sets;
			%do S = 1 %to &num.;
			  dili_av_arm&S.
			%end;
		%mend sets;
		%sets;
		;
		by lab;
	run;

	proc sort data = dili_av_all;
	by order;
	run;

	data dili_ds_all;
		merge
		%macro sets;
			%do S = 1 %to &num.;
			  dili_ds_arm&S.
			%end;
		%mend sets;
		%sets;
		;
		by lab;
	run;

	proc sort data = dili_ds_all;
	by order;
	run;

	data &lab._maxstdy_all;
		merge
		%macro sets;
			%do S = 1 %to &num.;
			  &lab._maxstdy_arm&S.
			%end;
		%mend sets;
		%sets;
		;
		drop usubjid;
	run;

%mend liver_one;


/*************************************************/
/* MERGE TOGETHER TABLES FOR ALL LIVER LAB TESTS */
/*************************************************/
%macro liver_outfmt;

	%put PUT DATASETS TOGETHER FOR OUTPUT;

	data ast_bili_max_all;
		merge
		%macro sets;
			%do S = 1 %to &num.;
			  ast_bili_max_arm&S.
			%end;
		%mend sets;
		%sets;
	run;

	data alt_bili_max_all;
		merge
		%macro sets;
			%do S = 1 %to &num.;
			  alt_bili_max_arm&S.
			%end;
		%mend sets;
		%sets;
	run;

	data lab_tables;
		set altdili_all astdili_all alpdili_all bilidili_all;
		drop order;
	run;

	data hyslaw;
		set dili_av_all dili_ds_all;
		drop order;
	run;

	data max_bl_tables;
		set altblmax_all astblmax_all alpblmax_all biliblmax_all;
	run;

/*Enhancement to return hy's law subject id's */

	data _null_;
		set treatment_arms end=stuff;
		if stuff then output;
		call symput('ngroup',strip(treatment));
	run;

	%put &ngroup;

	%macro naming();

		data _null_;
			%do i=1 %to &ngroup;
				var&i = "Dili_all_arm&i ";
			%end;
			result=CAT(OF var1-var&ngroup);
			%global result;
			call symput("result",result);
		run;

	%mend;

	%naming;

	%put &result;

	data test1 (keep=subnum dili_1ds dili_2ds dili_3ds dili_4ds dili_5ds dili_6ds dili_7ds dili_8ds dili_9ds);
		set &result;
		array qual{9} dili_1ds dili_2ds dili_3ds dili_4ds dili_5ds dili_6ds dili_7ds dili_8ds dili_9ds; 
		do i=1 to 9; 
			if qual(i)=1 then output;
		end;
	run;

	proc sort data=test1 nodupkey;
		by subnum;
	run;

	proc sql;
		create table hylawindT (drop=subnum) as
		select b.*, c.* from test1 b
		left outer join USUBJID a
		on b.subnum=a.subnum
		left outer join DM c
		on c.USUBJID=a.USUBJID;
		create table hylawind as
		select dili_1ds, dili_2ds, dili_3ds, dili_4ds, dili_5ds, dili_6ds, dili_7ds, dili_8ds, dili_9ds,
		USUBJID, ARM from hylawindT;
	quit;

/*End of Enhancement*/

/*Enhancement to track multiple and conflicting baseline*/

	proc sort data=lb;
		by USUBJID;
	run;

	data blconflict1(keep = USUBJID LBTESTCD LBSTRESN LBSTRESU LBSTNRHI LBNAM LBBLFL LBSTAT LBDTC LBDY ARM);
		merge lb(in=a) dm(in=b keep=usubjid arm);
		by usubjid;
		if a and LBBLFL='Y' and ARM ne '';
	run;

	proc sort data=blconflict1;
		by USUBJID LBTESTCD;
	run;

	data blconflict;
		set blconflict1;
		by USUBJID LBTESTCD;
		if not (first.LBTESTCD=1 and last.LBTESTCD=1);
	run;

/*	proc sort data=blconflict1;*/
/*		by USUBJID LBTESTCD LBSTRESN;*/
/*	run;*/
/**/
/*	data blconflict2 (keep=USUBJID LBTESTCD qual);*/
/*		set blconflict1;*/
/*		by USUBJID LBTESTCD LBSTRESN;*/
/*		qual=1;*/
/*		if (first.LBSTRESN=1 and last.LBSTRESN=1);*/
/*	run;*/
/**/
/*	proc sort data=blconflict2 nodupkey;*/
/*		by USUBJID;*/
/*	run;*/
/**/
/*	proc sort data=blconflict1;*/
/*		by USUBJID LBTESTCD;*/
/*	run;*/
/**/
/*	proc sort data=blconflict2;*/
/*		by USUBJID LBTESTCD;*/
/*	run;*/
/**/
/*	data blconflict (drop=qual);*/
/*		merge blconflict1 blconflict2;*/
/*		by USUBJID LBTESTCD;*/
/*		if qual=1;*/
/*	run;*/

/* truncate the list at 100 */

	data blconflict;
		retain usubjid LBTESTCD LBSTRESN LBSTRESU LBSTNRHI Blank1 LBNAM Blank2 Blank3 LBBLFL LBSTAT LBDTC LBDY ARM;
		length usubjid $100.;
		set blconflict;

		dsid = open('blconflict');
		nobs = attrn(dsid,'nobs');
		rc = close(dsid);

		if _n_ = 101 then do;
			USUBJID = trim(put(nobs,8. -l))||' events - Truncated at 100';
			LBTESTCD = '';   
			LBSTRESN = .;
			LBSTRESU = '';
			LBSTNRHI = .;
			LBNAM = '';
			LBBLFL = '';
			LBSTAT = '';
			LBDTC = '';
			LBDY = .;
			ARM = '';
			Blank1 = '';
			Blank2 = '';
			Blank3 = '';
		end;
		else if _n_ > 101 then delete;

		drop dsid nobs rc;
	run;

/*End of this enhancement*/

%mend liver_outfmt;


/*******************/
/* OUTPUT TO EXCEL */
/*******************/
%macro liver_output; 

	%put OUTPUT TO EXCEL;

	/*dataset with timestamp and source information*/
	data info;
		length path $500;
		path = "&ndabla.";
		output;

		path = "&studyid.";
		output;

		path = compbl(put(date(),e8601da.)||' '||put(time(),timeampm11.));
		output;

		path = ""; /* "&sl_custom_ds."; */
		output;

		%if &dm_actarm. %then %do;
			path = "ACTARM";
			output;
		%end;
		%else %do;
			path = "ARM";
			output;
		%end;
	run;

	/* libname export method */
	/* added by DK */
	%if not %symexist(run_location) %then %let run_location = LOCAL;

	/* local runs use the Microsoft Jet database-based Excel LIBNAME engine */
	%if %upcase(&run_location.) = LOCAL %then %do;
		*libname xls excel "&liverout." ver=2003; *Output function changed due to SAS 9.3(64bit) and Excel 2010(32bit) incompatability;
		libname xls pcfiles path="&liverout."; 
	%end;
	/* Script Launcher runs use the PCFILES LIBNAME Engine */
	%else %do;
	    %put &liverout.;
		libname xls pcfiles path="&liverout."; 
	%end;

	proc sql noprint;
		drop table xls.treatment_arms,
		           xls.data_lab_table,
				   xls.data_hy_s_law,
				   xls.data_max_vs_bl, 
				   xls.data_ast_vs_bili,
				   xls.data_alt_vs_bili,
				   xls.data_alt_max_stdy,
				   xls.data_ast_max_stdy,
				   xls.data_alp_max_stdy,
				   xls.data_tb_max_stdy,
				   xls.data_Hy,
				   xls.data_BLconflict,
				   xls.data_BLconflictS,
				   xls.information
	               ;
	quit;  

	data xls.treatment_arms;
		set treatment_arms;
	run;

	data xls.data_lab_table;
		set lab_tables;
	run;

	data xls.data_hy_s_law;
		set hyslaw;
	run;

	data xls.data_max_vs_bl;
		set max_bl_tables;
	run;

	data xls.data_ast_vs_bili;
		set ast_bili_max_all;
	run;

	data xls.data_alt_vs_bili;
		set alt_bili_max_all;
	run; 

	data xls.data_ast_max_stdy;
		set ast_maxstdy_all;
	run;

	data xls.data_alt_max_stdy;
		set alt_maxstdy_all;
	run;

	data xls.data_alp_max_stdy;
		set alp_maxstdy_all;
	run; 

	data xls.data_tb_max_stdy;
		set bili_maxstdy_all;
	run;

/*Enhancement addition for USUBJID Hy's law and Multiple Baseline Conflict*/

	data xls.data_hy;
		set Hylawind;
	run;

	data xls.data_blconflict;
		set Blconflict;
	run;

	proc sql noprint;
		select count(1) into: bkc_count
		from blconflict;
	quit;

	data xls.data_BLconflictS;
		length data $25;
		data = 'bkc_count'; val = %sysfunc(ifc(%symexist(bkc_count),&bkc_count.,0)); output;
	run;

/*Enhancement end*/

	data xls.information;
		set info;
	run;

	libname xls clear;

	%liver_check_output;

%mend liver_output;


/****************************/
/* LIVER LAB ANALYSIS PANEL */
/****************************/
%macro liver;

	%put LIVER LAB ANALYSIS PANEL;

	%liver_prelim;

	%if &dm_subj_gt0. and &all_req_var. and &liver_lbtestcd. %then %do;

		%liver_setup;

		%liver_arm;

		%liver_one(ALT);
		%liver_one(AST);
		%liver_one(BILI);
		%liver_one(ALP);

		%liver_outfmt; 

		/* liver panel data checks */
		%liver_check;

		/* do preprocessing of Script Launcher datasets */
		%group_subset_pp;

		%liver_output;

		/* create grouping & subsetting output */
		%group_subset_xls_out(gs_file=&liverout.);

	%end; 
	%else %do;
		%error_summary(err_file=&errout.,
                       err_nosubj=%sysfunc(ifc(&dm_subj_gt0.,0,1)),
                       err_missvar=%sysfunc(ifc(&all_req_var.,0,1)),
					   err_desc=%quote(&err_liver_lbtest.)
                       );
	%end;

	%if %upcase(&run_location.) = LOCAL %then %do;
		proc printto; run;
		options notes;
	%end;

%mend liver;


%liver;
