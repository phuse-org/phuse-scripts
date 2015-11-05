/***
  Qualification tests for PhUSE/CSS utility macro UTIL_ACCESS_TEST_DATA

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_util_access_test_data.docx
          
***/


*--- SETUP ---*;

  %let macroname = UTIL_ACCESS_TEST_DATA;

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
       , pparm_DS        char(32) label='Test values for the Positional parameter DS'
       , kparm_XPORT     char(32) label='Test values for the Keyword parameter XPORT'
       , kparm_LOCAL     char(75) label='Test values for the Keyword parameter LOCAL'

       , test_expect     char(50) label="EXPECTED test results for each call to %upcase(&macroname)"
      )
    ;

    insert into my_test_definitions
      values("%lowcase(&macroname)", 'atd.1.a.1', 'Error: Valid XPORT,  Invalid DS, remote XPT',
             'D', 'dset_dne', 'test',  ''                                 '-css_dset_dne')
      values("%lowcase(&macroname)", 'atd.1.a.2', 'Error: Valid XPORT,  Invalid DS, local XPT',
             'D', 'dset_dne', 'test',  "%str(%sysfunc(pathname(WORK))/)"  '-css_dset_dne')
      values("%lowcase(&macroname)", 'atd.1.b.1', 'Error: Invalid XPORT, remote XPT',
             'D', 'xpt_dne', '',       ''                                 '-css_xpt_dne')
      values("%lowcase(&macroname)", 'atd.1.b.2', 'Error: Invalid XPORT, local XPT',
             'D', 'xpt_dne', '',       "%str(%sysfunc(pathname(WORK))/)"  '-css_xpt_dne')

      values("%lowcase(&macroname)", 'atd.2.a.1', 'Access same-named data set',
             'D', 'test', '',     ''                                 'expect_test=css_test')
      values("%lowcase(&macroname)", 'atd.2.a.2', 'Access local same-named data set',
             'D', 'test', '',     "%str(%sysfunc(pathname(WORK))/)"  'expect_test=css_test')
      values("%lowcase(&macroname)", 'atd.2.b.1', 'Access other-named data set',
             'D', 'demo', 'test', ''                                 'expect_demo=css_demo')
      values("%lowcase(&macroname)", 'atd.2.b.2', 'Access local other-named data set',
             'D', 'demo', 'test', "%str(%sysfunc(pathname(WORK))/)"  'expect_demo=css_demo')

    /***
      values("%lowcase(&macroname)", '', '',   'D', '', '', ''   '')
      values("%lowcase(&macroname)", '', '',   'D', '', '', ''   '')
      values("%lowcase(&macroname)", '', '',   'D', '', '', ''   '')
    ***/

    ;
  quit;


*--- Setup test environment here (dsets, macro vars, etc) ---*;
  *--- Create a small XPT containing 2 data sets. Store in central location of CSS/PhUSE test data ---*;
    %util_access_test_data(adsl);

  *--- NB: IF YOU CHANGE THIS DATA SET, you need to also change the XPT in the central location ---*;
    data test (keep=studyid usubjid arm saffl ittfl)
         demo (keep=studyid usubjid arm age race sex);
      set css_adsl (keep=studyid usubjid arm saffl ittfl age race sex);
      retain reference 'http://www.theonion.com/article/fda-approves-sale-of-prescription-placebo-1606';

      if _n_ > 5 then delete;
      if arm =: 'Xanomeline' then substr(arm,1,10) = 'Sucrosa';
      arm = compbl(arm);
    run;

  /*** XPORT format for central test data repository
   The following XPORT container, including 2 data sets, should be on the CSS/PhUSE central test data repository
   ***/

    libname csstest xport "%sysfunc(pathname(WORK))/test.xpt";
    proc copy in=work out=csstest memtype=data; 
       select test demo;
    run;
    libname csstest clear;


*--- Create EXPECTED test results ---*;
  data _null_;
    rc = rename('test', 'expect_test', 'data');
    rc = rename('demo', 'expect_demo', 'data');
  run;

*--- Execute & evaluate tests, and report & store test results ---*;

  *--- DISABLE syntax check mode, which otherwise stops processing after 1st invalid dset name ---*;
  options NOSYNTAXCHECK;

  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);
