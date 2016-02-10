/***
  Qualification tests for PhUSE CS utility macro <MACRO-NAME>

  SETUP:  Ensure that PhUSE CS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_<MACRO-NAME>.docx
          
***/


*--- SETUP ---*;

  %let macroname = ASSERT_VAR_NONMISSING;

  %put WARNING: (TEST_%upcase(&macroname)) User must ensure PhUSE CS utilities are in the AUTOCALL path.;

  /*** EXECUTE ONE TIME only as needed

    Ensure PhUSE CS utilities are in the AUTOCALL path
    NB: This line is not necessary if PhUSE CS utilities are in your default AUTOCALL paths

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
       , Kparm_whr       char(60) label='Test values for the Keyword parameter WHR'

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

      values("%lowcase(&macroname)", '2.a.1', 'Non-missing NUM var, pref/suff vars ENTIRELY missings',   'S', 'test_nonmiss', 'num_val', '',   '1')
      values("%lowcase(&macroname)", '2.a.2', 'Non-missing NUM var, pref/suff vars EXACTLY 1 missing',   'S', 'test_1miss',   'num_val', '',   '1')
      values("%lowcase(&macroname)", '2.b.1', 'Non-missing CHAR var, pref/suff vars ENTIRELY missings',  'S', 'test_nonmiss', 'chr_val', '',   '1')
      values("%lowcase(&macroname)", '2.b.2', 'Non-missing CHAR var, pref/suff vars EXACTLY 1 missing',  'S', 'test_1miss',   'chr_val', '',   '1')

      values("%lowcase(&macroname)", '2.c.1', 'NUM var has EXACTLY 1 missing value .',   'S', 'test_1miss', 'd1_num_val', '',   '0')
      values("%lowcase(&macroname)", '2.c.2', 'NUM var has EXACTLY 1 missing value ._',  'S', 'test_1miss', 'u1_num_val', '',   '0')
      values("%lowcase(&macroname)", '2.c.3', 'NUM var has EXACTLY 1 missing value .m',  'S', 'test_1miss', 'm1_num_val', '',   '0')
      values("%lowcase(&macroname)", '2.c.4', 'NUM var has ENTIRELY missing values .',   'S', 'test_nonmiss', 'm_num_val', '',   '0')
      values("%lowcase(&macroname)", '2.c.5', 'NUM var has ENTIRELY special missings (., ._, .m)',  'S', 'test_nonmiss', 's_num_val', '',   '0')

      values("%lowcase(&macroname)", '2.d.1', 'CHAR var has EXACTLY 1 missing value',  'S', 'test_1miss',   'chr_val_d1', '',  '0')
      values("%lowcase(&macroname)", '2.d.2', 'CHAR var has ENTIRELY missing values',  'S', 'test_nonmiss', 'chr_val_m',  '',  '0')

      values("%lowcase(&macroname)", '2.e.1', 'WHR clause leaves NON-MISSING NUM values',   'S', 'test_miss_subset', 'num_val', 'desc="non-missing"',   '1')
      values("%lowcase(&macroname)", '2.e.2', 'WHR clause leaves NON-MISSING CHAR values',  'S', 'test_miss_subset', 'chr_val', 'desc="non-missing"',   '1')

      values("%lowcase(&macroname)", '2.f.1', 'WHR clause leaves EXACTLY 1 NUM missing',     'S', 'test_miss_subset', 'num_val', 'desc in ("missing_1.", "non-missing")',   '0')
      values("%lowcase(&macroname)", '2.f.2', 'WHR clause leaves EXACTLY 1 NUM special ._',  'S', 'test_miss_subset', 'num_val', 'desc in ("special_1_", "non-missing")',   '0')
      values("%lowcase(&macroname)", '2.f.3', 'WHR clause leaves EXACTLY 1 NUM special .m',  'S', 'test_miss_subset', 'num_val', 'desc in ("special_1m", "non-missing")',   '0')
      values("%lowcase(&macroname)", '2.f.4', 'WHR clause leaves MIX of NUM missing vals',   'S', 'test_miss_subset', 'num_val', 'desc contains "missing" or desc contains "special_"',   '0')
      values("%lowcase(&macroname)", '2.f.5', 'WHR clause leaves EXACTLY 1 CHAR missing',    'S', 'test_miss_subset', 'chr_val', 'desc in ("missing_1.", "non-missing")',   '0')

    ;
  quit;


*--- Setup test environment here (dsets, macro vars, etc) ---*;

data test_miss_subset;
  *--- USE DESC var to filter test data set for 2.x tests ---*;
  do key1 = 1, 2, 3, 4;
    do key2 = 'a', 'b', 'c';
      desc = 'non-missing'; num_val = 1 + ranuni(1253); chr_val = 'char of '!!put(num_val,best4.-L); OUTPUT;

      *--- MISSING char values ---*;
      chr_val = ' ';

      *--- multiple missings of each NUMERIC type, and EXACTLY ONE default missings ---*;
      desc = 'missings'; num_val = . ; OUTPUT;
      if (key1 = 1 and key2 = 'c') then do;
        desc = 'missing_1.'; OUTPUT;
      end;

      *--- Special NUM missings, and EXACTLY ONE of each special missing ---*;
      do num_val = ._, .a, .j, .m, .z;
        desc = 'specials'; 
        OUTPUT;

        if (key1 = 2 and key2 = 'b' and num_val = ._) then do;
          desc = 'special_1_';
          OUTPUT;
        end;
        else if (key1 = 3 and key2 = 'c' and num_val = .m) then do;
          desc = 'special_1m';
          OUTPUT;
        end;
        else if (key1 = 4 and key2 = 'a' and num_val = .z) then do;
          desc = 'special_1z';
          OUTPUT;
        end;
      end; *--- special missings ---*;
    end;
  end;
run;

*--- Test NON-MISSING num & char vars, in dset with prefix/suffix vars that are ENTIRELY missing ---*;
  data test_nonmiss;
    set test_miss_subset (where=(desc='non-missing'));
    *--- NUM and CHAR similar-name vars are entirely missing ---*;
    attrib m_num_val length=8.;
    attrib num_val_m length=8.;
    attrib s_num_val length=8.;
    attrib num_val_s length=8.;
    attrib m_chr_val length=$5;
    attrib chr_val_m length=$5;
    retain m_num_val num_val_m . m_chr_val chr_val_m ' ';

    drop temp;
    temp = ranuni(3947);
    if temp < 0.33 then s_num_val = ._;
    else if temp < 0.67 then s_num_val = .m;
    else s_num_val = .z;
   
    num_val_s = s_num_val;
  run;

*--- Test NON-MISSING num & char vars, in dset with prefix/suffix vars that each have EXACTLY 1 missing value ---*;
  data test_1miss;
    set test_miss_subset (where=(desc='non-missing'));
    *--- NUM and CHAR similar-name vars have EXACTLY 1 missing ---*;

    if not (key1 = 2 and key2 = 'a') then do;
      d1_num_val = num_val;
      num_val_d1 = num_val;

      u1_num_val = num_val;
      num_val_u1 = num_val;

      m1_num_val = num_val;
      num_val_m1 = num_val;

      z1_num_val = num_val;
      num_val_z1 = num_val;

      d1_chr_val = chr_val;
      chr_val_d1 = chr_val;
    end;
    else do;
      u1_num_val = ._;
      num_val_u1 = ._;

      m1_num_val = .m;
      num_val_m1 = .m;

      z1_num_val = .z;
      num_val_z1 = .z;

    end;
  run;



*--- Create EXPECTED test results ---*;


*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);
