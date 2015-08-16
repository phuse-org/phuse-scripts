/***
  Qualification tests for PhUSE/CSS utility macro ASSERT_COMPLETE_REFDS

  SETUP:  Ensure that PhUSE/CSS utilities are in the AUTOCALL path

  TEST PLAN:
  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_assert_complete_refds.docx
          
***/


*--- SETUP ---*;

  %put WARNING: (TEST_ASSERT_COMPLETE_REFDS) User must ensure PhUSE/CSS utilities are in the AUTOCALL path.;

  /*** EXECUTE ONE TIME only as needed

    Ensure PhUSE/CSS utilities are in the AUTOCALL path
    NB: This line is not necessary if PhUSE/CSS utilities are in your default AUTOCALL paths

    OPTIONS mrecall sasautos=(%sysfunc(getoption(sasautos)) "C:\CSS\phuse-scripts\whitepapers\utilities");

  ***/


  *--- SAVE TEST RESULTS as XML filename  ---*;
  *--- NB: if this filename is blank, do NOT save xml test results ---*;

    %let XML_FILENAME = .\outputs_sas\testresults_assert_complete_refds.xml;


*--- Test 1 - Single key (merge) variable, either NUM or CHAR ---*;

  proc sql;
    create table my_test_definitions
      (  test_mac        char(32) label='Name of macro to test'
       , test_id         char(15) label='Test ID for ASSERT_COMPLETE_REFDS'
       , test_dsc        char(80) label='Test Description'
       , test_type       char(5)  label='Test Type (Macro var, String-<B|C|L|T>, Data set, In data step)'
       , pparm_dsets     char(50) label='Test values for the positional parameter PNUM'
       , pparm_keys      char(50) label='Test values for the keyword parameter KNUM'
       , test_expect     char(50) label='EXPECTED test results for each call to ASSERT_COMPLETE_REFDS'
       , test_expect_sym char(15) label='TEST_PDLIM-delim Name=Value pairs of EXPECTED global syms created'
      )
    ;

    insert into my_test_definitions
      values('assert_complete_refds', 'refds_01_a_i', 'single num key, single related dset, extra REF rec allowed',
             'D', 'my_reference my_related', 'my_key', '-fail_crds', 'continue=1')
      values('assert_complete_refds', 'refds_01_a_ii', 'single num key, single related dset, extra REL rec NOT allowed',
             'D', 'my_reference my_related_extra', 'my_key', 'exp_fail_crds_1aii=fail_crds', 'continue=0')
      values('assert_complete_refds', 'refds_01_b_i', 'single char key, single related dset, extra REF rec allowed',
             'D', 'my_reference_c my_related_c', 'my_char_key', '-fail_crds', 'continue=1')
      values('assert_complete_refds', 'refds_01_b_ii', 'single char key, single related dset, extra REL rec NOT allowed',
             'D', 'my_reference_c my_related_extra_c', 'my_char_key', 'exp_fail_crds_1bii=fail_crds', 'continue=0')

    ;
  quit;

  *-- Test 1 A - Single NUM  key (merge) variable ---*;
  *-- Test 1 B - Single CHAR key (merge) variable ---*;

    *-- Test 1.a.i - Reference dset CAN have extra record with NUM key 2.003           --*;
    *-- Test 1.b.i - Reference dset CAN have extra record with CHAR key "Record 2.003" --*;
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

    *-- Test 1.a.ii - Related dset CANNOT have extra record with NUM key 1.5           --*;
    *-- Test 1.b.ii - Related dset CANNOT have extra record with CHAR key "Record 1.5" --*;
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

  *-- EXPECT assert_complete_refds macro to create FAIL_CRDS data sets with this structure/content --*;
  *-- (for successful assertions, Tests 1.a.i and 1.b.i, macro does NOT create dset FAIL_CRDS)     --*;

    data exp_fail_crds_1aii;
      my_key=1.5;   found_ds1=0; found_ds2=1; output;
    run;

    data exp_fail_crds_1bii;
      length my_char_key $15;
      my_char_key='Record 1.5';   found_ds1=0; found_ds2=1; output;
    run;

        proc datasets library=WORK memtype=DATA nolist nodetails;
          delete _ALL_;
        quit;


