/*** HEADER

    Display:     Figure 7.6 Box plot - Measurements at Last/Min/Max Baseline and Last/Min/Max Post-baseline by Treatment and Analysis Timepoint, Multiple Studies
    White paper: Central Tendency

    User Guide:     https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/CentralTendency-UserGuide.txt
    Macro Library:  https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/utilities
    Specs:          https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/specification
    Test Data:      https://github.com/phuse-org/phuse-scripts/tree/master/data/adam/cdisc-split
    Sample Output:  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_sas/WPCT-F.07.06_Box_plot_DIABP_last_base_post_by_study_for_timepoint_815.pdf

    Using this program:

      * See USER PROCESSING AND SETTINGS, below, to configure this program for your environment and data
      * Program will plot all studies, ordered by STUDYID, with maximum of 20 boxes on a page (default)
        + see user option MAX_BOXES_PER_PAGE, below, to change limit of 20 boxes per page
      * Program separately plots all parameters provided in PARAMCD
      * Measurements within each PARAMCD and ATPTN determine precision of statistical results
        + MEAN gets 1 extra decimal, STD DEV gets 2 extra decimals
        + see macro UTIL_VALUE_FORMAT to modify this behavior
      * If your treatment names are too long for the summary table, abbreviate them
        in the input data, and add a footnote that explains your short Tx codes
        + This program contains custom code to shorted Tx labels in the PhUSE CS test data
        + See "2b) USER SUBSET of data", below

    NOTES:
      Design decision:
        * User must specify a baseline visit number, and a post-baseline visit number.
        * An alternative approach: User specifies an analysis flag that identifies exactly 1
          post-baseline obs per subject (per param, analysis timepoint), and a BASELINE var that contains
          the corresponding baseline. See for example WPCT-F.07.07.sas, which uses this approach.

    TO DO list for program:

      * Complete and confirm specifications (see Outliers & Reference limit discussions, below)
          https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/specification
      * For annotated RED CIRCLEs outside normal range limits
          UPDATE the test data so that default outputs have some IQR OUTLIER SQUAREs that are not also RED.
      * The footnote could dynamically describe any normal range lines that appear. See the Fig. 7.1 specifications.
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
       LO_VAR: Variable in M_DS with LOWER LIMIT of reference range, such as ANRLO.
               Required to highlight values outside reference range (RED DOT in box plot), and reference lines
       HI_VAR: Variable in M_DS with UPPER LIMIT of reference range, such as ANRHI.
               Required to highlight values outside reference range (RED DOT in box plot), and reference lines

       P_FL:  Population flag variable. 'Y' indicates record is in population of interest.
       A_FL:  Analysis Flag variable.   'Y' indicates BASELINE and POST-BASELINE obs that contain:
                * A non-missing measurement             (either LAST, MIN or MAX for the timepoint AVISITN)
                * including a non-missing baseline      (LAST, MIN or MAX to match the measurement)
                * and a non-missing chg from baseline   (based on the above baseline & post-baseline measurements)
          NB: Exactly 1 BL and 1 PBL measure for each STUDYID, TRTPN, USUBJID, PARAMCD, ATPTN.
          NB: AVISITN identifies Baseline (lesser value) from Post-baseline (greater values) measure.
              For an example, see the PhUSE CS derivation in ADaM/derive_lastminmax_measure.sas

       C_MODE: Change Mode label. This is merely a label that describes the obs flagged by user-specified A_FL
                * LAST: Default. Change from LAST baseline to LAST post-baseline analysis measurement
                * MIN:  Change from MIN baseline to MIN post-baseline analysis measurement
                * MAX:  Change from MAX baseline to MAX post-baseline analysis measurement

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


    %put WARNING: (WPCT-F.07.06) User must ensure PhUSE CS utilities are in the AUTOCALL path.;

    /*** 1) PhUSE CS utilities in autocall paths (see "Macro Library", above)

      EXECUTE ONE TIME only as needed
      NB: The following line is necessary only when PhUSE CS utilities are NOT in your default AUTOCALL paths

      OPTIONS sasautos=("C:\CSS\phuse-scripts\whitepapers\utilities" "C:\CSS\phuse-scripts\whitepapers\ADaM" %sysfunc(getoption(sasautos)));

    ***/


    /*** 2a) REMOTE ACCESS data, by default PhUSE CS test data, and create WORK copy.                ***/
    /***     NB: If remote access to test data files does not work, see local override, below. ***/
      %util_access_test_data(advs, folder=cdisc-split)

      *--- NB: LOCAL PhUSE CS test data, override remote access by providing a local path ---*;
        %* %util_access_test_data(advs, local=C:\CSS\phuse-scripts\data\adam\cdisc-split\) ;


    /*** 2b) USER SUBSET of data, to limit number of box plot outputs, and to shorten Tx labels ***/

      data advs_sub;
        set work.advs;
        where (paramcd in ('DIABP') and atptn in (815 817));

        attrib trtp_short length=$6 label='Planned Treatment, abbreviated';

        select (trtp);
          when ('Placebo')              trtp_short = 'P';
          when ('Xanomeline High Dose') trtp_short = 'X-high';
          when ('Xanomeline Low Dose')  trtp_short = 'X-low';
          otherwise                     trtp_short = 'UNEXPECTED';
        end;
      run;

      %*--- Use PhUSE CS derivation of LAST, MIN or MAX Post-Baseline measures, with Change from corresponding Baseline ---*;
        %let lmm = last;
        %derive_lastminmax_measure(advs_sub, &LMM, 
                                   flvars=anl02fl, 
                                   grpvars=studyid usubjid trtpn paramcd atptn, 
                                   ordvars=avisitn, 
                                   incl=trtp_short saffl param atpt anrlo anrhi,
                                   dsout=advs_&LMM)


    %*--- 3) Key user settings ---*;

      %let m_lb   = work;
      %let m_ds   = advs_&LMM;

      %let t_var  = trtp_short;
      %let tn_var = trtpn;
      %let m_var  = aval;
      %let lo_var = anrlo;
      %let hi_var = anrhi;

      %let p_fl = saffl;

      *--- C_MODE is a label for &A_FL, which identifies 1 Baseline and 1 Post-baseline obs for each STUDYID USUBJID PARAMCD ATPT ---*;
        %let c_mode = &LMM;
        %let a_fl = anl02fl;

      %let ref_lines = NARROW;

      %let max_boxes_per_page = 20;

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

    %let ana_variables = STUDYID USUBJID &p_fl &a_fl &t_var &tn_var PARAM PARAMCD &m_var &lo_var &hi_var AVISITN ATPT ATPTN;

    %*--- Global boolean symbol CONTINUE, used with macro assert_continue(), warns user of invalid environment. Processing should HALT. ---*;
      %let CONTINUE = %assert_depend(OS=%str(AIX,WIN,HP IPF),
                                     SASV=9.4M2,
                                     SYSPROD=,
                                     vars=%str(&m_lb..&m_ds : &ana_variables),
                                     macros=assert_continue util_labels_from_var util_count_unique_values 
                                            util_get_reference_lines util_proc_template util_get_var_min_max
                                            util_value_format util_boxplot_block_ranges util_axis_order util_delete_dsets,
                                     symbols=m_lb m_ds t_var tn_var m_var lo_var hi_var p_fl c_mode a_fl 
                                             ref_lines max_boxes_per_page outputs_folder
                                    );

      %assert_continue(After asserting the dependencies of this script)


    /*** Data Prep
      1. Restrict analysis to SAFETY POP (&p_fl) and ANALYSIS RECORDS (&a_fl)
      2. Replace AVISIT/AVISITN with values that distinguish BASE and POST values (as needed for box plot)
      3. Plot requires 'Pooled' data with UNIQUE USUBJID for across-study results
      4. Plot requires a Study-Visit variable for the X-Axis, to cluster boxes and stats
    ***/
      proc sort data=&m_lb..&m_ds (keep=&ana_variables 
                                   where=(&p_fl = 'Y' and &a_fl = 'Y'))
                 out=css_safana;

        by studyid &tn_var paramcd atptn usubjid avisitn;
      run;

      %let c_mode = %upcase(&c_mode);

      %*--- Expect non-missing measurements ---*;
        %let CONTINUE = %assert_var_nonmissing(css_safana, &m_var);
        %assert_continue(After restricting analysis data - No missing values for "&c_mode" measurements in %upcase(&m_var))

        data css_safana;
          set css_safana;
          by studyid &tn_var paramcd atptn usubjid avisitn;

          *--- Replace AVISIT and AVISITN with plot-specific values ---*;
            attrib avisit length=$4 label='BASE or POST, to match user-specified Baseline and Post-baseline visits';

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

          *--- Create a Normal Range Outlier variable, for scatter plot overlay ---*;
            if (2 = n(&m_var, &lo_var) and &m_var < &lo_var) or
               (2 = n(&m_var, &hi_var) and &m_var > &hi_var) then m_var_outlier = &m_var;
            else m_var_outlier = .;
        run;

      *--- Create Pooled data, so sort after individual studies ---*;
        data css_pooled;
          set css_safana
              css_safana (in=in_pool);
          if in_pool then do;
            *--- Leading hex-char 'A0'x forces 'Pooled' results to follow individual studies ---*;
            studyid = 'A0'x !! 'Pooled';
            substr(usubjid,1,1) = 'P';
          end;
        run;

      *--- Create STUDYVISITN with plot-specific DISCRETE VALUEs for X-Axis, based on Study ID and AVISIT ---*;
        proc sort data=css_pooled;
          by studyid avisitn &tn_var;
        run;

        data css_anadata;
          set css_pooled;
          by studyid avisitn &tn_var;

          attrib studyvisitn label='X-Axis discrete numeric values for plot, from (Study Seq).(Visit Seq)';
          if first.studyid then do;
            studyvisitn = floor(studyvisitn);
            studyvisitn + 1;
          end;
          if first.avisitn then studyvisitn + 0.1;
      run;


  /*** GATHER INFO for data-driven processing
    Collect required information about these measurements:

    Number, Names and Labels of PARAMCDs - used to cycle through parameters that have measurements
      &PARAMCD_N count of parameters
      &PARAMCD_VAL1 to &&&PARAMCD_VAL&PARAMCD_N series of parameter codes
      &PARAMCD_LAB1 to &&&PARAMCD_LAB&PARAMCD_N series of parameter labels

    Number of treatments - used for handling treatments categories
      &TRTN
  ***/

    %*--- Parameters: Number (&PARAMCD_N), Names (&PARAMCD_VAL1 ...) and Labels (&PARAMCD_LAB1 ...) ---*;
      %util_labels_from_var(css_anadata, paramcd, param)

    %*--- Number of treatments: Set &TRTN from ana variable T_VAR ---*;
      %util_count_unique_values(css_anadata, &t_var, trtn)


  /*** BOXPLOT for each PARAMETER and ANALYSIS TIMEPOINT in selected data

    One box plot for each PARAMETER and ANALYSIS TIMEPOINT.
    By Visit and Treatment.

    In case of many visits and treatments, each box plot will use multiple pages.

    UTIL_PROC_TEMPLATE parameters:
      TEMPLATE     Positional parameter, the name of the template to compile.
      DESIGNWIDTH  Default is 260mm, suitable for one full-page landscape Letter/A4 plot.
                   130mm is suitable for these 2 side-by-side plots.
      DESIGNHEIGHT Default is 170mm, suitable for one full-page landscape Letter/A4 plot.

    BOXPLOT_EACH_PARAM_TP parameters:      
      CLEANUP      Default is 1, delete intermediate data sets. 
                   Set to 0 (zero) to preserve temp data sets from the final loop.

  ***/

    %util_proc_template(phuseboxplot)

    %macro boxplot_each_param_tp(plotds=css_anadata, cleanup=1);

      %local pdx tdx ;

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

        %*--- Y-AXIS alternative: Fix Y-Axis MIN/MAX based on all timepoints for PARAM. See Y-AXIS DEFAULT, below. ---*;
        %*--- NB: EXTRA normal range reference lines could expand Y-AXIS range.                                    ---*;
        %*   %util_get_var_min_max(css_nextparam, &m_var, aval_min_max, extra=&nxt_reflines)   *;


        %do tdx = 1 %to &atptn_n;

          /*** LOOP 2 ********************************************************************
           *** Loop through each TIMEPOINT for this parameter, working with ALL VISITS ***
           *** NB: PROC SORT here is REQUIRED in order to merge on STAT details, below ***
           *******************************************************************************/
            proc sort data=css_nextparam (where=(atptn = &&atptn_val&tdx))
                       out=css_nexttimept;
              by studyid avisitn &tn_var;
            run;

          %*--- Y-AXIS DEFAULT: Set Y-Axis MIN/MAX based on this timepoint. See Y-AXIS alternative, above. ---*;
          %*--- NB: EXTRA normal range reference lines could expand Y-AXIS range.                          ---*;
            %util_get_var_min_max(css_nexttimept, &m_var, aval_min_max, extra=&nxt_reflines)

          %*--- Create format string to display MEAN and STDDEV to default sig-digs: &UTIL_VALUE_FORMAT ---*;
            %util_value_format(css_nexttimept, &m_var)

          %*--- Create macro variable BOXPLOT_BLOCK_RANGES, to subset studies into box plot pages ---*;
            %util_boxplot_block_ranges(css_nexttimept, blockvar=studyid, catvars=&tn_var);


          *--- Calculate summary statistics, KEEP LABELS of VISIT and TRT for plotting, below ---*;
            proc summary data=css_nexttimept noprint;
              by studyid avisitn &tn_var studyvisitn avisit &t_var;
              var &m_var;
              output out=css_stats (drop=_type_ _freq_) 
                     n=n mean=mean std=std median=median min=datamin max=datamax q1=q1 q3=q3;
            run;

            /***
              STACK statistics (do NOT merge) BELOW the plot data, one obs per TREATMENT/VISIT.
              NB: We need exactly ONE obs per timepoint and trt: AXISTABLE defaults to a SUM function
            ***/
            data css_plot;
              set css_nexttimept
                  css_stats;

              format mean %scan(&util_value_format, 1, %str( )) std %scan(&util_value_format, 2, %str( ));
            run;


          *--- Graphics Settings - Set defaults for all graphs ---*;
            options orientation=landscape;
            goptions reset=all;

            ods graphics on / reset=all;
            ods graphics    / border=no attrpriority=COLOR;

            title     justify=left height=1.2 "Box Plot - &&paramcd_lab&pdx at &c_mode Baseline and &c_mode Post-Baseline for Multiple Studies and Analysis Timepoint &&atptn_lab&tdx";
            footnote1 justify=left height=1.0 'Box plot type is schematic: the box shows median and interquartile range (IQR, the box height); the whiskers extend to the minimum';
            footnote2 justify=left height=1.0 'and maximum data points within 1.5 IQR of the lower and upper quartiles, respectively. Values outside the whiskers are shown as outliers.';
            footnote3 justify=left height=1.0 'Means are marked with a different symbol for each treatment. Red dots indicate measures outside the normal reference range.';
            footnote4 justify=left height=1.0 'Baseline and post-baseline blocks have different background colors. BASE = baseline, POST = post-baseline.';

            %let y_axis = %util_axis_order( %scan(&aval_min_max,1,%str( )), %scan(&aval_min_max,2,%str( )) );

          *--- ODS PDF destination (Traditional Graphics, No ODS or Listing output) ---*;
            ods listing close;
            ods pdf file="&outputs_folder\WPCT-F.07.06_Box_plot_&&paramcd_val&pdx.._&c_mode._base_post_by_study_for_timepoint_&&atptn_val&tdx...pdf"
                    notoc bookmarklist=none dpi=300
                    author="(&SYSUSERID) PhUSE CS Standard Analysis Library"
                    subject='PhUSE CS Measures of Central Tendency'
                    title="Boxplot of &&paramcd_lab&pdx at &c_mode Baseline and &c_mode Post-baseline for Multiple Studies and Analysis Timepoint &&atptn_lab&tdx"
                    ;


          /*** LOOP 3 - FINALLY, A Graph ****************************
           *** - Multiple pages in case of many visits/treatments ***
           **********************************************************/

            %local vdx nxtvis;
            %let vdx=1;
            %do %while (%qscan(&boxplot_block_ranges,&vdx,|) ne );
              %let nxtvis = %qscan(&boxplot_block_ranges,&vdx,|);

              proc sgrender data=css_plot (where=( %unquote(&nxtvis) )) template=PhUSEboxplot ;
                dynamic 
                        _MARKERS    = "&t_var"
                        _BLOCKLABEL = 'studyid' 
                        _XVAR       = 'studyvisitn' 
                        _YVAR       = "&m_var"
                        _YOUTLIERS  = 'm_var_outlier'

                        %if %length(&nxt_reflines) > 0 %then %do;
                          _REFLINES   = "%sysfunc(translate( &nxt_reflines, %str(,), %str( ) ))"
                        %end;

                        _YLABEL     = "&&paramcd_lab&pdx"
                        _YMIN       = %scan(&y_axis, 1, %str( ))
                        _YMAX       = %scan(&y_axis, 3, %str( ))
                        _YINCR      = %scan(&y_axis, 5, %str( ))
                        _PERIOD     = 'avisit'
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

              %let vdx=%eval(&vdx+1);
            %end; %* --- LOOP 3 - Pages of box plots, VDX ---*;

          *--- Release the PDF output file! ---*;
            ods pdf close;
            ods listing;

        %end; %*--- LOOP 2 - Time Points, TDX ---*;

      %end; %*--- LOOP 1 - Parameters, PDX ---*;


      *--- Clean up temp data sets required to create box plots ---*;
        %if &cleanup %then %util_delete_dsets(css_nextparam css_nexttimept css_stats css_plot);

    %mend boxplot_each_param_tp;

    %boxplot_each_param_tp;

  /*** END boxplotting ***/
