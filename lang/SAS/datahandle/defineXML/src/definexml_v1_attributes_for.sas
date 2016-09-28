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

%MACRO definexml_v1_attributes_for(data) / DES = 'Create ATTRIB statements for required input datasets for the defineXML macro';

/*******************************************************************************
 * Macro rely on: none
 *******************************************************************************
 * Purpose          : Create ATTRIB statements for required input datasets for the defineXML macro
 * Programming Spec :
 * Validation Level : n.a.
 * Parameters       :
 *                    data : one of header datasets variables valuelevel codes methods comments documents
 *                           provides in-line dataset ATTRIB statements to create interface datasets used
 *                           for the defineXML macro
 * SAS Version      : HP-UX 9.2
 *******************************************************************************
 * Preconditions    :
 *     Macrovar. needed:
 *     Datasets  needed:
 *     Ext.Prg/Mac used:
 * Postconditions   :
 *     Macrovar created:
 *     Output   created:
 *     Datasets created:
 * Comments         :
 *******************************************************************************
 * Author(s)        : sgqyq (Katja Glass) / date: 28SEP2016 / V1.0
 *******************************************************************************
 * Change History   :
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
    DATA header;
        %definexml_v1_attributes_for(header);
        studyname = "12345";
    RUN;
 ******************************************************************************/




    %IF %UPCASE(&data) NE HEADER AND
        %UPCASE(&data) NE DATASETS AND
        %UPCASE(&data) NE VARIABLES AND
        %UPCASE(&data) NE VALUELEVEL AND
        %UPCASE(&data) NE CODES AND
        %UPCASE(&data) NE METHODS AND
        %UPCASE(&data) NE COMMENTS AND
        %UPCASE(&data) NE DOCUMENTS
    %THEN %DO;
        %PUT %STR(ERR)OR: DEFINEXML_V1_ATTRIBUTES_FOR - DATA must be one of HEADER DATASETS VARIABLES VALUELEVEL CODES METHODS COMMENTS DOCUMENTS;
    %END;

    %IF %UPCASE(&data.) = HEADER
    %THEN %DO;
        ATTRIB FILEOID          LENGTH = $200  FORMAT = $200.  LABEL = 'File Object ID' ;
        ATTRIB STUDYOID         LENGTH = $200  FORMAT = $200.  LABEL = 'Study Object ID' ;
        ATTRIB STUDYNAME        LENGTH = $200  FORMAT = $200.  LABEL = 'Study Name' ;
        ATTRIB STUDYDESCRIPTION LENGTH = $2000 FORMAT = $2000. LABEL = 'Study Description' ;
        ATTRIB PROTOCOLNAME     LENGTH = $200  FORMAT = $200.  LABEL = 'Protocol Name' ;
        ATTRIB STANDARD         LENGTH = $200  FORMAT = $200.  LABEL = 'Standard' ;
        ATTRIB VERSION          LENGTH = $200  FORMAT = $200.  LABEL = 'Standard Version' ;
        ATTRIB SCHEMALOCATION   LENGTH = $200  FORMAT = $200.  LABEL = 'Schema Location' ;
        ATTRIB STYLESHEET       LENGTH = $200  FORMAT = $200.  LABEL = 'Stylesheet' ;
        ATTRIB ORIGINATOR       LENGTH = $200  FORMAT = $200.  LABEL = 'Originator' ;
    %END;

    %ELSE %IF %UPCASE(&data.) = DATASETS
    %THEN %DO;
        ATTRIB DOMAIN               LENGTH = $200 FORMAT = $200. LABEL = 'Domain' ;
        ATTRIB DESCRIPTION          LENGTH = $200 FORMAT = $200. LABEL = 'Description' ;
        ATTRIB CLASS                LENGTH = $200 FORMAT = $200. LABEL = 'Class' ;
        ATTRIB STRUCTURE            LENGTH = $200 FORMAT = $200. LABEL = 'Structure' ;
        ATTRIB PURPOSE              LENGTH = $200 FORMAT = $200. LABEL = 'Purpose' ;
        ATTRIB ARCHIVELOCATION      LENGTH = $200 FORMAT = $200. LABEL = 'Archive Location' ;
        ATTRIB REPEATING            LENGTH = $200 FORMAT = $200. LABEL = 'Repeating' ;
        ATTRIB ISREFERENCEDATA      LENGTH = $200 FORMAT = $200. LABEL = 'Is Referenced Data' ;
        ATTRIB COMMENT              LENGTH = $200 FORMAT = $200. LABEL = 'Comment OID' ;
        ATTRIB ORDID                LENGTH = 8    FORMAT = BEST. LABEL = 'Order for Domain Display' ;
    %END;
    %ELSE %IF %UPCASE(&data.) = VARIABLES
    %THEN %DO;
        ATTRIB DOMAIN               LENGTH = $200 FORMAT = $200. LABEL = 'Domain' ;
        ATTRIB VARNUM               LENGTH = 8    FORMAT = BEST. LABEL = 'Variable Number' ;
        ATTRIB VARIABLE             LENGTH = $200 FORMAT = $200. LABEL = 'Variable Name' ;
        ATTRIB LABEL                LENGTH = $200 FORMAT = $200. LABEL = 'Label' ;
        ATTRIB KEYSEQUENCE          LENGTH = 8    FORMAT = BEST. LABEL = 'Key Sequence' ;
        ATTRIB TYPE                 LENGTH = $200 FORMAT = $200. LABEL = 'Type' ;
        ATTRIB LENGTH               LENGTH = 8    FORMAT = BEST. LABEL = 'Length' ;
        ATTRIB SIGNIFICANTDIGITS    LENGTH = 8    FORMAT = BEST. LABEL = 'Significant Digits' ;
        ATTRIB ORIGIN               LENGTH = $200 FORMAT = $200. LABEL = 'Origin' ;
        ATTRIB CRFPAGE              LENGTH = $200 FORMAT = $200. LABEL = 'CRF Page Number' ;
        ATTRIB PREDECESSOR          LENGTH = $200 FORMAT = $200. LABEL = 'Predecessor' ;
        ATTRIB DISPLAYFORMAT        LENGTH = $200 FORMAT = $200. LABEL = 'Display Format' ;
        ATTRIB COMPUTATIONMETHODOID LENGTH = $200 FORMAT = $200. LABEL = 'Computation Method Object ID' ;
        ATTRIB CODELISTNAME         LENGTH = $200 FORMAT = $200. LABEL = 'Codelist Name' ;
        ATTRIB MANDATORY            LENGTH = $200 FORMAT = $200. LABEL = 'Mandatory' ;
        ATTRIB VALUELISTOID         LENGTH = $200 FORMAT = $200. LABEL = 'Value List Object ID' ;
        ATTRIB COMMENT              LENGTH = $200 FORMAT = $200. LABEL = 'Comment OID' ;
    %END;
    %ELSE %IF %UPCASE(&data.) = VALUELEVEL
    %THEN %DO;
        ATTRIB VALUELISTOID         LENGTH = $200 FORMAT = $200. LABEL = 'Value List Object ID' ;
        ATTRIB VALUEORDER           LENGTH = 8    FORMAT = BEST. LABEL = 'Value Order' ;
        ATTRIB VALUENAME            LENGTH = $200 FORMAT = $200. LABEL = 'Value Name' ;
        ATTRIB ITEMOID              LENGTH = $200 FORMAT = $200. LABEL = 'Item Object ID' ;
        ATTRIB WHERECLAUSEOID       LENGTH = $200 FORMAT = $200. LABEL = 'Where Clause Object ID' ;
        ATTRIB TYPE                 LENGTH = $200 FORMAT = $200. LABEL = 'Type' ;
        ATTRIB LENGTH               LENGTH = 8    FORMAT = BEST. LABEL = 'Length' ;
        ATTRIB ORIGIN               LENGTH = $200 FORMAT = $200. LABEL = 'Origin' ;
        ATTRIB CRFPAGE              LENGTH = 8    FORMAT = BEST. LABEL = 'CRF Page Number' ;
        ATTRIB PREDECESSOR          LENGTH = $200 FORMAT = $200. LABEL = 'Predecessor' ;
        ATTRIB COMPUTATIONMETHODOID LENGTH = $200 FORMAT = $200. LABEL = 'Computational Method' ;
        ATTRIB CODELISTNAME         LENGTH = $200 FORMAT = $200. LABEL = 'Codelist Name' ;
        ATTRIB SIGNIFICANTDIGITS    LENGTH = 8    FORMAT = BEST. LABEL = 'Significant Digits' ;
        ATTRIB DISPLAYFORMAT        LENGTH = $200 FORMAT = $200. LABEL = 'Display Format' ;
        ATTRIB MANDATORY            LENGTH = $200 FORMAT = $200. LABEL = 'Mandatory' ;
        ATTRIB DESCRIPTION          LENGTH = $200 FORMAT = $200. LABEL = 'Description' ;
        ATTRIB COMMENT              LENGTH = $200 FORMAT = $200. LABEL = 'Comment OID' ;
    %END;
    %ELSE %IF %UPCASE(&data.) = CODES
    %THEN %DO;
        ATTRIB CODELISTNAME         LENGTH = $200 FORMAT = $200. LABEL = 'Codelist Name';
        ATTRIB CODELISTLABEL        LENGTH = $200 FORMAT = $200. LABEL = 'Codelist Label';
        ATTRIB RANK                 LENGTH = 8    FORMAT = BEST. LABEL = 'Rank';
        ATTRIB CODE                 LENGTH = $200 FORMAT = $200. LABEL = 'External Code ID';
        ATTRIB CODEDVALUE           LENGTH = $200 FORMAT = $200. LABEL = 'Coded Value';
        ATTRIB EXTENDEDVALUE_NY     LENGTH = $200 FORMAT = $200. LABEL = 'Extended Value of a CDISC Codelist? (N/Y)';
        ATTRIB TRANSLATED           LENGTH = $200 FORMAT = $200. LABEL = 'Translated Value';
        ATTRIB TYPE                 LENGTH = $200 FORMAT = $200. LABEL = 'Type (DataType)';
        ATTRIB CODELISTDICTIONARY   LENGTH = $200 FORMAT = $200. LABEL = 'Codelist Dictionary';
        ATTRIB CODELISTVERSION      LENGTH = $200 FORMAT = $200. LABEL = 'Codelist Version';
        ATTRIB DECODED              LENGTH = $200 FORMAT = $200. LABEL = 'Decoded NY';
        ATTRIB OID_POSTFIX          LENGTH = $200 FORMAT = $200. LABEL = 'OID Postfix';
    %END;
    %ELSE %IF %UPCASE(&data.) = METHODS
    %THEN %DO;
        ATTRIB COMPUTATIONMETHODOID  LENGTH = $200  FORMAT = $200.  LABEL = 'Computation Method Object ID' ;
        ATTRIB COMPUTATIONMETHODNAME LENGTH = $200  FORMAT = $200.  LABEL = 'Computation Method Name' ;
        ATTRIB COMPUTATIONMETHODTYPE LENGTH = $200  FORMAT = $200.  LABEL = 'Computation Method Type' ;
        ATTRIB DESCRIPTION           LENGTH = $2000 FORMAT = $2000. LABEL = 'Description' ;
        ATTRIB PDFLEAF               LENGTH = $200  FORMAT = $200.  LABEL = 'PDF Document Leaf ID' ;
        ATTRIB PDFPAGE               LENGTH = $200  FORMAT = $200.  LABEL = 'PDF Page' ;
        ATTRIB PDFDESTINATION        LENGTH = $200  FORMAT = $200.  LABEL = 'PDF Named Destination' ;
    %END;
    %ELSE %IF %UPCASE(&data.) = COMMENTS
    %THEN %DO;
        ATTRIB COMMENTOID     LENGTH = $200  FORMAT = $200.  LABEL = 'Comment Object ID' ;
        ATTRIB DESCRIPTION    LENGTH = $2000 FORMAT = $2000. LABEL = 'Description' ;
        ATTRIB PDFLEAF        LENGTH = $200  FORMAT = $200.  LABEL = 'PDF Document Leaf ID' ;
        ATTRIB PDFPAGE        LENGTH = $200  FORMAT = $200.  LABEL = 'PDF Page' ;
        ATTRIB PDFDESTINATION LENGTH = $200  FORMAT = $200.  LABEL = 'PDF Named Destination' ;
    %END;
    %ELSE %IF %UPCASE(&data.) = DOCUMENTS
    %THEN %DO;
        ATTRIB PDFLEAF       LENGTH = $200 FORMAT = $200. LABEL = 'PDF Leaf ID' ;
        ATTRIB PDFLINK       LENGTH = $200 FORMAT = $200. LABEL = 'PDF Link' ;
        ATTRIB PDFTITLE      LENGTH = $200 FORMAT = $200. LABEL = 'PDF Title' ;
        ATTRIB ANNOTATEDCRF  LENGTH = 8    FORMAT = 8.    LABEL = 'Annotated CRF';
    %END;
%MEND definexml_v1_attributes_for;