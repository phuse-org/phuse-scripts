/***
  Qualification tests for PhUSE/CSS utility macro ASSERT_DSET_EXIST

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST 1: Detection of data set in WORK library
          Certification & Confirmation: Expected log message that all tests pass
            NOTE: (TEST_ASSERT_DSET_EXIST) PASS all tests, T1-C2-A T1-C2-B T1-C2-C T1-C2-D

  TEST 2: Detection of data set in PERMANENT library
          Certification & Confirmation: Expected log message that all tests pass
            NOTE: (TEST_ASSERT_DSET_EXIST) PASS all tests, T2-C1-A T2-C1-B T2-C1-C

  TEST 3: Test of non-existent data sets produce expected log messages
          Certification: Manual check that log messages are correct, and
                         Format follows programming guidelines for log messages
          Confirmation:  Automated check that log messages remain unchanged
***/


*--- SETUP ---*;

  /*** EXECUTE ONE TIME only as needed

    Ensure PhUSE/CSS utilities are in the AUTOCALL path
    NB: This line is not necessary if PhUSE/CSS utilities are in your default AUTOCALL paths

    OPTIONS sasautos=(%sysfunc(getoption(sasautos)) "C:\_Offline_\CSS\phuse_code\whitepapers\utilities");

  ***/


*--- Test 1: Detection of vars in WORK library ---*;

  data class_modified;
    set sashelp.class;
  run;

  *--- Check 1: 1- and 2-level names work for temporary data sets ---*;
    %macro null;
      %local id pass fail;

      %*--- Correctly found CLASS_MODIFIED (defaulting to WORK lib) ---*;
      %let id = T1-C1-A;
      %if 1 = %assert_dset_exist(class_modified) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %*--- Correctly found WORK.CLASS_MODIFIED as specified ---*;
      %let id = T1-C1-B;
      %if 1 = %assert_dset_exist(work.class_modified) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %*--- Correctly fail to find non-existent class (defaulting to WORK lib) ---*;
      %let id = T1-C1-C;
      %if 0 = %assert_dset_exist(class) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %*--- Correctly fail to find non-existent WORK.CLASS as specified ---*;
      %let id = T1-C1-D;
      %if 0 = %assert_dset_exist(work.class) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %if 0 = %length(&fail) %then %put NOTE: (TEST_ASSERT_DSET_EXIST) PASS all tests, &pass;
      %else %do;
        %put PASS these tests, &pass;
        %put FAIL these tests, &fail;
      %end;

    %mend null;
    %null;


  *--- Check 2: Case of data set name does not change results from Check 1 ---*;
    %macro null;
      %local id pass fail;

      %*--- Correctly found CLASS_MODIFIED (defaulting to WORK lib) ---*;
      %let id = T1-C2-A;
      %if 1 = %assert_dset_exist(Class_Modified) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %*--- Correctly found WORK.CLASS_MODIFIED as specified ---*;
      %let id = T1-C2-B;
      %if 1 = %assert_dset_exist(work.CLASS_modified) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %*--- Correctly fail to find non-existent class (defaulting to WORK lib) ---*;
      %let id = T1-C2-C;
      %if 0 = %assert_dset_exist(claSS) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %*--- Correctly fail to find non-existent WORK.CLASS as specified ---*;
      %let id = T1-C2-D;
      %if 0 = %assert_dset_exist(work.cLAss) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %if 0 = %length(&fail) %then %put NOTE: (TEST_ASSERT_DSET_EXIST) PASS all tests, &pass;
      %else %do;
        %put PASS these tests, &pass;
        %put FAIL these tests, &fail;
      %end;

    %mend null;
    %null;

  *--- CLEAN UP temp test data set ---*;
    proc datasets memtype=DATA library=WORK nolist nodetails;
      delete class_modified;
    quit;


*--- Test 2: Detection of vars in PERMANENT library ---*;

  *--- Check 1: 2-level names work for permanent data sets, regardless of case ---*;
    %macro null;
      %local id pass fail;

      %*--- Correctly found SASHELP.CLASS ---*;
      %let id = T2-C1-A;
      %if 1 = %assert_dset_exist(sashelp.class) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %*--- Correctly found SASHELP.CLASS, case does not matter ---*;
      %let id = T2-C1-B;
      %if 1 = %assert_dset_exist(sashelp.cLAss) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %*--- Correctly fail to find non-existent SASHELP.CLASS_MODIFIED ---*;
      %let id = T2-C1-C;
      %if 0 = %assert_dset_exist(sashelp.class_modified) %then %let pass = &pass. &id;
      %else %let fail = &fail. &id;

      %if 0 = %length(&fail) %then %put NOTE: (TEST_ASSERT_DSET_EXIST) PASS all tests, &pass;
      %else %do;
        %put PASS these tests, &pass;
        %put FAIL these tests, &fail;
      %end;

    %mend null;
    %null;
