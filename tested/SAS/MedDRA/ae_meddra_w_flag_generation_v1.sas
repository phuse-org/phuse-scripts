/****************************************************************************/
/*                                                                          */
/*         PROGRAM NAME: MedDRA at a Glance Panel                           */
/*                                                                          */
/*          DESCRIPTION: Find subject counts per arm for each adverse event	*/
/*                        at each MedDRA level                              */
/*                       Find risk difference, relative risk, and Fisher's  */
/*                        exact test p-value for each pair of arms          */
/*                       Creates an Excel XML output file which allows      */
/*                        users to compare arms and highlight terms with    */
/*                        statistics above user-set thresholds              */
/*                                                                          */
/*      EVALUATION TYPE: Safety                                             */
/*                                                                          */
/*               AUTHOR: David Kretch (david.kretch@us.ibm.com)	            */
/*                                                                          */
/*                 DATE: February 15, 2011                                  */
/*                                                                          */
/*  EXTERNAL FILES USED: ae_setup.sas -- Merges AE, DM, and EX              */
/*                       ae_meddra.sas -- Does the analysis                 */
/*                       ae_meddra_output.sas -- Creates the output         */
/*                       xml_output.sas -- XML formatting macros            */
/*                       data_checks.sas -- Generic variable checks         */
/*                       sl_gs_output.sas -- Script Launcher settings output*/
/*                       err_output.sas -- Error output when missing vars   */
/*                       mdhier_x_y.sas7bdat -- MedDRA hierarchy ver. X.Y   */
/*                       dme.sas7bdat -- Designated Medical Events list     */
/*                                                                          */
/*  PARAMETERS REQUIRED: saspath -- location of external panel SAS programs */
/*                       utilpath -- location of external util SAS programs */
/*                       meddrapath -- location of MedDRA hierachy datasets */
/*                       dmepath -- location of the DME list dataset        */
/*                       aemedout -- file and path of output                */
/*                                                                          */
/*                       ver -- MedDRA version                              */
/*                       study_lag -- window in days after last exposure    */
/*                                    where AEs should be kept in analysis  */
/*                       cc -- continuity correction value                  */
/*                                                                          */
/*           LOCAL ONLY: outpath -- location of the output                  */
/*                       studypath -- location of the drug study datasets   */
/*                                                                          */
/*   VARIABLES REQUIRED: AE -- AEBODSYS                                     */
/*                             AEDECOD                                      */
/*                             USUBJID                                      */
/*                       DM -- ACTARM or ARM                                */
/*                             USUBJID                                      */
/*                       EX -- USUBJID                                      */
/*                                                                          */
/*       VARIABLES USED: AE -- AESTDTC                                      */
/*       WHEN AVAILABLE  DM -- RFSTDTC                                      */
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
2011-03-27  DK  Adding SL to SAS parameter mapping
                Run location handling
2011-05-07	DK  Changed lines 1827-1829 in ae_meddra_output to make the arm count
                a comma formatted number stored in a character variable
2011-05-08  DK  Added handling for errors in case DM has no subjects


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
		%let panel_title = MedDRA at a Glance;
		%let panel_desc = ;

		%global saspath utilpath;
		%let saspath = ;
		%let utilpath = ;

		%global outpath aemedout errout;
		%let outpath = ;
		%let aemedout = &outpath.\MedDRA at a Glance Analysis Panel.xls;	
		%let errout = &outpath.\MedDRA at a Glance Error Summary.xls;

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

		/* designated medical events */
		%let dmepath = ;

		libname dme "&dmepath.";

		/* study lag in days; determines window in days following the end of a study */
		/* in which AEs should be included in the analysis */
		%global study_lag;
		%let study_lag = 30;

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

		/* designated medical events */
		libname dme "&utildatapath.";

		/* map the user-defined Script Launcher panel option values onto panel macro variables */
		data _null_;

			/* MedDRA version */
			meddraver = "&meddraver.";
			meddra = ifc(upcase(substr("&meddraver.",1,1)) = 'N','N','Y'); 
			call symputx('ver',meddraver,'g'); 
			call symputx('meddra',meddra,'g'); 

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

/* (default) thresholds for minimum risk difference, fold difference, relative risk */
%let rd_th = 5;
%let rr_th = 5;
%let pv_th = ;

%include "&utilpath.\ae_setup.sas"; 	
%include "&saspath.\ae_meddra_output.sas";
%include "&utilpath.\data_checks.sas"; 
%include "&utilpath.\err_output.sas";
%include "&utilpath.\sl_gs_output.sas";
%include "&utilpath.\xml_output.sas";

/* set the continuity correction switch */
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

