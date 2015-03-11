%let wbtitle = AE Severity Panel;

/* length of the XML string */
/* must be wide enough to contain the longest string to be output */
%global strlen;
%let strlen = 1000;

*%include "&utilpath.\xml_output.sas";


/******************************/
/* ADVERSE EVENTS COVER SHEET */
/******************************/
%macro out_cover;

	%let ds = cover;
	%let wstitle = Front Page;

	%let nkeys = 1;
	%let nkeycols = 1;
	%let nvars = 1;

	%ws(&ds.,keycolwidth=50); 

	/* make the header */
	data ws_&ds._header_data; 
		length text $5000;
		text = ''; output;

		text = 'AE Severity Panel Front Page'; output;

		text = ''; output;

		text = 'NDA/BLA: '||"&ndabla."; output;
		text = 'Study: '||"&studyid."; output;
		text = "Analysis run date: &rundate."; output;

		text = ''; output;

		text = '1. Adverse Events by Arm Greater than 2%'; output;
		text = 'This analysis shows all adverse events that occur '||
               'in more than 2% of subjects in any treatment arm. Each adverse event is '||
               'counted only once per subject.'; output; 

		text = ''; output;

		text = '2. Serious Adverse Events by Arm'; output;
		text = 'This analysis shows all adverse events that were considered serious. '||
               'Calculations are performed the same as Analysis 1, except '||
               "only adverse events with a 'Y' in the AESER variable from the AE "||
               'dataset are used.'; output;

		text = ''; output;

		text = '3. Adverse Events by Severity'; output;
		text = 'This analysis shows all adverse events in the study and the '||
               'number of times they occur by arm and severity level, using the '||
               'AESEV variable from the AE dataset if it is available.'; output;

		text = ''; output;

		text = '4. Serious Adverse Events by Severity'; output;
		text = 'This analysis shows all adverse events that were considered serious '||
               'by arm and severity level. Calculations are performed the same as '||
               'Analysis 1, except only adverse events with a '||
               "'Y' in the AESER variable from the AE dataset are used."; output;

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
               'Treatment arm is determined using the '||ifc(&dm_actarm.,'actual treatment arm (ACTARM)',
                                                                         'planned treatment arm (ARM)')||
               ' from DM.'; output;

		text = ''; output;
	run;

	%annotate(ws_&ds._header_data,ws_&ds._header_note);

	data ws_&ds._header_note;
		set ws_&ds._header_note;

		MergeAcross = 10;
		StyleID = 'Default10Wrap';

		if Data = 'AE Severity Panel Front Page' then StyleID = 'Header';
		else if Data = 'Method and Calculations' then StyleID = 'SubHeader';
		else if anydigit(substr(Data,1,1)) then StyleID = 'SubHeader';

		if StyleID = 'Default10Wrap' then Height = max(1,ceil(length(trim(Data))/100))*12.75;
	run;

	%markup(ws_&ds._header_note,ws_&ds._header);

	/* cover sheet -- panel settings and a note about crossover studies */
	data ws_&ds._panel_data;
		length desc $250 setting $250;

		desc = ''; setting = ''; output;

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

		desc = ''; setting = ''; output;
		desc = ''; setting = ''; output;

		desc = 'Note that for crossover studies, the analysis by arm in this report '||
               'can only be used to examine treatment sequences and not individual treatments.'; output;
	run; 

	%annotate(ws_&ds._panel_data,ws_&ds._panel_note);

	data ws_&ds._panel_note;
		set ws_&ds._panel_note;

		if varname = 'desc' then MergeAcross = 1;

		if Data in ('Report Settings') then StyleID = 'SubHeader';
		else if bottom then do; StyleID = 'Default10RedWrap'; MergeAcross = 10; Height = 25.5; end;
	run;

	%markup(ws_&ds._panel_note,ws_&ds._panel); 

	/* define the print area */
	data ws_&ds._names;
		length string $&strlen.; 

		string = '<Names>'; output;
		string = '<NamedRange ss:Name="Print_Area" ss:RefersTo="='||"'Front Page'"||'!R1C1:R40C11"/>'; output;
		string = '</Names>'; output;
	run;

	/* set up the worksheet settings */
	data ws_&ds._settings; 
		length string $&strlen.; 
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<PageSetup>'; output;
		string = '<Header x:Data="&amp;L'||'AE Severity Front Page'||
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
			ws_&ds._header
			ws_&ds._panel
			ws_&ds._table_end
			ws_&ds._settings
			ws_&ds._end;
	run;

	proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;

