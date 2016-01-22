/***
  In-line macro to return a string used in a SAS/GRAPH axis statement to set ORDER (axis ranges).
  The macro returns a string like:
    0 to 100 by 10

  -INPUT:
    MIN   minimum data value to include in the resulting step-wise axis interval
            REQUIRED
            Syntax:  non-missing number, less than MAX
            Example: 4.8
    MAX   maximum data value to include in the resulting step-wise axis interval
            REQUIRED
            Syntax:  non-missing number, greater than MIN
            Example: 23.42
    ticks maximum number of ticks on the continuous axis. you will see about this many (it is NOT exact)
            OPTIONAL
            Syntax:  Positive integer
            Example: 16

  -OUTPUT:
    <string> return IN-LINE to be used in an AXIS ORDER=(<string>) statement.

  -EXAMPLE:
    axis1 order=(%util_axis_order(&non-missing-min, &non-missing-max)); 

  Author:   Dante Di Tommaso
***/

%macro util_axis_order(min, max, ticks=10);
  %local OK diff estep emin emax omin omax step;

  %if %sysevalf(&min >= &max) or 
      %datatyp(&min) = CHAR or %datatyp(&max) = CHAR or 
      %length(&min) = 0 or %length(&max) = 0 %then
      %put ERROR: (UTIL_AXIS_ORDER) MIN (&min) and MAX (&max) must be ascending, non-missing numeric values.;
  %else %if %length(&ticks) > 0 and %datatyp(&ticks) = CHAR %then
      %put ERROR: (UTIL_AXIS_ORDER) TICKS (&ticks) must be a non-missing, positive value.;
  %else %do;

    %*--- TICKS must be a positive integer, so avoid trouble ---*;
      %if %sysevalf(&ticks < 1) %then %let ticks = 10;
      %else %let ticks = %sysfunc(intz(&ticks));

    %*--- Interval to cover ---*;
      %let diff = %sysevalf(&max - &min);

    %*--- Initialize STEP based on max number of ticks specified ---*;
      %let step = %sysevalf(&diff / &ticks);

    %*--- Round UP the step size to the nearest increment, for this order of magnitude ---*;
      %let estep = %sysfunc(putn(&step, e10.));
      %let eexpo = %scan(&estep,2,E);
      %let ecoef = %sysevalf(%sysfunc( ceil(%scan(&estep,1,E)) ));

      %let step  = %sysfunc(putn(&ecoef.E&&eexpo, best10.));
 
    %*--- Set axis limits to cover the range and step nicely ---*;
      %let emin = %sysevalf( %sysfunc(floor(&min/&step)) * &step );
      %let emax = %sysevalf( %sysfunc(ceil(&max/&step)) * &step );

    &emin to &emax by &step

  %end;
%mend util_axis_order;
