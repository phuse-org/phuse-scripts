Programming guidelines and conventions
PhUSE/CSS WG5 Project 02: Standard Analyses

Starting Point is the PhUSE Good Programming Practice Guide:
• http://www.phuse.eu/publications.aspx
• http://www.phusewiki.org/wiki/index.php?title=Good_Programming_Practice


DETAILS

• keep it simple. aggressively.
.. before you add in complexity: stop, assess whether this is really needed, and
.. justify the gain in functionality vs. the costs of complexity.
.. before you finish your code: stop, review and assess whether you can make it simpler without meaningful loss

• but not too simple.
.. all variable names, symbol names, macro names must be meaningful
.. long, descriptive names are better for readability than short, cryptic names
.. EG, looping
.. (1) never use one-letter variables to loop (e.g., i j k ...)
.. (2) looping and parsing delimited strings (in base SAS or macro language)
.. .. code often loops through values, or parses a delimited string and processes each piece
.. .. EG: process each parameter in a list of lab parameters, or each var in a list of variables
.. .. our programs should uniformly use -IDX and -NXT suffixes for such processing
.. .. .. -IDX suffix for the indexing variable (or macro symbol)
.. .. .. e.g., See %assert_var_exist() for an example of looping through data sets and variable names.
               DIDX indexes data set names, and VIDX indexes variable names
               This makes the code easy to read!
.. .. .. -NXT suffix for the variable (or symbol) that holds the value to process next from a deliminted list
.. .. .. e.g., See %assert_var_exist() for an example of looping through data sets and variable names.
               DNXT holds the next data set name, and VNXT holds the next variable name
               This makes the code easy to read!

• all WORK data sets begin with prefix CSS_
.. DO NOT overwrite data sets that could help the user debug their data & changes
.. DO delete other WORK data sets as soon as they are obsolete

• headers contain a "TO DO" list, to facilitate contribution
.. "TO DO" placeholders within the script can also help contributors properly incorporate new code
• Header: see notes on "Comments", below
• Spacing and alignment
.. align code with space characters, never tabs.
.. .. set your editor to replace tabs with spaces.

.. consistent number of spaces to indent within a single program.
.. 2-space indents are preferred (not more). set your editor to 2-space indenting, replacing tabs with spaces.
.. .. see Explanations (a.k.a. Comments), below.
.. .. indenting helps group related blocks of code, so 2-space indenting allows more indenting
.. maintain spacing in a program. 
.. .. e.g., if you edit a program with 2-space alignment, stick with 2-space alignment

• capitalization
.. SAS is not a case-sensitive language
.. prefer lower case, unless necessary (title, labels) or helpful for clarity (comments)
.. use casing functions explicitly in algorithms lowcase(), upcase(), %lowcase(), %upcase()

• do not abbreviate SAS keywords anywhere
.. use the full keyword to support clarity and readability
.. create a good experience for end-users of all skill levels

• explicit parentheses in algorithms for readability
.. do not force reviewers to check order of operations, demonstrate that you are in control
.. NO:  var + 1 / 10
.. YES: var + (1/10)

• macro names should be meaningful, even if long
.. prefix indicates "type", e.g., assert_*, util_*, etc.
.. when reading the macro name in a calling script, the purpose should be clear
.. adhere to NAMING CONVENTIONS that SAS already establishes, whenever possible
.. NO:  %assert_dse()
.. NO:  %assert_dset_exists()
.. YES: %assert_dset_exist(), to match the grammar of SAS elements exist(), fexist(), symexist(), etc.

• use temporary macro NULL to wrap macro logic in open code, such as an %IF block
.. Example:
      %macro null;
        %if not %symexist(init_sasautos) %then %let init_sasautos = %sysfunc(getoption(sasautos));
      %mend null;
      %null;


• see "Conventions for macro parameter names", below
• OK to assume that one-level data sets are in WORK
.. without checking for the USER libname & related system option
.. but keep in mind as potential bug

• macro messages to the log follow this style and format:
.. NOTE: (MACRO-NAME-UPCASE) Clear informational message to user.
.. WARNING: (MACRO-NAME-UPCASE) Warning message to user, but processing continues.
.. ERROR: (MACRO-NAME-UPCASE) Error detected current context. Processing should stop as soon as possible.
.. this makes it easy to
.. (1) extract messages from logs
.. (2) separate SAS and PhUSE/CSS messages
.. for PhUSE/CSS ASSERT MACROS, see additional details, below

• macros use Quoting intelligently
.. use q- versions of macro functions whenever processing unknown text.
.. EG: then following macro FAILS for some values of &vars, unless you use the %qscan() function
      %macro null(vars);
        %if %scan(&vars, 1) = STDDEV %then %put Note: Calculating Standard Deviation.;
        %else %put Note: Calculating something else.;
      %mend null;
      %null(OR);