%mend out_cover;


/***********************************/
/* AES BY ARM / SERIOUS AES BY ARM */
/***********************************/
/* rpt = A/B controls whether to make output for report A or report B */
%macro out_ab(rpt=);

	%let rpt = %upcase(&rpt.);

	%let ds = ab_&rpt._output; 
	%let wstitle = %sysfunc(ifc(&rpt.=A,1 AEs by Arm,2 Serious AEs by Arm));

	/* get number of variables, observations, and by variables */
	%let dsid = %sysfunc(open(&ds.));
	%let nobs = %sysfunc(attrn(&dsid.,nobs));
	%let nvars = %sysfunc(attrn(&dsid.,nvars));
	%let rc = %sysfunc(close(&dsid.));

	%let nkeys = 2;
	%let nkeycols = 2;

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
		%if &rpt. = A %then %do;
			Data = 'Adverse Events by Organ Class and Term';
		%end;
		%else %do;
			Data = 'Serious Adverse Events by Organ Class and Term';
		%end;
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

		StyleID = 'Default10Wrap'; MergeAcross = 3;

		Row = %let row = %eval(&row. + 1); &row.;
		Height = 30;
		Data = 'Where subject count is the number of subjects in the treatment arm '||
               'experiencing at least one '||ifc("&rpt."='B','serious ','')||'adverse event '||
               'per organ class and term '||
			   %if &rpt. = A %then %do;
				  'and greater than 2% of subjects in any arm experienced at least one adverse event'||
			   %end;
			   '';
		output;

		Row = %let row = %eval(&row. + 1); &row.;
		Height = 12.75;
		Data = ''; StyleID = ''; output;
	run;

	%markup(ws_&ds._header_data,ws_&ds._header);

	/* make the footer */
	/* include a note about missing toxicity grades if there were any */
	data ws_&ds._footer_data; 
		retain group;
		length data $1000;

		group = 'note';
		data = 'NOTES:'; output;
		data = '1 This analysis uses the safety population '||
		       %if &vld_sw. %then %do;
               "and only counts adverse events that start between a subject's "|| 
               'first exposure and '||
               ifc(&study_lag.>0,"&study_lag. days after the subject's ",'')||'last exposure'||
			   %end;
               ''; output;
		%if &rpt. = B and &ae_aeser. %then %do;
			%if &all_ae_dm_ex_aeser_y. and not &all_ae_dm_ex_aeser_n. %then %do;
				data = '* All adverse events in this study were marked serious (AESER = Y)'; output;
			%end;
		%end;
	run; 

	%ws(&ds.); 
	%wsheader(ws_&ds._footer_data,ws_&ds._footer);

	/* column headers */
	data ws_&ds._columns_data;
		retain Row;
		%xml_tag_def;
		%xml_init;

		StyleID = 'ColumnOutline';
		Type='String';

		/* row 1 */
		Row = 1;
		Height = max(30,floor(&max_arm_nm_len./15)*13.75);
		MergeDown = 2;
		Data = 'Body System or Organ Class'; output;
		Data = 'Dictionary-Derived Term'; output;

		MergeAcross = 1; MergeDown = .;
		%do i = 1 %to %eval(&arm_count.+1);
			%if &i. < %eval(&arm_count.+1) %then %do;
				Data = "&&&arm_name_&i."; output;
			%end;
			%else %do;
				Data = 'Total'; output;
			%end;
		%end;
		MergeAcross = .;

		/* row 2 */
		Row = 2;
		Height = 15;
		MergeAcross = 1; MergeDown = .;
		%do i = 1 %to %eval(&arm_count.+1);
			Index = %sysfunc(ifc(&i.=1,%eval(&nkeycols.+1),.));
			%if &i. < %eval(&arm_count.+1) %then %do;
				Data = 'N='||put(&&&arm_&i.,comma7. -L); output;
			%end;
			%else %do;
				Data = 'N='||put(&arm_total.,comma7. -L); output;
			%end;
		%end;

		/* row 3 */
		Row = 3;
		Height = 30;
		MergeAcross = .; MergeDown = .;
		%do i = 1 %to %eval(&arm_count.+1);
			Index = %sysfunc(ifc(&i.=1,%eval(&nkeycols.+1),.));
			Data = 'Subject Count'; output;
			Index = .;
			Data = '%'; output;
		%end;
	run;

	%markup(ws_&ds._columns_data,ws_&ds._columns);


	/* data table */
	%annotate(&ds.,ws_&ds._data_note);

	data ws_&ds._data_note;
		set ws_&ds._data_note;
		
		if varname in ('aebodsys' 'aedecod') then StyleID = 'D_BLR';
		else if index(varname,'sum') then StyleID = 'D0_R2_BL';
		else if index(varname,'pct') then StyleID = 'D1_R2_BR';

		if bottom then StyleID = trim(StyleID)||'B';
	run;

	%markup(ws_&ds._data_note,ws_&ds._data);


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
                 'ss:RefersTo="='||"'&wstitle.'!R"||
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

		/* autofilter */
		string = '<AutoFilter x:Range="'||'R'||compress(%eval(&firstrow.-1))||'C1:R'||
                 compress(%eval(&firstrow.-1))||"C&nvars."||'" '||
                 'xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '</AutoFilter>'; output;

		/* conditional formatting for alternate row highlighting */
		string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&firstrow.C1:R&lastrow.C&nvars.</Range>"; output;
		string = '<Condition>'; output;
		string = "<Value1>MOD(SUBTOTAL(103,RC1:R2C1),2)=&fr_odd.</Value1>"; output;
		string = "<Format Style='background:silver'/>"; output;
		string = '</Condition>'; output;
		string = '</ConditionalFormatting>'; output;
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

