/***
  Execute and report results of tests defined in a structured way for a SAS macro.
  A test program then executes each macro call (as defined in each test), and assesses 
  actual results again the expected results (also defined in each test).

  SAS version: 9.2 (%symdel usage, Macro IN Operator)

  Inputs        : structured data set containing test definitions, 
                  plus any "results" items referenced in those definitions
  Outputs       : PASS/FAIL results for specified tests
  Called macros : -no external calls-

  Example of use: 
    https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/example_passfail_test_definitions.sas

  Parameters:
    Positional : DSIN      - Structured test data set
    Keyword    : CRITERION - Numeric value as required for PROC COMPARE CRITERION= option
                             (Default: null, for PROC COMPARE METHOD=EXACT)
                         NB: This should NOT be used to suppress diffs that STREAM should fix.
                             This should be used to suppress diffs that STREAM cannot handle.
                         EG: STR_UTIL_CALCDUR does not fix precision since calling program should
                             (so OK to apply CRITERION=1E-13 in STR_UTIL_CALCDUR unit tests)
                 SAVEXML   - (OPTIONAL) Save test results as XML to this filename
                 DEBUG     - (OPTIONAL) Y/N flag to write out additional processing details

  Notes:
    NB: The following PROC SQL block provides the expected structure of &DSIN data set.

      Note the repeating PPARM and KPARM vars, which include the names of each positional & 
      keyword macro parameter appended to the PPARM_ and KPARM_ prefixes.

      This is based on a SAS example of an easy-to-read SQL approach for creating a data set:
        http://support.sas.com/documentation/cdl/en/sqlproc/65065/HTML/default/n1ncn0pznd8wrln1tnp3xdxjz9xz.htm

      TEMPLATE CODE (replace "<TEST_MAC>" and "<..>" and ".." as needed):

          proc sql;
            create table my_test_definitions
              ( test_mac  char(32)   label='Name of macro to test',
                test_id   char(12)   label='Test ID for <TEST_MAC>',
                test_dsc  char(80)   label='Test Description',
                test_type char(10)   label='Test Type (Macro var, String-<B|C|L|T>, Data set, In data step)',
                pparm_<..> char(..)  label='Test values for the positional parm <..>',
                kparm_<..> char(..)  label='Test values for the keyword parm <..>',
                test_expect char(..) label='EXPECTED test results for each call to <TEST_MAC>',

                test_expect_sym char(..) label='OPTIONAL: TEST_PDLIM-delim Name=Value pairs of EXPECTED global syms created',
                test_wrap char(..) label='OPTIONAL: for String and In Data Step tests, wrapper code with _MACCALL<i>_ placeholders',
                test_pdlim char(1) label='OPTIONAL: Delim of param vals for tests with multiple macro calls (def=|)')
            ;

            insert into my_test_definitions
              values( ' ', ' ', .. )
            ;
          quit;

  NB: Data Step and Macro Variable names both have max length of 32 chars. The current prefix syntax "pparm_" and "kparm",
      therefore, makes it impossible to test macros with parameters of length > 26 char. If this constraint is a problem,
      then UTIL_PASSFAIL requires some redesign ... eg, use a vertical structure with a var indicating "POSITIONAL" or "KEYWORD".
 
  NB: Determining number of macro calls per test - For each test, Macro 1st counts num of '_MACCALL' strings in TEST_WRAP,
      regardless of test type (useful for macro calls without parameters). See TEST_WRAP details, below.
      Macro then counts num of TEST_PDLIM chars in each parameter value using COUNTC(*parm*, *pdlim*).
      Macro stores the largest result in TEST_CALLS, used later to build macro calls from parameter vals.
      There must be at least 1 macro call specified per test.
 
  NB: PPARM_ and KPARM_ values - leave variable blank (' ') to suppress including the parameter in the generated macro call.
                                 set variable to '_NULLPARM_' to force a null parameter into the generated macro call.
 
  NB: TEST_TYPE   < M | S-BCLT | D | I > determines test logic & processing of response
                  String test "S" can include post-processing instructions "-CLT" to
                              compBl(), Compress(), Left(), or Trim() string results in order specified
  NB: TEST_EXPECT results of test macro calls. For [D] & [I] tests, must be either
                    1. space-delim pairs of =-dlim NAMES of EXPECTED and RESULTING data sets, or
                       EG: "exp1=res1 exp2=res2" asserts that the macro call produces 2 data sets: res1 & res2
                           RES1 should match EXP1, and RES2 should match EXP2.
                    2. negated name of a data set that should NOT exist
                       EG: "-results" or "-work.results" asserts that no RESULTS data set should exist
               !! + NB: Order matters - "EXPECT=RESULT". Macro DELETES all right-hand (RESULT) dsets after each test
                        so that tests are independent.
                  + Expected dsets must exist in WORK prior to executing the PASS/FAIL tests
                  + Expected dsets can be re-used in multiple tests (this macro does not alter them)
                  + Expected dsets must not be altered by any of the test macro calls (violates test independence)
                  + IE, macro calls and TEST_WRAP code in suite of tests should not alter any Expected dset
  NB: TEST_WRAP   Contains wrapper code for macro calls to be embedded in other Base SAS statements.
                  NOT USED for (D) Data set tests. ONLY USED for Macro (M), String (S) and In Data Step (I) tests.
                  Include placeholders for each macro call specified in parameter settings: _MACCALL1_ _MACCALL2_, ...
                  (macro call placeholders must be separated from other codes with spaces or semi-colons)

  Author  :       D. Di Tommaso
                  Macro presented at PhUSE 2011. The paper is online and provides additional details
                  http://www.lexjansen.com/phuse/2011/ad/AD04.pdf
***/

