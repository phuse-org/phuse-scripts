/***
  Qualification tests for PhUSE/CSS utility macro <MACRO-NAME>

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_<MACRO-NAME>.docx
          
***/


*--- SETUP ---*;

  %let macroname = UTIL_AXIS_ORDER;

  %put WARNING: (TEST_%upcase(&macroname)) User must ensure PhUSE/CSS utilities are in the AUTOCALL path.;

  /*** EXECUTE ONE TIME only as needed

    Ensure PhUSE/CSS utilities are in the AUTOCALL path
    NB: This line is not necessary if PhUSE/CSS utilities are in your default AUTOCALL paths

    OPTIONS mrecall sasautos=(%sysfunc(getoption(sasautos)) "C:\CSS\phuse-scripts\whitepapers\utilities") ls=max ps=max formdlim=' ';

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
       , test_dsc        char(40) label='Test Description'

       , test_type       char(2)  label='Test Type (Macro var, String-<B|C|L|T>, Data set, In data step)'
       , Pparm_min       char(10) label='Test values for the Positional parameter MIN'
       , Pparm_max       char(10) label='Test values for the Positional parameter MAX'
       , Kparm_ticks     char(8)  label='Test values for the Keyword parameter TICKS'

       , test_expect     char(40) label="EXPECTED test results for each call to %upcase(&macroname)"
      )
    ;

    insert into my_test_definitions
      values("%lowcase(&macroname)", '1.a.1', 'Missing min',        'S', '', '-8', '',  '')
      values("%lowcase(&macroname)", '1.a.2', 'Missing max',        'S', '52', '', '',  '')
      values("%lowcase(&macroname)", '1.a.3', 'Missing min & max',  'S', '', '', '',  '')
      values("%lowcase(&macroname)", '1.b.1a', 'Min = Max',         'S', '1E-2', '0.01', '',  '')
      values("%lowcase(&macroname)", '1.b.1b', 'Min = Max',         'S', '315.01', '315.010', '',  '')
      values("%lowcase(&macroname)", '1.b.1c', 'Min = Max',         'S', '075', '75.0', '',  '')
      values("%lowcase(&macroname)", '1.b.2a', 'Min > Max',         'S', '-5.1', '-5.12', '',  '')
      values("%lowcase(&macroname)", '1.b.2b', 'Min > Max',         'S', '3', '-15', '',  '')
      values("%lowcase(&macroname)", '1.b.2c', 'Min > Max',         'S', '67', '57', '',  '')

      values("%lowcase(&macroname)", '2.a.1', 'Pos min & max, various vals',    'S', '0.0038', '0.0202', '',  '0.002 to 0.022 by 0.002')
      values("%lowcase(&macroname)", '2.a.2', 'Pos min & max, various vals',    'S', '0.004', '202', '',      '0 to 210 by 30')
      values("%lowcase(&macroname)", '2.a.3', 'Pos min & max, various vals',    'S', '87.98', '88.01', '',    '87.978 to 88.011 by 0.003')
      values("%lowcase(&macroname)", '2.a.4', 'Pos min & max, various vals',    'S', '8.8', '20.2', '',       '8 to 22 by 2')
      values("%lowcase(&macroname)", '2.a.5', 'Pos min & max, various vals',    'S', '7.2', '800.8', '',      '0 to 880 by 80')
      values("%lowcase(&macroname)", '2.a.6', 'Pos min & max, various vals',    'S', '60', '210', '',         '60 to 220 by 20')
      values("%lowcase(&macroname)", '2.a.7', 'Pos min & max, various vals',    'S', '4', '2725', '',         '0 to 3000 by 300')

      values("%lowcase(&macroname)", '2.b.1', 'Non-pos min & pos max, various vals',    'S', '-0.0202', '0.0038', '',  '-0.021 to 0.006 by 0.003')
      values("%lowcase(&macroname)", '2.b.2', 'Non-pos min & pos max, various vals',    'S', '0', '0.0202', '',        '0 to 0.021 by 0.003')
      values("%lowcase(&macroname)", '2.b.3', 'Non-pos min & pos max, various vals',    'S', '-0.001', '10000', '',    '-1000 to 10000 by 1000')
      values("%lowcase(&macroname)", '2.b.4', 'Non-pos min & pos max, various vals',    'S', '-0.90', '0.95', '',      '-1 to 1 by 0.2')
      values("%lowcase(&macroname)", '2.b.5', 'Non-pos min & pos max, various vals',    'S', '-88', '202', '',         '-90 to 210 by 30')
      values("%lowcase(&macroname)", '2.b.6', 'Non-pos min & pos max, various vals',    'S', '-202', '72', '',         '-210 to 90 by 30')
      values("%lowcase(&macroname)", '2.b.7', 'Non-pos min & pos max, various vals',    'S', '-82', '80', '',          '-100 to 80 by 20')
      values("%lowcase(&macroname)", '2.b.8', 'Non-pos min & pos max, various vals',    'S', '-820', '800', '',        '-1000 to 800 by 200')

      values("%lowcase(&macroname)", '2.c.1', 'Neg min & non-pos max, various vals',    'S', '-0.0202', '-0.0038', '',  '-0.022 to -0.002 by 0.002')
      values("%lowcase(&macroname)", '2.c.2', 'Neg min & non-pos max, various vals',    'S', '-202', '-0.004', '',      '-210 to 0 by 30')
      values("%lowcase(&macroname)", '2.c.3', 'Neg min & non-pos max, various vals',    'S', '-88.01', '-87.99', '',    '-88.01 to -87.99 by 0.002')
      values("%lowcase(&macroname)", '2.c.4', 'Neg min & non-pos max, various vals',    'S', '-20.2', '0', '',          '-21 to 0 by 3')
      values("%lowcase(&macroname)", '2.c.5', 'Neg min & non-pos max, various vals',    'S', '-800.8', '-7.2', '',      '-880 to 0 by 80')
      values("%lowcase(&macroname)", '2.c.6', 'Neg min & non-pos max, various vals',    'S', '-210', '-60', '',         '-220 to -60 by 20')
      values("%lowcase(&macroname)", '2.c.7', 'Neg min & non-pos max, various vals',    'S', '-2725', '-4', '',         '-3000 to 0 by 300')

      values("%lowcase(&macroname)", '2.d.1', 'Non-pos, non-int TICKS val',    'S', '0', '10', '0',       '0 to 10 by 1')
      values("%lowcase(&macroname)", '2.d.2', 'Non-pos, non-int TICKS val',    'S', '0', '10', '5.5',     '0 to 10 by 2')
      values("%lowcase(&macroname)", '2.d.3', 'Non-pos, non-int TICKS val',    'S', '0', '10', '0.001',   '0 to 10 by 1')
      values("%lowcase(&macroname)", '2.d.4', 'Non-pos, non-int TICKS val',    'S', '0', '10', '-0.001',  '0 to 10 by 1')
      values("%lowcase(&macroname)", '2.d.5', 'Non-pos, non-int TICKS val',    'S', '0', '10', '-4.2',    '0 to 10 by 1')
      values("%lowcase(&macroname)", '2.d.6', 'Non-pos, non-int TICKS val',    'S', '0', '10', '-8.5',    '0 to 10 by 1')

      values("%lowcase(&macroname)", '2.e.1', 'Range of pos int TICKS val',    'S', '-10', '10', '1',     '-20 to 20 by 20')
      values("%lowcase(&macroname)", '2.e.2', 'Range of pos int TICKS val',    'S', '-20', '0', '10',     '-20 to 0 by 2')
      values("%lowcase(&macroname)", '2.e.3', 'Range of pos int TICKS val',    'S', '0', '20', '100',     '0 to 20 by 0.2')

/*
      values("%lowcase(&macroname)", ' ', ' ',    'S', '', '', '',  ' to  by ')
*/

    ;
  quit;


*--- Setup test environment here (dsets, macro vars, etc) ---*;


*--- Create EXPECTED test results ---*;


*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);
