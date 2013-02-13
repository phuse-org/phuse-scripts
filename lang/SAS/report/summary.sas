/**********************  SUMMARY MACRO *************************
*                                                              *
*  This macro generates a table of summary statistics with by  *
*  variables                                                   *
*                                                              *
****************************************************************/

%macro summary(var=,      /* list of variables to summarise */
               stats=n mean std median min max, /* summary stats, as in proc univariate */
               by=,       /* by variable(s) */
               pagevar=,  /* page variable */
               column=,   /* column (e.g. treatment) variable */
               colorder=INTERNAL, /* ordering option for columns */
               missing=Y, /* missing option as in PROC REPORT */
               compstat=, 
               analysis=,
               transfor=, /* option for log transformations */
               baseline=, 
               timevar=,  /* visit variable */
               subjvar=,  /* subject variable */
               chconcat=, 
               cmpwhere=,
               diagfile=,
               outfile=,  /* output filename */
               filetype=TXT,          /* TXT or HTML or PDF or RTF */
               gencode=,  /* filename for generated code */
               pagenum=,  /* add x of y to footer */
               spacing=2, /* default spacing for PROC REPORT */
               style=2,   /* 1 or 2: 1 across, 2 down */
               statfmt=%str($kkxstat.), /* format for statistics */
               data=_last_, /* input dataset */
			   stathead=Value, /* column heading for stats */
               dwhere=             /* where clause */);  

*options nomlogic nomprint nosymbolgen;

%let debug = N;

%if "&gencode" ne "" %then %do;
  filename gencode "&gencode" mod;
%end;

%if %upcase(&filetype) ne HTML 
  and %upcase(&filetype) ne PDF 
  and %upcase(&filetype) ne RTF 
  and %upcase(&filetype) ne TXT 
  and %upcase(&filetype) ne ASCII 
    %then %put WARNING: Filetype option not recognised.  TXT file will be produced;

options mautosource;

/*** put all the requested statistics into individual macro variables ***/
%let statcnt=1;
%let word = %scan(&stats,&statcnt,%str( ));
%do %while(&word~=);
  %let kkstat&statcnt=%upcase(&word);
  %if "&&kkstat&statcnt" ne "KURTOSIS"
  and "&&kkstat&statcnt" ne "N"
  and "&&kkstat&statcnt" ne "P1"                                 
  and "&&kkstat&statcnt" ne "Q1"                                 
  and "&&kkstat&statcnt" ne "CSS"                                
  and "&&kkstat&statcnt" ne "MAX"                                
  and "&&kkstat&statcnt" ne "NMISS"                              
  and "&&kkstat&statcnt" ne "STD"                                
  and "&&kkstat&statcnt" ne "P5"                                 
  and "&&kkstat&statcnt" ne "Q3"                                 
  and "&&kkstat&statcnt" ne "MSIGN"                              
  and "&&kkstat&statcnt" ne "MEAN"                               
  and "&&kkstat&statcnt" ne "NOBS"                               
  and "&&kkstat&statcnt" ne "SUM"                                
  and "&&kkstat&statcnt" ne "P10"                                
  and "&&kkstat&statcnt" ne "QRANGE"                             
  and "&&kkstat&statcnt" ne "T"                                  
  and "&&kkstat&statcnt" ne "MEDIAN"                             
  and "&&kkstat&statcnt" ne "NORMAL"                             
  and "&&kkstat&statcnt" ne "SUMWGT"                             
  and "&&kkstat&statcnt" ne "P90"                                
  and "&&kkstat&statcnt" ne "STDMEAN"                            
  and "&&kkstat&statcnt" ne "PROBN"                              
  and "&&kkstat&statcnt" ne "MIN"                                
  and "&&kkstat&statcnt" ne "RANGE"                              
  and "&&kkstat&statcnt" ne "VAR"                                
  and "&&kkstat&statcnt" ne "P95"                                
  and "&&kkstat&statcnt" ne "CV"                                 
  and "&&kkstat&statcnt" ne "PROBM"                              
  and "&&kkstat&statcnt" ne "MODE"                               
  and "&&kkstat&statcnt" ne "SIGNRANK"                           
  and "&&kkstat&statcnt" ne "SKEWNESS"                           
  and "&&kkstat&statcnt" ne "P99"                                
  and "&&kkstat&statcnt" ne "USS"                                
  and "&&kkstat&statcnt" ne "PROBS" %then %do;
    %put ERROR: &&kkstat&statcnt IS NOT A VALID STATISTIC AND WILL BE IGNORED;
    %let kkstat&statcnt=;
  %end;
  %let statcnt=%eval(&statcnt+1);
  %let word = %scan(&stats,%eval(&statcnt),%str( ));
%end;
%let statcnt = %eval(&statcnt-1);

%if &pagevar=_var_ %then ;
%else %if &pagevar ne %then %let by=&pagevar &by;

%let missing=%upcase(&missing);
%let colorder=%upcase(&colorder);               

/*** put all the requested by variables into individual macro variables ***/
%let bycnt=1;
%let word = %scan(&by,&bycnt,%str( ));
%do %while(&word~=);
  %let kkby&bycnt=%upcase(&word);
  %let bycnt=%eval(&bycnt+1);
  %let word = %scan(&by,%eval(&bycnt),%str( ));
%end;
%let bycnt = %eval(&bycnt-1);

/*** put all the continuous variables into individual macro variables ***/
%let varcnt=1;
%let wordcnt=1;

%let word = %scan(&var,&varcnt,%str( ));
%do %while(&word~=);
  %let kkvar&varcnt=%upcase(&word);
  %let kkvart&varcnt=;
  %let word = %scan(&var,%eval(&wordcnt+1),%str( ));
  %if %upcase(&word) = %upcase(%nrquote($)) %then %do;
    %let kkvart&varcnt=2;
	%let wordcnt=%eval(&wordcnt+1);
    %let word = %scan(&var,%eval(&wordcnt+1),%str( ));
  %end;
  %let varcnt=%eval(&varcnt+1);
  %let wordcnt=%eval(&wordcnt+1);
%end;
%let varcnt = %eval(&varcnt-1);

%let pagenum=%upcase(&pagenum);

%do i=1 %to &varcnt;
  %put number &i variable was &&kkvar&i type &&kkvart&i;
%end;

/*** store all the variable formats and labels ***/
proc contents data=&data noprint out=kkzz0001 (keep=name type length label format formatl formatd just);
run;

data _null_;
  set kkzz0001;
  length kformat $15;
  if format = '$' then kformat = '$'||compress(put(formatl,7.0))||'.';
  else if format ne '' then kformat = compress(format)||'.';
  else if formatl > 0 then kformat = compress(put(formatl,best.)||'.'||put(formatd,best.));
  /*** get formats and labels for analysis variables ***/
  %do i=1 %to &varcnt;
    if compress(upcase(name)) = "&&kkvar&i" then do;
      if length(compress(label))>0 and label ne " " then call symput("kkvrlb&i",trim(left(label)));
      else call symput("kkvrlb&i",upcase(compress(name)));
      call symput("kkvrft&i",compress(kformat));
      call symput("kkvrfl&i",compress(put(formatl,best.)));
      call symput("kkvrfd&i",compress(put(formatd,best.)));
      %if &&kkvart&i= %then call symput("kkvart&i",type);;
      call symput("kkvrty&i",type);;
    end;
  %end;
  /*** get formats and labels for by variables ***/
  %do i=1 %to &bycnt;
    if compress(upcase(name)) = "&&kkby&i" then do;
      if length(compress(label))>0 and label ne " " then call symput("kkbylb&i",trim(left(label)));
      else call symput("kkbylb&i",upcase(compress(name)));
      call symput("kkbyft&i",compress(kformat));
      call symput("kkbyty&i",type);
    end;
  %end;
  /*** get the label for the cross variable ***/
  if compress(upcase(name)) = %upcase("&column") then do;
    if length(compress(label))>0 and label ne " " then call symput("kkcollb",trim(left(label)));
    else call symput("kkcollb",upcase(compress(name)));
    call symput("kkcolfmt",trim(kformat));
    call symput("kkcoltp",trim(type));
  end;
run;

%do i=1 %to &varcnt;
  %put number &i variable was &&kkvar&i with Label=&&kkvrlb&i;
%end;

proc sort data=&data out=_xxphxx_;
  by &column;
  %if "%bquote(&dwhere)" ne "" %then %do;
    where &dwhere;
  %end;
run;

%if %length(&gencode) > 0 %then %do;
  data _null_;
    file gencode mod;
    put "proc sort data=&data out=_xxphxx_;";
    put "  by &column;";
    %if "%bquote(&dwhere)" ne "" %then %do;
      put "  where &dwhere;";
    %end;
    put "run;";
    put;
  run;
%end;

/*** get the column labels ***/
%if %length(&column)>0 %then %do;
  proc sort data=_xxphxx_ (keep=%do i=1 %to &varcnt; &&kkvar&i %end; &column) nodupkey out=kkss0001;
    by &column;
  run;
  
  data kkss0002;
    length kkcl $ 100;
    set kkss0001;
    %if %length(&kkcolfmt)>0 %then kkcl = put(&column,&kkcolfmt);
    %else kkcl=&column;;
  %if &colorder=FORMATTED %then %do;
    proc sort;
      by kkcl;
    run;
  %end;
  %else %if &colorder=INTERNAL %then %do;
    proc sort;
      by &column;
    run;
  %end;

  %if &debug=Y %then %do;
    proc print;
      title "column labels";
    run;
  %end;

  data _null_; 
    set kkss0002;
    call symput("kkcllb"||compress(_n_),kkcl);
  run;
%end;

%let catcnt=;
%let colcnt=;
%let kkcont=0;
%let kkwrst=0;
%let kkchisq=0;
%let kkpwchsq=0;
%let kkmaxf = -9;

%let varlen = 0;
%do i=1 %to &varcnt;
  %if %length(&&kkvar&i)>&varlen %then %let varlen=%length(&&kkvar&i);
  %if %length(&&kkvrlb&i)>&varlen %then %let varlen=%length(&&kkvrlb&i);
%end;

/*** check what comparative statistics are required ***/
%let compcnt=1;
%let comp = %scan(&compstat,&compcnt,%str(|));
%do %while(%length(%trim(&comp))>0);
  %let kkcomp&compcnt=%upcase(&comp);
  %let compcnt = %eval(&compcnt+1);
  %let comp = %scan(&compstat,&compcnt,%str(|));
%end;
%let compcnt = %eval(&compcnt-1);

%let kkctstln=0;
%let kkcompt=;
%do i=1 %to &compcnt;
  %let keyword=%scan(&&kkcomp&i,1,{}* );
  %if &keyword=PWCHISQ %then %let keyword=PAIRED CHISQ;
  %if &keyword=CHISQ %then %do;
    %let kkcompt=OVERALL CHISQ;
    %let templen=&kkcompt;
  %end;
  %else %do;
    %if &i=1 %then %do;
      %let kkcompt=&keyword:%qscan(&&kkcomp&i,2,%nrbquote(*));
      %let templen=&kkcompt;
    %end;
    %else %do;
      %let templen=&keyword:%qscan(&&kkcomp&i,2,%nrbquote(*));
      %let kkcompt=&kkcompt#&keyword:%qscan(&&kkcomp&i,2,%nrbquote(*)); 
    %end;
  %end;
  %if %length(%trim(&templen))>&kkctstln %then %let kkctstln=%length(%trim(&templen));
