/****************************************************************************/
/*         PROGRAM NAME: Grouping and Subsetting Output                     */
/*                                                                          */
/*          DESCRIPTION: Create output for grouping and subsetting          */
/*                       Contains three macros:                             */
/*                          group_subset_pp -- Preprocessing to create      */
/*                                             output datasets              */
/*                          group_subset_xls_out -- XLS template output     */
/*                          group_subset_xml_out -- Excel XML output        */
/*                                                                          */
/*               AUTHOR: David Kretch (david.kretch@us.ibm.com)	            */
/*                                                                          */
/*                 DATE: March 4, 2011                                      */
/*                                                                          */
/*  EXTERNAL FILES USED: ae_xml_output.sas -- XML formatting macros         */
/*                       XLS template if using xls_out macro                */
/*                                                                          */
/*  PARAMETERS REQUIRED: (group_subset_xls_out) GS_FILE -- template file    */
/*                                                         and path         */
/*                                                                          */
/*    DATASETS REQUIRED: SL_GROUP                                           */
/*                       SL_SUBSET                                          */
/*                       SL_DATASETS                                        */
/*                                                                          */
/*            MADE WITH: SAS 9.2                                            */
/*                                                                          */
/*                NOTES:                                                    */
/*                                                                          */
/*            REVISIONS: ---                                                */
/*                                                                          */
/****************************************************************************/

