
SAS Programming Guidelines and Conventions
==========================================
PhUSE CS Standard Analyses
---------------------------

Starting Point is the PhUSE Good Programming Practice Guide:
* http://www.phuse.eu/publications.aspx
* http://www.phusewiki.org/wiki/index.php?title=Good_Programming_Practice

PhUSE CS project guidelines available in PhUSE wiki:
* http://phusewiki.org/wiki/index.php?title=WG5_P02_Programming_Guidelines

Utility Folder Macros Description:
* assert_complete_refds.sas  
  Assertion that according to listed unique KEYS, a reference dset (e.g., ADSL) contains info
  for all observations that appear in remaining dsets (e.g., ADAE, ADVS, ADLBC, ...)
  
* assert_continue.sas
   Error Handling - This defines the error handling of the PhUSE CS template programs.
   In case of error, continue checking syntax, but do not waste time or effort to process data.
* assert_depend.sas  
  
