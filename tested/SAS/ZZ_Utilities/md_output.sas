/****************************************************************************/
/*         PROGRAM NAME: Generic Panel Metadata Output                      */
/*                                                                          */
/*          DESCRIPTION: Create an Excel XML workbook with the settings     */
/*                        the user chose for a panel                        */
/*                                                                          */
/*               AUTHOR: David Kretch (david.kretch@us.ibm.com)	            */
/*                                                                          */
/*                 DATE: March 14, 2011                                     */
/*                                                                          */
/*  EXTERNAL FILES USED: xml_output.sas -- XML formatting macros            */
/*                       sl_gs_output.sas -- Script Launcher settings output*/
/*                                                                          */
/*  PARAMETERS REQUIRED: utilpath -- location of the external SAS programs  */
/*                       md_file -- filename and path of the output         */
/*                                                                          */
/*            MADE WITH: SAS 9.2                                            */
/*                                                                          */
/*                NOTES:                                                    */
/*                                                                          */
/*            REVISIONS: ---                                                */
/*                                                                          */
/****************************************************************************/


*%let ndabla = 12345;
*%let studyid = 123;	


*%let utilpath = C:\Documents and Settings\MATTOK\Desktop\SL_SAS_Progs\ZZ_Utilities;


%include "&utilpath.\xml_output.sas";
%include "&utilpath.\sl_gs_output.sas";	

%let wbtitle = &panel_title. Metadata Summary;


%macro metadata_summary(md_file=);

	%put SCRIPT LAUNCHER METADATA OUTPUT;

	%let ds = metadata;

	%wb;
	%styles; 

	/* set up worksheet start and end datasets */
	data ws_&ds._start;
		length string $&strlen.;
		string = '<Worksheet ss:Name="Metadata Summary">'; output; 
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
		string = '<Column ss:Width="150"/>'; output;
		string = '<Column/>'; output;
	run;

	data ws_&ds._table_end;
		length string $&strlen.; 
		string = '</Table>'; output;
	run;

	%group_subset_pp;
	%group_subset_xml_out(delete_im=N);	

	/* make the top of the worksheet with the title and run info */
	data ws_&ds._header_data;
		%xml_tag_def;
		%xml_init;

		Type = 'String';

		%let row = 0;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = ''; output;
		
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "&panel_title. Metadata Summary"; StyleID = 'Header'; output;

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

		%if %length(&panel_desc.) > 0 %then %do; 
			StyleID = 'Default10Wrap'; 

			Row = %let row = %eval(&row. + 1); &row.;
			Data = "&panel_message."; 
			MergeAcross = 6; 
			Height = ceil(length(trim("&panel_desc."))/150)*12.75;
			output;	

			Row = %let row = %eval(&row. + 1); &row.;
			Data = ''; StyleID = ''; output;
		%end;

		Row = %let row = %eval(&row. + 1); &row.;
		Data = 'Custom datasets: '||ifc("&sl_custom_ds." ne '',"&sl_custom_ds.",'No custom datasets'); output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Grouping: &sl_group_desc."; output;
		Row = %let row = %eval(&row. + 1); &row.;
		Data = "Subsetting: &sl_subset_desc."; output;
	run;

	%markup(ws_&ds._header_data,ws_&ds._header);

	data ws_&ds._settings;
		length string $&strlen.;
		string = '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '<PageSetup>'; output;
		string = '<Layout x:Orientation="Landscape"/>'; output;
		string = '<Header x:Data="&amp;L'||"&panel_title."||
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
		    ws_sl_gs_table_start
			ws_&ds._header 
			%if %upcase(%substr(&sl_group_desc.,1,1)) ne N %then ws_sl_gs_group;
			%if %upcase(%substr(&sl_subset_desc.,1,1)) ne N %then ws_sl_gs_subset;
			ws_&ds._table_end
			ws_&ds._settings
			ws_&ds._end
			wb_end
			;
	run;

	data _null_;
		set wb;
		file "&md_file." ls=32767;
		put string;
	run;

	proc datasets library=work nolist nodetails; delete ws_&ds.: ws_sl_gs:; quit;

%mend metadata_summary;