/********************************************************************/
/* aggregate the input dataset (dsin) by the by variables (by1-by4) */
/* and write to the output dataset (dsout)                          */
/********************************************************************/
%macro meddra(dsin,dsout,by1,by2,by3,by4,output=yes);

	/* find the number of by variables */
	%let i = 1;
	%do %while (%symexist(by&i.));
		%if (&&&by&i. = ) %then %goto exit;
		%let i = %eval(&i. + 1);
	%end;
	%exit: %let max_arg = %eval(&i. - 1);

	%if %symexist(key) %then %symdel key;

	/* create the by variable key */
	data _null_;
		key = %do i = 1 %to &max_arg.; "&&&by&i. "|| %end;'';
		call symputx('key',key);
	run;

	/* print current activity to the log */
	data _null_;
		title = "AGGREGATING &dsin. INTO &dsout. BY &key.";
		titlen = length(title);
		length separator $100;
		do i = 1 to titlen;
			separator =  trim(left(separator))||"*";
		end;

		put separator;
		put;
		put title;
		put;
		put separator;
	run;

	/* sort input dataset by the by variables */
	/* keep one record per subject and by key */ 
	proc sort data=&dsin.
               out=&dsout._sort(keep=usubjid arm_num &key. %if &&&by&max_arg. = pt_name %then dme;) nodupkey; 
		by &key. usubjid; 
	run;

	data &dsout.;
		set &dsout._sort;
		by &key.;

		/* AE counts for each arm */
		retain %do i = 1 %to &arm_count.;
				  arm&i._count
			   %end;
			   ;
		array arm{&arm_count.} 
			%do i = 1 %to &arm_count.; arm&i._count %end;
			; 

		/* initialize sums to zero */
		if first.&&&by&max_arg. then do i = 1 to &arm_count.;
			arm(i) = 0;
		end;

		/* summing */
		arm(arm_num) = arm(arm_num) + 1;

		/* percentages of arm safety population */
		if last.&&&by&max_arg. then do;
	        %do i = 1 %to &arm_count.;
			    arm&i._pct = 100*arm&i._count/&&&arm_&i.;
			%end;
		end; 

		if last.&&&by&max_arg. then output;

		label %do i = 1 %to &arm_count.;  
              arm&i._count="&&&arm_name_&i. Subject Count"
              arm&i._pct="&&&arm_name_&i. %"
			  %end;
			  ;

		keep &key. 
             %if &&&by&max_arg. = pt_name %then dme; 
             %do i = 1 %to &arm_count.; arm&i._count arm&i._pct %end;
             ;
	run;

	/* dataset for output */
	data &dsout.;
		retain &key. 
               %if &&&by&max_arg. = pt_name %then dme; 
               %do i = 1 %to &arm_count.; arm&i._count arm&i._pct %end;
               ;
		set &dsout.(keep=&key. 
                         %if &&&by&max_arg. = pt_name %then dme; 
                         %do i = 1 %to &arm_count.; arm&i._count arm&i._pct %end;
                    );
		by &key.;

		level = &max_arg.;

		/* level numbers; soc => 1, hlgt => 2, hlt => 3, pt => 4 */
		retain %do i = 1 %to &max_arg.; %substr(&&&by&i.,1,%eval(%index(&&&by&i.,_)-1)) %end;;
		%do i = 1 %to &max_arg.;
			if first.&&&by&i. then %substr(&&&by&i.,1,%eval(%index(&&&by&i.,_)-1)) = 
									sum(%substr(&&&by&i.,1,%eval(%index(&&&by&i.,_)-1)),1);
		%end;
	run;

	/* risk difference, relative risk, and p-value ranking */
	%if &arm_count. > 1 %then %do;
		data &dsout.;
			set &dsout.;

			%do i = 1 %to &arm_count.;
				%do j = 1 %to &arm_count.; 
					%if &i. ne &j. %then %do;

						/* risk difference */
						rd&i.&j. = arm&i._pct - arm&j._pct;

						/* set up 2x2 contingency table */
						a = arm&i._count;
						b = &&&arm_&i. - a;
						c = arm&j._count;
						d = &&&arm_&j. - c;

						/* Fisher's exact test */
						/*row = a + b;
						col = a + c;
						total = a + b + c + d;

						pdf = pdf('hyper',a,total,row,col);

						do i = 0 to min(row,col);
							pdfi = pdf('hyper',i,total,row,col);
							if pdfi <= pdf then pv&i.&j. = sum(pv&i.&j.,pdfi);
						end;
						drop row col total pdf pdfi i;

						pv&i.&j. = -log(pv&i.&j.);*/

						/* continuity correction */
						%if (&cc_sw. ne 0) %then %do; 

							if (/*a = 0 or b = 0 or */c = 0/* or d = 0*/) then do;

								/* continuity correction constant k = 1, 1/2, etc. */
								%if (&cc_sw. = 1) %then %do;
									a = a + &cc.;
									b = b + &cc.;
									c = c + &cc.;
									d = d + &cc.;
								%end;
								/* continuity correction reciprocal of opposite arm */
								%else %if &cc_sw. = 2 %then %do;
									a = a + 1/(c+d);
									b = b + 1/(c+d);
									c = c + 1/(a+b);
									d = d + 1/(a+b);
								%end;

								cc&i.&j. = '*';

							end;

						%end;

						/* relative risk calculation */
						if c ne 0 then rr&i.&j. = (a/(a+b)) / (c/(c+d));
						*else if a ne 0 then rr&i.&j. = .I;

					%end;
				%end;
			%end;

			drop a b c d;
		run;

		/* Fisher's exact test */
		/* set up the n x 2 table */
		data &dsout._ct(keep=term_num arm_num disease count)
             &dsout._term_num(keep=&key. term_num);
			set &dsout.;
			by &key.;

			%do i = 1 %to &arm_count.;

				term_num = _n_;
				if first.&&&by&max_arg. then output &dsout._term_num;

				arm_num = &i.;
				
				disease = -1;
				count = arm&i._count;
				output &dsout._ct;

				disease = 0;
				count = &&&arm_&i. - arm&i._count;
				output &dsout._ct;

			%end;

		run;

		/* find Fisher's exact test 2-tail p-value */
		/* for all pairs of arms (i,j) i < j */
		%do i = 1 %to &arm_count.;
			%do j = 1 %to &arm_count.;
				%if &i. < &j. %then %do;

				/* turn off notes temporarily to avoid notes about missing levels */
				options nonotes;

				/* find the p-value with EXACT FISHER */
				/* this method differs from the data step calculation by < 0.00001 */
				/* except in the case that both arms have 0 subjects, in which case */
				/* the FREQ procedure produces a missing value instead of 1 */
				proc freq data=&dsout._ct(where=(arm_num in (&i. &j.))) noprint;
					table arm_num*disease / nowarn; 
					weight count;
					by term_num;
					exact fisher;
					output out=&dsout._fisher_&i.&j. fisher;
				run;

				options notes;

				/* Fisher's exact test p-value does not depend on the order of the arms */
				/* find the negative log of the p-value */
				data &dsout._fisher_&i.&j.(keep=term_num pv:);
					set &dsout._fisher_&i.&j.;
					pv&i.&j. = -log(xp2_fish);
					pv&j.&i. = -log(xp2_fish);
				run;

				%end;
			%end;
		%end;

		/* combine p-values with output dataset */
		/* merge by the numeric identifier for each level */
		/* e.g. soc when the soc_name is the level being processed */
		data &dsout.;
			merge &dsout.
			      %do i = 1 %to &arm_count.;
					%do j = 1 %to &arm_count.;
						%if &i. < &j. %then %do;
							&dsout._fisher_&i.&j.(rename=(term_num=
                                                  %substr(&&&by&max_arg.,1,%eval(%index(&&&by&max_arg.,_)-1))))
						%end;
					%end;
				  %end;
				  ;
			by %substr(&&&by&max_arg.,1,%eval(%index(&&&by&max_arg.,_)-1));
		run;

	%end; /* if &arm_count. > 1 */

	/* reorder variables */
	data &dsout.;
		retain &key. %do i = 1 %to &arm_count.;
                        arm&i._count arm&i._pct
					 %end;
					 %do i = 1 %to &arm_count.;
						%do j = 1 %to &arm_count.;
                           %if &i. ne &j. %then %do;
                              rd&i.&j. rr&i.&j. pv&i.&j.
						   %end;
						%end;
		             %end;
			   ;
		set &dsout.;
	run;

	/* clean up datasets */
	proc datasets library=work nolist nodetails; 
		delete &dsout._sort
               &dsout._ct
			   &dsout._term_num
			   &dsout._fisher:
			   ;
	quit;

