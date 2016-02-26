/*** HEADER

  Return dset with derived baseline & post-baseline obs for all subjects with some non-missing Baseline and Post-baseline value.
  Drop subjects without a non-missing Baseline or Post-baseline measure.

  Design decision: Return vertical data, which works well with GTL PhUSEboxplot template.
                   Baseline and Post-baseline values remain in AVAL in output dset.

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

    C_MODES Space-delimited list of available Change Modes: LAST, MIN and MAX
            Macro creates separate flags and sets of obs for each mode specified.
            REQUIRED positional
            Syntax: case INsensitive keyword from 3 valid options
                NB: Number of Change Modes MUST MATCH number of user-specified flag variables FLVARS.

    FLVARS  Name of flag variables, to create on these derived records, with value 'Y'
            REQUIRED keyword
            Syntax: valid variable name, expect ADaM variable with 'FL' suffix.
                NB: Number of flag variables MUST MATCH number of user-specified Change Modes.
                NB: If user does not specify some flag var name, macro creates non-CDISC var ANL<chg-mode>FL.

    GRPVARS List of variables on DS, for grouping obs (SQL GROUP BY clause)
            REQUIRED keyword
            Syntax:  space-delimited list of vars to determine grouping of input obs.
                     program returns 2 records per group: Baseline & Post-baseline values
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
            Syntax:  one- or two-level data set name. Default is WORK.&DS._CHGMODES

    CLEANUP 0/1 boolean whether to cleanup intermediate data sets. For troubleshooting.
            OPTIONAL keyword
            Syntax: either 1 (yes, the default) to delete, or 0 (no) to leave intermediate data sets (WORK)

  OUTPUTS:
    DSOUT   Create this user-specified data set with BASELINE and POST-BASELINE OBS, new variables:
              * BASE  Baseline value, either LAST, MIN or MAX non-missing baseline measure
              * CHG   Change from BASE to AVAL, the LAST, MIN or MAX non-missing post-baseline measure
              * AVISIT  with values "Baseline (C_MODE)" or "Post-baseline(C_MODE)"
              * AVISITN with values for each Change Mode & Visit, starting with 9911 (baseline) and 9912 (post-baseline).
                        Each Change Mode increments +10. (So visit nums for 2nd C_MODE are 9921 & 9922, respectively.)

  NOTES and TO-DO:
    Design-decision: Flagging obs across grouping variables should happen in isolation.
                     Derive these flags from an intermediate ADaM data set (rather than SDTM).
    

  REFERENCES:
    List any helpful references, whether to industry resources or SAS online documentation

  AUTHOR:
    Name of author or subsequent contributor
***/

%macro derive_lastminmax_measure(ds, c_modes, flvars=, grpvars=, ordvars=, incl=, dsout=, cleanup=1);

  %local lmm_func lmm_var avlen sql_grp sql_ord sql_inc idx nxtcm nxtflv;

  %let c_modes = %upcase(&c_modes);
  %if %length(&dsout) = 0 %then %let dsout = WORK.&ds._chgmodes;

  %*--- Prepare SQL var lists, comma-separated. NB: When specified, ORD and INC lists include a leading comma ---*;
    %let sql_grp = %sysfunc(translate(&grpvars, %str(,), %str( )));
    %if %length(&ordvars) > 0 %then %let sql_ord = , %sysfunc(translate(&ordvars, %str(,), %str( )));
    %if %length(&incl) > 0 %then    %let sql_inc = , %sysfunc(translate(&incl, %str(,), %str( )));

  *--- Separate BASE and POST obs, to process separately, then recombine ---*;
    data lmm_base lmm_post;
      set &ds end=NoMore;
      if n(adt, trtsdt) < 2 or missing(aval) then delete;

      if adt <= trtsdt then OUTPUT LMM_BASE;
      else OUTPUT LMM_POST;

      *--- Ensure that AVISIT length, below, does not truncate 'Post-baseline (LAST)', 20 chars ---*;
      if NoMore then call symput('avlen', put(vlength(avisit),best8.-L));
    run;

    %if &avlen < 20 %then %let avlen = 20;
    %else %let avlen = ;

  *--- Get structure for DSOUT from DS ---*;
    data &dsout;
      %if %length(&avlen) > 0 %then length avisit $&avlen ;;
      retain avisit ' ';
      set &ds (keep=&grpvars &ordvars &incl);
      STOP;
    run;

  %*--- Loop through each Change Mode requested ---*;
    %let idx = 1;

    %do %while (%scan(&c_modes,&idx,%str( )) ne );
      %let nxtcm = %scan(&c_modes,&idx,%str( ));
      %let nxtflv= %scan(&flvars,&idx,%str( ));

      %let lmm_var  = AVAL;

      %if &nxtcm = MIN %then %let lmm_func = MIN;
      %else %if &nxtcm = MAX %then %let lmm_func = MAX;
      %else %do;
        %if &nxtcm NE LAST %then %put WARNING: (DERIVE_LASTMINMAX_MEASURES) Invalid C_MODES value: &nxtcm.. Defaulting to LAST (rather than MIN or MAX).;
        %let nxtcm    = LAST;
        %let lmm_func = MAX;
        %let lmm_var  = ADT;
      %end;

      %if %length(&nxtflv) = 0 %then %let nxtflv = anl&nxtcm.fl;

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

          avisit = "Baseline (&nxtcm)";
          avisitn = 9900 + 10*&idx + 1;
          base = aval; 
          chg  = 0;
        run;

        data lmm_post_anl;
          %if %length(&avlen) > 0 %then length avisit $&avlen ;;

          merge lmm_post_anl (in=in_post)
                lmm_base_anl (in=in_base keep=&grpvars base);
          by &grpvars;

          if in_post;

          if not in_base then do;
            put 'WARNING: (DERIVE_LASTMINMAX_MEASURES) Omitting obs without a baseline measure, such as ' _all_;
            delete;
          end;

          avisit = "Post-baseline (&nxtcm)"; 
          avisitn = 9900 + 10*&idx + 2;
          chg = aval - base;
        run;

      *--- Update DSOUT with data for this Change Mode ---*;
        data &dsout;
          set &dsout (in=in_prior)
              lmm_base_anl 
              lmm_post_anl;

          if not in_prior then do;
            attrib &nxtflv length=$1 label="Analysis Record Flag, Change derived from &nxtcm Baseline to &nxtcm value in this timepoint";
            &nxtflv = 'Y';
          end;
        run;            

      %let idx=%eval(&idx+1);
    %end;

  %if &cleanup %then %util_delete_dsets(lmm_base lmm_post lmm_base_anl lmm_post_anl);

%mend derive_lastminmax_measure;
