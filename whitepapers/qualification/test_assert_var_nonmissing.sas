/***
  Qualification tests for PhUSE/CSS utility macro <MACRO-NAME>

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_<MACRO-NAME>.docx
          
***/


*--- SETUP ---*;

  %let macroname = ASSERT_VAR_NONMISSING;

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
       , test_dsc        char(80) label='Test Description'

       , test_type       char(5)  label='Test Type (Macro var, String-<B|C|L|T>, Data set, In data step)'
       , Pparm_ds        char(50) label='Test values for the Positional parameter DS'
       , Pparm_var       char(50) label='Test values for the Positional parameter VAR'
       , Kparm_whr       char(50) label='Test values for the Keyword parameter WHR'

       , test_expect     char(50) label="EXPECTED test results for each call to %upcase(&macroname)"
      )
    ;

    insert into my_test_definitions
      values("%lowcase(&macroname)", '1.a.1', 'Missing require DS',              'S', '_NULLPARM_', 'weight',        '',   '0')
      values("%lowcase(&macroname)", '1.a.2', 'Missing required VAR',            'S', 'sashelp.heart', '_NULLPARM_', '',   '0')
      values("%lowcase(&macroname)", '1.a.3', 'Missing required DS and VAR',     'S', '_NULLPARM_', '_NULLPARM_',    '',   '0')

      values("%lowcase(&macroname)", '1.b.1', 'Invalid require DS',              'S', 'sashelp.hearts', 'weight',  '',   '0')
      values("%lowcase(&macroname)", '1.b.2', 'Invalid required VAR',            'S', 'sashelp.heart', 'weights',  '',   '0')
      values("%lowcase(&macroname)", '1.b.3', 'Invalid required DS and VAR',     'S', 'sashelp.hearts', 'weights', '',   '0')

      values("%lowcase(&macroname)", '1.c.1', 'Invalid WHR, invalid var name',            'S', 'sashelp.heart', 'cholesterol', 'weights > 150',        '0')
      values("%lowcase(&macroname)", '1.c.2', 'Invlaid WHR, type mismatch for NUM var',   'S', 'sashelp.heart', 'cholesterol', "weight in ('A' 'B')",  '0')
      values("%lowcase(&macroname)", '1.c.2', 'Invlaid WHR, type mismatch for CHAR var',  'S', 'sashelp.heart', 'cholesterol', 'bp_status > 5',        '0')

    ;
  quit;


*--- Setup test environment here (dsets, macro vars, etc) ---*;


*--- Create EXPECTED test results ---*;


*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, debug=N);
  %*util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);