%mend meddra;


/****************************/
/* make comparison datasets */
/****************************/
%macro meddra_cmp;

	/* overview dataset with all arms */
	data meddra_cmp(drop=row)
         meddra_cmp_data(drop=soc_name hlgt_name hlt_name pt_name dme row)
         meddra_cmp_data_row(keep=level soc hlgt hlt pt row);
		retain level soc_name hlgt_name hlt_name pt_name;
		set meddra_1(in=a)
		    meddra_2(in=b)
			meddra_3(in=c)
			meddra_4(in=d);

		/* order of the data sorted by level as it appears in the hidden data tab */
		row + 1;
	run;

	proc sort data=meddra_cmp out=meddra_cmp;
		by soc_name hlgt_name hlt_name pt_name level;
	run;

	/* add columns for indicators showing whether a signal exists */
	/* at a given level of the MedDRA hierarchy */
	data meddra_cmp_output(keep=level soc_name hlgt_name hlt_name pt_name dme
		                        sgnl sgnl_soc sgnl_hlgt sgnl_hlt sgnl_pt
			                    arm_exp_count arm_exp_pct arm_ctl_count arm_ctl_pct
			                    rd rr %if &cc_sw. %then cc; pv row)
         meddra_cmp_output_row(keep=level soc hlgt hlt pt row);
		retain level soc_name hlgt_name hlt_name pt_name dme
		       sgnl sgnl_soc sgnl_hlgt sgnl_hlt sgnl_pt
			   arm_exp_count arm_exp_pct arm_ctl_count arm_ctl_pct
			   rd rr %if &cc_sw. %then cc; pv 
			   row
               soc hlgt hlt pt;
		set meddra_cmp;

		/* order of the data as it initially appears on the visible	analysis tab */
		row + 1;

		length sgnl $1 sgnl_soc $1 sgnl_hlgt $1 sgnl_hlt $1 sgnl_pt $1 %if &cc_sw. %then cc $1;;

		call missing(arm_exp_count,arm_exp_pct,arm_ctl_count,arm_ctl_pct);
		call missing(rd,rr,pv);
		%if &cc_sw. %then %do; call missing(cc); %end;
		call missing(sgnl,sgnl_soc,sgnl_hlgt,sgnl_hlt,sgnl_pt);
	run;

	/* arrange data dataset; add columns to be filled with Excel analysis formulas */
	data meddra_cmp_data;
		retain level soc hlgt hlt pt rd rr pv cc sgnl sgnl_soc sgnl_hlgt sgnl_hlt sgnl_pt sgnl_any;
		set meddra_cmp_data;
		length cc $1;
		rd = .;
		rr = .;
		pv = .;	
		cc = '';
		sgnl = .;
		sgnl_soc = .;
		sgnl_hlgt = .;
		sgnl_hlt = .;
		sgnl_pt = .;
		sgnl_any = .;
	run;

	/* put row datasets in proper format */
	/* these will be merged while creating output and used in creating formulas */
	%do i = 1 %to 2;
		%let ds = %scan(data output,&i.);
		data meddra_cmp_&ds._row(keep=row lvl_nm lvl_no soc hlgt hlt pt);
			set meddra_cmp_&ds._row;
			length lvl_nm $4 lvl_no 8.;
			select (level);
				when (1) do; lvl_nm = 'soc'; lvl_no = soc;	end;
				when (2) do; lvl_nm = 'hlgt'; lvl_no = hlgt; end;
				when (3) do; lvl_nm = 'hlt'; lvl_no = hlt;	end;
				when (4) do; lvl_nm = 'pt'; lvl_no = pt;	end;
				otherwise;
			end;
		run;
	%end;

