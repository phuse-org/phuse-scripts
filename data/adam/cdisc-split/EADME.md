Modified CDISC ADaM pilot data

Modification:
  * Split single-study CDISC pilot data:
    https://github.com/phuse-org/phuse-scripts/tree/master/data/adam/cdisc

  * Into 2 studies: 01 and 02

Future effort:
  * This allows testing of pooled (multiple study) analyses
  * But does not allow checking pooled results against original single study results
    (since original study 01 data were split, rather than spoofing an entirely new/different study 02)
  * To allow qualifying pooled analyses against single-study analyses, create an "-multi" version of these data

CDISC published the original pilot data in a pilot electronic submission package:

  http://www.cdisc.org/sdtmadam-pilot-project
  * Complete CDISC pilot package is available to CDISC members only
  * Location within CDISC archive: 
    Updated Pilot Submission Package\900172\m5\datasets\cdiscpilot01\analysis\adam\datasets\
