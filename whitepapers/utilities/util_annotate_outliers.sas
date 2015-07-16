/***
  From input data set such as boxplot data, output an annotate data set to plot
  filled circles for outliers according to normal range criteria
                                                                                           
  DSET     data set containing the measurement values and normal range values
           REQUIRED                                                                         
           Syntax:  (libname.)memname
           Example: CSS_PLOTDATA
  ANNOSET  annotate data set to create, to draw filled circles for outliers
           REQUIRED
           Syntax:  (libname.)memname
           Example: CSS_ANNOTATE
  X_VAR    X-axis variable, expecting a timepoint variable as initiatize in %util_prep_shewhart_data
           REQUIRED
           Syntax:  variable name from &DATASET
           Example: TIMEPT
  Y_VAR    variable with measurement data, to test against normal range values on same obs
           REQUIRED
           Syntax:  variable name from &DATASET
           Example: AVAL
  LOW_VAR  variable with low value of normal range, to test measured value (NB: annotate values with Y_VAR < LOW_VAR)
           optional
           Syntax:  variable name from &DATASET
           Example: ANRLO 
  HIGH_VAR variable with high value of normal range, to test measured value (NB: annotate values with HIGH_VAR < Y_VAR)
           optional
           Syntax:  variable name from &DATASET
           Example: ANRHI
  COLOR    color of annotated symbols
           optional
           Syntax:  color-specification
           Example: red (Default color)
  SIZE     size of annotated symbols, as percentage of graphics area (see HSYS annotate variable)
           optional
           Syntax:  size-as-percentage-of-graph-area
           Example: 5 (Default size)

  Notes:
    Provide either LOW_VAR, HIGH_VAR or both.
    If you provide neither, macro returns a null annotate data set.
    http://support.sas.com/documentation/cdl/en/graphref/63022/HTML/default/viewer.htm#annodict-var.htm
    http://support.sas.com/documentation/cdl/en/graphref/63022/HTML/default/viewer.htm#annotate_hsys.htm
    http://support.sas.com/documentation/cdl/en/graphref/63022/HTML/default/viewer.htm#annodict-symbol.htm

  -OUTPUT
    ANNOSET  an annotate data set that draws filled circles on a plot
                                                                                           
  Author:          Dante Di Tommaso
***/

%macro util_annotate_outliers(dset,
                              annoset,
                              x_var=,
                              y_var=,
                              low_var=,
                              high_var=,
                              color=red,
                              size=2);

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

      x = &x_var;
      y = &y_var;

      * SIZE variable is percentage of graphic space *;
        hsys = '3';
        size = &size;

      * X and Y variables contain data values *;
        xsys = '2';
        ysys = '2';

      %if %length(&low_var) > 0 and %length(&high_var) > 0 %then %do;

        if (n(y, &low_var) = 2 and y < &low_var) or 
           (n(&high_var, y)= 2 and &high_var < y);

      %end;
      %else %if %length(&low_var) > 0 %then %do;

        if n(y, &low_var) = 2 and y < &low_var;

      %end;
      %else %if %length(&high_var) > 0 %then %do;

        if n(&high_var, y)= 2 and &high_var < y;

      %end;

      * Draw an outline circle in black, then fill with user-specified colored dot *;
      length color $%sysfunc(max(5, %length(&color))) text $6;

      color = "%upcase(&color)";
      text = 'DOT';
        OUTPUT;
      color = 'BLACK';
      text = 'CIRCLE';
        OUTPUT;
    run;

    %put NOTE: (UTIL_ANNOTATE_OUTLIERS) Successfully created annotate data set %upcase(&ANNOSET).;
  %end;
  %else %put ERROR: (UTIL_ANNOTATE_OUTLIERS) Unable to create an annotate data set based on parameters provided. See log messages.;

%mend util_annotate_outliers;
