/****************************************************************************/
/*         PROGRAM NAME: Adverse Events Relative Risk/Odds Ratio Analysis   */
/*                                                                          */
/*          DESCRIPTION: Find top adverse events by relative risk &         */
/*                        odds ratio between each pair of arms              */
/*                                                                          */
/*      EVALUATION TYPE: Safety                                             */
/*                                                                          */
/*               AUTHOR: David Kretch (david.kretch@us.ibm.com)	            */
/*                       Andreas Anastassopoulos                            */
/*                          (andreas.anastassapoulos@us.ibm.com)            */
/*                                                                          */
/*                 DATE: February 7, 2011                                   */
/*                                                                          */
/*  EXTERNAL FILES USED: ae.sas -- AE panel which includes this file        */
/*                                                                          */
/*  PARAMETERS REQUIRED: cc -- continuity correction value                  */
/*                       aeout2 -- filename of OR output                    */
/*                       aeout3 -- filename of RR output                    */
/*                                                                          */
/*   VARIABLES REQUIRED: N/A -- See AE                                      */
/*                                                                          */
/*            MADE WITH: SAS 9.2                                            */
/*                                                                          */
/*                NOTES:                                                    */
/*                                                                          */
/****************************************************************************/

/* REVISIONS */
/*
2011-02-26  DK  OR and RR by AEBODSYS and AEDECOD
                Include AEBODSYS MedDRA SOC abbreviation

2011-05-31  DK  Modified the creation of rror_count/freq to deal with
                 the case that an arm has no AEs by reversing the order
                Made loops whose upper bound was num_aedecod check the number of 
                 observations in the rr/or datasets and use the minimum	of the two
*/

options nosource;
%put ******************************************************;
%put * ADVERSE EVENTS RELATIVE RISK / ODDS RATIO ANALYSIS *;
%put ******************************************************;
options source;


/* number of top adverse events to include */
%let num_aedecod = 30;

/* SOC abbreviations for AEBODSYS */
/* made using this code: */
* proc sql;
*	select distinct upcase(soc_name), soc_abbrev from meddra.mdhier_x_y;
* quit;
data soc_abbrev;
	infile datalines dsd delimiter=',';
	length soc_name $200 soc_abbrev $10;
	input soc_name $ soc_abbrev $;
	datalines;
BLOOD AND LYMPHATIC SYSTEM DISORDERS,Blood
CARDIAC DISORDERS,Card
"CONGENITAL, FAMILIAL AND GENETIC DISORDERS",Cong
EAR AND LABYRINTH DISORDERS,Ear
ENDOCRINE DISORDERS,Endo
EYE DISORDERS,Eye
GASTROINTESTINAL DISORDERS,Gastr
GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS,Genrl
HEPATOBILIARY DISORDERS,Hepat
IMMUNE SYSTEM DISORDERS,Immun
INFECTIONS AND INFESTATIONS,Infec
"INJURY, POISONING AND PROCEDURAL COMPLICATIONS",Inj&P
INVESTIGATIONS,Inv
METABOLISM AND NUTRITION DISORDERS,Metab
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS,Musc
"NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED (INCL CYSTS AND POLYPS)",Neopl
NERVOUS SYSTEM DISORDERS,Nerv
"PREGNANCY, PUERPERIUM AND PERINATAL CONDITIONS",Preg
PSYCHIATRIC DISORDERS,Psych
RENAL AND URINARY DISORDERS,Renal
REPRODUCTIVE SYSTEM AND BREAST DISORDERS,Repro
"RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS",Resp
SKIN AND SUBCUTANEOUS TISSUE DISORDERS,Skin
SOCIAL CIRCUMSTANCES,SocCi
SURGICAL AND MEDICAL PROCEDURES,Surg
VASCULAR DISORDERS,Vasc
;
run;


