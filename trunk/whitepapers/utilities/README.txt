Programming guidelines and conventions

Starting Point is the PhUSE Good Programming Practice Guide:
• http://www.phuse.eu/publications.aspx
• http://www.phusewiki.org/wiki/index.php?title=Good_Programming_Practice


DETAILS

• keep it simple. aggressively
.. before you add in complexity: stop, assess whether this is really needed, 
   and justify the gain in functionality vs. the costs of complexity
.. before you finish your code: stop, review and assess whether it can be simpler without loss

• all WORK data sets begin with prefix CSS_
.. and DO NOT overwrite data sets that could help the user debug their data & changes
.. and DO delete other WORK data sets as soon as they are obsolete

• header contains a "TO DO" list, to facilitate contribution
.. "TO DO" placeholders within the program can also be helpful to help contributors properly incorporate new code
• Header: see notes on "Comments", below
• Spacing and alignment
.. align code with space characters, never tabs
.. consistent number of spaces to indent within a single program: 2, 3 or 4
..  maintain spacing in a program. if you edit a program with 2-space alignment, stick with 2-space alignment

• capitalization
.. SAS is not a case-sensitive language
.. prefer lower case, unless necessary (title, labels) or helpful for clarity (comments)
.. use casing functions explicitly in algorithms lowcase(), upcase(), %lowcase(), %upcase()

• do not abbreviate SAS keywords anywhere
.. use the full keyword to support clarity and readability
.. create good experience for end-users of all skill levels

• explicit parentheses in algorithms for readability
.. do not force reviewer to check order of operations, demonstrate that you are in control
.. NO:  var + 1 / 10
.. YES: var + (1/10)

• macro names should be meaningful, even if long
.. prefix indicates "type", e.g., asset_*, util_*, etc.
.. when reading the macro name in calling code, the purpose should be clear

• use temporary macro NULL to wrap macro logic such as %IF in open code
.. Example:
      %macro null;
        %if not %symexist(init_sasautos) %then %let init_sasautos = %sysfunc(getoption(sasautos));
      %mend null;
      %null;

• see "Conventions for macro parameters", below
• OK to assume that one-level data sets are in WORK
.. without checking for USER libname & system option
.. but keep in mind as potential bug

• macro message in log are one of these formats:
.. NOTE: (MACRO-NAME-UPCASE) Clear informational message to user.
.. WARNING: (MACRO-NAME-UPCASE) Warning message to user, but processing continues.
.. ERROR: (MACRO-NAME-UPCASE) Error detected current context. Processing should stop as soon as possible.
.. for ASSERT MACROS, see additional details, below

• macros clean up after themselves
.. delete temp data sets before exiting
.. reset any modifications before exiting: system options, graphics options, ODS destinations

• tests
.. every test is explicitly uses specific data


Explanations (a.k.a. Comments)
------------------------------
• Comments must be meaningful and easy to maintain
.. Explain what the code needs to achieve
.. Explain decisions in the code
.. .. why keep or drop certain vars?
.. .. why are the merge variables or by variables correct?
.. .. why is a particular algorithm correct? what do the elements represent?
.. No extra characters to draw boxes around comments (see header note, below)

• Comment types must be used intentionally
.. Header block between starting line (/***) and ending line (***/)
.. /*   */    style comments for blocks of explanation, like with the header
.. %*   *;    style comments to explain macro statements
.. *--- ---*; comment statements as single-line explanations
.. Comments visually group blocks of related code, which is indented one additional step
.. Examples (consistent 3-space indentation)
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


ASSERT macros
-------------
• return 0/1 result in-line whenever possible. 0 = FAIL, 1 = PASS
• use and return a %local OK symbol for in-line macros
• declare %local and %global symbols explicitly
• always return at least one message to the log, either
... NOTE: (MACRO-NAME-UPCASE) Result is PASS. Optional confirmation of the successful assertion.
... or...
... ERROR: (MACRO-NAME-UPCASE) Result is FAIL. Clear explanation of failed assertion.


UTIL macros
-----------


Conventions for macro parameters:
---------------------------------

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