/* aggregate the input dataset (dsin) by the by variables (by1-by4) */
/* and write to the output dataset (dsout) */
/* if output=yes then the macro will create an output dataset */
/* containing only the aggregation counts and percentages */
%macro aggregate(dsin,dsout,by1,by2,by3,by4,report=yes,output=yes);

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
	/* keep one record per subject, by key, and toxicity grade */ 
	proc sort data=&dsin. out=&dsout._sort(keep=usubjid arm_num &key. aetoxgr) nodupkey; 
		by &key. usubjid descending aetoxgr; 
	run;

	/* keep only the highest AETOXGR per subject */
	data &dsout._sort;
		set &dsout._sort;
		by &key. usubjid;
		if not first.usubjid then delete;
	run;

	data &dsout.;
		set &dsout._sort;
		by &key.;

		/* code missing values as max + 1 */
		if aetoxgr = . then aetoxgr = %eval(&toxgr_max. + 1);

		/* sums of each toxicity grade per arm */
		/* first index is arm */
		/* second index is toxicity grade; max + 1 is missing */
		retain %do i = 1 %to &arm_count.;
				  %do j = &toxgr_min. %to &toxgr_max.;
				  	arm&i._toxgr&j.
				  %end;
				  arm&i._toxgr_missing
			   %end;
			   ;
		array arm_toxgr{&arm_count.,&toxgr_min.:%eval(&toxgr_max. + 1)} 
			%do i = 1 %to &arm_count.;
				%do j = &toxgr_min. %to &toxgr_max.;
					arm&i._toxgr&j.
				%end;
				arm&i._toxgr_missing
			%end;
			;

		/* initialize sums to zero */
		if first.&&&by&max_arg. then do i = 1 to &arm_count.;
			do j = &toxgr_min. to %eval(&toxgr_max. + 1);
				arm_toxgr(i,j) = 0;
			end;
		end;

		/* summing */
		arm_toxgr(arm_num,aetoxgr) = sum(arm_toxgr(arm_num,aetoxgr),1);

		/* aggregate sums - all and 3/4, 3/4/5, or 3/4 and 5 */
		array arm_all{&arm_count.} %do i = 1 %to &arm_count.; arm&i._all %end;;
		%if &toxgr_grp5_sw. = 1 %then %let toxgr_grp = 345; %else %let toxgr_grp = 34;
		array arm_grp&toxgr_grp.{&arm_count.} %do i = 1 %to &arm_count.; arm&i._grp&toxgr_grp. %end;;
		
		if last.&&&by&max_arg. then do;
			do i = 1 to &arm_count.;
				arm_all(i) = 
					sum(%do i = &toxgr_min. %to %eval(&toxgr_max. + 1); 
							arm_toxgr(i,&i.), 
						%end; 0);
				arm_grp&toxgr_grp.(i) = 
					sum(%do i = 3 %to %eval(4 + &toxgr_grp5_sw.);
							arm_toxgr(i,&i.),
						%end; 0);
			end;
		end;

		array arm_subjcnt{&arm_count.} arm_subjcnt_1 - arm_subjcnt_&arm_count. 
                             (%do i = 1 %to &arm_count.; &&&arm_&i.. %end;);

		/* percentages of arm safety population */
		if last.&&&by&max_arg. then do;
	        %do i = 1 %to &arm_count.;
			    arm&i._all_pct = 100*arm&i._all/arm_subjcnt_&i.;
				arm&i._grp&toxgr_grp._pct = 100*arm&i._grp&toxgr_grp./arm_subjcnt_&i.;
				%do j = &toxgr_min. %to &toxgr_max.;
					arm&i._toxgr&j._pct = 100*arm&i._toxgr&j./arm_subjcnt_&i.;
				%end;
				arm&i._toxgr_missing_pct = 100*arm&i._toxgr_missing/arm_subjcnt_&i.;
			%end;
		end; 

		if last.&&&by&max_arg. then output;

		label %do i = 1 %to &arm_count.;
                 arm&i._all = "&&&arm_name_&i. All Grades Count"
				 arm&i._all_pct = "&&&arm_name_&i. All Grades %"

				 %do j = &toxgr_min. %to &toxgr_max.;
					arm&i._toxgr&j. = "&&&arm_name_&i. Grade &j. Count"
					arm&i._toxgr&j._pct = "&&&arm_name_&i. Grade &j. %"
				 %end;
				 arm&i._toxgr_missing = "&&&arm_name_&i. Grade Missing Count"
				 arm&i._toxgr_missing_pct = "&&&arm_name_&i. Grade Missing %"

				 %if &toxgr_grp5_sw. = 1 %then %do;
				 	arm&i._grp&toxgr_grp. = "&&&arm_name_&i. Grades 3/4/5 Count"
				 	arm&i._grp&toxgr_grp._pct = "&&&arm_name_&i. Grades 3/4/5 %"
				 %end;
				 %else %do;	
					arm&i._grp&toxgr_grp. = "&&&arm_name_&i. Grades 3/4 Count"
					arm&i._grp&toxgr_grp._pct = "&&&arm_name_&i. Grades 3/4 %"
				 %end;
			  %end;
			  ;

		keep %do i = 1 %to &max_arg.; &&&by&i. %end;
			 %do i = 1 %to &arm_count.;
		    	arm&i._all: arm&i._grp: arm&i._toxgr:
			 %end;
			 ;
	run;

	proc datasets library=work nolist nodetails; delete &dsout._sort; quit;

	/* reporting key variable and missing toxicity grade information */
	/* these are used later to look up information about a given aggregation */
	%if %upcase(%substr(&report.,1,1)) in (Y T) %then %let report = Y;
	%if &report. = Y %then %do;
		%rpt_key;
		%rpt_missing(&dsout.);
	%end;

	%if %upcase(%substr(&output.,1,1)) in (Y T) %then %let output = Y;
	%if &output. = Y %then %do;
		/* format for output */
		/* put variables in appropriate order */
		/* keep only variables to be output */
		data &dsout._output;
			retain &key.
	               %do i = 1 %to &arm_count.; 
	                  arm&i._all
	                  arm&i._all_pct
					  arm&i._grp&toxgr_grp.
					  arm&i._grp&toxgr_grp._pct
					  %if (&toxgr_max. = 5 and &toxgr_grp5_sw. = 0) %then
							arm&i._toxgr5
							arm&i._toxgr5_pct;
				   %end;
				   ;
			set &dsout.;

			keep &key.
				 %do i = 1 %to &arm_count.;
			    	arm&i._all arm&i._all_pct
				 	arm&i._grp&toxgr_grp. arm&i._grp&toxgr_grp._pct
				  	%if (&toxgr_max. = 5 and &toxgr_grp5_sw. = 0) %then
						arm&i._toxgr5 arm&i._toxgr5_pct;
				 %end;
				 ;
		run;
	%end;