%mend out_ab;

/***********************************/
/* AES BY ARM / SERIOUS AES BY ARM */
/***********************************/
/* rpt = C/D controls whether to make output for report C or report D */
%macro out_cd(rpt=);

	%let rpt = %upcase(&rpt.);

	%let ds = cd_&rpt._output; 
	%let wstitle = %sysfunc(ifc(&rpt.=C,3 AEs by Severity,4 Serious AEs by Severity));

	/* get number of variables, observations, and by variables */
	%let dsid = %sysfunc(open(&ds.));
	%let nobs = %sysfunc(attrn(&dsid.,nobs));
	%let nvars = %sysfunc(attrn(&dsid.,nvars));
	%let rc = %sysfunc(close(&dsid.));

	%let nkeys = 2;
	%let nkeycols = 2;

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
		%if &rpt. = C %then %do;
			Data = 'Adverse Events by Severity Level';
		%end;
		%else %do;
			Data = 'Serious Adverse Events by Severity Level';
		%end;
		output;

		/* store title for future use */
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

		StyleID = 'Default10Wrap'; MergeAcross = 5;

		Row = %let row = %eval(&row. + 1); &row.;
		Height = 12.75;
		Data = 'Where the number in each column is the number of '||ifc("&rpt."='D','serious ','')||
               'adverse events per treatment arm at the stated severity level.';
		output;

		Row = %let row = %eval(&row. + 1); &row.;
		Height = 12.75;
		Data = ''; StyleID = ''; output;
	run;

	%markup(ws_&ds._header_data,ws_&ds._header);

	/* make the footer */
	/* include a note about missing toxicity grades if there were any */
	data ws_&ds._footer_data; 
		retain group;
		length data $1000;

		group = 'note';
		data = 'NOTES:'; output;
		data = '1 This analysis uses the safety population '||
               "and only counts adverse events that are treatment emergent between a subject's "|| 
               'first exposure and '||
               ifc(&study_lag.>0,"&study_lag. days after the subject's ",'')||'last exposure'; output;
		%if &rpt. = D and &all_ae_dm_ex_aeser_y. and not &all_ae_dm_ex_aeser_n. %then %do;
			data = '* All adverse in this study were marked serious (AESER = Y)'; output;
		%end;
	run; 

	%ws(&ds.,colwidth=50); 
	%wsheader(ws_&ds._footer_data,ws_&ds._footer);

	/* column headers */
	data ws_&ds._columns_data;
		retain Row;
		%xml_tag_def;
		%xml_init;

		StyleID = 'ColumnOutline';
		Type='String';

		/* row 1 */
		Row = 1;
		Height = max(20,floor(&max_arm_nm_len./(&sev_count.*6.5))*13.75);
		MergeDown = 2;
		Data = 'Body System or Organ Class'; output;
		Data = 'Dictionary-Derived Term'; output;

		MergeAcross = %eval(&sev_count.-1); MergeDown = 1;
		%do i = 1 %to %eval(&arm_count.);
			Data = "&&&arm_name_&i."; output;
		%end;
		MergeAcross = .; MergeDown = 2;
		Data = 'Total'; output;

		/* row 2 */
		Row = 2;
		Height = 15;
		MergeAcross =.; MergeDown = .; 
		Index = %eval(&nkeycols.+&arm_count.*&sev_count.+1+1);
		StyleID = 'Default';
		Data = ''; output;
		StyleID = 'ColumnOutline';


		/* row 3 */
		Row = 3;
		Height = max(30,floor(&max_aesev_nm_len./5)*13.75);
		MergeAcross = .; MergeDown = .;
		%do i = 1 %to %eval(&arm_count.);	
			%do j = 1 %to &sev_count.;
			Index = %sysfunc(ifc(&i.=1 and &j.=1,%eval(&nkeycols.+1),.));
			Data = "&&&sev_name_&j."; output;
			%end;
		%end;
	run;

	%markup(ws_&ds._columns_data,ws_&ds._columns);


	/* data table */

	%annotate(&ds.,ws_&ds._data_note);

	data ws_&ds._data_note;
		set ws_&ds._data_note;

		if varname in ('aebodsys' 'aedecod') then StyleID = 'D_BLR';
		else if varname = 'sum_total' then StyleID = 'D0_R2_BLR';
		else if index(varname,'sev1') then StyleID = 'D0_R2_BL';
		else if index(varname,"sev&sev_count.") then StyleID = 'D0_R2_BR';
		else StyleID = 'D0_R2_B';

		if bottom then StyleID = trim(StyleID)||'B';
	run;

	%markup(ws_&ds._data_note,ws_&ds._data);

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
                 'ss:RefersTo="='||"'&wstitle.'!R"||
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

		/* autofilter */
		string = '<AutoFilter x:Range="'||'R'||compress(%eval(&firstrow.-1))||'C1:R'||
                 compress(%eval(&firstrow.-1))||"C&nvars."||'" '||
                 'xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '</AutoFilter>'; output;

		/* conditional formatting for alternate row highlighting */
		string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&firstrow.C1:R&lastrow.C&nvars.</Range>"; output;
		string = '<Condition>'; output;
		string = "<Value1>MOD(SUBTOTAL(103,RC1:R2C1),2)=&fr_odd.</Value1>"; output;
		string = "<Format Style='background:silver'/>"; output;
		string = '</Condition>'; output;
		string = '</ConditionalFormatting>'; output;
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

