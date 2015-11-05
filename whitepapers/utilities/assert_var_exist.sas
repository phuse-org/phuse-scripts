/***

  Assertion that data set DS contains variable VAR                                   
  Returns a 0 (fail) or 1 (pass) result in-line.                                     
                                                                                    
  Author:          Dante Di Tommaso                                                  
  Acknowledgement: Based on FUTS system from Thotwave                                
                   http://thotwave.com/resources/futs-framework-unit-testing-sas/    
***/

  %macro assert_var_exist(ds, var);
    %local OK dsid rc;

    %let OK = %assert_dset_exist(&ds);

    %if %length(&var) = 0 %then %let OK = 0;

    %if &OK %then %do;
      %let dsid = %sysfunc(open(&ds));
      %put NOTE: (ASSERT_VAR_EXIST) If DMS process locks data set %upcase(&ds), try closing data set ID &DSID;

      %if &dsid NE 0 %then %do;
        %if %sysfunc(varnum(&dsid, %upcase(&var))) LT 1 %then %let OK = 0;

        %let rc = %sysfunc(close(&dsid));
        %if &rc NE 0 %then %put ERROR: (ASSERT_VAR_EXIST) unable to close data set %upcase(&ds).;
      %end;
      %else %do;
        %let OK = 0;
        %put ERROR: (ASSERT_VAR_EXIST) data set %upcase(&ds) is not accessible. Abort check for variable %upcase(&var).;
        %put ERROR: (ASSERT_VAR_EXIST) SYSMSG is: %sysfunc(sysmsg());
      %end;
    %end;

    %if &OK %then %put NOTE: (ASSERT_VAR_EXIST) Result is PASS. %upcase(&var) is a variable on data set %upcase(&ds).;
    %else %put ERROR: (ASSERT_VAR_EXIST) Result is FAIL. "%upcase(&var)" is NOT a variable on data set %upcase(&ds).;

    &OK
  %mend assert_var_exist;
