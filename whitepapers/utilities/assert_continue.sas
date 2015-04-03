/***

This defines the error handling of the PhUSE/CSS template programs.
In case of error, continue checking syntax, but do not waste time or effort to process data.

The template program creates global symbol CONTINUE, a boolean:
  1 = &CONTINUE means everything is OK, so do nothing
  0 = &CONTINUE means some condition failed, so enter syntax-checking mode (set OBS=0)

This macro checks the value of global symbol &CONTINUE, and forces syntax-checking mode when indicated.

INPUTS
  CONTINUE  Global symbol created prior to macro invocation in PhUSE/CSS template program
  MSG       Positional parameter for free-text, quoted as needed, to allow the calling program
            to indicate the reason for or timing of this check. This message appears in the log.

***/

%macro assert_continue(msg);
  %if %symexist(continue) %then %do;
    %if &continue %then %put NOTE: (ASSERT_CONTINUE) &msg.. OK to continue.;
    %else %do;
      %put ERROR: (ASSERT_CONTINUE) &msg.. CONTINUE = &CONTINUE.. Forcing syntax-checking mode.;

      %if &sysenv = FORE %then %do;
        %put ERROR: (ASSERT_CONTINUE) &msg.. To reset syntax-checking mode, save your work and restart SAS.;
      %end;

      data css_do_not_create;
        set css_does_not_exist;
        put 'The sole purpose of this invalid data step is to force syntax-checking mode.';
      run;
    %end;
  %end;
  %else %put ERROR: (ASSERT_CONTINUE) &msg.. Global symbol CONTINUE expected, but does not exist.;
%mend assert_continue;
