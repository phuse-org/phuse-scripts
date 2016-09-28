%************************************************************************************************************************;
%**                                                                                                                    **;
%** License: MIT                                                                                                       **;
%**                                                                                                                    **;
%** Copyright (c) 2016 Katja Glass                                                                                     **;
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

%MACRO definexml_v1(
    outfile          =
  , indat_header     = header
  , indat_datasets   = datasets
  , indat_variables  = variables
  , indat_valuelevel = valuelevel
  , indat_codes      = codes
  , indat_methods    = methods
  , indat_comment    = comments
  , indat_documents  = documents)
/ DES = 'Create Define XML out of information datasets';

/*******************************************************************************
 * Macro rely on: none
 *******************************************************************************
 * Purpose          : Create Define XML out of information datasets
 * Programming Spec :
 * Validation Level : n.a.
 * Parameters       :
 *      outfile          : output file name
 *      indat_header     : input dataset containing general information
 *      indat_datasets   : input dataset containing datasets information
 *      indat_variables  : input dataset containing variables information
 *      indat_valuelevel : input dataset containing value level information
 *      indat_codes      : input dataset containing code information
 *      indat_methods    : input dataset containing method information
 *      indat_comment    : input dataset containing comment information
 *      indat_documents  : input dataset containing document information
 *
 * SAS Version      : HP-UX 9.2
 *******************************************************************************
 * Preconditions    :
 *     Macrovar. needed:
 *     Datasets  needed: INDAT_HEADER, INDAT_DATASETS and INDAT_VARIABLES must exist
 *     Ext.Prg/Mac used:
 * Postconditions   :
 *     Macrovar created:
 *     Output   created:  OUTFILE XML is created
 *     Datasets created:
 * Comments         :
 *******************************************************************************
 * Author(s)        : sgqyq (Katja Glass) / date: 28SEP2016 / V1.0
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       :
 * Reason           :
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %definexml();
 ******************************************************************************/

    %LOCAL macro mversion _starttime macro_parameter_error;
    %LET macro    = &sysmacroname.;
    %LET mversion = 1.0;


    %IF (%QUOTE(&macro_parameter_error.) EQ %STR(1)) %THEN %RETURN;

    %LET _starttime = %SYSFUNC(datetime());
    %PUT - &macro.: Version &mversion started %SYSFUNC(date(),worddate.) %SYSFUNC(time(),hhmm.);

    %LOCAL l_opts ;
    %LET l_opts = %SYSFUNC(getoption(source,keyword))
                  %SYSFUNC(getoption(notes,keyword))
                  %SYSFUNC(getoption(fmterr,keyword));

    OPTIONS NONOTES NOSOURCE NOFMTERR;

    %LOCAL l_crf_leaf
           l_standard;

%*;
%* check existence of required datasets;
%*;

    %IF %SYSFUNC(EXIST(%SCAN(&indat_header.,1,%STR(%(%))))) = 0 OR %LENGTH(&indat_header.) = 0
    %THEN %DO;
        %PUT ERROR: - &macro.: Required dataset INDAT_HEADER = &indat_header has not been provided.;
        %PUT - &macro.: Macro terminates due to errors.;
        %GOTO end_macro;
    %END;

    %IF %SYSFUNC(EXIST(%SCAN(&indat_datasets.,1,%STR(%(%))))) = 0 OR %LENGTH(&indat_datasets.) = 0
    %THEN %DO;
        %PUT ERROR: - &macro.: Required dataset INDAT_DATASETS = &indat_datasets has not been provided.;
        %PUT - &macro.: Macro terminates due to errors.;
        %GOTO end_macro;
    %END;

    %IF %SYSFUNC(EXIST(%SCAN(&indat_variables,1,%STR(%(%))))) = 0 OR %LENGTH(&indat_variables) = 0
    %THEN %DO;
        %PUT ERROR: - &macro.: Required dataset INDAT_VARIABLES = &indat_variables has not been provided.;
        %PUT - &macro.: Macro terminates due to errors.;
        %GOTO end_macro;
    %END;

