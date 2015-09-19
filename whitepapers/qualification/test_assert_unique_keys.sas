/***
  Qualification tests for PhUSE/CSS utility macro ASSERT_UNIQUE_KEYS

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_assert_unique_keys.docx
          
***/


*--- SETUP ---*;

  %let macroname = ASSERT_UNIQUE_KEYS;

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
       , test_dsc        char(60) label='Test Description'

       , test_type       char(5)  label='Test Type (Macro var, String-<B|C|L|T>, Data set, In data step)'
       , Pparm_DS        char(40) label='Test values for the Positional parameter DS'
       , Pparm_KEYS      char(30) label='Test values for the Positional parameter KEYS'
       , Kparm_INCL      char(30) label='Test values for the Keyword parameter INCL'
       , Kparm_SQLWHR    char(60) label='Test values for the Keyword parameter SQLWHR'

       , test_expect     char(30) label="EXPECTED test results for each call to %upcase(&macroname)"
       , test_expect_sym char(30) label='TEST_PDLIM-delim Name=Value pairs of EXPECTED global syms created'
      )
    ;

    * test type "I" (In data step) in order to wrap each test with code to create global macro var CONTINUE *;

    insert into my_test_definitions
      values("%lowcase(&macroname)", 'auk1.a.1', 'NULL dset name',
             'I', '_NULLPARM_', 'var1 var2', 'var3', '',   '-work.fail_auk', 'CONTINUE=0')
      values("%lowcase(&macroname)", 'auk1.a.2', 'Invalid dset name',
             'I', 'Work.Dne', 'var1 var2', '', '',   '-work.fail_auk', 'CONTINUE=0')
      values("%lowcase(&macroname)", 'auk1.a.3.i', 'Invalid truncated dset name',
             'I', 'SAShelp.CLAS', 'name', 'sex age', '',   '-work.fail_auk', 'CONTINUE=0')
      values("%lowcase(&macroname)", 'auk1.a.3.ii', 'Invalid dset name with partial match',
             'I', 'WORK.CSS_CLASSes', 'name sex', 'age', '',   '-work.fail_auk', 'CONTINUE=0')
      values("%lowcase(&macroname)", 'auk1.b.1', 'NULL keys',              
             'I', 'ClassES', '_NULLPARM_', '', '',   '-work.fail_auk', 'CONTINUE=0')
      values("%lowcase(&macroname)", 'auk1.b.2', 'Invalid single key',
             'I', 'sasHelp.Class', 'nam', 'sex age', '',   '-work.fail_auk', 'CONTINUE=0')
      values("%lowcase(&macroname)", 'auk1.b.3', 'Invalid multiple keys',
             'I', 'Work.CLASSes', 'nam gender', 'age', '',   '-work.fail_auk', 'CONTINUE=0')
      values("%lowcase(&macroname)", 'auk1.c.1', 'Invalid single INCL var',
             'I', 'worK.ClassES', 'name sex', 'ag', '',   '-work.fail_auk', 'CONTINUE=0')
      values("%lowcase(&macroname)", 'auk1.c.2', 'Invalid multiple INCL vars',
             'I', 'sasHelp.Class', 'name', 'gender aged', '',   '-work.fail_auk', 'CONTINUE=0')

      values("%lowcase(&macroname)", 'auk2.a', 'Unique single key',
             'I', 'SasHelp.Class', 'name', '', ''   '-fail_auk', 'CONTINUE=1')
      values("%lowcase(&macroname)", 'auk2.b', 'Non-unique single key FAILS',
             'I', 'classes', 'name', '', ''   'fail_auk2_b=fail_auk', 'CONTINUE=0')

      values("%lowcase(&macroname)", 'auk3.a', 'Unique set of keys',
             'I', 'Classes', 'name sex', '', ''   '-fail_auk', 'CONTINUE=1')
      values("%lowcase(&macroname)", 'auk3.b', 'Non-unique set of keys FAILS',
             'I', 'Work.Classes', 'name age', '', ''   'fail_auk3_b=fail_auk', 'CONTINUE=0')

      values("%lowcase(&macroname)", 'auk4.a', 'Non-unique single key FAILS & returns extra INCL vars',
             'I', 'classes', 'name', 'sex source', ''   'fail_auk4_a=fail_auk', 'CONTINUE=0')
      values("%lowcase(&macroname)", 'auk4.b', 'Non-unique set of keys FAILS & returns extra INCL vars',
             'I', 'Work.Classes', 'name age', 'source', ''   'fail_auk4_b=fail_auk', 'CONTINUE=0')

      values("%lowcase(&macroname)", 'auk5.a', 'Valid single key after SQLWHR subsetting',   
             'I', 'Work.Classes', 'name', '', 'where source="SASHELP"'   '-work.fail_auk', 'CONTINUE=1')
      values("%lowcase(&macroname)", 'auk5.b', 'Invalid single key after SQLWHR subsetting',   
             'I', 'Work.Classes', 'name', '', 'where height < 64'   'fail_auk5_b=work.fail_auk', 'CONTINUE=0')
      values("%lowcase(&macroname)", 'auk5.c', 'Valid set of keys after SQLWHR subsetting',   
             'I', 'classes_dup', 'name sex', '', 'where copy = 1'   '-FAIL_AUK', 'continue=1')
      values("%lowcase(&macroname)", 'auk5.d', 'Invalid set of keys after SQLWHR subsetting',   
             'I', 'classes_DUP', 'name sex', '', 'where age < 13'   'fail_auk5_d=work.fail_auk', 'continue=0')

/*
      values("%lowcase(&macroname)", '', '',   '', '', '', '', ''   '', '')
*/
    ;
  quit;

  data my_test_definitions;
    set my_test_definitions;

    * test type "I" (In data step) in order to wrap each test with code to create global macro var CONTINUE *;

    retain test_wrap '%global continue; _maccall1_;';
  run;


*--- Setup test environment here (dsets, macro vars, etc) ---*;

*--- Create EXPECTED test results ---*;
  data classes;
    * Duplicate SASHELP.CLASS records, but with SEX ('M', 'F') reversed *;
    * Result: NAME is a valid unique key in SASHELP.CLASS, but not in WORK.CLASS, with valid keys NAME, SEX *;
    set sashelp.class(in=in_orig) sashelp.class(in=in_rep);

    if in_orig then source = 'SASHELP';
    else do;
      source = 'FLIPPED';
      if sex = 'M' then sex = 'F';
      else sex = 'M';
    end;
  run;

  data classes_dup;
    set classes (in=in_one) classes;
    if in_one then copy = 1;
    else copy = 2;
  run;

  data fail_auk2_b (keep=name)
       fail_auk3_b (keep=name age)
       fail_auk4_a (keep=name sex source)
       fail_auk4_b (keep=name age source);
    set classes;
  run;

  proc sort data=fail_auk2_b nodupkey;
    by name;
  proc sort data=fail_auk3_b nodupkey;
    by name age;
  proc sort data=fail_auk4_a nodupkey;
    by name sex source;
  proc sort data=fail_auk4_b nodupkey;
    by name age source;
  run;

  proc sort data=classes (keep=name height where=(height < 64)) 
             out=fail_auk5_b (keep=name) nodupkey;
    by name;
  proc sort data=classes (keep=name sex age where=(age < 13)) 
             out=fail_auk5_d (keep=name sex) nodupkey;
    by name sex;
  run;


*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);