%end;
%if &kkctstln<15 %then %let kkctstln=15;

/*** if there are any categorical variables, get the format to use
     based on the total number of units available for analysis ***/
%let flag=0;
%do i=1 %to &varcnt;
  %if &&kkvart&i=2 %then %let flag=&i;
%end;
%if &flag>0 %then %do;

  data kktemp0;
    set _xxphxx_;
    kkdummy=1;
  proc sort;
    by &by &column &&kkvar&flag;
  run;  

  proc freq noprint;
    table kkdummy/out=kktemp1 noprint;
    %if %eval(%length(&by&column)) > 0 %then by &by &column;;
  run;
  
  /* get relevant formats */
  proc summary noprint;
    var count;
    output out=kktemp2 max=kkmax;
  run;
  
  data _null_;
    set kktemp2;
    if kkmax <10 then width=1;
    else if kkmax < 100 then width=2;
    else if kkmax < 1000 then width=3;
    else if kkmax < 10000 then width=4;
    else if kkmax < 100000 then width=5;
    else if kkmax < 1000000 then width=6;
    else if kkmax < 10000000 then width=7;
    call symput("kkmaxf",width);
  run;
%end;
/*** process each variable ***/  
%do j=1 %to &varcnt;
  
  proc sort data=_xxphxx_ out=kkxx0001;
    by &by &column &&kkvar&j;
  run;

  %if %length(&gencode) > 0 %then %do;
    data _null_;
      file gencode mod;
      put "******************************************;";
      put "* Process variable number &j : &&kkvar&j *;";
      put "******************************************;";
      put "proc sort data=_xxphxx_ out=kkxx0001;";
      put "  by &by &column &&kkvar&j;";
      put "run;";
      put;
    run;
  %end;
  
  /*** do the continuous variables***/
  %if &&kkvart&j=1 %then %do;
    /*** get the summary statistics ***/
    proc univariate noprint data=kkxx0001;
      var &&kkvar&j;
      %if %eval(%length(&by&column)) > 0 %then by &by &column;;
      output out=kkxx0002
      %do i=1 %to &statcnt;
        &&kkstat&i %if %length(&&kkstat&i)>0 %then =; &&kkstat&i
      %end;
      ;
      %if %length(&column)>0 %then %do;
        %if &colorder=INTERNAL %then format &column;;
      %end;
    run;

    %if &debug=Y %then %do;
      proc print;
        title "data kkxx0002";
      run;
    %end;

    %if %length(&gencode) > 0 %then %do;
      data _null_;
        file gencode mod;
        put "*** get the summary statistics ***;";
        put "proc univariate noprint data=kkxx0001;";
        put "  var &&kkvar&j;";
        %if %eval(%length(&by&column)) > 0 %then %do;
          put "  by &by &column;";
        %end;
        put "  output out=kkxx0002 " @;
        %do i=1 %to &statcnt;
          put "&&kkstat&i " @;
          %if %length(&&kkstat&i)>0 %then %do;
            put "= &&kkstat&i " @;
          %end;
        %end;
        put ";";
        %if %length(&column)>0 %then %do;
          %if &colorder=INTERNAL %then %do;
            put "  format &column;";
          %end;
        %end;
        put "run;";
        put;
      run;
    %end;

    /*** recode missing so that proc transpose keeps the missing values ***/
    %if %length(&column)>0 %then %do;
      data kkxx0002;
        set kkxx0002;
        %if &kkcoltp=1 %then %do;
          if &column=. then &column=-999999;
        %end;
        %else %do;
          if compress(&column)="" then &column="AAAAAA";
        %end;
      run;

      %if %length(&gencode) > 0 %then %do;
        data _null_;
          file gencode mod;
          put "*** recode missing so that proc transpose keeps the missing values ***;";
          put "data kkxx0002;";
          put "  set kkxx0002;";
          %if &kkcoltp=1 %then %do;
            put "  if &column=. then &column=-999999;";
          %end;
          %else %do;
            put "  if compress(&column)='' then &column='AAAAAA';";
          %end;
          put "run;";
          put;
        run;
      %end;
    %end;

    /*** arrange in a form suitable for reporting ***/
    proc transpose out=kkxx99&j;
      %if %length(&column)>0 %then id &column;;
      var %do i=1 %to &statcnt;
            &&kkstat&i
          %end;
          ;
      %if %length(&by) > 0 %then by &by;;
    run;

    %if &debug=Y %then %do;
      proc print;
        title "data kkxx99&j";
      run;
    %end;

    %if %length(&gencode) > 0 %then %do;
      data _null_;
        file gencode mod;
        put "*** arrange in a form suitable for reporting ***;";
        put "proc transpose out=kkxx99&j;";
        %if %length(&column)>0 %then %do;
          put "  id &column;";
        %end;
        put "  var " @;
        %do i=1 %to &statcnt;
          put "&&kkstat&i " @;
        %end;
        put ";";
        %if %length(&by) > 0 %then %do;
          put "  by &by;";
        %end;
        put "run;";
        put;
      run;
    %end;

    /*** get the names of the column variables ***/
    proc contents data=kkxx99&j out=kkxx0003(keep=name label format) noprint;
    run;

    data kkxx99&j;
      set kkxx99&j;
      /*** get the maximum length of the var variable ***/
      length var $ &varlen;
      %if %length(&&kkvrlb&j)>0 %then %do;
        var="&&kkvrlb&j";
      %end;
      %else var="&&kkvar&j";;
      kkorder1=&j;
      %do i=1 %to &statcnt;
        if compress(upcase(_name_))="%upcase(&&kkstat&i)" then kkorder2=&i;
      %end;
    run;

    %if %length(&gencode) > 0 %then %do;
      data _null_;
        file gencode mod;
        put "data kkxx99&j;";
        put "  set kkxx99&j;";
        put "  * get the maximum length of the var variable;";
        put "  length var $ &varlen;";
        %if %length(&&kkvrlb&j)>0 %then %do;
          put '  var="' @;
          put "&&kkvrlb&j" @;
          put '";';
        %end;
        %else %do;
          put '  var="' @;
          put "&&kkvar&j" @;
          put '";';
        %end;
        put "  kkorder1=&j;";
        %do i=1 %to &statcnt;
          put '  if compress(upcase(_name_))="' @;
          put "%upcase(&&kkstat&i)" @;
          put '" then kkorder2=' @;
          put "&i;";
        %end;
        put "run;";
        put;
      run;
    %end;

    proc sort data=kkxx0003;
      by name;
    run;

    %if &debug=Y %then %do;
      proc print;
        title "data kkxx0003";
      run;
    %end;

    data _null_;
      set kkxx0003;
      retain col 0;
      if compress(upcase(name)) not in ("_NAME_","_LABEL_" %if %length(&by)>0 %then,;
      %do i=1 %to &bycnt;
        "%upcase(&&kkby&i)" %if &i ne &bycnt %then ,;
      %end;
      ) 
      then do;
        col=col+1;
        call symput("kkcol"||compress(col),name);
        call symput("colcnt",compress(col));
      end;
    run;
  
    %put There are &colcnt column variables.  They are :-;
    %do i=1 %to &colcnt;
      %put Column &i is &&kkcol&i;
    %end;

    /*** do the comparative statistics ***/
    %if %length(&column)=0 and %length(&compstat)>0 %then %do;
      put ERROR: comparative statistics requested, but no column variable given;
    %end;
    %else %if %length(&column) > 0 and %length(&compstat)>0 %then %do;
 
      /* do change from baseline GLM analyses */
      %if &analysis=change %then %do;
      
        /*** work out the changes from baseline ***/
        data kkcc0001;
          set kkxx0001;
          by &by &column;
          where &timevar = &baseline;
          rename &&kkvar&j = bkkvarxx;
          keep &subjvar &&kkvar&j;
        proc sort;
          by &subjvar;
        *proc print;
        run;
        
        proc sort data=kkxx0001;
          by &subjvar;
        *proc print;
        run;
      
        data kkcc0002;
          merge kkxx0001 kkcc0001;
          by &subjvar;
          change=&&kkvar&j - bkkvarxx;
          %if &transfor=log %then %do;
            &&kkvar&j=log(&&kkvar&j);
            blkkvarx =log(bkkvarxx);
          %end;
          %if %length(&cmpwhere)>0 %then if &cmpwhere then output;;
        *proc print;
        proc sort;
          by &by;
        run;

        %if %length(&gencode) > 0 %then %do;
          data _null_;
            file gencode mod;
            put "*** work out the changes from baseline ***;";
            put "data kkcc0001;";
            put "  set kkxx0001;";
            put "  by &by &column;";
            put "  where &timevar = &baseline;";
            put "  rename &&kkvar&j = bkkvarxx;";
            put "  keep &subjvar &&kkvar&j;";
            put "proc sort;";
            put "  by &subjvar;";
            put "run;";
            put ;
            put "proc sort data=kkxx0001;";
            put "  by &subjvar;";
            put "run;";
            put ;
            put "data kkcc0002;";
            put "  merge kkxx0001 kkcc0001;";
            put "  by &subjvar;";
            put "  change=&&kkvar&j - bkkvarxx;";
            %if &transfor=log %then %do;
              put "  &&kkvar&j=log(&&kkvar&j);";
              put "  blkkvarx =log(bkkvarxx);";
            %end;
            %if %length(&cmpwhere)>0 %then %do;
              put "  if &cmpwhere then output;";
            %end;
            put "proc sort;";
            put "  by &by;";
            put "run;";
            put;
          run;
        %end;

        %do i=1 %to &compcnt;
          %if %scan(&&kkcomp&i,1,{}* )=CONTRAST %then %do;
            %let kkcont=1;
          %end;
          %else %if %scan(&&kkcomp&i,1,{}* )=WILCOXON %then %do;
            %let kkwrst=1;
          %end;
        %end;

        %global _xsummx_;

        /*** do ancova analyses ***/
        %if &kkcont=1 %then %do;
          %if &diagfile ne %then %do;
            proc printto file="&diagfile" %if &_xsummx_~=1 %then new;;
            run;

            %if %length(&gencode) > 0 %then %do;
              data _null_;
                file gencode mod;
                put 'proc printto file="' @;
                put "&diagfile " @;
                %if &_xsummx_~=1 %then %do;
                  put "new " @;
                %end;
                put ";";
                put "run;";
                put;
              run;
            %end;

          %end;
          %else %do;
            proc printto file="summary.dia" %if &_xsummx_~=1 %then new;;
            run;

            %if %length(&gencode) > 0 %then %do;
              data _null_;
                file gencode mod;
                put 'proc printto file="summary.dia" ' @;
                %if &_xsummx_~=1 %then %do;
                  put "new";
                %end;
                put ";";
                put "run;";
                put;
              run;
            %end;
          %end;

          %let _xsummx_=1;
          
          proc mixed data=kkcc0002;
            class &column;
            model &&kkvar&j = &column %if $transfor=log %then blkkvarx;%else bkkvarxx; / predicted;
            by &by;
            where &timevar ne &baseline;
            %do i=1 %to &compcnt;
              %if %scan(&&kkcomp&i,1,{}* )=CONTRAST %then %do;
                contrast "%qscan(&&kkcomp&i,2,%nrbquote(*))" &column 
                /* get the parameter values */
                %let kktemp=%scan(&&kkcomp&i,2,%str(}{));
                %let exit=0;
                %do %while(&exit=0);
                  %if %index(&kktemp,*)>0 %then %let kktemp=%substr(&kktemp,%index(&kktemp,*)+1);
                  %let kkcntv = &kktemp;
                  %if %index(&kktemp,*)=0 %then %let exit=1; 
                %end;
                &kkcntv;
                estimate "%qscan(&&kkcomp&i,2,%nrbquote(*))" &column 
                /* get the parameter values */
                %let kktemp=%scan(&&kkcomp&i,2,%str(}{));
                %let exit=0;
                %do %while(&exit=0);
                  %if %index(&kktemp,*)>0 %then %let kktemp=%substr(&kktemp,%index(&kktemp,*)+1);
                  %let kkcntv = &kktemp;
                  %if %index(&kktemp,*)=0 %then %let exit=1; 
                %end;
                &kkcntv;
                make 'estimate' out=kkcc0005;
              %end;
            %end;
            lsmeans &column /pdiff cl;
            make 'predicted' out=kkpp0001;
          run;
       
          proc plot data=kkpp0001;
            plot _resid_*_pred_;
            by &by;
          proc univariate plot normal;
            var _resid_;
            by &by;
          run;
      
          proc printto;
          run;
            
          data kkcc0006;
            set kkcc0005;
            %do i=1 %to &compcnt;
              %if %scan(&&kkcomp&i,1,{}* )=CONTRAST %then %do;
                %if %length(%qscan(&&kkcomp&i,2,%nrbquote(*))) < 20 %then if parm = "%qscan(&&kkcomp&i,2,%nrbquote(*))" then kkorder2=&i;
                %else if parm = "%substr(%qscan(&&kkcomp&i,2,%nrbquote(*)),1,20)" then kkorder2=&i;;
              %end;
            %end;
            upper=est+se*tinv(1-0.05/2,df);
            lower=est-se*tinv(1-0.05/2,df);
            kkorder1=&j;
            keep &by kkorder1 kkorder2 parm est upper lower p_t;
          run;

          %if %length(&gencode) > 0 %then %do;
            data _null_;
              file gencode mod;
              put "proc mixed data=kkcc0002;";
              put "  class &column;";
              put "  model &&kkvar&j = &column " @;
              %if $transfor=log %then %do;
                put "blkkvarx " @;
              %end;
              %else %do;
                put "bkkvarxx " @;
              %end;
              put " / predicted;";
              put "  by &by;
              put "  where &timevar ne &baseline;
              %do i=1 %to &compcnt;
                %if %scan(&&kkcomp&i,1,{}* )=CONTRAST %then %do;
                  put '  contrast "' @;
                  put "%qscan(&&kkcomp&i,2,%nrbquote(*))" @;
                  put '" ' @;
                  put "&column " @;
                  %let kktemp=%scan(&&kkcomp&i,2,%str(}{));
                  %let exit=0;
                  %do %while(&exit=0);
                    %if %index(&kktemp,*)>0 %then %let kktemp=%substr(&kktemp,%index(&kktemp,*)+1);
                    %let kkcntv = &kktemp;
                    %if %index(&kktemp,*)=0 %then %let exit=1; 
                  %end;
                  put "&kkcntv ;";
                  put 'estimate "' @;
                  put "%qscan(&&kkcomp&i,2,%nrbquote(*))" @;
                  put '" ' @;
                  put "&column " @;
                  %let kktemp=%scan(&&kkcomp&i,2,%str(}{));
                  %let exit=0;
                  %do %while(&exit=0);
                    %if %index(&kktemp,*)>0 %then %let kktemp=%substr(&kktemp,%index(&kktemp,*)+1);
                    %let kkcntv = &kktemp;
                    %if %index(&kktemp,*)=0 %then %let exit=1; 
                  %end;
                  put "&kkcntv;";
                  put "  make 'estimate' out=kkcc0005;";
                %end;
              %end;
              put "  lsmeans &column /pdiff cl;";
              put "  make 'predicted' out=kkpp0001;";
              put "run;";
              put ;
              put "proc plot data=kkpp0001;";
              put "  plot _resid_*_pred_;";
              put "  by &by;";
              put "proc univariate plot normal;";
              put "  var _resid_;";
              put "  by &by;";
              put "run;";
              put ;
              put "proc printto;";
              put "run;";
              put ;
              put "data kkcc0006;";
              put "  set kkcc0005;";
              %do i=1 %to &compcnt;
                %if %scan(&&kkcomp&i,1,{}* )=CONTRAST %then %do;
                  %if %length(%qscan(&&kkcomp&i,2,%nrbquote(*))) < 20 %then %do;
                    put '  if parm = "' @;
                    put "%qscan(&&kkcomp&i,2,%nrbquote(*))" @;
                    put '" then kkorder2=' @;
                    put "&i;";
                  %end;
                  %else %do;
                    put '  if parm = "' @;
                    put "%substr(%qscan(&&kkcomp&i,2,%nrbquote(*)),1,20)" @;
                    put '" then kkorder2=' @;
                    put "&i;";
                  %end;
                %end;
              %end;
              put "  upper=est+se*tinv(1-0.05/2,df);";
              put "  lower=est-se*tinv(1-0.05/2,df);";
              put "  kkorder1=&j;";
              put "  keep &by kkorder1 kkorder2 parm est upper lower p_t;";
              put "run;";
              put ;
            run;
          %end;
        %end;
        
        /*** do wilcoxon rank sum tests (paired) ***/
        %if &kkwrst=1 %then %do;
          %do i=1 %to &compcnt;
            %if %scan(&&kkcomp&i,1,{}* )=WILCOXON %then %do;
            
              %if &diagfile ne %then %do;
                proc printto file="&diagfile" %if &_xsummx_~=1 %then new;;
                run;

                %if %length(&gencode) > 0 %then %do;
                  data _null_;
                    file gencode mod;
                    put 'proc printto file="' @;
                    put "&diagfile " @;
                    %if &_xsummx_~=1 %then %do;
                      put "new " @;
                    %end;
                    put ";";
                    put "run;";
                    put;
                  run;
                %end;
              %end;
              %else %do;
                proc printto file="summary.dia" %if &_xsummx_~=1 %then new;;
                run;
                %if %length(&gencode) > 0 %then %do;
                  data _null_;
                    file gencode mod;
                    put 'proc printto file="summary.dia" ' @;
                    %if &_xsummx_~=1 %then %do;
                      put "new";
                    %end;
                    put ";";
                    put "run;";
                    put;
                  run;
                %end;
              %end;
              
              %let _xsummx_=1;

              proc npar1way data=kkcc0002 wilcoxon;
                var &&kkvar&j;
                class &column;
                by &by;
                where &timevar ne &baseline and &column in 
                /* get the treatment groups to be compared */
                %let kktemp=%scan(&&kkcomp&i,2,%str(}{));
                %let exit=0;
                %do %while(&exit=0);
                  %if %index(&kktemp,*)>0 %then %let kktemp=%substr(&kktemp,%index(&kktemp,*)+1);
                  %let kkcntv = &kktemp;
                  %if %index(&kktemp,*)=0 %then %let exit=1; 
                %end;
                %if &kkcoltp=2 %then %do;
                  ("%trim(%scan(&kkcntv,1))","%trim(%scan(&kkcntv,2))");
                %end;
                %else %if &kkcoltp=1 %then %do;
                  (%trim(%scan(&kkcntv,1)),%trim(%scan(&kkcntv,2)));
                %end;
                output out=kkccc&i;
              *proc print;
              run;
              
              proc printto;
              run;

              %if %length(&gencode) > 0 %then %do;
                data _null_;
                  file gencode mod;
                  put "proc npar1way data=kkcc0002 wilcoxon;";
                  put "  var &&kkvar&j;";
                  put "  class &column;";
                  put "  by &by;";
                  put "  where &timevar ne &baseline and &column in " @;
                  %let kktemp=%scan(&&kkcomp&i,2,%str(}{));
                  %let exit=0;
                  %do %while(&exit=0);
                    %if %index(&kktemp,*)>0 %then %let kktemp=%substr(&kktemp,%index(&kktemp,*)+1);
                    %let kkcntv = &kktemp;
                    %if %index(&kktemp,*)=0 %then %let exit=1; 
                  %end;
                  %if &kkcoltp=2 %then %do;
                    put '("' @;
                    put "%trim(%scan(&kkcntv,1))" @;
                    put '","' @;
                    put "%trim(%scan(&kkcntv,2))" @;
                    put '");' ;
                  %end;
                  %else %if &kkcoltp=1 %then %do;
                    put "(%trim(%scan(&kkcntv,1)),%trim(%scan(&kkcntv,2)));";
                  %end;
                  put "  output out=kkccc&i;";
                  put "run;";
                  put;
                  put "proc printto;";
                  put "run;";
                  put;
                run;
              %end;
            %end;
          %end;
          data kkcc0008;
            set 
            %do i=1 %to &compcnt;
              %if %scan(&&kkcomp&i,1,{}* )=WILCOXON %then kkccc&i (in=in&i);
            %end;;
            %do i=1 %to &compcnt;
              %if %scan(&&kkcomp&i,1,{}* )=WILCOXON %then if in&i then kkorder2=&i;;
            %end;
            kkorder1=&j;
          run;          

          %if %length(&gencode) > 0 %then %do;
            data _null_;
              file gencode mod;
              put "data kkcc0008;";
              put "  set " @;
              %do i=1 %to &compcnt;
                %if %scan(&&kkcomp&i,1,{}* )=WILCOXON %then %do;
                  put "kkccc&i (in=in&i) " @;
                %end;
              %end;
              put ";";
              %do i=1 %to &compcnt;
                %if %scan(&&kkcomp&i,1,{}* )=WILCOXON %then %do;
                  put "  if in&i then kkorder2=&i;";
                %end;
              %end;
              put "  kkorder1=&j;";
              put "run;";
              put;
            run;
          %end;
        %end;
      %end;
    %end;
  %end;
  %else %do;
    /*****  do the categorical variables *****/
  
    %do i=1 %to &compcnt;
      %if %scan(&&kkcomp&i,1,{}* )=CHISQ %then %do;
        %let kkchisq=1;
      %end;
      %else %if %scan(&&kkcomp&i,1,{}* )=PWCHISQ %then %do;
        %let kkpwchsq=1;
      %end;
    %end;

    proc freq data=kkxx0001 noprint;
      table &&kkvar&j %if %length(&column)>0 %then * &column; /out=kkff0001 %if &kkchisq and &chconcat= %then chisq;;
      %if %length(&by)>0 %then by &by;;
      %if &kkchisq and &chconcat= %then %do;
        output out=kkff0008 chisq;
      %end;
    run;

    %if &debug=Y %then %do;
      proc print;
        title "data as it comes out of proc freq";
      run;        
    %end;

    %if %length(&gencode) > 0 %then %do;
      data _null_;
        file gencode mod;
        put "proc freq data=kkxx0001 noprint;";
        put "  table &&kkvar&j " @;
        %if %length(&column)>0 %then %do;
          put "* &column " @;
        %end;
        put "/out=kkff0001 " @;
        %if &kkchisq and &chconcat= %then %do;
          put "chisq";
        %end;
        put ";";
        %if %length(&by)>0 %then %do;
          put "  by &by;";
        %end;
        %if &kkchisq and &chconcat= %then %do;
          put "  output out=kkff0008 chisq;";
        %end;
        put "run;";
        put;
      run;
    %end;

    /* if categories are to be collapsed for the chi-square ... */
    %if (&chconcat ne ) %then %do;

      /* store each group of concatenations */
      %let concnt=1;
      %let word = %scan(&chconcat,&concnt,%str({}));
      %do %while(%length(%trim(&word))>0);
        %let chcc&concnt=%upcase(&word);
        %let concnt = %eval(&concnt+1);
        %let word = %scan(&chconcat,&concnt,%str({}));
      %end;
      %let concnt = %eval(&concnt-1);
      
      /* for each concatenation group, store all categories */
      %do i=1 %to &concnt;
        %let concnt&i=1;
        %let word = %scan(&&chcc&i,&&concnt&i,%str( ));
        %do %while(%length(%trim(&word))>0);
          %let cc&i._&&concnt&i=%upcase(&word);
          %let concnt&i = %eval(&&concnt&i+1);
          %let word = %scan(&&chcc&i,&&concnt&i,%str( ));
        %end;
        %let concnt&i = %eval(&&concnt&i-1);
      %end;
      
      data kkxx001x;
        set kkxx0001;
        %do i=1 %to &concnt;
          %if &&kkvrty&j=2 %then %do;
            if &&kkvar&j in (
            %do k=1 %to &&concnt&i;
              %if &k>1 %then %do;
                "&&cc&i._&k" %if &k ne &&concnt&i %then ,;
              %end;
            %end;
            ) then &&kkvar&j="&&cc&i._1";
          %end;
          %else %if &&kkvrty&j=1 %then %do;
            if &&kkvar&j in (
            %do k=1 %to &&concnt&i;
              %if &k>1 %then %do;
                &&cc&i._&k %if &k ne &&concnt&i %then ,;
              %end;
            %end;
            ) then &&kkvar&j=&&cc&i._1;
          %end;
        %end;
      run;

      %if %length(&gencode) > 0 %then %do;
        data _null_;
          file gencode mod;
          put "data kkxx001x;";
          put "  set kkxx0001;";
          %do i=1 %to &concnt;
            %if &&kkvrty&j=2 %then %do;
              put "if &&kkvar&j in (" @;
              %do k=1 %to &&concnt&i;
                %if &k>1 %then %do;
                  put '"' @;
                  put "&&cc&i._&k" @;
                  put '"' @;
                  %if &k ne &&concnt&i %then %do;
                    put "," @;
                  %end;
                %end;
              %end;
              put ") then &&kkvar&j=" @;
              put '"' @;
              put "&&cc&i._1" @;
              put '";';
            %end;
            %else %if &&kkvrty&j=1 %then %do;
              put "  if &&kkvar&j in (" @;
              %do k=1 %to &&concnt&i;
                %if &k>1 %then %do;
                  put "&&cc&i._&k " @;
                  %if &k ne &&concnt&i %then %do;
                    put "," @;
                  %end;
                %end;
              %end;
              put ") then &&kkvar&j=&&cc&i._1;";
            %end;
          %end;
          put "run;";
          put;
        run;
      %end;
        
      %if &kkchisq %then %do;
        proc freq noprint;
          table &&kkvar&j %if %length(&column)>0 %then * &column; /chisq;
          %if %length(&by)>0 %then by &by;;
          output out=kkff0008 chisq;
        run;        

        %if %length(&gencode) > 0 %then %do;
          data _null_;
            file gencode mod;
            put "proc freq noprint;";
            put "  table &&kkvar&j " @;
            %if %length(&column)>0 %then %do;
              put "* &column; /chisq;";
            %end;
            %if %length(&by)>0 %then %do;
              put "  by &by;";
            %end;
            put "  output out=kkff0008 chisq;";
            put "run;";
            put;
          run;
        %end;
      %end;
    %end;
    

    /* work out the denominator for the percentages */
    %if &column ne %then %do;
      proc freq data=kkxx0001;
        table &column / noprint out=kkff0004 (keep=count &column %if %length(&by)>0 %then &by; rename=(count=denom)); 
        %if %length(&by)>0 %then by &by;;
      run;
  
      %if &debug=Y %then %do;
        proc print;
          title "data for denominators";
        run;   
      %end;
      
      proc sort data=kkff0001;
        by &column %if %length(&by)>0 %then &by;;
      proc sort data=kkff0004;
        by &column %if %length(&by)>0 %then &by;;
      run;
      
      data kkff0001;
        merge kkff0001 kkff0004;
        by &column %if %length(&by)>0 %then &by;;
        percent=(count/denom)*100;
        %if &missing=N %then %do;
          if &&kkvar&j ne %if &&kkvart&j=2 %then %str("";);
                          %else %str(.;);
        %end;
        drop denom;
      run;

      %if &debug=Y %then %do;
        proc print;
          title "count data merged with denom data";
        run;
      %end;

      %if %length(&gencode) > 0 %then %do;
        data _null_;
          file gencode mod;
          put "proc freq data=kkxx0001;";
          put "  table &column / noprint out=kkff0004 (keep=count &column " @;
          %if %length(&by)>0 %then %do;
            put "&by " @;
          %end;
          put " rename=(count=denom)); ";
          %if %length(&by)>0 %then %do;
            put "  by &by;";
          %end;
          put "run;";
          put;
          put "proc sort data=kkff0001;";
          put "  by &column " @;
          %if %length(&by)>0 %then %do;
            put "&by " @;
          %end;
          put ";";
          put "proc sort data=kkff0004;";
          put "  by &column " @;
          %if %length(&by)>0 %then %do;
            put "&by " @;
          %end;
          put ';';
          put "run;";
          put ;
          put "data kkff0001;";
          put "  merge kkff0001 kkff0004;";
          put "  by &column " @;
          %if %length(&by)>0 %then %do;
            put "&by " @;
          %end;
          put ';';
          put "  percent=(count/denom)*100;";
          %if &missing=N %then %do;
            put "  if &&kkvar&j ne " @;
            %if &&kkvart&j=2 %then %do;
              put '"";';
            %end;
            %else %do;
              put '.;';
            %end;
          %end;
          put "  drop denom;";
          put "run;";
          put;
        run;
      %end;
    %end;
      
    /*** create a variable holding both the N and % */
    data kkff0003;
      set kkff0001;
      stats=put(count,&kkmaxf..)||' ('||put(percent,5.1)||'%)';
      drop count percent;
      %if %length(&column)>0 %then %do;
        %if &colorder=INTERNAL %then format &column;;
      %end;
    run;

    %if &debug=Y %then %do;
      proc print;
        title "data in correct format for proc report";
      run;
    %end;

    proc sort;
      by &by &&kkvar&j;
    run;

    %if %length(&gencode) > 0 %then %do;
      data _null_;
        file gencode mod;
        put "*** create a variable holding both the N and % ;";
        put "data kkff0003;";
        put "  set kkff0001;";	
        put "  stats=put(count,%trim(&kkmaxf.).)||' ('||put(percent,5.1)||'%)';";
        put "  drop count percent;";
        %if %length(&column)>0 %then %do;
          %if &colorder=INTERNAL %then %do;
            put "  format &column;";
          %end;
        %end;
        put "proc sort;";
        put "  by &by &&kkvar&j;";
        put "run;";
        put;
      run;
    %end;

    /*** recode the missing column variables so proc transpose keeps them ***/
    %if %length(&column)>0 %then %do;
      data kkff0003;
        set kkff0003;
        %if &kkcoltp=1 %then %do;
          if &column=. then &column=-999999;
        %end;
        %else %do;
          if compress(&column)="" then &column="AAAAAA";
        %end;
      run;

      %if %length(&gencode) > 0 %then %do;
        data _null_;
          file gencode mod;
          put "*** recode the missing column variables so proc transpose keeps them ***;";
          put "data kkff0003;";
          put "  set kkff0003;";
          %if &kkcoltp=1 %then %do;
            put "if &column=. then &column=-999999;";
          %end;
          %else %do;
            put "  if compress(&column)=" @;
            put '"" then ' @;
            put "&column='AAAAAA';";
          %end;
          put "run;";
          put ;
        run;
      %end;
    %end;

    proc transpose out=kkxx99&j;
      %if %length(&column)>0 %then id &column;;
      var stats;
      by &by &&kkvar&j;
    run;

    %if &debug=Y %then %do;
      proc print;
        title "data after it has been transposed";
      run;
    %end;

    %if %length(&gencode) > 0 %then %do;
      data _null_;
        file gencode mod;
        put "proc transpose out=kkxx99&j;";
        %if %length(&column)>0 %then %do;
          put "  id &column;";
        %end;
        put "  var stats;";
        put "  by &by &&kkvar&j;";
        put "run;";
        put;
      run;
    %end;
 
    proc sort data=kkff0003;
      by &column;
    run;

    data _null_;
      set kkff0003 end=last;
      by &column;
      retain col 0;
      if first.&column;
      col = col + 1;
      %if &kkcoltp=1 %then %do;
        if &column = . then call symput("kkcol"||compress(col),"Missing");
        else call symput("kkcol"||compress(col),"_"||compress(put(&column,best.)));
      %end;
      %else %do;
        if compress(&column) = "" then call symput("kkcol"||compress(col),"Missing");
        &column=translate(trim(&column),"________________________","!£$%^&*():;@~#<,>.?/+=- ");
		if substr(&column,1,2) in ('1','2','3','4','5','6','7','8','9','0') then &column="_"||trim(&column);
        call symput("kkcol"||compress(col),compress(&column));
      %end;
      call symput("catcnt",compress(col));
    run;

    %if &debug=Y %then %do;
      proc print;
        title "attempt to get the proper column headings";
      run;
    %end;

