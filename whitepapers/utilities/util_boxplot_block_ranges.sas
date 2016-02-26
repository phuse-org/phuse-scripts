/*** To limit number of boxes per boxplot page, calculate x-axis CATEGORY ranges for each boxplot page
     Macro keeps together ALL CATEGORIES within each BLOCK.
     EG: Keep all TRTs within a VISIT together on a page, or
         Keep all VISIT*TRT within a STUDY together on a page.

  INPUTS
    DS          Data set including (1) measurements to plot, and (2) vars to be used for "block" labels
      REQUIRED positional
      Syntax:   Expecting one-level WORK data set name
      Example:  PLOT_DATA
    BLOCKVAR
      REQUIRED keyword
      Syntax:   Variable on DS containing BLOCK identifier (keep all CATVARS levels together)
      Example:  AVISITN
    CATVARS
      REQUIRED keyword
      Syntax:   Space-delimited list of variables on DS, used to identify & count distinct boxes within each BLOCK
      Example:  TRTPN
    SYM
      optional keyword
      Syntax:   Valid macro variable (symbol) name
      Example:  BOXPLOT_BLOCK_RANGES (the Default)

    MAX_BOXES_PER_PAGE  REQUIRED: Global user setting to limit number of boxes plotted per page

  OUTPUT
    BOXPLOT_BLOCK_RANGES  global symbol indicating VISIT subsets for each plot page (to limit boxes per page)
                          Example: 0 <= avisitn <7|7 <= avisitn <12

  Author:          Dante Di Tommaso
***/

%macro util_boxplot_block_ranges(ds, blockvar=, catvars=, sym=boxplot_block_ranges);
  %global &sym;
  %local OK missopt idx nxt blocktyp blocklen max_length brr_scrap;

  %let OK = 1;
  %let OK = %assert_depend(vars=%str(&DS : &blockvar &catvars), symbols=max_boxes_per_page);

  %if &OK %then %do;

    *--- Ensure that missing numerics print as '.' ---*;
      %let missopt = %qsysfunc(getoption(missing));
      options missing='.';

    proc sort data=&ds (keep=&blockvar &catvars)
              out=bbr_cats nodupkey;
      by &blockvar &catvars;
    run;

    proc freq data=bbr_cats noprint;
      tables &blockvar / missing out=brr_counts (drop=percent);
    run;

    data brr_pages;
      set brr_counts end=NoMore;
      by &blockvar ;

      retain pagecount 0 page 1;

      if first.&blockvar then do;
        *--- Alert user when the number of categories is immediately greater than MAX_BOXES_PER_PAGE ---*;
          if count > &max_boxes_per_page then 
             put "WARNING: (UTIL_BOXPLOT_BLOCK_RANGES) MAX_BOXES_PER_PAGE (&max_boxes_per_page) is too small for this blocking: " &blockvar= count=;
        *--- This BLOCK starts the next page, if current page cannot contain this set of categories ---*;
          if pagecount + count > &max_boxes_per_page then do;
            page+1;
            pagecount = count;
          end;
          else pagecount + count;
      end;

      *--- Get TYPE and LENGTH of BLOCKVAR, to determine length of the subsetting clauses created next ---*;
      if NoMore then do;
        call symput('blocktyp', vtype(&blockvar));
        call symput('blocklen', vlength(&blockvar));
      end;
    run;

    %let blocktyp = &blocktyp;
    %let blocklen = &blocklen;

    %*--- How long could subsetting string be? For CHAR vars, it could get quite long.
      Pattern: "<var-value>" <= <var-name> <= "<var-value>"
               (quotes only used for CHAR vars. NUMERIC vals are unlikely to format wider than 30 chars)
      Max len: <20 spacing chars + 2*<var-length> + <varname-length>
    ---*;
      %let max_length = %eval( 20 + 2*%sysfunc(max(30, &blocklen)) + %length(&blockvar) );


    data brr_ranges;
      set brr_pages;
      by page;

      attrib range length=$&max_length;
      retain range ' ';

      %if &blocktyp = N %then %do;
        if first.page then range = strip(put(&blockvar,8.-L)) !!"<=&blockvar";
        if last.page then do;
          range = strip(range)!!"<="!!put(&blockvar,8.-L);
          OUTPUT;
        end;
      %end;
      %else %do;
        if first.page then range = quote(strip(&blockvar)) !!"<=&blockvar";
        if last.page then do;
          range = strip(range)!!"<="!!quote(strip(&blockvar));
          OUTPUT;
        end;
      %end;
    run;

    %global &sym;
    %local brr_scrap;

    proc sql noprint;
      select distinct range, &blockvar into :&sym separated by '|', :brr_scrap
      from brr_ranges
      order by &blockvar;
    quit;

    %util_delete_dsets(bbr_cats brr_counts brr_pages brr_ranges)

    %put NOTE: (UTIL_BOXPLOT_BLOCK_RANGES) Default block ranges for each plot produces, limiting to &max_boxes_per_page boxes max per page.;
    %put NOTE: (UTIL_BOXPLOT_BLOCK_RANGES) %upcase(&sym) set to: &&&sym;

    *--- Restore prior display of missing numerics ---*;
      options missing="&missopt";

  %end;

%mend util_boxplot_block_ranges;
