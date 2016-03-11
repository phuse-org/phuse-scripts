%let wbtitle = MedDRA at a Glance Comparison Analysis;

/* length of the XML string */
/* must be wide enough to contain the longest string to be output */
%global strlen;
%let strlen = 1000;

*%include "&utilpath.\xml_output.sas";


/*********************************************************/
/* MedDRA AT A GLANCE COMPARISON ANALYSIS COVER SHEET */
/*********************************************************/
%macro out_cover;

	%let ds = cover;
	%let wstitle = Front Page;

	%let nkeys = 1;
	%let nkeycols = 1;
	%let nvars = 1;

	/* set up worksheet beginning and end sections */
	data ws_&ds._start;
		length string $&strlen.;
		string = '<Worksheet ss:Name="'||"&wstitle."||'">'; output; 
	run;

	data ws_&ds._end; 
		length string $&strlen.; 
		string = '</Worksheet>'; output;
	run;

	/* set up the column widths */
	data ws_&ds._table_start; 
		length string $&strlen.; 
		string = '<Table>'; output;
		string = '<Column ss:Width="16"/>'; output;
		string = '<Column ss:Width="125"/>'; output;
		string = '<Column ss:Width="21"/>'; output;
		do i = 1 to 5;
			string = '<Column ss:Width="13"/>'; output;
		end;
		do i = 1 to 2;
			do j = 1 to 2;
				string = ifc(j=1,'<Column ss:Width="50"/>','<Column ss:Width="35"/>'); output;
			end;
		end; 
		do i = 1 to 3;
			string = '<Column ss:Width="55"/>'; output;
		end;
		string = '<Column ss:Width="16"/>'; output;
		drop i j;
	run; 

	data ws_&ds._table_end;
		length string $&strlen.; 
		string = '</Table>'; output;
	run;

	/* make part 1 of the cover sheet */
	data ws_&ds._1_data; 
		length text $5000;
		text = ''; output;

		text = 'MedDRA at a Glance Comparison Analysis Front Page'; output;

		text = ''; output;

		text = 'NDA/BLA: '||"&ndabla."; output;
		text = 'Study: '||"&studyid."; output;
		text = "Analysis run date: &rundate."; output;

		text = ''; output;

		text = 'This analysis shows all system organ class, high-level group term, high-level '||
               'term, and preferred term MedDRA levels corresponding to the adverse events that '||
               'appear in the study. It allows you to choose which two arms to compare and '||
               'shows you subject counts and percentages (risks) for each chosen arm, the '||
               'risk difference and relative risk between the two arms, and a negative log p-value, '||
               'which ranks how noteworthy the association between the arms and the adverse event is. '||
               'Terms that exhibit signals are highlighted, where a signal is a risk difference, '||
               'relative risk, or negative log p-value  above a threshold value, which you '||
               'can also set.'; output;

		text = ''; output; 

		text = 'This analysis is for data exploration only. It should not be used for statistical inference.'; output;

		%if &arm_count. = 1 %then %do;
			text = ''; output; 

			text = 'You are examining a one-arm study. The comparison functions of this report are '||
                   'not available.'; output;
		%end;

		text = ''; output; 

		text = 'How To Use This Report'; output;

		text = '1. On the next tab, choose which arms you want to compare by selecting them '||
               'from the drop down menus that appear when you click in the yellow input cells for treatment '||
               'arm and control arm.'; output;

		text = ''; output; 

		text = '2. You can also choose what thresholds you want by typing in their respective yellow input cells. '||
               'A blank threshold means do not use that statistic; for example, if you only want to highlight '||
               'terms with risk differences above 5%, put 5 in the risk difference threshold (%) cell and '||
               'blank out the other two thresholds.'; output;

		text = ''; output; 

		text = '3. Once you have chosen your arms and thresholds, scroll down to see which terms are highlighted '||
               'to show that they have signals at your current threshold levels. You can also sort and filter '||
               'by each column using the drop-down menus on that column. When you filter a column, the arrow on '||
               'the drop-down button will turn from black to blue.'; output;

		text = ''; output; 

		text = 'Look for red arrows in the upper right corner of cells for hints on usage and '||
               'explanations of abbreviations.'; output;

		text = ''; output; 

		text = 'Here is an example line from the report. Each element is given a letter and explained below.'; output;

		text = ''; output;
	run;

	%annotate(ws_&ds._1_data,ws_&ds._1_note);

	data ws_&ds._1_note;
		set ws_&ds._1_note;

		if _n_ ne 1 then MergeAcross = 15; MergeDown = .;
		Height = max(1,ceil(length(Data)/135)) * 13.5;

		StyleID = 'Default10Wrap';

		if Data = 'MedDRA at a Glance Comparison Analysis Front Page' then do;
			StyleID = 'Header';
			Height = 15;
		end;
		else if Data in ('How To Use This Report'
                         'Toxicity Grade Summary'
                         'Preferred Term Analysis by Toxicity Grade') then StyleID = 'SubHeader';
	run;

	%markup(ws_&ds._1_note,ws_&ds._1); 

	/* make part 2 of the cover sheet, the example */
	data ws_&ds._2_note;
		retain Row;
		%xml_tag_def;
		%xml_init;

		/* column header */
		StyleID = 'ColumnOutline';
		Type='String';

		/* row 1 */
		Row = 1;
		Height = 13.5;
		MergeAcross = .; MergeDown = 2;
		StyleID = 'ColumnOutlineRotateCtr';
		Data = 'Level'; output;

		StyleID = 'ColumnOutline';
		Data = 'System Organ Class'; output; 

		StyleID = 'ColumnOutlineRotateCtr';
		MergeAcross = .; MergeDown = 2;	
		Data = 'DME'; output;
		Data = 'Signal'; output;

		StyleID = 'ColumnOutline';
		MergeAcross = 3; MergeDown = .;
		Data = 'Signal At'; output;

		MergeAcross = 1; MergeDown = .;
		Data = "Treatment:"; output;
		Data = "Control:"; output;
		MergeAcross = .;

		StyleID = 'ColumnOutline';
		MergeAcross = .; MergeDown = 2;
		Data = 'Risk Difference'; output; 
		Data = 'Relative Risk'; output;
		Data = 'Negative Log&#10;P-value'; output;

		Data = 'Sort Order'; StyleID = 'OR'; output;

		/* row 2 */
		Row = 2;
		StyleID = 'ColumnOutlineRotateCtr';
		Height = 20;
		MergeAcross = .; MergeDown = 1;
		Index = 5;
		Data = 'SOC'; output;
		Index = .;
		Data = 'HLGT'; output;
		Data = 'HLT'; output;
		Data = 'PT'; output;

		StyleID = 'ColumnOutline';
		MergeAcross = 1; MergeDown = .;
		Data = 'Arm 1'; output;
		Index = .;
		Data = 'Arm 2'; output;
		Formula = ''; MergeAcross = .;

		/* row 3 */
		Row = 3;
		Height = 30;
		MergeAcross = .; MergeDown = .;
		%do i = 1 %to 2;
			Index = %sysfunc(ifc(&i.=1,9,.));
			Data = 'Subject Count'; output;
			Index = .;
			Data = '%'; output;
		%end;

		/* example data row */
		Row = 4;
		Height = 11.25;	
		Type = 'Number'; StyleID = 'DataCenterBottom'; 
		Data = '1'; output;
		Type = 'String'; StyleID = 'DataBottom'; 
		Data = 'Blood and lymphatic system disorders'; output; 
		StyleID = 'DataCenterBottom';
		Data = '~!'; output;
		StyleID = 'Gray'; Data = 'Y'; output;
		StyleID = 'Red'; Data = 'Y'; output;
		StyleID = 'Peach'; Data = 'Y'; output;
		StyleID = 'Peach'; Data = 'Y'; output;
		StyleID = 'DataCenterBottom'; Data = ''; output;
		Type = 'Number';
		StyleID = 'D0_R2_BLB';
		Data = '100'; output;
		StyleID = 'D1_R1_BRB';
		Data = '20'; output;
		StyleID = 'D0_R2_BLB';
		Data = '50'; output;
		StyleID = 'D1_R1_BRB';
		Data = '10'; output;
		StyleID = 'D1_R2BR_BLRB';
		Data = '10'; output;
		StyleID = 'D1_R2_BLRB';
		Data = '2'; output;
		StyleID = 'D1_R2BR_BLRB';
		Data = '11.305077292'; output;
		StyleID = 'OW_BLRB';
		Data = ''; output;

		Row = 5;
		Height = 3; StyleID = 'D_B'; Data = ''; output;

		/* explanation numbers row */
		Row = 6;
		Type = 'String'; Height = 13.5; StyleID = 'B10O'; 
		Data = 'A'; output;	
		Data = 'B'; output;	
		Data = 'C'; output;	
		Data = 'D'; output;	
		Data = 'E'; MergeAcross = 3; output;	
		Data = 'F'; MergeAcross = 3; output;	
		Data = 'G'; MergeAcross = 2; output;	
		Data = 'H'; MergeAcross = .; output;
	run;

	%markup(ws_&ds._2_note,ws_&ds._2); 

	/* this step can be improved */
	/* it is several sections put together and as such the formatting code is rather confused */
	data ws_&ds._3_data;
		%xml_tag_def;
		%xml_init;

		Row = %let row = 1; &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'A'; output;
		Data = 'The MedDRA hierarchy level. Level 1 is system organ class; 2 is high-'||
               'level group term; 3 is high-level term; 4 is preferred term.'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'B'; output;
		Data = 'The MedDRA description of the adverse event.'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'C'; output;
		Data = 'An indicator for designated medical events.'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'D'; MergeDown = 7; output;
		MergeDown = .;
		Data = 'An indicator for whether the adverse event term had a signal, or if not, a signal '||
               'above or below. This column is color coded:'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Index = 2;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Index = 4; StyleID = 'DG'; Data = ''; output;
		Index = 6; StyleID = ''; MergeAcross = 10; 
		Data = 'There is a signal at this term'; output;
		Index = .; MergeAcross = .;

		Row = %let row = %eval(&row. + 1); &row.;
		Index = 4; StyleID = 'LG'; Data = ''; output;
		Index = 6; StyleID = ''; MergeAcross = 10; 
		Data = 'There is a signal above and/or below this term in the MedDRA hierarchy'; output;
		Index = .; MergeAcross = .;

		Index = 2;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'This term of the MedDRA hierarchy had a signal so it is dark gray. '||
               'If it did not have a signal but there was a signal above or below it, it would be light gray. '||
               'Otherwise, the cell in this column will be blank.'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'This column also has codes (which are not visible) that allow you to filter terms '||
               'based on where signals lie in the MedDRA hierarchy. If you want to view all terms '||
               'with a signal and their parent terms, click the drop-down menu for the signal column, '||
               'choose Custom, and show rows equal to Y (a signal is present) or containing B '||
               '(a signal is present at a term below it).'; output;

		Index = .;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'E'; MergeDown = 5; output;
		MergeDown = .;
		Data = 'Four columns indicating which levels have signals. These columns are color coded as follows:';
        output;

		Row = %let row = %eval(&row. + 1); &row.;
		Index = 2; Data = ''; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Index = 4; StyleID = 'R'; Data = ''; output;
		Index = 5; StyleID = ''; MergeAcross = 11; 
		Data = 'There is a signal at this term at the MedDRA level whose column this color appears in'; output;
		Index = .; MergeAcross = .;

		Row = %let row = %eval(&row. + 1); &row.;
		Index = 4; StyleID = 'P'; Data = ''; output;
		Index = 5; StyleID = ''; MergeAcross = 11; 
		Data = 'There is a signal at another MedDRA level whose column this color appears in'; output;
		Index = .; MergeAcross = .;

		Row = %let row = %eval(&row. + 1); &row.;
		Index = 2; Data = ''; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Index = 2;
		Data = 'This term had a signal (at SOC) and there were signals at the HLGT and HLT levels as well.'; output;

		Index = .;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'F'; output;
		Data = 'Subject counts and percentages for the treatment arm and control arm you have chosen.'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'G'; output;
		Data = 'The statistics comparing the treatment and control arms. Those that are above '||
               'thresholds are highlighted in red.'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'H'; output;
		Data = 'A column that allows you to restore the original MedDRA hierarchy sort order '||
               "using the Sort Ascending option in this column's drop-down menu."; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; Data = ''; output; 
	run; 

	data ws_&ds._3_data;
		set ws_&ds._3_data;	
		by Row;
		order = _n_;

		Type = 'String';

		if first.Row and Data ne '' and Index = . then StyleID = 'B10O';
		else if (not first.Row or Index = 2) and MergeAcross = . then MergeAcross = 14;
		if StyleID = '' then StyleID = 'I10';
	run;

	proc sql noprint;
		create table ws_&ds._3_note(drop=order) as
		select a.*, b.Height
		from ws_&ds._3_data(drop=Height) a
		left join (select Row, max(1,ceil(maxlen/130)) * 13.5 as Height
		           from (select Row, max(length(Data)) as maxlen
                         from ws_&ds._3_data
		                 where Data is not missing
		                 group by Row)) b
		on a.Row = b.Row
		order by order;
	quit;

	%markup(ws_&ds._3_note,ws_&ds._3); 

	/* method and calculations introduction */
	data ws_&ds._mc_note;
		%xml_tag_def;
		%xml_init;

		%let row = 0;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output; Data = ''; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'Method and Calculations'; output; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'An adverse event is determined by the system organ class, high-level group '||
               'term, high-level term, and preferred term corresponding to the '||
               'dictionary-defined term (AEDECOD) from the adverse event (AE) dataset.'||
			   %if &vld_sw. %then %do;
               "Only adverse events starting between subjects' first exposure and "||
               %sysfunc(ifc(&study_lag. ne 0,"&study_lag. days after ",''))||
               "subjects' last exposure are included in the analysis. "||
			   'Exposure dates are taken from variables EXSTDTC and EXENDTC in the exposure (EX) dataset; '||
               "if these dates are not available, subjects' reference start and end dates "||
               '(RFSTDTC and RFENDTC) from the demographics (DM) dataset are used instead. '||
			   %end;
               'Each adverse event is counted only once per subject. Treatment arm is determined '||
               'using the '||ifc(&dm_actarm.,'actual treatment arm (ACTARM)',
                                             'planned treatment arm (ARM)')||' from DM.'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'The following is a 2x2 contingency table which shows the quantities, '||
               'represented by the letters in the cells, used in the calculation of the '||
               'statistics in this report.'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
	run;

	data ws_&ds._mc_note;
		set ws_&ds._mc_note;

		if Data = 'Method and Calculations' then StyleID = 'SubHeader';
		else StyleID = 'Default10Wrap';
		MergeAcross = 14;

		Height = max(1,ceil(length(trim(Data))/108)) * 13.5;
	run; 

	%markup(ws_&ds._mc_note,ws_&ds._mc); 

	/* make part 4 of the cover sheet, 2x2 contingency table example */
	data ws_&ds._4_note;
		%xml_tag_def;
		%xml_init;

		Type = 'String';
		Height = 25;

		Row = 1;  
		StyleID = '';
		Data = ''; output; Data = ''; output;
		MergeAcross = 5;
		Data = ''; output; 	
		StyleID = 'Table';
		MergeAcross = 1; 
		Data = 'Arm 1'; output;
		Data = 'Arm 2'; output;

		Row = 2;  
		MergeAcross = .;
		StyleID = '';
		Data = ''; output; Data = ''; output;
		StyleID = 'Table';
		MergeAcross = 5;
		Data = 'Adverse event'; output;  
		MergeAcross = 1;
		Data = 'a'; output;
		Data = 'c'; output;

		Row = 3;    
		MergeAcross = .;
		StyleID = '';
		Data = ''; output; Data = ''; output;
		StyleID = 'Table';
		MergeAcross = 5;
		Data = 'No adverse event'; output; 	
		MergeAcross = 1;
		Data = 'b'; output;
		Data = 'd'; output;
	run;

	%markup(ws_&ds._4_note,ws_&ds._4); 

	/* make part 5 of the cover sheet -- calculation definitions */
	data ws_&ds._5_data;
		length raw $5000;
		raw = 
			",;
			Arm 1,;
			AE subject count:,a;
			Subject count:,a+b;
			AE % (risk):,a / (a+b);
			,;
			Arm 2,;
			AE subject count:,c;
			Subject count:,c+d;
			AE % (risk):,c / (c+d);
		    ,;
			Risk difference:,a/(a+b) - c/(c+d);
			Relative risk:,(a/(a+b)) / (c/(c+d));
			Negative log p-value:,-log(Fisher's exact test p-value);"; output;
	run;

	data ws_&ds._5_data;
		set ws_&ds._5_data;
		length line $1000 desc $250 calc $250;
		i = 1;
		line = scan(raw,i,';');
		do while (line ne '');
			desc = '~!~!~!'||left(scan(line,1,','));
			calc = left(scan(line,2,','));
			output;
			i = i+1;
			line = compress(scan(raw,i,';'),,'c');
		end;

		keep desc calc;
	run;

	%annotate(ws_&ds._5_data,ws_&ds._5_note);

	data ws_&ds._5_note;
		set ws_&ds._5_note;
		StyleID = 'Default10';
		if varname = 'desc' then MergeAcross = 1;
	run;

	%markup(ws_&ds._5_note,ws_&ds._5); 

	/* make a note about continuity correction and p-value (note added 12/28/2015 by PG)*/
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

			text = 'For terms where the control arm had zero subjects with an adverse event, a continuity '||
                   'correction of '||trim(cc)||' has been added to the quantities in each cell of the '||
                   'contingency table  before calculating relative risk. This avoids undefined relative risk '||
                   'values that would result when dividing by zero. Use caution with these results, since '||
                   'different continuity corrections yield different results and a notable relative risk '||
                   'statistic may only be an artifact of the correction used.'; 
			text = compbl(text); output;

		end;

		/* start of p-value note */

			text = ''; output;

			text = 'The negative log p value gives the relationship, between treatment and control, a number '|| 
				   'value that is easier to understand than a p-value and does not suggest '||'"statistical '||
				   'significance'||'". A stronger p-value (for example, 0.05) will have a higher negative log '||
				   'than a weak p-value (for example, 0.5). The higher the negative log p-value, the stronger '|| 
				   'the argument that there is a signal.';
		    text = compbl(text); output;

		/* end of p-value note */

		keep text;
	run;

	%annotate(ws_&ds._cc_data,ws_&ds._cc_note);

	data ws_&ds._cc_note;
		set ws_&ds._cc_note;

		MergeAcross = 15; MergeDown = .;
		Height = max(1,ceil(length(Data)/135)) * 13.5;

		StyleID = 'Default10Wrap';
	run;

	%markup(ws_&ds._cc_note,ws_&ds._cc); 

	/* make part 6 of the cover sheet */
	data ws_&ds._6_data;
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

		desc = '~!~!~!MedDRA version: '; setting = "&ver."; output;
		desc = '~!~!~!Continuity correction:'; select (&cc_sw.);
												when (1) setting = "&cc.";
												when (2) setting = 'The reciprocal of the opposite arm subject count';
												otherwise setting = 'No continuity correction';
											   end;	output;

		desc = ''; setting = ''; output;
		desc = ''; setting = ''; output;

		desc = 'Note that for cross-over studies, the analysis by arm in this report can only be used '||
               'to examine treatment sequences and not individual treatments because the analysis uses '||
               'planned treatment arm and not the timing of actual treatments.'; output;
	run; 

	%annotate(ws_&ds._6_data,ws_&ds._6_note);

	data ws_&ds._6_note;
		set ws_&ds._6_note;

		if varname = 'desc' then MergeAcross = 1;

		StyleID = 'Default10';
		if Data in ('Report Settings') then StyleID = 'SubHeader';
		else if bottom then do; StyleID = 'Default10RedWrap'; MergeAcross = 15; Height = 40.5; end;
	run;

	%markup(ws_&ds._6_note,ws_&ds._6); 

	/* define the print area */
	data ws_&ds._names;
		length string $&strlen.; 
		string = '<Names>'; output;
		string = '<NamedRange ss:Name="Print_Area" ss:RefersTo="='||"'Front Page'"||'!R1C1:R100C16"/>'; output;
		string = '</Names>'; output;
	run;

	/* set up the worksheet settings */
	data ws_&ds._settings; 
		length string $&strlen.; 
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<PageSetup>'; output;
		string = '<Header x:Data="&amp;L'||'MedDRA at a Glance Comparison Analysis Front Page'||
                 '&amp;R'||"NDA/BLA &ndabla.&#10;Study &studyid."||'"/>'; output;
		string = '<Footer x:Data="Page &amp;P of &amp;N"/>'; output;
		string = '</PageSetup>'; output;
		string = '<Print>'; output;
		string = '<ValidPrinterInfo/>'; output;
		string = '<Scale>82</Scale>'; output;
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
			ws_&ds._2 
			ws_&ds._3
			ws_&ds._mc
			ws_&ds._4
			ws_&ds._5
			ws_&ds._cc
			ws_&ds._6
			ws_&ds._table_end
			ws_&ds._settings
			ws_&ds._end;
	run;

	proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;

%mend out_cover;


/******************************/
/* MEDDRA COMPARISON ANALYSIS */
/******************************/
%macro out_meddra_cmp;

	%let ds = meddra_cmp_output; 
	%let wstitle = MedDRA Comparison Analysis;

	/* get number of variables, observations, and by variables */
	%let dsid = %sysfunc(open(&ds.));
	%let nobs = %sysfunc(attrn(&dsid.,nobs));
	%let nvars = %sysfunc(attrn(&dsid.,nvars));
	%let rc = %sysfunc(close(&dsid.));

	%let nkeys = 4;
	%let nkeycols = 4;
	%let fmt = N;

	data ws_&ds._start;
		length string $&strlen.;
		string = '<Worksheet ss:Name="'||"&wstitle."||'">'; output; 
	run;

	data ws_&ds._end; 
		length string $&strlen.; 
		string = '</Worksheet>'; output;
	run;

	/* set up the column widths */
	/* sysfunc-ifc calls hide columns that are empty when dealing with one-arm studies */
	data ws_&ds._table_start; 
		length string $&strlen.; 
		string = '<Table>'; output;
		/* MedDRA hierarchy level code */
		string = '<Column ss:Width="13"/>'; output;
		/* MedDRA hierarchy levels */
		do i = 1 to 4;
			string = '<Column ss:Width="120"/>'; output;
		end;
		/* designated medical event column */
		string = '<Column ss:Width="21"/>'; output;
		/* signal columns */
		do i = 1 to 5;
			string = '<Column ss:Width="13"'||%sysfunc(ifc(&arm_count.=1,' ss:Hidden="1"',''))||'/>'; output;
		end; 
		/* treatment arm */
		string = '<Column ss:Width="50"/>'; output;
		string = '<Column ss:Width="35"/>'; output;
		/* control arm */
		string = '<Column ss:Width="50"'||%sysfunc(ifc(&arm_count.=1,' ss:Hidden="1"',''))||'/>'; output;
		string = '<Column ss:Width="35"'||%sysfunc(ifc(&arm_count.=1,' ss:Hidden="1"',''))||'/>'; output;
		/* risk difference, relative risk, and negative log p-value */
		string = '<Column ss:Width="53"'||%sysfunc(ifc(&arm_count.=1,' ss:Hidden="1"',''))||'/>'; output;
		/* if the user has chosen to use continuity correction, show column headers for RR and CC */
		/* otherwise show only the column header for RR */
		%if &cc_sw. %then %do;
		string = '<Column ss:Width="43"'||%sysfunc(ifc(&arm_count.=1,' ss:Hidden="1"',''))||'/>'; output;
		string = '<Column ss:Width="13"'||%sysfunc(ifc(&arm_count.=1,' ss:Hidden="1"',''))||'/>'; output;
		%end;
		%else %do;
		string = '<Column ss:Width="53"'||%sysfunc(ifc(&arm_count.=1,' ss:Hidden="1"',''))||'/>'; output;
		%end;
		string = '<Column ss:Width="53"'||%sysfunc(ifc(&arm_count.=1,' ss:Hidden="1"',''))||'/>'; output;
		/* original MedDRA hierarchy sort order */
		string = '<Column ss:Width="13"/>'; output;
		drop i;
	run; 

	data ws_&ds._table_end;
		length string $&strlen.; 
		string = '</Table>'; output;
	run;

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
		Data = 'MedDRA at a Glance Comparison Analysis';
		output;

		/* store the title for future use */
		call symputx('wstitle_long',Data);

		%if (&sl_group_nobs. or &sl_subset_nobs.) %then %do;
			Row = %let row = %eval(&row. + 1); &row.;
			Data = "&sl_gs_desc."; StyleID = 'Default10'; output;
		%end;
	run;

	%markup(ws_&ds._header_data,ws_&ds._header);

	/* make the footer */
	data ws_&ds._footer_data; 
		retain group;
		length data $1000;

		group = 'note';
		data = 'NOTES:'; output;
		data = '1 This report is for data exploration only and should not be used for '||
               'statistical inference'; output;	
		data = '2 This analysis uses the safety population '||
		       %if &vld_sw. %then %do;
               "and only counts adverse events that start between a subject's "|| 
               'first exposure and '||
               ifc(&study_lag.>0,"&study_lag. days after the subject's ",'')||'last exposure'||
			   %end;
               ''; output;
		%if (&cc_sw. ne  0 and &arm_count. > 1) %then %do;
			data = '* Relative risk for the indicated term has been calculated after adjusting subject counts '||
	               'with a continuity correction of '||
	               ifc(&cc_sw.=2,'the reciprocal of the opposite arm subject count ',"&cc. ")||
	               'to avoid dividing by zero'; output;
			data = '* Use caution with these results, since different continuity corrections yield different '||
                   'results and a notable relative risk statistic may only be an artifact of the correction '||
                   'used'; output;
		%end;
	run; 

	%wsheader(ws_&ds._footer_data,ws_&ds._footer);

	/* define the part of the header where the user can specify thresholds */
	data ws_&ds._select_data;
		%xml_tag_def;
		%xml_init;

		Type = 'String';

		Row = 0;
		Index = 6;	Type = 'String'; MergeAcross = 10;
		StyleID = 'TBT';
		Data = ''; output;
		Index = .; MergeAcross = .; StyleID = '';

		Row = 1;
		Height = 13.5;
		Data = ''; output;
		StyleID = 'DefaultRight';
		Data = 'Treatment arm:'; 
		output;
		StyleID = 'I';
		MergeAcross = 1;
		Data = "&arm_name_1."; 
		Comment = 'Choose the treatment arm and control arm from the drop-down menus.';
		output;
		MergeAcross = .;
		Comment = ''; 
		StyleID = '';

		/* explanatory text box */
		Index = 6;	Type = 'String'; MergeAcross = 10;
		StyleID = 'TBM';
		Data = 'Choose your arms and type in your thresholds in the yellow input cells'; output;
		Index = .; MergeAcross = .; StyleID = '';

		Row = 2; 
		Height = 13.5;
		Data = ''; output;
		StyleID = 'DefaultRight';
		Data = 'Control arm:';
		output;	
		Comment = '';
		StyleID = 'I';
		MergeAcross = 1;
		Data = "&arm_name_2."; 
		output;	
		MergeAcross = .;
		StyleID = '';

		/* explanatory text box */
		Index = 6;	Type = 'String'; StyleID = 'TBM'; MergeAcross = 10;
		Data = 'Look below to see which terms have signals; you may have to scroll down'; output;
		Index = .; StyleID = ''; MergeAcross = .; 

		Row = 3;
		Height = 13.5;
		Data = ''; output;

		/* explanatory text box */
		Index = 6;	Type = 'String'; StyleID = 'TBM'; MergeAcross = 10;
		Data = 'The colors in the signal columns tell you about the signal:'; output;
		Index = .; StyleID = ''; MergeAcross = .; 

		Row = 4;
		Height = 13.5; 
		Type = 'String';
		Data = ''; output;
		StyleID = 'DefaultRight';
		Data = 'Risk difference threshold (%):'; 
		output;	
		Type = 'Number'; 
		StyleID = 'I';
		Data = "&rd_th."; 
		Comment = 'Set thresholds by typing in numbers here.';
		output;  
		Comment = ''; 
		StyleID = '';

		/* explanatory text box */
		Index = 6;	Type = 'String';
		StyleID = 'TBL'; Data = ''; output;
		Index = .;
		StyleID = 'DG'; Data = ''; output;
		StyleID = 'R'; Data = ''; output;
		StyleID = ''; Data = ''; output;
		StyleID = 'TBR'; MergeAcross = 6; Data = 'This term shows a signal'; output;
		StyleID = ''; MergeAcross = .; 

		Row = 5;
		Height = 13.5; 
		Type = 'String';
		Data = ''; output;
		StyleID = 'DefaultRight';
		Data = 'Relative risk threshold:'; output;
		Type = 'Number'; 
		StyleID = 'I';
		Data = "&rr_th."; output; 
		StyleID = '';

		/* explanatory text box */
		Index = 6;	Type = 'String';
		StyleID = 'TBL'; Data = ''; output;
		Index = .;
		StyleID = 'LG'; Data = ''; output;
		StyleID = 'P'; Data = ''; output;
		StyleID = ''; Data = ''; output;
		StyleID = 'TBR'; MergeAcross = 6; Data = 'A term above or below in MedDRA shows a signal'; output;
		StyleID = ''; MergeAcross = .; 

		Row = 6;
		Height = 13.5; 
		Type = 'String';
		Data = ''; output;
		StyleID = 'DefaultRight';
		Data = 'Negative log p-value threshold:'; output;
		Type = 'Number'; 
		StyleID = 'I';
		Data = "&pv_th."; output; 
		StyleID = '';

		/* explanatory text box */
		Index = 6;	Type = 'String'; StyleID = 'TBB'; MergeAcross = 10;
		Data = ''; output;
		Index = .; StyleID = ''; MergeAcross = .; 

		Row = 7; Height = .; Type = 'String'; Data = ''; output;
	run;

	%markup(ws_&ds._select_data,ws_&ds._select);

	/* when dealing with one-arm studies, hide selection rows */
	%if &arm_count. = 1 %then %do;
		data ws_&ds._select;
			set ws_&ds._select nobs=nobs;
			if string =: '<Row' and _n_ < nobs-3 then string = tranwrd(string,'>',' ss:Hidden="1">');
		run;
	%end;

	/* open the dataset to retrieve column numbers of variables */
	%let dsid = %sysfunc(open(&ds.));

	/* column headers */
	data ws_&ds._col_data;
		retain Row;
		%xml_tag_def;
		%xml_init;

		StyleID = 'ColumnOutline';
		Type='String';

		/* row 1 */
		Row = 1;
		Height = 13.5;
		MergeAcross = .; MergeDown = 2;
		StyleID = 'ColumnOutlineRotateCtr';
		Data = 'Level'; 
		Comment = '1 - SOC&#10;2 - HLGT&#10;3 - HLT&#10;4 - PT';
		output;
		Comment = '';

		StyleID = 'ColumnOutline';
		Data = 'System Organ Class'; output; 
		Data = 'High-Level Group Term'; output;
		Data = 'High-Level Term'; output;
		Data = 'Preferred Term'; output;

		StyleID = 'ColumnOutlineRotateCtr';
		MergeAcross = .; MergeDown = 2;	
		Data = 'DME'; 
		Comment = 'Designated Medical Event';
		output;  
		Comment = '';
		Data = 'Signal'; 
		Comment = 'Y - Signal&#10;A - Above&#10;AB - Above & Below&#10;B - Below';
		output;  
		Comment = '';

		StyleID = 'ColumnOutline';
		MergeAcross = 3; MergeDown = .;
		Data = 'Signal At'; output;

		MergeAcross = 1; MergeDown = .;
		Data = "Treatment:"; output;
		Data = "Control:"; output;
		MergeAcross = .;

		StyleID = 'ColumnOutline';
		MergeAcross = .; MergeDown = 2;
		Data = 'Risk Difference'; output; 
		MergeAcross = .; MergeDown = 2;
		StyleID = 'ColumnOutline';
		Data = 'Relative Risk'; %if &cc_sw. %then Data = trim(Data)||'*';; output;
		%if &cc_sw. %then %do;
		MergeAcross = .; MergeDown = 2;
		StyleID = 'COR';
		Data = 'Cont Corr'; 
		Comment = 'Continuity Correction';
		output;
		%end;
		StyleID = 'ColumnOutline';
		MergeAcross = .; MergeDown = 2;
		Data = 'Negative Log&#10;P-value'; 
		Comment = 'Negative log p-value ranks how strongly adverse events are associated with the arms';
		output;
		Comment = '';

		Data = 'Sort Order'; StyleID = 'OR'; Comment = 'Restore original MedDRA hierarchy sort order'; output;
		Comment = '';

		/* row 2 */
		Row = 2;
		StyleID = 'ColumnOutlineRotateCtr';
		Height = (ceil(&max_arm_nm_len./9)+1) * 13.5;
		MergeAcross = .; MergeDown = 1;
		Index = %sysfunc(varnum(&dsid.,sgnl_soc));
		Data = 'SOC'; output;
		Index = .;
		Data = 'HLGT'; output;
		Data = 'HLT'; output;
		Data = 'PT'; output;

		StyleID = 'ColumnOutline';
		MergeAcross = 1; MergeDown = .;
		Data = ''; Formula='=exp_name&&quot;&#10;N=&quot;&index(armn,exp)'; output;
		Index = .;
		Data = ''; Formula='=ctl_name&&quot;&#10;N=&quot;&index(armn,ctl)'; output;
		Formula = ''; MergeAcross = .;

		/* row 3 */
		Row = 3;
		Height = 27;
		MergeAcross = .; MergeDown = .;
		%do i = 1 %to 2;
			Index = %sysfunc(ifc(&i.=1,%sysfunc(varnum(&dsid.,arm_exp_count)),.));
			Data = 'Subject Count'; output;
			Index = .;
			Data = '%'; output;
		%end;
	run;

	%let rc = %sysfunc(close(&dsid.));

	%markup(ws_&ds._col_data,ws_&ds._columns);

	/* data rows */
	%annotate(&ds.,ws_&ds._data_note);

	/* add level name and number by row */
	data ws_&ds._data_note;
		set ws_&ds._data_note; 
		by Row;

		/* look up the MedDRA level name and number */
		if _n_ = 1 then do;
			declare hash h(dataset:"&ds._row");
			h.definekey('Row');
			h.definedata('lvl_nm','lvl_no');
			h.definedone();
		end;

		length lvl_nm $4 lvl_no 8;
		call missing(lvl_nm,lvl_no);
		rc = h.find();
		drop rc;

		if varname in ('rd' 'rr' 'cc' 'pv' 'row') or varname =: 'arm' then do;
			if varname in ('rd' 'pv') then StyleID = 'D1_R2_BLR';
			else if varname = 'rr' then do;
				if &cc_sw. then StyleID = 'D1_R1_BL';
				else StyleID = 'D1_R2_BLR';
			end;
			else if varname = 'cc' then StyleID = 'IB_BR';
			else if varname = 'row' then StyleID = 'OW_BLR';
			else if index(varname,'count') then StyleID = 'D0_R2_BL';
			else if index(varname,'pct') then StyleID = 'D1_R1_BR';
			if bottom then StyleID = trim(StyleID)||'B';
		end;
		else do;
			StyleID = 'D';
			if varname in ('level','dme','sgnl','sgnl_soc','sgnl_hlgt','sgnl_hlt','sgnl_pt') then StyleID = 'DC';
			if bottom then StyleID = trim(StyleID)||'B';
		end;

		select (varname);
			when ('arm_exp_count') 
				Formula = '=INDEX(INDIRECT(&quot;ae'||trim(lvl_nm)||'&quot;&amp;exp),'||compress(lvl_no)||',1)';
			when ('arm_exp_pct') 
				Formula = '=INDEX(INDIRECT(&quot;ae'||trim(lvl_nm)||'&quot;&amp;exp),'||compress(lvl_no)||',2)';
			when ('arm_ctl_count') 
				Formula = '=INDEX(INDIRECT(&quot;ae'||trim(lvl_nm)||'&quot;&amp;ctl),'||compress(lvl_no)||',1)';
			when ('arm_ctl_pct') 
				Formula = '=INDEX(INDIRECT(&quot;ae'||trim(lvl_nm)||'&quot;&amp;ctl),'||compress(lvl_no)||',2)';
			when ('sgnl') 
				Formula = '=INDEX(ae'||trim(lvl_nm)||'scd,'||compress(lvl_no)||')';
			when ('sgnl_soc') 
				Formula = '=INDEX(ae'||trim(lvl_nm)||'s,'||compress(lvl_no)||',1)';
			when ('sgnl_hlgt') 
				Formula = '=INDEX(ae'||trim(lvl_nm)||'s,'||compress(lvl_no)||',2)';
			when ('sgnl_hlt') 
				Formula = '=INDEX(ae'||trim(lvl_nm)||'s,'||compress(lvl_no)||',3)';
			when ('sgnl_pt') 
				Formula = '=INDEX(ae'||trim(lvl_nm)||'s,'||compress(lvl_no)||',4)';
			when ('rd') 
				Formula = '=INDEX(ae'||trim(lvl_nm)||'c,'||compress(lvl_no)||',1)';
			when ('rr') 
				Formula = '=INDEX(ae'||trim(lvl_nm)||'c,'||compress(lvl_no)||',2)';
			%if &cc_sw. ne 0 %then %do;
				when ('cc') 
					Formula = '=INDEX(ae'||trim(lvl_nm)||'cc,'||compress(lvl_no)||')';
			%end;
			when ('pv') 
				Formula = '=INDEX(ae'||trim(lvl_nm)||'c,'||compress(lvl_no)||',3)';
			otherwise;
		end;

		/* correct for Excel cell overflow into DME column */
		/* ~! is changed to a space by the markup macro */
		if varname = 'dme' and Data = '' then Data = '~!';

	run;

	%markup(ws_&ds._data_note,ws_&ds._data);

	/* get the row numbers for the first and last data rows */
	data _null_;
		set ws_&ds._header
			ws_&ds._select
		    ws_&ds._columns end=eof;
		retain count;
		if string in ('<Row/>' '</Row>') then count + 1;
		if eof then do;	
			firstrow = count + 1;
			lastrow =  firstrow + &nobs. - 1;
			call symputx('firstrow',put(firstrow,8. -L));
			call symputx('lastrow',put(lastrow,8. -L));
		end;
	run; 

	/* get the number of the first row for the user input cells */
	data _null_;
		set ws_&ds._header end=eof;
		retain count;
		if string in ('<Row/>' '</Row>') then count + 1;
		if eof then do;
			rownum = count + 2;
			call symputx('input_firstrow',put(rownum,8. -L));
		end;
	run;

	/* get the column number for the signal variable */
	data _null_;
		dsid = open("&ds.");
		varnum = varnum(dsid,'sgnl');
		rc = close(dsid);
		call symputx('sgnl_varnum',varnum);
	run;

	/* set up the worksheet settings for conditional formatting and autofilter */
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
		string = '<ActiveRow>'||compress(%eval(&input_firstrow.-1))||'</ActiveRow>'; output;
		string = '<ActiveCol>2</ActiveCol>'; output;
		string = '<RangeSelection>R'||compress(%eval(&input_firstrow.))||'C3:'||
                 'R'||compress(%eval(&input_firstrow.))||'C4</RangeSelection>'; output;
		string = '</Pane>'; output;
		string = '</Panes>'; output;

		string = '</WorksheetOptions>'; output;

		/* open the dataset so we can extract the variable numbers of columns by name */
		%let dsid = %sysfunc(open(&ds.));

		string = '<AutoFilter x:Range="'||'R'||compress(%eval(&firstrow.-1))||'C1:R'||
                 compress(%eval(&firstrow.-1))||"C&nvars."||'" '||
                 'xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '</AutoFilter>'; output;

		/* highlight columns or cells when there is a signal present */
		/* term description columns */
		string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&firstrow.C1:R&lastrow.C"||compress(%sysfunc(varnum(&dsid.,pt_name)))||'</Range>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(RC'||"&sgnl_varnum."||'=&quot;&quot;,1,0)</Value1>'; output;
		string = "<Format Style='color:silver'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(OR(RC'||"&sgnl_varnum."||'=&quot;A&quot;,RC'||"&sgnl_varnum."||'=&quot;AB&quot;,RC'||"&sgnl_varnum."||'=&quot;B&quot;),1,0)</Value1>'; output;
		string = "<Format Style='color:gray'/>"; output;
		string = '</Condition>'; output;
		string = '</ConditionalFormatting>'; output;

		/* any signal indicator column */
		string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&firstrow.C"||"&sgnl_varnum."||
                 ":R&lastrow.C"||"&sgnl_varnum."||"</Range>"; output;
		string = '<Condition>'; output;
		string = '<Qualifier>Equal</Qualifier>'; output;
		string = '<Value1>&quot;Y&quot;</Value1>'; output;
		string = "<Format Style='color:gray;background:gray'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(OR(RC'||"&sgnl_varnum."||'=&quot;A&quot;,RC'||"&sgnl_varnum."||'=&quot;AB&quot;,RC'||"&sgnl_varnum."||'=&quot;B&quot;),1,0)</Value1>'; output;
		string = "<Format Style='color:silver;background:silver'/>"; output;
		string = '</Condition>'; output;
		string = '</ConditionalFormatting>'; output; 

		/* level-specific signal indicator columns */
		string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&firstrow.C"||compress(%sysfunc(varnum(&dsid.,sgnl_soc)))||
                 ":R&lastrow.C"||compress(%sysfunc(varnum(&dsid.,sgnl_pt)))||"</Range>"; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(RC=&quot;Y&quot;,1,0)</Value1>'; output;
		string = "<Format Style='color:#FFCC99;background:#FFCC99'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(AND(RC=&quot;Y&quot;,COLUMN()-COLUMN(RC'||"&sgnl_varnum."||')=RC1),1,0)</Value1>'; output;
		string = "<Format Style='color:red;background:red'/>"; output;
		string = '</Condition>'; output;
		string = '</ConditionalFormatting>'; output; 

		/* subject counts and percentage columns */
		string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&firstrow.C"||compress(%sysfunc(varnum(&dsid.,arm_exp_count)))||":R&lastrow.C"||
                 compress(%sysfunc(varnum(&dsid.,arm_ctl_pct)))||"</Range>"; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(RC'||"&sgnl_varnum."||'=&quot;&quot;,1,0)</Value1>'; output;
		string = "<Format Style='color:silver'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(OR(RC'||"&sgnl_varnum."||'=&quot;A&quot;,RC'||"&sgnl_varnum."||'=&quot;AB&quot;,RC'||"&sgnl_varnum."||'=&quot;B&quot;),1,0)</Value1>'; output;
		string = "<Format Style='color:gray'/>"; output;
		string = '</Condition>'; output;
		string = '</ConditionalFormatting>'; output;

		/* rd column */
		string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&firstrow.C"||compress(%sysfunc(varnum(&dsid.,rd)))||":R&lastrow.C"||
                 compress(%sysfunc(varnum(&dsid.,rd)))||"</Range>"; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(RC'||"&sgnl_varnum."||'=&quot;&quot;,1,0)</Value1>'; output;
		string = "<Format Style='color:silver'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(OR(RC'||"&sgnl_varnum."||'=&quot;A&quot;,RC'||"&sgnl_varnum."||'=&quot;AB&quot;,RC'||"&sgnl_varnum."||'=&quot;B&quot;),1,0)</Value1>'; output;
		string = "<Format Style='color:gray'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Qualifier>Greater</Qualifier>'; output;
		string = '<Value1>rd</Value1>'; output;
		string = "<Format Style='color:red;font-weight:700'/>"; output;
		string = '</Condition>'; output;
		string = '</ConditionalFormatting>'; output;

		/* rr column */
		string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&firstrow.C"||compress(%sysfunc(varnum(&dsid.,rr)))||":R&lastrow.C"||
                 compress(%sysfunc(varnum(&dsid.,rr)))||"</Range>"; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(RC'||"&sgnl_varnum."||'=&quot;&quot;,1,0)</Value1>'; output;
		string = "<Format Style='color:silver'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(OR(RC'||"&sgnl_varnum."||'=&quot;A&quot;,RC'||"&sgnl_varnum."||'=&quot;AB&quot;,RC'||"&sgnl_varnum."||'=&quot;B&quot;),1,0)</Value1>'; output;
		string = "<Format Style='color:gray'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(AND(RC&gt;rr,RC&lt;&gt;&quot;.&quot;),1,0)</Value1>'; output;
		string = "<Format Style='color:red;font-weight:700'/>"; output;
		string = '</Condition>'; output;
		string = '</ConditionalFormatting>'; output;

		%if &cc_sw. %then %do;
		/* continuity correction indicator column */
		string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&firstrow.C"||compress(%sysfunc(varnum(&dsid.,cc)))||":R&lastrow.C"||
                 compress(%sysfunc(varnum(&dsid.,cc)))||'</Range>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(RC'||"&sgnl_varnum."||'=&quot;&quot;,1,0)</Value1>'; output;
		string = "<Format Style='color:silver'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(OR(RC'||"&sgnl_varnum."||'=&quot;A&quot;,RC'||"&sgnl_varnum."||'=&quot;AB&quot;,RC'||"&sgnl_varnum."||'=&quot;B&quot;),1,0)</Value1>'; output;
		string = "<Format Style='color:gray'/>"; output;
		string = '</Condition>'; output;
		string = '</ConditionalFormatting>'; output;
		%end;

		/* pv column */
		string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&firstrow.C"||compress(%sysfunc(varnum(&dsid.,pv)))||":R&lastrow.C"||
                 compress(%sysfunc(varnum(&dsid.,pv)))||"</Range>"; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(RC'||"&sgnl_varnum."||'=&quot;&quot;,1,0)</Value1>'; output;
		string = "<Format Style='color:silver'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(OR(RC'||"&sgnl_varnum."||'=&quot;A&quot;,RC'||"&sgnl_varnum."||'=&quot;AB&quot;,RC'||"&sgnl_varnum."||'=&quot;B&quot;),1,0)</Value1>'; output;
		string = "<Format Style='color:gray'/>"; output;
		string = '</Condition>'; output;
		string = '<Condition>'; output;
		string = '<Value1>IF(AND(RC&gt;pv,RC&lt;&gt;&quot;.&quot;),1,0)</Value1>'; output;
		string = "<Format Style='color:red;font-weight:700'/>"; output;
		string = '</Condition>'; output;
		string = '</ConditionalFormatting>'; output; 

		%let rc = %sysfunc(close(&dsid.));
	run;

	/* removes settings for the initial cell selected when using one-arm studies */
	%if &arm_count. = 1 %then %do;
		data ws_&ds._settings;
			set ws_&ds._settings;
			retain panes 0;
			if string = '<Panes>' then panes = 1;

			lag_string = lag1(string);
			if lag_string = '</Panes>' then panes = 0;

			if panes then delete;
			keep string;
		run;
	%end;

	/* set up the named ranges for user input cells */
	data wb_&ds._names;
		length string $&strlen.;
		string = '<NamedRange ss:Name="exp_name" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&input_firstrow.))||'C3"/>'; output; 	
		string = '<NamedRange ss:Name="ctl_name" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&input_firstrow.+1))||'C3"/>'; output; 	
		string = '<NamedRange ss:Name="rdn" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&input_firstrow.+3))||'C3"/>'; output; 	
		string = '<NamedRange ss:Name="rrn" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&input_firstrow.+3+1))||'C3"/>'; output; 
		string = '<NamedRange ss:Name="pvn" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&input_firstrow.+3+2))||'C3"/>'; output; 
	run;

	/* worksheet specific named range */
	/* repeat column headers on successive printed pages */
	/* consider making this pick up the rows at run time */
	data ws_&ds._names;
		length string $&strlen.;
		string = '<Names>'; output;
		string = '<NamedRange ss:Name="Print_Titles" '||
                 'ss:RefersTo="='||"'"||"&wstitle."||"'"||'!R11:R13"/>'; output;
		string = '</Names>'; output;
	run;

	/* set up data validation for user input cells */
	data ws_&ds._vld;
		length string $&strlen.;

		string = '<DataValidation xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = "<Range>R&input_firstrow.C3,R"||compress(%eval(&input_firstrow.+1))||"C3</Range>"; output;
		string = '<Type>List</Type>'; output;
		string = '<Value>wbinfo_arminfo_1</Value>'; output;
		string = '</DataValidation>'; output;
	run;
	
	/* put the worksheet together */
	data ws_&ds.;
		set ws_&ds._start
			ws_&ds._names
		    ws_&ds._table_start
			ws_&ds._header
			ws_&ds._select
		    ws_&ds._columns
			ws_&ds._data
			ws_&ds._footer
			ws_&ds._table_end
			ws_&ds._settings
			ws_&ds._vld
			ws_&ds._end;
	run;

	proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;

%mend out_meddra_cmp;


/* hidden data worksheet */
/* referenced by the visible 'interface' worksheet */
%macro out_meddra_cmp_data;

	%let ds = meddra_cmp_data; 
	%let wstitle = MedDRA Comparison Data;

	%let nvars = 1;
	%let nkeycols = 0;
	%let fmt = N;

	data ws_&ds._start;
		length string $&strlen.;
		string = '<Worksheet ss:Name="'||"&wstitle."||'">'; output; 
	run;

	data ws_&ds._end; 
		length string $&strlen.; 
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<Visible>SheetHidden</Visible>'; output;
		string = '<ProtectObjects>False</ProtectObjects>'; output;
		string = '<ProtectScenarios>False</ProtectScenarios>'; output;
		string = '</WorksheetOptions>'; output;
		string = '</Worksheet>'; output;
	run;

	data ws_&ds._table_start; 
		length string $&strlen.; 
		string = '<Table>'; output;
	run; 

	data ws_&ds._table_end;
		length string $&strlen.; 
		string = '</Table>'; output;
	run;

	%annotate(&ds.,ws_&ds._data_note);

	/* add level name and number by row */
	data ws_&ds._data_note;
		set ws_&ds._data_note;
		by Row;

		/* look up the MedDRA level name and number */
		if _n_ = 1 then do;
			declare hash h(dataset:"&ds._row");
			h.definekey('Row');
			h.definedata('lvl_nm','lvl_no','soc','hlgt','hlt','pt');
			h.definedone();
		end;

		length lvl_nm $4 lvl_no 8 soc 8 hlgt 8 hlt 8 pt 8;
		call missing(lvl_nm,lvl_no,soc,hlgt,hlt,pt);
		rc = h.find();
		drop rc;

		/* missing, undefined, and infinite values */
		if substr(varname,1,min(length(trim(varname)),2)) in ('rd' 'rr' 'pv') then do;
			*if Data = 'I' and Type  = 'Number' then Type = 'String';
			if Data = '' and Type = 'Number' then do;
				Data = '.'; Type = 'String';
			end;
		end;

		%let dsid = %sysfunc(open(&ds.));

		/* assign formulas for the arm comparison cells */
		/* look at the cmp named cell specifying which two arms to use */
		/* and pick out the corresponding cell in the named range for that set of arms e.g. cmp12 */
		select (varname);
			when ('rd') 
				Formula = '=INDEX(INDIRECT(&quot;aecmp&quot;&amp;cmp),'||compress(row)||',1)';
			when ('rr') 
				Formula = '=INDEX(INDIRECT(&quot;aecmp&quot;&amp;cmp),'||compress(row)||',2)';
			when ('pv') 
				Formula = '=INDEX(INDIRECT(&quot;aecmp&quot;&amp;cmp),'||compress(row)||',3)';
			%if &cc_sw. %then %do;
				when ('cc') 
					Formula = '=INDEX(INDIRECT(&quot;ccind&quot;&amp;cmp),'||compress(row)||')';
			%end;
			when ('sgnl')
				Formula = '=IF(OR(RC'||compress(%sysfunc(varnum(&dsid.,rd)))||'&gt;rd,
                                  AND(RC'||compress(%sysfunc(varnum(&dsid.,rr)))||'&lt;&gt;&quot;.&quot;,
                                      RC'||compress(%sysfunc(varnum(&dsid.,rr)))||'&gt;rr),
                                  AND(RC'||compress(%sysfunc(varnum(&dsid.,pv)))||'&lt;&gt;&quot;.&quot;,
                                      RC'||compress(%sysfunc(varnum(&dsid.,pv)))||'&gt;pv)),
                               &quot;Y&quot;,
                               &quot;&quot;)';
			otherwise;
		end;

		/* assign formulas for the signal cells */
		/* look up, over, or down depending on the level */
		select (lvl_nm);
			when ('soc') do;
				select (varname);
					when ('sgnl_soc') Formula = '=RC[-1]';
					when ('sgnl_hlgt') do;
						Formula = '=IF(ISNA(MATCH(&quot;Y&quot;,IF(gs='||compress(soc)||
                                  ',OFFSET(gs,0,'||
                                  compress(%sysfunc(varnum(&dsid.,sgnl_hlgt))-%sysfunc(varnum(&dsid.,soc)))||
                                  '),),0)),&quot;&quot;,&quot;Y&quot;)';
						ArrayRange = 'RC';
					end;
					when ('sgnl_hlt') do;
						Formula = '=IF(ISNA(MATCH(&quot;Y&quot;,IF(gs='||compress(soc)||
                                  ',OFFSET(gs,0,'||
                                  compress(%sysfunc(varnum(&dsid.,sgnl_hlt))-%sysfunc(varnum(&dsid.,soc)))||
                                  '),),0)),&quot;&quot;,&quot;Y&quot;)';
						ArrayRange = 'RC';
					end;
					when ('sgnl_pt') do;
						Formula = '=IF(ISNA(MATCH(&quot;Y&quot;,IF(gs='||compress(soc)||
                                  ',OFFSET(gs,0,'||
                                  compress(%sysfunc(varnum(&dsid.,sgnl_pt))-%sysfunc(varnum(&dsid.,soc)))||
                                  '),),0)),&quot;&quot;,&quot;Y&quot;)';
						ArrayRange = 'RC';
					end;
					otherwise;
				end;
			end;
			when ('hlgt') do;
				select (varname);
					when ('sgnl_soc') Formula = '=INDEX(aesocs,'||compress(soc)||',1)';
					when ('sgnl_hlgt') Formula = '=RC[-2]';
					when ('sgnl_hlt') do;
						Formula = '=IF(ISNA(MATCH(&quot;Y&quot;,IF(hg='||compress(hlgt)||
                                  ',OFFSET(hg,0,'||
                                  compress(%sysfunc(varnum(&dsid.,sgnl_hlt))-%sysfunc(varnum(&dsid.,hlgt)))||
                                  '),),0)),&quot;&quot;,&quot;Y&quot;)';
						ArrayRange = 'RC';
					end;
					when ('sgnl_pt') do;
						Formula = '=IF(ISNA(MATCH(&quot;Y&quot;,IF(hg='||compress(hlgt)||
                                  ',OFFSET(hg,0,'||
                                  compress(%sysfunc(varnum(&dsid.,sgnl_pt))-%sysfunc(varnum(&dsid.,hlgt)))||
                                  '),),0)),&quot;&quot;,&quot;Y&quot;)';
						ArrayRange = 'RC';
					end;
					otherwise;
				end;
			end;
			when ('hlt') do;
				select (varname);
					when ('sgnl_soc') Formula = '=INDEX(aesocs,'||compress(soc)||',1)';
					when ('sgnl_hlgt') Formula = '=INDEX(aehlgts,'||compress(hlgt)||',2)';
					when ('sgnl_hlt') Formula = '=RC[-3]';
					when ('sgnl_pt') do;
						Formula = '=IF(ISNA(MATCH(&quot;Y&quot;,IF(ph='||compress(hlt)||
                                  ',OFFSET(ph,0,'||
                                  compress(%sysfunc(varnum(&dsid.,sgnl_pt))-%sysfunc(varnum(&dsid.,hlt)))||
                                  '),),0)),&quot;&quot;,&quot;Y&quot;)';
						ArrayRange = 'RC';
					end;
					otherwise;
				end;
			end;
			when ('pt') do;
				select (varname);
					when ('sgnl_soc') Formula = '=INDEX(aesocs,'||compress(soc)||',1)';
					when ('sgnl_hlgt') Formula = '=INDEX(aehlgts,'||compress(hlgt)||',2)';
					when ('sgnl_hlt')Formula = '=INDEX(aehlts,'||compress(hlt)||',3)';
					when ('sgnl_pt') Formula = '=RC[-4]';
					otherwise;
				end;
			end;
			otherwise;
		end;

		/* assign formulas for the cell indicating a signal at any level */
		/* Y -> signal at this level; A -> signal above; B -> signal below */
		if varname = 'sgnl_any' then select (lvl_nm);
			when ('soc') Formula = '=IF(RC[-4]=&quot;Y&quot;,&quot;Y&quot;,'||
                                   'IF(OR(RC[-3]=&quot;Y&quot;,'||
                                   'RC[-2]=&quot;Y&quot;,RC[-1]=&quot;Y&quot;),'||
                                   '&quot;B&quot;,&quot;&quot;))';
			when ('hlgt') Formula = '=IF(RC[-3]=&quot;Y&quot;,&quot;Y&quot;,'||
                                    'IF(RC[-4]=&quot;Y&quot;,&quot;A&quot;,&quot;&quot;)&amp;'||
                                    'IF(OR(RC[-2]=&quot;Y&quot;,RC[-1]=&quot;Y&quot;),'||
                                    '&quot;B&quot;,&quot;&quot;))';
			when ('hlt') Formula =  '=IF(RC[-2]=&quot;Y&quot;,&quot;Y&quot;,'||
                                    'IF(OR(RC[-4]=&quot;Y&quot;,RC[-3]=&quot;Y&quot;),&quot;A&quot;,&quot;&quot;)&amp;'||
                                    'IF(RC[-1]=&quot;Y&quot;,'||
                                    '&quot;B&quot;,&quot;&quot;))';
			when ('pt') Formula =   '=IF(RC[-1]=&quot;Y&quot;,&quot;Y&quot;,'||
                                    'IF(OR(RC[-4]=&quot;Y&quot;,RC[-3]=&quot;Y&quot;,RC[-2]=&quot;Y&quot;),'||
                                    '&quot;A&quot;,&quot;&quot;))';
			otherwise;
		end;

		%let rc = %sysfunc(close(&dsid.));
	run;

	%markup(ws_&ds._data_note,ws_&ds._data);

	/* put the worksheet together */
	data ws_&ds.;
		set ws_&ds._start
		    ws_&ds._table_start
			ws_&ds._data
			ws_&ds._table_end
			ws_&ds._end;
	run;

	/* set up named ranges for each section of the hidden overview data worksheet */
	/* first get the start and end row numbers for each section (soc, hlgt, hlt, pt) */
	data _null_;
		set meddra_cmp_data_row;
		by lvl_nm notsorted;
		if first.lvl_nm then do; 
			group + 1;
			call symputx('row'||compress(group)||'s',row);
		end;
		if last.lvl_nm then call symputx('row'||compress(group)||'e',row);
	run;

	/* open dataset to extract column numbers for variables */
	%let dsid = %sysfunc(open(&ds.));

	/* create named ranges for each respective section of the hidden data sheet */
	data wb_&ds._names;
		length string $&strlen.;
		%do i = 1 %to &arm_count.;
			%do j = 1 %to 4;
				%let lvl = %scan(soc hlgt hlt pt,&j.);
				/* AE counts and rates for each arm, split up by MedDRA hierarchy level */
				/* e.g. soc1 is the set of counts/rates for the SOC term in arm 1 */
				string = '<NamedRange ss:Name="'||"ae&lvl.&i."||'" ss:RefersTo="='||"'"||"&wstitle."||"'"||
		                 '!R'||compress("&&&row&j.s.")||'C'||compress(%sysfunc(varnum(&dsid.,arm&i._count)))||':'||
		                 'R'||compress("&&&row&j.e.")||'C'||compress(%sysfunc(varnum(&dsid.,arm&i._pct)))||'"/>'; output; 
			%end;
		%end;
		%do i = 1 %to 4;
			%let lvl = %scan(soc hlgt hlt pt,&i.); 

			/* comparison values (rd, rr, pv) on the hidden data sheet */
			/* used to determine whether there is a signal at any given term */
			string = '<NamedRange ss:Name="'||"ae&lvl."||'c" ss:RefersTo="='||"'"||"&wstitle."||"'"||
		             '!R'||compress("&&&row&i.s.")||'C'||compress(%sysfunc(varnum(&dsid.,rd)))||':'||
		             'R'||compress("&&&row&i.e.")||'C'||compress(%sysfunc(varnum(&dsid.,pv)))||'"/>'; output; 

			/* continuity correction indicator column */
			string = '<NamedRange ss:Name="'||"ae&lvl."||'cc" ss:RefersTo="='||"'"||"&wstitle."||"'"||
		             '!R'||compress("&&&row&i.s.")||'C'||compress(%sysfunc(varnum(&dsid.,cc)))||':'||
		             'R'||compress("&&&row&i.e.")||'C'||compress(%sysfunc(varnum(&dsid.,cc)))||'"/>'; output; 

			/* signal columns identifying whether a given term has signals */
			/* at each of the four levels of the MedDRA hierarchy */
			/* signal at SOC --> column 1 'Y', etc. */
			string = '<NamedRange ss:Name="'||"ae&lvl."||'s" ss:RefersTo="='||"'"||"&wstitle."||"'"||
		             '!R'||compress("&&&row&i.s.")||'C'||compress(%sysfunc(varnum(&dsid.,sgnl_soc)))||':'||
		             'R'||compress("&&&row&i.e.")||'C'||compress(%sysfunc(varnum(&dsid.,sgnl_pt)))||'"/>'; output; 

			/* column identifying whether a term has a signal at any level */
			/* Y -> signal at term level; A -> signal above; B -> signal below */
			string = '<NamedRange ss:Name="'||"ae&lvl."||'scd" ss:RefersTo="='||"'"||"&wstitle."||"'"||
		             '!R'||compress("&&&row&i.s.")||'C'||compress(%sysfunc(varnum(&dsid.,sgnl_any)))||':'||
		             'R'||compress("&&&row&i.e.")||'C'||compress(%sysfunc(varnum(&dsid.,sgnl_any)))||'"/>'; output; 

		%end;
		/* id columns for the superior MedDRA hierarchy level for each level below SOC */
		/* e.g. the numeric SOC IDs for all HLGT terms */
		/* used to find whether there is a signal in any of the terms below a given term */
		string = '<NamedRange ss:Name="gs" ss:RefersTo="='||"'"||"&wstitle."||"'"||
		         '!R'||compress("&row2s.")||'C'||compress(%sysfunc(varnum(&dsid.,soc)))||':'||
		         'R'||compress("&row2e.")||'C'||compress(%sysfunc(varnum(&dsid.,soc)))||'"/>'; output; 
		string = '<NamedRange ss:Name="hg" ss:RefersTo="='||"'"||"&wstitle."||"'"||
		         '!R'||compress("&row3s.")||'C'||compress(%sysfunc(varnum(&dsid.,hlgt)))||':'||
		         'R'||compress("&row3e.")||'C'||compress(%sysfunc(varnum(&dsid.,hlgt)))||'"/>'; output; 
		string = '<NamedRange ss:Name="ph" ss:RefersTo="='||"'"||"&wstitle."||"'"||
		         '!R'||compress("&row4s.")||'C'||compress(%sysfunc(varnum(&dsid.,hlt)))||':'||
		         'R'||compress("&row4e.")||'C'||compress(%sysfunc(varnum(&dsid.,hlt)))||'"/>'; output; 
	run; 

	%let dsid = %sysfunc(close(&dsid.));

	/* named ranges for the calculations (rd, rr, pv) */
	data wb_&ds._calcnm; 
		length string $&strlen.;

		dsid = open("&ds.");

		%do i = 1 %to &arm_count.;
			%do j = 1 %to &arm_count.;
				%if &i. ne &j. %then %do;

			/* values for rd, rr, pv for each comparison */
			/* e.g. cmp12 is the set of values for arm 1 compared to arm 2 */
			string = '<NamedRange ss:Name="'||"aecmp&i.&j."||'" ss:RefersTo="='||"'"||"&wstitle."||"'"||
	                 '!R'||compress(1)||'C'||compress(varnum(dsid,"rd&i.&j."))||':'||
	                 'R'||compress(&row4e.)||'C'||compress(varnum(dsid,"pv&i.&j."))||'"/>'; output; 

			/* and for the continuity correction indicator columns */
			%if &cc_sw. %then %do;
				string = '<NamedRange ss:Name="'||"ccind&i.&j."||'" ss:RefersTo="='||"'"||"&wstitle."||"'"||
		                 '!R'||compress(1)||'C'||compress(varnum(dsid,"cc&i.&j."))||':'||
		                 'R'||compress(&row4e.)||'C'||compress(varnum(dsid,"cc&i.&j."))||'"/>'; output; 
			%end;

				%end;
			%end;
		%end;

		/* empty named range for arm to self comparisons */
		string = '<NamedRange ss:Name="cmp0" ss:RefersTo="='||"'"||"&wstitle."||"'"||
	                 '!R'||compress(1)||'C'||compress(attrn(dsid,'nvars')+1)||':'||
	                 'R'||compress(&row4e.)||'C'||compress(attrn(dsid,'nvars')+3)||'"/>'; output; 

		%if &cc_sw. ne 0 %then %do;
			string = '<NamedRange ss:Name="ccind0" ss:RefersTo="='||"'"||"&wstitle."||"'"||
		                 '!R'||compress(1)||'C'||compress(attrn(dsid,'nvars')+1)||':'||
		                 'R'||compress(&row4e.)||'C'||compress(attrn(dsid,'nvars')+1)||'"/>'; output; 
		%end;

		rc = close(dsid);

		keep string;
	run; 

	data wb_&ds._names;
		set wb_&ds._names wb_&ds._calcnm;
	run;

	proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;