/*
    %*** get the names of the column variables ***;
    proc contents data=kkxx99&j out=kkxx0003(keep=name label format) noprint;
    proc sort data=kkxx0003;
      by name;
    %if &debig=Y %then %do;
      proc print;
        title "data kkxx0003";
    %end;
    run;
  
    data _null_;
      set kkxx0003;
      retain col 0;
      if compress(upcase(name)) not in ("_NAME_","_LABEL_", "%upcase(&&kkvar&j)" 
        %if %length(&column)>0 %then ", %upcase(&column)"; 
        %if %length(&by)>0 %then,;
      %do i=1 %to &bycnt;
        "%upcase(&&kkby&i)" %if &i ne &bycnt %then ,;
      %end;
      ) 
      then do;
        col=col+1;
        call symput("kkcol"||compress(col),name);
        call symput("catcnt",compress(col));
      end;
    run;
*/
    %put There are &catcnt column variables.  They are :-;
    %do i=1 %to &catcnt;
      %put Column &i is &&kkcol&i;
    %end;

    data kkxx99&j;
      length _name_ $25 var $ &varlen statcat $ 100;
      set kkxx99&j;
      %if %length(&by)>0 %then %do;
        by &by;
        retain kkorder2;
        if first.&&kkby&bycnt then kkorder2=1;
        else kkorder2=kkorder2+1;
      %end;
      %else kkorder2=_n_;;
      %if %length(&&kkvrlb&j)>0 %then var="&&kkvrlb&j";
      %else var="&&kkvar&j";;  
      kkorder1=&j;
      %if %length(&&kkvrft&j)>0 %then statcat = put(&&kkvar&j,&&kkvrft&j);
      %else statcat=&&kkvar&j;;
      %if &missing=Y %then if statcat = "" then statcat='Missing';;
      drop %do i=1 %to &catcnt; 
             &&kkcol&i
           %end;;
      %do i=1 %to &catcnt;
        kkcol&i=&&kkcol&i;
      %end;
    run;

    %if &debug=Y %then %do;
      proc print;
        title "data kkxx99&j";
      run;
    %end;

    %if %length(&gencode) > 0 %then %do;
      data _null_;
        file gencode mod;
        put "data kkxx99&j;";
        put "  length _name_ $25 var $ &varlen statcat $ 100;";
        put "  set kkxx99&j;";
        %if %length(&by)>0 %then %do;
          put "  by &by;";
          put "  retain kkorder2;";
          put "  if first.&&kkby&bycnt then kkorder2=1;";
          put "  else kkorder2=kkorder2+1;";
        %end;
        %else %do;
          put "  kkorder2=_n_;";
        %end;
        %if %length(&&kkvrlb&j)>0 %then %do;
          put "  var='" @;
          put "&&kkvrlb&j" @;
          put "';";
        %end;
        %else %do;
          put "  var='" @;
          put "&&kkvar&j" @;
          put "';";
        %end;  
        put "  kkorder1=&j;";
        %if %length(&&kkvrft&j)>0 %then %do;
          put "  statcat = put(&&kkvar&j,&&kkvrft&j);";
        %end;
        %else %do;
          put "  statcat=&&kkvar&j;";
        %end;
        %if &missing=Y %then %do;
          put "  if statcat = '' then statcat='Missing';";
        %end;
        put "  drop " @;
        %do i=1 %to &catcnt; 
          put "%trim(&&kkcol&i) " @;
        %end;
        put ";";
        %do i=1 %to &catcnt;
          put "  kkcol&i=%trim(&&kkcol&i);";
        %end;
        put "run;";
        put;
      run;
    %end;

    /*** do the comparative statistics (overall chisq is included in the proc freq above) ***/
    %if %length(&column)=0 and %length(&compstat)>0 %then %do;
      put ERROR: comparative statistics requested, but no column variable given;
    %end;
    %else %if %length(&column) > 0 and %length(&compstat)>0 %then %do;
 
      %do i=1 %to &compcnt;
        /*** do overall chisq analyses ***/
        %if %scan(&&kkcomp&i,1,{}* )=CHISQ %then %do;
          data kkff009x;
            set kkff0008;
            kkorder2=&i;
            %if %length(&cmpwhere)>0 %then if &cmpwhere;;
            keep &by kkorder2 p_pchi;
          *proc print;
          run;        

          %if %length(&gencode) > 0 %then %do;
            data _null_;
              file gencode mod;
              put "data kkff009x;";
              put "  set kkff0008;";
              put "  kkorder2=&i;";
              %if %length(&cmpwhere)>0 %then %do;
                put "if &cmpwhere;";
              %end;
              put "  keep &by kkorder2 p_pchi;";
              put "run;";
              put;
            run;
          %end;
        %end;
      
        %if %scan(&&kkcomp&i,1,{}* )=PWCHISQ %then %do;
          %if &chconcat ne %then %do;
            proc freq data=kkxx001x noprint;
          %end;
          %else %do;
            proc freq data=kkxx0001 noprint;
          %end;
            table &&kkvar&j %if %length(&column)>0 %then * &column; / chisq;;
            %if %length(&by)>0 %then by &by;;
            output out=kkpw00&i chisq;
            where &column in 
            %let kktemp=%scan(&&kkcomp&i,2,%str(}{));
            %let exit=0;
            %do %while(&exit=0);
              %if %index(&kktemp,*)>0 %then %let kktemp=%substr(&kktemp,%index(&kktemp,*)+1);
              %let kkcntv = &kktemp;
              %if %index(&kktemp,*)=0 %then %let exit=1; 
            %end;
            %if &kkcoltp=2 %then %do;
              ("%trim(%scan(&kkcntv,1))","%trim(%scan(&kkcntv,2))")
            %end;
            %else %if &kkcoltp=1 %then %do;
              (%trim(%scan(&kkcntv,1)),%trim(%scan(&kkcntv,2)))
            %end;
            %if %length(&cmpwhere)>0 %then and &cmpwhere;;
          run;

          %if %length(&gencode) > 0 %then %do;
            data _null_;
              file gencode mod;
              %if &chconcat ne %then %do;
                put "proc freq data=kkxx001x noprint;";
              %end;
              %else %do;
                put "proc freq data=kkxx0001 noprint;";
              %end;
              put "  table &&kkvar&j " @;
              %if %length(&column)>0 %then %do;
                put "* &column " @;
              %end;
              put " / chisq;";
              %if %length(&by)>0 %then %do;
                put "  by &by;";
              %end;
              put "  output out=kkpw00&i chisq;";
              put "  where &column in " @;
              %let kktemp=%scan(&&kkcomp&i,2,%str(}{));
              %let exit=0;
              %do %while(&exit=0);
                %if %index(&kktemp,*)>0 %then %let kktemp=%substr(&kktemp,%index(&kktemp,*)+1);
                %let kkcntv = &kktemp;
                %if %index(&kktemp,*)=0 %then %let exit=1; 
              %end;
              %if &kkcoltp=2 %then %do;
                put '("' @;
                put "%trim(%scan(&kkcntv,1))" @;
                put '","' @;
                put "%trim(%scan(&kkcntv,2))" @;
                put '")' @;
              %end;
              %else %if &kkcoltp=1 %then %do;
                put "(%trim(%scan(&kkcntv,1)),%trim(%scan(&kkcntv,2)))" @;
              %end;
              %if %length(&cmpwhere)>0 %then %do;
                put "and &cmpwhere";
              %end;
              put";";
              put "run;";
            run;
          %end;
        %end;
      %end;  
      %if (&kkchisq or &kkpwchsq) %then %do;
        data kkff0009;
          set
          %if &kkchisq %then kkff009x;
          %if &kkpwchsq %then %do;
            %do i=1 %to &compcnt;
              %if %scan(&&kkcomp&i,1,{}* )=PWCHISQ %then kkpw00&i(in=in&i);
            %end;
          %end;;
          %do i=1 %to &compcnt;
            %if %scan(&&kkcomp&i,1,{}* )=PWCHISQ %then if in&i then kkorder2=&i;;
          %end;
          %if %length(&&kkvrlb&j)>0 %then var="&&kkvrlb&j";
          %else var="&&kkvar&j";;  
          kkorder1=&j;
        run;

        %if %length(&gencode) > 0 %then %do;
          data _null_;
            file gencode mod;
            put "data kkff0009;";
            put "  set " @;
            %if &kkchisq %then %do;
              put "kkff009x ";
            %end;
            %if &kkpwchsq %then %do;
              %do i=1 %to &compcnt;
                %if %scan(&&kkcomp&i,1,{}* )=PWCHISQ %then %do;
                  put "kkpw00&i(in=in&i)";
                %end;
              %end;
            %end;
            put ";";
            %do i=1 %to &compcnt;
              %if %scan(&&kkcomp&i,1,{}* )=PWCHISQ %then %do;
                put "  if in&i then kkorder2=&i;";
              %end;
            %end;
            %if %length(&&kkvrlb&j)>0 %then %do;
              put 'var="' @;
              put "&&kkvrlb&j" @;
              put '";';
            %end;
            %else %do;
              put 'var="' @;
              put "&&kkvar&j" @;
              put '";';  
            %end;
            put "  kkorder1=&j;";
            put "run;";
            put;
          run;
        %end;
      %end;
    %end;
  %end;
