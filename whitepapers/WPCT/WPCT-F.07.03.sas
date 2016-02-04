/*** HEADER

    Display:     Figure 7.1 Box plot - Measurements by Analysis Timepoint, Visit and Planned Treatment
    White paper: Central Tendency

    User Guide:     https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/CentralTendency-UserGuide.txt
    Macro Library:  https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/utilities
    Specs:          https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/specification
    Test Data:      https://github.com/phuse-org/phuse-scripts/tree/master/data/adam/cdisc
    Sample Output:  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_sas/WPCT-F.07.01_Box_plot_DIABP_by_visit_for_timepoint_815.pdf

    Using this program:

      * Figure 7.3 combines analyses from Figures 7.1 and 7.2 as side-by-side graphics.
        The approach follows SAS Note "Sample 41461: Put multiple PROC SGPLOT outputs on the same PDF page using PROC GREPLAY"
        http://support.sas.com/kb/41/461.html

      * See USER PROCESSING AND SETTINGS, below, to configure this program for your environment and data
      * Program will plot all visits, ordered by AVISITN, with maximum of 20 boxes on a page (default)
        + see user option MAX_BOXES_PER_PAGE, below, to change limit of 20 boxes per page
      * Program separately plots all parameters provided in PARAMCD
      * Measurements within each PARAMCD and ATPTN determine precision of statistical results
        + MEAN gets 1 extra decimal, STD DEV gets 2 extra decimals
        + see macro UTIL_VALUE_FORMAT to modify this behavior
      * If your treatment names are too long for the summary table, change TRTP 
        in the input data, and add a footnote that explains your short Tx codes
        + This program contains custom code to shorted Tx labels in the PhUSE/CSS test data
        + See "2b) USER SUBSET of data", below

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
       C_VAR:  Variable in M_DS with change-from-baseline data, such as CHG.

       LO_VAR: Variable in M_DS with LOWER LIMIT of reference range, such as ANRLO.
               Required to highlight values outside reference range (RED DOT in box plot), and reference lines
       HI_VAR: Variable in M_DS with UPPER LIMIT of reference range, such as ANRHI.
               Required to highlight values outside reference range (RED DOT in box plot), and reference lines

       OPTIONAL: omit to suppress Endpoint P-VALUE in graphic
         B_VAR:    Variable in M_DS with baseline measurements
         REF_TRTN: Numeric value of TRTPN for reference (comparator) treatment

       B_VISN: Visit number that represents Baseline in AVISITN (e.g., 0)
       E_VISN: Visit number that represents endpoint in AVISITN for chg-from-baseline comparison (e.g., 99)
               OPTIONAL: Include additional visits BETWEEN baseline and endpoint.
                         List space-delimited, INCREASING visit numbers in E_VISN.
                         The LAST (greatest) visit number in E_VISN is the endpoint visit.

       P_FL:  Population flag variable. 'Y' indicates record is in population of interest.
       A_FL:  Analysis Flag variable.   'Y' indicates that record is selected for analysis.

       REF_LINES:
             Option to specify which Normal Range reference lines to include in box plots
             <NONE | UNIFORM | NARROW | ALL | numeric-value(s)> See discussion in Central Tendency White Paper 
             NONE    - No reference lines on box plot
             UNIFORM - preferred alternative to default. Only plot LOW/HIGH ref lines if uniform for all obs
             NARROW  - Default. Display only the narrow normal limits: max LOW, and min HIGH limits
             ALL     - discouraged since displaying ALL reference lines confuses review our data display
             numeric-values - space-delimited list of reference line values, such as a 0 reference line for displays of change.

       MAX_BOXES_PER_PAGE:
             Maximum number of boxes to display per plot page (see "Notes", above)

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


    /*** 2a) REMOTE ACCESS data, by default PhUSE/CSS test data, and create WORK copy.                ***/
    /***     NB: If remote access to test data files does not work, see local override, below. ***/
      %util_access_test_data(advs)

      *--- NB: LOCAL CSS/PhUSE test data, override remote access by providing a local path ---*;
        %* %util_access_test_data(advs, local=C:\CSS\phuse-scripts\data\adam\cdisc\) ;


    /*** 2b) USER SUBSET of data, to limit number of box plot outputs, and to shorten Tx labels ***/

      data advs_sub (rename=(trtp_short=trtp));
        set work.advs;
        where (paramcd in ('DIABP') and atptn in (815));

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
      %let c_var  = CHG;

      %let lo_var = ANRLO;
      %let hi_var = ANRHI;

      %let b_var  = base;
      %let ref_trtn = 0;

      %let b_visn = 0;
      %let e_visn = 12 24 99;

      %let p_fl = saffl;
      %let a_fl = anl01fl;

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

    %let ana_variables = STUDYID USUBJID &p_fl &a_fl TRTP TRTPN PARAM PARAMCD &m_var &c_var &b_var &lo_var &hi_var AVISIT AVISITN ATPT ATPTN;

    %*--- Global boolean symbol CONTINUE, used with macro assert_continue(), warns user of invalid environment. Processing should HALT. ---*;
      %let CONTINUE = %assert_depend(OS=%str(AIX,WIN,HP IPF),
                                     SASV=9.4M2,
                                     SYSPROD=,
                                     vars=%str(&m_lb..&m_ds : &ana_variables),
                                     macros=assert_continue util_labels_from_var util_count_unique_values 
                                            util_get_reference_lines util_proc_template util_get_var_min_max
                                            util_value_format util_boxplot_visit_ranges util_axis_order util_delete_dsets,
                                     symbols=m_lb m_ds m_var c_var lo_var hi_var b_var ref_trtn b_visn e_visn p_fl a_fl 
                                             ref_lines max_boxes_per_page outputs_folder
                                    );

      %assert_continue(After asserting the dependencies of this script)


    *--- Restrict analysis to SAFETY POP and ANALYSIS RECORDS (&a_fl) ---*;
      data css_anadata;
        set &m_lb..&m_ds (keep=&ana_variables);
        where &p_fl = 'Y' and &a_fl = 'Y';

        *--- NB: Keep Baseline measures, but DO NOT PLOT these for the CHANGE graphic, below ---*;
          where also avisitn in (&b_visn &e_visn);

        *--- Create a Normal Range Outlier variable, for scatter plot overlay ---*;
          if (2 = n(&m_var, &lo_var) and &m_var < &lo_var) or
             (2 = n(&m_var, &hi_var) and &m_var > &hi_var) then m_var_outlier = &m_var;
          else m_var_outlier = .;

      run;


  /*** GATHER INFO for data-driven processing
    Collect required information about these measurements:

    Number, Names and Labels of PARAMCDs - used to cycle through parameters that have measurements
      &PARAMCD_N count of parameters
      &PARAMCD_VAL1 to &&&PARAMCD_VAL&PARAMCD_N series of parameter codes
      &PARAMCD_LAB1 to &&&PARAMCD_LAB&PARAMCD_N series of parameter labels

    Number of planned treatments - used for handling treatments categories
      &TRTN

    Baseline visit value & label
      &b_visn_val1
      &b_visn_lab1

    Endpoint visit value & label
      &e_visn_val1
      &e_visn_lab1

  ***/

    %*--- User may specify optional intermediate visits in E_VISN. ---*;
    %*--- Separate these into InterMediate (IM_VISN) visits, and a single EndPoint (EP_VISN) visit ---*;
      %macro null;
        %global im_visn ep_visn;
        %local cnt idx;

        %let im_visn = ;
        %let cnt = %sysfunc(countw(&e_visn, %str( )));

        %if &cnt > 1 %then %do idx = 1 %to %eval(&cnt - 1);
          %let im_visn = &im_visn %scan(&e_visn, &idx, %str( ));
        %end;

        %let ep_visn = %scan(&e_visn, -1, %str( ));
      %mend null;
      %null;


    %*--- Parameters: Number (&PARAMCD_N), Names (&PARAMCD_VAL1 ...) and Labels (&PARAMCD_LAB1 ...) ---*;
      %util_labels_from_var(css_anadata, paramcd, param)

    %*--- Baseline visit: Number (&B_VISN_N), Names (&B_VISN_VAL1) and Labels (&B_VISN_LAB1) ---*;
      %util_labels_from_var(css_anadata, avisitn, avisit, prefix=b_visn, whr=avisitn eq &b_visn)

    %*--- Endpoint visit: Number (&EP_VISN_N), Names (&E_VISN_VAL1) and Labels (&E_VISN_LAB1) ---*;
      %util_labels_from_var(css_anadata, avisitn, avisit, prefix=ep_visn, whr=avisitn eq &ep_visn)

    %*--- Number of planned treatments: Set &TRTN from ana variable TRTP ---*;
      %util_count_unique_values(css_anadata, trtp, trtn)


  /*** BOXPLOT for each PARAMETER and ANALYSIS TIMEPOINT in selected data

    One box plot for each PARAMETER and ANALYSIS TIMEPOINT.
    By Visit and Planned Treatment.

    In case of many visits and planned treatments, each box plot will use multiple pages.

    CLEANUP = O, blocks the macro from deleting temp data sets after the last parameter & timepoint loop

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
                                    low_var  =&lo_var, high_var =&hi_var,
                                    ref_lines=&ref_lines)

        %*--- Y-AXIS alternative: Fix Y-Axis MIN/MAX based on all timepoints for PARAM. See Y-AXIS DEFAULT, below. ---*;
        %*--- NB: EXTRA normal range reference lines could expand Y-AXIS range.                                    ---*;
        %*   %util_get_var_min_max(css_nextparam, &m_var, aval_min_max, extra=&nxt_reflines)   *;
        %*   %util_get_var_min_max(css_nextparam, &c_var, chg_min_max)   *;


        %do tdx = 1 %to &atptn_n;

          /*** LOOP 2 ********************************************************************
           *** Loop through each TIMEPOINT for this parameter, working with ALL VISITS ***
           *** NB: PROC SORT here is REQUIRED in order to merge on STAT details, below ***
           *******************************************************************************/
            proc sort data=css_nextparam (where=(atptn = &&atptn_val&tdx))
                       out=css_nexttimept;
              by avisitn trtpn;
            run;

          %*--- Y-AXIS DEFAULT: Set Y-Axis MIN/MAX based on this timepoint. See Y-AXIS alternative, above. ---*;
          %*--- NB: EXTRA normal range reference lines could expand Y-AXIS range.                          ---*;
            %util_get_var_min_max(css_nexttimept, &m_var, aval_min_max, extra=&nxt_reflines)
            %util_get_var_min_max(css_nexttimept, &c_var, chg_min_max)

          %*--- Number of visits for this parameter and analysis timepoint: &VISN ---*;
            %util_count_unique_values(css_nexttimept, avisitn, visn)

          %*--- Create format string to display MEAN and STDDEV to default sig-digs: &UTIL_VALUE_FORMAT ---*;
            %util_value_format(css_nexttimept, &m_var)

          %*--- Create macro variable BOXPLOT_VISIT_RANGES, to subset visits into box plot pages ---*;
            %util_boxplot_visit_ranges(css_nexttimept, vvisn=avisitn, vtrtn=trtpn);


          *--- Calculate summary statistics, KEEP LABELS of VISIT and TRT for plotting, below ---*;
            proc summary data=css_nexttimept noprint;
              by avisitn trtpn avisit trtp;
              var &m_var;
              output out=css_stats (drop=_type_ _freq_) 
                     n=n mean=mean std=std median=median min=datamin max=datamax q1=q1 q3=q3;
            run;


          %*--- Add ANCOVA p-values for Endpoint: CHG = BASE + TRT (if user specified a reference arm) ---*;
            %if %length(&b_var) > 0 and %length(&ref_trtn) > 0 %then %do;
              %local endpoint_definition;

              %let css_pval_ds = css_pvalues;
              %let endpoint_definition = avisitn = &ep_visn;

              ods select parameterestimates;
              ods output parameterestimates = &css_pval_ds;

              proc glm data=css_nexttimept;
                where &endpoint_definition;
                class trtpn (ref="&ref_trtn");
                model &c_var = &b_var trtpn / solution;
              run; quit;

              *--- UPDATE CSS_STATS with p-values for active arms, at Endpoint visit ---*;
                data temp;
                  *--- We simply need the structure of these vars, for subsequent merge ---*;
                  set css_stats (keep=avisitn trtpn);
                  STOP;
                run;

                data &css_pval_ds;
                  set temp &css_pval_ds (keep=parameter probt 
                                         rename=(probt=pval)
                                         where=(parameter=:'TRTPN'));
                  label pval="GLM ANCOVA p-value: Reference is TRTPN = &ref_trtn";
                  &endpoint_definition;
                  trtpn   = input(scan(parameter,-1,' '), best8.);
                run;

                proc sort data=&css_pval_ds;
                  by avisitn trtpn;
                run;

                data css_stats;
                  merge css_stats &css_pval_ds (keep=avisitn trtpn pval);
                  by avisitn trtpn;
                run;

                %util_delete_dsets(temp);
            %end;          


            /***
              STACK statistics (do NOT merge) BELOW the plot data, one obs per TREATMENT/VISIT.
              NB: We need exactly ONE obs per timepoint and trt: AXISTABLE defaults to a SUM function
            ***/
            data css_plot;
              set css_nexttimept
                  css_stats;

              label n         = 'n'
                    mean      = 'Mean'
                    std       = 'Std Dev'
                    datamin   = 'Min'
                    q1        = 'Q1'
                    median    = 'Median'
                    q3        = 'Q3'
                    datamax   = 'Max'
                    ;
              format mean %scan(&util_value_format, 1, %str( )) std %scan(&util_value_format, 2, %str( ));
            run;


          *--- Graphics Settings - Set defaults for all graphs ---*;
            options orientation=landscape;
            goptions reset=all;

            ods graphics on / reset=all;
            ods graphics    / border=no attrpriority=COLOR;

            title     justify=left height=1.2 "Box Plot - &&paramcd_lab&pdx Observed Values and Change from %upcase(&B_VISN_LAB1) to %upcase(&EP_VISN_LAB1) by Visit, Analysis Timepoint: &&atptn_lab&tdx";
            footnote1 justify=left height=1.0 'Box plot type is schematic: the box shows median and interquartile range (IQR, the box edges); the whiskers extend to the minimum and maximum data points';
            footnote2 justify=left height=1.0 'within 1.5 IQR below 25% and above 75%, respectively. Values outside the whiskers are shown as outliers. Means are marked with a different symbol for each treatment.';
            footnote3 justify=left height=1.0 'Red dots indicate measures outside the normal reference range. P-value is for the treatment comparison from ANCOVA model Change = Baseline + Treatment.';

            %let aval_axis = %util_axis_order( %scan(&aval_min_max,1,%str( )), %scan(&aval_min_max,2,%str( )) );
            %let chg_axis  = %util_axis_order( %scan(&chg_min_max,1, %str( )), %scan(&chg_min_max,2, %str( )) );

          *--- ODS PDF destination (Traditional Graphics, No ODS or Listing output) ---*;
            ods listing close;
            ods pdf dpi=300
                    author="(&SYSUSERID) PhUSE/CSS Standard Analysis Library"
                    subject='PhUSE/CSS Measures of Central Tendency'
                    title="Boxplot of &&paramcd_lab&pdx by Visit for Analysis Timepoint &&atptn_lab&tdx"
                    file="&outputs_folder\WPCT-F.07.03_Box_plot_&&paramcd_val&pdx.._with_change_by_visit_for_timepoint_&&atptn_val&tdx...pdf";


          /*** LOOP 3 - FINALLY, A Graph ****************************
           *** - Multiple pages in case of many visits/treatments ***
           **********************************************************/

            %local vdx nxtvis;
            %let vdx=1;
            %do %while (%qscan(&boxplot_visit_ranges,&vdx,|) ne );
              %let nxtvis = %qscan(&boxplot_visit_ranges,&vdx,|);

              *--- OBSERVED values (left plot) ---*;
                proc sgrender data=css_plot (where=( &nxtvis )) template=PhUSEboxplot ;
                  dynamic 
                          _TRT        = 'trtp'
                          _AVISITN    = 'avisitn' 
                          _AVISIT     = 'avisit' 
                          _AVAL       = "&m_var"
                          _AVALOUTLIE = 'm_var_outlier'

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
                proc sgrender data=css_plot (where=( avisitn ne &b_visn AND &nxtvis )) template=PhUSEboxplot ;
                  dynamic 
                          _TRT        = 'trtp'
                          _AVISITN    = 'avisitn' 
                          _AVISIT     = 'avisit' 
                          _AVAL       = "&c_var"
                          _AVALOUTLIE = 'm_var_outlier'
                          _REFLINES   = "0"
                          _YLABEL     = "&&paramcd_lab&pdx"
                          _YMIN       = %scan(&chg_axis, 1, %str( ))
                          _YMAX       = %scan(&chg_axis, 3, %str( ))
                          _YINCR      = %scan(&chg_axis, 5, %str( ))
                          _N          = 'n'
                          _MEAN       = 'mean'
                          _STD        = 'std'
                          _DATAMIN    = 'datamin'
                          _Q1         = 'q1'
                          _MEDIAN     = 'median'
                          _Q3         = 'q3'
                          _DATAMAX    = 'datamax'

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
        %if &cleanup %then %util_delete_dsets(css_nextparam css_nexttimept &css_pval_ds css_stats css_plot);

    %mend boxplot_each_param_tp;

    %boxplot_each_param_tp;

  /*** END boxplotting ***/
