/****************************************************************************/
/*                                                                          */
/*         PROGRAM NAME: Excel XML Output Macros                            */
/*                                                                          */
/*          DESCRIPTION: Macros for creating Excel XML workbooks            */
/*                       %wb -- create start and end markup of a workbook   */
/*                       %styles -- a collection of fixed styles            */
/*                       %xml_tag_def & %xml_init -- declare XML variables  */
/*                       %annotate -- annotate a dataset in prep. for XML   */
/*                       %markup -- turn annotated dataset into XML         */
/*                       %xml_style_dcl -- declare XML style variables      */
/*                       %xml_style_markup -- turn style vars into styles   */
/*                                                                          */
/*                       The following are deprecated but in use in places: */
/*                       %wsheader -- create headers/footers                */
/*                       %wsdata -- mark up a dataset with default styling  */
/*                       %ws_rowcount -- find the count of XML rows         */
/*                                                                          */
/*               AUTHOR: David Kretch (david.kretch@us.ibm.com)	            */
/*                                                                          */
/*                 DATE: February 15, 2011                                  */
/*                                                                          */
/*            MADE WITH: SAS 9.2                                            */
/*                                                                          */
/*                NOTES:                                                    */
/*                                                                          */
/*            REVISIONS: ---                                                */
/*                                                                          */
/****************************************************************************/

/* length for the string variable, which stores the XML code */
/* should be set by each panel to minimize string length */
%sysfunc(ifc(not %symexist(strlen),%nrstr(%global strlen; %let strlen = 2000;),));

%put XML TEXT STRING LENGTH: &strlen.;


/* workbook information */
/* first and last sets of tags in a workbook */
/* establishes title, author, and document type */
%macro wb(title);

	data wb_start;
		length string $&strlen.;
		string = '<?xml version="1.0"?>'; output;
		string = '<?mso-application progid="Excel.Sheet"?>'; output;
		string = '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '||
				   'xmlns:o="urn:schemas-microsoft-com:office:office" '||
				   'xmlns:x="urn:schemas-microsoft-com:office:excel" '||
				   'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" '||
				   'xmlns:html="http://www.w3.org/TR/REC-html40">'; output;
		string = '<DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">'; output;
		string = '<Title>'||"&wbtitle."||'</Title>'; output;
		string = '<Author>US Food &amp; Drug Administration</Author>'; output;
		string = '<Created>'||put(date(),YYMMDDd10.)||'T'||put(time(),TIME.)||'</Created>'; output;
 		string = '</DocumentProperties>'; output;
		string = '<ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">'; output;
		string = '</ExcelWorkbook>'; output;
	run;

	data wb_end;
		length string $&strlen.;
		string = '</Workbook>'; output;
	run;

%mend wb;


