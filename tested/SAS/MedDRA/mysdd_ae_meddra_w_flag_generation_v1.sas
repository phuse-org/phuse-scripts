/****************************************************************************/
/*                                                                          */
/*         PROGRAM NAME: MedDRA at a Glance Panel                           */
/*                                                                          */
/*          DESCRIPTION: Find subject counts per arm for each adverse event */
/*                        at each MedDRA level                              */
/*                       Find risk difference, relative risk, and Fisher's  */
/*                        exact test p-value for each pair of arms          */
/*                       Creates an Excel XML output file which allows      */
/*                        users to compare arms and highlight terms with    */
/*                        statistics above user-set thresholds              */
/*                                                                          */
/*      EVALUATION TYPE: Safety                                             */
/*                                                                          */
/*               AUTHOR: David Kretch (david.kretch@us.ibm.com)	          */
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
/*"&utilpath"
2011-03-27  DK  Adding SL to SAS parameter mapping
                Run location handling
2011-05-07	DK  Changed lines 1827-1829 in ae_meddra_output to make the arm count
                a comma formatted number stored in a character variable
2011-05-08  DK  Added handling for errors in case DM has no subjects

*/

options MAUTOSOURCE sasautos=("&bumlib"  sasautos) symbolgen mprint source2;

libname inlib "&studypath.";
libname outlib "&outpath ";
libname meddra "&meddrapath.";
libname dme "&meddrapath.";

%include "&utilpath./ae_setup.sas"; 	
%include "&utilpath./ae_meddra_output.sas";
%include "&utilpath./data_checks.sas"; 
%include "&utilpath./err_output.sas";
%include "&utilpath./sl_gs_output.sas";
%include "&utilpath./xml_output.sas";


/* YL Create input file *******/
	%let aemedout =%str(&outpath./MedDRA at a Glance Analysis Panel.xls);	
	%let errout =%str(&outpath./MedDRA at a Glance Error Summary.xls);
%put yyyy=&outpath.;
%put yyyyyyyy=&errout;

libname dict "&meddradict ";

/*

data meddra;
 set dict.dict_meddra(where=(dictver='14.1'));
 AEDECOD=PFTERM;
 AEBODSYS=SOCTERM;
  rename 	
         SOCTERM=SOC_NAME
	      HLGTERM =HLGT_NAME
         HLTERM=HLT_NAME
	      PFTERM =PT_NAME
         LLTERM=LLT_NAME
         PRISOCFLG=primary_soc_fg ;
 run;


data meddra.mdhier_14_1;
 set meddra;
 keep DICTVER AEDECOD	AEBODSYS SOC_NAME HLGT_NAME 	HLT_NAME PT_NAME  LLT_NAME primary_soc_fg;

run;



 proc sql;
 create table allae as 
 select AEDECOD
 from inlib.ae
;
quit;

proc sort data=allae nodupkey; by AEDECOD;run;

proc sql ;
 create table mdhier_14_1x as 
 select  DICTVER ,a.AEDECOD,	AEBODSYS, SOC_NAME, HLGT_NAME ,	HLT_NAME, PT_NAME, LLT_NAME,primary_soc_fg 
 from  meddra.mdhier_14_1 as a , allae as b
 where a.AEDECOD=b.AEDECOD;
 quit;
 
proc sort data=mdhier_14_1x out=meddra.mdhier_14_1x  noduprecs; by AEDECOD ;run;


data dme;
 set meddra.mdhier_14_1x ;
 keep LLT_NAME;
proc sort noduprecs;by LLT_NAME;
run;

data meddra.dme;
 set dme;
 VER='14.1';
 DME='Y';

proc sql;
 create table allae as
 select unique aedecod 
 from inlib.ae;
quit;

proc sql ;
 create table allaex as 
 select  *
 from  meddra.mdhier_14_1 as a , allae as b
 where a.AEDECOD=b.AEDECOD;
 quit;
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

     /* YL ERROR*/
		/*data _null_; set macrovar; call execute('%symdel '||trim(left(name))||';');	run;
		proc datasets kill; quit; 
        */
		%global panel_title panel_desc;
		%let panel_title = MedDRA at a Glance;
		%let panel_desc = ;

		%global saspath utilpath;
	*	%let saspath = ;
	*	%let utilpath = ;

    *  libname inlib "&studypath.";
    *  libname outlib "&outpath ";
     %put yyyy=&outpath.;
