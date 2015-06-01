/***
  Qualification tests for PhUSE/CSS utility macro ASSERT_DEPEND

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST 1: FAIL when critical macros and symbols are not available

  TEST 2: PASS SAS version, macros and symbols available
          Windows test: Warn that UNIX OS is not supported
          Not case sensitive for OS, macros and symbols names
          
***/


*--- SETUP ---*;

  /*** EXECUTE ONE TIME only as needed

    Ensure PhUSE/CSS utilities are in the AUTOCALL path
    NB: This line is not necessary if PhUSE/CSS utilities are in your default AUTOCALL paths

    OPTIONS sasautos=(%sysfunc(getoption(sasautos)) "C:\CSS\phuse-scripts\whitepapers\utilities");

  ***/


%macro test(macname);
  %if %util_autocallpath(&macname) %then %PUT NOTE (UTIL_AUTOCALLPATH): PASS find macro.;
  %else %put ERROR (UTIL_AUTOCALLPATH): FAIL find macro. Expect problems.;
%mend test;

%test (assert_depends);

%let TEST_SYM = I Exist!;

%* FAIL *;
%put [ %assert_depend(OS=uNIX, SAS=5.5,
                      macros= MY_NON_MACRO ASSERT_NONZERO_SYMBOL Assert_zero_symbol MISSING_MACRO,
                      symbols=MY_nOn_sYM Test_Sym SYSJOBID) ];


%* PASS - OS WARNING *;
%put [ %assert_depend(OS=uNIx, SAS=9.0+,
                      macros= ASSERT_NONZERO_SYMBOL Assert_zero_symbol,
                      symbols=Test_Sym SYSJOBID) ];


%* PASS *;
%put [ %assert_depend(OS=WIN, SAS=9.0+,
                      macros= ASSERT_NONZERO_SYMBOL Assert_zero_symbol,
                      symbols=Test_Sym SYSJOBID) ];


