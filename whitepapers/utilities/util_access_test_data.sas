/*** Access PhUSE CS test data, XPT containers

  See explaination in the PhUSE Wiki of this FILENAME/LIBNAME access to XPORT files
    http://www.phusewiki.org/wiki/index.php?title=WG5_Code_to_Retrieve_CSS/PhUSE_Test_Data

  Some users are not able to access these xport archives directly, but are still able to
  download data sets to a local folder. These users can specify a local folder, to override
  the default, remote access method. See LOCAL parameter, below.

  This utility macro isolates access to PhUSE CS test data xport archives. Any future change
  to this interface can be implemented in one place, here, without requiring changes to
  remaining PhUSE CS template programs.

  See the PhUSE Repository in Github for available PhUSE CS test data sets
    https://github.com/phuse-org/phuse-scripts/tree/master/data/adam/cdisc

  INPUT
    DS    name of PhUSE CS test data set
      REQUIRED positional
      Syntax:  One-level name
      Example: ADVS
    XPORT name of XPORT archive, if different from DS
      optional keyword
      Syntax:  Filename of XPORT archive that includes DS. If missing, set to DS
      Example: ADVS_CONTAINER
    LOCAL path to a local folder that contains the PhUSE CS test data sets, to override remote access
      optional keyword
      Syntax:  Local path to folder with test data, quoted as needed
      Example: C:\CSS\phuse-scripts\data\adam\cdisc

  OUTPUT
    WORK data set with name &DS

  TO DO
    * Implement some way of warning the user that a specified PhUSE CS data set does not exist.
***/

%macro util_access_test_data(ds, xport=, local=);

  %if %length(&xport) = 0 %then %let xport = &ds;

  %if %length(&local) > 0 %then %do;
    %* WARN user in case the path does NOT end with a separator, \ or / *;
    %local lastchar;

    %let lastchar = %qsubstr(%sysfunc(reverse(&local)),1,1);
    %if &lastchar NE %quote(\) and
        &lastchar NE %quote(/) %then
        %put ERROR: (UTIL_ACCESS_TEST_DATA) Local test data override path must end in a separator (/ or \).;

    filename source "&local.&xport..xpt";
  %end;
  %else %do;
    filename source url "https://github.com/phuse-org/phuse-scripts/raw/master/data/adam/cdisc/&xport..xpt";
  %end;

  libname source xport access=READONLY;

  data work.&ds;
    set source.&ds;
  run;

  %if &SYSERR ne 0 %then %do;
    %put ERROR: (UTIL_ACCESS_TEST_DATA) Please confirm that data set %upcase(&DS) exists in transport file %upcase(&XPORT).;
    %util_delete_dsets(&ds)
  %end;

  filename source clear;
  libname source clear;

%mend util_access_test_data;
