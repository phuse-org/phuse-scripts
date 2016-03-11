/**** 	11/18/2015 
		Modified by Peter Glass
		Added code to lines 221-237. Data check contained counts 
		of highest severity if no ae records were missing AESEV. ****/

/*******************************************************/
/* ANALYSIS A AND B: ADVERSE EVENTS PER PREFERRED TERM */
/*******************************************************/
%macro ab(aeser=no); 

	/* if AESER is used, do analysis B, otherwise do analysis A */
	%if (%upcase(%substr(&aeser.,1,1)) = Y or %upcase(%substr(&aeser.,1,1)) = T) %then %let analysis = b;
	%else %let analysis = a;

	/* find sums and percentages per arm for each SOC and term */
	data ab_&analysis.;
		set ds_base_bysubjpt end=eof;
		by aebodsys aedecod;

		%if &analysis = b %then %do;
			where aeser = 'Y';
		%end;

		retain arm_sum_1 - arm_sum_&arm_count.; 
		array arm_sum{*} arm_sum_1 - arm_sum_&arm_count. arm_sum_total;
		array arm_pct{*} arm_pct_1 - arm_pct_&arm_count. arm_pct_total;
		array arm_subjcnt{*} arm_subjcnt_1 - arm_subjcnt_&arm_count. arm_subjcnt_total 
                             (%do i = 1 %to &arm_count.; &&&arm_&i.. %end; &arm_total.);
		
		if first.aedecod then do i = 1 to &arm_count.;
			arm_sum(i) = 0;
		end;

		arm_sum(arm_num) = sum(arm_sum(arm_num),1);

		if last.aedecod then do;
			arm_sum_total = sum(of arm_sum_1-arm_sum_&arm_count.);
			do i = 1 to %eval(&arm_count. + 1);
				arm_pct(i) = 100 * arm_sum(i) / arm_subjcnt(i);
			end;
			output ab_&analysis.;
		end;

		label %do i = 1 %to &arm_count.;
				arm_sum_&i.= "&&&arm_name_&i.. Subject Count"
				arm_pct_&i.= "&&&arm_name_&i.. %"
		      %end;
			  arm_sum_total = 'Total Subject Count'
              arm_pct_total = 'Total %';

		keep aebodsys aedecod
             arm_sum_1 - arm_sum_&arm_count. arm_sum_total
			 arm_pct_1 - arm_pct_&arm_count. arm_pct_total;
	run;

	/* create output dataset with columns in the correct order */
	/* and text fields in proper noun case */
	data ab_&analysis._output;
		retain aebodsys aedecod 
               %do i = 1 %to &arm_count.; arm_sum_&i. arm_pct_&i. %end;
			   arm_sum_total arm_pct_total;
		set ab_&analysis.;
		%if &analysis. = a %then %do;
			where not (%do i = 1 %to &arm_count.; arm_pct_&i. <= 2 and %end; 1=1);
		%end;
	run;

	proc sort data=ab_&analysis._output;
		by aebodsys descending arm_pct_total;
	run;

%mend ab;

