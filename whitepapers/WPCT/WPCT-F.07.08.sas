/*** HEADER

    Display:     Figure 7.8 Box plot - Last/Min/Max Baseline versus Post-baseline Measurements by Treatment and Analysis Timepoint, Multiple Studies
    White paper: Central Tendency

    User Guide:     https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/CentralTendency-UserGuide.txt
    Macro Library:  https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/utilities
    Specs:          https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/specification
    Test Data:      https://github.com/phuse-org/phuse-scripts/tree/master/data/adam/cdisc-split
    Sample Output:  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_sas/WPCT-F.07.08_ ... _timepoint_815.pdf

    Using this program:

      * Figure 7.8 is intended Integrated Summaries involving a large number of studies. In such cases, displaying by-study results 
        becomes unreasonable. Instead, pool studies and report Last, Min and Max Baseline vs. Last, Min and Max Post-baseline measures.

      * See USER PROCESSING AND SETTINGS, below, to configure this program for your environment and data
      * Program will plot all visits, ordered by AVISITN, with maximum of 20 boxes on a page (default)
        + see user option MAX_BOXES_PER_PAGE, below, to change limit of 20 boxes per page
      * Program separately plots all parameters provided in PARAMCD
      * Measurements within each PARAMCD and ATPTN determine precision of statistical results
        + MEAN gets 1 extra decimal, STD DEV gets 2 extra decimals
        + see macro UTIL_VALUE_FORMAT to modify this behavior
      * If your treatment names are too long for the summary table, abbreviate them
        in the input data, and add a footnote that explains your short Tx codes
        + This program contains custom code to shorted Tx labels in the PhUSE CS test data
        + See "2b) USER SUBSET of data", below

    TO DO list for program:

      * Reduce the title/footnotes font size, to match Fig. 7.1 and Fig. 7.2 (or increase those to match this Fig. 7.3)

      * Complete and confirm specifications (see Outliers & Reference limit discussions, below)
          https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/specification
      * The footnote could dynamically describe any normal range lines that appear. See the Fig. 7.1 specifications.
      * For annotated RED CIRCLEs outside normal range limits
          UPDATE the test data so that default outputs have some IQR OUTLIER SQUAREs that are not also RED.
      * LABS & ECG - ADaM VS/LAB/ECG domains have some different variables and variable naming conventions.
          - What variables are used for LAB/ECG box plots?
          - What visits/time-points are relevant to LAB/ECG box plots?
          - Handle all of these within one template program? 
            Or separate them (and accept some redundancy)?
          - NB: Currently vars like AVISIT, AVISITN, ATPT, ATPTN are hard-coded in this program

end HEADER ***/



  /************************************
   *** USER PROCESSING AND SETTINGS ***
   ************************************

    1) REQUIRED - PhUSE CS Utilities macro library.
       These templates require the PhUSE CS macro utilities:
         https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/utilities
       User must ensure that SAS can find PhUSE CS macros in the SASAUTOS path (see EXECUTE ONE TIME, below)

    2) OPTIONAL - Subset measurement data, to limit resulting plots to specific
         - Parameters
         - Analysis Timepoints
         - Visits

    3) REQUIRED - Key user settings (libraries, data sets, variables and box plot options)
       M_LB:   Libname containing ADaM measurement data, such as ADVS.
               WORK by default, since step (2) creates the desired WORK subset.
       M_DS:   Measuments data set, such as ADVS.

       T_VAR:  Variable in M_DS with the Treatment Name, such as TRTP, TRTA.
       TN_VAR: Variable in M_DS with the Treatment Number (display controls order), such as TRTPN, TRTAN.
       M_VAR:  Variable in M_DS with measurements data, such as AVAL.
       C_VAR:  Variable in M_DS with change-from-baseline data, such as CHG.

       LO_VAR: Variable in M_DS with LOWER LIMIT of reference range, such as ANRLO.
               Required to highlight values outside reference range (RED DOT in box plot), and reference lines
       HI_VAR: Variable in M_DS with UPPER LIMIT of reference range, such as ANRHI.
               Required to highlight values outside reference range (RED DOT in box plot), and reference lines

       OPTIONAL P-Value settings. Leave this REFERENCE TREATMENT blank to omit p-value from right-hand table.
         B_VAR:  Variable in M_DS with baseline measurements, such as BASE.
         REF_TRTN: Numeric value of TN_VAR for reference (comparator) treatment

       P_FL:  Population flag variable, such as SAFFL. 'Y' indicates record is in population of interest.

       ANALYSIS FLAGS: Define all macro vars. At least one must be non-missing.
                   NB: Each obs can only be flagged for 1 analysis: Last, Min or Max.
         A_LASTFL: Variable flagging LAST post-baseline measures. 'Y' identifies subject values for LAST baseline, LAST post-baseline, and CHANGE.
         A_MINFL:  Variable flagging MIN  post-baseline measures. 'Y' identifies subject values for MIN  baseline, MIN  post-baseline, and CHANGE.
         A_MAXFL:  Variable flagging MAX  post-baseline measures. 'Y' identifies subject values for MAX  baseline, MAX  post-baseline, and CHANGE.

       REF_LINES:
             Option to specify which Normal Range reference lines to include in box plots
             <NONE | UNIFORM | NARROW | ALL | numeric-value(s)> See discussion in Central Tendency White Paper 
             NONE    - No reference lines on box plot
             UNIFORM - Preferred alternative to default. Only plot LOW/HIGH ref lines if they are uniform for all measurements
             NARROW  - Default. Display only the narrow normal limits: max LOW, and min HIGH limits
             ALL     - Discouraged, since displaying ALL reference lines confuses review of data display
             numeric-values - space-delimited list of reference line values, such as a 0 reference line for displays of change.

       MAX_BOXES_PER_PAGE:
             Maximum number of boxes to display per plot page (see "Notes", above)

       OUTPUTS_FOLDER:
             Location to write PDF outputs (WITHOUT final back- or forward-slash)

  ************************************
  *** user processing and settings ***
  ************************************/


    %put WARNING: (WPCT-F.07.08) User must ensure PhUSE CS utilities are in the AUTOCALL path.;

    /*** 1) PhUSE CS utilities in autocall paths (see "Macro Library", above)

      EXECUTE ONE TIME only as needed
      NB: The following line is necessary only when PhUSE CS utilities are NOT in your default AUTOCALL paths

      OPTIONS sasautos=("C:\CSS\phuse-scripts\whitepapers\utilities" "C:\CSS\phuse-scripts\whitepapers\ADaM" %sysfunc(getoption(sasautos)));

    ***/


    /*** 2a) REMOTE ACCESS data, by default PhUSE CS test data, and create WORK copy.                ***/
    /***     NB: If remote access to test data files does not work, see local override, below. ***/
      %util_access_test_data(advs)

      *--- NB: LOCAL PhUSE CS test data, override remote access by providing a local path ---*;
        %* %util_access_test_data(advs, local=C:\CSS\phuse-scripts\data\adam\cdisc-split\) ;


    /*** 2b) USER SUBSET of data, to limit number of box plot outputs, and to shorten Tx labels ***/

      data advs_sub;
        set work.advs;
        where (paramcd in ('DIABP') and 
               atptn in (815 817) and 
               trtpn in (0 81));

        attrib trtp_short length=$6 label='Planned Treatment, abbreviated';

        select (trtp);
          when ('Placebo')              trtp_short = 'P';
          when ('Xanomeline High Dose') trtp_short = 'X-high';
          otherwise                     trtp_short = 'UNEXPECTED';
        end;
      run;

      %derive_lastminmax_measure(advs_sub, LAST MIN MAX, 
                                 flvars=anl12fl anl14fl anl16fl,
                                 grpvars=studyid usubjid trtpn paramcd atptn, 
                                 ordvars=avisitn, 
                                 incl=trtp_short saffl param atpt anrlo anrhi,
                                 dsout=advs_chg)


    %*--- 3) Key user settings ---*;

      %let m_lb   = work;
      %let m_ds   = advs_chg;

      %let t_var  = trtp_short;
      %let tn_var = trtpn;
      %let m_var  = aval;
      %let c_var  = chg;

      %let lo_var = anrlo;
      %let hi_var = anrhi;

      %let b_var  = base;
      %let ref_trtn = 0;

      %let p_fl = saffl;

      %let a_lastfl = anl12fl;
      %let a_minfl  = anl14fl;
      %let a_maxfl  = anl16fl;

      %let ref_lines = NARROW;

      %let max_boxes_per_page = 12;

      %let outputs_folder = C:\CSS\phuse-scripts\whitepapers\WPCT\outputs_sas;

  /*** end USER PROCESSING AND SETTINGS ***********************************
   *** RELAX.                                                           ***
   *** The rest should simply work, or alert you to invalid conditions. ***
   ************************************************************************
  ***/



  /*** SETUP & CHECK DEPENDENCIES
    Explain to user in case environment or data do not support this analysis

    Keep just those variables and records required for this analysis
    For details, see specifications at top
  ***/

    options nocenter mautosource mrecall mprint msglevel=I mergenoby=WARN ls=max ps=max;

    %let ana_variables = STUDYID USUBJID &p_fl &a_lastfl &a_minfl &a_maxfl &t_var &tn_var PARAM PARAMCD &m_var &c_var &b_var &lo_var &hi_var AVISITN ATPT ATPTN;

    %*--- Global boolean symbol CONTINUE, used with macro assert_continue(), warns user of invalid environment. Processing should HALT. ---*;
      %let CONTINUE = %assert_depend(OS=%str(AIX,WIN,HP IPF),
                                     SASV=9.4M2,
                                     SYSPROD=,
                                     vars=%str(&m_lb..&m_ds : &ana_variables),
                                     macros=assert_continue util_labels_from_var util_count_unique_values 
                                            util_get_reference_lines util_proc_template util_get_var_min_max
                                            util_value_format util_boxplot_block_ranges util_axis_order util_delete_dsets,
                                     symbols=m_lb m_ds t_var tn_var m_var c_var b_var lo_var hi_var ref_trtn p_fl a_lastfl a_minfl a_maxfl
                                             ref_lines max_boxes_per_page outputs_folder
                                    );

      %assert_continue(After asserting the dependencies of this script)


    /*** Data Prep
      1. Restrict analysis to SAFETY POP (&p_fl) and ANALYSIS OBS (&a_lastfl or &a_minfl or &a_maxfl)
      2. Plot requires a Change-type discrete variable for the X-Axis, to cluster boxes and stats
      3. Plot requires an X-Axis variable that follows Change-type and Period (BASE or POST).
         ==> NB: PhUSEboxplot GTL template requires all values, BASE and POST, in one column.
    ***/
      %macro null;
        /*--- Simplify dynamic processing, below, since user can specify 1, 2 or all 3 flags.
              Note the use of these symbols, later: If user did not supply a variable, resulting comparisons are 'N' = 'Y' (impossible).
              This should be easier to read (and write!) than a bunch of conditional logic for each potential flag variable.
        ---*/
        %if %length(&a_lastfl.&a_minfl.&a_maxfl) = 0 %then %put ERROR: (WPCT-F.07.08) All user-specified analysis flags are missing. Expect failure due to 0 obs.;
        %if %length(&a_lastfl) = 0 %then %let a_lastfl = 'N';
        %if %length(&a_minfl)  = 0 %then %let a_minfl  = 'N';
        %if %length(&a_maxfl)  = 0 %then %let a_maxfl  = 'N';
      %mend null;
      %null;

      data css_pooled;
        set &m_lb..&m_ds (keep=&ana_variables);
        where &p_fl = 'Y' and (&a_lastfl = 'Y' or &a_minfl = 'Y' or &a_maxfl = 'Y');

        *--- Create Change-type Name and Number vars, to groups boxes in plots ---*;
          attrib chgtype length=$22 label='Identify type of obs (measure, baseline & change) as Last, Min or Max';

          if &a_lastfl = 'Y' then do;
            chgtypen = 1;
            chgtype  = 'Last BASE to Last POST';
          end;
          else if &a_minfl = 'Y' then do;
            chgtypen = 2;
            chgtype  = 'Min BASE to Min POST';
          end;
          else if &a_maxfl = 'Y' then do;
            chgtypen = 3;
            chgtype  = 'Max BASE to Max POST';
          end;
  
        *--- Create a Normal Range Outlier variable, for scatter plot overlay ---*;
          if (2 = n(&m_var, &lo_var) and &m_var < &lo_var) or
             (2 = n(&m_var, &hi_var) and &m_var > &hi_var) then m_var_outlier = &m_var;
          else m_var_outlier = .;
      run;

      *--- Replace AVISIT and AVISITN with plot-specific text. NB: Expect exactly 2 visits / usubj, BL & P-BL ---*;
        proc sort data=css_pooled;
          by chgtypen &tn_var paramcd atptn usubjid avisitn;
        run;

        data css_pooled;
          set css_pooled;
          by chgtypen &tn_var paramcd atptn usubjid avisitn;

          attrib avisit label='BASE or POST, to match user-specified Baseline and Post-baseline visits';

          if first.usubjid and not last.usubjid then do;
            avisit = 'BASE';
            avisitn= 1;
          end;
          else if not first.usubjid and last.usubjid then do;
            avisit = 'POST';
            avisitn= 2;
          end;
          else do;
            if first.usubjid then put 'WARNING: (WPCT-F.07.08) Expecting exactly 2 visits (not 1) for ' &tn_var= usubjid= paramcd= atptn= avisitn=;
            else put 'WARNING: (WPCT-F.07.08) Unexpected extra visit for ' &tn_var= usubjid= paramcd= atptn= avisitn=;
            avisit = 'UNK';
            avisitn=99;
          end;
        run;

      *--- Create CHGTYPEVISITN with plot-specific DISCRETE VALUEs for X-Axis, based on CHGTYPE and AVISIT ---*;
        proc sort data=css_pooled;
          by chgtypen avisitn &tn_var;
        run;

        data css_anadata;
          set css_pooled;
          by chgtypen avisitn &tn_var;

          attrib chgtypevisitn label='X-Axis discrete numeric values for plot, from (Change Mode).(Visit Seq)';
          if first.chgtypen then do;
            chgtypevisitn = floor(chgtypevisitn);
            chgtypevisitn + 1;
          end;
          if first.avisitn then chgtypevisitn + 0.1;
      run;


  /*** GATHER INFO for data-driven processing
    Collect required information about these measurements:

    Number, Names and Labels of PARAMCDs - used to cycle through parameters that have measurements
      &PARAMCD_N count of parameters
      &PARAMCD_VAL1 to &&&PARAMCD_VAL&PARAMCD_N series of parameter codes
      &PARAMCD_LAB1 to &&&PARAMCD_LAB&PARAMCD_N series of parameter labels

  ***/

    %*--- Parameters: Number (&PARAMCD_N), Names (&PARAMCD_VAL1 ...) and Labels (&PARAMCD_LAB1 ...) ---*;
      %util_labels_from_var(css_anadata, paramcd, param)


  /*** BOXPLOT for each PARAMETER and ANALYSIS TIMEPOINT in selected data

    Two box plots per page for each PARAMETER and ANALYSIS TIMEPOINT.
    By Visit number and Treatment.

    In case of >2 treatments, each PARAM/TIMEPOINT will use multiple pages.

    UTIL_PROC_TEMPLATE parameters:
      TEMPLATE     Positional parameter, the name of the template to compile.
      DESIGNWIDTH  Default is 260mm, suitable for one full-page landscape Letter/A4 plot.
                   130mm is suitable for these 2 side-by-side plots.
      DESIGNHEIGHT Default is 170mm, suitable for one full-page landscape Letter/A4 plot.

    BOXPLOT_EACH_PARAM_TP parameters:      
      CLEANUP      Default is 1, delete intermediate data sets. 
                   Set to 0 (zero) to preserve temp data sets from the final loop.

  ***/

    %util_proc_template(phuseboxplot, designwidth=130mm)

    %macro boxplot_each_param_tp(plotds=css_anadata, cleanup=1);

      %local pdx tdx css_pval_ds;

      %do pdx = 1 %to &paramcd_n;

        /*** LOOP 1 *****************************************************
         *** Loop through each PARAMETER, working with ALL TIMEPOINTS ***
         ****************************************************************/
          data css_nextparam;
            set &plotds (where=(paramcd = "&&paramcd_val&pdx"));
          run;

        %*--- Analysis Timepoints for this parameter: Num (&ATPTN_N), Names (&ATPTN_VAL1 ...) and Labels (&ATPTN_LAB1 ...) ---*;
          %util_labels_from_var(css_nextparam, atptn, atpt)

        %*--- Create NXT_REFLINES: a list of reference lines for this parameter, across all timepoints ---*;
          %util_get_reference_lines(css_nextparam, nxt_reflines,
                                    low_var=&lo_var, high_var=&hi_var, ref_lines=&ref_lines)

        %*--- Y-AXIS DEFAULT: Fix Y-Axis MIN/MAX based on all timepoints for PARAM. See Y-AXIS DEFAULT, below. ---*;
        %*--- NB: EXTRA normal range reference lines could expand Y-AXIS range.                                    ---*;
          %util_get_var_min_max(css_nextparam, &m_var, aval_min_max, extra=&nxt_reflines)
          %util_get_var_min_max(css_nextparam, &c_var, chg_min_max)


        %do tdx = 1 %to &atptn_n;

          /*** LOOP 2 **************************************************************************
           *** Loop through each TIMEPOINT for this parameter, working with ALL Change Types ***
           *** NB: PROC SORT here is REQUIRED in order to merge on STAT details, below       ***
           *************************************************************************************/
            proc sort data=css_nextparam (where=(atptn = &&atptn_val&tdx))
                       out=css_nexttimept;
              by chgtypen avisitn &tn_var;
            run;

          %*--- Y-AXIS alternative: Set Y-Axis MIN/MAX based on this timepoint. See Y-AXIS alternative, above. ---*;
          %*--- NB: EXTRA normal range reference lines could expand Y-AXIS range (left-hand plot, observed values). ---*;
          %*  %util_get_var_min_max(css_nexttimept, &m_var, aval_min_max, extra=&nxt_reflines)   *;
          %*  %util_get_var_min_max(css_nexttimept, &c_var, chg_min_max)                         *;

          %*--- Create format string to display MEAN and STDDEV to default sig-digs: &UTIL_VALUE_FORMAT for measures, &CHG_VALUE_FORMAT for change ---*;
            %util_value_format(css_nexttimept, &m_var, sym=util_value_format)
            %util_value_format(css_nexttimept, &c_var, sym=chg_value_format)

          %*--- Create macro variable BOXPLOT_BLOCK_RANGES, to subset change-type/visit into box plot pages ---*;
            %util_boxplot_block_ranges(css_nexttimept, blockvar=chgtypen, catvars=avisitn &tn_var)


          *--- Calculate summary statistics for VALUEs and CHANGE. KEEP LABELS of CHANGE TYPE, AVISIT and TRT for plotting, below ---*;
            proc summary data=css_nexttimept noprint;
              by chgtypen avisitn &tn_var chgtype avisit &t_var chgtypevisitn;
              var &m_var;
              output out=css_stats (drop=_type_ _freq_) 
                     n=n mean=mean std=std median=median min=datamin max=datamax q1=q1 q3=q3;
            run;

            %local endpoint_definition;
            %let endpoint_definition = avisit = 'POST';

            proc summary data=css_nexttimept (where=(&endpoint_definition)) noprint;
              by chgtypen avisitn &tn_var chgtype avisit &t_var chgtypevisitn;
              var &c_var;
              output out=css_c_stats (drop=_type_ _freq_) 
                     n=c_n mean=c_mean std=c_std median=c_median min=c_datamin max=c_datamax q1=c_q1 q3=c_q3;
            run;


          %*--- Add ANCOVA p-values for Endpoint: CHG = BASE + TRT (if user specified a reference arm) ---*;
            %if %length(&b_var) > 0 and %length(&ref_trtn) > 0 %then %do;

              %let css_pval_ds = css_pvalues;

              ods select parameterestimates;
              ods output parameterestimates = &css_pval_ds;

              proc glm data=css_nexttimept;
                by chgtypen avisitn chgtypevisitn;
                where &endpoint_definition;
                class &tn_var (ref="&ref_trtn");
                model &c_var = &b_var &tn_var / solution;
              run; quit;

              *--- UPDATE CSS_C_STATS with p-values for active arms, at Endpoint visit ---*;
                data temp;
                  *--- We simply need the structure of these vars, for subsequent merge ---*;
                  set css_c_stats (keep=chgtypen avisitn chgtypevisitn &tn_var);
                  STOP;
                run;

                data &css_pval_ds;
                  set temp &css_pval_ds (keep=chgtypen avisitn chgtypevisitn parameter probt 
                                         rename=(probt=pval)
                                         where=(parameter=:"%upcase(&tn_var)"));
                  label pval="GLM ANCOVA p-value: Reference is %upcase(&tn_var) = &ref_trtn";
                  &endpoint_definition;
                  &tn_var = input(scan(parameter,-1,' '), best8.);
                run;

                proc sort data=&css_pval_ds;
                  by chgtypen avisitn &tn_var;
                run;

                data css_c_stats;
                  merge css_c_stats &css_pval_ds (keep=chgtypen avisitn &tn_var pval);
                  by chgtypen avisitn &tn_var;
                run;

                %util_delete_dsets(temp);
            %end;          


            /***
              STACK statistics (do NOT merge) BELOW the plot data, one obs per TREATMENT/VISIT.
              NB: We need exactly ONE obs per timepoint and trt: AXISTABLE defaults to a SUM function
            ***/
            data css_plot;
              set css_nexttimept
                  css_stats
                  css_c_stats;

              format mean %scan(&util_value_format, 1, %str( )) std %scan(&util_value_format, 2, %str( ));
              format c_mean %scan(&chg_value_format, 1, %str( )) c_std %scan(&chg_value_format, 2, %str( ));
            run;


          *--- Graphics Adjustments - Set defaults for all graphs, MISSING=' ' since most P-VALUEs are missing ---*;
            options orientation=landscape missing=' ';
            goptions reset=all;

            ods graphics on / reset=all;
            ods graphics    / border=no attrpriority=COLOR;

            title1    justify=left height=1.2 "Box Plot - &&paramcd_lab&pdx Last/Min/Max Baseline versus Last/Min/Max Post-baseline by Treatment";
            title2    justify=left height=1.2 "Analysis Timepoint: &&atptn_lab&tdx";
            footnote1 justify=left height=1.0 'Box plot type is schematic: the box shows median and interquartile range (IQR, the box height); the whiskers extend to the minimum and maximum data points';
            footnote2 justify=left height=1.0 'within 1.5 IQR of the lower and upper quartiles, respectively. Values outside the whiskers are shown as outliers. Means are marked with a different symbol for each treatment.';
            footnote3 justify=left height=1.0 'Red dots indicate measures outside the normal reference range. P-value is for the treatment comparison from ANCOVA model Change = Baseline + Treatment.';

            %let aval_axis = %util_axis_order( %scan(&aval_min_max,1,%str( )), %scan(&aval_min_max,2,%str( )) );
            %let chg_axis  = %util_axis_order( %scan(&chg_min_max,1, %str( )), %scan(&chg_min_max,2, %str( )) );

          *--- ODS PDF destination (Traditional Graphics, No ODS or Listing output) ---*;
            ods listing close;

            ods pdf file="&outputs_folder\WPCT-F.07.08_Box_plot_&&paramcd_val&pdx.._lastminmax_change_timepoint_&&atptn_val&tdx...pdf"
                    notoc bookmarklist=none columns=2 dpi=300 startpage=no 
                    author="(&SYSUSERID) PhUSE CS Standard Analysis Library"
                    subject='PhUSE CS Measures of Central Tendency'
                    title="Boxplot of &&paramcd_lab&pdx Last/Min/Max Baseline versus Last/Min/Max Post-baseline by Treatment for Analysis Timepoint &&atptn_lab&tdx"
                    ;


          /*** LOOP 3 - FINALLY, A Graph ****************************
           *** - Multiple pages in case of many visits/treatments ***
           **********************************************************/

            %local vdx nxtvis;
            %let vdx=1;
            %do %while (%qscan(&boxplot_block_ranges,&vdx,|) ne );
              %let nxtvis = %qscan(&boxplot_block_ranges,&vdx,|);

              %*--- After page 1, force a new page in the PDF (see ODS PDF option STARTPAGE=NO, above) ---*;
                %if &vdx > 1 %then %do;
                  ods pdf startpage=now;
                %end;

              *--- OBSERVED values (left plot) ---*;
                proc sgrender data=css_plot (where=( %unquote(&nxtvis) )) template=PhUSEboxplot ;
                  dynamic 
                          _TITLE      = 'Observed Values'
                          _MARKERS    = "&t_var"
                          _XVAR       = 'chgtypevisitn' 
                          _BLOCKLABEL = 'chgtype' 
                          _YVAR       = "&m_var"
                          _YOUTLIERS  = 'm_var_outlier'

                          %if %length(&nxt_reflines) > 0 %then %do;
                            _REFLINES   = "%sysfunc(translate( &nxt_reflines, %str(,), %str( ) ))"
                          %end;

                          _YLABEL     = "&&paramcd_lab&pdx"
                          _YMIN       = %scan(&aval_axis, 1, %str( ))
                          _YMAX       = %scan(&aval_axis, 3, %str( ))
                          _YINCR      = %scan(&aval_axis, 5, %str( ))
                          _N          = 'n'
                          _MEAN       = 'mean'
                          _STD        = 'std'
                          _DATAMIN    = 'datamin'
                          _Q1         = 'q1'
                          _MEDIAN     = 'median'
                          _Q3         = 'q3'
                          _DATAMAX    = 'datamax'
                          ;
                run;

              *--- CHANGE values (right plot) DO NOT DISPLAY baseline visit (always zero change) ---*;
                proc sgrender data=css_plot (where=( &endpoint_definition AND %unquote(&nxtvis) )) template=PhUSEboxplot ;
                  dynamic 
                          _TITLE      = 'Change from Baseline'
                          _MARKERS    = "&t_var"
                          _XVAR       = 'chgtypevisitn' 
                          _BLOCKLABEL = 'chgtype' 
                          _YVAR       = "&c_var"
                          _REFLINES   = "0"
                          _YLABEL     = "Change in &&paramcd_lab&pdx"
                          _YMIN       = %scan(&chg_axis, 1, %str( ))
                          _YMAX       = %scan(&chg_axis, 3, %str( ))
                          _YINCR      = %scan(&chg_axis, 5, %str( ))
                          _N          = 'c_n'
                          _MEAN       = 'c_mean'
                          _STD        = 'c_std'
                          _DATAMIN    = 'c_datamin'
                          _Q1         = 'c_q1'
                          _MEDIAN     = 'c_median'
                          _Q3         = 'c_q3'
                          _DATAMAX    = 'c_datamax'

                          %if %length(&b_var) > 0 and %length(&ref_trtn) > 0 %then %do;
                            _PVAL       = 'pval'
                          %end;

                          ;
                run;

              %let vdx=%eval(&vdx+1);
            %end; %* --- LOOP 3 - Pages of box plots, VDX ---*;

          *--- Release the PDF output file! ---*;
            ods pdf close;
            ods listing;

        %end; %*--- LOOP 2 - Time Points, TDX ---*;

      %end; %*--- LOOP 1 - Parameters, PDX ---*;


      *--- Clean up temp data sets required to create box plots ---*;
        %if &cleanup %then %util_delete_dsets(css_nextparam css_nexttimept &css_pval_ds css_stats css_c_stats css_plot);

    %mend boxplot_each_param_tp;

    %boxplot_each_param_tp;

  /*** END boxplotting ***/
