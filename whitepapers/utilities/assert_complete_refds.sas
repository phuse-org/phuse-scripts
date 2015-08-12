/***
  Assertion that according to listed unique KEYS, a reference dset (e.g., ADSL) contains info
  for all observations that appear in remaining dsets (e.g., ADAE, ADVS, ADLBC, ...)

  Usage:
    * DSETS  list of reference and related data sets, minimum of 2 data sets
        REQUIRED
        SYNTAX:  reference-dset measurement-dset-1 measurement-dset-2
        EXAMPLE: ADSL ADAE ADVS ADLBC

    * KEYS   list of unique keys to link obs in reference and measurements data sets, space-delimited
        REQUIRED
        SYNTAX:  key_1 key_2
        EXAMPLE: STUDYID USUBJID
             NB: NO SUPPORT for data sets lists, see references

  Outputs:
    FAIL_CRDS Data set that macro creates only in case on invalid keys.
              It contains a list of keys only in the related, measurement data sets.
              It does not include all unique keys in the reference data set.
  Notes:
    * 1st dset is REFERENCE DATA SET, such as ADSL. 
    * Remaining related data sets should contain only obs, according to KEYS, that are in 1st dset.
    * IF UNEXPECTED OBS appear in any measurements data set, the macro creates WORK.FAIL_CRDS and puts log ERRORs
    * Macro checks that data sets exist, but does not check that keys exist on each dset

  References:
    Data Set Lists: http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#a003040446.htm

  Author: Dante Di Tommaso
  Acknowledgement: Based on FUTS system from Thotwave
                   http://thotwave.com/resources/futs-framework-unit-testing-sas/
***/

  %macro assert_complete_refds(dsets, keys);
    %local ndsets nkeys OK idx nxt;

    %let ndsets = %sysfunc(countw(&dsets, %str( )));
    %let nkeys  = %sysfunc(countw(&keys, %str( )));
    %let OK = 1;

    %do idx = 1 %to &ndsets;
      %let nxt = %scan(&dsets, &idx, %str( ));

      %if %assert_dset_exist(&nxt) %then %do;
        proc sort data = &nxt (keep=&keys) out=crds_dset&idx nodupkey;
          by &keys;
        run;
      %end;
      %else %do;
        %let OK = 0;
      %end;
    %end;

    %if &OK %then %do;
      data fail_crds;
        merge %do idx = 1 %to &ndsets; crds_dset&idx (in=in_ds&idx) %end; ;
        by &keys;

        if not in_ds1 %do idx = 2 %to &ndsets; or not in_ds&idx %end; ;

        %do idx = 1 %to &ndsets;
          found_ds&idx = in_ds&idx;
        %end;

        if not in_ds1 then do;
          put "ERROR: (ASSERT_COMPLETE_REFDS) Result is FAIL. Obs missing from reference dset %upcase(%scan(&dsets,1,%str( ))): "
              &keys %do idx = 1 %to &ndsets; in_ds&idx= %end;;
          call symput('OK', '0');
        end;
        else delete;
      run;

      %if &OK %then %put NOTE: (ASSERT_COMPLETE_REFDS) Result is PASS. %upcase(%scan(&dsets,1,%str( ))) includes all subjects.;
    %end;

    proc datasets nolist library=work;
      delete %do idx = 1 %to &ndsets; crds_dset&idx %end;
             %if &OK %then fail_crds;
      ;
    quit;

  %mend assert_complete_refds;
