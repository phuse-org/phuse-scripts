/*** HEADER

    Display:     Figure 7.1 Box plot - Measurements by Analysis Timepoint, Visit and Planned Treatment
    White paper: Central Tendency

    Specs:       https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/specification/WPCT-F.07.01_specs.yml
    Output:      https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_sas/WPCT-F.07.01_Box_plot_DIABP_by_visit_for_timepoint_815.pdf

    Using this program:

      * See USER PROCESSING AND SETTINGS, below, to configure this program for your environment and data
      * Program plots all visits, ordered by AVISITN, with maximum of 20 boxes on a page (default)
        + see user option MAX_BOXES_PER_PAGE, below, to change 20 per page
      * Program separately plots all parameters available in PARAMCD
      * Measurements within each PARAMCD and ATPTN determine precision of statistical results
        + MEAN gets 1 extra decimal, STD DEV gets 2 extra decimals
        + see macro UTIL_VALUE_FORMAT to adjust this behavior
      * If your treatment names are too long for the summary table, change TRTP 
        in the input data, and add a footnote that explains your short Tx codes

    TO DO list for program:

      * NB: Search for "TO DO" without quotes, for placeholders in the code
      * Complete and confirm specifications (see Outliers & Reference limit discussions, below)
          https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/specification
      * RED color for values outside pre-defined reference limits
          - See discussion in section 7.1
          - See Figure 6.1 Explanation of Box Plot, from SAS/STAT user guide
          - Symbol for IQR outliers
          - Apply RED color for values outside pre-defined reference limits
          - EG, include ANRLO and ANRHI in dependencies and program logic
      * Confirm meaning of "N" in summary table
          - Population size?
          - Sample size?
          - Should display distinguish between "N" (pop), "n" (samples), and pop with NO measures?
      * Reference limit lines. Provide options for several scenarios (see explanation in White Paper):
          - NONE:    DEFAULT. no reference lines
          - UNIFORM: reference limits are uniform for entire population
                     only display uniform ref lines, to match outlier logic, otherwise no lines
                     NB: preferred alternative to default (NONE)
          - NARROW:  reference limits vary across selected population (e.g., based on some demographic or lab)
                     display reference lines for the narrowest interval
                     EG: highest of the low limits, lowest of the high limits
                     NB: discourage, since creates confusion for reviewers
          - ALL:     reference limits vary across selected population (e.g., based on some demographic or lab)
                     display all reference lines, pairing low/high limits by color and line type
                     NB: discourage, since creates confusion for reviewers

end HEADER ***/



  /*** USER PROCESSING AND SETTINGS

    1) REQUIRED - PhUSE/CSS Utilities macro library.
       These templates require the PhUSE/CSS macro utilities:
         https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/utilities
       User must ensure that SAS can find PhUSE/CSS macros in the SASAUTOS path (see EXECUTE ONE TIME, below)

    2) OPTIONAL - Subset measurement data, to limit resulting plots to specific
         - Parameters
         - Analysis Timepoints
         - Visits

    3) REQUIRED - Key user settings (libraries, data sets, variables and box plot options)
       S_LB: Libname containing ADaM subject-level data, typically ADSL
             WORK by default, since step (2) creates the desired WORK subsets.
       S_DS: Subject-level data set for population counts, typically ADSL.
       M_LB: Libname containing ADaM measurement data, such as ADVS.
             WORK by default, since step (2) creates the desired WORK subsets.
       M_DS: Measuments data set, such as ADVS.
       P_FL: Population flag variable. 'Y' indicates record is in population of interest.
       A_FL: Analysis Flag variable.   'Y' indicates that record is selected for analysis.

       MAX_BOXES_PER_PAGE:
             Maximum number of boxes to display per plot page (see "Notes", above)

  ***/

    %put WARNING: (WPCT-F.07.01) User must ensure PhUSE/CSS utilities are in the AUTOCALL path.;

    /*** 1) PhUSE/CSS utilities in autocall paths

      EXECUTE ONE TIME only as needed
      NB: The following line is necessary only when PhUSE/CSS utilities are NOT in your default AUTOCALL paths

      OPTIONS sasautos=(%sysfunc(getoption(sasautos)) "C:\CSS\phuse-scripts\whitepapers\utilities");

    ***/


    %*--- 2a) ACCESS PhUSE/CSS test data, and create work copy with prefix "CSS_" ---*;
      %util_access_test_data(adsl)
      %util_access_test_data(advs)

    *--- 2b) USER SUBSET of data, to limit number of box plot outputs, and to shorten Tx labels ---*;
      %macro shorten_trt_name(ori_var, new_var);
        length &new_var $6;
        select (&ori_var);
          when ('Placebo')              &new_var = 'P';
          when ('Xanomeline High Dose') &new_var = 'X-high';
          when ('Xanomeline Low Dose')  &new_var = 'X-low';
          otherwise                     &new_var = 'UNEXPECTED';
        end;
      %mend shorten_trt_name;

      data adsl_sub (rename=(trt01p_short=trt01p));
        set css_adsl;

        %shorten_trt_name(trt01p, trt01p_short)

        drop trt01p;
      run;

      data advs_sub (rename=(trtp_short=trtp));
        set css_advs;
        where (paramcd in ('DIABP') and atptn in (815)) or 
              (paramcd in ('SYSBP') and atptn in (816));

        %shorten_trt_name(trtp, trtp_short)

        drop trtp;
      run;


    *--- 3) Key user settings ---*;
      %let s_lb = work;
      %let s_ds = adsl_sub;

      %let m_lb = work;
      %let m_ds = advs_sub;

      %let p_fl = saffl;
      %let a_fl = anl01fl;

      %let max_boxes_per_page = 20;

  /*** end USER PROCESSING AND SETTINGS
    RELAX.
    The rest should simply work, or alert you to invalid conditions.
  ***/



  /*** SETUP & CHECK DEPENDENCIES
    Explain to user in case environment or data do not support this analysis

    Keep just those variables and records required for this analysis
    For details, see specifications at top
  ***/

    options nocenter mautosource mrecall mprint msglevel=I mergenoby=WARN
            syntaxcheck dmssynchk obs=MAX ls=max ps=max;
    goptions reset=all;
    ods show;

    %let asl_variables = STUDYID USUBJID &p_fl TRT01P TRT01PN;
    %let ana_variables = STUDYID USUBJID &p_fl &a_fl TRTP TRTPN PARAM PARAMCD AVAL ANRLO ANRHI AVISIT AVISITN ATPT ATPTN;

    *--- Restrict analysis to SAFETY POP and ANALYSIS RECORDS (&a_fl) ---*;
      data css_asldata;
        set &s_lb..&s_ds (keep=&asl_variables);
        where &p_fl = 'Y';
      run;

      data css_anadata;
        set &m_lb..&m_ds (keep=&ana_variables);
        where &p_fl = 'Y' and &a_fl = 'Y';
      run;

      %*--- Assert that ASL is a complete reference data set, that it contains all subjects represented in measured data ---*;
        %assert_complete_refds(css_asldata css_anadata, usubjid)

    %*--- Global boolean symbol CONTINUE, used with macro assert_continue(), warns user of invalid environment. Processing should HALT. ---*;
      %let CONTINUE = %assert_depend(OS=%str(AIX,WIN,HP IPF),
                                     SASV=9.2+,
                                     vars=%str(css_asldata: &asl_variables, css_anadata : &ana_variables),
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

    %*--- Number of planned treatments: &TRTN ---*;
      %util_count_unique_values(css_anadata, trtp, trtn)


  /*** BOXPLOT for each PARAMETER and ANALYSIS TIMEPOINT in selected data
    PROC SHEWHART creates the summary table of stats from "block" (stats) variables
                  and reads "phases" (visits) from a special _PHASE_ variable

    One box plot for each PARAMETER and ANALYSIS TIMEPOINT.
    By Visit and Planned Treatment.

    In case of many visits and planned treatments, each box plot will use multiple pages.
  ***/

    %macro boxplot_each_param_tp(plotds=css_anadata);
      %local pdx tdx;

      %do pdx = 1 %to &paramcd_n;
        *--- Work with one PARAMETER, but start with ALL TIMEPOINTS ---*;
          data css_nextparam;
            set &plotds (where=(paramcd = "&&paramcd_val&pdx"));
          run;

        %*--- Y-AXIS alternative: Fix Y-Axis MIN/MAX based on all timepoints. See Y-AXIS DEFAULT, below. ---*;
        %*   %util_get_var_min_max(css_nextparam, aval, aval_min_max)   *;

        %*--- Analysis Timepoints for this parameter: Num (&ATPTN_N), Names (&ATPTN_NAM1 ...) and Labels (&ATPTN_LAB1 ...) ---*;
          %util_labels_from_var(css_nextparam, atptn, atpt)

        %do tdx = 1 %to &atptn_n;

          *--- Work with just one TIMEPOINT for this parameter, but ALL VISITS ---*;
          *--- NB: PROC SORT here is REQUIRED, in order to merge on STAT details, below ---*;
            proc sort data=css_nextparam (where=(atptn = &&atptn_val&tdx))
                       out=css_nexttimept;
              by avisitn trtpn;
            run;

          %*--- Y-AXIS DEFAULT: Fix Y-Axis MIN/MAX based on this timepoint. See Y-AXIS alternative, above. ---*;
            %util_get_var_min_max(css_nextparam, aval, aval_min_max)

          %*--- Number of visits for this parameter and analysis timepoint: &VISN ---*;
            %util_count_unique_values(css_nexttimept, avisitn, visn)

          %*--- Create format string to display MEAN and STDDEV to default sig-digs: &UTIL_VALUE_FORMAT ---*;
            %util_value_format(css_nexttimept, aval)



          /*** TO DO
            With just these data selected for analysis and display
            - REF LIMIT OUTLIERS: Determine outlier values, based on Reference limits
                                  (could be part of %util_prep_shewhart_data(), below)
            - REF LIMIT LINES:    Determine whether to include reference lines
          ***/



          *--- Calculate summary statistics, and merge onto measurement data for use as "block" variables ---*;
            proc summary data=css_nexttimept noprint;
              by avisitn trtpn;
              var aval;
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
              Example of BOXPLOT_TIMEPT_RANGES: 0 <= timept <7|7 <= timept <12|


            TO DO
              * Update macro to also return an ANNOTATE data set, to highlight measures outside reference ranges

          ***/

            %util_prep_shewhart_data(css_plot, 
                                     vvisn=avisitn, vtrtn=trtpn, vtrt=trtp, vval=aval,
                                     numtrt=&trtn, numvis=&visn)


          *--- Graphics Settings ---*;
            options orientation=landscape;
            goptions reset=all hsize=14in vsize=7.5in;

            title     justify=left height=1.2 "Box Plot - &&paramcd_lab&pdx by Visit, Analysis Timepoint: &&atptn_lab&tdx";
            footnote1 justify=left height=1.0 'Box plot type=schematic, the box shows median, interquartile range (IQR, edge of the bar), min and max';
            footnote2 justify=left height=1.0 'within 1.5 IQR below 25% and above 75% (ends of the whisker). Values outside the 1.5 IQR below 25% and';
            footnote3 justify=left height=1.0 'above 75% are shown as outliers. Means plotted as different symbols by treatments.';
            axis1     value=none label=none major=none minor=none;
            axis2     order=( %util_axis_order(%scan(&aval_min_max,1), %scan(&aval_min_max,2)) );


          *--- PDF output destination ---*;
            ods pdf file="outputs_sas\WPCT-F.07.01_Box_plot_&&paramcd_val&pdx.._by_visit_for_timepoint_&&atptn_val&tdx...pdf";

          *--- FINALLY, A Graph - Multiple pages in case of many visits/treatments ---*;
            %local vdx nxtvis;
            %let vdx=1;
            %do %while (%qscan(&boxplot_timept_ranges,&vdx,|) ne );
              %let nxtvis = %qscan(&boxplot_timept_ranges,&vdx,|);

              proc shewhart data=css_plot_tp (where=( &nxtvis ));
                boxchart aval*timept (max q3 median q1 min std mean n trtp) = trtp /
                         boxstyle=schematic
                         notches
                         stddeviations
                         nolegend
                         ltmargin = 5
                         blockpos = 3
                         blocklabelpos = left
                         blocklabtype=scaled
                         blockrep
                         haxis=axis1
                         vaxis=axis2
                         idsymbol=dot
                         idcolor=red
                         nolimits
                         readphase = all
                         phaseref
                         phaselabtype=scaled
                         phaselegend;

                label aval    = "&&paramcd_lab&pdx"
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
            %end;

          *--- Release the PDF output file! ---*;
            ods pdf close;

        %end; %*--- TDX loop ---*;

      %end; %*--- PDX loop ---*;

      *--- Clean up temp data sets required to create box plots ---*;
        proc datasets library=WORK memtype=DATA nolist nodetails;
          delete css_plot css_plot_tp css_nextparam css_nexttimept css_stats;
        quit;

    %mend boxplot_each_param_tp;
    %boxplot_each_param_tp;

  /*** END boxplotting ***/