/* style information */
/* defines styles for cells in a worksheet */
/* eg font size, borders, etc. */
%macro styles(size=9);

	data wb_styles;
		length string $&strlen.;
		string = '<Styles>'; output; 

			/* default style */
			string = '<Style ss:ID="Default" ss:Name="Normal">'; output;
	   		string = '<Font ss:Size="'||"&size."||'"/>'; output;
	   		string = '<Interior ss:Pattern="Solid"/>'; output;
	  		string = '</Style>'; output;  

			/* default style with left alignment */
			string = '<Style ss:ID="DefaultLeft" ss:Parent="Default">'; output;
			string = '<Alignment ss:Horizontal="Left" ss:Vertical="Top" ss:WrapText="0"/>'; output;
			string = '</Style>'; output;

			/* default style with right alignment */
			string = '<Style ss:ID="DefaultRight" ss:Parent="Default">'; output;
			string = '<Alignment ss:Horizontal="Right" ss:Vertical="Top" ss:WrapText="0"/>'; output;
			string = '</Style>'; output;

			/* default style with white text */
			string = '<Style ss:ID="DefaultWhite" ss:Parent="Default">'; output;
	   		string = '<Font ss:Color="#FFFFFF"/>'; output;
			string = '</Style>'; output;

			/* default style with 10 pt font */
			string = '<Style ss:ID="Default10" ss:Parent="Default">'; output;
			string = '<Alignment ss:Vertical="Top" ss:WrapText="0"/>'; output;
	   		string = '<Font ss:Size="10"/>'; output;
			string = '</Style>'; output;

			/* default style with 10 pt font and word wrap */
			string = '<Style ss:ID="Default10Wrap" ss:Parent="Default10">'; output;
			string = '<Alignment ss:Vertical="Top" ss:WrapText="1"/>'; output;
			string = '</Style>'; output;

			/* default style with 10 pt red and italic font and word wrapping */
			string = '<Style ss:ID="Default10RedWrap" ss:Parent="Default">'; output;
			string = '<Alignment ss:Vertical="Top" ss:WrapText="1"/>'; output;
	   		string = '<Font ss:Color="#FF0000" ss:Size="10" ss:Italic="1"/>'; output;
			string = '</Style>'; output;

			/* default style with 10 pt font and right alignment */
			string = '<Style ss:ID="Default10Right" ss:Parent="Default10">'; output;
			string = '<Alignment ss:Horizontal="Right" ss:Vertical="Top" ss:WrapText="0"/>'; output;
			string = '</Style>'; output;

			/* default style with 8 pt font */
			string = '<Style ss:ID="Default8" ss:Parent="Default">'; output;
			string = '<Alignment ss:Vertical="Top" ss:WrapText="0"/>'; output;
	   		string = '<Font ss:Size="8"/>'; output;
			string = '</Style>'; output;

			/* header style */
			string = '<Style ss:ID="Header">'; output;
			string = '<Alignment/>'; output;
	   		string = '<Font ss:Size="12" ss:Bold="1" ss:Italic="1"/>'; output;
	  		string = '</Style>'; output;

			/* subheader style */
			string = '<Style ss:ID="SubHeader">'; output;
			string = '<Alignment ss:Vertical="Top"/>'; output;
	   		string = '<Font ss:Size="10" ss:Bold="1" ss:Italic="0"/>'; output;
	  		string = '</Style>'; output;

			/* column header style */
			string = '<Style ss:ID="Column">'; output;
			string = '<Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'; output;	
			string = '<Interior ss:Color="#333399" ss:Pattern="Solid"/>'; output;
			string = '<Font ss:Size="10" ss:Color="#FFFFFF" ss:Bold="1"/>'; output;
			string = '</Style>'; output;

			/* column header outline style */
			string = '<Style ss:ID="ColumnOutline" ss:Parent="Column">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
    		string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
    		string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
    		string = '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;  

			/* column header outline style with small text */
			string = '<Style ss:ID="ColumnOutlineSmall" ss:Parent="ColumnOutline">'; output;
			string = '<Font ss:Size="8" ss:Color="#FFFFFF" ss:Bold="1"/>'; output;
			string = '</Style>'; output;

			/* column header outline style with italic text */
			string = '<Style ss:ID="ColumnOutlineItalic" ss:Parent="ColumnOutline">'; output;
			string = '<Font ss:Size="10" ss:Color="#FFFFFF" ss:Bold="1" ss:Italic="1"/>'; output;
			string = '</Style>'; output; 

			/* column header outline style with rotated text vertically aligned to the top */
			string = '<Style ss:ID="ColumnOutlineRotateTop" ss:Parent="ColumnOutline">'; output;
			string = '<Alignment ss:Horizontal="Center" ss:Vertical="Top" ss:Rotate="90" ss:WrapText="1"/>'; output;
			string = '</Style>'; output;

			/* column header outline style with rotated text vertically aligned to the center */
			string = '<Style ss:ID="ColumnOutlineRotateCtr" ss:Parent="ColumnOutline">'; output;
			string = '<Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:Rotate="90" ss:WrapText="1"/>'; output;
			string = '</Style>'; output;

			/* data header row style */
			string = '<Style ss:ID="DataHeader">'; output;
			string = '<Alignment ss:Horizontal="Left" ss:Vertical="Center" ss:WrapText="0"/>'; output;	
			string = '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
    		string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
    		string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
    		string = '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '<Font ss:Size="10" ss:Bold="1"/>'; output;
			string = '</Style>'; output;

			/* simple table style */
			string = '<Style ss:ID="Table">'; output;
			string = '<Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="0"/>'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
	    	string = '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
	   		string = '<Font ss:Size="10"/>'; output;
			string = '</Style>'; output;

			/* data parent style */
			string = '<Style ss:ID="Data">'; output;
			string = '<Alignment ss:Vertical="Top" ss:WrapText="0"/>'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;

			/* data style with word-wrapping */
			string = '<Style ss:ID="DataWrap" ss:Parent="Data">'; output;
			string = '<Alignment ss:Vertical="Top" ss:WrapText="1"/>'; output;
			string = '</Style>'; output;

			/* data style with right-alignment */
			string = '<Style ss:ID="DataRight" ss:Parent="Data">'; output;
			string = '<Alignment ss:Horizontal="Right" ss:Vertical="Top" ss:WrapText="0"/>'; output;
			string = '</Style>'; output;

			/* highlighted data style with right-alignment */
			string = '<Style ss:ID="DataRightHighlight" ss:Parent="DataRight">'; output;
			string = '<Interior ss:Color="#CCCCFF" ss:Pattern="Solid"/>'; output;
			string = '</Style>'; output;  

			/* data style with center-alignment */
			string = '<Style ss:ID="DataCenter" ss:Parent="Data">'; output;
			string = '<Alignment ss:Horizontal="Center" ss:Vertical="Top" ss:WrapText="0"/>'; output;
			string = '</Style>'; output;

			/* zero decimal place number format style */
			string = '<Style ss:ID="DataDec0" ss:Parent="Data">'; output;
			string = '<Alignment ss:Horizontal="Right" ss:Vertical="Top"/>'; output;
			string = '<NumberFormat ss:Format="0"/>'; output;
			string = '</Style>'; output;

			/* centered zero decimal place number format style */
			string = '<Style ss:ID="DataDec0Center" ss:Parent="DataDec0">'; output;
			string = '<Alignment ss:Horizontal="Center" ss:Vertical="Top" ss:WrapText="0"/>'; output;
			string = '</Style>'; output;

			/* highlighted zero decimal place number format style */
			string = '<Style ss:ID="DataDec0Highlight" ss:Parent="DataDec0">'; output;
			string = '<Interior ss:Color="#CCCCFF" ss:Pattern="Solid"/>'; output;
			string = '</Style>'; output;  

			/* one decimal place number format style */
			string = '<Style ss:ID="DataDec1" ss:Parent="Data">'; output;
			string = '<Alignment ss:Horizontal="Right" ss:Vertical="Top"/>'; output;
			string = '<NumberFormat ss:Format="0.0"/>';	output;
			string = '</Style>'; output;

			/* centered one decimal place number format style */
			string = '<Style ss:ID="DataDec1Center" ss:Parent="DataDec1">'; output;
			string = '<Alignment ss:Horizontal="Center" ss:Vertical="Top" ss:WrapText="0"/>'; output;
			string = '</Style>'; output;

			/* highlighted one decimal place number format style */
			string = '<Style ss:ID="DataDec1Highlight" ss:Parent="DataDec1">'; output;
			string = '<Interior ss:Color="#CCCCFF" ss:Pattern="Solid"/>'; output;
			string = '</Style>'; output; 

			/* two decimal place number format style */
			string = '<Style ss:ID="DataDec2" ss:Parent="Data">'; output;
			string = '<Alignment ss:Horizontal="Right" ss:Vertical="Top"/>'; output;
			string = '<NumberFormat ss:Format="0.00"/>';	output;
			string = '</Style>'; output;

			/* centered two decimal place number format style */
			string = '<Style ss:ID="DataDec2Center" ss:Parent="DataDec2">'; output;
			string = '<Alignment ss:Horizontal="Center" ss:Vertical="Top" ss:WrapText="0"/>'; output;
			string = '</Style>'; output;

			/* highlighted two decimal place number format style */
			string = '<Style ss:ID="DataDec2Highlight" ss:Parent="DataDec2">'; output;
			string = '<Interior ss:Color="#CCCCFF" ss:Pattern="Solid"/>'; output;
			string = '</Style>'; output; 

			/* scientific notation number format style */
			string = '<Style ss:ID="DataSN" ss:Parent="Data">'; output;
			string = '<Alignment ss:Horizontal="Right" ss:Vertical="Top"/>'; output;
			string = '<NumberFormat ss:Format="0.00E+00"/>';	output;
			string = '</Style>'; output;

			/* centered scientific notation number format style */
			string = '<Style ss:ID="DataSNCenter" ss:Parent="DataSN">'; output;
			string = '<Alignment ss:Horizontal="Center" ss:Vertical="Top" ss:WrapText="0"/>'; output;
			string = '</Style>'; output;

			/* highlighted scientific notation number format style */
			string = '<Style ss:ID="DataSNHighlight" ss:Parent="DataSN">'; output;
			string = '<Interior ss:Color="#CCCCFF" ss:Pattern="Solid"/>'; output;
			string = '</Style>'; output; 

			/* percent number format style */
			string = '<Style ss:ID="DataPct" ss:Parent="Data">'; output;
			string = '<Alignment ss:Horizontal="Right" ss:Vertical="Top"/>'; output;
			string = '<NumberFormat ss:Format="0%"/>';	output;
			string = '</Style>'; output;

			/* highlighted percent number format style */
			string = '<Style ss:ID="DataPctHighlight" ss:Parent="DataPct">'; output;
			string = '<Interior ss:Color="#CCCCFF" ss:Pattern="Solid"/>'; output;
			string = '</Style>'; output;

			/* data style for bottom row */
			string = '<Style ss:ID="DataBottom" ss:Parent="Data">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;  

			/* data style with word-wrapping for bottom row */
			string = '<Style ss:ID="DataWrapBottom" ss:Parent="DataWrap">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;  

			/* data style with right-alignment for the bottom row */
			string = '<Style ss:ID="DataRightBottom" ss:Parent="DataRight">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;

			/* highlighted data style with right-alignment for the bottom row */
			string = '<Style ss:ID="DataRightHighlightBottom" ss:Parent="DataRightHighlight">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* data style with center-alignment for the bottom row */
			string = '<Style ss:ID="DataCenterBottom" ss:Parent="DataCenter">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* zero decimal place number format style for bottom row */
			string = '<Style ss:ID="DataDec0Bottom" ss:Parent="DataDec0">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* centered zero decimal place number format style for bottom row */
			string = '<Style ss:ID="DataDec0CenterBottom" ss:Parent="DataDec0Center">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* highlighted zero decimal place number format style for bottom row */
			string = '<Style ss:ID="DataDec0HighlightBottom" ss:Parent="DataDec0Highlight">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* one decimal place number format style for bottom row */
			string = '<Style ss:ID="DataDec1Bottom" ss:Parent="DataDec1">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* centered one decimal place number format style for bottom row */
			string = '<Style ss:ID="DataDec1CenterBottom" ss:Parent="DataDec1Center">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* highlighted one decimal place number format style for bottom row */
			string = '<Style ss:ID="DataDec1HighlightBottom" ss:Parent="DataDec1Highlight">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* two decimal place number format style for bottom row */
			string = '<Style ss:ID="DataDec2Bottom" ss:Parent="DataDec2">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* centered two decimal place number format style for bottom row */
			string = '<Style ss:ID="DataDec2CenterBottom" ss:Parent="DataDec2Center">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* highlighted two decimal place number format style for bottom row */
			string = '<Style ss:ID="DataDec2HighlightBottom" ss:Parent="DataDec2Highlight">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* scientific notation number format style for bottom row */
			string = '<Style ss:ID="DataSNBottom" ss:Parent="DataSN">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* centered scientific notation number format style for bottom row */
			string = '<Style ss:ID="DataSNCenterBottom" ss:Parent="DataSNCenter">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* highlighted scientific notation number format style for bottom row */
			string = '<Style ss:ID="DataSNHighlightBottom" ss:Parent="DataSNHighlight">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output; 

			/* percent number format style for bottom row */
			string = '<Style ss:ID="DataPctBottom" ss:Parent="DataPct">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;

			/* highlighted percent number format style for bottom row */
			string = '<Style ss:ID="DataPctHighlightBottom" ss:Parent="DataPctHighlight">'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;

			/* for AE MedDRA report cover page */

			/* gray */
			string = '<Style ss:ID="Gray" ss:Parent="DataCenterBottom">'; output;
			string = '<Font ss:Size="8" ss:Color="#808080"/>'; output;
			string = '<Interior ss:Color="#808080" ss:Pattern="Solid"/>'; output;
			string = '</Style>'; output; 

			/* red */
			string = '<Style ss:ID="Red" ss:Parent="DataCenterBottom">'; output;
			string = '<Font ss:Size="8" ss:Color="#FF0000"/>'; output;
			string = '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'; output;
			string = '</Style>'; output; 

			/* peach */
			string = '<Style ss:ID="Peach" ss:Parent="DataCenterBottom">'; output;
			string = '<Font ss:Size="8" ss:Color="#FFCC99"/>'; output;
			string = '<Interior ss:Color="#FFCC99" ss:Pattern="Solid"/>'; output;
			string = '</Style>'; output; 

			/* bold red text */
			string = '<Style ss:ID="BoldRedText" ss:Parent="DataDec1Bottom">'; output;
			string = '<Font ss:Size="8" ss:Color="#FF0000" ss:Bold="1"/>'; output;
			string = '</Style>'; output; 

			/* grouping and subsetting styles with 10 pt font */
			string = '<Style ss:ID="GS_BTLRB">'; output;
			string = '<Alignment ss:Vertical="Top" ss:WrapText="1"/>'; output;
	   		string = '<Font ss:Size="10"/>'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;

			/* centered grouping and subsetting styles with 10 pt font */
			string = '<Style ss:ID="GSC_BTLRB">'; output;
			string = '<Alignment ss:Vertical="Top" ss:Horizontal="Center" ss:WrapText="1"/>'; output;
	   		string = '<Font ss:Size="10"/>'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;

			string = '<Style ss:ID="GS_BTLR">'; output;
			string = '<Alignment ss:Vertical="Top" ss:WrapText="1"/>'; output;
	   		string = '<Font ss:Size="10"/>'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;

			string = '<Style ss:ID="GS_BLR">'; output;
			string = '<Alignment ss:Vertical="Top" ss:WrapText="1"/>'; output;
	   		string = '<Font ss:Size="10"/>'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;

			string = '<Style ss:ID="GS_BLRB">'; output;
			string = '<Alignment ss:Vertical="Top" ss:WrapText="1"/>'; output;
	   		string = '<Font ss:Size="10"/>'; output;
			string = '<Borders>'; output;
			string = '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'; output;
			string = '</Borders>'; output;
			string = '</Style>'; output;


		string = '</Styles>'; output;
	run;

