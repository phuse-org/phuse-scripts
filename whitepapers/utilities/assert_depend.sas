/***
  IN-LINE macro returns 1 or 0 whether or not env meets mandatory program dependencies.
  NB: This macro must remain IN-LINE whenever updated for new functionality

  TO DO
    SASPROD implementation, OPTIONAL, to check that a required SAS product is licensed
            use SASPROD() function, with pipe-delim (|-delim) string since prod names contain spaces
    SYM_NON_MISS implementation, OPTIONAL, to call %assert_sym_non_miss() to check
            that a symbol not only exists, but is also non-missing, %length() > 0

  CALLS utility macro   UTIL_AUTOCALLPATH.SAS, also an IN-LINE macro
   which in turn calls UTIL_RESOLVESASAUTOS.SAS, also an IN-LINE macro

  OS dependency is based on automatic symbol &SYSSCP (which may contain spaces)
    REQUIRED parameter
    IMPORTANCE: WARNING - Warning in log that OS unqualified, but otherwise give it a try
    SYNTAX:     comma-delimited list WITHOUT extra white space, quoted as necessary
    EXAMPLE:    %str(WIN,AIX,HP IPF)
  SASV version dependency is based on numeric auto symbol &SYSVER
    REQUIRED parameter
    IMPORTANCE: MANDATORY - Error in log that SAS version unqualified and stop processing
    SYNTAX:     "n.n"  is an explicit dependency - exactly version "n.n" mandatory
                "n.n+" is a baseline dependency - version "n.n" or greater is mandatory
    EXAMPLES:   9.2
                9.2+
  VARS dependency is based on valid VARNUM() for each required variable in each data set
    IMPORTANCE: MANDATORY - continue only if all required vars exist
    SYNTAX:     comma-delimited list of "data set : var1 var2" lists, quoted as necessary
                NO SUPPORT for variable lists. Explicitly name each required var
    EXAMPLES:   ADSL : USUBJID SAFFL
                %str(ADSL : USUBJID SAFFL, ADVS : USUBJID SAFFL PARAM AVAL)
  MACROS dependency is based on finding listed symbols in SASHELP.VMACRO
    IMPORTANCE: MANDATORY - Error in log that required macro is not available to SAS
    SYNTAX:     space-delimited list of macro names
    EXAMPLE:    CMPRES LOWCASE MY_MACRO_NAME
  SYMBOLS dependency is based on finding listed symbols in SASHELP.VMACRO
    IMPORTANCE: MANDATORY - Error in log that required macro symbol is not available
    SYNTAX:     space-delimited list of macro symbol names
    EXAMPLE:    SYM_NAME_1 SYM_NAME_2

  Author:          Dante Di Tommaso
  Acknowledgement: Based on FUTS system from Thotwave
                   http://thotwave.com/resources/futs-framework-unit-testing-sas/
***/

  %macro assert_depend(OS=,
                       SASV=,
                       SASPROD=,
                       vars=,
                       macros=,
                       symbols=);

    %local OK cmp didx dnxt vlst vidx vnxt idx nxt;
    %let OK = 1;

    %*--- Current OS should be in dependency list ---*;
      %if %length(&os) > 0 %then %do;
        %if not %sysfunc(indexw(%qupcase(&OS), %qupcase(&SYSSCP), %str(,))) %then %do;
          %put WARNING: (ASSERT_DEPEND) Program requires OS like (&OS), but this %str(&)SYSSCP is &SYSSCP.. Let us see what happens.;
        %end;
      %end;

    %*--- Current SAS version must be in the dependency list ---*;
      %if %length(&sasv) > 0 %then %do;

        %if %qsubstr(&sasv,%length(&sasv)) = %str(+) %then %do;
          %let cmp = GE;
          %let sasv = %substr(&sasv, 1, %length(&sasv)-1);
        %end;
        %else %let cmp = EQ;

        %if not %sysevalf(&SYSVER &CMP &SASV) %then %do;
          %let OK = 0;
          %put ERROR: (ASSERT_DEPEND) Program can only run with SAS version based on %str(&)SYSVER &cmp &SASV..;
        %end;
      %end;

    %*--- Required SAS products must be licensed ---*;
      %if %length(&sasprod) > 0 %then %do;
        %*--- TO DO using SASPROD() and looping through |-delim symbol &SASPROD ---*;
      %end;

    %*--- Data sets must contain required variables ---*;
      %let didx = 1;
      %do %while (%qscan(&vars, &didx, %str(,)) ne );
        %let dnxt = %qscan(&vars, &didx, %str(,));
        %let vlst = %qtrim(%scan(&dnxt, 2, :));
        %let dnxt = %qsysfunc(strip(%scan(&dnxt, 1, :)));

        %if %assert_dset_exist(&dnxt) %then %do;
          %let vidx = 1;
          %do %while (%qscan(&vlst, &vidx, %str( )) ne );
            %let vnxt = %sysfunc(strip(%scan(&vlst, &vidx, %str( ))));

            %if not %assert_var_exist(&dnxt, &vnxt) %then %do;
              %let OK = 0;
              %put ERROR: (ASSERT_DEPEND) Data set %upcase(&dnxt) does not contain required variable %upcase(&vnxt).);
            %end;

            %let vidx = %eval(&vidx + 1);
          %end;
        %end;
        %else %do;
          %let OK = 0;
          %put ERROR: (ASSERT_DEPEND) Data set %upcase(&dnxt) is not available.;
        %end;

        %let didx = %eval(&didx + 1);
      %end;

    %*--- Macros must be available for compilation (in the SAS autocall path) ---*;
      %let idx=1;
      %do %while (%qscan(&macros,&idx,%str( )) ne );
        %let nxt=%qscan(&macros,&idx,%str( ));
         %if not %assert_macro_exist(&nxt) %then %do;
          %let OK = 0;
          %put ERROR: (ASSERT_DEPEND) Macro %upcase(&nxt) is required but not in the AUTOCALL path(s).;
         %end;
        %let idx=%eval(&idx+1);
      %end;

    %*--- Symbols (macro vars) must be available ---*;
      %let idx=1;
      %do %while (%qscan(&symbols,&idx,%str( )) ne );
        %let nxt=%qscan(&symbols,&idx,%str( ));
        %if not %symexist(&nxt) %then %do;
          %let OK = 0;
          %put ERROR: (ASSERT_DEPEND) Symbol (macro var) %upcase(&nxt) is required but not found.;
        %end;
        %let idx=%eval(&idx+1);
      %end;

    %*--- Write result of dependency checks to log ---*;
      %if &OK %then %do;
        %put NOTE: (ASSERT_DEPEND) Result is PASS.;
      %end;
      %else %do;
        %put ERROR: (ASSERT_DEPEND) Result is FAIL. Dependencies for this program not met. Expect problems.;
      %end;

    &OK
  %mend assert_depend;
