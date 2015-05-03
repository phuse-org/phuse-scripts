/*** Prep box plot data for PROC SHEWHART

This macro prepares measurement data for SAS/QC PROC SHEWHART, which has several conventions for plotting data.

PROC SHEWHART creates the summary table of stats from "block" variable (typically "stats", for us)
              and reads "phases" from a special _PHASE_ variable (typically "visits", for us)

TO DO
  * List of STATS used for summary table "blocks" could be customizable
  * Option to produce an ANNOTATE data set, based on measured values, to highlight measures outside reference ranges

INPUTS
  DS          Data set including (1) measurements to plot, and (2) vars to be used for "block" labels
    REQUIRED
    Syntax:   Expecting one-level WORK data set name
    Example:  PLOT_DATA
  VVISN
    REQUIRED
    Syntax:   Variable on DS containing visit numbers
    Example:  AVISITN
  VTRTN
    REQUIRED
    Syntax:   Variable on DS containing treatment numbers
    Example:  TRTPN
  VTRT
    REQUIRED
    Syntax:   Variable on DS containing treatment names (kept in data sets for plotting)
    Example:  TRTP
  VVAL
    REQUIRED
    Syntax:   Variable on DS containing numeric measurements (kept in data sets for plotting)
    Example:  AVAL

  NUMTRT              REQUIRED: Global sym with Number of treatments, e.g., calculate prior with UTIL_LABELS_FROM_VAR
  NUMVIS              REQUIRED: Global sym with Number of visits, e.g., calculate prior with UTIL_COUNT_UNIQUE_VALUES
  MAX_BOXES_PER_PAGE  REQUIRED: Global user setting to limit number of boxes plotted per page

OUTPUT
  &DS._TP                Updated data set, including TIMEPT var and _PHASE_ var for SHEWHART box plot
  BOXPLOT_TIMEPT_RANGES  global symbol indicating TIMEPT subsets for each plot page (to limit boxes per page)
                         Example: 0 <= timept <7|7 <= timept <12|
***/

%macro util_prep_shewhart_data(ds, vvisn=, vtrtn=, vtrt=, vval=, numtrt=, numvis=);
  %global BOXPLOT_TIMEPT_RANGES;
  %local OK;
  %let OK = 1;

  %let OK = %assert_depend(vars=%str(&DS : &vvisn &vtrtn &vtrt &vval max q3 median q1 min std mean n),
                           symbols=max_boxes_per_page);

  %if &OK %then %do;

    data &ds._tp;
      set &ds end=NoMore;
      by &vvisn &vtrtn;

      keep &vval timept &vtrtn &vtrt max q3 median q1 min std mean n _PHASE_;

      /*** 
        TIMEPT increments are arbitrary, but nec for SAS to separate trt groups along the x-axis
        • INTEGERS identify visits -- floor(+1) for each visit
        • FRACTIONS identify treatments -- +(1/(1+&numtrt)) for each trt, plus 1 for extra spacing between visits
      ***/
      
        retain timept 0;
        if first.&vvisn then timept = floor(timept + 1);
        if first.&vtrtn then timept + (1/(1+&numtrt));

      *--- Create BOXPLOT_TIMEPT_RANGES, to limit number of boxes per plot page to &MAX_BOXES_PER_PAGE ---*;
        length boxplot_timept_ranges $%sysfunc(max(200, %eval(&numtrt*&numvis)));
        retain max_boxes_per_page &max_boxes_per_page
               boxes_on_page 0
               last_timept_end 0
               boxplot_timept_ranges ' ';

        if last.&vvisn then do;
          boxes_on_page = boxes_on_page + &numtrt;

          if boxes_on_page + &numtrt > max_boxes_per_page then do;
            *--- Current visit is enough for this plot, no more boxes, next visit will be too much ---*;
            boxplot_timept_ranges = strip(boxplot_timept_ranges)
                                    !!strip(compbl(  put(last_timept_end,8.-L)
                                                     !!' <= timept <'!!
                                                     put(ceil(timept),8.-L)  ))
                                    !!'|';
            boxes_on_page = 0;
            last_timept_end = timept;
          end;
          else if NoMore then do;
            boxplot_timept_ranges = strip(boxplot_timept_ranges)
                                    !!strip(compbl(  put(last_timept_end,8.-L)
                                    !!' <= timept <'
                                    !!put(timept,8.-L)  ))!!'|';
          end;
        end;

        if NoMore then call symput('boxplot_timept_ranges', strip(boxplot_timept_ranges));
    run;

    %put Note: (UTIL_PREP_SHEWHART_DATA) Default TIMEPT ranges for each plot produces, limiting to &max_boxes_per_page boxes max per page.;
    %put Note: (UTIL_PREP_SHEWHART_DATA) BOXPLOT_TIMEPT_RANGES set to: &boxplot_timept_ranges;

  %end;

%mend util_prep_shewhart_data;