%mend out_meddra_cmp_data;



/* hidden parameters worksheet */
%macro wbinfo;

	%let ds = wbinfo;
	%let wstitle = Workbook Information;

	/* set up worksheet */
	data ws_&ds._start;
		length string $&strlen.;
		string = '<Worksheet ss:Name="'||"&wstitle."||'">'; output; 
	run;

	data ws_&ds._end; 
		length string $&strlen.; 
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<Visible>SheetHidden</Visible>'; output;
		string = '<ProtectObjects>False</ProtectObjects>'; output;
		string = '<ProtectScenarios>False</ProtectScenarios>'; output;
		string = '</WorksheetOptions>'; output;
		string = '</Worksheet>'; output;
	run;

	data ws_&ds._table_start; 
		length string $&strlen.; 
		string = '<Table>'; output;
	run;

	data ws_&ds._table_end;
		length string $&strlen.; 
		string = '</Table>'; output;
	run;

	/* prepare the data for the worksheet */
	data ws_&ds._arminfo_data;
		retain arm_display arm_num count;
		set all_arm(keep=arm_display arm_num count rename=(count=countn));
		count = put(countn,comma.);
		drop countn;
	run;

	%annotate(ws_&ds._arminfo_data,ws_&ds._arminfo_note);

	%markup(ws_&ds._arminfo_note,ws_&ds._arminfo);

	data ws_&ds._lkp_note;
		%xml_tag_def;
		%xml_init;

		Row = 1;
		/* treatment (experiment) number, control number, treatment & control numbers */
		Formula = '=VLOOKUP(exp_name,wbinfo_arminfo_2,2,FALSE)'; output;
		Formula = '=VLOOKUP(ctl_name,wbinfo_arminfo_2,2,FALSE)'; output;
		Formula = '=IF(exp&lt;&gt;ctl,exp&amp;ctl,0)'; output; 

		Row = 2;
		/* make blank thresholds equal to positive infinity */
		/* then, only non-blank thresholds will contribute to AE highlighting */
		Formula = '=IF(ISBLANK(rdn),&quot;I&quot;,rdn)'; output;
		Formula = '=IF(ISBLANK(rrn),&quot;I&quot;,rrn)'; output;
		Formula = '=IF(ISBLANK(pvn),&quot;I&quot;,pvn)'; output;

	run;

	%markup(ws_&ds._lkp_note,ws_&ds._lkp);

	data ws_&ds.;
		set ws_&ds._start
		    ws_&ds._table_start
			ws_&ds._arminfo
			ws_&ds._lkp
			ws_&ds._table_end
			ws_&ds._end;
	run;

	data wb_&ds._names;
		length string $&strlen.;
		string = '<NamedRange ss:Name="wbinfo_arminfo_1" ss:RefersTo="='||
                 "'Workbook Information'"||'!R1C1:R'||"&arm_count."||'C1"/>'; output;
		string = '<NamedRange ss:Name="wbinfo_arminfo_2" ss:RefersTo="='||
                 "'Workbook Information'"||'!R1C1:R'||"&arm_count."||'C2"/>'; output;
		string = '<NamedRange ss:Name="armn" ss:RefersTo="='||
                 "'Workbook Information'"||'!R1C3:R'||"&arm_count."||'C3"/>'; output;
		/* numeric arm number & comparison number identifiers */
		string = '<NamedRange ss:Name="exp" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&arm_count.+1))||'C1"/>'; output; 	
		string = '<NamedRange ss:Name="ctl" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&arm_count.+1))||'C2"/>'; output; 	
		string = '<NamedRange ss:Name="cmp" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&arm_count.+1))||'C3"/>'; output; 	
		/* rd, rr, and pv thresholds */
		string = '<NamedRange ss:Name="rd" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&arm_count.+2))||'C1"/>'; output; 	
		string = '<NamedRange ss:Name="rr" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&arm_count.+2))||'C2"/>'; output; 	
		string = '<NamedRange ss:Name="pv" ss:RefersTo="='||"'"||"&wstitle."||"'!"||
                 'R'||compress(%eval(&arm_count.+2))||'C3"/>'; output; 	

	run;

	proc datasets library=work nolist nodetails; delete ws_&ds._:; quit;