%*;
%* create optional datasets if not available with correct structure but empty content;
%*;

    %* if the parameters are not filled, use temporary datasets;
    %IF %LENGTH(&indat_valuelevel) = 0 %THEN %LET indat_valuelevel = _tmp_xml_vl;
    %IF %LENGTH(&indat_codes)      = 0 %THEN %LET indat_codes      = _tmp_xml_code;
    %IF %LENGTH(&indat_methods)    = 0 %THEN %LET indat_methods    = _tmp_xml_mt;
    %IF %LENGTH(&indat_comment)    = 0 %THEN %LET indat_comment    = _tmp_xml_cm;
    %IF %LENGTH(&indat_documents)  = 0 %THEN %LET indat_documents  = _tmp_xml_doc;

    %IF %SYSFUNC(EXIST(%SCAN(&indat_valuelevel,1,%STR(%(%))))) = 0
    %THEN %DO;
        %PUT - &macro.: Optional dataset INDAT_VALUELEVEL = &indat_valuelevel is created empty.;

        DATA &indat_valuelevel;
            %definexml_v1_attributes_for(valuelevel);
            SET _NULL_;
        RUN;
    %END;

    %IF %SYSFUNC(EXIST(%SCAN(&indat_codes,1,%STR(%(%))))) = 0
    %THEN %DO;
        %PUT - &macro.: Optional dataset INDAT_CODES = &indat_codes is created empty.;

        DATA &indat_codes;
            %definexml_v1_attributes_for(codes);
            SET _NULL_;
        RUN;
    %END;

    %IF %SYSFUNC(EXIST(%SCAN(&indat_methods,1,%STR(%(%))))) = 0
    %THEN %DO;
        %PUT - &macro.: Optional dataset INDAT_METHODS = &indat_methods is created empty.;

        DATA &indat_methods;
            %definexml_v1_attributes_for(methods);
            SET _NULL_;
        RUN;
    %END;

    %IF %SYSFUNC(EXIST(%SCAN(&indat_comment,1,%STR(%(%))))) = 0
    %THEN %DO;
        %PUT - &macro.: Optional dataset INDAT_COMMENT = &indat_comment is created empty.;

        DATA &indat_comment;
            %definexml_v1_attributes_for(comments);
            SET _NULL_;
        RUN;
    %END;

    %IF %SYSFUNC(EXIST(%SCAN(&indat_documents,1,%STR(%(%))))) = 0
    %THEN %DO;
        %PUT - &macro.: Optional dataset INDAT_DOCUMENTS = &indat_documents is created empty.;

        DATA &indat_documents;
            %definexml_v1_attributes_for(documents);
            SET _NULL_;
        RUN;
    %END;

%*;
%* parameter checks;
%*;

    %IF %LENGTH(&outfile) = 0
    %THEN %DO;
        %PUT ERROR: - &macro.: Required parameter OUTFILE must not be empty.;
        %PUT - &macro.: Macro terminates due to errors.;
        %GOTO end_macro;
    %END;

    %IF %UPCASE(%SCAN(&outfile,-1,.)) NE XML
    %THEN %DO;
        %LET outfile = &outfile..xml;
    %END;

