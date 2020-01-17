/*** HEADER

    Display:     Figure 7.1 Box plot - Measurements by Analysis Timepoint, Visit and Treatment
    White paper: Central Tendency

    User Guide:     https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/CentralTendency-UserGuide.txt
    Macro Library:  https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/utilities
    Specs:          https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/specification
    Test Data:      https://github.com/phuse-org/phuse-scripts/tree/master/data/adam/cdisc
    Sample Output:  https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/WPCT/outputs_sas/WPCT-F.07.01_Box_plot_DIABP_by_visit_for_timepoint_815.pdf

	*Some changes*
	
	********************
	Comments and modifications 2020-01-17:
	
	- comment %assert_timepoint_exist as this is not available;
	
	To have this script runnable for the example data, you need to update some settings (SASAUTOS, pathes),
	furthermore you need to create dummy ATPTN and ATPT variables as these are currently not in the test data.
	
	OPTIONS SASAUTOS=("<PATH>/whitepapers/utilities", SASAUTOS);
	OPTIONS MRECALL MAUTOSOURCE;
	
	%let ds = ADLBC;
	%util_access_test_data(&ds);
	%* program requires time point variables, so create dummy content as not available in test data;
	DATA &ds;
		SET &ds;
		ATPTN = 1;
		ATPT = "TimePoint unknown";
	RUN;
	
	%let outputs_folder = <PATH>/results;
	********************

    Using this program:

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
       A_FL:  Analysis Flag variable.   'Y' indicates that record is selected for analysis.

       REF_LINES:
             Option to specify which Normal Range reference lines to include in box plots
             <NONE | UNIFORM | NARROW | ALL | numeric-value(s)> See discussion in Central Tendency White Paper
             NONE    - No reference lines on box plot
             UNIFORM - Default. preferred alternative to default. Only plot LOW/HIGH ref lines if uniform for all obs
             NARROW  - Display only the narrow normal limits: max LOW, and min HIGH limits
             ALL     - Discouraged, since displaying ALL reference lines confuses review of data display
             numeric-values - space-delimited list of reference line values, such as a 0 reference line for displays of change.

       MAX_BOXES_PER_PAGE:
             Maximum number of boxes to display per plot page (see "Notes", above)

       OUTPUTS_FOLDER:
             Location to write PDF outputs (WITHOUT final back- or forward-slash)

  ************************************
  *** user processing and settings ***
  ************************************/

	OPTIONS sasautos=(	"\\quintiles.net\enterprise\Apps\sasdata\StatOpB\CSV\9_GB_Phuse\phuse-scripts\whitepapers\utilities"
						"\\quintiles.net\enterprise\Apps\sasdata\StatOpB\CSV\9_GB_Phuse\phuse-scripts\whitepapers\ADaM" %sysfunc(getoption(sasautos)));
    %put WARNING: (WPCT-F.07.01) User must ensure PhUSE CS utilities are in the AUTOCALL path.;

    /*** 1) PhUSE CS utilities in autocall paths (see "Macro Library", above)

      EXECUTE ONE TIME only as needed
      NB: The following line is necessary only when PhUSE CS utilities are NOT in your default AUTOCALL paths

      OPTIONS sasautos=(%sysfunc(getoption(sasautos)) "C:\CSS\phuse-scripts\whitepapers\utilities");

    ***/
      %let ds = ADLBC;

    /*** 2a) REMOTE ACCESS data, by default PhUSE CS test data, and create WORK copy.                ***/
    /***     NB: If remote access to test data files does not work, see local override, below. ***/
       %util_access_test_data(&ds, local=\\quintiles.net\enterprise\Apps\sasdata\StatOpB\CSV\9_GB_Phuse\phuse-scripts\data\adam\cdisc-split\) ;

      *--- NB: LOCAL PhUSE CS test data, override remote access by providing a local path ---*;
        %* %util_access_test_data(&ds, local=C:\CSS\phuse-scripts\data\adam\cdisc\) ;


    %*--- 3a) Key user settings ---*;
      %let m_lb   = work;
      %let m_ds   = &ds._sub;
	  %let param = 'ALB';
	  %let cond = %str(and AVISITN in (0 2 4 6));

      %let t_var  = trtp_short;
      %let tn_var = trtpn;
      %let m_var  = aval;
      %let lo_var = a1lo;
      %let hi_var = a1hi;

      %let p_fl = saffl;
      %let a_fl = anl01fl;

      %let ref_lines = UNIFORM;

      %let max_boxes_per_page = 20;

	  %let root = \\quintiles.net\enterprise\Apps\sasdata\StatOpB\CSV;
      %let outputs_folder = &Root\9_GB_PhUSE\phuse-scripts\whitepapers\WPCT\GB_Test;

	*--Specify TRTPN and short treatment values;
	proc format;
		value trt_short
		0 = 'P'
		54 = 'X-high'
		81 = 'X-low'
		other = 'UNEXPECTED';
	run;

	  /*** 3b) USER SUBSET of data, to limit number of box plot outputs, and to shorten Tx labels ***/
      data &ds._sub;
        set work.&ds;
        where (paramcd in (&param) &cond);

        attrib trtp_short length=$6 label='Planned Treatment, abbreviated';

		trtp_short = put(&tn_var,trt_short.);

		%*assert_timepoint_exist(ds=&ds._sub);
      run;

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

    %let ana_variables = STUDYID USUBJID &p_fl &a_fl &t_var &tn_var PARAM PARAMCD &m_var &lo_var &hi_var AVISIT AVISITN ATPT ATPTN;

    %*--- Global boolean symbol CONTINUE, used with macro assert_continue(), warns user of invalid environment. Processing should HALT. ---*;
      %let CONTINUE = %assert_depend(OS=%str(AIX,WIN,HP IPF),
                                     SASV=9.4M1,
                                     SYSPROD=,
                                     vars=%str(&m_lb..&m_ds : &ana_variables),
                                     macros=assert_continue util_labels_from_var util_count_unique_values
                                            util_get_reference_lines util_proc_template util_get_var_min_max
                                            util_value_format util_boxplot_block_ranges util_axis_order util_delete_dsets,
                                     symbols=m_lb m_ds t_var tn_var m_var lo_var hi_var p_fl a_fl
                                             ref_lines max_boxes_per_page outputs_folder
                                    );

      %assert_continue(After asserting the dependencies of this script)


    *--- Restrict analysis to SAFETY POP and ANALYSIS RECORDS (&a_fl) ---*;
      data css_anadata;
        set &m_lb..&m_ds (keep=&ana_variables);
        where &p_fl = 'Y' and &a_fl = 'Y';
		%*assert_timepoint_exist(ds=css_anadata);
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
              by avisitn &tn_var;
            run;

          %*--- Y-AXIS DEFAULT: Set Y-Axis MIN/MAX based on this timepoint. See Y-AXIS alternative, above. ---*;
          %*--- NB: EXTRA normal range reference lines could expand Y-AXIS range.                          ---*;
            %util_get_var_min_max(css_nexttimept, &m_var, aval_min_max, extra=&nxt_reflines)

          %*--- Number of visits for this parameter and analysis timepoint: &VISN ---*;
            %util_count_unique_values(css_nexttimept, avisitn, visn)

          %*--- Create format string to display MEAN and STDDEV to default sig-digs: &UTIL_VALUE_FORMAT ---*;
            %util_value_format(css_nexttimept, &m_var)

          %*--- Create macro variable BOXPLOT_BLOCK_RANGES, to subset visits into box plot pages ---*;
            %util_boxplot_block_ranges(css_nexttimept, blockvar=avisitn, catvars=&tn_var);


          *--- Calculate summary statistics, KEEP LABELS of VISIT and TRT for plotting, below ---*;
            proc summary data=css_nexttimept noprint;
              by avisitn &tn_var avisit &t_var;
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

            title     justify=left height=1.2 "Box Plot - &&paramcd_lab&pdx Observed Values by Visit, Analysis Timepoint: &&atptn_lab&tdx";


            footnote1 justify=left height=1.0 'Box plot type is schematic: the box shows median and interquartile range (IQR, the box height); the whiskers extend to the minimum';
            footnote2 justify=left height=1.0 'and maximum data points within 1.5 IQR of the lower and upper quartiles, respectively. Values outside the whiskers are shown as outliers.';
            footnote3 justify=left height=1.0 'Means are marked with a different symbol for each treatment. Red dots indicate measures outside the normal reference range.';

            %let y_axis = %util_axis_order( %scan(&aval_min_max,1,%str( )), %scan(&aval_min_max,2,%str( )) );

          *--- ODS PDF destination (Traditional Graphics, No ODS or Listing output) ---*;
            ods listing close;
            ods pdf file="&outputs_folder/WPCT-F.07.01_Box_plot_&&paramcd_val&pdx.._by_visit_for_timepoint_&&atptn_val&tdx...pdf"
                    notoc bookmarklist=none dpi=300
                    author="(&SYSUSERID) PhUSE CS Standard Analysis Library"
                    subject='PhUSE CS Measures of Central Tendency'
                    title="Boxplot of &&paramcd_lab&pdx by Visit for Analysis Timepoint &&atptn_lab&tdx"
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
                        _XVAR       = 'avisitn'
                        _BLOCKLABEL = 'avisit'
                        _YVAR       = "&m_var"
                        _YOUTLIERS  = 'm_var_outlier'

                        %if %length(&nxt_reflines) > 0 %then %do;
                          _REFLINES   = "%sysfunc(translate( &nxt_reflines, %str(,), %str( ) ))"
                        %end;

                        _YLABEL     = "&&paramcd_lab&pdx"
                        _YMIN       = %scan(&y_axis, 1, %str( ))
                        _YMAX       = %scan(&y_axis, 3, %str( ))
                        _YINCR      = %scan(&y_axis, 5, %str( ))
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