/*******************************************************/
/* ANALYSIS C AND D: ADVERSE EVENTS PER SEVERITY LEVEL */
/*******************************************************/
%macro cd(aeser=no);

	/* if AESER is used, do analysis D, otherwise do analysis C */
	%if (%upcase(%substr(&aeser.,1,1)) = Y or %upcase(%substr(&aeser.,1,1)) = T) %then %let analysis = d;
	%else %let analysis = c;

	/* create list of severity levels present in the data */
	%if %sysfunc(exist(all_sev)) = 0 %then %do;

		/* get severity variable and severity level count */
		proc sql noprint;
			create table all_sev as
			select aesev, count(1) as count
			from ds_base
			group by aesev;

			%global max_aesev_nm_len;
			select max(length(aesev)) into: max_aesev_nm_len
			from all_sev;
		quit;

		data all_sev;
			set all_sev end=eof;
			retain count;
			length aesev_display $30;
			
			count = sum(count,1); 

			aesev_display = propcase(aesev);

			select (upcase(aesev));
				when ('MILD') order = 1;
				when ('MODERATE') order = 2;
				when ('SEVERE') order = 3;
				when ('LIFE THREATENING') order = 4;
				when ('FATAL') order = 5;
				when ('MISSING') order = 100;
				when ('') do; order = 100; aesev_display = propcase('MISSING'); end;
				otherwise do;
					order = 6;
				end;
			end;
		run;

		proc sort data=all_sev; by order aesev; run;

		data all_sev;
			set all_sev end=eof;
			by order;
			retain sev_num;
			if order < 100 or (order = 100 and first.order) then do;
				sev_num = _n_;
				call symputx('sev_name_'||compress(sev_num),aesev_display,'g');
			end;
			if eof then call symputx('sev_count',sev_num,'g');
		run;
	%end;

	/* find sums of each system organ class/preferred term per arm and severity level */
	/* using the base dataset with multiple AEs of a given term per subject */
	data cd_&analysis._output;
		set ds_base;
		by aebodsys aedecod;

		%if &analysis = d %then %do;
			where aeser = 'Y';
		%end;

		retain 
			%do i = 1 %to &arm_count.;
               %do j = 1 %to &sev_count.;
                  arm&i._sev&j.
			   %end;
			%end;
			;	
		array sum_sev{&arm_count.,&sev_count.} 
			%do i = 1 %to &arm_count.;
               %do j = 1 %to &sev_count.;
                  arm&i._sev&j.
			   %end;
			%end;
			;

		length sev_num 8.;
		call missing(sev_num);

		if _n_ = 1 then do;
			declare hash sev_lookup(dataset:'all_sev');
			sev_lookup.definekey('aesev');
			sev_lookup.definedata('sev_num');
			sev_lookup.definedone();
		end;

		/* look up assigned severity level number from all_sev */
		rc = sev_lookup.find();

		if first.aedecod then do;
			do i = 1 to &arm_count.;
				do j = 1 to &sev_count.;
					sum_sev(i,j) = 0;
				end;
			end;
		end;

		sum_sev(arm_num,sev_num) = sum(sum_sev(arm_num,sev_num),1);	

		if last.aedecod then do;
			sum_total = sum(%do i = 1 %to &arm_count.; of arm&i._sev1-arm&i._sev&sev_count., %end; 0);
			output;
		end;

		label %do i = 1 %to &arm_count.;
		         %do j = 1 %to &sev_count.;
				     arm&i._sev&j. = "&&&arm_name_&i.. &&&sev_name_&j.."
				 %end;
			  %end;
			  sum_total = 'Total'
			  ;

		keep aebodsys aedecod 
		     %do i = 1 %to &arm_count.;
			     arm&i._sev1-arm&i._sev&sev_count.
			 %end;
			 sum_total;
	run;

	proc sort data=cd_&analysis._output;
		by /*aebodsys*/ descending sum_total;
	run;

	/* find sums of missing severity levels */
	/* and create missing reporting dataset */
	proc sql;
		create table rpt_missing_&analysis.(drop=null) as
		select ifc(substr(upcase("&aeser."),1,1)='N',
               'AEs by Severity',
               'Serious AEs by Severity') as report,
			   %do i = 1 %to &arm_count.;
					%do j = 1 %to &sev_count.;
						sum(arm&i._sev&j.) as arm&i._sev&j.,
					%end;
			   %end;
			   0 as null
		from cd_&analysis._output;
	quit;

	data _null_;											/* 11/18/2015 PG */
		set all_sev;										/* 11/18/2015 PG */
        if _n_=&sev_count.;									/* 11/18/2015 PG */
        call symput('last_sev',strip(aesev_display));		/* 11/18/2015 PG */
    run;

	data rpt_missing_&analysis.;
		set rpt_missing_&analysis.;
		%do i = 1 %to &arm_count.;
			%if "&last_sev." = "Missing" %then %do;			/* 11/18/2015 PG */
				arm&i._missing = arm&i._sev&sev_count.;		
				arm&i._missing_pct = 100*arm&i._sev&sev_count./sum(of arm&i._sev1-arm&i._sev&sev_count.);
			%end;											/* 11/18/2015 PG */
            %else %do;										/* 11/18/2015 PG */
                arm&i._missing = 0;							/* 11/18/2015 PG */
                arm&i._missing_pct = 0;						/* 11/18/2015 PG */
            %end;       									/* 11/18/2015 PG */
		%end;
		keep report %do i = 1 %to &arm_count.; arm&i._missing: %end;;
	run;

	data rpt_missing;
		set %if %sysfunc(exist(rpt_missing)) %then rpt_missing;
		    rpt_missing_&analysis.;
	run;
/*
	proc datasets library=work nolist nodetails; delete rpt_missing_&analysis.; quit;
*/
%mend cd;