%*;
%* read input datasets;
%* perform checks;
%*;

    %PUT - &macro.: Read and update input datasets.;

    DATA _header;
        %definexml_v1_attributes_for(header);
        ATTRIB _std_without_ig FORMAT=$20.;
        SET &indat_header;
        KEEP fileoid studyoid studyname studydescription protocolname standard version schemalocation stylesheet originator _std_without_ig;
        %* update casing for STANDARD;
        IF      UPCASE(standard) = "ADAM-IG"
        THEN DO;
            standard = "ADaM-IG";
        END;
        ELSE IF UPCASE(standard) = "SDTM-IG"
        THEN DO;
            standard = "SDTM-IG";
        END;
        ELSE IF UPCASE(standard) = "SEND"
        THEN DO;
            standard = "SEND-IG";
        END;
        ELSE DO;
            PUT "WAR" "NING: &macro - Check STANDARD value in header - in most cases it should be ADaM-IG, SDTM-IG or SEND-IG";
        END;
        _std_without_ig = SCAN(standard,1,"-");
        CALL SYMPUTX('l_standard',_std_without_ig);
    RUN;

    DATA _datasets(RENAME=(comment = documentation domain = name));
        %definexml_v1_attributes_for(datasets);

        SET &indat_datasets;
        KEEP domain description class structure purpose archivelocation archivelocationid repeating isreferencedata comment ordid archivelocation;
        archivelocationid = archivelocation;
        IF INDEX(archivelocationid,"/") > 0 THEN archivelocationid = SCAN(archivelocationid,-1,'/');
    RUN;

    DATA _variables;
        %definexml_v1_attributes_for(variables);
        SET &indat_variables;
        KEEP domain varnum variable label keysequence type length significantdigits origin crfpage predecessor displayformat
             computationmethodoid codelistname mandatory valuelistoid comment;
        %* check that LENGTH is not missing;
        IF MISSING(length) and type in ('float' 'integer' 'text')
           THEN PUT "WARNING: &macro - LENGTH must not be missing in data %UPCASE(&indat_variables.): " domain variable;
        %* check mandatory must either be NO or YES.;
        IF UPCASE(mandatory) NOT IN ("NO","YES")
           THEN PUT "WARNING: &macro - MANDATORY must be NO/YES in data %UPCASE(&indat_variables.): " domain variable;
    RUN;

    DATA _valuelevel;
        %definexml_v1_attributes_for(valuelevel);
        SET &indat_valuelevel;
        KEEP valuelistoid valueorder valuename itemoid whereclauseoid type length origin crfpage predecessor computationmethodoid
             codelistname significantdigits displayformat mandatory description comment;
    RUN;

    DATA _codes;
        %definexml_v1_attributes_for(codes);
        SET &indat_codes;
        KEEP codelistname codelistlabel rank code codedvalue extendedvalue_ny translated type codelistdictionary codelistversion
             decoded oid_postfix;
    RUN;

    DATA _methods;
        %definexml_v1_attributes_for(methods);
        SET &indat_methods;
        KEEP computationmethodoid computationmethodname computationmethodtype description pdfleaf pdfpage pdfdestination;
    RUN;

    DATA _comment;
        %definexml_v1_attributes_for(comments);
        SET &indat_comment;
        KEEP commentoid description pdfleaf pdfpage pdfdestination;
    RUN;

    DATA _documents;
        %definexml_v1_attributes_for(documents);
        SET &indat_documents.;
        KEEP pdfleaf pdflink pdftitle annotatedcrf;
    RUN;

    %_definexml_quote_xml_v1(data=_header    );
    %_definexml_quote_xml_v1(data=_datasets  );
    %_definexml_quote_xml_v1(data=_variables );
    %_definexml_quote_xml_v1(data=_valuelevel);
    %_definexml_quote_xml_v1(data=_codes     );
    %_definexml_quote_xml_v1(data=_methods   );
    %_definexml_quote_xml_v1(data=_comment   );
    %_definexml_quote_xml_v1(data=_documents );

%*;
%* apply additional settings;
%*;

    %LOCAL l_file;
    %LET l_file = %SCAN(&outfile,-1,/);
    FILENAME output "&outfile" encoding="UTF-8";

    PROC SQL NOPRINT;
        SELECT PDFLEAF INTO :l_crf_leaf FROM _documents WHERE annotatedcrf = 1;
    QUIT;
    %LET l_crf_leaf = &l_crf_leaf;  %* remove blanks at the end;

%*;
%* Create TOC dataset containing information from DATASETS and VARIABLES;
%*;

    PROC SORT DATA=_datasets; BY name; RUN;

    PROC SQL NOPRINT;
        CREATE TABLE _toc_inf AS
               SELECT a.*, b.* FROM _datasets A, _variables B
               WHERE A.name = B.domain;
    QUIT;

    DATA _toc_inf;
        SET _toc_inf;

        ATTRIB oid FORMAT=$200.;
        ATTRIB itemoid FORMAT=$200.;
        oid = STRIP(name);
        itemoid = STRIP(name) || "." || STRIP(variable);
    RUN;

%*;
%* Create XML;
%*;

    %PUT - &macro.: Create XML file.;


