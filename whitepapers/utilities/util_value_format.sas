/***
  Determine format for MEAN and STDDEV based on sig-digs of measured values

  DSET  data set containing the measurement values to summarize as MEAN and STDDEV
          REQUIRED
          Syntax:  (libname.)memname
          Example: ANA.ADVS
  VAR   variable on DSET containing numeric result values
          REQUIRED
          Syntax:  variable-name
          Example: AVALN
  WHR   valid WHERE clause to subset DS data
          optional                                                                         
          Syntax:   where-expression
          Examples: studyid = 'STUDY01'
                    avisitn eq 99

  -OUTPUT
  UTIL_VALUE_FORMAT, a global symbol containing a space-delim string of exactly 2 parts:
                     1. format for MEAN values (one decimal more than most precise value)
                     2. format for STDDEV vals (two decimals more than most precise value)
          Example: 5.1 6.2

  Author:          Dante Di Tommaso
***/

%macro util_value_format(ds, var, whr=);
  %global util_value_format;
  %local OK;

  %let OK = %assert_dset_exist(&ds);
  %if &OK %then %let OK = %assert_var_exist(&ds, &var);

  %if &OK %then %do;
    data css_fmt;
      set &DS end=NoMore;

      %if %length(&whr) > 0 %then where &whr;
      ;

      retain max_int 0 max_dec 0;

      length int dec $8;
      valtxt = put(&var, best8.-L);
      int = scan(valtxt, 1, '.');
      dec = scan(valtxt, 2, '.');

      max_int = ifn(not missing(int) and length(int) > max_int,
                     length(int),
                     max_int);

      max_dec = ifn(not missing(dec) and length(dec) > max_dec,
                    length(dec),
                    max_dec);

      if NoMore then do;
        meanfmt = strip(put(max_int+max_dec+2,8.-L))!!'.'!!strip(put(max_dec+1,8.-L));
        stdvfmt = strip(put(max_int+max_dec+3,8.-L))!!'.'!!strip(put(max_dec+2,8.-L));
        call symput('util_value_format', strip(meanfmt)!!' '!!strip(stdvfmt));
      end;
    run;

    proc datasets library=WORK memtype=DATA nolist nodetails;
      delete css_fmt;
    quit;


    %put NOTE: (UTIL_VALUE_FORMAT) Successfully created symbol UTIL_VALUE_FORMAT = &util_value_format;
  %end;
  %else %do;
    %let util_value_format=;
    %put ERROR: (UTIL_VALUE_FORMAT) Result is FAIL. Unable to read values from variable %upcase(&var) on data set %upcase(&ds).;
  %end;

%mend util_value_format;