/*		%global  aemedout errout;
		*%let outpath = ;

		%let aemedout =%str(&outpath./MedDRA_Analysis_Panel.xls);	* MedDRA_ at a Glance Analysis Panel.xls;
		%let errout =%str(&outpath./MedDRA_Error_Summary.xls);
*/
  

	 *	%let studypath = ;
    * libname inlib "&studypath."; 

		/* retrieve the required datasets */
		data ae; set inlib.ae; run;
		data dm; set inlib.dm; run;
		data ex; set inlib.ex; run;

		/* NDA/BLA and study number */
		%global ndabla studyid;
		%let ndabla = xxx;
		%let studyid = fdadata;

		/* MedDRA hierachy */
	*	%let meddrapath = ;
   *	libname meddra "&meddrapath.";

		/* MedDRA version */
		%global ver meddra meddra_pct; 
		%let ver =14.1 ; 
		%if %upcase(%substr(&ver.,1,1)) = N %then %do;
			%let meddra = N;
			%let meddra_pct = 0;
		%end;
		%else %let meddra = Y;

		/* designated medical events */
		*%let dmepath = ;
		* libname dme "&dmepath.";
      * libname dme "&meddrapath.";

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
			*delete;
		run;
		data sl_group;
			group_name = ''; domain = ''; partition = ''; var_name = ''; var_value = ''; dsvg_grp_name = ''; 
			*delete;
		run;
		data sl_subset;
			name = ''; domain = ''; partition = ''; var_name = ''; var_value = ''; inner_operator = ''; outer_operator = '';
			*delete;
		run;

	%end; 

	/* program parameters if the program is run through Script Launcher */
	

%mend params;

%params; 

/* data validation switch; determines whether to perform data validation on AEs */
%let vld_sw = 1; 

/* (default) thresholds for minimum risk difference, fold difference, relative risk */
%let rd_th = 5;
%let rr_th = 5;
%let pv_th = ;
/*

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
		%error_summary(err_file= &errout.,
                       err_nosubj=%sysfunc(ifc(&dm_subj_gt0.,0,1)),
                       err_missvar=%sysfunc(ifc(&setup_req_var.,0,1)),
					   err_desc=%sysfunc(ifc(&meddra_pct.=0,%str(There were zero adverse events with matching MedDRA descriptions.),))
                       );
	%end;

%mend aemed;


%let start = %sysfunc(time());

/* run the MedDRA at a Glance analysis */
%aemed;


%ut_saslogcheck;

%let end = %sysfunc(time());

%let diff = %sysevalf(&end. - &start.);

%put NOTE: RUNNING TIME: %sysfunc(trim(%sysfunc(putn(&diff.,mmss20))));

%put &outpath.;