• macros clean up after themselves
.. delete temp data sets before exiting
.. reset any modifications before exiting
.. .. system options, 
.. .. graphics options, 
.. .. ODS destinations
.. .. etc


Explanations (a.k.a. Comments)
------------------------------
• Comments must be meaningful and easy to maintain
.. No extra characters to draw boxes around comments (see header note, below)
.. Explain what the code needs to achieve
.. Explain decisions in the code
.. .. why keep or drop certain vars?
.. .. why are the merge variables or by variables correct?
.. .. why is a particular algorithm correct? what do the elements represent?

• Comment types must be used intentionally
.. Header block between starting line (/***) and ending line (***/)
.. /***   ***/    style comments for blocks of explanation, like with the header
.. %*---   ---*;  style comments to explain macro statements
.. *---   ---*;   comment statements as single-line explanations

• Comments visually group blocks of related code, which are indented one additional step
.. Examples (consistent 2-space indentation)
   *--- Single-line comment to explain the next, related steps ---*;
      all code that accomplishes this objective is indented to this level

   /*** You can Title this code block, if you like
      This next bit is more complicated
      And requires a bit more explanation
      But not too much
   ***/
      all code to accomplish this complex task

      still working on it down here

   %*--- OK, now I am prepared to call my utility macro ---*;
      %get_the_job_done(ds=my_data)

• Comments declare the names of any symbols that a macro call creates. See also "TEMPLATE programs", below.

TEMPLATE programs
-----------------
• Use PhUSE/CSS test data
• Access PhUSE/CSS test data via %UTIL_ACCESS_TEST_DATA
• Use global symbol &CONTINUE with values 0 (No, there's a problem) and 1 (Yes, continue) to monitor success of processing
• Use assertion macro %ASSERT_CONTINUE to interrupt processing if a problem occurs (force syntax-checking mode if error indicated)
• Declare the symbols that utility programs create. E.g., see these macro calls in template program WPCT-F.07.01.sas
  %*--- Parameters: Number (&PARAMCD_N), Names (&PARAMCD_NAM1 ...) and Labels (&PARAMCD_LAB1 ...) ---*;
    %util_labels_from_var(css_anadata, paramcd, param)

  %*--- Number of planned treatments: &TRTN ---*;
    %util_count_unique_values(css_anadata, trtp, trtn)


TEST programs
-------------
• script naming convention: test_<program-name-without-extension>.sas
• every test explicitly uses specific data
  (1) this can be test data created specifically within the test program for specific tests, or
  (2) centralized PhUSE/CSS test data available for multiple tests. see:
      https://github.com/phuse-org/phuse-scripts/tree/master/scriptathon2014/data
• centralized PhUSE/CSS data sets must include a QLTSTID variable that identifies specific test data
.. QLTSTID has label "CSS/PhUSE Qualification Test ID", and length sufficient for all current test IDs
.. see: https://github.com/phuse-org/phuse-scripts/blob/master/scriptathon2014/data/advs.xpt
.. QLTSTID values should not change, once assigned.
.. EG, if some test relies on records with QLTSTID = "TEST-01-01", 
.. (1) those obs should not change, individually or as a set, and
.. (2) any new obs added to the same central data set must have a new value for QLTSTID


ASSERT macros
-------------
• return a 0/1 result in-line whenever possible: 0 = FAIL, 1 = PASS
• use and return a %local OK symbol for in-line macros
• declare %local and %global symbols explicitly
• always return at least one message to the log, either
.. NOTE: (MACRO-NAME-UPCASE) Result is PASS. Optional confirmation of the successful assertion.
.. or
.. ERROR: (MACRO-NAME-UPCASE) Result is FAIL. Clear explanation of failed assertion.


UTIL macros
-----------
• perform a specific task
• are never highjacked to perform a related task
• are never highjacked to create a convenient side-effect


Conventions for macro parameter names:
--------------------------------------

Symbol    Description                                      Comments                            Programs used in
--------- ----------------------------------------------   -----------------------             ----------------------------------
DS        SAS data set, one or two levels                  positional, when usage is obvious
VAR       SAS var, no special chars expected               positional, when usage is obvious
ORD       name of an ORDER variable such as AVISITN        always named parameter
WHR       complete where statement, %str()-quoted          always named parameter
SQLWHR    complete SQL where clause, quoted as needed      always named parameter
FMT       SAS format name WITH punctuation (@$.), as nec   always named parameter
SYM       name of a symbol (macro variable)                positional, when usage is obvious

Other macro parameters (program name)   Comment
-------------------------------------   -------------------------------
TABLE   (util_freq2format.sas)          a 2-var PROC FREQ table spec like var1*var2, can include extra spacing
FMTNAME (util_freq2format.sas)          macro determines fmt type, so value does NOT include punctuation (@$.)
MACNAME (util_autocallpath.sas)         a macro name, without any special chars
DSETS   (assert_refds_complete.sas)     list of data sets, where order has a specific meaning