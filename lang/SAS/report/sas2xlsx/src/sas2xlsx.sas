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

%macro sas2xlsx( inlib =
              , indata =
             , outfile =
              , outdir =
           , sheetname = MEMLABEL
             , headers = BOTH
             , exclude = 
         , auto_filter = Y 
              , freeze = Y 
            , minwidth = 12 
            , maxwidth = 40 );

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
   %************************************************************************************************************************;

   %* set compression and set missing option that works for Excel;
   options compress=yes missing=' ';

   %* get users home directory, if not specified then use output directory;
   filename home pipe "echo $HOME";
   data _null_;
      infile home;
      input;
      x=_infile_;
      if x ne '' then home=strip(x);
      else home="&outdir.";
      call symput('home',strip(home));
   run;
   filename home;
   
   %* create temporary directory and sub directories;
   x "cd '&home.'; mkdir _tempxlsx; cd _tempxlsx; /usr/bin/rm -fr * ; mkdir _rels; mkdir docProps; mkdir xl; cd xl; mkdir _rels; mkdir worksheets;";

   %* create .rels;
   data _null_;
      file "&home./_tempxlsx/_rels/.rels" encoding="utf-8" lrecl=32000;
      put '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
      put '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' '0D'x;
      put '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>' '0D'x;
      put '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' '0D'x;
      put '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' '0D'x;
      put '</Relationships>' @;
   run;

   %* create app.xml;
   data _null_;
      file "&home./_tempxlsx/docProps/app.xml" encoding="utf-8" lrecl=32000;
      put '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
      put '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">' '0D'x;
      put '<Application>SAS</Application>' '0D'x;
      put '<Company>Astellas Pharma Global Development</Company>' '0D'x;
      put '</Properties>' @;
   run;

   %* create core.xml;
   data _null_;
      file "&home./_tempxlsx/docProps/core.xml" encoding="utf-8" lrecl=32000;
      length created $200 creator $200;
      created=put(datetime(),is8601dz20.);
      %if %symexist(_clientusername) %then %do;
         creator=htmlencode(&_clientusername.,'amp gt lt apos quot 7bit');
      %end;
      %else %do;
         creator=htmlencode("&sysuserid",'amp gt lt apos quot 7bit');
      %end;
      put '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
      put '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"' @;
      put ' xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"' @;
      put ' xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' '0D'x;
      put '<dc:creator>' creator +(-1) '</dc:creator>' '0D'x;
      put '<cp:lastModifiedBy>' creator +(-1) '</cp:lastModifiedBy>' '0D'x;
      put '<dcterms:created xsi:type="dcterms:W3CDTF">' created +(-1) '</dcterms:created>' '0D'x;
      put '<dcterms:modified xsi:type="dcterms:W3CDTF">' created +(-1) '</dcterms:modified>' '0D'x;
      put '</cp:coreProperties>' @;
   run;

   %* determine whether single, multiple or all datasets are needed;
   %local _wc;
   %if %index(%upcase(&indata.),|) %then %do;
      %let _wc=and upcase(memname) in ("%sysfunc(tranwrd(%upcase(&indata.),|," "))");
   %end;
   %else %if %index(%upcase(&indata.),*) %then %do;
      %let _wc= and upcase(memname) like "%sysfunc(tranwrd(%upcase(&indata.),*,%))";
   %end;
   %else %if &indata.=ALL or &indata.=all or &indata.= %then %do;
      %let _wc=;
   %end;
   %else %do;
      %let _wc=and upcase(memname) eq "%upcase(&indata.)";
   %end;

   %* determine data sets to process;
   proc sql noprint;
      create table _dsets as
      select
         memname
       , memlabel
         %if %index(%upcase(&indata),|) %then %do;
          , case
            %do i=1 %to %sysfunc(count(&indata.,|))+1;
               when upcase(memname)=upcase("%scan(&indata.,&i.,|)") then &i.
            %end;
            end as sorter   
         %end;
         %else %do;
          , monotonic() as sorter
         %end;
       , nobs
      from
         sashelp.vtable
      where
         upcase(libname)=upcase("&inlib.")
         and upcase(memtype)='DATA'
         &_wc.
      order by
         sorter
      ;
   quit;

   %* %str(a)bort if no data sets selected;
   %if &sqlobs.=0 %then %do;
      %put %str(W)ARNING: current selection does not result in any data to be processed. Macro will %str(a)bort!;
      %goto galactus;
   %end;
   %* also %str(a)bort if not all data sets are found;
   %else %if "&indata." ne "ALL" and "&indata." ne "all" and not %index(%upcase(&indata.),*) and &sqlobs. ne %sysfunc(count(&indata.,|))+1 %then %do;
      %put %str(W)ARNING: not all data sets specified were found. Macro will %str(a)bort!;
      %goto galactus;
   %end;
   %else %do;
   
      %* create workbook.xml.rels;
      data _null_;
         file "&home./_tempxlsx/xl/_rels/workbook.xml.rels" encoding="utf-8" lrecl=32000;
         put '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
         put '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' '0D'x;
         do i=1 to &sqlobs.;
            put '<Relationship Id="rId' i +(-1) '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"' @;
            put ' Target="worksheets/sheet' i +(-1) '.xml"/>' '0D'x;
         end;
         put '</Relationships>' @;
      run;

      %* create [Content_types].xml;
      data _null_;
         file "&home./_tempxlsx/Content_types.xml" encoding="utf-8" lrecl=32000;
         put '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
         put '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' '0D'x;
         put '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' '0D'x;
         put '<Default Extension="xml" ContentType="application/xml"/>' '0D'x;
         put '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>' '0D'x;
         put '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' '0D'x;
         put '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' '0D'x;
         do i=1 to &sqlobs.;
            put '<Override PartName="/xl/worksheets/sheet' i +(-1) '.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' '0D'x;
         end;
         put '</Types>' @;
      run;

      %* rename to the proper name (SAS does not like [] in filenames);
      x "cd '&home./_tempxlsx'; mv Content_types.xml [Content_types].xml";

      %* create workbook.xml;
      data _null_;
         set _dsets end=eof;
         length lbl $200;
         %if %upcase(&sheetname.)=MEMNAME %then %do;
            lbl=htmlencode(substr(memname,1,31),'amp gt lt apos quot 7bit');
         %end;
         %else %if %upcase(&sheetname.)=MEMLABEL %then %do;
            lbl=compress(htmlencode(substr(coalescec(memlabel,memname),1,31),'amp gt lt apos quot 7bit'),'/\?*[]:');
         %end;
         file "&home./_tempxlsx/xl/workbook.xml" encoding="utf-8" lrecl=32000;
         if _n_=1 then do;
            put '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
            put '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' '0D'x;
            put '<sheets>' '0D'x;
         end;
         put '<sheet name="' lbl +(-1) '" sheetId="' sorter +(-1) '" r:id="rId' sorter +(-1) '"/>' '0D'x;
         if eof then do;
            put '</sheets>' '0D'x;
            put '</workbook>' @;
         end;
      run;

      %* get memnames;
      proc sql noprint;
         select
            memname
          , nobs
         into
            :memnames separated by '@'
          , :nobs separated by '@'
         from
            _dsets
         order by
            sorter
         ;
      quit;

      %* determine whether column exclusion is needed;
      %local _wc2;
      %if %index(%upcase(&exclude.),|) %then %do;
         %let _wc2=and upcase(name) not in ("%sysfunc(tranwrd(%upcase(&exclude.),|," "))");
      %end;
      %else %if &exclude.= %then %do;
         %let _wc2=;
      %end;
      %else %do;
         %let _wc2=and upcase(name) ne "%upcase(&exclude.)";
      %end;

      %* loop through data sets;
      %do i=1 %to &sqlobs.;

         %* get variable information;
         proc sql noprint;
            select
               name
             , compress(coalescec(label,name),',') as label
             , type
             , coalescec(format,'_none_') as format
             , count(distinct(name)) as vars
            into
               :names separated by '@'
             , :labels separated by '@'
             , :types separated by '@'
             , :formats separated by '@'
             , :vars
            from dictionary.columns
            where
               upcase(libname)=upcase("&inlib.")
               and upcase(memname)="%scan(&memnames.,&i.,@)"
               &_wc2.
            order by
               varnum
            ;

            %* get variable lengths;
            select distinct
               %do j=1 %to &vars.;
                  %if &j. ne 1 %then %do;
                     !! '@' !!
                  %end;
                  %if %scan(&types.,&j.,@)=num and (%scan(&formats.,&j.,@)=_none_ or %index(%scan(&formats.,&j.,@),BEST) or %sysfunc(compress(%scan(&formats.,&j.,@),'0123456789.'))= ) %then %do;
                     "8"
                  %end;
                  %else %if %scan(&formats.,&j.,@)=_none_ %then %do;
                     strip(put(max(length(strip(%scan(&names.,&j.,@)))),best8.))
                  %end;
                  %else %do;
                     strip(put(max(length(strip(put(%scan(&names.,&j.,@),%scan(&formats.,&j.,@))))),best8.))
                  %end;
               %end;
            into
               :lengths
            from
               &inlib..%scan(&memnames.,&i.,@) (encoding='asciiany')
            ;
         quit;

         %if %scan(&nobs.,&i.,@)=0 %then %do;

            %* no observations;
            data _null_;
               file "&home./_tempxlsx/xl/worksheets/sheet&i..xml" encoding="utf-8" lrecl=32000;
               %if %upcase(&headers.)=BOTH %then %do;
                  __lastrow=3;
                  __firstrow=2;
               %end;
               %else %do;
                  __lastrow=2;
                  __firstrow=1;
               %end;
               length __lastcol __col $2 __lastcell $20 __val $4000;
               if &vars. le 26 then __lastcol=byte(mod(&vars.,27)+64);
               else __lastcol=translate(byte(floor((&vars.-1)/26)+64)!!byte(mod(&vars.,26)+64),'Z','@');
               __lastcell=strip(__lastcol) !! strip(put(__lastrow,best8.));
              
               %* start of the sheet;
               put '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
               put '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' '0D'x;
               put '<dimension ref="A1:' __lastcell +(-1) '"/>' '0D'x;
               put '<sheetViews>' '0D'x;
               %if &i.=1 %then %do;
                  put '<sheetView tabSelected="1" workbookViewId="0">' '0D'x;   
               %end;
               %else %do;
                  put '<sheetView workbookViewId="0">' '0D'x;
               %end;
               %if %upcase(&freeze.) = Y %then %do;
                  %if %upcase(&headers.)=BOTH %then %do;
                     put '<pane ySplit="2" topLeftCell="A3" activePane="bottomLeft" state="frozen"/>' '0D'x;
                     put '<selection pane="bottomLeft" activeCell="A3" sqref="A3"/>' '0D'x;
                  %end;
                  %else %do;
                     put '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>' '0D'x;
                     put '<selection pane="bottomLeft" activeCell="A2" sqref="A2"/>' '0D'x;
                  %end;
               %end;
               put '</sheetView>' '0D'x;
               put '</sheetViews>' '0D'x;
               put '<cols>' '0D'x;
               %do j=1 %to &vars.;
                  __colwidth=round(1.1*&minwidth.);
                  put '<col min="' "&j." '" max="' "&j." '" width="' __colwidth +(-1) '" customWidth="1"/>' '0D'x;
               %end;
               put '</cols>' '0D'x;
               put '<sheetData>' '0D'x;

               %* row with variable labels;
               %if %upcase(&headers.)=BOTH or %upcase(&headers.)=LABEL %then %do;
                  put '<row r="1">' '0D'x;
                  %do j=1 %to &vars.;
                     if &j. le 26 then __col=byte(mod(&j.,27)+64);
                     else __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                     __val=htmlencode("%scan(&labels.,&j.,@)",'amp gt lt apos quot 7bit');
                     put '<c r="' __col +(-1) '1" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                  %end;
                  put '</row>' '0D'x;
               %end;

               %* row with variable names (in case both are needed);
               %if %upcase(&headers.)=BOTH %then %do;
                  put '<row r="2">' '0D'x;
                  %do j=1 %to &vars.;
                     if &j. le 26 then __col=byte(mod(&j.,27)+64);
                     else __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                     __val=htmlencode("%scan(&names.,&j.,@)",'amp gt lt apos quot 7bit');
                     put '<c r="' __col +(-1) '2" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                  %end;
                  put '</row>' '0D'x;
               %end;

               %* row with variable names;
               %else %if %upcase(&headers.)=NAME %then %do;
                  put '<row r="1">' '0D'x;
                  %do j=1 %to &vars.;
                     if &j. le 26 then __col=byte(mod(&j.,27)+64);
                     else __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                     __val=htmlencode("%scan(&names.,&j.,@)",'amp gt lt apos quot 7bit');
                     put '<c r="' __col +(-1) '1" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                  %end;
                  put '</row>' '0D'x;
               %end;

               %* actual data rows;
               put '<row r="3">' '0D'x;
               put '<c r="A3" t="inlineStr"><is><t>This data set does not contain any observations</t></is></c>' '0D'x;
               put '</row>' '0D'x;

               %* close the sheet;
               put '</sheetData>' '0D'x;
               %if %upcase(&auto_filter.)=Y %then %do;
                  put '<autoFilter ref="A' __firstrow +(-1) ':' __lastcell +(-1) '"/>' '0D'x;
               %end;
               put '</worksheet>' @;
            run;

         %end;

         %else %do;

            %* create worksheet per data set;
            data _null_;
               set &inlib..%scan(&memnames.,&i.,@) (encoding='asciiany') end=__eof nobs=__nobs;
               file "&home./_tempxlsx/xl/worksheets/sheet&i..xml" encoding="utf-8" lrecl=32000;
               %if %upcase(&headers.)=BOTH %then %do;
                  __row=_n_+2;
                  __firstrow=2;
                  __lastrow=__nobs+2;
               %end;
               %else %do;
                  __row=_n_+1;
                  __firstrow=1;
                  __lastrow=__nobs+1;
               %end;
               length __lastcol __col $2 __lastcell $20 __val $4000;
               if &vars. le 26 then __lastcol=byte(mod(&vars.,27)+64);
               else __lastcol=translate(byte(floor((&vars.-1)/26)+64)!!byte(mod(&vars.,26)+64),'Z','@');
               __lastcell=strip(__lastcol) !! strip(put(__lastrow,best8.));
              
               if _n_=1 then do;
                  %* start of the sheet;
                  put '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' '0D'x;
                  put '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' '0D'x;
                  put '<dimension ref="A1:' __lastcell +(-1) '"/>' '0D'x;
                  put '<sheetViews>' '0D'x;
                  %if &i.=1 %then %do;
                     put '<sheetView tabSelected="1" workbookViewId="0">' '0D'x;   
                  %end;
                  %else %do;
                     put '<sheetView workbookViewId="0">' '0D'x;
                  %end;
                  %if %upcase(&freeze.) = Y %then %do;
                     %if %upcase(&headers.)=BOTH %then %do;
                        put '<pane ySplit="2" topLeftCell="A3" activePane="bottomLeft" state="frozen"/>' '0D'x;
                        put '<selection pane="bottomLeft" activeCell="A3" sqref="A3"/>' '0D'x;
                     %end;
                     %else %do;
                        put '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>' '0D'x;
                        put '<selection pane="bottomLeft" activeCell="A2" sqref="A2"/>' '0D'x;
                     %end;
                  %end;
                  put '</sheetView>' '0D'x;
                  put '</sheetViews>' '0D'x;
                  put '<cols>' '0D'x;
                  %do j=1 %to &vars.;
                     __colwidth=round(1.1*min(max(%scan(&lengths.,&j.,@),&minwidth.),&maxwidth.));
                     put '<col min="' "&j." '" max="' "&j." '" width="' __colwidth +(-1) '" customWidth="1"/>' '0D'x;
                  %end;
                  put '</cols>' '0D'x;
                  put '<sheetData>' '0D'x;

                  %* row with variable labels;
                  %if %upcase(&headers.)=BOTH or %upcase(&headers.)=LABEL %then %do;
                     put '<row r="1">' '0D'x;
                     %do j=1 %to &vars.;
                        if &j. le 26 then __col=byte(mod(&j.,27)+64);
                        else __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                        __val=htmlencode("%scan(&labels.,&j.,@)",'amp gt lt apos quot 7bit');
                        put '<c r="' __col +(-1) '1" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                     %end;
                     put '</row>' '0D'x;
                  %end;

                  %* row with variable names (in case both are needed);
                  %if %upcase(&headers.)=BOTH %then %do;
                     put '<row r="2">' '0D'x;
                     %do j=1 %to &vars.;
                        if &j. le 26 then __col=byte(mod(&j.,27)+64);
                        else __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                        __val=htmlencode("%scan(&names.,&j.,@)",'amp gt lt apos quot 7bit');
                        put '<c r="' __col +(-1) '2" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                     %end;
                     put '</row>' '0D'x;
                  %end;

                  %* row with variable names;
                  %else %if %upcase(&headers.)=NAME %then %do;
                     put '<row r="1">' '0D'x;
                     %do j=1 %to &vars.;
                        if &j. le 26 then __col=byte(mod(&j.,27)+64);
                        else __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                        __val=htmlencode("%scan(&names.,&j.,@)",'amp gt lt apos quot 7bit');
                        put '<c r="' __col +(-1) '1" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                     %end;
                     put '</row>' '0D'x;
                  %end;
               end;

               %* actual data rows;
               put '<row r="' __row +(-1) '">' '0D'x;
               %do j=1 %to &vars.;
                  if &j. le 26 then __col=byte(mod(&j.,27)+64);
                  else __col=translate(byte(floor((&j.-1)/26)+64)!!byte(mod(&j.,26)+64),'Z','@');
                  __val=htmlencode(vvalue(%scan(&names.,&j.,@)),'amp gt lt apos quot 7bit');
                  if index(__val,'1A'x) then __val=translate(__val,'?','1A'x);

                  %* numeric variables without format;
                  %if %scan(&types.,&j.,@)=num and (%scan(&formats.,&j.,@)=_none_ or %index(%scan(&formats.,&j.,@),BEST) or %sysfunc(compress(%scan(&formats.,&j.,@),'0123456789.'))= ) %then %do;
                     put '<c r="' __col +(-1) __row +(-1) '"><v>' __val +(-1) '</v></c>' '0D'x;
                  %end;
                  %* other variables;
                  %else %do;
                     put '<c r="' __col +(-1) __row +(-1) '" t="inlineStr"><is><t>' __val +(-1) '</t></is></c>' '0D'x;
                  %end;
               %end;
               put '</row>' '0D'x;

               %* close the sheet;
               if __eof then do;
                  put '</sheetData>' '0D'x;
                  %if %upcase(&auto_filter.)=Y %then %do;
                     put '<autoFilter ref="A' __firstrow +(-1) ':' __lastcell +(-1) '"/>' '0D'x;
                  %end;
                  put '</worksheet>' @;
               end;
            run;

         %end;

      %end;

      %* create xlsx file;
      x "cd '&home./_tempxlsx'; /sas/common/prod/bin/zip -r &outfile..xlsx *; mv '&home./_tempxlsx/&outfile..xlsx' '&outdir./&outfile..xlsx'";

   %end;

   %* the devourer of macros;
   %galactus:

   %* remove temporary directory and contents;
   x "cd '&home.'; /usr/bin/rm -fr _tempxlsx";

   %* clean up;
   proc datasets library=work memtype=data nolist nowarn;
      delete _dsets;
   run;
   quit;

%mend sas2xlsx;
