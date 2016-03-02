/***
  Inline Assertion that data set DS exists.
  Returns a 0 (fail) or 1 (pass) result in-line.

  DS
    REQUIRED
    Syntax:  One or more WORK or permanent data sets, space-delimited
    Example: WORK.TEMP_DS
    Example: SASHELP.CLASS WORK.TEMP_DS

  Notes:
    If calling macro provides multiple data set names, ALL must exist to pass the assertion.
                                                                                    
  Author:          Dante Di Tommaso                                                  
  Acknowledgement: Inspired by FUTS system from Thotwave                                
                   http://thotwave.com/resources/futs-framework-unit-testing-sas/    
***/

  %macro assert_dset_exist(ds);
    %local OK idx nxt;

    %*--- Initialize result for null DS ---*;
    %let OK = 0;

    %if %length(&ds) = 0 %then %put ERROR: (ASSERT_DSET_EXIST) Result is FAIL. Please specify a data set name.;

    %let idx=1;
    %do %while (%qscan(&ds, &idx, %str( )) ne );
      %let nxt = %qscan(&ds, &idx, %str( ));

      %if %sysfunc(exist(&nxt)) %then %do;
        %*--- The 1st and every other DS must exist to pass the assertion ---*;
        %if 1 = &idx %then %let OK = 1;
        %put NOTE: (ASSERT_DSET_EXIST) Result is PASS. Data set %upcase(&nxt) is accessible.;
      %end;
      %else %do;
        %let OK = 0;
        %put ERROR: (ASSERT_DSET_EXIST) Result is FAIL. Data set %upcase(&nxt) is NOT accessible. Try another data set.;
      %end;

      %let idx = %eval(&idx+1);
    %end;

    &OK
  %mend assert_dset_exist;
