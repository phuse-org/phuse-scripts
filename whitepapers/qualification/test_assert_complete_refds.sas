/***
  Qualification tests for PhUSE/CSS utility macro ASSERT_COMPLETE_REFDS

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST 1: Single-key checks, 2 data sets
    a. Check that fractional numeric keys work as expected
    b. Check that char keys work as expected
      i.  extra record in REFERENCE is OK
      ii. extra record in RELATED dset is NOT ok

  TEST 2: Multiple-key checks, multiple related data sets
    a. Mix of num and char keys
          
***/


*--- SETUP ---*;

  /*** EXECUTE ONE TIME only as needed

    Ensure PhUSE/CSS utilities are in the AUTOCALL path
    NB: This line is not necessary if PhUSE/CSS utilities are in your default AUTOCALL paths

    OPTIONS sasautos=(%sysfunc(getoption(sasautos)) "C:\CSS\phuse-scripts\whitepapers\utilities");

  ***/


proc sql;
  create table my_test_definitions
    ( test_mac    char(32) label='Name of macro to test',
      test_id     char(15) label='Test ID for ASSERT_COMPLETE_REFDS',
      test_dsc    char(80) label='Test Description',
      test_type   char(5)  label='Test Type (Macro var, String-<B|C|L|T>, Data set, In data step)',
      pparm_dsets char(50)  label='Test values for the positional parameter PNUM',
      pparm_keys  char(50)  label='Test values for the keyword parameter KNUM',
      test_expect char(50)  label='EXPECTED test results for each call to ASSERT_COMPLETE_REFDS'
    )
  ;

  insert into my_test_definitions
    values('assert_complete_refds', 'refds_01_a_i', 'single num key, single related dset, extra REF rec allowed',
           'D', 'my_reference my_related', 'my_key', '-fail_crds')
    values('assert_complete_refds', 'refds_01_a_ii', 'single num key, single related dset, extra REL rec NOT allowed',
           'D', 'my_reference my_related_extra', 'my_key', 'exp_fail_crds_1aii=fail_crds')
    values('assert_complete_refds', 'refds_01_b_i', 'single char key, single related dset, extra REF rec allowed',
           'D', 'my_reference_c my_related_c', 'my_char_key', '-fail_crds')
    values('assert_complete_refds', 'refds_01_b_ii', 'single char key, single related dset, extra REL rec NOT allowed',
           'D', 'my_reference_c my_related_extra_c', 'my_char_key', 'exp_fail_crds_1bii=fail_crds')
  ;
quit;


* Test 1 - reference and related data sets *;

    * Reference dset CAN have extra record 2.003 *;
      data my_reference (keep=my_key extra_ref_info)
           my_reference_c (keep=my_char_key extra_ref_info);
        do my_key = 0.001, 1.002, 2.003, 3.004;
          my_char_key    = 'Record '!!put(my_key, best8.-L);
          extra_ref_info = 'My extra info for key '!!put(my_key, best8.-L);
          output;
        end;
      run;

    data my_related (keep=my_key extra_rel_info)
         my_related_c (keep=my_char_key extra_rel_info);
      do my_key = 0.001, 1.002, 3.004;
        my_char_key    = 'Record '!!put(my_key, best8.-L);
        extra_rel_info = 'My extra info for key '!!put(my_key, best8.-L);
        output;

        if ranuni(6743) < 0.5 then do;
          extra_rel_info = 'Additional info for key '!!put(my_key, best8.-L);
          output;
        end;
      end;
    run;

    * Related dset CANNOT have extra record 1.5 *;
      data my_related_extra;
        set my_related end=NoMore;
        output;
        if NoMore then do;
            my_key = 1.5;
            extra_rel_info = 'No reference match!';
          output;
        end;
      run;

      data my_related_extra_c;
        set my_related_c end=NoMore;
        output;
        if NoMore then do;
            my_char_key = 'Record 1.5';
            extra_rel_info = 'No reference match!';
          output;
        end;
      run;

      data exp_fail_crds_1aii;
        my_key=1.5;   found_ds1=0; found_ds2=1; output;
        my_key=2.003; found_ds1=1; found_ds2=0; output;
      run;

      data exp_fail_crds_1bii;
        length my_char_key $15;
        my_char_key='Record 1.5';   found_ds1=0; found_ds2=1; output;
        my_char_key='Record 2.003'; found_ds1=1; found_ds2=0; output;
      run;


%util_passfail (my_test_definitions, debug=N);
