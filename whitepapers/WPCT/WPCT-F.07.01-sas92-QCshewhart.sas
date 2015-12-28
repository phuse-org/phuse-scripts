/*** HEADER

    Display:     Figure 7.1 Box plot - Measurements by Analysis Timepoint, Visit and Planned Treatment
    White paper: Central Tendency

    User Guide:     https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/CentralTendency-UserGuide.txt
    Macro library:  https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/utilities
    Specs:          https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/specification
    Test Data:      https://github.com/phuse-org/phuse-scripts/tree/master/data/adam/cdisc
    Sample Output:  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_sas/WPCT-F.07.01_Box_plot_DIABP_by_visit_for_timepoint_815.pdf

    Using this program:

      * See USER PROCESSING AND SETTINGS, below, to configure this program for your environment and data
      * Program will plot all visits, ordered by AVISITN, with maximum of 20 boxes on a page (default)
        + see user option MAX_BOXES_PER_PAGE, below, to change limit of 20 boxes per page
      * Program separately plots all parameters provided in PARAMCD
      * Measurements within each PARAMCD and ATPTN determine precision of statistical results
        + MEAN gets 1 extra decimal, STD DEV gets 2 extra decimals
        + see macro UTIL_VALUE_FORMAT to modify this behavior
      * If your treatment names are too long for the summary table, change TRTP 
        in the input data, and add a footnote that explains your short Tx codes

    TO DO list for program:

      * Q for Reviewer: Should we use ADSL data to report patients, not just obs in stats table?
          initial reviewer response in "No.", so removed code related to ADSL.
      * Complete and confirm specifications (see Outliers & Reference limit discussions, below)
          https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/specification
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

    1) REQUIRED - PhUSE/CSS Utilities macro library.
       These templates require the PhUSE/CSS macro utilities:
         https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/utilities
       User must ensure that SAS can find PhUSE/CSS macros in the SASAUTOS path (see EXECUTE ONE TIME, below)

    2) OPTIONAL - Subset measurement data, to limit resulting plots to specific
         - Parameters
         - Analysis Timepoints
         - Visits

    3) REQUIRED - Key user settings (libraries, data sets, variables and box plot options)
       M_LB:   Libname containing ADaM measurement data, such as ADVS.
               WORK by default, since step (2) creates the desired WORK subsets.
       M_DS:   Measuments data set, such as ADVS.
       M_VAR:  Variable in M_DS with measurements data, such as AVAL.
       LO_VAR: Variable in M_DS with LOWER LIMIT of reference range, such as ANRLO.
               Required to highlight values outside reference range (RED DOT in box plot), and reference lines
       HI_VAR: Variable in M_DS with UPPER LIMIT of reference range, such as ANRHI.
               Required to highlight values outside reference range (RED DOT in box plot), and reference lines
       JITTER: Y (default) or N, to jitter reference range outliers (red dots) in the boxplot.
               Amount of jitter is based on number of treatment groups (boxes within visit blocks).

       P_FL:  Population flag variable. 'Y' indicates record is in population of interest.
       A_FL:  Analysis Flag variable.   'Y' indicates that record is selected for analysis.

       MAX_BOXES_PER_PAGE:
             Maximum number of boxes to display per plot page (see "Notes", above)

       REF_LINES:
             Option to specify which Normal Range reference lines to include in box plots
             <NONE | UNIFORM | NARROW | ALL | numeric-value(s)> See discussion in Central Tendency White Paper 
             NONE    - default. no reference lines on box plot
             UNIFORM - preferred alternative to default. Only plot LOW/HIGH ref lines if uniform for all obs
             NARROW  - display only the narrow normal limits: max LOW, and min HIGH limits
             ALL     - discouraged since displaying ALL reference lines confuses review our data display
             numeric-values - space-delimited list of reference line values, such as a 0 reference line for displays of change.

       OUTPUTS_FOLDER:
             Location to write PDF outputs (WITHOUT final back- or forward-slash)

  ************************************
  *** user processing and settings ***
  ************************************/


    %put WARNING: (WPCT-F.07.01) User must ensure PhUSE/CSS utilities are in the AUTOCALL path.;

    /*** 1) PhUSE/CSS utilities in autocall paths (see "Macro Library", above)

      EXECUTE ONE TIME only as needed
      NB: The following line is necessary only when PhUSE/CSS utilities are NOT in your default AUTOCALL paths

      OPTIONS sasautos=(%sysfunc(getoption(sasautos)) "C:\CSS\phuse-scripts\whitepapers\utilities");

    ***/


    /*** 2a) ACCESS data, by default PhUSE/CSS test data, and create WORK copy.                ***/
    /***     NB: If remote access to test data files does not work, see local override, below. ***/
      %util_access_test_data(advs)

      *--- NB: OFFLINE CSS/PhUSE test data, override remote access by providing a local path ---*;
        %* %util_access_test_data(advs, local=C:\CSS\phuse-scripts\data\adam\cdisc\) ;


    /*** 2b) USER SUBSET of data, to limit number of box plot outputs, and to shorten Tx labels ***/

      data advs_sub (rename=(trtp_short=trtp));
        set work.advs;
        where (paramcd in ('DIABP') and atptn in (815)) or 
              (paramcd in ('SYSBP') and atptn in (816));

        length trtp_short $6;
        select (trtp);
          when ('Placebo')              trtp_short = 'P';
          when ('Xanomeline High Dose') trtp_short = 'X-high';
          when ('Xanomeline Low Dose')  trtp_short = 'X-low';
          otherwise                     trtp_short = 'UNEXPECTED';
        end;

        drop trtp;
      run;


    %*--- 3) Key user settings ---*;

      %let m_lb   = work;
      %let m_ds   = advs_sub;

      %let m_var  = AVAL;
      %let lo_var = ANRLO;
      %let hi_var = ANRHI;

      %let jitter = Y;
      %let ref_lines = UNIFORM;

      %let p_fl = saffl;
      %let a_fl = anl01fl;

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
    goptions reset=all;
    ods show;

    %let ana_variables = STUDYID USUBJID &p_fl &a_fl TRTP TRTPN PARAM PARAMCD &m_var &lo_var &hi_var AVISIT AVISITN ATPT ATPTN;

    *--- Restrict analysis to SAFETY POP and ANALYSIS RECORDS (&a_fl) ---*;
      data css_anadata;
        set &m_lb..&m_ds (keep=&ana_variables);
        where &p_fl = 'Y' and &a_fl = 'Y';
      run;

    %*--- Global boolean symbol CONTINUE, used with macro assert_continue(), warns user of invalid environment. Processing should HALT. ---*;
      %let CONTINUE = %assert_depend(OS=%str(AIX,WIN,HP IPF),
                                     SASV=9.2+,
                                     vars=%str(css_anadata : &ana_variables),
                                     macros=assert_continue util_labels_from_var util_count_unique_values 
                                            util_value_format util_prep_shewhart_data
                                    );

      %assert_continue(After asserting the dependencies of this script)


  /*** GATHER INFO for data-driven processing
    Collect required information about these measurements:

    Number, Names and Labels of PARAMCDs - used to cycle through parameters that have measurements
      &PARAMCD_N count of parameters
      &PARAMCD_VAL1 to &&&PARAMCD_VAL&PARAMCD_N series of parameter codes
      &PARAMCD_LAB1 to &&&PARAMCD_LAB&PARAMCD_N series of parameter labels

    Number of planned treatments - used for handling treatments categories
      &TRTN
  ***/

    %*--- Parameters: Number (&PARAMCD_N), Names (&PARAMCD_NAM1 ...) and Labels (&PARAMCD_LAB1 ...) ---*;
      %util_labels_from_var(css_anadata, paramcd, param)

    %*--- Number of planned treatments: Set &TRTN from ana variable TRTP ---*;
      %util_count_unique_values(css_anadata, trtp, trtn)


  /*** BOXPLOT for each PARAMETER and ANALYSIS TIMEPOINT in selected data
    PROC SHEWHART creates the summary table of stats from "block" (stats) variables
                  and reads "phases" (visits) from a special _PHASE_ variable

    One box plot for each PARAMETER and ANALYSIS TIMEPOINT.
    By Visit and Planned Treatment.

    In case of many visits and planned treatments, each box plot will use multiple pages.

    CLEANUP = O blocks the macro from deleting temp data sets after the last parameter & timepoint loop

    TO DO: Confirm whether temp data sets should be explicitly deleted after each parameter & timepoint loop.
           Could a left-over temp data set interfer with a subsequent loop?
           Or are temp dsets always initialized within each loop?
  ***/

    %macro boxplot_each_param_tp(plotds=css_anadata, cleanup=1);

      %local pdx tdx;

      %do pdx = 1 %to &paramcd_n;

        /*** LOOP 1 *****************************************************
         *** Loop through each PARAMETER, working with ALL TIMEPOINTS ***
         ****************************************************************/
          data css_nextparam;
            set &plotds (where=(paramcd = "&&paramcd_val&pdx"));
          run;

        %*--- Y-AXIS alternative: Fix Y-Axis MIN/MAX based on all timepoints for PARAM. See Y-AXIS DEFAULT, below. ---*;
        %*   %util_get_var_min_max(css_nextparam, &m_var, aval_min_max)   *;

        %*--- Analysis Timepoints for this parameter: Num (&ATPTN_N), Names (&ATPTN_NAM1 ...) and Labels (&ATPTN_LAB1 ...) ---*;
          %util_labels_from_var(css_nextparam, atptn, atpt)


        %do tdx = 1 %to &atptn_n;

          /*** LOOP 2 ********************************************************************
           *** Loop through each TIMEPOINT for this parameter, working with ALL VISITS ***
           *** NB: PROC SORT here is REQUIRED in order to merge on STAT details, below ***
           *******************************************************************************/
            proc sort data=css_nextparam (where=(atptn = &&atptn_val&tdx))
                       out=css_nexttimept;
              by avisitn trtpn;
            run;

          %*--- Y-AXIS DEFAULT: Fix Y-Axis MIN/MAX based on this timepoint. See Y-AXIS alternative, above. ---*;
            %util_get_var_min_max(css_nexttimept, &m_var, aval_min_max)

          %*--- Number of visits for this parameter and analysis timepoint: &VISN ---*;
            %util_count_unique_values(css_nexttimept, avisitn, visn)

          %*--- Create format string to display MEAN and STDDEV to default sig-digs: &UTIL_VALUE_FORMAT ---*;
            %util_value_format(css_nexttimept, &m_var)


          *--- Calculate summary statistics, and merge onto measurement data for use as "block" variables ---*;
            proc summary data=css_nexttimept noprint;
              by avisitn trtpn;
              var &m_var;
              output out=css_stats (drop=_type_) 
                     n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
            run;

            *--- Reminder: PROC SHEWHART reads "phases" (visits) from a special _PHASE_ variable ---*;
            data css_plot (rename=(avisit=_PHASE_));
              merge css_nexttimept (in=in_paramcd)
                    css_stats (in=in_stats);
              by avisitn trtpn;
              label n      = 'n'
                    mean   = 'Mean'
                    std    = 'Std Dev'
                    min    = 'Min'
                    q1     = 'Q1'
                    median = 'Median'
                    q3     = 'Q3'
                    max    = 'Max';
            run;


          /*** Create TIMEPT var, Calculate visit ranges for pages
            TIMEPT variable controls the location of by-treatment boxes along the x-axis
            Create symbol BOXPLOT_TIMEPT_RANGES, a |-delimited string that groups visits onto pages
              Example of BOXPLOT_TIMEPT_RANGES: 0 <= timept < 7|7 <= timept < 12|

            NB: OUTPUT DSET of %util_prep_shewhart_data has _TP suffix.
          ***/

            %util_prep_shewhart_data(css_plot, 
                                     vvisn=avisitn, vtrtn=trtpn, vtrt=trtp, vval=&m_var,
                                     numtrt=&trtn, numvis=&visn,
                                     alsokeep=&lo_var &hi_var)

            %util_annotate_outliers(css_plot_tp, 
                                    css_annotate,
                                    x_var    = TIMEPT,
                                    y_var    = &m_var,
                                    low_var  = &lo_var,
                                    high_var = &hi_var,
                                    jitter   = &jitter,
                                    numtrt   = &trtn)

          *--- Graphics Settings - Default HSIZE and VSIZE are suitable for A4 and letter ---*;
            options orientation=landscape;
            goptions reset=all device=pdf;

            title     justify=left height=1.2 "Box Plot - &&paramcd_lab&pdx by Visit, Analysis Timepoint: &&atptn_lab&tdx";
            footnote1 justify=left height=1.0 'Box plot type=schematic, the box shows median, interquartile range (IQR, edge of the bar), min and max';
            footnote2 justify=left height=1.0 'within 1.5 IQR below 25% and above 75% (ends of the whisker). Values outside the 1.5 IQR below 25% and';
            footnote3 justify=left height=1.0 'above 75% are shown as outliers. Means plotted as different symbols by treatments.';
            axis1     value=none label=none major=none minor=none;
            axis2     order=( %util_axis_order(%scan(&aval_min_max,1), %scan(&aval_min_max,2)) );

          *--- ODS PDF destination (Traditional Graphics, No ODS or Listing output) ---*;
            ODS GRAPHICS OFF;
            ODS LISTING CLOSE;
            ods pdf author='PhUSE/CSS Standard Analysis Library'
                    subject='PhUSE/CSS Measures of Central Tendency'
                    title="Boxplot of &&paramcd_lab&pdx by Visit for Analysis Timepoint &&atptn_lab&tdx"
                    file="&outputs_folder\WPCT-F.07.01-sas92-QCshewhart_Box_plot_&&paramcd_val&pdx.._by_visit_for_timepoint_&&atptn_val&tdx...pdf";


          /*** LOOP 3 - FINALLY, A Graph ****************************
           *** - Multiple pages in case of many visits/treatments ***
           **********************************************************/
            %local vdx nxtvis;
            %let vdx=1;
            %do %while (%qscan(&boxplot_timept_ranges,&vdx,|) ne );
              %let nxtvis = %qscan(&boxplot_timept_ranges,&vdx,|);

              %util_get_reference_lines(css_plot_tp (where=( &nxtvis )),
                                        nxt_vrefs,
                                        low_var  =&lo_var,
                                        high_var =&hi_var,
                                        ref_lines=&ref_lines)

              proc shewhart data=css_plot_tp (where=( &nxtvis ));
                boxchart &m_var * timept (max q3 median q1 min std mean n trtp) = trtp /
                         annotate = css_annotate (where=( %sysfunc(tranwrd(&nxtvis, timept, x)) ))
                         boxstyle = schematic
                         notches
                         nolegend
                         ltmargin = 5
                         blockpos = 3
                         blocklabelpos = left
                         blocklabtype=scaled
                         blockrep
                         haxis=axis1
                         vaxis=axis2
                         %if %length(&nxt_vrefs) > 0 %then 
                           vref=&nxt_vrefs
                           cvref=RED
                         ;
                         idsymbol=square
                         idcolor=black
                         nolimits
                         readphase = all
                         phaseref
                         phaselabtype=scaled
                         phaselegend;

                label &m_var  = "&&paramcd_lab&pdx"
                      timept  = 'Visit'
                      trtp    = 'Treatment'
                      n       = 'n'
                      mean    = 'Mean'
                      std     = 'Std'
                      median  = 'Median'
                      min     = 'Min'
                      max     = 'Max'
                      q1      = 'Q1'
                      q3      = 'Q3';
                format mean %scan(&util_value_format, 1, %str( )) std %scan(&util_value_format, 2, %str( ));
              run;

              %let vdx=%eval(&vdx+1);
            %end; %* --- LOOP 3 - Pages of box plots, VDX ---*;

          *--- Release the PDF output file! ---*;
            ods pdf close;
            ods listing;

        %end; %*--- LOOP 2 - Time Points, TDX ---*;

      %end; %*--- LOOP 1 - Parameters, PDX ---*;


      *--- Clean up temp data sets required to create box plots ---*;
        %if &cleanup %then %util_delete_dsets(css_plot css_plot_tp css_nextparam css_nexttimept css_stats css_annotate);

    %mend boxplot_each_param_tp;

    %boxplot_each_param_tp;

  /*** END boxplotting ***/