****************************************;
%ut_saslogcheck;
/******PACMAN****** DO NOT EDIT BELOW THIS LINE ******PACMAN******/
/*<?xml version="1.0" encoding="UTF-8"?>*/
/*<process sessionid="29febe54:1535222af11:-21d6" sddversion="3.5" cdvoption="N" parseroption="B">*/
/* <parameters>*/
/*  <parameter userdefined="S" obfuscate="N" id="&star;LST&star;" canlinktobasepath="Y" protect="N" label="SAS output" systemtype="&star;LST&star;" order="1" processid="P5" dependsaction="ENABLE" baseoption="A" resolution="INPUT" advanced="N"*/
/*   required="N" enable="N" type="LSTFILE" autolaunch="N" filetype="LST" tabname="System Files">*/
/*   <target rootname="" extension="lst">*/
/*    <folder system="RELATIVE" source="RELATIVE" displayname="system_files" id="system_files" itemtype="Container" fileinfoversion="3.0">*/
/*    </folder>*/
/*   </target>*/
/*   <description>*/
/*   </description>*/
/*  </parameter>*/
/*  <parameter userdefined="S" obfuscate="N" id="&star;LOG&star;" canlinktobasepath="Y" protect="N" label="SAS log" systemtype="&star;LOG&star;" order="2" processid="P5" dependsaction="ENABLE" baseoption="A" resolution="INPUT" advanced="N" required="N"*/
/*   enable="N" type="LOGFILE" autolaunch="N" filetype="LOG" tabname="System Files">*/
/*   <target rootname="" extension="log">*/
/*    <folder system="RELATIVE" source="RELATIVE" displayname="system_files" id="system_files" itemtype="Container" fileinfoversion="3.0">*/
/*    </folder>*/
/*   </target>*/
/*   <description>*/
/*   </description>*/
/*  </parameter>*/
/*  <parameter userdefined="Y" obfuscate="N" id="DICT" canlinktobasepath="Y" expandfiletypes="N" protect="N" label="Data Dictionary Folder" order="3" processid="P5" dependsaction="ENABLE" baseoption="A" resolution="INPUT" advanced="N" required="N"*/
/*   readfiles="Y" enable="N" type="FOLDER" writefiles="N" tabname="Parameters">*/
/*   <fileset setType="1">*/
/*    <sourceContainer system="SDD" source="DOMAIN" displaypath="/lillyce/prd/dictionaries" displayname="current" id="/lillyce/prd/dictionaries/current" itemtype="Container" fileinfoversion="3.0">*/
/*    </sourceContainer>*/
/*    <fileInfoList>*/
/*     <file system="RELATIVE" source="RELATIVE" displayname="dict_meddra_smq.sas7bdat" id="dict_meddra_smq.sas7bdat" itemtype="Item" type="sas7bdat" fileinfoversion="3.0">*/
/*     </file>*/
/*    </fileInfoList>*/
/*    <filterList>*/
/*     <item name="ALL">*/
/*     </item>*/
/*    </filterList>*/
/*   </fileset>*/
/*   <description>*/
/*   </description>*/
/*  </parameter>*/
/*  <parameter id="VER" resolution="INTERNAL" type="TEXT" order="4">*/
/*  </parameter>*/
/*  <parameter tabname="Parameters" id="OUTPATH" expandfiletypes="N" obfuscate="N" label="Folder" required="N" order="5" baseoption="A" processid="P5" type="FOLDER" enable="N" canlinktobasepath="Y" readfiles="Y" protect="N" advanced="N"*/
/*   dependsaction="ENABLE" writefiles="Y" resolution="INPUT">*/
/*   <fileset setType="0">*/
/*    <sourceContainer system="SDD" source="DOMAIN" displaypath="/lillyce/qa/multi_compound/gps/general_safety/programs" displayname="tfl_output" id="/lillyce/qa/multi_compound/gps/general_safety/programs/tfl_output" itemtype="Container"*/
/*     fileinfoversion="3.0">*/
/*    </sourceContainer>*/
/*    <filterList>*/
/*     <item name="ALL">*/
/*     </item>*/
/*    </filterList>*/
/*   </fileset>*/
/*   <description>*/
/*   </description>*/
/*  </parameter>*/
/*  <parameter tabname="Parameters" id="MEDDRADICT" expandfiletypes="N" obfuscate="N" label="Folder" required="N" order="6" baseoption="A" processid="P5" type="FOLDER" enable="N" canlinktobasepath="Y" readfiles="Y" protect="N" advanced="N"*/
/*   dependsaction="ENABLE" writefiles="N" resolution="INPUT">*/
/*   <fileset setType="1">*/
/*    <sourceContainer system="SDD" source="DOMAIN" displaypath="/lillyce/prd/dictionaries" displayname="current" id="/lillyce/prd/dictionaries/current" itemtype="Container" fileinfoversion="3.0">*/
/*    </sourceContainer>*/
/*    <fileInfoList>*/
/*     <file system="RELATIVE" source="RELATIVE" displayname="dict_meddra.sas7bdat" id="dict_meddra.sas7bdat" itemtype="Item" type="sas7bdat" fileinfoversion="3.0">*/
/*     </file>*/
/*    </fileInfoList>*/
/*    <filterList>*/
/*     <item name="ALL">*/
/*     </item>*/
/*    </filterList>*/
/*   </fileset>*/
/*   <description>*/
/*   </description>*/
/*  </parameter>*/
/*  <parameter tabname="Parameters" id="MEDDRAPATH" expandfiletypes="N" obfuscate="N" label="Folder" required="N" order="7" baseoption="A" processid="P5" type="FOLDER" enable="N" canlinktobasepath="Y" readfiles="Y" protect="N" advanced="N"*/
/*   dependsaction="ENABLE" writefiles="Y" resolution="INPUT">*/
/*   <fileset setType="1">*/
/*    <sourceContainer system="SDD" source="DOMAIN" displaypath="/lillyce/qa/multi_compound/gps/general_safety/data/custom" displayname="ae_meddra" id="/lillyce/qa/multi_compound/gps/general_safety/data/custom/ae_meddra" itemtype="Container"*/
/*     fileinfoversion="3.0">*/
/*    </sourceContainer>*/
/*    <fileInfoList>*/
/*     <file system="RELATIVE" source="RELATIVE" displayname="dme.sas7bdat" id="dme.sas7bdat" itemtype="Item" type="sas7bdat" fileinfoversion="3.0">*/
/*     </file>*/
/*     <file system="RELATIVE" source="RELATIVE" displayname="mdhier_14_1.sas7bdat" id="mdhier_14_1.sas7bdat" itemtype="Item" type="sas7bdat" fileinfoversion="3.0">*/
/*     </file>*/
/*     <file system="RELATIVE" source="RELATIVE" displayname="mdhier_18_1.sas7bdat" id="mdhier_18_1.sas7bdat" itemtype="Item" type="sas7bdat" fileinfoversion="3.0">*/
/*     </file>*/
/*    </fileInfoList>*/
/*    <filterList>*/
/*     <item name="ALL">*/
/*     </item>*/
/*    </filterList>*/
/*   </fileset>*/
/*   <description>*/
/*   </description>*/
/*  </parameter>*/
/*  <parameter tabname="Parameters" id="BUMLIB" expandfiletypes="N" obfuscate="N" label="Folder" required="N" order="8" baseoption="A" processid="P5" type="FOLDER" enable="N" canlinktobasepath="Y" readfiles="Y" protect="N" advanced="N"*/
/*   dependsaction="ENABLE" writefiles="N" resolution="INPUT">*/
/*   <fileset setType="1">*/
/*    <sourceContainer system="SDD" source="DOMAIN" displaypath="/lillyce/prd/general/bums" displayname="macro_library" id="/lillyce/prd/general/bums/macro_library" itemtype="Container" fileinfoversion="3.0">*/
/*    </sourceContainer>*/
/*    <fileInfoList>*/
/*     <file system="RELATIVE" source="RELATIVE" displayname="ut_saslogcheck.sas" id="ut_saslogcheck.sas" itemtype="Item" type="sas" version="3" fileinfoversion="3.0">*/
/*     </file>*/
/*    </fileInfoList>*/
/*    <filterList>*/
/*     <item name="ALL">*/
/*     </item>*/
/*    </filterList>*/
/*   </fileset>*/
/*   <description>*/
/*   </description>*/
/*  </parameter>*/
/*  <parameter tabname="Parameters" id="UTILPATH" expandfiletypes="N" obfuscate="N" label="Folder" required="N" order="9" baseoption="A" processid="P5" type="FOLDER" enable="N" canlinktobasepath="Y" readfiles="Y" protect="N" advanced="N"*/
/*   dependsaction="ENABLE" writefiles="N" resolution="INPUT">*/
/*   <fileset setType="0">*/
/*    <sourceContainer system="SDD" source="DOMAIN" displaypath="/lillyce/qa/multi_compound/gps/general_safety/programs" displayname="author_component_modules" id="/lillyce/qa/multi_compound/gps/general_safety/programs/author_component_modules"*/
/*     itemtype="Container" fileinfoversion="3.0">*/
/*    </sourceContainer>*/
/*    <filterList>*/
/*     <item name="ALL">*/
/*     </item>*/
/*    </filterList>*/
/*   </fileset>*/
/*   <description>*/
/*   </description>*/
/*  </parameter>*/
/*  <parameter tabname="Parameters" id="STUDYPATH" expandfiletypes="N" obfuscate="N" label="Folder" required="N" order="10" baseoption="A" processid="P5" type="FOLDER" enable="N" canlinktobasepath="Y" readfiles="Y" protect="N" advanced="N"*/
/*   dependsaction="ENABLE" writefiles="N" resolution="INPUT">*/
/*   <fileset setType="1">*/
/*    <sourceContainer system="SDD" source="DOMAIN" displaypath="/lillyce/qa/multi_compound/gps/general_safety/data/custom" displayname="sdtm_ff" id="/lillyce/qa/multi_compound/gps/general_safety/data/custom/sdtm_ff" itemtype="Container"*/
/*     fileinfoversion="3.0">*/
/*    </sourceContainer>*/
/*    <fileInfoList>*/
/*     <file system="RELATIVE" source="RELATIVE" displayname="ae.sas7bdat" id="ae.sas7bdat" itemtype="Item" type="sas7bdat" fileinfoversion="3.0">*/
/*     </file>*/
/*     <file system="RELATIVE" source="RELATIVE" displayname="dm.sas7bdat" id="dm.sas7bdat" itemtype="Item" type="sas7bdat" fileinfoversion="3.0">*/
/*     </file>*/
/*     <file system="RELATIVE" source="RELATIVE" displayname="ex.sas7bdat" id="ex.sas7bdat" itemtype="Item" type="sas7bdat" fileinfoversion="3.0">*/
/*     </file>*/
/*    </fileInfoList>*/
/*    <filterList>*/
/*     <item name="ALL">*/
/*     </item>*/
/*    </filterList>*/
/*   </fileset>*/
/*   <description>*/
/*   </description>*/
/*  </parameter>*/
/*  <parameter id="RUN_LOCATION" resolution="INTERNAL" type="TEXT" order="11">*/
/*  </parameter>*/
/*  <parameter id="PANEL_TITLE" resolution="INTERNAL" type="TEXT" order="12">*/
/*  </parameter>*/
/*  <parameter id="PANEL_DESC" resolution="INTERNAL" type="TEXT" order="13">*/
/*  </parameter>*/
/*  <parameter id="SASPATH" resolution="INTERNAL" type="TEXT" order="14">*/
/*  </parameter>*/
/*  <parameter id="AEMEDOUT" resolution="INTERNAL" type="TEXT" order="15">*/
/*  </parameter>*/
/*  <parameter id="ERROUT" resolution="INTERNAL" type="TEXT" order="16">*/
/*  </parameter>*/
/*  <parameter id="NDABLA" resolution="INTERNAL" type="TEXT" order="17">*/
/*  </parameter>*/
/*  <parameter id="STUDYID" resolution="INTERNAL" type="TEXT" order="18">*/
/*  </parameter>*/
/*  <parameter id="MEDDRA" resolution="INTERNAL" type="TEXT" order="19">*/
/*  </parameter>*/
/*  <parameter id="MEDDRA_PCT" resolution="INTERNAL" type="TEXT" order="20">*/
/*  </parameter>*/
/*  <parameter id="STUDY_LAG" resolution="INTERNAL" type="TEXT" order="21">*/
/*  </parameter>*/
/*  <parameter id="CC" resolution="INTERNAL" type="TEXT" order="22">*/
/*  </parameter>*/
/*  <parameter id="VLD_SW" resolution="INTERNAL" type="TEXT" order="23">*/
/*  </parameter>*/
/*  <parameter id="RD_TH" resolution="INTERNAL" type="TEXT" order="24">*/
/*  </parameter>*/
/*  <parameter id="RR_TH" resolution="INTERNAL" type="TEXT" order="25">*/
/*  </parameter>*/
/*  <parameter id="PV_TH" resolution="INTERNAL" type="TEXT" order="26">*/
/*  </parameter>*/
/*  <parameter id="DSIN" resolution="INTERNAL" type="TEXT" order="27">*/
/*  </parameter>*/
/*  <parameter id="DSOUT" resolution="INTERNAL" type="TEXT" order="28">*/
/*  </parameter>*/
/*  <parameter id="BY1" resolution="INTERNAL" type="TEXT" order="29">*/
/*  </parameter>*/
/*  <parameter id="BY2" resolution="INTERNAL" type="TEXT" order="30">*/
/*  </parameter>*/
/*  <parameter id="BY3" resolution="INTERNAL" type="TEXT" order="31">*/
/*  </parameter>*/
/*  <parameter id="BY4" resolution="INTERNAL" type="TEXT" order="32">*/
/*  </parameter>*/
/*  <parameter id="OUTPUT" resolution="INTERNAL" type="TEXT" order="33">*/
/*  </parameter>*/
/*  <parameter id="I" resolution="INTERNAL" type="TEXT" order="34">*/
/*  </parameter>*/
/*  <parameter id="BY" resolution="INTERNAL" type="TEXT" order="35">*/
/*  </parameter>*/
/*  <parameter id="MAX_ARG" resolution="INTERNAL" type="TEXT" order="36">*/
/*  </parameter>*/
/*  <parameter id="KEY" resolution="INTERNAL" type="TEXT" order="37">*/
/*  </parameter>*/
/*  <parameter id="ARM_COUNT" resolution="INTERNAL" type="TEXT" order="38">*/
/*  </parameter>*/
/*  <parameter id="ARM_" resolution="INTERNAL" type="TEXT" order="39">*/
/*  </parameter>*/
/*  <parameter id="ARM_NAME_" resolution="INTERNAL" type="TEXT" order="40">*/
/*  </parameter>*/
/*  <parameter id="J" resolution="INTERNAL" type="TEXT" order="41">*/
/*  </parameter>*/
/*  <parameter id="CC_SW" resolution="INTERNAL" type="TEXT" order="42">*/
/*  </parameter>*/
/*  <parameter id="DS" resolution="INTERNAL" type="TEXT" order="43">*/
/*  </parameter>*/
/*  <parameter id="SETUP_SUCCESS" resolution="INTERNAL" type="TEXT" order="44">*/
/*  </parameter>*/
/*  <parameter id="DM_SUBJ_GT0" resolution="INTERNAL" type="TEXT" order="45">*/
/*  </parameter>*/
/*  <parameter id="SETUP_REQ_VAR" resolution="INTERNAL" type="TEXT" order="46">*/
/*  </parameter>*/
/*  <parameter id="START" resolution="INTERNAL" type="TEXT" order="47">*/
/*  </parameter>*/
/*  <parameter id="END" resolution="INTERNAL" type="TEXT" order="48">*/
/*  </parameter>*/
/*  <parameter id="DIFF" resolution="INTERNAL" type="TEXT" order="49">*/
/*  </parameter>*/
/* </parameters>*/
/*</process>*/
/**/
/******PACMAN******************************************PACMAN******/