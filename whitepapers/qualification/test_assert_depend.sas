/***
  Qualification tests for PhUSE/CSS utility macro ASSERT_DEPEND

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_assert_depend.docx
          
***/


*--- SETUP ---*;

  %let macroname = ASSERT_DEPEND;

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
       , kparm_OS        char(50) label='Test values for the keyword parameter OS'
       , kparm_SASV      char(50) label='Test values for the keyword parameter SASV'
       , kparm_macros    char(50) label='Test values for the keyword parameter MACROS'
       , kparm_symbols   char(50) label='Test values for the keyword parameter SYMBOLS'

       , test_expect     char(50) label="EXPECTED test results for each call to %upcase(&macroname)"
      )
    ;

    insert into my_test_definitions
      values("%lowcase(&macroname)", 'ad.1.a.1', 'autocall macro does exist',     
             'S', ' ', ' ', 'QTrim Assert_Complete_RefDS', ' ',      '1')
      values("%lowcase(&macroname)", 'ad.1.a.2', 'autocall macro DOES NOT exist', 
             'S', ' ', ' ', 'QTrim_DNE', ' ',                        '0')
      values("%lowcase(&macroname)", 'ad.1.b.1', 'macro variable exists',     
             'S', ' ', ' ', ' ', 'MacroName SYSscp',                 '1')
      values("%lowcase(&macroname)", 'ad.1.b.1', 'macro variable exists',     
             'S', ' ', ' ', ' ', 'MacroName SYSscp MV_DoesNotExist', '0')

      values("%lowcase(&macroname)", 'ad.2.a.1', 'SAS version IS at least 6.12',
             'S', ' ', '6.12', ' ', ' ',     '1')
      values("%lowcase(&macroname)", 'ad.2.a.2', 'SAS version IS at least 9.1',
             'S', ' ', '9.1', ' ', ' ',      '1')
      values("%lowcase(&macroname)", 'ad.2.a.3', 'SAS version IS at least 9.4M2',
             'S', ' ', '9.4M2', ' ', ' ',    '1')
      values("%lowcase(&macroname)", 'ad.2.b1',   'SAS version is NOT 9.4M8',     
             'S', ' ', '09.04m08', ' ', ' ', '0')
      values("%lowcase(&macroname)", 'ad.2.b2',   'SAS version is NOT 20.5',
             'S', ' ', '20.5', ' ', ' ',     '0')

      /*** NB: OS check never returns 0, but issues a WARNING to the log ***/
      values("%lowcase(&macroname)", 'ad.3.a',   'Confirm whether OS is exactly WIN',
             'S', 'WIN', '', '', '',                             '1')
      values("%lowcase(&macroname)", 'ad.3.b.1', 'Confirm whether OS is other than WIN',
             'S', '%str(AIX,HP,LIN,LINUX,SUN)', '', '', '',      '1')
      values("%lowcase(&macroname)", 'ad.3.b.2', 'Confirm whether OS is any that SAS supports',
             'S', '%str(Win,Aix,Hp,Lin,Linux,Sun)', '', '', '',  '1')
      values("%lowcase(&macroname)", 'ad.3.c',   'Confirm whether OS matches a fictional OS',
             'S', '%str(DNE,JUNK)', '', '', '',                  '1')


      values("%lowcase(&macroname)", 'ad.4.a', 'AUTOCALL MACRO is missing',
             'S', '%str(Win,Aix,Hp,Lin,Linux,Sun)', '6.12', 'LowCase DNE_Delete_DSets', 'MacroName SYSscp',   '0')
      values("%lowcase(&macroname)", 'ad.4.b', 'SAS VERSION is obsolete',
             'S', '%str(Win,Aix,Hp,Lin,Linux,Sun)', '9.04M08', 'LowCase Util_Delete_DSets', 'MacroName SYSscp',  '0')
      values("%lowcase(&macroname)", 'ad.4.c', 'OS is not supported',
             'S', '%str(Dne,Junk)', '9.4m1', 'LowCase Util_Delete_DSets', 'MacroName SYSscp',                  '1')
      values("%lowcase(&macroname)", 'ad.4.d', 'All conditions are successful',
             'S', '%str(Win,Aix,Hp,Lin,Linux,Sun)', '9.4M1', 'LowCase Util_Delete_DSets', 'MacroName SYSscp',  '1')

      /***
      values("%lowcase(&macroname)", '', '',
             'S', '', '', '', '',   '', '')
      ***/

    ;
  quit;


*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);

