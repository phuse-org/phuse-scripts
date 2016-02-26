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

  Author:          Dante Di Tommaso
***/

%macro obsolete_util_boxplot_ranges(ds, vvisn=, vtrtn=);
  %global BOXPLOT_VISIT_RANGES;
  %local OK numvis numtrt vistyp vislen max_length;
  %let OK = 1;

  %let OK = %assert_depend(vars=%str(&DS : &vvisn &vtrtn),
                           symbols=max_boxes_per_page);

  %if &OK %then %do;
    %*--- Expect only NON-MISSING values for both VISIT and TREATMENT ---*;
      %if not %assert_var_nonmissing(&ds, &vvisn) %then %put WARNING: (OBSOLETE_UTIL_BOXPLOT_RANGES) Variable "%upcase(&ds..&vvisn)" has missing values. Results may be unexpected.;
      %if not %assert_var_nonmissing(&ds, &vtrtn) %then %put WARNING: (OBSOLETE_UTIL_BOXPLOT_RANGES) Variable "%upcase(&ds..&vtrtn)" has missing values. Results may be unexpected.;

    %*--- Get VIS and TRT counts from the data. These are the max values. Some TRTs may not appear in all VISs. ---*;
      %util_count_unique_values(&ds, &vvisn, numvis)
      %util_count_unique_values(&ds, &vtrtn, numtrt)

      %if &numtrt > &max_boxes_per_page %then %do;
        %put WARNING: (OBSOLETE_UTIL_BOXPLOT_RANGES) Treatment count (&NUMTRT) is greater than Max boxes per page (&MAX_BOXES_PER_PAGE). Keeping treatments together, Max boxes per page is effectively &NUMTRT..;
      %end;


    *--- Expect VISIT var of type N, but handle char var of type C ---*;
      data _null_;
        set &ds;
        call symput('vistyp', vtype(&vvisn));
        call symput('vislen', vlength(&vvisn));
        STOP;
      run;

      %let vistyp = &vistyp;
      %let vislen = &vislen;

      %*--- How long could the return string be? For CHAR vars, it could get quite long. 
        Pattern: "<var-value>" <= <var-name> <= "<var-value>"|
                 (quotes only used for CHAR vars)
                 (NUMERIC vals are unlikely to format wider than 30 chars - long date-time formats)
        Max len: <20 spacing chars + 2*<var-length> + <varname-length>
        Repeat:  for each page of boxes. Max pages = num visits (one visit per page).
      ---*;
        %let max_length = %eval( 20 + 2*%sysfunc(max(30, &vislen)) + %length(&vvisn) );
        %let max_length = %eval( &numvis*&max_length );

      %if &vistyp = C %then %do;
        %let vislen = $&vislen;
        %put WARNING: (OBSOLETE_UTIL_BOXPLOT_RANGES) Expecting NUMERIC visit numbers, not CHAR &vislen.. Results may be unexpected.;
      %end;


    proc sort data=&ds (keep=&vvisn &vtrtn) 
              out=temp_vis_trt nodupkey;
      by &vvisn &vtrtn;
    run;

    data _null_;
      set temp_vis_trt end=NoMore;
      by &vvisn &vtrtn;

      *--- Create BOXPLOT_VISIT_RANGES, to limit number of boxes per plot page to &MAX_BOXES_PER_PAGE ---*;
        length boxplot_visit_ranges $&max_length
               start_visit &vislen;
        retain boxes_on_page 0
               boxplot_visit_ranges ' '
               %if &vistyp = C %then start_visit ' ';
               %else start_visit .;
               ;

        if 0 = boxes_on_page then start_visit = &vvisn;
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
          end;

        end;

        if NoMore then call symput('boxplot_visit_ranges', strip(boxplot_visit_ranges));
    run;

    %util_delete_dsets(temp_vis_trt)

    %put Note: (OBSOLETE_UTIL_BOXPLOT_RANGES) Default visit ranges for each plot produces, limiting to &max_boxes_per_page boxes max per page.;
    %put Note: (OBSOLETE_UTIL_BOXPLOT_RANGES) BOXPLOT_VISIT_RANGES set to: &boxplot_visit_ranges;

  %end;

%mend obsolete_util_boxplot_ranges;