%mend aggregate;


/* record key variable information on the aggregated data in rpt_key */
%macro rpt_key;

	proc sql noprint;
		select label into: key_label separated by ', '
		from sashelp.vcolumn
		where libname = 'WORK' and memname = upcase("&dsout.") and varnum <= &max_arg.;
	quit;

	data rpt_&dsout._key;
		retain ds key keyvar_cnt;
		length ds $35 key $35 report $100 key_label $100;
		ds = "&dsout.";
		key = "&key.";
		keyvar_cnt = &max_arg.;

		select(ds); 
			when ('pt_1') report = 'Toxicity Grade Summary';
			when ('pt_2') report = 'Preferred Term Analysis by Toxicity Grade';
			when ('pt_3') report = trim(propcase(put(keyvar_cnt,words.)))||'-Term '||
                                   ifc("&meddra."='Y','MedDRA Analysis','Analysis');
			otherwise report = ds;
		end;

		key_label = ifc("&key_label." ne '',"&key_label",tranwrd("&key",' ',', '));
		keep ds key keyvar_cnt report key_label;
	run;
	
	data rpt_key;
		set %if %sysfunc(exist(rpt_key)) %then
			   rpt_key;
			rpt_&dsout._key;
	run;

	proc datasets library=work nolist nodetails; delete rpt_&dsout._key; quit; 

%mend rpt_key;


/* create reporting dataset with counts of missings per arm */
%macro rpt_missing(ds);

	proc sql;
		create table &ds._missing(drop=null) as
		select "&ds." as ds length=35,
		%do i = 1 %to &arm_count.;
			sum(arm&i._toxgr_missing) as arm&i._toxgr_missing, 
            100*sum(arm&i._toxgr_missing)/sum(arm&i._all) as arm&i._toxgr_missing_pct,
		%end; 0 as null
		from &ds.;
	quit;

	data rpt_missing; 
		set %if %sysfunc(exist(rpt_missing)) %then
			   rpt_missing;
		    &ds._missing;
	run;

	proc datasets library=work nolist nodetails; delete &ds._missing; quit;