%end;

/*** check if there are any continous/categorical variables ***/
%let contvar=0;
%let catvar=0;

%do i=1 %to &varcnt;
  %if &&kkvart&i=1 %then %let contvar=1;
  %if &&kkvart&i=2 %then %let catvar=1;
%end;

%if &contvar=1 %then %do;  
  /*** merge all the continuous variables together ***/
  data kkxx0004;
    set %do i=1 %to &varcnt;
          %if &&kkvart&i=1 %then kkxx99&i;
        %end;;
  run;

  %if &debug=Y %then %do;
    proc print;
      title "data kkxx0004";
    run;
  %end;

  %if %length(&gencode) > 0 %then %do;
    data _null_;
      file gencode mod;
      put "***********************************************;";
      put "* merge all the continuous variables together *;";
      put "***********************************************;";
      put "data kkxx0004;";
      put "  set " @;
      %do i=1 %to &varcnt;
        %if &&kkvart&i=1 %then %do;
          put "kkxx99&i " @;
        %end;
      %end; 
      put ";";
      put "run;";
      put;
    run;
  %end;
                                                                      
  /*** get the width of the summary statistics (continuous) columns ***/
  proc summary noprint;
    var   %do i=1 %to &colcnt;
            &&kkcol&i
          %end;;
    output out=kkxx0006 min= %do i=1 %to &colcnt;
                               kkmin&i
                             %end;
                        max= %do i=1 %to &colcnt;
                               kkmax&i
                             %end;;
  run; 

  data _null_;
    set kkxx0006;
    min=put(%if &colcnt>1 %then %do;
              min(%do i=1 %to &colcnt;
                    kkmin&i %if &i ne &colcnt %then , ;
                  %end;)
            %end;
            %else kkmin1;,E.);
    max=put(%if &colcnt>1 %then %do;
              max(%do i=1 %to &colcnt;
                    kkmax&i %if &i ne &colcnt %then , ;
                  %end;)
            %end;
            %else kkmax1;,E.);
    len1=substr(compress(min),length(compress(min))-2)+1;
    len2=substr(compress(max),length(compress(max))-2)+1;
    if min < 0 then sign=1;
    else sign=0;
    /* difference between min and max, one space if negative numbers plus 3 sig digits */
    if len2 < 0 and len1 < 0 then width=len1;
    else if len2 >= 0 and len1 >= 0 then width=len2;
    else if (len2 >= 0 and len1 < 0) or (len2 <0 and len1 >= 0) then width=abs(len1)+abs(len2);
    call symput("valwidth",width+sign+4);
  *proc print;
  run;

  /*** work out column widths ***/
  %do i=1 %to &varcnt;
    %if &&kkvrfl&i > &valwidth %then %let valwidth=&&kkvrfl&i;
  %end; 

  /*** save the width to use with the comparative statistics ***/
  %let kkwidth=&valwidth;

  %do i=1 %to &colcnt;
    %if %length(%trim(&&kkcllb&i)) > &valwidth %then %let valwidth=%length(%trim(&&kkcllb&i));
  %end;

  proc sort data=kkxx0004;
    by &by kkorder1 kkorder2;
  run;

  %if %length(&gencode) > 0 %then %do;
    data _null_;
      file gencode mod;
      put "proc sort data=kkxx0004;";
      put "  by &by kkorder1 kkorder2;";
      put "run;";
      put;
    run;
  %end;

  %if &kkcont=1 %then %do;
    proc sort data=kkcc0006;
      by &by kkorder1 kkorder2;
    run;  
    %if %length(&gencode) > 0 %then %do;
      data _null_;
        file gencode mod;
        put "proc sort data=kkcc0006;";
        put "  by &by kkorder1 kkorder2;";
        put "run;";
        put;
      run;
    %end;
  %end;
  %if &kkwrst=1 %then %do;
    proc sort data=kkcc0008;
      by &by kkorder1 kkorder2;
    run;  
    %if %length(&gencode) > 0 %then %do;
      data _null_;
        file gencode mod;
        put "proc sort data=kkcc0008;";
        put "  by &by kkorder1 kkorder2;";
        put "run;";
        put;
      run;
    %end;
  %end;

  data kkxx0005;
    %if (&kkcont=1 and &kkwrst=1) %then %do;
      merge kkxx0004 kkcc0006 kkcc0008;
      by &by kkorder1 kkorder2;
    %end;
    %else %if &kkcont=1 %then %do;
      merge kkxx0004 kkcc0006;
      by &by kkorder1 kkorder2;
    %end;
    %else %if &kkwrst=1 %then %do;
      merge kkxx0004 kkcc0008;
      by &by kkorder1 kkorder2;
    %end;
    %else set kkxx0004;;
    length %do i=1 %to &colcnt;  kkcol&i  %end; $ &valwidth;
    length statcat $ 100;
    /*** format the summary statistic values ***/
    statcat=put(_name_,&statfmt);
    %do j=1 %to &varcnt;
      if kkorder1=&j then do;
        if compress(upcase(_name_)) in ("N","NMISS","NOBS") then do;
          %do i=1 %to &colcnt;
            kkcol&i=put(&&kkcol&i,%eval(&valwidth %if &&kkvrfd&j<3 %then -4;%else -2-&&kkvrfd&j;).0);
          %end;
        end;
        else if compress(upcase(_name_)) in ("CSS","USS","STD","VAR","STDMEAN","CV","T","SIGNRANK","SKEWNESS","KURTOSIS") then do;                         
          %do i=1 %to &colcnt;
             kkcol&i=put(&&kkcol&i,%eval(&valwidth %if &&kkvrfd&j<2 %then +&&kkvrfd&j-2; ).%eval(&&kkvrfd&j+1));
          %end;
        end;
        else if compress(upcase(_name_)) in ("MAX","MIN", "SUM","P1","Q1","P5","Q3","P10","QRANGE", "MEDIAN", "P90","RANGE","P95","MODE","P99","MEAN","SUMWGT","MSIGN") then do;
          %do i=1 %to &colcnt;
             kkcol&i=put(&&kkcol&i,%eval(&valwidth-1 %if &&kkvrfd&j=1 %then -1;%else %if &&kkvrfd&j=0 %then -3;).&&kkvrfd&j);
          %end;
        end;
        else if compress(upcase(_name_)) in("PROBN","PROBM","PROBS","NORMAL") then do;
          %do i=1 %to &colcnt;
             kkcol&i=put(&&kkcol&i,%eval(&valwidth).3);
          %end;
        end;
        %if &kkcont=1 %then %do;
          if est ne . then do;
            kkest=put(est,%eval(&kkwidth-&&kkvrfd&j).%eval(&&kkvrfd&j));
            kk95ci='['||put(lower,%eval(&kkwidth-&&kkvrfd&j).%eval(&&kkvrfd&j))||
                   ','||put(upper,%eval(&kkwidth-&&kkvrfd&j-1).%eval(&&kkvrfd&j))||']';
            kkpval=put(p_t,pval.);
          end;
        %end;
        %if &kkwrst=1 %then %do;
          if p2_wil ne . then do;
            kkpval=put(p2_wil,pval.);
          end;
        %end;
      end;
    %end;
  run;

  %if %length(&gencode) > 0 %then %do;
    data _null_;
      file gencode mod;
      put "data kkxx0005;";
      %if (&kkcont=1 and &kkwrst=1) %then %do;
        put "  merge kkxx0004 kkcc0006 kkcc0008;";
        put "  by &by kkorder1 kkorder2;";
      %end;
      %else %if &kkcont=1 %then %do;
        put "  merge kkxx0004 kkcc0006;";
        put "  by &by kkorder1 kkorder2;";
      %end;
      %else %if &kkwrst=1 %then %do;
        put "  merge kkxx0004 kkcc0008;";
        put "  by &by kkorder1 kkorder2;";
      %end;
      %else %do;
        put "  set kkxx0004;";
      %end;
      put "  length " @;
      %do i=1 %to &colcnt;
        put "kkcol&i " @;
      %end;
      put "$ &valwidth;";
      put "  length statcat $ 100;";
      put "  * format the summary statistic values ;";
      put "  statcat=put(_name_,&statfmt);";
      %do j=1 %to &varcnt;
        put "  if kkorder1=&j then do;";
        put '    if compress(upcase(_name_)) in ("N","NMISS","NOBS") then do;';
        %do i=1 %to &colcnt;
          put "      kkcol&i=put(%trim(&&kkcol&i)," @;
          %if &&kkvrfd&j<3 %then %let kkextra=-4;
          %else %let kkextra=%eval(-2-&&kkvrfd&j);
          put "%eval(&valwidth+&kkextra).0);";
        %end;
        put "    end;";
        put '    else if compress(upcase(_name_)) in ("CSS","USS","STD","VAR","STDMEAN","CV","T","SIGNRANK","SKEWNESS","KURTOSIS") then do;';
        %do i=1 %to &colcnt;
          put "      kkcol&i=put(%trim(&&kkcol&i)," @;
          %if &&kkvrfd&j<2 %then %let kkextra = %eval(&&kkvrfd&j-2); 
          %else %let kkextra=;
          %if &&kkextra>0 %then %let kkextra=+&kkextra;
          put "%eval(&valwidth &kkextra).%eval(&&kkvrfd&j+1));";
        %end;
        put "    end;";
        put '    else if compress(upcase(_name_)) in ("MAX","MIN", "SUM","P1","Q1","P5","Q3","P10","QRANGE", "MEDIAN", "P90","RANGE","P95","MODE","P99","MEAN","SUMWGT","MSIGN") then do;';
        %do i=1 %to &colcnt;
          put "      kkcol&i=put(%trim(&&kkcol&i)," @;
          %if &&kkvrfd&j=1 %then %let kkextra=-1;
          %else %if &&kkvrfd&j=0 %then %let kkextra=-3;
          put "%eval(&valwidth-1 &kkextra).&&kkvrfd&j);";
        %end;
        put "    end;";
        put '    else if compress(upcase(_name_)) in("PROBN","PROBM","PROBS","NORMAL") then do;';
        %do i=1 %to &colcnt;
          put "      kkcol&i=put(%trim(&&kkcol&i),%eval(&valwidth).3);";
        %end;
        put "    end;";
        %if &kkcont=1 %then %do;
          put "    if est ne . then do;";
          put "      kkest=put(est,%eval(&kkwidth-&&kkvrfd&j).%eval(&&kkvrfd&j));";
          put "      kk95ci='['||put(lower,%eval(&kkwidth-&&kkvrfd&j).%eval(&&kkvrfd&j))||" @;
          put "','||put(upper,%eval(&kkwidth-&&kkvrfd&j-1).%eval(&&kkvrfd&j))||']';";
          put "      kkpval=put(p_t,pval.);";
          put "    end;";
        %end;
        %if &kkwrst=1 %then %do;
          put "    if p2_wil ne . then do;";
          put "      kkpval=put(p2_wil,pval.);";
          put "    end;";
        %end;
        put "  end;";
      %end;
      put "run;";
      put;
    run;
  %end;
