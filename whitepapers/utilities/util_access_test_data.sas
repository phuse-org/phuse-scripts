/*** Access PhUSE/CSS test data

  See explaination in the PhUSE Wiki of this FILENAME/LIBNAME access to XPORT files
    http://www.phusewiki.org/wiki/index.php?title=Scriptathon_2014_Code_for_Retreiving_Inputs

  This utility macro isolates access to PhUSE/CSS test data so that any future change
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

  OUTPUT
    WORK data set with name CSS_&DS

  TO DO
    * Implement some way of warning the user that a specified PhUSE/CSS data set does not exist.
***/

%macro util_access_test_data(ds, xport=);

  %if %length(&xport) = 0 %then %let xport = &ds;

  filename source url "https://raw.github.com/phuse-org/phuse-scripts/master/scriptathon2014/data/&xport..xpt";
  libname source xport access=READONLY;

  data css_&ds;
    set source.&ds;
  run;

  filename source clear;
  libname source clear;

%mend util_access_test_data;
