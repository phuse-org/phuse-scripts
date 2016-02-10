/***
  Delete WORK DATA SETS

  This is a simple PhUSE CS clean-up utility to delete WORK DATA SETS
  (not views, and not from other libraries)

  INPUTS:
    DSETS Space-delimited list of data sets to delete from WORK.
          REQUIRED
          Syntax: list of one-level data sets that exist in WORK library
                  _ALL_ is a special keyword, see 1st Example, below
          Example: _ALL_
               NB: if WORK._ALL_ DOES exist, delete just this one data set
                   if WORK._ALL_ does NOT exist, delete *ALL* work data sets
                   (if you include _ALL_ in a list of WORK dsets, macro looks only for this exact dset.)
          Example: my_data_1 my_test_data another_dset
               NB: macro simply passes this list to PROC DATASETS ... DELETE
                   so, macro supports data set lists, as well, see references

  Return: No return value
          SAS PROC DATASETS ... DELETE writes a NOTE to the log for each dset not found
          This macro does no additional reporting
          EG:
            NOTE: The file WORK.JUNK (memtype=DATA) was not found, but appears on a DELETE statement.
            NOTE: The file WORK.JUNK_DNE (memtype=DATA) was not found, but appears on a DELETE statement.

  References:
    Data Set Lists: http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#a003040446.htm

  Author: Dante Di Tommaso                                                  

***/

  %macro util_delete_dsets(dsets);
    %local uds_list;

    %if %upcase(&dsets) = _ALL_ %then %do;
      proc sql noprint;
        select unique(memname) into :uds_list separated by ' '
        from dictionary.members
        where memtype = 'DATA' and libname = 'WORK'
        order by memname;
      quit;
    %end;
    %else %do;
      %let uds_list = %upcase(&dsets);
    %end;

    proc datasets library=WORK memtype=DATA nolist nodetails;
      delete &uds_list;
    quit;

  %mend util_delete_dsets;