%macro util_passfail (dsin, criterion=, savexml=, debug=N) / minoperator;

  %local maxlrecl dslib dsnam dsout compmeth
         pparms kparms allparms
         ppcnt  kpcnt  apcnt parm_idx
         test_mac_name mac_calls_num mac_calls_idx test_len_post
         last_test
         test_num test_idx test_id test_dsc dset_idx dset_exp dset_res
         test_expect test_result test_fail_title good_compare
         inisyms expsyms endsyms ;

  %*+-------------------------------------------------------------------------+*;
  %*| Check debugging settings & store processed test data if DEBUG=Y         |*;
  %*+-------------------------------------------------------------------------+*;
  %let debug = %upcase(&debug);
  %if %length(%cmpres(&debug)) eq 0 %then %let debug = N;
  %let debug = %upcase(%substr(&debug,1,1));

  %if &debug = N %then %let dsout = work.css_passfail;
  %else %do;
    %if &sysscp = WIN %then libname home "%sysget(USERPROFILE)";
    %else libname home '~';
    ;

    %let dsout = home.css_passfail;
  %end;

  %* Establish PROC COMPARE METHOD and CRITERION *;
  %if %length(&criterion) > 0 %then %do;
    %if %datatyp(&criterion) = NUMERIC %then %let compmeth = METHOD=ABSOLUTE CRITERION=&criterion;
    %else %put WARNING: (&sysmacroname) Invalid, non-numeric value (&criterion) for CRITERION. Reveting to PROC COMPARE METHOD=EXACT.;
  %end;

  %if %length(&compmeth) = 0 %then %let compmeth = METHOD=EXACT;

  %* Ensure PFEXCODE fileref exists for writing/executing tests *;
  %let maxlrecl = 32767;

  %if not %sysfunc(fexist(PFEXCODE)) %then %do;
    filename PFEXCODE temp lrecl = &maxlrecl;
  %end;

  %*+-------------------------------------------------------------------------+*;
  %*| Store names of Positional and Keyword parms for building macro calls    |*;
  %*+-------------------------------------------------------------------------+*;
  %if %index(&dsin, .) %then %do;
    %let dslib = %upcase(%scan(&dsin, 1, .));
    %let dsnam = %upcase(%scan(&dsin,-1, .));
  %end;
  %else %do;
    %let dslib = WORK;
    %let dsnam = %upcase(&dsin);
  %end;

  proc sql noprint;
    select name into : pparms separated by ' '
    from dictionary.columns
    where libname = "&dslib" and
          memname = "&dsnam" and
          upcase(name) like "PPARM_%";

    %let ppcnt = &sqlobs;

    select name into : kparms separated by ' '
    from dictionary.columns
    where libname = "&dslib" and
          memname = "&dsnam" and
          upcase(name) like "KPARM_%";

    %let kpcnt = &sqlobs;
  quit;

  %let allparms = &pparms &kparms;
  %let apcnt    = %eval(&ppcnt + &kpcnt);

  %if &debug = Y %then %do;
    %put NOTE: (&sysmacroname) Positional parameters are [&pparms];
    %put NOTE: (&sysmacroname) Keyword parameters are    [&kparms];

    options ls=MAX;

    proc print data=&dsin;
    run;
  %end;

  options nocenter;

  *+-------------------------------------------------------------------------+*;
  *| Collect var info required below for conditional/dynamic logic           |*;
  *+-------------------------------------------------------------------------+*;
  %local len_te len_tes len_wrap len_call len_id len_dsc
         use_te use_tes use_wrap use_pdlim use_dsc;

  %let use_te    = 0;
  %let use_tes   = 0;
  %let use_wrap  = 0;
  %let use_dsc   = 0;
  %let use_pdlim = 0;

  data _null_;
    array lens[*] $ test_mac &allparms;

    dsid = open("&dsin");
    if dsid > 0 then do;

      if varnum(dsid, 'test_expect') > 0 then do;
         call symput('len_te', compress(put(varlen(dsid, varnum(dsid, 'test_expect')), 8.)));
         call symput('use_te', '1');
      end;

      if varnum(dsid, 'test_expect_sym') > 0 then do;
         call symput('len_tes', compress(put(varlen(dsid, varnum(dsid, 'test_expect_sym')), 8.)));
         call symput('use_tes', '1');
      end;

      if varnum(dsid, 'test_wrap') > 0 then do;
         call symput('len_wrap', compress(put(varlen(dsid, varnum(dsid, 'test_wrap')), 8.)));
         call symput('use_wrap', '1');
      end;

      if varnum(dsid, 'test_id') > 0 then
         call symput('len_id', compress(put(varlen(dsid, varnum(dsid, 'test_id')), 8.)));

      if varnum(dsid, 'test_dsc') > 0 then
         call symput('use_dsc', '1');

      if varnum(dsid, 'test_pdlim') > 0 then
         call symput('use_pdlim', '1');

      do idx = 1 to dim(lens);
        len_call + varlen(dsid, varnum(dsid, vname(lens[idx])));
      end;
      call symput('len_call', compress(put(len_call, 8.)));

    end;
    else put "WARNING: (&sysmacroname) Unable to open test data set &dsin. Expect trouble.";
  run;


  *+-------------------------------------------------------------------------+*;
  *| Create test result structure                                            |*;
  *| TEST_RESULT must be longer than TEST_EXPECT to catch truncation errors  |*;
  *+-------------------------------------------------------------------------+*;
  data &dsout (rename=(test_type=test_type_orig));
    set &dsin end=NoMore ;

    %if &use_te %then %do;
      attrib test_result length=$ %eval(2 * &len_te);
      retain test_result ' ';
    %end;

    %if not &use_pdlim %then %do;
      * Create default delimiter for multiple tests/macro vars, since not specified *;

      attrib test_pdlim length=$1 label='Delim of param vals for tests with mult macro calls (def=|)';
      retain test_pdlim '|';
    %end;

    %if not &use_dsc %then %do;
      * Create default description for tests, since not provided *;

      attrib test_dsc length=$25 label='Test Description';
      retain test_dsc '(no description provided)';
    %end;

    %if &use_wrap %then %do;
      attrib test_wrap_temp length=$&len_wrap label='Temp copy of TEST_WRAP for parsing';
      retain test_wrap_temp ' ';

      attrib test_wrap_next length=$&len_wrap label='Temp copy of TEST_WRAP for writing to PFEXCODE';
      retain test_wrap_next ' ';
    %end;

    %if &use_tes %then %do;
      * Standard var to store macro var results, 5x length of EXPECTED results to catch truncation *;

      attrib test_result_sym length=$ %eval(5 * &len_tes);
      retain test_result_sym ' ';
    %end;

    *+-------------------------------------------------------------+*;
    *| Determine max macro calls, MAC_CALLS, across all tests.     |*;
    *| Also number of macro calls per test, TEST_CALLS.            |*;
    *| Cycle through parms and count delimited vals, recording max |*;
    *+-------------------------------------------------------------+*;
    drop mac_calls ;
    retain mac_calls 1;

    test_calls = 1;

    %if &apcnt > 0 %then %do;
      array params [*] $ &allparms;
      attrib test_calls length=8 label='Number of macro calls in each test';

      test_calls = max(1
                       %do parm_idx = 1 %to &apcnt;
                       , countc(strip(params[&parm_idx]), test_pdlim)+1
                       %end;
                      );

      %if &use_wrap %then %do;
        * nb: Use TEST_WRAP to force number of calls, eg. for a no-param macro *;
        test_calls = max(test_calls, count(test_wrap, '_MACCALL', 'i'));
      %end;

      if test_calls > mac_calls then mac_calls = test_calls;
    %end;

    *+-------------------------------------------------------------+*;
    *| Separate post-processing instruct(s) for cleaner processing |*;
    *+-------------------------------------------------------------+*;
    drop len_post len_this len_dsc;
    retain len_post 1 len_dsc 1;

    test_type = upcase(test_type);
    if index(test_type, '-') then do;
      len_this = length(substr( test_type, index(test_type, '-')+1 ));
      if len_this > len_post then len_post = len_this;
    end;

    if length(test_dsc) > len_dsc then len_dsc = length(test_dsc);

    *+--------------------------------------+*;
    *| Store key attributes of these tests  |*;
    *+--------------------------------------+*;
    if NoMore then do;
      call symput('test_mac_name', compress(upcase(test_mac)));
      call symput('test_len_post', compress(put(len_post, 8.)));
      call symput('mac_calls_num', compress(put(mac_calls,8.)));
      call symput('len_dsc',       compress(put(len_dsc,  8.)));

      *+-------------------------------------------------------------------------+*;
      *| MACRO_CALL_<i> vars must sufficient to store longest poss macro call:   |*;
      *|   '%macro-name( max-len-pos-parm-1, ..., key-parm-1=max-len-kp1, ... )' |*;
      *+-------------------------------------------------------------------------+*;
      call symput('len_mac_calls', compress(put(35*&apcnt + 35*&kpcnt + 2*&len_call, 8.)));
    end;
  run;

  *+------------------------------------------------------------------------------+*;
  *| Create macro call structure required for these tests, based on lengths above |*;
  *+------------------------------------------------------------------------------+*;
  data &dsout (drop=test_type_orig);
    set &dsout;

    %do test_idx = 1 %to &mac_calls_num;
      attrib macro_call_&test_idx length=$&len_mac_calls;
    %end;

    attrib test_type length=$1              label='Test Type [M]acro var, [S]tring, [D]ata set, [I]n data step';
    attrib test_post length=$&test_len_post label='Post-proc func for String tests Comp[B]l, [C]ompress, [L]eft, [T]rim';

    if index(test_type_orig, '-') then test_post = substr( test_type_orig, index(test_type_orig, '-')+1 );
    test_type = substr(test_type_orig, 1, 1);

    *+--------------------------------------+*;
    *| Build required number of macro calls |*;
    *+--------------------------------------+*;
    %build_macro_calls;

  run;

  *+========================================================+*;
  *| Process unit tests one by one in order defined in dset |*;
  *+========================================================+*;
  data _null_;
    set &dsout nobs=test_num;
    call symput('test_num', compress(put(test_num, 8.)));
    STOP;
  run;

  %if &test_num > 0 %then %do test_idx = 1 %to &test_num;

    %* Store current GLOBAL syms for comparison after macro call *;
    %iniglobsyms;

    %if &debug = Y %then %put COMMENT (&sysmacroname): Begin test &test_idx of &test_num here.;

    *+============================================+*;
    *| Execute macro call & record inline results |*;
    *+============================================+*;
    data &dsout;
      set &dsout ;

      *+--------------------------------------------------------------------+*;
      *| Write test code to PFEXCODE file, include after DATA STEP boundary |*;
      *| NB: ALERTs to PFEXCODE file - use TEST_PUT_TEMP for macro-PUTs!!   |*;
      *+--------------------------------------------------------------------+*;
      file PFEXCODE lrecl = &maxlrecl;
      length test_put_temp $200;

      drop idx test_fail test_put_temp ;

      %if &use_wrap %then %do;
        drop test_wrap_temp test_wrap_next test_code;
        attrib test_code length=$ %eval(&mac_calls_num * &len_mac_calls + &len_wrap);
      %end;

      test_fail = 0;

      if _n_ = &test_idx then do;
        call symput('test_id', '%bquote('!!strip(test_id)!!')');
        call symput('test_dsc', '%bquote('!!strip(test_dsc)!!')');
        call symput('last_test', test_type);

        * Check that caller supplied required variables *;
        if test_type = 'M' and not &use_tes then test_fail = 1;
        if test_type in ('S' 'D' 'I') and not &use_te  then test_fail = 2;

        call symput('test_fail', compress(put(test_fail, 8.)));

        if test_fail then do;
          test_put_temp = '%put CRITICAL '!!"(&sysmacroname):";

          select (test_fail);
            when (1) test_put_temp = strip(test_put_temp)!! ' TEST_EXPECT_SYM is required for Macro var tests.';
            when (2) test_put_temp = strip(test_put_temp)!! ' TEST_EXPECT is required for this test.';
            otherwise test_put_temp= strip(test_put_temp)!! ' Unknown test failure.';
          end;

          test_put_temp = strip(test_put_temp)!!' Leaving test '!!quote(strip(test_id))!!' with TEST_TYPE '!!quote(strip(test_type))!!'.;';
          put test_put_temp;

          RETURN;
        end;

        *+------------------------------------+*;
        *| [M] Macro variable tests           |*;
        *| NB: only expecting TEST_EXPECT_SYM |*;
        *|     and not TEST_EXPECT            |*;
        if test_type = 'M' then do;

          %if &use_wrap %then %do;
            if not missing(test_wrap) then do;
              test_code = test_wrap;

              %do mac_calls_idx = 1 %to &mac_calls_num;
                test_code = tranwrd(test_code, "_MACCALL&mac_calls_idx._", strip(macro_call_&mac_calls_idx));
              %end;

              put test_code;
            end;
            else do;
              %do mac_calls_idx = 1 %to &mac_calls_num;
                if not missing(macro_call_&mac_calls_idx) then put macro_call_&mac_calls_idx;
              %end;
            end;
          %end;
          %else %do mac_calls_idx = 1 %to &mac_calls_num;
            if not missing(macro_call_&mac_calls_idx) then put macro_call_&mac_calls_idx;
          %end;

          %if &use_te %then %do;
            if not missing(test_expect) then do;
              test_put_temp = '%put ALERT '!!"(&sysmacroname)"!!': Unexpected TEST_EXPECT for Macro test '!!
                              quote(strip(test_id))!!' [ '!!quote(strip(test_expect))!!' ].;' ;
              put test_put_temp;
            end;
          %end;

        end;
        *| end [M] Macro variable tests      |*;
        *+-----------------------------------+*;

        *+-----------------------------------+*;
        *| [S] String tests                  |*;
        if test_type = 'S' then do;

          test_result = %do mac_calls_idx = 1 %to &mac_calls_num;
                          %if &mac_calls_idx = 1 %then resolve(macro_call_&mac_calls_idx);
                          %else !!' '!! resolve(macro_call_&mac_calls_idx);
                        %end;
                        ;

          %if &use_wrap %then %do;
            if not missing(test_wrap) then do;
              test_code = test_wrap;

              %do mac_calls_idx = 1 %to &mac_calls_num;
                test_code = tranwrd(test_code, "_MACCALL&mac_calls_idx._", strip(macro_call_&mac_calls_idx));
              %end;

              test_result = resolve(test_code);
            end;
          %end;

          if not missing(test_post) then do idx = 1 to length(test_post);
            if      substr(test_post, idx, 1) = 'B' then test_result = compbl(test_result);
            else if substr(test_post, idx, 1) = 'C' then test_result = compress(test_result);
            else if substr(test_post, idx, 1) = 'L' then test_result = left(test_result);
            else if substr(test_post, idx, 1) = 'T' then test_result = trim(test_result);
          end;

        end;
        *| end [S] String tests              |*;
        *+-----------------------------------+*;

        *+-----------------------------------+*;
        *| [D] Data set tests                |*;
        if test_type = 'D' then do;

          %do mac_calls_idx = 1 %to &mac_calls_num;
            if not missing(macro_call_&mac_calls_idx) then put macro_call_&mac_calls_idx;
          %end;

        end;
        *| end [D] Data set tests            |*;
        *+-----------------------------------+*;

        %if &use_wrap %then %do;
          *+-----------------------------------+*;
          *| [I] In data step tests            |*;

          if test_type = 'I' then do;
            test_wrap_temp = left(test_wrap);

            * Execute/consume user-specified wrapper code, resolving macro call placeholders *;
            do while (not missing(test_wrap_temp));

              * First execute any leading macro calls *;
              do while (upcase(test_wrap_temp) =: '_MACCALL');
                * compress out non-numeric chars to leave just the macro call index *;
                idx = input(compress(scan(upcase(test_wrap_temp), 1), '_MACAL'), 8.);

                %do mac_calls_idx = 1 %to &mac_calls_num;
                  if idx = &mac_calls_idx and not missing(macro_call_&mac_calls_idx) then
                     put macro_call_&mac_calls_idx;
                %end;

                test_wrap_temp = left(substr(test_wrap_temp, indexc(test_wrap_temp, ';', ' ')+1 ));
              end;

              * Next, execute any intermediate code prior to next macro call *;
              if index(upcase(test_wrap_temp), '_MACCALL') then do;
                test_wrap_next = substr(test_wrap_temp, 1, index(upcase(test_wrap_temp), '_MACCALL')-1);
                if not missing(test_wrap_next) then put test_wrap_next;

                test_wrap_temp = substr(test_wrap_temp, index(upcase(test_wrap_temp), '_MACCALL'));
              end;
              else do;
                if not missing(test_wrap_temp) then put test_wrap_temp;

                test_wrap_temp = ' ';
              end;

            end;

          end;
          else if test_type eq 'D' and not missing(test_wrap) then do;
            test_put_temp = '%put ALERT ' !! "(&sysmacroname):"!!
                            ' TEST_WRAP value is unexpected, ignored for TEST_ID '!!
                            quote(strip(test_id))!!' with TEST_TYPE '!!quote(strip(test_type))!!'.;';
            put test_put_temp;
          end;

          *| end [I] In data step tests        |*;
          *+-----------------------------------+*;
        %end;

        if test_type in ('D' 'I') then do;
          if index(test_expect, ' =') or index(test_expect, '= ') then do;
            test_put_temp = '%put ALERT '!!"(&sysmacroname):"!!
                            ' Extra spaces around equal sign(s) in TEST_EXPECT would produce ERRORs ...;' ;
            put test_put_temp;
            test_put_temp = '%put ALERT '!!"(&sysmacroname):"!!
                            ' ... Removing extra spaces around equal sign(s) to avoid ERRORs.;' ;
            put test_put_temp;

            do while (index(test_expect, ' =') or index(test_expect, '= '));
              test_expect = transtrn(test_expect, ' =', '=');
              test_expect = transtrn(test_expect, '= ', '=');
            end;
          end;

          call symput('test_expect', strip(test_expect));

          if missing(test_expect) then test_expect = substr('(not defined)', 1, min(&len_te, 13));
        end;

      end;
    run;

    *+============================================+*;
    *| Execute the test                           |*;
    *+============================================+*;

    %if &debug = Y and &use_wrap %then %do;

      *+-----------------------------------------------------------------+*;
      *| WRITE out the user-specified wrapper code, to support debugging |*;
      *| NB: handle line terminators for known file formats              |*;
      *|     http://vim.wikia.com/wiki/File_format                       |*;
      *+-----------------------------------------------------------------+*;
      data _null_;
        attrib fidtxt length=$&len_wrap label='Temp var to write out TEST_WRAP code';

        fid   = fopen('PFEXCODE', 'I');
        fidrc = fsep(fid, '0A0D', 'X');

        if fid > 0 then do;
          put ' ';
          put "NOTE: (&sysmacroname) > START of wrapped macro call (test &test_idx of &test_num) >";

          do while (fread(fid) = 0);
            do while (fget(fid, fidtxt) = 0);
              put "NOTE: (&sysmacroname)   " fidtxt;
              fidtxt = ' ';
            end;
          end;

          put "NOTE: (&sysmacroname) < END of wrapped macro call (debug = &debug) <";
          put ' ';

          fid = fclose(fid);
        end;
        else put "WARNING: (&sysmacroname) Unable to open PFEXCODE file for debug display!";
      run;

    %end;

    %if &debug = Y %then %put COMMENT (&sysmacroname): Execute code for test &test_idx of &test_num here (%trim(&test_id) - %trim(&test_dsc)).;

    %if &test_fail = 0 %then %do;
      %include PFEXCODE;
    %end;
    %else %put WARNING: (&sysmacroname) Skip execution of test &test_idx of &test_num due to test failure (&test_fail);

    *+============================================+*;
    *| Record results of in-data-step tests       |*;
    *+============================================+*;
    title;

    %if %eval(&last_test in D I) %then %do;
      %let test_result = ;

      %let dset_idx = 1;
      %do %while (%qscan(&test_expect, &dset_idx, %str( )) ne );
        %let dset_exp = %qscan( %qscan(&test_expect, &dset_idx, %str( )), 1, =);
        %let dset_res = %qscan( %qscan(&test_expect, &dset_idx, %str( )), 2, =);

        %let good_compare = 0;

        %if %qsubstr(&dset_exp,1,1) = %quote(-) %then %do;
          %* This is a data set that should NOT exist after the macro call *;
          %if not %sysfunc(exist(%substr(&dset_exp,2))) %then %do;
            %let test_result  = &test_result &dset_exp;
            %let good_compare = 1;
          %end;
          %else %do;
            %let test_result  = &test_result %substr(&dset_exp,2) EXISTS;
            %let good_compare = 0;
          %end;
        %end;
        %else %if %sysfunc(exist(&dset_exp)) & %sysfunc(exist(&dset_res)) %then %do;
          proc compare base=&dset_exp compare=&dset_res noprint &compmeth;
          quit;

          %if &sysinfo eq 0 %then %do;
            %let test_result  = &test_result &dset_exp=&dset_res;
            %let good_compare = 1;
          %end;
          %else %do;
            %put WARNING: (&sysmacroname) Proc Compare Failed (SYSINFO=&sysinfo)! Test &test_idx, Compare &dset_idx (%trim(&test_id) - %trim(&test_dsc)).;
            %let test_fail_title = %bquote(Test &test_idx, Compare &dset_idx (%trim(&test_id) - %trim(&test_dsc)));
            %let test_fail_title = %sysfunc(quote(FAIL - &test_fail_title));
            title &test_fail_title;

            %let test_result = &test_result &dset_exp NE &dset_res;

            proc compare base=&dset_exp compare=&dset_res listvars &compmeth;
            quit;
            title;
          %end;

          * Following successful comparison, delete this result data set *;
          * Otherwise, set aside resulting data set for user to review   *;
          %local res_lib res_nam res_fail;

          %if %index(&dset_res, .) %then %let res_lib = %scan(&dset_res, 1, .);
          %else %let res_lib = work;

          %let res_nam = %scan(&dset_res, -1, .);
          %let res_fail= failed_compare_&test_idx._&dset_idx;

          proc datasets nolist library=%lowcase(&res_lib);
            %if &good_compare %then %do;
              delete &res_nam;
            %end;
            %else %do;
              %put WARNING: (&sysmacroname) Saving result %upcase(&res_lib..&res_nam) as %upcase(&res_lib..&res_fail).;
              %if %sysfunc(exist(&res_lib..&res_fail)) %then %do;
                delete &res_fail;
                run;
              %end;

              change &res_nam = failed_compare_&test_idx._&dset_idx;
            %end;
          quit;

        %end;
        %else %do;
            %if %sysfunc(exist(&dset_exp)) %then %let test_result = &dset_exp;
            %else %let test_result = missing(&dset_exp);

            %if %sysfunc(exist(&dset_res)) %then %let test_result = &test_result NE &dset_res;
            %else %let test_result = &test_result NE missing(&dset_res);
        %end;

        %let dset_idx = %eval(&dset_idx + 1);
      %end;

      data &dsout;
        modify &dsout;

        if _n_ = &test_idx then do;
          test_result = "&test_result";

          if missing(test_result) then test_result = substr('(not defined)', 1, min(&len_te, 13));
        end;
      run;


    %end;

    %* Check GLOBAL syms for changes *;
    %endglobsyms;

  %end;


  *+======================+*;
  *| Report results       |*;
  *+======================+*;
  data &dsout;
    set &dsout nobs=TestTot end=NoMore;
    file print;

    drop overall pass fail idx;
    overall= ' ALL TESTS PASSED - ';

    %if &use_te %then %do;
      if test_expect = test_result then
        result = 'PASS';
      else
        result = 'FAIL';
    %end;

    %if &use_tes %then %do;
      if test_expect_sym = test_result_sym & result ne 'FAIL' then
        result = 'PASS';
      else
        result = 'FAIL';
    %end;

    if result = 'PASS' then pass + 1;
    else fail + 1;

    if result ^= 'PASS' then do;
      put result ' - ' test_id ', ' test_dsc $&len_dsc..;

      %if &use_te %then %do;
        put '  Expected: ' test_expect;
        put '  Returned: ' test_result;
      %end;

      %if &use_tes %then %do;
        put '  Expected Global Syms: ' test_expect_sym;
        put '  Returned Global Syms: ' test_result_sym;
      %end;
      overall = ' Passed - ';
    end;

    if NoMore then do;
      put / '### -----' / "###" / "### %upcase(&test_mac_name) Overall: " @;
      put overall pass @;
      if fail > 0 then put ' but  Failed - ' fail ' test(s)!' @;
      put / '###' / '### -----' / ' ';

      do idx = 1 to TestTot;
        set &dsout point=idx;
        put '   ' idx z3. '   ' test_id $&len_id.. test_dsc $&len_dsc..;
      end;
    end;
  run;

  %if &debug = Y %then %do;
    proc print data= &dsout;
    run;
  %end;

  %if %length(&savexml) > 0 %then %do;
    *--- STORE test results as XML ---*;
    libname savexml xml "&savexml";

    data savexml.css_passfail;
      set css_passfail;
    run;

    libname savexml clear;
  %end;

