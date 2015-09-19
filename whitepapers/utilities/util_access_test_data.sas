/*** Access PhUSE/CSS test data

  See explaination in the PhUSE Wiki of this FILENAME/LIBNAME access to XPORT files
    http://www.phusewiki.org/wiki/index.php?title=WG5_Code_to_Retrieve_CSS/PhUSE_Test_Data

  Some users are not able to access these xport archives directly, but are still able to
  download data sets to a local folder. These users can specify a local folder, to override
  the default, remote access method. See LOCAL parameter, below.

  This utility macro isolates access to PhUSE/CSS test data xport archives. Any future change
  to this interface can be implemented in one place, here, without requiring changes to
  remaining PhUSE/CSS template programs.

  See the PhUSE Repository in Github for available PhUSE/CSS test data sets
    https://github.com/phuse-org/phuse-scripts/tree/master/scriptathon2014/data

  INPUT
    DS    name of PhUSE/CSS test data set
      REQUIRED positional
      Syntax:  One-level name
      Example: ADVS
    XPORT name of XPORT archive, if different from DS
      optional keyword
      Syntax:  Filename of XPORT archive that includes DS. If missing, set to DS
      Example: CSS_TEST_DATA
    LOCAL path to a local folder that contains the CSS test data sets, to override remote access
      optional keyword
      Syntax:  Local path to folder with test data, quoted as needed
      Example: C:\CSS\phuse-scripts\scriptathon2014\data

  OUTPUT
    WORK data set with name CSS_&DS

  TO DO
    * Implement some way of warning the user that a specified PhUSE/CSS data set does not exist.
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
    filename source url "https://raw.github.com/phuse-org/phuse-scripts/master/scriptathon2014/data/&xport..xpt";
  %end;

  libname source xport access=READONLY;

  data css_&ds;
    set source.&ds;
  run;

  filename source clear;
  libname source clear;

%mend util_access_test_data;
