/***
  Assertion that according to listed unique KEYS, a reference dset (e.g., ADSL) contains info
  for all observations that appear in remaining dsets (e.g., ADAE, ADVS, ADLBC, ...)

  Usage:
    * DSETS  list of reference and related data sets, minimum of 2 data sets
        REQUIRED
        SYNTAX:  reference-dset measurement-dset-1 measurement-dset-2
        EXAMPLE: ADSL ADAE ADVS ADLBC

    * KEYS   list of unique keys to link obs in reference and measurements data sets
        REQUIRED
        SYNTAX:  key_1 key_2
        EXAMPLE: STUDYID USUBJID

  Notes:
    * 1st dset is REFERENCE DATA SET, such as ADSL. 
    * Remaining data set should contain only obs, according to KEYS, that are in 1st dset.
    * IF UNEXPECTED OBS appear in any measurements data set, the macro will put ERRORs to the log
    * NO DEBUGGING - User must ensure that listed DSETS contain KEYS, and both lists are non-missing

  Author: Dante Di Tommaso
***/

  %macro assert_complete_refds(dsets, keys);
    %local ndsets nkeys OK;

    %let ndsets = %sysfunc(countw(&dsets, %str( )));
    %let nkeys  = %sysfunc(countw(&keys, %str( )));
    %let OK = 1;

    %do idx = 1 %to &ndsets;
      proc sort data = %scan(&dsets, &idx, %str( )) (keep=&keys) out=crds_dset&idx nodupkey;
        by &keys;
      run;
    %end;

    data fail_crds;
      merge %do idx = 1 %to &ndsets; crds_dset&idx (in=in_ds&idx) %end; ;
      by &keys;

      if not in_ds1 %do idx = 2 %to &ndsets; or not in_ds&idx %end; ;

      %do idx = 1 %to &ndsets;
        found_ds&idx = in_ds&idx;
      %end;

      if not in_ds1 then do;
        put "ERROR: (ASSERT_COMPLETE_REFDS) Result if FAIL. Obs missing from reference dset %upcase(%scan(&dsets,1,%str( ))): "
            &keys %do idx = 1 %to &ndsets; in_ds&idx= %end;;
        call symput('OK', '0');
      end;
    run;

    %if &OK %then %put NOTE: (ASSERT_COMPLETE_REFDS) Result is PASS. %upcase(%scan(&dsets,1,%str( ))) includes all subjects.;

    proc datasets nolist library=work;
      delete %do idx = 1 %to &ndsets; crds_dset&idx %end; fail_crds;
    quit;
  %mend assert_complete_refds;