%mend styles;  


/* makes a header with a title (large font, bold, italic) and subtitular notes */
/* or footnotes */
/* from a given dataset */
/* depending on the value of the group variable */
%macro wsheader(dsin,dsout);

	data &dsout.;
		set &dsin. end=eof;
		length string $&strlen. style $30;
		by group notsorted;

		if first.group then do;
			string = '<Row/>'; output;
		end;

		if group = 'title' then style = 'Header';
		else if group = 'subtitle' then style = 'SubHeader';
		else style = 'Default';

		string = '<Row>'; output;
		string = '<Cell ss:StyleID="'||trim(style)||'">'||
                 '<Data ss:Type="String">'||trim(data)||'</Data></Cell>'; output;
		string = '</Row>'; output;

		if eof then do;
			string = '<Row/>'; output;
		end;

		keep string;
	run;

%mend wsheader;


/* create XML formatted data from a dataset */
%macro wsdata(ds);

	%if not %symexist(fmt) %then %let fmt = N;
	%if &fmt. = N %then %do;
		data &ds._ind;
			do i = 1 to &nobs.;
				header = 0; output;
			end;
			drop i;
		run;
	%end;

	data ws_&ds._data(keep=string);
		set &ds. end=eof;
		set &ds._ind;
		length string $&strlen. style $30 type $6;

		
		/* loop through each variable in the dataset */
		%let dsid = %sysfunc(open(&ds.));
		/* format data header rows */
		if header = 1 then do;
			string = '<Row ss:Height="18">'; output; 
			string = '<Cell ss:MergeAcross="'||trim(put(%eval(&nvars.-1),8.-L))||
                     '" ss:StyleID="DataHeader"><Data ss:Type="String">'||
	                 trim(%sysfunc(varname(&dsid.,1)))||'</Data></Cell>';
			output;
			string = '</Row>'; output;
		end;
		/* format ordinary data rows */
		else do;
			string = '<Row>'; output; 

			%do i = 1 %to %sysfunc(attrn(&dsid.,nvars));
				/* determine variable data type */
				%if %sysfunc(vartype(&dsid.,&i.)) = C %then 
					type = 'String';
				%else 
					type = 'Number';
					;

				/* initialize the missing number indicator to 0 */
				miss_num = 0;

				/* determine the appropriate style */
				%let varname = %sysfunc(varname(&dsid.,&i.));

				style = 'Data'; 
				if type = 'Number' then do;
					if index("&varname",'pct') then 
						style = trim(style)||'Dec1';
					else if "&varname." in ('rd' 'rr' 'ort' 'fd') then
						style = trim(style)||'Dec1';
					else if substr("&varname.",1,min(length("&varname."),2)) in ('rd' 'rr' 'or') 
					or "&varname." = 'p_value' then  
						style = trim(style)||'Dec2';
					/* scientific notation style for extremely large numbers */
					if (&varname. > 10**6) then
						style = 'DataSN';
					/* style for missing numeric data (display a dot) */
					if (missing(&varname.)) then do;
						miss_num = 1;
						type = 'String';
						style = 'DataRight';
					end;
				end;


				%if &fmt. = Y %then %do;
					if upcase("&varname.") = upcase("&sort.") then style = trim(style)||'Highlight';
				%end;
				if eof then style = trim(style)||'Bottom';

				string = '<Cell ss:StyleID="'||trim(style)||'">'||
                          ifc(not (type='String' and missing(&varname) and not miss_num),
                              '<Data ss:Type="'||compress(type)||'">'||
		                      %sysfunc(ifc(&fmt. = Y and &i. = 1,%str('     '||),))
                              ifc(not miss_num,trim(left(&varname.)),'.')||'</Data>','')||
                         '</Cell>';
				output;

			%end; 

			string = '</Row>'; output;
		end;
		%let rc = %sysfunc(close(&dsid.));

	run; 

	%if &fmt. = N %then %do;
		proc datasets library=work nolist nodetails; delete &ds._ind; quit;
	%end;

