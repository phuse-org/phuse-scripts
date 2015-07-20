/***
  From input data set such as boxplot data, determin 
             
  INPUTS                                                                              
    DSET      data set containing the measurement values and normal range values. data set options OK.
              REQUIRED - positional
              Syntax:  (libname.)memname
              Example: CSS_PLOT_TP (where=( 0 <= timept < 7 ))
    MACVAR    global macro variable to create with resulting reference line values from DSET
              REQUIRED - positional
              Syntax:  (libname.)memname
              Example: CSS_ANNOTATE
    LOW_VAR   variable with low value of normal range, to test measured value 
                (NB: annotate values with Y_VAR < LOW_VAR)
              optional
              Syntax:  variable name from &DATASET
              Example: ANRLO 
    HIGH_VAR  variable with high value of normal range, to test measured value 
                (NB: annotate values with HIGH_VAR < Y_VAR)
              optional
              Syntax:  variable name from &DATASET
              Example: ANRHI
    REF_LINES Reference lines to display, e.g., Normal Range LOWs/HIGHs. 
                (See discussion in Central Tendency white paper.)
              optional
              Syntax:  NONE (default) or UNIFORM (only if LOW & HIGH are uniform) or 
                       NARROW (max LOW and min HIGH) or ALL (confusing to review)
              Example: UNIFORM

  OUTPUT
    Global macro var specified in MACVAR with numeric values for reference lines, as required by
    VREF= option in PROC SHEWHART BOXCHART statement:
    http://support.sas.com/documentation/cdl/en/qcug/63922/HTML/default/qcug_shewhart_a0000003887.htm

  Notes:
    Provide either LOW_VAR, HIGH_VAR or both. If you provide neither, macro returns a null macro variable.
  
  Author:          Dante Di Tommaso
***/

%macro util_get_reference_lines(dset,
                                macvar,
                                low_var=,
                                high_var=,
                                ref_lines=NONE)
       / minoperator;

  %if %symexist(&macvar) %then %symdel &macvar;
  %global &macvar;

  %local OK lo_vals hi_vals val_counts range_count;

  %let OK = %assert_dset_exist( %scan(&dset,1,%str( %()) );

  %if 1 = &OK and %length(&low_var) > 0 %then
      %let OK = %assert_var_exist(%scan(&dset,1,%str( %()), &low_var);
  
  %if 1 = &OK and %length(&high_var) > 0 %then
      %let OK = %assert_var_exist(%scan(&dset,1,%str( %()), &high_var);
  
  %*--- ALWAYS PROCESS 2 VARS to keep code simple, even if this mean processing just a LOW or HIGH reference twice ---*;
    %if %length(&low_var) > 0 and %length(&high_var) > 0 %then %let lhb = B;
    %else %if %length(&low_var) > 0 %then %do;
      %let lhb = L;
      %let high_var = &low_var;
    %end;
    %else %if %length(&high_var) > 0 %then %do;
      %let lhb = H;
      %let low_var = &high_var;
    %end;

  %if %length(&ref_lines) > 0 and
      %upcase(&ref_lines) in (UNIFORM NARROW ALL) %then %let ref_lines = %upcase(&ref_lines);
  %else %let ref_lines = NONE;


  %if 1 = &OK and 
      &lhb in (L H B) and 
      &ref_lines in (UNIFORM NARROW ALL) %then %do;

    proc sql noprint;
      select distinct &low_var, &high_var, count(&low_var)+nmiss(&low_var)
             into :lo_vals separated by ', ', :hi_vals separated by ', ', :val_counts separated by ' '
      from &dset
      where n(&low_var, &high_var) > 0
      group by &low_var, &high_var;
    quit;

    %let lo_vals = %quote(&lo_vals);
    %let hi_vals = %quote(&hi_vals);

    %let range_count = &sqlobs;

    %put NOTE: (UTIL_GET_REFERENCE_LINES) &range_count distinct reference ranges in &dset..;
    %put NOTE: (UTIL_GET_REFERENCE_LINES) LOW , HIGH (number of observations);
    %let idx = 1;
    %do %while (%scan(&val_counts, &idx, %str( )) ne );
      %if &lhb = L %then
        %put NOTE: (UTIL_GET_REFERENCE_LINES) %scan(&lo_vals, &idx, %str(, )) , --- (%scan(&val_counts, &idx, %str( )));
      %if &lhb = H %then
        %put NOTE: (UTIL_GET_REFERENCE_LINES) --- , %scan(&hi_vals, &idx, %str(, )) (%scan(&val_counts, &idx, %str( )));
      %if &lhb = B %then
        %put NOTE: (UTIL_GET_REFERENCE_LINES) %scan(&lo_vals, &idx, %str(, )) , %scan(&hi_vals, &idx, %str(, )) (%scan(&val_counts, &idx, %str( )));

      %let idx=%eval(&idx+1);
    %end;
    %put NOTE: (UTIL_GET_REFERENCE_LINES) If you see duplicate values, check the HEX value of your data.;

    %*--- DETERMINE which of these non-missing reference lines to draw ---*;
      %if &range_count > 0 %then %do;
        %if &ref_lines = UNIFORM %then %do;
          %*--- If multiple reference ranges, then draw NONE ---*;
          %if &range_count NE 1 %then %let ref_lines = NONE;
        %end;
        %else %if &ref_lines = NARROW %then %do;
          %*--- If multiple reference ranges, then draw max of LOW and min of HIGH ---*;
          %if &range_count > 1 %then %do;
            %let lo_vals = %sysfunc(max(%unquote(&lo_vals)));
            %let hi_vals = %sysfunc(min(%unquote(&hi_vals)));
            %let range_count = 1;
          %end;
        %end;
      %end;
      %else %let ref_lines = NONE;

    %*--- CREATE macro var with user-specified reference line values ---*;
      %if &ref_lines ne NONE %then %do;

        *--- Use data step and sort to clean up this list of reference lines (Unique, sorted Ascending) ---*;
        data grl_temp;
          do val = %if &lhb = B %then &lo_vals, &hi_vals ;
                   %else %if &lhb = L %then &lo_vals ;
                   %else %if &lhb = H %then &hi_vals ;
                   ;
            OUTPUT;
          end;
        run;

        proc sql noprint;
          select distinct val into :&macvar separated by ' '
          from grl_temp
          where not missing(val)
          order by val;
        quit;
        %let &macvar = &&&macvar;

        proc datasets library=WORK memtype=DATA nolist nodetails;
          delete grl_temp;
        quit;
      %end;
      %else %do;
        %let &macvar=;
        %put NOTE: (UTIL_GET_REFERENCE_LINES) Non-uniform reference limits detected, so suppressing reference lines.;
      %end;
      
    %put NOTE: (UTIL_GET_REFERENCE_LINES) Successfully created macro var %upcase(&MACVAR) with reference values (&&&MACVAR).;
  %end;
  %else %if 0 = &OK %then %do;

    %put ERROR: (UTIL_GET_REFERENCE_LINES) Unable to determine reference lines based on parameters provided. See log messages.;

  %end;

%mend util_get_reference_lines;