%end;

/*** join the reporting datasets from the continuous and categorical variables ***/

%if &catcnt>&colcnt %then %let colcnt=&catcnt;

/* if the column width for categorical data is bigger, fix it */
%if &contvar %then %do;
  %if &valwidth < %eval(&kkmaxf+9) %then %let colwidth=%eval(&kkmaxf+9);
  %else %let colwidth=&valwidth;
%end;
%else %let colwidth=%eval(&kkmaxf+9);

data kkxx0008;
  length statcat $ 100;
  length %do i=1 %to &colcnt;
           kkcol&i
         %end; $ &colwidth;
  set %if &contvar %then kkxx0005; 
    %do i=1 %to &varcnt;
      %if &&kkvart&i=2 %then kkxx99&i;
    %end;;
  statcat = left(statcat);
  var=left(var);
  stctlen=length(trim(statcat));
  varlen=length(trim(var));
run;

%if &debug=Y %then %do;
  proc print;
    title "after the reporting datasets have been merged";
  run;  
%end;

%if %length(&gencode) > 0 %then %do;
  data _null_;
    file gencode mod;
    put "*****************************************************************************;";
    put "* Join the reporting datasets from the continuous and categorical variables *;";
    put "*****************************************************************************;";
    put "data kkxx0008;";
    put "  length statcat $ 100;";
    put "  length " @;
    %do i=1 %to &colcnt;
      put "kkcol&i " @;
    %end;
    put " $ &colwidth;";
    put "  set " @;
    %if &contvar %then %do;
      put "kkxx0005 " @;
    %end; 
    %do i=1 %to &varcnt;
      %if &&kkvart&i=2 %then %do;
        put "kkxx99&i " @;
      %end;
    %end;
    put ";";
    put "  statcat = left(statcat);";
    put "  var=left(var);";
    put "  stctlen=length(trim(statcat));";
    put "  varlen=length(trim(var));";
    put "run;";
    put;
  run;
