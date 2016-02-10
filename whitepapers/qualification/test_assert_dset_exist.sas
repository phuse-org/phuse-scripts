/***
  Qualification tests for PhUSE CS utility macro ASSERT_DSET_EXIST

  SETUP:  Ensure that PhUSE CS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_assert_dset_exist.docx
          
***/


*--- SETUP ---*;

  %let macroname = ASSERT_DSET_EXIST;

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
       , Pparm_ds        char(80) label='Test values for the Positional parameter DS'

       , test_expect     char(50) label="EXPECTED test results for each call to %upcase(&macroname)"
      )
    ;

    insert into my_test_definitions
      values("%lowcase(&macroname)", 'dse.1', 'Null data set list returns FAIL',   
             'S', '_NULLPARM_',   '0')

      values("%lowcase(&macroname)", 'dse.2.a.1', 'Existing one-level WORK dset found',   
             'S', 'Not',                   '1')
      values("%lowcase(&macroname)", 'dse.2.a.2', 'Existing two-level WORK dset found',   
             'S', 'Work.Class_Modified',   '1')

      values("%lowcase(&macroname)", 'dse.2.b.1', 'Non-existent one-level WORK dset NOT found',   
             'S', 'NotInWork',             '0')
      values("%lowcase(&macroname)", 'dse.2.b.2', 'Non-existent two-level WORK dset NOT found',   
             'S', 'Work.Class_Mod_DNE',    '0')

      values("%lowcase(&macroname)", 'dse.2.c.1', 'Existing two-level Permanent dset found',   
             'S', 'And.Or',                '1')
      values("%lowcase(&macroname)", 'dse.2.d.1', 'Non-existent Permanent dset NOT found',   
             'S', 'Sashelp.Classics',      '0')

      values("%lowcase(&macroname)", 'dse.3.a',    'Multiple work and permanent data sets found',   
             'S', 'SasHelp.Class WORK.Not And.OR', '1')

      values("%lowcase(&macroname)", 'dse.3.b.1', '1st missing data sets results in overall FAIL',   
             'S', 'Work.If Sashelp.Class Work.NOT AND.or',           '0')
      values("%lowcase(&macroname)", 'dse.3.b.2', 'last missing data sets results in overall FAIL',   
             'S', 'Sashelp.Class Work.NOT AND.or Work.For',          '0')
      values("%lowcase(&macroname)", 'dse.3.b.3', 'in between missing data sets results in overall FAIL',   
             'S', 'Sashelp.Class Work.NOT SAShelp.Classics AND.or',  '0')

      /***
      values("%lowcase(&macroname)", '', '',   
             'S', '',   '')
      ***/
    ;
  quit;


*--- Setup test environment here (dsets, macro vars, etc) ---*;

  data class_modified;
    set sashelp.class;
  data not;
    set sashelp.class;
  run;

  libname AND '.';

  data and.or;
    set sashelp.class;
  run;



*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);



*--- CLEAN UP Permanent test data set ---*;
  proc datasets memtype=DATA library=AND nolist nodetails;
    delete OR;
  quit;

  libname AND clear;