/*****************************************/
/* GROUPING AND SUBSETTING PREPROCESSING */
/*****************************************/
%macro group_subset_pp;

	%put SL GROUPING/SUBSETTING PREPROCESSING;

	data _null_;
		dsid = open('sl_group');
		if dsid then nobs = attrn(dsid,'nobs');
		else nobs = 0;
		call symputx('sl_group_nobs',put(nobs,8. -l),'g');
		rc = close(dsid);

		dsid = open('sl_subset');
		if dsid then nobs = attrn(dsid,'nobs');
		else nobs = 0;
		call symputx('sl_subset_nobs',put(nobs,8. -l),'g');
		rc = close(dsid);
	run;

	/****************************************/
	/* GROUPING AND SUBSETTING DESCRIPTIONS */
	/****************************************/

	/* grouping */
	%global sl_group_desc;
	
	/* if grouping was used, make a description */
	%if &sl_group_nobs. %then %do;

		proc sql noprint;
			select distinct group_name into: sl_group_desc separated by ', '
			from sl_group;

			select count(distinct group_name) into: group_count
			from sl_group;
		quit;

		data _null_;
			length group_desc $5000;

			group_desc = "&sl_group_desc.";
			group_count = &group_count.;

			if group_count = 2 then group_desc = tranwrd(group_desc,', ',' and ');
			else if group_count > 2 then do;
				index = length(trim(group_desc)) - index(left(reverse(group_desc)),',') + 1;
				group_desc = substr(group_desc,1,index)||' and'||substr(group_desc,index+1);
			end;

			group_desc = 'Grouped by '||group_desc;

			call symputx('sl_group_desc',group_desc,'g');
		run;

	%end;
	%else %do;
		%let sl_group_desc = No grouping;
	%end;


	/* subsetting */
	%global sl_subset_desc sl_subset_operator;

	%if &sl_subset_nobs. %then %do;

		proc sql noprint;
			select distinct lowcase(outer_operator) into: sl_subset_outer separated by ','
			from sl_subset;

			select count(distinct outer_operator) - 1 into: sl_subset_outer_err
			from sl_subset;

			select distinct name into: sl_subset_desc separated by " &sl_subset_outer. "
			from sl_subset;
		quit;

		%let sl_subset_desc = Subset by &sl_subset_desc.;

		/* create description of subsetting outer operator */
		proc sql noprint;
			select count(distinct name)	into: sl_subset_count
			from sl_subset;
		quit;

		data _null_;
			length sl_subset_operator $500;
			if &sl_subset_count. > 1 then select ("&sl_subset_outer.");
				when ('and') sl_subset_operator = 'ALL of the following rules must be true '||
                                                  'for a subject to be included in the analysis.';
				when ('or') sl_subset_operator  = 'ANY of the following rules must be true '||
                                                  'for a subject to be included in the analysis.';
				otherwise sl_subset_operator = '';
			end;
			else do;
				sl_subset_operator = '';
			end;

			call symputx('sl_subset_operator',sl_subset_operator,'g');
		run;

	%end;
	%else %do;
		%let sl_subset_desc = No subsetting;
		%let sl_subset_operator = N/A;
	%end;

	%put &sl_group_desc.;
	%put &sl_subset_desc.;


	/* single line description */
	%global sl_gs_desc;

	%if &sl_group_nobs. and &sl_subset_nobs. %then
		%let sl_gs_desc = &sl_group_desc.%str(;) &sl_subset_desc.;
	%else %if &sl_group_nobs. %then
		%let sl_gs_desc = &sl_group_desc.;
	%else %if &sl_subset_nobs. %then
		%let sl_gs_desc = &sl_subset_desc.;
	%else 
		%let sl_gs_desc = ;

	%put &sl_gs_desc.;


	/*******************************************************/
	/* GROUPING AND SUBSETTING DETAILED DESCRIPTION TABLES */
	/*******************************************************/

	/****************/
	/* group detail */
	/****************/

	%put GROUP DETAIL;

	proc sort data=sl_group; by group_name partition var_name dsvg_grp_name var_value; run;

	/* find whether any of the grouped variables were partitioned */
	proc sql noprint;
		select count(1)	into: sl_group_part_ind
		from (select distinct domain
		      from sl_datasets a,
			       sl_group b
			  where a.datatype = b.domain
	            and a.partition_variable is not missing);
	quit;

	data sl_out_group;
		retain group_name domain partition_desc var_desc placeholder var_value dsvg_grp_name;
		set sl_group end=eof;
		by group_name var_name partition dsvg_grp_name var_value;

		/* placeholder for the merged column in the template */
		call missing(placeholder);

		length varlabel $256;
		call missing(varlabel);

		/* variable description */
		if first.group_name then do;
			dsid = open(domain);
			retain varlabel;
			if dsid then do;
				varnum = varnum(dsid,upcase(var_name));
				if varnum then varlabel = varlabel(dsid,varnum);
			end;
		end;
		if last.group_name then do;
			rc = close(dsid);
		end;

		length var_desc $300;
		if not missing(varlabel) then var_desc = trim(varlabel)||' ('||trim(var_name)||')';
		else var_desc = trim(var_name);


		/* partition description */
		/* look up partition variables */
		length partition_desc $300;
		call missing(partition_desc);

		/* commented out due to exclusive use of Lab Test to partition in task order 4 */
		/*%if &sl_group_part_ind. %then %do;

			datatype = domain;

			if _n_ = 1 then do;
				declare hash h(dataset:'sl_datasets');
				h.definekey('datatype');
				h.definedata('partition_variable');
				h.definedone();
			end;

			length partition_variable $32;
			call missing(partition_variable);
			rc = h.find();
			drop rc;

			if not missing(partition_variable) then do;
				dsid = open(domain);
				if dsid then partition_varlabel = varlabel(dsid,varnum(dsid,upcase(partition_variable)));
				rc = close(dsid);
				
				if partition_varlabel ne '' then do;
					partition_desc = trim(partition_varlabel)||' ('||upcase(trim(partition_variable))||')'||
	                                 " '"||trim(partition)||"'";
				end;
				else do;
					partition_desc = upcase(trim(partition_variable))||''||" '"||trim(partition)||"'";
				end;

			end;

		%end; */

		if not missing(partition) then partition_desc = partition;
		else partition_desc = 'N/A';


		/* format for output */
		if not first.group_name then do;
			group_name = '';
			domain = '';
		end;

		if not first.partition then partition_desc = '';

		if not first.var_name then var_desc = '';

		if not first.dsvg_grp_name then do;
			dsvg_grp_name = '';
		end;

		label group_name = 'Grouping Rule Name'
		      domain = 'Domain'
			  partition_desc = 'For Observations Where...'
			  var_desc = 'Variable'
			  var_value = 'Original Variable Value'
			  dsvg_grp_name = 'Grouped Variable Value'
			  ;

		keep group_name domain partition_desc placeholder var_desc var_value dsvg_grp_name;
	run;


	/*****************/
	/* subset detail */
	/*****************/

	%put SUBSET DETAIL;

	proc sort data=sl_subset; by name domain partition var_name var_value; run;

	/* find whether any of the subset rules used partitioned variables */
	proc sql noprint;
		select count(1)	into: sl_subset_part_ind
		from (select distinct domain
		      from sl_datasets a,
			       sl_subset b
			  where a.datatype = b.domain
	            and a.partition_variable is not missing);
	quit;

	/* find the number of conditions per subset rule */
	proc sql noprint;
		create table sl_subset_condition as
		select name as subset_name, count(1) as condition_count
		from (select distinct name, partition, var_name
	          from sl_subset)
		group by name;
	quit;

	data sl_out_subset;
		retain subset_name domain partition_desc  var_desc condition var_value operator;
		set sl_subset(rename=(name=subset_name)) end=eof;
		by subset_name domain partition var_name var_value;

		length varlabel $256;
		call missing(varlabel);

		/* variable description */
		if first.var_name then do;
			dsid = open(domain); 
			retain varlabel;
			if dsid then do;
				varnum = varnum(dsid,upcase(var_name));
				if varnum then varlabel = varlabel(dsid,varnum);
			end;
		end;
		if last.subset_name then do;
			rc = close(dsid);
		end;

		length var_desc $300;
		if not missing(varlabel) then var_desc = trim(varlabel)||' ('||trim(var_name)||')';
		else var_desc = var_name;

		
		/* condition number */
		/* numbers each condition in each subset rule */
		length condition $10;
		retain condition_no condition_sub_no;
		if first.subset_name then do;
			condition_no + 1;
			condition_sub_no = 0;
		end;
		if first.partition or first.var_name then condition_sub_no + 1;
		condition = trim(put(condition_no,8. -l))||'.'||trim(put(condition_sub_no,8. -l));


		/* partition description */
		/* look up partition variables */
		length partition_desc $300;
		call missing(partition_desc);

		/* commented out due to exclusive use of Lab Test to partition in task order 4 */
		/*%if &sl_subset_part_ind. %then %do;

			datatype = domain;

			if _n_ = 1 then do;
				declare hash h1(dataset:'sl_datasets');
				h1.definekey('datatype');
				h1.definedata('partition_variable');
				h1.definedone();
			end;

			length partition_variable $32;
			call missing(partition_variable);
			rc = h1.find();
			drop rc;

			if not missing(partition_variable) then do;
				dsid = open(domain);
				if dsid then do;
					partition_varlabel = varlabel(dsid,varnum(dsid,upcase(partition_variable)));
				end;
				rc = close(dsid);
				
				if partition_varlabel ne '' then do;
					partition_desc = trim(partition_varlabel)||' ('||upcase(trim(partition_variable))||')'||
	                                 " '"||trim(partition)||"'";
				end;
				else do;
					partition_desc = upcase(trim(partition_variable))||''||" '"||trim(partition)||"'";
				end;
			end;

		%end; */

		if not missing(partition) then partition_desc = partition;
		else partition_desc = 'N/A';


		/* operator description */
		length operator $50;
		call missing(operator);
		
		if first.subset_name then do;
			if _n_ = 1 then do;
				declare hash h2(dataset:'sl_subset_condition');
				h2.definekey('subset_name');
				h2.definedata('condition_count');
				h2.definedone();
			end;

			length condition_count 8.;
			call missing(condition_count);
			rc = h2.find();
			drop rc;

			if inner_operator ne '' then do;
				do i = 1 to condition_count;
					operator = left(trim(operator))||' '||trim(put(condition_no,8. -l))||'.'||
	                           trim(put(i,8. -l))||' '||ifc(i<condition_count,upcase(inner_operator),'');
				end;
				select(inner_operator);
					when ('OR') operator = 'Condition '||operator;
					when ('AND') operator = 'Conditions '||operator;
					otherwise;
				end;
				operator = compbl(operator);
			end;
			else operator = 'N/A';
		end;


		/* format for output */
		if not first.subset_name then do;
			subset_name = '';
		end;

		if not first.domain then domain = '';

		if not first.partition then partition_desc = '';

		if not first.var_name then do;
			var_desc = ''; 
			condition = '';
		end;

		label subset_name = 'Subset Rule Name'
		      domain = 'Domain'
			  partition_desc = 'For Observations Where...'
			  var_desc = 'Variable'
			  condition_no = 'Condition Number'
			  var_value = 'Variable Value'
		      operator = 'Which Conditions Apply?'
			  ;

		keep subset_name domain partition_desc var_desc condition var_value operator;
	run;

	proc datasets library=work nolist nodetails; delete sl_subset_condition; quit;


	/*******************/
	/* CUSTOM DATASETS */
	/*******************/

	%put CUSTOM DATASETS;

	%global sl_custom_ds;

	proc sql noprint;
		select datatype into: sl_custom_ds separated by ', '
		from sl_datasets
		where default = 'N';
	quit;