%end;

%if &catvar %then %do;
  %if &kkchisq or &kkpwchsq %then %do;
    proc sort;
      by &by kkorder1 kkorder2;
    proc sort data=kkff0009;
      by &by kkorder1 kkorder2;
    run;  

    data kkxx0008;
      merge kkxx0008 kkff0009;
      by &by kkorder1 kkorder2;
      if p_pchi ne . then do;
        kkpval=put(p_pchi,pval.);
      end;
    run;

    %if %length(&gencode) > 0 %then %do;
      data _null_;
        file gencode mod;
        put "proc sort;";
        put "  by &by kkorder1 kkorder2;";
        put "proc sort data=kkff0009;";
        put "  by &by kkorder1 kkorder2;";
        put "run;";
        put;
        put "data kkxx0008;";
        put "  merge kkxx0008 kkff0009;";
        put "  by &by kkorder1 kkorder2;";
        put "  if p_pchi ne . then do;";
        put "    kkpval=put(p_pchi,pval.);";
        put "  end;";
        put "run;";
        put;
      run;
    %end;
  %end;
%end;

/* get relevant formats */
proc summary noprint;
  var stctlen varlen;
  output out=kkff0007 max=kkmax kkmax2;
run;
    
data _null_;
  set kkff0007;
  call symput("w_sttct",kkmax);
  call symput("w_var",kkmax2);