%mend wsdata;


/* get the count of XML rows prior to the observation where ds = <stop> */
/* or in the entire dataset */
%macro ws_rowcount(ds,stop);

	data _null_;
		set &ds. end=eof;
		retain row_count;
		if ds = "&stop." or eof then do; 
			call symputx("&ds._firstrow",row_count + 1);
			%if %symexist(&ds._nobs) %then %do;
				call symputx("&ds._lastrow",row_count + &&&ds._nobs.);
			%end;
		end;
		if index(string,'<Row') then row_count = sum(row_count,1);
	run;  

%mend ws_rowcount;


/* convert a SAS dataset into a dataset amenable to being converted into XML */
/* changes each variable into a new row and assigns row numbers and datatypes */
%macro annotate(dsin,dsout);

	data &dsout.;
		set &dsin. end=eof;
		%xml_tag_def;
		%xml_init;

		Row = _n_;

		if eof then bottom = 1;

		%let dsid = %sysfunc(open(&dsin.));
		%do ai = 1 %to %sysfunc(attrn(&dsid.,nvars));
			%let var = %sysfunc(varname(&dsid.,&ai.));
			varname = lowcase("&var.");
			Data = left(&var.);
			%if %sysfunc(vartype(&dsid.,&ai.)) = C %then 
				Type = 'String';
			%else 
				Type = 'Number';
				;
			output;
		%end;
		%let rc = %sysfunc(close(&dsid.));

		keep Row Data Type varname bottom
             Height Index MergeAcross MergeDown StyleID Formula Comment Name ArrayRange;
	run;

