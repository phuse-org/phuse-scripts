/***
  Assertion that records in DS are unique according to KEYS

  INPUTS
    CONTINUE  Global symbol created prior to macro invocation in PhUSE CStemplate program.
              NB: The calling program ensures that this global macro var exists.

  Usage:
    DS     Data set containing the unique id variables, KEYS
             REQUIRED
             Syntax:  (libname.)memname
             Example: ANA.ADVS

    KEYS   Valid variables in DS that compose unique ids, space-delimited
             REQUIRED                 
             Syntax:  list of valid DS variables
             Example: USUBJID PARAMCD ATPTN AVISITN
                  NB: NO SUPPORT for data set lists, see references

    INCL   Valid variables from DS to include in FAIL_AUK, to troubleshoot invalid unique keys, space-delimited
             optional
             Syntax: list of valid DS variables, in addition to KEYS
             Example: PARAM ATPT AVISIT 
                  NB: NO SUPPORT for data set lists, see references

    SQLWHR Complete SQL where expression, to limit check to subset of DS data
             optional
             Syntax:  where sql-where-expression, without a terminal semi-colon
             Example: where studyid = 'STUDY01'

  OUTPUTS:
    CONTINUE global symbol set to 1 (OK to continue) or 0 (STOP PROCESSING if invalid unique keys are unacceptable)
    FAIL_AUK work data set with 1 or more records that violate unique keys.
             NB: data set will NOT exist if the unique keys are valid.
             NB: this macro does not enforce stopping of processing. the calling macro can choose to do so.

  References:
    Data Set Lists: http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#a003040446.htm

  Author: Dante Di Tommaso
  Acknowledgement: Based on FUTS system from Thotwave
                   http://thotwave.com/resources/futs-framework-unit-testing-sas/
***/

  %macro assert_unique_keys (ds, keys, incl=, sqlwhr=);
    %*--- If CONTINUE already exists, no hard done. But it must exist to receive return code. ---*;
    %global continue;

    %local idx nxt sqlkeys sqlvars;

    %let continue = %assert_dset_exist(&ds);

    %if %length(&keys) < 1 %then %do;
      %let continue = 0;
      %put ERROR: (ASSERT_UNIQUE_KEYS) Result is FAIL. Please specify a variable name.;
    %end;

    %if &continue %then %do;
      %let sqlkeys = %scan(&keys, 1, %str( ));
      %let continue = %assert_var_exist(&ds, &sqlkeys);

      %if %sysfunc(countw(&keys)) > 1 %then %do idx = 2 %to %sysfunc(countw(&keys));
        %let nxt = %scan(&keys, &idx, %str( ));
        %if &continue %then %let continue = %assert_var_exist(&ds, &nxt);

        %let sqlkeys = &sqlkeys., &nxt;
      %end;

      %if &continue %then %do;
        %if %length(&incl) > 0 %then %do;
          %let sqlvars = %scan(&incl, 1, %str( ));
          %let continue = %assert_var_exist(&ds, &sqlvars);

          %if %sysfunc(countw(&incl)) > 1 %then %do idx = 2 %to %sysfunc(countw(&incl));
            %let nxt = %scan(&incl, &idx, %str( ));
            %if &continue %then %let continue = %assert_var_exist(&ds, &nxt);

            %let sqlvars = &sqlvars., &nxt;
          %end;
        %end;

        %if &continue %then %do;

          proc sql noprint;
            create table fail_auk as
            select &sqlkeys %if %length(&sqlvars) > 0 %then , &sqlvars ;
            from &ds

            %if %length(&sqlwhr) > 0 %then %do;
              &sqlwhr
            %end;

            group by &sqlkeys
            having count(%scan(&keys, -1, %str( ))) > 1
            order by &sqlkeys %if %length(&sqlvars) > 0 %then , &sqlvars ;
            ;
          quit;

          %if &sqlobs NE 0 %then %do;
            %put ERROR: (ASSERT_UNIQUE_KEYS) Unexpected duplicates in %upcase(&DS) with unique keys %upcase(&keys) &sqlwhr (SQLOBS = &sqlobs). See WORK.FAIL_AUK.;
            %let continue = 0;
          %end;
          %else %do;
            %put NOTE: (ASSERT_UNIQUE_KEYS) %upcase(&DS) has unique records for keys %upcase(&keys) &sqlwhr (SQLOBS = &sqlobs).;
            %util_delete_dsets(fail_auk);
          %end;

        %end; %*--- Valid (or null) INCL vars ---*;
      %end; %*--- Valid KEYS vars ---*;
    %end; %*--- Valid DS ---*;

  %mend assert_unique_keys;
