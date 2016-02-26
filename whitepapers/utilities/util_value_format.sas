/***
  Determine format for MEAN and STDDEV based on sig-digs of measured values

  DS    data set containing the measurement values to summarize as MEAN and STDDEV
          REQUIRED positional
          Syntax:  (libname.)memname
          Example: ANA.ADVS
  VAR   variable on DS containing numeric result values
          REQUIRED positional
          Syntax:  variable-name
          Example: AVALN
  SYM   name of global macro variable to create with resulting space-delimited formats
          optional keyword
          Syntax:   valid macro variable name. Default symbol is UTIL_VALUE_FORMAT
          Examples: util_value_format
  WHR   valid WHERE clause to subset DS data
          optional keyword
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

%macro util_value_format(ds, var, sym=util_value_format, whr=);
  %global &sym;
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
        call symput("&sym", strip(meanfmt)!!' '!!strip(stdvfmt));
      end;
    run;

    proc datasets library=WORK memtype=DATA nolist nodetails;
      delete css_fmt;
    quit;


    %put NOTE: (UTIL_VALUE_FORMAT) Successfully created symbol %upcase(&sym) = &&&sym;
  %end;
  %else %do;
    %let &sym=;
    %put ERROR: (UTIL_VALUE_FORMAT) Result is FAIL. Unable to read values from variable %upcase(&var) on data set %upcase(&ds).;
  %end;

%mend util_value_format;

