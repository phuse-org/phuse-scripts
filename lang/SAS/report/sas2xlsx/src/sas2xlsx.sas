%************************************************************************************************************************;
%** Copyright (c) 2015 Edwin van Stein                                                                                 **;
%**                                                                                                                    **;
%** Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated       **;
%** documentation files (the "Software"), to deal in the Software without restriction, including without limitation    **;
%** the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and   **;
%** to permit persons to whom the Software is furnished to do so, subject to the following conditions:                 **;
%**                                                                                                                    **;
%** The above copyright notice and this permission notice shall be included in all copies or substantial portions of   **;
%** the Software.                                                                                                      **;
%**                                                                                                                    **;
%** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO   **;
%** THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE     **;
%** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,**;
%** TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE     **;
%** SOFTWARE.                                                                                                          **;
%************************************************************************************************************************;

%MACRO sas2xlsx(inlib       =,
                indata      =,
                outfile     =,
                outdir      =,
                sheetname   = MEMLABEL,
                headers     = BOTH,
                exclude     =,
                auto_filter = Y,
                freeze      = Y,
                minwidth    = 12,
                maxwidth    = 40,
                verbose     = Y);

%************************************************************************************************************************;
%** sas2xlsx                                                                                                           **;
%************************************************************************************************************************;
%** Program name     : sas2xlsx.sas                                                                                    **;
%** Version          : 1.0 (initial release)                                                                           **;
%** Author           : Edwin van Stein                                                                                 **;
%** Company          : Astellas Pharma Global Development                                                              **;
%** Date             : 2015-10-30                                                                                      **;
%** SAS version      : 9.3                                                                                             **;
%** OS Name/version  : Solaris 10 8/07                                                                                 **;
%** Purpose          : export SAS data sets to XLSX workbook                                                           **;
%** Comment          : version is created on Solaris, to port to a different SAS server update at least:               **;
%**                    - creation of macro variable home starting at line 87                                           **;
%**                    - X statements at line 99, 242, 553 and 575                                                     **;
%**                    - FILE statements at lines 103, 114, 125, 201, 213, 240, 333, 434                               **;
%**                                                                                                                    **;
%**                                                                                                                    **;
%************************************************************************************************************************;
%** sas2xlsx macro parameters                                                                                          **;
%************************************************************************************************************************;
%** inlib       : input library                                                                                        **;
%** indata      : input data sets, this can be:                                                                        **;
%**               - missing, all or ALL: exports all data sets from the input library                                  **;
%**               - a single data set name                                                                             **;
%**               - a name with * as wildcard, for instance PLUS_* for all data sets starting with PLUS_               **;
%**               - a pipe (|) delimited list of data set names                                                        **;
%** outfile     : name of the output xlsx file without extension                                                       **;
%** outdir      : directory where output xlsx should be saved                                                          **;
%** sheetname   : data used for sheetname, this can be:                                                                **;
%**               - MEMNAME: data set names are used for sheet names                                                   **;
%**               - MEMLABEL: data set labels (or name if label is not set) are used for sheet names                   **;
%**               note that sheetnames have a maximum of 31 characters                                                 **;
%**               default is MEMLABEL                                                                                  **;
%** headers     : determines what headers are printed, this can be:                                                    **;
%**               - LABEL: only variable labels (or name if label is not set) are printed as 1st row in each sheet     **;
%**               - NAME: only variable names are printed as 1st row in each sheet                                     **;
%**               - BOTH: first row in each sheet contains variable labels (or name if label is not set), 2nd row in   **;
%**                 each sheet contains variable names                                                                 **;
%**               default is BOTH                                                                                      **;
%** exclude     : a pipe (|) delimited list of variables to exclude                                                    **;
%** auto_filter : determines whether auto filter is turned on, this can be:                                            **;
%**               - Y                                                                                                  **;
%**               - N                                                                                                  **;
%**               default is Y                                                                                         **;
%** freeze      : determines whether headers are frozen, this can be:                                                  **;
%**               - Y                                                                                                  **;
%**               - N                                                                                                  **;
%**               default is Y                                                                                         **;
%** minwidth    : minimum column width in output xlsx in number of characters                                          **;
%** maxwidth    : maximum column width in output xlsx in number of characters                                          **;
%** verbose     : Flag to indicate if information message should be printed to the log                                 **;
%**               - Y                                                                                                  **;
%**               - N                                                                                                  **;
%**               default is Y                                                                                         **;
%************************************************************************************************************************;
/* Changed by       : Katja Glass - Bayer Pharma AG / date: 17NOV2015
 * Reason           : - use just the "zip" command without a path as the zip program might be located on any location
 *                      but is likely to be a system command
 *                    - "touch" the final file so various systems can investigate that the excel file is a program output
 *                    - define used macro variables as local
 *                    - apply different formatting
 *                    - turn of notes etc. and provide information to the log instead
 *                    - new parameter VERBOSE
 *************************************************************************************************************************/
 
    %LOCAL macro mversion _starttime l_opts;
    %LET macro    = &sysmacroname.;
    %LET mversion = 1.0 (17NOV2015);
    
    %LET _starttime = %SYSFUNC(datetime());
    %IF &verbose = Y
    %THEN %DO;
        %PUT - &macro.: Version &mversion started %SYSFUNC(date(),worddate.) %SYSFUNC(time(),hhmm.);
    %END;
    
    %LET l_opts = %SYSFUNC(GETOPTION(SOURCE,keyword))
                  %SYSFUNC(GETOPTION(NOTES, keyword))
                  %SYSFUNC(GETOPTION(FMTERR,keyword))
                  %SYSFUNC(GETOPTION(NOTES, keyword));

    OPTIONS NONOTES NOSOURCE NOFMTERR;
 
    %* define local macro variables;
    %LOCAL i j temp zip_location;

    %* set compression and set missing option that works for Excel;
    OPTIONS COMPRESS=yes MISSING=' ';

    %IF &verbose = Y
    %THEN %DO;
        %PUT - &macro.: Prepare XLXS file using the following parameters:;
        %PUT -     INLIB    = &inlib;
        %PUT -     INDATA   = &indata;
        %PUT -     OUTFILE  = &outfile;
        %PUT -     OUTDIR   = &outdir;
    %END;
    
    %* investigate zip program location;
    FILENAME runoc PIPE "which zip";
    DATA _NULL_;
        INFILE runoc;
        INPUT;
        LENGTH cmd $2000;
        cmd = _infile_;
        CALL SYMPUT('zip_location',STRIP(cmd));
    RUN;    
    %IF %SYSFUNC(FILEEXIST(/usr/bin/zip)) = 0
    %THEN %DO;
        %PUT %str(W)ARNING: - &macro.: Zip program location could not be found. Please make sure the zip program is available.;
        %GOTO galactus;
    %END;
    %ELSE %DO;
        %PUT - &macro.: ZIP program used: &zip_location;
    %END;
    
    
    %PUT %SYSFUNC(FILEEXIST(/usr/bin/zip));
    

    %* get users home directory, if not specified then use output directory;
    FILENAME home PIPE "echo $HOME";
    DATA _NULL_;
        INFILE home;
        INPUT;
        x=_infile_;
        IF x NE ''
            THEN home=strip(x);
            ELSE home="&outdir.";
        CALL symput('home',strip(home));
    RUN;
    FILENAME home;

    %* create temporary directory and sub directories;
    X "cd '&home.'; mkdir _tempxlsx; cd _tempxlsx; /usr/bin/rm -fr * ; mkdir _rels; mkdir docProps; mkdir xl; cd xl; mkdir _rels; mkdir worksheets;";

    %* create .rels;
    DATA _NULL_;
        FILE "&home./_tempxlsx/_rels/.rels" ENCODING="utf-8" LRECL=32000;
        PUT '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
        PUT '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' '0D'x;
        PUT '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>' '0D'x;
        PUT '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' '0D'x;
        PUT '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' '0D'x;
        PUT '</Relationships>' @;
    RUN;

    %* create app.xml;
    DATA _NULL_;
        FILE "&home./_tempxlsx/docProps/app.xml" ENCODING="utf-8" LRECL=32000;
        PUT '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
        PUT '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">' '0D'x;
        PUT '<Application>SAS</Application>' '0D'x;
        PUT '<Company>Astellas Pharma Global Development</Company>' '0D'x;
        PUT '</Properties>' @;
    RUN;

    %* create core.xml;
    DATA _NULL_;
        FILE "&home./_tempxlsx/docProps/core.xml" ENCODING="utf-8" LRECL=32000;
        LENGTH created $200 creator $200;
        created=put(datetime(),is8601dz20.);
        %IF %symexist(_clientusername) %THEN %DO;
            creator=htmlencode(&_clientusername.,'amp gt lt apos quot 7bit');
        %END;
        %ELSE %DO;
            creator=htmlencode("&sysuserid",'amp gt lt apos quot 7bit');
        %END;
        PUT '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
        PUT '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"' @;
        PUT ' xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"' @;
        PUT ' xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' '0D'x;
        PUT '<dc:creator>' creator +(-1) '</dc:creator>' '0D'x;
        PUT '<cp:lastModifiedBy>' creator +(-1) '</cp:lastModifiedBy>' '0D'x;
        PUT '<dcterms:created xsi:type="dcterms:W3CDTF">' created +(-1) '</dcterms:created>' '0D'x;
        PUT '<dcterms:modified xsi:type="dcterms:W3CDTF">' created +(-1) '</dcterms:modified>' '0D'x;
        PUT '</cp:coreProperties>' @;
    RUN;

    %* determine whether single, multiple or all datasets are needed;
    %LOCAL _wc;
    %IF %index(%upcase(&indata.),|) %THEN %DO;
        %LET _wc=and upcase(memname) in ("%sysfunc(tranwrd(%upcase(&indata.),|," "))");
    %END;
    %ELSE
    %IF %index(%upcase(&indata.),*) %THEN %DO;
        %LET _wc= and upcase(memname) like "%sysfunc(tranwrd(%upcase(&indata.),*,%))";
    %END;
    %ELSE
    %IF &indata.=ALL OR &indata.=all OR &indata.= %THEN %DO;
        %LET _wc=;
    %END;
    %ELSE %DO;
        %LET _wc=and upcase(memname) eq "%upcase(&indata.)";
    %END;

    %* determine data sets to process;
    PROC SQL NOPRINT;
        CREATE TABLE _dsets AS
        SELECT
         memname
        , memlabel
        %IF %index(%upcase(&indata),|) %THEN %DO;
            , case
            %DO i=1 %TO %sysfunc(count(&indata.,|))+1;
                when upcase(memname)=upcase("%scan(&indata.,&i.,|)") then &i.
            %END;
            end as sorter
        %END;
        %ELSE %DO;
            , monotonic() as sorter
        %END;
        , nobs
        from
         sashelp.vtable
        where
         upcase(libname)=upcase("&inlib.")
         AND upcase(memtype)='DATA'
         &_wc.
        order by
         sorter
        ;
    QUIT;

    %* %str(a)bort if no data sets selected;
    %IF &sqlobs.=0 %THEN %DO;
        %PUT %str(W)ARNING: - &macro.: Current selection does not result in any data to be processed. Macro will %str(a)bort!;
        %GOTO galactus;
    %END;
    %* also %str(a)bort if not all data sets are found;
    %ELSE
    %IF "&indata." NE "ALL" AND "&indata." NE "all" AND NOT %index(%upcase(&indata.),*) AND &sqlobs. NE %sysfunc(count(&indata.,|))+1 %THEN %DO;
        %PUT %str(W)ARNING: - &macro.: Not all data sets specified were found. Macro will %str(a)bort!;
        %GOTO galactus;
    %END;
    %ELSE %DO;

        %* create workbook.xml.rels;
        DATA _NULL_;
            FILE "&home./_tempxlsx/xl/_rels/workbook.xml.rels" ENCODING="utf-8" LRECL=32000;
            PUT '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
            PUT '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' '0D'x;
            DO i=1 TO &sqlobs.;
                PUT '<Relationship Id="rId' i +(-1) '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"' @;
                PUT ' Target="worksheets/sheet' i +(-1) '.xml"/>' '0D'x;
            END;
            PUT '</Relationships>' @;
        RUN;

        %* create [Content_types].xml;
        DATA _NULL_;
            FILE "&home./_tempxlsx/Content_types.xml" ENCODING="utf-8" LRECL=32000;
            PUT '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
            PUT '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' '0D'x;
            PUT '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' '0D'x;
            PUT '<Default Extension="xml" ContentType="application/xml"/>' '0D'x;
            PUT '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>' '0D'x;
            PUT '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' '0D'x;
            PUT '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' '0D'x;
            DO i=1 TO &sqlobs.;
                PUT '<Override PartName="/xl/worksheets/sheet' i +(-1) '.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' '0D'x;
            END;
            PUT '</Types>' @;
        RUN;

        %* rename to the proper name (SAS does not like [] in filenames);
        X "cd '&home./_tempxlsx'; mv Content_types.xml [Content_types].xml";

        %* create workbook.xml;
        DATA _NULL_;
            SET _dsets END=eof;
            LENGTH lbl $200;
            %IF %upcase(&sheetname.)=MEMNAME %THEN %DO;
                lbl=htmlencode(substr(memname,1,31),'amp gt lt apos quot 7bit');
            %END;
            %ELSE
            %IF %upcase(&sheetname.)=MEMLABEL %THEN %DO;
                lbl=compress(htmlencode(substr(coalescec(memlabel,memname),1,31),'amp gt lt apos quot 7bit'),'/\?*[]:');
            %END;
            FILE "&home./_tempxlsx/xl/workbook.xml" ENCODING="utf-8" LRECL=32000;
            IF _N_=1 THEN DO;
                PUT '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
                PUT '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' '0D'x;
                PUT '<sheets>' '0D'x;
            END;
            PUT '<sheet name="' lbl +(-1) '" sheetId="' sorter +(-1) '" r:id="rId' sorter +(-1) '"/>' '0D'x;
            IF eof THEN DO;
                PUT '</sheets>' '0D'x;
                PUT '</workbook>' @;
            END;
        RUN;

        %* get memnames;
        PROC SQL NOPRINT;
            SELECT
                memname
              , nobs
             INTO
                :memnames SEPARATED BY '@'
              , :nobs SEPARATED BY '@'
             FROM
                _dsets
             ORDER BY
                sorter
             ;
        QUIT;

        %* determine whether column exclusion is needed;
        %LOCAL _wc2;
        %IF %index(%upcase(&exclude.),|) %THEN %DO;
            %LET _wc2=and upcase(name) not in ("%sysfunc(tranwrd(%upcase(&exclude.),|," "))");
        %END;
        %ELSE
        %IF &exclude.= %THEN %DO;
            %LET _wc2=;
        %END;
        %ELSE %DO;
            %LET _wc2=and upcase(name) ne "%upcase(&exclude.)";
        %END;

        %* loop through data sets;
        %DO i=1 %TO &sqlobs.;

            %* get variable information;
            PROC SQL NOPRINT;
                SELECT
                   name
                 , compress(coalescec(label,name),',') AS label
                 , type
                 , coalescec(format,'_none_') AS format
                 , count(DISTINCT(name)) AS vars
                INTO
                   :names SEPARATED BY '@'
                 , :labels SEPARATED BY '@'
                 , :types SEPARATED BY '@'
                 , :formats SEPARATED BY '@'
                 , :vars
                FROM dictionary.columns
                WHERE
                   upcase(libname)=upcase("&inlib.")
                   AND upcase(memname)="%scan(&memnames.,&i.,@)"
                   &_wc2.
                ORDER BY
                   varnum
                ;

                %* get variable lengths;
                SELECT DISTINCT
                %DO j=1 %TO &vars.;
                    %IF &j. NE 1 %THEN %DO;
                        !! '@' !!
                    %END;
                    %IF %scan(&types.,&j.,@)=num AND (%scan(&formats.,&j.,@)=_none_ OR %index(%scan(&formats.,&j.,@),BEST) OR %sysfunc(compress(%scan(&formats.,&j.,@),'0123456789.'))= ) %THEN %DO;
                        "8"
                    %END;
                    %ELSE
                    %IF %scan(&formats.,&j.,@)=_none_ %THEN %DO;
                        strip(put(max(length(strip(%scan(&names.,&j.,@)))),best8.))
                    %END;
                    %ELSE %DO;
                        strip(put(max(length(strip(put(%scan(&names.,&j.,@),%scan(&formats.,&j.,@))))),best8.))
                    %END;
                %END;
                into
                   :lengths
                from
                   &inlib..%scan(&memnames.,&i.,@) (ENCODING='asciiany')
                ;
            QUIT;

            %IF %scan(&nobs.,&i.,@)=0 %THEN %DO;

                %* no observations;
                DATA _NULL_;
                    FILE "&home./_tempxlsx/xl/worksheets/sheet&i..xml" ENCODING="utf-8" LRECL=32000;
                    %IF %upcase(&headers.)=BOTH %THEN %DO;
                        __lastrow=3;
                        __firstrow=2;
                    %END;
                    %ELSE %DO;
                        __lastrow=2;
                        __firstrow=1;
                    %END;
                    LENGTH __lastcol __col $2 __lastcell $20 __val $4000;
                    IF &vars. LE 26 THEN __lastcol=byte(mod(&vars.,27)+64);
                    ELSE
                    __lastcol=translate(byte(floor((&vars.-1)/26)+64)!!byte(mod(&vars.,26)+64),'Z','@');
                    __lastcell=strip(__lastcol) !! strip(put(__lastrow,best8.));

                    %* start of the sheet;
                    PUT '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
                    PUT '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' '0D'x;
                    PUT '<dimension ref="A1:' __lastcell +(-1) '"/>' '0D'x;
                    PUT '<sheetViews>' '0D'x;
                    %IF &i.=1 %THEN %DO;
                        PUT '<sheetView tabSelected="1" workbookViewId="0">' '0D'x;
                    %END;
                    %ELSE %DO;
                        PUT '<sheetView workbookViewId="0">' '0D'x;
                    %END;
                    %IF %upcase(&freeze.) = Y %THEN %DO;
                        %IF %upcase(&headers.)=BOTH %THEN %DO;
                            PUT '<pane ySplit="2" topLeftCell="A3" activePane="bottomLeft" state="frozen"/>' '0D'x;
                            PUT '<selection pane="bottomLeft" activeCell="A3" sqref="A3"/>' '0D'x;
                        %END;
                        %ELSE %DO;
                            PUT '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>' '0D'x;
                            PUT '<selection pane="bottomLeft" activeCell="A2" sqref="A2"/>' '0D'x;
                        %END;
                    %END;
                    PUT '</sheetView>' '0D'x;
                    PUT '</sheetViews>' '0D'x;
                    PUT '<cols>' '0D'x;
                    %DO j=1 %TO &vars.;
                        __colwidth=round(1.1*&minwidth.);
                        PUT '<col min="' "&j." '" max="' "&j." '" width="' __colwidth +(-1) '" customWidth="1"/>' '0D'x;
                    %END;
                    PUT '</cols>' '0D'x;
                    PUT '<sheetData>' '0D'x;

                    %* row with variable labels;
                    %IF %upcase(&headers.)=BOTH OR %upcase(&headers.)=LABEL %THEN %DO;
                        PUT '<row r="1">' '0D'x;
                        %DO j=1 %TO &vars.;
                            IF &j. LE 26 THEN __col=byte(mod(&j.,27)+64);
                            ELSE
                            __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                            __val=htmlencode("%scan(&labels.,&j.,@)",'amp gt lt apos quot 7bit');
                            PUT '<c r="' __col +(-1) '1" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                        %END;
                        PUT '</row>' '0D'x;
                    %END;

                    %* row with variable names (in case both are needed);
                    %IF %upcase(&headers.)=BOTH %THEN %DO;
                        PUT '<row r="2">' '0D'x;
                        %DO j=1 %TO &vars.;
                            IF &j. LE 26 THEN __col=byte(mod(&j.,27)+64);
                            ELSE
                            __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                            __val=htmlencode("%scan(&names.,&j.,@)",'amp gt lt apos quot 7bit');
                            PUT '<c r="' __col +(-1) '2" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                        %END;
                        PUT '</row>' '0D'x;
                    %END;

                    %* row with variable names;
                    %ELSE
                    %IF %upcase(&headers.)=NAME %THEN %DO;
                        PUT '<row r="1">' '0D'x;
                        %DO j=1 %TO &vars.;
                            IF &j. LE 26 THEN __col=byte(mod(&j.,27)+64);
                            ELSE
                            __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                            __val=htmlencode("%scan(&names.,&j.,@)",'amp gt lt apos quot 7bit');
                            PUT '<c r="' __col +(-1) '1" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                        %END;
                        PUT '</row>' '0D'x;
                    %END;

                    %* actual data rows;
                    PUT '<row r="3">' '0D'x;
                    PUT '<c r="A3" t="inlineStr"><is><t>This data set does not contain any observations</t></is></c>' '0D'x;
                    PUT '</row>' '0D'x;

                    %* close the sheet;
                    PUT '</sheetData>' '0D'x;
                    %IF %upcase(&auto_filter.)=Y %THEN %DO;
                        PUT '<autoFilter ref="A' __firstrow +(-1) ':' __lastcell +(-1) '"/>' '0D'x;
                    %END;
                    PUT '</worksheet>' @;
                RUN;

            %END;

            %ELSE %DO;

                %* create worksheet per data set;
                DATA _NULL_;
                    SET &inlib..%scan(&memnames.,&i.,@) (ENCODING='asciiany') END=__eof NOBS=__nobs;
                    FILE "&home./_tempxlsx/xl/worksheets/sheet&i..xml" ENCODING="utf-8" LRECL=32000;
                    %IF %upcase(&headers.)=BOTH %THEN %DO;
                        __row=_N_+2;
                        __firstrow=2;
                        __lastrow=__nobs+2;
                    %END;
                    %ELSE %DO;
                        __row=_N_+1;
                        __firstrow=1;
                        __lastrow=__nobs+1;
                    %END;
                    LENGTH __lastcol __col $2 __lastcell $20 __val $4000;
                    IF &vars. LE 26 THEN __lastcol=byte(mod(&vars.,27)+64);
                    ELSE
                    __lastcol=translate(byte(floor((&vars.-1)/26)+64)!!byte(mod(&vars.,26)+64),'Z','@');
                    __lastcell=strip(__lastcol) !! strip(put(__lastrow,best8.));

                    IF _N_=1 THEN DO;
                        %* start of the sheet;
                        PUT '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
                        PUT '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' '0D'x;
                        PUT '<dimension ref="A1:' __lastcell +(-1) '"/>' '0D'x;
                        PUT '<sheetViews>' '0D'x;
                        %IF &i.=1 %THEN %DO;
                            PUT '<sheetView tabSelected="1" workbookViewId="0">' '0D'x;
                        %END;
                        %ELSE %DO;
                            PUT '<sheetView workbookViewId="0">' '0D'x;
                        %END;
                        %IF %upcase(&freeze.) = Y %THEN %DO;
                            %IF %upcase(&headers.)=BOTH %THEN %DO;
                                PUT '<pane ySplit="2" topLeftCell="A3" activePane="bottomLeft" state="frozen"/>' '0D'x;
                                PUT '<selection pane="bottomLeft" activeCell="A3" sqref="A3"/>' '0D'x;
                            %END;
                            %ELSE %DO;
                                PUT '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>' '0D'x;
                                PUT '<selection pane="bottomLeft" activeCell="A2" sqref="A2"/>' '0D'x;
                            %END;
                        %END;
                        PUT '</sheetView>' '0D'x;
                        PUT '</sheetViews>' '0D'x;
                        PUT '<cols>' '0D'x;
                        %DO j=1 %TO &vars.;
                            __colwidth=round(1.1*min(max(%scan(&lengths.,&j.,@),&minwidth.),&maxwidth.));
                            PUT '<col min="' "&j." '" max="' "&j." '" width="' __colwidth +(-1) '" customWidth="1"/>' '0D'x;
                        %END;
                        PUT '</cols>' '0D'x;
                        PUT '<sheetData>' '0D'x;

                        %* row with variable labels;
                        %IF %upcase(&headers.)=BOTH OR %upcase(&headers.)=LABEL %THEN %DO;
                            PUT '<row r="1">' '0D'x;
                            %DO j=1 %TO &vars.;
                                IF &j. LE 26 THEN __col=byte(mod(&j.,27)+64);
                                ELSE
                                __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                                __val=htmlencode("%scan(&labels.,&j.,@)",'amp gt lt apos quot 7bit');
                                PUT '<c r="' __col +(-1) '1" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                            %END;
                            PUT '</row>' '0D'x;
                        %END;

                        %* row with variable names (in case both are needed);
                        %IF %upcase(&headers.)=BOTH %THEN %DO;
                            PUT '<row r="2">' '0D'x;
                            %DO j=1 %TO &vars.;
                                IF &j. LE 26 THEN __col=byte(mod(&j.,27)+64);
                                ELSE
                                __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                                __val=htmlencode("%scan(&names.,&j.,@)",'amp gt lt apos quot 7bit');
                                PUT '<c r="' __col +(-1) '2" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                            %END;
                            PUT '</row>' '0D'x;
                        %END;

                        %* row with variable names;
                        %ELSE
                        %IF %upcase(&headers.)=NAME %THEN %DO;
                            PUT '<row r="1">' '0D'x;
                            %DO j=1 %TO &vars.;
                                IF &j. LE 26 THEN __col=byte(mod(&j.,27)+64);
                                ELSE
                                __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                                __val=htmlencode("%scan(&names.,&j.,@)",'amp gt lt apos quot 7bit');
                                PUT '<c r="' __col +(-1) '1" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                            %END;
                            PUT '</row>' '0D'x;
                        %END;
                    END;

                    %* actual data rows;
                    PUT '<row r="' __row +(-1) '">' '0D'x;
                    %DO j=1 %TO &vars.;
                        IF &j. LE 26 THEN __col=byte(mod(&j.,27)+64);
                        ELSE
                        __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                        __val=htmlencode(vvalue(%scan(&names.,&j.,@)),'amp gt lt apos quot 7bit');
                        IF index(__val,'1A'x) THEN __val=translate(__val,'?','1A'x);

                        %* numeric variables without format;
                        %IF %scan(&types.,&j.,@)=num AND (%scan(&formats.,&j.,@)=_none_ OR %index(%scan(&formats.,&j.,@),BEST) OR %sysfunc(compress(%scan(&formats.,&j.,@),'0123456789.'))= ) %THEN %DO;
                            PUT '<c r="' __col +(-1) __row +(-1) '"><v>' __val +(-1) '</v></c>' '0D'x;
                        %END;
                        %* other variables;
                        %ELSE %DO;
                            PUT '<c r="' __col +(-1) __row +(-1) '" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                        %END;
                    %END;
                    PUT '</row>' '0D'x;

                    %* close the sheet;
                    IF __eof THEN DO;
                        PUT '</sheetData>' '0D'x;
                        %IF %upcase(&auto_filter.)=Y %THEN %DO;
                            PUT '<autoFilter ref="A' __firstrow +(-1) ':' __lastcell +(-1) '"/>' '0D'x;
                        %END;
                        PUT '</worksheet>' @;
                    END;
                RUN;

            %END;

        %END;
        
        %IF &verbose = Y
        %THEN %DO;
            %PUT - &macro.: Create final XLSX through a zip file;
        %END;

        %* create xlsx file;
        X "cd '&home./_tempxlsx'; &zip_location -r &outfile..xlsx *; mv '&home./_tempxlsx/&outfile..xlsx' '&outdir./&outfile..xlsx'";

        %* "touch" the output file;
        FILENAME _tout "&outdir./&outfile..xlsx";
        %LET temp=%SYSFUNC(fopen(_tout, A));
        %LET temp= %SYSFUNC(fclose(&temp));
        FILENAME _tout;

    %END;

%* the devourer of macros;
%GALACTUS:

    %* remove temporary directory and contents;
    X "cd '&home.'; /usr/bin/rm -fr _tempxlsx";

    %* clean up;
    PROC DATASETS LIBRARY=work MEMTYPE=data NOLIST NOWARN;
        DELETE _dsets;
        RUN;
    QUIT;
    
    OPTIONS &l_opts.;
    %IF &verbose = Y
    %THEN %DO;
        %PUT - &macro.: version &mversion terminated. Runtime: %SYSFUNC(putn(%SYSFUNC(datetime())-&_starttime., F12.2)) seconds!;
    %END;

%MEND sas2xlsx;
