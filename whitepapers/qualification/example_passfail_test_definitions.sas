/***
  EXAMPLE of how to create a test-definition data set for UTIL_PASSFAIL to execute
  NB: DD published this macro at PhUSE 2011. The paper online provides additional detail
    http://www.lexjansen.com/phuse/2011/ad/AD04.pdf
***/


* TRIVIAL MACRO that simply adds 2 numbers together, returning the result in-line *;

%macro add2nums (pnum, knum=);
  %* return result in-line *;
  %local result;

  %if %length(&pnum) > 0 %then %let result = %sysevalf(&pnum + &knum);
  %else %let result = &pnum;

  &result
%mend add2nums;


proc sql;
  create table my_test_definitions
    ( test_mac  char(32)  label='Name of macro to test',
      test_id   char(12)  label='Test ID for ADD2NUMS',
      test_dsc  char(80)  label='Test Description',
      test_type char(10)  label='Test Type (Macro var, String-<B|C|L|T>, Data set, In data step)',
      pparm_pnam char(8)  label='Test values for the positional parameter PNUM',
      kparm_knum char(8)  label='Test values for the keyword parameter KNUM',
      test_expect char(8) label='EXPECTED test results for each call to ADD2NUMS',
      test_wrap char(50)  label='Wrapper code with _MACCALL<i>_ placeholders'
    )
  ;

  insert into my_test_definitions
    values('add2nums', 'a2n_001', 'add 2 positive numbers in-line', 'S', '2', '8', '10', ' ')
    values('add2nums', 'a2n_002', 'add 2 negative numbers in-line', 'S', '-4', '-6', '-10', ' ')
    values('add2nums', 'a2n_003', 'add a pos and a neg num in-line', 'S', '2', '-6', '-4', ' ')
    values('add2nums', 'a2n_004', 'multiple macro calls, in-line result', 'S', '2|-4|2', '8|-6|-6', '-4',
           '%eval(_MACCALL1_ + _MACCALL2_ + _MACCALL3_)')
  ;
quit;


%util_passfail (my_test_definitions, debug=Y);
%util_passfail (my_test_definitions, debug=N);
