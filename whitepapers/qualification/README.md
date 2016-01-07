General
-------
Assert and Util macros can generally be testing using a PASS/FAIL unit-test approach.

PASS/FAIL convention
--------------------
We have simplified testing by adopting a PASS/FAIL test execution and assessment macro presented at [PhUSE 2011](http://www.lexjansen.com/phuse/2011/ad/AD04.pdf).

For further guidance, see:
* An example of PASS/FAIL test definition, execution, assessment and reporting: [example_passfail_test_definitions.sas](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/example_passfail_test_definitions.sas)
* Template PASS/FAIL test plan document: [testplan_TEMPLATE.dotx](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/testplan_TEMPLATE.dotx)
* Template PASS/FAIL test program (SAS): [test_TEMPLATE.sas](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/test_TEMPLATE.sas)

The language-specific output subfolders contain test artifacts:
* For SAS: the PASS/FAIL setup produces a log, listing and XML record of the test results (e.g., [testresults_assert_dset_exist.xml](https://github.com/phuse-org/phuse-scripts/blob/master/whitepapers/qualification/outputs_sas/testresults_assert_dset_exist.xml))