%mend out_cd;


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
		Height = max(1,ceil(length(trim(Data))/130))*12.75;
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
		Height = max(1,ceil(length(trim(compress(Data,'~!')))/125))*12.75;
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


	/***************************/
	/* MISSING SEVERITY LEVELS */
	/***************************/

	%if &ae_aesev. %then %do;

		/* make section header */
		data ws_rpt_missing_header_data; 
			retain group;
			length data $1000;

			group = 'subtitle';
			data = "Missing Severity Levels"; output;

			group = 'note';	
			data = 'Adverse events with missing severity levels appear '||
	               'in their own columns in the severity level reports.'; output; 
			data = 'Below, the total number of adverse events missing severity levels '||
	               'in each report is shown for each arm.'; output; 
		run;

		%wsheader(ws_rpt_missing_header_data,ws_rpt_missing_header);

		/* missing tox grade column headers */
		data ws_rpt_missing_columns_data;
			%xml_tag_def;
			%xml_init;

			Type = 'String';
			StyleID = 'ColumnOutline';

			Row = 1;
			Height = 25;
			Data = 'Missing Severity Level Summary'; MergeAcross = 2*&arm_count.; output;
			MergeAcross = .;

			Row = 2;
			Height = 40;
			Data = 'Report'; MergeDown = 1; output;
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
		%annotate(rpt_missing,ws_rpt_missing_data);

		data ws_rpt_missing_data;
			set ws_rpt_missing_data end=eof;
			by Row;

			Height = 12.75;

			if varname = 'report' then StyleID = 'DT_BLR';
			else if index(varname,'missing') then StyleID = 'D0_R1T_BL';
			if index(varname,'pct') then StyleID = 'D1_R1T_BR';

			if bottom then StyleID = trim(StyleID)||'B';
		run;

		%markup(ws_rpt_missing_data,ws_rpt_missing);

		/* missing report footer */
		data ws_rpt_missing_footer_data; 
			retain group;
			length data $1000;
			call missing(data);

			group = 'note';
			/*data = 'NOTES:'; output;
			data = '* Missing count is the sum of all adverse events, '||
	               'counting one per subject and stated level of aggregation, without a toxicity grade'; output; 
			data = '* % is the proportion of all adverse events, counting one per subject, '||
	               'made up by adverse events without a toxicity grade'; output;*/
		run;
		
		%wsheader(ws_rpt_missing_footer_data,ws_rpt_missing_footer);

	%end;


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
			%end;
			ws_null
			%if &ae_aesev. %then %do;
				ws_rpt_missing_header
				ws_rpt_missing_columns
				ws_rpt_missing
			%end;
			;
	run; 

	/* settings for alternating row highlighting */
	/* get the info on the first and last rows for the data validation by term */
	/* to set up alternate row highlighting */
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

	data ws_err_settings;
		length string $&strlen.; 
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<PageSetup>'; output;
		string = '<Layout x:Orientation="Landscape"/>'; output;
		string = '<Header x:Data="&amp;LAdverse Events Data Check Summary'||
                 '&amp;R'||"NDA/BLA &ndabla.&#10;Study &studyid."||'"/>'; output;
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