%mend util_passfail;


%macro build_macro_calls;

  %if &apcnt > 0 %then %do;
    attrib next_value length=$&len_call label='Temp var for building macro calls';
  %end;

  %do test_idx = 1 %to &mac_calls_num;
    if &test_idx <= test_calls then do;
      %if &test_idx = 1 %then %do;
        length put_text $100;
        drop put_text;
        put_text = compbl(test_id !!', '!! put(test_calls,8.-L) !!' call(s)');
        put "NOTE: (&sysmacroname) > " put_text;
      %end;

      put "NOTE: (&sysmacroname)  BUILDING MACRO CALL &test_idx";

      %if &apcnt > 0 %then %do;
        * Initiate macro call *;
        macro_call_&test_idx = '%'!! trim(left(test_mac)) !!'(';
        comma = '';

        %* Add positional & keyword parms *;
        %add_parms(&pparms, POS)
        %add_parms(&kparms, KEY)

        * Complete macro call *;
        macro_call_&test_idx = trim(left(macro_call_&test_idx)) !!')';

        * After construction of call, remove null placeholders *;
        if compress(macro_call_&test_idx) = '%'!! compress(test_mac) !!'()' then macro_call_&test_idx = '%'!! compress(test_mac);
        else macro_call_&test_idx = tranwrd(macro_call_&test_idx, '_NULLPARM_', '');

        drop next_value comma;
      %end;
      %else %do;
        macro_call_&test_idx = '%'!! trim(left(test_mac));
      %end;

      put "NOTE: (&sysmacroname) GENERATED MACRO CALL &test_idx " macro_call_&test_idx;

      if &test_idx = test_calls then
         put "NOTE: (&sysmacroname) <";

    end;
  %end;
