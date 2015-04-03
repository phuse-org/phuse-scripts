/***
  Inline Assertion that data set DS exists.
  Returns a 0 (fail) or 1 (pass) result in-line.
                                                                                    
  Author:          Dante Di Tommaso                                                  
  Acknowledgement: Based on FUTS system from Thotwave                                
                   http://thotwave.com/resources/futs-framework-unit-testing-sas/    
***/

  %macro assert_dset_exist(ds);
    %local OK;

    %if %sysfunc(exist(&ds)) %then %do;
      %let OK = 1;
      %put NOTE: (ASSERT_DSET_EXIST) Result is PASS. Data set %upcase(&ds) is accessible.;
    %end;
    %else %do;
      %let OK = 0;
      %put ERROR: (ASSERT_DSET_EXIST) Result is FAIL. Data set %upcase(&ds) is NOT accessible. Try another data set.;
    %end;

    &OK
  %mend assert_dset_exist;