run;

%if &w_sttct<9 %then %let w_sttct=9;
%if &w_var<8 %then %let w_var=8;
%if &w_sttct>80 %then %let w_sttct=80;


%if &style=2 %then %do;
  %let lwidth=0;
  %if &w_var>&lwidth %then %let lwidth=&w_var;
  %if %eval(&w_sttct+2)>&lwidth %then %let lwidth=%eval(&w_sttct+2);
%end;

%if &pagenum=Y %then %do;

  %*** first, get the length of the page ***;
  data _null_;
    set sashelp.voption;
    if optname='LINESIZE' then call symput("linesize",setting);
    else if optname='PAGESIZE' then call symput("pagesize",setting);
  run;

  %*** then check the number of titles and footnotes ***;
  proc sort data=sashelp.vtitle out=kktitle1;
    by type number;
  run;

  %let numtitle=0;
  %let numfootn=0;
  data _null_;
    set kktitle1;
    by type number;
    if last.type then do;
      if type='T' then call symput("numtitle",number);
      else if type='F' then call symput("numfootn",number);
    end;
  run;

  %*** check how many lines will be required for the headings ***;
  %do i=1 %to &bycnt;
    %let wordcnt=1;
    %let clwid&i=0;
    %if %index(%bquote(&&kkbylb&i),#) %then %let split_=#;
    %else %let split_=%str( );
    %let word = %scan(&&kkbylb&i,&wordcnt,&split_);
    %do %while("&word"~="");
      %if %length(&word)>&&clwid&i %then %let clwid&i=%length(&word);
      %let wordcnt=%eval(&wordcnt+1);
      %let word = %scan(&&kkbylb&i,&wordcnt,&split_);
    %end;
  %end;

  %let lshead=0;
  %do i=1 %to &bycnt;
    %let lscnt=1;
    %if %index(%bquote(&&kkbylb&i),#) %then %let split_=#;
    %else %let split_=%str( );
    %let word = %scan(%bquote(&&kkbylb&i),&lscnt,"&split_");
    %let wordlen = %length(%bquote(&word));
    %if %bquote(&word)= %then %let varhead=0;
    %else %let varhead=1;
    %do %while(%bquote(&word)~=);
      %if &wordlen>&&clwid&i %then %do;
        %let varhead=%eval(&varhead+1);
        %let wordlen=%length(%bquote(&word));
      %end;
      %let lscnt=%eval(&lscnt+1);
      %let word = %scan(%bquote(&&kkbylb&i),&lscnt,"&split_");
      %let wordlen=%eval(&wordlen+%length(%bquote(&word))+1);
    %end;
    %if &varhead>&lshead %then %let lshead=&varhead;
  %end;

  %do i=1 %to &colcnt;
    %let wordcnt=1;
    %let clwid&i=0;
    %if %index(%bquote(&&kkcllb&i),#) %then %let split_=#;
    %else %let split_=%str( );
    %let word = %scan(&&kkcllb&i,&wordcnt,&split_);
    %do %while("&word"~="");
      %if %length(&word)>&&clwid&i %then %let clwid&i=%length(&word);
      %let wordcnt=%eval(&wordcnt+1);
      %let word = %scan(&&kkcllb&i,&wordcnt,&split_);
    %end;
  %end;

  %do i=1 %to &colcnt;
    %let lscnt=1;
    %if %index(%bquote(&&kkcllb&i),#) %then %let split_=#;
    %else %let split_=%str( );
    %let word = %scan(%bquote(&&kkcllb&i),&lscnt,"&split_");
    %let wordlen = %length(%bquote(&word));
    %if %bquote(&word)= %then %let varhead=0;
    %else %let varhead=1;
    %do %while(%bquote(&word)~=);
      %if &wordlen>&&clwid&i %then %do;
        %let varhead=%eval(&varhead+1);
        %let wordlen=%length(%bquote(&word));
      %end;
      %let lscnt=%eval(&lscnt+1);
      %let word = %scan(%bquote(&&kkcllb&i),&lscnt,"&split_");
      %let wordlen=%eval(&wordlen+%length(%bquote(&word))+1);
    %end;
    %if &varhead>&lshead %then %let lshead=&varhead;
  %end;

  %if (&contvar and &catvar) %then %do;
    %if &lshead<3 %then %let lshead=3;
  %end;
  %else %do;
    %if &lshead<1 %then %let lshead=1;
  %end; 

  %*** one extra line for the heading underline and the space below
       and one for the bottom underline and the page X of X ***;
  %let repextra=5;
  %if &numtitle>0 %then %let repextra=%eval(&repextra+1); %* an extra spacer line *;
  %if &numfootn>0 %then %let repextra=%eval(&repextra+1); %* an extra spacer line * ;

  %if &style=1 %then %do;
    %if &lshead<1 %then %let lshead=1;
  %end;
  %else %do;
    %if &lshead<2 %then %let lshead=1;
  %end;


  %let repspace=%eval(&pagesize-&numtitle-&numfootn-&lshead-&repextra);                    
                    
  %put NOTE: Page Size=%trim(&pagesize) Report Space=%trim(&repspace) No. titles=%trim(&numtitle) No. footnotes=%trim(&numfootn) Header space=%trim(&lshead);

  %*** get the width of the report ***;
  %if &bycnt>0 %then %do;
    data _temp_;
      set kkxx0008 end=last;
      retain %do i=1 %to &bycnt;
               _bylcol&i
             %end; 0;
      %* get the length of the by columns;
      %do i=1 %to &bycnt;
        %if &&kkbyty&i = 1 and &&kkbyft&i = %then %do;
          if length(trim(put(&&kkby&i,best.)))>_bylcol&i then _bylcol&i=length(trim(put(&&kkby&i,best.)));
        %end;
        %else %if &&kkbyty&i = 2 and &&kkbyft&i = %then %do;
          if length(trim(&&kkby&i))>_bylcol&i then _bylcol&i=length(trim(&&kkby&i));
        %end;
        %else %if &&kkbyty&i = 2 and &&kkbyft&i ne %then %do;
          if length(trim(put(&&kkby&i,&&kkbyft&i)))>_bylcol&i then _bylcol&i=length(trim(put(&&kkby&i,&&kkbyft&i)));
        %end;
      %end;
      if last then do;
        %do i=1 %to &bycnt;
          call symput("BYLCOL&i",_bylcol&i);
        %end;
      end;
    run;
  %end;

  %let totwidth=0;
  %put Initial report width is zero;
  %do i=1 %to &bycnt;
    %let totwidth=%eval(&totwidth+&&bylcol&i+&spacing);
    %put Adding for by column number &i &&bylcol&i plus &spacing for spacing;
  %end;
  %if &style=1 %then %do;
    %let totwidth=%eval(&totwidth+&w_var+&w_sttct+&spacing+&spacing);
    %put Adding &w_var for the Variable column and &w_sttct for the statistic and category column plus 2*&spacing;
  %end;
  %else %do;
    %let totwidth=%eval(&totwidth+&spacing+&lwidth);
    %put Adding %eval(&spacing+&lwidth) spaces for combined desc + stat column;
    %put Total width is now &totwidth;
  %end;
  %do i=1 %to &colcnt;
    %let totwidth=%eval(&totwidth+&colwidth);
    %put Adding &colwidth for column number &i;
    %if &i ne &colcnt %then %let totwidth=%eval(&totwidth+&spacing);
    %put Adding &spacing for spacing;
  %end;
  %put The report is going to be &totwidth characters wide;
  %*** get the start column of the report ***;
  %let startcol=0;
  %if &totwidth>&linesize %then %put NOTE: The Report is too wide.  Try using smaller labels or using the FLOW option;
  %else %let startcol=%eval((&linesize-&totwidth)/2+1);
  
%end;

%if &style=2 %then %do;
  proc sort data=kkxx0008;
    by kkorder1 &by var statcat ;
  run;

  data kkxx0008 ;
    length _xlabel_ $100;
    set kkxx0008 ;
    by kkorder1 &by var statcat ;
    if first.var then do;
      _xlabel_ = var;
      temp = kkorder2;
      kkorder2 = 0;
      output;
      kkorder2 = temp;
    end;
    _xlabel_='  '||statcat;
    output;
  run;

  data kkxx0008 ;
    set kkxx0008 ;
    if compress(_xlabel_) = '' then delete;
    if kkorder2 = 0 then do;
    %do i=1 %to &colcnt;
      kkcol&i='';
    %end;
    end;
  run;
%end;

%if &pagenum=Y %then %do;

  proc sort data=kkxx0008;
    by kkorder1 var &by statcat %do i=1 %to &colcnt;
                                  kkcol&i
                                %end;;
  run;

  data kkxx0008;
    set kkxx0008 end=last;
    by kkorder1 var &by statcat %do i=1 %to &colcnt;
                                  kkcol&i
                                %end;;
    retain _lsline_ 0;
    _lsline_= _lsline_+1;
    if mod(_lsline_,&repspace) ne 1 and first.var then _lsline_=_lsline_+1;
    %do i=1 %to &bycnt;
      if mod(_lsline_,&repspace) ne 1 and first.&&kkby&i then _lsline_=_lsline_+1;
    %end;
    _lspage_=ceil(_lsline_/&repspace);
    _chpage_=compress(put(_lspage_,12.0));
    if last then call symput("reppages",_lspage_);
  run;

  %*** work out where to put the page X of X ***;
  %let maxplen=%length(%trim(&reppages));
  %let pxx = %eval(&startcol+&totwidth-&maxplen-&maxplen-9);
  %if &debug=Y %then %do;
    %put NOTE: Line Size=%trim(&linesize) Report Width=%trim(&totwidth) Start Col=%trim(&startcol) PageXXPos=%trim(&pxx) MaxPLen=%trim(&maxplen);

    proc print;
      title "data kkxx0008";
    run;  
  %end;

  %if %length(&gencode) > 0 %then %do;
    data _null_;
      file gencode mod;
      put "***************************************************************;";
      put "* Sort the data prior to adding paging details to the dataset *;";
      put "***************************************************************;";
      put "proc sort data=kkxx0008;";
      put "  by kkorder1 var &by statcat " @;
      %do i=1 %to &colcnt;
        put "kkcol&i " @;
      %end;
      put ";";
      put "run;";
      put;
      put "*************************************;";
      put "* Add paging details to the dataset *;";
      put "*************************************;";
      put "*** Variable _lsline_ stores the current line of the report;";
      put "*** Variable _lspage_ stores the current page of the report;";
      put "data kkxx0008;";
      put "  set kkxx0008 end=last;";
      put "  by kkorder1 var &by statcat " @;
      %do i=1 %to &colcnt;
        put "kkcol&i " @;
      %end;
      put ";";
      put "  retain _lsline_ 0;";
      put "  _lsline_= _lsline_+1;";
      put "  if mod(_lsline_,&repspace) ne 1 and first.var then _lsline_=_lsline_+1;";
      %do i=1 %to &bycnt;
        put "  if mod(_lsline_,&repspace) ne 1 and first.&&kkby&i then _lsline_=_lsline_+1;";
      %end;
      put "  _lspage_=ceil(_lsline_/&repspace);";
      put "  _chpage_=compress(put(_lspage_,12.0));";
      put "run;";
      put;
    run;
  %end;
%end;

%if "&outfile" ne "" %then %do;
  %if %upcase(&filetype) = HTML %then %do;
    ods listing close;
    ods html body="&outfile";
    ods html select all;
  %end;
  %if %upcase(&filetype) = RTF %then %do;
    ods listing close;
    ods rtf body="&outfile";
    ods rtf select all;
  %end;
  %if %upcase(&filetype) = PDF %then %do;
    ods listing close;
    ods pdf body="&outfile";
    ods pdf select all;
  %end;
  %else %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then %do;
    proc printto new print="&outfile";
    run;
  %end;
%end;

/*** do the report ***/        
proc report nowd missing headline headskip data=kkxx0008 split='#' spacing=&spacing;
  column %if &pagenum=Y %then _lspage_;
  kkorder1 
  %if &style=1 %then %do;
    var &by kkorder2 statcat 
  %end;
  %else %do;
    &by var kkorder2 _xlabel_
  %end;
  %if &colcnt=1 %then %do;
    kkcol1;
  %end;
  %else %do;
    ( %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then "--" ; "&kkcollb" 
    %do i=1 %to &colcnt;
      kkcol&i
    %end;)
    %if &kkcont=1 %then ("- Comparisons -" "&kkcompt" kkest kk95ci kkpval);
    %else %if (&kkwrst=1 or &kkchisq=1 or &kkpwchsq=1) %then ("- Comparisons -" "&kkcompt" kkpval);
  %end;;
  %if &pagenum=Y %then %do;
    define _lspage_ / group noprint;
  %end;
  define kkorder1 /order noprint;
  define kkorder2 /order noprint;
  %if &style=1 %then %do;
    define var / order group "Variable" 
      %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then width=&w_var;;
    %do i=1 %to &bycnt;
      define &&kkby&i /order=internal group 
      %if %length(&&kkbylb&i)>0 %then "&&kkbylb&i";
      %if %length(&&kkbyft&i)>0 %then format=&&kkbyft&i;
      %if &&kkby&i=%trim(%upcase(&pagevar)) %then noprint;;
    %end;
    define statcat / display %if (&contvar and &catvar) %then "Statistic#or#Category";
                             %else %do;
                               %if &contvar %then "Statistic";
                               %else %if &catvar %then "Category";
                             %end; 
                             %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII 
                               %then width=&w_sttct;;
  %end;
  %else %do;
    %do i=1 %to &bycnt;
      define &&kkby&i /order=internal group 
      %if %length(&&kkbylb&i)>0 %then "&&kkbylb&i";
      %if %length(&&kkbyft&i)>0 %then format=&&kkbyft&i;
      %if &&kkby&i=%trim(%upcase(&pagevar)) %then noprint;;
    %end;
    define var / order noprint;
    define _xlabel_ / %if (&contvar and &catvar) %then "Variable#   Statistic#   or#    Category";%else %do;%if &contvar %then "Variable#   Statistic";%else %if &catvar %then "Variable#   Category";%end; 
                      %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then width = &lwidth; order;
  %end;
  %if &colcnt=1 %then %do;
    define kkcol1 / display %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then width=&colwidth left; "&stathead";
  %end;
  %else %do i=1 %to &colcnt;
    define kkcol&i / display %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then width=&colwidth left; %if %length(%trim(&&kkcllb&i))>0 %then "%trim(&&kkcllb&i)";
                                                  %else "Missing";;
  %end;
  %if &kkcont=1 %then %do;
    define kkest / display 'Est.diff' %if &valwidth<8 %then width=8;
                                      %else width=&valwidth;;
    define kk95ci / display '95% CI';
    define kkpval / display 'P-val' %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then width=6;;
  %end;
  %if (&kkchisq=1 or &kkpwchsq=1 or &kkwrst) %then %do;
    define kkpval / display 'P-val' %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then width=&kkctstln;;
  %end;
  break after var / skip;
  %if %length(&by)>0 %then %do;                                          
    break after &&kkby&bycnt/skip;
  %end;
  %if &pagevar ne %then %do;
    break after %if &pagevar ne _var_ %then &pagevar; %else var; / page;
  %end;
  %if &pagenum=Y %then %do;
    break after _lspage_ / page;
    compute after _lspage_ %if %upcase(&filetype) ne TXT and %upcase(&filetype) ne ASCII %then %do;
                             / style=[just=right]
                           %end;;
      %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then %do;
        length uline $ &totwidth;
        uline=repeat('-',&totwidth);
        line @&startcol uline $&totwidth..;
      %end;
      chpage = compress(put(_lspage_,&maxplen..));
      pagetext = "Page "||compress(chpage)||" of %trim(&reppages)";
      line %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then @&pxx; pagetext $varying20.;
    endcomp;
  %end;
run;

%if "&outfile" ne "" %then %do;
  %if %upcase(&filetype) = HTML %then %do;
    ods html close;
  %end;
  %else %if %upcase(&filetype) = RTF %then %do;
    ods rtf close;
  %end;
  %else %if %upcase(&filetype) = PDF %then %do;
    ods pdf close;
  %end;
  %else %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then %do;
    proc printto;
    run;
  %end;
%end;

%if %length(&gencode) > 0 %then %do;
  data _null_;
    file gencode mod;
    %if "&outfile" ne "" %then %do;
      %if %upcase(&filetype) = HTML %then %do;
        put "ods listing close;";
        put 'ods html body="' @;
        put "&outfile" @;
        put '";';
        put "ods html select all;";
      %end;
      %else %if %upcase(&filetype) = RTF %then %do;
        put "ods listing close;";
        put 'ods rtf body="' @;
        put "&outfile" @;
        put '";';
        put "ods rtf select all;";
      %end;
      %else %if %upcase(&filetype) = PDF %then %do;
        put "ods listing close;";
        put 'ods pdf body="' @;
        put "&outfile" @;
        put '";';
        put "ods pdf select all;";
      %end;
      %else %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then %do;
        put 'proc printto new print="' @;
        put "&outfile" @;
        put '";';
        put "run;";
      %end;
    %end;
    put "**********************;";
    put "* Do the Proc Report *;";
    put "**********************;";
    put "proc report nowd missing headline headskip data=kkxx0008 split='#' spacing=&spacing;";
    put "  column " @;
    %if &pagenum=Y %then %do;
      put "_lspage_ " @;
    %end;
    put "kkorder1 var &by statcat " @;
    %if &colcnt=1 %then %do;
      put "kkcol1 " @;
    %end;
    %else %do;
      put '("--" "' @;
      put "&kkcollb" @;
      put '" ' @;
      %do i=1 %to &colcnt;
        put "kkcol&i " @;
      %end;
      put ") " @;
      %if &kkcont=1 %then %do;
        put '("- Comparisons -" "' @;
        put "&kkcompt" @;
        put '" kkest kk95ci kkpval)' @;
      %end;
      %else %if (&kkwrst=1 or &kkchisq=1 or &kkpwchsq=1) %then %do;
        put '("- Comparisons -" "' @;
        put "&kkcompt" @;
        put '" kkpval)' @;
      %end;
    %end;
    put ";";
    %if &pagenum=Y %then %do;
      put "  define _lspage_ / group noprint;";
    %end;
    put "  define kkorder1 /order noprint;";
    put '  define var / order group "Variable" width=' @;
    put "%trim(&w_var);" ;
    %do i=1 %to &bycnt;
      put "  define &&kkby&i /order=internal group " @;
      %if %length(&&kkbylb&i)>0 %then %do;
        put '"' @;
        put "&&kkbylb&i" @;
        put '" ' @;
      %end;
      %if %length(&&kkbyft&i)>0 %then %do;
        put "format=&&kkbyft&i " @;
      %end;
      %if &&kkby&i=%trim(%upcase(&pagevar)) %then %do;
        put "noprint " @;
      %end;
      put ";";
    %end;
    put "  define statcat / display " @;
    %if (&contvar and &catvar) %then %do;
      put '"Statistic#or#Category" ' @;
    %end;
    %else %do;
      %if &contvar %then %do;
        put '"Statistic" ' @;
      %end;
      %else %if &catvar %then %do;
        put '"Category" ' @;
      %end;
    %end; 
    put "width=&w_sttct; ";
    %if &colcnt=1 %then %do;
      put "  define kkcol1 / display width=&colwidth left " @;
      put '"'&stathead'";';
    %end;
    %else %do i=1 %to &colcnt;
      %put The column label in column number i is &&kkcllb&i;
      put "  define kkcol&i / display width=&colwidth left " @;
      %if %length(%trim(&&kkcllb&i))>0 %then %do;
        put '"' @;
        put "%trim(&&kkcllb&i)" @;
        put '"' @;
      %end;
      %else %do;
        put "'Missing'" @;
      %end;
      put ';';
    %end;
    %if &kkcont=1 %then %do;
      put "  define kkest / display 'Est.diff' " @;
      %if &valwidth<8 %then %do;
        put "width=8;";
      %end;
      %else %do;
        put"width=&valwidth;";
      %end;
      put "  define kk95ci / display '95% CI';";
      put "  define kkpval / display 'P-val' width=6;";
    %end;
    %if (&kkchisq=1 or &kkpwchsq=1 or &kkwrst) %then %do;
      put "  define kkpval / display 'P-val' width=&kkctstln;";
    %end;
    put "  break after var / skip;";
    %if %length(&by)>0 %then %do;                                          
      put "  break after &&kkby&bycnt/skip;";
    %end;
    %if &pagevar ne %then %do;
      put "  break after " @;
      %if &pagevar ne _var_ %then %do;
        put "&pagevar " @;
      %end;
      %else %do;
        put "var ";
      %end;
      put " / page;";
    %end;
    %if &pagenum=Y %then %do;
      put "  break after _lspage_ / page;";
      put "  compute after _lspage_;";
      %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then %do;
        put "    length uline $ &totwidth;";
        put "    uline=repeat('-',&totwidth);";
        put "    line @&startcol uline $&totwidth..;";
      %end;
      put "    line @&pxx " @;
      put '"Page " ' @;
      put "_lspage_ &maxplen.." @;
      put '" of ' @;
      put "%trim(&reppages)" @;
      put '";';
      put "  endcomp;";
    %end;
    put "run;";
    put;
    %if "&outfile" ne "" %then %do;
      %if %upcase(&filetype) = HTML %then %do;
        put "ods html close;";
      %end;
      %else %if %upcase(&filetype) = RTF %then %do;
        put "ods rtf close;";
      %end;
      %else %if %upcase(&filetype) = PDF %then %do;
        put "ods pdf close;";
      %end;
      %else %if %upcase(&filetype) = TXT or %upcase(&filetype) = ASCII %then %do;
        put "proc printto";
        put "run;";
      %end;
    %end;
  run;
%end;
   
%mend summary;

