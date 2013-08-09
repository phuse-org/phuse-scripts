filename mcsldata url "http://phuse-scripts.googlecode.com/svn/trunk/lang/R/report/test/data/mcsl.csv" ;
 
data mcsl ;
  infile mcsldata delimiter="," firstobs=2 missover ;
  length studyid $20 usubjid $20 trt01a $20 ageu $10 race $25 sex $1 saffl $1 efffl $1 dcdecod $50 dcreascd $50 ;
  length trt01an age racen bmibl heightbl weightbl 8 ;
  input studyid $ usubjid $ trt01a $ trt01an age ageu $ race $ racen 
        sex $ saffl $ efffl $ bmibl heightbl weightbl dcdecod $ dcreascd $ ;
  run;

proc means data=mcsl ;
  var age bmibl heightbl weightbl ;
  title1 "Summary Statistics of Key Continuous Variables" ;
  run ;

proc freq data=mcsl ;
  tables dcdecod dcreascd ;
  title1 "Summary Statistics of Key Discrete Variables" ;
  run ;