%mend annotate;


/* convert a dataset with XML tags stored in tag variables into XML */
%macro markup(dsin,dsout);

	data &dsout.;
		set &dsin.;
		by row notsorted;
		length string $&strlen.;

		if first.row then do;
			string = '<Row'||ifc(not missing(Height),' ss:Height="'||trim(left(Height))||'"','')||'>'; output;
		end;

		string = '<Cell'|| 	
		         ifc(Index > 0,' ss:Index="'||trim(left(Index))||'"','')||
		         ifc(MergeAcross > 0,' ss:MergeAcross="'||trim(left(MergeAcross))||'"','')||	
		         ifc(MergeDown > 0,' ss:MergeDown="'||trim(left(MergeDown))||'"','')||
		         ifc(not missing(ArrayRange),' ss:ArrayRange="'||trim(left(ArrayRange))||'"','')||
		         ifc(not missing(StyleID),' ss:StyleID="'||trim(left(StyleID))||'"','')||
                 ifc(not missing(Formula),' ss:Formula="'||trim(left(Formula))||'"','')||'>'||
				 ifc(not missing(Data),'<Data'||ifc(not missing(Type),' ss:Type="'||trim(left(Type))||'"',' ss:Type="String"')||'>'||trim(Data)||'</Data>','')||
				 ifc(not missing(Comment),'<Comment><ss:Data xmlns="http://www.w3.org/TR/REC-html40">'||trim(left(Comment))||'</ss:Data></Comment> ','')||
				 ifc(not missing(Name),'<NamedCell ss:Name="'||trim(left(Name))||'"/>','')||
                 '</Cell>';

		/* get rid of extraneous spaces */
		string = tranwrd(tranwrd(compbl(string),' >','>'),'> <','><');

		/* replace space indicator string '~!' with a space */
		string = tranwrd(string,'~!',' ');

		output;


		if last.row then do;
			string = '</Row>'; output;
		end;

		keep string;
	run;

