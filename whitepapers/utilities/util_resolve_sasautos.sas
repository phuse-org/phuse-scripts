/***
  DESCRIPTION:   IN-LINE macro returns pipe-delim list of SASAUTOS paths

  FILENAME:      util_resolve_sasautos.sas
  AUTHOR:        D. Di Tommaso
  PLATFORM:      SAS 8.02 TS Level 02M0 / WIN_PRO (XP PRO) & AIX 5.2

  INPUT:         getoption(sasautos) paths to parse and search
  OUTPUT:        pipe-delim list of SASAUTOS paths, quoted as necessary

  ASSUMPTIONS/
  RESTRICTIONS:  SASAUTOS must contain valid pathnames
                 (filerefs or QUOTED literal pathnames)
                 NB: for windows, SASAUTOS literal pathnames must be in
                     DOUBLE-QUOTEs -- SAS cant handle single quotes
***/

%macro util_resolve_sasautos;
  %local sasautos salen mchar end fndend paths current sep
         dsid frnum xpnum idx obs frval xpval pthnames;

  %* GET current list of SASAUTOS filerefs (no quotes) & quoted pathnames *;
  %let sasautos = %qsysfunc(getoption(sasautos));

  %* remove any enclosing parens, () *;
  %if %qsubstr(&sasautos,1,1) eq %str(%() &
      %qsubstr(&sasautos,%length(&sasautos)) eq %str(%)) %then %do;
    %let salen = %eval(%length(&sasautos)-2);
    %let sasautos = %qsubstr(&sasautos,2,&salen);
  %end;

  %* PROCESS the sasautos string until its exhausted *;
  %do %until(&sasautos eq );
    %let paths =;

    %* HANDLE quoted pathnames differently (may contain spaces, commas, parens) *;
    %* FIND SINGLE QUOTED PATHNAME: *;
    %if %qsubstr(&sasautos,1,1) eq %str(%') |
        %qsubstr(&sasautos,1,1) eq %str(%") %then %do;

      %* FIND end of quoted pathname -- ignoring 2 x quoted quotes *;
      %let mchar = %qsubstr(&sasautos,1,1);
      %let end = 2;  %* starting, assume str ends w next char *;
      %let fndend = 0;
      %do %until (&fndend | &end gt &salen);

        %if %qsubstr(&sasautos,&end,1) eq &mchar %then %do;
          %* IGNORE 2 x quote marks (quoted SAME quotes) *;
          %if &end lt &salen %then %do;
            %if %qsubstr(&sasautos,&end,2) ne &mchar&mchar %then
                %let fndend = 1;
            %else %let end = %eval(&end+2);
          %end;
          %else %let fndend = 1;
        %end;
        %else %let end = %eval(&end+1);
      %end;

      %* new path surrounded by matching quotes *;
      %if &fndend %then %let paths = %qsubstr(&sasautos,2,&end-2);

      %* NB: If path wrapped in single quotes, convert  *;
      %*     paired single quotes into one single-quote *;
      %let idx = 1;
      %if &mchar eq %str(%') %then
      %do %while ( &idx lt %length(&paths) );
        %if %qsubstr(&paths,&idx,2) eq '' %then %do;
          %let paths = %qsubstr(&paths,1,%eval(&idx-1))%qsubstr(&paths,%eval(&idx+1));
        %end;
        %let idx = %eval(&idx+1);
      %end;

      %* REMOVE this newest path from sasautos *;
      %if &salen gt &end %then
          %let sasautos = %qleft(%qsubstr(&sasautos,&end+1));
      %else %let sasautos = ;
    %end;

    %* FIND ALL PATHNAMES associated with unquoted fileref *;
    %else %do;

      %let current = %qscan( &sasautos,1,%str( ,) );
      %if %index(&sasautos, %str( )) %then
          %let sasautos = %qleft(%qsubstr(&sasautos, 1+%index(&sasautos, %str( ))));
      %else %let sasautos = ;

      %* READ paths for this fileref from sashelp.vextfl *;
      %let dsid = %sysfunc(open( sashelp.vextfl ));
      %let frnum  = %sysfunc(varnum( &dsid, fileref ));
      %let xpnum  = %sysfunc(varnum( &dsid, xpath ));

      %* CONCATENATE all paths associated with this fileref (|-delim) *;
      %let obs = 0;
      %let idx = 0;
      %do %until (&obs eq -1);
        %let idx = %eval(&idx + 1);
        %let obs = %sysfunc(fetchobs( &dsid, &idx ));
        %let frval = %qsysfunc(getvarc( &dsid, &frnum ));
        %let xpval = %qsysfunc(getvarc( &dsid, &xpnum ));

        %if %upcase(&frval) = %upcase(&current) %then %do;
          %if %length(&paths) eq 0 %then %let paths = %qtrim(&xpval);
          %else %let paths = %qtrim(&paths)|%qtrim(&xpval);
        %end;
      %end;
      %let dsid = %sysfunc(close( &dsid ));
    %end;

    %* CONCATENATE paths collected from sasautos *;
    %if %length(&pthnames) eq 0 %then %let pthnames = &paths;
    %else %let pthnames = &pthnames|&paths;

    %let salen = %length(&sasautos);
  %end;

  &pthnames

%mend util_resolve_sasautos;