****************************************************************************************;
* create HEADER information;
****************************************************************************************;

    DATA _NULL_;
        FILE output lrecl=2000  encoding="UTF-8" NOTITLES NOFOOTNOTES;
        ATTRIB line FORMAT=$200.;
        SET _header;

        * head information;
        PUT '<?xml version="1.0" encoding="UTF-8"?>';
        PUT '<?xml-stylesheet type="text/xsl" href="' stylesheet +(-1) '"?>';

        PUT "<!-- ********************************************************************************** -->";
        line = "<!-- File: &l_file" || REPEAT(' ',76 - LENGTH("&l_file")) || "-->";
        PUT line;
        line = "<!-- Author: &sysuserid" || REPEAT(' ',74 - LENGTH("&sysuserid")) || "-->";
        PUT line;
        PUT "<!-- Description: This is the define.xml for a study                                    -->";
        PUT "<!-- ********************************************************************************** -->";

        PUT @1 '<ODM';
        PUT @3 'xmlns="' schemalocation +(-1) '"';
        PUT @3 'xmlns:xlink="http://www.w3.org/1999/xlink"';
        PUT @3 'xmlns:def="http://www.cdisc.org/ns/def/v2.0"';
        PUT @3 'ODMVersion="1.3.2"';
        PUT @3 'FileOID="'  fileoid +(-1) '"';
        PUT @3 'FileType="Snapshot"';
        line = "CreationDateTime=""" || PUT(datetime(),E8601DT.) || '"';
        PUT @3 line;


        PUT @3 'Originator="' originator +(-1) '"' /
            @3 'SourceSystem="SAS Macro definexml"' /
            @3 "SourceSystemVersion=""&mversion"">" /
            @3 '<Study OID="' studyoid +(-1) '">' /
            @3 '<GlobalVariables>' /
            @5 '<StudyName>' studyname +(-1) '</StudyName>' /
            @5 '<StudyDescription>' studydescription +(-1) '</StudyDescription>' /
            @5 '<ProtocolName>' protocolname +(-1) '</ProtocolName>' /
            @3 '</GlobalVariables>' /
            @3 '<MetaDataVersion OID="CDISC.' _std_without_ig +(-1) '.' version +(-1) '"' /
            @5 'Name="' studyname +(-1) ', Data Definitions"' /
            @5 'Description="' studyname +(-1) ', Data Definitions"' /
            @5 'def:DefineVersion="2.0.0"' /
            @5 'def:StandardName="' standard +(-1) '"'/
            @5 'def:StandardVersion="' version +(-1) '">';
        IF UPCASE(standard) = "SDTM-IG" THEN
        DO;
            PUT @5 '<def:AnnotatedCRF>' /
                @7 "<def:DocumentRef leafID=""&l_crf_leaf""/>" /
                @5 '</def:AnnotatedCRF>';
        END;
        PUT @5 '<def:SupplementalDoc>';
        DO UNTIL (lobs);
            SET _documents (WHERE=(annotatedcrf NE 1)) END=lobs;
            PUT @7 '<def:DocumentRef leafID="' pdfleaf +(-1) '"/>';
        END;
        PUT @5 '</def:SupplementalDoc>';
    RUN;

****************************************************************************************;
* VALUE LEVEL detail information (def:ValueListDef);
****************************************************************************************;

    PROC SORT DATA=_valuelevel;
        BY valuelistoid itemoid;
    RUN;

    DATA _NULL_;
        SET _valuelevel END=eof;
        BY valuelistoid;
        FILE output MOD LRECL=2000  ENCODING="UTF-8";

        IF _N_ = 1
        THEN DO;
            PUT @5 "<!-- ******************************************* -->" /
                @5 "<!-- VALUE LEVEL LIST DEFINITION INFORMATION  ** -->" /
                @5 "<!-- ******************************************* -->";
        END;
        IF FIRST.valuelistoid
           THEN PUT @5 '<def:ValueListDef OID="' valuelistoid +(-1) '">';

        PUT @7 '<ItemRef ItemOID="' itemoid +(-1) '"' /
            @16 'OrderNumber="' valueorder +(-1) '"' /
            @16 'Mandatory="' mandatory +(-1) '"' ;
        IF computationmethodoid NE ''
            THEN PUT @16 'MethodOID="' computationmethodoid +(-1) '"';
        PUT @16 '>' /
            @9 '<def:WhereClauseRef WhereClauseOID="' whereclauseoid +(-1) '"/>' /
            @7 '</ItemRef>';

        IF LAST.valuelistoid
           THEN PUT @5 '</def:ValueListDef>';
    RUN;