%mend wbinfo;


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
		Data = 'Adverse Events Analysis Data Check Summary';
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

		MergeAcross = 7;

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
	                   'in the subject count for anaemia on comparison analysis tab, and the two adverse events '||
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
		Height = max(1,ceil(length(trim(Data))/130))*13.5;
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
			Height = 13.75 + max(1,round(&max_arm_nm_len./10,1))*13.75;
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
			Height = (ceil(&max_arm_nm_len./10)+1)*13.5;
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
			ws_rpt_meddra_header
			ws_rpt_meddra_columns
			ws_rpt_meddra
			%if %sysfunc(floor(&meddra_pct.)) < 100 %then %do;
				ws_null
				ws_rpt_err_meddra_columns
				ws_rpt_err_meddra
			%end;
			ws_null
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

	%if %sysfunc(floor(&meddra_pct.)) < 100 %then %do;
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
			string = '<Value1>MOD(ROW(),2)-'||trim(put(%sysfunc(mod(&err_firstrow.,2)),8. -l))||'</Value1>'; 
			output;
			string = "<Format Style='background:silver'/>"; output;
			string = '</Condition>'; output;
			string = '</ConditionalFormatting>'; output;
		%end;
		%if %sysfunc(floor(&meddra_pct.)) < 100 %then %do;
			string = '<ConditionalFormatting xmlns="urn:schemas-microsoft-com:office:excel">'; output;
			string = "<Range>R&meddra_firstrow.C1:R&meddra_lastrow.C8</Range>"; output;
			string = '<Condition>'; output;
			string = '<Value1>MOD(ROW(),2)-'||trim(put(%sysfunc(mod(&meddra_firstrow.,2)),8. -l))||'</Value1>'; 
			output;
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


