/***
  Qualification tests for PhUSE/CSS utility macro ASSERT_VAR_EXIST

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_assert_var_exist.docx
          
***/


*--- SETUP ---*;

  %let macroname = ASSERT_VAR_EXIST;

  %put WARNING: (TEST_%upcase(&macroname)) User must ensure PhUSE/CSS utilities are in the AUTOCALL path.;

/*** EXECUTE ONE TIME only as needed

    Ensure PhUSE/CSS utilities are in the AUTOCALL path
    NB: This line is not necessary if PhUSE/CSS utilities are in your default AUTOCALL paths

    OPTIONS mrecall sasautos=(%sysfunc(getoption(sasautos)) "C:\CSS\phuse-scripts\whitepapers\utilities") ls=max ps=max;

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
       , test_dsc        char(99) label='Test Description'

       , test_type       char(5)  label='Test Type (Macro var, String-<B|C|L|T>, Data set, In data step)'
       , Pparm_DS        char(50) label='Test values for the Positional parameter DS'
       , Pparm_VAR       char(50) label='Test values for the Keyword parameter VAR'

       , test_expect     char(50) label="EXPECTED test results for each call to %upcase(&macroname)"
      )
    ;

    insert into my_test_definitions
      values("%lowcase(&macroname)", 'ave.1.a.1', 'NULL data set',
             'S', '', '',                  '0')
      values("%lowcase(&macroname)", 'ave.1.a.2', 'Non-existent one-level data set, but name matches start of a valid name',
             'S', 'longdata', '',          '0')
      values("%lowcase(&macroname)", 'ave.1.a.3', 'Non-existent one-level data set, but name appears within a valid name',
             'S', 'dataset', '',           '0')
      values("%lowcase(&macroname)", 'ave.1.a.4', 'Non-existent two-level data set, but name matches end of a valid name',
             'S', 'sasuser.setname', '',   '0')

      values("%lowcase(&macroname)", 'ave.1.b.1', 'NULL variable',   'S', 'longdatasetname', '',   '0')
      values("%lowcase(&macroname)", 'ave.1.b.2', 'Non-existent variable in one-level data set, but name is prefix of a valid variable',
             'S', 'longdatasetname', 'longnam',   '0')
      values("%lowcase(&macroname)", 'ave.1.b.3', 'Non-existent variable in one-level data set, but name appears within a valid variable',
             'S', 'longdatasetname', 'ongvar',    '0')
      values("%lowcase(&macroname)", 'ave.1.b.4', 'Non-existent variable in one-level data set, but name is suffix of a valid variable',
             'S', 'longdatasetname', 'ablename',  '0')
      values("%lowcase(&macroname)", 'ave.1.b.5', 'Non-existent variable in two-level data set, but a valid variable matches start of this variable',
             'S', 'sasuser.longdsetname', 'longname',               '0')
      values("%lowcase(&macroname)", 'ave.1.b.6', 'Non-existent variable in two-level data set, but a valid variable appears within this variable',
             'S', 'sasuser.longdsetname', 'newvariablestr',         '0')
      values("%lowcase(&macroname)", 'ave.1.b.7', 'Non-existent variable in two-level data set, but a valid variable matches end of this variable',
             'S', 'sasuser.longdsetname', 'ratherlongvariablestr',  '0')

      values("%lowcase(&macroname)", 'ave.2.a.1', 'Valid variable in one-level data set',
             'S', 'longdatasetname', 'longvariablename',   '1')
      values("%lowcase(&macroname)", 'ave.2.a.2', 'Valid variable in two-level data set',
             'S', 'sasuser.longdsetname', 'long',          '1')

/*
      values("%lowcase(&macroname)", 'ave.', '',   'S', '', '',   '')
*/

    ;
  quit;


*--- Setup test environment here (dsets, macro vars, etc) ---*;
  data longdatasetname;
    longvariablename = 'full name';
    long             = 'prefix name';
    variable         = 'contained name';
    name             = 'suffix name';
    OUTPUT;
  run;

  data sasuser.longdsetname;
    set longdatasetname;
  run;



*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);


*--- Cleanup ---*;
  proc datasets library=SASUSER memtype=DATA nolist nodetails;
    delete longdatasetname;
  quit;