%mend markup; 


/* set up XML row, cell, and data tag variable types and lengths */
%macro xml_tag_def(defdata=Y);

	length Row 8. varname $32;

	%if &defdata. = Y %then %do;
		length Data $1000 Type $6;
	%end;

	length Formula $500 Height 8. Index 8. MergeAcross 8. MergeDown 8. 
           StyleID $35 Comment $250 Name $35 ArrayRange $12;

%mend xml_tag_def;


/* initialize XML tags to missing */
%macro xml_init(defdata=Y);

	%if &defdata. = Y %then %do;
		call missing(Data,Type);
	%end;

	call missing(Row,varname,Formula,Height,Index,MergeAcross,MergeDown,StyleID,Comment,Name,ArrayRange);

%mend xml_init;


/*****************************/
/* XML STYLE CREATION MACROS */
/*****************************/

/* declarations for the style information variables */
%macro xml_style_dcl;

	length ID $50 
           HA $10 VA $10 Indent 8. Wrap 8. Rotate 8.
           BT 8. BL 8. BR 8. BB 8. BWt 8. BLS $20
           IntClr $6 
		   FontSize 8. FontColor $8 Bold 8. Italic 8.
           NumFmt $75
           ;
	call missing(ID,HA,VA,Indent,Wrap,Rotate,BT,BL,BR,BB,BWt,BLS,FontSize,FontColor,Bold,Italic,NumFmt,IntClr);