/* create the XML styles used in this workbook */
%macro out_aem_styles;

	data wb_aem_styles_data;
		%xml_style_dcl;	
		ID = 'D'; output;

		ID = 'D0_R1'; NumFmt = '0'; HA = 'Right'; Indent = 1; output; 
		ID = 'D0_R2'; NumFmt = '0'; HA = 'Right'; Indent = 2; output; 
		ID = 'D0_R3'; NumFmt = '0'; HA = 'Right'; Indent = 3; output; 
		ID = 'D0_R4'; NumFmt = '0'; HA = 'Right'; Indent = 4; output;
		ID = 'D1_R0'; NumFmt = '0.0'; HA = 'Right'; Indent = .; output;
		ID = 'D1_R1'; NumFmt = '0.0'; HA = 'Right'; Indent = 1; output;
		ID = 'D1_R2'; NumFmt = '0.0'; HA = 'Right'; Indent = 2; output;
		ID = 'D1_R3'; NumFmt = '0.0'; HA = 'Right'; Indent = 3; output;
		ID = 'D2_R1'; NumFmt = '0.00'; HA = 'Right'; Indent = 1; output;
		ID = 'D2_R2'; NumFmt = '0.00'; HA = 'Right'; Indent = 2; output;
		ID = 'D2_R3'; NumFmt = '0.00'; HA = 'Right'; Indent = 3; output;
		NumFmt = ''; HA = ''; Indent = .;

		ID = 'IB'; NumFmt = '[=0]&quot;&quot;;General';	HA = 'Left'; output;
	run;
	
	data wb_aem_styles_data;
		set wb_aem_styles_data; 
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

	data wb_aem_styles_o_data;
		%xml_style_dcl;
		do i = 1 to 100;
			output;
		end;
	run;

	data wb_aem_styles_o_data;
		set wb_aem_styles_o_data;
		%let si = 0;

		/* Data and DataCenter styles */
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'D'; VA = 'Top'; Wrap = 0; BL = 1; BR = 1; BWt = 1;
		end; 
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'DC'; HA = 'Center'; VA = 'Top'; Wrap = 0; BL = 1; BR = 1; BWt = 1;
		end; 
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'DB'; VA = 'Top'; Wrap = 0; BL = 1; BR = 1; BB = 1; BWt = 1;
		end; 
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'DCB'; HA = 'Center'; VA = 'Top'; Wrap = 0; BL = 1; BR = 1; BB = 1; BWt = 1;
		end; 

		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'I'; HA = 'Left'; VA = 'Center'; IntClr = 'FFFF99'; BT = 1; BL = 1; BR = 1; BB = 1; BWt = .;
		end; 
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'TBT'; HA = 'Left'; Indent = 1; VA = 'Center'; BT = 1; BL = 1; BR = 1; BWt = .;
		end; 
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'TBM'; HA = 'Left'; Indent = 1; VA = 'Center'; BL = 1; BR = 1; BWt = .;
		end; 
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'TBL'; HA = 'Left'; Indent = 1; VA = 'Center'; BL = 1; BWt = .;
		end; 
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'TBR'; HA = 'Left'; VA = 'Center'; BR = 1; BWt = .;
		end; 
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'TBB'; HA = 'Left'; Indent = 1; VA = 'Center'; BL = 1; BR = 1; BB = 1; BWt = .;
		end; 
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'D1_R2BR_BLRB'; NumFmt = '0.0'; FontSize = 8; FontColor = 'FF0000'; Bold = 1; 
			HA = 'Right'; Indent = 2; 
            BL = 1; BR = 1; BB = 1; BWt = 1;
		end;
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'I10'; FontSize = 10; HA = 'Left'; VA = 'Top'; Wrap = 1; Indent = 1;
		end;
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'B10O'; FontSize = 10; Bold = 1; HA = 'Center'; VA = 'Top'; IntClr = 'C0C0C0';
			BT = 1; BL = 1; BR = 1; BB = 1; BWt = 1; BLS = 'Dash';
		end;
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'DG'; IntClr = '808080';
			BT = 1; BL = 1; BR = 1; BB = 1; BWt = 1;
		end;
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'LG'; IntClr = 'C0C0C0';
			BT = 1; BL = 1; BR = 1; BB = 1; BWt = 1;
		end;
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'R'; IntClr = 'FF0000';
			BT = 1; BL = 1; BR = 1; BB = 1; BWt = 1;
		end;
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'P'; IntClr = 'FFCC99';
			BT = 1; BL = 1; BR = 1; BB = 1; BWt = 1;
		end;
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'OR'; HA = 'Center'; VA = 'Center'; Rotate = 90;
			BT = 1; BL = 1; BR = 1; BB = 1; BWt = .;
		end;
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'OW_BLR'; NumFmt = '&quot;&quot;'; FontColor = 'FFFFFF'; FontSize = 8;
			BL = 1; BR = 1; BWt = .;
		end;
		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'OW_BLRB'; NumFmt = '&quot;&quot;'; FontColor = 'FFFFFF'; FontSize = 8;
			BL = 1; BR = 1; BB = 1; BWt = .;
		end;

		if _n_ = %let si = %eval(&si. + 1); &si. then do;
			ID = 'COR'; FontColor = 'FFFFFF'; FontSize = 8;	IntClr = '333399';
			HA = 'Center'; VA = 'Center'; Wrap = 1;	Rotate = 90;
			BT = 1; BL = 1; BR = 1; BB = 1; BWt = 1;
		end;

		if ID = '' then delete;
	run;

	data wb_aem_styles_data;
		set wb_aem_styles_data wb_aem_styles_o_data;
	run;

	%xml_style_markup(wb_aem_styles_data,wb_aem_styles);

	proc datasets library=work nolist nodetails; delete wb_aem_styles_:; quit;

