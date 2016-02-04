/***
  Count the number of unique values in a variable,
  Create a sequence of symbols that contain the distinct values of the primary var
  Create a corresponding sequence of symbols that contain labels from a secondary var 
         for those primary values
                                                                                           
  DS      Data set containing the variable with discrete value-label pairs
            REQUIRED                                                                         
            Syntax:  (libname.)memname                                                       
            Example: ANA.ADVS                                                                
  VAR     Primary variable on DS containing discrete values to label with values from a secondary var
          By default, macro uses VAR name as the prefix to create macro variables
            REQUIRED                                                                         
            Syntax:  variable-name                                                           
            Example: AVISITN
  LAB     Secondary variable on DS containing discrete values used to label values in primary VAR
            REQUIRED                                                                         
            Syntax:  variable-name                                                           
            Example: AVISIT
  PREFIX  Prefix to use instead of VAR name, for sequences of macro variables for values and labels
            optional
            Syntax:  prefix text, LETTERS ONLY
            Example: PARAMUNIT
  WHR     Valid WHERE clause to subset DS data
            optional                                                                         
            Syntax:   where-expression
            Examples: studyid = 'STUDY01'
                      avisitn eq 99

  -OUTPUT                                                                                  
    &VAR._N    a global symbol containing the number of distinct values in VAR (and typically LAB)
      Example: AVISITN_N
    &VAR._VAL1 to &VAR._VAL&&&VAR.N 
               a sequence of global symbols with the distinct values of VAR, ordered by VAR
      Example: AVISITN_VAL1, AVISITN_VAL2, ... AVISITN_VAL8
    &VAR._LAB1 to &VAR._VAL&&&VAR.N
               a sequence of global symbols with the labels for VAR, taken from LAB
      Example: AVISITN_LAB1, AVISITN_LAB2, ... AVISITN_LAB8

    NB: If &PREFIX is non-missing, then replace &VAR, above, with &PREFIX
                                                                                           
  Author:          Dante Di Tommaso                                                        
***/

%macro util_labels_from_var(ds, var, lab, prefix=, whr=);
  %if %length(&prefix) = 0 %then %let prefix = &var;

  %global &prefix._n;
  %local OK idx;

  %let OK = %assert_dset_exist(&ds);
  %if &OK %then %let OK = %assert_var_exist(&ds, &var);
  %if &OK %then %let OK = %assert_var_exist(&ds, &lab);

  %if &OK %then %do;

    %if %length(&whr) > 0 %then %let whr = where &whr;

    %util_count_unique_values(&ds, &var, &prefix._n, sqlwhr=&whr)

    *--- Create paired sequences of symbols containing values and labels ---*;
      %do idx = 1 %to &&&prefix._n;
        %global &prefix._val&idx &prefix._lab&idx;
      %end;

      proc sort data=&ds
                out=css_lfv nodupkey;
        by &var &lab;
        &whr ;
      run;

      data _null_;
        set css_lfv;
        by &var;
        if not (first.&var and last.&var) then do;
          put "ERROR: (UTIL_LABELS_FROM_VAR) Each %upcase(&VAR) value should have exacly one %upcase(&LAB) value." &var= &lab=;
          put "ERROR: (UTIL_LABELS_FROM_VAR) Most likely you are missing some global symbols.";
        end;

        call symput(strip("&prefix._val"!!put(_n_, 8.-L)), strip(&var));
        call symput(strip("&prefix._lab"!!put(_n_, 8.-L)), strip(&lab));
      run;

      proc datasets library=WORK memtype=DATA nolist nodetails;
        delete css_lfv;
      quit;

    %put NOTE: (UTIL_LABELS_FROM_VAR) Successfully created symbols for Values and Labels from %upcase(&var) and %upcase(&lab);
  %end;
  %else %do;
    %put ERROR: (UTIL_LABELS_FROM_VAR) Unable to read variable %upcase(&var) or %upcase(&lab) on data set %upcase(&ds).;
  %end;

%mend util_labels_from_var;
