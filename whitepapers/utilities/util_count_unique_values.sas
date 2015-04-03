/***
  Count the number of unique values in a variable, and assign the result to a global symbol
                                                                                           
  DSET    data set containing the variable with discrete values to count
            REQUIRED                                                                         
            Syntax:  (libname.)memname                                                       
            Example: ANA.ADVS                                                                
  VAR     variable on DSET containing discrete values to count
            REQUIRED                                                                         
            Syntax:  variable-name                                                           
            Example: TRTP
  SYM     name of symbol (macro variable) to declare globally and assign the result
            REQUIRED
            Syntax:  symbol-name
            Example: trtpn
  SQLWHR  complete SQL where expression, to limit check to subset of DS data
            optional                                                                         
            Syntax:  where sql-where-expression
            Example: where studyid = 'STUDY01'

  -OUTPUT                                                                                  
  &SYM, a global symbol containing the count of unique values in the user-specified variable
                                                                                           
  Author:          Dante Di Tommaso                                                        
***/

%macro util_count_unique_values(ds, var, sym, sqlwhr=);
  %global &sym;
  %local OK;

  %let OK = %assert_dset_exist(&ds);
  %if &OK %then %let OK = %assert_var_exist(&ds, &var);

  %if &OK %then %do;

    proc sql noprint;
      select count(unique(&var)) into: &sym
      from &ds
      &sqlwhr;
    quit;
    %let &sym = &&&sym;

    %put NOTE: (UTIL_COUNT_UNIQUE_VALUES) Successfully created symbol %upcase(&sym) = &&&sym;
  %end;
  %else %do;
    %put ERROR: (UTIL_COUNT_UNIQUE_VALUES) Unable to read values from variable %upcase(&var) on data set %upcase(&ds).;
  %end;

%mend util_count_unique_values;