/* make a tab with a title and a note */
/* whenever the information required to make a report was not available */
%macro out_note(rpt=);

	%let rpt = %upcase(&rpt.);
	%if &rpt. = B %then %let ds = ab_b_output;
	%else %if &rpt. = C %then %let ds = cd_c_output;
	%else %if &rpt. = D %then %let ds = cd_d_output;

	data ws_&ds._table_data; 
		retain group;
		length data $1000 group $15;

		group = 'title';

		select ("&rpt.");
			when ('B') do;
						data = "Serious Adverse Events by Organ Class and Term";
						call symputx('wstitle','Serious AEs by Arm');
			           end;
			when ('C') do;
						data = "Adverse Events by Severity Level"; 
						call symputx('wstitle','AEs by Severity');
					   end;
			when ('D') do;
						data = "Serious Adverse Events by Severity Level"; 
						call symputx('wstitle','Serious AEs by Severity');
					   end;
			otherwise;
		end;
		output;

		group = 'subtitle';
		select ("&rpt.");
			when ('B') data = "AESER, the serious event variable, was not used in this study.";
			when ('C') data = "AESEV, the severity level variable, was not used in this study.";
			when ('D') do;
						if &ae_aeser. then 
							data = "AESEV, the severity level variable, was not used in this study.";
						else 
							data = "AESER, the serious event variable, and AESEV, "||
                                   "the severity level variable, were not used in this study.";
					   end;
			otherwise;
		end;
		output;
	run;

	%let nvars = 1;
	%let nkeycols = 0;
	
	%ws(&ds.);
	%wsheader(ws_&ds._table_data,ws_&ds._table);

	data ws_&ds.;
		set ws_&ds._start
			ws_&ds._table_start
			ws_&ds._table
			ws_&ds._table_end 
			ws_&ds._end;
	run;

	proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;

