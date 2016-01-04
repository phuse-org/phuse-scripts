/***
  Qualification tests for PhUSE/CSS utility macro <MACRO-NAME>

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_<MACRO-NAME>.docx
          
***/


*--- SETUP ---*;

  %let macroname = <MACRO-NAME>;

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




/*** TEST calls

  %put [%util_axis_order(88.2, 20.2)];        *** NB: ERROR condition ***;
  %put [%util_axis_order(20.2, 20.2)];        *** NB: ERROR condition ***;
  %put [%util_axis_order(87.9999, 88.0001)];

  %put [%util_axis_order(0.00009, 202)];
  %put [%util_axis_order(8.8, 20.2)];
  %put [%util_axis_order(7.9, 8.8)];
  %put [%util_axis_order(42, 2725)];
  %put [%util_axis_order(-2029, -39)];

  %put [%util_axis_order(-88, 202)];
  %put [%util_axis_order(-202, 72)];

  %put [%util_axis_order(0.000038, 0.00202)];
  %put [%util_axis_order(-0.00202, -0.000038)];
  %put [%util_axis_order(-0.00202, 0.000038)];
  %put [%util_axis_order(-0.000038, 0.00202)];

  %put [%util_axis_order(60, 210)];
  %put [%util_axis_order(-0.90, 0.95)];
  %put [%util_axis_order(-0.001, -0.00001)];
  %put [%util_axis_order(-0.001, 10000)];
  %put [%util_axis_order(-82, 80)];
  %put [%util_axis_order(-820, 800)];


***/




    ;
  quit;


*--- Setup test environment here (dsets, macro vars, etc) ---*;


*--- Create EXPECTED test results ---*;


*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);