%mend rpt_missing;


/* aggregates <dsin> by the by1-by4 variables */
/* and finds descriptive statistics using the FREQ procedure */
%macro compare(dsin,dsout,by1,by2,by3,by4,report=yes);

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
		title1 = "AGGREGATING &dsin. INTO &dsout. BY &key.";
		title2 = "AND CALCULATING DESCRIPTIVE STATISTICS";
		titlen = max(length(title1),length(title2));
		length separator $100;
		do i = 1 to titlen;
			separator =  trim(left(separator))||"*";
		end;

		put separator;
		put; 
		put title1;
		put title2;
		put;
		put separator;
	run;

	/* fix the control arm if its number is greater than the arm count */
	%if &ctl. > &arm_count. %then %let ctl = &arm_count.;
	
	/* build the difference variable label and variable name extension */
	data _null_;
		length cmpgr_label $20 num $10;
		if "&cmpgr." = 'all' then cmpgr_label = 'All Grades';
		else if not notdigit(compress("&cmpgr.")) then do;
			if length("&cmpgr.") = 1 then cmpgr_label = "Grade &cmpgr.";
			else do;
				do i = 1 to length("&cmpgr.");
					num = left(trim(num))||substr("&cmpgr.",i,1)||ifc(i<length("&cmpgr"),'/','');
				end;
				cmpgr_label = "Grades "||compress(num);
			end;
		end;
		call symputx('cmpgr_label',cmpgr_label);

		length cmpgr_varext $20;
		if "&cmpgr." = 'all' then cmpgr_varext = 'all';
		else if "&cmpgr." = 'missing' then cmpgr_varext = 'toxgr_missing';
		else if not anyalpha("&cmpgr.") then do;
			if length("&cmpgr.") = 1 then cmpgr_varext = "toxgr&cmpgr.";
			else cmpgr_varext = "grp&cmpgr.";
		end;
		call symputx('cmpgr_varext',cmpgr_varext);
	run;

	/* keep one record per subject, key, and aetoxgr */
	proc sort data=&dsin.(keep=&key. usubjid arm_num aetoxgr) out=&dsout._sort nodupkey;
		by usubjid &key. descending aetoxgr;
		*where arm_num in (&exp. &ctl.);
	run;

	/* keep only the highest aetoxgr per subject and adverse event */
	data &dsout._sort &dsout._sort_allarm;
		set &dsout._sort;
		by usubjid &key. descending aetoxgr;
		if first.&&&by&max_arg.;
	run;

	/* keep AEs where the subject's arm is the experiment or control */
	/* keep only aetoxgr in the list of those to be used in the comparison metric */
	proc sort data=&dsout._sort(where=(arm_num in (&exp. &ctl.)
                                       %if not %sysfunc(notdigit(&cmpgr.)) %then %do;
                                       and  aetoxgr in (%do i = 1 %to %length(&cmpgr.); %substr(&cmpgr.,&i.,1) %end;)
		                               %end;))
              out=&dsout._sort(drop=aetoxgr);
		by &key.;
	run;

	/* assign adverse event term numbers */
	data &dsout._sort &dsout._term(keep=&key. term_num);
		set &dsout._sort end=eof;
		by &key.;
		retain term_num;
		if _n_ = 1 then term_num = 0;
		if first.&&&by&max_arg. then do;
			term_num = term_num + 1;
			output &dsout._term;
		end;
		output &dsout._sort;
	run;

	/* get counts of subjects' adverse events per arm */
	proc freq data=&dsout._sort noprint;
		table term_num*arm_num / out=&dsout._freq(drop=percent) sparse;
	run;

	/* create cartesian product of the arm numbers and term numbers and merge the counts onto them */
	proc sql noprint;
		create table &dsout._arm_term_cp as
		select term_num, arm_num
		from all_arm a,
		     &dsout._term b
		where arm_num in (&exp. &ctl.)
		order by term_num, arm_num;
	quit;

	data &dsout._freq;
		merge &dsout._arm_term_cp(in=a)
		      &dsout._freq(in=b);
		by term_num arm_num;
		if a;
		/* set missing counts to zero */
		if a and not b then count = 0;
	run;		

	proc transpose data=&dsout._freq out=&dsout._count(drop=_name_ _label_) prefix=arm;
		by term_num;
		var count;
		id arm_num;
	run;

	/* set up 2x2 contingency table for each adverse event */
	/* by adding counts of subjects with no adverse events */
	data &dsout._ct;
		set &dsout._freq;

		select (arm_num);
			%do i = 1 %to &arm_count.;
				when (&i.) arm_count = &&&arm_&i.;
			%end;
			otherwise;
		end;

		/* renumber the arms according to the user's selection */
		/* of treatment and control */
		if arm_num = &exp. then arm_num_ord = 1;
		else if arm_num = &ctl. then arm_num_ord = 2;

		disease = -1; 
		output;
		disease = 0; 
		count = arm_count - count;
		output;

		drop arm_count;
	run;

	/* find risk difference */
	/* separated from the calculation of relative risk */
	/* because continuity correction is unnecessary for risk difference */
	proc freq data=&dsout._ct noprint;
		table arm_num_ord*disease / riskdiff nowarn; 
		weight count;
		by term_num;
		exact binomial fisher;
		output out=&dsout._stat_rd rsk11 rsk21 rdif1 fisher;
	run;

	/* continuity correction */
	/* determine which terms have a zero cell count */
	/* only then apply a continuity correction */
	%if (&cc_sw. ne 0) %then %do; 
		proc sql noprint;
			create table &dsout._ct_cc as
			select a.term_num, arm_num, arm_num_ord, disease, cc_ind,
				   %if &cc_sw. = 1 %then %do;
	                  (case 
	                      when cc_ind = 1 then (count + &cc.) 
	                      else count 
	                   end)
				   %end;
				   %else %if &cc_sw. = 2 %then %do;
	                  (case 
	                      when cc_ind = 1 and arm_num = &exp. then (count + 1/&&&arm_&ctl.) 
	                      when cc_ind = 1 and arm_num = &ctl. then (count + 1/&&&arm_&exp.)
	                      else count 
	                   end)
				   %end;
				   %else %do;
                      count
				   %end;
				      as count
			from &dsout._ct a
			left join (select distinct term_num, 1 as cc_ind
			           from &dsout._ct
					   where count = 0) b
			on a.term_num = b.term_num
			order by term_num, arm_num, disease;
		quit;

		proc datasets library=work nolist nodetails;
			change &dsout._ct=&dsout._ct_nocc;
		quit;

		proc datasets library=work nolist nodetails;
			change &dsout._ct_cc=&dsout._ct;
		quit;

		proc sql noprint;
			create table &dsout._cc_ind as
			select distinct term_num, cc_ind
			from &dsout._ct;
		quit;
	%end;

	%if not &cc_whole. %then %do;
		%put NOTE: WHEN USING NON-INTEGER CONTINUITY CORRECTION, THE FOLLOWING FREQ PROCEDURE;
		%put NOTE: WILL GIVE A WARNING;
	%end;

	/* suppress printing notes about risk estimates not being computed due to zero cell counts */
	options nonotes;

	/* find relative risk and odds ratio */
	proc freq data=&dsout._ct noprint;
		table arm_num_ord*disease / relrisk nowarn; 
		weight count;
		by term_num;
		exact or;
		output out=&dsout._stat_rror relrisk;
	run;

	options notes;

	/* put together counts and statistics */
	/* make dataset suitable for output */
	data &dsout.(keep=&key. arm&exp. _rsk11_ arm&ctl. _rsk21_
	                        %if &ae_rate_ci_sw. = 1 %then %do;
                            xl_rsk11 xu_rsk11 xl_rsk21 xu_rsk21
							%end;
					        _rdif1_ l_rdif1 u_rdif1
						    _rrc1_  l_rrc1  u_rrc1
						    _rror_ 
							l_rror  u_rror
						    xp2_fish
							%if &cc_sw. ne 0 %then row cc_ind;
			                );
		retain &key.
               arm&exp. _rsk11_
			   %if &ae_rate_ci_sw. = 1 %then %do;
               xl_rsk11 xu_rsk11
			   %end;
               arm&ctl. _rsk21_
			   %if &ae_rate_ci_sw. = 1 %then %do;
               xl_rsk21 xu_rsk21
			   %end;
               _rdif1_ l_rdif1 u_rdif1
			   _rrc1_  l_rrc1  u_rrc1
			   _rror_  l_rror  u_rror
			   xp2_fish
               ; 
		merge &dsout._term(in=a)
              &dsout._count(in=b)
		      &dsout._stat_rd(in=c)
		      &dsout._stat_rror(in=d)
              %if &cc_sw. ne 0 %then &dsout._cc_ind(in=e);
			  ;
		by term_num;

		/* fix percentages */
		_rsk11_ = 100*_rsk11_;
		xl_rsk11 = 100*xl_rsk11;
		xu_rsk11 = 100*xu_rsk11;
		_rsk21_ = 100*_rsk21_;
		xl_rsk21 = 100*xl_rsk21;
		xu_rsk21 = 100*xu_rsk21;
		_rdif1_ = 100*_rdif1_;
		l_rdif1 = 100*l_rdif1;
		u_rdif1 = 100*u_rdif1;

		%if not &cc_sw. %then %do;
			cc_ind = 0;
		%end;

		/* if you are not using continuity correction */
		/* or you are using continuity correction with a whole number c.c. */
		/* or you are using non-whole-number continuity correction and the AE did not require c.c. */
		/* then use exact CI for odds ratio */
		if not &cc_sw. or (&cc_sw. and &cc_whole.) or (&cc_sw. and not &cc_whole. and not cc_ind) then do;
			l_rror = xl_rror;
			u_rror = xu_rror;
		end;

		/* row number stored to use when looking up cc indicator during output */
		row = _n_;
	run;

	proc datasets library=work nolist nodetails;
		modify &dsout.;
		rename arm&exp.=arm&exp._&cmpgr_varext.
		       arm&ctl.=arm&ctl._&cmpgr_varext.
               _rsk11_=arm&exp._&cmpgr_varext._pct
		       _rsk21_=arm&ctl._&cmpgr_varext._pct
			   %if &ae_rate_ci_sw. = 1 %then %do;
			   xl_rsk11 = arm&exp._&cmpgr_varext._pct_cilb
			   xu_rsk11 = arm&exp._&cmpgr_varext._pct_ciub
			   xl_rsk21 = arm&ctl._&cmpgr_varext._pct_cilb
			   xu_rsk21 = arm&ctl._&cmpgr_varext._pct_ciub
			   %end;
               _rdif1_=rd
               l_rdif1=rd_cilb
		       u_rdif1=rd_ciub
		       _rrc1_=rr
		       l_rrc1=rr_cilb
			   u_rrc1=rr_ciub
               _rror_=ort
			   l_rror=or_cilb
               u_rror=or_ciub
               xp2_fish=p_value
		       ;
	quit;

	proc datasets library=work nolist nodetails;
		modify &dsout.;
		label arm&exp._&cmpgr_varext.="Treatment: &&&arm_name_&exp. &cmpgr_label. Count"
		      arm&ctl._&cmpgr_varext.="Control: &&&arm_name_&ctl. &cmpgr_label. Count"
			  arm&exp._&cmpgr_varext._pct="Treatment: &&&arm_name_&exp. &cmpgr_label. %"
		      arm&ctl._&cmpgr_varext._pct="Control: &&&arm_name_&ctl. &cmpgr_label. %"
			  %if &ae_rate_ci_sw. = 1 %then %do;
			   arm&exp._&cmpgr_varext._pct_cilb="Treatment: &&&arm_name_&exp. &cmpgr_label. % Exact Lower CL"
			   arm&exp._&cmpgr_varext._pct_ciub="Treatment: &&&arm_name_&exp. &cmpgr_label. % Exact Upper CL"
			   arm&ctl._&cmpgr_varext._pct_cilb="Control: &&&arm_name_&ctl. &cmpgr_label. % Exact Lower CL"
			   arm&ctl._&cmpgr_varext._pct_ciub="Control: &&&arm_name_&ctl. &cmpgr_label. % Exact Upper CL"
			  %end;
		      rd='Risk Difference'
			  rd_cilb='Risk Difference Lower CL'
			  rd_ciub='Risk Difference Upper CL'
              rr='Relative Risk'
			  rr_cilb='Relative Risk Lower CL'
			  rr_ciub='Relative Risk Upper CL'
			  ort='Odds Ratio'
			  or_cilb='Odds Ratio Lower CL'
			  or_ciub='Odds Ratio Upper CL'
			  p_value="Fisher's Exact Test P-value"
             ;
	quit;

	%if &cc_sw. ne 0 %then %do;
		data &dsout._output(drop=row cc_ind)
	         &dsout._output_cc_ind(keep=row cc_ind);
			set &dsout.;
		run;
	%end;
	%else %do;
		data &dsout._output;
			set &dsout.;
		run;
	%end;

	/* reporting key variable and missing toxicity grade information */
	/* these are used later to look up information about a given aggregation */
	%if %upcase(%substr(&report.,1,1)) in (Y T) %then %let report = Y;
	%if &report. = Y %then %do;
		%rpt_key;
		
		/* find counts of all AEs and AEs with missing toxicity grades */
		proc sql noprint;
			create table &dsout._missing(drop=null) as
			select "&dsout." as ds, %do i = 1 %to &arm_count.;
			                         arm&i._toxgr_missing, 
									 100*arm&i._toxgr_missing/arm&i._all as arm&i._toxgr_missing_pct,
									%end;
									0 as null
			from (select %do i = 1 %to &arm_count.;
			       	      sum(case when arm_num = &i. then 1 else 0 end) as arm&i._all,
		           	      sum(case when aetoxgr is missing and arm_num = &i. then 1 else 0 end) as arm&i._toxgr_missing, 
				         %end;
				         0 as null
			      from &dsout._sort_allarm)
			;
		quit;

		data rpt_missing; 
			set %if %sysfunc(exist(rpt_missing)) %then
				rpt_missing;
			    &dsout._missing;
		run;
	%end;