****************************************************************************************;
* VALUE LEVEL WHERE CLAUSE information (def:WhereClauseDef);
****************************************************************************************;

    DATA _NULL_;
        SET _valuelevel END=eof;
        BY valuelistoid itemoid;
        FILE output MOD LRECL=2000  ENCODING="UTF-8";

        ATTRIB varval FORMAT=$200.;
        ATTRIB varcat FORMAT=$200.;

        * support of missing values, either using nothing or MISSING;
        whereclauseoid = TRANWRD(whereclauseoid,'..','. .');

        IF _N_ = 1
        THEN DO;
            PUT @5 "<!-- ***************************************************** -->" /
                @5 "<!-- VALUE LEVEL WHERE CLAUSE DEFINITION INFORMATION    ** -->" /
                @5 "<!-- ***************************************************** -->";
        END;

        IF FIRST.itemoid
           THEN PUT @5 '<def:WhereClauseDef OID="' whereclauseoid +(-1) '">';

        DO _i = 3 TO COUNTW(whereclauseoid,'.') -1 BY 2;
            varcat = COMPRESS('IT.' || SCAN(whereclauseoid,2,'.') || '.' ||
                     SCAN(whereclauseoid, _i , '.'));
            varval = COMPRESS(SCAN(whereclauseoid, _i + 1, '.'));
            IF varval = "MISSING" THEN varval = "";
            PUT @7 '<RangeCheck SoftHard="Soft" def:ItemOID="' varcat +(-1) '" Comparator="EQ">' /
                @11 '<CheckValue>' varval +(-1) '</CheckValue>' /
                @7 '</RangeCheck>';
        END;

        IF LAST.itemoid
           THEN PUT @5 '</def:WhereClauseDef>';
    RUN;

****************************************************************************************;
* create DATASET information for TOC (ItemGroupDef);
****************************************************************************************;

    PROC SORT DATA=_toc_inf; BY ordid name; RUN;

    DATA _NULL_;
        FILE output mod lrecl=2000  encoding="UTF-8";

        SET _toc_inf;
        BY ordid name;

        IF FIRST.ordid
        THEN DO;
            PUT @5 "<!-- ******************************************* -->" /
                @5 "<!-- " oid @25 "ItemGroupDef INFORMATION *** -->" /
                @5 "<!-- ******************************************* -->" /
                @5 '<ItemGroupDef OID="IG.' oid +(-1) '"';
            %IF &l_standard. = SDTM
            %THEN %DO;
                PUT @7 'Domain="' name +(-1) '"';
            %END;
            PUT @7 'Name="' name +(-1) '"' /
                @7 'Repeating="' repeating +(-1) '"' /
                @7 'IsReferenceData="' isreferencedata +(-1) '"' /
                @7 'SASDatasetName="' name +(-1) '"' /
                @7 'Purpose="' purpose +(-1) '"' /
                @7 'def:Structure="' structure +(-1) '"' /
                @7 'def:Class="' class +(-1) '"' /
                @7 'def:CommentOID="' documentation +(-1) '"' /
                @7 'def:ArchiveLocationID="LF.' archivelocationid +(-1) '">';
            PUT @7 '<Description>' /
                @7 '<TranslatedText xml:lang="en">' description +(-1) '</TranslatedText>' /
                @7 '</Description>';
        END;

        PUT @7 '<ItemRef ItemOID="IT.' itemoid +(-1) '"' /
            @9 'OrderNumber="' varnum +(-1) '"' /
            @9 'Mandatory="' mandatory +(-1) '"';
        IF keysequence NE ' '
        THEN DO;
            PUT @9 'KeySequence="' keysequence +(-1) '"';
        END;
        IF computationmethodoid NE ' '
        THEN DO;
            PUT @9 'MethodOID="' computationmethodoid +(-1) '"';
        END;
        PUT @7 '/>';

        IF LAST.ordid
        THEN DO;
            PUT @7 "<!-- **************************************************** -->" /
                @7 "<!-- def:leaf details for hypertext linking the dataset -->" /
                @7 "<!-- **************************************************** -->" /
                @7 '<def:leaf ID="LF.' archivelocationid +(-1) '" xlink:href="' archivelocation +(-1) '.xpt">' /
                @9 '<def:title>' archivelocation +(-1) '.xpt </def:title>' /
                @7 '</def:leaf>' /
                @5 '</ItemGroupDef>';
        END;
    RUN;