*--- Test 2 - Multiple-keys, Three related data sets ---*;

    proc sql;

      insert into my_test_definitions
        values('assert_complete_refds', 'refds_02_a', 'multiple-key, three related dsets, extra REF rec allowed',
               'D', 'my_ref_2 my_lb my_vs my_ecg', 'num_key key_char key3', '-fail_crds', 'continue=1')
        values('assert_complete_refds', 'refds_02_b', 'multiple-key, three related dsets, extra REL rec NOT allowed',
               'D', 'my_ref_2 my_lb_ext my_vs_ext my_ecg_ext', 'num_key key_char key3', 'exp_fail_crds_2b=fail_crds', 'continue=0')

      ;
    quit;


  *-- Test 2 A - REFerence dset CAN have extra record with key num_key = 2.003, or key_char = 'Record A', or key3 = 'Subrec 2.003' --*;
  *-- Test 2 B - RELated dsets can NOT have extra records num_key = 1.5, or key_char = 'Rec D', or key3 = 'Subrec 400'             --*;

    data my_ref_2;
      do num_key = 0.001, 1.002, 2.003, 3.004;
        do key_char = 'Record A', 'Record B', 'Record C';
          do key3 = 'Subrec 0.001', 'Subrec 1.002', 'Subrec 2.003';
            detail_a = 'Detail A for '!!trim(put(num_key, best8.-L))!!' and '!!trim(key_char);
            detail_b = 'Detail B for '!!trim(key_char)!!' and '!!trim(key3);
            OUTPUT;
          end;
        end;
      end;
    run;

    data my_lb  my_lb_ext
         my_vs  my_vs_ext
         my_ecg my_ecg_ext;
      do num_key = 0.001, 1.002, 3.004;
        do key_char = 'Record B', 'Record C';
          do key3 = 'Subrec 0.001', 'Subrec 1.002';
            detail_a = 'LAB A for '!!trim(put(num_key, best8.-L))!!' and '!!trim(key_char);
            detail_b = 'LAB B for '!!trim(key_char)!!' and '!!trim(key3);
            if ranuni(61475) < 0.9 then OUTPUT my_lb my_lb_ext;

            detail_a = 'VS A for '!!trim(put(num_key, best8.-L))!!' and '!!trim(key_char);
            detail_b = 'VS B for '!!trim(key_char)!!' and '!!trim(key3);
            if ranuni(56147) < 0.9 then OUTPUT my_vs my_vs_ext;

            detail_a = 'ECG A for '!!trim(put(num_key, best8.-L))!!' and '!!trim(key_char);
            detail_b = 'ECG B for '!!trim(key_char)!!' and '!!trim(key3);
            if ranuni(75614) < 0.9 then OUTPUT my_ecg my_ecg_ext;
          end;
        end;
      end;

      num_key = 1.5;   key_char = 'Record B'; key3 = 'Subrec 0.001'; 
      detail_a = 'INVALID lab for 1.5 and Record B'; detail_b = 'INVALID lab for Record B and Subrec 0.001';
      OUTPUT MY_LB_EXT;

      num_key = 1.002; key_char = 'Rec D';    key3 = 'Subrec 1.002'; 
      detail_a = 'INVALID lab for 1.002 and Record D'; detail_b = 'INVALID lab for Record D and Subrec 1.002';
      OUTPUT MY_VS_EXT;

      num_key = 2.003; key_char = 'Record C'; key3 = 'Subrec 400';
      detail_a = 'INVALID lab for 2.003 and Record C'; detail_b = 'INVALID lab for Record C and Subrec 400';
      OUTPUT MY_ECG_EXT;

    run;

    %assert_unique_keys(my_lb, num_key key_char key3)
    %assert_unique_keys(my_vs, num_key key_char key3)
    %assert_unique_keys(my_ecg, num_key key_char key3)
    %assert_unique_keys(my_lb_ext, num_key key_char key3)
    %assert_unique_keys(my_vs_ext, num_key key_char key3)
    %assert_unique_keys(my_ecg_ext, num_key key_char key3)


  *-- EXPECT assert_complete_refds macro to create FAIL_CRDS data sets with this structure/content --*;
  *-- (for successful assertions, Tests 1.a.i and 1.b.i, macro does NOT create dset FAIL_CRDS)     --*;

    data exp_fail_crds_2b;
      num_key = 1.002; key_char = 'Rec D   '; key3 = 'Subrec 1.002'; found_ds1=0; found_ds2=0; found_ds3=1; found_ds4=0; output;
      num_key = 1.5;   key_char = 'Record B'; key3 = 'Subrec 0.001'; found_ds1=0; found_ds2=1; found_ds3=0; found_ds4=0; output;
      num_key = 2.003; key_char = 'Record C'; key3 = 'Subrec 400';   found_ds1=0; found_ds2=0; found_ds3=0; found_ds4=1; output;
    run;

*--- Execute & evaluate tests, and report & store test results ---*;
  %util_passfail (my_test_definitions, savexml=&xml_filename, debug=N);