/*
	proc datasets library=work nolist nodetails; 
		delete &dsout._term
		       &dsout._sort
		       &dsout._sort_allarm
			   &dsout._freq
			   &dsout._cc_ind
			   &dsout._count
			   &dsout._ct:
			   &dsout._stat:
			   %if &report. = Y %then &dsout._missing;
               ; 
	quit;
*/
%mend compare;


/* create a version of the output with header rows */
/* for each group in the first column */
/* if sortgrp_sw = Y then it sorts <ds> by1,by2,...,by(n-1) key groups */
/* by the value of the highest member of the group */
/* sortdir (desc/asc) controls the direction of sorting */
%macro fmt_output(ds,sort_sw=no,sortvar=,sortgrp_sw=no,sortdir=desc);

	%if %upcase(%substr(&sort_sw.,1,1)) in (Y T) %then %let sort_sw	= Y;
	%if %upcase(%substr(&sortgrp_sw.,1,1)) in (Y T) %then %let sortgrp_sw = Y;

	%if &sortvar. = p_value %then %let sortdir = asc;

	proc sql noprint;
		select key, keyvar_cnt into : key, : keyvar_cnt
		from rpt_key
		where upcase(substr(  ds ,1,min(length(trim(ds)),length(trim("&ds")))))
            = upcase(substr("&ds",1,min(length(trim(ds)),length(trim("&ds")))));
	quit; 

	/* incorporate the cc indicator if necessary */
	%if &cc_sw. ne 0 and %index(&ds.,pt_3) %then %do;
		data &ds._cc;
			set &ds.;
			set &ds._cc_ind(drop=row);
		run;

		%let l_ds = &ds._cc;
	%end;
	%else %let l_ds = &ds.;

	/* only do this sorting if sort=yes */
	%if &sort_sw. = Y %then %do;
		/* sort by by1,by2,...,by(n-1) key variables and sort variable */
		proc sort data=&l_ds. out=&ds._fmt_sort;
			by %do i = 1 %to %eval(&keyvar_cnt.-1); %scan(&key.,&i.) %end; 
	           %if &sortdir. = desc %then descending; &sortvar.;
		run; 

		/* find the highest count in each group to sort by the highest per-group count */
		%if &sortgrp_sw = Y %then %do;
			data &ds._fmt_sort_order;
				set &ds._fmt_sort(keep=%do i = 1 %to %eval(&keyvar_cnt.-1); %scan(&key.,&i.) %end; &sortvar.);
				by %do i = 1 %to %eval(&keyvar_cnt.-1); %scan(&key.,&i.) %end; 
			       %if &sortdir. = desc %then descending; &sortvar.;
				array top_cnt{*} top_cnt1 - top_cnt3;
				retain grp_order top_cnt1 - top_cnt3;
				if first.%scan(&key.,%eval(&keyvar_cnt.-1)) then do;
					grp_order = 0;
					do i = 1 to 3; top_cnt(i) = .; end;
				end;
				grp_order = grp_order + 1;
				if grp_order <= 3 then top_cnt(grp_order) = &sortvar.;
				if last.%scan(&key.,%eval(&keyvar_cnt.-1)) then output;
				drop &sortvar. grp_order i;
			run;

			/* merge the top 3 sort variable values to each member of each group */
			data &ds._fmt_sort;
				set &ds._fmt_sort;

				if _n_ = 1 then do;
					declare hash h(dataset:"&ds._fmt_sort_order");
					h.definekey(%do i = 1 %to %eval(&keyvar_cnt.-1); 
                                    %sysfunc(ifc(&i.<%eval(&keyvar_cnt.-1),
                                                 %sysfunc(quote(%scan(&key.,&i.)))%str(,),
                                                 %sysfunc(quote(%scan(&key.,&i.)))))
                                %end;);
					h.definedata('top_cnt1','top_cnt2','top_cnt3');
					h.definedone();
				end;

				call missing(top_cnt1, top_cnt2, top_cnt3);

				rc = h.find();
				
				drop rc;
			run;
		%end;
	%end;
	%else %do;
		data &ds._fmt_sort;
			set &ds.;
		run;
	%end;

	/* reverse the order of the dataset */
	proc sort data=&ds._fmt_sort 
              out=&ds._fmt_sort;
		by %if &sortgrp_sw. = Y %then %do;
              %do tci = 1 %to 3; %if &sortdir. = asc %then descending; top_cnt&tci. %end;
		   %end;
		   %if &sort_sw. = Y %then %do;
              %do i = 1 %to %eval(&keyvar_cnt.-1); descending %scan(&key.,&i.) %end;
              %if &sortdir. = asc %then descending; &sortvar.
			  descending %scan(&key.,&keyvar_cnt.)
		   %end;
		   %else %do;
              %do i = 1 %to %eval(&keyvar_cnt.); descending %scan(&key.,&i.) %end;
		   %end;
           ;
	run;

	/* output a new header row at the end (beginning) of each group */
	data &ds._fmt(drop=&key.);
		retain order adverse_event;
		set &ds._fmt_sort;
		by %if &sortgrp_sw. = Y %then %do; 
		      %do tci = 1 %to 3; %if &sortdir. = asc %then descending; top_cnt&tci. %end; 
           %end; 
           %do i = 1 %to %eval(&keyvar_cnt.-1); descending %scan(&key.,&i.) %end; 
           %if &sortdir. = asc %then descending; &sortvar.;
		length adverse_event $800;
		label adverse_event='Adverse Event';

		order + 1;
		header = 0;
		adverse_event = '     '||%scan(&key.,&keyvar_cnt.);
		output;

		if last.%scan(&key.,%eval(&keyvar_cnt.-1)) then do;
			order + 1;
			header = 1;
			adverse_event = %do i = 1 %to %eval(&keyvar_cnt.-1); 
                               trim(%scan(&key.,&i.))
                               %if &i. ne %eval(&keyvar_cnt.-1) %then %do; ||' : '|| %end;
                            %end;;
			%let dsid = %sysfunc(open(&ds.));
			%do i = 1 %to %sysfunc(attrn(&dsid.,nvars));
				call missing(%sysfunc(varname(&dsid.,&i.)));;
			%end; 
			%let rc = %sysfunc(close(&dsid.));
			output;
		end;  

		%if &sortgrp_sw. = Y %then drop top_cnt:;;
	run;

	/* restore original order */
	proc sort data=&ds._fmt out=&ds._fmt(drop=order);
		by descending order;
	run;

	/* separate out header row indicator from output */
	%if &cc_sw. ne 0 and %index(&ds.,pt_3) %then %do;
		data &ds._fmt(drop=header row cc_ind) 
	         &ds._fmt_ind(keep=header) 
			 &ds._fmt_cc_ind(keep=row cc_ind);
			 ;
			set &ds._fmt;
			row = _n_;
		run;
	%end;
	%else %do;
		data &ds._fmt(drop=header) 
	         &ds._fmt_ind(keep=header) 
			 ;
			set &ds._fmt;
		run;
	%end;

	proc datasets library=work nolist nodetails;
		delete &ds._fmt_sort:
               %if &cc_sw. ne 0 and %index(&ds.,pt_3) %then &ds._cc;
			   ;
	quit;

%mend fmt_output;
