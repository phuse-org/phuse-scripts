/*** In-line assertion (0/1 return value) that a variable only contains non-missing values.

  INPUTS
    DS          Data set including the specified variable
      REQUIRED
      Syntax:   One or two-level data set name
      ExampleS: ADAE, SASHELP.HEART
    VAR
      REQUIRED  Variable to test for missing values
      Syntax:   Num or Char variable name
      Example:  AVISITN, TRTP, AEDECOD
    WHR
      OPTIONAL  A valid where clause
      Syntax:   Any where clause that fits into "where=(missing(&var) and (&WHR))"
      Examples: siteid = '701'
                upcase(paramcd) in ('DIABP' 'SYSBP') and upcase(atpt) contains 'STANDING'

  OUTPUT
    0 or 1      0 = Assertion fails, variable contains missing values 
    response:   1 = Assertion passes, variable contains only non-missing values

  NOTES
    Missing values produce a WARNING (good to know), rather than an ERROR (fatal) to the log.
    Any problems accessing the data set or variable produce an ERROR in the log.

  Author:       Dante Di Tommaso                                                  
  Acknowledgement: Based on FUTS system from Thotwave                                
                   http://thotwave.com/resources/futs-framework-unit-testing-sas/    
***/

%macro assert_var_nonmissing(ds, var, whr=);
  %local OK dsid rc where_full;

  %let OK = %assert_dset_exist(&ds);

  %if 0 = %length(&var) %then %do;
    %put ERROR: (ASSERT_VAR_NONMISSING) Please specify a variable on data set %upcase(&ds).;
    %let OK = 0;
  %end;
  %else %if &OK %then %let OK = %assert_var_exist(&ds, &var);

  %if &OK %then %do;
    %if 0 = %length(&whr) %then %let where_full = where=(missing(&var));
    %else %let where_full = where=(missing(&var) and (&whr));

    %let dsid = %sysfunc(open( &ds (&where_full) ));

    %if &dsid NE 0 %then %do;
      %put NOTE: (ASSERT_VAR_NONMISSING) If DMS process locks the data set %upcase(&ds), try closing data set ID &DSID;
      %let rc = %sysfunc(attrn(&dsid, NLOBSF));

      %if &rc > 0 %then %do;
        %let OK = 0;
        %put WARNING: (ASSERT_VAR_NONMISSING) Result is FAIL. &rc Missing values for variable "%upcase(&var)" on data set "%upcase(&ds)" (where=&whr).;
      %end;
      %else %do;
        %let OK = 1;
        %put NOTE: (ASSERT_VAR_NONMISSING) Result is PASS. &rc Missing values for variable "%upcase(&var)" on data set "%upcase(&ds)" (where=&whr).;
      %end;
      
      %let rc = %sysfunc(close(&dsid));
      %if &rc NE 0 %then %put ERROR: (ASSERT_VAR_NONMISSING) Unable to close data set %upcase(&ds), opened with data set ID &DSID;
    %end;
    %else %do;
      %let OK = 0;
      %put ERROR: (ASSERT_VAR_NONMISSING) Data set %upcase(&ds) is not accessible. Abort check for variable %upcase(&var).;
      %if 0 < %length(&whr) %then %put ERROR: (ASSERT_VAR_NONMISSING) Review your where clause carefully. Test the compound clause: &where_full;
      %put ERROR: (ASSERT_VAR_NONMISSING) SYSMSG is: %sysfunc(sysmsg());
    %end;
  %end;

  &OK
%mend assert_var_nonmissing;