%mend group_subset_pp;


/*****************************/
/* EXCEL XLS TEMPLATE OUTPUT */
/*****************************/
%macro group_subset_xls_out(gs_file=);

	%put GROUPING/SUBSETTING EXCEL TEMPLATE OUTPUT;

	proc sql noprint;
		select put(count(1),8. -l) into: sl_group_row_count
		from sl_out_group;
	
		select put(count(1),8. -l) into: sl_subset_row_count
		from sl_out_subset;
	quit;

	/* grouping and subsetting info */
	data sl_out_group_subset_info;
		length val_desc $25 val $500;

		val_desc = 'Grouped by';
		val = "&sl_group_desc.";
		output;

		val_desc = 'Subset by';
		val = "&sl_subset_desc.";
		output;
		
		val_desc = 'Group row count';
		val = "&sl_group_row_count.";
		output;

		val_desc = 'Subset row count';
		val = "&sl_subset_row_count.";
		output;	

		val_desc = 'Subset operator';
		val = "&sl_subset_operator.";
		output;	

		val_desc = 'Note';
		if not (&sl_group_row_count. and &sl_subset_row_count.) then do;
			if not &sl_group_row_count. and &sl_subset_row_count. then val = 'No grouping was used.';
			else if &sl_group_row_count. and not &sl_subset_row_count. then val = 'No subsetting was used.';
			else val = 'Neither grouping nor subsetting were used.';
		end;
		else val = '';
		output;

		val_desc = 'GS description';
		val = "&sl_gs_desc.";
		output;
	run;

	%put &run_location.;

	/* local runs use the Microsoft Jet database-based Excel LIBNAME engine */
	%if %upcase(&run_location.) = LOCAL %then %do;
		libname xls excel "&gs_file." ver=2003; 
	%end;
	/* Script Launcher runs use the PCFILES LIBNAME Engine */
	%else %do;
		/* the server appears to require a waiting period */
		/* sleep for one second before opening the library */
		data _null_;
			rc = sleep(1);
		run;

		libname xls pcfiles path="&gs_file."; 
	%end;

	proc datasets library=xls nolist nodetails;
		delete group_detail
               subset_detail
               group_subset_info;
	quit; 

	data xls.group_detail;
		set sl_out_group;
	run;

	data xls.subset_detail;
		set sl_out_subset;
	run;

	data xls.group_subset_info;
		set sl_out_group_subset_info;
	run;
	
	libname xls clear;

