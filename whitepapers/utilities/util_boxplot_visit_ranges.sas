/*** To limit number of boxes per boxplot page, calculate visit ranges for each boxplot page
     Macro keeps together ALL TREATMENTS within each VISIT block.
     EG: Either print all TRTs in VISIT X together on this page, or on the next page.

  INPUTS
    DS          Data set including (1) measurements to plot, and (2) vars to be used for "block" labels
      REQUIRED
      Syntax:   Expecting one-level WORK data set name
      Example:  PLOT_DATA
    VVISN
      REQUIRED
      Syntax:   Numeric variable on DS containing visit numbers
      Example:  AVISITN
    VTRTN
      REQUIRED
      Syntax:   Numeric variable on DS containing treatment numbers
      Example:  TRTPN

    MAX_BOXES_PER_PAGE  REQUIRED: Global user setting to limit number of boxes plotted per page

  OUTPUT
    BOXPLOT_VISIT_RANGES  global symbol indicating VISIT subsets for each plot page (to limit boxes per page)
                          Example: 0 <= avisitn <7|7 <= avisitn <12|

  NOTES

***/

%macro util_boxplot_visit_ranges(ds, vvisn=, vtrtn=);
  %global BOXPLOT_VISIT_RANGES;
  %local OK numvis numtrt vistyp vislen;
  %let OK = 1;

  %let OK = %assert_depend(vars=%str(&DS : &vvisn &vtrtn),
                           symbols=max_boxes_per_page);

  %if &OK %then %do;

    *--- Expect VISIT var of type N, but handle char var of type C ---*;
      data _null_;
        set &ds;
        call symput('vistyp', vtype(&vvisn));
        call symput('vislen', vlength(&vvisn));
        STOP;
      run;

      %if &vistyp = C %then %do;
        %let vislen = $&vislen;
        %put WARNING: (UTIL_BOXPLOT_VISIT_RANGES) Expecting NUMERIC visit numbers. Results may be unexpected.;
      %end;
      

    %*--- Get totals from this data set. These are the max values. Some TRTs may not appear in all VISs. ---*;
    %util_count_unique_values(&ds, &vvisn, numvis)
    %util_count_unique_values(&ds, &vtrtn, numtrt)

    proc sort data=&ds (keep=&vvisn &vtrtn) 
              out=temp_vis_trt nodupkey;
      by &vvisn &vtrtn;
    run;

    data _null_;
      set temp_vis_trt end=NoMore;
      by &vvisn &vtrtn;

      *--- Create BOXPLOT_VISIT_RANGES, to limit number of boxes per plot page to &MAX_BOXES_PER_PAGE ---*;
        length boxplot_visit_ranges $%sysfunc(max(200, %eval(&numvis*&numtrt)))
               start_visit &vislen;
        retain boxes_on_page 0
               boxplot_visit_ranges ' '
               %if &vistyp = C %then start_visit ' ';
               %else start_visit .;
               ;

        if missing(start_visit) then start_visit = &vvisn;
        boxes_on_page + 1;

        *--- Within a visit, keep all trts together: On last obs for this visit, is there room for another set of boxes? ---*;
        if last.&vvisn then do;

          if NoMore or boxes_on_page + &numtrt > &max_boxes_per_page then do;
            *--- Current visit is enough for this plot. No more boxes. Next visit would be too much ---*;
            %if &vistyp = C %then %do;
              boxplot_visit_ranges = strip(boxplot_visit_ranges)
                                     !!strip(compbl(  quote(strip(start_visit))
                                                      !!" <= &vvisn <= "
                                                      !!quote(strip(&vvisn)) ))
                                     !!'|';
            %end;
            %else %do;
              boxplot_visit_ranges = strip(boxplot_visit_ranges)
                                     !!strip(compbl(  put(start_visit, best8.-L)
                                                      !!" <= &vvisn <= "
                                                      !!put(&vvisn, best8.-L) ))
                                     !!'|';
            %end;

            boxes_on_page = 0;

            %if &vistyp = C %then start_visit = ' ';
            %else start_visit = .;
            ;
          end;

        end;

        if NoMore then call symput('boxplot_visit_ranges', strip(boxplot_visit_ranges));
    run;

    %util_delete_dsets(temp_vis_trt)

    %put Note: (UTIL_BOXPLOT_VISIT_RANGES) Default visit ranges for each plot produces, limiting to &max_boxes_per_page boxes max per page.;
    %put Note: (UTIL_BOXPLOT_VISIT_RANGES) BOXPLOT_VISIT_RANGES set to: &boxplot_visit_ranges;

  %end;

%mend util_boxplot_visit_ranges;