****************************************************************************************;
* create VARIABLES information (ItemDef);
****************************************************************************************;

    DATA _NULL_;
        SET _toc_inf END=eof;

        FILE output mod lrecl=2000  encoding="UTF-8";

        IF _N_ = 1 THEN
        PUT @5 "<!-- ************************************************************ -->" /
            @5 "<!-- The details of each variable is here for all domains -->" /
            @5 "<!-- ************************************************************ -->" ;
        PUT @5 '<ItemDef OID="IT.' itemoid +(-1) '"' /
            @7 'Name="' variable +(-1) '"' /
            @7 'DataType="' type +(-1) '"' ;
        IF type IN ('float' 'integer' 'text')
           THEN PUT @7 'Length="' length +(-1) '"';
        PUT @7 'SASFieldName="' variable +(-1) '"' ;
        IF significantdigits NE ''
           THEN PUT @7 'SignificantDigits="' significantdigits +(-1) '"';
        IF displayformat NE ''
           THEN PUT @7 'def:DisplayFormat="' displayformat +(-1) '"';
        IF comment NE ''
           THEN PUT @7 'def:CommentOID="' comment +(-1) '"';
        PUT @5 '>';
        PUT @7 '<Description>' /
            @7 '<TranslatedText xml:lang="en">' label +(-1) '</TranslatedText>' /
            @7 '</Description>';
        IF codelistname NE ''
           THEN PUT @7 '<CodeListRef CodeListOID="CL.' codelistname +(-1) '"/>';
        PUT @7 '<def:Origin Type="' origin +(-1) '"' /;
        IF UPCASE(origin) = "CRF"
        THEN DO;
            PUT @7 '>' /
                @9 "<def:DocumentRef leafID=""&l_crf_leaf"">" /
                @11 '<def:PDFPageRef PageRefs=" ' crfpage +(-1)'" Type="PhysicalRef"/>' /
                @9 '</def:DocumentRef>' /
                @7 '</def:Origin>' /;
        END;
        ELSE IF UPCASE(origin) = "PREDECESSOR"
        THEN DO;
            PUT @7  '>' /
                @9  '<Description>' /
                @11 '<TranslatedText xml:lang="en">' predecessor +(-1) '</TranslatedText>' /
                @9  '</Description>' /
                @7  '</def:Origin>' /;
        END;
        ELSE DO;
            PUT @7 '/>' ;
        END;
        IF valuelistoid NE ''
           THEN PUT @7 '<def:ValueListRef ValueListOID="' valuelistoid +(-1) '"/>';
        PUT @5 '</ItemDef>';
    RUN;

****************************************************************************************;
* create general VALUE LEVEL information (ItemDef);
****************************************************************************************;

    DATA _NULL_;
        SET _valuelevel END=eof;
        FILE output MOD LRECL=2000  ENCODING="UTF-8";
        IF _N_ = 1
        THEN DO;
            PUT @5 "<!-- ************************************************************ -->" /
                @5 "<!-- The details of value level items are here                    -->" /
                @5 "<!-- ************************************************************ -->" ;
        END;
        PUT @5 '<ItemDef OID="' itemoid +(-1) '"' /
            @7 'Name="' valuename +(-1) '"' /
            @7 'SASFieldName="' valuename +(-1) '"' /
            @7 'DataType="' type +(-1) '"' /
            @7 'Length="' length +(-1) '"';
        IF significantdigits NE ''
           THEN PUT @7 'SignificantDigits="' significantdigits +(-1) '"';
        IF displayformat NE ''
           THEN PUT @7 'def:DisplayFormat="' displayformat +(-1) '"';
        IF comment NE ''
           THEN PUT @7 'def:CommentOID="' comment +(-1) '"';
        PUT @5 '>';
        IF description NE ' '
        THEN DO;
            PUT @7 '<Description>' /
                @7 '<TranslatedText xml:lang="en">' description +(-1) '</TranslatedText>' /
                @7 '</Description>';
        END;
        IF codelistname NE ''
           THEN PUT @7 '<CodeListRef CodeListOID="CL.' codelistname +(-1) '"/>';
        PUT @7 '<def:Origin Type="' origin +(-1) '"' /;
        IF UPCASE(origin) = "CRF"
        THEN DO;
            PUT @7 '>' /
                @9 "<def:DocumentRef leafID=""&l_crf_leaf"">" /
                @11 '<def:PDFPageRef PageRefs=" ' crfpage +(-1)'" Type="PhysicalRef"/>' /
                @9 '</def:DocumentRef>' /
                @7 '</def:Origin>' /;
        END;
        ELSE IF UPCASE(origin) = "PREDECESSOR"
        THEN DO;
            PUT @7  '>' /
                @9  '<Description>' /
                @11 '<TranslatedText xml:lang="en">' predecessor +(-1) '</TranslatedText>' /
                @9  '</Description>' /
                @7  '</def:Origin>' /;
        END;
        ELSE DO;
            PUT @7 '/>' ;
        END;
        PUT @5 '</ItemDef>';
    RUN;