%mend out_note;


/* worksheet information */
/* establishes worksheet name, column widths, etc. */
/* one set per worksheet */
%macro ws(ds,keycolwidth=200,colwidth=61.5);

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
				string = '<Column ss:Width="'||"&colwidth"||'"/>'; output;
			%end;
		%end;
	run;

	data ws_&ds._table_end;
		length string $&strlen.; 
		string = '</Table>'; output;
	run;

%mend ws; 


/* create the XML styles used in this workbook */
%macro out_ae_styles;

	data wb_ae_styles_data;
		%xml_style_dcl;	
		ID = 'D'; output;

		ID = 'D0_R1'; NumFmt = '0'; HA = 'Right'; Indent = 1; output; 
		ID = 'D0_R2'; NumFmt = '0'; HA = 'Right'; Indent = 2; output; 
		ID = 'D0_R4'; NumFmt = '0'; HA = 'Right'; Indent = 4; output;
		ID = 'D1_R1'; NumFmt = '0.0'; HA = 'Right'; Indent = 1; output;
		ID = 'D1_R2'; NumFmt = '0.0'; HA = 'Right'; Indent = 2; output;
		HA = ''; Indent = .;

		ID = 'DT'; VA = 'Top'; Wrap = 1; output;
		Wrap = .;
		ID = 'D0_R1T'; NumFmt = '0'; HA = 'Right'; VA = 'Top'; Indent = 1; output; 
		ID = 'D1_R1T'; NumFmt = '0.0'; HA = 'Right'; VA = 'Top'; Indent = 1; output;
	run;
	
	data wb_ae_styles_data;
		set wb_ae_styles_data; 
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

	%xml_style_markup(wb_ae_styles_data,wb_ae_styles);

	proc datasets library=work nolist nodetails; delete wb_ae_styles_:; quit;

%mend out_ae_styles;


/************************/
/* begin running output */
/************************/
%macro out_ae; 

	/* print current activity to the log */
	data _null_;
		title = "MAKING EXCEL XML OUTPUT FOR ADVERSE EVENTS REPORT";
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
	%out_ae_styles;	

	data wb_styles;
		set wb_styles 
            wb_ae_styles end=eof;
		if string = '</Styles>' then delete;
		keep string;
		output;
		if eof then do; string = '</Styles>'; output; end;
	run;

	%out_cover;

	/* analyses A & B */
	%out_ab(rpt=a);
	%if &ae_aeser. %then %do; %out_ab(rpt=b); %end;
	%else %out_note(rpt=b);;

	/* analyses C & D */
	%if &ae_aesev. %then %do;
		%out_cd(rpt=c);
		%if &ae_aeser. %then %do; %out_cd(rpt=d); %end;
		%else %out_note(rpt=d);;
	%end;
	%else %do; 
		%out_note(rpt=c);
		%out_note(rpt=d);
	%end;
	%out_err

	data wb;
		set wb_start
		    wb_styles  
			ws_cover
			ws_ab_a_output
			ws_ab_b_output
			ws_cd_c_output
			ws_cd_d_output
			ws_err
			%if %sysfunc(exist(ws_sl_gs)) %then ws_sl_gs;
			wb_end;
	run;

	proc datasets library=work nolist nodetails; delete wb_:; quit;

	data _null_;
		set wb;
		file "&aeout1." ls=32767;
		put string;
	run;

%mend out_ae;