/* find odds ratio and relative risk for each pair of arms in the study */
%macro rror;

	/* get subject counts of each adverse event (AEDECOD) */
	/* assign numbers to each AEBODSYS/AEDECOD combination */
	data ds_base_bysubjpt_rror ds_base_term(keep=aebodsys aedecod aebodsys_abbrev term_num);
		set ds_base_bysubjpt end=eof;
		by aebodsys aedecod;

		soc_name = upcase(aebodsys);

		/* look up the abbreviation for the body system */
		if _n_ = 1 then do;
			declare hash h(dataset:'soc_abbrev');
			h.definekey('soc_name');
			h.definedata('soc_abbrev');
			h.definedone();
		end;

		length soc_abbrev $10;
		call missing(soc_abbrev);
		rc = h.find();
		drop rc soc_name;
		rename soc_abbrev=aebodsys_abbrev;

		if first.aedecod then do;
			term_num + 1;
			output ds_base_term;
		end;
		output ds_base_bysubjpt_rror;
	run;

	proc sql noprint;
		create table rror_count(drop=null) as
		select term_num, 
               %do i = 1 %to &arm_count.; sum(case when arm_num = &i. then 1 else 0 end) as cd&i., %end;
		       0 as null
		from ds_base_bysubjpt_rror
		group by term_num;
	quit;

	proc transpose data=rror_count out=rror_freq(rename=(col1=count));
		by term_num;
	run;

	data rror_freq;
		set rror_freq;
		arm_num = input(compress(_name_,,'dk'),best.);
		drop _name_;
	run;

	data rror_count;
		set rror_count;
		%do i = 1 %to &arm_count.;
			prob&i. = cd&i./&&&arm_&i.;
		%end;

		array n_arm{&arm_count.} $100 n_arm1-n_arm&arm_count. (%do i = 1 %to &arm_count.; "&&&arm_name_&i." %end;);
	run;

	/* set up contingency table for each adverse event */
	/* by adding counts of subjects with no adverse events */
	data rror_ct;
		set rror_freq;

		select (arm_num);
			%do i = 1 %to &arm_count.;
				when (&i.) arm_count = &&&arm_&i.;
			%end;
			otherwise;
		end;

		disease = -1; 
		output;
		disease = 0; 
		count = arm_count - count;
		output;

		drop arm_count;
	run;

	%do i = 1 %to &arm_count.;
		%do j = 1 %to &arm_count.;
			%if &i. ne &j. %then %do;
	
			/* make 2x2 contingency table for each pair of arms in the study */
			/* continuity correction */
			/* determine which terms have a zero cell count */
			/* only then apply a continuity correction */
			proc sql noprint;
				create table rror_ct_&i.&j. as
				select a.term_num, 
                       arm_num, 
                       (case when arm_num = &i. then 1 when arm_num = &j. then 2 else . end) as arm_num_ord, 
                       disease, 
                       cc_ind,
					   %if &cc_sw. = 1 %then %do;
				          (case 
				              when cc_ind = 1 then (count + &cc.) 
				              else count 
				           end) as count
					   %end;
					   %else %if &cc_sw. = 2 %then %do;
			              (case 
			                  when cc_ind = 1 and arm_num = &i. then (count + 1/&&&arm_&j.) 
			                  when cc_ind = 1 and arm_num = &j. then (count + 1/&&&arm_&i.)
			                  else count 
			               end)	as count
					   %end;
					   %else %do;
					      count
					   %end;
				from (select *
                      from rror_ct
                      where arm_num in (&i.,&j.)) a
				left join (select distinct term_num, 1 as cc_ind
				           from rror_ct
						   where arm_num in (&i.,&j.)
						   and count = 0) b
				on a.term_num = b.term_num
				order by term_num, arm_num_ord, disease;
			quit;

			/* make a continuity correction indicator dataset for each AEBODSYS/AEDECOD */
			proc sql noprint;
				create table rror_cc_ind_&i.&j. as
				select distinct term_num, cc_ind
				from rror_ct_&i.&j.;
			quit;

			/* suppress printing notes about risk estimates not being computed due to zero cell counts */
			options nonotes;

			/* find relative risk and odds ratio */
			/* and their confidence limits */
			proc freq data=rror_ct_&i.&j. noprint;
				table arm_num_ord*disease / relrisk nowarn; 
				weight count;
				by term_num;
				exact or;
				output out=rror_stat_&i.&j. relrisk;
			run;

			options notes;

			/* separate odds ratio and relative risk statistics */
			data rror_stat_or_&i.&j.(keep=term_num or&i.&j. elcl&i.&j. eucl&i.&j.);
				set rror_stat_&i.&j.(keep=term_num _rror_ l_rror u_rror xl_rror xu_rror);

				/* look up whether continuity correction was used */
				if _n_ = 1 then do;
					declare hash h(dataset:"rror_cc_ind_&i.&j.");
					h.definekey('term_num');
					h.definedata('cc_ind');
					h.definedone();
				end;

				call missing(cc_ind);
				rc = h.find();
				drop rc;

				rename _rror_=or&i.&j.;

				/* if you are not using continuity correction */
				/* or you are using continuity correction with a whole number c.c. */
				/* or you are using non-whole-number continuity correction and the AE did not require c.c. */
				/* then use exact CI for odds ratio */
				if not &cc_sw. 
				or (&cc_sw. and &cc_whole.) 
				or (&cc_sw. and not &cc_whole. and not cc_ind) then do;
					elcl&i.&j.=xl_rror;
					eucl&i.&j.=xu_rror;
				end;
				else do;
					elcl&i.&j.=l_rror;
					eucl&i.&j.=u_rror;
				end;

				label elcl&i.&j.='Lower CL, Odds Ratio'
				      eucl&i.&j.='Upper CL, Odds Ratio';
			run;

			data rror_stat_rr_&i.&j.(keep=term_num rr&i.&j. elcl&i.&j. eucl&i.&j.);
				set rror_stat_&i.&j.(keep=term_num _rrc1_ l_rrc1 u_rrc1);

				rename _rrc1_=rr&i.&j.
				              l_rrc1=elcl&i.&j.
							  u_rrc1=eucl&i.&j.
							  ;
			run;

			%end;
		%end;
	%end; 

	/* combine odds ratios and relative risks from all pairs of arms into single datasets */
	data or;
		merge ds_base_term
              rror_count
		      %do i = 1 %to &arm_count.;
			  	%do j = 1 %to &arm_count.;
				  %if &i. ne &j. %then %do;
                     rror_stat_or_&i.&j.
				  %end;
				%end;
			  %end;
			  ;
		by term_num;
	run;

	data rr;
		merge ds_base_term
              rror_count(in=a)
		      %do i = 1 %to &arm_count.;
			  	%do j = 1 %to &arm_count.;
				  %if &i. ne &j. %then %do;
                     rror_stat_rr_&i.&j.
				  %end;
				%end;
			  %end;
			  ;
		by term_num;
	run; 

	/* find count of OR and RR terms */
	data test; 
		dsid = open('rr');
		if dsid then nobs = attrn(dsid,'nobs');
		else nobs = 0;
		rc = close(dsid);
		call symputx('rr_nobs',nobs,'g');

		dsid = open('or');
		if dsid then nobs = attrn(dsid,'nobs');
		else nobs = 0;
		rc = close(dsid); 
		call symputx('or_nobs',nobs,'g');
	run;

	proc datasets library=work nolist nodetails;
		modify or;
		attrib _all_ label='';
	quit;

	proc datasets library=work nolist nodetails;
		modify rr;
		attrib _all_ label='';
	quit;

	/*proc datasets library=work nolist nodetails;
		delete rror:;
	quit;  */