****************************************************************************************;
* CODELIST items (CodeList);
****************************************************************************************;

    PROC SORT DATA=_codes;
        BY codelistname rank;
    RUN;

    DATA _NULL_;
        SET _codes END=eof;
        BY codelistname rank;
        FILE output MOD LRECL=2000  ENCODING="UTF-8";

        IF _N_ = 1
        THEN DO;
            PUT @5 "<!-- ************************************************************ -->" /
                @5 "<!-- Codelists are presented below                                -->" /
                @5 "<!-- ************************************************************ -->" ;
        END;

        IF FIRST.codelistname
        THEN DO;
            IF NOT MISSING(OID_Postfix)
                THEN PUT @5 '<CodeList OID="CL.' codelistname +(-1) '.' oid_postfix + (-1) '"';
                ELSE PUT @5 '<CodeList OID="CL.' codelistname +(-1) '"';
            PUT @7 'Name="' codelistlabel +(-1) '"' /
                @7 'DataType="' type +(-1)'">';
        END;

        **** output codelists that are not external dictionaries;
        IF codelistdictionary = ''
        THEN DO;
            IF UPCASE(decoded) NE 'YES'
            THEN DO;
                PUT @7 '<EnumeratedItem CodedValue="' codedvalue +(-1) '"' @;
                IF rank NE .                               THEN PUT ' OrderNumber="' rank +(-1) '"' @;
                IF UPCASE(extendedvalue_ny) IN ('Y','YES') THEN PUT ' def:ExtendedValue="Yes"' @;
                PUT '>';

                IF code NE ' '
                    THEN PUT @7 '<Alias Name="' code +(-1) '" Context="nci:ExtCodeID"/>';
                PUT @7 '</EnumeratedItem>';
            END;
            ELSE DO;
                PUT @7 '<CodeListItem CodedValue="' codedvalue +(-1) '"' @;
                IF rank NE .                               THEN PUT ' OrderNumber="' rank +(-1) '"' @;
                IF UPCASE(extendedvalue_ny) IN ('Y','YES') THEN PUT ' def:ExtendedValue="Yes"' @;
                PUT '>';

                PUT @9 '<Decode>' /
                    @11 '<TranslatedText>' translated +(-1) '</TranslatedText>' /
                    @9 '</Decode>' ;
                IF code NE ' '
                   THEN PUT @7 '<Alias Name="' code +(-1) '" Context="nci:ExtCodeID"/>';
                PUT @7 '</CodeListItem>';
            END;
            IF codelist NE ' '
               THEN PUT @7 '<Alias Name="' codelist +(-1) '" Context="nci:ExtCodeID"/>';
        END;

        **** output codelists that are pointers to external codelists;
        ELSE DO;
            IF codelistdictionary NE ''
            THEN DO;
                PUT @7 '<ExternalCodeList Dictionary="' codelistdictionary +(-1)
                       '" Version="' codelistversion +(-1) '"/>';
            END;
        END;

        IF LAST.codelistname
           THEN PUT @5 '</CodeList>';
    RUN;

****************************************************************************************;
* COMPUTATIONAL MEHTODS (MethodDef);
****************************************************************************************;

    DATA _NULL_;
        SET _methods END=eof;
        FILE output MOD LRECL=2000  ENCODING="UTF-8";

        IF _N_ = 1
        THEN DO;
            PUT @5 "<!-- ******************************************* -->" /
                @5 "<!-- COMPUTATIONAL METHOD INFORMATION *** -->" /
                @5 "<!-- ******************************************* -->";
        END;

        PUT @5  '<MethodDef OID="' computationmethodoid +(-1) '"'/
            @16 'Name="' computationmethodname +(-1) '"' /
            @16 'Type="' computationmethodtype +(-1)'">' /
            @7  '<Description>' /
            @7  '<TranslatedText xml:lang="en">' description +(-1) '</TranslatedText>' /
            @7  '</Description>';
        IF NOT MISSING(pdfleaf)
        THEN DO;
            PUT @7 '<def:DocumentRef leafID="' pdfleaf +(-1) '">';
            IF NOT MISSING(pdfpage)
            THEN DO;
                PUT @9 '<def:PDFPageRef PageRefs="' pdfpage +(-1) '" Type="PhysicalRef"/>';
            END;
            ELSE IF NOT MISSING(pdfdestination)
            THEN DO;
                PUT @9 '<def:PDFPageRef PageRefs="' pdfdestination +(-1) '" Type="NamedDestination"/>';
            END;
            PUT @7 '</def:DocumentRef>';
        END;
        PUT @5 '</MethodDef>';
    RUN;