%mend build_macro_calls;


%macro add_parms(parmlist, parmtype);
  %*+------------------------------------------------------+*;
  %*| PARMLIST: list of vars containing parameter settings |*;
  %*| PARMTYPE: POS (positional) or KEY (keyword) list     |*;
  %*+------------------------------------------------------+*;

  %local parmname vdx nxt nxtv;

  %let vdx = 1;
  %do %while (%qscan(&parmlist, &vdx, %str( )) ne );
    %let nxt  = %qscan(&parmlist, &vdx, %str( ));
    %let nxtv = %qsubstr(&nxt, %index(&nxt,_)+1);

    %if &debug = Y %then %put NOTE: (&sysmacroname) Next &parmtype parameter is [&nxtv];

    next_value = scan( &nxt, &test_idx, test_pdlim, 'M' );

    if not missing(next_value) then do;

      %if &parmtype=POS %then %do;
        macro_call_&test_idx = trim(left(macro_call_&test_idx)) !! compress(comma) !!' '!! trim(left(next_value));
      %end;
      %else %do;
        macro_call_&test_idx = trim(left(macro_call_&test_idx)) !! compress(comma) !!" &nxtv="!! trim(left(next_value));
      %end;

      comma=',';
    end;
    else if "&debug" = 'Y' then put "NOTE: (&sysmacroname) Skipping val &test_idx of " &nxt=;

    %let vdx = %eval(&vdx + 1);
  %end;

  if "&debug" = 'Y' then put "NOTE: (&sysmacroname) Added &parmtype parms to macro call &test_idx " macro_call_&test_idx;