%mend rror;

%rror;


** NOW PULL THE CORRECT VARIABLES FOR EACH COMPARRISON AND EXPORT THEM ***;


%macro outs;
	%do  i = 1 %to &arm_count.;
		%do  j = 1 %to &arm_count.;
			%if &i ne &j %then %do;

				* SORT TO GET THE TOP  **;

				proc sort data = rr;
				  by decending rr&i.&j.;
				run;

				proc sort data = or;
				  by decending or&i.&j.;
				run;

				%put ARMS &i. & &j.;

				/* top 30 terms by relative risk for arms i & j */
				%do A = 1 %to %sysfunc(min(&num_aedecod.,&rr_nobs.));

					%if &a. = 1 %then %do;
						%put;
						%put RELATIVE RISK;
					%end;

					data _null_;
						set rr(firstobs=&a. obs=&a);

						call symputx('rr_aecd',aedecod);
						call symputx('rr_term_num',term_num);
					run;

					/* find whether this term had continuity correction */
					/* and if so, add an asterisk */
					proc sql noprint;
						select (case 
                                   when cc_ind = 1 then trim("&rr_aecd.")||'*' 
                                   else "&rr_aecd."||' ' 
                                end) into: rr_aecd
						from rror_cc_ind_&i.&j.
						where term_num = &rr_term_num.;
					quit;

					** NOW I NEED TO CREATE A VERTICAL RECORD FOR EACH AEDECOD ***;
					data vert_rr&A. (keep= var sort_order aedecod&A.);
						set rr(firstobs=&a. obs=&a);
						format var 2. sort_order $250.; 

						*if _N_ = &A.;

						label aedecod&A. = "&rr_aecd";

						var = 1;
						sort_order = '01 Mean';
						aedecod&A. = rr&i.&j.;
						output;

						var = 2;
						sort_order = '02 Median';
						aedecod&A. = rr&i.&j.;
						output;

						var = 3;
						sort_order = '03 Q1';
						aedecod&A. = rr&i.&j.;
						output;

						var = 4;
						sort_order = '04 Q3';
						aedecod&A. = rr&i.&j.;
						output;

						var = 5;
						sort_order = '05 Min';
						aedecod&A. = elcl&i.&j.;
						output;

						var = 6;
						sort_order = '06 Max';
						aedecod&A. = eucl&i.&j.;
						output;

						var = 7;
						sort_order = '07 25th';
						aedecod&A. = rr&i.&j.;
						output;

						var = 8;
						sort_order = '08 50th';
						aedecod&A. = 0;
						output;

						var = 9;
						sort_order = '09 75th';
						aedecod&A. = 0;
						output;

						var = 10;
						sort_order = '10 Min';
						aedecod&A. = sum(rr&i.&j.,-elcl&i.&j.);
						output;

						var = 11;
						sort_order = '11 Max';
						aedecod&A. = sum(eucl&i.&j.,-rr&i.&j.);
						output;

						var = 12;
						sort_order = '12 Offset';
						aedecod&A. = .975 - (&A.-1)*.95/(&num_aedecod.-1);
						output;

						var = 13;
						sort_order = '13 Line';
						aedecod&A. = 1;
						output;

						var = 14;
						sort_order = n_arm&i.;
						aedecod&A. = 1;
						output;

						var = 15;
						sort_order = '15 Count1';
						aedecod&A. = cd&i.;
						output;

						var = 16;
						sort_order = '16 Prob1';
						aedecod&A. = 100*prob&i.;
						output;

						var = 17;
						sort_order = n_arm&j.;
						aedecod&A. = 1;
						output;

						var = 18;
						sort_order = '18 Count2';
						aedecod&A. = cd&j.;
						output;

						var = 19;
						sort_order = '19 Prob2';
						aedecod&A. = 100*prob&j.;
						output;

						var = 20;
						sort_order = 'Favors '||trim(n_arm&i.);
						aedecod&A. = .;
						output;

						var = 21;
						sort_order = 'Favors '||trim(n_arm&j.);
						aedecod&A. = .;
						output;

					run;

					/* create a dataset with each AE's body system abbreviation */
					data abbrev_rr&a.(keep= var sort_order aedecod&a.);
						set rr(firstobs=&a. obs=&a);

						var = 22;
						sort_order = 'Body System Abbrev.';
						aedecod&A. = aebodsys_abbrev;
					run;

				%end;
				
				/* top 30 terms by odds ratio for arms i & j */
				%do A = 1 %to %sysfunc(min(&num_aedecod.,&or_nobs.));

					%if &a. = 1 %then %do;
						%put;
						%put ODDS RATIO;
					%end;

					data _null_;
						set or(firstobs=&a. obs=&a);

						call symputx('or_aecd',aedecod);
						call symputx('or_term_num',term_num);
					run;

					/* find whether this term had continuity correction */
					/* and if so, add an asterisk */
					proc sql noprint;
						select (case 
                                   when cc_ind = 1 then trim("&or_aecd.")||'*' 
                                   else "&or_aecd."||' ' 
                                end) into: or_aecd
						from rror_cc_ind_&i.&j.
						where term_num = &or_term_num.;
					quit;

					data vert_or&A.(keep=var sort_order aedecod&A.);
						set or(firstobs=&a. obs=&a);
						format var 2. sort_order $250.;

						label aedecod&A. = "&or_aecd.";

						var = 1;
						sort_order = '01 Mean';
						aedecod&A. = or&i.&j.;
						output;

						var = 2;
						sort_order = '02 Median';
						aedecod&A. = or&i.&j.;
						output;

						var = 3;
						sort_order = '03 Q1';
						aedecod&A. = or&i.&j.;
						output;

						var = 4;
						sort_order = '04 Q3';
						aedecod&A. = or&i.&j.;
						output;

						var = 5;
						sort_order = '05 Min';
						aedecod&A. = elcl&i.&j.;
						output;

						var = 6;
						sort_order = '06 Max';
						aedecod&A. = eucl&i.&j.;
						output;

						var = 7;
						sort_order = '07 25th';
						aedecod&A. = or&i.&j.;
						output;

						var = 8;
						sort_order = '08 50th';
						aedecod&A. = 0;
						output;

						var = 9;
						sort_order = '09 75th';
						aedecod&A. = 0;
						output;

						var = 10;
						sort_order = '10 Min';
						aedecod&A. = sum(or&i.&j.,-elcl&i.&j.);
						output;

						var = 11;
						sort_order = '11 Max';
						aedecod&A. = sum(eucl&i.&j.,-or&i.&j.);
						output;

						var = 12;
						sort_order = '12 Offset';
						aedecod&A. = .975 - (&A.-1)*.95/(&num_aedecod.-1);
						output;

						var = 13;
						sort_order = '13 Line';
						aedecod&A. = 1;
						output;

						var = 14;
						sort_order = n_arm&i.;
						aedecod&A. = 1;
						output;

						var = 15;
						sort_order = '15 Count1';
						aedecod&A. = cd&i.;
						output;

						var = 16;
						sort_order = '16 Prob1';
						aedecod&A. = 100*prob&i.;
						output;

						var = 17;
						sort_order = n_arm&j.;
						aedecod&A. = 1;
						output;

						var = 18;
						sort_order = '18 Count2';
						aedecod&A. = cd&j.;
						output;

						var = 19;
						sort_order = '19 Prob2';
						aedecod&A. = 100*prob&j.;
						output;

						var = 20;
						sort_order = 'Favors '||trim(n_arm&i.);
						aedecod&A. = .;
						output;

						var = 21;
						sort_order = 'Favors '||trim(n_arm&j.);
						aedecod&A. = .;
						output;

					run;

					/* create a dataset with each AE's body system abbreviation */
					data abbrev_or&a.(keep=var sort_order aedecod&a.);
						set or(firstobs=&a. obs=&a);

						var = 22;
						sort_order = 'Body System Abbrev.';
						aedecod&A. = aebodsys_abbrev;
					run;

				%end; 

				options notes;

				/* merge together the separate vertical records*/
				data rr_&i.&j._out;
					merge %do r = 1 %to %sysfunc(min(&num_aedecod.,&rr_nobs.));
						     vert_rr&r.
						  %end;
					      ;
					by var;
				run;

				data rr_&i.&j._abbrev_out;
					merge %do r = 1 %to %sysfunc(min(&num_aedecod.,&rr_nobs.));
						     abbrev_rr&r.
						  %end;
					      ;
					by var;
				run;


				data or_&i.&j._out;
					merge %do r = 1 %to %sysfunc(min(&num_aedecod.,&or_nobs.));
						     vert_or&r.
						  %end;
					      ;
					by var;
				run;

				data or_&i.&j._abbrev_out;
					merge %do r = 1 %to %sysfunc(min(&num_aedecod.,&or_nobs.));
						     abbrev_or&r.
						  %end;
					      ;
					by var;
				run;

				/* clean up */
				proc datasets library=work nolist nodetails;
					delete vert: abbrev:;
				quit;

			%end;
		%end; 
	%end;