%mend out_aem_styles;


/************************/
/* begin running output */
/************************/
%macro out_med;

	/* print current activity to the log */
	data _null_;
		title = "MAKING EXCEL XML OUTPUT FOR AE MEDDRA COMPARISON REPORT";
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
	%styles(size=8);
	%out_aem_styles;

	data wb_styles;
		set wb_styles 
            wb_aem_styles end=eof;
		if string = '</Styles>' then delete;
		keep string;
		output;
		if eof then do; string = '</Styles>'; output; end;
	run;

	%out_cover;
	%out_err;

	%out_meddra_cmp;
	%out_meddra_cmp_data;
	%wbinfo;


	data wb_names_start;
		length string $&strlen.;
		string = '<Names>';
	run;

	data wb_names_end;
		length string $&strlen.;
		string = '</Names>';
	run;

	/* collect all named ranges */
	data wb_names;
		set wb_names_start 
	        wb_meddra_cmp_output_names
	        wb_meddra_cmp_data_names
			wb_wbinfo_names
	        wb_names_end;
	run;


	data wb;
		set wb_start
		    wb_styles 
			wb_names
			ws_cover
			ws_meddra_cmp_output
			ws_err 
			%if %sysfunc(exist(ws_sl_gs)) %then ws_sl_gs;
			ws_meddra_cmp_data
			ws_wbinfo
			wb_end;
	run;

	/*proc datasets library=work nolist nodetails; delete wb_:; quit;*/

	data _null_;
		set wb;
		file "&aemedout." ls=32767;
		put string;
	run;

%mend out_med;
