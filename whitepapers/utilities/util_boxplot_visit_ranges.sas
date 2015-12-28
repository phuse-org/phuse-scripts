/*** To limit number of boxes per boxplot page, calculate visit ranges for each boxplot page

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

    NUMTRT              REQUIRED: Number of treatments, e.g., calculate prior with UTIL_COUNT_UNIQUE_VALUES
    NUMVIS              REQUIRED: Number of visits, e.g., calculate prior with UTIL_COUNT_UNIQUE_VALUES
    MAX_BOXES_PER_PAGE  REQUIRED: Global user setting to limit number of boxes plotted per page

  OUTPUT
    BOXPLOT_VISIT_RANGES  global symbol indicating VISIT subsets for each plot page (to limit boxes per page)
                           Example: 0 <= avisitn <7|7 <= avisitn <12|

  NOTES

***/

%macro util_boxplot_visit_ranges(ds, vvisn=, vtrtn=, numtrt=, numvis=);
  %global BOXPLOT_VISIT_RANGES;
  %local OK;
  %let OK = 1;

  %let OK = %assert_depend(vars=%str(&DS : &vvisn &vtrtn),
                           symbols=max_boxes_per_page);

  %if &OK %then %do;

    proc sort data=&ds (keep=&vvisn &vtrtn) 
              out=temp_vis_trt nodupkey;
      by &vvisn &vtrtn;
    run;

    data _null_;
      set temp_vis_trt end=NoMore;
      by &vvisn &vtrtn;

      *--- Create BOXPLOT_VISIT_RANGES, to limit number of boxes per plot page to &MAX_BOXES_PER_PAGE ---*;
        length boxplot_visit_ranges $%sysfunc(max(200, %eval(&numtrt*&numvis)));
        retain boxes_on_page 0
               start_visit .
               boxplot_visit_ranges ' ';

        if missing(start_visit) then start_visit = &vvisn;
        boxes_on_page + 1;

        *--- Within a visit, keep all trts together: On last obs for this visit, is there room for another set of boxes? ---*;
        if last.&vvisn then do;

          if NoMore or boxes_on_page + &numtrt > &max_boxes_per_page then do;
            *--- Current visit is enough for this plot. No more boxes. Next visit would be too much ---*;
            boxplot_visit_ranges = strip(boxplot_visit_ranges)
                                   !!strip(compbl(  put(start_visit, best8.-L)
                                                    !!" <= &vvisn <= "
                                                    !!put(&vvisn, best8.-L) ))
                                   !!'|';
            boxes_on_page = 0;
            start_visit = .;
          end;

        end;

        if NoMore then call symput('boxplot_visit_ranges', strip(boxplot_visit_ranges));
    run;

    %util_delete_dsets(temp_vis_trt)

    %put Note: (UTIL_BOXPLOT_VISIT_RANGES) Default visit ranges for each plot produces, limiting to &max_boxes_per_page boxes max per page.;
    %put Note: (UTIL_BOXPLOT_VISIT_RANGES) BOXPLOT_VISIT_RANGES set to: &boxplot_visit_ranges;

  %end;

%mend util_boxplot_visit_ranges;