%mend meddra_cmp; 


/********************************************/
/* RUN MEDDRA AT A GLANCE ANALYSIS PANEL */
/********************************************/
%macro aemed;

	%setup(mdhier=Y,dme=Y);

	%if &setup_success. and &meddra_pct. > 0 %then %do;

		%meddra(ds_base_meddra,meddra_1,soc_name); 
		%meddra(ds_base_meddra,meddra_2,soc_name,hlgt_name); 
		%meddra(ds_base_meddra,meddra_3,soc_name,hlgt_name,hlt_name);
		%meddra(ds_base_meddra,meddra_4,soc_name,hlgt_name,hlt_name,pt_name);

		%meddra_cmp;

		%out_med;

	%end;
	%else %do;
		%error_summary(err_file=&errout.,
                       err_nosubj=%sysfunc(ifc(&dm_subj_gt0.,0,1)),
                       err_missvar=%sysfunc(ifc(&setup_req_var.,0,1)),
					   err_desc=%sysfunc(ifc(&meddra_pct.=0,%str(There were zero adverse events with matching MedDRA descriptions.),))
                       );
	%end;

%mend aemed;


%let start = %sysfunc(time());

/* run the MedDRA at a Glance analysis */
%aemed;



%let end = %sysfunc(time());

%let diff = %sysevalf(&end. - &start.);

%put NOTE: RUNNING TIME: %sysfunc(trim(%sysfunc(putn(&diff.,mmss20))));

%put &outpath.;