%mend;

/* take style information from dataset ds and make an XML style definition */
%macro xml_style_markup(dsin,dsout);

	data &dsout.;
		set &dsin.;
		length string $&strlen.;

		string = '<Style ss:ID="'||trim(left(ID))||'">'; output;

		if (HA ne '' or VA ne '' or Indent or Wrap or Rotate) then do;
			string = '<Alignment '|| 
                     ifc(HA ne '','ss:Horizontal="'||trim(left(HA))||'" ','')||
                     ifc(VA ne '','ss:Vertical="'||trim(left(VA))||'" ','')|| 
                     ifc(Indent ne .,'ss:Indent="'||trim(put(Indent,8. -l))||'" ','')||
                     ifc(Wrap ne .,'ss:WrapText="'||trim(put(Wrap,8. -l))||'" ','')||
					 ifc(Rotate ne .,'ss:Rotate="'||trim(put(Rotate,8. -l))||'"','')||
                     '/>'; output;
		end;

		if (BT or BL or BR or BB) then do;
			string = '<Borders>'; output;
			if BT then do; string = '<Border ss:Position="Top" '||
                                    ifc(BLS ne '','ss:LineStyle="'||trim(BLS)||'" ','ss:LineStyle="Continuous" ')||
                                    ifc(BWt,' ss:Weight="'||trim(put(BWt,8. -l))||'"','')||'/>'; output; end;
			if BL then do; string = '<Border ss:Position="Left" '||
                                    ifc(BLS ne '','ss:LineStyle="'||trim(BLS)||'" ','ss:LineStyle="Continuous" ')||
                                    ifc(BWt,' ss:Weight="'||trim(put(BWt,8. -l))||'"','')||'/>'; output; end;
			if BR then do; string = '<Border ss:Position="Right" '||
                                    ifc(BLS ne '','ss:LineStyle="'||trim(BLS)||'" ','ss:LineStyle="Continuous" ')||
                                    ifc(BWt,' ss:Weight="'||trim(put(BWt,8. -l))||'"','')||'/>'; output; end;
			if BB then do; string = '<Border ss:Position="Bottom" '||
                                    ifc(BLS ne '','ss:LineStyle="'||trim(BLS)||'" ','ss:LineStyle="Continuous" ')||
                                    ifc(BWt,' ss:Weight="'||trim(put(BWt,8. -l))||'"','')||'/>'; output; end;
			string = '</Borders>'; output;
		end;

		if (FontSize ne . or FontColor ne '' or Bold or Italic) then do;
			string = '<Font '||	
                     ifc(FontSize ne .,'ss:Size="'||trim(put(FontSize,8. -l))||'" ','')||
                     ifc(FontColor ne '','ss:Color="#'||trim(FontColor)||'" ','')||
                     ifc(Bold,'ss:Bold="1" ','')||
                     ifc(Italic,'ss:Italic="1"','')||
                     '/>'; output;
		end;

		if IntClr ne '' then do;
			string = '<Interior ss:Color="#'||trim(left(IntClr))||'" ss:Pattern="Solid"/>'; output;
		end;

		if NumFmt ne '' then do;
			string = '<NumberFormat ss:Format="'||trim(left(NumFmt))||'"/>'; output;
		end;

		string = '</Style>'; output;

		keep ID string;
	run;

	data &dsout.;
		set &dsout.;
		string = tranwrd(compbl(string),' />','/>');
	run;

%mend xml_style_markup;
