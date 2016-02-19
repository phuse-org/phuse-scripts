/*** HEADER

  Create new, derived post-baseline records for subjects with some non-missing Baseline and Post-baseline value.
  Flag records 

  INPUTS:
    DS      Name of ADaM data with non-missing baseline and post-baseline measures in AVAL.
            Program expects these ADaM variables:
              * TRTSDT  treatment start date
              * ADT     analysis date for measurement
              * AVAL    analysis measurement
              * AVISIT  analysis visit name
            ==> "ADT <= TRTSDT" identifies Baseline obs. Otherwise handled as Post-baseline obs.
            REQUIRED positional
            Syntax:  one- or two-level data set name
            Example: ADVS or WORK.ADVS

    C_MODE  LAST, MIN or MAX, to specify which Baseline & Post-baseline value to flag
            REQUIRED positional
            Syntax: case INsensitive keyword from 3 valid options

    FLVAR   Name of flag variable to create on these derived records, with value 'Y'
            REQUIRED keyword
            Syntax: valid variable name, expect ADaM variable with 'FL' suffix. No default.

    GRPVARS List of variables on DS, for grouping obs (SQL GROUP BY clause)
            REQUIRED keyword
            Syntax:  space-delimited list of vars to determine grouping of input obs.
                     program return 1 record per group.
            Example: STUDYID USUBJID TRTPN PARAMCD ATPTN

    ORDVARS List of variables on DS, for ordering obs (SQL ORDER BY clause)
            This is useful to control which obs among duplicates are kept
            OPTIONAL keyword
            Syntax:  space-delimited list of vars to order obs, in addition to GRPVARS
            Example: AVISITN

    INCL    Additional variables from DS to include in the output data set (unmodified)
            OPTIONAL keyword
            Syntax: space-delimited list of variables on DS to carry along unmodified to DSOUT

    DSOUT   Name of ADaM to produce with new flags.
            OPTIONAL keyword
            Syntax:  one- or two-level data set name. Default is WORK.&DS._&C_MODE

    CLEANUP 0/1 boolean whether to cleanup intermediate data sets. For troubleshooting.
            OPTIONAL keyword
            Syntax: either 1 (yes, the default) to delete, or 0 (no) to leave intermediate data sets (WORK)

  OUTPUTS:
    DSOUT   Create this user-specified data set with POST-BASELINE OBS, new variables:
              * BASE  Baseline value, either LAST, MIN or MAX non-missing baseline measure
              * CHG   Change from BASE to AVAL, the LAST, MIN or MAX non-missing post-baseline measure
              * AVISIT & AVISITN with values Post-baseline(C_MODE) & 9999, respectively

  NOTES and TO-DO:
    Design-decision: Flagging obs across grouping variables should happen in isolation.
                     Derive these flags from an intermediate ADaM data set (rather than SDTM).
    

  REFERENCES:
    List any helpful references, whether to industry resources or SAS online documentation

  AUTHOR:
    Name of author or subsequent contributor
***/

%macro derive_lastminmax_measure(ds, c_mode, flvar=, grpvars=, ordvars=, incl=, dsout=, cleanup=1);

  %local lmm_func lmm_var avlen sql_grp sql_ord sql_inc;

  %let c_mode = %upcase(&c_mode);
  %if %length(&dsout) = 0 %then %let dsout = WORK.&ds._&c_mode.;

  %*--- Prepare SQL var lists, comma-separated. NB: When specified, ORD and INC lists include a leading comma ---*;
    %let sql_grp = %sysfunc(translate(&grpvars, %str(,), %str( )));
    %if %length(&ordvars) > 0 %then %let sql_ord = , %sysfunc(translate(&ordvars, %str(,), %str( )));
    %if %length(&incl) > 0 %then    %let sql_inc = , %sysfunc(translate(&incl, %str(,), %str( )));

  %let lmm_var  = AVAL;

  %if &c_mode = MIN %then %let lmm_func = MIN;
  %else %if &c_mode = MAX %then %let lmm_func = MAX;
  %else %do;
    %if &c_mode NE LAST %then %put WARNING: (DERIVE_LASTMINMAX_MEASURES) Invalid C_MODE value: &c_mode.. Defaulting to LAST (rather than MIN or MAX).;
    %let c_mode   = LAST;
    %let lmm_func = MAX;
    %let lmm_var  = ADT;
  %end;

  *--- Separate BASE and POST obs, to process separately, then recombine ---*;
    data lmm_base lmm_post;
      set &ds end=NoMore;
      if n(adt, trtsdt) < 2 then delete;
      if adt <= trtsdt then OUTPUT LMM_BASE;
      else OUTPUT LMM_POST;

      *--- Ensure that AVISIT length, below, does not truncate 'Post-baseline (LAST)', 20 chars ---*;
      if NoMore then call symput('avlen', put(vlength(avisit),best8.-L));
    run;

    %if &avlen < 20 %then %let avlen = 20;
    %else %let avlen = ;

  *--- Isolate one LAST/MIN/MAX baseline and post-baseline obs per patient, param, timepoint ---*;
    proc sql noprint;
      create table lmm_base_anl as
      select aval, adt, &sql_grp &sql_ord &sql_inc
      from lmm_base
      group by &sql_grp
      having &lmm_func(&lmm_var) = &lmm_var
      order by &sql_grp &sql_ord ;

      create table lmm_post_anl as
      select aval, adt, &sql_grp &sql_ord &sql_inc
      from lmm_post
      group by &sql_grp
      having &lmm_func(&lmm_var) = &lmm_var
      order by &sql_grp &sql_ord ;
    quit;

    *--- Eliminate any duplicate records that could result from derived records ---*;
      proc sort data=lmm_base_anl nodupkey;
        by &grpvars;
      proc sort data=lmm_post_anl nodupkey;
        by &grpvars;
      run;

  *--- Update BL and Post-BL obs with analysis baseline and related values ---*;
  *--- ONLY KEEP Subjects that have both BASELINE and POST-BASELINE values ---*;

    data lmm_base_anl;
      merge lmm_base_anl (in=in_base)
            lmm_post_anl (in=in_post keep=&grpvars);
      by &grpvars;

      if in_base;

      if not in_post then do;
        put 'WARNING: (DERIVE_LASTMINMAX_MEASURES) Omitting obs without a post-baseline measure, such as ' _all_;
        delete;
      end;

      avisit = "Baseline (&c_mode)";
      avisitn = 0;
      base = aval; 
      chg  = 0;
    run;

    data &dsout;
      %if %length(&avlen) > 0 %then length avisit $&avlen ;;

      merge lmm_post_anl (in=in_post)
            lmm_base_anl (in=in_base keep=&grpvars base);
      by &grpvars;

      if in_post;

      if not in_base then do;
        put 'WARNING: (DERIVE_LASTMINMAX_MEASURES) Omitting obs without a baseline measure, such as ' _all_;
        delete;
      end;

      avisit = "Post-baseline (&c_mode)"; 
      avisitn = 9999;
      chg = aval - base;

      attrib &flvar length=$1 label="Analysis Record Flag, Change derived from &c_mode Baseline to &c_mode Post-baseline";
      &flvar = 'Y';
    run;

  %if &cleanup %then %util_delete_dsets(lmm_base lmm_post lmm_base_anl lmm_post_anl);

%mend derive_lastminmax_measure;