****************************************************************************************;
* COMMENTS (def:CommentDef);
****************************************************************************************;

    DATA _NULL_;
        SET _comment END=eof;
        FILE output MOD LRECL=2000  ENCODING="UTF-8";

        IF _N_ = 1
        THEN DO;
            PUT @5 "<!-- ******************************* -->" /
                @5 "<!-- COMMENTS INFORMATION *** -->" /
                @5 "<!-- ******************************** -->";
        END;

        PUT @5 '<def:CommentDef OID="' commentoid +(-1) '">'/
            @7 '<Description>' /
            @7 '<TranslatedText xml:lang="en">' description +(-1) '</TranslatedText>' /
            @7 '</Description>';
        IF NOT MISSING(pdfleaf)
        THEN DO;
            PUT @7 '<def:DocumentRef leafID="' pdfleaf +(-1) '">';
            IF NOT MISSING(pdfpage)
            THEN DO;
                PUT @9 '<def:PDFPageRef PageRefs="' pdfpage +(-1) '" Type="PhysicalRef"/>';
            END;
            ELSE IF NOT MISSING(pdfdestination)
            THEN DO;
                PUT @9 '<def:PDFPageRef PageRefs="' pdfdestination +(-1) '" Type="NamedDestination"/>';
            END;
            PUT @7 '</def:DocumentRef>';
        END;
        PUT @5 '</def:CommentDef>';
    RUN;

****************************************************************************************;
* define leaves (def:leaf);
****************************************************************************************;

    DATA _NULL_;
        FILE output mod lrecl=2000  encoding="UTF-8";

        SET _documents;

        PUT @5 '<def:leaf ID="' pdfleaf +(-1) '" xlink:href="' pdflink +(-1) '">' /
            @7 '<def:title>' pdftitle +(-1) '</def:title>' /
            @5 '</def:leaf>';
    RUN;

****************************************************************************************;
* close definitions;
****************************************************************************************;

    DATA _NULL_;
        FILE output mod lrecl=2000  encoding="UTF-8";

        PUT @5 '</MetaDataVersion>';
        PUT @3 '</Study>';
        PUT "</ODM>";
    RUN;

%*;
%* Reset, clean-up and finish;
%*;

%end_macro:;

    PROC DATASETS NOLIST NOWARN;
        DELETE _codes _comment _datasets _documents _header
               _methods _tmp _toc_inf _valuelevel _variables
               _tmp_xml_vl _tmp_xml_code _tmp_xml_mt _tmp_xml_cm _tmp_xml_doc;
    QUIT;

    OPTIONS &l_opts.;

    %PUT - &macro.: version &mversion terminated. Runtime: %SYSFUNC(putn(%SYSFUNC(datetime())-&_starttime., F12.2)) seconds!;

%MEND definexml_v1;

%MACRO _definexml_quote_xml_v1(data=);
    %LOCAL l_varlist l_i;

    PROC SQL NOPRINT;
        SELECT name INTO :l_varlist SEPARATED BY ' '
               FROM dictionary.columns WHERE libname="WORK" AND memname="%UPCASE(&data)" and type="char";
    QUIT;

    DATA &data;
        SET &data;
        %DO l_i = 1 %TO %SYSFUNC(COUNTW(%STR( )&l_varlist));
            %SCAN(&l_varlist,&l_i) = TRANWRD(%SCAN(&l_varlist,&l_i),"&",'&amp;');
            %SCAN(&l_varlist,&l_i) = TRANWRD(%SCAN(&l_varlist,&l_i),'"','&quot;');
            %SCAN(&l_varlist,&l_i) = TRANWRD(%SCAN(&l_varlist,&l_i),"'",'&apos;');
            %SCAN(&l_varlist,&l_i) = TRANWRD(%SCAN(&l_varlist,&l_i),"<",'&lt;');
            %SCAN(&l_varlist,&l_i) = TRANWRD(%SCAN(&l_varlist,&l_i),">",'&gt;');
        %END;
    RUN;

%MEND _definexml_quote_xml_v1;

