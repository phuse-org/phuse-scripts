%let wbtitle = AE Toxicity Panel;

%global strlen;
%let strlen = 1000;

*%include "&utilpath.\xml_output.sas";


/***************************************/
/* AE TOXICITY COVER SHEET */
/***************************************/
%macro out_cover;

	%let ds = cover;
	%let wstitle = Front Page;

	%let nkeys = 1;
	%let nkeycols = 1;
	%let nvars = 1;

	%ws(&ds.,keycolwidth=50); 

	/* determine how toxicity grades are grouped */
	%if &toxgr_max. = 5 %then %do; 
		%if &toxgr_grp5_sw. = 1 %then %let toxgr_grp_desc = 3, 4, and 5;
		%else %let toxgr_grp_desc = 3 and 4 and separately 5;
	%end;
	%else toxgr_grp_desc = 3 and 4;

	/* determine what toxicity grades were used in the comparison */
	%if &cmpgr. = all %then %let toxgr_cmp_desc = all toxicity grades;
	%else %if not %sysfunc(anyalpha(&cmpgr.)) %then %do;
		%if %length(&cmpgr.) = 1 %then %let toxgr_cmp_desc = toxicity grade &cmpgr.;
		%else %if %length(&cmpgr.) = 2 %then %let toxgr_cmp_desc = toxicity grades %substr(&cmpgr.,1,1) and %substr(&cmpgr.,2,1);
		%else %do; 
			data _null_; length g $50; 
			do i = 1 to %eval(%length(&cmpgr.)-1); 
				g = trim(g)||' '||substr("&cmpgr.",i,1)||','; 
			end;
			g = trim(g)||' and '||substr("&cmpgr.",length("&cmpgr."),1);
			call symputx('toxgr_cmp_desc',compbl('toxicity grades '||g)); 
			run;
		%end;
	%end;

	/* determine how the two-term report was aggregated */
	data _null_;
		set rpt_key;
		where ds = 'pt_3';
		length meddra_key_desc $200;
		do i = 1 to keyvar_cnt;
			meddra_key_desc = trim(meddra_key_desc)||' '||trim(lowcase(scan(key_label,i,',')))||' ('||trim(upcase(scan(key,i)))||')'||ifc(keyvar_cnt>2,', ','')||ifc(i=keyvar_cnt-1,' and ','');
		end;
		meddra_key_desc = compbl(meddra_key_desc);
		call symputx('meddra_key_desc',meddra_key_desc);
	run;

	/* make part 1 of the cover sheet */
	data ws_&ds._1_data; 
		length text $5000;
		text = ''; output;

		text = 'AE Toxicity Panel Front Page'; output;

		text = ''; output;

		text = 'NDA/BLA: '||"&ndabla."; output;
		text = 'Study: '||"&studyid."; output;
		text = "Analysis run date: &rundate."; output;

		text = ''; output;

		%if not &ae_aetoxgr. %then %do;
			text = 'Adverse event toxicity grade (AETOXGR) was not available in the '||
			       "adverse event domain dataset (AE). All adverse events' toxicity grades "||
				   'have been set to missing.'; output;

			text = ''; output;
		%end;

		text = '1: Toxicity Grade Summary'; output;
		text = "This analysis shows how many and what proportion of each arm's subjects "||
               'experienced any adverse event, for all toxicity grades and for toxicity '||
               'grades '||"&toxgr_grp_desc."||'.'; output; 

		text = ''; output;

		text = '2 & 3: Preferred Term Analysis by Toxicity Grade'; output;
		text = 'This analysis lists all adverse events that appeared in the study and '||
               'shows how many and what proportion of subjects experienced each adverse '||
               'event in each arm, for all toxicity grades and for toxicity grades '||
               "&toxgr_grp_desc."||'.'; output;
		text = ''; output;
		text = 'Version 1 of this analysis allows you to sort and filter while version 2 '||
               'is formatted for printing.'; output;

		text = ''; output;

		%if &arm_count. > 1 %then %do;
		text = compbl('4 & 5: Two-Term '||ifc("&meddra."='Y' & &meddra_pct.>80,'MedDRA ','')||'Analysis'); output;
		text = 'This analysis lists all adverse events that appeared in the study '||
		       %if &meddra. = Y & &meddra_pct.>80 %then %do; 'that correspond to MedDRA '||"&meddra_key_desc."||
               ' terms '||%end; 'and shows how many and what proportion of subjects '||
               'experienced each adverse event in the treatment arm, '||"&&&arm_name_&exp."||
               ', and the control arm, '||"&&&arm_name_&ctl."||', for '||"&toxgr_cmp_desc.."; output;
		text = ''; output;
        text = 'This analysis also gives risk differences, relative risks, odds ratios, '||
               'confidence limits for 95% confidence intervals for these statistics, and '||
               'p-values for these adverse events.'; output;
		text = ''; output;
		text = 'Version 1 of this analysis allows you to sort and filter while version 2 '||
               'is formatted for printing.'; output;

		text = ''; output; text = ''; output;

		text = 'Method and Calculations'; output;
		text = 'For all analyses in this report, an adverse event is determined by the body system or '||
               'organ class (AEBODSYS) and dictionary-defined term (AEDECOD) from the '||
               'adverse event (AE) dataset. '||
			   %if &vld_sw. %then %do;
               "Only adverse events with a start date between subjects' "||
               'first exposure and '||%sysfunc(ifc(&study_lag. ne 0,"&study_lag. days after ",''))||
               "subjects' last exposure are included in the analysis. "||
			   'Exposure dates are taken from variables EXSTDTC and EXENDTC in the exposure (EX) dataset; '||
               "if these dates are not available, the subjects' reference start and end dates "||
               '(RFSTDTC and RFENDTC) from the demographics (DM) dataset are used instead. '||
			   %end;
               'Each adverse event is counted only once per subject. Treatment arm is determined '||
               'using the '||ifc(&dm_actarm.,'actual treatment arm (ACTARM)',
                                             'planned treatment arm (ARM)')||' from DM.'; output;
 	
		text = ''; output;

		text = 'The following is a 2x2 contingency table which shows the quantities, '||
               'represented by the letters in the cells, used in the calculation of the '||
               'statistics in this report.'; output;

		text = ''; output;
		%end;
	run;

	%annotate(ws_&ds._1_data,ws_&ds._1_note);

	data ws_&ds._1_note;
		set ws_&ds._1_note;

		if _n_ ne 1 then MergeAcross = 10; MergeDown = .;
		Height = max(1,ceil(length(Data)/110.5)) * 13.5;

		StyleID = 'Default10Wrap';

		if Data = 'AE Toxicity Panel Front Page' then StyleID = 'Header';
		else if Data in ('1: Toxicity Grade Summary'
                         '2 & 3: Preferred Term Analysis by Toxicity Grade'
                         'Method and Calculations') 
		or substr(Data,1,15) = '4 & 5: Two-Term' then StyleID = 'SubHeader';
	run;

	%markup(ws_&ds._1_note,ws_&ds._1); 

	/* make part 2 of the cover sheet, 2x2 contingency table example */
	data ws_&ds._2_note;
		%xml_tag_def;
		%xml_init;

		Type = 'String';
		Height = 25;

		Row = 1;  
		StyleID = '';
		Data = ''; output; Data = ''; output; Data = ''; output; 
		MergeAcross = 1;
		Data = ''; output; 	
		StyleID = 'Table';
		MergeAcross = .; 
		Data = 'Arm 1'; output;
		Data = 'Arm 2'; output;

		Row = 2; 
		StyleID = '';
		Data = ''; output; Data = ''; output; Data = ''; output; 
		StyleID = 'Table';
		MergeAcross = 1;
		Data = 'Adverse event'; output;  
		MergeAcross = .;
		Data = 'a'; output;
		Data = 'c'; output;

		Row = 3;  
		StyleID = '';
		Data = ''; output; Data = ''; output; Data = ''; output; 
		StyleID = 'Table';
		MergeAcross = 1;
		Data = 'No adverse event'; output; 	
		MergeAcross = .;
		Data = 'b'; output;
		Data = 'd'; output;
	run;

	%markup(ws_&ds._2_note,ws_&ds._2); 

	/* determine whether the continuity correction is a whole number */
	%if &cc_sw. = 2 %then %let cc_whole = 0;
    %else %if (&cc_sw. = 1 and %sysevalf(&cc. - %sysfunc(floor(&cc.))) ne 0) %then %let cc_whole = 0;
	%else %let cc_whole = 1;

	/* make part 3 of the cover sheet -- calculation definitions */
	data ws_&ds._3_data;
		length raw $5000;
		raw = ",;
			  ~!~!~!Arm 1,;
			  ~!~!~!AE subject count:,a;
			  ~!~!~!Subject count:,a+b;
			  ~!~!~!AE % (risk):,a / (a+b);"; output; 
		raw = ",;
			  ~!~!~!Arm 2,;
			  ~!~!~!AE subject count:,c;
			  ~!~!~!Subject count:,c+d;
			  ~!~!~!AE % (risk):,c / (c+d);
			  ,;"; output; 
		raw = "~!~!~!AE % (risk) CI:,Clopper-Pearson exact 95% CI from SAS FREQ procedure;
			  ,;
			  ~!~!~!Risk difference:,a/(a+b) - c/(c+d);
			  ~!~!~!Risk difference CI:,Asymptotic 95% CI from SAS FREQ procedure; 
			  ,;"; output; 
		raw = "~!~!~!Relative risk:,(a/(a+b)) / (c/(c+d));
			  ~!~!~!Relative risk CI:,Asymptotic 95% CI from SAS FREQ procedure;"; output;
		%if &cc_sw. = 0 or &cc_whole. = 1 %then %do; 	
		raw = ",;
			  ~!~!~!Odds ratio:,(a/b) / (c/d);
			  ~!~!~!Odds ratio CI:,Exact 95% CI from SAS FREQ procedure;
			  ,;
			  ~!~!~!P-value:,Fisher%str(%')s exact test p-value from SAS FREQ procedure;"; output;
		%end;
		%else %do;
		raw = ",;
			  ~!~!~!Odds ratio:,(a/b) / (c/d);
			  ~!~!~!Odds ratio CI:,Exact 95% CI from SAS FREQ procedure;
			  ~!~!~!,Asymptotic 95% CI from SAS FREQ procedure where continuity correction is used;"; output;
		raw = ",;
			  ~!~!~!P-value:,Fisher%str(%')s exact test p-value from SAS FREQ procedure;"; output;
		%end;
	run;

	data ws_&ds._3_data;
		set ws_&ds._3_data;
		length line $1000 desc $250 calc $250;
		i = 1;
		line = scan(raw,i,';');
		do while (line ne '');
			desc = left(scan(line,1,','));
			calc = left(scan(line,2,','));
			output;
			i = i+1;
			line = compress(scan(raw,i,';'),,'c');
		end;

		if left(trim(desc)) = 'AE % (risk) CI:' and &ae_rate_ci_sw. = 0 then delete;

		keep desc calc;
	run;

	%annotate(ws_&ds._3_data,ws_&ds._3_note);

	data ws_&ds._3_note;
		set ws_&ds._3_note;
		if varname = 'desc' then MergeAcross = 1;
	run;

	%markup(ws_&ds._3_note,ws_&ds._3); 

	/* make a note about continuity correction */
	data ws_&ds._cc_data;
		length text $5000;

		length cc $50;
		select (&cc_sw.);
			when (1) cc = "&cc.";
			when (2) cc = 'the reciprocal of the opposite arm subject count';
			otherwise cc = 'no continuity correction';
		end;

		if (cc ne 'no continuity correction') then do;
			text = ''; output; 

			text = 'For terms where either arm had a zero cell count, a continuity correction '||
                   'of '||cc||' has been added to the quantities in each cell of the contingency table  '||
                   'before calculating odds ratio and relative risk. This avoids undefined values '||
                   'that would result when dividing by zero. Use caution with these results, since '||
                   'different continuity corrections yield different results and a notable odds ratio or '||
                   'relative risk statistic may only be an artifact of the correction used.'; 
			text = compbl(text); output; 
		end;

		keep text;
	run;

	%annotate(ws_&ds._cc_data,ws_&ds._cc_note);

	data ws_&ds._cc_note;
		set ws_&ds._cc_note;

		MergeAcross = 10; MergeDown = .;
		Height = max(1,ceil(length(Data)/115)) * 13.5;

		StyleID = 'Default10Wrap';
	run;

	%markup(ws_&ds._cc_note,ws_&ds._cc); 

	/* make part 4 of the cover sheet */
	data ws_&ds._4_data;
		length desc $250 setting $250;

		desc = ''; setting = ''; output; desc = ''; setting = ''; output;

		desc = 'Report Settings'; output;

		desc = '~!~!~!NDA/BLA:'; setting = "&ndabla."; output;
		desc = '~!~!~!Study:'; setting = "&studyid."; output;
		desc = '~!~!~!Analysis run date:'; setting = "&rundate."; output;

		desc = ''; setting = ''; output;

		desc = '~!~!~!Custom datasets:'; setting = ifc("&sl_custom_ds." ne '',"&sl_custom_ds.",'None'); output;
		desc = '~!~!~!Grouping/subsetting:'; setting = ifc("&sl_gs_desc." ne '',"&sl_gs_desc.",'None'); output;
		%if &sl_group_nobs. or &sl_subset_nobs. %then %do;
			desc = ''; setting = 'For more information, see the Grouping and Subsetting tab '||
                                 'at the end of this workbook'; output;
		%end;

		desc = ''; setting = ''; output;

		desc = '~!~!~!Study analysis period: '; %if &vld_sw. %then %do;
												setting = "Subject first exposure date to last exposure date"||
                                                          ifc(&study_lag.>0," + &study_lag. days",''); output;
												%end;
												%else %do;
												setting = 'Necessary date variables were not available; '||
												          'all adverse events used in analysis'; output;
												%end;
		/*desc = '~!~!~!Toxicity grades:'; setting = "&toxgr_min. to &toxgr_max."; output;*/
		if &toxgr_max. >= 5 then do;
			desc = '~!~!~!Tox. grade grouping:'; setting = "&toxgr_grp_desc."; output;
		end;

		desc = ''; setting = ''; output;

		%if &arm_count. > 1 %then %do;
		desc = '~!~!~!Two-Term '||ifc("&meddra."='Y' & &meddra_pct.>80,'MedDRA ','')||'Analysis'; setting = ''; output;
		desc = '~!~!~!Treatment arm: '; setting = "&&&arm_name_&exp."; output;	
		desc = '~!~!~!Control arm: '; setting = "&&&arm_name_&ctl."; output;
		desc = '~!~!~!MedDRA version: '; setting = "&ver."; output;
		desc = '~!~!~!Comparison terms:'; setting = upcase(substr("&meddra_key_desc.",1,1))||substr("&meddra_key_desc.",2); output;
		desc = '~!~!~!Comparison grades:'; setting = upcase(substr("&toxgr_cmp_desc.",1,1))||substr("&toxgr_cmp_desc.",2); output;
		desc = '~!~!~!Continuity correction:'; select (&cc_sw.);
												when (1) setting = "&cc.";
												when (2) setting = 'The reciprocal of the opposite arm subject count';
												otherwise setting = 'No continuity correction';
											   end;	output;
		desc = '~!~!~!Sorted by: '; dsid = open('pt_3_output');
									label = varlabel(dsid,varnum(dsid,"&cmpsort."));
									label = upcase(substr(label,1,1))||lowcase(substr(label,2));
									if indexw(label,'cl') then substr(label,indexw(label,'cl'),2) = 'CL';
									rc = close(dsid);
									setting = label; output;
		drop dsid label rc;

		desc = ''; setting = ''; output;
		%end;

		desc = ''; setting = ''; output;

		desc = 'Note that for cross-over studies, the analysis by arm in this report '||
               'can only be used to examine treatment sequences and not individual treatments.'; output;
	run; 

	%annotate(ws_&ds._4_data,ws_&ds._4_note);

	data ws_&ds._4_note;
		set ws_&ds._4_note;

		if varname = 'desc' then MergeAcross = 1;
		if varname = 'desc' and Data = '~!~!~!Two-Term '||ifc("&meddra."='Y','MedDRA ','')||'Analysis'
			then MergeAcross = 2;

		if Data in ('Report Settings') then StyleID = 'SubHeader';
		else if bottom then do; StyleID = 'Default10RedWrap'; MergeAcross = 10; Height = 40.5; end;
	run;

	%markup(ws_&ds._4_note,ws_&ds._4); 

	/* define the print area */
	data ws_&ds._names;
		length string $&strlen.; 

		string = '<Names>'; output;
		string = '<NamedRange ss:Name="Print_Area" ss:RefersTo="='||"'Front Page'"||'!R1C1:R85C11"/>'; output;
		string = '</Names>'; output;
	run;

	/* set up the worksheet settings */
	data ws_&ds._settings; 
		length string $&strlen.; 
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<PageSetup>'; output;
		string = '<Header x:Data="&amp;L'||'AE Toxicity Panel Front Page'||
                 '&amp;R'||"NDA/BLA &ndabla.&#10;Study &studyid."||'"/>'; output;
		string = '<Footer x:Data="Page &amp;P of &amp;N"/>'; output;
		string = '</PageSetup>'; output;
		string = '<Print>'; output;
		string = '<ValidPrinterInfo/>'; output;
		string = '<Scale>95</Scale>'; output;
		string = '<HorizontalResolution>600</HorizontalResolution>'; output;
		string = '<VerticalResolution>0</VerticalResolution>'; output;
		string = '</Print>'; output;
		string = '</WorksheetOptions>'; output;
	run;

	data ws_&ds.;
		set ws_&ds._start
			ws_&ds._names
		    ws_&ds._table_start
			ws_&ds._1
			%if &arm_count. > 1 %then %do;
				ws_&ds._2 
				ws_&ds._3
				ws_&ds._cc
			%end;
			ws_&ds._4
			ws_&ds._table_end
			ws_&ds._settings
			ws_&ds._end;
	run;

	proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;

%mend out_cover;


/**************************/
/* TOXICITY GRADE SUMMARY */
/**************************/
%macro out_pt_1(fmt=N);

	%let ds = pt_1_output;
	%let wstitle = 1 Toxicity Grade Summary;

	/* get number of variables, observations, and by variables */
	%let dsid = %sysfunc(open(&ds.));
	%let nobs = %sysfunc(attrn(&dsid.,nobs));
	%let nvars = %sysfunc(attrn(&dsid.,nvars));
	%let rc = %sysfunc(close(&dsid.));

	proc sql noprint;
		select put(keyvar_cnt,8. -L),
               ifc("&fmt." = 'N',put(keyvar_cnt,8. -L),put(keyvar_cnt-1,8. -L)) 
               into : nkeys, : nkeycols
		from rpt_key	
		where upcase(substr(  ds ,1,min(length(trim(ds)),length(trim("&ds")))))
            = upcase(substr("&ds",1,min(length(trim(ds)),length(trim("&ds")))));
	quit;

	/* make the header */
	data ws_&ds._header_data;
		%xml_tag_def;
		%xml_init;

		Type = 'String';

		%let row = 0;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
		
		Row = %let row = %eval(&row. + 1); &row.;
		StyleID = 'Header'; 
		Data = 'Toxicity Grade Summary';
		output;

		/* store the title for future use */
		call symputx('wstitle_long',Data);

		%if (&sl_group_nobs. or &sl_subset_nobs.) %then %do;
			Row = %let row = %eval(&row. + 1); &row.;
			Data = "&sl_gs_desc."; StyleID = 'Default10'; output;
		%end;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;

		StyleID = 'Default8'; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = "NDA/BLA: &ndabla."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Study: &studyid."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Analysis run date: &rundate."; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;

		StyleID = 'Default10Wrap'; MergeAcross = 8;

		Row = %let row = %eval(&row. + 1); &row.;
		Height = 30;
		Data = 'Where subject count is the number of subjects experiencing at least one adverse event '|| 
               'at the stated toxicity grade using the maximum toxicity grade per subject';
		output;

		Row = %let row = %eval(&row. + 1); &row.;
		Height = 12.75;
		Data = ''; StyleID = ''; output;
	run;

	%markup(ws_&ds._header_data,ws_&ds._header);

	/* find whether this dataset had any missing toxicity grades */
	data _null_;
		set rpt_missing;
		where upcase(substr(  ds ,1,min(length(trim(ds)),length(trim("&ds")))))
            = upcase(substr("&ds",1,min(length(trim(ds)),length(trim("&ds")))));
		if not (%do i = 1 %to &arm_count.;
					arm&i._toxgr_missing = 0 and
		        %end;
				1=1
			   ) then missing = 1;
		else missing = 0;
		call symputx('missing',missing);
	run;
	%if not %symexist(missing) %then %let missing = 0;

	data ws_&ds._footer_data; 
		retain group;
		length data $1000;

		group = 'note';
		data = 'NOTES:'; output;
		data = '1 This analysis uses the safety population '||
		       %if &vld_sw. %then %do;
               "and only counts adverse events that start between a subject's first exposure and "||
               ifc(&study_lag.>0,"&study_lag. days after the subject's ",'')||'last exposure'||
			   %end;
               ''; output;
		%if &missing. %then %do;
			data = '2 Subjects whose adverse events were missing toxicity grades have been included '||
			       'in the All Grades subject counts; '||
	               'see the Data Check Summary tab for details'; output;
		%end;
	run;

	%ws(&ds.); 
	%wsheader(ws_&ds._footer_data,ws_&ds._footer);
	%wscolumns(&ds.);


	/**************/
	/* data table */
	/**************/
	%annotate(&ds.,ws_&ds._data_note);

	/* add style information for markup */
	data ws_&ds._data_note;
		merge ws_&ds._data_note(in=a);
		by row;

		if Type = 'Number' and Data in ('' 'I') then do;
			Type = 'String';
			Data = '.';
		end;

		/* apply styles */
			if varname = 'total' then StyleID = 'D_BLR';
			else if index(varname,'pct') then StyleID = 'D1_R1_BR';
			else StyleID = 'D0_R2_B';

		if bottom then StyleID = trim(StyleID)||'B';
	run;

	%markup(ws_&ds._data_note,ws_&ds._data);


	data ws_&ds._settings;
		length string $&strlen.; 
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<PageSetup>'; output;
		string = '<Layout x:Orientation="Landscape"/>'; output;
		string = '<Header x:Data="&amp;L'||"&wstitle_long."||
                 '&amp;R'||"NDA/BLA &ndabla.&#10;Study &studyid."||'"/>'; output;
		string = '<Footer x:Data="Page &amp;P of &amp;N"/>'; output;
		string = '</PageSetup>'; output;
		string = '<FitToPage/>'; output;
		string = '<Print>'; output;
        string = '<FitHeight>100</FitHeight>'; output;
       	string = '</Print>'; output;
		string = '</WorksheetOptions>'; output;
	run;


	data ws_&ds.;
		set ws_&ds._start
		    ws_&ds._table_start
			ws_&ds._header
		    ws_&ds._columns
			ws_&ds._data 
			ws_&ds._footer
			ws_&ds._table_end
			ws_&ds._settings
			ws_&ds._end;
	run; 

	proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;

%mend out_pt_1;

/*********************************/
/* PT ANALYSIS BY TOXICITY GRADE */
/*********************************/
/* fmt = Y/N controls whether to make output for the formatted sheet */
%macro out_pt_2(fmt=N);

	%if &fmt. = N %then
		%let ds = pt_2_output; 
	%else %if &fmt. = Y %then
		%let ds = pt_2_output_fmt; 
	%let wstitle = %sysfunc(ifc(&fmt.=N,2,3)) PT Analysis by Tox. Grade V%sysfunc(ifc(&fmt.=N,1,2));

	/* get number of variables, observations, and by variables */
	%let dsid = %sysfunc(open(&ds.));
	%let nobs = %sysfunc(attrn(&dsid.,nobs));
	%let nvars = %sysfunc(attrn(&dsid.,nvars));
	%let rc = %sysfunc(close(&dsid.));

	proc sql noprint;
		select put(keyvar_cnt,8. -L),
               ifc("&fmt." = 'N',put(keyvar_cnt,8. -L),put(keyvar_cnt-1,8. -L)) 
               into : nkeys, : nkeycols
		from rpt_key	
		where upcase(substr(  ds ,1,min(length(trim(ds)),length(trim("&ds")))))
            = upcase(substr("&ds",1,min(length(trim(ds)),length(trim("&ds")))));
	quit;

	/* make the header */
	data ws_&ds._header_data;
		%xml_tag_def;
		%xml_init;

		Type = 'String';

		%let row = 0;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
		
		Row = %let row = %eval(&row. + 1); &row.;
		StyleID = 'Header'; 
		Data = 'Preferred Term Analysis by Toxicity Grade';
		output;

		/* store the title for future use */
		call symputx('wstitle_long',Data);

		%if (&sl_group_nobs. or &sl_subset_nobs.) %then %do;
			Row = %let row = %eval(&row. + 1); &row.;
			Data = "&sl_gs_desc."; StyleID = 'Default10'; output;
		%end;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;

		StyleID = 'Default8'; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = "NDA/BLA: &ndabla."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Study: &studyid."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Analysis run date: &rundate."; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;

		StyleID = 'Default10Wrap'; MergeAcross = ifn("&fmt."='Y',8,5);

		Row = %let row = %eval(&row. + 1); &row.;
		Height = 30;
		Data = 'Where subject count is the number of subjects experiencing at least one adverse event '|| 
               'at the stated toxicity grade using the maximum toxicity grade per subject, organ class, and term';
		output;

		Row = %let row = %eval(&row. + 1); &row.;
		Height = 12.75;
		Data = ''; StyleID = ''; output;
	run;

	%markup(ws_&ds._header_data,ws_&ds._header);

	/* find whether this dataset had any missing toxicity grades */
	data _null_;
		set rpt_missing;
		where upcase(substr(  ds ,1,min(length(trim(ds)),length(trim("&ds")))))
            = upcase(substr("&ds",1,min(length(trim(ds)),length(trim("&ds")))));
		if not (%do i = 1 %to &arm_count.;
					arm&i._toxgr_missing = 0 and
		        %end;
				1=1
			   ) then missing = 1;
		else missing = 0;
		call symputx('missing',missing);
	run;
	%if not %symexist(missing) %then %let missing = 0;

	/* make the footer */
	/* include a note about missing toxicity grades if there were any */
	data ws_&ds._footer_data; 
		retain group;
		length data $1000;

		group = 'note';
		data = 'NOTES:'; output;
		data = '1 This analysis uses the safety population '||
		       %if &vld_sw. %then %do;
               "and only counts adverse events that start between a subject's first exposure and "||
               ifc(&study_lag.>0,"&study_lag. days after the subject's ",'')||'last exposure'||
			   %end;
               ''; output;
		%if &missing. %then %do;
			data = '2 Subjects whose adverse events were missing toxicity grades have been included '||
			       'in the All Grades subject counts; '||
	               'see the Data Check Summary tab for details'; output;
		%end;
	run; 

	%ws(&ds.); 
	%wsheader(ws_&ds._footer_data,ws_&ds._footer);
	%wscolumns(&ds.);


	/**************/
	/* data table */
	/**************/
	%annotate(&ds.,ws_&ds._data_note);

	/* header row indicator */
	%if &fmt. = Y %then %do;
		data &ds._ind;
			set &ds._ind;
			row = _n_;
		run;
	%end;
	%else %do;
		data &ds._ind;
			do row = 1 to &nobs.;
				header = 0; output;
			end;
		run;
	%end;

	/* combine header row indicator with annotated data */
	/* add style information for markup */
	data ws_&ds._data_note;
		merge ws_&ds._data_note(in=a) &ds._ind(in=b);
		by row;

		%if &fmt. = Y %then %do;
			if header then do;
				if first.row then do;
					Height = 18;
					MergeAcross = %eval(&nvars.-1);
					StyleID = 'DataHeader';
				end;
				else delete;
			end;
			else do;
				if varname = 'adverse_event' then Data = '~!~!~!~!~!'||Data;
			end;
		%end;

		if Type = 'Number' and Data in ('' 'I') then do;
			Type = 'String';
			Data = '.';
		end;

		/* apply styles */
		if not header then do;
			if ("&fmt." = 'Y' and varname = 'adverse_event') 
			   or varname in ('aebodsys' 'aedecod') then StyleID = 'D_BLR';
			else if index(varname,'pct') then StyleID = 'D1_R1_BR';
			else StyleID = 'D0_R2_B';
		end;

		if bottom then StyleID = trim(StyleID)||'B';
	run;

	%markup(ws_&ds._data_note,ws_&ds._data);

	/* remove created header row indicator */
	%if &fmt. ne Y %then %do; proc datasets library=work nolist nodetails; delete &ds._ind; quit; %end;


	/* get the row numbers for the first and last data rows */
	data _null_;
		set ws_&ds._header ws_&ds._columns end=eof;
		retain count;
		if string in ('<Row/>' '</Row>') then count + 1;
		if eof then do;
			firstrow = count + 1;
			lastrow =  firstrow + &nobs. - 1;
			call symputx('firstrow',put(firstrow,8. -L));
			call symputx('lastrow',put(lastrow,8. -L));
		end;
	run;

	/* set up named ranges */
	/* right now, there is only one named range */
	/* which is for repeating column headers when printing */
	data ws_&ds._names;
		length string $&strlen.; 
		string = '<Names>'; output;
		string = '<NamedRange ss:Name="Print_Titles" '||
                 'ss:RefersTo="='||"'"||"&wstitle."||"'!R"||
                  compress(%eval(&firstrow.-1))||':R'||compress(%eval(&firstrow.-3))||'"/>'; output;
		string = '</Names>'; output;
	run; 

	/* determine whether first row is even or odd */
	%let fr_odd = %sysfunc(mod(&firstrow.,2));

	/* set up the worksheet settings for conditional formatting and autofilter*/
	data ws_&ds._settings; 
		length string $&strlen.; 
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;

		string = '<PageSetup>'; output;
		string = '<Layout x:Orientation="Landscape"/>'; output;
		string = '<Header x:Data="&amp;L'||"&wstitle_long."||
                 '&amp;R'||"NDA/BLA &ndabla.&#10;Study &studyid."||'"/>'; output;
		string = '<Footer x:Data="Page &amp;P of &amp;N"/>'; output;
		string = '</PageSetup>'; output;
		string = '<FitToPage/>'; output;
		string = '<Print>'; output;
        string = '<FitHeight>100</FitHeight>'; output;
       	string = '</Print>'; output; 

		/* frozen panes settings */
		string = '<Selected/>'; output;
       	string = '<FreezePanes/>'; output;
       	string = '<FrozenNoSplit/>'; output;
       	string = '<SplitHorizontal>'||compress(%eval(&firstrow.-1))||'</SplitHorizontal>'; output;
       	string = '<TopRowBottomPane>'||compress(%eval(&firstrow.-1))||'</TopRowBottomPane>'; output;
		string = '<ActivePane>2</ActivePane>'; output;

		/* selected cell */
		string = '<Panes>'; output;
		string = '<Pane>'; output;
		string = '<Number>2</Number>'; output;
		string = '<ActiveRow>0</ActiveRow>'; output;
		string = '</Pane>'; output;
		string = '</Panes>'; output;

		string = '</WorksheetOptions>'; output;

		%if &fmt. = N %then %do;
			string = '<AutoFilter x:Range="'||'R'||compress(%eval(&firstrow.-1))||'C1:R'||
                     compress(%eval(&firstrow.-1))||"C&nvars."||'" '||
                     'xmlns="urn:schemas-microsoft-com:office:excel">'; output;
			string = '</AutoFilter>'; output;
			string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
			string = "<Range>R&firstrow.C1:R&lastrow.C&nvars.</Range>"; output;
			string = '<Condition>'; output;
			string = "<Value1>MOD(SUBTOTAL(103,RC1:R2C1),2)=&fr_odd.</Value1>"; output;
			string = "<Format Style='background:silver'/>"; output;
			string = '</Condition>'; output;
			string = '</ConditionalFormatting>'; output;
		%end;
	run;

	data ws_&ds.;
		set ws_&ds._start
			ws_&ds._names
		    ws_&ds._table_start
			ws_&ds._header
		    ws_&ds._columns
			ws_&ds._data 
			ws_&ds._footer
			ws_&ds._table_end
			ws_&ds._settings
			ws_&ds._end;
	run;

	proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;

%mend out_pt_2;


/*****************************************/
/* ADVERSE EVENTS N-TERM MEDDRA ANALYSIS */
/*****************************************/
/* fmt = Y/N controls whether to make output for the formatted sheet */
%macro out_pt_3(fmt=N);

	%if &fmt. = N %then %do;
		%let ds = pt_3_output; 	
		%let ds_unfmt = pt_3_output; 
	%end;
	%else %if &fmt. = Y %then %do; 
		%let ds = pt_3_output_fmt; 
		%let ds_unfmt = pt_3_output; 
	%end;

	/* get number of variables and observations */
	%let dsid = %sysfunc(open(&ds.));
	%let nobs = %sysfunc(attrn(&dsid.,nobs));
	%let nvars = %sysfunc(attrn(&dsid.,nvars));
	%let rc = %sysfunc(close(&dsid.));

	/* get number of keys, number of key columns, and list of key variables */ 
	proc sql noprint;
		select put(keyvar_cnt,8. -L),
               ifc("&fmt." = 'N',put(keyvar_cnt,8. -L),'1'),
               report, 
			   "'"||tranwrd(key,' ',"' '")||"'",
               key_label 
               into : nkeys, : nkeycols, : report, : key, : key_label
		from rpt_key
		where upcase(substr(  ds ,1,min(length(trim(ds)),length(trim("&ds")))))
            = upcase(substr("&ds",1,min(length(trim(ds)),length(trim("&ds")))));
	quit;
	
	/* worksheet tab name */
	%let wstitle = %sysfunc(compbl(%sysfunc(ifc(&fmt.=N,4,5)) &report. V%sysfunc(ifc(&fmt.=N,1,2))));

	/* make character string of the key variable labels */
	data _null_;
		length key_label $100;
		key_label = "&key_label.";
		nkeys = &nkeys.;
		if nkeys = 1 then key_subtitle = key_label;
		else do;
			/* position of the last comma */
			pos = length(trim(left(key_label))) - index(reverse(trim(left(key_label))),',') + 1;
			/* add an and after the last comma */
			key_subtitle = compbl(substr(key_label,1,pos)||' and '||substr(key_label,pos+1));
		end;
		key_title = ifc(nkeys=2,compress(key_subtitle,','),key_subtitle);	
		call symputx('key_title',key_title);
		call symputx('key_subtitle',key_subtitle);
	run;

	/* make the comparison variable label and comparison variable suffix */
	data _null_;
		length cmpvar$12 cmplabel $12;
		cmpgr = "&cmpgr.";
		if cmpgr = 'all' then do; cmplabel = 'All Grades'; cmpvar = 'all'; end;
		else if not anyalpha(cmpgr) then do;
			if length(cmpgr) > 1 then do;
				do i = 1 to length(cmpgr);
					if i = length(cmpgr) then cmplabel = trim(left(cmplabel))||substr(cmpgr,i,1);
					else cmplabel = trim(left(cmplabel))||substr(cmpgr,i,1)||'/';
					if i = length(cmpgr) then cmplabel = 'Grades '||cmplabel;
				end;
				cmpvar = "grp&cmpgr.";
			end;
			else do; cmplabel = 'Grade '||cmpgr;	cmpvar = "toxgr&cmpgr."; end;
		end; 
		call symputx('cmplabel',cmplabel);
		call symputx('cmpvar',cmpvar);
	run;

	/* make sort variable label */
	proc sql noprint;
		select label into: sortlabel
		from sashelp.vcolumn
		where libname = 'WORK' and memname=upcase("&ds.") and upcase(name)=upcase("&cmpsort.");
	quit;

	/* make the header */
	data ws_&ds._header_data;
		%xml_tag_def;
		%xml_init;

		Type = 'String';

		%let row = 0;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
		
		Row = %let row = %eval(&row. + 1); &row.;
		StyleID = 'Header'; 
		Data = "Adverse Events &report."; output;

		call symputx('wstitle1_long',Data);
		
		Row = %let row = %eval(&row. + 1); &row.;
        Data = "by &key_title."
			   %if &fmt. = Y %then %do; ||'; Sorted by '||"&sortlabel." %end;
               ; output;

		call symputx('wstitle2_long',Data);

		%if (&sl_group_nobs. or &sl_subset_nobs.) %then %do;
			Row = %let row = %eval(&row. + 1); &row.;
			Data = "&sl_gs_desc."; StyleID = 'Default10'; output;
		%end;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;

		StyleID = 'Default8'; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = "NDA/BLA: &ndabla."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Study: &studyid."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Analysis run date: &rundate."; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;

		StyleID = 'Default10Wrap'; MergeAcross = ifn("&fmt."='Y',8,5);

		Row = %let row = %eval(&row. + 1); &row.;
		Height = 30;
		Data = 'Where subject count is the number of subjects experiencing at least one adverse event '|| 
               'at the stated toxicity grade using the maximum toxicity grade per subject'||
                ifc(&nkeys.=1,' and '||lowcase("&key_subtitle."),', '||lowcase("&key_subtitle."));
		output;

		Row = %let row = %eval(&row. + 1); &row.;
		Height = 12.75;
		Data = ''; StyleID = ''; output;
	run;

	%markup(ws_&ds._header_data,ws_&ds._header);

	/* find whether this dataset had any missing toxicity grades */
	data _null_;
		set rpt_missing;
		where upcase(substr(  ds ,1,min(length(trim(ds)),length(trim("&ds")))))
            = upcase(substr("&ds",1,min(length(trim(ds)),length(trim("&ds")))));
		if not (arm&exp._toxgr_missing = 0 and arm&ctl._toxgr_missing = 0) then missing = 1;
		else missing = 0;
		call symputx('missing',missing);
	run;
	%if not %symexist(missing) %then %let missing = 0;

	/* make the footer */
	/* include a note about missing toxicity grades if there were any */
	data ws_&ds._footer_data; 
		retain group;
		length data $1000;

		group = 'note';
		data = 'NOTES:'; output; 
		data = '1 This report is for data exploration only and should not be used for '||
               'statistical inference'; output;	
		data = '2 This analysis uses the safety population '||
		       %if &vld_sw. %then %do;
               "and only counts adverse events that start between a subject's first exposure and "||
               ifc(&study_lag.>0,"&study_lag. days after the subject's ",'')||'last exposure'||
			   %end;
               ''; output;
			   
		%let note_cnt = 2;

		%if &cmpgr. = all and &missing. %then %do;
			%let note_cnt = %eval(&note_cnt. + 1);
			data = "&note_cnt. Subjects whose adverse events were missing toxicity grades have been included "||
			       'in the All Grades subject counts; '||
	               'see the Data Check Summary tab for details'; output;
		%end; 

		%let note_cnt = %eval(&note_cnt. + 1);
		data = "&note_cnt. Confidence limits are for 95% confidence intervals"; output;

		%let note_cnt = %eval(&note_cnt. + 1);
		data = "&note_cnt. On rare occasions, Fisher's exact test p-values may not match the confidence "||
               'interval for risk difference, relative risk, or odds ratio because they are the results of '||
               'different tests'; output;

		%if (&cc_sw. ne 0) %then %do;
			data = '* Relative risk and odds ratio for the indicated term have been calculated after '||
	               'adjusting subject counts with a continuity correction of '||
	               ifc(&cc_sw.=2,'the reciprocal of the opposite arm subject count ',"&cc. ")||
	               'to avoid dividing by zero'; output;
			data = '* Use caution with these results, since different continuity corrections yield different '||
                   'results and a notable odds ratio or relative risk statistic may only be an artifact of '||
                   'the correction used'; output;
		%end;
	run; 

	%ws(&ds.); 
	%wsheader(ws_&ds._footer_data,ws_&ds._footer);
	

	/* find variable numbers of the pct columns */
	proc sql noprint;
		select varnum into: pct_cols separated by ' '
		from dictionary.columns
		where libname = 'WORK' 
		and memname = upcase("&ds.")
		and upcase(reverse(substr(left(reverse(name)),1,3))) = 'PCT';
	quit;

	data ws_&ds._table_start; 
		length string $&strlen.; 
		string = '<Table>'; output;
		%do i = 1 %to &nvars.; 
			%if &i. <= &nkeycols. %then %do;
				string = '<Column ss:Width="200"/>'; output;
			%end;
			%else %if &i. in (&pct_cols.) %then %do;
				string = '<Column ss:Width="37"/>'; output;
			%end;
			%else %do;
				string = '<Column ss:Width="55"/>'; output;
			%end;
		%end;
	run;

	/* open dataset to extract column numbers for variables */
	%let dsid = %sysfunc(open(&ds.));

	/* column headers */
	data ws_&ds._columns_data;
		retain Row;
		%xml_tag_def;
		%xml_init;

		StyleID = 'ColumnOutline';
		Type='String';

		/* row 1 */
		Row = 1;
		Height = %if &ae_rate_ci_sw. = 1 %then 52.5;
		         %else 2*13.75 + max(1,round(&max_arm_nm_len./13.25,1))*13.75;
				 ;
		do i = 1 to &nkeycols.;
			%if &fmt.=Y %then %do;
		        Data = 'Adverse Event'; 
			%end;
			%else %do; 
	            Data = left(scan("&key_label.",i,',')); 
            %end;
			MergeDown = 2;
			output;
		end;
		MergeAcross = %if &ae_rate_ci_sw. = 1 %then 3; %else 1;; MergeDown = .;
		Data = 'Treatment:&#10;'||"&&&arm_name_&exp.&#10;N="||trim(put(&&&arm_&exp.,comma7. -L)); output;
		Data = 'Control:&#10;'||"&&&arm_name_&ctl.&#10;N="||trim(put(&&&arm_&ctl.,comma7. -L)); output;
		MergeAcross = 2; MergeDown = .;	
		Data = 'Risk Difference'; output;
		MergeAcross = 2; MergeDown = .;
		Data = 'Relative Risk'; output;
		MergeAcross = 2; MergeDown = .;
		Data = 'Odds Ratio'; output;
		MergeAcross = .; MergeDown = 2;	
		Data = 'P-value'; varname = 'p_value'; output;
		MergeAcross = .; MergeDown = .;	varname = '';

		/* row 2 */
		Row = 2;
		Height = 15.75;
		Index = %eval(&nkeycols.+1);
		MergeAcross = %if &ae_rate_ci_sw. = 1 %then 3; %else 1;; MergeDown = .;
		Data = "&cmplabel."; output;
		Index = .;
		Data = "&cmplabel."; output;

		Index = %sysfunc(varnum(&dsid.,rd)); MergeAcross = .; MergeDown = 1; 
		Data = 'Risk Difference'; varname = 'rd'; output;
		Index = .;
		MergeAcross = 1; MergeDown = .;
		Data = 'Confidence Interval'; varname = ''; output;

		Index = %sysfunc(varnum(&dsid.,rr)); MergeAcross = .; MergeDown = 1; 
		Data = 'Relative Risk'; varname = 'rr'; output;
		Index = .;
		MergeAcross = 1; MergeDown = .;
		Data = 'Confidence Interval'; varname = ''; output;

		Index = %sysfunc(varnum(&dsid.,ort)); MergeAcross = .; MergeDown = 1; 
		Data = 'Odds Ratio'; varname = 'ort'; output;
		Index = .;
		MergeAcross = 1; MergeDown = .;
		Data = 'Confidence Interval'; varname = ''; output;	
		MergeDown = .; MergeAcross = .;	Index = .;

		/* row 3 */
		Row = 3;
		Height = 30;
		Index = %eval(&nkeycols.+1);
		Data = 'Subject Count'; varname = "arm&exp._&cmpvar."; output;
		Index = .;
		Data = '%'; varname = "arm&exp._&cmpvar._pct"; output;
		%if &ae_rate_ci_sw. = 1 %then %do;
		Data = %if &fmt.=Y %then '%&#10;Lower CL'; %else '% Lower CL';; varname = "arm&exp._&cmpvar._pct_cilb"; output;
		Data = %if &fmt.=Y %then '%&#10;Upper CL'; %else '% Upper CL';; varname = "arm&exp._&cmpvar._pct_ciub"; output;
		%end;
		Data = 'Subject Count'; varname = "arm&ctl._&cmpvar."; output;
		Data = '%'; varname = "arm&ctl._&cmpvar._pct"; output; 
		%if &ae_rate_ci_sw. = 1 %then %do;
		Data = %if &fmt.=Y %then '%&#10;Lower CL'; %else '% Lower CL';; varname = "arm&ctl._&cmpvar._pct_cilb"; output;
		Data = %if &fmt.=Y %then '%&#10;Upper CL'; %else '% Upper CL';; varname = "arm&ctl._&cmpvar._pct_ciub"; output;
		%end;
		Index = %sysfunc(varnum(&dsid.,rd_cilb));
		Data = %if &fmt.=Y %then 'Lower CL'; %else 'Lower&#10;CL';; varname = 'rd_cilb'; output;
		Index = .;
		Data = %if &fmt.=Y %then 'Upper CL'; %else 'Upper&#10;CL';; varname = 'rd_ciub'; output;
		Index = %sysfunc(varnum(&dsid.,rr_cilb));
		Data = %if &fmt.=Y %then 'Lower CL'; %else 'Lower&#10;CL';; varname = 'rr_cilb'; output;
		Index = .;
		Data = %if &fmt.=Y %then 'Upper CL'; %else 'Upper&#10;CL';; varname = 'rr_ciub'; output;
		Index = %sysfunc(varnum(&dsid.,or_cilb));
		Data = %if &fmt.=Y %then 'Lower CL'; %else 'Lower&#10;CL';; varname = 'or_cilb'; output;
		Index = .;
		Data = %if &fmt.=Y %then 'Upper CL'; %else 'Upper&#10;CL';; varname = 'or_ciub'; output;
		
		drop i;
	run;

	%let rc = %sysfunc(close(&dsid.));

	/* go over column header data and change some settings */
	/* depending on whether the formatted output is being made */
	data ws_&ds._columns_data;
		set ws_&ds._columns_data;
		%if &fmt. = Y %then %do;
			if varname = "&cmpsort." then StyleID = trim(StyleID)||'Italic';
		%end;
	run;

	%markup(ws_&ds._columns_data,ws_&ds._columns);


	/**************/
	/* data table */
	/**************/
	%annotate(&ds.,ws_&ds._data_note);

	/* header row indicator */
	%if &fmt. = Y %then %do;
		data &ds._ind;
			set &ds._ind;
			row = _n_;
		run;
	%end;
	%else %do;
		data &ds._ind;
			do row = 1 to &nobs.;
				header = 0; output;
			end;
		run;
	%end;

	/* combine header row indicator with annotated data */
	/* add style information for markup */
	data ws_&ds._data_note;
		merge ws_&ds._data_note(in=a) &ds._ind(in=b) %if &cc_sw. ne 0 %then &ds._cc_ind;;
		by row;

		%if &fmt. = Y %then %do;
			if header then do;
				if first.row then do;
					Height = 18;
					MergeAcross = %eval(&nvars.-1);
					StyleID = 'DataHeader';
				end;
				else delete;
			end;
			else do;
				if varname = 'adverse_event' then Data = '~!~!~!~!~!'||Data;
			end;
		%end;

		if Type = 'Number' and Data in ('' 'I') then do;
			Type = 'String';
			Data = '.';
		end;

		/* apply styles */
		if not header then do;
			if ("&fmt." = 'Y' and varname = 'adverse_event') or varname in (&key.) then StyleID = 'D_BLR';
			else if varname in ("arm&exp._&cmpvar." "arm&ctl._&cmpvar.") then StyleID = 'D0_R2_BL';
			else if varname in ('rd') then StyleID = 'D1_R2_BL';
			else if varname in ('rr' 'ort') then do;
				%if &cc_sw. ne 0 %then %do;
				if cc_ind = 1 then StyleID = 'D1_R2S_BL';
				else StyleID = 'D1_R2N_BL';
				%end;
				%else %do;
					StyleID = 'D1_R2_BL';
				%end;
			end;
			else if varname in ('p_value') then StyleID = 'D2_R2_BLR';
			else if index(varname,'pct') then StyleID = 'D1_R1_B';
			if index(varname,'cilb') then StyleID = 'LCL_B';
			if index(varname,'ciub') then do;
				StyleID = 'UCL_BR';
				if input(Data,E.) > 10**6 then StyleID = 'UCLSN_BR';
			end;
		end;

		if bottom then StyleID = trim(StyleID)||'B';

		/* highlight the sort column */
		%if &fmt. = Y %then %do;
			if varname = "&cmpsort." then do;
				pos = length(trim(StyleID)) - index(left(reverse(StyleID)),'_');
				StyleID = substr(StyleID,1,pos)||'H'||'_'||substr(StyleID,pos + 2);
			end; 
			drop pos;
		%end;
	run;

	%markup(ws_&ds._data_note,ws_&ds._data);

	/* remove created header row indicator */
	%if &fmt. ne Y %then %do; proc datasets library=work nolist nodetails; delete &ds._ind; quit; %end;


	/* get the row numbers for the first and last data rows */
	data _null_;
		set ws_&ds._header ws_&ds._columns end=eof;
		retain count;
		if string in ('<Row/>' '</Row>') then count + 1;
		if eof then do;
			firstrow = count + 1;
			lastrow =  firstrow + &nobs. - 1;
			call symputx('firstrow',put(firstrow,8. -L));
			call symputx('lastrow',put(lastrow,8. -L));
		end;
	run;

	/* determine whether first row is even or odd */
	%let fr_odd = %sysfunc(mod(&firstrow.,2));

	/* set up named ranges */
	/* right now, there is only one named range */
	/* which is for repeating column headers when printing */
	data ws_&ds._names;
		length string $&strlen.; 
		string = '<Names>'; output;
		string = '<NamedRange ss:Name="Print_Titles" '||
                 'ss:RefersTo="='||"'"||"&wstitle."||"'!R"||
                  compress(%eval(&firstrow.-1))||':R'||compress(%eval(&firstrow.-3))||'"/>'; output;
		string = '</Names>'; output;
	run;

	/* set up the worksheet settings for conditional formatting and autofilter*/
	data ws_&ds._settings; 
		length string $&strlen.; 
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;

		string = '<PageSetup>'; output;
		string = '<Layout x:Orientation="Landscape"/>'; output;
		string = '<Header x:Data="&amp;L'||"&wstitle1_long.&#10;&wstitle2_long."||
                 '&amp;R'||"NDA/BLA &ndabla.&#10;Study &studyid."||'"/>'; output;
		string = '<Footer x:Data="Page &amp;P of &amp;N"/>'; output;
		string = '</PageSetup>'; output; 
		string = '<FitToPage/>'; output;
		string = '<Print>'; output;
        string = '<FitHeight>100</FitHeight>'; output;
       	string = '</Print>'; output; 

		/* frozen panes settings */
		string = '<Selected/>'; output;
       	string = '<FreezePanes/>'; output;
       	string = '<FrozenNoSplit/>'; output;
       	string = '<SplitHorizontal>'||compress(%eval(&firstrow.-1))||'</SplitHorizontal>'; output;
       	string = '<TopRowBottomPane>'||compress(%eval(&firstrow.-1))||'</TopRowBottomPane>'; output;
		string = '<ActivePane>2</ActivePane>'; output;

		/* selected cell */
		string = '<Panes>'; output;
		string = '<Pane>'; output;
		string = '<Number>2</Number>'; output;
		string = '<ActiveRow>0</ActiveRow>'; output;
		string = '</Pane>'; output;
		string = '</Panes>'; output;

		string = '</WorksheetOptions>'; output;

		%if &fmt. = N %then %do;
			string = '<AutoFilter x:Range="'||'R'||compress(%eval(&firstrow.-1))||'C1:R'||
                     compress(%eval(&firstrow.-1))||"C&nvars."||'" '||
                     'xmlns="urn:schemas-microsoft-com:office:excel">'; output;
			string = '</AutoFilter>'; output;
			string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
			string = "<Range>R&firstrow.C1:R&lastrow.C&nvars.</Range>"; output;
			string = '<Condition>'; output;
			string = "<Value1>MOD(SUBTOTAL(103,RC1:R2C1),2)=&fr_odd.</Value1>"; output;
			string = "<Format Style='background:silver'/>"; output;
			string = '</Condition>'; output;
			string = '</ConditionalFormatting>'; output;
		%end;
	run;

	data ws_&ds.;
		set ws_&ds._start
		    ws_&ds._names
		    ws_&ds._table_start
			ws_&ds._header
		    ws_&ds._columns
			ws_&ds._data 
			ws_&ds._footer
			ws_&ds._table_end
			ws_&ds._settings
			ws_&ds._end;
	run;

	proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;

%mend out_pt_3;


/**********************/
/* DATA CHECK SUMMARY */
/**********************/
%macro out_err;

	/* set up worksheet */
	data ws_err_start;
		length string $&strlen.;
		string = '<Worksheet ss:Name="'||"Data Check Summary"||'">'; output; 
	run;

	data ws_err_end; 
		length string $&strlen.; 
		string = '</Worksheet>'; output;
	run;

	data ws_err_table_start; 
		length string $&strlen.; 
		string = '<Table>'; output;
		string = '<Column ss:Width="266"/>'; output;
	run;

	data ws_err_table_end;
		length string $&strlen.; 
		string = '</Table>'; output;
	run;

	/* header */
	/* make worksheet header */
	data ws_err_header_data;
		%xml_tag_def;
		%xml_init;

		Type = 'String';

		%let row = 0;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
		
		Row = %let row = %eval(&row. + 1); &row.;
		StyleID = 'Header'; 
		Data = 'Adverse Events Data Check Summary';
		output;

		%if (&sl_group_nobs. or &sl_subset_nobs.) %then %do;
			Row = %let row = %eval(&row. + 1); &row.;
			Data = "&sl_gs_desc."; StyleID = 'Default10'; output;
		%end;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;

		StyleID = 'Default8'; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = "NDA/BLA: &ndabla."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Study: &studyid."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Analysis run date: &rundate."; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;
	run;

	%markup(ws_err_header_data,ws_err_header);

	/* empty row for separating sections of the data check summary */
	data ws_null;
		length string $&strlen.;
		string = '<Row/>';
	run;


	/****************************/
	/* SUBJECT VALIDATION TABLE */
	/****************************/
	/* make section header */
	data ws_rpt_dm_header_data;
		%xml_tag_def;
		%xml_init;

		MergeAcross = 6;

		%let row = 0;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;

		Row = %let row = %eval(&row. + 1); &row.;
		StyleID = 'SubHeader';
		Data = "Subject Validation"; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
		
		Row = %let row = %eval(&row. + 1); &row.;
		StyleID = 'Default10Wrap';
		Data = "Subjects are validated before their adverse events are used in this report's analysis. "||
               'Subjects are excluded if they fail screening or are unassigned to an arm, '||
               'are not in the safety population, or are missing treatment and reference start and '||
               'end dates. The following table shows how many subjects were in the demographics (DM) dataset, '||
               'how many were removed for each of these reasons, and how many remained whose adverse events '||
               'were used in the analysis.';
		output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
	run;

	data ws_rpt_dm_header_data;
		set ws_rpt_dm_header_data;
		Height = max(1,ceil(length(trim(Data))/130))*13.5;
	run;

	%markup(ws_rpt_dm_header_data,ws_rpt_dm_header);

	/* subject validation column headers */
	data ws_rpt_dm_columns_data;
		%xml_tag_def;
		%xml_init;

		Type = 'String';
		StyleID = 'ColumnOutline';

		Row = 1;
		Height = 35;
		MergeAcross = 2*(&arm_count.+1);
		Data = 'Subject Validation Summary'; output;
		MergeAcross = .;

		Row = 2;
		Height = 13.75 + max(1,round(&max_arm_nm_len./12,1))*13.75;
		MergeDown = 1;
		Data = 'Subject Validation Step'; output; 
		MergeDown = .; MergeAcross = 1;
		%do i = 1 %to &arm_count.;
			Data = "&&&arm_name_&i."; output;
		%end;
		Data = 'Total'; output;

		Row = 3;
		Height = 27;
		Index = 2;
		MergeAcross = .;
		%do i = 1 %to &arm_count.;
			Data = "Subject Count"; output;
			Index = .;
			Data = "%"; output;
		%end;
		Data = "Subject Count"; output;
		Data = "%"; output;
	run;

	%markup(ws_rpt_dm_columns_data,ws_rpt_dm_columns);

	/* subject validation data table */
	%annotate(rpt_dm,ws_rpt_dm_data);

	data ws_rpt_dm_data;
		set ws_rpt_dm_data;
		by Row;	

		if varname = 'desc' then StyleID = 'D_BLR';
		else if index(varname,'count') then StyleID = 'D0_R1_BL';
		else if index(varname,'pct') then StyleID = 'D1_R1_BR';

		if bottom then StyleID = trim(StyleID)||'B';
	run;

	%markup(ws_rpt_dm_data,ws_rpt_dm);


	/*************************/
	/* DATA VALIDATION TABLE */
	/*************************/

	/* find out whether there were any adverse events excluded during validation */
	%let dsid = %sysfunc(open(rpt_err));
	%if %sysfunc(attrn(&dsid.,nobs)) %then %let vld_err = Y;
	%else %let vld_err = N;
	%let rc = %sysfunc(close(&dsid.));

	/* make section header */
	data ws_rpt_err_header_data;
		%xml_tag_def;
		%xml_init;

		MergeAcross = 6;

		%let row = 0;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;

		Row = %let row = %eval(&row. + 1); &row.;
		StyleID = 'SubHeader';
		Data = "Adverse Events Data Validation"; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
		
		Row = %let row = %eval(&row. + 1); &row.;
		StyleID = 'Default10Wrap';
		Data = "Data validation is performed on all adverse events experienced by validated subjects, "||
		       "of which there were "||trim(put(&naes_sp.,comma7. -L))||" "||
               'in this study. Adverse events can be excluded for the following reasons:'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = '~!~!~!1. The start date of the adverse event was missing or could not be interpreted '||
               'as a date with at least month and year'; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "~!~!~!2. The start date of the adverse event was not between the subject's first "||
               'exposure date and last exposure date '||ifc(&study_lag. ne 0,"+ &study_lag. days",''); 
               output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = '~!~!~!3. The body system or organ class (AEBODSYS) or dictionary-derived term (AEDECOD) '||
               'was blank'; output;

		%if &vld_sw. %then %do;
			%if &vld_err. = N %then %do;
				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; output;
				Row = %let row = %eval(&row. + 1); &row.;
				Data = 'No adverse events were excluded during data validation.'; output;
			%end;
			%else %do;
				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; output;
				Row = %let row = %eval(&row. + 1); &row.;
				Data = 'The counts in the following two tables are counts of events and not of subjects. '||
	                   'A subject can have for example an adverse event anaemia that '||
	                   'passed validation and two that did not. That subject is counted '||
	                   'in the subject count for anaemia on prior tabs, and the two adverse events '||
	                   'that were excluded are counted here individually.'; output;
			%end;
		%end;
		%else %do;
				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; output;
				Row = %let row = %eval(&row. + 1); &row.;
				Data = 'Data validation was not done because necessary date variables '||
                       'were not available. All adverse events were used in the analysis.'; output;
		%end;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
	run;

	data ws_rpt_err_header_data;
		set ws_rpt_err_header_data;
		Height = max(1,ceil(length(trim(compress(Data,'~!')))/125))*13.5;
	run;

	%markup(ws_rpt_err_header_data,ws_rpt_err_header);

	/* if there were excluded AEs, then include a summary table */
	/* and a table listing them by term */
	%if &vld_err. = Y %then %do;

		/* SUMMARY */
		data ws_rpt_err_columns_data;
			%xml_tag_def;
			%xml_init;


			Type = 'String';
			StyleID = 'ColumnOutline';

			Row = 1;
			Height = 35;
			MergeAcross = 2*&arm_count.;
			Data = 'Adverse Events Data Validation Summary'; output;
			MergeAcross = .;

			Row = 2;
			Height = 13.75 + max(1,round(&max_arm_nm_len./13.25,1))*13.75;
			MergeDown = 1;
			Data = 'Reason for Exclusion'; output; 
			MergeDown = .;
			MergeAcross = 1;
			%do i = 1 %to &arm_count.;
				Data = "&&&arm_name_&i."||'&#10;'||'N='||put(&&&naes_sp_&i.,comma7. -L); output;
			%end;
			MergeAcross = .;

			Row	= 3;
			Height = 27;
			Index = 2;
			%do i = 1 %to &arm_count.;
				Data = 'Event Count'; output;
				Index = .;
				Data = '%'; output;
			%end;
		run;

		%markup(ws_rpt_err_columns_data,ws_rpt_err_columns);

		%annotate(rpt_err,ws_rpt_err_data);

		data ws_rpt_err_data;
			set ws_rpt_err_data;
			by Row;	

			if varname = 'err_desc' then StyleID = 'D_BLR';
			else if index(varname,'count') then StyleID = 'D0_R1_BL';
			else if index(varname,'pct') then StyleID = 'D1_R1_BR';

			if bottom then StyleID = trim(StyleID)||'B';
		run;

		%markup(ws_rpt_err_data,ws_rpt_err);

		/* DATA VALIDATION BY TERM */
		data ws_rpt_err_term_columns_data;
			%xml_tag_def;
			%xml_init;

			Type = 'String';
			StyleID = 'ColumnOutline';

			Row = 1;
			Height = 25;
			MergeAcross = 5 + 2*&arm_count.;
			Data = 'Adverse Events Data Validation by Term'; output;
			MergeAcross = .;

			Row = 2;
			Height = 13.75 + max(1,round(&max_arm_nm_len./13.25,1))*13.75;
			Data = 'Body System or Organ Class'; output;
			MergeAcross = 4;
			Data = 'Dictionary-Derived Term'; output;
			MergeAcross = .;
			MergeAcross = 1;
			%do i = 1 %to &arm_count.;
				Data = "&&&arm_name_&i."||'&#10;'||'Event Count'; output;		
			%end;
			MergeAcross = .;
		run;

		%markup(ws_rpt_err_term_columns_data,ws_rpt_err_term_columns);

		%annotate(rpt_err_term,ws_rpt_err_term_data);

		data ws_rpt_err_term_data;
			set ws_rpt_err_term_data;

			StyleID = 'Data';
			if bottom then StyleID = trim(StyleID)||'Bottom';
			if upcase(varname) = 'AEDECOD' then MergeAcross = 4;
			else if upcase(varname) in (%do i = 1 %to &arm_count.; "ARM&i."  %end;) then MergeAcross = 1;
			else MergeAcross = .;
		run;

		%markup(ws_rpt_err_term_data,ws_rpt_err_term);
	%end;


	/*******************/
	/* MEDDRA MATCHING */
	/*******************/

	%if &meddra. = Y %then %do;

		/* get key variable count */
		proc sql noprint;
			select lowcase(put(keyvar_cnt,words.)) into : ntrmrpt_num
			from rpt_key
			where upcase(substr(  ds ,1,min(length(trim(ds)),length(trim("pt_3")))))
	            = upcase(substr("pt_3",1,min(length(trim(ds)),length(trim("pt_3")))));
		quit;


		/* make section header */
		data ws_rpt_meddra_header_data; 
			%xml_tag_def;
			%xml_init;

			MergeAcross = 7;

			%let row = 0;

			Row = %let row = %eval(&row. + 1); &row.;
			Data = ''; output;

			Row = %let row = %eval(&row. + 1); &row.;
			StyleID = 'SubHeader';
			Data = "MedDRA Matching"; output;

			Row = %let row = %eval(&row. + 1); &row.;
			Data = ''; output;
			
			Row = %let row = %eval(&row. + 1); &row.;
			StyleID = 'Default10Wrap';
			Data = 'MedDRA matching is performed on all adverse events which passed data validation, '||
			       'of which there were '||trim(put(&naes_spv.,comma7. -L))||' in this study.'; output;

			%if &meddra. = N %then %do;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = ''; output;

				Row = %let row = %eval(&row. + 1); &row.;
				Data = "Fewer than 80 percent of adverse events had matching MedDRA terms (version &ver.), "||
	                   'so the '||trim("&ntrmrpt_num.")||'-term reports use '||
	                   'the adverse event descriptions provided in the AE dataset'; output;

			%end;

			Row = %let row = %eval(&row. + 1); &row.;
			Data = ''; output;
		run;

		data ws_rpt_meddra_header_data;
			set ws_rpt_meddra_header_data;
			Height = max(1,ceil(length(trim(Data))/130))*13.5;
		run;

		%markup(ws_rpt_meddra_header_data,ws_rpt_meddra_header);

		/* summary */
		data ws_rpt_meddra_columns_data;
			%xml_tag_def;
			%xml_init;

			Type = 'String';
			StyleID = 'ColumnOutline';

			Row = 1;
			Height = 35;
			MergeAcross = 3;
			Data = 'MedDRA Matching Summary'||'&#10;'||"N="||put(&naes_spv.,comma7. -L); output;
			MergeAcross = .;

			Row = 2;
			Height = 40;
			Data = 'MedDRA Version'; output;
			Data = 'Match Count'; output;
			Data = 'Non-Match Count'; output;
			Data = 'Match %'; output;
		run;

		%markup(ws_rpt_meddra_columns_data,ws_rpt_meddra_columns);

		%annotate(rpt_meddra,ws_rpt_meddra_data);

		data ws_rpt_meddra_data;
			set ws_rpt_meddra_data;
			by Row;

			StyleID = 'Data';
			if index(varname,'pct') then StyleID = trim(StyleID)||'Dec1'; 
			if not first.Row then StyleID = trim(StyleID)||'Center';
			if bottom then StyleID = trim(StyleID)||'Bottom';
		run;

		%markup(ws_rpt_meddra_data,ws_rpt_meddra);

		/* per-term counts */
		%if %sysfunc(floor(&meddra_pct.)) < 100 %then %do;
			data ws_rpt_err_meddra_columns_data;
				%xml_tag_def;
				%xml_init;

				Type = 'String';
				StyleID = 'ColumnOutline';

				Row = 1;
				Height = 25;
				MergeAcross = 7;
				Data = 'Adverse Events Without Matching MedDRA Terms'; output;
				MergeAcross = .;

				Row = 2;
				Height = 30;
				Data = 'Body System or Organ Class'; output;
				MergeAcross = 4;
				Data = 'Dictionary-Derived Term'; output;
				MergeAcross = .; 
				Data = 'Subject Count'; output;
				Data = 'Event Count'; output;
			run;

			%markup(ws_rpt_err_meddra_columns_data,ws_rpt_err_meddra_columns);
			
			%annotate(rpt_meddra_term,ws_rpt_err_meddra_data);

			data ws_rpt_err_meddra_data;
				set ws_rpt_err_meddra_data;

				StyleID = 'Data';
				if bottom then StyleID = trim(StyleID)||'Bottom';
				if upcase(varname) = upcase('aedecod') then MergeAcross = 4;
			run;

			%markup(ws_rpt_err_meddra_data,ws_rpt_err_meddra);
		%end;	

	%end;

	
	/***************************/
	/* MISSING TOXICITY GRADES */
	/***************************/

	/* make section header */
	data ws_rpt_missing_header_data;
		%xml_tag_def;
		%xml_init;

		MergeAcross = 6;

		%let row = 0;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		StyleID = 'SubHeader';
		Data = "Missing Toxicity Grades"; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		StyleID = 'Default10Wrap';
		Data = "The following table summarizes how many subjects' adverse events had no toxicity grades, "||
               'for each analysis in this report. These adverse events are included in the All Grades '||
               "subject counts. Here they are separated out and added up so that each one of a subject's "||
               'adverse events with no toxicity grade is counted once.'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'For the Toxicity Grade Summary, a subject is counted as having a missing toxicity grade '||
               "if all of that subject's adverse events have no toxicity grades. For the other two reports, "||
               'a subject is counted for each adverse event with no toxicity grade, where adverse events are '||
               'aggregated together as stated below the title of each analysis. For example, a subject with '||
               'anaemia and nausea, neither of which had toxicity grades, will add two to the count of '||
               'missing toxicity grades below.'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
	run;

	data ws_rpt_missing_header_data;
		set ws_rpt_missing_header_data;
		Height = max(1,ceil(length(trim(Data))/130))*13.5;
	run;

	%markup(ws_rpt_missing_header_data,ws_rpt_missing_header);


	/* missing tox grade column headers */
	data ws_rpt_missing_columns_data;
		%xml_tag_def;
		%xml_init;

		Type = 'String';
		StyleID = 'ColumnOutline';

		Row = 1;
		Height = 25;
		Data = 'Missing Toxicity Grade Summary'; MergeAcross = 2*&arm_count.; output;
		MergeAcross = .;

		Row = 2;
		Height = max(20,round(&max_arm_nm_len./13.25,1) * 13.75);
		Data = 'Analysis'; MergeDown = 1; output;
		MergeDown = .;
		%do i = 1 %to &arm_count.;
			Data = "&&&arm_name_&i."; MergeAcross = 1; output;
		%end;
		Height = .; MergeAcross = .;

		Row = 3;
		Height = 30;
		%do i = 1 %to &arm_count.; 
			Data = 'Missing Count'; %if &i. = 1 %then Index = 2;; output;
			Index = .;
			Data = '%'; output;
		%end;
	run;

	%markup(ws_rpt_missing_columns_data,ws_rpt_missing_columns);

	/* missing data */
	proc sql;
		create table rpt_missing_output(drop=ds) as
		select trim(report)||'&#10;'||'~!~!~!~!~!by '||lowcase(key_label) as report_key,
		       a.*
		from rpt_missing a 
		     left join
			 rpt_key b
		on a.ds = b.ds;
	quit;

	%annotate(rpt_missing_output,ws_rpt_missing_data);

	data ws_rpt_missing_data;
		set ws_rpt_missing_data end=eof;
		by Row;

		Height = 25.5;

		if varname = 'report_key' then StyleID = 'DT_BLR';
		else if index(varname,'missing') then StyleID = 'D0_R1T_BL';
		if index(varname,'pct') then StyleID = 'D1_R1T_BR';

		if bottom then StyleID = trim(StyleID)||'B';
	run;

	%markup(ws_rpt_missing_data,ws_rpt_missing);


	/*********************/
	/* ASSEMBLE WORKBOOK */
	/*********************/
	data ws_err_table;
		set ws_err_header
			ws_rpt_dm_header
			ws_rpt_dm_columns
			ws_rpt_dm
			ws_rpt_err_header
			%if &vld_err. = Y %then %do;
				ws_rpt_err_columns
				ws_rpt_err
				ws_null
				ws_rpt_err_term_columns
				ws_rpt_err_term
				ws_null
			%end;
			ws_rpt_missing_header
			ws_rpt_missing_columns
			ws_rpt_missing
			%if &meddra. = Y %then %do;
				ws_null
				ws_rpt_meddra_header
				ws_rpt_meddra_columns
				ws_rpt_meddra
				%if %sysfunc(floor(&meddra_pct.)) < 100 %then %do;
					ws_null
					ws_rpt_err_meddra_columns
					ws_rpt_err_meddra
				%end;
			%end;
			;
	run; 

	/* settings for alternating row highlighting */
	/* get the info on the first and last rows for the data validation by term */
	/* and the MedDRA matching by term in order to set up alternate row highlighting */
	%if &vld_err. = Y %then %do;
		%let dsid = %sysfunc(open(rpt_err_term));
		%let nobs = %sysfunc(attrn(&dsid.,nobs));
		%let rc = %sysfunc(close(&dsid.));

		data _null_;
			set ws_err_header
				ws_rpt_dm_header
				ws_rpt_dm_columns
				ws_rpt_dm
				ws_rpt_err_header
				ws_rpt_err_columns
				ws_rpt_err
				ws_null
				ws_rpt_err_term_columns
	            end=eof;
			retain count;
			if string in ('<Row/>' '</Row>') then count + 1;
			if eof then do;
				firstrow = count + 1;
				lastrow =  firstrow + &nobs. - 1;
				call symputx('err_firstrow',put(firstrow,8. -L));
				call symputx('err_lastrow',put(lastrow,8. -L));
			end;
		run;
	%end;

	%if &meddra. = Y and %sysfunc(floor(&meddra_pct.)) < 100 %then %do;
		%let dsid = %sysfunc(open(rpt_meddra_term));
		%let nobs = %sysfunc(attrn(&dsid.,nobs));
		%let rc = %sysfunc(close(&dsid.));

		data _null_;
			set ws_err_header
				ws_rpt_dm_header
				ws_rpt_dm_columns
				ws_rpt_dm
				ws_rpt_err_header
				%if &vld_err. = Y %then %do;
					ws_rpt_err_columns
					ws_rpt_err
					ws_null
					ws_rpt_err_term_columns
					ws_rpt_err_term
					ws_null
				%end;
				ws_rpt_missing_header
				ws_rpt_missing_columns
				ws_rpt_missing
				ws_null
				ws_rpt_meddra_header
				ws_rpt_meddra_columns
				ws_rpt_meddra
				ws_null
				ws_rpt_err_meddra_columns
				end=eof;
			retain count;
			if string in ('<Row/>' '</Row>') then count + 1;
			if eof then do;
				firstrow = count + 1;
				lastrow =  firstrow + &nobs. - 1;
				call symputx('meddra_firstrow',put(firstrow,8. -L));
				call symputx('meddra_lastrow',put(lastrow,8. -L));
			end;
		run;
	%end;

	data ws_err_settings;
		length string $&strlen.; 
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<PageSetup>'; output;
		string = '<Layout x:Orientation="Landscape"/>'; output;
		string = '<Footer x:Data="Page &amp;P of &amp;N"/>'; output;
		string = '</PageSetup>'; output; 
		string = '<FitToPage/>'; output;
		string = '<Print>'; output;
        string = '<FitHeight>100</FitHeight>'; output;
       	string = '</Print>'; output;
		string = '</WorksheetOptions>'; output;
		%if &vld_err. = Y %then %do;
			string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
			string = "<Range>R&err_firstrow.C1:R&err_lastrow.C"||
	                  compress(%eval(6+2*&arm_count.))||"</Range>"; output;
			string = '<Condition>'; output;
			string = '<Value1>MOD(ROW(),2)</Value1>'; output;
			string = "<Format Style='background:silver'/>"; output;
			string = '</Condition>'; output;
			string = '</ConditionalFormatting>'; output;
		%end;
		%if &meddra. = Y and %sysfunc(floor(&meddra_pct.)) < 100 %then %do;
			string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
			string = "<Range>R&meddra_firstrow.C1:R&meddra_lastrow.C8</Range>"; output;
			string = '<Condition>'; output;
			string = '<Value1>MOD(ROW(),2)</Value1>'; output;
			string = "<Format Style='background:silver'/>"; output;
			string = '</Condition>'; output;
			string = '</ConditionalFormatting>'; output;
		%end;
	run;

	data ws_err;
		set ws_err_start
			ws_err_table_start
			ws_err_table
			ws_err_table_end 
			ws_err_settings
			ws_err_end;
	run;

	proc datasets library=work nolist nodetails; delete ws_err_: ws_rpt_:; quit;

%mend out_err;


/* worksheet information */
/* establishes worksheet name, column widths, etc. */
/* one set per worksheet */
%macro ws(ds,keycolwidth=200);

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
		%do i = 1 %to &nvars.; 
			%if &i. <= &nkeycols. %then %do;
				string = '<Column ss:Width="'||"&keycolwidth"||'"/>'; output;
			%end;
			%else %do;
				%if %sysfunc(mod(%eval(&i.-&nkeycols.),2)) = 0 %then %do;
					string = '<Column ss:Width="35.75"/>'; output;
				%end;
				%else %if &fmt.=N %then %do;
					string = '<Column ss:Width="61.5"/>'; output;
				%end;
				%else %do;
					string = '<Column/>'; output;
				%end;
			%end;
		%end;
	run;

	data ws_&ds._table_end;
		length string $&strlen.; 
		string = '</Table>'; output;
	run;

%mend ws; 


/* create column headers for the data */
/* for PT analysis only */
%macro wscolumns(ds);

	data ws_&ds._columns_data;
		retain row;
		length data $1000;

		/* FIRST ROW */
		row = 1;
		
		/* the by variables for the table */
		%let dsid = %sysfunc(open(&ds.));
		%do i = 1 %to &nkeycols.;
			%let label = %sysfunc(varlabel(&dsid.,&i.));
			data = "&label.";
			output; 
		%end;
		%let rc = %sysfunc(close(&dsid.));

		/* the arms */
		%do i = 1 %to &arm_count.;
			data = "&&&arm_name_&i."||'&#10;N='||trim(put(&&&arm_&i.,comma7. -L)); 
			output;
		%end;

		/* SECOND ROW */
		row = 2;

		%do i = 1 %to &arm_count.;
			data = 'All Grades'; output;
			%if &toxgr_max. = 4 or (&toxgr_max. = 5 and &toxgr_grp5_sw. = 0) %then %do;
				data = 'Grades 3/4'; output;
				%if (&toxgr_max. = 5 and &toxgr_grp5_sw. = 0) %then %do;
					data = 'Grade 5'; output;
				%end;
			%end;
			%else %if &toxgr_max. = 5 and &toxgr_grp5_sw. = 1 %then %do;
				data = 'Grades 3/4/5'; output;
			%end;
		%end;

		/* THIRD ROW */
		row = 3;

		%do i = 1 %to %eval(&arm_count.*%sysfunc(ifn(&toxgr_grp5_sw.=1,2,3)));
			data = 'Subject Count'; output;
			data = '%'; output;
		%end;

	run;

	data ws_&ds._columns; 
		retain row col;
		set ws_&ds._columns_data;
		by row notsorted; 
		length string $&strlen.;

		if first.row then col = 0;
		col = col + 1;

		if first.row then do;
			select (row);
				when (1) height = 40;
				when (2) height = 15.75;
				when (3) height = 31.5;
				otherwise height = 15.75;
			end;
			string = '<Row ss:Height="'||compress(put(height,8.2))||'">'; output;
		end;

		if row = 1 then do;
			if col <= &nkeycols. then do;
				string = '<Cell ss:MergeDown="2" ss:StyleID="ColumnOutline">'||
                         '<Data ss:Type="String">'||trim(data)||'</Data></Cell>'; 
			end;
			else do;
				string = '<Cell ss:MergeAcross="'||compress(%sysfunc(ifn(&toxgr_grp5_sw.=1,3,5)))||
                         '" ss:StyleID="ColumnOutline">'||
                         '<Data ss:Type="String">'||trim(data)||'</Data></Cell>'; 
			end;
		end;

		if row = 2 then do;
			string = '<Cell ss:MergeAcross="1" ss:StyleID="ColumnOutline">'||
                     '<Data ss:Type="String">'||trim(data)||'</Data></Cell>'; 
			if col = 1 then
				string = substr(string,1,6)||'ss:Index="'||compress(%eval(&nkeycols.+1))||'" '||substr(string,7);
		end;

		if row = 3 then do;
			string = '<Cell ss:StyleID="ColumnOutline"><Data ss:Type="String">'||trim(data)||'</Data></Cell>';
			if col = 1 then
				string = substr(string,1,6)||'ss:Index="'||compress(%eval(&nkeycols.+1))||'" '||substr(string,7);
		end;

		output;

		if last.row then do;
			string = '</Row>'; output; 
		end;

		keep string;
	run;

%mend wscolumns;


/* create the XML styles used in this workbook */
%macro out_oae_styles;

	data wb_oae_styles_data;
		%xml_style_dcl;	
		ID = 'D'; output;

		ID = 'D0_R1'; NumFmt = '0'; HA = 'Right'; Indent = 1; output; 
		ID = 'D0_R2'; NumFmt = '0'; HA = 'Right'; Indent = 2; output; 
		ID = 'D0_R4'; NumFmt = '0'; HA = 'Right'; Indent = 4; output;
		ID = 'D1_R1'; NumFmt = '0.0'; HA = 'Right'; Indent = 1; output;
		ID = 'D1_R2'; NumFmt = '0.0'; HA = 'Right'; Indent = 2; output;
		ID = 'D1_R2N'; NumFmt = '0.0_*'; HA = 'Right'; Indent = 2; output;
		ID = 'D1_R2S'; NumFmt = '0.0&quot;*&quot;'; HA = 'Right'; Indent = 2; output;
		ID = 'D2_R1'; NumFmt = '0.00'; HA = 'Right'; Indent = 1; output;
		ID = 'D2_R2'; NumFmt = '0.00'; HA = 'Right'; Indent = 2; output;
		HA = ''; Indent = .;

		ID = 'LCL'; NumFmt = '&quot;(&quot;0.00&quot;,&quot;;&quot;(-&quot;0.00&quot;,&quot;'; HA = 'Right'; output;
		ID = 'UCL'; NumFmt = '0.00&quot;)&quot;'; HA = 'Left'; output;	
		ID = 'UCLSN'; NumFmt = '0.0E+00&quot;)&quot;'; HA = 'Left'; output;
		NumFmt = ''; HA = '';

		ID = 'DT'; VA = 'Top'; Wrap = 1; output;
		Wrap = .;
		ID = 'D0_R1T'; NumFmt = '0'; HA = 'Right'; VA = 'Top'; Indent = 1; output; 
		ID = 'D1_R1T'; NumFmt = '0.0'; HA = 'Right'; VA = 'Top'; Indent = 1; output;
	run;

	data wb_oae_styles_h_data;
		set wb_oae_styles_data;
		ID = trim(ID)||'H'; IntClr = 'CCCCFF';
	run;
	
	data wb_oae_styles_data;
		set wb_oae_styles_data wb_oae_styles_h_data; 
		length ParentID $50;

		ParentID = ID;

		do BL = 0 to 1;
			do BR = 0 to 1;
				do BB = 0 to 1;
					ID = trim(left(ParentID))||'_B'; 
					if BL then ID = trim(left(ID))||'L';
					if BR then ID = trim(left(ID))||'R';
					if BB then ID = trim(left(ID))||'B';
					if BL or BR or BB then BWt = 1;
					output;
				end;
			end;
		end;
	run;

	%xml_style_markup(wb_oae_styles_data,wb_oae_styles);

	proc datasets library=work nolist nodetails; delete wb_oae_styles_:; quit;

%mend out_oae_styles;


/************************/
/* begin running output */
/************************/
%macro out_onc;

	/* print current activity to the log */
	data _null_;
		title = "MAKING EXCEL XML OUTPUT FOR ONCOLOGY AE REPORT";
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

	/* create analysis run date macro variable */
	data _null_;
		call symputx('rundate',compbl(put(date(),e8601da.)||' '||put(time(),timeampm11.)),'g');
	run;

	/* create grouping & subsetting output */
	%group_subset_pp;
	%group_subset_xml_out;

	%wb;
	%styles;
	%out_oae_styles;

	data wb_styles;
		set wb_styles 
            wb_oae_styles end=eof;
		if string = '</Styles>' then delete;
		keep string;
		output;
		if eof then do; string = '</Styles>'; output; end;
	run;

	%out_cover;

	%out_pt_1;
	%out_pt_2; 
	%out_pt_2(fmt=Y);
	%if &arm_count. > 1 %then %do;
	%out_pt_3; 
	%out_pt_3(fmt=Y);
	%end;
	%out_err

	data wb;
		set wb_start
		    wb_styles 
			ws_cover
			ws_pt_1_output
			ws_pt_2_output
			ws_pt_2_output_fmt 
			%if &arm_count. > 1 %then %do;
			ws_pt_3_output 
			ws_pt_3_output_fmt
			%end;
			ws_err 
			%if %sysfunc(exist(ws_sl_gs)) %then ws_sl_gs;
			wb_end;
	run;

	/*proc datasets library=work nolist nodetails; delete wb_:; quit;*/

	data _null_;
		set wb;
		file "&oncaeout." ls=32767;
		put string;
	run;

%mend out_onc;