%mend outs;

%outs;


/* make dataset storing information to be displayed in various places throughout the output */
data lib;
	length path $500;
	path = "&ndabla.";
	output;

	path = "&studyid.";
	output;

	path = "&rundate.";
	output;

	if &vld_sw. then 
		path = "Subject first exposure date to last exposure date"||ifc(&study_lag.>0," + &study_lag. days",'');
	else 
		path = 'Necessary date variables were not available; all adverse events used in analysis';
	output;	

	if &cc_sw. = 0 then path = 'No continuity correction';
	else if &cc_sw. = 1 then path = "&cc.";
	else if &cc_sw. = 2 then path = 'The reciprocal of the opposite arm subject count';
	else path = '';
	output;

	if &cc_sw. ne 0 then path = '* For the indicated adverse event, STATISTIC has been calculated '||
		                        'after adjusting subject counts with a continuity correction of '||
								ifc(&cc_sw. = 1,"&cc. ",'the reciprocal of the opposite arm subject count ')||
                                'to avoid dividing by zero. See the front page for more detail';
	else path = '';
	output;

	if &cc_sw. ne 0 then path = 'For terms where either arm had a zero cell count, a continuity correction '||
                                'of '||ifc(&cc_sw.=1,"&cc. ",'the reciprocal of the opposite arm subject count ')||
                                'has been added to the quantities in each cell of the contingency table before '||
                                'calculating STATISTIC. This avoids undefined values that would result when '||
                                'dividing by zero. Use caution with these results, since different continuity '||
                                'corrections yield different results and a notable STATISTIC statistic may only '||
                                'be an artifact of the correction used.';
	else path = '';
	output;

	path = "&arm_count.";
	output;	

	path = "&sl_custom_ds.";
	output;

	path = trim(left("&study_lag."));
	output;

	path = ifc(&dm_actarm.,'actual treatment arm (ACTARM)','planned treatment arm (ARM)');
	output;
