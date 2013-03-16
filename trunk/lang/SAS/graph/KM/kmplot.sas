/*
This is a comment area. 
Test editing
Adding some more text for editing.
Testing by adding a comment. Also, tested by doing a Windows CTRL-A/CTRL-C to select all and copy
into buffer. Then, paste into local SAS for execution.
Idea: at the risk of big file sizes - better off using a separate which only generates source data
- good for SAS and R???
*/
data one ;
  length arm $8 ;
  censor = 0 ;
  arm = "Arm 1" ;
  do day = 143,164,188,188,190,192,206,213,216,220,227.230,
           234,246,265,304 ;
    output ;
  end ;
  censor = 1 ;
  day = 216 ; output ;
  day = 244 ; output ;
  censor = 0 ;
  arm = "Arm 2" ;
  do day = 142,156,163,198,205,232,232,233,233,233,233,239,
           240, 261, 280, 280, 296, 296, 323 ;
    output ;
  end ;
  censor = 1 ;
  day = 204 ; output ;
  day = 344 ; output ;
  run ;
  
ods pdf file = "/bdm/myfolder/mcarniel/kmplot.pdf" ;
ods listing close ;
ods graphics on ;

proc lifetest data=one plots=survival (atrisk=0 to 330 by 30) ;
  time day*censor(1) ;
  srata arm ;
  title1 "Example K-M Plot" ;
  run ;
  
ods graphics off ;
ods pdf close ;
