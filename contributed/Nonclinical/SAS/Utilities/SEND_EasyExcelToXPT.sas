/******************************************************************************
*                                MPI Research                                 *
*******************************************************************************
* Macro         : EasyExcelToXPT                                              *
* Company       : MPI Research, A Charles River Company                       *
* Parameters    : InputExcelFile, SheetName, OutputDirectory, XPTFileName     *
* Input(s)      : .xlsm, .xls                                                 *
* Output(s)     : .xpt                                                        *
* Description   : This macro is called by the                                 *
*                 SEND_EasyExcelToXPT_xxxxx.xlsm master                       *
*                 file and processes the designated XLS file to .XPT.         *
*******************************************************************************
* History:                                                                    *
*   Author          Date        Description                                   *
*   --------------- ----------- --------------------------------------------- *
*   Jacob Boehmer   2013-10-21  Created program.                              *
*   Jared Slain     2014-08-14  Re-created program based on prior run logs    *
*                               and general requirements                      * 
******************************************************************************/

/******************************************************************************
* User information                                                            *
******************************************************************************/
data _null_;
    put "*******************************************************************************";
    put "* USER     : &sysuserid.";
    put "* DATE     : &sysday. &sysdate.";
    put "* MACHINE  : &syshostname.";
    put "* OS       : &sysscp. &sysscpl.";
    put "* VERSION  : SAS v&sysver.";
    put "*******************************************************************************";
run;

/******************************************************************************
* System options                                                              *
******************************************************************************/
options nosource;

/******************************************************************************
* Reading in the user input parameters from the Excel masterfile              *
******************************************************************************/
libname input "&sysparm." getnames=no mixed=yes access=readonly;

data test;
    set input."User Inputs$"n;
    if _n_ > 1;

    name = strip(f1);
    if name = "XPTFileName" then call symput(strip(lowcase(f1)), strip(upcase(f3)));
    else call symput(strip(lowcase(f1)), strip(lowcase(f3)));

    if f1 = "SUBMIT" then stop;
run;

libname input clear;

/******************************************************************************
* Checking if user inputs exist                                               *
******************************************************************************/
%macro check_if_inputs_exist;
    data _null_;
        retain abend;

        %let userinputs = InputExcelFile, SheetName, OutputDirectory, XPTFileName;

        %let k = 1;
        %do %while(%scan("&userinputs.", &k., ",") ne %str());
            %let userinput = %scan("&userinputs.", &k., ",");

            if length(strip("&&&userinput..")) <= 1 then do;
                put "ERR" "OR: Missing input value for &userinput.! The system will now terminate";
                abend = 1;
            end;

            %let k = %eval(&k.+1);
        %end;

        if abend then abort abend;
    run;
%mend check_if_inputs_exist;

%check_if_inputs_exist;

/******************************************************************************
* Checking if user specified directories exist                                *
******************************************************************************/
%macro check_if_directories_exist;
    /*Check to see if Excel File Exists*/
    %if %sysfunc(fileexist("&InputExcelFile.")) %then %do; 
        /*do nothing*/
    %end;
    %else %do;
        data _null_;
            put "ERR" "OR: &InputExcelFile. does not exist! The system will now terminate";
            abort abend;
        run;
    %end;

    /*Assign libname to file to be converted*/
    libname EXCEL "&InputExcelFile." mixed=yes access=readonly;

    /*read Excel wksht into dataset*/
    data INPUTEXCELFILE;
        set EXCEL."&SheetName.$"n;
    run;

    libname EXCEL clear;

    /*Perform basic data integrity checks*/
    %if &syserr. %then %do;
        data _null_;
            put "ERR" "OR: Problem reading Excel file to be converted. Check that the worksheet, &SheetName., exists. The system will now terminate";
            abort abend;
        run;
    %end;

    libname temp "&OutputDirectory.";

    data temp.temp;
        set _null_;
    run;

    %if &syserr. %then %do;
        data _null_;
            put "ERR" "OR: &OutputDirectory. does not exist! The system will now terminate";
            abort abend;
        run;
    %end;

    proc datasets library=temp nolist;
        delete temp;
    quit;

    libname temp clear;

%mend check_if_directories_exist;

%check_if_directories_exist;

/******************************************************************************
* Reading in the variable list from the Excel masterfile                      *
******************************************************************************/
%macro get_var_list;
    /* Assign libname to masterfile */
    libname varlist "&sysparm." mixed=yes access=readonly;

    /* read Excel wksht into dataset */
    data VARIABLELIST;
        set varlist."Variable List$"n;
    run;

    libname varlist clear;

    %if &syserr. %then %do;
        data _null_;
            put "ERR" "OR: Problem reading variables from Master File. Check that the worksheet, Variable List, exists. The system will now terminate";
            abort abend;
        run;
    %end;
    
    /* Make sure there is at least one, partially complete row. Put Number of Variables into Macro Var */
    data LISTVARIABLES;
        set VARIABLELIST;
        WHERE CMISS(variablename, variabletype, variablelabel) < 3;
    run;

    data _null_;
        dsid=open("LISTVARIABLES");
        nobs=ATTRN(dsid, "nobs");

        if nobs < 1 then do; 
            put "ERR" "OR: No variables read from the Variable List workseet in the Master File. The system will now terminate";
            abort abend;
        end;
        call symputx("NoVars", nobs);
    run;

