/***
  Qualification tests for PhUSE CS utility macro ASSERT_MACRO_EXIST

  SETUP:  Ensure that PhUSE CS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_assert_dset_exist.docx
          
***/


*--- SETUP ---*;

  %let macroname = ASSERT_MACRO_EXIST;

  %put WARNING: (TEST_%upcase(&macroname)) User must ensure PhUSE CS utilities are in the AUTOCALL path.;

  /*** EXECUTE ONE TIME only as needed

    Ensure PhUSE CS utilities are in the AUTOCALL path
    NB: This line is not necessary if PhUSE CS utilities are in your default AUTOCALL paths

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
       , Pparm_sym       char(50) label='Test values for the Positional parameter SYM'

       , test_expect     char(50) label="EXPECTED test results for each call to %upcase(&macroname)"
      )
    ;

    insert into my_test_definitions
      values("%lowcase(&macroname)", 'me.1.a.1', 'Find SAS AUTOCALL macro CMPRES',
             'S', 'CMPres',   '1')
      values("%lowcase(&macroname)", 'me.1.a.2', 'Find SAS AUTOCALL macro QLEFT',
             'S', 'qleFT',    '1')
      values("%lowcase(&macroname)", 'me.1.a.3', 'Find SAS AUTOCALL macro LOWCASE',
             'S', 'LoWcAsE',  '1')
      values("%lowcase(&macroname)", 'me.1.b.1', 'Do not find macro CMPRE',
             'S', 'CMPre',    '0')
      values("%lowcase(&macroname)", 'me.1.b.2', 'Do not find SAS AUTOCALL macro QLEF',
             'S', 'qleF',     '0')
      values("%lowcase(&macroname)", 'me.1.b.3', 'Do not find SAS AUTOCALL macro CSS_LOWERCASING',
             'S', 'CsS_LoWeRcAsInG',  '0')
      values("%lowcase(&macroname)", 'me.1.c',   'Controlled fail given NULL macro name',
             'S', '_NULLPARM_',       '0')


      values("%lowcase(&macroname)", 'me.2.a.1', 'Find PhUSE CS macro ASSERT_CONTINUE',
             'S', 'Assert_CONTINUE',   '1')
      values("%lowcase(&macroname)", 'me.2.a.2', 'Find PhUSE CS macro UTIL_DELETE_DSETS',
             'S', 'UTIL_delete_DSETS', '1')

      values("%lowcase(&macroname)", 'me.3.a', 'Find macro written on the fly: CSS_ONTHEFLY',
             'S', 'CSS_ONTHEFLY',   '1')

      /***
      values("%lowcase(&macroname)", '', '',   
             'S', '',   '')
      ***/
    ;
  quit;


*--- Setup test environment here WRITE temp macro, and force path into SASAUTO paths ---*;

  filename tempmac "%sysfunc(pathname(WORK))/css_onthefly.sas";
  data _null_;
    file tempmac;
    put '%macro css_onthefly; %put NOTE: (CSS_ONTHEFLY) PASS, on-the-fly macro found and executed.; %mend css_onthefly;';
  run;

  %macro update_sasautos;
    %local currautos;

    %let currautos = %sysfunc(getoption(sasautos));
    %if %qsubstr(&currautos,1,1) = %str(%() %then %let currautos = %qsubstr(&currautos,2,%eval(%length(&currautos)-2));

    OPTIONS mrecall sasautos=(&currautos "%sysfunc(pathname(WORK))");
  %mend update_sasautos;
  %update_sasautos;


*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);


*--- CLEAN UP test environment as needed ---*;

  filename tempmac clear;