run; 

data lib_or;
	set lib end=eof;
	if index(path,'STATISTIC') then path = tranwrd(path,'STATISTIC','odds ratio');
run;

data lib_rr;
	set lib end=eof;
	if index(path,'STATISTIC') then path = tranwrd(path,'STATISTIC','relative risk');
run; 

proc sql noprint;
	create table lib_arm as
	select arm_num, arm_display
	from all_arm;
quit;


/* output to templates */
%macro out_ae_rror;

	%put *****************************************************;
	%put * CREATE AE ODDS RATIO / RELATIVE RISK EXCEL OUTPUT *;
	%put *****************************************************;

	%if not %symexist(run_location) %then %let run_location = LOCAL;

	/* odds ratio output */
	%put Odds Ratio Output;

	/* local runs use the Microsoft Jet database-based Excel LIBNAME engine */
	%if %upcase(&run_location.) = LOCAL %then %do;
		*libname xls_or excel "&aeout2."; *Output function changed due to SAS 9.3(64bit) and Excel 2010(32bit) incompatability;
		libname xls_or pcfiles path="&aeout2."; 
	%end;
	/* Script Launcher runs use the PCFILES LIBNAME Engine */
	%else %do;
		libname xls_or pcfiles path="&aeout2.";
	%end;

	/* output each top 30 OR dataset to their respective worksheets */
	%do i = 1 %to &arm_count.;
		%do j = 1 %to &arm_count.;
			%if &i. ne &j. %then %do;
				proc sql noprint; drop table xls_or.data&i.&j., xls_or.abbrev&i.&j.; quit;

				data xls_or.data&i.&j.(dblabel=yes);
					set or_&i.&j._out;
				run;

				data xls_or.abbrev&i.&j.;
					set or_&i.&j._abbrev_out;
				run;
			%end;
		%end;
	%end;

	/* output the study and arm info */
	proc sql noprint; 
		drop table xls_or.arminfo,
                   xls_or.info; 
	quit;

	data xls_or.info; set lib_or; run;

	data xls_or.arminfo; set lib_arm; run;

	/* relative risk output */
	%put Relative Risk Output;

	/* local runs use the Microsoft Jet database-based Excel LIBNAME engine */
	%if %upcase(&run_location.) = LOCAL %then %do;
		*libname xls_rr excel "&aeout3."; *Output function changed due to SAS 9.3(64bit) and Excel 2010(32bit) incompatability;
		libname xls_rr pcfiles path="&aeout3.";
	%end;
	/* Script Launcher runs use the PCFILES LIBNAME Engine */
	%else %do;
		libname xls_rr pcfiles path="&aeout3.";
	%end;

	/* output each top 30 RR dataset to their respective worksheets */
	/* in the Excel RR template */
	%do i = 1 %to &arm_count.;
		%do j = 1 %to &arm_count.;
			%if &i. ne &j. %then %do;
				proc sql noprint; drop table xls_rr.data&i.&j., xls_rr.abbrev&i.&j.; quit;

				data xls_rr.data&i.&j.(dblabel=yes);
					set rr_&i.&j._out;
				run;

				data xls_rr.abbrev&i.&j.;
					set rr_&i.&j._abbrev_out;
				run;
			%end;
		%end;
	%end;

	proc sql noprint; 
		drop table xls_rr.arminfo,
                   xls_rr.info; 
	quit;

	data xls_rr.info; set lib_rr; run;

	data xls_rr.arminfo; set lib_arm; run;

	%put OR/RR Output Finished;

	libname xls_or clear;
	libname xls_rr clear;

	/* output subsetting and grouping info */
	%group_subset_xls_out(gs_file=&aeout2.);
	%group_subset_xls_out(gs_file=&aeout3.);

%mend out_ae_rror;

%out_ae_rror;
