/***
  In-line macro to return a string used in a SAS/GRAPH axis statement to set ORDER (axis ranges).
  The macro returns a string like:
    0 to 100 by 10

  -INPUT:
    MIN  data set containing the numeric variable for which you want MIN and MAX
           REQUIRED
           Syntax:  (libname.)memname
           Example: ANA.ADVS
    MAX  variable on DSET containing non-missing values
           REQUIRED
           Syntax:  variable-name
           Example: AVAL

  -OUTPUT:
    <string> return IN-LINE to be used in an AXIS ORDER=(<string>) statement.

  -EXAMPLE:
    axis1 order=(%util_axis_order(&non-missing-min, &non-missing-max)); 

  Author:          Dante Di Tommaso
***/

%macro util_axis_order(min, max);
  %local OK emin emax omin omax step;

  %if %sysevalf(&min >= &max) or 
      "&min" = "." or "&max" = "." or 
      %length(&min) = 0 or %length(&max) = 0 %then %do;
    %put ERROR: (UTIL_AXIS_ORDER) MIN (&min) and MAX (&max) must be ascending, non-missing numeric values.;
  %end;
  %else %do;

    %*--- Determine Orders-of-magnitude by expressing values in scientific notation ---*;
      %let emin = %sysfunc(putn(&min, e10.));
      %let emax = %sysfunc(putn(&max, e10.));

      %let omin = %scan(&emin,2,E);
      %let omax = %scan(&emax,2,E);

      %*--- Dissimilar orders of magnitude? Just use integers. ---*;
        %if (&omin < 0 and &omax >= 0) or (&omin >= 0 and &omax < 0) %then %do;
          %if &omin < 0 %then %let omin = 0;
          %else %if &omax < 0 %then %let omax = 0;
        %end;

    %*--- Set the default STEP, based on MIN, MAX orders of magnitude ---*;
      %let step = %sysevalf(%sysfunc(abs(&omin - &omax)));

      %if &omax >= 0 %then %let step = %sysevalf(10 ** &step);
      %else %let step = %sysevalf(10 ** (-&step));

      %if %sysevalf( (&max - &min)/&step < 4 ) %then %let step = %sysevalf(&step/2);
      %else %if %sysevalf( (&max - &min)/&step > 12 ) %then %let step = %sysevalf(&step*2);

    %let emin = %sysevalf( %sysfunc(floor(&min/&step)) * &step );
    %let emax = %sysevalf( %sysfunc(ceil(&max/&step)) * &step );

    &emin to &emax by &step
  %end;
%mend util_axis_order;


/*** TEST calls

  %put [%util_axis_order(88.2, 20.2)];        *** NB: ERROR condition ***;
  %put [%util_axis_order(20.2, 20.2)];        *** NB: ERROR condition ***;
  %put [%util_axis_order(87.9999, 88.0001)];

  %put [%util_axis_order(0.00009, 202)];
  %put [%util_axis_order(8.8, 20.2)];
  %put [%util_axis_order(7.9, 8.8)];
  %put [%util_axis_order(42, 2725)];
  %put [%util_axis_order(-2029, -39)];

  %put [%util_axis_order(-88, 202)];
  %put [%util_axis_order(-202, 72)];

  %put [%util_axis_order(0.000038, 0.00202)];
  %put [%util_axis_order(-0.00202, -0.000038)];
  %put [%util_axis_order(-0.00202, 0.000038)];
  %put [%util_axis_order(-0.000038, 0.00202)];

***/
