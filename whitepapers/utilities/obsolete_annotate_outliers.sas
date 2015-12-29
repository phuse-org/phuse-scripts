/***
  From input data set such as boxplot data, output an annotate data set to plot
  filled circles for outliers according to normal range criteria

  ---
    Development Freeze: OBSOLETE MACRO
    This approach is not longer needed in SAS 9.4 scripts,
    which now use a GTL approach instead on annotating a traditional graphic.
  ---

  INPUTS                                                                              
    DSET      data set containing the measurement values and normal range values
              REQUIRED - positional
              Syntax:  (libname.)memname
              Example: CSS_PLOTDATA
    ANNOSET   annotate data set to create, to draw filled circles for outliers
              REQUIRED - positional
              Syntax:  (libname.)memname
              Example: CSS_ANNOTATE
    X_VAR     X-axis variable, expecting a timepoint variable as initiatize in %util_prep_shewhart_data
              REQUIRED
              Syntax:  variable name from &DATASET
              Example: TIMEPT
    Y_VAR     variable with measurement data, to test against normal range values on same obs
              REQUIRED
              Syntax:  variable name from &DATASET
              Example: AVAL

    LOW_VAR   variable with low value of normal range, to test measured value (NB: annotate values with Y_VAR < LOW_VAR)
              optional
              Syntax:  variable name from &DATASET
              Example: ANRLO 
    HIGH_VAR  variable with high value of normal range, to test measured value (NB: annotate values with HIGH_VAR < Y_VAR)
              optional
              Syntax:  variable name from &DATASET
              Example: ANRHI
    JITTER    N/Y to jitter annotations around the X_VAR value
              optional - but if used, then NUMTRT is REQUIRED
              Syntax:  y (default is n)
              Example: n
    NUMTRT    Number of treatments, e.g., calculate before with UTIL_COUNT_UNIQUE_VALUES. (See NOTES, below.)
              optional - but REQUIRED if JITTER = Y
              Syntax:  integer number of treatments, or macro variable that resolves to an integer
              Example: 3
    COLOR     color of annotated symbols
              optional
              Syntax:  color-specification
              Example: red (Default is RED)
    SIZE      size of annotated symbols, as percentage of graphics area (see HSYS annotate variable)
              optional
              Syntax:  size-as-percentage-of-graph-area
              Example: 2 (Default is 2, to match)

  OUTPUT
    ANNOSET  an annotate data set that draws filled circles on a plot
                                                                                           
  NOTES
    Provide either LOW_VAR, HIGH_VAR or both. If you provide neither, macro returns a null annotate data set.
    JITTER: Logic based on ±8% of spacing used for PROC SHEWHART boxplot. See UTIL_PREP_SHEWHART_DATA

    http://support.sas.com/documentation/cdl/en/graphref/63022/HTML/default/viewer.htm#annodict-var.htm
    http://support.sas.com/documentation/cdl/en/graphref/63022/HTML/default/viewer.htm#annotate_hsys.htm
    http://support.sas.com/documentation/cdl/en/graphref/63022/HTML/default/viewer.htm#annodict-symbol.htm

  Author:          Dante Di Tommaso
***/

%macro obsolete_annotate_outliers(dset,
                              annoset,
                              x_var=,
                              y_var=,
                              low_var=,
                              high_var=,
                              jitter=N,
                              numtrt=,
                              color=RED,
                              size=1);

  %local OK;

  %if %assert_dset_exist(&dset) &
      %assert_var_exist(&dset, &x_var) &
      %assert_var_exist(&dset, &y_var) %then %let OK = 1;

  %if &OK and %length(&low_var) > 0 %then
      %let OK = %assert_var_exist(&dset, &low_var);
  
  %if &OK and %length(&high_var) > 0 %then
      %let OK = %assert_var_exist(&dset, &high_var);
  
  %if %length(annoset) = 0 %then %let annoset = css_annotate;

  %if &OK %then %do;

    data &annoset (keep=function hsys text size color x xsys y ysys);
      set &dset;

      function = 'SYMBOL';

      * On the horizontal axis (typically TimePT), introduce user-selected jitter *;
        x = &x_var;
        y = &y_var;

        %if %upcase(&jitter) = Y %then %do;
          %if %length(&numtrt) > 0 and %datatyp(&numtrt) = NUMERIC %then %do;
            * jitter size is based on ±8% of spacing used for PROC SHEWHART boxplot., *;
              jitter = 0.08 / (1+&numtrt);
              jitter = ranuni(29507) * jitter;
              if ranuni(41385) > 0.5 then jitter = -1 * jitter;

              x = x + jitter;
          %end;
          %else %put WARNING: (UTIL_ANNOTATE_OUTLIERS) Unable to jitter annotated symbols based on %upcase(&numtrt) treatments.;
        %end;

      * SIZE variable is percentage of graphic space *;
        hsys = '3';
        size = &size;

      * X and Y variables contain data values *;
        xsys = '2';
        ysys = '2';

      %if %length(&low_var) > 0 and %length(&high_var) > 0 %then %do;

        * ANNOTATE non-missing obs with valid LOW and HIGH limits *;
        if (n(y, &low_var)  = 2 and y < &low_var) or 
           (n(&high_var, y) = 2 and &high_var < y);

      %end;
      %else %if %length(&low_var) > 0 %then %do;

        * ANNOTATE non-missing obs with valid LOW limit *;
        if n(y, &low_var)  = 2 and y < &low_var;

      %end;
      %else %if %length(&high_var) > 0 %then %do;

        * ANNOTATE non-missing obs with valid HIGH limit *;
        if n(&high_var, y) = 2 and &high_var < y;

      %end;

      * Draw a filled DOT with user-selected COLOR *;
        length color $%sysfunc(max(5, %length(&color))) text $6;

        color = "%upcase(&color)";
        text = 'DOT';
        OUTPUT;
    run;

    %put NOTE: (UTIL_ANNOTATE_OUTLIERS) Successfully created annotate data set %upcase(&ANNOSET).;
  %end;
  %else %put ERROR: (UTIL_ANNOTATE_OUTLIERS) Unable to create an annotate data set based on parameters provided. See log messages.;

%mend obsolete_annotate_outliers;