%mend add_parms;


%macro iniglobsyms;

  * Build list of current GLOBAL macro syms, check for unexpected changes *;
  proc sql noprint;
    select unique name into : inisyms separated by ' '
    from dictionary.macros
    where scope = 'GLOBAL';
  quit;

  %let expsyms = ;
  %let endsyms = ;

%mend iniglobsyms;


%macro endglobsyms;

  %if &use_tes %then %do;
    * Record any global syms created by STRING TEST macro call *;
    data &dsout;
      modify &dsout ;

      drop dlim this_sym_name test_idx;
      attrib dlim length=$1;
      attrib this_sym_name length=$&len_tes label='Temp copy of TEST_EXPECT_SYM for parsing';

      if _n_ = &test_idx then do;
        test_idx = 1;
        if not missing(test_expect_sym) then do while (scan(test_expect_sym, test_idx, test_pdlim) ne ' ');
          this_sym_name = scan( scan(test_expect_sym, test_idx, test_pdlim), 1, '=');
          test_result_sym = left( trim(test_result_sym)
                                  !! dlim !! compress(scan(this_sym_name, 1, '='))
                                  !!'='!! symget(this_sym_name)
                                );

          *--- NB: DLIM is blank, first time through ---*;
          dlim = test_pdlim;

          call execute('%symdel '!!this_sym_name!!';');
          test_idx + 1;
        end;
      end;
    run;
  %end;

  * Build list of GLOB/LOCAL macro symbols after completing tests *;
  proc sql noprint;
    select unique name into : endsyms separated by ' '
    from dictionary.macros
    where scope = 'GLOBAL';
  quit;

  %local sidx snxt extra_endsyms extra_endsyms_count;

  %let sidx = 1;
  %let extra_endsyms_count = 0;

  %do %while (%scan(&inisyms &endsyms, &sidx, %str( )) ne );
    %let snxt = %scan(&inisyms &endsyms, &sidx, %str( ));

    %if not %sysfunc(indexw(&inisyms, &snxt, %str( ))) and
        not %sysfunc(indexw(&extra_endsyms, &snxt, %str( ))) %then %do;

        %let extra_endsyms = &extra_endsyms &snxt;
        %let extra_endsyms_count = %eval(&extra_endsyms_count + 1);

    %end;

    %let sidx = %eval(&sidx + 1);
  %end;

  %if &extra_endsyms_count > 0 %then %do;
    * Report any new & unexpected global macro vars *;
    %put WARNING: (&sysmacroname) UNEXPECTED Global sym(s) created - Test %cmpres(&test_id: &extra_endsyms);

    data _null_;
      set &dsout ;
      file print;

      if _n_ = &test_idx then do;
        put '  UNEXPECTED Global sym(s) created - Test ' test_id ": &extra_endsyms";
      end;
    run;

    %symdel &extra_endsyms;
  %end;

%mend endglobsyms;