%mend get_var_list;

%get_var_list;

/******************************************************************************
* Comparing and merging data columns with variable list                       *
******************************************************************************/
PROC CONTENTS DATA=INPUTEXCELFILE MEMTYPE=data OUT=EXCELVARIABLES(rename=(name=VariableName)) NOPRINT;
RUN;

proc sort data=LISTVARIABLES;
    by VariableName;
run;

proc sort data=EXCELVARIABLES;
    by VariableName; 
run;

data MergedVariables;
    merge EXCELVARIABLES (keep=VariableName type formatl formatd varnum length) LISTVARIABLES;
    by VariableName;
run;

/******************************************************************************
* Create the final dataset to be converted to xpt                             *
******************************************************************************/
%macro create_ds_for_conv;
    proc sort data=MergedVariables;
        by varnum; 
    run;

    /*Put Column Attributes into Array of Macro Vars*/
    data _null_;
        set MergedVariables end=eof;
        by varnum; 

        call symputx("Name" || strip(put(_N_, best.)), VariableName);
        call symputx("NewType" || strip(put(_N_, best.)), variabletype);
        call symputx("OldType" || strip(put(_N_, best.)), type);
        call symputx("Label" || strip(put(_N_, best.)), variablelabel);
        call symputx("Formatl" || strip(put(_N_, best.)), length);
        call symputx("Formatd" || strip(put(_N_, best.)), formatd);

        if eof and (_N_ < &NoVars.) then do; /*Ensure that we didn't lose any columns when merging on name*/
            put "ERR" "OR: At least one variable name from the Variable List workseet in the Master File does not match the column headings in the input file. The system will now terminate";
            abort abend;
        end;
    run;

    data NewDs (keep=
                    %do i = 1 %to &NoVars.;
                        &&Name&i..
                    %end;
                );
        LENGTH 
        %do i = 1 %to &NoVars.;
            %if %upcase("&&NewType&i.") = "CHAR" %then %do;
                &&Name&i.. $ 200
            %end; 
            %else %if %upcase("&&NewType&i.") = "NUM" %then %do;
                &&Name&i.. &&Formatl&i..
            %end; 
            %else %do;
                put "ERR" "OR: An improper variable type designation was found in the Master File: &&Name&i.. &&Formatl&i... The system will now terminate";
                abort abend;
            %end;
        %end;
        ;
        set INPUTEXCELFILE (rename=(
                                %do i = 1 %to &NoVars.;
                                    &&Name&i.. = var&i.
                                %end;
                            ));

        %do i = 1 %to &NoVars.;
            %if %upcase("&&NewType&i.") = "CHAR" %then %do;
                %if &&OldType&i.. = 1 %then %do;  /*Num to Char conversion*/
                    if missing(var&i.) then do;
                        &&Name&i.. = ' ';
                    end;
                    else do;
                       &&Name&i.. = put(var&i., &&Formatl&i...&&Formatd&i..);
                    end;
                    label &&Name&i.. = &&Label&i..;
                %end;
                %else %do;  /*Char to Char*/
                    &&Name&i.. = var&i.;
                    label &&Name&i.. = &&Label&i..;
                %end;
            %end;
            %else %if %upcase("&&NewType&i.") = "NUM" %then %do;
                %if &&OldType&i.. = 1 %then %do;  /*Num to Num*/
                    &&Name&i.. = var&i.;
                    label &&Name&i.. = &&Label&i..;
                %end;
                %else %do;  /*Char to Num conversion*/
                    &&Name&i.. = input(var&i., &&Formatl&i...&&Formatd&i..);
                    if missing(&&Name&i..) and missing(var&i.) ^= 1 then do;
                        put "ERR" "OR: The " &&Name&i.. " column was read in as character but converted to numeric. At least one non-missing value was converted to missing during the process. Please check your data and settings. The system will now terminate";
                        abort abend;
                    end;
                    label &&Name&i.. = &&Label&i..;
                %end;
            %end;
        %end;
    run;

%mend create_ds_for_conv;

%create_ds_for_conv;

/******************************************************************************
* Write the xpt file                                                          *
******************************************************************************/
LIBNAME xpt XPORT "&OutputDirectory./&XPTFileName..xpt";

/*proc copy in = work out = xpt;
    select NewDs;
run;*/

data xpt.&XPTFileName.;
    set NewDs;
run;

libname xpt clear;