%mend group_subset_xls_out;


/******************************************/
/* GROUPING & SUBSETTING EXCEL XML OUTPUT */
/******************************************/
%macro group_subset_xml_out(delete_im=Y);

	%put SL GROUPING/SUBSETTING EXCEL XML OUTPUT;

	%let ds = sl_gs;
	%let wstitle = Grouping and Subsetting;

	/* set up worksheet start and end datasets */
	data ws_&ds._start;
		length string $&strlen.;
		string = '<Worksheet ss:Name="'||"&wstitle."||'">'; output; 
	run;

	data ws_&ds._end; 
		length string $&strlen.; 
		string = '</Worksheet>'; output;
	run;

	data ws_&ds._table_start; 
		length string $&strlen.; 
		string = '<Table>'; output;
		/* define column widths */
		string = '<Column ss:Width="162"/>'; output;
		string = '<Column ss:Width="48"/>'; output;
		string = '<Column ss:Width="162"/>'; output;
		string = '<Column ss:Width="162"/>'; output;
		string = '<Column ss:Width="50.5"/>'; output;
		string = '<Column ss:Width="162"/>'; output;
		string = '<Column ss:Width="162"/>'; output;
		string = '<Column/>'; output;
	run;

	data ws_&ds._table_end;
		length string $&strlen.; 
		string = '</Table>'; output;
	run;

	/* make the top of the worksheet with the title and run info */
	data ws_&ds._header_data;
		%xml_tag_def;
		%xml_init;

		Type = 'String';

		%let row = 0;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
		
		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'Grouping and Subsetting Summary'; StyleID = 'Header'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;

		StyleID = 'Default8'; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = "NDA/BLA: &ndabla."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Study: &studyid."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'Analysis run date: '||put(date(),e8601da.)||' '||put(time(),timeampm11.); output;
	run;

	%markup(ws_&ds._header_data,ws_&ds._header);

	%if &sl_group_nobs. or &sl_subset_nobs. %then %do;

		/* find the number of rows to merge down for each of the grouping and subsetting tables */
		%macro gs_rows(ds=,varlist=);

			%let n = %eval(%sysfunc(countc(%sysfunc(compbl(&varlist.)),,s))+1);

			data sl_fmt_&ds._row(keep=row)
				 %do i = 1 %to &n.; 
					%let var = %scan(&varlist.,&i.);
				    sl_fmt_&ds._&var.(keep=&var._row &var._n rename=(&var._row=row)) 
				 %end;
				 ;
				set sl_&ds.%if &ds. = subset %then (rename=(name=subset_name));;
				by &varlist.;

				row + 1;
				output sl_fmt_&ds._row;

				%do i = 1 %to &n.;
					%let var = %scan(&varlist.,&i.);
					retain &var._row &var._n;

					if first.&var. then do;
						&var._row = row;
						&var._n = 0;
					end;
					else &var._n + 1;

					if last.&var. then output sl_fmt_&ds._&var.;
				%end;
			run;

			data sl_fmt_&ds.;
				merge sl_fmt_&ds._row(in=a)
				      %do i = 1 %to &n.; sl_fmt_&ds._%scan(&varlist.,&i.) %end;
					  ;
				by row;
			run;

			proc datasets library=work nolist nodetails; delete sl_fmt_&ds._:; quit;

		%mend gs_rows;

		/************/
		/* GROUPING */
		/************/
		%if &sl_group_nobs. %then %do;

			%put GROUPING;

			/* make the section text */
			data ws_&ds._group_text_data;
				%xml_tag_def;
				%xml_init;

				Type = 'String';

				%let row = 0;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = "&sl_group_desc."; StyleID = 'SubHeader'; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;

				StyleID = 'Default10Wrap'; MergeAcross = 6;

				Row = %let row = %eval(&row. + 1); &row.;
				Height = 50;
				Data = 'The table below shows the rules used for grouping values together. Each grouping '||
                       'applies to a single domain and variable. The values of that variable can be put into '||
                       'more than one group. For example, if four arms from the planned arm (ARM) variable in '||
                       'domain DM are put into two groups -- one with the control arm and the other with the '||
                       'three other arms -- this table would show four values in the Original Value column '||
                       'mapped onto two values in the Grouped Value column.'; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Height = 12.75;
				Data = 'If a grouping for the LB or VS domain has a non-empty cell in the Test column, that '||
                       'grouping is applied only to lab or vital sign tests of the kind stated in the Test column. '; 
                output;	

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;
			run;

			%markup(ws_&ds._group_text_data,ws_&ds._group_text);

			/* make the grouping data table column headers */
			data ws_&ds._group_cols_data;
				%xml_tag_def;
				%xml_init;

				Type = 'String';
				StyleID = 'ColumnOutline';

				Row = 1;
				Height = 30;
				Data = 'Grouping Name'; output;
				Data = 'Domain'; output;
				Data = 'Test'; output;
				Data = 'Variable'; MergeAcross = 1; output;
				MergeAcross = .;
				Data = 'Original Value'; output;
				Data = 'Grouped Value'; output;
			run;

			%markup(ws_&ds._group_cols_data,ws_&ds._group_cols);


			/* make a dataset containing the number of rows to merge down for each grouping */
			%gs_rows(ds=group,varlist=group_name partition var_name dsvg_grp_name);

			/* find the variable numbers */
			proc sql noprint;
				create table sl_fmt_group_varnum as
				select name, varnum
				from dictionary.columns
				where libname = 'WORK'
				  and memtype = 'DATA'
				  and memname = 'SL_OUT_GROUP';
			quit;


			/* mark up the grouping data table */
			%annotate(sl_out_group,ws_&ds._group_data_note);

			data ws_&ds._group_data_note;
				set ws_&ds._group_data_note;

				if upcase(varname) = 'PLACEHOLDER' then delete;

				/* look up row info for merging cells */
				if _n_ = 1 then do;
					declare hash h1(dataset:'sl_fmt_group');
					h1.definekey('row');
					h1.definedata('group_name_n','partition_n','var_name_n','dsvg_grp_name_n');
					h1.definedone();
				end;

				call missing(group_name_n,var_name_n,partition_n,dsvg_grp_name_n);
				rc = h1.find();
				drop rc;

				/* look up column info */
				if _n_ = 1 then do;
					declare hash h2(dataset:'sl_fmt_group_varnum(rename=(name=varname))');
					h2.definekey('varname');
					h2.definedata('varnum');
					h2.definedone();
				end;

				call missing(varnum);
				rc = h2.find();
				drop rc;

				lag_varnum = lag(varnum);

				if varnum > 1 and varnum - lag_varnum ne 1 then Index = varnum;

				if varname = 'var_desc' then MergeAcross = 1;

				if varname in ('group_name','domain','partition_desc','var_desc') then do;
					if group_name_n ne . then MergeDown = group_name_n;
					else delete;
				end;
				if varname = 'dsvg_grp_name' then do;
					if dsvg_grp_name_n ne . then MergeDown = dsvg_grp_name_n;
					else delete;
				end;

				if varname not in ('var_value') then StyleID = 'GS_BTLRB';
				else do;
					if dsvg_grp_name_n ne . then StyleID = 'GS_BTLR';
					else StyleID = 'GS_BLR';
					if bottom then StyleID = trim(StyleID)||'B';
				end;

			run;

			%markup(ws_&ds._group_data_note,ws_&ds._group_data);

			data ws_&ds._group;
				set ws_&ds._group_text
				    ws_&ds._group_cols
					ws_&ds._group_data;
			run;

		%end;
		%else %do;

			%put NO GROUPING;

			/* make the section text */
			data ws_&ds._group_data;
				%xml_tag_def;
				%xml_init;

				Type = 'String';

				%let row = 0;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = "&sl_group_desc."; StyleID = 'SubHeader'; output;
			run;

			%markup(ws_&ds._group_data,ws_&ds._group);

		%end;

		/**************/
		/* SUBSETTING */
		/**************/
		%if &sl_subset_nobs. %then %do;

			%put SUBSETTING;

			/* make the section text */
			data ws_&ds._subset_text_data;
				%xml_tag_def;
				%xml_init;

				Type = 'String';

				%let row = 0;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = "&sl_subset_desc."; StyleID = 'SubHeader'; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;

				StyleID = 'Default10Wrap'; MergeAcross = 6;

				Row = %let row = %eval(&row. + 1); &row.;
				Height = 50;
				Data = "The table below shows the rules for subsetting subjects and those subjects' "||
                       'observations in other domains. For a subject to be included in the subset and used '||
                       'in analysis, they must have at least one value in the Value column for the associated '||
                       'variable in the Variable column. For example, if the Value column has values 5 through '||
                       '10 for domain LB and variable LBSTRESN, a subject must have at least one lab test in LB '||
                       'with LBSTRESN from 5 and 10.'; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Height = 50;
				Data = 'Each subset can be made up of several conditions and these are numbered in the Condition '||
                       "No. column. The 'Which Conditions Apply? (AND vs OR)' column states whether for a given "||
                       'subset, all its conditions must be true for a subject to be included in the subset, or '||
                       'any one of them being true will suffice. If all must be true, this column will list out '||
                       "all the subset's conditions separated by an 'AND'. If only one must be true, the "||
                       "subset's conditions will be separated by an 'OR'.'"; 
                output;	

				Row = %let row = %eval(&row. + 1); &row.; 
				Height = 50;
				Data = 'If a subset using the LB or VS domain has a non-empty cell in the Test column, only lab '||
                       'or vital sign tests of the kind stated in the Test column are used to determine whether a subject '||
                       'should be included in the subset. For example, if the domain is LB and lab test is '||
                       'ALBUMIN and variable LBSTRESN must have values from 5 to 10, only subjects with albumin '||
                       'lab test results from 5 to 10 are included in the subset and used in subsequent analysis.';
				output;	

				Row = %let row = %eval(&row. + 1); &row.;
				Height = 12.75;
				Data = "&sl_subset_operator."; StyleID = 'SubHeader'; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Height = 12.75;
				Data = ''; StyleID = ''; output;
			run;

			%markup(ws_&ds._subset_text_data,ws_&ds._subset_text);

			/* make the subseting data table column headers */
			data ws_&ds._subset_cols_data;
				%xml_tag_def;
				%xml_init;

				Type = 'String';
				StyleID = 'ColumnOutline';

				Row = 1;
				Height = 30;
				Data = 'Subset Name'; output;
				Data = 'Domain'; output;
				Data = 'Test'; output;
				Data = 'Variable'; output;
				Data = 'Condition No.'; output;
				Data = 'Value'; output;
				Data = 'Which Conditions Apply?&#10;(AND vs OR)'; output;
			run;

			%markup(ws_&ds._subset_cols_data,ws_&ds._subset_cols);


			/* make a dataset containing the number of rows to merge down for each subseting */
			%gs_rows(ds=subset,varlist=subset_name domain partition var_name);

			/* find the variable numbers */
			proc sql noprint;
				create table sl_fmt_subset_varnum as
				select name, varnum
				from dictionary.columns
				where libname = 'WORK'
				  and memtype = 'DATA'
				  and memname = 'SL_OUT_SUBSET';
			quit;


			/* mark up the subseting data table */
			%annotate(sl_out_subset,ws_&ds._subset_data_note);

			data ws_&ds._subset_data_note;
				set ws_&ds._subset_data_note;

				/* look up row info for merging cells */
				if _n_ = 1 then do;
					declare hash h1(dataset:'sl_fmt_subset');
					h1.definekey('row');
					h1.definedata('subset_name_n','domain_n','partition_n','var_name_n');
					h1.definedone();
				end;

				call missing(subset_name_n,domain_n,partition_n,var_name_n);
				rc = h1.find();
				drop rc;

				/* look up column info */
				if _n_ = 1 then do;
					declare hash h2(dataset:'sl_fmt_subset_varnum(rename=(name=varname))');
					h2.definekey('varname');
					h2.definedata('varnum');
					h2.definedone();
				end;

				call missing(varnum);
				rc = h2.find();
				drop rc;

				/* merge cells down depending on the variable */
				select (varname);
					when ('subset_name','operator') do;
						if subset_name_n ne . then MergeDown = subset_name_n;
					    else delete;
					end;
					when ('domain') do;
						if domain_n ne . then MergeDown = domain_n;
					    else delete;
					end;
					when ('partition_desc') do;
						if partition_n ne . then MergeDown = partition_n;
					    else delete;
					end;
					when ('var_desc','condition') do;
						if var_name_n ne . then MergeDown = var_name_n;
					    else delete;
					end;
					otherwise;
				end;

				lag_varnum = lag(varnum);

				if varnum > 1 and varnum - lag_varnum ne 1 then Index = varnum;

				if varname = 'condition' then StyleID = 'GSC_BTLRB';
				else if varname not in ('var_value') then StyleID = 'GS_BTLRB';
				else do;
					if var_name_n ne . then StyleID = 'GS_BTLR';
					else StyleID = 'GS_BLR';
					if bottom then StyleID = trim(StyleID)||'B';
				end;

			run;

			%markup(ws_&ds._subset_data_note,ws_&ds._subset_data);
			
			data ws_&ds._subset;
				set ws_&ds._subset_text
				    ws_&ds._subset_cols
					ws_&ds._subset_data;
			run;

		%end;
		%else %do;

			%put NO SUBSETTING;

			/* make the section text */
			data ws_&ds._subset_data;
				%xml_tag_def;
				%xml_init;

				Type = 'String';

				%let row = 0;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; StyleID = ''; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = "&sl_subset_desc."; StyleID = 'SubHeader'; output;
			run;

			%markup(ws_&ds._subset_data,ws_&ds._subset);

		%end;

	%end;
	%else %do;

		%put NO GROUPING OR SUBSETTING;

		/* make the section text */
		data ws_&ds._group_data;
			%xml_tag_def;
			%xml_init;

			Type = 'String';

			%let row = 0;

			Row = %let row = %eval(&row. + 1); &row.;
			Data = ''; StyleID = ''; output;

			Row = %let row = %eval(&row. + 1); &row.;
			Data = ''; StyleID = ''; output;

			Row = %let row = %eval(&row. + 1); &row.;
			Data = 'Neither grouping nor subsetting were used'; StyleID = 'SubHeader'; output;
		run;

		%markup(ws_&ds._group_data,ws_&ds._group);

		data ws_&ds._subset;
			length string $&strlen.;
			call missing(string);
		run;

	%end;

	data ws_&ds._settings;
		length string $&strlen.;
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<PageSetup>'; output;
		string = '<Layout x:Orientation="Landscape"/>'; output;
		string = '<Header x:Data="&amp;LGrouping and Subsetting Summary'||
                 '&amp;R'||"NDA/BLA &ndabla.&#10;Study &studyid."||'"/>'; output;
		string = '<Footer x:Data="Page &amp;P of &amp;N"/>'; output;
		string = '</PageSetup>'; output;
		string = '<FitToPage/>'; output;
		string = '<Print>'; output;
		string = '<FitHeight>100</FitHeight>'; output;
		string = '<ValidPrinterInfo/>'; output;
		string = '<Scale>78</Scale>'; output;
		string = '<HorizontalResolution>600</HorizontalResolution>'; output;
		string = '<VerticalResolution>0</VerticalResolution>'; output;
		string = '</Print>'; output;
		string = '</WorksheetOptions>'; output;
	run;

	%put COMBINE AND OUTPUT;

	data ws_&ds.;
		set ws_&ds._start
		    ws_&ds._table_start
			ws_&ds._header 
			ws_&ds._group
			ws_&ds._subset
			ws_&ds._table_end
			ws_&ds._settings
			ws_&ds._end
			;
	run;

	%if &delete_im. = Y %then %do;
		proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;
	%end;

%mend group_subset_xml_out;
