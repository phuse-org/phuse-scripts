/****************************************************************************/
/*         PROGRAM NAME: Generic Panel Error Output                         */
/*                                                                          */
/*          DESCRIPTION: Create an Excel XML workbook with the settings     */
/*                        the user chose for a panel                        */
/*                                                                          */
/*               AUTHOR: David Kretch (david.kretch@us.ibm.com)	            */
/*                                                                          */
/*                 DATE: March 28, 2011                                     */
/*                                                                          */
/*  EXTERNAL FILES USED: xml_output.sas -- XML formatting macros            */
/*                       sl_gs_output.sas -- Script Launcher settings output*/
/*                                                                          */
/*  PARAMETERS REQUIRED: utilpath -- location of the external SAS programs  */
/*                       err_file -- filename and path of the output        */
/*                                                                          */
/*            MADE WITH: SAS 9.2                                            */
/*                                                                          */
/*                NOTES:                                                    */
/*                                                                          */
/*            REVISIONS: ---                                                */
/*                                                                          */
/****************************************************************************/

/* REVISION HISTORY */
/*
2011-05-08  DK  Added support for errors in case there are no subjects in DM

2011-06-08  DK  Added an argument to turn on or off setting the error status
                Also previously added the errsummaryrun macro to indicate 
                that it has already run
*/


*%let ndabla = 12345;
*%let studyid = 123;	


*%let utilpath = C:\Documents and Settings\MATTOK\Desktop\SL_SAS_Progs\ZZ_Utilities;


%include "&utilpath.\xml_output.sas";

%macro error_summary(err_file=,err_nosubj=0,err_missvar=0,err_seterr=1,err_desc=); 

	%let wbtitle = &panel_title. Error Summary;	

	%if &err_nosubj. %then %do;
		/* get the required variable check dataset ready for output */
		%put PANEL NO SUBJECTS ERROR PREPROCESSING;

		proc sql noprint;
			select count(1) into: sl_subset_count
			from sl_subset;
		quit;

		%if &sl_subset_count. > 0 %then %do;

			proc sql noprint;
				select lowcase(outer_operator) into: operator
		        from sl_subset;

				select distinct name into: sl_subset_desc separated by " &operator. "
				from sl_subset;
			quit;

		%end;
		%else %let sl_subset_desc = ;
	%end;

	%if &err_missvar. %then %do;
		/* get the required variable check dataset ready for output */
		%put PANEL MISSING VARIABLE ERROR PREPROCESSING;

		data err_missing_var;
			set rpt_chk_var_req;
			where ind ne 1;
			keep ds var;
		run;
	%end;

	/* create the output */
	%put SCRIPT LAUNCHER ERROR SUMMARY OUTPUT;

	%let ds = err;

	%wb;
	%styles;

	/* set up worksheet start and end datasets */
	data ws_&ds._start;
		length string $&strlen.;
		string = '<Worksheet ss:Name="Error Summary">'; output; 
	run;

	data ws_&ds._end; 
		length string $&strlen.; 
		string = '</Worksheet>'; output;
	run;

	data ws_&ds._table_start; 
		length string $&strlen.; 
		string = '<Table>'; output;
		/* define column widths */
		string = '<Column ss:Width="150"/>'; output;
		string = '<Column ss:Width="250"/>'; output;
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
		Data = "&panel_title. Error Summary"; StyleID = 'Header'; output;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;

		StyleID = 'Default10'; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = "NDA/BLA: &ndabla."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Study: &studyid."; output; 
		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'Analysis run date: '||put(date(),e8601da.)||' '||put(time(),timeampm11.); output;
		Row = %let row = %eval(&row. + 1); &row.; 

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; output;

		/* output the panel description if there is one */
		%if %length(&panel_desc.) > 0 %then %do; 

			StyleID = 'Default10Wrap'; 

			Row = %let row = %eval(&row. + 1); &row.;
			Data = "&panel_desc."; 
			MergeAcross = 6; 
			Height = ceil(length(trim("&panel_desc."))/150)*12.75;
			output;	

			Row = %let row = %eval(&row. + 1); &row.;
			Data = ''; StyleID = ''; output;

		%end; 

		/* output the error description */
		StyleID = 'Default10Wrap'; 

		Row = %let row = %eval(&row. + 1); &row.;
		MergeAcross = 6; 
		Height = ceil(length(trim(Data))/130)*12.75;

		/* custom error message */
		%if %length(&err_desc.) > 0 %then %do;
			Row = %let row = %eval(&row. + 1); &row.;
			Data = "&err_desc."; output;

			Row = %let row = %eval(&row. + 1); &row.;
			Data = ''; StyleID = ''; Height = 12.75; output;
		%end; 

		/* no subjects in DM error */
		%if &err_nosubj. %then %do;
			Row = %let row = %eval(&row. + 1); &row.;
			Data = 'There are no subjects in the demographics domain (DM) dataset'||
                   %if %length(&sl_subset_desc.) > 0 %then %do; " after subsetting by &sl_subset_desc"|| %end; 
                   '.';  output;

			Row = %let row = %eval(&row. + 1); &row.;
			Data = ''; StyleID = ''; Height = 12.75; output;
		%end;

		/* missing variable error */
		%if &err_missvar. %then %do;
			Row = %let row = %eval(&row. + 1); &row.;
			Data = 'Some variables that are required by this panel are missing. These variables are shown '||
                   'in the following table.';  output;
		%end;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; StyleID = ''; Height = 12.75; output;
	run;

	%markup(ws_&ds._header_data,ws_&ds._header); 

	/* missing variable information data table */
	%if &err_missvar. %then %do;

		/* make the missing variable table column headers */
		data ws_&ds._missing_cols_data;
			%xml_tag_def;
			%xml_init;

			Type = 'String';
			StyleID = 'ColumnOutline';

			Row = 1;
			Height = 30;
			Data = 'Domain/Dataset'; output;
			Data = 'Variable'; output;
		run;

		%markup(ws_&ds._missing_cols_data,ws_&ds._missing_cols);

		%annotate(err_missing_var,ws_&ds._missing_data);

		data ws_&ds._missing_data;
			set ws_&ds._missing_data;
			StyleID = 'Table';
		run; 

		%markup(ws_&ds._missing_data,ws_&ds._missing);

	%end;

	data ws_&ds._settings;
		length string $&strlen.;
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<PageSetup>'; output;
		string = '<Layout x:Orientation="Landscape"/>'; output;
		string = '<Header x:Data="&amp;L'||"panel_title."||
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

	data wb;
		set wb_start
		    wb_styles  
			ws_&ds._start 
		    ws_&ds._table_start	
			ws_&ds._header 
			%if &err_missvar. %then %do;
				ws_&ds._missing_cols 
				ws_&ds._missing
			%end;
		    ws_&ds._table_end	
			ws_&ds._settings
			ws_&ds._end
			wb_end
			;
	run;

	data _null_;
		set wb;
		file "&err_file." ls=32767;
		put string;
	run;

	/*proc datasets library=work nolist nodetails; delete ws_&ds.:; quit;*/

	/* set the error status so Script Launcher can determine there was an error */
	%if &err_seterr. = 1 %then %do;
		%let errstatus = 5;
	%end;

%mend error_summary;
