%* modification 2019-12-23 - update path as data has been moved;
%* dataset adae_updated is not available, but program runs also with adae (slow);

  %LOCAL _num_groups ;

  *** read input datasets: adsl *** ;
  filename source url "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/adsl.xpt" ;
  *filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adsl.xpt" ;
  libname source xport ;
  data work.adsl ;
    set source.adsl ;
  run ;

  *** read input datasets: adsl *** ;
  filename source url "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/adae.xpt" ;
  *filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/adae_updated.xpt" ;
  libname source xport ;
  data work.adae ;
    set source.adae ;
  run ;





%MACRO scriptathon_target24 ; 

  ** DETERMINE HOW MANY ACTIVE TREATMENT GROUPS THERE ARE IN ORDER TO LOOP FOR EACH ONE ***;
  %let _num_groups = 0 ;
  proc sql noprint;
    select count(distinct trt01a) into: _num_groups
    from   work.adsl
  ; 
  quit ;
  %let _num_groups = %trim(%left(&_num_groups)) ;
  %put _num_groups = &_num_groups ;



  %MACRO AEstat (  dsin    = work.adae  
                 , byvar   =
                 , tclause = 
                 , wclause = %STR()
                ) ;

    %LET paramcount = %EVAL(&paramcount. + 1) ;

    proc sort data= work.adae ;
      BY &byvar. ;
    run ; 

    PROC MEANS DATA = work.adae ;
      BY &byvar. ;
      &wclause. ;
      OUTPUT OUT = work.stat&paramcount.
              n  = n
      ; 
    QUIT ;

  %MEND AEstat ;

  %LET paramcount = 0 ;

  *** number of subjects experiencing treatment emergent adverse events *** ;
  %AEstat (dsin = work.adae , byvar = trtan , tclause = trtemfl  , wclause = %NRSTR(WHERE UPCASE(STRIP(SAFFL)) ='Y' AND UPCASE(STRIP(AOCCFL))='Y')) ;

  *** number of subjects experiencing treatment emergent adverse events *** ;
  %AEstat (dsin = work.adae , byvar = trtan aesoc , tclause = AOCCSFL  , wclause = %NRSTR(WHERE UPCASE(STRIP(SAFFL)) ='Y' AND UPCASE(STRIP(AOCCSFL))='Y')) ;

  *** number of subjects experiencing treatment emergent adverse events *** ;
  %AEstat (dsin = work.adae , byvar = trtan aesoc aedecod , tclause = AOCCSFL  , wclause = %NRSTR(WHERE UPCASE(STRIP(SAFFL)) ='Y' AND UPCASE(STRIP(AOCCPFL))='Y')) ;

  





%MEND scriptathon_target24 ; 

%scriptathon_target24 ; 
