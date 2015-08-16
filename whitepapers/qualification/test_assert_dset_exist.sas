/***
  Qualification tests for PhUSE/CSS utility macro ASSERT_DSET_EXIST

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_assert_dset_exist.docx
          
***/


*--- SETUP ---*;

  %let macroname = ASSERT_DSET_EXIST;

  %put WARNING: (TEST_%upcase(&macroname)) User must ensure PhUSE/CSS utilities are in the AUTOCALL path.;

  /*** EXECUTE ONE TIME only as needed

    Ensure PhUSE/CSS utilities are in the AUTOCALL path
    NB: This line is not necessary if PhUSE/CSS utilities are in your default AUTOCALL paths

    OPTIONS mrecall sasautos=(%sysfunc(getoption(sasautos)) "C:\CSS\phuse-scripts\whitepapers\utilities");

  ***/


  *--- SAVE TEST RESULTS as XML filename  ---*;
  *--- NB: if this filename is blank, do NOT save xml test results ---*;

    %let XML_FILENAME = .\outputs_sas\testresults_%lowcase(&macroname).xml;


*--- Test Definitions  ---*;
  *--- Full Specs for test definitions: https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/utilities/util_passfail.sas ---*;

  proc sql;
    create table my_test_definitions
      (  test_mac        char(32) label='Name of macro to test'
       , test_id         char(15) label="Test ID for %upcase(&macroname)"
       , test_dsc        char(80) label='Test Description'

       , test_type       char(5)  label='Test Type (Macro var, String-<B|C|L|T>, Data set, In data step)'
       , Pparm_<..>      char(50) label='Test values for the Positional parameter <..>'
       , Kparm_<..>      char(50) label='Test values for the Keyword parameter <..>'

       , test_expect     char(50) label="EXPECTED test results for each call to %upcase(&macroname)"
       , test_expect_sym char(20) label='TEST_PDLIM-delim Name=Value pairs of EXPECTED global syms created'
      )
    ;

    insert into my_test_definitions
      values("%lowcase(&macroname)", '', '',   '', '', '',   '', '')
      values("%lowcase(&macroname)", '', '',   '', '', '',   '', '')
      values("%lowcase(&macroname)", '', '',   '', '', '',   '', '')
      values("%lowcase(&macroname)", '', '',   '', '', '',   '', '')
      values("%lowcase(&macroname)", '', '',   '', '', '',   '', '')

    ;
  quit;


*--- Setup test environment here (dsets, macro vars, etc) ---*;


*--- Create EXPECTED test results ---*;



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



*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);
